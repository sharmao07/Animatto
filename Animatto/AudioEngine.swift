import Foundation
import AVFoundation
import AppKit
import Combine

// MARK: - Audio Ambient Type
public enum AudioAmbientType: String, CaseIterable, Identifiable, Codable {
    case rainThunder = "Rain & Thunder"
    case forestBirdsong = "Forest & Birdsong"
    case winterWind = "Winter Wind"
    
    public var id: String { rawValue }
    
    public var assetName: String {
        switch self {
        case .rainThunder: return "ambient_rain_thunder"
        case .forestBirdsong: return "ambient_forest_birdsong"
        case .winterWind: return "ambient_winter_wind"
        }
    }
}

// MARK: - Companion Vocalization Type
public enum CompanionVocalizationType: String, CaseIterable {
    case happy = "Happy"
    case curious = "Curious"
    case sleepy = "Sleepy"
    
    public var assetName: String {
        switch self {
        case .happy: return "companion_voice_happy"
        case .curious: return "companion_voice_curious"
        case .sleepy: return "companion_voice_sleepy"
        }
    }
}

// MARK: - UI Sound Effect Type
public enum UISoundType: String, CaseIterable {
    case click = "Click"
    case select = "Select"
    case toggle = "Toggle"
    
    public var assetName: String {
        switch self {
        case .click: return "ui_click"
        case .select: return "ui_select"
        case .toggle: return "ui_toggle"
        }
    }
}

// MARK: - Audio Settings Manager
public class AudioSettings: ObservableObject {
    public static let shared = AudioSettings()
    
    private let defaults = UserDefaults.standard
    private let prefix = "com.dev.Animatto.audio."
    
    // Master controls
    @Published public var isMasterMuted: Bool {
        didSet { defaults.set(isMasterMuted, forKey: prefix + "isMasterMuted") }
    }
    @Published public var masterVolume: Double {
        didSet { defaults.set(masterVolume, forKey: prefix + "masterVolume") }
    }
    
    // Ambient Category & Sub-types
    @Published public var ambientEnabled: Bool {
        didSet { defaults.set(ambientEnabled, forKey: prefix + "ambientEnabled") }
    }
    @Published public var ambientVolume: Double {
        didSet { defaults.set(ambientVolume, forKey: prefix + "ambientVolume") }
    }
    @Published public var rainThunderEnabled: Bool {
        didSet { defaults.set(rainThunderEnabled, forKey: prefix + "rainThunderEnabled") }
    }
    @Published public var rainThunderVolume: Double {
        didSet { defaults.set(rainThunderVolume, forKey: prefix + "rainThunderVolume") }
    }
    @Published public var forestBirdsongEnabled: Bool {
        didSet { defaults.set(forestBirdsongEnabled, forKey: prefix + "forestBirdsongEnabled") }
    }
    @Published public var forestBirdsongVolume: Double {
        didSet { defaults.set(forestBirdsongVolume, forKey: prefix + "forestBirdsongVolume") }
    }
    @Published public var winterWindEnabled: Bool {
        didSet { defaults.set(winterWindEnabled, forKey: prefix + "winterWindEnabled") }
    }
    @Published public var winterWindVolume: Double {
        didSet { defaults.set(winterWindVolume, forKey: prefix + "winterWindVolume") }
    }
    
    // Character Audio
    @Published public var footstepsEnabled: Bool {
        didSet { defaults.set(footstepsEnabled, forKey: prefix + "footstepsEnabled") }
    }
    @Published public var footstepsVolume: Double {
        didSet { defaults.set(footstepsVolume, forKey: prefix + "footstepsVolume") }
    }
    @Published public var sleepSoundsEnabled: Bool {
        didSet { defaults.set(sleepSoundsEnabled, forKey: prefix + "sleepSoundsEnabled") }
    }
    @Published public var sleepSoundsVolume: Double {
        didSet { defaults.set(sleepSoundsVolume, forKey: prefix + "sleepSoundsVolume") }
    }
    @Published public var companionVoicesEnabled: Bool {
        didSet { defaults.set(companionVoicesEnabled, forKey: prefix + "companionVoicesEnabled") }
    }
    @Published public var companionVoicesVolume: Double {
        didSet { defaults.set(companionVoicesVolume, forKey: prefix + "companionVoicesVolume") }
    }
    
