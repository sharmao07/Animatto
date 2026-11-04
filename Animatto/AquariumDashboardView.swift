import SwiftUI
import AppKit

// MARK: - Aquarium Mode In-App Management View (Phase 2 Redesign)
// Dedicated, high-craft desktop oceanarium control center.

public struct AquariumDashboardView: View {
    @ObservedObject private var aquariumManager = AquariumManager.shared
    @ObservedObject private var audioSettings = AudioSettings.shared
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    @State private var showFeedAlert = false
    @State private var showLicenseSheet = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AnimattoTheme.space20) {
                
                // 1. Header Banner
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text("Aquarium Mode")
                                .font(.system(size: 20, weight: .semibold))
                            
                            AnimattoBadge(
                                aquariumManager.isAquariumModeActive ? "Aquarium Mode Active" : "Companions Mode",
                                icon: aquariumManager.isAquariumModeActive ? "water.waves" : "pawprint.fill",
                                color: aquariumManager.isAquariumModeActive ? .cyan : .secondary
                            )
                        }
                        
                        Text("Transforms active desktop companion widgets on your screen into living interactive aquariums. Turning off Aquarium Mode restores your original companions.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        aquariumManager.toggleAquariumMode()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: aquariumManager.isAquariumModeActive ? "arrow.uturn.backward" : "water.waves")
                            Text(aquariumManager.isAquariumModeActive ? "Turn Off Aquarium Mode" : "Turn On Aquarium Mode")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(aquariumManager.isAquariumModeActive ? .orange : .accentColor)
                    .controlSize(.regular)
                }
                
                // 2. Desktop Widgets Status Banner
                let detectedWidgets = DesktopWidgetDetector.shared.detectDesktopWidgets()
                let widgetCount = detectedWidgets.count
                AnimattoCard {
                    HStack(spacing: AnimattoTheme.space16) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "macwindow.on.rectangle")
                                    .foregroundColor(.cyan)
                                Text("Desktop Widgets Status")
                                    .font(.system(size: 12, weight: .semibold))
                                AnimattoBadge(widgetCount > 0 ? "\(widgetCount) detected on desktop" : "0 on screen")
                            }
                            
                            if widgetCount > 0 {
                                Text(aquariumManager.isAquariumModeActive ?
                                     "\(widgetCount) macOS desktop widget(s) (Clock, Weather, etc.) are currently replaced by interactive aquariums." :
                                     "\(widgetCount) macOS desktop widget(s) detected on screen. Turn on Aquarium Mode to transform them directly into living aquariums.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No macOS desktop widgets currently detected on screen. Add macOS widgets to your desktop or spawn companion widgets to experience Aquarium Mode.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if widgetCount == 0 && (PetManager.shared?.activePets.isEmpty ?? true) {
                            Button(action: {
                                PetManager.shared?.ensureDefaultWidget()
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Spawn Companion")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                
                // 3. Tank Quick Actions Bar
                AnimattoCard {
                    HStack(spacing: AnimattoTheme.space16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Interactive Controls")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Interact directly with your aquatic companions on screen.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            aquariumManager.feedFlakes(count: 3)
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.orange)
                                Text("Feed Pellets")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!aquariumManager.isAquariumModeActive)
                        .help("Drop 3 nutrient food flakes into the tank")
                        
                        Button(action: {
                            let center = CGPoint(x: 360, y: 240)
                            aquariumManager.tapGlass(at: center)
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "hand.tap.fill")
                                    .foregroundColor(.cyan)
                                Text("Tap Glass")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!aquariumManager.isAquariumModeActive)
                        .help("Send a refractive shockwave startling companions into dart bursts")
                        
                        Button(action: {
                            aquariumManager.toggleStaysOnTop()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: aquariumManager.settings.staysOnTop ? "pin.fill" : "pin")
                                Text(aquariumManager.settings.staysOnTop ? "Pinned" : "Pin on Top")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                
                // 4. Species Roster Section
                VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                    AnimattoSectionHeader(
                        title: "Aquatic Species Roster",
                        subtitle: "Four original companion species engineered with 120 transparent pixel-art frames.",
                        icon: "fish.fill"
                    )
                    
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        speciesCard(
                            name: "Finny",
                            scientificName: "Golden Sunfin",
                            niche: "Pelagic",
                            nicheColor: .orange,
                            iconName: "sun.max.fill",
                            speedRange: "65–140 pt/s",
                            description: "Amber-gold pelagic cruiser with flowing dorsal fins that swims gracefully through middle depths."
                        )
                        
                        speciesCard(
                            name: "Pip",
                            scientificName: "Spotted Pygmy Puffer",
                            niche: "Surface Hover",
                            nicheColor: .green,
                            iconName: "circle.grid.cross.fill",
                            speedRange: "50–110 pt/s",
                            description: "Curious spotted puffer with rapid fin fluttering, hovering physics, and playful boundary bounces."
                        )
                        
                        speciesCard(
                            name: "Glow",
                            scientificName: "Neon Ghost Tetra",
                            niche: "Schooling (Boids)",
                            nicheColor: .cyan,
                            iconName: "sparkles",
                            speedRange: "70–160 pt/s",
                            description: "Translucent bioluminescent tetra swimming in coordinated groups using Reynolds flocking algorithms."
                        )
                        
                        speciesCard(
                            name: "Barnaby",
                            scientificName: "Mossy Hermit Crab",
                            niche: "Benthic Substrate",
                            nicheColor: .brown,
                            iconName: "shield.fill",
                            speedRange: "35–80 pt/s",
                            description: "Moss-covered crustacean with benthic negative buoyancy that scuttles realistically across bottom rocks."
                        )
                    }
                }
                
                // 5. Tank Configuration & Environment
                VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                    AnimattoSectionHeader(
                        title: "Tank Environment & Physics",
                        subtitle: "Visual rendering, dimensions, and atmospheric parameters.",
                        icon: "slider.horizontal.3"
                    )
                    
                    AnimattoCard {
                        VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                            // Desktop Widget Size Preset
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text("Widget Size Presets")
                                            .font(.system(size: 13, weight: .regular))
                                        if aquariumManager.settings.tankSizePreset == .custom {
                                            AnimattoBadge("Pro Custom", icon: "sparkles", color: .purple)
                                        }
                                    }
                                    Text("Compact desktop widget dimensions or arbitrary custom sizing")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { aquariumManager.settings.tankSizePreset },
                                    set: { newPreset in
                                        if newPreset == .custom {
                                            if entitlementManager.isEntitled(to: .aquariumPro) {
                                                aquariumManager.applyPreset(.custom)
                                            } else {
                                                showLicenseSheet = true
                                            }
                                        } else {
                                            aquariumManager.applyPreset(newPreset)
                                        }
                                    }
                                )) {
                                    Text("Small (280×180)").tag(TankSizePreset.small)
                                    Text("Medium (420×280)").tag(TankSizePreset.medium)
                                    Text("Large (560×360)").tag(TankSizePreset.large)
                                    Text("Panoramic (640×240)").tag(TankSizePreset.panoramicWidget)
                                    Text("Custom (Pro)").tag(TankSizePreset.custom)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 220)
                            }
                            
                            if aquariumManager.settings.tankSizePreset == .custom && entitlementManager.isEntitled(to: .aquariumPro) {
                                Divider()
                                AnimattoSliderRow(
                                    "Custom Tank Width",
                                    description: "Width: \(Int(aquariumManager.settings.customWidth)) pt",
                                    icon: "arrow.left.and.right",
                                    value: $aquariumManager.settings.customWidth,
                                    in: 320.0...1200.0,
                                    step: 20.0
                                )
                                AnimattoSliderRow(
                                    "Custom Tank Height",
                                    description: "Height: \(Int(aquariumManager.settings.customHeight)) pt",
                                    icon: "arrow.up.and.down",
                                    value: $aquariumManager.settings.customHeight,
                                    in: 240.0...800.0,
                                    step: 20.0
                                )
                            }
                            
                            Divider()
                            
                            // Water Atmosphere Theme
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text("Water Atmosphere Theme")
                                            .font(.system(size: 13, weight: .regular))
                                        if aquariumManager.settings.waterTheme.isProOnly {
                                            AnimattoBadge("Pro Theme", icon: "sparkles", color: .purple)
                                        }
                                    }
                                    Text("Optical water filtration and lighting color gradation")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { aquariumManager.settings.waterTheme },
                                    set: { newTheme in
                                        if newTheme.isProOnly && !entitlementManager.isEntitled(to: .aquariumPro) {
                                            showLicenseSheet = true
                                        } else {
                                            aquariumManager.settings.waterTheme = newTheme
                                        }
                                    }
                                )) {
                                    ForEach(WaterAtmosphereTheme.allCases, id: \.self) { theme in
                                        Text(theme.isProOnly ? "\(theme.displayName) ✦" : theme.displayName).tag(theme)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 220)
                            }
                            
                            Divider()
                            
                            // Caustics & Clarity Sliders
                            AnimattoSliderRow(
                                "Caustic Shimmer Intensity",
                                description: "Overhead refractive water light patterns",
                                value: $aquariumManager.settings.causticIntensity,
                                in: 0.0...1.0,
                                step: 0.05
                            )
                            
                            Divider()
                            
                            AnimattoSliderRow(
                                "Water Clarity",
                                description: "Depth attenuation and light penetration",
                                value: $aquariumManager.settings.waterClarity,
                                in: 0.1...1.0,
                                step: 0.05
                            )
                            
                            Divider()
                            
                            // Simulation Quality Mode
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Simulation Quality")
                                        .font(.system(size: 13, weight: .regular))
                                    Text("Clamps maximum bubble count and particle calculations.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Picker("", selection: $aquariumManager.settings.qualityMode) {
                                    Text("Low Power").tag(AmbientQualityMode.lowPower)
                                    Text("Balanced").tag(AmbientQualityMode.balanced)
                                    Text("High Quality").tag(AmbientQualityMode.highQuality)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 220)
                            }
                        }
                    }
                }
                
                // 6. Sound & Submerged Ambience
                VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                    AnimattoSectionHeader(
                        title: "Underwater Soundscape",
                        subtitle: "Submerged aerator resonance, bubbling filter, and feeding audio.",
                        icon: "speaker.wave.2.fill"
                    )
                    
                    AnimattoCard {
                        VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                            AnimattoToggleRow(
                                "Underwater Audio",
                                description: "Enable low-pass ambient tank hum and aerator sound loops",
                                icon: "speaker.wave.2",
                                isOn: $aquariumManager.settings.soundEnabled
                            )
                            
                            if aquariumManager.settings.soundEnabled {
                                Divider()
                                
                                AnimattoSliderRow(
                                    "Aerator Volume",
                                    description: "Volume of bubble stream percolation and filter hum",
                                    value: $aquariumManager.settings.aeratorVolume,
                                    in: 0.0...1.0,
                                    step: 0.05
                                )
                            }
                        }
                    }
                }
            }
            .padding(AnimattoTheme.space20)
        }
        .sheet(isPresented: $showLicenseSheet) {
            FreeVsPremiumSheet()
        }
    }
    
    // MARK: - Helper Views
    
    private func speciesCard(
        name: String,
        scientificName: String,
        niche: String,
        nicheColor: Color,
        iconName: String,
        speedRange: String,
        description: String
    ) -> some View {
        AnimattoCard(padding: AnimattoTheme.space12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(name)
                            .font(.system(size: 14, weight: .semibold))
                        Text(scientificName)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    AnimattoBadge(niche, icon: iconName, color: nicheColor)
                }
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 4) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 9))
                    Text(speedRange)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.secondary)
                .padding(.top, 2)
            }
        }
    }
}
