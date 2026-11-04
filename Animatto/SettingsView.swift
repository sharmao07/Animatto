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
    @ObservedObject private var entitlementManager = EntitlementManager.shared
    
    @State private var activeCategory: SettingsTabCategory = .general
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)
    @State private var showCacheAlert = false
    @State private var clearedCacheCount = 0
    @State private var showClearMemoriesAlert = false
    @State private var showLicenseSheet = false
    @State private var diagnosticsCopied = false
    @State private var supporterConsent = EntitlementManager.shared.supporterConsentEnabled
    @State private var supporterName = EntitlementManager.shared.supporterDisplayName
    @State private var customHexText = ""
    @State private var hexError: String? = nil
    
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
    
    @ObservedObject private var themeManager = AnimattoThemeManager.shared
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
        .sheet(isPresented: $showLicenseSheet) {
            FreeVsPremiumSheet()
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
                VStack(alignment: .leading, spacing: AnimattoTheme.space16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Theme Preset Swatches")
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text(themeManager.isSystemAccent ? "macOS System Accent" : "#\(themeManager.currentAccentHex.uppercased())")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Text("Applied live to selection indicators, primary action buttons, sliders, and highlights.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    // Preset Swatches Grid
                    HStack(spacing: AnimattoTheme.space8) {
                        ForEach(AnimattoAccentPreset.allCases) { preset in
                            let isSelected = (themeManager.activeProPalette == nil && preset.defaultHex.uppercased() == themeManager.currentAccentHex.uppercased())
                            Button(action: {
                                themeManager.setPreset(preset)
                                AudioEngine.shared.playUISound(.select)
                            }) {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(preset.previewColor)
                                            .frame(width: 28, height: 28)
                                            .shadow(color: preset.previewColor.opacity(isSelected ? 0.45 : 0.15), radius: isSelected ? 4 : 2, y: 1)
                                        
                                        if isSelected {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .frame(width: 28, height: 28)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    Text(preset.title)
                                        .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                                        .foregroundColor(isSelected ? .primary : .secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: AnimattoTheme.radius8)
                                        .fill(isSelected ? AnimattoTheme.accentColor.opacity(0.12) : Color.primary.opacity(0.03))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AnimattoTheme.radius8)
                                        .stroke(isSelected ? AnimattoTheme.accentColor : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Divider()
                    
                    // Pro Theme Palettes Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Pro Custom Palettes")
                                        .font(.system(size: 13, weight: .semibold))
                                    if entitlementManager.isEntitled(to: .proCustomPalettes) {
                                        AnimattoBadge("Pro Active", icon: "sparkles", color: .purple)
                                    } else {
                                        AnimattoBadge("Pro Feature", icon: "lock.fill", color: .secondary)
                                    }
                                }
                                Text("Dual-tone color gradations crafted for dark and light desktop environments.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        HStack(spacing: AnimattoTheme.space8) {
                            ForEach(AnimattoProPalette.allCases) { palette in
                                let isSelected = (themeManager.activeProPalette == palette)
                                Button(action: {
                                    if entitlementManager.isEntitled(to: .proCustomPalettes) {
                                        themeManager.setProPalette(palette)
                                        AudioEngine.shared.playUISound(.select)
                                    } else {
                                        showLicenseSheet = true
                                        AudioEngine.shared.playUISound(.click)
                                    }
                                }) {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(palette.gradient)
                                                .frame(width: 28, height: 28)
                                                .shadow(color: palette.primaryColor.opacity(isSelected ? 0.45 : 0.15), radius: isSelected ? 4 : 2, y: 1)
                                            
                                            if isSelected {
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                                    .frame(width: 28, height: 28)
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.white)
                                            } else if !entitlementManager.isEntitled(to: .proCustomPalettes) {
                                                Image(systemName: "lock.fill")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.white.opacity(0.85))
                                            }
                                        }
                                        
                                        Text(palette.title)
                                            .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                                            .foregroundColor(isSelected ? .primary : .secondary)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: AnimattoTheme.radius8)
                                            .fill(isSelected ? palette.primaryColor.opacity(0.12) : Color.primary.opacity(0.03))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AnimattoTheme.radius8)
                                            .stroke(isSelected ? palette.primaryColor : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Custom Color Picker & Hex Input
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Custom Hex Color")
                                    .font(.system(size: 13))
                                if !entitlementManager.isEntitled(to: .proCustomPalettes) {
                                    AnimattoBadge("Pro Feature", icon: "lock.fill", color: .secondary)
                                }
                            }
                            Text("Pick or type any 6-digit hex color for complete visual personalization")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        if entitlementManager.isEntitled(to: .proCustomPalettes) {
                            ColorPicker("", selection: Binding(
                                get: { themeManager.currentAccentColor },
                                set: { newColor in
                                    themeManager.setHex(newColor.toHex())
                                }
                            ))
                            .labelsHidden()
                        } else {
                            Button("Unlock Pro") {
                                showLicenseSheet = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
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
            
            AnimattoSectionHeader(
                title: "Animatto Pro & Licensing",
                subtitle: "Support open-source development with Lifetime Pro ($3.99) or Founder Supporter ($5.99).",
                icon: "sparkles"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(entitlementManager.status.displayTitle)
                                    .font(.system(size: 13, weight: .semibold))
                                AnimattoBadge(
                                    entitlementManager.status.statusBadgeTitle,
                                    icon: "checkmark.circle.fill",
                                    color: entitlementManager.status == .unlicensed ? .blue : (entitlementManager.activePayload?.licenseTier == .founder ? .purple : .green)
                                )
                            }
                            Text(entitlementManager.status.statusSummary)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("View Tiers & Licensing") {
                            showLicenseSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
            
            if entitlementManager.isEntitled(to: .founderBadge) {
                AnimattoSectionHeader(
                    title: "Founder Supporter Recognition",
                    subtitle: "Exclusive supporter perks, priority beta access, and optional README recognition.",
                    icon: "crown.fill"
                )
                
                AnimattoCard {
                    VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Founder Supporter Perks Active")
                                        .font(.system(size: 13, weight: .semibold))
                                    AnimattoBadge("Founder Active", icon: "sparkles", color: .purple)
                                }
                                Text("All Pro capabilities permanently unlocked plus priority access to early release candidates.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Repository README Recognition")
                                        .font(.system(size: 13))
                                    Text("Acknowledge your support publicly in the official GitHub repository README.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { supporterConsent },
                                    set: { newValue in
                                        supporterConsent = newValue
                                        entitlementManager.updateSupporterConsent(enabled: newValue, supporterName: supporterName)
                                    }
                                ))
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .controlSize(.small)
                            }
                            
                            if supporterConsent {
                                HStack(spacing: 8) {
                                    TextField("Supporter Display Name", text: $supporterName)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 11))
                                    
                                    Button("Save") {
                                        entitlementManager.updateSupporterConsent(enabled: true, supporterName: supporterName)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            
                            Text("Privacy Notice: Supporter recognition requires explicit consent. You can withdraw your consent at any time without affecting your Founder license.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            AnimattoSectionHeader(
                title: "Diagnostics & Beta Feedback",
                subtitle: "Zero telemetry. Export privacy-sanitized breadcrumbs directly to your clipboard.",
                icon: "waveform.path.ecg"
            )
            
            AnimattoCard {
                VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Diagnostic Breadcrumbs")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Captures in-memory state, active widgets, and error logs with all usernames, emails, and tokens redacted.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            DiagnosticLogger.shared.copyToClipboard()
                            diagnosticsCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                diagnosticsCopied = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: diagnosticsCopied ? "checkmark" : "doc.on.doc")
                                Text(diagnosticsCopied ? "Copied!" : "Copy Diagnostics")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(diagnosticsCopied ? .green : .accentColor)
                        .controlSize(.small)
                    }
                    
                    HStack(spacing: 12) {
                        Text("Privacy Guarantee: Diagnostic logs are kept strictly in local RAM and never transmitted automatically.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
