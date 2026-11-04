import Foundation
import AppKit
import CoreGraphics
import ImageIO

// MARK: - Animation Cache Key
public nonisolated struct AnimationCacheKey: Hashable, Sendable {
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

// MARK: - In-Flight Decode Record
private final class InFlightDecode {
    let condition = NSCondition()
    var isComplete = false
    var result: Result<CGImage, Error>?
}

// MARK: - Cache Budget Status
public enum CacheBudgetStatus: Equatable, Sendable, CustomStringConvertible {
    case withinBudget(usageBytes: Int, limitBytes: Int)
    case overBudgetPinnedExceedsLimit(pinnedBytes: Int, limitBytes: Int, excessBytes: Int)
    case overBudgetUnpinnedEligible(usageBytes: Int, limitBytes: Int)
    
    public var description: String {
        switch self {
        case .withinBudget(let usage, let limit):
            return "Within budget: \(usage) / \(limit) bytes (\(String(format: "%.1f", Double(usage)/1024.0/1024.0)) MB / \(String(format: "%.1f", Double(limit)/1024.0/1024.0)) MB)"
        case .overBudgetPinnedExceedsLimit(let pinned, let limit, let excess):
            return "Over budget (pinned frames exceed limit): pinned \(pinned) bytes exceeds limit \(limit) bytes by \(excess) bytes. Active frames preserved."
        case .overBudgetUnpinnedEligible(let usage, let limit):
            return "Over budget (unpinned frames eligible for trim): usage \(usage) bytes exceeds limit \(limit) bytes."
        }
    }
}

// MARK: - Unified Shared Decoded Frame Cache
public nonisolated final class AnimationAssetCache: @unchecked Sendable {
    public static let shared = AnimationAssetCache()
    
    private var cache: [AnimationCacheKey: AnimationCacheEntry] = [:]
    private var manifestCache: [URL: AnimationManifest] = [:]
    private var pinnedStates: Set<String> = [] // format: "\(characterId):\(state)"
    private var inFlightLoads: [AnimationCacheKey: InFlightDecode] = [:]
    
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
    
    /// Resolves an animation directory either from a directory URL or a companion asset file URL
    public static func resolveAnimationDirectory(for url: URL) -> URL? {
        if isAnimationDirectory(url: url) {
            return url
        }
        // Check sibling "Cat" directory if pointing to animatto_cat.png
        let siblingCat = url.deletingLastPathComponent().appendingPathComponent("Cat")
        if isAnimationDirectory(url: siblingCat) {
            return siblingCat
        }
        // Check child "DefaultCompanions/Cat" directory if url is at resources root
        let defaultCompanionsCat = url.deletingLastPathComponent().appendingPathComponent("DefaultCompanions/Cat")
        if isAnimationDirectory(url: defaultCompanionsCat) {
            return defaultCompanionsCat
        }
        // Check if parent directory contains manifest.json
        let parentDir = url.deletingLastPathComponent()
        if isAnimationDirectory(url: parentDir) {
            return parentDir
        }
        return nil
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
    
    // MARK: - Frame Decoding & Insertion (Thread-Safe In-Flight Deduplication)
    @discardableResult
    public func loadAndCacheFrame(key: AnimationCacheKey, fileURL: URL) throws -> CGImage {
        lock.lock()
        
        // 1. Check if already decoded and cached
        if var existing = cache[key] {
            existing.lastAccessTime = CACurrentMediaTime()
            cache[key] = existing
            lock.unlock()
            return existing.image
        }
        
        // 2. Check if another concurrent thread is already decoding this exact key
        if let inFlight = inFlightLoads[key] {
            lock.unlock()
            
            // Wait for in-flight decode to complete without holding the cache lock
            inFlight.condition.lock()
            while !inFlight.isComplete {
                inFlight.condition.wait()
            }
            let res = inFlight.result
            inFlight.condition.unlock()
            
            switch res {
            case .success(let image):
                return image
            case .failure(let error):
                throw error
            case .none:
                throw AnimationAssetError.frameDecodingFailed(fileURL)
            }
        }
        
        // 3. Register ourselves as the single in-flight decoder for this key
        let inFlight = InFlightDecode()
        inFlightLoads[key] = inFlight
        lock.unlock()
        
        // 4. Decode the image outside the cache lock so concurrent operations on other keys are not blocked
        let decodeResult: Result<CGImage, Error>
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw AnimationAssetError.frameFileNotFound(fileURL)
            }
            
            guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
                throw AnimationAssetError.frameDecodingFailed(fileURL)
            }
            
            let options: [CFString: Any] = [
                kCGImageSourceShouldCacheImmediately: true
            ]
            
            guard let image = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
                throw AnimationAssetError.frameDecodingFailed(fileURL)
            }
            decodeResult = .success(image)
        } catch {
            decodeResult = .failure(error)
        }
        
        // 5. Store result under lock and notify all waiters
        lock.lock()
        inFlightLoads.removeValue(forKey: key)
        
        switch decodeResult {
        case .success(let image):
            let cost = image.bytesPerRow > 0 ? (image.bytesPerRow * image.height) : (image.width * image.height * 4)
            
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
            
            performTrimToCostLimit()
            lock.unlock()
            
            // Broadcast success to any callers that were waiting for this key
            inFlight.condition.lock()
            inFlight.result = .success(image)
            inFlight.isComplete = true
            inFlight.condition.broadcast()
            inFlight.condition.unlock()
            
            return image
            
        case .failure(let error):
            lock.unlock()
            
            // Broadcast failure to any waiting callers
            inFlight.condition.lock()
            inFlight.result = .failure(error)
            inFlight.isComplete = true
            inFlight.condition.broadcast()
            inFlight.condition.unlock()
            
            throw error
        }
    }
    
    // MARK: - Eviction & Trimming
    public func trimToCostLimit() {
        lock.lock()
        defer { lock.unlock() }
        performTrimToCostLimit()
    }
    
    private func performTrimToCostLimit() {
        // Must be called with lock held
        guard currentCost > maxCostLimit else { return }
        
        // Collect unpinned candidates sorted by oldest access (LRU)
        let candidates = cache.values
            .filter { !isPinned(key: $0.key) }
            .sorted { $0.lastAccessTime < $1.lastAccessTime }
        
        for entry in candidates {
            if currentCost <= maxCostLimit { break }
            cache.removeValue(forKey: entry.key)
            currentCost -= entry.cost
        }
        
        // Documented Memory-Budget Policy:
        // Pinned states represent active working-set frames (e.g. current animations being rendered on screen)
        // and are never forcibly discarded during trim while actively pinned. If pinned frames alone exceed
        // maxCostLimit, all unpinned frames are evicted down to 0, and the cache explicitly enters the
        // over-budget state (isOverBudget == true, budgetStatus == .overBudgetPinnedExceedsLimit).
        // The cache truthfully reports its actual memory consumption (currentCostInBytes), never falsely
        // claiming compliance. Once states are unpinned, subsequent trims reclaim memory down to budget.
    }
    
    public func handleMemoryWarning() {
        lock.lock()
        defer { lock.unlock() }
        
        // Under memory warning, immediately evict ALL unpinned frames
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
    
    // MARK: - Memory Budget Inspection
    public var isOverBudget: Bool {
        lock.lock()
        defer { lock.unlock() }
        return currentCost > maxCostLimit
    }
    
    public var pinnedCostInBytes: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.values
            .filter { isPinned(key: $0.key) }
            .reduce(0) { $0 + $1.cost }
    }
    
    public var unpinnedCostInBytes: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.values
            .filter { !isPinned(key: $0.key) }
            .reduce(0) { $0 + $1.cost }
    }
    
    public var budgetStatus: CacheBudgetStatus {
        lock.lock()
        defer { lock.unlock() }
        if currentCost <= maxCostLimit {
            return .withinBudget(usageBytes: currentCost, limitBytes: maxCostLimit)
        }
        let pinnedCost = cache.values
            .filter { isPinned(key: $0.key) }
            .reduce(0) { $0 + $1.cost }
        if pinnedCost > maxCostLimit {
            return .overBudgetPinnedExceedsLimit(
                pinnedBytes: pinnedCost,
                limitBytes: maxCostLimit,
                excessBytes: currentCost - maxCostLimit
            )
        } else {
            return .overBudgetUnpinnedEligible(
                usageBytes: currentCost,
                limitBytes: maxCostLimit
            )
        }
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
