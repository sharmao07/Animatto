import Foundation
import AppKit
import SwiftUI
import Combine

// MARK: - Ambient Particle Engine
public class AmbientEngine: ObservableObject {
    public static let shared = AmbientEngine()
    
    // User Configuration
    @Published public var isEnabled: Bool = false {
        didSet {
            handleEnableStateChange()
            savePreferences()
        }
    }
    
    @Published public var currentEnvironment: AmbientEnvironmentType = .rain {
        didSet {
            rebuildParticles()
            savePreferences()
            notifyEnvironmentChanged()
        }
    }
    
    @Published public var intensity: Double = 0.5 {
        didSet {
            rebuildParticles()
            savePreferences()
        }
    }
    
    @Published public var windStrength: Double = 0.2 {
        didSet {
            savePreferences()
        }
    }
    
    @Published public var qualityMode: AmbientQualityMode = .balanced {
        didSet {
            rebuildParticles()
            restartSimulationTimer()
            savePreferences()
        }
    }
    
    @Published public var activePresetKey: String = "rainy_evening"
    @Published public var isPaused: Bool = false
    @Published public var isTimeScheduleEnabled: Bool = false
    @Published public var customPresets: [AtmospherePreset] = []
    
    // Active Particles
    @Published public private(set) var activeParticles: [AmbientParticle] = []
    
    // Screen bounds provider for deterministic testing
    public var screenBoundsProvider: () -> CGRect = {
        NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }
    
