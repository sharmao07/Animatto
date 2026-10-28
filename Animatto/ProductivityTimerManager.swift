import Foundation
import Combine
import SwiftUI
import UserNotifications
import AppKit

// MARK: - Productivity Session Mode
public enum ProductivitySessionMode: Codable, Equatable {
    case countdown(minutes: Int)
    case pomodoro
    case longFocus
    case custom(focusMinutes: Int, breakMinutes: Int)
    
    public var displayName: String {
        switch self {
        case .countdown(let m): return "\(m)m Countdown"
        case .pomodoro: return "Pomodoro (25m / 5m)"
        case .longFocus: return "Long Focus (50m / 10m)"
        case .custom(let f, let b): return "Custom (\(f)m / \(b)m)"
        }
    }
    
    public var focusDuration: TimeInterval {
        switch self {
        case .countdown(let m): return Double(max(1, m) * 60)
        case .pomodoro: return 25.0 * 60.0
        case .longFocus: return 50.0 * 60.0
        case .custom(let f, _): return Double(max(1, min(f, 360)) * 60)
        }
    }
    
    public var breakDuration: TimeInterval {
        switch self {
        case .countdown: return 0.0
        case .pomodoro: return 5.0 * 60.0
        case .longFocus: return 10.0 * 60.0
        case .custom(_, let b): return Double(max(1, min(b, 120)) * 60)
        }
    }
    
    public var hasBreak: Bool {
        switch self {
        case .countdown: return false
        case .pomodoro, .longFocus, .custom: return true
        }
    }
}

// MARK: - Productivity Session Phase
public enum ProductivitySessionPhase: String, Codable, Equatable {
    case idle
    case focus
    case breakTime
    case completed
    
    public var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .focus: return "Focus Session"
        case .breakTime: return "Break Time"
        case .completed: return "Completed"
        }
    }
}

// MARK: - Companion Focus Behavior
public enum FocusCompanionBehavior: String, Codable, CaseIterable {
    case sleepQuietly = "sleep"
    case sitIdle = "idle"
    case normal = "normal"
    
    public var displayName: String {
        switch self {
        case .sleepQuietly: return "Sleep Quietly"
        case .sitIdle: return "Sit Idle"
        case .normal: return "Normal Movement"
        }
    }
}

// MARK: - Productivity Session Persistence Model
public struct ProductivitySessionRecord: Codable {
    public var mode: ProductivitySessionMode
    public var phase: ProductivitySessionPhase
    public var isPaused: Bool
    public var targetDeadline: Date?
    public var remainingSeconds: TimeInterval
    public var totalSeconds: TimeInterval
    public var generationId: UUID
    public var savedAt: Date
}

// MARK: - Productivity Timer Manager
public class ProductivityTimerManager: ObservableObject {
    public static let shared = ProductivityTimerManager()
    
    // Injectable dependencies for deterministic unit testing
    public var nowProvider: () -> Date = { Date() }
    public var notificationHandler: ((_ title: String, _ body: String, _ timeInterval: TimeInterval, _ id: UUID) -> Void)?
    public var alertSoundHandler: (() -> Void)?
    public var onPhaseChange: ((ProductivitySessionPhase, ProductivitySessionMode) -> Void)?
    public var onTimerComplete: ((ProductivitySessionMode) -> Void)?
    
    // Settings & State
    @Published public var currentMode: ProductivitySessionMode = .pomodoro
    @Published public var currentPhase: ProductivitySessionPhase = .idle
    @Published public var isPaused: Bool = false
    @Published public var remainingSeconds: TimeInterval = 0
    @Published public var totalSeconds: TimeInterval = 0
    @Published public var generationId: UUID = UUID()
    
    // User Configuration
    @Published public var soundEnabled: Bool = true
    @Published public var notificationsEnabled: Bool = true
    @Published public var speechDialogueEnabled: Bool = true
    @Published public var companionFocusBehavior: FocusCompanionBehavior = .sleepQuietly
    @Published public var customFocusMinutes: Int = 25
    @Published public var customBreakMinutes: Int = 5
    
    // Internal timing
    private var targetDeadline: Date?
    private var timerPublisher: AnyCancellable?
    private let lock = NSLock()
    private let storageKey = "com.dev.Animatto.productivity_session"
    
    public init() {
        loadPersistedState()
        setupSystemObservers()
    }
    
