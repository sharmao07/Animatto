import Foundation
import AppKit
import CoreGraphics
import ImageIO

// MARK: - Animation Cache Key
public struct AnimationCacheKey: Hashable, Sendable {
    public let characterId: String
    public let state: String
    public let frameIndex: Int
    
    public init(characterId: String, state: String, frameIndex: Int) {
        self.characterId = characterId
        self.state = state
        self.frameIndex = frameIndex
    }
}

// MARK: - Internal Cache Entry
private struct AnimationCacheEntry {
    let key: AnimationCacheKey
    let image: CGImage
    let cost: Int
    var lastAccessTime: TimeInterval
}

// MARK: - Unified Shared Decoded Frame Cache
public final class AnimationAssetCache: @unchecked Sendable {
    public static let shared = AnimationAssetCache()
    
    private var cache: [AnimationCacheKey: AnimationCacheEntry] = [:]
    private var manifestCache: [URL: AnimationManifest] = [:]
    private var pinnedStates: Set<String> = [] // format: "\(characterId):\(state)"
    
    private var currentCost: Int = 0
    public let maxCostLimit: Int
    private let lock = NSRecursiveLock()
    public static let memoryWarningNotification = Notification.Name("AnimattoDidReceiveMemoryWarningNotification")
    private var memoryPressureSource: (any DispatchSourceMemoryPressure)?
    private var memoryPressureObserver: NSObjectProtocol?
    
    public init(maxCostLimit: Int = 32 * 1024 * 1024) { // Default: 32 MB
        self.maxCostLimit = maxCostLimit
        
        // 1. Dispatch memory pressure source (macOS kernel warning & critical events)
        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: DispatchQueue.global(qos: .utility)
        )
        source.setEventHandler { [weak self] in
            self?.handleMemoryWarning()
        }
        source.resume()
        self.memoryPressureSource = source
        
        // 2. NotificationCenter observer for testability and simulated memory warnings
        self.memoryPressureObserver = NotificationCenter.default.addObserver(
            forName: Self.memoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    deinit {
        memoryPressureSource?.cancel()
        if let observer = memoryPressureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Directory Inspection Helper
    public static func isAnimationDirectory(url: URL) -> Bool {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            return false
        }
        let manifestURL = url.appendingPathComponent("manifest.json")
        return FileManager.default.fileExists(atPath: manifestURL.path)
    }
    
    // MARK: - Manifest Resolution & Caching
    public func manifest(for directoryURL: URL) throws -> AnimationManifest {
        lock.lock()
        defer { lock.unlock() }
        
        if let cached = manifestCache[directoryURL] {
            return cached
        }
        
        let loaded = try AnimationManifest.load(from: directoryURL)
        manifestCache[directoryURL] = loaded
        return loaded
    }
    
    // MARK: - State Pinning
    public func pinState(characterId: String, state: String) {
        lock.lock()
        defer { lock.unlock() }
        pinnedStates.insert("\(characterId):\(state)")
    }
    
    public func unpinState(characterId: String, state: String) {
        lock.lock()
        defer { lock.unlock() }
        pinnedStates.remove("\(characterId):\(state)")
    }
    
    public func isStatePinned(characterId: String, state: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return pinnedStates.contains("\(characterId):\(state)")
    }
    
    // MARK: - Frame Retrieval
    public func frame(key: AnimationCacheKey) -> CGImage? {
        lock.lock()
        defer { lock.unlock() }
        
        guard var entry = cache[key] else { return nil }
        entry.lastAccessTime = CACurrentMediaTime()
        cache[key] = entry
        return entry.image
    }
    
    public func frame(for directoryURL: URL, state: String, frameIndex: Int) -> CGImage? {
        lock.lock()
        
        // Fast path: manifest cached and frame cached
        if let manifest = manifestCache[directoryURL] {
            let key = AnimationCacheKey(characterId: manifest.characterId, state: state, frameIndex: frameIndex)
            if let existing = cache[key] {
                var updated = existing
                updated.lastAccessTime = CACurrentMediaTime()
                cache[key] = updated
                lock.unlock()
                return existing.image
            }
        }
        lock.unlock()
        
        // Slow path: load manifest if needed, decode on demand
        do {
            let manifest = try self.manifest(for: directoryURL)
            guard let stateConfig = manifest.states[state] else {
                return nil
            }
            guard frameIndex >= 0 && frameIndex < stateConfig.frameCount else {
                return nil
            }
            
            let folderURL = directoryURL.appendingPathComponent(stateConfig.folder)
            let filename = String(format: "%@_%02d.png", state, frameIndex)
            let frameURL = folderURL.appendingPathComponent(filename)
            let key = AnimationCacheKey(characterId: manifest.characterId, state: state, frameIndex: frameIndex)
            
            return try loadAndCacheFrame(key: key, fileURL: frameURL)
        } catch {
            return nil
        }
    }
    
    // MARK: - Frame Decoding & Insertion
    @discardableResult
    public func loadAndCacheFrame(key: AnimationCacheKey, fileURL: URL) throws -> CGImage {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw AnimationAssetError.frameFileNotFound(fileURL)
        }
        
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            throw AnimationAssetError.frameDecodingFailed(fileURL)
        }
        
