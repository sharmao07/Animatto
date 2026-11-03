import Foundation

// MARK: - Animation Canvas Size
public struct AnimationCanvasSize: Codable, Sendable, Equatable {
    public let width: Int
    public let height: Int
    
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

// MARK: - Animation State Config
public struct AnimationStateConfig: Codable, Sendable, Equatable {
    public let folder: String
    public let frameCount: Int
    public let frameDurationMs: Int
    public let loop: Bool
    public let footstepFrames: [Int]?
    public let nextState: String?
    
    public var frameDuration: TimeInterval {
        Double(frameDurationMs) / 1000.0
    }
    
    public init(
        folder: String,
        frameCount: Int,
        frameDurationMs: Int,
        loop: Bool,
        footstepFrames: [Int]? = nil,
        nextState: String? = nil
    ) {
        self.folder = folder
        self.frameCount = frameCount
        self.frameDurationMs = frameDurationMs
        self.loop = loop
        self.footstepFrames = footstepFrames
        self.nextState = nextState
    }
}

// MARK: - Animation Manifest
public struct AnimationManifest: Codable, Sendable, Equatable {
    public let characterId: String
    public let version: String
    public let name: String
    public let masterArtwork: String?
    public let canvasSize: AnimationCanvasSize
    public let groundBaselineY: Int
    public let states: [String: AnimationStateConfig]
    
    public init(
        characterId: String,
        version: String,
        name: String,
        masterArtwork: String? = nil,
        canvasSize: AnimationCanvasSize,
        groundBaselineY: Int = 32,
        states: [String: AnimationStateConfig]
    ) {
        self.characterId = characterId
        self.version = version
        self.name = name
        self.masterArtwork = masterArtwork
        self.canvasSize = canvasSize
        self.groundBaselineY = groundBaselineY
        self.states = states
    }
    
    public static func load(from directoryOrManifestURL: URL) throws -> AnimationManifest {
        var isDir: ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: directoryOrManifestURL.path, isDirectory: &isDir)
        guard fileExists else {
            throw AnimationAssetError.directoryNotFound(directoryOrManifestURL)
        }
        
        let manifestURL: URL
        if isDir.boolValue {
            manifestURL = directoryOrManifestURL.appendingPathComponent("manifest.json")
        } else if directoryOrManifestURL.lastPathComponent == "manifest.json" {
            manifestURL = directoryOrManifestURL
        } else {
            manifestURL = directoryOrManifestURL.deletingLastPathComponent().appendingPathComponent("manifest.json")
        }
        
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw AnimationAssetError.manifestNotFound(manifestURL)
        }
        
        do {
            let data = try Data(contentsOf: manifestURL)
            let decoder = JSONDecoder()
            return try decoder.decode(AnimationManifest.self, from: data)
        } catch let err as DecodingError {
            throw AnimationAssetError.manifestInvalid(err.localizedDescription)
        } catch {
            throw AnimationAssetError.manifestInvalid(error.localizedDescription)
        }
    }
}

// MARK: - Animation Asset Errors
public enum AnimationAssetError: LocalizedError, Equatable {
    case directoryNotFound(URL)
    case manifestNotFound(URL)
    case manifestInvalid(String)
    case stateNotFound(String)
    case frameIndexOutOfBounds(state: String, index: Int, total: Int)
    case frameFileNotFound(URL)
    case frameDecodingFailed(URL)
    case cacheEvicted
    
    public var errorDescription: String? {
        switch self {
        case .directoryNotFound(let url):
            return "Animation directory not found at: \(url.path)"
        case .manifestNotFound(let url):
            return "Animation manifest.json not found at: \(url.path)"
        case .manifestInvalid(let reason):
            return "Animation manifest.json is invalid: \(reason)"
        case .stateNotFound(let state):
            return "Animation state '\(state)' not defined in manifest."
        case .frameIndexOutOfBounds(let state, let index, let total):
            return "Frame index \(index) out of bounds for state '\(state)' (total \(total))."
        case .frameFileNotFound(let url):
            return "Sprite frame file not found at: \(url.path)"
        case .frameDecodingFailed(let url):
            return "Failed to decode CGImage from frame file at: \(url.path)"
        case .cacheEvicted:
            return "Requested animation frame was evicted from cache."
        }
    }
}
