import SwiftUI
@preconcurrency import Vision
import CoreImage
import AppKit
import Combine
import UniformTypeIdentifiers
import ImageIO

// MARK: - Search Result Model
struct ShimejiSearchResult: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let uploader: String
    let fileSize: String
    let type: String
    let remoteURL: URL
    let thumbnailURL: URL
}

struct AIToolsView: View {
    @State private var selectedImage: NSImage?
    @State private var selectedImageURL: URL?
    @State private var processedData: Data?
    @State private var isGIF = false
    
    @State private var isProcessing = false
    @State private var prompt = ""
    @State private var statusMessage = "Select an image or generate one."
    
    // --- SEARCH STATE ---
    @State private var searchQuery = ""
    @State private var searchResults: [ShimejiSearchResult] = []
    @State private var isSearching = false
    @State private var selectedSearchResult: ShimejiSearchResult?
    @State private var downloadStatus = "Ready to search."
    
    // --- UI TOGGLE ---
    @State private var showingSearchGrid = false
    
    let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 10)]
    
    var body: some View {
        HStack(spacing: 0) {
            
            // LEFT SIDE: Controls
            VStack(alignment: .leading, spacing: 25) {
                Text("Workshop")
                    .font(.largeTitle).bold()
                
                // Tool 1: Magic Eraser
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Magic Eraser (Local AI)")
                        .font(.headline)
                    Text("Uses Apple Vision to remove backgrounds offline. Supports images & GIFs.")
                        .font(.caption).foregroundColor(.gray)
                    
                    HStack {
                        Button("Load Image / GIF") { loadImage() }
                        Button("Remove Background") {
                            Task { await removeBackground() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedImage == nil || isProcessing)
                    }
                }
                .padding().background(Color.black.opacity(0.2)).cornerRadius(10)
                
                // Tool 2: AI Generator
                VStack(alignment: .leading, spacing: 10) {
                    Text("2. AI Generator (Cloud)")
                        .font(.headline)
                    Text("Generates sprites using an unfiltered AI.")
                        .font(.caption).foregroundColor(.gray)
                    
                    TextField("E.g., A cute pixel wizard...", text: $prompt)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Generate Pet") {
                        Task { await generateImage() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(prompt.isEmpty || isProcessing)
                }
                .padding().background(Color.black.opacity(0.2)).cornerRadius(10)
                
                // Tool 3: Shimeji DB Search
                VStack(alignment: .leading, spacing: 10) {
                    Text("3. Shimeji DB Search (External)")
                        .font(.headline)
                    Text("Find existing transparent shimeji assets by keyword.")
                        .font(.caption).foregroundColor(.gray)
                    
                    HStack {
                        TextField("Search... e.g., 'Sayori' or 'Miku'", text: $searchQuery)
                            .textFieldStyle(.roundedBorder)
                        Button(action: {
                            Task { await searchShimejiDB() }
                        }) {
                            Image(systemName: "magnifyingglass")
                        }
                        .disabled(searchQuery.isEmpty || isSearching)
                    }
                }
                .padding().background(Color.black.opacity(0.2)).cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .frame(width: 350)
            
            Divider()
            
            // RIGHT SIDE: Results Canvas
            VStack {
                if showingSearchGrid {
                    VStack {
                        HStack {
                            Text("Shimeji DB Search Results (\(searchResults.count))")
                                .font(.headline).bold()
                            Spacer()
                            Text(downloadStatus).font(.caption).foregroundColor(.gray)
                        }.padding(.top)
                        
                        ZStack {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(searchResults) { result in
                                        VStack(alignment: .leading) {
                                            AsyncImage(url: result.thumbnailURL) { phase in
                                                if let image = phase.image {
                                                    image.resizable().scaledToFill()
                                                } else if phase.error != nil {
                                                    Color.red.opacity(0.3)
                                                } else {
                                                    ProgressView()
                                                }
                                            }
                                            .frame(width: 140, height: 140)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedSearchResult == result ? Color.blue : Color.clear, lineWidth: 3)
                                            )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(result.name).font(.subheadline).bold().lineLimit(1)
                                                HStack {
                                                    Text(result.type).font(.caption)
                                                    Text("by \(result.uploader)").font(.caption).foregroundColor(.gray).lineLimit(1)
                                                }
                                                Text(result.fileSize).font(.caption2).foregroundColor(.gray)
                                            }
                                        }
                                        .onTapGesture {
                                            selectedSearchResult = result
                                        }
                                    }
                                }
                                .padding()
                            }
                            
                            if isSearching {
                                ProgressView("Searching External DB...")
                                    .padding().background(Color.black.opacity(0.7)).cornerRadius(10)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(15)
                        
                        Button(action: {
                            Task { await importSelectedShimeji() }
                        }) {
                            Text("💾 Download Selected Pet")
                                .bold().frame(width: 180).padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent).tint(.green)
                        .disabled(selectedSearchResult == nil || isProcessing)
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text("Canvas Preview").font(.headline)
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 300, height: 300)
                            .cornerRadius(15)
                        
                        if isProcessing { ProgressView("Processing...") }
                        else if let image = selectedImage {
                            Image(nsImage: image).resizable().scaledToFit().frame(width: 280, height: 280)
                        }
                        else { Text("No image loaded").foregroundColor(.gray) }
                    }
                    
                    Text(statusMessage).font(.caption).foregroundColor(.gray).padding(.top, 5)
                    
                    Button("💾 Save to Library") { saveToLibrary() }
                    .buttonStyle(.borderedProminent).tint(.green)
                    .disabled(selectedImage == nil || isProcessing).padding()
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
    
    // MARK: - App Actions
    func loadImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK, let url = panel.url {
            selectedImage = NSImage(contentsOf: url)
            selectedImageURL = url
            isGIF = url.pathExtension.lowercased() == "gif"
            processedData = nil
            statusMessage = isGIF ? "GIF loaded." : "Image loaded."
            showingSearchGrid = false
            searchResults = []
        }
    }
    
    // MARK: - Local App Actions (Add From PC Fix)
    func saveToLibrary() {
        let appFolder = PetStorage.getStorageDirectory()
        
        do {
            // 1. FORCE create the directory if it does not exist
            if !FileManager.default.fileExists(atPath: appFolder.path) {
                try FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
            }
            
            // 2. Safely write the data
            if let dataToSave = processedData {
                let extensionString = isGIF ? "gif" : "png"
                let fileURL = appFolder.appendingPathComponent("AI_Pet_\(UUID().uuidString.prefix(5)).\(extensionString)")
                try dataToSave.write(to: fileURL)
                statusMessage = "Saved successfully! Check Library tab."
                
            } else if let image = selectedImage,
                      let tiffData = image.tiffRepresentation,
                      let bitmapImage = NSBitmapImageRep(data: tiffData),
                      let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                
                let fileURL = appFolder.appendingPathComponent("AI_Pet_\(UUID().uuidString.prefix(5)).png")
                try pngData.write(to: fileURL)
                statusMessage = "Saved successfully! Check Library tab."
                
            } else {
                statusMessage = "No valid image data to save."
                return
            }
            
        } catch {
            statusMessage = "File Error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Local AI
    func removeBackground() async {
        isProcessing = true
        
        if isGIF, let url = selectedImageURL {
            statusMessage = "Extracting frames..."
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let newGIFData = processGIF(url: url) {
                    DispatchQueue.main.async {
                        self.processedData = newGIFData
                        self.selectedImage = NSImage(data: newGIFData)
                        self.statusMessage = "GIF background removed!"
                        self.isProcessing = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = "Failed to process GIF."
                        self.isProcessing = false
                    }
                }
            }
            return
        }
        
        guard let image = selectedImage,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            isProcessing = false
            return
        }
        
        statusMessage = "Extracting subject..."
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
                if let result = request.results?.first {
                    let maskPixelBuffer = try result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: false)
                    
                    let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)
                    let context = CIContext()
                    if let finalCGImage = context.createCGImage(ciImage, from: ciImage.extent) {
                        let finalNSImage = NSImage(cgImage: finalCGImage, size: image.size)
                        
                        let bitmapImage = NSBitmapImageRep(cgImage: finalCGImage)
                        let pngData = bitmapImage.representation(using: .png, properties: [:])
                        
                        DispatchQueue.main.async {
                            self.selectedImage = finalNSImage
                            self.processedData = pngData
                            self.statusMessage = "Background removed!"
                            self.isProcessing = false
                        }
                        return
                    }
                }
            } catch {
                print("Vision error: \(error)")
            }
            DispatchQueue.main.async {
                self.statusMessage = "Failed to remove background."
                self.isProcessing = false
            }
        }
    }
    
    func processGIF(url: URL) -> Data? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData as CFMutableData, UTType.gif.identifier as CFString, count, nil) else { return nil }
        
        let gifProperties = CGImageSourceCopyProperties(source, nil)
        CGImageDestinationSetProperties(destination, gifProperties)
        
        let request = VNGenerateForegroundInstanceMaskRequest()
        let context = CIContext()
        
        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, i, nil)
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            var finalCGImage = cgImage
            
            do {
                try handler.perform([request])
                if let result = request.results?.first {
                    let maskPixelBuffer = try result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: false)
                    let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)
                    if let cgMasked = context.createCGImage(ciImage, from: ciImage.extent) {
                        finalCGImage = cgMasked
                    }
                }
            } catch {
                print("Frame \(i) masking failed: \(error)")
            }
            
            CGImageDestinationAddImage(destination, finalCGImage, frameProperties)
        }
        
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
    
    func generateImage() async {
        isProcessing = true
        showingSearchGrid = false
        statusMessage = "Generating via Unfiltered Anime AI..."
        
        let fullPrompt = prompt + " chibi character, simple white background, high quality, clean design"
        
        guard let encodedPrompt = fullPrompt.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://image.pollinations.ai/prompt/\(encodedPrompt)?width=1024&height=1024&nologo=true&model=flux-anime") else {
            statusMessage = "Invalid prompt formatting."
            isProcessing = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.statusMessage = "AI generation failed. Try a different prompt."
                self.isProcessing = false
                return
            }
            
            if let downloadedImage = NSImage(data: data) {
                self.selectedImage = downloadedImage
                self.selectedImageURL = nil
                self.isGIF = false
                self.processedData = nil
                self.statusMessage = "Generation complete! Click Remove Background."
            } else {
                self.statusMessage = "Failed to decode image data."
            }
        } catch {
            self.statusMessage = "Network error: \(error.localizedDescription)"
        }
        
        self.isProcessing = false
    }
    
    // MARK: - External Search Engine
    func searchShimejiDB() async {
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        showingSearchGrid = true
        isSearching = true
        searchResults = []
        selectedSearchResult = nil
        downloadStatus = "Contacting Database..."
        
        let apiURLString = "https://animotion-api.vercel.app/api/search?query=\(encodedQuery)"
        
        guard let url = URL(string: apiURLString) else {
            DispatchQueue.main.async {
                self.downloadStatus = "Invalid API URL."
                self.isSearching = false
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.downloadStatus = "Invalid response from server."
                    self.isSearching = false
                }
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.downloadStatus = "API returned an error (Code: \(httpResponse.statusCode))."
                    self.isSearching = false
                }
                return
            }
            
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var foundResults: [ShimejiSearchResult] = []
                
                for item in jsonArray {
                    if let name = item["name"] as? String,
                       let uploader = item["uploader"] as? String,
                       let fileSize = item["fileSize"] as? String,
                       let type = item["type"] as? String,
                       let remoteURLString = item["remoteURL"] as? String,
                       let remoteURL = URL(string: remoteURLString),
                       let thumbnailURLString = item["thumbnailURL"] as? String,
                       let thumbnailURL = URL(string: thumbnailURLString) {
                        
                        let result = ShimejiSearchResult(
                            name: name,
                            uploader: uploader,
                            fileSize: fileSize,
                            type: type,
                            remoteURL: remoteURL,
                            thumbnailURL: thumbnailURL
                        )
                        foundResults.append(result)
                    }
                }
                
                DispatchQueue.main.async {
                    self.searchResults = foundResults
                    self.downloadStatus = foundResults.isEmpty ? "No results found for '\(self.searchQuery)'." : "Search complete."
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.downloadStatus = "Network error. Could not reach database."
            }
        }
        
        DispatchQueue.main.async {
            self.isSearching = false
        }
    }
    
    // MARK: - Actual File Downloader (Web Download Fix)
    func importSelectedShimeji() async {
        guard let selected = selectedSearchResult else { return }
        isProcessing = true
        downloadStatus = "Downloading \(selected.name)..."
        
        do {
            // Fetch the image from the web
            var request = URLRequest(url: selected.remoteURL)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
            request.setValue("image/gif, image/png, image/*", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    self.downloadStatus = "Rejected by server (Code: \(code))."
                    self.isProcessing = false
                }
                return
            }
            
            // 1. FORCE create the directory if it does not exist
            let appFolder = PetStorage.getStorageDirectory()
            if !FileManager.default.fileExists(atPath: appFolder.path) {
                try FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
            }
            
            // 2. Save directly to the Library folder, completely bypassing the old import logic
            let safeName = selected.name.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "")
            let finalURL = appFolder.appendingPathComponent("\(safeName)_\(UUID().uuidString.prefix(4))\(selected.type)")
            
            try data.write(to: finalURL)
            
            DispatchQueue.main.async {
                self.processedData = data
                self.isProcessing = false
                self.searchResults = []
                self.showingSearchGrid = false
                self.statusMessage = "Shimeji '\(selected.name)' saved to library!"
            }
            
        } catch {
            DispatchQueue.main.async {
                self.downloadStatus = "Save error: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
}
