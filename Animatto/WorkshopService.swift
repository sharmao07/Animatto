import Foundation
import SwiftUI
import AppKit
@preconcurrency import Vision
import CoreImage
import UniformTypeIdentifiers
import ImageIO
import Combine

// MARK: - Search Result Model
public struct ShimejiSearchResult: Identifiable, Hashable, Codable {
    public let id: UUID
    public let name: String
    public let uploader: String
    public let fileSize: String
    public let type: String
    public let remoteURL: URL
    public let thumbnailURL: URL
    
    public init(
        id: UUID = UUID(),
        name: String,
        uploader: String,
        fileSize: String,
        type: String,
        remoteURL: URL,
        thumbnailURL: URL
    ) {
        self.id = id
        self.name = name
        self.uploader = uploader
        self.fileSize = fileSize
        self.type = type
        self.remoteURL = remoteURL
        self.thumbnailURL = thumbnailURL
    }
}

// MARK: - Workshop Error
public enum WorkshopError: LocalizedError, Equatable {
    case emptyData
    case fileTooLarge(size: Int, limit: Int)
    case unsupportedMediaFormat
    case invalidURL
    case networkError(String)
    case serverRejected(code: Int)
    case malformedResponse
    case visionProcessingFailed(String)
    case pathTraversalDetected
    case cancelled
    case onlineDisabled
    
    public var errorDescription: String? {
        switch self {
        case .emptyData:
            return "Imported file data is empty."
        case .fileTooLarge(let size, let limit):
            let sizeMB = Double(size) / (1024 * 1024)
            let limitMB = Double(limit) / (1024 * 1024)
            return String(format: "File size (%.1f MB) exceeds limit of %.1f MB.", sizeMB, limitMB)
        case .unsupportedMediaFormat:
            return "File format is unsupported or failed signature verification."
        case .invalidURL:
            return "Invalid or malformed external URL."
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .serverRejected(let code):
            return "Server rejected request with status code \(code)."
        case .malformedResponse:
            return "Received unexpected or malformed response data from server."
        case .visionProcessingFailed(let reason):
            return "Vision foreground extraction failed: \(reason)"
        case .pathTraversalDetected:
            return "Security violation: filename contains unsafe path traversal characters."
        case .cancelled:
            return "Processing operation was cancelled."
        case .onlineDisabled:
            return "Online cloud services are currently disabled. Operating in offline mode."
        }
    }
}

// MARK: - Workshop Configuration
public class WorkshopConfiguration: ObservableObject {
    public static let shared = WorkshopConfiguration()
    
    // Centralized external endpoints
    // NOTE: The `flux-anime` model was a paid/premium model that returned HTTP 402.
    // Switched to the free `flux` model on image.pollinations.ai which requires no auth.
    // Added `&enhance=true` for better character sprite quality.
    @Published public var aiEndpointTemplate: String = "https://image.pollinations.ai/prompt/{prompt}?width=1024&height=1024&nologo=true&model=flux&enhance=true&seed=-1"
    @Published public var shimejiSearchEndpoint: String = "https://animotion-api.vercel.app/api/search"
    @Published public var requestTimeout: TimeInterval = 10.0
    @Published public var aiGenerationTimeout: TimeInterval = 60.0
    @Published public var maxDownloadBytes: Int = 50 * 1024 * 1024 // 50 MB
    @Published public var isOnlineDisabled: Bool = false
    @Published public var aiPromptSuffix: String = ", chibi character, simple white background, high quality anime art style, clean design"
    
    public init() {}
    
    // MARK: - Endpoint URL Builders
    
    public func buildAIGenerationURL(prompt: String) -> URL? {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let fullPrompt = trimmed + aiPromptSuffix
        guard let encoded = fullPrompt.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        
        let urlString = aiEndpointTemplate.replacingOccurrences(of: "{prompt}", with: encoded)
        return URL(string: urlString)
    }
    
