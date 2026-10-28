import SwiftUI
import UniformTypeIdentifiers
import ServiceManagement

struct MainAppView: View {
    @EnvironmentObject var petManager: PetManager
    @State private var selectedTab = "Library"
    @State private var selectedFileURL: URL?
    
    // Read the saved color hex from storage (Defaults to standard Apple Blue)
    @AppStorage("appAccentHex") private var appAccentHex = "007AFF"
    
    var body: some View {
        ZStack {
            // 1. Base dark/light macOS window background
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            
            // 2. Premium Gradient Tint Layer
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: appAccentHex).opacity(0.30), // Strong color at the top
                    Color(hex: appAccentHex).opacity(0.10), // Smooth fade in the middle
                    Color.clear                             // Fades to standard background at bottom
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack(spacing: 20) {
                    Text("Animatto").font(.headline).bold()
                    
                    Button("Library") { selectedTab = "Library" }
                        .foregroundColor(selectedTab == "Library" ? Color(hex: appAccentHex) : .gray)
                    Button("Workshop") { selectedTab = "Workshop" }
                        .foregroundColor(selectedTab == "Workshop" ? Color(hex: appAccentHex) : .gray)
                    Button("Settings") { selectedTab = "Settings" }
                        .foregroundColor(selectedTab == "Settings" ? Color(hex: appAccentHex) : .gray)
                    
                    Spacer()
                }
                .padding()
                // A subtle glassmorphism effect for the top bar
                .background(Color.black.opacity(0.2))
                
                Divider()
                
                // Main Content Area
                if selectedTab == "Library" {
                    LibraryView(selectedFileURL: $selectedFileURL)
                } else if selectedTab == "Workshop" {
                    AIToolsView()
                } else if selectedTab == "Settings" {
                    SettingsView()
                } else {
                    Text("\(selectedTab) UI Coming Soon...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .tint(Color(hex: appAccentHex))
    }
    
    // MARK: - The Library Tab
    struct LibraryView: View {
        @EnvironmentObject var petManager: PetManager
        @StateObject var storage = PetStorage()
        @Binding var selectedFileURL: URL?
        @State private var petSize: Double = 150
        let columns = [GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 20)]
        
        // Renaming State
        @State private var showRenameAlert = false
        @State private var petToRename: URL?
        @State private var newPetName: String = ""
        
        // Personality State
        @State private var currentProfile: PersonalityProfile?
        @State private var showCustomTraits = false
        
        @AppStorage("appAccentHex") private var appAccentHex = "007AFF"
        
        var body: some View {
            HStack(spacing: 0) {
                
                // LEFT SIDE: Grid
                VStack {
                    HStack {
                        Text("Your Animations").font(.title2).bold()
                        Spacer()
                        Button(action: pickFile) { Label("Add from PC", systemImage: "folder.fill.badge.plus") }.buttonStyle(.borderedProminent)
                    }.padding()
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(storage.savedPets, id: \.self) { url in
                                VStack {
                                    ZStack(alignment: .topTrailing) {
                                        ThumbnailView(url: url).id(url)
                                            .frame(width: 120, height: 120)
                                            .background(Color.black.opacity(0.4))
                                            .cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(selectedFileURL == url ? Color(hex: appAccentHex) : Color.clear, lineWidth: 3))
                                        
                                        Button(action: {
                                            storage.deletePet(at: url)
                                            if selectedFileURL == url { selectedFileURL = nil }
                                        }) {
                                            Image(systemName: "minus.circle.fill").foregroundColor(.red).background(Circle().fill(Color.white))
                                        }.buttonStyle(.plain).padding(4)
                                    }
                                    .contextMenu {
                                        Button("Rename") { triggerRename(for: url) }
                                        Button("Delete", role: .destructive) {
                                            storage.deletePet(at: url)
                                            if selectedFileURL == url { selectedFileURL = nil }
                                        }
                                    }
                                    
                                    Text(url.deletingPathExtension().lastPathComponent)
                                        .font(.caption).lineLimit(1).truncationMode(.middle).frame(width: 120)
                                }
                                .onTapGesture {
                                    selectedFileURL = url
                                    currentProfile = PersonalityStorage.shared.getProfile(for: url)
                                }
                            }
                        }.padding()
                    }
                }.frame(maxWidth: .infinity, alignment: .topLeading)
                
                Divider()
                
                // RIGHT SIDE: Details & Personality Panel
                ScrollView {
                    VStack(spacing: 16) {
                        if let url = selectedFileURL {
                            HStack {
                                Text(url.deletingPathExtension().lastPathComponent)
                                    .font(.headline).lineLimit(1).truncationMode(.middle)
                                
                                Button(action: { triggerRename(for: url) }) {
                                    Image(systemName: "pencil").foregroundColor(Color(hex: appAccentHex))
                                }.buttonStyle(.plain)
                            }
                        } else {
                            Text("Selected Animation").font(.headline)
                        }
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)).frame(width: 200, height: 200)
                            if let url = selectedFileURL { ThumbnailView(url: url).id(url).frame(width: CGFloat(petSize), height: CGFloat(petSize)) }
                            else { Text("None Selected").foregroundColor(.gray) }
                        }.frame(width: 200, height: 200).clipped()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text("Spawn Size").font(.subheadline).bold(); Spacer(); Text("\(Int(petSize)) px").font(.caption).foregroundColor(.gray) }
                            Slider(value: $petSize, in: 50...400, step: 10)
                        }.padding(.horizontal, 4)
                        
                        Button(action: {
                            if let url = selectedFileURL {
                                petManager.launchPet(url: url, size: CGFloat(petSize))
                            }
                        }) {
                            Text("LAUNCH ANIMATION").bold().frame(width: 180).padding(.vertical, 8)
                        }.buttonStyle(.borderedProminent).disabled(selectedFileURL == nil)
                        
                        // MARK: - Personality Engine Inspector
                        if let url = selectedFileURL, let profile = currentProfile {
                            Divider().padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label("Personality", systemImage: "sparkles")
                                        .font(.headline)
                                        .foregroundColor(Color(hex: appAccentHex))
                                    Spacer()
                                }
                                
                                // Preset Selector
                                Picker("Preset", selection: Binding(
                                    get: { profile.preset ?? .balanced },
                                    set: { newPreset in
                                        var updated = PersonalityProfile.preset(newPreset)
                                        updated.name = profile.name
                                        currentProfile = updated
                                        PersonalityStorage.shared.saveProfile(updated, for: url)
                                        petManager.updateProfile(for: url, newProfile: updated)
                                    }
                                )) {
                                    ForEach(PersonalityPreset.allCases) { preset in
                                        Label(preset.displayName, systemImage: preset.iconName).tag(preset)
                                    }
                                }
                                .pickerStyle(.menu)
                                
                                Text(profile.preset?.summary ?? "Custom behavior configuration.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                // Custom Trait Sliders
                                DisclosureGroup(isExpanded: $showCustomTraits) {
                                    VStack(spacing: 8) {
                                        traitSlider(name: "Energy", value: Binding(
                                            get: { profile.energy },
                                            set: { updateTrait(\.energy, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Curiosity", value: Binding(
                                            get: { profile.curiosity },
                                            set: { updateTrait(\.curiosity, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Playfulness", value: Binding(
                                            get: { profile.playfulness },
                                            set: { updateTrait(\.playfulness, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Laziness", value: Binding(
                                            get: { profile.laziness },
                                            set: { updateTrait(\.laziness, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Sociability", value: Binding(
                                            get: { profile.sociability },
                                            set: { updateTrait(\.sociability, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Mischief", value: Binding(
                                            get: { profile.mischief },
                                            set: { updateTrait(\.mischief, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Attention", value: Binding(
                                            get: { profile.attentionSeeking },
                                            set: { updateTrait(\.attentionSeeking, value: $0, url: url) }
                                        ))
                                        
                                        Button("Reset to Preset Defaults") {
                                            if let preset = profile.preset {
                                                var reset = PersonalityProfile.preset(preset)
                                                reset.name = profile.name
                                                currentProfile = reset
                                                PersonalityStorage.shared.saveProfile(reset, for: url)
                                                petManager.updateProfile(for: url, newProfile: reset)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .font(.caption)
                                        .foregroundColor(Color(hex: appAccentHex))
                                        .padding(.top, 4)
                                    }
                                    .padding(.top, 4)
                                } label: {
                                    Text("Customize Traits")
                                        .font(.subheadline)
                                        .bold()
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding()
                }
                .frame(width: 270)
            }
            .onAppear {
                storage.loadPets()
                if let first = selectedFileURL ?? storage.savedPets.first {
                    selectedFileURL = first
                    currentProfile = PersonalityStorage.shared.getProfile(for: first)
                }
            }
            .alert("Rename Animation", isPresented: $showRenameAlert) {
                TextField("New Name", text: $newPetName)
                Button("Cancel", role: .cancel) { petToRename = nil }
                Button("Save") { renameFile() }
            } message: {
                Text("Enter a new name for this character.")
            }
        }
        
        func triggerRename(for url: URL) {
            petToRename = url
            newPetName = url.deletingPathExtension().lastPathComponent
            showRenameAlert = true
        }
        
        func renameFile() {
            guard let oldURL = petToRename, !newPetName.isEmpty else { return }
            let ext = oldURL.pathExtension
            let safeName = newPetName.replacingOccurrences(of: "/", with: "-")
            let newURL = oldURL.deletingLastPathComponent().appendingPathComponent("\(safeName).\(ext)")
            
            do {
                if !FileManager.default.fileExists(atPath: newURL.path) {
                    try FileManager.default.moveItem(at: oldURL, to: newURL)
                    PersonalityStorage.shared.handleFileRenamed(from: oldURL, to: newURL)
                    if selectedFileURL == oldURL { selectedFileURL = newURL }
                    storage.loadPets()
                }
            } catch {
                print("Failed to rename file: \(error.localizedDescription)")
            }
        }
        
        func updateTrait(_ keyPath: WritableKeyPath<PersonalityProfile, Double>, value: Double, url: URL) {
            guard var profile = currentProfile else { return }
            profile[keyPath: keyPath] = min(max(value, 0.0), 1.0)
            currentProfile = profile
            PersonalityStorage.shared.saveProfile(profile, for: url)
            petManager.updateProfile(for: url, newProfile: profile)
        }
        
        func traitSlider(name: String, value: Binding<Double>) -> some View {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(.caption2)
                        .bold()
                    Spacer()
                    Text("\(Int(value.wrappedValue * 100))%")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Slider(value: value, in: 0.0...1.0, step: 0.05)
            }
        }
        
        func pickFile() {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = true
            panel.canChooseDirectories = false
            panel.allowedContentTypes = SupportedMediaFormat.supportedUTTypes
            
            if panel.runModal() == .OK {
                let appFolder = PetStorage.getStorageDirectory()
                do {
                    if !FileManager.default.fileExists(atPath: appFolder.path) {
                        try FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
                    }
                    for sourceURL in panel.urls {
                        guard SupportedMediaFormat.isSupported(url: sourceURL) else { continue }
                        let ext = sourceURL.pathExtension
                        let baseName = sourceURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: " ", with: "_")
                        let uniqueFilename = "\(baseName)_\(UUID().uuidString.prefix(4)).\(ext)"
                        let destinationURL = appFolder.appendingPathComponent(uniqueFilename)
                        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                    }
                    DispatchQueue.main.async { self.storage.loadPets() }
                } catch {
                    print("Failed to import file from PC: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - The Settings Tab
struct SettingsView: View {
    @EnvironmentObject var petManager: PetManager
    @ObservedObject private var screenService = ScreenAwarenessService.shared
    
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)
    @State private var showCacheAlert = false
    @State private var clearedCacheCount = 0
    
    @AppStorage("gravityStrength") private var gravityStrength = 0.8
    @AppStorage("walkSpeed") private var walkSpeed = 2.0
    @AppStorage("eventFrequency") private var eventFrequency = 0.5
    @AppStorage("discordRPCEnabled") private var discordRPCEnabled = true
    @AppStorage("musicSyncEnabled") private var musicSyncEnabled = true
    
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
    
    @AppStorage("appAccentHex") private var appAccentHex = "007AFF"
    
    var body: some View {
        VStack {
            Text("Settings Panel")
                .font(.largeTitle).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            Form {
                Section(header: Text("Appearance").font(.headline)) {
                    ColorPicker("App Accent Color", selection: Binding(
                        get: { Color(hex: appAccentHex) },
                        set: { appAccentHex = $0.toHex() }
                    ))
                }.padding(.bottom, 10)
                
                Section(header: Text("General").font(.headline)) {
                    Toggle("Launch at Login", isOn: Binding(
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
                                print("Failed to update Launch at Login: \(error)")
                                launchAtLogin = (SMAppService.mainApp.status == .enabled)
                            }
                        }
                    ))
                    .onAppear {
                        launchAtLogin = (SMAppService.mainApp.status == .enabled)
                    }
                    
                    Button("Clear Cache") {
                        clearedCacheCount = PetStorage.clearCache()
                        showCacheAlert = true
                    }
                    .alert("Cache Cleared", isPresented: $showCacheAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(clearedCacheCount > 0 ? "Removed \(clearedCacheCount) temporary file(s)." : "Cache is already clean.")
                    }
                }.padding(.bottom, 10)
                
                Section(header: Text("Pet Behavior").font(.headline)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Slider(value: $gravityStrength, in: 0.1...2.0, step: 0.1)
                        Text("Gravity Strength: \(gravityStrength, specifier: "%.1f") (Range: 0.1 - 2.0)")
                            .font(.caption).foregroundColor(.gray)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Slider(value: $walkSpeed, in: 1.0...5.0, step: 0.5)
                        Text("Walk Speed: \(walkSpeed, specifier: "%.1f") (Range: 1.0 - 5.0)")
                            .font(.caption).foregroundColor(.gray)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Slider(value: $eventFrequency, in: 0.0...1.0, step: 0.1)
                        Text("Random Event Frequency: \(Int(eventFrequency * 100))% (Range: 0% - 100%)")
                            .font(.caption).foregroundColor(.gray)
                    }
                }.padding(.bottom, 10)
                
                Section(header: Text("Integrations").font(.headline)) {
                    Toggle("Enable Discord Rich Presence", isOn: $discordRPCEnabled)
                    HStack {
                        Toggle("Enable Music Reactivity (Spotify/Apple Music)", isOn: $musicSyncEnabled)
                        HStack(spacing: 4) {
                            Image(systemName: "music.note").foregroundColor(.green)
                            Image(systemName: "apple.logo").foregroundColor(.red)
                        }.font(.subheadline)
                    }
                }.padding(.bottom, 10)
                
                Section(header: Text("Environmental Awareness").font(.headline)) {
                    Toggle("Enable Environmental Awareness", isOn: $environmentAwarenessEnabled)
                    
                    if environmentAwarenessEnabled {
                        Toggle("Application Activity Awareness", isOn: $appAwarenessEnabled)
                        Toggle("Cursor Proximity Awareness", isOn: $cursorTrackingEnabled)
                        Toggle("User Inactivity Awareness", isOn: $inactivityTrackingEnabled)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Slider(value: $reactionFrequency, in: 0.1...1.0, step: 0.1)
                            Text("Reaction Sensitivity: \(Int(reactionFrequency * 100))% (Range: 10% - 100%)")
                                .font(.caption).foregroundColor(.gray)
                        }
                        
                        Button("Reset Environmental Defaults") {
                            environmentAwarenessEnabled = true
                            appAwarenessEnabled = true
                            cursorTrackingEnabled = true
                            inactivityTrackingEnabled = true
                            reactionFrequency = 0.6
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }.padding(.bottom, 10)
                
                Section(header: Text("Speech Bubbles & Dialogue").font(.headline)) {
                    Toggle("Enable Speech Bubbles", isOn: $dialogueEnabled)
                    
                    if dialogueEnabled {
                        Toggle("Quiet Mode (Mute all speech)", isOn: $quietModeEnabled)
                        
                        if !quietModeEnabled {
                            Toggle("Contextual Commentary", isOn: $contextualCommentaryEnabled)
                            Toggle("Direct Interaction Responses", isOn: $directInteractionResponsesEnabled)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Slider(value: $dialogueFrequency, in: 0.1...1.0, step: 0.1)
                                Text("Speech Frequency: \(Int(dialogueFrequency * 100))% (Range: 10% - 100%)")
                                    .font(.caption).foregroundColor(.gray)
                            }
                        }
                        
                        Button("Reset Dialogue Defaults") {
                            dialogueEnabled = true
                            quietModeEnabled = false
                            contextualCommentaryEnabled = true
                            directInteractionResponsesEnabled = true
                            dialogueFrequency = 0.5
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }.padding(.bottom, 10)
                
                Section(header: Text("Screen Awareness & Visual Intelligence").font(.headline)) {
                    Toggle("Enable Screen Awareness", isOn: $screenService.isEnabled)
                    
                    if screenService.isEnabled {
                        HStack {
                            Text("Screen Recording Permission:")
                            Spacer()
                            Text(screenService.permissionState().rawValue)
                                .foregroundColor(screenService.permissionState() == .authorized ? .green : .red)
                            if screenService.permissionState() != .authorized {
                                Button("Grant") {
                                    _ = screenService.requestPermission()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        Picker("Capture Source", selection: $screenService.selectedSourceType) {
                            ForEach(CaptureSourceType.allCases, id: \.self) { source in
                                Text(source.rawValue).tag(source)
                            }
                        }
                        
                        HStack {
                            Button("Observe Screen Now") {
                                Task {
                                    _ = await screenService.observeScreenNow(for: petManager.activePets.values.first)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(screenService.isObserving)
                            
                            if screenService.isObserving {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                        
                        Text("Status: \(screenService.statusMessage)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Toggle("Periodic Observation", isOn: $screenService.periodicObservationEnabled)
                        
                        if screenService.periodicObservationEnabled {
                            VStack(alignment: .leading, spacing: 6) {
                                Slider(value: $screenService.observationInterval, in: 300...3600, step: 60)
                                Text("Observation Interval: \(Int(screenService.observationInterval / 60)) minutes (Min: 5 min)")
                                    .font(.caption).foregroundColor(.gray)
                            }
                        }
                        
                        Picker("Processing Mode", selection: $screenService.processingMode) {
                            ForEach(VisionProcessingMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        
                        if screenService.processingMode == .cloud {
                            Text("⚠️ Cloud processing sends in-memory downscaled frames to a remote API. No images are saved to disk.")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Toggle("I consent to remote image analysis", isOn: $screenService.cloudConsentGiven)
                            
                            SecureField("API Key (Bearer Token)", text: $screenService.cloudProvider.apiKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            TextField("Local Endpoint URL", text: Binding(
                                get: { screenService.localProvider.endpoint.absoluteString },
                                set: { if let u = URL(string: $0) { screenService.localProvider.endpoint = u } }
                            ))
                            .textFieldStyle(.roundedBorder)
                            
                            TextField("Model Name", text: $screenService.localProvider.modelName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Button("Clear In-Memory Analysis History") {
                            screenService.clearHistory()
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }
            }
            // Disables the default opaque form background so the window tint shines through cleanly
            .scrollContentBackground(.hidden)
            .formStyle(.grouped)
            .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Color Hex Conversion Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
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
