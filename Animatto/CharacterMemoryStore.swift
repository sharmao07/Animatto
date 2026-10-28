import Foundation
import Combine

// MARK: - Memory Category
public enum MemoryCategory: String, Codable, CaseIterable {
    case shortTermInteraction   // Transient interaction history (auto-expires)
    case durableSocial          // Meaningful social interactions between companions
    case userConfirmedPreference// Explicitly confirmed user preference or note
    case interactionPattern     // Derived interaction patterns (e.g. frequent companion)
    
    public var displayName: String {
        switch self {
        case .shortTermInteraction: return "Recent Interaction"
        case .durableSocial: return "Social Memory"
        case .userConfirmedPreference: return "Confirmed Preference"
        case .interactionPattern: return "Interaction Pattern"
        }
    }
}

// MARK: - Memory Event Type
public enum MemoryEventType: String, Codable, CaseIterable {
    case socialGreeting
    case socialPlay
    case socialEncounter
    case companionInteraction
    case userNote
    case activityPattern
    
    public var displayName: String {
        switch self {
        case .socialGreeting: return "Greeting"
        case .socialPlay: return "Play Session"
        case .socialEncounter: return "Encounter"
        case .companionInteraction: return "Interaction"
        case .userNote: return "User Note"
        case .activityPattern: return "Activity Pattern"
        }
    }
}

// MARK: - Character Memory Record
public struct CharacterMemoryRecord: Codable, Identifiable, Equatable {
    public let id: UUID
    public let characterId: String               // Stable character identity from PersonalityStorage
    public let category: MemoryCategory
    public let eventType: MemoryEventType
    public var summary: String                   // Concise summary (capped at 200 chars)
    public var partnerCharacterId: String?       // Partner character's stable ID (if applicable)
    public var partnerName: String?              // Partner character's name at time of event
    public let createdAt: Date
    public var updatedAt: Date
    public var expiresAt: Date?                  // Expiration timestamp for transient records
    public var isUserApproved: Bool              // Confirmed vs tentative/inferred
    public var schemaVersion: Int
    public var metadata: [String: String]        // Structured metadata (e.g. interactionCount)
    
    public init(
        id: UUID = UUID(),
        characterId: String,
        category: MemoryCategory,
        eventType: MemoryEventType,
        summary: String,
        partnerCharacterId: String? = nil,
        partnerName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        expiresAt: Date? = nil,
        isUserApproved: Bool = false,
        schemaVersion: Int = 1,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.characterId = characterId
        self.category = category
        self.eventType = eventType
        self.summary = String(summary.prefix(200))
        self.partnerCharacterId = partnerCharacterId
        self.partnerName = partnerName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.expiresAt = expiresAt
        self.isUserApproved = isUserApproved
        self.schemaVersion = schemaVersion
        self.metadata = metadata
    }
    
    public var isExpired: Bool {
        guard let exp = expiresAt else { return false }
        return exp < Date()
    }
}

// MARK: - Memory Storage Container
public struct CharacterMemoryContainer: Codable {
    public var schemaVersion: Int
    public var memories: [String: [CharacterMemoryRecord]] // Keyed by characterId
    public var isMemoryEnabledGlobally: Bool
    public var disabledCharacterIds: Set<String>
    
    public init(
        schemaVersion: Int = 1,
        memories: [String: [CharacterMemoryRecord]] = [:],
        isMemoryEnabledGlobally: Bool = true,
        disabledCharacterIds: Set<String> = []
    ) {
        self.schemaVersion = schemaVersion
        self.memories = memories
        self.isMemoryEnabledGlobally = isMemoryEnabledGlobally
        self.disabledCharacterIds = disabledCharacterIds
    }
}

// MARK: - Character Memory Store
public class CharacterMemoryStore: ObservableObject {
    public static let shared = CharacterMemoryStore()
    
    private let storageURL: URL
    private let lock = NSLock()
    
    // Configurable retention limits
    public var maxTransientRecordsPerCharacter = 20
    public var maxDurableRecordsPerCharacter = 50
    public var transientDefaultLifespan: TimeInterval = 600 // 10 minutes
    
    // Injectable clock for deterministic unit testing
    public var nowProvider: () -> Date = { Date() }
    
    @Published public private(set) var memoriesByCharacter: [String: [CharacterMemoryRecord]] = [:]
    @Published public var isMemoryEnabledGlobally: Bool = true
    @Published public var disabledCharacterIds: Set<String> = []
    