    // Reduced motion provider
    public var reducedMotionProvider: () -> Bool = {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
    
    private var simulationTimer: Timer?
    private var scheduleTimer: Timer?
    private var overlayPanels: [NSPanel] = []
    private let lock = NSLock()
    
    private let prefsKey = "com.dev.Animatto.ambient_settings"
    private let customPresetsKey = "com.dev.Animatto.custom_presets"
    
    public init() {
        loadPreferences()
        loadCustomPresets()
        setupTimeBasedSchedule()
    }
    
    deinit {
        stopSimulation()
        dismissOverlayPanels()
    }
    
    // MARK: - Lifecycle Controls
    
    private func handleEnableStateChange() {
        if isEnabled && !isPaused {
            rebuildParticles()
            restartSimulationTimer()
            createOrUpdateOverlayPanels()
        } else {
            stopSimulation()
            dismissOverlayPanels()
            lock.lock()
            activeParticles.removeAll()
            lock.unlock()
        }
    }
    
    public func pause() {
        isPaused = true
        simulationTimer?.invalidate()
        simulationTimer = nil
        dismissOverlayPanels()
    }
    
    public func resume() {
        isPaused = false
        if isEnabled {
            rebuildParticles()
            restartSimulationTimer()
            createOrUpdateOverlayPanels()
        }
    }
    
    public func restoreDefaults() {
        isEnabled = false
        currentEnvironment = .rain
        intensity = 0.5
        windStrength = 0.2
        qualityMode = .balanced
        activePresetKey = "rainy_evening"
        isPaused = false
        isTimeScheduleEnabled = false
        applyPreset(presetKey: "rainy_evening")
    }
    
    // MARK: - Particle Generation & Simulation
    
    public func rebuildParticles() {
        lock.lock()
        defer { lock.unlock() }
        
        guard isEnabled && !isPaused else {
            activeParticles.removeAll()
            return
        }
        
        let bounds = screenBoundsProvider()
        let maxCount = qualityMode.maxParticles
        let targetCount = Int(Double(maxCount) * max(intensity, 0.15))
        let isReducedMotion = reducedMotionProvider()
        
        var newParticles: [AmbientParticle] = []
        newParticles.reserveCapacity(targetCount)
        
        for i in 0..<targetCount {
            let layer = (i % 3 == 0) ? 1 : 0 // 1/3 foreground, 2/3 background
            let p = createParticle(in: bounds, layer: layer, reducedMotion: isReducedMotion)
            newParticles.append(p)
        }
        
        self.activeParticles = newParticles
    }
    
    private func createParticle(in bounds: CGRect, layer: Int, reducedMotion: Bool) -> AmbientParticle {
        let x = CGFloat.random(in: bounds.minX...bounds.maxX)
        let y = CGFloat.random(in: bounds.minY...bounds.maxY)
        let layerScale: CGFloat = (layer == 1) ? 1.3 : 0.75
        let motionDamping: CGFloat = reducedMotion ? 0.35 : 1.0
        
        let vx: CGFloat
        let vy: CGFloat
        let size: CGFloat
        let opacity: CGFloat
        let rotSpeed: CGFloat
        
        switch currentEnvironment {
        case .rain:
            vx = (CGFloat(windStrength) * 3.0) * motionDamping
            vy = -(CGFloat.random(in: 12.0...22.0) * layerScale) * motionDamping
            size = (layer == 1) ? 3.0 : 1.8
            opacity = (layer == 1) ? 0.65 : 0.35
            rotSpeed = 0
            
        case .snow:
            vx = (CGFloat(windStrength) * 2.0 + CGFloat.random(in: -0.6...0.6)) * motionDamping
            vy = -(CGFloat.random(in: 1.8...4.2) * layerScale) * motionDamping
            size = CGFloat.random(in: 3.0...6.5) * layerScale
            opacity = CGFloat.random(in: 0.4...0.85)
            rotSpeed = CGFloat.random(in: -0.05...0.05) * motionDamping
            
        case .fog:
            vx = (CGFloat(windStrength) * 0.8 + 0.4) * motionDamping
            vy = CGFloat.random(in: -0.15...0.15)
            size = CGFloat.random(in: 80.0...160.0) * layerScale
            opacity = CGFloat.random(in: 0.08...0.22) * CGFloat(intensity)
            rotSpeed = CGFloat.random(in: -0.01...0.01)
            
        case .sunlight:
            vx = (CGFloat(windStrength) * 0.3) * motionDamping
            vy = CGFloat.random(in: -0.3...0.3) * motionDamping
            size = CGFloat.random(in: 40.0...110.0) * layerScale
            opacity = CGFloat.random(in: 0.12...0.28) * CGFloat(intensity)
            rotSpeed = 0
            
        case .wind:
            vx = (CGFloat(windStrength) * 14.0 + CGFloat.random(in: 2.0...6.0)) * motionDamping
            vy = CGFloat.random(in: -1.2...1.2) * motionDamping
            size = CGFloat.random(in: 20.0...50.0)
            opacity = CGFloat.random(in: 0.15...0.35)
            rotSpeed = 0
            
        case .fallingLeaves:
            vx = (CGFloat(windStrength) * 4.5 + CGFloat.random(in: -1.0...1.0)) * motionDamping
            vy = -(CGFloat.random(in: 1.5...3.8) * layerScale) * motionDamping
            size = CGFloat.random(in: 10.0...18.0) * layerScale
            opacity = CGFloat.random(in: 0.7...0.95)
            rotSpeed = CGFloat.random(in: -0.08...0.08) * motionDamping
        }
        
        return AmbientParticle(
            x: x,
            y: y,
            vx: vx,
            vy: vy,
            size: size,
            opacity: opacity,
            rotation: CGFloat.random(in: 0...(2 * .pi)),
            rotationSpeed: rotSpeed,
            layer: layer,
            environment: currentEnvironment
        )
    }
    
    public func tick() {
        lock.lock()
        defer { lock.unlock() }
        
        guard isEnabled && !isPaused else { return }
        let bounds = screenBoundsProvider()
        
        for i in 0..<activeParticles.count {
            activeParticles[i].x += activeParticles[i].vx
            activeParticles[i].y += activeParticles[i].vy
            activeParticles[i].rotation += activeParticles[i].rotationSpeed
            
            // Boundary wrapping
            if activeParticles[i].y < bounds.minY - 30 {
                activeParticles[i].y = bounds.maxY + 20
                activeParticles[i].x = CGFloat.random(in: bounds.minX...bounds.maxX)
            } else if activeParticles[i].y > bounds.maxY + 30 {
                activeParticles[i].y = bounds.minY - 20
                activeParticles[i].x = CGFloat.random(in: bounds.minX...bounds.maxX)
            }
            
            if activeParticles[i].x < bounds.minX - 50 {
                activeParticles[i].x = bounds.maxX + 40
            } else if activeParticles[i].x > bounds.maxX + 50 {
                activeParticles[i].x = bounds.minX - 40
            }
        }
    }
    
    private func restartSimulationTimer() {
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: qualityMode.frameInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
    }
    
    // MARK: - Preset Management
    
    public func applyPreset(presetKey: String) {
        if let builtIn = AtmospherePreset.builtInPresets.first(where: { $0.presetKey == presetKey }) {
            applyPresetDirect(builtIn)
            return
        }
        if let custom = customPresets.first(where: { $0.presetKey == presetKey }) {
            applyPresetDirect(custom)
            return
        }
    }
    
    public func applyPresetDirect(_ preset: AtmospherePreset) {
        self.activePresetKey = preset.presetKey
        self.currentEnvironment = preset.environmentType
        self.intensity = preset.intensity
        self.windStrength = preset.windStrength
        self.qualityMode = preset.qualityMode
        savePreferences()
    }
    
    public func saveCustomPreset(name: String) -> AtmospherePreset {
        let key = "custom_" + UUID().uuidString.prefix(8).lowercased()
        let preset = AtmospherePreset(
            presetKey: String(key),
            name: name,
            environmentType: currentEnvironment,
            intensity: intensity,
            windStrength: windStrength,
            qualityMode: qualityMode,
            companionReactionsAllowed: true,
            isBuiltIn: false
        )
        customPresets.append(preset)
        saveCustomPresets()
        return preset
    }
    
    public func deleteCustomPreset(presetKey: String) {
        customPresets.removeAll { $0.presetKey == presetKey && !$0.isBuiltIn }
        if activePresetKey == presetKey {
            activePresetKey = "rainy_evening"
            applyPreset(presetKey: "rainy_evening")
        }
        saveCustomPresets()
    }
    
    // MARK: - Time-Based Ambience Scheduling
    
    private func setupTimeBasedSchedule() {
        scheduleTimer?.invalidate()
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.evaluateTimeSchedule()
        }
    }
    
