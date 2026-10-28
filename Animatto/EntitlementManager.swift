import Foundation
import Combine
import Security

// MARK: - Entitlement Definitions
public enum AppEntitlement: String, CaseIterable, Identifiable, Codable {
    // 100% Free Core Capabilities
    case coreDesktopPhysics = "core_desktop_physics"
    case unlimitedCharacters = "unlimited_characters"
    case personalityMatrix = "personality_matrix"
    case contextualDialogue = "contextual_dialogue"
    case characterMemory = "character_memory"
    case socialEncounters = "social_encounters"
    case productivitySessions = "productivity_sessions"
    case workshopStudio = "workshop_studio"
    
    // Potential Future Cloud/Service Capabilities
    case cloudSyncBackup = "cloud_sync_backup"
    case hostedLLMStreaming = "hosted_llm_streaming"
    case creatorMarketplace = "creator_marketplace"
    
    public var id: String { rawValue }
    
    public var isFreeTier: Bool {
        switch self {
        case .coreDesktopPhysics,
             .unlimitedCharacters,
             .personalityMatrix,
             .contextualDialogue,
             .characterMemory,
             .socialEncounters,
             .productivitySessions,
             .workshopStudio:
            return true
        case .cloudSyncBackup,
             .hostedLLMStreaming,
             .creatorMarketplace:
            return false
        }
    }
    
    public var displayName: String {
        switch self {
        case .coreDesktopPhysics: return "Desktop Physics & Movement"
        case .unlimitedCharacters: return "Unlimited Local Characters"
        case .personalityMatrix: return "10-Trait Personality Matrix"
        case .contextualDialogue: return "Speech Bubbles & Dialogue"
        case .characterMemory: return "Character Memory & Continuity"
        case .socialEncounters: return "Multi-Companion Social Encounters"
        case .productivitySessions: return "Pomodoro & Focus Sprints"
        case .workshopStudio: return "Workshop Studio & Magic Eraser"
        case .cloudSyncBackup: return "Multi-Device Cloud Sync"
        case .hostedLLMStreaming: return "Hosted Cloud AI Token Quota"
        case .creatorMarketplace: return "Community Creator Marketplace"
        }
    }
}

// MARK: - License Status & State Machine
public enum LicenseStatus: Equatable {
    case unlicensed
    case valid(licenseKey: String, expiry: Date?, maxDevices: Int)
    case gracePeriod(licenseKey: String, expiry: Date?, errorReason: String)
    case expired(licenseKey: String)
    case revoked(licenseKey: String, reason: String)
    
    public var isValid: Bool {
        switch self {
        case .valid, .gracePeriod:
            return true
        case .unlicensed, .expired, .revoked:
            return false
        }
    }
    
    public var displayTitle: String {
        switch self {
        case .unlicensed: return "Free & Open-Source Tier"
        case .valid: return "Premium License Active"
        case .gracePeriod: return "Offline Grace Period Active"
        case .expired: return "License Expired"
        case .revoked: return "License Revoked"
        }
    }
}

// MARK: - Key Sanitization & Redaction
public struct LicenseRedactor {
    public static func redact(_ key: String) -> String {
        let clean = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 8 else {
            return "****"
        }
        let prefix = clean.prefix(4)
        let suffix = clean.suffix(4)
        return "\(prefix)-****-****-\(suffix)"
    }
}

// MARK: - Secure Storage Interface (Keychain)
public protocol LicenseSecureStorage {
    func save(key: String, value: String) -> Bool
    func read(key: String) -> String?
    func delete(key: String) -> Bool
}

public class KeychainLicenseStorage: LicenseSecureStorage {
    public static let shared = KeychainLicenseStorage()
    private let service = "com.dev.Animatto.licensing"
    
    public init() {}
    
    public func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        // Remove existing entry before saving
        SecItemDelete(query as CFDictionary)
        
        var newQuery = query
        newQuery[kSecValueData as String] = data
        let status = SecItemAdd(newQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    public func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    public func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

public class MockLicenseStorage: LicenseSecureStorage {
    private var store: [String: String] = [:]
    public init() {}
    
    public func save(key: String, value: String) -> Bool {
        store[key] = value
        return true
    }
    public func read(key: String) -> String? {
        return store[key]
    }
    public func delete(key: String) -> Bool {
        store.removeValue(forKey: key)
        return true
    }
}

// MARK: - Entitlement Manager
public class EntitlementManager: ObservableObject {
    public static let shared = EntitlementManager()
    
    @Published public private(set) var status: LicenseStatus = .unlicensed
    @Published public private(set) var isOnlineValidationConfigured: Bool = false
    
    private let storage: LicenseSecureStorage
    private let storageKey = "active_license_key"
    public var nowProvider: () -> Date = { Date() }
    
    public init(storage: LicenseSecureStorage = KeychainLicenseStorage.shared) {
        self.storage = storage
        
        // Attempt to load existing key from secure storage
        if let savedKey = storage.read(key: storageKey), !savedKey.isEmpty {
            // By default, a saved key enters grace period until verified against a real server authority
            self.status = .gracePeriod(licenseKey: savedKey, expiry: nil, errorReason: "Awaiting server verification")
        } else {
            self.status = .unlicensed
        }
    }
    
    // MARK: - Entitlement Inquiries
    
    public func isEntitled(to entitlement: AppEntitlement) -> Bool {
        // Free capabilities are unconditionally granted across all states
        if entitlement.isFreeTier {
            return true
        }
        return status.isValid
    }
    
    // MARK: - License Actions
    
    public func activateLicense(key: String) -> Bool {
        let clean = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.count >= 8 else {
            return false
        }
        
        let saved = storage.save(key: storageKey, value: clean)
        if saved {
            self.status = .valid(licenseKey: clean, expiry: nil, maxDevices: 3)
            return true
        }
        return false
    }
    
    public func enterGracePeriod(reason: String) {
        switch status {
        case .valid(let key, let expiry, _),
             .gracePeriod(let key, let expiry, _):
            self.status = .gracePeriod(licenseKey: key, expiry: expiry, errorReason: reason)
        case .unlicensed, .expired, .revoked:
            break
        }
    }
    
    public func deactivateLicense() {
        _ = storage.delete(key: storageKey)
        self.status = .unlicensed
        // Notice: Local companions, character memories, focus sessions, and user settings are strictly preserved
    }
    
    public func redactedActiveKey() -> String? {
        switch status {
        case .valid(let key, _, _),
             .gracePeriod(let key, _, _),
             .expired(let key),
             .revoked(let key, _):
            return LicenseRedactor.redact(key)
        case .unlicensed:
            return nil
        }
    }
}