    deinit {
        timerPublisher?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Computed Properties
    
    public var isFocusActive: Bool {
        return currentPhase == .focus && !isPaused
    }
    
    public var isBreakActive: Bool {
        return currentPhase == .breakTime && !isPaused
    }
    
    public var progress: Double {
        guard totalSeconds > 0 else { return 0.0 }
        let elapsed = max(0, totalSeconds - remainingSeconds)
        return min(max(elapsed / totalSeconds, 0.0), 1.0)
    }
    
    public var formattedRemainingTime: String {
        let secs = max(0, Int(remainingSeconds.rounded()))
        let m = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    // MARK: - Lifecycle Control (Start, Pause, Resume, Skip, Stop, Restart)
    
    public func start(mode: ProductivitySessionMode) {
        lock.lock()
        currentMode = mode
        currentPhase = .focus
        isPaused = false
        
        let duration = mode.focusDuration
        totalSeconds = duration
        remainingSeconds = duration
        
        let gen = UUID()
        generationId = gen
        
        let now = nowProvider()
        targetDeadline = now.addingTimeInterval(duration)
        lock.unlock()
        
        scheduleNotification(
            title: "Focus Session Finished",
            body: mode.hasBreak ? "Great work! Time for a short break." : "Timer finished!",
            duration: duration,
            id: gen
        )
        
        startTimerLoop()
        savePersistedState()
        onPhaseChange?(.focus, mode)
    }
    
    public func pause() {
        guard currentPhase == .focus || currentPhase == .breakTime else { return }
        guard !isPaused else { return }
        
        lock.lock()
        isPaused = true
        // Compute precise remaining time against deadline
        if let deadline = targetDeadline {
            remainingSeconds = max(0, deadline.timeIntervalSince(nowProvider()))
        }
        targetDeadline = nil
        let gen = generationId
        lock.unlock()
        
        cancelScheduledNotification(id: gen)
        stopTimerLoop()
        savePersistedState()
    }
    
    public func resume() {
        guard currentPhase == .focus || currentPhase == .breakTime else { return }
        guard isPaused else { return }
        
        lock.lock()
        isPaused = false
        let now = nowProvider()
        targetDeadline = now.addingTimeInterval(remainingSeconds)
        let gen = generationId
        let rem = remainingSeconds
        lock.unlock()
        
        if rem > 0 {
            let title = (currentPhase == .focus) ? "Focus Session Finished" : "Break Finished"
            let body = (currentPhase == .focus) ? "Focus completed!" : "Break is over! Ready to focus?"
            scheduleNotification(title: title, body: body, duration: rem, id: gen)
        }
        
        startTimerLoop()
        savePersistedState()
    }
    
    public func skip() {
        lock.lock()
        let oldGen = generationId
        guard currentPhase == .focus || currentPhase == .breakTime else {
            lock.unlock()
            return
        }
        lock.unlock()
        
        cancelScheduledNotification(id: oldGen)
        
        if currentPhase == .focus && currentMode.hasBreak {
            transitionToBreak()
        } else if currentPhase == .breakTime {
            transitionToFocus()
        } else {
            completeSession()
        }
    }
    
    public func stop() {
        lock.lock()
        let oldGen = generationId
        currentPhase = .idle
        isPaused = false
        remainingSeconds = 0
        totalSeconds = 0
        targetDeadline = nil
        generationId = UUID()
        lock.unlock()
        
        cancelScheduledNotification(id: oldGen)
        stopTimerLoop()
        clearPersistedState()
        onPhaseChange?(.idle, currentMode)
    }
    
    public func restart() {
        let mode = currentMode
        stop()
        start(mode: mode)
    }
    
    // MARK: - Tick Update
    
    public func tick() {
        guard (currentPhase == .focus || currentPhase == .breakTime), !isPaused else { return }
        guard let deadline = targetDeadline else { return }
        
        let now = nowProvider()
        let remaining = max(0, deadline.timeIntervalSince(now))
        
        lock.lock()
        remainingSeconds = remaining
        lock.unlock()
        
        if remaining <= 0 {
            handleDeadlineReached()
        }
    }
    
    private func handleDeadlineReached() {
        if currentPhase == .focus {
            if currentMode.hasBreak {
                fireCompletionFeedback(isFocusSession: true)
                transitionToBreak()
            } else {
                fireCompletionFeedback(isFocusSession: true)
                completeSession()
            }
        } else if currentPhase == .breakTime {
            fireCompletionFeedback(isFocusSession: false)
            transitionToFocus()
        }
    }
    
    private func transitionToBreak() {
        lock.lock()
        currentPhase = .breakTime
        isPaused = false
        let duration = currentMode.breakDuration
        totalSeconds = duration
        remainingSeconds = duration
        let gen = UUID()
        generationId = gen
        let now = nowProvider()
        targetDeadline = now.addingTimeInterval(duration)
        let mode = currentMode
        lock.unlock()
        
        scheduleNotification(
            title: "Break Finished",
            body: "Your break is over. Time to get back to work!",
            duration: duration,
            id: gen
        )
        
        startTimerLoop()
        savePersistedState()
        onPhaseChange?(.breakTime, mode)
    }
    
    private func transitionToFocus() {
        lock.lock()
        currentPhase = .focus
        isPaused = false
        let duration = currentMode.focusDuration
        totalSeconds = duration
        remainingSeconds = duration
        let gen = UUID()
        generationId = gen
        let now = nowProvider()
        targetDeadline = now.addingTimeInterval(duration)
        let mode = currentMode
        lock.unlock()
        
        scheduleNotification(
            title: "Focus Session Finished",
            body: currentMode.hasBreak ? "Focus complete! Time for a break." : "Timer finished!",
            duration: duration,
            id: gen
        )
        
        startTimerLoop()
        savePersistedState()
        onPhaseChange?(.focus, mode)
    }
    
    private func completeSession() {
        lock.lock()
        currentPhase = .completed
        isPaused = false
        remainingSeconds = 0
        targetDeadline = nil
        let mode = currentMode
        lock.unlock()
        
        stopTimerLoop()
        clearPersistedState()
        onTimerComplete?(mode)
        onPhaseChange?(.completed, mode)
    }
    
    // MARK: - Feedback (Notifications, Audio, Speech)
    
    private func fireCompletionFeedback(isFocusSession: Bool) {
        // Sound chime
        if soundEnabled {
            if let customSound = alertSoundHandler {
                customSound()
            } else {
                NSSound.beep()
            }
        }
    }
    
    private func scheduleNotification(title: String, body: String, duration: TimeInterval, id: UUID) {
        guard notificationsEnabled, duration > 0 else { return }
        
        if let customHandler = notificationHandler {
            customHandler(title, body, duration, id)
            return
        }
        
        guard Bundle.main.bundleIdentifier != nil else { return }
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = soundEnabled ? .default : nil
        content.userInfo = ["generationId": id.uuidString]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(
            identifier: "animatto_timer_\(id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error.localizedDescription)")
            }
        }
    }
    