    public func buildShimejiSearchURL(query: String) -> URL? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        guard var components = URLComponents(string: shimejiSearchEndpoint) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "query", value: trimmed)
        ]
        return components.url
    }
}

// MARK: - Workshop Import & Signature Validator
public struct WorkshopImportValidator {
    
    /// Validates file header / magic bytes against known signatures rather than relying solely on extension.
    public static func detectFormat(data: Data) -> SupportedMediaFormat? {
        guard data.count >= 8 else { return nil }
        
        // 1. PNG: 89 50 4E 47 0D 0A 1A 0A
        let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        if data.prefix(8).elementsEqual(pngHeader) {
            return .png
        }
        
        // 2. GIF: GIF87a (47 49 46 38 37 61) or GIF89a (47 49 46 38 39 61)
        if data.count >= 6 {
            let gif87: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]
            let gif89: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]
            let prefix6 = Array(data.prefix(6))
            if prefix6 == gif87 || prefix6 == gif89 {
                return .gif
            }
        }
        
        // 3. JPEG: FF D8 FF
        if data.count >= 3 && data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF {
            return .jpeg
        }
        
        // 4. WebP: RIFF (bytes 0..3) ... WEBP (bytes 8..11)
        if data.count >= 12 {
            let riff: [UInt8] = [0x52, 0x49, 0x46, 0x46]
            let webp: [UInt8] = [0x57, 0x45, 0x42, 0x50]
            if data.prefix(4).elementsEqual(riff) && data[8..<12].elementsEqual(webp) {
                return .webp
            }
        }
        
        // 5. MP4 / QuickTime: bytes 4..7 contain 'ftyp'
        if data.count >= 12 {
            let ftyp: [UInt8] = [0x66, 0x74, 0x79, 0x70]
            if data[4..<8].elementsEqual(ftyp) {
                return .mp4
            }
        }
        
        return nil
    }
    
    /// Sanitizes file name against path traversal (../, /), invalid characters, and strips unsafe suffixes.
    public static func sanitizeFileName(_ original: String, defaultExtension: String = "png") -> String {
        // Trim leading and trailing whitespace first
        var clean = original.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Strip path traversal patterns and replace spaces with underscores
        clean = clean
            .replacingOccurrences(of: "../", with: "")
            .replacingOccurrences(of: "..\\", with: "")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "\0", with: "")
        
        // Remove dangerous shell/filesystem characters: * ? " < > |
        let disallowed = CharacterSet(charactersIn: "*?\"<>|;$`'~")
        clean = clean.components(separatedBy: disallowed).joined(separator: "")
        
        // Strip leading dots to prevent hidden files
        while clean.hasPrefix(".") {
            clean.removeFirst()
        }
        
        // If string consists purely of underscores or is empty, use safe generated fallback
        let stripped = clean.replacingOccurrences(of: "_", with: "")
        if clean.isEmpty || stripped.isEmpty {
            clean = "companion_\(UUID().uuidString.prefix(6))"
        }
        
        // Ensure valid extension
        let ext = (clean as NSString).pathExtension.lowercased()
        if ext.isEmpty || SupportedMediaFormat(rawValue: ext) == nil {
            clean = "\(clean).\(defaultExtension)"
        }
        
        return clean
    }
    
    /// Thoroughly validates data and file name before persistence.
    public static func validate(
        data: Data,
        suggestedName: String,
        maxBytes: Int = 50 * 1024 * 1024
    ) throws -> (sanitizedName: String, format: SupportedMediaFormat) {
        guard !data.isEmpty else {
            throw WorkshopError.emptyData
        }
        
        guard data.count <= maxBytes else {
            throw WorkshopError.fileTooLarge(size: data.count, limit: maxBytes)
        }
        
        guard let format = detectFormat(data: data) else {
            throw WorkshopError.unsupportedMediaFormat
        }
        
        let sanitized = sanitizeFileName(suggestedName, defaultExtension: format.rawValue)
        return (sanitized, format)
    }
}

