import Foundation
import SwiftUI
import AppKit
import Combine

// MARK: - Semantic Version Parser & Comparator
public struct SemanticVersion: Comparable, Hashable, Codable, CustomStringConvertible {
    public let rawString: String
    public let components: [Int]
    public let prerelease: String?
    public let buildMetadata: String?
    
    public var isPrerelease: Bool {
        return prerelease != nil && !prerelease!.isEmpty
    }
    
    public var description: String {
        var str = components.map(String.init).joined(separator: ".")
        if let pre = prerelease {
            str += "-\(pre)"
        }
        if let build = buildMetadata {
            str += "+\(build)"
        }
        return str
    }
    
    public init?(string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        self.rawString = trimmed
        
        // Strip optional 'v' or 'V' prefix
        var clean = trimmed
        if clean.hasPrefix("v") || clean.hasPrefix("V") {
            clean.removeFirst()
        }
        
        // Extract build metadata (+...)
        let buildParts = clean.split(separator: "+", maxSplits: 1, omittingEmptySubsequences: true)
        if buildParts.count > 1 {
            self.buildMetadata = String(buildParts[1])
            clean = String(buildParts[0])
        } else {
            self.buildMetadata = nil
        }
        
        // Extract prerelease (-...)
        let preParts = clean.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
        if preParts.count > 1 {
            self.prerelease = String(preParts[1])
            clean = String(preParts[0])
        } else {
            self.prerelease = nil
        }
        
        // Extract numeric components (. separated)
        let numParts = clean.split(separator: ".")
        var parsed: [Int] = []
        for part in numParts {
            // Take digits from the component
            let digitStr = part.prefix(while: { $0.isNumber })
            if let val = Int(digitStr) {
                parsed.append(val)
            } else {
                return nil
            }
        }
        
        guard !parsed.isEmpty else { return nil }
        self.components = parsed
    }
    
    public init(major: Int, minor: Int, patch: Int, prerelease: String? = nil, buildMetadata: String? = nil) {
        self.components = [major, minor, patch]
        self.prerelease = prerelease
        self.buildMetadata = buildMetadata
        var raw = "\(major).\(minor).\(patch)"
        if let pre = prerelease { raw += "-\(pre)" }
        if let b = buildMetadata { raw += "+\(b)" }
        self.rawString = raw
    }
    
    // MARK: - Comparable Implementation
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let maxCount = max(lhs.components.count, rhs.components.count)
        for i in 0..<maxCount {
            let leftVal = i < lhs.components.count ? lhs.components[i] : 0
            let rightVal = i < rhs.components.count ? rhs.components[i] : 0
            
            if leftVal != rightVal {
                return leftVal < rightVal
            }
        }
        
        // If numeric components are equal, handle prerelease precedence according to SemVer 2.0:
        // A normal version (no prerelease) has HIGHER precedence than a prerelease version.
        // e.g. 1.0.0-beta < 1.0.0
        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil):
            return false // Identical versions
        case (nil, .some):
            return false // Normal release is strictly newer than prerelease
        case (.some, nil):
            return true  // Prerelease is strictly older than normal release
        case (.some(let leftPre), .some(let rightPre)):
            return leftPre.compare(rightPre, options: .numeric) == .orderedAscending
        }
    }
    
    public static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let maxCount = max(lhs.components.count, rhs.components.count)
        for i in 0..<maxCount {
            let leftVal = i < lhs.components.count ? lhs.components[i] : 0
            let rightVal = i < rhs.components.count ? rhs.components[i] : 0
            if leftVal != rightVal { return false }
        }
        return lhs.prerelease == rhs.prerelease
    }
}

// MARK: - GitHub Release Asset Model
public struct ReleaseAssetInfo: Identifiable, Hashable, Codable {
    public let id: Int
    public let name: String
    public let contentType: String
    public let size: Int
    public let downloadCount: Int
    public let browserDownloadURL: URL
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case contentType = "content_type"
        case size
        case downloadCount = "download_count"
        case browserDownloadURL = "browser_download_url"
    }
    
    public init(id: Int, name: String, contentType: String, size: Int, downloadCount: Int, browserDownloadURL: URL) {
        self.id = id
        self.name = name
        self.contentType = contentType
        self.size = size
        self.downloadCount = downloadCount
        self.browserDownloadURL = browserDownloadURL
    }
    
    public var isDMG: Bool {
        return name.lowercased().hasSuffix(".dmg")
    }
    
    public var isVerifiedSource: Bool {
        guard browserDownloadURL.scheme == "https" else { return false }
        guard let host = browserDownloadURL.host?.lowercased() else { return false }
        return host == "github.com" || host.hasSuffix(".github.com") || host == "objects.githubusercontent.com"
    }
}

