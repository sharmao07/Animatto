import SwiftUI
import UniformTypeIdentifiers
import ServiceManagement

// MARK: - Main Application View (Phase 2 Native Redesign)
struct MainAppView: View {
    @EnvironmentObject var petManager: PetManager
    @ObservedObject private var ambientEngine = AmbientEngine.shared
    @ObservedObject private var timerManager = ProductivityTimerManager.shared
    @ObservedObject private var audioSettings = AudioSettings.shared
    @ObservedObject private var aquariumManager = AquariumManager.shared
    
    @State private var selectedTab = "Library"
    @State private var selectedFileURL: URL?
    
    // Persistent Preferences
    @AppStorage("appAccentHex") private var appAccentHex = "007AFF"
    @AppStorage("isLiquidGlassEnabled") private var isLiquidGlassEnabled = true
    @AppStorage("upsideDownMenuMode") private var upsideDownMenuMode = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Window Vibrancy & Title Bar Unification
            WindowAccessorView { window in
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.titlebarSeparatorStyle = .none
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true
                
                if isLiquidGlassEnabled {
                    window.isOpaque = false
                    window.backgroundColor = .clear
                } else {
                    window.isOpaque = true
                    window.backgroundColor = NSColor.windowBackgroundColor
                }
            }
            .frame(width: 0, height: 0)
            
            // Base Window Background: Neutral macOS surface (no muddy color bleed)
            if isLiquidGlassEnabled {
                LiquidGlassView(material: .underWindowBackground, blendingMode: .behindWindow)
                    .ignoresSafeArea()
            } else {
                Color(NSColor.windowBackgroundColor)
                    .ignoresSafeArea()
            }
            
