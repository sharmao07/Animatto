import SwiftUI
import AppKit
import UniformTypeIdentifiers
import ImageIO

// MARK: - Workshop Tab Mode
enum WorkshopTabMode: String, CaseIterable, Identifiable {
    case magicEraser = "Magic Eraser"
    case aiGenerator = "AI Generator"
    case shimejiDB = "Shimeji DB"
    case presetGallery = "Preset Gallery"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .magicEraser: return "wand.and.stars"
        case .aiGenerator: return "sparkles"
        case .shimejiDB: return "magnifyingglass"
        case .presetGallery: return "person.crop.circle.badge.checkmark"
        }
    }
    
    var isLocal: Bool {
        switch self {
        case .magicEraser, .presetGallery: return true
        case .aiGenerator, .shimejiDB: return false
        }
    }
    
    var badgeLabel: String {
        switch self {
        case .magicEraser: return "Offline Local AI"
        case .aiGenerator: return "Remote Cloud API"
        case .shimejiDB: return "Remote Community API"
        case .presetGallery: return "Offline Local"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .magicEraser, .presetGallery: return .green
        case .aiGenerator: return .purple
        case .shimejiDB: return .orange
        }
    }
}

// MARK: - AIToolsView (Workshop & Creator Experience)
struct AIToolsView: View {
    @StateObject private var workshop = WorkshopService.shared
    @StateObject private var config = WorkshopConfiguration.shared
    @StateObject private var petStorage = PetStorage()
    
    @State private var activeTab: WorkshopTabMode = .magicEraser
    
    // Magic Eraser State
    @State private var selectedImage: NSImage?
    @State private var selectedImageURL: URL?
    @State private var processedData: Data?
    @State private var isGIF: Bool = false
    @State private var eraserStatusMessage: String = "Select an image or GIF to remove background offline."
    
    // AI Generator State
    @State private var promptText: String = ""
    @State private var aiStatusMessage: String = "Enter a prompt to generate a character sprite."
    
    // Shimeji DB Search State
    @State private var searchQuery: String = ""
    
    // Preset Gallery State
    @State private var selectedPreset: PersonalityPreset = .curious
    @State private var targetCompanionURL: URL?
    @State private var appliedPresetAlertMessage: String?
    @State private var showAppliedAlert: Bool = false
    
