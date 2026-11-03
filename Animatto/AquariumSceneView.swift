import Foundation
import CoreGraphics
import SwiftUI
import Combine

// MARK: - Aquarium Scene State
public final class AquariumSceneState: ObservableObject {
    @Published public var elapsedTime: Double = 0.0
    public var bubbles: [AquariumBubble] = []
    public var plants: [AquariumPlant] = []
    public var rippleCenter: CGPoint?
    public var rippleProgress: Double = 1.0
    
    public init() {}
    
    public func ensureInitialized(width: Double, height: Double, plantCount: Int, targetBubbleCount: Int = 55) {
        if plants.isEmpty {
            rebuildFlora(width: width, height: height, count: plantCount)
        }
        if bubbles.isEmpty {
            reseedBubbles(width: width, height: height, targetCount: targetBubbleCount)
        }
    }
    
    public func rebuildFlora(width: Double, height: Double, count: Int) {
        plants.removeAll()
        guard count > 0, width > 50 else { return }
        
        let step = width / Double(count + 1)
        for i in 1...count {
            let x = step * Double(i) + Double.random(in: -15.0...15.0)
            let h = Double.random(in: (height * 0.35)...(height * 0.70))
            let stalks = Int.random(in: 3...5)
            plants.append(AquariumPlant(
                rootX: x,
                height: h,
                width: 32.0,
                phaseOffset: Double(i) * 0.85,
                stalkCount: stalks
            ))
        }
    }
    
    public func reseedBubbles(width: Double, height: Double, targetCount: Int) {
        bubbles.removeAll()
        let aeratorX1 = width * 0.16
        let aeratorX2 = width * 0.84
        
        for i in 0..<targetCount {
            let aerator = (i % 2 == 0) ? aeratorX1 : aeratorX2
            let spreadX = aerator + Double.random(in: -12.0...12.0)
            let startY = Double.random(in: 12.0...height)
            bubbles.append(AquariumBubble(
                x: spreadX,
                y: startY,
                z: Double.random(in: 0.2...0.8),
                radius: Double.random(in: 2.2...5.2),
                speed: Double.random(in: 45.0...85.0),
                wobblePhase: Double.random(in: 0.0...(.pi * 2.0)),
                wobbleFrequency: Double.random(in: 3.0...5.0),
                opacity: Double.random(in: 0.45...0.80)
            ))
        }
    }
    
    public func update(
        deltaTime: TimeInterval,
        width: Double,
        height: Double,
        settings: AquariumSettings
    ) {
        elapsedTime += deltaTime
        
        // Update ripple
        if rippleProgress < 1.0 {
            rippleProgress += deltaTime * 1.8
            if rippleProgress >= 1.0 {
                rippleCenter = nil
            }
        }
        
        // Target bubble count by quality
        let maxBubbles: Int
        switch settings.qualityMode {
        case .lowPower: maxBubbles = 25
        case .balanced: maxBubbles = 55
        case .highQuality: maxBubbles = 95
        }
        
        if bubbles.count != maxBubbles {
            reseedBubbles(width: width, height: height, targetCount: maxBubbles)
        }
        
        let aeratorX1 = width * 0.16
        let aeratorX2 = width * 0.84
        
        for i in 0..<bubbles.count {
            bubbles[i].y += bubbles[i].speed * deltaTime
            
            // Pop at surface and respawn at aerator
            if bubbles[i].y >= height - 8.0 {
                let aerator = (i % 2 == 0) ? aeratorX1 : aeratorX2
                bubbles[i].x = aerator + Double.random(in: -12.0...12.0)
                bubbles[i].y = Double.random(in: 12.0...24.0)
                bubbles[i].speed = Double.random(in: 45.0...85.0)
                bubbles[i].radius = Double.random(in: 2.2...5.2)
                bubbles[i].opacity = Double.random(in: 0.45...0.80)
            }
        }
    }
    
    public func triggerGlassTap(at point: CGPoint) {
        rippleCenter = point
        rippleProgress = 0.0
    }
}

// MARK: - Aquarium Multi-Layer Scene View
public struct AquariumSceneView: View {
    @ObservedObject public var settingsHolder: AquariumManager
    @StateObject private var sceneState = AquariumSceneState()
    
    @State private var isHoveringControls: Bool = false
    
