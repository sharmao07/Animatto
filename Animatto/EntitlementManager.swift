import Foundation
import Combine
import Security
import CryptoKit

// MARK: - License Tier Definition
public enum LicenseTier: String, Codable, CaseIterable, Sendable {
    case free = "free"
    case pro = "pro"
    case founder = "founder"
    
    public var displayName: String {
        switch self {
        case .free: return "Free Core (Apache-2.0)"
        case .pro: return "Lifetime Pro"
        case .founder: return "Founder Supporter"
        }
    }
    
    public var priceUSD: Double {
        switch self {
        case .free: return 0.0
        case .pro: return 3.99
        case .founder: return 5.99
        }
    }
    
    public var priceFormatted: String {
        switch self {
        case .free: return "$0"
        case .pro: return "$3.99"
        case .founder: return "$5.99"
        }
    }
    
    public var billingType: String {
        return "One-time payment (Perpetual access)"
    }
}

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
    
    // Pro Tier Capabilities
    case proSoundStudio = "pro_sound_studio"
    case proCustomPalettes = "pro_custom_palettes"
    case aquariumPro = "aquarium_pro"
    case multiDevice3 = "multi_device_3"
    case cloudSyncBackup = "cloud_sync_backup"
    case hostedLLMStreaming = "hosted_llm_streaming"
    case creatorMarketplace = "creator_marketplace"
    
    // Founder Supporter Capabilities (Includes all Pro Tier Capabilities)
    case founderBadge = "founder_badge"
    case readmeAcknowledgement = "readme_acknowledgement"
    case earlyBetaAccess = "early_beta_access"
    
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
        case .proSoundStudio,
             .proCustomPalettes,
             .aquariumPro,
             .multiDevice3,
             .cloudSyncBackup,
             .hostedLLMStreaming,
             .creatorMarketplace,
             .founderBadge,
             .readmeAcknowledgement,
             .earlyBetaAccess:
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
        case .proSoundStudio: return "Pro Sound Studio & Acoustics"
        case .proCustomPalettes: return "Pro Custom Palettes & Themes"
        case .aquariumPro: return "Aquarium Pro Customization"
        case .multiDevice3: return "Multi-Mac Activation (Up to 3)"
        case .cloudSyncBackup: return "Multi-Device Cloud Sync"
        case .hostedLLMStreaming: return "Hosted Cloud AI Token Quota"
        case .creatorMarketplace: return "Community Creator Marketplace"
        case .founderBadge: return "Founder Supporter Recognition"
        case .readmeAcknowledgement: return "Repository README Acknowledgement (Optional)"
        case .earlyBetaAccess: return "Early Public Beta Access"
        }
    }
}

// MARK: - Signed License Payload
public struct SignedLicensePayload: Codable, Equatable, Sendable {
    public let orderId: String
    public let customerEmail: String
    public let productId: String
    public let tier: String
    public let maxDevices: Int
    public let issuedAt: TimeInterval
    public let expiresAt: TimeInterval?
    public let entitlements: [String]
    public let supporterName: String?
    public let supporterConsent: Bool?
    
    public init(
        orderId: String,
        customerEmail: String,
        productId: String = "pdt_animatto_pro_lifetime",
        tier: String = "pro",
        maxDevices: Int = 3,
        issuedAt: TimeInterval = Date().timeIntervalSince1970,
        expiresAt: TimeInterval? = nil,
        entitlements: [String] = ["pro_sound_studio", "pro_custom_palettes", "aquarium_pro", "multi_device_3"],
        supporterName: String? = nil,
        supporterConsent: Bool? = nil
    ) {
        self.orderId = orderId
        self.customerEmail = customerEmail
        self.productId = productId
        self.tier = tier
        self.maxDevices = maxDevices
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.entitlements = entitlements
        self.supporterName = supporterName
        self.supporterConsent = supporterConsent
    }
    
    public var licenseTier: LicenseTier {
        if tier.lowercased() == "founder" || productId.contains("founder") {
            return .founder
        }
        return .pro
    }
}

// MARK: - License Cryptography Utility
public enum LicenseCryptoUtility {
    // Bundled official Ed25519 verification public key (Rotated Phase 5 Security Fix)
    public static let officialPublicKeyBase64 = "THicWCQTcrv96L6uwREk9qLrOiQcz5aGnVgbG7QXMGE="
    
