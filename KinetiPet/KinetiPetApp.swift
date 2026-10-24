import SwiftUI
import AppKit
import UniformTypeIdentifiers
import Combine

@main
struct KinetiPetApp: App {
    // Assuming you have your PetManager initialized here
    @StateObject var petManager = PetManager()
    
    var body: some Scene {
        // 1. The Main App Window
        WindowGroup {
            MainAppView()
                .environmentObject(petManager)
        }
        
        // 2. The Premium Menu Bar Integration
        // This places an icon right next to the user's WiFi/Battery indicators
        MenuBarExtra("KinetiPet", systemImage: "hare.fill") {
            MenuBarDashboard()
                .environmentObject(petManager)
        }
        // Using .window instead of .menu makes it a sleek, interactive popover panel
        .menuBarExtraStyle(.window)
    }
}
