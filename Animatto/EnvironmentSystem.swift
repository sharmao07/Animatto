import Foundation
import AppKit
import Combine

// MARK: - User Interaction Type
public enum UserInteractionType: String, Codable {
    case click
    case hover
    case dragStart
    case dragEnd
}

// MARK: - Inactivity Threshold
public enum InactivityThreshold: String, Codable, CaseIterable {
    case brief       // 60 seconds
    case moderate    // 300 seconds (5 min)
    case extended    // 900 seconds (15 min)
    
    public var duration: TimeInterval {
        switch self {
        case .brief: return 60
        case .moderate: return 300
        case .extended: return 900
        }
    }
}

// MARK: - Environmental Event Type
public enum EnvironmentEventType: Equatable {
    case appActivated(bundleId: String, appName: String)
    case appLaunched(bundleId: String, appName: String)
    case appTerminated(bundleId: String, appName: String)
    case cursorApproached(distance: CGFloat, cursorLocation: NSPoint)
    case cursorDeparted
    case userInteracted(type: UserInteractionType)
    case userInactivityReached(threshold: InactivityThreshold)
    case musicTrackChanged(track: String?)
    case animattoFocusChanged(isActive: Bool)
    case userReturned
    case ambientConditionChanged(type: AmbientEnvironmentType, intensity: Double)
}

// MARK: - Environmental Event
public struct EnvironmentEvent: Equatable {
    public let type: EnvironmentEventType
    public let timestamp: Date
    public let targetPetId: UUID?
    
    public init(type: EnvironmentEventType, timestamp: Date = Date(), targetPetId: UUID? = nil) {
        self.type = type
        self.timestamp = timestamp
        self.targetPetId = targetPetId
    }
}

// MARK: - Stable Environmental Snapshot
public struct EnvironmentSnapshot: Equatable {
    public var activeAppBundleId: String?
    public var activeAppName: String?
    public var isAnimattoActive: Bool
    public var lastUserInteractionTime: Date
    public var nowPlayingTrack: String?
    public var isUserInactive: Bool
    public var currentInactivityThreshold: InactivityThreshold?
    
    public init(
        activeAppBundleId: String? = nil,
        activeAppName: String? = nil,
        isAnimattoActive: Bool = false,
        lastUserInteractionTime: Date = Date(),
        nowPlayingTrack: String? = nil,
        isUserInactive: Bool = false,
        currentInactivityThreshold: InactivityThreshold? = nil
    ) {
        self.activeAppBundleId = activeAppBundleId
        self.activeAppName = activeAppName
        self.isAnimattoActive = isAnimattoActive
        self.lastUserInteractionTime = lastUserInteractionTime
        self.nowPlayingTrack = nowPlayingTrack
        self.isUserInactive = isUserInactive
        self.currentInactivityThreshold = currentInactivityThreshold
    }
}

// MARK: - Dedicated Environment Monitor
public class EnvironmentMonitor: ObservableObject {
    public static let shared = EnvironmentMonitor()
    
    @Published public private(set) var snapshot = EnvironmentSnapshot()
    
    // User configuration
    public var isEnabled: Bool = true
    public var appAwarenessEnabled: Bool = true
    public var cursorTrackingEnabled: Bool = true
    public var inactivityTrackingEnabled: Bool = true
    public var reactionFrequency: Double = 0.6
    
    // Proximity Hysteresis Configuration
    public struct ProximityConstants {
        public static let enterDistance: CGFloat = 130.0 // Distance to trigger approach
        public static let exitDistance: CGFloat = 180.0  // Distance to trigger departure (50pt deadband)
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var proximityTimer: Timer?
    private var lastEmittedThreshold: InactivityThreshold?
    private var petProximityStates: [UUID: Bool] = [:]
    private var lastAppEventTime: Date = .distantPast
    
    // Callback handler for dispatched events
    public var onEvent: ((EnvironmentEvent) -> Void)?
    
