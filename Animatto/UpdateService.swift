import Foundation
import SwiftUI
import AppKit
import Combine
import CryptoKit

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
        
        // Nightly Tag Support (e.g. "nightly-20261030-4293c9c", "nightly-2026-10-30-58b15d2", "nightly-20261030")
        if clean.lowercased().hasPrefix("nightly") {
            var rest = clean.dropFirst(7) // drop "nightly"
            if rest.hasPrefix("-") || rest.hasPrefix("_") || rest.hasPrefix(".") {
                rest = rest.dropFirst()
            }
            let parts = rest.split(separator: "-")
            if parts.count >= 3, let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) {
                self.components = [y, m, d]
                let remaining = parts.dropFirst(3).joined(separator: "-")
                self.prerelease = remaining.isEmpty ? "nightly" : "nightly-\(remaining)"
                self.buildMetadata = nil
                return
            } else if let first = parts.first, first.count >= 8, let dateVal = Int(first.prefix(8)) {
                let y = dateVal / 10000
                let m = (dateVal % 10000) / 100
                let d = dateVal % 100
                self.components = [y, m, d]
                let remaining = parts.dropFirst().joined(separator: "-")
                self.prerelease = remaining.isEmpty ? "nightly" : "nightly-\(remaining)"
                self.buildMetadata = nil
                return
            }
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
        // A normal release (no prerelease) has HIGHER precedence than a prerelease version.
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
    
    public var isZIP: Bool {
        return name.lowercased().hasSuffix(".zip")
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
    
    public var primaryUpdateAsset: ReleaseAssetInfo? {
        return assets.first(where: { $0.isDMG && $0.isVerifiedSource })
            ?? assets.first(where: { ($0.isDMG || $0.isZIP) && $0.isVerifiedSource })
    }
    
    public var displayTitle: String {
        if let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return name
        }
        return tagName
    }
}

// MARK: - Download Progress Model
public struct DownloadProgress: Equatable {
    public let bytesDownloaded: Int64
    public let totalBytesExpected: Int64
    public let fractionCompleted: Double
    public let speedBytesPerSecond: Double
    public let timeRemainingSeconds: TimeInterval?
    
    public init(
        bytesDownloaded: Int64,
        totalBytesExpected: Int64,
        fractionCompleted: Double,
        speedBytesPerSecond: Double,
        timeRemainingSeconds: TimeInterval?
    ) {
        self.bytesDownloaded = bytesDownloaded
        self.totalBytesExpected = totalBytesExpected
        self.fractionCompleted = fractionCompleted
        self.speedBytesPerSecond = speedBytesPerSecond
        self.timeRemainingSeconds = timeRemainingSeconds
    }
    
    public var formattedDownloaded: String {
        ByteCountFormatter.string(fromByteCount: bytesDownloaded, countStyle: .file)
    }
    
    public var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalBytesExpected, countStyle: .file)
    }
    
    public var formattedSpeed: String {
        let speedStr = ByteCountFormatter.string(fromByteCount: Int64(speedBytesPerSecond), countStyle: .file)
        return "\(speedStr)/s"
    }
    
    public var formattedTimeRemaining: String {
        guard let rem = timeRemainingSeconds, rem > 0 else { return "Calculating..." }
        let sec = Int(rem)
        if sec < 60 {
            return "\(sec)s remaining"
        } else {
            let mins = sec / 60
            let rSec = sec % 60
            return "\(mins)m \(rSec)s remaining"
        }
    }
}

// MARK: - Update Verification Engine
public enum UpdateVerificationError: LocalizedError, Equatable {
    case checksumMismatch(expected: String, actual: String)
    case unreadableFile(path: String)
    case emptyFile
    case diskImageInvalid(reason: String)
    case invalidBundleStructure(reason: String)
    case codeSignatureInvalid(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .checksumMismatch(let expected, let actual):
            return "SHA-256 verification mismatch. Expected: \(expected.prefix(8))... Actual: \(actual.prefix(8))..."
        case .unreadableFile(let path):
            return "Unable to read downloaded update at \(path)."
        case .emptyFile:
            return "Downloaded update package is empty."
        case .diskImageInvalid(let reason):
            return "Disk image integrity verification failed: \(reason)"
        case .invalidBundleStructure(let reason):
            return "Application bundle verification failed: \(reason)"
        case .codeSignatureInvalid(let reason):
            return "Application code signature is invalid: \(reason)"
        }
    }
}