    public init(manager: AquariumManager) {
        self.settingsHolder = manager
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let settings = settingsHolder.settings
            let companions = settingsHolder.activeCompanions
            
            ZStack {
                // Layer 0: Deep Water Gradient & Caustics Shimmer
                WaterAtmosphereLayer(
                    theme: settings.waterTheme,
                    causticIntensity: settings.causticIntensity,
                    reduceMotion: settings.reduceMotion,
                    time: sceneState.elapsedTime
                )
                
                // Layer 1: Distant Background Scenery (Sunken rocks & silhouettes)
                DistantSceneryLayer(
                    theme: settings.waterTheme,
                    size: size
                )
                
                // Layer 2: Deep Aquatic Plane (Background fish at 0.7x scale with water tint)
                BackgroundCreaturesLayer(
                    companions: companions.filter { $0.state.position.z > 0.6 },
                    size: size,
                    theme: settings.waterTheme
                )
                
                // Layer 3: Mid-Ground Habitat (Substrate sand bed & swaying plants)
                SubstrateAndFloraLayer(
                    theme: settings.waterTheme,
                    plants: sceneState.plants,
                    reduceMotion: settings.reduceMotion,
                    time: sceneState.elapsedTime,
                    size: size
                )
                
                // Food Pellets Layer (Drifting organic flakes & settled dissolving morsels)
                FoodPelletsLayer(
                    pellets: settingsHolder.foodPellets,
                    size: size
                )
                
                // Layer 4: Primary Companion Plane (Active companions at foreground/midground)
                PrimaryAquaticPlaneView(
                    companions: companions.filter { $0.state.position.z <= 0.6 },
                    size: size
                )
                
                // Layer 5: Foreground Aerator Bubbles (Rising particle streams)
                BubbleStreamLayer(
                    bubbles: sceneState.bubbles,
                    reduceMotion: settings.reduceMotion,
                    time: sceneState.elapsedTime,
                    size: size
                )
                
                // Layer 6: Tank Surface Glass (Meniscus, reflection glint, rim)
                if settings.presentationMode == .dedicatedWindow {
                    AquariumGlassOverlayView(
                        size: size,
                        rippleCenter: sceneState.rippleCenter,
                        rippleProgress: sceneState.rippleProgress
                    )
                }
                
                // Subtle Top Controls Overlay (fades in on hover in Dedicated Window mode)
                if settings.presentationMode == .dedicatedWindow {
                    VStack {
                        topGlassControlBar
                            .opacity(isHoveringControls ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.25), value: isHoveringControls)
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: settings.presentationMode == .dedicatedWindow ? 16 : 0))
            .onContinuousHover { phase in
                switch phase {
                case .active(let point):
                    settingsHolder.cursorLocation = point
                    isHoveringControls = (point.y < 50)
                case .ended:
                    settingsHolder.cursorLocation = nil
                    isHoveringControls = false
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { location in
                sceneState.triggerGlassTap(at: location)
                settingsHolder.tapGlass(at: location)
            }
            .simultaneousGesture(
                TapGesture(count: 1).onEnded {
                    if let point = settingsHolder.cursorLocation, point.y > 45 {
                        settingsHolder.feedAt(point: point)
                    }
                }
            )
            .onReceive(settingsHolder.$glassTapLocation) { loc in
                if let pt = loc {
                    sceneState.triggerGlassTap(at: pt)
                }
            }
            .onAppear {
                let targetBubbles: Int
                switch settings.qualityMode {
                case .lowPower: targetBubbles = 25
                case .balanced: targetBubbles = 55
                case .highQuality: targetBubbles = 95
                }
                sceneState.ensureInitialized(
                    width: Double(size.width),
                    height: Double(size.height),
                    plantCount: settings.plantDensity,
                    targetBubbleCount: targetBubbles
                )
            }
            .onChange(of: settings.plantDensity) { _, newCount in
                sceneState.rebuildFlora(
                    width: Double(size.width),
                    height: Double(size.height),
                    count: newCount
                )
            }
            .onReceive(settingsHolder.$tickSignal) { dt in
                guard !settingsHolder.isPaused else { return }
                sceneState.update(
                    deltaTime: dt,
                    width: Double(size.width),
                    height: Double(size.height),
                    settings: settings
                )
            }
        }
    }
    
    // MARK: - Glass Control Bar
    
    private var topGlassControlBar: some View {
        HStack(spacing: 12) {
            // Mute / Unmute
            Button(action: {
                settingsHolder.settings.soundEnabled.toggle()
            }) {
                Image(systemName: settingsHolder.settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .buttonStyle(.plain)
            .help(settingsHolder.settings.soundEnabled ? "Mute Water Sounds" : "Unmute Water Sounds")
            
            // Feed Flakes
            Button(action: {
                settingsHolder.feedFlakes(count: 3)
            }) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.yellow.opacity(0.9))
            }
            .buttonStyle(.plain)
            .help("Drop Fish Food")
            
            // Pin on Top
            Button(action: {
                settingsHolder.toggleStaysOnTop()
            }) {
                Image(systemName: settingsHolder.settings.staysOnTop ? "pin.fill" : "pin")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(settingsHolder.settings.staysOnTop ? .cyan : .white.opacity(0.75))
            }
            .buttonStyle(.plain)
            .help("Always on Top")
            
            Spacer()
            
            // Theme Indicator
            Text(settingsHolder.settings.waterTheme.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
            
            // Close Button
            Button(action: {
                settingsHolder.closeAquarium()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Close Aquarium Tank")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.35))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        )
    }
}

// MARK: - Layer 0: Water Atmosphere Layer
public struct WaterAtmosphereLayer: View {
    public let theme: WaterAtmosphereTheme
    public let causticIntensity: Double
    public let reduceMotion: Bool
    public let time: Double
    
    public init(
        theme: WaterAtmosphereTheme,
        causticIntensity: Double = 0.6,
        reduceMotion: Bool = false,
        time: Double = 0.0
    ) {
        self.theme = theme
        self.causticIntensity = causticIntensity
        self.reduceMotion = reduceMotion
        self.time = time
    }
    
    public var body: some View {
        Canvas { context, size in
            // Base water gradient
            let gradient = Gradient(colors: [
                theme.gradientColors.top,
                theme.gradientColors.mid,
                theme.gradientColors.bottom
            ])
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: size.width * 0.5, y: 0),
                    endPoint: CGPoint(x: size.width * 0.5, y: size.height)
                )
            )
            
            // Procedural dual-sine caustic shimmer
            if !reduceMotion && causticIntensity > 0.05 {
                let causticAlpha = 0.12 * causticIntensity
                let bandCount = 10
                let stepY = (size.height * 0.65) / Double(bandCount)
                
                for i in 0..<bandCount {
                    let yBase = Double(i) * stepY + 10.0
                    var path = Path()
                    let k1 = 0.024
                    let k2 = 0.018
                    let w1 = 1.3
                    let w2 = 0.9
                    
                    var firstPoint = true
                    for x in stride(from: 0.0, through: size.width, by: 12.0) {
                        let offset = sin(k1 * x + w1 * time + Double(i) * 0.7) * 7.0
                                   + cos(k2 * x - w2 * time) * 4.0
                        let pt = CGPoint(x: x, y: yBase + offset)
                        if firstPoint {
                            path.move(to: pt)
                            firstPoint = false
                        } else {
                            path.addLine(to: pt)
                        }
                    }
                    
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(causticAlpha)),
                        lineWidth: 3.5
                    )
                }
            }
        }
    }
}

