import Foundation
import SwiftUI

struct MenuBarDashboard: View {
    @EnvironmentObject var petManager: PetManager
    
    // Connect to global settings
    @AppStorage("appAccentHex") private var appAccentHex = "007AFF"
    
    // Mini-Dashboard Controls
    @AppStorage("isPhysicsPaused") private var isPhysicsPaused = false
    @AppStorage("isMuted") private var isMuted = false
    @AppStorage("upsideDownMenuMode") private var upsideDownMenuMode = false
    
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
                Toggle("Pause Physics", isOn: $isPhysicsPaused)
                    .toggleStyle(.switch)
                    .tint(Color(hex: appAccentHex))
                
                Toggle("Mute Audio", isOn: $isMuted)
                    .toggleStyle(.switch)
                    .tint(Color(hex: appAccentHex))
                
                Toggle("Walk on Menu Bar", isOn: $upsideDownMenuMode)
                    .toggleStyle(.switch)
                    .tint(Color(hex: appAccentHex))
            }
            
            Divider()
            
            // Character Management
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Companion")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Button(action: openMainWindow) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("Open Library to Swap")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: appAccentHex))
            }
            
            Divider()
            
            // Footer Quit Button (Crucial for Menu Bar Apps)
            HStack {
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
    }
    
    // Helper function to summon the main window if it was closed
    private func openMainWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "Animatto" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
