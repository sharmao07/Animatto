import Foundation
import CoreGraphics
import AppKit

// MARK: - Window Platform Model
public struct WindowPlatform: Identifiable, Equatable, Hashable {
    public let id: CGWindowID
    public let ownerName: String
    public let frame: CGRect // Cocoa coordinates (bottom-left origin)
    public let topEdgeY: CGFloat
    public let minX: CGFloat
    public let maxX: CGFloat
    public let layer: Int
    
    public init(
        id: CGWindowID,
        ownerName: String,
        frame: CGRect,
        layer: Int = 0
    ) {
        self.id = id
        self.ownerName = ownerName
        self.frame = frame
        self.topEdgeY = frame.maxY
        self.minX = frame.minX
        self.maxX = frame.maxX
        self.layer = layer
    }
    
    public func containsX(_ x: CGFloat) -> Bool {
        return x >= minX && x <= maxX
    }
}

// MARK: - Window Platform Tracker
public class WindowPlatformTracker: @unchecked Sendable {
    public static let shared = WindowPlatformTracker()
    
    // Configuration & Tuning
    public var isEnabled: Bool = true
    public var cacheInterval: TimeInterval = 0.33 // 3 Hz polling cache for high battery efficiency
    public var minWindowWidth: CGFloat = 160.0
    public var minWindowHeight: CGFloat = 80.0
    
    // Injectable provider for deterministic headless unit tests
    public var windowListProvider: (() -> [[String: Any]]?)?
    public var screenHeightProvider: () -> CGFloat = {
        NSScreen.screens.first?.frame.height ?? 1080.0
    }
    
    // Cached state
    private var cachedPlatforms: [WindowPlatform] = []
    private var lastScanTime: Date = .distantPast
    private let lock = NSLock()
    
    public init() {}
    
    /// Clears cached window platforms
    public func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedPlatforms = []
        lastScanTime = .distantPast
    }
    
    /// Retrieves current active window platforms, leveraging the 3 Hz battery-efficient cache.
    public func getPlatforms(forceRefresh: Bool = false) -> [WindowPlatform] {
        guard isEnabled else { return [] }
        
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        if !forceRefresh && now.timeIntervalSince(lastScanTime) < cacheInterval && !cachedPlatforms.isEmpty {
            return cachedPlatforms
        }
        
        let primaryHeight = screenHeightProvider()
        let animattoPID = ProcessInfo.processInfo.processIdentifier
        
        let rawInfoList: [[String: Any]]?
        if let customProvider = windowListProvider {
            rawInfoList = customProvider()
        } else {
            guard let infoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
                return cachedPlatforms
            }
            rawInfoList = infoList
        }
        
        guard let list = rawInfoList else {
            return cachedPlatforms
        }
        
        var platforms: [WindowPlatform] = []
        
        for dict in list {
            // Filter 1: Window Layer (Layer 0 is standard app windows; excludes menubars, status items, desktop)
            guard let layer = dict[kCGWindowLayer as String] as? Int, layer == 0 else {
                continue
            }
            
            // Filter 2: Exclude Animatto's own process to avoid walking on companions/bubbles/overlays
            if let pid = dict[kCGWindowOwnerPID as String] as? pid_t, pid == animattoPID {
                continue
            }
            
            // Filter 3: Check window bounds
            guard let boundsDict = dict[kCGWindowBounds as String] as? [String: Any],
                  let qX = (boundsDict["X"] as? CGFloat) ?? (boundsDict["X"] as? Double).map({ CGFloat($0) }),
                  let qY = (boundsDict["Y"] as? CGFloat) ?? (boundsDict["Y"] as? Double).map({ CGFloat($0) }),
                  let qW = (boundsDict["Width"] as? CGFloat) ?? (boundsDict["Width"] as? Double).map({ CGFloat($0) }),
                  let qH = (boundsDict["Height"] as? CGFloat) ?? (boundsDict["Height"] as? Double).map({ CGFloat($0) }) else {
                continue
            }
            
            // Filter 4: Minimum dimension check (exclude invisible/tool windows)
            if qW < minWindowWidth || qH < minWindowHeight {
                continue
            }
            
            // Filter 5: Window alpha / visibility
            if let alpha = dict[kCGWindowAlpha as String] as? Double, alpha < 0.2 {
                continue
            }
            
            // Convert Quartz coordinate space (top-left origin) to Cocoa space (bottom-left origin)
            let cocoaX = qX
            let cocoaY = primaryHeight - (qY + qH)
            let frame = CGRect(x: cocoaX, y: cocoaY, width: qW, height: qH)
            
            let windowID = (dict[kCGWindowNumber as String] as? CGWindowID) ?? (dict[kCGWindowNumber as String] as? Int).map { CGWindowID($0) } ?? 0
            let ownerName = (dict[kCGWindowOwnerName as String] as? String) ?? "Application"
            
            platforms.append(WindowPlatform(
                id: windowID,
                ownerName: ownerName,
                frame: frame,
                layer: layer
            ))
        }
        
        self.cachedPlatforms = platforms
        self.lastScanTime = now
        return platforms
    }
    
    /// Resolves the supporting horizontal floor for a companion given its horizontal position and visual feet Y.
    /// Returns the target floor Y, whether the companion is standing on a window, and the platform if applicable.
    public func resolveSupportingFloor(
        petMidX: CGFloat,
        visualFeetY: CGFloat,
        screenFloor: CGFloat,
        currentPlatform: WindowPlatform? = nil
    ) -> (floorY: CGFloat, isOnWindow: Bool, platform: WindowPlatform?) {
        let platforms = getPlatforms()
        
        // 1. If currently on a platform, check if the companion is still horizontally within its bounds
        if let current = currentPlatform {
            if let updated = platforms.first(where: { $0.id == current.id }) {
                // If the window is still open and companion is within horizontal bounds
                if updated.containsX(petMidX) {
                    let topEdge = updated.topEdgeY - 40
                    // If feet are reasonably close to the platform top (within 30pt), maintain stickiness
                    if visualFeetY >= topEdge - 15 && visualFeetY <= topEdge + 35 {
                        return (floorY: topEdge, isOnWindow: true, platform: updated)
                    }
                }
            }
        }
        
        // 2. Scan candidate platforms that horizontally cover the companion
        let candidates = platforms
            .filter { $0.containsX(petMidX) }
            .sorted { $0.topEdgeY > $1.topEdgeY } // Highest window first
        
        for candidate in candidates {
            let candidateTopEdge = candidate.topEdgeY - 40
            
            // Feet must be at or above the candidate top edge (or slightly above when landing)
            if visualFeetY >= candidateTopEdge - 20 {
                // Found highest platform beneath the companion
                return (floorY: candidateTopEdge, isOnWindow: true, platform: candidate)
            }
        }
        
        // 3. Fallback to display screen bottom floor
        return (floorY: screenFloor, isOnWindow: false, platform: nil)
    }
}
