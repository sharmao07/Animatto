import SwiftUI
import AppKit
import Combine

// MARK: - Animatto Menu Notification Identifiers
public extension Notification.Name {
    static let animattoAddNewCompanion = Notification.Name("com.dev.Animatto.addNewCompanion")
    static let animattoImportCompanion = Notification.Name("com.dev.Animatto.importCompanion")
    static let animattoSelectTab = Notification.Name("com.dev.Animatto.selectTab")
    static let animattoResetPositions = Notification.Name("com.dev.Animatto.resetPositions")
    static let animattoToggleUpsideDown = Notification.Name("com.dev.Animatto.toggleUpsideDown")
    static let animattoToggleAmbience = Notification.Name("com.dev.Animatto.toggleAmbience")
    static let animattoToggleMute = Notification.Name("com.dev.Animatto.toggleMute")
    static let animattoBringPetsToFront = Notification.Name("com.dev.Animatto.bringPetsToFront")
    static let animattoHideAllPets = Notification.Name("com.dev.Animatto.hideAllPets")
}

// MARK: - Native macOS Menu Bar Commands
public struct AnimattoMenuCommands: Commands {
    public init() {}
    
    public var body: some Commands {
        // 1. File Menu: Add Companion, Import, Close Window
        CommandGroup(replacing: .newItem) {
            Button("Add Companion...") {
                NotificationCenter.default.post(name: .animattoAddNewCompanion, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("Import Companion File...") {
                NotificationCenter.default.post(name: .animattoImportCompanion, object: nil)
            }
            .keyboardShortcut("o", modifiers: .command)
            
            Divider()
            
            Button("Close Window") {
                NSApp.keyWindow?.performClose(nil)
            }
            .keyboardShortcut("w", modifiers: .command)
        }
        
        // 2. Standard Text Editing Commands (Cut, Copy, Paste, Select All, Undo, Redo)
        TextEditingCommands()
        
        // 3. View Menu: Tabs, Positions, Ambience, Upside-Down Mode
        CommandMenu("View") {
            Button("Library") {
                NotificationCenter.default.post(name: .animattoSelectTab, object: "Library")
            }
            .keyboardShortcut("1", modifiers: .command)
            
            Button("Workshop") {
                NotificationCenter.default.post(name: .animattoSelectTab, object: "Workshop")
            }
            .keyboardShortcut("2", modifiers: .command)
            
            Button("Settings") {
                NotificationCenter.default.post(name: .animattoSelectTab, object: "Settings")
            }
            .keyboardShortcut("3", modifiers: .command)
            
            Divider()
            
            Button("Reset All Companion Positions") {
                NotificationCenter.default.post(name: .animattoResetPositions, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            
            Button("Toggle Upside-Down Menu Bar Mode") {
                NotificationCenter.default.post(name: .animattoToggleUpsideDown, object: nil)
            }
            .keyboardShortcut("u", modifiers: [.command, .option])
            
            Button("Toggle Desktop Ambience") {
                NotificationCenter.default.post(name: .animattoToggleAmbience, object: nil)
            }
            .keyboardShortcut("a", modifiers: [.command, .option])
            
            Button("Toggle Sound Mute") {
                NotificationCenter.default.post(name: .animattoToggleMute, object: nil)
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
        }
        
        // 4. Window Menu: Standard arrangements plus companion controls
        CommandGroup(after: .windowArrangement) {
            Divider()
            
            Button("Bring All Companions to Front") {
                NotificationCenter.default.post(name: .animattoBringPetsToFront, object: nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .option])
            
            Button("Hide All Companions") {
                NotificationCenter.default.post(name: .animattoHideAllPets, object: nil)
            }
            .keyboardShortcut("h", modifiers: [.command, .option])
        }
        
        // 5. Help Menu: Documentation, Release Notes, Licensing, Updates
        CommandGroup(replacing: .help) {
            Button("Animatto Documentation") {
                if let url = URL(string: "https://github.com/sharmao07/Animatto#readme") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Button("Release Notes") {
                if let url = URL(string: "https://github.com/sharmao07/Animatto/releases") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Button("Audio Licensing & Attribution") {
                if let url = URL(string: "https://github.com/sharmao07/Animatto/blob/main/docs/AUDIO_LICENSES.md") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Divider()
            
            Button("Check for Updates...") {
                Task {
                    await UpdateService.shared.checkForUpdates(isManualCheck: true)
                }
            }
            .keyboardShortcut("u", modifiers: .command)
        }
    }
}

// MARK: - Liquid Glass Vibrancy View (NSVisualEffectView)
public struct LiquidGlassView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State
    
    public init(
        material: NSVisualEffectView.Material = .underWindowBackground,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.autoresizingMask = [.width, .height]
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Window Accessor for Dynamic Vibrancy & Translucency
public struct WindowAccessorView: NSViewRepresentable {
    public var onWindowFound: (NSWindow) -> Void
    
    public init(onWindowFound: @escaping (NSWindow) -> Void) {
        self.onWindowFound = onWindowFound
    }
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindowFound(window)
            }
        }
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onWindowFound(window)
            }
        }
    }
}

// MARK: - Dynamic Adaptive Accent & Appearance Helper
public struct AppearanceThemeManager {
    public static func opacityLevels(isDark: Bool, isLiquidGlass: Bool) -> (top: Double, middle: Double) {
        if isLiquidGlass {
            return (top: isDark ? 0.14 : 0.08, middle: isDark ? 0.05 : 0.02)
        } else {
            return (top: isDark ? 0.22 : 0.14, middle: isDark ? 0.08 : 0.04)
        }
    }
    
    public static func adaptiveGradient(accentHex: String, isDark: Bool, isLiquidGlass: Bool) -> LinearGradient {
        let accent = Color(hex: accentHex)
        let levels = opacityLevels(isDark: isDark, isLiquidGlass: isLiquidGlass)
        return LinearGradient(
            gradient: Gradient(colors: [
                accent.opacity(levels.top),
                accent.opacity(levels.middle),
                Color.clear
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Color Hex Conversion Extension
public extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    func toHex() -> String {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return "007AFF" }
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(format: "%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }
}