public struct UpdateVerifier {
    public static func computeSHA256(for fileURL: URL) throws -> String {
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else {
            throw UpdateVerificationError.unreadableFile(path: fileURL.path)
        }
        defer { try? handle.close() }
        
        var hasher = SHA256()
        var totalRead: Int = 0
        while true {
            let chunk = handle.readData(ofLength: 64 * 1024)
            if chunk.isEmpty { break }
            totalRead += chunk.count
            hasher.update(data: chunk)
        }
        
        guard totalRead > 0 else {
            throw UpdateVerificationError.emptyFile
        }
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    public static func extractExpectedSHA256(from text: String, assetName: String? = nil) -> String? {
        let hexPattern = #"(?i)\b([a-f0-9]{64})\b"#
        guard let regex = try? NSRegularExpression(pattern: hexPattern) else { return nil }
        
        let lines = text.components(separatedBy: .newlines)
        if let asset = assetName {
            for line in lines where line.contains(asset) {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if let match = regex.firstMatch(in: line, range: range),
                   let matchRange = Range(match.range(at: 1), in: line) {
                    return String(line[matchRange]).lowercased()
                }
            }
        }
        
        for line in lines where line.lowercased().contains("sha") || line.lowercased().contains("checksum") {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = regex.firstMatch(in: line, range: range),
               let matchRange = Range(match.range(at: 1), in: line) {
                return String(line[matchRange]).lowercased()
            }
        }
        
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, range: fullRange),
           let matchRange = Range(match.range(at: 1), in: text) {
            return String(text[matchRange]).lowercased()
        }
        
        return nil
    }
    
    @discardableResult
    public static func verify(fileURL: URL, expectedSHA256: String?) throws -> String {
        let computed = try computeSHA256(for: fileURL)
        if let expected = expectedSHA256?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !expected.isEmpty {
            if computed.lowercased() != expected {
                throw UpdateVerificationError.checksumMismatch(expected: expected, actual: computed)
            }
        }
        return computed
    }
    
    public static func verifyStagedAppBundle(at appURL: URL) throws {
        let plistURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard FileManager.default.fileExists(atPath: plistURL.path) else {
            throw UpdateVerificationError.invalidBundleStructure(reason: "Contents/Info.plist is missing")
        }
        
        guard let plistData = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            throw UpdateVerificationError.invalidBundleStructure(reason: "Contents/Info.plist could not be parsed")
        }
        
        guard let bundleId = plist["CFBundleIdentifier"] as? String, bundleId == "com.dev.Animatto" else {
            throw UpdateVerificationError.invalidBundleStructure(reason: "Bundle identifier mismatch: \(plist["CFBundleIdentifier"] ?? "none")")
        }
        
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        proc.arguments = ["--verify", "--deep", "--strict", appURL.path]
        let errPipe = Pipe()
        proc.standardError = errPipe
        try? proc.run()
        proc.waitUntilExit()
        
