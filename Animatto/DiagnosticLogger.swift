import Foundation
import AppKit

// MARK: - Diagnostic Subsystem Category
public enum DiagnosticCategory: String, Codable, CaseIterable, Sendable {
    case general = "General"
    case companion = "Companion"
    case physics = "Physics"
    case aquarium = "Aquarium"
    case ambient = "Ambient"
    case audio = "Audio"
    case productivity = "Productivity"
    case licensing = "Licensing"
    case system = "System"
}

// MARK: - Diagnostic Log Level
public enum DiagnosticLevel: String, Codable, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}

// MARK: - Diagnostic Log Entry
public struct DiagnosticLogEntry: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let level: DiagnosticLevel
    public let category: DiagnosticCategory
    public let message: String
    
    public init(timestamp: Date = Date(), level: DiagnosticLevel = .info, category: DiagnosticCategory = .general, message: String) {
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
    }
}

// MARK: - Privacy-Conscious Diagnostic Logger
public final class DiagnosticLogger: @unchecked Sendable {
    public static let shared = DiagnosticLogger()
    
    private let lock = NSLock()
    private var entries: [DiagnosticLogEntry] = []
    private let maxEntries: Int = 200
    private var isHandlerInstalled = false
    
    private init() {
        installExceptionHandler()
        log(level: .info, category: .system, message: "Animatto diagnostic logging initialized.")
    }
    
    // MARK: - Logging API
    
    public func log(level: DiagnosticLevel = .info, category: DiagnosticCategory = .general, message: String) {
        let sanitized = sanitize(message)
        let entry = DiagnosticLogEntry(level: level, category: category, message: sanitized)
        
        lock.lock()
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        lock.unlock()
    }
    
    public func breadcrumb(_ category: DiagnosticCategory, _ message: String) {
        log(level: .info, category: category, message: message)
    }
    
    public func error(_ category: DiagnosticCategory, _ message: String, error: Error? = nil) {
        let fullMsg = error != nil ? "\(message): \(error!.localizedDescription)" : message
        log(level: .error, category: category, message: fullMsg)
    }
    
    // MARK: - Privacy Sanitization Engine
    
    public func sanitize(_ text: String) -> String {
        var clean = text
        
        // 1. Sanitize local home directory paths: /Users/<username> -> ~
        let homeDir = NSHomeDirectory()
        clean = clean.replacingOccurrences(of: homeDir, with: "~")
        
        // Secondary regex for any /Users/[^/]+
        let userPathPattern = #"/Users/[a-zA-Z0-9._-]+"#
        if let regex = try? NSRegularExpression(pattern: userPathPattern) {
            clean = regex.stringByReplacingMatches(in: clean, range: NSRange(clean.startIndex..<clean.endIndex, in: clean), withTemplate: "~")
        }
        
        // Sanitize current username if appearing as a standalone token
        let currentUsername = NSUserName()
        if !currentUsername.isEmpty && currentUsername.count >= 2 && currentUsername != "root" && currentUsername != "daemon" {
            clean = clean.replacingOccurrences(of: currentUsername, with: "[USER]")
        }
        
        // 2. Sanitize email addresses
        let emailPattern = #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#
        if let emailRegex = try? NSRegularExpression(pattern: emailPattern) {
            clean = emailRegex.stringByReplacingMatches(in: clean, range: NSRange(clean.startIndex..<clean.endIndex, in: clean), withTemplate: "[REDACTED_EMAIL]")
        }
        
        // 3. Sanitize long bearer tokens / secret keys
        let secretPattern = #"(?i)(key|secret|token|password|authorization)\s*[:=]\s*['"]?[a-zA-Z0-9_\-+=/]{16,}['"]?"#
        if let secretRegex = try? NSRegularExpression(pattern: secretPattern) {
            clean = secretRegex.stringByReplacingMatches(in: clean, range: NSRange(clean.startIndex..<clean.endIndex, in: clean), withTemplate: "$1: [REDACTED]")
        }
        
        // 4. Sanitize license keys (e.g. ANIM-PRO-xxxx or ANIM-FOUNDER-xxxx)
        let licensePattern = #"\bANIM-(PRO|FOUNDER)-[A-Z0-9\-]+\b"#
        if let licenseRegex = try? NSRegularExpression(pattern: licensePattern) {
            clean = licenseRegex.stringByReplacingMatches(in: clean, range: NSRange(clean.startIndex..<clean.endIndex, in: clean), withTemplate: "ANIM-$1-[REDACTED_LICENSE]")
        }
        
        return clean
    }
    
    // MARK: - Export Formatter
    
    public func exportSanitizedDiagnostics() -> String {
        lock.lock()
        let snapshot = entries
        lock.unlock()
        
        let bundleVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.0"
        let buildNum = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "3"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        
        var arch = "Unknown"
        #if arch(arm64)
        arch = "Apple Silicon (arm64)"
        #elseif arch(x86_64)
        arch = "Intel (x86_64)"
        #endif
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var report = """
        ### Animatto Diagnostic Report
        - **App Version:** v\(bundleVer) (Build \(buildNum))
        - **macOS Version:** \(osVersion)
        - **Architecture:** \(arch)
        - **Timestamp:** \(df.string(from: Date()))
        - **Active Companions:** \(PetManager.shared?.activePets.count ?? 0)
        - **Aquarium Mode Active:** \(AquariumManager.shared.isAquariumModeActive ? "Yes" : "No")
        - **Ambient Engine Enabled:** \(AmbientEngine.shared.isEnabled ? "Yes (\(AmbientEngine.shared.currentEnvironment.displayName))" : "No")
        - **Audio Master Muted:** \(AudioSettings.shared.isMasterMuted ? "Yes" : "No")
        
        #### Recent Event Breadcrumbs (Sanitized)
        ```text
        """
        
        let recentEntries = snapshot.suffix(60)
        if recentEntries.isEmpty {
            report += "\n(No diagnostic events recorded)"
        } else {
            for entry in recentEntries {
                let timeStr = df.string(from: entry.timestamp)
                report += "\n[\(timeStr)] [\(entry.level.rawValue)] [\(entry.category.rawValue)] \(entry.message)"
            }
        }
        
        report += "\n```\n"
        return report
    }
    
    public func copyToClipboard() {
        let text = exportSanitizedDiagnostics()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    // MARK: - Crash & Unhandled Exception Handler
    
    private func installExceptionHandler() {
        guard !isHandlerInstalled else { return }
        isHandlerInstalled = true
        
        NSSetUncaughtExceptionHandler { exception in
            let rawReason = exception.reason ?? "No reason provided"
            let sanitizedReason = DiagnosticLogger.shared.sanitize(rawReason)
            let callStack = exception.callStackSymbols.prefix(8).joined(separator: "\n  ")
            let sanitizedStack = DiagnosticLogger.shared.sanitize(callStack)
            
            DiagnosticLogger.shared.log(
                level: .error,
                category: .system,
                message: "Uncaught Cocoa Exception: \(exception.name.rawValue) - Reason: \(sanitizedReason)\nStack:\n  \(sanitizedStack)"
            )
        }
    }
}
