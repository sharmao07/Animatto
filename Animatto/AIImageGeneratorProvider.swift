//
//  AIImageGeneratorProvider.swift
//  Animatto
//
//  Created for Animatto Workshop & Creator Studio.
//  Modular image generation provider abstraction and Pollinations AI integration.
//

import Foundation
import AppKit

// MARK: - Aesthetic Style
public enum AnimattoAestheticStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case pixelArt = "Pixel Art"
    case chibi = "Chibi Companion"
    case animeSprite = "Anime Sprite"
    case retroMascot = "Retro Desktop Mascot"
    case cleanCustom = "Custom (Direct Prompt)"
    
    public var id: String { rawValue }
    
    public var promptSuffix: String {
        switch self {
        case .pixelArt:
            return ", 16-bit pixel art desktop companion sprite, clean silhouette, isolated white background, crisp pixel edges"
        case .chibi:
            return ", chibi anime companion character, cute proportions, clear standing pose, clean isolated white background"
        case .animeSprite:
            return ", 2D anime character sprite, front-facing standing pose, sharp cel-shaded outlines, isolated plain background"
        case .retroMascot:
            return ", retro 90s desktop mascot character, playful personality, bold vector outline, isolated white background"
        case .cleanCustom:
            return ""
        }
    }
}

// MARK: - AI Image Model Definition
public struct AIImageModel: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let displayName: String
    public let isPaidOnly: Bool
    public let modelDescription: String
    public let category: String
    
    public init(
        id: String,
        displayName: String,
        isPaidOnly: Bool,
        modelDescription: String,
        category: String = "image"
    ) {
        self.id = id
        self.displayName = displayName
        self.isPaidOnly = isPaidOnly
        self.modelDescription = modelDescription
        self.category = category
    }
}

// MARK: - Generation Request
public struct AIImageGenerationRequest: Sendable {
    public let prompt: String
    public let aestheticStyle: AnimattoAestheticStyle
    public let modelId: String
    public let width: Int
    public let height: Int
    public let seed: Int?
    public let apiKey: String?
    public let timeout: TimeInterval
    
    public init(
        prompt: String,
        aestheticStyle: AnimattoAestheticStyle = .pixelArt,
        modelId: String = "flux",
        width: Int = 1024,
        height: Int = 1024,
        seed: Int? = nil,
        apiKey: String? = nil,
        timeout: TimeInterval = 60.0
    ) {
        self.prompt = prompt
        self.aestheticStyle = aestheticStyle
        self.modelId = modelId
        self.width = width
        self.height = height
        self.seed = seed
        self.apiKey = apiKey
        self.timeout = timeout
    }
    
    public var fullPrompt: String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed + aestheticStyle.promptSuffix
    }
}

// MARK: - Provider Protocol
public protocol ImageGenerationProvider: Sendable {
    var providerId: String { get }
    var displayName: String { get }
    var requiresAuthentication: Bool { get }
    var supportedModels: [AIImageModel] { get }
    
    func generateImage(request: AIImageGenerationRequest) async throws -> (image: NSImage, rawData: Data)
    func fetchAvailableModels() async throws -> [AIImageModel]
}

// MARK: - Pollinations AI Provider Implementation
public class PollinationsImageProvider: ImageGenerationProvider, @unchecked Sendable {
    public let providerId: String = "pollinations"
    public let displayName: String = "Pollinations AI"
    public let requiresAuthentication: Bool = true // Pollinations now requires an account API key
    
    public var session: URLSession
    public var baseURL: URL
    
    public static let defaultModels: [AIImageModel] = [
        AIImageModel(
            id: "flux",
            displayName: "FLUX (Standard)",
            isPaidOnly: false,
            modelDescription: "Balanced text-to-image diffusion model for character concepts and sprites."
        ),
        AIImageModel(
            id: "tongyi-mai/z-image-turbo",
            displayName: "Z-Image Turbo",
            isPaidOnly: false,
            modelDescription: "Instant, budget-friendly images with crisp upscaled output."
        ),
        AIImageModel(
            id: "community/MarcosFRG/sdxl-lightning",
            displayName: "SDXL Lightning",
            isPaidOnly: false,
            modelDescription: "Distilled fast text-to-image engine for responsive visuals."
        ),
        AIImageModel(
            id: "black-forest-labs/flux.1.1-pro",
            displayName: "FLUX 1.1 Pro",
            isPaidOnly: false,
            modelDescription: "High-precision text-to-image generation with strong prompt adherence."
        )
    ]
    
    public var supportedModels: [AIImageModel] {
        Self.defaultModels
    }
    
