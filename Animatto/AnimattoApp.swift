import SwiftUI
import AppKit
import UniformTypeIdentifiers
import Combine


// MARK: - App Delegate for macOS Lifecycle & Reopen Handling
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?
    
    override init() {
        super.init()
        AppDelegate.shared = self
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            let hasVisibleNormalWindow = NSApp.windows.contains { $0.isVisible && $0.level == .normal }
            if !hasVisibleNormalWindow {
                self?.openMainWindow()
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openMainWindow()
        }
        return true
    }
    
    func openMainWindow() {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { ($0.title == "Animatto" || $0.canBecomeMain) && $0.level == .normal }) {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                NotificationCenter.default.post(name: .reopenAnimattoMainWindow, object: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    // MARK: - Cocoa First Responder Standard Selectors
    @objc func newDocument(_ sender: Any?) {
        openMainWindow()
        NotificationCenter.default.post(name: .animattoAddNewCompanion, object: nil)
    }
    
    @objc func openDocument(_ sender: Any?) {
        openMainWindow()
        NotificationCenter.default.post(name: .animattoImportCompanion, object: nil)
    }
    
    @objc func resetCompanionPositions(_ sender: Any?) {
        NotificationCenter.default.post(name: .animattoResetPositions, object: nil)
    }
    
    @objc func toggleUpsideDownMode(_ sender: Any?) {
        NotificationCenter.default.post(name: .animattoToggleUpsideDown, object: nil)
    }
    
    @objc func toggleAmbience(_ sender: Any?) {
        NotificationCenter.default.post(name: .animattoToggleAmbience, object: nil)
    }
    
    @objc func toggleMute(_ sender: Any?) {
        NotificationCenter.default.post(name: .animattoToggleMute, object: nil)
    }
    
    @objc func bringCompanionsToFront(_ sender: Any?) {
        NotificationCenter.default.post(name: .animattoBringPetsToFront, object: nil)
    }
    
    @objc func hideAllCompanions(_ sender: Any?) {
        NotificationCenter.default.post(name: .animattoHideAllPets, object: nil)
    }
    
    @objc func checkForUpdates(_ sender: Any?) {
        Task {
            await UpdateService.shared.checkForUpdates(isManualCheck: true)
        }
    }
}

@main
struct AnimattoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var petManager = PetManager()
    
    var body: some Scene {
        // 1. The Main App Window
        WindowGroup("Animatto", id: "main") {
            MainAppView()
                .environmentObject(petManager)
        }
        .handlesExternalEvents(matching: ["main", "*"])
        .commands {
            AnimattoMenuCommands()
        }
        
        // 2. The Premium Menu Bar Integration
        // This places an icon right next to the user's WiFi/Battery indicators
        MenuBarExtra("Animatto", systemImage: "hare.fill") {
            MenuBarDashboard()
                .environmentObject(petManager)
        }
        // Using .window instead of .menu makes it a sleek, interactive popover panel
        .menuBarExtraStyle(.window)
    }
}
