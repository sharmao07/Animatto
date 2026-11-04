import SwiftUI
import AppKit

// MARK: - Companion Focus Behavior Extension
extension FocusCompanionBehavior {
    var explanation: String {
        switch self {
        case .sleepQuietly: return "Companions nap peacefully and silence dialogue during active focus blocks."
        case .sitIdle: return "Companions sit quietly near the corner of your screen without wandering."
        case .normal: return "Companions roam and explore normally with standard desktop physics."
        }
    }
}

// MARK: - Productivity & Focus Sessions View (Phase 2 Redesign)
// Clean, native focus console coordinating companion behaviors with Pomodoro cycles.

public struct ProductivityFocusView: View {
    @ObservedObject private var timerManager = ProductivityTimerManager.shared
    @State private var customMinutes: Double = 25
    @State private var customBreakMinutes: Double = 5
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AnimattoTheme.space20) {
                
                // 1. Header
                VStack(alignment: .leading, spacing: 3) {
                    Text("Productivity & Focus")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Coordinate companion behaviors with deep work intervals and Pomodoro cycles.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // 2. Timer Hero Display
                AnimattoCard(padding: AnimattoTheme.space20) {
                    VStack(spacing: AnimattoTheme.space16) {
                        HStack {
                            AnimattoBadge(
                                timerManager.currentPhase.displayName,
                                icon: timerManager.currentPhase == .breakTime ? "cup.and.saucer.fill" : (timerManager.currentPhase == .focus ? "brain.head.profile" : "timer"),
                                color: timerManager.currentPhase == .breakTime ? .green : (timerManager.isPaused ? .orange : .accentColor)
                            )
                            
                            Spacer()
                            
                            if timerManager.currentPhase != .idle {
                                Text(timerManager.currentMode.hasBreak ? "Pomodoro Cycle" : "Countdown")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Digital Clock Readout
                        Text(timerManager.formattedRemainingTime)
                            .font(.system(size: 56, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(.vertical, AnimattoTheme.space8)
                        
                        // Progress Bar
                        ProgressView(value: timerManager.progress)
                            .progressViewStyle(.linear)
                            .tint(timerManager.currentPhase == .breakTime ? .green : .accentColor)
                        
                        // Lifecycle Buttons
                        HStack(spacing: AnimattoTheme.space12) {
                            if timerManager.currentPhase == .idle {
                                Button(action: {
                                    timerManager.start(mode: .pomodoro)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.fill")
                                        Text("Start Pomodoro (25m)")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            } else {
                                Button(action: {
                                    if timerManager.isPaused {
                                        timerManager.resume()
                                    } else {
                                        timerManager.pause()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                                        Text(timerManager.isPaused ? "Resume" : "Pause")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                
                                if timerManager.currentMode.hasBreak {
                                    Button(action: {
                                        timerManager.skip()
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "forward.fill")
                                            Text("Skip Phase")
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.large)
                                }
                                
                                Button(action: {
                                    timerManager.stop()
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "stop.fill")
                                        Text("Stop")
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                        }
                    }
                }
                
                // 3. Quick Mode Presets
                VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                    AnimattoSectionHeader(
                        title: "Focus Presets",
                        subtitle: "One-click timer setups tailored for different work rhythms.",
                        icon: "bolt.fill"
                    )
                    
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        presetCard(
                            title: "25m Pomodoro",
                            subtitle: "25m focus / 5m break",
                            icon: "timer",
                            action: { timerManager.start(mode: .pomodoro) }
                        )
                        
                        presetCard(
                            title: "50m Deep Work",
                            subtitle: "50m focus / 10m long break",
                            icon: "brain.head.profile",
                            action: { timerManager.start(mode: .longFocus) }
                        )
                        
                        presetCard(
                            title: "15m Quick Sprint",
                            subtitle: "15m single countdown",
                            icon: "bolt.fill",
                            action: { timerManager.start(mode: .countdown(minutes: 15)) }
                        )
                        
                        presetCard(
                            title: "5m Rapid Task",
                            subtitle: "5m single countdown",
                            icon: "flame.fill",
                            action: { timerManager.start(mode: .countdown(minutes: 5)) }
                        )
                    }
                }
                
                // 4. Companion Focus Settings
                VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                    AnimattoSectionHeader(
                        title: "Companion Focus Reactions",
                        subtitle: "Dictate how desktop companions behave during active focus sessions.",
                        icon: "pawprint.fill"
                    )
                    
                    AnimattoCard {
                        VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                            HStack {
                                Text("Focus Behavior")
                                    .font(.system(size: 13, weight: .regular))
                                Spacer()
                                Picker("", selection: $timerManager.companionFocusBehavior) {
                                    ForEach(FocusCompanionBehavior.allCases, id: \.self) { behavior in
                                        Text(behavior.displayName).tag(behavior)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 320)
                            }
                            
                            Text(timerManager.companionFocusBehavior.explanation)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            AnimattoToggleRow(
                                "Distraction Suppression",
                                description: "Silences spontaneous companion idle chatter and spontaneous social encounters while focusing",
                                icon: "bubble.left.and.exclamationmark.bubble.right",
                                isOn: .constant(true)
                            )
                            .disabled(true)
                        }
                    }
                }
            }
            .padding(AnimattoTheme.space20)
        }
    }
    
    private func presetCard(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            AnimattoCard(padding: AnimattoTheme.space12) {
                HStack(spacing: AnimattoTheme.space12) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