    // Dynamic provider for active pet locations
    public var petCentersProvider: (() -> [UUID: NSPoint])?
    
    // Mock / injectable location provider for testing
    public var mouseLocationProvider: () -> NSPoint = { NSEvent.mouseLocation }
    public var nowProvider: () -> Date = { Date() }
    
    public init() {
        setupObservers()
        startPeriodicChecks()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Observer Lifecycle
    
    public func setupObservers() {
        cancellables.removeAll()
        
        let wsCenter = NSWorkspace.shared.notificationCenter
        
        // 1. Application Activation Notification
        wsCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] notification in
                self?.handleWorkspaceAppNotification(notification, type: .activate)
            }
            .store(in: &cancellables)
            
        // 2. Application Launch Notification
        wsCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .sink { [weak self] notification in
                self?.handleWorkspaceAppNotification(notification, type: .launch)
            }
            .store(in: &cancellables)
            
        // 3. Application Terminate Notification
        wsCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .sink { [weak self] notification in
                self?.handleWorkspaceAppNotification(notification, type: .terminate)
            }
            .store(in: &cancellables)
            
        // 4. Animatto Focus Notification
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self = self, self.isEnabled else { return }
                self.snapshot.isAnimattoActive = true
                self.emit(EnvironmentEvent(type: .animattoFocusChanged(isActive: true), timestamp: self.nowProvider()))
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .sink { [weak self] _ in
                guard let self = self, self.isEnabled else { return }
                self.snapshot.isAnimattoActive = false
                self.emit(EnvironmentEvent(type: .animattoFocusChanged(isActive: false), timestamp: self.nowProvider()))
            }
            .store(in: &cancellables)
            
        // 5. Music Track Updates
        MusicMonitor.shared.$currentTrack
            .removeDuplicates()
            .sink { [weak self] track in
                guard let self = self, self.isEnabled else { return }
                self.snapshot.nowPlayingTrack = track
                self.emit(EnvironmentEvent(type: .musicTrackChanged(track: track), timestamp: self.nowProvider()))
            }
            .store(in: &cancellables)
    }
    
