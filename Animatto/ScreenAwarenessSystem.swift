import Foundation
import CoreGraphics
import AppKit
import Combine
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

// MARK: - Capture Source Type
public enum CaptureSourceType: String, Codable, CaseIterable {
    case activeDisplay = "Active Display"
    case mainDisplay = "Main Display"
    case activeWindow = "Active Window"
}

// MARK: - Vision Processing Mode
public enum VisionProcessingMode: String, Codable, CaseIterable {
    case local = "Local Vision Model (Private)"
    case cloud = "Cloud Vision API (Remote)"
}

// MARK: - Screen Capture Permission State
public enum ScreenCapturePermissionState: String {
    case authorized = "Authorized"
    case denied = "Denied"
    case notDetermined = "Not Determined"
}

// MARK: - Screen Understanding Request
public struct ScreenUnderstandingRequest {
    public let imageData: Data
    public let activeAppName: String?
    public let activeAppBundleId: String?
    public let characterName: String
    public let personalitySummary: String
    public let timestamp: Date
    
    public init(
        imageData: Data,
        activeAppName: String? = nil,
        activeAppBundleId: String? = nil,
        characterName: String = "Companion",
        personalitySummary: String = "Curious and observant",
        timestamp: Date = Date()
    ) {
        self.imageData = imageData
        self.activeAppName = activeAppName
        self.activeAppBundleId = activeAppBundleId
        self.characterName = characterName
        self.personalitySummary = personalitySummary
        self.timestamp = timestamp
    }
}

// MARK: - Structured Screen Understanding Result
public struct ScreenUnderstandingResult: Codable, Equatable {
    public let category: VisualActivityCategory
    public let summary: String
    public let observations: [String]
    public let confidence: Double
    public let timestamp: Date
    public let providerName: String
    public let isSuitableForDialogue: Bool
    
    public init(
        category: VisualActivityCategory,
        summary: String,
        observations: [String] = [],
        confidence: Double = 0.85,
        timestamp: Date = Date(),
        providerName: String = "Local Vision",
        isSuitableForDialogue: Bool = true
    ) {
        self.category = category
        // Limit summary length for safety
        self.summary = String(summary.prefix(140)).trimmingCharacters(in: .whitespacesAndNewlines)
        self.observations = Array(observations.prefix(3).map { String($0.prefix(80)) })
        self.confidence = min(max(confidence, 0.0), 1.0)
        self.timestamp = timestamp
        self.providerName = providerName
        self.isSuitableForDialogue = isSuitableForDialogue
    }
}

// MARK: - Screen Awareness Errors
public enum ScreenAwarenessError: Error, LocalizedError, Equatable {
    case disabled
    case permissionDenied
    case activeAppExcluded(bundleId: String)
    case cloudConsentRequired
    case apiKeyMissing
    case localEndpointUnavailable(String)
    case invalidResponse
    case captureFailed(String)
    case inFlightCancelled
    case noDisplayAvailable
    
    public var errorDescription: String? {
        switch self {
        case .disabled:
            return "Screen awareness is currently disabled."
        case .permissionDenied:
            return "Screen recording permission has not been granted in macOS System Settings."
        case .activeAppExcluded(let bundleId):
            return "Capture skipped: Active application (\(bundleId)) is in your privacy exclusion list."
        case .cloudConsentRequired:
            return "Cloud visual processing requires explicit user consent before image data leaves your Mac."
        case .apiKeyMissing:
            return "No cloud API key configured."
        case .localEndpointUnavailable(let details):
            return "Local vision model endpoint is unavailable: \(details)"
        case .invalidResponse:
            return "The vision model returned an invalid or unparseable response."
        case .captureFailed(let reason):
            return "ScreenCaptureKit capture failed: \(reason)"
        case .inFlightCancelled:
            return "Capture request was cancelled."
        case .noDisplayAvailable:
            return "No active display found for screen capture."
        }
    }
}

// MARK: - Vision Provider Protocol
public protocol ScreenUnderstandingProvider {
    var providerName: String { get }
    var isLocal: Bool { get }
    func analyzeScreen(request: ScreenUnderstandingRequest) async throws -> ScreenUnderstandingResult
}

