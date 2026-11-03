import Foundation
import AppKit
import SwiftUI
import Combine

// MARK: - Dedicated Resizable Aquarium Panel
public final class AquariumPanel: NSPanel {
    public weak var manager: AquariumManager?
    
    public init(contentRect: NSRect, manager: AquariumManager) {
        self.manager = manager
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isReleasedWhenClosed = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.floatingWindow)) - 1)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.minSize = CGSize(width: 320, height: 240)
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        
        setupOcclusionNotification()
    }
    
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { false }
    
    private func setupOcclusionNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowOcclusionDidChange(_:)),
            name: NSWindow.didChangeOcclusionStateNotification,
            object: self
        )
    }
    
    @objc private func windowOcclusionDidChange(_ notification: Notification) {
        guard let manager = manager else { return }
        let isVisibleOnScreen = self.occlusionState.contains(.visible)
        if isVisibleOnScreen {
            manager.resumeFromOcclusion()
        } else {
            manager.pauseDueToOcclusion()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Aquarium Manager & Window Host
public final class AquariumManager: ObservableObject {
    public static let shared = AquariumManager()
    
    // Published State
    @Published public var settings: AquariumSettings {
        didSet {
            handleSettingsChanged()
            saveSettings()
        }
    }
    
    @Published public var isVisible: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var tickSignal: TimeInterval = 0.033
    @Published public var activeCompanions: [AquaticCompanionInstance] = []
    
    public private(set) var aquariumPanel: AquariumPanel?
    public private(set) var currentBounds: AquaticBounds = AquaticBounds(minX: 0, maxX: 720, minY: 0, maxY: 480)
    
    private var simulationTimer: Timer?
    private var lastTickTimestamp: TimeInterval = 0.0
    private let userDefaultsKey = "com.dev.Animatto.aquarium_settings"
    private var cancellables = Set<AnyCancellable>()
    
    public init(initialSettings: AquariumSettings? = nil) {
        if let initial = initialSettings {
            self.settings = initial
        } else {
            self.settings = AquariumManager.loadPersistedSettings() ?? AquariumSettings()
        }
        
        // Enforce desktop overlay feature flag guard
        enforceDesktopOverlayFeatureFlag()
        
        setupDefaultCompanions()
        setupSystemObservers()
        updateBounds(dimensions: settings.effectiveDimensions)
    }
    
    deinit {
        invalidate()
    }
    
    // MARK: - Persistence
    
    private static func loadPersistedSettings() -> AquariumSettings? {
        guard let data = UserDefaults.standard.data(forKey: "com.dev.Animatto.aquarium_settings") else {
            return nil
        }
        return try? JSONDecoder().decode(AquariumSettings.self, from: data)
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - Feature Flag Enforcement
    
    private func enforceDesktopOverlayFeatureFlag() {
        if settings.presentationMode == .desktopOverlay && !AquariumSettings.isDesktopOverlayModeEnabled {
            NSLog("[AquariumManager] Desktop Overlay mode is disabled by feature flag. Reverting to dedicated tank window.")
            settings.presentationMode = .dedicatedWindow
        }
    }
    
    // MARK: - Companion Management
    
    public func setupDefaultCompanions() {
        activeCompanions.removeAll()
        
        // 1. Finny - Golden Sunfin (Pelagic Cruiser)
        let finny = AquaticCompanionInstance(
            speciesId: "animatto.creature.sunfin",
            displayName: "Finny",
            niche: .pelagic,
            initialState: AquaticEntityState(
                position: AquaticVector3D(x: 220, y: 260, z: 0.35),
                velocity: AquaticVector3D(x: 40, y: 5, z: 0),
                heading: 0.1,
                targetDepth: 0.35,
                isFacingRight: true
            ),
            physicsConfig: .pelagicDefault
        )
        
        // 2. Pip - Spotted Pygmy Puffer (Curious Mid-Surface Explorer)
        let pip = AquaticCompanionInstance(
            speciesId: "animatto.creature.puffer",
            displayName: "Pip",
            niche: .surface,
            initialState: AquaticEntityState(
                position: AquaticVector3D(x: 480, y: 380, z: 0.25),
                velocity: AquaticVector3D(x: -30, y: -2, z: 0),
                heading: .pi - 0.1,
                targetDepth: 0.25,
                isFacingRight: false
            ),
            physicsConfig: AquaticPhysicsConfig(
                dragCoefficient: 0.08,
                linearDrag: 1.1,
                buoyancyStiffness: 5.5,
                depthDamping: 2.8,
                boundaryRepulsionStiffness: 450.0,
                maxSpeed: 110.0,
                maxTurnRate: .pi * 1.2,
                maxBankingAngle: 12.0
            )
        )
        
        // 3. Glow - Neon Ghost Tetra (Deep Background Schooling)
        let glow = AquaticCompanionInstance(
            speciesId: "animatto.creature.tetra",
            displayName: "Glow",
            niche: .pelagic,
            initialState: AquaticEntityState(
                position: AquaticVector3D(x: 340, y: 200, z: 0.75),
                velocity: AquaticVector3D(x: 55, y: 8, z: 0),
                heading: 0.15,
                targetDepth: 0.75,
                isFacingRight: true
            ),
            physicsConfig: .pelagicDefault
        )
        
        activeCompanions.append(finny)
        activeCompanions.append(pip)
        activeCompanions.append(glow)
    }
    
    public func addCompanion(_ companion: AquaticCompanionInstance) {
        guard activeCompanions.count < settings.maxCreatureCount else { return }
        activeCompanions.append(companion)
    }
    
    public func removeCompanion(id: UUID) {
        activeCompanions.removeAll { $0.id == id }
    }
    
    // MARK: - Window Hosting Lifecycle
    
    public func showAquarium() {
        enforceDesktopOverlayFeatureFlag()
        
        if aquariumPanel == nil {
            let dim = settings.effectiveDimensions
            let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
            let originX = screenFrame.midX - (dim.width / 2.0)
            let originY = screenFrame.midY - (dim.height / 2.0)
            let windowRect = NSRect(x: originX, y: originY, width: dim.width, height: dim.height)
            
            let panel = AquariumPanel(contentRect: windowRect, manager: self)
            let sceneView = AquariumSceneView(manager: self)
            panel.contentView = NSHostingView(rootView: sceneView)
            
            // Sync staysOnTop window level
            updateWindowLevel(for: panel)
            
            self.aquariumPanel = panel
        }
        
        updateBounds(dimensions: settings.effectiveDimensions)
        aquariumPanel?.makeKeyAndOrderFront(nil)
        isVisible = true
        settings.isEnabled = true
        isPaused = false
        
        startSimulationTimer()
    }
    
    public func closeAquarium() {
        aquariumPanel?.orderOut(nil)
        aquariumPanel = nil
        isVisible = false
        settings.isEnabled = false
        stopSimulationTimer()
    }
    
    public func toggleAquarium() {
        if isVisible {
            closeAquarium()
        } else {
            showAquarium()
        }
    }
    
    public func toggleStaysOnTop() {
        settings.staysOnTop.toggle()
        if let panel = aquariumPanel {
            updateWindowLevel(for: panel)
        }
    }
    
    private func updateWindowLevel(for panel: AquariumPanel) {
        if settings.staysOnTop {
            panel.level = .floating
        } else {
            panel.level = NSWindow.Level(Int(CGWindowLevelForKey(.floatingWindow)) - 1)
        }
    }
    
    public func applyPreset(_ preset: TankSizePreset) {
        settings.tankSizePreset = preset
        let dim = preset.defaultDimensions
        settings.customWidth = dim.width
        settings.customHeight = dim.height
        
        updateBounds(dimensions: dim)
        
        if let panel = aquariumPanel {
            var currentFrame = panel.frame
            currentFrame.size = dim
            panel.setFrame(currentFrame, display: true, animate: true)
        }
    }
    
    public func updateBounds(dimensions: CGSize) {
        currentBounds = AquaticBounds(
            minX: 0.0,
            maxX: Double(dimensions.width),
            minY: 0.0,
            maxY: Double(dimensions.height),
            minZ: 0.0,
            maxZ: 1.0,
            margin: 48.0
        )
    }
    
    // MARK: - Simulation Loop & Power Management
    
    public func startSimulationTimer() {
        stopSimulationTimer()
        lastTickTimestamp = ProcessInfo.processInfo.systemUptime
        
        let interval: TimeInterval
        switch settings.qualityMode {
        case .lowPower: interval = 1.0 / 20.0   // 20 Hz
        case .balanced: interval = 1.0 / 30.0   // 30 Hz
        case .highQuality: interval = 1.0 / 60.0 // 60 Hz
        }
        
        simulationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tickSimulation()
        }
        RunLoop.main.add(simulationTimer!, forMode: .common)
    }
    
    public func stopSimulationTimer() {
        simulationTimer?.invalidate()
        simulationTimer = nil
    }
    
    public func pauseDueToOcclusion() {
        guard !isPaused else { return }
        isPaused = true
        stopSimulationTimer()
    }
    
    public func resumeFromOcclusion() {
        guard isPaused, isVisible else { return }
        isPaused = false
        startSimulationTimer()
    }
    
    private func tickSimulation() {
        guard isVisible, !isPaused else { return }
        
        let now = ProcessInfo.processInfo.systemUptime
        let dt = min(now - lastTickTimestamp, AquaticPhysicsSimulator.maxDeltaTimeClamp)
        lastTickTimestamp = now
        
        guard dt >= AquaticPhysicsSimulator.minDeltaTime else { return }
        
        // Sync bounds if window frame was resized by user
        if let panel = aquariumPanel {
            let panelSize = panel.frame.size
            if abs(panelSize.width - currentBounds.maxX) > 1.0 || abs(panelSize.height - currentBounds.maxY) > 1.0 {
                updateBounds(dimensions: panelSize)
            }
        }
        
        // Step physics for all active companions
        for companion in activeCompanions {
            companion.stepPhysics(bounds: currentBounds, dt: dt)
        }
        
        tickSignal = dt
    }
    
    // MARK: - User Interactions
    
    public func tapGlass(at location: CGPoint) {
        // Scatter nearby companions away from tap location
        // Convert location: SwiftUI (Y=0 top) to Aquatic coordinates (Y=0 bottom)
        let tapX = Double(location.x)
        let tapY = currentBounds.maxY - Double(location.y)
        let tapPoint = AquaticVector3D(x: tapX, y: tapY, z: 0.0)
        
        for companion in activeCompanions {
            let diff = companion.state.position - tapPoint
            let dist = diff.length2D
            if dist < 160.0 {
                let dir = diff.normalized
                let impulse = max(30.0, 160.0 - dist) * 1.5
                companion.state.velocity += dir * impulse
                companion.state.isResting = false
            }
        }
    }
    
    public func feedFlakes(count: Int = 3) {
        // Stimulate active companions to steer upward toward surface
        for companion in activeCompanions where companion.niche != .benthic {
            companion.targetWaypoint = AquaticVector3D(
                x: Double.random(in: (currentBounds.minX + 60)...(currentBounds.maxX - 60)),
                y: currentBounds.maxY - 15.0,
                z: Double.random(in: 0.1...0.4)
            )
            companion.state.isResting = false
        }
    }
    
    // MARK: - Observers & Cleanup
    
    private func setupSystemObservers() {
        let center = NotificationCenter.default
        let ws = NSWorkspace.shared.notificationCenter
        
        // Sleep & Wake power conservation
        ws.addObserver(
            self,
            selector: #selector(screensDidSleep),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
        ws.addObserver(
            self,
            selector: #selector(screensDidWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
        
        // Screen resolution or display configuration changes
        center.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        // Reduced motion accessibility
        ws.addObserver(
            self,
            selector: #selector(accessibilityReducedMotionChanged),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil
        )
        
        // Initial accessibility sync
        settings.reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
    
    @objc private func screensDidSleep() {
        pauseDueToOcclusion()
    }
    
    @objc private func screensDidWake() {
        if isVisible {
            resumeFromOcclusion()
        }
    }
    
    @objc private func screenParametersChanged() {
        guard let panel = aquariumPanel, let screen = panel.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        var panelFrame = panel.frame
        
        // Ensure panel remains visible on screen
        if panelFrame.maxX < visible.minX + 50 {
            panelFrame.origin.x = visible.minX + 20
        }
        if panelFrame.minX > visible.maxX - 50 {
            panelFrame.origin.x = visible.maxX - panelFrame.width - 20
        }
        if panelFrame.maxY < visible.minY + 50 {
            panelFrame.origin.y = visible.minY + 20
        }
        if panelFrame.minY > visible.maxY - 50 {
            panelFrame.origin.y = visible.maxY - panelFrame.height - 20
        }
        
        panel.setFrame(panelFrame, display: true)
    }
    
    @objc private func accessibilityReducedMotionChanged() {
        settings.reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
    
    private func handleSettingsChanged() {
        enforceDesktopOverlayFeatureFlag()
        
        if let panel = aquariumPanel {
            updateWindowLevel(for: panel)
        }
        
        if isVisible && !isPaused {
            startSimulationTimer()
        }
    }
    
    public func invalidate() {
        stopSimulationTimer()
        aquariumPanel?.orderOut(nil)
        aquariumPanel = nil
        isVisible = false
        activeCompanions.removeAll()
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