    public func startPeriodicChecks() {
        proximityTimer?.invalidate()
        // Checks proximity and inactivity every 0.8 seconds (low CPU overhead)
        proximityTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let centers = self.petCentersProvider?() ?? [:]
            self.checkProximityAndInactivity(petCenters: centers)
        }
    }
    
    public func stopMonitoring() {
        cancellables.removeAll()
        proximityTimer?.invalidate()
        proximityTimer = nil
        petProximityStates.removeAll()
        lastEmittedThreshold = nil
    }
    
    public func stop() {
        isEnabled = false
        stopMonitoring()
    }
    
    public func start() {
        isEnabled = true
        setupObservers()
        startPeriodicChecks()
    }
    
    // MARK: - Application Event Handling
    
    private enum AppNotificationKind {
        case activate, launch, terminate
    }
    
    private func handleWorkspaceAppNotification(_ notification: Notification, type: AppNotificationKind) {
        guard isEnabled && appAwarenessEnabled else { return }
        
        let now = nowProvider()
        // Debounce rapid application activations within 0.3s
        guard now.timeIntervalSince(lastAppEventTime) >= 0.3 else { return }
        lastAppEventTime = now
        
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        let bundleId = app.bundleIdentifier ?? "unknown.bundle"
        let appName = app.localizedName ?? "Application"
        
        // Skip Animatto self-notifications to avoid feedback loops
        if bundleId == Bundle.main.bundleIdentifier {
            return
        }
        
        switch type {
        case .activate:
            snapshot.activeAppBundleId = bundleId
            snapshot.activeAppName = appName
            emit(EnvironmentEvent(type: .appActivated(bundleId: bundleId, appName: appName), timestamp: now))
        case .launch:
            emit(EnvironmentEvent(type: .appLaunched(bundleId: bundleId, appName: appName), timestamp: now))
        case .terminate:
            if snapshot.activeAppBundleId == bundleId {
                snapshot.activeAppBundleId = nil
                snapshot.activeAppName = nil
            }
            emit(EnvironmentEvent(type: .appTerminated(bundleId: bundleId, appName: appName), timestamp: now))
        }
    }
    
    // MARK: - Cursor Proximity & Inactivity Checks
    
    public func checkProximityAndInactivity(petCenters: [UUID: NSPoint] = [:]) {
        guard isEnabled else { return }
        
        let now = nowProvider()
        
        // 1. User Inactivity Check
        if inactivityTrackingEnabled {
            let elapsedIdle = now.timeIntervalSince(snapshot.lastUserInteractionTime)
            
            if elapsedIdle >= InactivityThreshold.extended.duration {
                if lastEmittedThreshold != .extended {
                    lastEmittedThreshold = .extended
                    snapshot.isUserInactive = true
                    snapshot.currentInactivityThreshold = .extended
                    emit(EnvironmentEvent(type: .userInactivityReached(threshold: .extended), timestamp: now))
                }
            } else if elapsedIdle >= InactivityThreshold.moderate.duration {
                if lastEmittedThreshold != .moderate && lastEmittedThreshold != .extended {
                    lastEmittedThreshold = .moderate
                    snapshot.isUserInactive = true
                    snapshot.currentInactivityThreshold = .moderate
                    emit(EnvironmentEvent(type: .userInactivityReached(threshold: .moderate), timestamp: now))
                }
            } else if elapsedIdle >= InactivityThreshold.brief.duration {
                if lastEmittedThreshold == nil {
                    lastEmittedThreshold = .brief
                    snapshot.isUserInactive = true
                    snapshot.currentInactivityThreshold = .brief
                    emit(EnvironmentEvent(type: .userInactivityReached(threshold: .brief), timestamp: now))
                }
            }
        }
        
        // 2. Cursor Proximity Check with Hysteresis
        if cursorTrackingEnabled && !petCenters.isEmpty {
            let cursor = mouseLocationProvider()
            
            for (petId, center) in petCenters {
                let dx = cursor.x - center.x
                let dy = cursor.y - center.y
                let distance = sqrt(dx * dx + dy * dy)
                let isCurrentlyNear = petProximityStates[petId] ?? false
                
                if !isCurrentlyNear && distance <= ProximityConstants.enterDistance {
                    // Enter event
                    petProximityStates[petId] = true
                    recordUserInteraction()
                    emit(EnvironmentEvent(type: .cursorApproached(distance: distance, cursorLocation: cursor), timestamp: now, targetPetId: petId))
                } else if isCurrentlyNear && distance > ProximityConstants.exitDistance {
                    // Exit event (hysteresis deadband of 50pt prevents jitter)
                    petProximityStates[petId] = false
                    emit(EnvironmentEvent(type: .cursorDeparted, timestamp: now, targetPetId: petId))
                }
            }
        }
    }
    
    // MARK: - Direct User Interaction Feeder
    
    public func recordUserInteraction(type: UserInteractionType = .hover, petId: UUID? = nil) {
        let now = nowProvider()
        let wasInactive = snapshot.isUserInactive
        snapshot.lastUserInteractionTime = now
        snapshot.isUserInactive = false
        snapshot.currentInactivityThreshold = nil
        lastEmittedThreshold = nil
        
        guard isEnabled else { return }
        if wasInactive {
            emit(EnvironmentEvent(type: .userReturned, timestamp: now, targetPetId: petId))
        }
        emit(EnvironmentEvent(type: .userInteracted(type: type), timestamp: now, targetPetId: petId))
    }
    
    public func emit(_ event: EnvironmentEvent) {
        if Thread.isMainThread {
            self.onEvent?(event)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onEvent?(event)
            }
        }
    }
    
    public func resetDefaults() {
        isEnabled = true
        appAwarenessEnabled = true
        cursorTrackingEnabled = true
        inactivityTrackingEnabled = true
        reactionFrequency = 0.6
    }
}