// MARK: - Layer 1: Distant Scenery Layer
public struct DistantSceneryLayer: View {
    public let theme: WaterAtmosphereTheme
    public let size: CGSize
    
    public init(theme: WaterAtmosphereTheme, size: CGSize) {
        self.theme = theme
        self.size = size
    }
    
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            
            // Distant sunken rock arches silhouette
            var rocksPath = Path()
            rocksPath.move(to: CGPoint(x: 0, y: h))
            rocksPath.addLine(to: CGPoint(x: 0, y: h * 0.62))
            rocksPath.addQuadCurve(
                to: CGPoint(x: w * 0.35, y: h * 0.78),
                control: CGPoint(x: w * 0.18, y: h * 0.50)
            )
            rocksPath.addQuadCurve(
                to: CGPoint(x: w * 0.70, y: h * 0.85),
                control: CGPoint(x: w * 0.52, y: h * 0.70)
            )
            rocksPath.addQuadCurve(
                to: CGPoint(x: w, y: h * 0.58),
                control: CGPoint(x: w * 0.85, y: h * 0.48)
            )
            rocksPath.addLine(to: CGPoint(x: w, y: h))
            rocksPath.closeSubpath()
            
            let silhouetteColor = Color.black.opacity(0.18)
            context.fill(rocksPath, with: .color(silhouetteColor))
            
