import SwiftUI
import AppKit

// MARK: - Audio Console & Soundscape View (Phase 2 Redesign)
// Unified, high-fidelity sound mixing console for desktop companions & atmospheres.

public struct AudioConsoleView: View {
    @ObservedObject private var audioSettings = AudioSettings.shared
    @ObservedObject private var aquariumManager = AquariumManager.shared
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    @State private var showLicenseSheet = false
    
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
                
                // 3. Pro Sound Studio & Acoustics Card
                VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                    HStack {
                        AnimattoSectionHeader(
                            title: "Pro Sound Studio & Acoustics",
                            subtitle: "Spatial coordinate panning, parametric room acoustic profiles, and multi-track presence.",
                            icon: "waveform.badge.magnifyingglass"
                        )
                        Spacer()
                        if entitlementManager.isEntitled(to: .proSoundStudio) {
                            AnimattoBadge("Pro Active", icon: "sparkles", color: .purple)
                        } else {
                            AnimattoBadge("Pro Feature", icon: "lock.fill", color: .secondary)
                        }
                    }
                    
                    AnimattoCard {
                        if entitlementManager.isEntitled(to: .proSoundStudio) {
                            VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                                // Acoustic Profile Selector
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Acoustic Room Profile")
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(audioSettings.acousticProfile.description)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Picker("", selection: $audioSettings.acousticProfile) {
                                        ForEach(AcousticProfile.allCases) { profile in
                                            Text(profile.rawValue).tag(profile)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 170)
                                }
                                
                                Divider()
                                
                                // Spatial Stereo Audio Panning
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Spatial Coordinate Panning")
                                            .font(.system(size: 13, weight: .regular))
                                        Text("Pans companion footsteps and voices across stereo speakers based on screen X position")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $audioSettings.spatialAudioPanningEnabled)
                                        .labelsHidden()
                                        .toggleStyle(.switch)
                                        .controlSize(.small)
                                }
                                
                                Divider()
                                
                                // Multi-Track Mixing Presence
                                AnimattoSliderRow(
                                    "Acoustic Presence Gain",
                                    description: "Harmonic dynamic range and presence shaping",
                                    icon: "tuningfork",
                                    value: $audioSettings.multiTrackMixingPresence,
                                    in: 0.5...1.5,
                                    step: 0.05
                                )
                            }
                        } else {
                            // Locked State with Unlock CTA
                            HStack(spacing: AnimattoTheme.space12) {
                                Image(systemName: "lock.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Pro Sound Studio & Acoustics")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Unlock 5 parametric acoustic profiles (Warm Lo-Fi, Cozy Room, Cavern Reverb, Binaural Field) and physical companion stereo spatial panning.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Unlock Pro ($3.99)") {
                                    showLicenseSheet = true
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                    }
                }
                
                // 4. Companion Audio Channels
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
        .sheet(isPresented: $showLicenseSheet) {
            FreeVsPremiumSheet()
        }
    }
}
