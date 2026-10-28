import Foundation

// MARK: - Personality Preset
public enum PersonalityPreset: String, Codable, CaseIterable, Identifiable {
    case sleepy
    case curious
    case energetic
    case mischievous
    case shy
    case balanced
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .sleepy: return "Sleepy"
        case .curious: return "Curious"
        case .energetic: return "Energetic"
        case .mischievous: return "Mischievous"
        case .shy: return "Shy"
        case .balanced: return "Balanced"
        }
    }
    
    public var iconName: String {
        switch self {
        case .sleepy: return "moon.zzz.fill"
        case .curious: return "magnifyingglass"
        case .energetic: return "bolt.fill"
        case .mischievous: return "sparkles"
        case .shy: return "eye.slash.fill"
        case .balanced: return "circle.hexagongrid.fill"
        }
    }
    
    public var summary: String {
        switch self {
        case .sleepy: return "Prefers resting and naps. Low energy and high laziness."
        case .curious: return "Loves to explore and inspect surroundings when bored."
        case .energetic: return "High movement and playfulness. Rarely stays idle."
        case .mischievous: return "Unpredictable and playful with sudden turns and bursts."
        case .shy: return "Quiet and reserved. Seeks less interaction."
        case .balanced: return "Evenly tempered balance of rest, walking, and curiosity."
        }
    }
}

// MARK: - Personality Profile
public struct PersonalityProfile: Codable, Identifiable, Equatable {
    public var id: UUID
    public var schemaVersion: Int
    public var name: String
    public var preset: PersonalityPreset?
    
    // Core traits normalized 0.0 ... 1.0
    public var energy: Double           // Preference for energetic vs relaxed activity
    public var curiosity: Double        // Tendency to investigate or explore
    public var playfulness: Double      // Tendency to engage in playful behavior
    public var laziness: Double         // Preference for rest and inactivity
    public var sociability: Double      // Tendency to respond to interactions
    public var mischief: Double         // Preference for playful, unpredictable behavior
    public var attentionSeeking: Double // Tendency to seek interaction / approach user
    
    public init(
        id: UUID = UUID(),
        schemaVersion: Int = 1,
        name: String = "Balanced",
        preset: PersonalityPreset? = .balanced,
        energy: Double = 0.5,
        curiosity: Double = 0.5,
        playfulness: Double = 0.5,
        laziness: Double = 0.5,
        sociability: Double = 0.5,
        mischief: Double = 0.5,
        attentionSeeking: Double = 0.5
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.name = name
        self.preset = preset
        self.energy = min(max(energy, 0.0), 1.0)
        self.curiosity = min(max(curiosity, 0.0), 1.0)
        self.playfulness = min(max(playfulness, 0.0), 1.0)
        self.laziness = min(max(laziness, 0.0), 1.0)
        self.sociability = min(max(sociability, 0.0), 1.0)
        self.mischief = min(max(mischief, 0.0), 1.0)
        self.attentionSeeking = min(max(attentionSeeking, 0.0), 1.0)
    }
    
    public func clamped() -> PersonalityProfile {
        var copy = self
        copy.energy = min(max(copy.energy, 0.0), 1.0)
        copy.curiosity = min(max(copy.curiosity, 0.0), 1.0)
        copy.playfulness = min(max(copy.playfulness, 0.0), 1.0)
        copy.laziness = min(max(copy.laziness, 0.0), 1.0)
        copy.sociability = min(max(copy.sociability, 0.0), 1.0)
        copy.mischief = min(max(copy.mischief, 0.0), 1.0)
        copy.attentionSeeking = min(max(copy.attentionSeeking, 0.0), 1.0)
        return copy
    }
    
    public static func preset(_ preset: PersonalityPreset) -> PersonalityProfile {
        switch preset {
        case .sleepy:
            return PersonalityProfile(
                name: "Sleepy",
                preset: .sleepy,
                energy: 0.2,
                curiosity: 0.25,
                playfulness: 0.2,
                laziness: 0.85,
                sociability: 0.3,
                mischief: 0.15,
                attentionSeeking: 0.2
            )
        case .curious:
            return PersonalityProfile(
                name: "Curious",
                preset: .curious,
                energy: 0.6,
                curiosity: 0.9,
                playfulness: 0.5,
                laziness: 0.3,
                sociability: 0.6,
                mischief: 0.4,
                attentionSeeking: 0.5
            )
        case .energetic:
            return PersonalityProfile(
                name: "Energetic",
                preset: .energetic,
                energy: 0.9,
                curiosity: 0.7,
                playfulness: 0.85,
                laziness: 0.15,
                sociability: 0.75,
                mischief: 0.5,
                attentionSeeking: 0.7
            )
        case .mischievous:
            return PersonalityProfile(
                name: "Mischievous",
                preset: .mischievous,
                energy: 0.75,
                curiosity: 0.7,
                playfulness: 0.9,
                laziness: 0.25,
                sociability: 0.6,
                mischief: 0.9,
                attentionSeeking: 0.65
            )
        case .shy:
            return PersonalityProfile(
                name: "Shy",
                preset: .shy,
                energy: 0.35,
                curiosity: 0.4,
                playfulness: 0.3,
                laziness: 0.6,
                sociability: 0.2,
                mischief: 0.1,
                attentionSeeking: 0.15
            )
        case .balanced:
            return PersonalityProfile(
                name: "Balanced",
                preset: .balanced,
                energy: 0.5,
                curiosity: 0.5,
                playfulness: 0.5,
                laziness: 0.5,
                sociability: 0.5,
                mischief: 0.5,
                attentionSeeking: 0.5
            )
        }
    }
}