// MARK: - GitHub Release Info Model
public struct AppReleaseInfo: Identifiable, Hashable, Codable {
    public let id: Int
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlURL: URL
    public let publishedAt: Date?
    public let isPrerelease: Bool
    public let isDraft: Bool
    public let assets: [ReleaseAssetInfo]
    
    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case body
        case htmlURL = "html_url"
        case publishedAt = "published_at"
        case isPrerelease = "prerelease"
        case isDraft = "draft"
        case assets
    }
    
    public init(
        id: Int,
        tagName: String,
        name: String? = nil,
        body: String? = nil,
        htmlURL: URL,
        publishedAt: Date? = nil,
        isPrerelease: Bool = false,
        isDraft: Bool = false,
        assets: [ReleaseAssetInfo] = []
    ) {
        self.id = id
        self.tagName = tagName
        self.name = name
        self.body = body
        self.htmlURL = htmlURL
        self.publishedAt = publishedAt
        self.isPrerelease = isPrerelease
        self.isDraft = isDraft
        self.assets = assets
    }
    
    public var semanticVersion: SemanticVersion? {
        return SemanticVersion(string: tagName)
    }
    
    public var primaryDMGAsset: ReleaseAssetInfo? {
        return assets.first(where: { $0.isDMG && $0.isVerifiedSource })
    }
    
    public var displayTitle: String {
        if let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return name
        }
        return tagName
    }
}

// MARK: - Update Configuration
public class UpdateConfiguration: ObservableObject {
    public static let shared = UpdateConfiguration()
    
    @Published public var repositoryOwner: String = "sharmao07"
    @Published public var repositoryName: String = "Animatto"
    @Published public var apiEndpoint: String = "https://api.github.com/repos/sharmao07/Animatto/releases"
    @Published public var requestTimeout: TimeInterval = 15.0
    @Published public var includePrereleases: Bool = false
    @Published public var automaticCheckEnabled: Bool = true
    @Published public var checkIntervalHours: Double = 24.0
    
    public init() {}
    
    public func releasesURL() -> URL? {
        return URL(string: apiEndpoint)
    }
    
    public func repositoryReleasesWebURL() -> URL {
        return URL(string: "https://github.com/\(repositoryOwner)/\(repositoryName)/releases")!
    }
}

// MARK: - Update Check Results & States
public enum UpdateCheckResult: Equatable {
    case upToDate(installed: SemanticVersion)
    case updateAvailable(release: AppReleaseInfo, installed: SemanticVersion)
    case noSuitableRelease(reason: String)
    case failed(error: String)
}

public enum UpdateUIState: Equatable {
    case idle
    case checking
    case upToDate(installedVersion: String, checkedAt: Date)
    case updateAvailable(release: AppReleaseInfo, installedVersion: String)
    case error(message: String)
}

// MARK: - Update Service Manager
public class UpdateService: ObservableObject {
    public static let shared = UpdateService()
    
    // Dependencies (Injectable for deterministic testing)
    public var nowProvider: () -> Date = { Date() }
    public var session: URLSession
    public var installedVersionProvider: () -> SemanticVersion = {
        let bundleVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return SemanticVersion(string: bundleVer) ?? SemanticVersion(major: 1, minor: 0, patch: 0)
    }
    
    // Observable UI State
    @Published public var state: UpdateUIState = .idle
    @Published public var isChecking: Bool = false
    @Published public var lastCheckedDate: Date?
    @Published public var availableRelease: AppReleaseInfo?
    
    private let dismissedVersionKey = "com.dev.Animatto.dismissed_update_version"
    private let dismissedTimestampKey = "com.dev.Animatto.dismissed_update_time"
    private let lastCheckTimeKey = "com.dev.Animatto.last_update_check_time"
    
    private var activeTask: Task<Void, Never>?
    
    public init(session: URLSession? = nil) {
        if let customSession = session {
            self.session = customSession
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = UpdateConfiguration.shared.requestTimeout
            config.timeoutIntervalForResource = UpdateConfiguration.shared.requestTimeout * 2
            self.session = URLSession(configuration: config)
        }
        
        if let timestamp = UserDefaults.standard.object(forKey: lastCheckTimeKey) as? Date {
            self.lastCheckedDate = timestamp
        }
    }
    
    deinit {
        activeTask?.cancel()
    }
    
    // MARK: - Dismissal Management
    
    public func dismissCurrentUpdate() {
        guard case .updateAvailable(let release, _) = state else { return }
        let now = nowProvider()
        UserDefaults.standard.set(release.tagName, forKey: dismissedVersionKey)
        UserDefaults.standard.set(now, forKey: dismissedTimestampKey)
        state = .idle
    }
    
