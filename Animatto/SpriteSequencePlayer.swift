import Foundation
import SwiftUI
import AppKit
import CoreGraphics
import Combine

// MARK: - Sprite Sequence Player
public final class SpriteSequencePlayer: ObservableObject, @unchecked Sendable {
    // Observable playback states
    @Published public private(set) var currentState: String
    @Published public private(set) var currentFrameIndex: Int
    @Published public private(set) var currentFrame: CGImage?
    @Published public private(set) var isPlaying: Bool
    @Published public private(set) var hasError: Bool
    @Published public private(set) var lastError: String?
    
    // Core parameters
    public let characterId: String
    public let directoryURL: URL
    public let manifest: AnimationManifest
    public let cache: AnimationAssetCache
    
    // Callbacks & Triggers
    public var onOneShotComplete: ((_ completedState: String) -> Void)?
    public var onFrameChange: ((_ state: String, _ frameIndex: Int) -> Void)?
    public var onFootstep: ((_ frameIndex: Int) -> Void)?
    
    // Timing & synchronization
    private var elapsedTimeInCurrentFrame: TimeInterval = 0.0
    private var playbackTimer: Timer?
    private let lock = NSRecursiveLock()
    
    // MARK: - Initializer
    public init(
        directoryURL: URL,
        cache: AnimationAssetCache = .shared,
        initialState: String? = nil
    ) throws {
        self.directoryURL = directoryURL
        self.cache = cache
        
        // 1. Resolve manifest
        let resolvedManifest: AnimationManifest
        do {
            resolvedManifest = try cache.manifest(for: directoryURL)
        } catch {
            self.characterId = "unknown"
            self.manifest = AnimationManifest(
                characterId: "unknown",
                version: "1.0.0",
                name: "Fallback",
                canvasSize: AnimationCanvasSize(width: 256, height: 256),
                states: [:]
            )
            self.currentState = "idle"
            self.currentFrameIndex = 0
            self.currentFrame = nil
            self.isPlaying = false
            self.hasError = true
            self.lastError = error.localizedDescription
            throw error
        }
        
        self.manifest = resolvedManifest
        self.characterId = resolvedManifest.characterId
        
        // 2. Select initial state
        let targetState: String
        if let requested = initialState, resolvedManifest.states[requested] != nil {
            targetState = requested
        } else if resolvedManifest.states["idle"] != nil {
            targetState = "idle"
        } else if let firstState = resolvedManifest.states.keys.sorted().first {
            targetState = firstState
        } else {
            self.currentState = "none"
            self.currentFrameIndex = 0
            self.currentFrame = nil
            self.isPlaying = false
            self.hasError = true
            self.lastError = "Manifest contains zero defined animation states."
            throw AnimationAssetError.manifestInvalid(lastError!)
        }
        
        self.currentState = targetState
        self.currentFrameIndex = 0
        self.hasError = false
        self.lastError = nil
        self.isPlaying = true
        
        // 3. Pin initial state in cache to protect it from memory eviction
        cache.pinState(characterId: resolvedManifest.characterId, state: targetState)
        
        // 4. Load initial frame (frame 0)
        let initialImage = cache.frame(for: directoryURL, state: targetState, frameIndex: 0)
        self.currentFrame = initialImage
        if initialImage == nil {
            self.hasError = true
            self.lastError = "Failed to load initial frame for state: \(targetState)"
        }
    }
    
    deinit {
        stopPlaybackTimer()
        cache.unpinState(characterId: characterId, state: currentState)
    }
    
    // MARK: - State Transitions
    public func transition(to newState: String, resetFrameIndex: Bool = true) {
        lock.lock()
        defer { lock.unlock() }
        
        guard newState != currentState || resetFrameIndex else { return }
        
        guard let config = manifest.states[newState] else {
            hasError = true
            lastError = "Cannot transition: state '\(newState)' not defined."
            return
        }
        
        // Unpin previous state, pin newly active state
        cache.unpinState(characterId: characterId, state: currentState)
        cache.pinState(characterId: characterId, state: newState)
        
        currentState = newState
        if resetFrameIndex {
            currentFrameIndex = 0
            elapsedTimeInCurrentFrame = 0.0
        } else if currentFrameIndex >= config.frameCount {
            currentFrameIndex = max(0, config.frameCount - 1)
            elapsedTimeInCurrentFrame = 0.0
        }
        
        updateFrame()
        isPlaying = true
        hasError = false
        lastError = nil
        
        onFrameChange?(currentState, currentFrameIndex)
        
        // Check footstep trigger on frame 0
        if let footsteps = config.footstepFrames, footsteps.contains(currentFrameIndex) {
            onFootstep?(currentFrameIndex)
        }
    }
    