        if proc.terminationStatus != 0 {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errString = String(data: errData, encoding: .utf8) ?? ""
            if errString.contains("invalid") || errString.contains("corrupt") || errString.contains("tampered") {
                throw UpdateVerificationError.codeSignatureInvalid(reason: errString.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }
}

// MARK: - Update Downloader (URLSessionDownloadDelegate)
public class UpdateDownloader: NSObject, URLSessionDownloadDelegate, ObservableObject {
    @Published public var progress: DownloadProgress = DownloadProgress(
        bytesDownloaded: 0,
        totalBytesExpected: 0,
        fractionCompleted: 0,
        speedBytesPerSecond: 0,
        timeRemainingSeconds: nil
    )
    @Published public var isDownloading: Bool = false
    
    public var onProgressUpdate: ((DownloadProgress) -> Void)?
    public var completionHandler: ((Result<URL, Error>) -> Void)?
    
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var downloadStartTime: Date?
    private var expectedTotalSize: Int64 = 0
    
    public override init() {
        super.init()
    }
    
    public func startDownload(
        from url: URL,
        expectedSize: Int64 = 0,
        progressHandler: ((DownloadProgress) -> Void)? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        cancel()
        
        self.onProgressUpdate = progressHandler
        self.completionHandler = completion
        self.expectedTotalSize = expectedSize
        self.downloadStartTime = Date()
        self.isDownloading = true
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 600.0
        
        let opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 1
        
        let sess = URLSession(configuration: config, delegate: self, delegateQueue: opQueue)
        self.session = sess
        
        var request = URLRequest(url: url)
        request.setValue("Animatto-Desktop-App", forHTTPHeaderField: "User-Agent")
        
        let task = sess.downloadTask(with: request)
        self.downloadTask = task
        task.resume()
    }
    
    public func cancel() {
        downloadTask?.cancel()
        downloadTask = nil
        session?.invalidateAndCancel()
        session = nil
        DispatchQueue.main.async {
            self.isDownloading = false
        }
    }
    
    // MARK: - URLSessionDownloadDelegate
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let expected = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : expectedTotalSize
        let fraction = expected > 0 ? min(1.0, max(0.0, Double(totalBytesWritten) / Double(expected))) : 0.0
        
        let elapsed = max(0.1, Date().timeIntervalSince(downloadStartTime ?? Date()))
        let speed = Double(totalBytesWritten) / elapsed
        let remainingBytes = max(0, expected - totalBytesWritten)
        let timeRemaining: TimeInterval? = speed > 1000 ? Double(remainingBytes) / speed : nil
        
        let newProgress = DownloadProgress(
            bytesDownloaded: totalBytesWritten,
            totalBytesExpected: expected,
            fractionCompleted: fraction,
            speedBytesPerSecond: speed,
            timeRemainingSeconds: timeRemaining
        )
        
        DispatchQueue.main.async {
            self.progress = newProgress
            self.onProgressUpdate?(newProgress)
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("com.dev.Animatto/Updates", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: cachesDir, withIntermediateDirectories: true)
            let destURL = cachesDir.appendingPathComponent("AnimattoUpdate-\(UUID().uuidString).dmg")
            try? FileManager.default.removeItem(at: destURL)
            try FileManager.default.copyItem(at: location, to: destURL)
            
            DispatchQueue.main.async {
                self.isDownloading = false
                self.completionHandler?(.success(destURL))
            }
        } catch {
            DispatchQueue.main.async {
                self.isDownloading = false
                self.completionHandler?(.failure(error))
            }
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let err = error {
            if (err as NSError).code == NSURLErrorCancelled {
                return
            }
            DispatchQueue.main.async {
                self.isDownloading = false
                self.completionHandler?(.failure(err))
            }
        }
    }
}

// MARK: - Update Stager & Installer
public enum UpdateStagingError: LocalizedError, Equatable {
    case mountFailed(code: Int32, message: String)
    case appNotFoundInImage
    case stagingCopyFailed(reason: String)
    case restartScriptFailed(reason: String)
    case destinationRequiresElevation
    
    public var errorDescription: String? {
        switch self {
        case .mountFailed(let code, let msg):
            return "Failed to mount DMG (code \(code)): \(msg)"
        case .appNotFoundInImage:
            return "No .app bundle found inside the update image."
        case .stagingCopyFailed(let reason):
            return "Failed to extract application bundle: \(reason)"
        case .restartScriptFailed(let reason):
            return "Failed to prepare restart script: \(reason)"
        case .destinationRequiresElevation:
            return "Updating Animatto in /Applications requires administrator permissions. Opening disk image for standard installation."
        }
    }
}

public struct UpdateStager {
    public static var stagingDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Animatto/Updates/Staged", isDirectory: true)
    }
    
    public static func stageApp(fromDMG dmgURL: URL) throws -> URL {
        let staging = stagingDirectory
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        
        let mountPoint = staging.appendingPathComponent("mnt", isDirectory: true)
        try? FileManager.default.removeItem(at: mountPoint)
        try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true)
        
        let mountProc = Process()
        mountProc.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        mountProc.arguments = ["attach", dmgURL.path, "-nobrowse", "-readonly", "-mountpoint", mountPoint.path]
        
        let errorPipe = Pipe()
        mountProc.standardError = errorPipe
        try mountProc.run()
        mountProc.waitUntilExit()
        
        guard mountProc.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errorData, encoding: .utf8) ?? "Unknown mount error"
            try? FileManager.default.removeItem(at: mountPoint)
            throw UpdateStagingError.mountFailed(code: mountProc.terminationStatus, message: errStr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        defer {
            let detachProc = Process()
            detachProc.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            detachProc.arguments = ["detach", mountPoint.path, "-force"]
            try? detachProc.run()
            detachProc.waitUntilExit()
            try? FileManager.default.removeItem(at: mountPoint)
        }
        
        let items = try FileManager.default.contentsOfDirectory(at: mountPoint, includingPropertiesForKeys: nil)
        guard let appBundle = items.first(where: { $0.pathExtension.lowercased() == "app" }) else {
            throw UpdateStagingError.appNotFoundInImage
        }
        
        let stagedTarget = staging.appendingPathComponent("Animatto.app", isDirectory: true)
        try? FileManager.default.removeItem(at: stagedTarget)
        
        do {
            try FileManager.default.copyItem(at: appBundle, to: stagedTarget)
            try UpdateVerifier.verifyStagedAppBundle(at: stagedTarget)
        } catch {
            throw UpdateStagingError.stagingCopyFailed(reason: error.localizedDescription)
        }
        
        return stagedTarget
    }
    