// MARK: - Community Asset Attribution & Metadata Sidecar
public struct CommunityAssetAttribution: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var uploader: String
    public var fileSize: String
    public var format: String
    public var sourceURL: String?
    public var license: String
    public var dateImported: Date
    public var isLocalOnly: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        uploader: String,
        fileSize: String,
        format: String,
        sourceURL: String? = nil,
        license: String = "Community Share",
        dateImported: Date = Date(),
        isLocalOnly: Bool = false
    ) {
        self.id = id
        self.name = name
        self.uploader = uploader
        self.fileSize = fileSize
        self.format = format
        self.sourceURL = sourceURL
        self.license = license
        self.dateImported = dateImported
        self.isLocalOnly = isLocalOnly
    }
    
    public static func sidecarURL(for assetURL: URL) -> URL {
        return assetURL.deletingPathExtension().appendingPathExtension("meta.json")
    }
    
    public func saveSidecar(for assetURL: URL) {
        let metaURL = Self.sidecarURL(for: assetURL)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(self)
            try data.write(to: metaURL, options: .atomic)
        } catch {
            print("Failed to save metadata sidecar for \(assetURL.lastPathComponent): \(error)")
        }
    }
    
    public static func loadSidecar(for assetURL: URL) -> CommunityAssetAttribution? {
        let metaURL = sidecarURL(for: assetURL)
        guard FileManager.default.fileExists(atPath: metaURL.path),
              let data = try? Data(contentsOf: metaURL),
              let attribution = try? JSONDecoder().decode(CommunityAssetAttribution.self, from: data) else {
            return nil
        }
        return attribution
    }
}

// MARK: - Vision Background Removal Engine
public class VisionBackgroundRemover: @unchecked Sendable {
    public static let shared = VisionBackgroundRemover()
    
    public init() {}
    
    /// Removes background from a CGImage using Apple Vision offline framework.
    public nonisolated func removeBackground(from cgImage: CGImage) throws -> (transparentCGImage: CGImage, pngData: Data) {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try handler.perform([request])
        
        guard let result = request.results?.first else {
            throw WorkshopError.visionProcessingFailed("No foreground subjects detected by Vision model.")
        }
        
        let maskPixelBuffer = try result.generateMaskedImage(
            ofInstances: result.allInstances,
            from: handler,
            croppedToInstancesExtent: false
        )
        
        let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        let context = CIContext(options: [.useSoftwareRenderer: false])
        
        guard let finalCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw WorkshopError.visionProcessingFailed("Failed to render masked image to CGImage.")
        }
        
