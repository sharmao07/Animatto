import SwiftUI
import UniformTypeIdentifiers
import ServiceManagement

struct MainAppView: View {
    @EnvironmentObject var petManager: PetManager
    @State private var selectedTab = "Library"
    @State private var selectedFileURL: URL?
    
    // Read the saved color hex from storage (Defaults to standard Apple Blue)
    @AppStorage("appAccentHex") private var appAccentHex = "007AFF"
    @AppStorage("isLiquidGlassEnabled") private var isLiquidGlassEnabled = true
    @AppStorage("upsideDownMenuMode") private var upsideDownMenuMode = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Window Vibrancy & Dynamic Background Accessor
            WindowAccessorView { window in
                if isLiquidGlassEnabled {
                    window.isOpaque = false
                    window.backgroundColor = .clear
                } else {
                    window.isOpaque = true
                    window.backgroundColor = NSColor.windowBackgroundColor
                }
            }
            .frame(width: 0, height: 0)
            
            // 1. Base Layer: Liquid Glass Vibrancy or Solid macOS Window Background
            if isLiquidGlassEnabled {
                LiquidGlassView(material: .underWindowBackground, blendingMode: .behindWindow)
                    .ignoresSafeArea()
            } else {
                Color(NSColor.windowBackgroundColor)
                    .ignoresSafeArea()
            }
            