    let gridColumns = [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 14)]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar with Mode Selector and Online/Offline Badges
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Workshop & Creator Studio")
                        .font(.title2).bold()
                    Text("Create, customize, and edit desktop companions.")
                        .font(.caption).foregroundColor(.gray)
                }
                
                Spacer()
                
                // Mode Segmented Control
                Picker("Workshop Tool", selection: $activeTab) {
                    ForEach(WorkshopTabMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 480)
                
                // Current Mode Privacy / Network Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(activeTab.badgeColor)
                        .frame(width: 8, height: 8)
                    Text(activeTab.badgeLabel)
                        .font(.caption2).bold()
                        .foregroundColor(activeTab.badgeColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(activeTab.badgeColor.opacity(0.12))
                .cornerRadius(6)
            }
            .padding()
            .background(Color.black.opacity(0.25))
            
            Divider()
            
            // Main Tool Area
            Group {
                switch activeTab {
                case .magicEraser:
                    magicEraserView
                case .aiGenerator:
                    aiGeneratorView
                case .shimejiDB:
                    shimejiDBView
                case .presetGallery:
                    presetGalleryView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .alert("Preset Applied", isPresented: $showAppliedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appliedPresetAlertMessage ?? "")
        }
    }
    
    // MARK: - 1. Magic Eraser (Local Vision AI)
    private var magicEraserView: some View {
        HStack(spacing: 20) {
            // Controls
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Magic Eraser (Offline Vision)")
                        .font(.headline)
                    Text("Uses Apple Vision framework offline to isolate companions and remove backgrounds from static images and multi-frame animated GIFs.")
                        .font(.caption).foregroundColor(.gray)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 10) {
                    Button(action: selectLocalFile) {
                        Label("Choose Image or GIF...", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    if let url = selectedImageURL {
                        Text("Selected: \(url.lastPathComponent)")
                            .font(.caption2).foregroundColor(.gray).lineLimit(1)
                    }
                    
                    Button(action: runBackgroundRemoval) {
                        if workshop.isProcessing {
                            HStack {
                                ProgressView().scaleEffect(0.7)
                                Text("Removing Background...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("Remove Background", systemImage: "wand.and.stars")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedImage == nil || workshop.isProcessing)
                    
                    if workshop.isProcessing && isGIF {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: workshop.progress, total: 1.0)
                            Text("Processing frames: \(Int(workshop.progress * 100))%")
                                .font(.caption2).foregroundColor(.gray)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                
                Spacer()
                
                Text(eraserStatusMessage)
                    .font(.caption).foregroundColor(.gray)
                
                Button(action: saveEraserResultToLibrary) {
                    Label("Save to Library", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(processedData == nil || workshop.isProcessing)
            }
            .frame(width: 320)
            
            Divider()
            
            // Preview Canvas with Checkerboard Background
            VStack {
                Text("Transparency Preview").font(.subheadline).bold()
                
                ZStack {
                    CheckerboardBackground()
                        .frame(width: 320, height: 320)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    
                    if let image = selectedImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.6))
                            Text("No Image Loaded")
                                .font(.caption).foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }
    
    // MARK: - 2. AI Generator (Cloud)
    private var aiGeneratorView: some View {
        HStack(spacing: 20) {
            // Controls
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("AI Character Generator")
                        .font(.headline)
                    Text("Generates companion character sprites using remote AI (Pollinations Flux Anime). Generated sprites can then be background-removed with Magic Eraser.")
                        .font(.caption).foregroundColor(.gray)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Prompt").font(.subheadline).bold()
                    TextField("E.g. A cute cyberpunk cat, anime chibi...", text: $promptText)
                        .textFieldStyle(.roundedBorder)
                    
                    // Prompt helpers
                    Text("Quick Inspiration:").font(.caption2).foregroundColor(.gray)
                    HStack(spacing: 6) {
                        Button("Pixel Mage") { promptText = "chibi pixel mage with blue cloak and magical wand" }
                            .buttonStyle(.borderless).font(.caption2)
                        Button("Cyber Kitty") { promptText = "cyberpunk neon robotic kitten with glowing visor" }
                            .buttonStyle(.borderless).font(.caption2)
                        Button("Coffee Sloth") { promptText = "lazy sleepy sloth holding a steaming coffee cup" }
                            .buttonStyle(.borderless).font(.caption2)
                    }
                    
                    Button(action: runAIGeneration) {
                        if workshop.isProcessing {
                            HStack {
                                ProgressView().scaleEffect(0.7)
                                Text("Generating...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("Generate Companion", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(promptText.trimmingCharacters(in: .whitespaces).isEmpty || workshop.isProcessing)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                
                Spacer()
                
                Text(aiStatusMessage)
                    .font(.caption).foregroundColor(.gray)
                
                HStack {
                    Button(action: transferAIToMagicEraser) {
                        Label("Remove BG in Magic Eraser", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedImage == nil || workshop.isProcessing)
                    
                    Button(action: saveEraserResultToLibrary) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(selectedImage == nil || workshop.isProcessing)
                }
            }
            .frame(width: 340)
            
            Divider()
            
            // Generated Result Preview
            VStack {
                Text("Generated Preview").font(.subheadline).bold()
                
                ZStack {
                    CheckerboardBackground()
                        .frame(width: 320, height: 320)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    
                    if let image = selectedImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.6))
                            Text("Generate an image to view preview")
                                .font(.caption).foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }
    
    // MARK: - 3. Shimeji DB Search (External Community)
    private var shimejiDBView: some View {
        VStack(spacing: 14) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search Shimeji DB by character (e.g. Miku, Sayori, Cat)...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit { runShimejiSearch() }
                
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                
                Button("Search") {
                    runShimejiSearch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(searchQuery.trimmingCharacters(in: .whitespaces).isEmpty || workshop.isSearching)
            }
            .padding(10)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
            
            // Results Grid
            if workshop.isSearching {
                Spacer()
                ProgressView("Searching community database...")
                Spacer()
            } else if workshop.searchResults.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(.gray.opacity(0.6))
                    Text(workshop.statusMessage.isEmpty ? "Enter a search term above to discover community Shimejis." : workshop.statusMessage)
                        .font(.caption).foregroundColor(.gray)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 14) {
                        ForEach(workshop.searchResults) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                ZStack {
                                    CheckerboardBackground()
                                        .frame(height: 120)
                                        .cornerRadius(8)
                                    
                                    AsyncImage(url: item.thumbnailURL) { phase in
                                        if let image = phase.image {
                                            image.resizable().scaledToFit().frame(height: 110)
                                        } else if phase.error != nil {
                                            Image(systemName: "photo").foregroundColor(.gray)
                                        } else {
                                            ProgressView().scaleEffect(0.6)
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).font(.subheadline).bold().lineLimit(1)
                                    HStack {
                                        Text(item.type.uppercased())
                                            .font(.caption2).padding(2).background(Color.blue.opacity(0.2)).cornerRadius(3)
                                        Text(item.fileSize).font(.caption2).foregroundColor(.gray)
                                    }
                                    Text("by \(item.uploader)").font(.caption2).foregroundColor(.gray).lineLimit(1)
                                }
                                
                                Button(action: { downloadShimeji(item) }) {
                                    Label("Download", systemImage: "arrow.down.circle")
                                        .font(.caption).frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(workshop.isProcessing)
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Footer status
            HStack {
                Text(workshop.statusMessage)
                    .font(.caption2).foregroundColor(.gray)
                Spacer()
            }
        }
        .padding()
    }
    
    // MARK: - 4. Preset & Profile Gallery (Offline Local)
    private var presetGalleryView: some View {
        HStack(spacing: 20) {
            // Preset Selection List
            VStack(alignment: .leading, spacing: 10) {
                Text("Personality Presets (10 Archetypes)")
                    .font(.headline)
                Text("Select an archetype to inspect traits and apply to any companion in your library without altering its artwork.")
                    .font(.caption).foregroundColor(.gray)
                
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(PersonalityPreset.allCases, id: \.self) { preset in
                            PresetCardRow(
                                preset: preset,
                                isSelected: selectedPreset == preset,
                                onSelect: { selectedPreset = preset }
                            )
                        }
                    }
                }
            }
            .frame(width: 320)
            
            Divider()
            
            // Detail & Apply Inspector
            PresetDetailInspectorView(
                preset: selectedPreset,
                targetCompanionURL: $targetCompanionURL,
                savedPets: petStorage.savedPets,
                onApply: { applyPresetToSelectedCompanion() }
            )
        }
        .padding()
    }
    
    // MARK: - Subviews & Helpers
    
    private func traitBar(label: String, value: Double, color: Color) -> some View {
        HStack {
            Text(label).font(.caption).frame(width: 90, alignment: .leading)
            ProgressView(value: value, total: 1.0)
                .tint(color)
            Text(String(format: "%.0f%%", value * 100))
                .font(.caption2).foregroundColor(.gray).frame(width: 36, alignment: .trailing)
        }
    }
    
    private func sampleVoiceLine(for preset: PersonalityPreset) -> String {
        switch preset {
        case .curious: return "Ooh, what are you working on now?"
        case .sleepy: return "Five more minutes... please..."
        case .playful: return "Catch me if you can! Zoom!"
        case .shy: return "...Um, hi there... I'm right here if you need me."
        case .mischievous: return "Hehehe, don't look away from your screen!"
        case .calm: return "Take a deep breath. Everything is going smoothly."
        case .energetic: return "Let's do this! What's next on our agenda?!"
        case .sarcastic: return "Oh wonderful, another click. Thrilling."
        case .supportive: return "You've got this! I believe in your work!"
        case .balanced: return "Just hanging out by your window!"
        }
    }
    
    // MARK: - Actions
    
    private func selectLocalFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = SupportedMediaFormat.supportedUTTypes
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            selectedImageURL = url
            selectedImage = NSImage(contentsOf: url)
            isGIF = url.pathExtension.lowercased() == "gif"
            processedData = nil
            eraserStatusMessage = "Loaded \(url.lastPathComponent). Ready to remove background."
        }
    }
    
    private func runBackgroundRemoval() {
        guard let image = selectedImage else { return }
        
        Task {
            if isGIF, let url = selectedImageURL {
                do {
                    let gifData = try await workshop.processLocalGIF(sourceURL: url)
                    await MainActor.run {
                        self.processedData = gifData
                        self.selectedImage = NSImage(data: gifData)
                        self.eraserStatusMessage = "Background removed successfully from GIF!"
                    }
                } catch {
                    await MainActor.run {
                        self.eraserStatusMessage = "GIF Error: \(error.localizedDescription)"
                    }
                }
            } else {
                do {
                    let (transparentImage, pngData) = try await workshop.processLocalStillImage(image: image)
                    await MainActor.run {
                        self.selectedImage = transparentImage
                        self.processedData = pngData
                        self.eraserStatusMessage = "Background removed successfully!"
                    }
                } catch {
                    await MainActor.run {
                        self.eraserStatusMessage = "Vision Error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func runAIGeneration() {
        let prompt = promptText
        Task {
            do {
                let (image, data) = try await workshop.generateAISprite(prompt: prompt)
                await MainActor.run {
                    self.selectedImage = image
                    self.processedData = data
                    self.isGIF = false
                    self.selectedImageURL = nil
                    self.aiStatusMessage = "Generated sprite! Click 'Remove BG in Magic Eraser' to isolate."
                }
            } catch {
                await MainActor.run {
                    self.aiStatusMessage = "Generation Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func transferAIToMagicEraser() {
        activeTab = .magicEraser
        eraserStatusMessage = "AI sprite transferred. Click 'Remove Background' to erase white background."
    }
    
    private func runShimejiSearch() {
        let query = searchQuery
        Task {
            do {
                _ = try await workshop.searchShimejiDB(query: query)
            } catch {
                await MainActor.run {
                    workshop.statusMessage = "Search error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func downloadShimeji(_ item: ShimejiSearchResult) {
        Task {
            do {
                _ = try await workshop.downloadAndImportCommunityAsset(result: item)
                await MainActor.run {
                    petStorage.loadPets()
                }
            } catch {
                await MainActor.run {
                    workshop.statusMessage = "Download error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveEraserResultToLibrary() {
        guard let data = processedData ?? selectedImage?.tiffRepresentation else { return }
        
        do {
            let storageDir = PetStorage.getStorageDirectory()
            let ext = isGIF ? "gif" : "png"
            let name = "Custom_Pet_\(UUID().uuidString.prefix(6)).\(ext)"
            let (sanitizedName, _) = try WorkshopImportValidator.validate(data: data, suggestedName: name)
            let destURL = storageDir.appendingPathComponent(sanitizedName)
            try data.write(to: destURL, options: .atomic)
            
            // Save local creator attribution sidecar
            let attribution = CommunityAssetAttribution(
                name: sanitizedName,
                uploader: "Local Creator",
                fileSize: "\(data.count / 1024) KB",
                format: ext,
                license: "User Created",
                isLocalOnly: true
            )
            attribution.saveSidecar(for: destURL)
            
            petStorage.loadPets()
            eraserStatusMessage = "Saved '\(sanitizedName)' to Library!"
        } catch {
            eraserStatusMessage = "Save error: \(error.localizedDescription)"
        }
    }
    
    private func applyPresetToSelectedCompanion() {
        guard let url = targetCompanionURL else { return }
        let charId = PersonalityStorage.shared.characterId(for: url)
        PersonalityDecoupler.applyPreset(preset: selectedPreset, to: charId)
        
        appliedPresetAlertMessage = "Applied the '\(selectedPreset.displayName)' archetype to '\(url.deletingPathExtension().lastPathComponent)'! Its animation and artwork remain completely unchanged."
        showAppliedAlert = true
    }
}

// MARK: - Checkerboard Pattern View
struct CheckerboardBackground: View {
    var body: some View {
        Canvas { context, size in
            let squareSize: CGFloat = 10
            let cols = Int(ceil(size.width / squareSize))
            let rows = Int(ceil(size.height / squareSize))
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let isEven = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(Path(rect), with: .color(isEven ? Color.gray.opacity(0.18) : Color.white.opacity(0.08)))
                }
            }
        }
    }
}

// MARK: - Preset Card Row Component
struct PresetCardRow: View {
    let preset: PersonalityPreset
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: preset.iconName)
                .frame(width: 24, height: 24)
                .foregroundColor(isSelected ? .blue : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.displayName).font(.subheadline).bold()
                Text(preset.summary).font(.caption2).foregroundColor(.gray).lineLimit(1)
            }
            Spacer()
        }
        .padding(8)
        .background(isSelected ? Color.blue.opacity(0.25) : Color.black.opacity(0.15))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Preset Detail Inspector Component
struct PresetDetailInspectorView: View {
    let preset: PersonalityPreset
    @Binding var targetCompanionURL: URL?
    let savedPets: [URL]
    let onApply: () -> Void
    
    var body: some View {
        let profile = PersonalityProfile.preset(preset)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: preset.iconName)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(preset.displayName)
                    .font(.title2).bold()
                Spacer()
                Text("[Offline Local]")
                    .font(.caption2).bold().foregroundColor(.green)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.green.opacity(0.15)).cornerRadius(4)
            }
            
            Text(preset.summary)
                .font(.subheadline).foregroundColor(.gray)
                .font(.subheadline).foregroundColor(.gray)
            
            Divider()
            
            // Trait Breakdown Meters
            VStack(alignment: .leading, spacing: 6) {
                Text("Core Behavioral Tendencies").font(.subheadline).bold()
                traitBar(label: "Energy", value: profile.energy, color: .orange)
                traitBar(label: "Sociability", value: profile.sociability, color: .blue)
                traitBar(label: "Playfulness", value: profile.playfulness, color: .green)
                traitBar(label: "Shyness", value: profile.shyness, color: .purple)
                traitBar(label: "Independence", value: profile.independence, color: .teal)
            }
            
            Divider()
            
            // Sample Voice Line
            VStack(alignment: .leading, spacing: 4) {
                Text("Sample Voice Line").font(.subheadline).bold()
                Text("\"\(sampleVoiceLine(for: preset))\"")
                    .font(.body).italic().foregroundColor(.secondary)
                    .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.2)).cornerRadius(6)
            }
            
            Spacer()
            
            // Apply to Companion Target
            VStack(alignment: .leading, spacing: 8) {
                Text("Apply Preset to Companion").font(.subheadline).bold()
                Text("This updates the companion's personality matrix while leaving its original sprite and animation frames intact.")
                    .font(.caption2).foregroundColor(.gray)
                
                HStack {
                    Picker("Target Companion", selection: $targetCompanionURL) {
                        Text("Select a companion...").tag(nil as URL?)
                        ForEach(savedPets, id: \.self) { petURL in
                            Text(petURL.deletingPathExtension().lastPathComponent).tag(petURL as URL?)
                        }
                    }
                    
                    Button("Apply Preset") {
                        onApply()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(targetCompanionURL == nil)
                }
            }
            .padding()
            .background(Color.black.opacity(0.25))
            .cornerRadius(10)
        }
    }
    
    private func traitBar(label: String, value: Double, color: Color) -> some View {
        HStack {
            Text(label).font(.caption).frame(width: 90, alignment: .leading)
            ProgressView(value: value, total: 1.0)
                .tint(color)
            Text(String(format: "%.0f%%", value * 100))
                .font(.caption2).foregroundColor(.gray).frame(width: 36, alignment: .trailing)
        }
    }
    
    private func sampleVoiceLine(for preset: PersonalityPreset) -> String {
        switch preset {
        case .curious: return "Ooh, what are you working on now?"
        case .sleepy: return "Five more minutes... please..."
        case .playful: return "Catch me if you can! Zoom!"
        case .shy: return "...Um, hi there... I'm right here if you need me."
        case .mischievous: return "Hehehe, don't look away from your screen!"
        case .calm: return "Take a deep breath. Everything is going smoothly."
        case .energetic: return "Let's do this! What's next on our agenda?!"
        case .sarcastic: return "Oh wonderful, another click. Thrilling."
        case .supportive: return "You've got this! I believe in your work!"
        case .balanced: return "Just hanging out by your window!"
        }
    }
}