// MARK: - Local Vision Provider
public class LocalVisionProvider: ScreenUnderstandingProvider {
    public let providerName = "Local Vision (Ollama / LocalAI)"
    public let isLocal = true
    public var endpoint: URL = URL(string: "http://localhost:11434/api/generate")!
    public var modelName: String = "llava"
    
    public init() {}
    
    public func analyzeScreen(request: ScreenUnderstandingRequest) async throws -> ScreenUnderstandingResult {
        // Enforce prompt requesting strict classification
        let base64Image = request.imageData.base64EncodedString()
        let prompt = """
        Analyze this screenshot. Output strict JSON with keys:
        - "category": one of ["coding", "gaming", "video", "readingBrowsing", "creativeWork", "generalDesktop", "unknown"]
        - "summary": a brief 1-sentence description (under 100 characters)
        - "confidence": number from 0.0 to 1.0
        """
        
        let payload: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "images": [base64Image],
            "stream": false,
            "format": "json"
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            throw ScreenAwarenessError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = httpBody
        urlRequest.timeoutInterval = 15.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw ScreenAwarenessError.localEndpointUnavailable("HTTP status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            }
            
            // Parse Ollama response wrapper
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let responseText = json["response"] as? String,
                  let responseData = responseText.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
                // If model returned plain text or unparseable JSON
                return ScreenUnderstandingResult(
                    category: .generalDesktop,
                    summary: "Active desktop session",
                    confidence: 0.5,
                    providerName: providerName
                )
            }
            
            let catStr = (parsed["category"] as? String) ?? "unknown"
            let category = VisualActivityCategory(rawValue: catStr) ?? .unknown
            let summary = (parsed["summary"] as? String) ?? "Observing screen content"
            let confidence = (parsed["confidence"] as? Double) ?? 0.75
            
            return ScreenUnderstandingResult(
                category: category,
                summary: summary,
                confidence: confidence,
                timestamp: request.timestamp,
                providerName: providerName,
                isSuitableForDialogue: confidence >= 0.5
            )
        } catch {
            throw ScreenAwarenessError.localEndpointUnavailable(error.localizedDescription)
        }
    }
}

// MARK: - Cloud Vision Provider
public class CloudVisionProvider: ScreenUnderstandingProvider {
    public let providerName = "Cloud Vision API"
    public let isLocal = false
    public var apiKey: String = ""
    public var endpoint: URL = URL(string: "https://api.openai.com/v1/chat/completions")!
    public var consentGiven: Bool = false
    
    public init() {}
    
    public func analyzeScreen(request: ScreenUnderstandingRequest) async throws -> ScreenUnderstandingResult {
        // Enforce explicit user consent before any image data leaves the device
        guard consentGiven else {
            throw ScreenAwarenessError.cloudConsentRequired
        }
        
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ScreenAwarenessError.apiKeyMissing
        }
        
        let base64Image = request.imageData.base64EncodedString()
        let prompt = """
        Analyze this desktop image and respond strictly in JSON:
        {"category": "coding"|"gaming"|"video"|"readingBrowsing"|"creativeWork"|"generalDesktop"|"unknown", "summary": "1 sentence description", "confidence": 0.0-1.0}
        """
        
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                ]
            ]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 150,
            "response_format": ["type": "json_object"]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            throw ScreenAwarenessError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = httpBody
        urlRequest.timeoutInterval = 20.0
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ScreenAwarenessError.invalidResponse
        }
        
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = root["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            throw ScreenAwarenessError.invalidResponse
        }
        
        let catStr = (parsed["category"] as? String) ?? "unknown"
        let category = VisualActivityCategory(rawValue: catStr) ?? .unknown
        let summary = (parsed["summary"] as? String) ?? "Observing screen content"
        let confidence = (parsed["confidence"] as? Double) ?? 0.85
        
        return ScreenUnderstandingResult(
            category: category,
            summary: summary,
            confidence: confidence,
            timestamp: request.timestamp,
            providerName: providerName,
            isSuitableForDialogue: confidence >= 0.5
        )
    }
}

