import Foundation
import SwiftUI

// MARK: - Notification for Reopening Main Window
extension Notification.Name {
    static let reopenAnimattoMainWindow = Notification.Name("reopenAnimattoMainWindow")
}

// MARK: - MenuBarDashboard (Phase 2 Native Redesign)
// Compact, beautifully balanced popover panel with 2x2 quick toggle grid and streamlined sections.
struct MenuBarDashboard: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var petManager: PetManager
    @ObservedObject private var timerManager = ProductivityTimerManager.shared
    @ObservedObject private var updateService = UpdateService.shared
    @ObservedObject private var ambientEngine = AmbientEngine.shared
    @ObservedObject private var minigameManager = AmbientMinigameManager.shared
    @ObservedObject private var audioSettings = AudioSettings.shared
    @ObservedObject private var aquariumManager = AquariumManager.shared
    @StateObject private var storage = PetStorage()
    
    // Global Settings & Theming
    @ObservedObject private var themeManager = AnimattoThemeManager.shared
    @AppStorage("isPhysicsPaused") private var isPhysicsPaused = false
    @AppStorage("upsideDownMenuMode") private var upsideDownMenuMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: AnimattoTheme.space8) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(themeManager.currentAccentColor)
                
                Text("Animatto")
                    .font(.system(size: 13, weight: .bold))
                
                Spacer()
                
                Button(action: openMainWindow) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open Main Window")
            }
            .padding(.horizontal, AnimattoTheme.space12)
            .padding(.vertical, 10)
            
            Divider()
            
            // Body Content
            VStack(spacing: AnimattoTheme.space10) {
                    
                    // 1. Privacy Shield Active Banner
                    if petManager.isPrivacyShieldActive {
                        HStack(spacing: 6) {
                            Image(systemName: "shield.slash.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                            Text("Privacy Shield Active")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                            Spacer()
                            Button("Resume") {
                                petManager.resumeAllCompanionsAndMonitoring()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.mini)
                            .tint(.orange)
                        }
                        .padding(AnimattoTheme.space8)
                        .background(RoundedRectangle(cornerRadius: AnimattoTheme.radius6).fill(Color.orange.opacity(0.12)))
                    }
                    
                    // 2. 2x2 Quick Controls Grid
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            // Toggle 1: Privacy Shield
                            quickToggleButton(
                                title: petManager.isPrivacyShieldActive ? "Shield On" : "Shield Off",
                                icon: petManager.isPrivacyShieldActive ? "shield.fill" : "shield",
                                isActive: petManager.isPrivacyShieldActive,
                                activeColor: .orange
                            ) {
                                if petManager.isPrivacyShieldActive {
                                    petManager.resumeAllCompanionsAndMonitoring()
                                } else {
                                    petManager.pauseAllCompanionsAndMonitoring()
                                }
                            }
                            
                            // Toggle 2: Physics Pause
                            quickToggleButton(
                                title: isPhysicsPaused ? "Physics Paused" : "Physics Active",
                                icon: isPhysicsPaused ? "pause.fill" : "play.fill",
                                isActive: isPhysicsPaused,
                                activeColor: .blue
                            ) {
                                isPhysicsPaused.toggle()
                            }
                        }
                        
                        HStack(spacing: 6) {
                            // Toggle 3: Master Mute
                            quickToggleButton(
                                title: audioSettings.isMasterMuted ? "Sound Muted" : "Sound On",
                                icon: audioSettings.isMasterMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                                isActive: audioSettings.isMasterMuted,
                                activeColor: .secondary
                            ) {
                                audioSettings.isMasterMuted.toggle()
                                AudioEngine.shared.updateAmbientVolume()
                            }
                            
                            // Toggle 4: Walk on Menu Bar
                            quickToggleButton(
                                title: upsideDownMenuMode ? "Menu Bar Walk" : "Floor Walk",
                                icon: upsideDownMenuMode ? "menubar.arrow.up.rectangle" : "arrow.down.to.line",
                                isActive: upsideDownMenuMode,
                                activeColor: themeManager.currentAccentColor
                            ) {
                                upsideDownMenuMode.toggle()
                            }
                        }
                    }
                    
                    // 3. Active Companions Row
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Companions")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            AnimattoBadge("\(petManager.activePets.count) roaming")
                        }
                        
                        if !petManager.activePets.isEmpty {
                            VStack(spacing: 4) {
                                ForEach(Array(petManager.activePets.values)) { pet in
                                    HStack(spacing: 6) {
                                        Circle().fill(Color.green).frame(width: 6, height: 6)
                                        Text(pet.name)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                        Spacer()
                                        Button("Dismiss") {
                                            petManager.removePet(id: pet.id)
                                        }
                                        .buttonStyle(.borderless)
                                        .font(.system(size: 10))
                                        .foregroundColor(.red)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: AnimattoTheme.radius6).fill(Color.primary.opacity(0.04)))
                                }
                            }
                        } else {
                            Text("No companions currently roaming")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)
                        }
                        
                        // Launch saved companion menu
                        if !storage.savedPets.isEmpty {
                            Menu {
                                ForEach(storage.savedPets, id: \.self) { petURL in
                                    Button(petURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")) {
                                        petManager.launchPet(url: petURL, size: 128)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Spawn Companion...")
                                }
                                .font(.system(size: 10, weight: .medium))
                            }
                            .menuStyle(.borderlessButton)
                        }
                    }
                    .padding(AnimattoTheme.space8)
                    .background(RoundedRectangle(cornerRadius: AnimattoTheme.radius8).fill(Color(nsColor: .controlBackgroundColor).opacity(0.5)))
                    .overlay(RoundedRectangle(cornerRadius: AnimattoTheme.radius8).stroke(AnimattoTheme.subtleBorder, lineWidth: AnimattoTheme.hairline))
                    
                    // 4. Aquarium Mode Quick Strip
                    HStack(spacing: 8) {
                        Image(systemName: "water.waves")
                            .font(.system(size: 12))
                            .foregroundColor(.cyan)
                        
                        Text("Aquarium Mode")
                            .font(.system(size: 11, weight: .medium))
                        
                        Spacer()
                        
                        if aquariumManager.isAquariumModeActive {
                            Button("Feed") {
                                aquariumManager.feedFlakes(count: 3)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                        
                        Toggle("", isOn: Binding(
                            get: { aquariumManager.isAquariumModeActive },
                            set: { val in
                                if val { aquariumManager.enableAquariumMode() }
                                else { aquariumManager.disableAquariumMode() }
                            }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                    }
                    .padding(AnimattoTheme.space8)
                    .background(RoundedRectangle(cornerRadius: AnimattoTheme.radius8).fill(Color(nsColor: .controlBackgroundColor).opacity(0.5)))
                    .overlay(RoundedRectangle(cornerRadius: AnimattoTheme.radius8).stroke(AnimattoTheme.subtleBorder, lineWidth: AnimattoTheme.hairline))
                    
                    // 5. Productivity Strip
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "timer")
                                .font(.system(size: 12))
                                .foregroundColor(timerManager.currentPhase == .breakTime ? .green : themeManager.currentAccentColor)
                            Text(timerManager.currentPhase == .idle ? "Focus Timer" : timerManager.currentPhase.displayName)
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            if timerManager.currentPhase != .idle {
                                Text(timerManager.formattedRemainingTime)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            }
                        }
                        
                        if timerManager.currentPhase == .idle {
                            HStack(spacing: 4) {
                                Button("15m") { timerManager.start(mode: .countdown(minutes: 15)) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                Button("25m") { timerManager.start(mode: .pomodoro) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                Button("50m") { timerManager.start(mode: .longFocus) }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                            }
                        } else {
                            ProgressView(value: timerManager.progress)
                                .controlSize(.small)
                                .tint(timerManager.currentPhase == .breakTime ? .green : themeManager.currentAccentColor)
                            
                            HStack(spacing: 6) {
                                Button(timerManager.isPaused ? "Resume" : "Pause") {
                                    if timerManager.isPaused { timerManager.resume() }
                                    else { timerManager.pause() }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                                
                                Button("Stop") { timerManager.stop() }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                            }
                        }
                    }
                    .padding(AnimattoTheme.space8)
                    .background(RoundedRectangle(cornerRadius: AnimattoTheme.radius8).fill(Color(nsColor: .controlBackgroundColor).opacity(0.5)))
                    .overlay(RoundedRectangle(cornerRadius: AnimattoTheme.radius8).stroke(AnimattoTheme.subtleBorder, lineWidth: AnimattoTheme.hairline))
                }
                .padding(AnimattoTheme.space10)
            
            Divider()
            
            // Footer Navigation
            HStack {
                Button("Open Library") { openMainWindow() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.currentAccentColor)
                
                Spacer()
                
                if !petManager.activePets.isEmpty {
                    Button(action: {
                        petManager.dismissAllCompanions()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "trash")
                            Text("Delete All")
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, AnimattoTheme.space12)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
        .onReceive(NotificationCenter.default.publisher(for: .reopenAnimattoMainWindow)) { _ in
            openMainWindow()
        }
    }
    
    private func quickToggleButton(title: String, icon: String, isActive: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isActive ? activeColor : .secondary)
                Text(title)
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .primary : .secondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: AnimattoTheme.radius6)
                    .fill(isActive ? activeColor.opacity(0.12) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AnimattoTheme.radius6)
                    .stroke(isActive ? activeColor.opacity(0.3) : AnimattoTheme.subtleBorder, lineWidth: AnimattoTheme.hairline)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func openMainWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "Animatto" || ($0.canBecomeMain && $0.level == .normal) }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