    public init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://gen.pollinations.ai")!
    ) {
        self.session = session
        self.baseURL = baseURL
    }
    
    public func fetchAvailableModels() async throws -> [AIImageModel] {
        let modelsURL = baseURL.appendingPathComponent("v1/models")
        var request = URLRequest(url: modelsURL)
        request.timeoutInterval = 10.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return Self.defaultModels
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]] else {
            return Self.defaultModels
        }
        
        var models: [AIImageModel] = []
        for item in dataArray {
            let cat = item["category"] as? String ?? ""
            let outMods = item["output_modalities"] as? [String] ?? []
            if cat == "image" || outMods.contains("image") {
                if let id = item["id"] as? String,
                   let title = item["title"] as? String {
                    let paid = item["paid_only"] as? Bool ?? false
                    let desc = item["description"] as? String ?? ""
                    models.append(AIImageModel(id: id, displayName: title, isPaidOnly: paid, modelDescription: desc, category: cat))
                }
            }
        }
        
        return models.isEmpty ? Self.defaultModels : models
    }
    
    public func generateImage(request: AIImageGenerationRequest) async throws -> (image: NSImage, rawData: Data) {
        let fullPrompt = request.fullPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fullPrompt.isEmpty else {
            throw WorkshopError.invalidURL
        }
        
        guard let encodedPrompt = fullPrompt.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw WorkshopError.invalidURL
        }
        
        // Build generation URL: https://gen.pollinations.ai/image/{prompt}?...
        var components = URLComponents(url: baseURL.appendingPathComponent("image/\(encodedPrompt)"), resolvingAgainstBaseURL: true)
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "model", value: request.modelId),
            URLQueryItem(name: "width", value: "\(request.width)"),
            URLQueryItem(name: "height", value: "\(request.height)"),
            URLQueryItem(name: "nologo", value: "true")
        ]
        
        if let seed = request.seed {
            queryItems.append(URLQueryItem(name: "seed", value: "\(seed)"))
        }
        
        // If API key is provided, pass via query parameter and authorization header
        if let key = request.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty {
            queryItems.append(URLQueryItem(name: "key", value: key))
        }
        
        components?.queryItems = queryItems
        guard let requestURL = components?.url else {
            throw WorkshopError.invalidURL
        }
        
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.timeoutInterval = request.timeout
        urlRequest.setValue("image/png, image/jpeg, image/webp, image/*", forHTTPHeaderField: "Accept")
        urlRequest.setValue("Animatto-Desktop-App/1.1", forHTTPHeaderField: "User-Agent")
        
        if let key = request.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty {
            urlRequest.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WorkshopError.malformedResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 400:
            throw WorkshopError.networkError("Invalid prompt syntax or unsupported generation parameters (HTTP 400).")
        case 401:
            throw WorkshopError.networkError("Authentication required (HTTP 401). Pollinations now requires an account API key. Please obtain a free key at https://enter.pollinations.ai and configure it in Generator Settings.")
        case 402:
            var message = "Payment required / Insufficient Pollen balance (HTTP 402)"
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errObj = json["error"] as? [String: Any],
               let errMsg = errObj["message"] as? String {
                message = errMsg
            }
            throw WorkshopError.networkError("\(message). Check your balance or complete Quests for free credits at enter.pollinations.ai.")
        case 403:
            throw WorkshopError.networkError("Access to model '\(request.modelId)' is forbidden (HTTP 403). It may be restricted to paid accounts.")
        case 404:
            throw WorkshopError.networkError("Model '\(request.modelId)' not found on Pollinations server (HTTP 404).")
        case 429:
            throw WorkshopError.networkError("Rate limit reached (HTTP 429). Please wait a moment before sending another generation request.")
        case 500...599:
            throw WorkshopError.networkError("Image generation service error (HTTP \(httpResponse.statusCode)). Please retry shortly.")
        default:
            throw WorkshopError.serverRejected(code: httpResponse.statusCode)
        }
        
        // Verify response size
        guard data.count > 512 else {
            throw WorkshopError.malformedResponse
        }
        
        // Verify image format via magic bytes
        let (_, format) = try WorkshopImportValidator.validate(data: data, suggestedName: "ai_character")
        guard format == .png || format == .jpeg || format == .webp else {
            throw WorkshopError.unsupportedMediaFormat
        }
        
        guard let image = NSImage(data: data) else {
            throw WorkshopError.malformedResponse
        }
        
        return (image, data)
    }
}

// MARK: - Mock Image Provider (For Deterministic Testing & Offline Verification)
public class MockImageGenerationProvider: ImageGenerationProvider, @unchecked Sendable {
    public let providerId: String = "mock"
    public let displayName: String = "Mock Test Generator"
    public let requiresAuthentication: Bool = false
    
    public var shouldSucceed: Bool = true
    public var simulatedError: Error?
    public var simulatedDelay: TimeInterval = 0.05
    public var lastRequest: AIImageGenerationRequest?
    
    public var supportedModels: [AIImageModel] = [
        AIImageModel(id: "mock-pixel", displayName: "Mock Pixel Engine", isPaidOnly: false, modelDescription: "Offline deterministic test model."),
        AIImageModel(id: "mock-chibi", displayName: "Mock Chibi Engine", isPaidOnly: false, modelDescription: "Offline test model.")
    ]
    
    public init() {}
    
    public func fetchAvailableModels() async throws -> [AIImageModel] {
        return supportedModels
    }
    
    public func generateImage(request: AIImageGenerationRequest) async throws -> (image: NSImage, rawData: Data) {
        lastRequest = request
        
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        if let err = simulatedError {
            throw err
        }
        
        guard shouldSucceed else {
            throw WorkshopError.networkError("Mock generation simulated failure.")
        }
        
        let trimmed = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw WorkshopError.invalidURL
        }
        
        // Generate a synthetic valid 64x64 PNG sprite for testing
        let size = NSSize(width: 64, height: 64)
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Draw background box and character circle
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        NSColor.systemIndigo.setFill()
        let oval = NSBezierPath(ovalIn: NSRect(x: 12, y: 12, width: 40, height: 40))
        oval.fill()
        
        image.unlockFocus()
        
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let pngData = rep.representation(using: .png, properties: [:]) else {
            throw WorkshopError.malformedResponse
        }
        
        return (image, pngData)
    }
}