            // 2. Cohesive Dynamic Accent Gradient Tint Layer (Eliminates harsh black background)
            AppearanceThemeManager.adaptiveGradient(
                accentHex: appAccentHex,
                isDark: colorScheme == .dark,
                isLiquidGlass: isLiquidGlassEnabled
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack(spacing: 20) {
                    Text("Animatto").font(.headline).bold()
                    
                    Button("Library") {
                        selectedTab = "Library"
                        AudioEngine.shared.playUISound(.click)
                    }
                    .foregroundColor(selectedTab == "Library" ? Color(hex: appAccentHex) : .secondary)
                    Button("Workshop") {
                        selectedTab = "Workshop"
                        AudioEngine.shared.playUISound(.click)
                    }
                    .foregroundColor(selectedTab == "Workshop" ? Color(hex: appAccentHex) : .secondary)
                    Button("Settings") {
                        selectedTab = "Settings"
                        AudioEngine.shared.playUISound(.click)
                    }
                    .foregroundColor(selectedTab == "Settings" ? Color(hex: appAccentHex) : .secondary)
                    
                    Spacer()
                }
                .padding()
                // Adaptive glassmorphism top bar without harsh black opacity
                .background(
                    isLiquidGlassEnabled
                        ? (colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
                        : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                )
                
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
        .navigationTitle("Animatto")
        .task {
            if UpdateConfiguration.shared.automaticCheckEnabled {
                await UpdateService.shared.checkForUpdates(isManualCheck: false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoSelectTab)) { notif in
            if let tab = notif.object as? String {
                selectedTab = tab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoAddNewCompanion)) { _ in
            selectedTab = "Library"
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoResetPositions)) { _ in
            resetAllCompanionPositions()
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoToggleUpsideDown)) { _ in
            upsideDownMenuMode.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoToggleAmbience)) { _ in
            AmbientEngine.shared.isEnabled.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoToggleMute)) { _ in
            AudioSettings.shared.isMasterMuted.toggle()
            AudioEngine.shared.updateAmbientVolume()
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoBringPetsToFront)) { _ in
            bringAllPetsToFront()
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoHideAllPets)) { _ in
            toggleHideAllPets()
        }
    }
    
    private func resetAllCompanionPositions() {
        guard let screen = NSScreen.main else { return }
        let midX = screen.visibleFrame.midX - 50
        let bottomY = screen.visibleFrame.minY + 20
        for pet in petManager.activePets.values {
            pet.currentX = midX
            pet.currentY = bottomY
            pet.yVelocity = 0
            pet.isFalling = false
            pet.updatePosition()
        }
    }
    
    private func bringAllPetsToFront() {
        for pet in petManager.activePets.values {
            pet.bringToFront()
        }
    }
    
    private func toggleHideAllPets() {
        for pet in petManager.activePets.values {
            pet.toggleVisibility()
        }
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
        @ObservedObject private var memoryStore = CharacterMemoryStore.shared
        @State private var currentProfile: PersonalityProfile?
        @State private var showCustomTraits = false
        @State private var showInterests = false
        @State private var showBehaviorPrefs = false
        @State private var showPreviewSheet = false
        @State private var showResetConfirmAlert = false
        @State private var showImportErrorAlert = false
        @State private var importErrorMessage = ""
        
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
                    
                    if storage.savedPets.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No Companions in Library")
                                .font(.headline)
                            Text("Add custom sprites or GIFs from your Mac, or restore the starter companions.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Button("Restore Starter Companions") {
                                storage.loadDefaultCharacters()
                                storage.loadPets()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
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
                                    Label("Personality Matrix", systemImage: "sparkles")
                                        .font(.headline)
                                        .foregroundColor(Color(hex: appAccentHex))
                                    Spacer()
                                    
                                    Button(action: { showPreviewSheet = true }) {
                                        Label("Preview", systemImage: "eye.fill")
                                            .font(.caption2)
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                                // Preset Selector
                                Picker("Archetype", selection: Binding(
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
                                
                                // SECTION 1: The Ten Personality Dimensions
                                DisclosureGroup(isExpanded: $showCustomTraits) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Movement & Vitality")
                                            .font(.caption2).bold().foregroundColor(.secondary).padding(.top, 2)
                                        traitSlider(name: "Energetic", desc: "Sluggish ↔ Hyperactive", value: Binding(
                                            get: { profile.energy },
                                            set: { updateTrait(\.energy, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Lazy", desc: "Active ↔ Couch Potato", value: Binding(
                                            get: { profile.laziness },
                                            set: { updateTrait(\.laziness, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Playful", desc: "Serious ↔ Non-Stop Fun", value: Binding(
                                            get: { profile.playfulness },
                                            set: { updateTrait(\.playfulness, value: $0, url: url) }
                                        ))
                                        
                                        Divider().padding(.vertical, 2)
                                        Text("Social & Independence")
                                            .font(.caption2).bold().foregroundColor(.secondary)
                                        traitSlider(name: "Sociable", desc: "Introverted ↔ Social Butterfly", value: Binding(
                                            get: { profile.sociability },
                                            set: { updateTrait(\.sociability, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Shy", desc: "Bold / Outgoing ↔ Timid & Elusive", value: Binding(
                                            get: { profile.shyness },
                                            set: { updateTrait(\.shyness, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Independent", desc: "Attentive ↔ Free Spirit", value: Binding(
                                            get: { profile.independence },
                                            set: { updateTrait(\.independence, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Attention Seeking", desc: "Independent ↔ Craving Interaction", value: Binding(
                                            get: { profile.attentionSeeking },
                                            set: { updateTrait(\.attentionSeeking, value: $0, url: url) }
                                        ))
                                        
                                        Divider().padding(.vertical, 2)
                                        Text("Expression & Wit")
                                            .font(.caption2).bold().foregroundColor(.secondary)
                                        traitSlider(name: "Curious", desc: "Indifferent ↔ Inquisitive Explorer", value: Binding(
                                            get: { profile.curiosity },
                                            set: { updateTrait(\.curiosity, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Mischievous", desc: "Orderly ↔ Agent of Chaos", value: Binding(
                                            get: { profile.mischief },
                                            set: { updateTrait(\.mischief, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Sarcastic", desc: "Earnest ↔ Sharp Wit", value: Binding(
                                            get: { profile.sarcasm },
                                            set: { updateTrait(\.sarcasm, value: $0, url: url) }
                                        ))
                                        traitSlider(name: "Supportive", desc: "Neutral ↔ Devoted Cheerleader", value: Binding(
                                            get: { profile.supportiveness },
                                            set: { updateTrait(\.supportiveness, value: $0, url: url) }
                                        ))
                                    }
                                    .padding(.top, 4)
                                } label: {
                                    Text("Personality Traits (10 Dimensions)")
                                        .font(.subheadline)
                                        .bold()
                                }
                                
                                // SECTION 2: Topic Preferences & Interests
                                DisclosureGroup(isExpanded: $showInterests) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Customized reactions to desktop activities.")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        
                                        ForEach(CharacterInterestTopic.allCases) { topic in
                                            let currentPref = profile.preference(for: topic)
                                            HStack {
                                                Image(systemName: topic.iconName).frame(width: 16)
                                                Text(topic.displayName).font(.caption2)
                                                Spacer()
                                                Picker("", selection: Binding(
                                                    get: { currentPref },
                                                    set: { updateTopicPreference(topic: topic, preference: $0, url: url) }
                                                )) {
                                                    ForEach(TopicPreference.allCases, id: \.self) { pref in
                                                        Label(pref.displayName, systemImage: pref.iconName).tag(pref)
                                                    }
                                                }
                                                .pickerStyle(.menu)
                                                .frame(width: 110)
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                } label: {
                                    Text("Interests, Likes & Dislikes")
                                        .font(.subheadline)
                                        .bold()
                                }
                                
                                // SECTION 3: Behavioral Boundaries & Preferences
                                DisclosureGroup(isExpanded: $showBehaviorPrefs) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Toggle("Follow Cursor", isOn: Binding(
                                            get: { profile.behaviorPreferences.cursorFollowingEnabled },
                                            set: { updateBehaviorPref(\.cursorFollowingEnabled, value: $0, url: url) }
                                        ))
                                        .font(.caption2).bold()
                                        
                                        if profile.behaviorPreferences.cursorFollowingEnabled {
                                            traitSlider(
                                                name: "Cursor Follow Strength",
                                                desc: "How eagerly it approaches the cursor",
                                                value: Binding(
                                                    get: { profile.behaviorPreferences.cursorFollowingStrength },
                                                    set: { updateBehaviorPref(\.cursorFollowingStrength, value: $0, url: url) }
                                                )
                                            )
                                        }
                                        
                                        traitSlider(
                                            name: "Rest & Nap Readiness",
                                            desc: "Readiness to rest and sleep",
                                            value: Binding(
                                                get: { profile.behaviorPreferences.sleepFrequency },
                                                set: { updateBehaviorPref(\.sleepFrequency, value: $0, url: url) }
                                            )
                                        )
                                        
                                        traitSlider(
                                            name: "Exploration Tendency",
                                            desc: "Readiness to explore windows & bounds",
                                            value: Binding(
                                                get: { profile.behaviorPreferences.explorationTendency },
                                                set: { updateBehaviorPref(\.explorationTendency, value: $0, url: url) }
                                            )
                                        )
                                        
                                        traitSlider(
                                            name: "Speech Bubble Frequency",
                                            desc: "Dialogue rate and cooldown multiplier",
                                            value: Binding(
                                                get: { profile.behaviorPreferences.commentFrequency },
                                                set: { updateBehaviorPref(\.commentFrequency, value: $0, url: url) }
                                            )
                                        )
                                        
                                        Toggle("Mute Dialogue", isOn: Binding(
                                            get: { profile.behaviorPreferences.dialogueMuted },
                                            set: { updateBehaviorPref(\.dialogueMuted, value: $0, url: url) }
                                        ))
                                        .font(.caption2).bold()
                                        
                                        Toggle("Social Encounters", isOn: Binding(
                                            get: { profile.behaviorPreferences.socialInteractionsEnabled },
                                            set: { updateBehaviorPref(\.socialInteractionsEnabled, value: $0, url: url) }
                                        ))
                                        .font(.caption2).bold()
                                        
                                        Toggle("Retain Memory", isOn: Binding(
                                            get: { profile.behaviorPreferences.memoryEnabled },
                                            set: { updateBehaviorPref(\.memoryEnabled, value: $0, url: url) }
                                        ))
                                        .font(.caption2).bold()
                                    }
                                    .padding(.top, 4)
                                } label: {
                                    Text("Behavior Preferences")
                                        .font(.subheadline)
                                        .bold()
                                }
                                
                                // SECTION 4: Memories & Continuity
                                let charId = PersonalityStorage.shared.characterId(for: url)
                                let memories = memoryStore.memories(for: charId)
                                DisclosureGroup("Character Memories (\(memories.count))") {
                                    VStack(alignment: .leading, spacing: 6) {
                                        if memories.isEmpty {
                                            Text("No memories recorded yet for this companion.")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .padding(.vertical, 2)
                                        } else {
                                            ForEach(memories.prefix(6)) { mem in
                                                HStack(alignment: .top) {
                                                    VStack(alignment: .leading, spacing: 1) {
                                                        Text(mem.summary)
                                                            .font(.caption2).bold()
                                                        Text("\(mem.category.displayName) • \(mem.createdAt.formatted(date: .omitted, time: .shortened))")
                                                            .font(.system(size: 9))
                                                            .foregroundColor(.secondary)
                                                    }
                                                    Spacer()
                                                    Button(action: {
                                                        memoryStore.deleteMemory(id: mem.id, for: charId)
                                                    }) {
                                                        Image(systemName: "trash")
                                                            .font(.system(size: 9))
                                                            .foregroundColor(.red)
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                                .padding(.vertical, 2)
                                            }
                                            
                                            Button("Clear Companion Memories") {
                                                memoryStore.clearMemories(for: charId)
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundColor(.red)
                                            .font(.system(size: 10))
                                            .padding(.top, 4)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                                .font(.subheadline).bold()
                                
                                Divider().padding(.vertical, 2)
                                
                                // Actions: Export, Import, Reset
                                HStack(spacing: 8) {
                                    Button("Export Profile") {
                                        exportCurrentProfile(profile: profile)
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption2)
                                    
                                    Button("Import Profile") {
                                        importProfileForCurrent(url: url)
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption2)
                                    
                                    Spacer()
                                    
                                    Button("Reset") {
                                        showResetConfirmAlert = true
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.red)
                                    .font(.caption2)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding()
                }
                .frame(width: 330)
            }
            .onAppear {
                storage.loadPets()
                if let first = selectedFileURL ?? storage.savedPets.first {
                    selectedFileURL = first
                    currentProfile = PersonalityStorage.shared.getProfile(for: first)
                }
            }
            .sheet(isPresented: $showPreviewSheet) {
                if let profile = currentProfile {
                    BehaviorPreviewSheet(profile: profile)
                }
            }
            .confirmationDialog("Reset Profile Defaults", isPresented: $showResetConfirmAlert) {
                Button("Reset to Preset Defaults", role: .destructive) {
                    if let url = selectedFileURL, let profile = currentProfile, let preset = profile.preset {
                        var reset = PersonalityProfile.preset(preset)
                        reset.name = profile.name
                        currentProfile = reset
                        PersonalityStorage.shared.saveProfile(reset, for: url)
                        petManager.updateProfile(for: url, newProfile: reset)
                    }
                }
            } message: {
                Text("Reset all traits, interests, and behavior preferences to their preset defaults?")
            }
            .alert("Profile Import Error", isPresented: $showImportErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage)
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
        
        func updateBehaviorPref<T>(_ keyPath: WritableKeyPath<CharacterBehaviorPreferences, T>, value: T, url: URL) {
            guard var profile = currentProfile else { return }
            profile.behaviorPreferences[keyPath: keyPath] = value
            currentProfile = profile
            PersonalityStorage.shared.saveProfile(profile, for: url)
            petManager.updateProfile(for: url, newProfile: profile)
        }
        
        func updateTopicPreference(topic: CharacterInterestTopic, preference: TopicPreference, url: URL) {
            guard var profile = currentProfile else { return }
            profile.setPreference(preference, for: topic)
            currentProfile = profile
            PersonalityStorage.shared.saveProfile(profile, for: url)
            petManager.updateProfile(for: url, newProfile: profile)
        }
        
        func exportCurrentProfile(profile: PersonalityProfile) {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            let safeName = profile.name.replacingOccurrences(of: " ", with: "_")
            panel.nameFieldStringValue = "\(safeName)_personality.json"
            panel.title = "Export Personality Profile"
            
            if panel.runModal() == .OK, let saveURL = panel.url {
                let result = PersonalityStorage.shared.exportProfileJSON(profile)
                if case .success(let data) = result {
                    try? data.write(to: saveURL, options: .atomic)
                }
            }
        }
        
        func importProfileForCurrent(url: URL) {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.json]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.title = "Import Personality Profile"
            
            if panel.runModal() == .OK, let openURL = panel.url {
                if let data = try? Data(contentsOf: openURL) {
                    let result = PersonalityStorage.shared.importProfile(from: data)
                    switch result {
                    case .success(var imported):
                        imported.name = currentProfile?.name ?? imported.name
                        currentProfile = imported
                        PersonalityStorage.shared.saveProfile(imported, for: url)
                        petManager.updateProfile(for: url, newProfile: imported)
                    case .failure(let err):
                        importErrorMessage = err
                        showImportErrorAlert = true
                    }
                }
            }
        }
        
        func traitSlider(name: String, desc: String, value: Binding<Double>) -> some View {
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
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
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
                    print("Failed to import companion asset: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - The Settings Tab
struct SettingsView: View {
    @EnvironmentObject var petManager: PetManager
    @ObservedObject private var screenService = ScreenAwarenessService.shared
    @ObservedObject private var memoryStore = CharacterMemoryStore.shared
    @ObservedObject private var timerManager = ProductivityTimerManager.shared
    @ObservedObject private var updateService = UpdateService.shared
    @ObservedObject private var updateConfig = UpdateConfiguration.shared
    @ObservedObject private var ambientEngine = AmbientEngine.shared
    @ObservedObject private var minigameManager = AmbientMinigameManager.shared
    @ObservedObject private var weatherSync = WeatherSyncService.shared
    @ObservedObject private var packService = AtmospherePackService.shared
    @ObservedObject private var audioSettings = AudioSettings.shared
    
    @State private var newPresetName = ""
    @State private var packImportError: String?
    
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)
    @State private var showCacheAlert = false
    @State private var clearedCacheCount = 0
    @State private var showClearMemoriesAlert = false
    
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
    
    @AppStorage("socialInteractionsEnabled") private var socialInteractionsEnabled = true
    @AppStorage("memoryEnabled") private var memoryEnabled = true
    
    @AppStorage("appAccentHex") private var appAccentHex = "007AFF"
    @AppStorage("isLiquidGlassEnabled") private var isLiquidGlassEnabled = true
    
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
                    
                    Toggle("Liquid Glass Vibrancy", isOn: $isLiquidGlassEnabled)
                    Text("Enables native translucent NSVisualEffectView glass surfaces and dynamic window tinting.")
                        .font(.caption).foregroundColor(.secondary)
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
                
                Section(header: Text("Sound & Audio Effects").font(.headline)) {
                    Toggle("Master Mute", isOn: Binding(
                        get: { audioSettings.isMasterMuted },
                        set: {
                            audioSettings.isMasterMuted = $0
                            AudioEngine.shared.updateAmbientVolume()
                        }
                    ))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Slider(value: $audioSettings.masterVolume, in: 0.0...1.0, step: 0.05)
                            .onChange(of: audioSettings.masterVolume) { _, _ in
                                AudioEngine.shared.updateAmbientVolume()
                            }
                        Text("Master Volume: \(Int(audioSettings.masterVolume * 100))%")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // --- Ambient Audio ---
                    Toggle("Ambient Audio", isOn: Binding(
                        get: { audioSettings.ambientEnabled },
                        set: {
                            audioSettings.ambientEnabled = $0
                            AudioEngine.shared.updateAmbientVolume()
                        }
                    ))
                    
                    if audioSettings.ambientEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Slider(value: $audioSettings.ambientVolume, in: 0.0...1.0, step: 0.05)
                                .onChange(of: audioSettings.ambientVolume) { _, _ in
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                            Text("Ambient Sub-Master Volume: \(Int(audioSettings.ambientVolume * 100))%")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.leading, 12)
                        
                        // Rain & Thunder
                        HStack {
                            Toggle("Rain & Thunder", isOn: Binding(
                                get: { audioSettings.rainThunderEnabled },
                                set: {
                                    audioSettings.rainThunderEnabled = $0
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                            ))
                            Spacer()
                            Button("Test") {
                                AudioEngine.shared.setAmbientEnvironment(.rainThunder)
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                        }
                        .padding(.leading, 12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Slider(value: $audioSettings.rainThunderVolume, in: 0.0...1.0, step: 0.05)
                                .onChange(of: audioSettings.rainThunderVolume) { _, _ in
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                            Text("Rain & Thunder Volume: \(Int(audioSettings.rainThunderVolume * 100))%")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.leading, 24)
                        
                        // Forest & Birdsong
                        HStack {
                            Toggle("Forest & Birdsong", isOn: Binding(
                                get: { audioSettings.forestBirdsongEnabled },
                                set: {
                                    audioSettings.forestBirdsongEnabled = $0
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                            ))
                            Spacer()
                            Button("Test") {
                                AudioEngine.shared.setAmbientEnvironment(.forestBirdsong)
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                        }
                        .padding(.leading, 12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Slider(value: $audioSettings.forestBirdsongVolume, in: 0.0...1.0, step: 0.05)
                                .onChange(of: audioSettings.forestBirdsongVolume) { _, _ in
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                            Text("Forest & Birdsong Volume: \(Int(audioSettings.forestBirdsongVolume * 100))%")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.leading, 24)
                        
                        // Winter Wind
                        HStack {
                            Toggle("Winter Wind", isOn: Binding(
                                get: { audioSettings.winterWindEnabled },
                                set: {
                                    audioSettings.winterWindEnabled = $0
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                            ))
                            Spacer()
                            Button("Test") {
                                AudioEngine.shared.setAmbientEnvironment(.winterWind)
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                        }
                        .padding(.leading, 12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Slider(value: $audioSettings.winterWindVolume, in: 0.0...1.0, step: 0.05)
                                .onChange(of: audioSettings.winterWindVolume) { _, _ in
                                    AudioEngine.shared.updateAmbientVolume()
                                }
                            Text("Winter Wind Volume: \(Int(audioSettings.winterWindVolume * 100))%")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.leading, 24)
                    }
                    
                    Divider()
                    
                    // --- Character Audio ---
                    // Footsteps
                    HStack {
                        Toggle("Character Footsteps", isOn: $audioSettings.footstepsEnabled)
                        Spacer()
                        Button("Test") {
                            AudioEngine.shared.playFootstep()
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    if audioSettings.footstepsEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Slider(value: $audioSettings.footstepsVolume, in: 0.0...1.0, step: 0.05)
                            Text("Footsteps Volume: \(Int(audioSettings.footstepsVolume * 100))%")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.leading, 12)
                    }
                    
                    // Sleep Sounds
                    HStack {
                        Toggle("Sleep Sounds & Purring", isOn: $audioSettings.sleepSoundsEnabled)
                        Spacer()
                        Button("Test") {
                            AudioEngine.shared.startSleepSound(forPetId: "preview_test", totalSleepingPets: 1)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                AudioEngine.shared.stopSleepSound(forPetId: "preview_test")
                            }
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    if audioSettings.sleepSoundsEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Slider(value: $audioSettings.sleepSoundsVolume, in: 0.0...1.0, step: 0.05)
                            Text("Sleep Volume: \(Int(audioSettings.sleepSoundsVolume * 100))%")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.leading, 12)
                    }
                    
                    // Companion Voices
                    HStack {
                        Toggle("Companion Voices & Vocalizations", isOn: $audioSettings.companionVoicesEnabled)
                        Spacer()
                        Button("Test") {
                            AudioEngine.shared.playCompanionVoice(.happy)
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    if audioSettings.companionVoicesEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Slider(value: $audioSettings.companionVoicesVolume, in: 0.0...1.0, step: 0.05)
                            Text("Companion Voices Volume: \(Int(audioSettings.companionVoicesVolume * 100))%")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.leading, 12)
                    }
                    
                    Divider()
                    
                    // --- UI Sounds ---
                    HStack {
                        Toggle("UI Interaction Sounds", isOn: $audioSettings.uiSoundsEnabled)
                        Spacer()
                        Button("Test") {
                            AudioEngine.shared.playUISound(.click)
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    if audioSettings.uiSoundsEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Slider(value: $audioSettings.uiSoundsVolume, in: 0.0...1.0, step: 0.05)
                            Text("UI Sounds Volume: \(Int(audioSettings.uiSoundsVolume * 100))%")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.leading, 12)
                    }
                    
                    Button("Reset Audio Defaults") {
                        audioSettings.resetToDefaults()
                        AudioEngine.shared.updateAmbientVolume()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
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
                
                Section(header: Text("Multi-Character Social Behavior").font(.headline)) {
                    Toggle("Enable Social Encounters", isOn: $socialInteractionsEnabled)
                    
                    Text("Allows nearby companions to approach, greet, and interact autonomously on your desktop.")
                        .font(.caption).foregroundColor(.gray)
                }.padding(.bottom, 10)
                
                Section(header: Text("Character Memory & Continuity").font(.headline)) {
                    Toggle("Enable Character Memory", isOn: $memoryEnabled)
                    
                    Text("Allows companions to retain bounded, local interaction history and social continuity between sessions. No personal data or screen content is ever stored.")
                        .font(.caption).foregroundColor(.gray)
                    
                    if memoryEnabled {
                        HStack {
                            Text("Stored Records:")
                            Spacer()
                            Text("\(memoryStore.totalMemoryCount()) records across \(memoryStore.memoriesByCharacter.keys.count) companions")
                                .font(.caption).bold()
                        }
                        
                        Button("Clear All Character Memories") {
                            showClearMemoriesAlert = true
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
                .confirmationDialog("Clear All Character Memories", isPresented: $showClearMemoriesAlert) {
                    Button("Clear All Memories", role: .destructive) {
                        memoryStore.clearAllMemories()
                    }
                } message: {
                    Text("Are you sure you want to delete all stored interaction memories across all characters? This action cannot be undone.")
                }
                .padding(.bottom, 10)
                
                Section(header: Text("Productivity Companion & Focus Sessions").font(.headline)) {
                    Text("Structured focus sprints and Pomodoro cycles with intelligent companion sleep, quiet work behavior, and celebratory break reactions.")
                        .font(.caption).foregroundColor(.gray)
                    
                    if timerManager.currentPhase != .idle {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(timerManager.currentPhase.displayName)
                                    .font(.headline)
                                    .foregroundColor(timerManager.currentPhase == .breakTime ? .green : Color(hex: appAccentHex))
                                Spacer()
                                Text(timerManager.formattedRemainingTime)
                                    .font(.system(.title2, design: .monospaced))
                                    .bold()
                            }
                            
                            ProgressView(value: timerManager.progress)
                                .tint(timerManager.currentPhase == .breakTime ? .green : Color(hex: appAccentHex))
                            
                            HStack(spacing: 12) {
                                Button(timerManager.isPaused ? "Resume" : "Pause") {
                                    if timerManager.isPaused {
                                        timerManager.resume()
                                    } else {
                                        timerManager.pause()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(hex: appAccentHex))
                                
                                if timerManager.currentMode.hasBreak {
                                    Button("Skip to Next") {
                                        timerManager.skip()
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                                Button("Stop Session") {
                                    timerManager.stop()
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(10)
                    } else {
                        HStack(spacing: 8) {
                            Button("Start Pomodoro (25m)") {
                                timerManager.start(mode: .pomodoro)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: appAccentHex))
                            
                            Button("Long Focus (50m)") {
                                timerManager.start(mode: .longFocus)
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Custom (\(timerManager.customFocusMinutes)m)") {
                                timerManager.start(mode: .custom(focusMinutes: timerManager.customFocusMinutes, breakMinutes: timerManager.customBreakMinutes))
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Custom Durations:").font(.caption).bold()
                        HStack {
                            Stepper("Focus: \(timerManager.customFocusMinutes) min", value: $timerManager.customFocusMinutes, in: 1...180)
                            Spacer()
                            Stepper("Break: \(timerManager.customBreakMinutes) min", value: $timerManager.customBreakMinutes, in: 1...60)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Picker("Companion Behavior During Focus", selection: $timerManager.companionFocusBehavior) {
                        ForEach(FocusCompanionBehavior.allCases, id: \.self) { behavior in
                            Text(behavior.displayName).tag(behavior)
                        }
                    }
                    
                    Toggle("Sound Alerts & Chimes", isOn: $timerManager.soundEnabled)
                    Toggle("Desktop Notifications", isOn: $timerManager.notificationsEnabled)
                    Toggle("Companion Speech Announcements", isOn: $timerManager.speechDialogueEnabled)
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
                
                Section(header: Text("Software Updates & Release Quality").font(.headline)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Animatto macOS Companion")
                                .font(.subheadline).bold()
                            Text("Installed Version: v\(updateService.installedVersionProvider().description)")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if updateService.isChecking {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Button("Check for Updates") {
                                Task {
                                    await updateService.checkForUpdates(isManualCheck: true)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: appAccentHex))
                        }
                    }
                    
                    switch updateService.state {
                    case .idle:
                        if let lastCheck = updateService.lastCheckedDate {
                            Text("Last checked: \(lastCheck.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundColor(.gray)
                        } else {
                            Text("No update checks performed yet.")
                                .font(.caption).foregroundColor(.gray)
                        }
                    case .checking:
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("Checking GitHub Releases...")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    case .upToDate(let installedVer, let checkedAt):
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Animatto v\(installedVer) is up to date.")
                                .font(.caption).bold()
                            Spacer()
                            Text("Checked: \(checkedAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2).foregroundColor(.gray)
                        }
                    case .updateAvailable(let release, let currentVer):
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                    .foregroundColor(Color(hex: appAccentHex))
                                Text("Update Available: \(release.displayTitle)")
                                    .font(.subheadline).bold()
                                Spacer()
                                if release.isPrerelease {
                                    Text("Nightly / Beta").font(.caption2).bold()
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .foregroundColor(.orange)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text("Current: v\(currentVer) → Latest: \(release.tagName)")
                                .font(.caption).foregroundColor(.secondary)
                            
                            if let body = release.body, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Release Highlights:").font(.caption2).bold().foregroundColor(.secondary)
                                    ScrollView {
                                        Text(body)
                                            .font(.system(.caption, design: .monospaced))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(6)
                                    }
                                    .frame(maxHeight: 100)
                                    .background(Color.black.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                            
                            if let asset = release.primaryUpdateAsset {
                                HStack {
                                    Label(asset.name, systemImage: "shippingbox.fill")
                                        .font(.caption2).foregroundColor(.secondary)
                                    Spacer()
                                    Text(ByteCountFormatter.string(fromByteCount: Int64(asset.size), countStyle: .file))
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                            }
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    updateService.startDownload(release: release)
                                }) {
                                    Label("Download & Install Update", systemImage: "arrow.down.circle.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(hex: appAccentHex))
                                
                                Button(action: {
                                    updateService.openReleaseWebPage(url: release.htmlURL)
                                }) {
                                    Label("Download via Browser", systemImage: "safari")
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Dismiss") {
                                    updateService.dismissCurrentUpdate()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(10)
                        .background(Color(hex: appAccentHex).opacity(0.08))
                        .cornerRadius(8)
                    case .downloading(let release, let progress):
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(Color(hex: appAccentHex))
                                Text("Downloading \(release.displayTitle)...")
                                    .font(.subheadline).bold()
                                Spacer()
                                Text("\(Int(progress.fractionCompleted * 100))%")
                                    .font(.caption).bold()
                            }
                            
                            ProgressView(value: progress.fractionCompleted, total: 1.0)
                                .tint(Color(hex: appAccentHex))
                            
                            HStack {
                                Text("\(progress.formattedDownloaded) of \(progress.formattedTotal)")
                                    .font(.caption2).foregroundColor(.secondary)
                                Spacer()
                                Text("\(progress.formattedSpeed) • \(progress.formattedTimeRemaining)")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 8) {
                                Button("Cancel") {
                                    updateService.cancelDownload()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Spacer()
                                
                                Button(action: {
                                    updateService.openReleaseWebPage(url: release.htmlURL)
                                }) {
                                    Label("Download from GitHub", systemImage: "safari")
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                            }
                        }
                        .padding(10)
                        .background(Color(hex: appAccentHex).opacity(0.08))
                        .cornerRadius(8)
                    case .verifying(_, let status):
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                ProgressView().controlSize(.small)
                                Text(status)
                                    .font(.subheadline).bold()
                            }
                            Text("Verifying update package integrity and staging application bundle...")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color(hex: appAccentHex).opacity(0.08))
                        .cornerRadius(8)
                    case .readyToRestart(let release, _):
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Update Ready: \(release.displayTitle)")
                                    .font(.subheadline).bold()
                            }
                            Text("The update package has been downloaded, verified, and staged. Restart Animatto now to complete installation.")
                                .font(.caption).foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    updateService.applyUpdateAndRestart()
                                }) {
                                    Label("Restart Animatto Now", systemImage: "arrow.clockwise.circle.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                
                                Button("Show in Finder") {
                                    updateService.revealStagedUpdateInFinder()
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Later") {
                                    updateService.state = .idle
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(10)
                        .background(Color.green.opacity(0.08))
                        .cornerRadius(8)
                    case .error(let msg):
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(msg)
                                    .font(.caption).foregroundColor(.red)
                            }
                            HStack(spacing: 8) {
                                Button("Retry Check") {
                                    Task {
                                        await updateService.checkForUpdates(isManualCheck: true)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button(action: {
                                    updateService.openReleaseWebPage(url: updateConfig.repositoryReleasesWebURL())
                                }) {
                                    Label("Download from GitHub", systemImage: "safari")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    
                    Divider().padding(.vertical, 2)
                    
                    Toggle("Automatically Check for Updates on Launch", isOn: $updateConfig.automaticCheckEnabled)
                    Toggle("Include Prerelease Builds (Beta / RC)", isOn: $updateConfig.includePrereleases)
                        .onChange(of: updateConfig.includePrereleases) { _, _ in
                            Task {
                                await updateService.checkForUpdates(isManualCheck: true)
                            }
                        }
                    
                    Text("Updates are verified against official GitHub releases. Animatto never installs software silently in the background or bypasses macOS security policies.")
                        .font(.caption2).foregroundColor(.gray)
                }
                .padding(.bottom, 10)
                
                Section(header: Text("Ambient Worlds & Weather-Reactive Atmosphere").font(.headline)) {
                    Toggle("Enable Desktop Atmosphere", isOn: $ambientEngine.isEnabled)
                        .font(.subheadline).bold()
                    
                    if ambientEngine.isEnabled {
                        // Environment Selector
                        Picker("Environment Type", selection: $ambientEngine.currentEnvironment) {
                            ForEach(AmbientEnvironmentType.allCases, id: \.self) { env in
                                Label(env.displayName, systemImage: env.iconName).tag(env)
                            }
                        }
                        
                        // Preset Selector
                        Picker("Atmosphere Preset", selection: $ambientEngine.activePresetKey) {
                            Text("Built-in Presets").font(.caption).bold().foregroundColor(.secondary)
                            ForEach(AtmospherePreset.builtInPresets) { preset in
                                Text(preset.name).tag(preset.presetKey)
                            }
                            if !ambientEngine.customPresets.isEmpty {
                                Text("Custom Presets").font(.caption).bold().foregroundColor(.secondary)
                                ForEach(ambientEngine.customPresets) { preset in
                                    Text(preset.name).tag(preset.presetKey)
                                }
                            }
                        }
                        .onChange(of: ambientEngine.activePresetKey) { _, newKey in
                            ambientEngine.applyPreset(presetKey: newKey)
                        }
                        
                        // Sliders
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Intensity")
                                Spacer()
                                Text("\(Int(ambientEngine.intensity * 100))%")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Slider(value: $ambientEngine.intensity, in: 0.15...1.0, step: 0.05)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Wind Strength")
                                Spacer()
                                Text(String(format: "%.1f", ambientEngine.windStrength))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Slider(value: $ambientEngine.windStrength, in: -1.0...1.0, step: 0.1)
                        }
                        
                        Picker("Performance & Quality Mode", selection: $ambientEngine.qualityMode) {
                            ForEach(AmbientQualityMode.allCases, id: \.self) { q in
                                Text("\(q.displayName) (Max \(q.maxParticles) particles)").tag(q)
                            }
                        }
                        
                        Toggle("Time-Based Ambience Scheduling", isOn: $ambientEngine.isTimeScheduleEnabled)
                        
                        // Custom Preset Creation
                        HStack {
                            TextField("New Preset Name", text: $newPresetName)
                                .textFieldStyle(.roundedBorder)
                            Button("Save Current as Preset") {
                                guard !newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                _ = ambientEngine.saveCustomPreset(name: newPresetName.trimmingCharacters(in: .whitespacesAndNewlines))
                                newPresetName = ""
                            }
                            .buttonStyle(.bordered)
                            .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        
                        Divider()
                        
                        // Collectible Minigame
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle("Collectible Minigame", isOn: $minigameManager.isGameEnabled)
                                .font(.subheadline).bold()
                            
                            if minigameManager.isGameEnabled {
                                HStack {
                                    Text("Session Score: \(minigameManager.currentScore)")
                                        .font(.caption).bold().foregroundColor(.orange)
                                    Spacer()
                                    Text("High Score: \(minigameManager.highScore)")
                                        .font(.caption).bold()
                                    Spacer()
                                    Button("Reset Score") {
                                        minigameManager.resetSessionScore()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Live Weather Sync
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle("Live Weather Synchronization", isOn: $weatherSync.isSyncEnabled)
                                .font(.subheadline).bold()
                            
                            if weatherSync.isSyncEnabled {
                                Toggle("Inverse Weather Mode (Contrasting Ambience)", isOn: $weatherSync.isInverseModeEnabled)
                                    .font(.caption)
                                
                                HStack {
                                    Text("Location: \(weatherSync.userCityName.isEmpty ? "Manual Coordinates" : weatherSync.userCityName)")
                                        .font(.caption).foregroundColor(.secondary)
                                    Spacer()
                                    Text(weatherSync.statusMessage)
                                        .font(.caption2).foregroundColor(.gray)
                                }
                                
                                Button("Clear Saved Location & Stop Sync") {
                                    weatherSync.clearLocationData()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        Divider()
                        
                        // Reset Defaults
                        Button("Restore Default Atmosphere Settings") {
                            ambientEngine.restoreDefaults()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.bottom, 10)
                
                Section(header: Text("Licensing & Project Ethos").font(.headline)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apache 2.0 Open-Source")
                                .font(.subheadline).bold()
                            Text("Free & Unrestricted Desktop Experience")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("FREE")
                            .font(.caption2).bold()
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                    
                    Text("Animatto is community-first software. All companion physics, character roaming, unlimited custom sprites, focus sessions, contextual speech, and on-device machine learning tools are 100% free with zero advertisements or subscription paywalls.")
                        .font(.caption).foregroundColor(.gray)
                }
                .padding(.bottom, 10)
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



// MARK: - Behavior Preview Simulator Sheet
struct BehaviorPreviewSheet: View {
    let profile: PersonalityProfile
    @Environment(\.dismiss) private var dismiss
    
    var simulation: PersonalityBehaviorSimulator.SimulationResult {
        PersonalityBehaviorSimulator.simulate(profile: profile)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Behavior Simulation Preview", systemImage: "sparkles")
                    .font(.title3).bold()
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            Text("Simulated preview based on '\(profile.name)' traits, interests, and behavior preferences. No live desktop character state or screen captures are triggered.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // 1. Action Tendencies
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Predicted Action Tendencies")
                            .font(.headline)
                        
                        ForEach(CharacterAction.allCases, id: \.self) { action in
                            let pct = simulation.actionProbabilities[action] ?? 0.0
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(action.displayName).font(.subheadline)
                                    Spacer()
                                    Text("\(Int(pct))%").font(.caption).bold()
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.2))
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(actionColor(for: action))
                                            .frame(width: max(geo.size.width * CGFloat(pct / 100.0), 4))
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 2. Cursor & Resting Reactions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interaction & Rest Dynamics")
                            .font(.headline)
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "cursorarrow.rays").foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cursor Proximity Response").font(.subheadline).bold()
                                Text(simulation.cursorResponseDescription).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "moon.zzz.fill").foregroundColor(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sleep & Nap Readiness").font(.subheadline).bold()
                                Text(simulation.restingTendencyDescription).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 3. Topic Reactions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interest Reactions to Desktop Activities")
                            .font(.headline)
                        
                        ForEach(CharacterInterestTopic.allCases) { topic in
                            let pref = profile.preference(for: topic)
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: topic.iconName).frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(topic.displayName).font(.subheadline).bold()
                                        Spacer()
                                        Text(pref.displayName).font(.caption2).bold()
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(prefBadgeColor(pref))
                                            .cornerRadius(4)
                                    }
                                    if let reaction = simulation.topicReactions[topic] {
                                        Text(reaction).font(.caption).foregroundColor(.secondary)
                                    }
                                }
                            }
                            if topic != CharacterInterestTopic.allCases.last {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 4. Sample Contextual Dialogue Voice
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Sample Dialogue Voice")
                                .font(.headline)
                            if profile.behaviorPreferences.dialogueMuted {
                                Spacer()
                                Text("Muted")
                                    .font(.caption2).bold()
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.red.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }
                        
                        ForEach(simulation.sampleDialogue, id: \.self) { sample in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "bubble.left.fill").foregroundColor(.accentColor)
                                Text(sample).font(.callout).italic()
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .frame(minWidth: 460, minHeight: 520)
    }
    
    private func actionColor(for action: CharacterAction) -> Color {
        switch action {
        case .walking: return .blue
        case .exploring: return .green
        case .idle: return .orange
        case .sleeping: return .purple
        }
    }
    
    private func prefBadgeColor(_ pref: TopicPreference) -> Color {
        switch pref {
        case .like: return Color.pink.opacity(0.2)
        case .interested: return Color.blue.opacity(0.2)
        case .dislike: return Color.red.opacity(0.2)
        case .neutral: return Color.gray.opacity(0.2)
        }
    }
}