    public func isVersionDismissed(_ version: SemanticVersion) -> Bool {
        guard let dismissedTag = UserDefaults.standard.string(forKey: dismissedVersionKey),
              let dismissedVer = SemanticVersion(string: dismissedTag) else {
            return false
        }
        
        // If the available version is newer than the dismissed version, do not suppress
        if version > dismissedVer {
            return false
        }
        
        // Cooldown check: allow re-prompting after 7 days even for the same version
        if let dismissedTime = UserDefaults.standard.object(forKey: dismissedTimestampKey) as? Date {
            let elapsed = nowProvider().timeIntervalSince(dismissedTime)
            let sevenDays: TimeInterval = 7 * 24 * 3600
            if elapsed > sevenDays {
                return false
            }
        }
        
        return true
    }
    
    public func clearDismissal() {
        UserDefaults.standard.removeObject(forKey: dismissedVersionKey)
        UserDefaults.standard.removeObject(forKey: dismissedTimestampKey)
    }
    
    // MARK: - Update Check Workflow
    
    @discardableResult
    public func checkForUpdates(isManualCheck: Bool = false) async -> UpdateCheckResult {
        // Prevent concurrent checks
        guard !isChecking else {
            return .noSuitableRelease(reason: "Check already in progress.")
        }
        
        isChecking = true
        state = .checking
        
        let installed = installedVersionProvider()
        let config = UpdateConfiguration.shared
        
        guard let url = config.releasesURL() else {
            isChecking = false
            let err = "Invalid GitHub releases API endpoint."
            state = .error(message: err)
            return .failed(error: err)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = config.requestTimeout
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Animatto-Desktop-App", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                isChecking = false
                let err = "Invalid response received from GitHub."
                state = .error(message: err)
                return .failed(error: err)
            }
            
            // Check HTTP Status Codes
            if httpResponse.statusCode == 403 {
                isChecking = false
                let err = "GitHub API rate limit exceeded. Please try again later."
                state = .error(message: err)
                return .failed(error: err)
            }
            
            if httpResponse.statusCode == 404 {
                isChecking = false
                let err = "Repository releases endpoint not found."
                state = .error(message: err)
                return .failed(error: err)
            }
            
            guard httpResponse.statusCode == 200 else {
                isChecking = false
                let err = "GitHub returned HTTP status code \(httpResponse.statusCode)."
                state = .error(message: err)
                return .failed(error: err)
            }
            
            // Decode Releases
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let releases: [AppReleaseInfo]
            do {
                releases = try decoder.decode([AppReleaseInfo].self, from: data)
            } catch {
                isChecking = false
                let err = "Malformed release response received from GitHub."
                state = .error(message: err)
                return .failed(error: err)
            }
            
            // Filter out drafts and, unless opted in, prereleases
            let eligibleReleases = releases.filter { release in
                if release.isDraft { return false }
                if !config.includePrereleases && release.isPrerelease { return false }
                return release.semanticVersion != nil
            }
            
            // Find the highest semantic version
            guard let latestRelease = eligibleReleases.max(by: {
                guard let v1 = $0.semanticVersion, let v2 = $1.semanticVersion else { return false }
                return v1 < v2
            }), let latestVer = latestRelease.semanticVersion else {
                isChecking = false
                let checkTime = nowProvider()
                self.lastCheckedDate = checkTime
                UserDefaults.standard.set(checkTime, forKey: lastCheckTimeKey)
                state = .upToDate(installedVersion: installed.description, checkedAt: checkTime)
                return .upToDate(installed: installed)
            }
            
            let checkTime = nowProvider()
            self.lastCheckedDate = checkTime
            UserDefaults.standard.set(checkTime, forKey: lastCheckTimeKey)
            self.isChecking = false
            
            // Version Comparison
            if latestVer > installed {
                // Check if user previously dismissed this exact version (only applies to background checks)
                if !isManualCheck && isVersionDismissed(latestVer) {
                    state = .idle
                    return .updateAvailable(release: latestRelease, installed: installed)
                }
                
                self.availableRelease = latestRelease
                state = .updateAvailable(release: latestRelease, installedVersion: installed.description)
                return .updateAvailable(release: latestRelease, installed: installed)
            } else {
                self.availableRelease = nil
                state = .upToDate(installedVersion: installed.description, checkedAt: checkTime)
                return .upToDate(installed: installed)
            }
            
        } catch {
            self.isChecking = false
            let errMessage: String
            if (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == NSURLErrorTimedOut {
                errMessage = "Update check timed out. Please verify your internet connection."
            } else if (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == NSURLErrorNotConnectedToInternet {
                errMessage = "No internet connection available. Offline mode active."
            } else {
                errMessage = "Network error: \(error.localizedDescription)"
            }
            state = .error(message: errMessage)
            return .failed(error: errMessage)
        }
    }
    
    // MARK: - Safe External Navigation
    
    public func openReleaseWebPage(url: URL) {
        guard url.scheme == "https" else { return }
        guard let host = url.host?.lowercased(), host == "github.com" || host.hasSuffix(".github.com") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