        let bitmap = NSBitmapImageRep(cgImage: finalCGImage)
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw WorkshopError.visionProcessingFailed("Failed to encode transparent PNG data.")
        }
        
        return (finalCGImage, pngData)
    }
    
    /// Removes background from a single static image using Apple Vision offline framework.
    public nonisolated func removeBackground(from image: NSImage) throws -> (transparentImage: NSImage, pngData: Data) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw WorkshopError.visionProcessingFailed("Unable to extract CGImage from provided image.")
        }
        
        let (finalCGImage, pngData) = try removeBackground(from: cgImage)
        let finalNSImage = NSImage(cgImage: finalCGImage, size: image.size)
        return (finalNSImage, pngData)
    }
    
    /// Processes an animated GIF frame-by-frame, removing backgrounds while preserving delays, loop counts, and dimensions.
    public nonisolated func removeBackgroundFromGIF(
        sourceURL: URL,
        progress: ((Double) -> Void)? = nil,
        isCancelled: (() -> Bool)? = nil
    ) throws -> Data {
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw WorkshopError.visionProcessingFailed("Failed to open GIF source image.")
        }
        
        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else {
            throw WorkshopError.visionProcessingFailed("GIF source contains 0 frames.")
        }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData,
            UTType.gif.identifier as CFString,
            frameCount,
            nil
        ) else {
            throw WorkshopError.visionProcessingFailed("Unable to create GIF destination context.")
        }
        
        // Preserve global container properties (loop count, color map, etc.)
        let globalProperties = CGImageSourceCopyProperties(source, nil)
        CGImageDestinationSetProperties(destination, globalProperties)
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        let request = VNGenerateForegroundInstanceMaskRequest()
        
        for i in 0..<frameCount {
            if let isCancelled = isCancelled, isCancelled() {
                throw WorkshopError.cancelled
            }
            
            autoreleasepool {
                guard let frameCG = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                    return
                }
                
                // Copy frame timing properties (delay time, unclamped delay, disposal method)
                let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, i, nil)
                
                var maskedFrameCG: CGImage = frameCG
                let handler = VNImageRequestHandler(cgImage: frameCG, options: [:])
                
                do {
                    try handler.perform([request])
                    if let result = request.results?.first {
                        let maskPixelBuffer = try result.generateMaskedImage(
                            ofInstances: result.allInstances,
                            from: handler,
                            croppedToInstancesExtent: false
                        )
                        let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)
                        if let rendered = context.createCGImage(ciImage, from: ciImage.extent) {
                            maskedFrameCG = rendered
                        }
                    }
                } catch {
                    // Fall back to original frame to preserve animation continuity
                    maskedFrameCG = frameCG
                }
                
                CGImageDestinationAddImage(destination, maskedFrameCG, frameProperties)
            }
            
            let currentProgress = Double(i + 1) / Double(frameCount)
            progress?(currentProgress)
        }
        
        guard CGImageDestinationFinalize(destination) else {
            throw WorkshopError.visionProcessingFailed("Failed to finalize output GIF destination.")
        }
        
        return mutableData as Data
    }
}

// MARK: - Decoupling Personality Profiles & Character Artwork
public struct PersonalityDecoupler {
    
    /// Binds a new artwork file to an existing character ID, preserving all memories and personality settings.
    public static func updateArtwork(for characterId: String, newAssetURL: URL) {
        PersonalityStorage.shared.bindArtwork(at: newAssetURL, to: characterId)
    }
    
    /// Applies a predefined personality archetype preset to a character without altering its sprite or artwork.
    public static func applyPreset(preset: PersonalityPreset, to characterId: String) {
        PersonalityStorage.shared.applyPreset(preset, to: characterId)
    }
}

// MARK: - Workshop Service (Unified Engine)
@MainActor
public class WorkshopService: ObservableObject {
    public static let shared = WorkshopService()
    
    // Injectable URLSession for deterministic testing and timeout control
    public var session: URLSession
    
    // Observable UI State
    @Published public var isProcessing: Bool = false
    @Published public var isSearching: Bool = false
    @Published public var statusMessage: String = "Ready."
    @Published public var progress: Double = 0.0
    @Published public var searchResults: [ShimejiSearchResult] = []
    @Published public var selectedSearchResult: ShimejiSearchResult?
    @Published public var previewImage: NSImage?
    @Published public var previewData: Data?
    @Published public var isGIFPreview: Bool = false
    
    private var activeTask: Task<Void, Never>?
    
    public init(session: URLSession? = nil) {
        if let customSession = session {
            self.session = customSession
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = WorkshopConfiguration.shared.requestTimeout
            config.timeoutIntervalForResource = WorkshopConfiguration.shared.requestTimeout * 2
            self.session = URLSession(configuration: config)
        }
    }
    
    deinit {
        activeTask?.cancel()
    }
    
    public func cancelCurrentOperation() {
        activeTask?.cancel()
        isProcessing = false
        isSearching = false
        statusMessage = "Operation cancelled."
    }
    
    // MARK: - Local AI: Background Removal
    
    public func processLocalStillImage(image: NSImage) async throws -> (NSImage, Data) {
        isProcessing = true
        statusMessage = "Extracting subject with Apple Vision (offline)..."
        defer { isProcessing = false }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw WorkshopError.visionProcessingFailed("Unable to extract CGImage from provided image.")
        }
        let size = image.size
        
