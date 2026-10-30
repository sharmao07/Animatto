import Foundation
import SwiftUI

// MARK: - Notification for Reopening Main Window
extension Notification.Name {
    static let reopenAnimattoMainWindow = Notification.Name("reopenAnimattoMainWindow")
}


struct MenuBarDashboard: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var petManager: PetManager
    @ObservedObject private var timerManager = ProductivityTimerManager.shared
    @ObservedObject private var updateService = UpdateService.shared
    
    // Connect to global settings
    @AppStorage("appAccentHex") private var appAccentHex = "007AFF"
    
    // Mini-Dashboard Controls
    @AppStorage("isPhysicsPaused") private var isPhysicsPaused = false
    @AppStorage("isMuted") private var isMuted = false
    @AppStorage("upsideDownMenuMode") private var upsideDownMenuMode = false
    
    @ObservedObject private var ambientEngine = AmbientEngine.shared
    @ObservedObject private var minigameManager = AmbientMinigameManager.shared
    @ObservedObject private var audioSettings = AudioSettings.shared
    @StateObject private var storage = PetStorage()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Header
            HStack {
                Text("Animatto")
                    .font(.headline)
                    .bold()
                
                Spacer()
                
                // Quick access to bring the heavy main window to the front
                Button(action: openMainWindow) {
                    Image(systemName: "slider.horizontal.3")
                }
                .buttonStyle(.plain)
                .foregroundColor(Color(hex: appAccentHex))
                .help("Open Full Settings")
            }
            
            Divider()
            
            // Quick Toggles
            VStack(spacing: 12) {
                if petManager.isPrivacyShieldActive {
                    HStack {
                        Image(systemName: "shield.fill").foregroundColor(.orange)
                        Text("Privacy Shield Active")
                            .font(.caption).bold().foregroundColor(.orange)
                        Spacer()
                        Button("Resume") {
                            petManager.resumeAllCompanionsAndMonitoring()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.orange)
                    }
                    .padding(6)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(6)
                }
                
                Button(action: {
                    if petManager.isPrivacyShieldActive {
                        petManager.resumeAllCompanionsAndMonitoring()
                    } else {
                        petManager.pauseAllCompanionsAndMonitoring()
                    }
                }) {
                    HStack {
                        Image(systemName: petManager.isPrivacyShieldActive ? "play.circle.fill" : "shield.slash.fill")
                        Text(petManager.isPrivacyShieldActive ? "Resume All Companions" : "Privacy Shield: Pause All & Monitoring")
                            .font(.caption2).bold()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Toggle("Pause Physics", isOn: $isPhysicsPaused)
                    .toggleStyle(.switch)
                    .tint(Color(hex: appAccentHex))
                
                Toggle("Mute Audio", isOn: Binding(
                    get: { audioSettings.isMasterMuted },
                    set: { newVal in
                        audioSettings.isMasterMuted = newVal
                        isMuted = newVal
                        AudioEngine.shared.updateAmbientVolume()
                    }
                ))
                    .toggleStyle(.switch)
                    .tint(Color(hex: appAccentHex))
                
                Toggle("Walk on Menu Bar", isOn: $upsideDownMenuMode)
                    .toggleStyle(.switch)
                    .tint(Color(hex: appAccentHex))
            }
            
            Divider()
            
            // Character Management
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Companions (\(petManager.activePets.count) active)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                if !petManager.activePets.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(Array(petManager.activePets.values)) { pet in
                            HStack {
                                Text(pet.name)
                                    .font(.caption)
                                    .bold()
                                    .lineLimit(1)
                                Spacer()
                                Button("Dismiss") {
                                    petManager.removePet(id: pet.id)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                    }
                } else {
                    Text("No companions roaming")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if !storage.savedPets.isEmpty {
                    Menu {
                        ForEach(storage.savedPets, id: \.self) { petURL in
                            Button(petURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")) {
                                petManager.launchPet(url: petURL, size: 128)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Launch Saved Companion...")
                                .font(.caption2)
                        }
                    }
                    .menuStyle(.borderlessButton)
                }
                
                Button(action: openMainWindow) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("Open Full Library")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: appAccentHex))
            }
            
            Divider()
            
            // Productivity & Focus Timer
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(timerManager.currentPhase == .idle ? "Productivity Timer" : timerManager.currentPhase.displayName, systemImage: "timer")
                        .font(.caption)
                        .bold()
                        .foregroundColor(timerManager.currentPhase == .breakTime ? .green : Color(hex: appAccentHex))
                    Spacer()
                    if timerManager.currentPhase != .idle {
                        Text(timerManager.formattedRemainingTime)
                            .font(.system(.caption, design: .monospaced))
                            .bold()
                    }
                }
                
                if timerManager.currentPhase == .idle {
                    HStack(spacing: 6) {
                        Button("5m") { timerManager.start(mode: .countdown(minutes: 5)) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("15m") { timerManager.start(mode: .countdown(minutes: 15)) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("25m") { timerManager.start(mode: .pomodoro) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("50m") { timerManager.start(mode: .longFocus) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                } else {
                    ProgressView(value: timerManager.progress)
                        .tint(timerManager.currentPhase == .breakTime ? .green : Color(hex: appAccentHex))
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            if timerManager.isPaused {
                                timerManager.resume()
                            } else {
                                timerManager.pause()
                            }
                        }) {
                            Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help(timerManager.isPaused ? "Resume Session" : "Pause Session")
                        
                        if timerManager.currentMode.hasBreak {
                            Button(action: { timerManager.skip() }) {
                                Image(systemName: "forward.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Skip to next phase")
                        }
                        
                        Button(action: { timerManager.stop() }) {
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Stop Session")
                        
                        Spacer()
                    }
                }
            }
            
            Divider()
            
            // Ambient Worlds Quick Controls
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: ambientEngine.currentEnvironment.iconName)
                        .foregroundColor(ambientEngine.isEnabled ? .cyan : .secondary)
                    Text("Ambience")
                        .font(.caption).bold()
                    Spacer()
                    Toggle("", isOn: $ambientEngine.isEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }
                
                if ambientEngine.isEnabled {
                    HStack {
                        Picker("", selection: $ambientEngine.currentEnvironment) {
                            ForEach(AmbientEnvironmentType.allCases, id: \.self) { env in
                                Text(env.displayName).tag(env)
                            }
                        }
                        .labelsHidden()
                        .controlSize(.small)
                        
                        Button(action: {
                            if ambientEngine.isPaused {
                                ambientEngine.resume()
                            } else {
                                ambientEngine.pause()
                            }
                        }) {
                            Image(systemName: ambientEngine.isPaused ? "play.fill" : "pause.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help(ambientEngine.isPaused ? "Resume Ambience" : "Pause Ambience")
                    }
                    
                    // Minigame Quick Toggle
                    HStack {
                        Toggle("Minigame", isOn: $minigameManager.isGameEnabled)
                            .toggleStyle(.checkbox)
                            .font(.caption2)
                        Spacer()
                        if minigameManager.isSessionActive {
                            Text("Score: \(minigameManager.currentScore)")
                                .font(.caption2).bold().foregroundColor(.orange)
                        }
                    }
                }
            }
            
            Divider()
            
            // Available Update Banner
            if let release = updateService.availableRelease {
                HStack {
                    Image(systemName: "arrow.down.circle.fill").foregroundColor(.blue)
                    Text("Update: \(release.tagName)")
                        .font(.caption2).bold()
                    Spacer()
                    Button("View") {
                        updateService.openReleaseWebPage(url: release.htmlURL)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                .padding(6)
                .background(Color.blue.opacity(0.12))
                .cornerRadius(6)
            }
            
            // Footer Navigation & Actions
            HStack {
                Button("Check for Updates") {
                    Task {
                        await updateService.checkForUpdates(isManualCheck: true)
                    }
                }
                .buttonStyle(.plain)
                .font(.caption2)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Quit Animatto") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.gray)
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() }
                    else { NSCursor.pop() }
                }
            }
        }
        .padding()
        // Locks the popover to a clean, fixed size
        .frame(width: 260)
        .onReceive(NotificationCenter.default.publisher(for: .reopenAnimattoMainWindow)) { _ in
            openMainWindow()
        }
    }
    
    // Helper function to summon the main window if it was closed
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