            // Native Split Layout: Left Sidebar + Right Main Content
            HStack(spacing: 0) {
                // MARK: 1. Left Sidebar
                sidebarView
                    .frame(width: 220)
                
                // Divider Hairline
                Rectangle()
                    .fill(AnimattoTheme.divider)
                    .frame(width: AnimattoTheme.hairline)
                    .ignoresSafeArea()
                
                // MARK: 2. Right Main Content Area
                VStack(spacing: 0) {
                    contentHeaderBar
                    
                    Divider()
                    
                    // Active Tab Content
                    Group {
                        switch selectedTab {
                        case "Library":
                            LibraryView(selectedFileURL: $selectedFileURL)
                        case "Aquarium":
                            AquariumDashboardView()
                        case "Ambient Worlds":
                            AmbientModesView()
                        case "Workshop":
                            AIToolsView()
                        case "Productivity":
                            ProductivityFocusView()
                        case "Audio", "Audio Console":
                            AudioConsoleView()
                        case "Settings":
                            SettingsView()
                        default:
                            LibraryView(selectedFileURL: $selectedFileURL)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(
                    isLiquidGlassEnabled ?
                    Color(NSColor.windowBackgroundColor).opacity(colorScheme == .dark ? 0.35 : 0.55) :
                    Color(NSColor.windowBackgroundColor)
                )
            }
        }
        .tint(Color(hex: appAccentHex))
        .navigationTitle("Animatto")
        .frame(minWidth: 920, minHeight: 640)
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
            ambientEngine.isEnabled.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoToggleMute)) { _ in
            audioSettings.isMasterMuted.toggle()
            AudioEngine.shared.updateAmbientVolume()
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoBringPetsToFront)) { _ in
            bringAllPetsToFront()
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoHideAllPets)) { _ in
            toggleHideAllPets()
        }
        .onReceive(NotificationCenter.default.publisher(for: .animattoToggleAquarium)) { _ in
            aquariumManager.toggleAquarium()
        }
    }
    
    // MARK: - Sidebar View
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Identity Header (Padded to clear macOS traffic lights)
            HStack(spacing: AnimattoTheme.space10) {
                Image(systemName: "hare.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: appAccentHex))
                    .frame(width: 24, height: 24)
                    .background(Color(hex: appAccentHex).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Animatto")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Text("v1.2.0")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.leading, 78) // Clear standard macOS window traffic lights
            .padding(.trailing, AnimattoTheme.space16)
            .padding(.top, 14)
            .padding(.bottom, AnimattoTheme.space16)
            
            Divider()
                .padding(.bottom, AnimattoTheme.space8)
            
            // Navigation Groups
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AnimattoTheme.space16) {
                    
                    // Group: Companions
                    sidebarSection(title: "COMPANIONS") {
                        AnimattoSidebarItem(
                            title: "Library",
                            icon: "pawprint.fill",
                            isSelected: selectedTab == "Library",
                            badge: petManager.activePets.isEmpty ? nil : "\(petManager.activePets.count) roaming"
                        ) {
                            switchTab("Library")
                        }
                    }
                    
                    // Group: Environments
                    sidebarSection(title: "ENVIRONMENTS") {
                        AnimattoSidebarItem(
                            title: "Aquarium",
                            icon: "fish.fill",
                            isSelected: selectedTab == "Aquarium",
                            badge: aquariumManager.isVisible ? "Open" : nil
                        ) {
                            switchTab("Aquarium")
                        }
                        
                        AnimattoSidebarItem(
                            title: "Ambient Worlds",
                            icon: "cloud.sun.rain.fill",
                            isSelected: selectedTab == "Ambient Worlds",
                            badge: ambientEngine.isEnabled ? "Active" : nil
                        ) {
                            switchTab("Ambient Worlds")
                        }
                    }
                    
                    // Group: Studio
                    sidebarSection(title: "STUDIO") {
                        AnimattoSidebarItem(
                            title: "Workshop",
                            icon: "wand.and.stars",
                            isSelected: selectedTab == "Workshop"
                        ) {
                            switchTab("Workshop")
                        }
                    }
                    
                    // Group: Tools
                    sidebarSection(title: "TOOLS") {
                        AnimattoSidebarItem(
                            title: "Productivity",
                            icon: "timer",
                            isSelected: selectedTab == "Productivity",
                            badge: timerManager.currentPhase != .idle ? timerManager.formattedRemainingTime : nil
                        ) {
                            switchTab("Productivity")
                        }
                        
                        AnimattoSidebarItem(
                            title: "Audio Console",
                            icon: "speaker.wave.3.fill",
                            isSelected: selectedTab == "Audio" || selectedTab == "Audio Console",
                            badge: audioSettings.isMasterMuted ? "Muted" : nil
                        ) {
                            switchTab("Audio Console")
                        }
                    }
                    
                    // Group: Preferences
                    sidebarSection(title: "PREFERENCES") {
                        AnimattoSidebarItem(
                            title: "Settings",
                            icon: "gearshape.fill",
                            isSelected: selectedTab == "Settings"
                        ) {
                            switchTab("Settings")
                        }
                    }
                }
                .padding(.horizontal, AnimattoTheme.space12)
                .padding(.top, AnimattoTheme.space4)
            }
            
            Spacer()
            
            // Bottom Privacy & Local-First Indicator
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: AnimattoTheme.space8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: appAccentHex))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Offline & Local First")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Zero telemetry • 100% on-device")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, AnimattoTheme.space16)
                .padding(.vertical, AnimattoTheme.space12)
            }
        }
        .background {
            if isLiquidGlassEnabled {
                LiquidGlassView(material: .sidebar, blendingMode: .behindWindow)
            } else {
                Color(NSColor.windowBackgroundColor)
            }
        }
    }
    
    private func sidebarSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.horizontal, AnimattoTheme.space10)
                .padding(.bottom, 2)
            content()
        }
    }
    
    private func switchTab(_ tab: String) {
        selectedTab = tab
        AudioEngine.shared.playUISound(.click)
    }
    
    // MARK: - Content Header Bar
    private var contentHeaderBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(tabTitle(for: selectedTab))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text(tabSubtitle(for: selectedTab))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quick Status Indicators & Controls
            HStack(spacing: AnimattoTheme.space8) {
                if petManager.isPrivacyShieldActive {
                    AnimattoBadge("Privacy Shield", icon: "shield.slash.fill", color: .orange)
                }
                
                if audioSettings.isMasterMuted {
                    AnimattoBadge("Audio Muted", icon: "speaker.slash.fill", color: .secondary)
                }
                
                if aquariumManager.isVisible {
                    AnimattoBadge("Aquarium Open", icon: "fish.fill", color: .cyan)
                }
            }
        }
        .padding(.horizontal, AnimattoTheme.space20)
        .padding(.vertical, 12)
    }
    
    private func tabTitle(for tab: String) -> String {
        switch tab {
        case "Library": return "Companions Library"
        case "Aquarium": return "Aquarium Environment"
        case "Ambient Worlds": return "Ambient Worlds & Weather"
        case "Workshop": return "Creator Studio & AI Workshop"
        case "Productivity": return "Productivity & Focus Timer"
        case "Audio", "Audio Console": return "Audio Console & Soundscape"
        case "Settings": return "Application Preferences"
        default: return tab
        }
    }
    
    private func tabSubtitle(for tab: String) -> String {
        switch tab {
        case "Library": return "Manage, inspect, and launch roaming desktop companions"
        case "Aquarium": return "Desktop oceanarium simulation with autonomous aquatic species"
        case "Ambient Worlds": return "Immersive atmospheric weather systems and seasonal particles"
        case "Workshop": return "Offline background removal, preset crafting, and community sprites"
        case "Productivity": return "Integrated Pomodoro timer with companion encouragement states"
        case "Audio", "Audio Console": return "Independent companion voice, movement, weather, and UI channel mix"
        case "Settings": return "Physics, system startup, personality memory, and display options"
        default: return ""
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
    
    // MARK: - The Library Tab (Redesigned)
    struct LibraryView: View {
        @EnvironmentObject var petManager: PetManager
        @StateObject var storage = PetStorage()
        @Binding var selectedFileURL: URL?
        @State private var petSize: Double = 150
        
        // Renaming State
        @State private var showRenameAlert = false
        @State private var petToRename: URL?
        @State private var newPetName: String = ""
        
        // Deletion Confirmation
        @State private var showDeleteConfirm = false
        @State private var petToDelete: URL?
        
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
        @Environment(\.colorScheme) private var colorScheme
        
        let columns = [GridItem(.adaptive(minimum: 120, maximum: 150), spacing: AnimattoTheme.space16)]
        
        var body: some View {
            HStack(spacing: 0) {
                
                // LEFT SIDE: Companion Grid
                VStack(spacing: 0) {
                    // Toolbar
                    HStack {
                        HStack(spacing: AnimattoTheme.space8) {
                            Text("Saved Companions")
                                .font(.system(size: 14, weight: .semibold))
                            AnimattoBadge("\(storage.savedPets.count)")
                        }
                        
                        Spacer()
                        
                        Button(action: pickFile) {
                            Label("Add from Mac", systemImage: "plus")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, AnimattoTheme.space20)
                    .padding(.vertical, AnimattoTheme.space12)
                    
                    Divider()
                    
                    if storage.savedPets.isEmpty {
                        AnimattoEmptyState(
                            icon: "sparkles.rectangle.stack",
                            title: "No Companions in Library",
                            message: "Add custom sprites or GIFs from your Mac, or restore the official starter companions.",
                            actionTitle: "Restore Starter Companions",
                            action: {
                                storage.loadDefaultCharacters()
                                storage.loadPets()
                            }
                        )
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: AnimattoTheme.space16) {
                                ForEach(storage.savedPets, id: \.self) { url in
                                    companionGridCard(for: url)
                                }
                            }
                            .padding(AnimattoTheme.space20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
                // Hairline Divider
                Rectangle()
                    .fill(AnimattoTheme.divider)
                    .frame(width: AnimattoTheme.hairline)
                
                // RIGHT SIDE: Details & Personality Inspector Panel
                ScrollView {
                    VStack(alignment: .leading, spacing: AnimattoTheme.space16) {
                        if let url = selectedFileURL {
                            selectedCompanionInspector(for: url)
                        } else {
                            AnimattoEmptyState(
                                icon: "arrow.left.circle",
                                title: "No Companion Selected",
                                message: "Select a companion from the grid to configure their personality matrix, scale, and launch them onto your desktop."
                            )
                            .frame(minHeight: 400)
                        }
                    }
                    .padding(AnimattoTheme.space20)
                }
                .frame(width: 350)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.35))
            }
            .onAppear {
                storage.loadPets()
                if selectedFileURL == nil, let first = storage.savedPets.first {
                    selectCompanion(url: first)
                }
            }
            .onChange(of: storage.savedPets) { _, pets in
                if selectedFileURL == nil, let first = pets.first {
                    selectCompanion(url: first)
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
                Text("Reset all traits, interests, and behavior preferences to their archetype defaults?")
            }
            .confirmationDialog("Delete Companion", isPresented: $showDeleteConfirm) {
                Button("Delete Companion", role: .destructive) {
                    if let target = petToDelete {
                        storage.deletePet(at: target)
                        if selectedFileURL == target {
                            selectedFileURL = storage.savedPets.first(where: { $0 != target })
                            if let newSel = selectedFileURL {
                                currentProfile = PersonalityStorage.shared.getProfile(for: newSel)
                            } else {
                                currentProfile = nil
                            }
                        }
                        petToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to permanently remove this companion from your library?")
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
        
        // MARK: - Companion Card Component
        private func companionGridCard(for url: URL) -> some View {
            let isSelected = selectedFileURL == url
            let isRoaming = isPetRoaming(url: url)
            
            return Button(action: { selectCompanion(url: url) }) {
                VStack(spacing: AnimattoTheme.space8) {
                    ZStack(alignment: .topTrailing) {
                        // Thumbnail Preview
                        ThumbnailView(url: url)
                            .id(url)
                            .frame(width: 120, height: 120)
                            .background(Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08))
                            .clipShape(RoundedRectangle(cornerRadius: AnimattoTheme.radius10))
                        
                        // Active Roaming Indicator Pill
                        if isRoaming {
                            HStack(spacing: 3) {
                                Circle().fill(Color.green).frame(width: 6, height: 6)
                                Text("Roaming").font(.system(size: 9, weight: .bold)).foregroundColor(.green)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.black.opacity(0.65)))
                            .padding(6)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: AnimattoTheme.radius10)
                            .stroke(
                                isSelected ? Color(hex: appAccentHex) : AnimattoTheme.subtleBorder,
                                lineWidth: isSelected ? 2 : AnimattoTheme.hairline
                            )
                    )
                    
                    // Name
                    Text(url.deletingPathExtension().lastPathComponent)
                        .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(width: 120)
                }
                .padding(AnimattoTheme.space8)
                .background(
                    RoundedRectangle(cornerRadius: AnimattoTheme.radius10)
                        .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Launch Companion") {
                    petManager.launchPet(url: url, size: CGFloat(petSize))
                }
                
                Divider()
                
                Button("Rename") { triggerRename(for: url) }
                
                let profile = PersonalityStorage.shared.getProfile(for: url)
                Button("Export Profile...") {
                    exportCurrentProfile(profile: profile)
                }
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    petToDelete = url
                    showDeleteConfirm = true
                }
            }
        }
        
        // MARK: - Selected Companion Inspector
        private func selectedCompanionInspector(for url: URL) -> some View {
            VStack(alignment: .leading, spacing: AnimattoTheme.space16) {
                
                // Character Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(url.deletingPathExtension().lastPathComponent)
                            .font(.system(size: 16, weight: .bold))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Text(url.pathExtension.uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { triggerRename(for: url) }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Rename Companion")
                }
                
                // Large Preview Display
                AnimattoCard {
                    ZStack {
                        CheckerboardBackground()
                            .opacity(0.15)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: AnimattoTheme.radius8))
                        
                        ThumbnailView(url: url)
                            .id(url)
                            .frame(width: min(CGFloat(petSize), 160), height: min(CGFloat(petSize), 160))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()
                }
                
                // Launch / Roaming Actions
                let isRoaming = isPetRoaming(url: url)
                VStack(spacing: AnimattoTheme.space8) {
                    Button(action: {
                        petManager.launchPet(url: url, size: CGFloat(petSize))
                        AudioEngine.shared.playUISound(.click)
                    }) {
                        Label("Launch onto Desktop", systemImage: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if isRoaming {
                        HStack {
                            Text("1 active instance roaming")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Dismiss") {
                                dismissPet(url: url)
                            }
                            .buttonStyle(.borderless)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Divider()
                
                // Spawn Scale Slider
                AnimattoSliderRow(
                    "Desktop Spawn Scale",
                    description: "Initial rendered bounding box size",
                    value: $petSize,
                    in: 50...400,
                    step: 10,
                    format: { "\(Int($0)) px" }
                )
                
                Divider()
                
                // MARK: - Personality Matrix Inspector
                if let profile = currentProfile {
                    VStack(alignment: .leading, spacing: AnimattoTheme.space12) {
                        HStack {
                            AnimattoSectionHeader(
                                title: "Personality Matrix",
                                subtitle: "Governs autonomous behavior and reactions",
                                icon: "sparkles"
                            )
                            Spacer()
                            Button("Preview") { showPreviewSheet = true }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                        
                        // Archetype Selector
                        AnimattoCard {
                            VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                                HStack {
                                    Text("Archetype")
                                        .font(.system(size: 12, weight: .medium))
                                    Spacer()
                                    Picker("", selection: Binding(
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
                                    .labelsHidden()
                                    .controlSize(.small)
                                }
                                
                                Text(profile.preset?.summary ?? "Custom behavior configuration.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        // 1. Ten Dimensions Disclosure
                        DisclosureGroup(isExpanded: $showCustomTraits) {
                            VStack(alignment: .leading, spacing: AnimattoTheme.space10) {
                                Text("VITALITY & LOCOMOTION")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                                
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
                                Text("SOCIAL DEMEANOR")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                traitSlider(name: "Sociable", desc: "Introverted ↔ Social Butterfly", value: Binding(
                                    get: { profile.sociability },
                                    set: { updateTrait(\.sociability, value: $0, url: url) }
                                ))
                                traitSlider(name: "Shy", desc: "Bold ↔ Timid & Elusive", value: Binding(
                                    get: { profile.shyness },
                                    set: { updateTrait(\.shyness, value: $0, url: url) }
                                ))
                                traitSlider(name: "Independent", desc: "Attentive ↔ Free Spirit", value: Binding(
                                    get: { profile.independence },
                                    set: { updateTrait(\.independence, value: $0, url: url) }
                                ))
                                traitSlider(name: "Attention Seeking", desc: "Aloof ↔ Craving Interaction", value: Binding(
                                    get: { profile.attentionSeeking },
                                    set: { updateTrait(\.attentionSeeking, value: $0, url: url) }
                                ))
                                
                                Divider().padding(.vertical, 2)
                                Text("EXPRESSION & WIT")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                
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
                            Text("10 Personality Dimensions")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        
                        // 2. Interests & Reactions Disclosure
                        DisclosureGroup(isExpanded: $showInterests) {
                            VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                                Text("Reactions to active desktop applications and workflows.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 2)
                                
                                ForEach(CharacterInterestTopic.allCases) { topic in
                                    let currentPref = profile.preference(for: topic)
                                    HStack {
                                        Image(systemName: topic.iconName).frame(width: 16)
                                            .foregroundColor(.secondary)
                                        Text(topic.displayName).font(.system(size: 11))
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
                                        .labelsHidden()
                                        .controlSize(.small)
                                        .frame(width: 105)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        } label: {
                            Text("Interests & Topic Reactions")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        
                        // 3. Behavioral Boundaries & Rules
                        DisclosureGroup(isExpanded: $showBehaviorPrefs) {
                            VStack(alignment: .leading, spacing: AnimattoTheme.space8) {
                                AnimattoToggleRow(
                                    "Follow Cursor",
                                    description: "Attraction toward the user's mouse",
                                    isOn: Binding(
                                        get: { profile.behaviorPreferences.cursorFollowingEnabled },
                                        set: { updateBehaviorPref(\.cursorFollowingEnabled, value: $0, url: url) }
                                    )
                                )
                                
                                AnimattoSliderRow(
                                    "Rest & Nap Readiness",
                                    description: "Willingness to idle and sleep",
                                    value: Binding(
                                        get: { profile.behaviorPreferences.sleepFrequency },
                                        set: { updateBehaviorPref(\.sleepFrequency, value: $0, url: url) }
                                    ),
                                    in: 0.0...1.0,
                                    step: 0.05,
                                    format: { "\(Int($0 * 100))%" }
                                )
                                
                                AnimattoSliderRow(
                                    "Speech Frequency",
                                    description: "Dialogue frequency multiplier",
                                    value: Binding(
                                        get: { profile.behaviorPreferences.commentFrequency },
                                        set: { updateBehaviorPref(\.commentFrequency, value: $0, url: url) }
                                    ),
                                    in: 0.1...2.0,
                                    step: 0.1,
                                    format: { String(format: "%.1fx", $0) }
                                )
                                
                                AnimattoToggleRow(
                                    "Mute Dialogue",
                                    description: "Silences cartoon speech bubbles",
                                    isOn: Binding(
                                        get: { profile.behaviorPreferences.dialogueMuted },
                                        set: { updateBehaviorPref(\.dialogueMuted, value: $0, url: url) }
                                    )
                                )
                                
                                AnimattoToggleRow(
                                    "Social Encounters",
                                    description: "Interact with other roaming companions",
                                    isOn: Binding(
                                        get: { profile.behaviorPreferences.socialInteractionsEnabled },
                                        set: { updateBehaviorPref(\.socialInteractionsEnabled, value: $0, url: url) }
                                    )
                                )
                            }
                            .padding(.top, 4)
                        } label: {
                            Text("Behavior Preferences & Rules")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        
                        // 4. Memory History
                        let charId = PersonalityStorage.shared.characterId(for: url)
                        let memories = memoryStore.memories(for: charId)
                        DisclosureGroup("Memories & Continuity (\(memories.count))") {
                            VStack(alignment: .leading, spacing: 6) {
                                if memories.isEmpty {
                                    Text("No memories recorded yet for this companion.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 2)
                                } else {
                                    ForEach(memories.prefix(4)) { mem in
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(mem.summary)
                                                    .font(.system(size: 11, weight: .medium))
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
                        .font(.system(size: 12, weight: .semibold))
                        
                        Divider().padding(.vertical, 2)
                        
                        // Actions: Export, Import, Reset
                        HStack(spacing: AnimattoTheme.space8) {
                            Button("Export...") { exportCurrentProfile(profile: profile) }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            
                            Button("Import...") { importProfileForCurrent(url: url) }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            
                            Spacer()
                            
                            Button("Reset Defaults") { showResetConfirmAlert = true }
                                .buttonStyle(.plain)
                                .foregroundColor(.red)
                                .font(.system(size: 11))
                        }
                    }
                }
            }
        }
        
        // MARK: - Helpers
        private func selectCompanion(url: URL) {
            selectedFileURL = url
            currentProfile = PersonalityStorage.shared.getProfile(for: url)
            AudioEngine.shared.playUISound(.select)
        }
        
        private func isPetRoaming(url: URL) -> Bool {
            petManager.activePets.values.contains(where: { $0.url == url })
        }
        
        private func dismissPet(url: URL) {
            if let active = petManager.activePets.values.first(where: { $0.url == url }) {
                petManager.removePet(id: active.id)
            }
        }
        
        private func triggerRename(for url: URL) {
            petToRename = url
            newPetName = url.deletingPathExtension().lastPathComponent
            showRenameAlert = true
        }
        
        private func renameFile() {
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
        
        private func updateTrait(_ keyPath: WritableKeyPath<PersonalityProfile, Double>, value: Double, url: URL) {
            guard var profile = currentProfile else { return }
            profile[keyPath: keyPath] = min(max(value, 0.0), 1.0)
            currentProfile = profile
            PersonalityStorage.shared.saveProfile(profile, for: url)
            petManager.updateProfile(for: url, newProfile: profile)
        }
        
        private func updateBehaviorPref<T>(_ keyPath: WritableKeyPath<CharacterBehaviorPreferences, T>, value: T, url: URL) {
            guard var profile = currentProfile else { return }
            profile.behaviorPreferences[keyPath: keyPath] = value
            currentProfile = profile
            PersonalityStorage.shared.saveProfile(profile, for: url)
            petManager.updateProfile(for: url, newProfile: profile)
        }
        
        private func updateTopicPreference(topic: CharacterInterestTopic, preference: TopicPreference, url: URL) {
            guard var profile = currentProfile else { return }
            profile.setPreference(preference, for: topic)
            currentProfile = profile
            PersonalityStorage.shared.saveProfile(profile, for: url)
            petManager.updateProfile(for: url, newProfile: profile)
        }
        
        private func exportCurrentProfile(profile: PersonalityProfile) {
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
        
        private func importProfileForCurrent(url: URL) {
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
        
        private func traitSlider(name: String, desc: String, value: Binding<Double>) -> some View {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Text("\(Int(value.wrappedValue * 100))%")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Slider(value: value, in: 0.0...1.0, step: 0.05)
                    .controlSize(.small)
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        
        private func pickFile() {
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