        let processingTask = Task.detached(priority: .userInitiated) {
            try VisionBackgroundRemover.shared.removeBackground(from: cgImage)
        }
        let (transparentCGImage, pngData) = try await processingTask.value
        
        let finalImage = NSImage(cgImage: transparentCGImage, size: size)
        return (finalImage, pngData)
    }
    
    public func processLocalGIF(sourceURL: URL) async throws -> Data {
        isProcessing = true
        statusMessage = "Processing GIF frames with Apple Vision (offline)..."
        progress = 0.0
        defer {
            isProcessing = false
            progress = 1.0
        }
        
        let (progressStream, progressContinuation) = AsyncStream<Double>.makeStream()
        
        let progressUpdater = Task { @MainActor [weak self] in
            for await p in progressStream {
                self?.progress = p
            }
        }
        defer {
            progressUpdater.cancel()
        }
        
        let gifTask = Task.detached(priority: .userInitiated) {
            try VisionBackgroundRemover.shared.removeBackgroundFromGIF(
                sourceURL: sourceURL,
                progress: { p in
                    progressContinuation.yield(p)
                },
                isCancelled: {
                    Task.isCancelled
                }
            )
        }
        let resultData = try await gifTask.value
        
        progressContinuation.finish()
        return resultData
    }
    
    // MARK: - Cloud AI: Sprite Generation
    
    /// Generates a companion sprite image from a text prompt using Pollinations.ai free `flux` model.
    ///
    /// Provider: https://image.pollinations.ai (free, no auth required, anonymous)
    /// Model: `flux` — the free FLUX text-to-image model. `flux-anime` was removed from the free
    /// tier and now returns HTTP 402 Payment Required. `flux` is the documented free alternative.
    ///
    /// Limitations:
    /// - Requires an internet connection.
    /// - Generation can take 20–60 seconds for complex prompts.
    /// - Anonymous quota applies; excessive automated requests may be throttled (HTTP 429).
    /// - If Pollinations.ai changes its free tier, this endpoint may return 402 again.
    public func generateAISprite(prompt: String) async throws -> (NSImage, Data) {
        guard !WorkshopConfiguration.shared.isOnlineDisabled else {
            throw WorkshopError.onlineDisabled
        }
        
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw WorkshopError.invalidURL
        }
        
        guard let url = WorkshopConfiguration.shared.buildAIGenerationURL(prompt: trimmedPrompt) else {
            throw WorkshopError.invalidURL
        }
        
        isProcessing = true
        statusMessage = "Generating sprite via Pollinations AI (may take 20–60s)…"
        defer { isProcessing = false }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = WorkshopConfiguration.shared.aiGenerationTimeout
        request.setValue("image/jpeg, image/png, image/webp, image/*", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko)", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WorkshopError.malformedResponse
        }
        
        // Translate well-known status codes to actionable messages
        switch httpResponse.statusCode {
        case 200:
            break
        case 400:
            throw WorkshopError.networkError("Bad request — the prompt may contain unsupported characters (HTTP 400).")
        case 401, 403:
            throw WorkshopError.networkError("Access denied by image server (HTTP \(httpResponse.statusCode)). The provider may require authentication.")
        case 402:
            var detail = "Payment required / Free rate limit exceeded"
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errObj = json["error"] as? [String: Any],
               let msg = errObj["message"] as? String {
                detail = msg
            }
            throw WorkshopError.networkError("\(detail) (HTTP 402). Free anonymous tier allows 1 image every 45 seconds. Please wait before generating again.")
        case 429:
            throw WorkshopError.networkError("Generation rate limit reached (HTTP 429). Please wait a moment before trying again.")
        case 500...599:
            throw WorkshopError.networkError("Image generation server error (HTTP \(httpResponse.statusCode)). Please try again later.")
        default:
            throw WorkshopError.serverRejected(code: httpResponse.statusCode)
        }
        
        // Guard against suspiciously small responses (HTML error pages, etc.)
        guard data.count > 512 else {
            throw WorkshopError.malformedResponse
        }
        
        // Validate magic bytes — accept PNG, JPEG, WebP; reject HTML or text error pages
        let (_, format) = try WorkshopImportValidator.validate(data: data, suggestedName: "ai_sprite")
        guard format == .png || format == .jpeg || format == .webp else {
            throw WorkshopError.unsupportedMediaFormat
        }
        
        guard let image = NSImage(data: data) else {
            throw WorkshopError.malformedResponse
        }
        
        await MainActor.run {
            self.statusMessage = "Sprite generated! Use 'Remove BG' to isolate the character."
        }
        
        return (image, data)
    }
    
    // MARK: - Community Search & Download
    
    public func searchShimejiDB(query: String) async throws -> [ShimejiSearchResult] {
        guard !WorkshopConfiguration.shared.isOnlineDisabled else {
            throw WorkshopError.onlineDisabled
        }
        
        guard let url = WorkshopConfiguration.shared.buildShimejiSearchURL(query: query) else {
            throw WorkshopError.invalidURL
        }
        
        isSearching = true
        statusMessage = "Searching Shimeji database..."
        defer { isSearching = false }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = WorkshopConfiguration.shared.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WorkshopError.malformedResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw WorkshopError.serverRejected(code: httpResponse.statusCode)
            }
            
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw WorkshopError.malformedResponse
            }
        
        var results: [ShimejiSearchResult] = []
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
                results.append(result)
            }
        }
        
        let finalResults = results
        await MainActor.run {
            self.searchResults = finalResults
            self.statusMessage = finalResults.isEmpty ? "No results found for '\(query)'." : "Found \(finalResults.count) results."
        }
        
        return finalResults
        } catch {
            await MainActor.run {
                if (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == NSURLErrorTimedOut {
                    self.statusMessage = "Search timed out. Community database is currently unresponsive."
                } else if case WorkshopError.serverRejected(let code) = error {
                    self.statusMessage = "Community server error (HTTP \(code)). Please try again later."
                } else {
                    self.statusMessage = "Search failed: \(error.localizedDescription)"
                }
            }
            throw error
        }
    }
    
    public func downloadAndImportCommunityAsset(
        result: ShimejiSearchResult,
        storageDirectory: URL? = nil
    ) async throws -> URL {
        guard !WorkshopConfiguration.shared.isOnlineDisabled else {
            throw WorkshopError.onlineDisabled
        }
        
        let targetDir = storageDirectory ?? PetStorage.getStorageDirectory()
        
        isProcessing = true
        statusMessage = "Downloading \(result.name)..."
        defer { isProcessing = false }
        
        var request = URLRequest(url: result.remoteURL)
        request.timeoutInterval = WorkshopConfiguration.shared.requestTimeout
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("image/gif, image/png, image/*", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WorkshopError.malformedResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw WorkshopError.serverRejected(code: httpResponse.statusCode)
        }
        
        // Strict magic byte validation and filename sanitization
        let (sanitizedName, _) = try WorkshopImportValidator.validate(
            data: data,
            suggestedName: "\(result.name)\(result.type)",
            maxBytes: WorkshopConfiguration.shared.maxDownloadBytes
        )
        
        // Ensure storage directory exists
        if !FileManager.default.fileExists(atPath: targetDir.path) {
            try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
        }
        
        let destinationURL = targetDir.appendingPathComponent(sanitizedName)
        try data.write(to: destinationURL, options: .atomic)
        
        // Persist community attribution sidecar
        let attribution = CommunityAssetAttribution(
            name: result.name,
            uploader: result.uploader,
            fileSize: result.fileSize,
            format: result.type,
            sourceURL: result.remoteURL.absoluteString,
            license: "Community Share (Shimeji DB)",
            isLocalOnly: false
        )
        attribution.saveSidecar(for: destinationURL)
        
        await MainActor.run {
            self.statusMessage = "Saved '\(result.name)' to Library with attribution."
        }
        
        return destinationURL
    }
}
