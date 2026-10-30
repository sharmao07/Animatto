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
            syncAmbientAudio()
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
    
    // Active Particles (Decoupled from @Published to eliminate Combine churn and 60 FPS view re-renders)
    public private(set) var activeParticles: [AmbientParticle] = []
    
    // Distant lightning flash intensity for rainy mode
    public var lightningFlashOpacity: Double = 0.0
    
    private var overlayViews: NSHashTable<NSView> = NSHashTable.weakObjects()
    
    public func registerOverlayView(_ view: NSView) {
        overlayViews.add(view)
    }
    
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
        setupSleepWakeObservers()
    }
    
    deinit {
        stopSimulation()
        dismissOverlayPanels()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Sleep & Wake Power Management
    
    private func setupSleepWakeObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenSleep),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }
    
    @objc private func handleScreenSleep() {
        stopSimulation()
    }
    
    @objc private func handleScreenWake() {
        if isEnabled && !isPaused {
            restartSimulationTimer()
        }
    }
    
    // MARK: - Lifecycle Controls
    
    private func handleEnableStateChange() {
        if isEnabled && !isPaused {
            rebuildParticles()
            restartSimulationTimer()
            createOrUpdateOverlayPanels()
            syncAmbientAudio()
        } else {
            stopSimulation()
            dismissOverlayPanels()
            lock.lock()
            activeParticles.removeAll()
            lock.unlock()
            syncAmbientAudio()
        }
    }
    
    public func pause() {
        isPaused = true
        simulationTimer?.invalidate()
        simulationTimer = nil
        dismissOverlayPanels()
        syncAmbientAudio()
    }
    
    public func resume() {
        isPaused = false
        if isEnabled {
            rebuildParticles()
            restartSimulationTimer()
            createOrUpdateOverlayPanels()
            syncAmbientAudio()
        }
    }
    
    public func syncAmbientAudio() {
        guard isEnabled && !isPaused else {
            AudioEngine.shared.setAmbientEnvironment(nil)
            return
        }
        let audioType: AudioAmbientType
        switch currentEnvironment {
        case .rainyDay, .rain, .cozyCafe:
            audioType = .rainThunder
        case .winterCalm, .snow, .cosmicDream, .wind:
            audioType = .winterWind
        case .enchantedForest, .sakuraGarden, .sunset, .ocean, .fallingLeaves, .sunlight, .fog:
            audioType = .forestBirdsong
        }
        AudioEngine.shared.setAmbientEnvironment(audioType)
    }
    
    public func restoreDefaults() {
        isEnabled = false
        currentEnvironment = .rainyDay
        intensity = 0.5
        windStrength = 0.2
        qualityMode = .balanced
        activePresetKey = "rainy_day"
        isPaused = false
        isTimeScheduleEnabled = false
        applyPreset(presetKey: "rainy_day")
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
        case .rainyDay, .rain:
            vx = (CGFloat(windStrength) * 3.5) * motionDamping
            vy = -(CGFloat.random(in: 14.0...24.0) * layerScale) * motionDamping
            size = (layer == 1) ? 3.5 : 2.0
            opacity = (layer == 1) ? 0.70 : 0.40
            rotSpeed = 0
            
        case .enchantedForest:
            // Floating magical fireflies & gentle forest motes
            vx = (CGFloat(windStrength) * 0.8 + CGFloat.random(in: -0.6...0.6)) * motionDamping
            vy = CGFloat.random(in: -0.8...0.8) * motionDamping
            size = (layer == 1) ? CGFloat.random(in: 4.5...7.5) : CGFloat.random(in: 2.5...4.5)
            opacity = CGFloat.random(in: 0.50...0.95)
            rotSpeed = CGFloat.random(in: -0.02...0.02)
            
        case .winterCalm, .snow:
            vx = (CGFloat(windStrength) * 2.0 + CGFloat.random(in: -0.6...0.6)) * motionDamping
            vy = -(CGFloat.random(in: 1.8...4.2) * layerScale) * motionDamping
            size = CGFloat.random(in: 3.0...6.5) * layerScale
            opacity = CGFloat.random(in: 0.4...0.85)
            rotSpeed = CGFloat.random(in: -0.05...0.05) * motionDamping
            
        case .sunset:
            // Warm lighting & drifting clouds
            vx = (CGFloat(windStrength) * 1.5 + 0.4) * motionDamping
            vy = CGFloat.random(in: -0.2...0.2) * motionDamping
            size = CGFloat.random(in: 50.0...120.0) * layerScale
            opacity = CGFloat.random(in: 0.12...0.26) * CGFloat(intensity)
            rotSpeed = 0
            
        case .cosmicDream:
            // Stars & nebula dust particles
            vx = (CGFloat(windStrength) * 0.3 + CGFloat.random(in: -0.25...0.25)) * motionDamping
            vy = CGFloat.random(in: -0.25...0.25) * motionDamping
            size = CGFloat.random(in: 2.2...5.5) * layerScale
            opacity = CGFloat.random(in: 0.35...0.95)
            rotSpeed = CGFloat.random(in: -0.01...0.01)
            
        case .sakuraGarden:
            // Falling cherry blossom petals
            vx = (CGFloat(windStrength) * 3.5 + CGFloat.random(in: -0.8...0.8)) * motionDamping
            vy = -(CGFloat.random(in: 1.2...3.2) * layerScale) * motionDamping
            size = CGFloat.random(in: 8.0...14.0) * layerScale
            opacity = CGFloat.random(in: 0.70...0.92)
            rotSpeed = CGFloat.random(in: -0.06...0.06) * motionDamping
            
        case .cozyCafe:
            // Rising warm steam particles
            vx = (CGFloat(windStrength) * 0.5 + CGFloat.random(in: -0.4...0.4)) * motionDamping
            vy = (CGFloat.random(in: 1.2...2.8) * layerScale) * motionDamping // Rising upward
            size = CGFloat.random(in: 12.0...28.0) * layerScale
            opacity = CGFloat.random(in: 0.15...0.38)
            rotSpeed = CGFloat.random(in: -0.02...0.02)
            
        case .ocean:
            // Sea mist & rolling wave motes
            vx = (CGFloat(windStrength) * 4.0 + CGFloat.random(in: 1.0...2.5)) * motionDamping
            vy = CGFloat.random(in: -0.5...0.5) * motionDamping
            size = CGFloat.random(in: 16.0...40.0) * layerScale
            opacity = CGFloat.random(in: 0.18...0.35) * CGFloat(intensity)
            rotSpeed = 0
            
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
        
        // Occasional distant lightning for Rainy Day
        if currentEnvironment == .rainyDay || currentEnvironment == .rain {
            if Int.random(in: 0...280) == 0 {
                lightningFlashOpacity = 0.85
            } else if lightningFlashOpacity > 0 {
                lightningFlashOpacity = max(0, lightningFlashOpacity - 0.12)
            }
        } else {
            lightningFlashOpacity = 0.0
        }
        
        for i in 0..<activeParticles.count {
            activeParticles[i].x += activeParticles[i].vx
            activeParticles[i].y += activeParticles[i].vy
            activeParticles[i].rotation += activeParticles[i].rotationSpeed
            
            // Boundary wrapping
            if activeParticles[i].vy < 0 {
                // Downward moving particles
                if activeParticles[i].y < bounds.minY - 30 {
                    activeParticles[i].y = bounds.maxY + 20
                    activeParticles[i].x = CGFloat.random(in: bounds.minX...bounds.maxX)
                }
            } else {
                // Upward moving particles (e.g. cozy cafe steam)
                if activeParticles[i].y > bounds.maxY + 30 {
                    activeParticles[i].y = bounds.minY - 20
                    activeParticles[i].x = CGFloat.random(in: bounds.minX...bounds.maxX)
                }
            }
            
            if activeParticles[i].x < bounds.minX - 50 {
                activeParticles[i].x = bounds.maxX + 40
            } else if activeParticles[i].x > bounds.maxX + 50 {
                activeParticles[i].x = bounds.minX - 40
            }
        }
        
        // Direct zero-overhead redraw trigger to registered overlay views (bypassing SwiftUI Combine tree)
        if !overlayViews.allObjects.isEmpty {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                for view in self.overlayViews.allObjects {
                    view.needsDisplay = true
                }
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
            panel.ignoresMouseEvents = true // Guarantee 100% click-through for desktop applications
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            
            let overlay = AmbientParticleOverlayView(engine: self, screenFrame: screen.frame)
            panel.contentView = overlay
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

// MARK: - High-Performance Native CoreGraphics Overlay View
public final class AmbientParticleOverlayView: NSView {
    public weak var engine: AmbientEngine?
    public let screenFrame: CGRect
    
    public init(engine: AmbientEngine, screenFrame: CGRect) {
        self.engine = engine
        self.screenFrame = screenFrame
        super.init(frame: NSRect(origin: .zero, size: screenFrame.size))
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
        engine.registerOverlayView(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func hitTest(_ point: NSPoint) -> NSView? {
        // Guarantee 100% click-through to underlying applications
        return nil
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        guard let engine = engine, let context = NSGraphicsContext.current?.cgContext else { return }
        AmbientParticleRenderer.render(
            particles: engine.activeParticles,
            in: bounds,
            context: context,
            lightningFlash: engine.lightningFlashOpacity
        )
    }
}

// MARK: - CoreGraphics Particle Renderer
public struct AmbientParticleRenderer {
    public static func render(
        particles: [AmbientParticle],
        in bounds: CGRect,
        context: CGContext,
        lightningFlash: Double = 0.0
    ) {
        // Distant lightning flash for Rainy Day
        if lightningFlash > 0.02 {
            context.saveGState()
            context.setFillColor(CGColor(red: 0.85, green: 0.95, blue: 1.0, alpha: CGFloat(lightningFlash * 0.16)))
            context.fill(bounds)
            context.restoreGState()
        }
        
        for p in particles {
            context.saveGState()
            let rect = CGRect(
                x: p.x - p.size / 2,
                y: p.y - p.size / 2,
                width: p.size,
                height: p.size
            )
            
            switch p.environment {
            case .rainyDay, .rain:
                context.setStrokeColor(CGColor(red: 0.45, green: 0.78, blue: 0.98, alpha: p.opacity))
                context.setLineWidth(p.size)
                context.setLineCap(.round)
                context.move(to: CGPoint(x: rect.midX, y: rect.maxY))
                context.addLine(to: CGPoint(x: rect.midX - p.vx * 1.5, y: rect.minY - 10))
                context.strokePath()
                
            case .enchantedForest:
                // Glowing golden-green firefly with pulsating halo
                context.setFillColor(CGColor(red: 0.82, green: 0.96, blue: 0.35, alpha: p.opacity * 0.35))
                context.fillEllipse(in: rect.insetBy(dx: -p.size * 0.5, dy: -p.size * 0.5))
                context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 0.55, alpha: p.opacity))
                context.fillEllipse(in: rect)
                
            case .winterCalm, .snow:
                context.setFillColor(CGColor(red: 0.96, green: 0.98, blue: 1.0, alpha: p.opacity))
                context.fillEllipse(in: rect)
                
            case .sunset:
                // Soft drifting warm cloud motes
                context.setFillColor(CGColor(red: 0.98, green: 0.58, blue: 0.38, alpha: p.opacity * 0.45))
                context.fillEllipse(in: rect)
                
            case .cosmicDream:
                // Twinkling purple-cyan stars
                context.setFillColor(CGColor(red: 0.82, green: 0.76, blue: 1.0, alpha: p.opacity))
                context.fillEllipse(in: rect)
                
            case .sakuraGarden:
                // Falling pink blossom petals
                context.translateBy(x: rect.midX, y: rect.midY)
                context.rotate(by: p.rotation)
                let petalRect = CGRect(x: -p.size / 2, y: -p.size * 0.7, width: p.size, height: p.size * 1.4)
                context.setFillColor(CGColor(red: 1.0, green: 0.72, blue: 0.82, alpha: p.opacity))
                context.fillEllipse(in: petalRect)
                
            case .cozyCafe:
                // Warm rising coffee steam motes
                context.setFillColor(CGColor(red: 0.95, green: 0.90, blue: 0.85, alpha: p.opacity * 0.38))
                context.fillEllipse(in: rect)
                
            case .ocean:
                // Sea mist & ocean spray motes
                context.setFillColor(CGColor(red: 0.45, green: 0.85, blue: 0.95, alpha: p.opacity * 0.45))
                context.fillEllipse(in: rect)
                
            case .fog:
                context.setFillColor(CGColor(red: 0.75, green: 0.80, blue: 0.85, alpha: p.opacity))
                context.fillEllipse(in: rect)
                
            case .sunlight:
                context.setFillColor(CGColor(red: 1.0, green: 0.92, blue: 0.50, alpha: p.opacity))
                context.fillEllipse(in: rect)
                
            case .wind:
                context.setStrokeColor(CGColor(red: 0.9, green: 0.95, blue: 1.0, alpha: p.opacity))
                context.setLineWidth(1.5)
                context.move(to: CGPoint(x: rect.minX, y: rect.midY))
                context.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.midY - 8))
                context.strokePath()
                
            case .fallingLeaves:
                context.translateBy(x: rect.midX, y: rect.midY)
                context.rotate(by: p.rotation)
                let leafRect = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size)
                context.setFillColor(CGColor(red: 0.95, green: 0.50, blue: 0.15, alpha: p.opacity))
                context.fillEllipse(in: leafRect)
            }
            context.restoreGState()
        }
    }
}