    public static func relaunchAndApplyUpdate(stagedAppURL: URL, targetAppURL: URL = Bundle.main.bundleURL, dmgURL: URL? = nil) throws {
        guard targetAppURL.pathExtension.lowercased() == "app" else {
            NSWorkspace.shared.open(stagedAppURL.deletingLastPathComponent())
            return
        }
        
        let targetExists = FileManager.default.fileExists(atPath: targetAppURL.path)
        let parentDir = targetAppURL.deletingLastPathComponent().path
        let targetWritable = targetExists ? FileManager.default.isWritableFile(atPath: targetAppURL.path) : FileManager.default.isWritableFile(atPath: parentDir)
        let parentWritable = FileManager.default.isWritableFile(atPath: parentDir)
        
        if !targetWritable || !parentWritable {
            if let dmg = dmgURL, FileManager.default.fileExists(atPath: dmg.path) {
                NSWorkspace.shared.open(dmg)
            } else {
                NSWorkspace.shared.open(stagedAppURL.deletingLastPathComponent())
            }
            throw UpdateStagingError.destinationRequiresElevation
        }
        
        let pid = ProcessInfo.processInfo.processIdentifier
        let scriptURL = FileManager.default.temporaryDirectory.appendingPathComponent("animatto_relaunch.sh")
        
        let script = """
        #!/bin/bash
        PID=\(pid)
        TARGET="\(targetAppURL.path)"
        STAGED="\(stagedAppURL.path)"
        
        for i in {1..50}; do
            if ! kill -0 $PID 2>/dev/null; then
                break
            fi
            sleep 0.2
        done
        
        rm -rf "$TARGET"
        cp -R "$STAGED" "$TARGET"
        open "$TARGET"
        """
        
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path]
        try process.run()
        
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Update Configuration
public class UpdateConfiguration: ObservableObject {
    public static let shared = UpdateConfiguration()
    
    private let nightlyDefaultsKey = "com.dev.Animatto.include_nightly_updates"
    
    @Published public var repositoryOwner: String = "sharmao07"
    @Published public var repositoryName: String = "Animatto"
    @Published public var apiEndpoint: String = "https://api.github.com/repos/sharmao07/Animatto/releases"
    @Published public var requestTimeout: TimeInterval = 15.0
    
    @Published public var includePrereleases: Bool {
        didSet {
            UserDefaults.standard.set(includePrereleases, forKey: nightlyDefaultsKey)
        }
    }
    
    @Published public var automaticCheckEnabled: Bool = true
    @Published public var checkIntervalHours: Double = 24.0
    