            // Distant kelp forest vertical silhouettes
            for x in stride(from: w * 0.05, through: w * 0.95, by: w * 0.18) {
                var kelpPath = Path()
                kelpPath.move(to: CGPoint(x: x, y: h))
                kelpPath.addCurve(
                    to: CGPoint(x: x + 8.0, y: h * 0.35),
                    control1: CGPoint(x: x - 12.0, y: h * 0.75),
                    control2: CGPoint(x: x + 18.0, y: h * 0.55)
                )
                context.stroke(kelpPath, with: .color(Color.black.opacity(0.12)), lineWidth: 6.0)
            }
        }
    }
}

// MARK: - Layer 2: Deep Aquatic Plane (Background Companions)
public struct BackgroundCreaturesLayer: View {
    public let companions: [AquaticCompanionInstance]
    public let size: CGSize
    public let theme: WaterAtmosphereTheme
    
    public init(
        companions: [AquaticCompanionInstance],
        size: CGSize,
        theme: WaterAtmosphereTheme
    ) {
        self.companions = companions
        self.size = size
        self.theme = theme
    }
    
    public var body: some View {
        Canvas { context, size in
            for companion in companions {
                let st = companion.state
                // Map physics coordinates (AppKit Y=0 is bottom) to Canvas (Y=0 is top)
                let canvasX = st.position.x
                let canvasY = size.height - st.position.y
                
                // Depth scaling: Z in [0.6, 1.0] -> scale 0.65x to 0.78x
                let depthFactor = st.position.z
                let scale = 1.0 - (0.35 * depthFactor)
                let baseRadius: Double = 18.0 * scale
                
                context.drawLayer { subContext in
                    subContext.translateBy(x: canvasX, y: canvasY)
                    subContext.rotate(by: Angle(degrees: st.bankAngle))
                    if !companion.isFacingRight {
                        subContext.scaleBy(x: -1, y: 1)
                    }
                    
                    if let cgImage = companion.currentFrameImage {
                        let resolved = context.resolve(Image(decorative: cgImage, scale: 1.0, orientation: .up))
                        let targetW = companion.renderSize.width * scale
                        let targetH = companion.renderSize.height * scale
                        let rect = CGRect(x: -targetW / 2.0, y: -targetH / 2.0, width: targetW, height: targetH)
                        subContext.opacity = 0.70
                        subContext.draw(resolved, in: rect)
                    } else {
                        // Silhouette fish with deep water haze blend
                        var fishPath = Path()
                        fishPath.move(to: CGPoint(x: baseRadius * 1.5, y: 0))
                        fishPath.addQuadCurve(
                            to: CGPoint(x: -baseRadius, y: -baseRadius * 0.7),
                            control: CGPoint(x: 0, y: -baseRadius)
                        )
                        fishPath.addLine(to: CGPoint(x: -baseRadius * 1.6, y: -baseRadius * 0.9))
                        fishPath.addLine(to: CGPoint(x: -baseRadius * 1.2, y: 0))
                        fishPath.addLine(to: CGPoint(x: -baseRadius * 1.6, y: baseRadius * 0.9))
                        fishPath.addLine(to: CGPoint(x: -baseRadius, y: baseRadius * 0.7))
                        fishPath.addQuadCurve(
                            to: CGPoint(x: baseRadius * 1.5, y: 0),
                            control: CGPoint(x: 0, y: baseRadius)
                        )
                        fishPath.closeSubpath()
                        
                        // Water haze color
                        let hazeColor = theme.gradientColors.mid.opacity(0.45)
                        subContext.fill(fishPath, with: .color(hazeColor))
                    }
                }
            }
        }
    }
}

// MARK: - Layer 3: Substrate & Swaying Flora Layer
public struct SubstrateAndFloraLayer: View {
    public let theme: WaterAtmosphereTheme
    public let plants: [AquariumPlant]
    public let reduceMotion: Bool
    public let time: Double
    public let size: CGSize
    