// MARK: - Mock Vision Provider (For Testing & Verification)
public class MockVisionProvider: ScreenUnderstandingProvider {
    public let providerName: String
    public let isLocal: Bool
    public var resultToReturn: ScreenUnderstandingResult
    public var shouldThrowError: ScreenAwarenessError? = nil
    
    public init(
        providerName: String = "Mock Vision Provider",
        isLocal: Bool = true,
        result: ScreenUnderstandingResult = ScreenUnderstandingResult(
            category: .coding,
            summary: "Active Swift programming session",
            confidence: 0.95
        )
    ) {
        self.providerName = providerName
        self.isLocal = isLocal
        self.resultToReturn = result
    }
    
    public func analyzeScreen(request: ScreenUnderstandingRequest) async throws -> ScreenUnderstandingResult {
        if let err = shouldThrowError {
            throw err
        }
        return resultToReturn
    }
}

// MARK: - Visual Observation Receiver Protocol
public protocol VisualObservationReceiver: AnyObject {
    var characterName: String { get }
    var personalityName: String { get }
    func handleVisualObservation(_ result: ScreenUnderstandingResult)
}

// MARK: - Dedicated Screen Awareness Service
public class ScreenAwarenessService: ObservableObject {
    public static let shared = ScreenAwarenessService()
    
    // Core Configuration
    @Published public var isEnabled: Bool = false
    @Published public private(set) var isObserving: Bool = false
    @Published public private(set) var statusMessage: String = "Idle"
    @Published public private(set) var lastResult: ScreenUnderstandingResult? = nil
    
    // Periodic Observation
    @Published public var periodicObservationEnabled: Bool = false {
        didSet {
            if periodicObservationEnabled && isEnabled {
                startPeriodicTimer()
            } else {
                stopPeriodicTimer()
            }
        }
    }
    @Published public var observationInterval: TimeInterval = 300.0 // Minimum 300s = 5 min
    
    // Processing Mode & Privacy
    @Published public var processingMode: VisionProcessingMode = .local
    @Published public var cloudConsentGiven: Bool = false
    @Published public var selectedSourceType: CaptureSourceType = .mainDisplay
    @Published public var excludedBundleIds: Set<String> = [
        "com.apple.keychainaccess",
        "com.agilebits.onepassword",
        "com.1password.1password"
    ]
    
    // Providers
    public var localProvider = LocalVisionProvider()
    public var cloudProvider = CloudVisionProvider()
    public var customProvider: ScreenUnderstandingProvider? = nil
    
    // Injectable capture function for mock testing
    public var captureHandler: (() async throws -> CGImage)? = nil
    
    private var periodicTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var isCancelled = false
    
    public init() {}
    
    deinit {
        stopPeriodicTimer()
    }
    
    // MARK: - Permission Verification
    
    public func permissionState() -> ScreenCapturePermissionState {
        if CGPreflightScreenCaptureAccess() {
            return .authorized
        }
        return .denied
    }
    
    public func requestPermission() -> Bool {
        return CGRequestScreenCaptureAccess()
    }
    
    // MARK: - Still-Image Capture
    
    public func captureStillImage() async throws -> CGImage {
        // 1. Verify Permission
        guard permissionState() == .authorized || captureHandler != nil else {
            throw ScreenAwarenessError.permissionDenied
        }
        
        // 2. Check Excluded Applications
        let activeApp = NSWorkspace.shared.frontmostApplication
        if let bundleId = activeApp?.bundleIdentifier, excludedBundleIds.contains(bundleId) {
            throw ScreenAwarenessError.activeAppExcluded(bundleId: bundleId)
        }
        
        // 3. Custom capture handler (used in mock/unit tests)
        if let customHandler = captureHandler {
            return try await customHandler()
        }
        
        // 4. Native ScreenCaptureKit capture (macOS 14+)
        #if canImport(ScreenCaptureKit)
        if #available(macOS 14.0, *) {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else {
                throw ScreenAwarenessError.noDisplayAvailable
            }
            
            let ownBundleId = Bundle.main.bundleIdentifier ?? "com.dev.Animatto"
            let ownPID = ProcessInfo.processInfo.processIdentifier
            let excludedWindows = content.windows.filter { window in
                window.owningApplication?.processID == ownPID ||
                window.owningApplication?.bundleIdentifier == ownBundleId
            }
            