    // MARK: - Frame Stepping & Delta Time Advancement
    public func advance(by deltaTime: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        
        guard isPlaying, !hasError else { return }
        guard deltaTime > 0 else { return }
        guard let config = manifest.states[currentState], config.frameCount > 0 else { return }
        
        let frameDuration = config.frameDuration
        guard frameDuration > 0 else { return }
        
        elapsedTimeInCurrentFrame += deltaTime
        
        let epsilon: TimeInterval = 0.0001
        while elapsedTimeInCurrentFrame >= (frameDuration - epsilon) {
            elapsedTimeInCurrentFrame = max(0.0, elapsedTimeInCurrentFrame - frameDuration)
            
            let nextIndex = currentFrameIndex + 1
            if nextIndex < config.frameCount {
                currentFrameIndex = nextIndex
                updateFrame()
                onFrameChange?(currentState, currentFrameIndex)
                
                if let footsteps = config.footstepFrames, footsteps.contains(currentFrameIndex) {
                    onFootstep?(currentFrameIndex)
                }
            } else {
                // Reached sequence end
                if config.loop {
                    currentFrameIndex = 0
                    updateFrame()
                    onFrameChange?(currentState, currentFrameIndex)
                    
                    if let footsteps = config.footstepFrames, footsteps.contains(currentFrameIndex) {
                        onFootstep?(currentFrameIndex)
                    }
                } else {
                    // One-shot state completed
                    let completedState = currentState
                    onOneShotComplete?(completedState)
                    
                    if let nextState = config.nextState, manifest.states[nextState] != nil {
                        // Auto-transition to nextState
                        transition(to: nextState, resetFrameIndex: true)
                        return
                    } else {
                        // Hold on last frame and stop advancing
                        elapsedTimeInCurrentFrame = 0.0
                        isPlaying = false
                        return
                    }
                }
            }
        }
    }
    
    private func updateFrame() {
        if let image = cache.frame(for: directoryURL, state: currentState, frameIndex: currentFrameIndex) {
            currentFrame = image
            hasError = false
        } else {
            hasError = true
            lastError = "Missing frame \(currentFrameIndex) for state '\(currentState)'."
        }
    }
    
    // MARK: - Playback Controls
    public func play() {
        lock.lock()
        defer { lock.unlock() }
        isPlaying = true
    }
    
    public func pause() {
        lock.lock()
        defer { lock.unlock() }
        isPlaying = false
    }
    
    public func stop() {
        lock.lock()
        defer { lock.unlock() }
        isPlaying = false
        currentFrameIndex = 0
        elapsedTimeInCurrentFrame = 0.0
        updateFrame()
    }
    
    // MARK: - Timer-Driven Playback
    public func startPlayback(fps: Double = 60.0) {
        stopPlaybackTimer()
        let interval = max(0.008, 1.0 / fps)
        var lastTime = CACurrentMediaTime()
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = CACurrentMediaTime()
            let dt = min(now - lastTime, 0.1) // Clamp dt to prevent spiral of death
            lastTime = now
            self.advance(by: dt)
        }
    }
    
    public func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

// MARK: - SwiftUI Sprite Sequence Player View
public struct SpriteSequencePlayerView: View {
    public let directoryURL: URL
    public var fallbackImageURL: URL?
    
    @StateObject private var playerHolder: PlayerHolder
    
    public init(directoryURL: URL, fallbackImageURL: URL? = nil) {
        self.directoryURL = directoryURL
        self.fallbackImageURL = fallbackImageURL
        _playerHolder = StateObject(wrappedValue: PlayerHolder(directoryURL: directoryURL, fallbackURL: fallbackImageURL))
    }
    
    public var body: some View {
        Group {
            if let player = playerHolder.player, !player.hasError, let cgImage = player.currentFrame {
                Image(decorative: cgImage, scale: 1.0)
                    .resizable()
                    .interpolation(.high)
            } else if let fallback = resolvedFallbackURL {
                NativeImageView(url: fallback)
            } else {
                Color.clear
            }
        }
        .onAppear {
            playerHolder.player?.startPlayback()
        }
        .onDisappear {
            playerHolder.player?.stopPlaybackTimer()
        }
    }
    
    private var resolvedFallbackURL: URL? {
        if let fallback = fallbackImageURL {
            return fallback
        }
        if let manifest = try? AnimationAssetCache.shared.manifest(for: directoryURL),
           let master = manifest.masterArtwork {
            let candidateSameDir = directoryURL.appendingPathComponent(master)
            if FileManager.default.fileExists(atPath: candidateSameDir.path) {
                return candidateSameDir
            }
            let candidateParentDir = directoryURL.deletingLastPathComponent().appendingPathComponent(master)
            if FileManager.default.fileExists(atPath: candidateParentDir.path) {
                return candidateParentDir
            }
        }
        return nil
    }
}

// MARK: - Player Holder Helper
private final class PlayerHolder: ObservableObject {
    @Published var player: SpriteSequencePlayer?
    
    init(directoryURL: URL, fallbackURL: URL?) {
        do {
            self.player = try SpriteSequencePlayer(directoryURL: directoryURL)
        } catch {
            print("SpriteSequencePlayer initialization fallback: \(error.localizedDescription)")
            self.player = nil
        }
    }
}
