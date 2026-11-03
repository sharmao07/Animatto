import SwiftUI
import AppKit
import ServiceManagement

// MARK: - Settings Tab Category
public enum SettingsTabCategory: String, CaseIterable, Identifiable {
    case general = "General"
    case physics = "Physics & Roaming"
    case dialogue = "Dialogue & Memory"
    case integrations = "Integrations"
    case updates = "Updates & About"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .general: return "gearshape"
        case .physics: return "arrow.down.forward.and.arrow.up.backward"
        case .dialogue: return "bubble.left.and.bubble.right"
        case .integrations: return "link"
        case .updates: return "info.circle"
        }
    }
}

// MARK: - Redesigned Tabbed Settings View (Phase 2)
public struct SettingsView: View {
    @EnvironmentObject var petManager: PetManager
    @ObservedObject private var screenService = ScreenAwarenessService.shared
    @ObservedObject private var memoryStore = CharacterMemoryStore.shared
    @ObservedObject private var updateService = UpdateService.shared
    @ObservedObject private var updateConfig = UpdateConfiguration.shared
    
    @State private var activeCategory: SettingsTabCategory = .general
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)
    @State private var showCacheAlert = false
    @State private var clearedCacheCount = 0
    @State private var showClearMemoriesAlert = false
    
    // Persistent Preferences
    @AppStorage("gravityStrength") private var gravityStrength = 0.8
    @AppStorage("walkSpeed") private var walkSpeed = 2.0
    @AppStorage("eventFrequency") private var eventFrequency = 0.5
    @AppStorage("discordRPCEnabled") private var discordRPCEnabled = true
    @AppStorage("musicSyncEnabled") private var musicSyncEnabled = true
    @AppStorage("upsideDownMenuMode") private var upsideDownMenuMode = false
    
    @AppStorage("environmentAwarenessEnabled") private var environmentAwarenessEnabled = true
    @AppStorage("appAwarenessEnabled") private var appAwarenessEnabled = true
    @AppStorage("cursorTrackingEnabled") private var cursorTrackingEnabled = true
    @AppStorage("inactivityTrackingEnabled") private var inactivityTrackingEnabled = true
    @AppStorage("reactionFrequency") private var reactionFrequency = 0.6
    
    @AppStorage("dialogueEnabled") private var dialogueEnabled = true
    @AppStorage("contextualCommentaryEnabled") private var contextualCommentaryEnabled = true
    @AppStorage("directInteractionResponsesEnabled") private var directInteractionResponsesEnabled = true
    @AppStorage("quietModeEnabled") private var quietModeEnabled = false
    @AppStorage("dialogueFrequency") private var dialogueFrequency = 0.5
    
    @AppStorage("socialInteractionsEnabled") private var socialInteractionsEnabled = true
    @AppStorage("memoryEnabled") private var memoryEnabled = true
    
    @AppStorage("appAccentHex") private var appAccentHex = "007AFF"
    @AppStorage("isLiquidGlassEnabled") private var isLiquidGlassEnabled = true
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            
            // 1. Top Category Bar
            HStack(spacing: 8) {
                ForEach(SettingsTabCategory.allCases) { cat in
                    Button(action: {
                        activeCategory = cat
                        AudioEngine.shared.playUISound(.select)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 11, weight: activeCategory == cat ? .semibold : .regular))
                            Text(cat.rawValue)
                                .font(.system(size: 12, weight: activeCategory == cat ? .semibold : .regular))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: AnimattoTheme.radius6)
                                .fill(activeCategory == cat ? Color.accentColor.opacity(0.14) : Color.clear)
                        )
                        .foregroundColor(activeCategory == cat ? .accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding(.horizontal, AnimattoTheme.space20)
            .padding(.top, AnimattoTheme.space12)
            .padding(.bottom, AnimattoTheme.space8)
            
            Divider()
            
            // 2. Tab Content Body
            ScrollView {
                VStack(alignment: .leading, spacing: AnimattoTheme.space16) {
                    switch activeCategory {
                    case .general:
                        generalSection
                    case .physics:
                        physicsSection
                    case .dialogue:
                        dialogueSection
                    case .integrations:
                        integrationsSection
                    case .updates:
                        updatesAndAboutSection
                    }
                }
                .frame(maxWidth: 640)
                .padding(AnimattoTheme.space20)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .onAppear {
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }
    
    // MARK: - Category Sections
    
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: AnimattoTheme.space16) {
            AnimattoSectionHeader(
                title: "Appearance & Window",
                subtitle: "Customize application colors, vibrancy, and surface treatments.",
                icon: "paintbrush.fill"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Accent Color")
                                .font(.system(size: 13))
                            Text("Applied to selection indicators, primary action buttons, and active sliders")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { Color(hex: appAccentHex) },
                            set: { appAccentHex = $0.toHex() }
                        ))
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    AnimattoToggleRow(
                        "Liquid Glass Vibrancy",
                        description: "Enables native translucent NSVisualEffectView glass surfaces",
                        icon: "macwindow",
                        isOn: $isLiquidGlassEnabled
                    )
                }
            }
            
            AnimattoSectionHeader(
                title: "System & Storage",
                subtitle: "Startup behavior and local disk caching.",
                icon: "internaldrive.fill"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Launch at Login")
                                .font(.system(size: 13))
                            Text("Automatically start Animatto in the background when logging in")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { launchAtLogin },
                            set: { newValue in
                                do {
                                    if newValue {
                                        if SMAppService.mainApp.status == .requiresApproval {
                                            SMAppService.openSystemSettingsLoginItems()
                                        }
                                        try SMAppService.mainApp.register()
                                        launchAtLogin = (SMAppService.mainApp.status == .enabled)
                                    } else {
                                        try SMAppService.mainApp.unregister()
                                        launchAtLogin = false
                                    }
                                } catch {
                                    launchAtLogin = (SMAppService.mainApp.status == .enabled)
                                }
                            }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Temporary Media Cache")
                                .font(.system(size: 13))
                            Text("Decoded animation frames and temporary imported assets")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Clear Cache") {
                            clearedCacheCount = PetStorage.clearCache()
                            showCacheAlert = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .alert("Cache Cleared", isPresented: $showCacheAlert) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(clearedCacheCount > 0 ? "Removed \(clearedCacheCount) temporary file(s)." : "Cache is already clean.")
                    }
                }
            }
        }
    }
    
    private var physicsSection: some View {
        VStack(alignment: .leading, spacing: AnimattoTheme.space16) {
            AnimattoSectionHeader(
                title: "Desktop Physics Simulation",
                subtitle: "Gravity, roaming speed, and surface collisions.",
                icon: "arrow.down.forward.and.arrow.up.backward"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                    AnimattoSliderRow(
                        "Gravity Strength",
                        description: "Downward acceleration applied to falling companions",
                        value: $gravityStrength,
                        in: 0.1...2.0,
                        step: 0.1,
                        format: { String(format: "%.1fx", $0) }
                    )
                    
                    Divider()
                    
                    AnimattoSliderRow(
                        "Walking Speed",
                        description: "Horizontal locomotion velocity multiplier",
                        value: $walkSpeed,
                        in: 1.0...5.0,
                        step: 0.5,
                        format: { String(format: "%.1f pt/t", $0) }
                    )
                    
                    Divider()
                    
                    AnimattoToggleRow(
                        "Walk on Menu Bar",
                        description: "Inverts gravity allowing companions to walk upside-down along the macOS menu bar",
                        icon: "menubar.arrow.up.rectangle",
                        isOn: $upsideDownMenuMode
                    )
                }
            }
            
            AnimattoSectionHeader(
                title: "Position Management",
                subtitle: "Emergency companion recovery.",
                icon: "arrow.counterclockwise"
            )
            
            AnimattoCard {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Companion Positions")
                            .font(.system(size: 13))
                        Text("Teleports all active roaming companions back to the center of your primary screen")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Reset Positions") {
                        NotificationCenter.default.post(name: .animattoResetPositions, object: nil)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }
    
    private var dialogueSection: some View {
        VStack(alignment: .leading, spacing: AnimattoTheme.space16) {
            AnimattoSectionHeader(
                title: "Speech Bubbles & Dialogue",
                subtitle: "Contextual companion thoughts and commentary.",
                icon: "bubble.left.and.bubble.right"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                    AnimattoToggleRow(
                        "Speech Bubbles",
                        description: "Allow companions to speak via floating thought and speech bubbles",
                        icon: "bubble.left",
                        isOn: $dialogueEnabled
                    )
                    
                    if dialogueEnabled {
                        Divider()
                        
                        AnimattoToggleRow(
                            "Quiet Mode",
                            description: "Suppresses spontaneous chatter while keeping direct responses active",
                            icon: "moon.fill",
                            isOn: $quietModeEnabled
                        )
                        
                        Divider()
                        
                        AnimattoSliderRow(
                            "Dialogue Frequency",
                            description: "Frequency of companion contextual thoughts",
                            value: $dialogueFrequency,
                            in: 0.1...1.0,
                            step: 0.1
                        )
                    }
                }
            }
            
            AnimattoSectionHeader(
                title: "Social Encounters & Memory",
                subtitle: "Local-first continuity and companion interactions.",
                icon: "person.2.fill"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                    AnimattoToggleRow(
                        "Multi-Companion Social Encounters",
                        description: "Companions recognize nearby friends and initiate playful greetings",
                        icon: "person.2",
                        isOn: $socialInteractionsEnabled
                    )
                    
                    Divider()
                    
                    AnimattoToggleRow(
                        "Character Memory Store",
                        description: "Retains local memories of past encounters and user topic preferences (100% offline)",
                        icon: "memorychip",
                        isOn: $memoryEnabled
                    )
                    
                    if memoryEnabled {
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clear All Memories")
                                    .font(.system(size: 13))
                                Text("Permanently erase all stored interaction memories across all companions")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Clear All Memories", role: .destructive) {
                                showClearMemoriesAlert = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .confirmationDialog("Clear Memories", isPresented: $showClearMemoriesAlert) {
                                Button("Delete All Memories", role: .destructive) {
                                    memoryStore.clearAllMemories()
                                }
                            } message: {
                                Text("Are you sure you want to delete all recorded companion memories? This cannot be undone.")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var integrationsSection: some View {
        VStack(alignment: .leading, spacing: AnimattoTheme.space16) {
            AnimattoSectionHeader(
                title: "Desktop Integrations",
                subtitle: "Local system observers and application coordination.",
                icon: "link"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                    AnimattoToggleRow(
                        "Discord Rich Presence",
                        description: "Displays your roaming desktop companion in Discord status (via local IPC socket, zero external SDKs)",
                        icon: "gamecontroller",
                        isOn: $discordRPCEnabled
                    )
                    
                    Divider()
                    
                    AnimattoToggleRow(
                        "Music Playback Synchronization",
                        description: "Coordinates companion dance animations with active Spotify and Apple Music tracks",
                        icon: "music.note",
                        isOn: $musicSyncEnabled
                    )
                }
            }
            
            AnimattoSectionHeader(
                title: "Privacy & Screen Awareness",
                subtitle: "Optional visual intelligence strictly gated by user consent.",
                icon: "shield.fill"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("100% Offline & Private")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Animatto never captures raw keystrokes, personal windows, or network data.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    AnimattoToggleRow(
                        "Screen Context Awareness",
                        description: "Allows companions to make witty, personality-tailored comments about permitted active app categories",
                        icon: "eye",
                        isOn: $screenService.isEnabled
                    )
                }
            }
        }
    }
    
    private var updatesAndAboutSection: some View {
        VStack(alignment: .leading, spacing: AnimattoTheme.space16) {
            AnimattoSectionHeader(
                title: "Software Updates",
                subtitle: "Transparent SemVer release discovery with macOS Gatekeeper verification.",
                icon: "arrow.down.circle.fill"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Version")
                                .font(.system(size: 13, weight: .semibold))
                            Text("v1.2.0 (Build 3) • Universal Binary")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Check for Updates") {
                            Task {
                                await updateService.checkForUpdates(isManualCheck: true)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    
                    Divider()
                    
                    AnimattoToggleRow(
                        "Automatic Background Checks",
                        description: "Periodically check official GitHub releases (zero binary auto-replacement)",
                        icon: "clock.arrow.circlepath",
                        isOn: $updateConfig.automaticCheckEnabled
                    )
                }
            }
            
            AnimattoSectionHeader(
                title: "Open Source Ethos & Licensing",
                subtitle: "Permissive, offline, and community-driven.",
                icon: "heart.fill"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                    HStack {
                        Text("License")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        AnimattoBadge("Apache-2.0", icon: "doc.text.fill", color: .blue)
                    }
                    
                    Text("Animatto is 100% free and open source. All desktop companions, physics engines, Aquarium Mode, and Apple Vision tools run offline without paywalls, subscriptions, license keys, or tracking telemetry.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        Link(destination: URL(string: "https://github.com/sharmao07/Animatto")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                Text("GitHub Repository")
                            }
                            .font(.system(size: 11))
                        }
                        
                        Link(destination: URL(string: "https://github.com/sharmao07/Animatto/issues")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "ladybug.fill")
                                Text("Report Bug / Feedback")
                            }
                            .font(.system(size: 11))
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}
