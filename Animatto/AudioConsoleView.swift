import SwiftUI
import AppKit

// MARK: - Audio Console & Soundscape View (Phase 2 Redesign)
// Unified, high-fidelity sound mixing console for desktop companions & atmospheres.

public struct AudioConsoleView: View {
    @ObservedObject private var audioSettings = AudioSettings.shared
    @ObservedObject private var aquariumManager = AquariumManager.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AnimattoTheme.space20) {
                
                // 1. Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text("Audio & Soundscape")
                                .font(.system(size: 20, weight: .semibold))
                            
                            AnimattoBadge(
                                audioSettings.isMasterMuted ? "Muted" : "Active",
                                icon: audioSettings.isMasterMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                                color: audioSettings.isMasterMuted ? .red : .green
                            )
                        }
                        
                        Text("Fine-tune ambient weather soundscapes, companion footsteps, sleeping purrs, and UI chimes.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Reset to Defaults") {
                        audioSettings.resetToDefaults()
                        AudioEngine.shared.updateAmbientVolume()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                // 2. Master Sound Card
                AnimattoCard(padding: AnimattoTheme.space16) {
                    VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                        HStack {
                            Label("Master Audio Control", systemImage: audioSettings.isMasterMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(audioSettings.isMasterMuted ? .red : .primary)
                            
                            Spacer()
                            
                            Toggle("Master Mute", isOn: Binding(
                                get: { audioSettings.isMasterMuted },
                                set: {
                                    audioSettings.isMasterMuted = $0
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                            ))
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        }
                        
                        Divider()
                        
                        AnimattoSliderRow(
                            "Master Volume",
                            description: "Global attenuation for all companion and environment audio",
                            icon: "slider.horizontal.3",
                            value: $audioSettings.masterVolume,
                            in: 0.0...1.0,
                            step: 0.05
                        )
                        .onChange(of: audioSettings.masterVolume) { _, _ in
                            AudioEngine.shared.updateAmbientVolume()
                        }
                    }
                }
                
                // 3. Companion Audio Channels
                VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                    AnimattoSectionHeader(
                        title: "Companion Sound Effects",
                        subtitle: "Ground-contact footsteps, resting purrs, and vocalizations.",
                        icon: "pawprint.fill"
                    )
                    
                    AnimattoCard {
                        VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                            // Footsteps
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ground-Contact Footsteps")
                                        .font(.system(size: 13, weight: .regular))
                                    Text("Synchronized to walking and running sprite keyframes")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Test") {
                                    AudioEngine.shared.playFootstep()
                                }
                                .buttonStyle(.borderless)
                                .font(.system(size: 11))
                                
                                Toggle("", isOn: $audioSettings.footstepsEnabled)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                            }
                            
                            if audioSettings.footstepsEnabled {
                                AnimattoSliderRow(
                                    "Footsteps Volume",
                                    value: $audioSettings.footstepsVolume,
                                    in: 0.0...1.0,
                                    step: 0.05
                                )
                                .padding(.leading, 12)
                            }
                            
                            Divider()
                            
                            // Sleep sounds
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sleep Sounds & Purring")
                                        .font(.system(size: 13, weight: .regular))
                                    Text("Gentle purring loop when companions rest or sleep")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: $audioSettings.sleepSoundsEnabled)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                            }
                            
                            if audioSettings.sleepSoundsEnabled {
                                AnimattoSliderRow(
                                    "Sleep Purr Volume",
                                    value: $audioSettings.sleepSoundsVolume,
                                    in: 0.0...1.0,
                                    step: 0.05
                                )
                                .padding(.leading, 12)
                            }
                            
                            Divider()
                            
                            // Voices
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Companion Vocalizations")
                                        .font(.system(size: 13, weight: .regular))
                                    Text("Chimes played on dialogue appearance")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: $audioSettings.companionVoicesEnabled)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                            }
                            
                            if audioSettings.companionVoicesEnabled {
                                AnimattoSliderRow(
                                    "Vocalizations Volume",
                                    value: $audioSettings.companionVoicesVolume,
                                    in: 0.0...1.0,
                                    step: 0.05
                                )
                                .padding(.leading, 12)
                            }
                        }
                    }
                }
                
                // 4. Ambient Weather Audio Channels
                VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                    AnimattoSectionHeader(
                        title: "Ambient Weather Audio",
                        subtitle: "Environmental atmospheric audio loops for rain, forest, and wind.",
                        icon: "cloud.rain.fill"
                    )
                    
                    AnimattoCard {
                        VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                            AnimattoToggleRow(
                                "Ambient Weather Audio",
                                description: "Master switch for weather particle sound playback",
                                icon: "cloud.sun.rain",
                                isOn: Binding(
                                    get: { audioSettings.ambientEnabled },
                                    set: {
                                        audioSettings.ambientEnabled = $0
                                        AudioEngine.shared.updateAmbientVolume()
                                    }
                                )
                            )
                            
                            if audioSettings.ambientEnabled {
                                Divider()
                                
                                AnimattoSliderRow(
                                    "Ambient Sub-Master Volume",
                                    value: $audioSettings.ambientVolume,
                                    in: 0.0...1.0,
                                    step: 0.05
                                )
                                .onChange(of: audioSettings.ambientVolume) { _, _ in
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                                .padding(.leading, 12)
                                
                                Divider()
                                
                                // Rain & Thunder
                                HStack {
                                    Text("Rain & Thunder")
                                        .font(.system(size: 12, weight: .medium))
                                    Spacer()
                                    Button("Audition") {
                                        AudioEngine.shared.setAmbientEnvironment(.rainThunder)
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.system(size: 11))
                                    
                                    Toggle("", isOn: Binding(
                                        get: { audioSettings.rainThunderEnabled },
                                        set: {
                                            audioSettings.rainThunderEnabled = $0
                                            AudioEngine.shared.updateAmbientVolume()
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.mini)
                                }
                                .padding(.leading, 12)
                                
                                AnimattoSliderRow(
                                    "Rain Volume",
                                    value: $audioSettings.rainThunderVolume,
                                    in: 0.0...1.0,
                                    step: 0.05
                                )
                                .padding(.leading, 24)
                                .onChange(of: audioSettings.rainThunderVolume) { _, _ in
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                                
                                Divider()
                                
                                // Forest & Birdsong
                                HStack {
                                    Text("Forest & Birdsong")
                                        .font(.system(size: 12, weight: .medium))
                                    Spacer()
                                    Button("Audition") {
                                        AudioEngine.shared.setAmbientEnvironment(.forestBirdsong)
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.system(size: 11))
                                    
                                    Toggle("", isOn: Binding(
                                        get: { audioSettings.forestBirdsongEnabled },
                                        set: {
                                            audioSettings.forestBirdsongEnabled = $0
                                            AudioEngine.shared.updateAmbientVolume()
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.mini)
                                }
                                .padding(.leading, 12)
                                
                                AnimattoSliderRow(
                                    "Forest Volume",
                                    value: $audioSettings.forestBirdsongVolume,
                                    in: 0.0...1.0,
                                    step: 0.05
                                )
                                .padding(.leading, 24)
                                .onChange(of: audioSettings.forestBirdsongVolume) { _, _ in
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                                
                                Divider()
                                
                                // Winter Wind
                                HStack {
                                    Text("Winter Wind")
                                        .font(.system(size: 12, weight: .medium))
                                    Spacer()
                                    Button("Audition") {
                                        AudioEngine.shared.setAmbientEnvironment(.winterWind)
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.system(size: 11))
                                    
                                    Toggle("", isOn: Binding(
                                        get: { audioSettings.winterWindEnabled },
                                        set: {
                                            audioSettings.winterWindEnabled = $0
                                            AudioEngine.shared.updateAmbientVolume()
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.mini)
                                }
                                .padding(.leading, 12)
                                
                                AnimattoSliderRow(
                                    "Wind Volume",
                                    value: $audioSettings.winterWindVolume,
                                    in: 0.0...1.0,
                                    step: 0.05
                                )
                                .padding(.leading, 24)
                                .onChange(of: audioSettings.winterWindVolume) { _, _ in
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                            }
                        }
                    }
                }
                
                // 5. Interface Audio
                VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                    AnimattoSectionHeader(
                        title: "Interface Sound Effects",
                        subtitle: "Subtle tactile acoustic clicks on button taps and selection.",
                        icon: "cursorarrow.click"
                    )
                    
                    AnimattoCard {
                        VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                            HStack {
                                Text("UI Interaction Sounds")
                                    .font(.system(size: 13, weight: .regular))
                                Spacer()
                                Button("Audition") {
                                    AudioEngine.shared.playUISound(.click)
                                }
                                .buttonStyle(.borderless)
                                .font(.system(size: 11))
                                
                                Toggle("", isOn: $audioSettings.uiSoundsEnabled)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                            }
                            
                            if audioSettings.uiSoundsEnabled {
                                AnimattoSliderRow(
                                    "UI Sounds Volume",
                                    value: $audioSettings.uiSoundsVolume,
                                    in: 0.0...1.0,
                                    step: 0.05
                                )
                                .padding(.leading, 12)
                            }
                        }
                    }
                }
            }
            .padding(AnimattoTheme.space20)
        }
    }
}