    public func evaluateTimeSchedule(referenceDate: Date = Date()) {
        guard isTimeScheduleEnabled && isEnabled else { return }
        let hour = Calendar.current.component(.hour, from: referenceDate)
        
        let targetKey: String
        switch hour {
        case 6..<11:
            targetKey = "golden_morning"
        case 11..<17:
            targetKey = "autumn_window"
        case 17..<21:
            targetKey = "rainy_evening"
        default:
            targetKey = "quiet_night"
        }
        
        if activePresetKey != targetKey {
            applyPreset(presetKey: targetKey)
        }
    }
    
    // MARK: - Desktop Click-Through Transparent Overlay Panels
    
    private func createOrUpdateOverlayPanels() {
        guard isEnabled && !isPaused else { return }
        dismissOverlayPanels()
        
        for screen in NSScreen.screens {
            let panel = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.level = .floating
            panel.ignoresMouseEvents = true // Guarantee click-through for underlying desktop applications!
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            
            let hosting = NSHostingView(rootView: AmbientParticleCanvasView(engine: self, screenFrame: screen.frame))
            panel.contentView = hosting
            panel.orderFrontRegardless()
            overlayPanels.append(panel)
        }
    }
    
    private func dismissOverlayPanels() {
        for panel in overlayPanels {
            panel.orderOut(nil)
        }
        overlayPanels.removeAll()
    }
    
    // MARK: - Companion Integration Notification
    
    private func notifyEnvironmentChanged() {
        EnvironmentMonitor.shared.emit(
            EnvironmentEvent(type: .animattoFocusChanged(isActive: isEnabled))
        )
    }
    
    // MARK: - Persistence
    
