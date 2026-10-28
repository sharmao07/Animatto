import Foundation
import Combine
import Darwin

// MARK: - Personality Storage Model
public struct PersonalityStorageContainer: Codable {
    public var schemaVersion: Int
    public var profiles: [String: PersonalityProfile] // Keyed by character ID
    public var fileToIdMap: [String: String]           // Keyed by filename
    
    public init(schemaVersion: Int = 1, profiles: [String: PersonalityProfile] = [:], fileToIdMap: [String: String] = [:]) {
        self.schemaVersion = schemaVersion
        self.profiles = profiles
        self.fileToIdMap = fileToIdMap
    }
}

// MARK: - Personality Storage Manager
public class PersonalityStorage: ObservableObject {
    public static let shared = PersonalityStorage()
    
    private let storageURL: URL
    private let xattrKey = "com.animatto.characterId"
    
    @Published public private(set) var profiles: [String: PersonalityProfile] = [:]
    private var fileToIdMap: [String: String] = [:]
    private let lock = NSLock()
    
    public init() {
        let storageDir = PetStorage.getStorageDirectory()
        self.storageURL = storageDir.appendingPathComponent("character_profiles.json")
        load()
    }
    
    // MARK: - Persistence
    
    public func load() {
        lock.lock()
        defer { lock.unlock() }
        
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            let container = try decoder.decode(PersonalityStorageContainer.self, from: data)
            self.profiles = container.profiles
            self.fileToIdMap = container.fileToIdMap
        } catch {
            print("Failed to decode personality profiles: \(error.localizedDescription). Initializing clean storage.")
        }
    }
    
    public func save() {
        lock.lock()
        defer { lock.unlock() }
        
        do {
            let container = PersonalityStorageContainer(
                schemaVersion: 1,
                profiles: self.profiles,
                fileToIdMap: self.fileToIdMap
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(container)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to save personality profiles: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Stable Character Identity Resolution
    
    public func characterId(for url: URL) -> String {
        lock.lock()
        defer { lock.unlock() }
        
        // 1. Try reading extended attribute on the file
        if let xattrId = readXattr(key: xattrKey, from: url.path), !xattrId.isEmpty {
            fileToIdMap[url.lastPathComponent] = xattrId
            return xattrId
        }
        
        // 2. Try looking up filename in registry map
        if let mappedId = fileToIdMap[url.lastPathComponent], !mappedId.isEmpty {
            writeXattr(key: xattrKey, value: mappedId, to: url.path)
            return mappedId
        }
        
        // 3. Generate a new stable character ID
        let newId = UUID().uuidString
        fileToIdMap[url.lastPathComponent] = newId
        writeXattr(key: xattrKey, value: newId, to: url.path)
        return newId
    }
    
    // MARK: - Profile Retrieval & Saving
    
    public func getProfile(for url: URL) -> PersonalityProfile {
        let id = characterId(for: url)
        
        lock.lock()
        if let existing = profiles[id] {
            lock.unlock()
            return existing
        }
        lock.unlock()
        
        // Determine intelligent default preset from filename if applicable
        let nameLower = url.deletingPathExtension().lastPathComponent.lowercased()
        let defaultPreset: PersonalityPreset
        if nameLower.contains("sleep") || nameLower.contains("lazy") || nameLower.contains("nap") {
            defaultPreset = .sleepy
        } else if nameLower.contains("run") || nameLower.contains("fast") || nameLower.contains("zoom") || nameLower.contains("sonic") {
            defaultPreset = .energetic
        } else if nameLower.contains("mischief") || nameLower.contains("devil") || nameLower.contains("chaos") {
            defaultPreset = .mischievous
        } else if nameLower.contains("shy") || nameLower.contains("quiet") || nameLower.contains("hide") {
            defaultPreset = .shy
        } else if nameLower.contains("curious") || nameLower.contains("look") || nameLower.contains("detective") {
            defaultPreset = .curious
        } else {
            defaultPreset = .balanced
        }
        
        var profile = PersonalityProfile.preset(defaultPreset)
        profile.name = url.deletingPathExtension().lastPathComponent
        
        lock.lock()
        profiles[id] = profile
        lock.unlock()
        
        save()
        return profile
    }
    
    public func saveProfile(_ profile: PersonalityProfile, for url: URL) {
        let id = characterId(for: url)
        
        lock.lock()
        profiles[id] = profile.clamped()
        lock.unlock()
        
        save()
    }
    
    public func handleFileRenamed(from oldURL: URL, to newURL: URL) {
        lock.lock()
        if let id = fileToIdMap.removeValue(forKey: oldURL.lastPathComponent) {
            fileToIdMap[newURL.lastPathComponent] = id
            // Re-apply xattr to ensure it matches
            writeXattr(key: xattrKey, value: id, to: newURL.path)
        }
        lock.unlock()
        
        save()
    }
    
    // MARK: - Native Extended Attribute Helpers (APFS / HFS+)
    
    private func readXattr(key: String, from path: String) -> String? {
        let length = getxattr(path, key, nil, 0, 0, 0)
        guard length > 0 else { return nil }
        
        var buffer = [CChar](repeating: 0, count: length + 1)
        let bytesRead = getxattr(path, key, &buffer, length, 0, 0)
        guard bytesRead > 0 else { return nil }
        
        return String(cString: buffer)
    }
    
    private func writeXattr(key: String, value: String, to path: String) {
        value.withCString { cStr in
            _ = setxattr(path, key, cStr, strlen(cStr), 0, 0)
        }
    }
}