    // UI Audio
    @Published public var uiSoundsEnabled: Bool {
        didSet { defaults.set(uiSoundsEnabled, forKey: prefix + "uiSoundsEnabled") }
    }
    @Published public var uiSoundsVolume: Double {
        didSet { defaults.set(uiSoundsVolume, forKey: prefix + "uiSoundsVolume") }
    }
    
    public init() {
        let d = defaults
        let p = prefix
        
        self.isMasterMuted = d.object(forKey: p + "isMasterMuted") as? Bool ?? false
        self.masterVolume = d.object(forKey: p + "masterVolume") as? Double ?? 0.8
        
        self.ambientEnabled = d.object(forKey: p + "ambientEnabled") as? Bool ?? true
        self.ambientVolume = d.object(forKey: p + "ambientVolume") as? Double ?? 0.6
        self.rainThunderEnabled = d.object(forKey: p + "rainThunderEnabled") as? Bool ?? true
        self.rainThunderVolume = d.object(forKey: p + "rainThunderVolume") as? Double ?? 0.7
        self.forestBirdsongEnabled = d.object(forKey: p + "forestBirdsongEnabled") as? Bool ?? true
        self.forestBirdsongVolume = d.object(forKey: p + "forestBirdsongVolume") as? Double ?? 0.7
        self.winterWindEnabled = d.object(forKey: p + "winterWindEnabled") as? Bool ?? true
        self.winterWindVolume = d.object(forKey: p + "winterWindVolume") as? Double ?? 0.7
        
        self.footstepsEnabled = d.object(forKey: p + "footstepsEnabled") as? Bool ?? true
        self.footstepsVolume = d.object(forKey: p + "footstepsVolume") as? Double ?? 0.5
        self.sleepSoundsEnabled = d.object(forKey: p + "sleepSoundsEnabled") as? Bool ?? true
        self.sleepSoundsVolume = d.object(forKey: p + "sleepSoundsVolume") as? Double ?? 0.5
        self.companionVoicesEnabled = d.object(forKey: p + "companionVoicesEnabled") as? Bool ?? true
        self.companionVoicesVolume = d.object(forKey: p + "companionVoicesVolume") as? Double ?? 0.6
        
        self.uiSoundsEnabled = d.object(forKey: p + "uiSoundsEnabled") as? Bool ?? true
        self.uiSoundsVolume = d.object(forKey: p + "uiSoundsVolume") as? Double ?? 0.5
    }
    
    public func resetToDefaults() {
        isMasterMuted = false
        masterVolume = 0.8
        
        ambientEnabled = true
        ambientVolume = 0.6
        rainThunderEnabled = true
        rainThunderVolume = 0.7
        forestBirdsongEnabled = true
        forestBirdsongVolume = 0.7
        winterWindEnabled = true
        winterWindVolume = 0.7
        
        footstepsEnabled = true
        footstepsVolume = 0.5
        sleepSoundsEnabled = true
        sleepSoundsVolume = 0.5
        companionVoicesEnabled = true
        companionVoicesVolume = 0.6
        
        uiSoundsEnabled = true
        uiSoundsVolume = 0.5
    }
}

// MARK: - Central Audio Engine
public class AudioEngine: ObservableObject {
    public static let shared = AudioEngine()
    
    public let settings: AudioSettings
    
    // Active players
    private var ambientPlayer: AVAudioPlayer?
    private var currentAmbientType: AudioAmbientType?
    
    // Character sleep loops keyed by pet UUID string
    private var sleepPlayers: [String: AVAudioPlayer] = [:]
    
    // Player cache for UI & sound effects
    private var soundEffectPlayers: [String: AVAudioPlayer] = [:]
    
    // Rate limiting & anti-spam timestamps
    private var lastFootstepTime: TimeInterval = 0
    private var lastVoiceTime: TimeInterval = 0
    private var lastUITime: TimeInterval = 0
    