    public init(
        theme: WaterAtmosphereTheme,
        plants: [AquariumPlant],
        reduceMotion: Bool,
        time: Double,
        size: CGSize
    ) {
        self.theme = theme
        self.plants = plants
        self.reduceMotion = reduceMotion
        self.time = time
        self.size = size
    }
    
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            
            // 1. Swaying aquatic plants
            for plant in plants {
                let swayAmount = reduceMotion ? 0.0 : sin(0.8 * time + plant.phaseOffset) * 16.0
                
                for s in 0..<plant.stalkCount {
                    let stalkOffset = Double(s - plant.stalkCount / 2) * 6.0
                    let root = CGPoint(x: plant.rootX + stalkOffset, y: h - 18.0)
                    let tip = CGPoint(
                        x: plant.rootX + stalkOffset + swayAmount * (1.0 + Double(s) * 0.15),
                        y: h - plant.height + Double(s) * 8.0
                    )
                    let ctrl1 = CGPoint(
                        x: plant.rootX + stalkOffset - swayAmount * 0.3,
                        y: h - plant.height * 0.4
                    )
                    let ctrl2 = CGPoint(
                        x: plant.rootX + stalkOffset + swayAmount * 0.7,
                        y: h - plant.height * 0.75
                    )
                    
                    var leafPath = Path()
                    leafPath.move(to: root)
                    leafPath.addCurve(to: tip, control1: ctrl1, control2: ctrl2)
                    
                    let stalkColor = Color(red: 0.15, green: 0.58, blue: 0.28).opacity(0.85)
                    context.stroke(leafPath, with: .color(stalkColor), lineWidth: 4.0)
                }
            }
            
            // 2. Sand Substrate contour
            var substratePath = Path()
            substratePath.move(to: CGPoint(x: 0, y: h))
            substratePath.addLine(to: CGPoint(x: 0, y: h - 28.0))
            substratePath.addCurve(
                to: CGPoint(x: w * 0.5, y: h - 22.0),
                control1: CGPoint(x: w * 0.25, y: h - 34.0),
                control2: CGPoint(x: w * 0.38, y: h - 18.0)
            )
            substratePath.addCurve(
                to: CGPoint(x: w, y: h - 26.0),
                control1: CGPoint(x: w * 0.70, y: h - 26.0),
                control2: CGPoint(x: w * 0.88, y: h - 32.0)
            )
            substratePath.addLine(to: CGPoint(x: w, y: h))
            substratePath.closeSubpath()
            
            let sandGradient = Gradient(colors: [
                Color(red: 0.82, green: 0.74, blue: 0.58),
                Color(red: 0.62, green: 0.54, blue: 0.40)
            ])
            context.fill(
                substratePath,
                with: .linearGradient(
                    sandGradient,
                    startPoint: CGPoint(x: w * 0.5, y: h - 30),
                    endPoint: CGPoint(x: w * 0.5, y: h)
                )
            )
            
            // 3. Rounded river pebbles
            let pebbleCount = 8
            let pStep = w / Double(pebbleCount + 1)
            for i in 1...pebbleCount {
                let px = pStep * Double(i) + Double((i * 17) % 11) - 5.0
                let py = h - 16.0 + Double((i * 7) % 9) - 4.0
                let pRect = CGRect(x: px - 6.0, y: py - 4.0, width: 12.0, height: 8.0)
                let pebbleColor = Color(red: 0.45, green: 0.42, blue: 0.38).opacity(0.9)
                context.fill(Path(ellipseIn: pRect), with: .color(pebbleColor))
            }
        }
    }
}

// MARK: - Layer 4: Food Pellets Layer
public struct FoodPelletsLayer: View {
    public let pellets: [AquariumFoodPellet]
    public let size: CGSize
    
    public init(pellets: [AquariumFoodPellet], size: CGSize) {
        self.pellets = pellets
        self.size = size
    }
    
    public var body: some View {
        Canvas { context, canvasSize in
            for pellet in pellets {
                let canvasX = pellet.position.x
                let canvasY = canvasSize.height - pellet.position.y
                let pelletRadius = 3.5
                let opacity = max(0.0, 1.0 - pellet.dissolveProgress)
                
                context.drawLayer { subContext in
                    subContext.translateBy(x: canvasX, y: canvasY)
                    
                    // Pellet flake body (warm organic amber/ochre)
                    let flakePath = Path(ellipseIn: CGRect(
                        x: -pelletRadius,
                        y: -pelletRadius * 0.7,
                        width: pelletRadius * 2.0,
                        height: pelletRadius * 1.4
                    ))
                    
                    let pelletColor = Color(red: 0.92, green: 0.58, blue: 0.22).opacity(opacity)
                    let highlightColor = Color(red: 1.0, green: 0.82, blue: 0.45).opacity(opacity * 0.85)
                    
                    subContext.fill(flakePath, with: .color(pelletColor))
                    
                    let highlightPath = Path(ellipseIn: CGRect(
                        x: -pelletRadius * 0.5,
                        y: -pelletRadius * 0.4,
                        width: pelletRadius * 0.9,
                        height: pelletRadius * 0.5
                    ))
                    subContext.fill(highlightPath, with: .color(highlightColor))
                }
            }
        }
    }
}