// MARK: - SwiftUI Ambient Canvas View (Used for in-app Studio Previews)
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
                    y: size.height - p.y - p.size / 2,
                    width: p.size,
                    height: p.size
                )
                
                context.opacity = Double(p.opacity)
                
                switch p.environment {
                case .rainyDay, .rain:
                    let path = Path { pt in
                        pt.move(to: CGPoint(x: rect.midX, y: rect.minY))
                        pt.addLine(to: CGPoint(x: rect.midX - p.vx * 1.5, y: rect.maxY + 10))
                    }
                    context.stroke(path, with: .color(.cyan.opacity(0.7)), lineWidth: p.size)
                    
                case .enchantedForest:
                    context.fill(Path(ellipseIn: rect), with: .color(.green.opacity(0.85)))
                    
                case .winterCalm, .snow:
                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                    
                case .sunset:
                    context.fill(Path(ellipseIn: rect), with: .color(.orange.opacity(0.5)))
                    
                case .cosmicDream:
                    context.fill(Path(ellipseIn: rect), with: .color(.purple.opacity(0.8)))
                    
                case .sakuraGarden:
                    context.fill(Path(ellipseIn: rect), with: .color(.pink.opacity(0.85)))
                    
                case .cozyCafe:
                    context.fill(Path(ellipseIn: rect), with: .color(.brown.opacity(0.4)))
                    
                case .ocean:
                    context.fill(Path(ellipseIn: rect), with: .color(.teal.opacity(0.6)))
                    
                case .fog:
                    context.fill(Path(ellipseIn: rect), with: .color(.gray.opacity(0.4)))
                    
                case .sunlight:
                    context.fill(Path(ellipseIn: rect), with: .color(.yellow.opacity(0.35)))
                    
                case .wind:
                    let path = Path { pt in
                        pt.move(to: CGPoint(x: rect.minX, y: rect.midY))
                        pt.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.midY - 8))
                    }
                    context.stroke(path, with: .color(.white.opacity(0.4)), lineWidth: 1.5)
                    
                case .fallingLeaves:
                    context.fill(Path(ellipseIn: rect), with: .color(.orange.opacity(0.85)))
                }
            }
        }
        .allowsHitTesting(false)
        .edgesIgnoringSafeArea(.all)
    }
}
