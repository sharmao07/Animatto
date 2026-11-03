import Foundation
import AppKit
import SwiftUI
import Combine

// MARK: - Native Desktop Aquarium Widget Panel
public final class AquariumHostingView<Content: View>: NSHostingView<Content> {
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

public final class AquariumPanel: NSPanel {
    public weak var manager: AquariumManager?
    public static let frameAutosaveKey = "com.dev.Animatto.aquarium_widget_frame"
    
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
        self.level = manager.settings.staysOnTop ? .floating : NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.minSize = CGSize(width: 240, height: 140)
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.isMovableByWindowBackground = true
        
        setupOcclusionNotification()
        setupFramePersistence()
    }
    
    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }
    public override var acceptsFirstResponder: Bool { false }
    
    private func setupFramePersistence() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMoveOrResize(_:)),
            name: NSWindow.didMoveNotification,
            object: self
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMoveOrResize(_:)),
            name: NSWindow.didResizeNotification,
            object: self
        )
    }
    
    @objc private func windowDidMoveOrResize(_ notification: Notification) {
        let frameString = NSStringFromRect(self.frame)
        UserDefaults.standard.set(frameString, forKey: Self.frameAutosaveKey)
    }
    
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
    @Published public var foodPellets: [AquariumFoodPellet] = []
    @Published public var cursorLocation: CGPoint? = nil
    @Published public var glassTapLocation: CGPoint? = nil
    
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
            profile: .sunfin,
            initialState: AquaticEntityState(
                position: AquaticVector3D(x: 220, y: 260, z: 0.35),
                velocity: AquaticVector3D(x: 40, y: 5, z: 0),
                heading: 0.1,
                targetDepth: 0.35,
                isFacingRight: true
            )
        )
        
        // 2. Pip - Spotted Pygmy Puffer (Curious Mid-Surface Explorer)
        let pip = AquaticCompanionInstance(
            profile: .puffer,
            initialState: AquaticEntityState(
                position: AquaticVector3D(x: 480, y: 380, z: 0.25),
                velocity: AquaticVector3D(x: -30, y: -2, z: 0),
                heading: .pi - 0.1,
                targetDepth: 0.25,
                isFacingRight: false
            )
        )
        
        // 3. Glow - Neon Ghost Tetra 1 (Schooling Pelagic)
        let glow1 = AquaticCompanionInstance(
            profile: .tetra,
            initialState: AquaticEntityState(
                position: AquaticVector3D(x: 340, y: 200, z: 0.65),
                velocity: AquaticVector3D(x: 55, y: 8, z: 0),
                heading: 0.15,
                targetDepth: 0.65,
                isFacingRight: true
            )
        )
        
        activeCompanions.append(finny)
        activeCompanions.append(pip)
        activeCompanions.append(glow1)
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
            let screen = NSScreen.main ?? NSScreen.screens.first
            let screenFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
            
            // Restore persisted widget frame if valid and on-screen
            var windowRect: NSRect
            if let saved = UserDefaults.standard.string(forKey: AquariumPanel.frameAutosaveKey),
               !saved.isEmpty {
                let parsed = NSRectFromString(saved)
                if parsed.width >= 240 && parsed.height >= 140 && screenFrame.intersects(parsed) {
                    windowRect = parsed
                } else {
                    let originX = max(screenFrame.minX + 40, screenFrame.maxX - dim.width - 40)
                    let originY = screenFrame.minY + 40
                    windowRect = NSRect(x: originX, y: originY, width: dim.width, height: dim.height)
                }
            } else {
                let originX = max(screenFrame.minX + 40, screenFrame.maxX - dim.width - 40)
                let originY = screenFrame.minY + 40
                windowRect = NSRect(x: originX, y: originY, width: dim.width, height: dim.height)
            }
            
            let panel = AquariumPanel(contentRect: windowRect, manager: self)
            let sceneView = AquariumSceneView(manager: self)
            panel.contentView = AquariumHostingView(rootView: sceneView)
            
            // Sync staysOnTop window level
            updateWindowLevel(for: panel)
            
            self.aquariumPanel = panel
        }
        
        updateBounds(dimensions: settings.effectiveDimensions)
        aquariumPanel?.orderFront(nil)
        isVisible = true
        settings.isEnabled = true
        isPaused = false
        
        startSimulationTimer()
        if settings.soundEnabled {
            AudioEngine.shared.startAquariumAmbience(
                aeratorVolume: settings.aeratorVolume,
                waterSoundVolume: settings.waterSoundVolume
            )
        }
    }
    
    public func closeAquarium() {
        aquariumPanel?.orderOut(nil)
        aquariumPanel = nil
        isVisible = false
        settings.isEnabled = false
        stopSimulationTimer()
        AudioEngine.shared.stopAquariumAmbience()
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
            panel.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)) + 1)
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
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            interval = 1.0 / 20.0   // 20 Hz in Low Power Mode
        } else {
            switch settings.qualityMode {
            case .lowPower: interval = 1.0 / 20.0   // 20 Hz
            case .balanced: interval = 1.0 / 30.0   // 30 Hz
            case .highQuality: interval = 1.0 / 60.0 // 60 Hz
            }
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
        AudioEngine.shared.stopAquariumAmbience()
    }
    
    public func resumeFromOcclusion() {
        guard isPaused, isVisible else { return }
        isPaused = false
        startSimulationTimer()
        if settings.soundEnabled {
            AudioEngine.shared.startAquariumAmbience(
                aeratorVolume: settings.aeratorVolume,
                waterSoundVolume: settings.waterSoundVolume
            )
        }
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
        
        // 1. Advance Food Pellets Physics & Dissolution
        var pelletIndex = 0
        while pelletIndex < foodPellets.count {
            if !foodPellets[pelletIndex].isSettled {
                foodPellets[pelletIndex].age += dt
                foodPellets[pelletIndex].wobblePhase += dt * foodPellets[pelletIndex].wobbleFreq * (.pi * 2.0)
                let wobbleOffset = sin(foodPellets[pelletIndex].wobblePhase) * 12.0 * dt
                foodPellets[pelletIndex].position.x += wobbleOffset
                foodPellets[pelletIndex].position.y += foodPellets[pelletIndex].velocity.y * dt
                
                // Ground settling on bottom substrate
                let substrateY = currentBounds.minY + 6.0
                if foodPellets[pelletIndex].position.y <= substrateY {
                    foodPellets[pelletIndex].position.y = substrateY
                    foodPellets[pelletIndex].velocity = .zero
                    foodPellets[pelletIndex].isSettled = true
                }
                pelletIndex += 1
            } else {
                // Dissolve settled pellets over 15 seconds
                foodPellets[pelletIndex].dissolveProgress += dt / 15.0
                if foodPellets[pelletIndex].dissolveProgress >= 1.0 {
                    foodPellets.remove(at: pelletIndex)
                } else {
                    pelletIndex += 1
                }
            }
        }
        
        // 2. Step AI & physics for all active companions
        for companion in activeCompanions {
            companion.stepAI(
                bounds: currentBounds,
                allCompanions: activeCompanions,
                pellets: &foodPellets,
                cursorLocation: cursorLocation,
                dt: dt
            )
        }
        
        tickSignal = dt
    }
    
    // MARK: - User Interactions
    
    public func feedAt(point: CGPoint) {
        let tapX = Double(point.x)
        let tapY = currentBounds.maxY - Double(point.y)
        
        // Overfeed protection: max 8 active pellets
        guard foodPellets.count < 8 else {
            // Overfed: spawn gentle bubble ripple instead
            glassTapLocation = point
            return
        }
        
        let count = min(2, 8 - foodPellets.count)
        for i in 0..<count {
            let offset = (Double(i) - 0.5) * 14.0
            let pellet = AquariumFoodPellet(
                position: AquaticVector3D(
                    x: max(currentBounds.minX + 20, min(currentBounds.maxX - 20, tapX + offset)),
                    y: max(currentBounds.minY + 30, tapY),
                    z: Double.random(in: 0.25...0.65)
                ),
                velocity: AquaticVector3D(x: 0, y: -22.0, z: 0)
            )
            foodPellets.append(pellet)
        }
        AudioEngine.shared.playAquariumSound(.feedFlake)
    }
    
    public func tapGlass(at location: CGPoint) {
        glassTapLocation = location
        AudioEngine.shared.playAquariumSound(.glassTap)
        
        let tapX = Double(location.x)
        let tapY = currentBounds.maxY - Double(location.y)
        let tapPoint = AquaticVector3D(x: tapX, y: tapY, z: 0.0)
        
        for companion in activeCompanions {
            let diff = companion.state.position - tapPoint
            let dist = diff.length2D
            if dist < 180.0 {
                let dir = dist > 0.01 ? diff.normalized : AquaticVector3D(x: 1, y: 0, z: 0)
                let impulse = max(40.0, 180.0 - dist) * 1.8
                companion.state.velocity += dir * impulse
                companion.state.isResting = false
                
                if companion.niche == .benthic {
                    // Barnaby retreats into shell
                    companion.transitionAnimation(to: .rest)
                    companion.state.isResting = true
                } else {
                    // Finny, Pip, Glow startle into dart burst
                    companion.dartTimer = 1.5
                    companion.transitionAnimation(to: .dart)
                }
            }
        }
    }
    
    public func feedFlakes(count: Int = 3) {
        let spawnPoint = CGPoint(x: currentBounds.maxX * 0.5, y: 30.0)
        feedAt(point: spawnPoint)
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
            if settings.soundEnabled {
                AudioEngine.shared.updateAquariumAmbienceVolume(
                    aeratorVolume: settings.aeratorVolume,
                    waterSoundVolume: settings.waterSoundVolume
                )
            } else {
                AudioEngine.shared.stopAquariumAmbience()
            }
        }
    }
    
    public func invalidate() {
        stopSimulationTimer()
        AudioEngine.shared.stopAquariumAmbience()
        aquariumPanel?.orderOut(nil)
        aquariumPanel = nil
        isVisible = false
        activeCompanions.removeAll()
        foodPellets.removeAll()
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