            let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)
            let config = SCStreamConfiguration()
            config.width = 1024
            config.height = 768
            config.showsCursor = false
            
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        }
        #endif
        
        throw ScreenAwarenessError.captureFailed("ScreenCaptureKit unavailable on this platform.")
    }
    
    // MARK: - Analysis Pipeline
    
    @MainActor
    public func observeScreenNow(for receiver: VisualObservationReceiver? = nil) async -> ScreenUnderstandingResult? {
        guard isEnabled else {
            statusMessage = "Screen awareness is disabled."
            return nil
        }
        
        guard !isObserving else {
            statusMessage = "Analysis already in progress."
            return nil
        }
        
        isObserving = true
        isCancelled = false
        statusMessage = "Capturing screen frame..."
        
        do {
            let cgImage = try await captureStillImage()
            guard !isCancelled else { throw ScreenAwarenessError.inFlightCancelled }
            
            // Downscale to lightweight memory buffer (max 1024x1024)
            guard let imageData = downscaleImage(cgImage: cgImage, maxDimension: 1024) else {
                throw ScreenAwarenessError.captureFailed("Image downscaling failed.")
            }
            
            statusMessage = "Analyzing visual context..."
            
            // Route to selected provider
            let provider: ScreenUnderstandingProvider
            if let custom = customProvider {
                provider = custom
            } else {
                switch processingMode {
                case .local:
                    provider = localProvider
                case .cloud:
                    cloudProvider.consentGiven = cloudConsentGiven
                    provider = cloudProvider
                }
            }
            
            let activeApp = NSWorkspace.shared.frontmostApplication
            let request = ScreenUnderstandingRequest(
                imageData: imageData,
                activeAppName: activeApp?.localizedName,
                activeAppBundleId: activeApp?.bundleIdentifier,
                characterName: receiver?.characterName ?? "Companion",
                personalitySummary: receiver?.personalityName ?? "Curious"
            )
            
            let result = try await provider.analyzeScreen(request: request)
            guard !isCancelled else { throw ScreenAwarenessError.inFlightCancelled }
            
            self.lastResult = result
            self.statusMessage = "Observed: \(result.category.displayName) (\(Int(result.confidence * 100))%)"
            self.isObserving = false
            
            // Pass validated result to character's dialogue system if appropriate
            if let receiver = receiver, result.isSuitableForDialogue {
                receiver.handleVisualObservation(result)
            }
            
            return result
        } catch {
            self.isObserving = false
            self.statusMessage = "Error: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Periodic Timer
    
    public func startPeriodicTimer() {
        stopPeriodicTimer()
        let interval = max(observationInterval, 300.0) // Minimum 5 minutes
        periodicTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, self.isEnabled, self.periodicObservationEnabled else { return }
            Task { @MainActor in
                _ = await self.observeScreenNow()
            }
        }
    }
    
    public func stopPeriodicTimer() {
        periodicTimer?.invalidate()
        periodicTimer = nil
    }
    
    public func stopPeriodicObservation() {
        periodicObservationEnabled = false
        stopPeriodicTimer()
        cancelInFlight()
    }
    
    public func startPeriodicObservation(companionProvider: (() -> VisualObservationReceiver?)? = nil) {
        periodicObservationEnabled = true
        startPeriodicTimer()
    }
    
    // MARK: - In-Flight Control & Privacy
    
    public func cancelInFlight() {
        isCancelled = true
        isObserving = false
        statusMessage = "Analysis cancelled."
    }
    
    public func clearHistory() {
        lastResult = nil
        statusMessage = "Analysis data cleared."
    }
    
    // MARK: - Lightweight In-Memory Downscaling
    
    public func downscaleImage(cgImage: CGImage, maxDimension: CGFloat = 1024) -> Data? {
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let scale = min(maxDimension / max(width, height), 1.0)
        
        let targetWidth = Int(width * scale)
        let targetHeight = Int(height * scale)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: targetWidth * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        
        guard let resized = context.makeImage() else { return nil }
        let bitmapRep = NSBitmapImageRep(cgImage: resized)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.75])
    }
}