// MARK: - Character Mood
public enum CharacterMood: String, Codable, CaseIterable {
    case contented
    case playful
    case tired
    case restless
    case bored
    
    public var displayName: String {
        switch self {
        case .contented: return "Contented"
        case .playful: return "Playful"
        case .tired: return "Tired"
        case .restless: return "Restless"
        case .bored: return "Bored"
        }
    }
}

// MARK: - Character Needs
public struct CharacterNeeds: Codable, Equatable {
    // Current internal dynamic levels (0.0 ... 1.0)
    public var energy: Double           // 1.0 = fully energized, 0.0 = exhausted
    public var boredom: Double          // 0.0 = engaged, 1.0 = deeply bored
    public var curiosityDrive: Double   // 0.0 = satisfied, 1.0 = intense desire to explore
    public var socialDrive: Double      // 0.0 = self-sufficient, 1.0 = craving interaction
    public var mood: CharacterMood
    
    // Tuning rates per second (configurable constants)
    public struct Constants {
        public static let energyDepletionRate: Double = 0.015
        public static let energyRecoveryRate: Double = 0.035
        public static let idleEnergyDepletionRate: Double = 0.003
        public static let boredomBuildupRate: Double = 0.012
        public static let boredomReliefRate: Double = 0.025
        public static let curiosityBuildupRate: Double = 0.010
        public static let socialBuildupRate: Double = 0.008
    }
    
    public init(
        energy: Double = 0.8,
        boredom: Double = 0.1,
        curiosityDrive: Double = 0.3,
        socialDrive: Double = 0.3,
        mood: CharacterMood = .contented
    ) {
        self.energy = min(max(energy, 0.0), 1.0)
        self.boredom = min(max(boredom, 0.0), 1.0)
        self.curiosityDrive = min(max(curiosityDrive, 0.0), 1.0)
        self.socialDrive = min(max(socialDrive, 0.0), 1.0)
        self.mood = mood
    }
    
    public mutating func update(elapsedSeconds: TimeInterval, currentAction: CharacterAction, profile: PersonalityProfile) {
        let dt = min(max(elapsedSeconds, 0.0), 30.0)
        guard dt > 0 else { return }
        
        switch currentAction {
        case .walking, .exploring:
            let energyMultiplier = 1.3 - (profile.energy * 0.6)
            let cost = (currentAction == .exploring ? 1.2 : 1.0) * Constants.energyDepletionRate * energyMultiplier * dt
            energy = max(energy - cost, 0.0)
            
            let relief = Constants.boredomReliefRate * dt
            boredom = max(boredom - relief, 0.0)
            
            if currentAction == .exploring {
                curiosityDrive = max(curiosityDrive - (0.04 * dt), 0.0)
            } else {
                curiosityDrive = min(curiosityDrive + (Constants.curiosityBuildupRate * profile.curiosity * dt), 1.0)
            }
            
        case .sleeping:
            let recoveryMultiplier = 0.8 + (profile.laziness * 0.4)
            energy = min(energy + (Constants.energyRecoveryRate * recoveryMultiplier * dt), 1.0)
            boredom = max(boredom - (0.01 * dt), 0.0)
            
        case .idle:
            energy = max(energy - (Constants.idleEnergyDepletionRate * dt), 0.0)
            let boredomMultiplier = 0.6 + (profile.curiosity * 0.8)
            boredom = min(boredom + (Constants.boredomBuildupRate * boredomMultiplier * dt), 1.0)
            curiosityDrive = min(curiosityDrive + (Constants.curiosityBuildupRate * profile.curiosity * dt), 1.0)
        }
        
        socialDrive = min(socialDrive + (Constants.socialBuildupRate * profile.sociability * dt), 1.0)
        
        // Update mood based on updated needs
        if energy < 0.25 {
            mood = .tired
        } else if boredom > 0.70 {
            mood = .bored
        } else if curiosityDrive > 0.65 || boredom > 0.45 {
            mood = .restless
        } else if profile.playfulness > 0.7 && energy > 0.5 {
            mood = .playful
        } else {
            mood = .contented
        }
    }
    
    public mutating func interactWithUser() {
        socialDrive = max(socialDrive - 0.4, 0.0)
        boredom = max(boredom - 0.3, 0.0)
        if mood == .bored {
            mood = .playful
        }
    }
}