    private func savePreferences() {
        let dict: [String: Any] = [
            "isEnabled": isEnabled,
            "currentEnvironment": currentEnvironment.rawValue,
            "intensity": intensity,
            "windStrength": windStrength,
            "qualityMode": qualityMode.rawValue,
            "activePresetKey": activePresetKey,
            "isTimeScheduleEnabled": isTimeScheduleEnabled
        ]
        UserDefaults.standard.set(dict, forKey: prefsKey)
    }
    
    private func loadPreferences() {
        guard let dict = UserDefaults.standard.dictionary(forKey: prefsKey) else { return }
        if let enabled = dict["isEnabled"] as? Bool { self.isEnabled = enabled }
        if let envRaw = dict["currentEnvironment"] as? String, let env = AmbientEnvironmentType(rawValue: envRaw) {
            self.currentEnvironment = env
        }
        if let val = dict["intensity"] as? Double { self.intensity = val }
        if let val = dict["windStrength"] as? Double { self.windStrength = val }
        if let qRaw = dict["qualityMode"] as? String, let q = AmbientQualityMode(rawValue: qRaw) {
            self.qualityMode = q
        }
        if let preset = dict["activePresetKey"] as? String { self.activePresetKey = preset }
        if let sched = dict["isTimeScheduleEnabled"] as? Bool { self.isTimeScheduleEnabled = sched }
    }
    
    private func saveCustomPresets() {
        if let data = try? JSONEncoder().encode(customPresets) {
            UserDefaults.standard.set(data, forKey: customPresetsKey)
        }
    }
    
    private func loadCustomPresets() {
        guard let data = UserDefaults.standard.data(forKey: customPresetsKey),
              let list = try? JSONDecoder().decode([AtmospherePreset].self, from: data) else { return }
        self.customPresets = list
    }
}

// MARK: - SwiftUI Ambient Canvas View
public struct AmbientParticleCanvasView: View {
    @ObservedObject var engine: AmbientEngine
    let screenFrame: CGRect
    
    public init(engine: AmbientEngine, screenFrame: CGRect) {
        self.engine = engine
        self.screenFrame = screenFrame
    }
    
    public var body: some View {
        Canvas { context, size in
            for p in engine.activeParticles {
                let rect = CGRect(
                    x: p.x - p.size / 2,
                    y: size.height - p.y - p.size / 2, // Flip coordinates to AppKit bottom-left
                    width: p.size,
                    height: p.size
                )
                
                context.opacity = Double(p.opacity)
                
                switch p.environment {
                case .rain:
                    let path = Path { pt in
                        pt.move(to: CGPoint(x: rect.midX, y: rect.minY))
                        pt.addLine(to: CGPoint(x: rect.midX - p.vx * 1.5, y: rect.maxY + 10))
                    }
                    context.stroke(path, with: .color(.cyan.opacity(0.7)), lineWidth: p.size)
                    
                case .snow:
                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                    
                case .fog:
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.gray.opacity(0.4))
                    )
                    
                case .sunlight:
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.yellow.opacity(0.35))
                    )
                    
                case .wind:
                    let path = Path { pt in
                        pt.move(to: CGPoint(x: rect.minX, y: rect.midY))
                        pt.addQuadCurve(
                            to: CGPoint(x: rect.maxX, y: rect.midY),
                            control: CGPoint(x: rect.midX, y: rect.midY - 8)
                        )
                    }
                    context.stroke(path, with: .color(.white.opacity(0.4)), lineWidth: 1.5)
                    
                case .fallingLeaves:
                    let leafPath = Path { pt in
                        pt.move(to: CGPoint(x: rect.midX, y: rect.minY))
                        pt.addQuadCurve(
                            to: CGPoint(x: rect.midX, y: rect.maxY),
                            control: CGPoint(x: rect.maxX + 4, y: rect.midY)
                        )
                        pt.addQuadCurve(
                            to: CGPoint(x: rect.midX, y: rect.minY),
                            control: CGPoint(x: rect.minX - 4, y: rect.midY)
                        )
                    }
                    context.fill(leafPath, with: .color(.orange.opacity(0.85)))
                }
            }
        }
        .allowsHitTesting(false) // Click-through guarantee!
        .edgesIgnoringSafeArea(.all)
    }
}