        // Immediate hardware surface decode into raw RGBA bitmap
        let options: [CFString: Any] = [
            kCGImageSourceShouldCacheImmediately: true
        ]
        
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
            throw AnimationAssetError.frameDecodingFailed(fileURL)
        }
        
        lock.lock()
        defer { lock.unlock() }
        
        // Calculate cost in bytes
        let cost = image.bytesPerRow > 0 ? (image.bytesPerRow * image.height) : (image.width * image.height * 4)
        
        // If updating existing entry, adjust cost
        if let old = cache[key] {
            currentCost -= old.cost
        }
        
        let entry = AnimationCacheEntry(
            key: key,
            image: image,
            cost: cost,
            lastAccessTime: CACurrentMediaTime()
        )
        
        cache[key] = entry
        currentCost += cost
        
        trimToCostLimit()
        
        return image
    }
    
    // MARK: - Eviction & Trimming
    public func trimToCostLimit() {
        // Must be called with lock held or acquires it
        // Check if cost exceeded
        guard currentCost > maxCostLimit else { return }
        
        // Collect unpinned candidates sorted by oldest access
        let candidates = cache.values
            .filter { !isPinned(key: $0.key) }
            .sorted { $0.lastAccessTime < $1.lastAccessTime }
        
        for entry in candidates {
            if currentCost <= maxCostLimit { break }
            cache.removeValue(forKey: entry.key)
            currentCost -= entry.cost
        }
    }
    
    public func handleMemoryWarning() {
        lock.lock()
        defer { lock.unlock() }
        
        // Under memory warning, evict ALL unpinned frames
        let unpinnedKeys = cache.values.filter { !isPinned(key: $0.key) }.map { $0.key }
        for key in unpinnedKeys {
            if let entry = cache.removeValue(forKey: key) {
                currentCost -= entry.cost
            }
        }
    }
    
    private func isPinned(key: AnimationCacheKey) -> Bool {
        return pinnedStates.contains("\(key.characterId):\(key.state)")
    }
    
    // MARK: - Asynchronous Preloading
    public func preloadAllFrames(from directoryURL: URL) async throws -> AnimationManifest {
        let manifest = try self.manifest(for: directoryURL)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (stateName, stateConfig) in manifest.states {
                let folderURL = directoryURL.appendingPathComponent(stateConfig.folder)
                for frameIndex in 0..<stateConfig.frameCount {
                    let filename = String(format: "%@_%02d.png", stateName, frameIndex)
                    let frameURL = folderURL.appendingPathComponent(filename)
                    let key = AnimationCacheKey(characterId: manifest.characterId, state: stateName, frameIndex: frameIndex)
                    
                    group.addTask { [weak self] in
                        guard let self = self else { return }
                        _ = try self.loadAndCacheFrame(key: key, fileURL: frameURL)
                    }
                }
            }
            try await group.waitForAll()
        }
        
        return manifest
    }
    
    public func preloadState(characterId: String, state: String, from directoryURL: URL) async throws {
        let manifest = try self.manifest(for: directoryURL)
        guard manifest.characterId == characterId else {
            throw AnimationAssetError.manifestInvalid("Character ID mismatch: expected \(characterId), got \(manifest.characterId)")
        }
        guard let stateConfig = manifest.states[state] else {
            throw AnimationAssetError.stateNotFound(state)
        }
        
        let folderURL = directoryURL.appendingPathComponent(stateConfig.folder)
        for frameIndex in 0..<stateConfig.frameCount {
            let filename = String(format: "%@_%02d.png", state, frameIndex)
            let frameURL = folderURL.appendingPathComponent(filename)
            let key = AnimationCacheKey(characterId: characterId, state: state, frameIndex: frameIndex)
            _ = try loadAndCacheFrame(key: key, fileURL: frameURL)
        }
    }
    
    // MARK: - Inspection & Telemetry
    public var cachedFrameCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.count
    }
    
    public var currentCostInBytes: Int {
        lock.lock()
        defer { lock.unlock() }
        return currentCost
    }
    
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
        manifestCache.removeAll()
        pinnedStates.removeAll()
        currentCost = 0
    }
}
