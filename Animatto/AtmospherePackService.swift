import Foundation
import Combine

// MARK: - Community Atmosphere Pack Model
public struct AtmospherePack: Codable, Identifiable, Equatable {
    public var id: String { packId }
    public var schemaVersion: Int
    public var packId: String
    public var name: String
    public var author: String
    public var sourceURL: String?
    public var license: String
    public var description: String
    public var presets: [AtmospherePreset]
    
    public init(
        schemaVersion: Int = 1,
        packId: String,
        name: String,
        author: String,
        sourceURL: String? = nil,
        license: String = "CC-BY-4.0",
        description: String = "",
        presets: [AtmospherePreset] = []
    ) {
        self.schemaVersion = schemaVersion
        self.packId = packId
        self.name = name
        self.author = author
        self.sourceURL = sourceURL
        self.license = license
        self.description = description
        self.presets = presets
    }
}

// MARK: - Atmosphere Pack Service
public class AtmospherePackService: ObservableObject {
    public static let shared = AtmospherePackService()
    
    @Published public private(set) var installedPacks: [AtmospherePack] = []
    
    public static let maxPackSizeBytes: Int = 10 * 1024 * 1024 // 10MB safety bound
    private let installedPacksKey = "com.dev.Animatto.installed_atmosphere_packs"
    
    public init() {
        loadInstalledPacks()
    }
    
    // MARK: - Export
    
    public func exportPackJSON(_ pack: AtmospherePack) -> Result<Data, Error> {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(pack)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Import Validation & Security
    
    public enum PackImportError: LocalizedError, Equatable {
        case fileTooLarge
        case invalidJSON
        case securityViolation(String)
        case unsupportedSchema(Int)
        case emptyPresets
        
        public var errorDescription: String? {
            switch self {
            case .fileTooLarge:
                return "Pack exceeds 10MB safety limit."
            case .invalidJSON:
                return "File is not valid JSON."
            case .securityViolation(let reason):
                return "Security check failed: \(reason)"
            case .unsupportedSchema(let v):
                return "Unsupported pack schema version (\(v))."
            case .emptyPresets:
                return "Pack does not contain any atmosphere presets."
            }
        }
    }
    
    public func importPack(from data: Data) -> Result<AtmospherePack, PackImportError> {
        // 1. File size bound check
        guard data.count <= AtmospherePackService.maxPackSizeBytes else {
            return .failure(.fileTooLarge)
        }
        
        // 2. JSON Structure & Forbidden Key Scanning
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .failure(.invalidJSON)
        }
        
        let forbidden = ["script", "executable", "shell", "command", "bash", "apiKey", "password", "memories", "screenshot"]
        for key in forbidden {
            if jsonObject[key] != nil {
                return .failure(.securityViolation("Forbidden key '\(key)' detected in pack."))
            }
        }
        
        // 3. Decode
        do {
            let decoder = JSONDecoder()
            let pack = try decoder.decode(AtmospherePack.self, from: data)
            
            guard pack.schemaVersion == 1 else {
                return .failure(.unsupportedSchema(pack.schemaVersion))
            }
            
            guard !pack.presets.isEmpty else {
                return .failure(.emptyPresets)
            }
            
            // Sanitize presets
            var sanitizedPresets: [AtmospherePreset] = []
            for p in pack.presets {
                var clean = p
                clean.intensity = min(max(clean.intensity, 0.1), 1.0)
                clean.windStrength = min(max(clean.windStrength, -1.0), 1.0)
                clean.isBuiltIn = false
                sanitizedPresets.append(clean)
            }
            
            var validatedPack = pack
            validatedPack.presets = sanitizedPresets
            
            installPack(validatedPack)
            return .success(validatedPack)
        } catch {
            return .failure(.invalidJSON)
        }
    }
    
    public func installPack(_ pack: AtmospherePack) {
        installedPacks.removeAll { $0.packId == pack.packId }
        installedPacks.append(pack)
        
        // Register presets into AmbientEngine
        for p in pack.presets {
            AmbientEngine.shared.customPresets.removeAll { $0.presetKey == p.presetKey }
            AmbientEngine.shared.customPresets.append(p)
        }
        
        saveInstalledPacks()
    }
    
    public func removePack(packId: String) {
        if let pack = installedPacks.first(where: { $0.packId == packId }) {
            for p in pack.presets {
                AmbientEngine.shared.deleteCustomPreset(presetKey: p.presetKey)
            }
        }
        installedPacks.removeAll { $0.packId == packId }
        saveInstalledPacks()
    }
    
    // MARK: - Persistence
    
    public var storageDirectoryURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let animattoDir = appSupport.appendingPathComponent("Animatto", isDirectory: true)
        let packsDir = animattoDir.appendingPathComponent("AtmospherePacks", isDirectory: true)
        try? FileManager.default.createDirectory(at: packsDir, withIntermediateDirectories: true)
        return packsDir
    }
    
    private var indexFileURL: URL {
        return storageDirectoryURL.appendingPathComponent("installed_packs.json")
    }
    
    private func saveInstalledPacks() {
        if let data = try? JSONEncoder().encode(installedPacks) {
            try? data.write(to: indexFileURL, options: .atomic)
        }
    }
    
    public func registerPresetsIntoEngine() {
        for pack in installedPacks {
            for p in pack.presets {
                AmbientEngine.shared.customPresets.removeAll { $0.presetKey == p.presetKey }
                AmbientEngine.shared.customPresets.append(p)
            }
        }
    }
    
    private func loadInstalledPacks() {
        // 1. Load from filesystem in Application Support
        if let data = try? Data(contentsOf: indexFileURL),
           let list = try? JSONDecoder().decode([AtmospherePack].self, from: data) {
            self.installedPacks = list
            registerPresetsIntoEngine()
            UserDefaults.standard.removeObject(forKey: installedPacksKey)
            return
        }
        
        // 2. Migration from legacy UserDefaults storage
        if let legacyData = UserDefaults.standard.data(forKey: installedPacksKey),
           let list = try? JSONDecoder().decode([AtmospherePack].self, from: legacyData) {
            self.installedPacks = list
            registerPresetsIntoEngine()
            saveInstalledPacks()
            UserDefaults.standard.removeObject(forKey: installedPacksKey)
        }
    }
}