    public init() {
        self.includePrereleases = UserDefaults.standard.object(forKey: nightlyDefaultsKey) as? Bool ?? true
    }
    
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
    case downloading(release: AppReleaseInfo, progress: DownloadProgress)
    case verifying(release: AppReleaseInfo, status: String)
    case readyToRestart(release: AppReleaseInfo, stagedAppURL: URL)
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
    @Published public var stagedAppURL: URL?
    @Published public var downloadedDMGURL: URL?
    
    public let downloader = UpdateDownloader()
    
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
        
        if version > dismissedVer {
            return false
        }
        
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
            
            let eligibleReleases = releases.filter { release in
                if release.isDraft { return false }
                if !config.includePrereleases && release.isPrerelease { return false }
                return release.semanticVersion != nil
            }
            
            guard let latestRelease = eligibleReleases.max(by: {
                guard let v1 = $0.semanticVersion, let v2 = $1.semanticVersion else { return false }
                if v1 != v2 {
                    return v1 < v2
                }
                if let d1 = $0.publishedAt, let d2 = $1.publishedAt {
                    return d1 < d2
                }
                return $0.id < $1.id
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
            
            if latestVer > installed {
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
    
    // MARK: - In-App Download, Verification & Staging
    public func startDownload(release: AppReleaseInfo) {
        guard let asset = release.primaryUpdateAsset else {
            state = .error(message: "No suitable update package found for \(release.displayTitle). Please download manually from GitHub.")
            return
        }
        
        let initialProgress = DownloadProgress(
            bytesDownloaded: 0,
            totalBytesExpected: Int64(asset.size),
            fractionCompleted: 0.0,
            speedBytesPerSecond: 0.0,
            timeRemainingSeconds: nil
        )
        self.state = .downloading(release: release, progress: initialProgress)
        
        downloader.startDownload(
            from: asset.browserDownloadURL,
            expectedSize: Int64(asset.size),
            progressHandler: { [weak self] currentProgress in
                guard let self = self else { return }
                if case .downloading(let rel, _) = self.state {
                    self.state = .downloading(release: rel, progress: currentProgress)
                }
            },
            completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let localURL):
                    self.downloadedDMGURL = localURL
                    self.verifyAndStage(localURL: localURL, release: release)
                case .failure(let error):
                    self.state = .error(message: "Download failed: \(error.localizedDescription)")
                }
            }
        )
    }
    
    public func cancelDownload() {
        downloader.cancel()
        if let rel = availableRelease {
            state = .updateAvailable(release: rel, installedVersion: installedVersionProvider().description)
        } else {
            state = .idle
        }
    }
    
    public func verifyAndStage(localURL: URL, release: AppReleaseInfo) {
        self.state = .verifying(release: release, status: "Verifying checksum (SHA-256)...")
        
        Task.detached(priority: .userInitiated) {
            do {
                let expectedHash = UpdateVerifier.extractExpectedSHA256(
                    from: release.body ?? "",
                    assetName: release.primaryUpdateAsset?.name
                )
                _ = try UpdateVerifier.verify(fileURL: localURL, expectedSHA256: expectedHash)
                
                await MainActor.run {
                    self.state = .verifying(release: release, status: "Staging application bundle...")
                }
                
                let staged = try UpdateStager.stageApp(fromDMG: localURL)
                
                await MainActor.run {
                    self.stagedAppURL = staged
                    self.state = .readyToRestart(release: release, stagedAppURL: staged)
                }
            } catch {
                await MainActor.run {
                    self.state = .error(message: "Verification or extraction failed: \(error.localizedDescription). Please download the update directly from GitHub.")
                }
            }
        }
    }
    
    public func applyUpdateAndRestart() {
        guard case .readyToRestart(_, let stagedURL) = state else { return }
        do {
            try UpdateStager.relaunchAndApplyUpdate(stagedAppURL: stagedURL, dmgURL: downloadedDMGURL)
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }
    
    public func revealStagedUpdateInFinder() {
        if let staged = stagedAppURL {
            NSWorkspace.shared.selectFile(staged.path, inFileViewerRootedAtPath: staged.deletingLastPathComponent().path)
        } else if let dmg = downloadedDMGURL {
            NSWorkspace.shared.selectFile(dmg.path, inFileViewerRootedAtPath: dmg.deletingLastPathComponent().path)
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