    public init(settings: AudioSettings = .shared) {
        self.settings = settings
    }
    
    // MARK: - Asset Resolution
    
    public func resolveAudioURL(named name: String) -> URL? {
        // 1. Bundle resource directly
        if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Audio") {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Resources/Audio") {
            return url
        }
        
        // 2. Relative development path fallback
        let fileManager = FileManager.default
        let possibleDirs = [
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Audio"),
            URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent("Animatto/Resources/Audio"),
            URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent("Resources/Audio")
        ]
        
        for dir in possibleDirs {
            let candidate = dir.appendingPathComponent("\(name).wav")
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        
        return nil
    }
    
    private func getOrCreatePlayer(for assetName: String) -> AVAudioPlayer? {
        if let player = soundEffectPlayers[assetName] {
            return player
        }
        guard let url = resolveAudioURL(named: assetName) else { return nil }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            soundEffectPlayers[assetName] = player
            return player
        } catch {
            print("Failed to initialize AVAudioPlayer for \(assetName): \(error)")
            return nil
        }
    }
    
    // MARK: - Ambient Audio Playback
    
    public func setAmbientEnvironment(_ type: AudioAmbientType?) {
        guard let type = type else {
            stopAmbient()
            return
        }
        
        if currentAmbientType == type && ambientPlayer?.isPlaying == true {
            updateAmbientVolume()
            return
        }
        
        currentAmbientType = type
        startAmbient(type: type)
    }
    
    private func startAmbient(type: AudioAmbientType) {
        guard !settings.isMasterMuted, settings.ambientEnabled else {
            ambientPlayer?.pause()
            return
        }
        
        let typeEnabled: Bool
        let typeVolume: Double
        switch type {
        case .rainThunder:
            typeEnabled = settings.rainThunderEnabled
            typeVolume = settings.rainThunderVolume
        case .forestBirdsong:
            typeEnabled = settings.forestBirdsongEnabled
            typeVolume = settings.forestBirdsongVolume
        case .winterWind:
            typeEnabled = settings.winterWindEnabled
            typeVolume = settings.winterWindVolume
        }
        
        guard typeEnabled else {
            ambientPlayer?.pause()
            return
        }
        
        guard let url = resolveAudioURL(named: type.assetName) else {
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // Seamless continuous loop
            let effectiveVolume = Float(settings.masterVolume * settings.ambientVolume * typeVolume)
            player.volume = max(0.0, min(1.0, effectiveVolume))
            player.prepareToPlay()
            player.play()
            
            ambientPlayer?.stop()
            ambientPlayer = player
        } catch {
            print("AudioEngine: Failed to start ambient audio for \(type): \(error)")
        }
    }
    
    public func updateAmbientVolume() {
        guard let current = currentAmbientType, let player = ambientPlayer else { return }
        
        let isMutedOrDisabled = settings.isMasterMuted || !settings.ambientEnabled
        let (typeEnabled, typeVolume): (Bool, Double) = {
            switch current {
            case .rainThunder: return (settings.rainThunderEnabled, settings.rainThunderVolume)
            case .forestBirdsong: return (settings.forestBirdsongEnabled, settings.forestBirdsongVolume)
            case .winterWind: return (settings.winterWindEnabled, settings.winterWindVolume)
            }
        }()
        
        if isMutedOrDisabled || !typeEnabled {
            if player.isPlaying {
                player.pause()
            }
        } else {
            let effectiveVolume = Float(settings.masterVolume * settings.ambientVolume * typeVolume)
            player.volume = max(0.0, min(1.0, effectiveVolume))
            if !player.isPlaying {
                player.play()
            }
        }
    }
    
    public func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
        currentAmbientType = nil
    }
    
    // MARK: - Character Audio (Footsteps, Sleep, Vocalizations)
    
    public func playFootstep(petCount: Int = 1) {
        guard !settings.isMasterMuted, settings.footstepsEnabled else { return }
        let now = Date().timeIntervalSince1970
        // Throttle footsteps: minimum 140ms between footsteps to avoid chaotic noise
        guard now - lastFootstepTime >= 0.14 else { return }
        lastFootstepTime = now
        
        // Volume ducking for multi-pet scaling
        let duckingFactor = 1.0 / sqrt(Double(max(1, petCount)))
        let effectiveVolume = Float(settings.masterVolume * settings.footstepsVolume * duckingFactor)
        
        playOneShot(named: "character_footstep", volume: effectiveVolume)
    }
    
    public func startSleepSound(forPetId petId: String, totalSleepingPets: Int = 1) {
        guard !settings.isMasterMuted, settings.sleepSoundsEnabled else {
            stopSleepSound(forPetId: petId)
            return
        }
        
        if let existing = sleepPlayers[petId], existing.isPlaying {
            let duckingFactor = 1.0 / sqrt(Double(max(1, totalSleepingPets)))
            existing.volume = Float(max(0.0, min(1.0, settings.masterVolume * settings.sleepSoundsVolume * duckingFactor)))
            return
        }
        
        guard let url = resolveAudioURL(named: "character_sleep_purr") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            let duckingFactor = 1.0 / sqrt(Double(max(1, totalSleepingPets)))
            player.volume = Float(max(0.0, min(1.0, settings.masterVolume * settings.sleepSoundsVolume * duckingFactor)))
            player.prepareToPlay()
            player.play()
            sleepPlayers[petId] = player
        } catch {
            print("AudioEngine: Error playing sleep purr: \(error)")
        }
    }
    
    public func stopSleepSound(forPetId petId: String) {
        if let player = sleepPlayers.removeValue(forKey: petId) {
            player.stop()
        }
    }
    
    public func updateAllSleepVolumes(totalSleepingPets: Int) {
        let isMutedOrDisabled = settings.isMasterMuted || !settings.sleepSoundsEnabled
        let duckingFactor = 1.0 / sqrt(Double(max(1, totalSleepingPets)))
        let volume = Float(max(0.0, min(1.0, settings.masterVolume * settings.sleepSoundsVolume * duckingFactor)))
        
        for (_, player) in sleepPlayers {
            if isMutedOrDisabled {
                player.pause()
            } else {
                player.volume = volume
                if !player.isPlaying {
                    player.play()
                }
            }
        }
    }
    
    public func playCompanionVoice(_ type: CompanionVocalizationType) {
        guard !settings.isMasterMuted, settings.companionVoicesEnabled else { return }
        let now = Date().timeIntervalSince1970
        guard now - lastVoiceTime >= 0.3 else { return } // Rate limit 300ms
        lastVoiceTime = now
        
        let effectiveVolume = Float(settings.masterVolume * settings.companionVoicesVolume)
        playOneShot(named: type.assetName, volume: effectiveVolume)
    }
    
    // MARK: - UI Sounds
    
    public func playUISound(_ type: UISoundType) {
        guard !settings.isMasterMuted, settings.uiSoundsEnabled else { return }
        let now = Date().timeIntervalSince1970
        guard now - lastUITime >= 0.04 else { return } // 40ms rate limit
        lastUITime = now
        
        let effectiveVolume = Float(settings.masterVolume * settings.uiSoundsVolume)
        playOneShot(named: type.assetName, volume: effectiveVolume)
    }
    
    // MARK: - Private One-shot Playback Helper
    
    private func playOneShot(named assetName: String, volume: Float) {
        guard volume > 0.001 else { return }
        
        if let player = getOrCreatePlayer(for: assetName) {
            player.volume = max(0.0, min(1.0, volume))
            if player.isPlaying {
                player.currentTime = 0
            } else {
                player.play()
            }
        }
    }
    
    // MARK: - Cleanup & Battery Conservation
    
    public func cleanupPet(id: String) {
        stopSleepSound(forPetId: id)
    }
    
    public func stopAll() {
        stopAmbient()
        for (_, player) in sleepPlayers {
            player.stop()
        }
        sleepPlayers.removeAll()
        for (_, player) in soundEffectPlayers {
            player.stop()
        }
        soundEffectPlayers.removeAll()
    }
}