// MARK: - Layer 4b: Primary Aquatic Plane View
public struct PrimaryAquaticPlaneView: View {
    public let companions: [AquaticCompanionInstance]
    public let size: CGSize
    
    public init(companions: [AquaticCompanionInstance], size: CGSize) {
        self.companions = companions
        self.size = size
    }
    
    public var body: some View {
        Canvas { context, size in
            for companion in companions {
                let st = companion.state
                let canvasX = st.position.x
                let canvasY = size.height - st.position.y
                
                // Depth projection scale: s(Z) = 1.0 - 0.35 * Z
                let depthFactor = st.position.z
                let scale = 1.0 - (0.35 * depthFactor)
                let baseRadius: Double = 22.0 * scale
                
                context.drawLayer { subContext in
                    subContext.translateBy(x: canvasX, y: canvasY)
                    subContext.rotate(by: Angle(degrees: st.bankAngle))
                    if !companion.isFacingRight {
                        subContext.scaleBy(x: -1, y: 1)
                    }
                    
                    if let cgImage = companion.currentFrameImage {
                        let resolved = context.resolve(Image(decorative: cgImage, scale: 1.0, orientation: .up))
                        let targetW = companion.renderSize.width * scale
                        let targetH = companion.renderSize.height * scale
                        let rect = CGRect(x: -targetW / 2.0, y: -targetH / 2.0, width: targetW, height: targetH)
                        subContext.draw(resolved, in: rect)
                    } else {
                        // Render stylized primary fish form fallback
                        var bodyPath = Path()
                        bodyPath.move(to: CGPoint(x: baseRadius * 1.5, y: 0))
                        bodyPath.addQuadCurve(
                            to: CGPoint(x: -baseRadius, y: -baseRadius * 0.75),
                            control: CGPoint(x: 0, y: -baseRadius * 1.1)
                        )
                        // Tail fin
                        bodyPath.addLine(to: CGPoint(x: -baseRadius * 1.8, y: -baseRadius * 1.0))
                        bodyPath.addLine(to: CGPoint(x: -baseRadius * 1.3, y: 0))
                        bodyPath.addLine(to: CGPoint(x: -baseRadius * 1.8, y: baseRadius * 1.0))
                        bodyPath.addLine(to: CGPoint(x: -baseRadius, y: baseRadius * 0.75))
                        bodyPath.addQuadCurve(
                            to: CGPoint(x: baseRadius * 1.5, y: 0),
                            control: CGPoint(x: 0, y: baseRadius * 1.1)
                        )
                        bodyPath.closeSubpath()
                        
                        // Golden sunfin warm coloration
                        let bodyColor = Color(red: 0.98, green: 0.72, blue: 0.22)
                        subContext.fill(bodyPath, with: .color(bodyColor))
                        
                        // Pectoral fin highlight
                        var finPath = Path()
                        finPath.move(to: CGPoint(x: 0, y: baseRadius * 0.2))
                        finPath.addQuadCurve(
                            to: CGPoint(x: -baseRadius * 0.8, y: baseRadius * 0.85),
                            control: CGPoint(x: -baseRadius * 0.3, y: baseRadius * 0.9)
                        )
                        finPath.closeSubpath()
                        subContext.fill(finPath, with: .color(Color.white.opacity(0.65)))
                        
                        // Eye
                        let eyeRect = CGRect(x: baseRadius * 0.8, y: -baseRadius * 0.35, width: 5.0 * scale, height: 5.0 * scale)
                        subContext.fill(Path(ellipseIn: eyeRect), with: .color(.black))
                        let pupilRect = CGRect(x: baseRadius * 0.8 + 1.0, y: -baseRadius * 0.35 + 1.0, width: 2.0 * scale, height: 2.0 * scale)
                        subContext.fill(Path(ellipseIn: pupilRect), with: .color(.white))
                    }
                }
            }
        }
    }
}