    public static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        return Data(base64Encoded: base64)
    }
    
    public static func base64URLEncode(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    public static func verifyToken(
        _ token: String,
        publicKeyBase64: String = officialPublicKeyBase64
    ) -> (valid: Bool, payload: SignedLicensePayload?, error: String?) {
        let clean = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.hasPrefix("ANIM-PRO-") else {
            return (false, nil, "Invalid license key prefix. Must start with ANIM-PRO-")
        }
        
        let body = String(clean.dropFirst("ANIM-PRO-".count))
        let parts = body.split(separator: ".", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            return (false, nil, "Malformed license token format")
        }
        
        guard let payloadData = base64URLDecode(parts[0]),
              let signatureData = base64URLDecode(parts[1]) else {
            return (false, nil, "Base64URL decoding failed")
        }
        
        guard signatureData.count == 64 else {
            return (false, nil, "Invalid signature length")
        }
        
        guard let pubKeyData = Data(base64Encoded: publicKeyBase64),
              let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: pubKeyData) else {
            return (false, nil, "Invalid public verification key")
        }
        
        let isSignatureValid = publicKey.isValidSignature(signatureData, for: payloadData)
        guard isSignatureValid else {
            return (false, nil, "Cryptographic signature mismatch. Token may be tampered or invalid.")
        }
        
        guard let payload = try? JSONDecoder().decode(SignedLicensePayload.self, from: payloadData) else {
            return (false, nil, "Invalid entitlement payload JSON structure")
        }
        
        // Expiration check
        if let expiry = payload.expiresAt, expiry <= Date().timeIntervalSince1970 {
            return (false, payload, "License expired")
        }
        
        return (true, payload, nil)
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
        return isValid(asOf: Date())
    }
    
    public func isValid(asOf date: Date) -> Bool {
        switch self {
        case .valid(_, let expiry, _),
             .gracePeriod(_, let expiry, _):
            if let expiry = expiry, expiry <= date {
                return false
            }
            return true
        case .unlicensed, .expired, .revoked:
            return false
        }
    }
    
    public var displayTitle: String {
        switch self {
        case .unlicensed: return "Free Core (Apache-2.0)"
        case .valid:
            if let payload = EntitlementManager.shared.activePayload, payload.licenseTier == .founder {
                return "Animatto Founder Supporter Active"
            }
            return "Animatto Lifetime Pro Active"
        case .gracePeriod: return "Offline Grace Period Active"
        case .expired: return "License Expired"
        case .revoked: return "License Revoked"
        }
    }
    
    public var statusBadgeTitle: String {
        switch self {
        case .unlicensed: return "Free Core"
        case .valid:
            if let payload = EntitlementManager.shared.activePayload, payload.licenseTier == .founder {
                return "Founder Active"
            }
            return "Pro Active"
        case .gracePeriod: return "Grace Period"
        case .expired: return "Expired"
        case .revoked: return "Revoked"
        }
    }
    
    public var statusBadgeColorName: String {
        switch self {
        case .unlicensed: return "secondary"
        case .valid:
            if let payload = EntitlementManager.shared.activePayload, payload.licenseTier == .founder {
                return "purple"
            }
            return "green"
        case .gracePeriod: return "orange"
        case .expired: return "yellow"
        case .revoked: return "red"
        }
    }
    
    public var statusSummary: String {
        switch self {
        case .unlicensed:
            return "All 8 core pillars are 100% free forever under Apache-2.0. Lifetime Pro ($3.99) or Founder Supporter ($5.99) can be unlocked with an Animatto license key."
        case .valid(_, let expiry, let maxDevices):
            if let payload = EntitlementManager.shared.activePayload, payload.licenseTier == .founder {
                let supporterSuffix = (payload.supporterConsent == true && payload.supporterName != nil && !payload.supporterName!.isEmpty) ? " • Supporter: \(payload.supporterName!)" : ""
                return "Founder Supporter license active across up to \(maxDevices) Macs with lifetime access & repository recognition\(supporterSuffix)."
            }
            if let exp = expiry {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Full Pro access enabled across \(maxDevices) devices until \(formatter.string(from: exp))."
            }
            return "Lifetime Pro access active across up to \(maxDevices) personal Macs with offline verification."
        case .gracePeriod(_, _, let reason):
            return "Offline access active (\(reason)). All premium features remain fully functional."
        case .expired:
            return "This license key has reached its expiration date. Core open-source features remain 100% active."
        case .revoked(_, let reason):
            return "This license was revoked (\(reason)). Core open-source features remain 100% active."
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
    
    @Published public var status: LicenseStatus = .unlicensed
    @Published public private(set) var activePayload: SignedLicensePayload? = nil
    @Published public private(set) var isOnlineValidationConfigured: Bool = false
    
    private let storage: LicenseSecureStorage
    private let storageKey = "active_license_key"
    private let payloadKey = "active_license_payload"
    private let deviceIdKey = "active_device_id"
    public var nowProvider: () -> Date = { Date() }
    
    public init(storage: LicenseSecureStorage = KeychainLicenseStorage.shared) {
        self.storage = storage
        
        // Attempt to load and verify existing key from secure storage
        if let savedKey = storage.read(key: storageKey), !savedKey.isEmpty {
            // Check for mock test keys
            if savedKey.uppercased() == "ANIM-PRO-TEST-ACTIVE" {
                self.activePayload = SignedLicensePayload(
                    orderId: "ord_mock_active",
                    customerEmail: "tester@animatto.app",
                    productId: "pdt_animatto_pro_lifetime",
                    tier: "pro",
                    maxDevices: 3
                )
                self.status = .valid(licenseKey: savedKey, expiry: nil, maxDevices: 3)
                return
            } else if savedKey.uppercased() == "ANIM-FOUNDER-TEST-ACTIVE" {
                self.activePayload = SignedLicensePayload(
                    orderId: "ord_mock_founder",
                    customerEmail: "founder@animatto.app",
                    productId: "pdt_animatto_founder_lifetime",
                    tier: "founder",
                    maxDevices: 3,
                    entitlements: [
                        "pro_sound_studio", "pro_custom_palettes", "aquarium_pro", "multi_device_3",
                        "founder_badge", "readme_acknowledgement", "early_beta_access"
                    ],
                    supporterName: "Test Founder",
                    supporterConsent: true
                )
                self.status = .valid(licenseKey: savedKey, expiry: nil, maxDevices: 3)
                return
            } else if savedKey.uppercased() == "ANIM-PRO-TEST-EXPIRED" {
                self.status = .expired(licenseKey: savedKey)
                return
            } else if savedKey.uppercased() == "ANIM-PRO-TEST-REVOKED" {
                self.status = .revoked(licenseKey: savedKey, reason: "Flagged for refund or chargeback")
                return
            }
            
            // Perform cryptographic Ed25519 verification
            let verification = LicenseCryptoUtility.verifyToken(savedKey)
            if verification.valid, let payload = verification.payload {
                self.activePayload = payload
                let expiryDate = payload.expiresAt != nil ? Date(timeIntervalSince1970: payload.expiresAt!) : nil
                self.status = .valid(licenseKey: savedKey, expiry: expiryDate, maxDevices: payload.maxDevices)
            } else if verification.error == "License expired" {
                self.status = .expired(licenseKey: savedKey)
            } else {
                // If corrupted or invalid signature, reset to unlicensed
                _ = storage.delete(key: storageKey)
                _ = storage.delete(key: payloadKey)
                self.status = .unlicensed
            }
        } else {
            self.status = .unlicensed
        }
    }
    
    // MARK: - Unique Device Identifier
    
    public var currentDeviceId: String {
        if let existing = storage.read(key: deviceIdKey), !existing.isEmpty {
            return existing
        }
        let newId = "mac_" + UUID().uuidString.prefix(12).lowercased()
        _ = storage.save(key: deviceIdKey, value: newId)
        return newId
    }
    
    // MARK: - Entitlement Inquiries
    
    public func isEntitled(to entitlement: AppEntitlement) -> Bool {
        // Free capabilities are unconditionally granted across all states
        if entitlement.isFreeTier {
            return true
        }
        guard status.isValid(asOf: nowProvider()) else {
            return false
        }
        
        // Entitlement inheritance & gating based on verified tier
        if let payload = activePayload {
            // Founder Supporter tier inherits 100% of Pro benefits + Founder perks
            if payload.licenseTier == .founder {
                return true
            }
            
            // Lifetime Pro includes all Pro benefits, but NOT Founder-exclusive perks
            if entitlement == .founderBadge || entitlement == .readmeAcknowledgement || entitlement == .earlyBetaAccess {
                return false
            }
            
            return true
        }
        
        // Fallback for valid mock statuses without payload:
        // Pro features allowed, founder perks denied unless explicitly founder
        if entitlement == .founderBadge || entitlement == .readmeAcknowledgement || entitlement == .earlyBetaAccess {
            return false
        }
        return true
    }
    
    // MARK: - License Actions
    
    @discardableResult
    public func activateLicense(key: String) -> Bool {
        return activateLicenseWithDetails(key: key).success
    }
    
    public func activateLicenseWithDetails(key: String) -> (success: Bool, error: String?) {
        let clean = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            return (false, "License key cannot be empty.")
        }
        
        // Mock Key Detection for Development Testing
        if clean.uppercased() == "ANIM-PRO-TEST-ACTIVE" {
            _ = storage.save(key: storageKey, value: clean)
            self.activePayload = SignedLicensePayload(
                orderId: "ord_mock_active",
                customerEmail: "tester@animatto.app",
                productId: "pdt_animatto_pro_lifetime",
                tier: "pro",
                maxDevices: 3
            )
            self.status = .valid(licenseKey: clean, expiry: nil, maxDevices: 3)
            return (true, nil)
        }
        
        if clean.uppercased() == "ANIM-FOUNDER-TEST-ACTIVE" {
            _ = storage.save(key: storageKey, value: clean)
            self.activePayload = SignedLicensePayload(
                orderId: "ord_mock_founder",
                customerEmail: "founder@animatto.app",
                productId: "pdt_animatto_founder_lifetime",
                tier: "founder",
                maxDevices: 3,
                entitlements: [
                    "pro_sound_studio", "pro_custom_palettes", "aquarium_pro", "multi_device_3",
                    "founder_badge", "readme_acknowledgement", "early_beta_access"
                ],
                supporterName: "Test Founder",
                supporterConsent: true
            )
            self.status = .valid(licenseKey: clean, expiry: nil, maxDevices: 3)
            return (true, nil)
        }
        
        if clean.uppercased() == "ANIM-PRO-TEST-EXPIRED" {
            _ = storage.save(key: storageKey, value: clean)
            self.status = .expired(licenseKey: clean)
            return (true, nil)
        }
        
        if clean.uppercased() == "ANIM-PRO-TEST-REVOKED" {
            _ = storage.save(key: storageKey, value: clean)
            self.status = .revoked(licenseKey: clean, reason: "Flagged for refund or chargeback")
            return (true, nil)
        }
        
        #if DEBUG
        // Legacy test key compatibility in debug mode
        if !clean.hasPrefix("ANIM-PRO-") && clean.count >= 8 {
            _ = storage.save(key: storageKey, value: clean)
            self.activePayload = SignedLicensePayload(orderId: "ord_legacy_test", customerEmail: "dev@animatto.app")
            self.status = .valid(licenseKey: clean, expiry: nil, maxDevices: 3)
            return (true, nil)
        }
        #endif
        
        // Cryptographic Ed25519 Token Verification
        let verification = LicenseCryptoUtility.verifyToken(clean)
        guard verification.valid, let payload = verification.payload else {
            return (false, verification.error ?? "Invalid license token or cryptographic signature.")
        }
        
        // Persist to secure Keychain
        let keySaved = storage.save(key: storageKey, value: clean)
        if let payloadData = try? JSONEncoder().encode(payload),
           let payloadStr = String(data: payloadData, encoding: .utf8) {
            _ = storage.save(key: payloadKey, value: payloadStr)
        }
        
        if keySaved {
            self.activePayload = payload
            let expiryDate = payload.expiresAt != nil ? Date(timeIntervalSince1970: payload.expiresAt!) : nil
            self.status = .valid(licenseKey: clean, expiry: expiryDate, maxDevices: payload.maxDevices)
            return (true, nil)
        }
        
        return (false, "Failed to write license to secure macOS Keychain.")
    }
    
    public func activateMockState(_ status: LicenseStatus) {
        self.status = status
        switch status {
        case .valid(let key, _, _),
             .gracePeriod(let key, _, _),
             .expired(let key),
             .revoked(let key, _):
            _ = storage.save(key: storageKey, value: key)
        case .unlicensed:
            _ = storage.delete(key: storageKey)
            _ = storage.delete(key: payloadKey)
            self.activePayload = nil
        }
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
        _ = storage.delete(key: payloadKey)
        self.activePayload = nil
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