    public init(storageURL: URL? = nil) {
        if let url = storageURL {
            self.storageURL = url
        } else {
            let storageDir = PetStorage.getStorageDirectory()
            self.storageURL = storageDir.appendingPathComponent("character_memories.json")
        }
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
            let container = try decoder.decode(CharacterMemoryContainer.self, from: data)
            self.isMemoryEnabledGlobally = container.isMemoryEnabledGlobally
            self.disabledCharacterIds = container.disabledCharacterIds
            
            // Prune expired records during load
            let now = nowProvider()
            var sanitized: [String: [CharacterMemoryRecord]] = [:]
            for (charId, list) in container.memories {
                let valid = list.filter { record in
                    if let exp = record.expiresAt {
                        return exp >= now
                    }
                    return true
                }
                sanitized[charId] = valid
            }
            self.memoriesByCharacter = sanitized
        } catch {
            print("Failed to decode character memories: \(error.localizedDescription). Initializing safe empty store.")
        }
    }
    
    public func save() {
        lock.lock()
        defer { lock.unlock() }
        
        do {
            let container = CharacterMemoryContainer(
                schemaVersion: 1,
                memories: self.memoriesByCharacter,
                isMemoryEnabledGlobally: self.isMemoryEnabledGlobally,
                disabledCharacterIds: self.disabledCharacterIds
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(container)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to save character memories: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Query & State
    
    public func isMemoryEnabled(for characterId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard isMemoryEnabledGlobally else { return false }
        return !disabledCharacterIds.contains(characterId)
    }
    
    public func setMemoryEnabled(_ enabled: Bool, for characterId: String) {
        lock.lock()
        if enabled {
            disabledCharacterIds.remove(characterId)
        } else {
            disabledCharacterIds.insert(characterId)
        }
        lock.unlock()
        save()
    }
    
    public func memories(for characterId: String) -> [CharacterMemoryRecord] {
        lock.lock()
        defer { lock.unlock() }
        let now = nowProvider()
        return (memoriesByCharacter[characterId] ?? []).filter { record in
            if let exp = record.expiresAt {
                return exp >= now
            }
            return true
        }
    }
    
    public func totalMemoryCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return memoriesByCharacter.values.reduce(0) { $0 + $1.count }
    }
    
    public func memoryCount(for characterId: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return memoriesByCharacter[characterId]?.count ?? 0
    }
    
    // MARK: - Memory Recording Operations
    
    @discardableResult
    public func recordMemory(
        characterId: String,
        category: MemoryCategory,
        eventType: MemoryEventType,
        summary: String,
        partnerCharacterId: String? = nil,
        partnerName: String? = nil,
        expiresIn: TimeInterval? = nil,
        isUserApproved: Bool = false,
        metadata: [String: String] = [:]
    ) -> CharacterMemoryRecord? {
        guard isMemoryEnabled(for: characterId) else { return nil }
        
        let now = nowProvider()
        let expiresAt = expiresIn.map { now.addingTimeInterval($0) }
        
        lock.lock()
        var list = memoriesByCharacter[characterId] ?? []
        
        // Check for deduplication / consolidation of repeated social encounters
        if let partnerId = partnerCharacterId,
           let existingIdx = list.firstIndex(where: {
               $0.eventType == eventType && $0.partnerCharacterId == partnerId
           }) {
            // Update existing record rather than creating unbounded duplicate records
            var existing = list[existingIdx]
            let count = (Int(existing.metadata["interactionCount"] ?? "1") ?? 1) + 1
            var updatedMetadata = metadata
            updatedMetadata["interactionCount"] = String(count)
            existing.updatedAt = now
            existing.expiresAt = expiresAt
            existing.metadata = updatedMetadata
            existing.summary = String(summary.prefix(200))
            if let pName = partnerName { existing.partnerName = pName }
            list[existingIdx] = existing
            memoriesByCharacter[characterId] = list
            lock.unlock()
            save()
            return existing
        }
        
        let newRecord = CharacterMemoryRecord(
            id: UUID(),
            characterId: characterId,
            category: category,
            eventType: eventType,
            summary: summary,
            partnerCharacterId: partnerCharacterId,
            partnerName: partnerName,
            createdAt: now,
            updatedAt: now,
            expiresAt: expiresAt,
            isUserApproved: isUserApproved,
            metadata: metadata
        )
        
        list.append(newRecord)
        
        // Enforce capacity bounds
        let transients = list.filter { $0.category == .shortTermInteraction }
        let durables = list.filter { $0.category != .shortTermInteraction }
        
        var boundedList: [CharacterMemoryRecord] = []
        if transients.count > maxTransientRecordsPerCharacter {
            boundedList.append(contentsOf: transients.suffix(maxTransientRecordsPerCharacter))
        } else {
            boundedList.append(contentsOf: transients)
        }
        
        if durables.count > maxDurableRecordsPerCharacter {
            boundedList.append(contentsOf: durables.suffix(maxDurableRecordsPerCharacter))
        } else {
            boundedList.append(contentsOf: durables)
        }
        
        memoriesByCharacter[characterId] = boundedList
        lock.unlock()
        save()
        return newRecord
    }
    
    // MARK: - Dedicated Social Memory Operations
    
    @discardableResult
    public func recordSocialEncounter(
        characterId: String,
        partnerId: String,
        partnerName: String,
        actionType: String,
        isDurable: Bool = false
    ) -> CharacterMemoryRecord? {
        guard isMemoryEnabled(for: characterId) else { return nil }
        
        let category: MemoryCategory = isDurable ? .durableSocial : .shortTermInteraction
        let eventType: MemoryEventType
        if actionType.contains("play") {
            eventType = .socialPlay
        } else if actionType.contains("greet") {
            eventType = .socialGreeting
        } else {
            eventType = .socialEncounter
        }
        
        let summary: String
        if isDurable {
            summary = "Shared \(actionType) session with \(partnerName)"
        } else {
            summary = "Recently met \(partnerName)"
        }
        
        let lifespan: TimeInterval? = isDurable ? nil : transientDefaultLifespan
        return recordMemory(
            characterId: characterId,
            category: category,
            eventType: eventType,
            summary: summary,
            partnerCharacterId: partnerId,
            partnerName: partnerName,
            expiresIn: lifespan,
            metadata: ["action": actionType]
        )
    }
    
    public func hasRecentInteraction(characterId: String, with partnerId: String, within interval: TimeInterval) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let now = nowProvider()
        let list = memoriesByCharacter[characterId] ?? []
        return list.contains { record in
            guard record.partnerCharacterId == partnerId else { return false }
            return now.timeIntervalSince(record.updatedAt) < interval
        }
    }
    
    public func interactionCount(characterId: String, with partnerId: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let list = memoriesByCharacter[characterId] ?? []
        for record in list where record.partnerCharacterId == partnerId {
            if let countStr = record.metadata["interactionCount"], let count = Int(countStr) {
                return count
            }
            return 1
        }
        return 0
    }
    
    public func recentInteractions(for characterId: String, with partnerId: String? = nil, limit: Int = 5) -> [CharacterMemoryRecord] {
        lock.lock()
        defer { lock.unlock() }
        let now = nowProvider()
        let list = (memoriesByCharacter[characterId] ?? []).filter { record in
            if let exp = record.expiresAt, exp < now { return false }
            if let partner = partnerId { return record.partnerCharacterId == partner }
            return true
        }
        return Array(list.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(limit))
    }
    
    // MARK: - Deletion & Clearing
    
    public func deleteMemory(id: UUID, for characterId: String) {
        lock.lock()
        if var list = memoriesByCharacter[characterId] {
            list.removeAll(where: { $0.id == id })
            memoriesByCharacter[characterId] = list
        }
        lock.unlock()
        save()
    }
    
    public func clearMemories(for characterId: String) {
        lock.lock()
        memoriesByCharacter[characterId] = []
        lock.unlock()
        save()
    }
    
    public func clearAllMemories() {
        lock.lock()
        memoriesByCharacter.removeAll()
        lock.unlock()
        save()
    }
    
    public func pruneExpiredMemories() {
        lock.lock()
        let now = nowProvider()
        var changed = false
        for (charId, list) in memoriesByCharacter {
            let beforeCount = list.count
            let pruned = list.filter { record in
                if let exp = record.expiresAt {
                    return exp >= now
                }
                return true
            }
            if pruned.count != beforeCount {
                memoriesByCharacter[charId] = pruned
                changed = true
            }
        }
        lock.unlock()
        if changed {
            save()
        }
    }
}