// MARK: - Layer 5: Foreground Aerator Bubbles Layer
public struct BubbleStreamLayer: View {
    public let bubbles: [AquariumBubble]
    public let reduceMotion: Bool
    public let time: Double
    public let size: CGSize
    
    public init(
        bubbles: [AquariumBubble],
        reduceMotion: Bool,
        time: Double,
        size: CGSize
    ) {
        self.bubbles = bubbles
        self.reduceMotion = reduceMotion
        self.time = time
        self.size = size
    }
    
    public var body: some View {
        Canvas { context, size in
            for b in bubbles {
                let wobble = reduceMotion ? 0.0 : sin(b.wobblePhase + time * b.wobbleFrequency) * 3.5
                let drawX = b.x + wobble
                let drawY = size.height - b.y
                
                let rect = CGRect(
                    x: drawX - b.radius,
                    y: drawY - b.radius,
                    width: b.radius * 2.0,
                    height: b.radius * 2.0
                )
                
                // Translucent bubble body
                let bubbleColor = Color.white.opacity(b.opacity * 0.45)
                context.fill(Path(ellipseIn: rect), with: .color(bubbleColor))
                
                // Thin bubble outline
                let outlineColor = Color.white.opacity(b.opacity * 0.85)
                context.stroke(Path(ellipseIn: rect), with: .color(outlineColor), lineWidth: 1.0)
                
                // Specular glint dot in upper left
                let glintRect = CGRect(
                    x: rect.minX + b.radius * 0.45,
                    y: rect.minY + b.radius * 0.45,
                    width: max(1.0, b.radius * 0.5),
                    height: max(1.0, b.radius * 0.5)
                )
                context.fill(Path(ellipseIn: glintRect), with: .color(Color.white.opacity(b.opacity)))
            }
        }
    }
}

// MARK: - Layer 6: Tank Surface Glass Overlay
public struct AquariumGlassOverlayView: View {
    public let size: CGSize
    public let rippleCenter: CGPoint?
    public let rippleProgress: Double
    
    public init(
        size: CGSize,
        rippleCenter: CGPoint? = nil,
        rippleProgress: Double = 1.0
    ) {
        self.size = size
        self.rippleCenter = rippleCenter
        self.rippleProgress = rippleProgress
    }
    
    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            
            // 1. Water Meniscus line near top surface
            var meniscus = Path()
            meniscus.move(to: CGPoint(x: 10, y: 12))
            meniscus.addLine(to: CGPoint(x: w - 10, y: 12))
            context.stroke(meniscus, with: .color(Color.white.opacity(0.40)), lineWidth: 1.5)
            
            // 2. Corner specular glass glints
            var glintPath = Path()
            glintPath.move(to: CGPoint(x: 0, y: 0))
            glintPath.addLine(to: CGPoint(x: w * 0.45, y: 0))
            glintPath.addLine(to: CGPoint(x: 0, y: h * 0.35))
            glintPath.closeSubpath()
            
            let glintGradient = Gradient(colors: [
                Color.white.opacity(0.12),
                Color.white.opacity(0.0)
            ])
            context.fill(
                glintPath,
                with: .linearGradient(
                    glintGradient,
                    startPoint: .zero,
                    endPoint: CGPoint(x: w * 0.35, y: h * 0.28)
                )
            )
            
            // 3. Glass outer frame bevel
            let outerRect = CGRect(origin: .zero, size: size).insetBy(dx: 1.0, dy: 1.0)
            let roundedPath = Path(roundedRect: outerRect, cornerRadius: 16)
            context.stroke(roundedPath, with: .color(Color.white.opacity(0.22)), lineWidth: 2.0)
            
            // 4. Tap ripple animation
            if let center = rippleCenter, rippleProgress < 1.0 {
                let rippleRadius = 80.0 * rippleProgress
                let rippleAlpha = (1.0 - rippleProgress) * 0.65
                let rippleRect = CGRect(
                    x: center.x - rippleRadius,
                    y: center.y - rippleRadius,
                    width: rippleRadius * 2.0,
                    height: rippleRadius * 2.0
                )
                context.stroke(
                    Path(ellipseIn: rippleRect),
                    with: .color(Color.white.opacity(rippleAlpha)),
                    lineWidth: 2.5
                )
            }
        }
        .allowsHitTesting(false)
    }
}