    private func cancelScheduledNotification(id: UUID) {
        if let customHandler = notificationHandler {
            customHandler("", "", 0, id) // Signal cancellation
            return
        }
        guard Bundle.main.bundleIdentifier != nil else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["animatto_timer_\(id.uuidString)"])
    }
    
    // MARK: - Timer Loop
    
    private func startTimerLoop() {
        timerPublisher?.cancel()
        timerPublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func stopTimerLoop() {
        timerPublisher?.cancel()
        timerPublisher = nil
    }
    
    // MARK: - Sleep & Wake Handling
    
    private func setupSystemObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    @objc public func systemDidWake() {
        guard !isPaused, let deadline = targetDeadline else { return }
        let now = nowProvider()
        if now >= deadline {
            // Deadline elapsed during system sleep
            handleDeadlineReached()
        } else {
            remainingSeconds = max(0, deadline.timeIntervalSince(now))
        }
    }
    
    @objc private func applicationWillTerminate() {
        savePersistedState()
    }
    
    // MARK: - State Persistence Across App Launches
    
    public func savePersistedState() {
        guard currentPhase == .focus || currentPhase == .breakTime else {
            clearPersistedState()
            return
        }
        
        let record = ProductivitySessionRecord(
            mode: currentMode,
            phase: currentPhase,
            isPaused: isPaused,
            targetDeadline: targetDeadline,
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            generationId: generationId,
            savedAt: nowProvider()
        )
        
        if let data = try? JSONEncoder().encode(record) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    public func loadPersistedState() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let record = try? JSONDecoder().decode(ProductivitySessionRecord.self, from: data) else {
            return
        }
        
        currentMode = record.mode
        currentPhase = record.phase
        isPaused = record.isPaused
        totalSeconds = record.totalSeconds
        generationId = record.generationId
        
        let now = nowProvider()
        if record.isPaused {
            remainingSeconds = record.remainingSeconds
            targetDeadline = nil
        } else if let deadline = record.targetDeadline {
            if now >= deadline {
                // Session elapsed while application was closed
                currentPhase = .completed
                remainingSeconds = 0
                targetDeadline = nil
                clearPersistedState()
            } else {
                remainingSeconds = max(0, deadline.timeIntervalSince(now))
                targetDeadline = deadline
                startTimerLoop()
            }
        }
    }
    
    public func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
