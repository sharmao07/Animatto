import SwiftUI
import AppKit

// MARK: - Ambient Modes & Worlds Studio View (Task 1: Functional Presets & Studio Experience)
public struct AmbientModesView: View {
    @StateObject private var ambientEngine = AmbientEngine.shared
    @ObservedObject private var audioSettings = AudioEngine.shared.settings
    @State private var selectedAmbientPresetKey: String = "rainy_day"
    @State private var isStudioPreviewActive: Bool = false
    @State private var previewParticles: [AmbientParticle] = []
    @State private var previewTimer: Timer?
    @State private var companionAtmosphereEnabled: Bool = true
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 20) {
            // Left: Gallery of Presets & Global Toggle
            VStack(alignment: .leading, spacing: 14) {
                // Header & Status
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ambient Modes & Worlds")
                                .font(.headline)
                            Text("Immersive desktop atmospheres, animated particles & dynamic audio.")
                                .font(.caption).foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("Desktop Ambience", isOn: $ambientEngine.isEnabled)
                            .toggleStyle(.switch)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                
                // 8 Presets Grid
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(AtmospherePreset.builtInPresets.prefix(8)) { preset in
                            AmbientPresetCard(
                                preset: preset,
                                isSelected: selectedAmbientPresetKey == preset.presetKey,
                                isActiveOnDesktop: ambientEngine.isEnabled && ambientEngine.activePresetKey == preset.presetKey,
                                accentColor: accentForEnvironment(preset.environmentType),
                                onPreview: {
                                    handlePreview(preset: preset)
                                },
                                onApply: {
                                    handleApply(preset: preset)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                // Bottom Toolbar
                HStack {
                    Button(action: {
                        ambientEngine.restoreDefaults()
                        selectedAmbientPresetKey = "rainy_day"
                        if let defaultPreset = AtmospherePreset.builtInPresets.first(where: { $0.presetKey == "rainy_day" }) {
                            startStudioPreview(for: defaultPreset)
                        }
                    }) {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button(action: {
                        if let preset = AtmospherePreset.builtInPresets.first(where: { $0.presetKey == selectedAmbientPresetKey }) {
                            ambientEngine.isEnabled = true
                            ambientEngine.applyPresetDirect(preset)
                            AudioEngine.shared.playUISound(.select)
                        }
                    }) {
                        Label("Apply to Desktop", systemImage: "checkmark.circle.fill")
                            .font(.caption).bold()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(minWidth: 380, maxWidth: 440)
            
            Divider()
            
            // Right: Live Studio Preview & Atmosphere Controls
            VStack(alignment: .leading, spacing: 14) {
                // Live Viewport Preview
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Studio Preview")
                            .font(.subheadline).bold()
                        Spacer()
                        if let cur = AtmospherePreset.builtInPresets.first(where: { $0.presetKey == selectedAmbientPresetKey }) {
                            Text(cur.name)
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    
                    ZStack {
                        previewBackgroundGradient(for: selectedAmbientPresetKey)
                            .cornerRadius(12)
                        
                        GeometryReader { geo in
                            StudioParticleCanvas(particles: previewParticles, viewSize: geo.size)
                        }
                        .cornerRadius(12)
                        
                        if let preset = AtmospherePreset.builtInPresets.first(where: { $0.presetKey == selectedAmbientPresetKey }) {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: preset.environmentType.iconName)
                                        .font(.system(size: 54))
                                        .foregroundColor(.white.opacity(0.15))
                                        .padding(16)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                
                // Controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Environment Controls").font(.subheadline).bold()
                    
                    // Intensity Slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Atmospheric Intensity:").font(.caption).bold()
                            Spacer()
                            Text("\(Int(ambientEngine.intensity * 100))%")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Slider(value: $ambientEngine.intensity, in: 0.1...1.0)
                    }
                    
                    // Particle Density / Quality Mode
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Particle Density & Performance:").font(.caption).bold()
                            Spacer()
                            Text(ambientEngine.qualityMode.displayName)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Picker("Quality Mode", selection: $ambientEngine.qualityMode) {
                            ForEach(AmbientQualityMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Divider().padding(.vertical, 2)
                    
                    // Audio Controls
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Toggle("Ambient Soundscape Audio", isOn: $audioSettings.ambientEnabled)
                                .font(.caption).bold()
                            Spacer()
                            if audioSettings.ambientEnabled {
                                Text(ambientEngine.currentEnvironment.displayName)
                                    .font(.caption2).foregroundColor(.green)
                            } else {
                                Text("Muted")
                                    .font(.caption2).foregroundColor(.gray)
                            }
                        }
                        
                        if audioSettings.ambientEnabled {
                            HStack(spacing: 10) {
                                Image(systemName: "speaker.wave.1.fill")
                                    .font(.caption).foregroundColor(.gray)
                                Slider(value: $audioSettings.ambientVolume, in: 0.0...1.0)
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.caption).foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Divider().padding(.vertical, 2)
                    
                    // Companion Atmosphere Reactions
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Companion Weather Awareness")
                                .font(.caption).bold()
                            Text("Companions adjust activity and dialogue based on ambient weather.")
                                .font(.caption2).foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("", isOn: $companionAtmosphereEnabled)
                            .toggleStyle(.switch)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                
                Spacer()
            }
        }
        .padding()
        .onAppear {
            isStudioPreviewActive = true
            if let preset = AtmospherePreset.builtInPresets.first(where: { $0.presetKey == ambientEngine.activePresetKey }) {
                selectedAmbientPresetKey = preset.presetKey
                startStudioPreview(for: preset)
            } else if let first = AtmospherePreset.builtInPresets.first {
                selectedAmbientPresetKey = first.presetKey
                startStudioPreview(for: first)
            }
        }
        .onDisappear {
            isStudioPreviewActive = false
            stopStudioPreview()
        }
    }
    
    private func handlePreview(preset: AtmospherePreset) {
        selectedAmbientPresetKey = preset.presetKey
        startStudioPreview(for: preset)
    }
    
    private func handleApply(preset: AtmospherePreset) {
        selectedAmbientPresetKey = preset.presetKey
        ambientEngine.isEnabled = true
        ambientEngine.applyPresetDirect(preset)
        startStudioPreview(for: preset)
        AudioEngine.shared.playUISound(.select)
    }
    
    private func accentForEnvironment(_ env: AmbientEnvironmentType) -> Color {
        switch env {
        case .rainyDay, .rain: return .cyan
        case .enchantedForest: return .green
        case .winterCalm, .snow: return .blue
        case .sunset: return .orange
        case .cosmicDream: return .purple
        case .sakuraGarden: return .pink
        case .cozyCafe: return Color(red: 0.85, green: 0.65, blue: 0.45)
        case .ocean: return .teal
        case .fog: return .gray
        case .sunlight: return .yellow
        case .wind: return .mint
        case .fallingLeaves: return .orange
        }
    }
    
    private func previewBackgroundGradient(for presetKey: String) -> some View {
        let colors: [Color]
        switch presetKey {
        case "rainy_day", "rainy_evening":
            colors = [Color(red: 0.08, green: 0.12, blue: 0.20), Color(red: 0.04, green: 0.06, blue: 0.12)]
        case "enchanted_forest", "misty_forest":
            colors = [Color(red: 0.06, green: 0.16, blue: 0.10), Color(red: 0.02, green: 0.08, blue: 0.05)]
        case "winter_calm", "first_snow":
            colors = [Color(red: 0.10, green: 0.18, blue: 0.26), Color(red: 0.05, green: 0.09, blue: 0.16)]
        case "sunset":
            colors = [Color(red: 0.35, green: 0.15, blue: 0.25), Color(red: 0.15, green: 0.06, blue: 0.12)]
        case "cosmic_dream", "quiet_night":
            colors = [Color(red: 0.12, green: 0.06, blue: 0.24), Color(red: 0.04, green: 0.02, blue: 0.10)]
        case "sakura_garden":
            colors = [Color(red: 0.25, green: 0.10, blue: 0.18), Color(red: 0.10, green: 0.04, blue: 0.08)]
        case "cozy_cafe":
            colors = [Color(red: 0.22, green: 0.14, blue: 0.08), Color(red: 0.09, green: 0.05, blue: 0.03)]
        case "ocean":
            colors = [Color(red: 0.06, green: 0.18, blue: 0.26), Color(red: 0.02, green: 0.08, blue: 0.14)]
        default:
            colors = [Color(red: 0.10, green: 0.10, blue: 0.14), Color(red: 0.04, green: 0.04, blue: 0.06)]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
    
    private func startStudioPreview(for preset: AtmospherePreset) {
        stopStudioPreview()
        guard isStudioPreviewActive else { return }
        
        let width: CGFloat = 360
        let height: CGFloat = 200
        var newParticles: [AmbientParticle] = []
        let count = 24
        
        for _ in 0..<count {
            let x = CGFloat.random(in: 10...width - 10)
            let y = CGFloat.random(in: 10...height - 10)
            let vx: CGFloat
            let vy: CGFloat
            let size: CGFloat
            let opacity: CGFloat
            
            switch preset.environmentType {
            case .rainyDay, .rain:
                vx = 1.0
                vy = -CGFloat.random(in: 6...12)
                size = 2.0
                opacity = 0.7
            case .enchantedForest:
                vx = CGFloat.random(in: -0.4...0.4)
                vy = CGFloat.random(in: -0.4...0.4)
                size = CGFloat.random(in: 3...5)
                opacity = 0.8
            case .winterCalm, .snow:
                vx = CGFloat.random(in: -0.5...0.5)
                vy = -CGFloat.random(in: 1.0...2.5)
                size = CGFloat.random(in: 3...5)
                opacity = 0.8
            case .sunset:
                vx = 0.8
                vy = 0
                size = CGFloat.random(in: 25...45)
                opacity = 0.25
            case .cosmicDream:
                vx = CGFloat.random(in: -0.1...0.1)
                vy = CGFloat.random(in: -0.1...0.1)
                size = CGFloat.random(in: 2...4)
                opacity = 0.85
            case .sakuraGarden:
                vx = CGFloat.random(in: 0.8...1.8)
                vy = -CGFloat.random(in: 0.8...1.8)
                size = CGFloat.random(in: 6...10)
                opacity = 0.8
            case .cozyCafe:
                vx = CGFloat.random(in: -0.2...0.2)
                vy = CGFloat.random(in: 0.8...2.0)
                size = CGFloat.random(in: 8...16)
                opacity = 0.35
            case .ocean:
                vx = CGFloat.random(in: 1.0...2.2)
                vy = CGFloat.random(in: -0.3...0.3)
                size = CGFloat.random(in: 10...20)
                opacity = 0.4
            case .fog:
                vx = 0.3
                vy = 0
                size = 35.0
                opacity = 0.2
            case .sunlight:
                vx = 0.2
                vy = 0.1
                size = 25.0
                opacity = 0.25
            case .wind:
                vx = 4.0
                vy = 0
                size = 15.0
                opacity = 0.3
            case .fallingLeaves:
                vx = 1.2
                vy = -1.2
                size = 10.0
                opacity = 0.8
            }
            
            newParticles.append(
                AmbientParticle(
                    x: x,
                    y: y,
                    vx: vx,
                    vy: vy,
                    size: size,
                    opacity: opacity,
                    rotation: 0,
                    rotationSpeed: 0.02,
                    layer: 0,
                    environment: preset.environmentType
                )
            )
        }
        
        self.previewParticles = newParticles
        
        previewTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [self] _ in
            guard isStudioPreviewActive else { return }
            for i in 0..<previewParticles.count {
                previewParticles[i].x += previewParticles[i].vx
                previewParticles[i].y += previewParticles[i].vy
                
                if previewParticles[i].vy < 0 {
                    if previewParticles[i].y < -10 {
                        previewParticles[i].y = height + 10
                        previewParticles[i].x = CGFloat.random(in: 0...width)
                    }
                } else {
                    if previewParticles[i].y > height + 10 {
                        previewParticles[i].y = -10
                        previewParticles[i].x = CGFloat.random(in: 0...width)
                    }
                }
                
                if previewParticles[i].x < -20 {
                    previewParticles[i].x = width + 10
                } else if previewParticles[i].x > width + 20 {
                    previewParticles[i].x = -10
                }
            }
        }
    }
    
    private func stopStudioPreview() {
        previewTimer?.invalidate()
        previewTimer = nil
    }
}

// MARK: - Ambient Preset Card View
struct AmbientPresetCard: View {
    let preset: AtmospherePreset
    let isSelected: Bool
    let isActiveOnDesktop: Bool
    let accentColor: Color
    let onPreview: () -> Void
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: preset.environmentType.iconName)
                    .font(.title3)
                    .foregroundColor(accentColor)
                
                Spacer()
                
                if isActiveOnDesktop {
                    Text("Active")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.25))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                } else if isSelected {
                    Text("Previewing")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.25))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            Text(preset.name)
                .font(.subheadline)
                .bold()
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Text(preset.description)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 4)
            
            HStack {
                Button("Preview", action: onPreview)
                    .buttonStyle(.bordered)
                    .font(.caption2)
                
                Button(action: onApply) {
                    Text(isActiveOnDesktop ? "Applied" : "Apply")
                        .font(.caption2)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .tint(isActiveOnDesktop ? .green : .accentColor)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.white.opacity(0.08) : Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActiveOnDesktop ? Color.green : (isSelected ? Color.accentColor : Color.white.opacity(0.08)), lineWidth: isSelected || isActiveOnDesktop ? 1.5 : 1)
        )
        .onTapGesture(perform: onPreview)
    }
}

// MARK: - Studio Particle Preview Canvas View
struct StudioParticleCanvas: View {
    let particles: [AmbientParticle]
    let viewSize: CGSize
    
    var body: some View {
        Canvas { context, size in
            for p in particles {
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
                        pt.addLine(to: CGPoint(x: rect.midX - p.vx * 1.5, y: rect.maxY + 8))
                    }
                    context.stroke(path, with: .color(.cyan.opacity(0.8)), lineWidth: p.size)
                case .enchantedForest:
                    context.fill(Path(ellipseIn: rect), with: .color(.green.opacity(0.85)))
                case .winterCalm, .snow:
                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                case .sunset:
                    context.fill(Path(ellipseIn: rect), with: .color(.orange.opacity(0.55)))
                case .cosmicDream:
                    context.fill(Path(ellipseIn: rect), with: .color(.purple.opacity(0.85)))
                case .sakuraGarden:
                    context.fill(Path(ellipseIn: rect), with: .color(.pink.opacity(0.85)))
                case .cozyCafe:
                    context.fill(Path(ellipseIn: rect), with: .color(.brown.opacity(0.5)))
                case .ocean:
                    context.fill(Path(ellipseIn: rect), with: .color(.teal.opacity(0.7)))
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
    }
}
