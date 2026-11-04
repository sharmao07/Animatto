import SwiftUI
import AppKit

// MARK: - Ambient Modes & Worlds Studio View (Task 1: Functional Presets & Studio Experience)
public struct AmbientModesView: View {
    @StateObject private var ambientEngine = AmbientEngine.shared
    @ObservedObject private var audioSettings = AudioEngine.shared.settings
    @State private var selectedAmbientPresetKey: String = "rainy_day"
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
            .frame(width: 340)
            
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
                            if let preset = AtmospherePreset.builtInPresets.first(where: { $0.presetKey == selectedAmbientPresetKey }) {
                                StudioParticleCanvas(environment: preset.environmentType, viewSize: geo.size)
                            }
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
            if let preset = AtmospherePreset.builtInPresets.first(where: { $0.presetKey == ambientEngine.activePresetKey }) {
                selectedAmbientPresetKey = preset.presetKey
            } else if let first = AtmospherePreset.builtInPresets.first {
                selectedAmbientPresetKey = first.presetKey
            }
        }
    }
    
    private func handlePreview(preset: AtmospherePreset) {
        selectedAmbientPresetKey = preset.presetKey
    }
    
    private func handleApply(preset: AtmospherePreset) {
        selectedAmbientPresetKey = preset.presetKey
        ambientEngine.isEnabled = true
        ambientEngine.applyPresetDirect(preset)
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

// MARK: - Isolated Studio Particle Preview Canvas View
struct StudioParticleCanvas: View {
    let environment: AmbientEnvironmentType
    let viewSize: CGSize
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let count = 16
                for i in 0..<count {
                    let seed = Double(i) * 37.13
                    let speedMult = 1.0 + Double(i % 5) * 0.2
                    let progress = (time * speedMult + seed).truncatingRemainder(dividingBy: 8.0) / 8.0
                    
                    let normX = (sin(seed * 2.3 + time * 0.2) + 1.0) / 2.0
                    var x = normX * max(size.width, 100)
                    var y: CGFloat = 0.0
                    var particleSize: CGFloat = 4.0
                    var opacity: Double = 0.75
                    
                    switch environment {
                    case .rainyDay, .rain:
                        y = CGFloat(progress) * size.height
                        let streakLen: CGFloat = 12.0
                        let path = Path { pt in
                            pt.move(to: CGPoint(x: x, y: y))
                            pt.addLine(to: CGPoint(x: x - 2, y: y + streakLen))
                        }
                        context.stroke(path, with: .color(.cyan.opacity(0.7)), lineWidth: 1.5)
                        continue
                    case .enchantedForest:
                        y = (CGFloat(sin(seed + time * 0.6)) + 1.0) / 2.0 * size.height
                        particleSize = 4.5
                        opacity = (sin(time * 2.0 + seed) + 1.0) / 2.0 * 0.6 + 0.3
                        let rect = CGRect(x: x, y: y, width: particleSize, height: particleSize)
                        context.fill(Path(ellipseIn: rect), with: .color(.green.opacity(opacity)))
                        continue
                    case .winterCalm, .snow:
                        y = CGFloat(progress) * size.height
                        x += CGFloat(sin(time + seed)) * 15.0
                        particleSize = 3.5
                        let rect = CGRect(x: x, y: y, width: particleSize, height: particleSize)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.85)))
                        continue
                    case .sunset:
                        x = CGFloat(progress) * size.width
                        y = CGFloat(sin(seed)) * 30 + size.height * 0.4
                        particleSize = 28.0
                        let rect = CGRect(x: x, y: y, width: particleSize, height: particleSize)
                        context.fill(Path(ellipseIn: rect), with: .color(.orange.opacity(0.3)))
                        continue
                    case .cosmicDream:
                        y = (CGFloat(cos(seed + time * 0.2)) + 1.0) / 2.0 * size.height
                        particleSize = 3.0
                        opacity = (cos(time * 1.5 + seed) + 1.0) / 2.0 * 0.5 + 0.4
                        let rect = CGRect(x: x, y: y, width: particleSize, height: particleSize)
                        context.fill(Path(ellipseIn: rect), with: .color(.purple.opacity(opacity)))
                        continue
                    case .sakuraGarden:
                        y = CGFloat(progress) * size.height
                        x += CGFloat(sin(time * 1.5 + seed)) * 25.0
                        particleSize = 7.0
                        let rect = CGRect(x: x, y: y, width: particleSize, height: particleSize)
                        context.fill(Path(ellipseIn: rect), with: .color(.pink.opacity(0.8)))
                        continue
                    case .cozyCafe:
                        y = size.height - (CGFloat(progress) * size.height)
                        x += CGFloat(sin(time + seed)) * 12.0
                        particleSize = 12.0
                        let rect = CGRect(x: x, y: y, width: particleSize, height: particleSize)
                        context.fill(Path(ellipseIn: rect), with: .color(.brown.opacity(0.35)))
                        continue
                    case .ocean:
                        x = CGFloat(progress) * size.width
                        y = size.height * 0.7 + CGFloat(sin(time * 2.0 + seed)) * 15.0
                        particleSize = 14.0
                        let rect = CGRect(x: x, y: y, width: particleSize, height: particleSize)
                        context.fill(Path(ellipseIn: rect), with: .color(.teal.opacity(0.5)))
                        continue
                    default:
                        y = CGFloat(progress) * size.height
                        particleSize = 5.0
                        let rect = CGRect(x: x, y: y, width: particleSize, height: particleSize)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.5)))
                        continue
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
