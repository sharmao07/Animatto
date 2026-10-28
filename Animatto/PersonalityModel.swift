import Foundation

// MARK: - Personality Preset
public enum PersonalityPreset: String, Codable, CaseIterable, Identifiable {
    case sleepy
    case curious
    case energetic
    case mischievous
    case shy
    case balanced
    case playful
    case calm
    case sarcastic
    case supportive
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .sleepy: return "Sleepy"
        case .curious: return "Curious"
        case .energetic: return "Energetic"
        case .mischievous: return "Mischievous"
        case .shy: return "Shy"
        case .balanced: return "Balanced"
        case .playful: return "Playful"
        case .calm: return "Calm"
        case .sarcastic: return "Sarcastic"
        case .supportive: return "Supportive"
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
        case .playful: return "figure.play"
        case .calm: return "cup.and.saucer.fill"
        case .sarcastic: return "face.smiling"
        case .supportive: return "heart.fill"
        }
    }
    
    public var summary: String {
        switch self {
        case .sleepy: return "Prefers resting and naps. Low energy and high laziness."
        case .curious: return "Loves to explore and inspect surroundings and active tasks."
        case .energetic: return "High movement and stamina. Rarely stays idle."
        case .mischievous: return "Unpredictable with sudden turns, playful antics, and jokes."
        case .shy: return "Quiet, gentle, and reserved. Seeks quiet corners away from the cursor."
        case .balanced: return "Evenly tempered balance of rest, walking, and curiosity."
        case .playful: return "Enthusiastic and joyful. Loves interacting and frequent games."
        case .calm: return "Peaceful and serene companion with steady, quiet habits."
        case .sarcastic: return "Sharp-witted, dry humor, and independent attitude."
        case .supportive: return "Devoted cheerleader providing warmth and encouragement."
        }
    }
}

// MARK: - The Ten Personality Trait Dimensions
public enum PersonalityTraitDimension: String, CaseIterable, Identifiable {
    case energetic
    case lazy
    case curious
    case playful
    case sarcastic
    case supportive
    case shy
    case sociable
    case mischievous
    case independent
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .energetic: return "Energetic"
        case .lazy: return "Lazy"
        case .curious: return "Curious"
        case .playful: return "Playful"
        case .sarcastic: return "Sarcastic"
        case .supportive: return "Supportive"
        case .shy: return "Shy"
        case .sociable: return "Sociable"
        case .mischievous: return "Mischievous"
        case .independent: return "Independent"
        }
    }
    
    public var iconName: String {
        switch self {
        case .energetic: return "bolt.fill"
        case .lazy: return "moon.zzz.fill"
        case .curious: return "magnifyingglass"
        case .playful: return "figure.play"
        case .sarcastic: return "face.smiling"
        case .supportive: return "heart.fill"
        case .shy: return "eye.slash.fill"
        case .sociable: return "person.2.fill"
        case .mischievous: return "sparkles"
        case .independent: return "leaf.fill"
        }
    }
    
    public var explanation: String {
        switch self {
        case .energetic: return "Preference for active movement, walking, and physical stamina."
        case .lazy: return "Tendency to conserve energy, sit, and take frequent naps."
        case .curious: return "Desire to explore new windows, bounds, and desktop activities."
        case .playful: return "Engages in playful hops, joyful reactions, and animations."
        case .sarcastic: return "Dry wit, teasing remarks, and humorous commentary."
        case .supportive: return "Encouraging praise, emotional warmth, and cheering."
        case .shy: return "Hesitant nature, retreats from cursor, prefers quiet corners."
        case .sociable: return "Loves companionship, responds warmly to user presence."
        case .mischievous: return "Sudden direction reversals and unpredictable antics."
        case .independent: return "Follows own agenda, ignores cursor, happy doing own thing."
        }
    }
    
    public var lowDescription: String {
        switch self {
        case .energetic: return "Sluggish / Relaxed"
        case .lazy: return "Active / Restless"
        case .curious: return "Indifferent"
        case .playful: return "Serious"
        case .sarcastic: return "Earnest / Literal"
        case .supportive: return "Neutral"
        case .shy: return "Bold / Outgoing"
        case .sociable: return "Introverted"
        case .mischievous: return "Orderly / Calm"
        case .independent: return "Clingy / Attentive"
        }
    }
    
    public var highDescription: String {
        switch self {
        case .energetic: return "Hyperactive"
        case .lazy: return "Couch Potato"
        case .curious: return "Inquisitive Explorer"
        case .playful: return "Non-Stop Fun"
        case .sarcastic: return "Sharp Wit"
        case .supportive: return "Devoted Cheerleader"
        case .shy: return "Timid & Elusive"
        case .sociable: return "Social Butterfly"
        case .mischievous: return "Agent of Chaos"
        case .independent: return "Free Spirit"
        }
    }
}

// MARK: - Topic Preference
public enum TopicPreference: String, Codable, CaseIterable {
    case like = "like"
    case interested = "interested"
    case dislike = "dislike"
    case neutral = "neutral"
    
    public var displayName: String {
        switch self {
        case .like: return "Loves"
        case .interested: return "Interested"
        case .dislike: return "Dislikes"
        case .neutral: return "Neutral"
        }
    }
    
    public var iconName: String {
        switch self {
        case .like: return "heart.fill"
        case .interested: return "sparkle"
        case .dislike: return "hand.thumbsdown.fill"
        case .neutral: return "minus"
        }
    }
}

// MARK: - Character Interest Topics
public enum CharacterInterestTopic: String, Codable, CaseIterable, Identifiable {
    case coding = "coding"
    case gaming = "gaming"
    case music = "music"
    case art = "art"
    case anime = "anime"
    case study = "study"
    case relaxation = "relaxation"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .coding: return "Coding & Programming"
        case .gaming: return "Gaming"
        case .music: return "Music"
        case .art: return "Art & Drawing"
        case .anime: return "Anime & Shows"
        case .study: return "Study & Reading"
        case .relaxation: return "Relaxation & Breaks"
        }
    }
    
    public var iconName: String {
        switch self {
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .gaming: return "gamecontroller.fill"
        case .music: return "music.note"
        case .art: return "paintpalette.fill"
        case .anime: return "tv.fill"
        case .study: return "book.fill"
        case .relaxation: return "cup.and.saucer.fill"
        }
    }
    
    public static func topicForContext(
        appName: String? = nil,
        visualCategoryName: String? = nil,
        isMusic: Bool = false,
        isInactive: Bool = false
    ) -> CharacterInterestTopic? {
        if isMusic { return .music }
        if isInactive { return .relaxation }
        
        if let visual = visualCategoryName?.lowercased() {
            if visual.contains("code") || visual.contains("coding") { return .coding }
            if visual.contains("game") || visual.contains("gaming") { return .gaming }
            if visual.contains("video") || visual.contains("anime") { return .anime }
            if visual.contains("read") || visual.contains("browse") { return .study }
            if visual.contains("art") || visual.contains("creative") { return .art }
        }
        
        if let name = appName?.lowercased() {
            if name.contains("xcode") || name.contains("code") || name.contains("terminal") || name.contains("cursor") || name.contains("sublime") || name.contains("intellij") {
                return .coding
            }
            if name.contains("steam") || name.contains("game") || name.contains("minecraft") || name.contains("unity") || name.contains("roblox") {
                return .gaming
            }
            if name.contains("music") || name.contains("spotify") || name.contains("sound") {
                return .music
            }
            if name.contains("photoshop") || name.contains("figma") || name.contains("illustrator") || name.contains("blender") || name.contains("sketch") || name.contains("canva") {
                return .art
            }
            if name.contains("crunchyroll") || name.contains("anime") || name.contains("vlc") || name.contains("netflix") || name.contains("youtube") {
                return .anime
            }
            if name.contains("notion") || name.contains("obsidian") || name.contains("notes") || name.contains("books") || name.contains("preview") || name.contains("safari") || name.contains("chrome") {
                return .study
            }
        }
        
        return nil
    }
}

// MARK: - Character Behavior Preferences
public struct CharacterBehaviorPreferences: Codable, Equatable {
    public var cursorFollowingEnabled: Bool
    public var cursorFollowingStrength: Double  // 0.0 ... 1.0 (how actively it follows cursor)
    public var attentionSeekingTendency: Double // 0.0 ... 1.0 (how often it approaches user)
    public var sleepFrequency: Double           // 0.0 ... 1.0 (how readily it chooses sleep/rest)
    public var explorationTendency: Double      // 0.0 ... 1.0 (how readily it explores surfaces)
    public var commentFrequency: Double         // 0.0 ... 1.0 (dialogue rate multiplier)
    public var dialogueMuted: Bool              // if true, speech bubbles will never trigger for this character
    public var socialInteractionsEnabled: Bool  // if true, participates in multi-character social behavior
    public var memoryEnabled: Bool              // if true, stores bounded interaction continuity and memories
    
    public init(
        cursorFollowingEnabled: Bool = true,
        cursorFollowingStrength: Double = 0.5,
        attentionSeekingTendency: Double = 0.5,
        sleepFrequency: Double = 0.5,
        explorationTendency: Double = 0.5,
        commentFrequency: Double = 0.5,
        dialogueMuted: Bool = false,
        socialInteractionsEnabled: Bool = true,
        memoryEnabled: Bool = true
    ) {
        self.cursorFollowingEnabled = cursorFollowingEnabled
        self.cursorFollowingStrength = min(max(cursorFollowingStrength, 0.0), 1.0)
        self.attentionSeekingTendency = min(max(attentionSeekingTendency, 0.0), 1.0)
        self.sleepFrequency = min(max(sleepFrequency, 0.0), 1.0)
        self.explorationTendency = min(max(explorationTendency, 0.0), 1.0)
        self.commentFrequency = min(max(commentFrequency, 0.0), 1.0)
        self.dialogueMuted = dialogueMuted
        self.socialInteractionsEnabled = socialInteractionsEnabled
        self.memoryEnabled = memoryEnabled
    }
    
    public func clamped() -> CharacterBehaviorPreferences {
        return CharacterBehaviorPreferences(
            cursorFollowingEnabled: cursorFollowingEnabled,
            cursorFollowingStrength: cursorFollowingStrength,
            attentionSeekingTendency: attentionSeekingTendency,
            sleepFrequency: sleepFrequency,
            explorationTendency: explorationTendency,
            commentFrequency: commentFrequency,
            dialogueMuted: dialogueMuted,
            socialInteractionsEnabled: socialInteractionsEnabled,
            memoryEnabled: memoryEnabled
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case cursorFollowingEnabled, cursorFollowingStrength, attentionSeekingTendency
        case sleepFrequency, explorationTendency, commentFrequency, dialogueMuted
        case socialInteractionsEnabled, memoryEnabled
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cursorFollowingEnabled = try container.decodeIfPresent(Bool.self, forKey: .cursorFollowingEnabled) ?? true
        self.cursorFollowingStrength = try container.decodeIfPresent(Double.self, forKey: .cursorFollowingStrength) ?? 0.5
        self.attentionSeekingTendency = try container.decodeIfPresent(Double.self, forKey: .attentionSeekingTendency) ?? 0.5
        self.sleepFrequency = try container.decodeIfPresent(Double.self, forKey: .sleepFrequency) ?? 0.5
        self.explorationTendency = try container.decodeIfPresent(Double.self, forKey: .explorationTendency) ?? 0.5
        self.commentFrequency = try container.decodeIfPresent(Double.self, forKey: .commentFrequency) ?? 0.5
        self.dialogueMuted = try container.decodeIfPresent(Bool.self, forKey: .dialogueMuted) ?? false
        self.socialInteractionsEnabled = try container.decodeIfPresent(Bool.self, forKey: .socialInteractionsEnabled) ?? true
        self.memoryEnabled = try container.decodeIfPresent(Bool.self, forKey: .memoryEnabled) ?? true
    }
}

// MARK: - Personality Profile
public struct PersonalityProfile: Codable, Identifiable, Equatable {
    public var id: UUID
    public var schemaVersion: Int
    public var name: String
    public var preset: PersonalityPreset?
    
    // The Ten Dimensions (Normalized 0.0 ... 1.0)
    public var energy: Double           // 1. Energetic
    public var laziness: Double         // 2. Lazy
    public var curiosity: Double        // 3. Curious
    public var playfulness: Double      // 4. Playful
    public var sarcasm: Double          // 5. Sarcastic
    public var supportiveness: Double   // 6. Supportive
    public var shyness: Double          // 7. Shy
    public var sociability: Double      // 8. Sociable
    public var mischief: Double         // 9. Mischievous
    public var independence: Double     // 10. Independent
    
    // Legacy / Backwards Compatibility
    public var attentionSeeking: Double // Attention Seeking
    
    // Interests & Topic Preferences
    public var topicPreferences: [String: TopicPreference]
    
    // Behavior Preferences
    public var behaviorPreferences: CharacterBehaviorPreferences
    
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
        attentionSeeking: Double = 0.5,
        sarcasm: Double = 0.3,
        supportiveness: Double = 0.5,
        shyness: Double? = nil,
        independence: Double = 0.5,
        topicPreferences: [String: TopicPreference] = [:],
        behaviorPreferences: CharacterBehaviorPreferences = CharacterBehaviorPreferences()
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
        self.sarcasm = min(max(sarcasm, 0.0), 1.0)
        self.supportiveness = min(max(supportiveness, 0.0), 1.0)
        if let shyness = shyness {
            self.shyness = min(max(shyness, 0.0), 1.0)
        } else {
            let derived = (1.0 - sociability) * 0.5 + (1.0 - attentionSeeking) * 0.5
            self.shyness = min(max(derived, 0.0), 1.0)
        }
        self.independence = min(max(independence, 0.0), 1.0)
        self.topicPreferences = topicPreferences
        self.behaviorPreferences = behaviorPreferences.clamped()
    }
    
    // MARK: - Decodable Migration (Schema V1 -> V2)
    enum CodingKeys: String, CodingKey {
        case id, schemaVersion, name, preset
        case energy, curiosity, playfulness, laziness, sociability, mischief, attentionSeeking
        case sarcasm, supportiveness, shyness, independence
        case topicPreferences, behaviorPreferences
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Companion"
        self.preset = try container.decodeIfPresent(PersonalityPreset.self, forKey: .preset)
        
        let rawEnergy = try container.decodeIfPresent(Double.self, forKey: .energy) ?? 0.5
        let rawCuriosity = try container.decodeIfPresent(Double.self, forKey: .curiosity) ?? 0.5
        let rawPlayfulness = try container.decodeIfPresent(Double.self, forKey: .playfulness) ?? 0.5
        let rawLaziness = try container.decodeIfPresent(Double.self, forKey: .laziness) ?? 0.5
        let rawSociability = try container.decodeIfPresent(Double.self, forKey: .sociability) ?? 0.5
        let rawMischief = try container.decodeIfPresent(Double.self, forKey: .mischief) ?? 0.5
        let rawAttention = try container.decodeIfPresent(Double.self, forKey: .attentionSeeking) ?? 0.5
        
        self.energy = min(max(rawEnergy, 0.0), 1.0)
        self.curiosity = min(max(rawCuriosity, 0.0), 1.0)
        self.playfulness = min(max(rawPlayfulness, 0.0), 1.0)
        self.laziness = min(max(rawLaziness, 0.0), 1.0)
        self.sociability = min(max(rawSociability, 0.0), 1.0)
        self.mischief = min(max(rawMischief, 0.0), 1.0)
        self.attentionSeeking = min(max(rawAttention, 0.0), 1.0)
        
        // Phase 6 additions with intelligent schema migration defaults
        if let rawSarcasm = try container.decodeIfPresent(Double.self, forKey: .sarcasm) {
            self.sarcasm = min(max(rawSarcasm, 0.0), 1.0)
        } else {
            self.sarcasm = 0.3
        }
        
        if let rawSupp = try container.decodeIfPresent(Double.self, forKey: .supportiveness) {
            self.supportiveness = min(max(rawSupp, 0.0), 1.0)
        } else {
            self.supportiveness = 0.5
        }
        
        if let rawShy = try container.decodeIfPresent(Double.self, forKey: .shyness) {
            self.shyness = min(max(rawShy, 0.0), 1.0)
        } else {
            // Derive shyness from low sociability and low attention-seeking
            let derived = (1.0 - rawSociability) * 0.5 + (1.0 - rawAttention) * 0.5
            self.shyness = min(max(derived, 0.0), 1.0)
        }
        
        if let rawIndep = try container.decodeIfPresent(Double.self, forKey: .independence) {
            self.independence = min(max(rawIndep, 0.0), 1.0)
        } else {
            self.independence = 0.5
        }
        
        self.topicPreferences = try container.decodeIfPresent([String: TopicPreference].self, forKey: .topicPreferences) ?? [:]
        self.behaviorPreferences = (try container.decodeIfPresent(CharacterBehaviorPreferences.self, forKey: .behaviorPreferences) ?? CharacterBehaviorPreferences()).clamped()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(preset, forKey: .preset)
        try container.encode(energy, forKey: .energy)
        try container.encode(curiosity, forKey: .curiosity)
        try container.encode(playfulness, forKey: .playfulness)
        try container.encode(laziness, forKey: .laziness)
        try container.encode(sociability, forKey: .sociability)
        try container.encode(mischief, forKey: .mischief)
        try container.encode(attentionSeeking, forKey: .attentionSeeking)
        try container.encode(sarcasm, forKey: .sarcasm)
        try container.encode(supportiveness, forKey: .supportiveness)
        try container.encode(shyness, forKey: .shyness)
        try container.encode(independence, forKey: .independence)
        try container.encode(topicPreferences, forKey: .topicPreferences)
        try container.encode(behaviorPreferences, forKey: .behaviorPreferences)
    }
    
    // MARK: - Topic Helpers
    public func preference(for topic: CharacterInterestTopic) -> TopicPreference {
        return topicPreferences[topic.rawValue] ?? .neutral
    }
    
    public mutating func setPreference(_ preference: TopicPreference, for topic: CharacterInterestTopic) {
        if preference == .neutral {
            topicPreferences.removeValue(forKey: topic.rawValue)
        } else {
            topicPreferences[topic.rawValue] = preference
        }
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
        copy.sarcasm = min(max(copy.sarcasm, 0.0), 1.0)
        copy.supportiveness = min(max(copy.supportiveness, 0.0), 1.0)
        copy.shyness = min(max(copy.shyness, 0.0), 1.0)
        copy.independence = min(max(copy.independence, 0.0), 1.0)
        copy.behaviorPreferences = copy.behaviorPreferences.clamped()
        return copy
    }
    
    // MARK: - Presets Factory
    public static func preset(_ preset: PersonalityPreset) -> PersonalityProfile {
        switch preset {
        case .sleepy:
            return PersonalityProfile(
                schemaVersion: 2,
                name: "Sleepy",
                preset: .sleepy,
                energy: 0.2,
                curiosity: 0.25,
                playfulness: 0.2,
                laziness: 0.85,
                sociability: 0.3,
                mischief: 0.15,
                attentionSeeking: 0.2,
                sarcasm: 0.2,
                supportiveness: 0.4,
                shyness: 0.5,
                independence: 0.7,
                topicPreferences: [
                    CharacterInterestTopic.relaxation.rawValue: .like,
                    CharacterInterestTopic.music.rawValue: .like,
                    CharacterInterestTopic.coding.rawValue: .dislike
                ],
                behaviorPreferences: CharacterBehaviorPreferences(
                    cursorFollowingEnabled: true,
                    cursorFollowingStrength: 0.2,
                    attentionSeekingTendency: 0.2,
                    sleepFrequency: 0.85,
                    explorationTendency: 0.2,
                    commentFrequency: 0.3
                )
            )
            
        case .curious:
            return PersonalityProfile(
                schemaVersion: 2,
                name: "Curious",
                preset: .curious,
                energy: 0.6,
                curiosity: 0.9,
                playfulness: 0.5,
                laziness: 0.3,
                sociability: 0.6,
                mischief: 0.4,
                attentionSeeking: 0.5,
                sarcasm: 0.2,
                supportiveness: 0.6,
                shyness: 0.2,
                independence: 0.5,
                topicPreferences: [
                    CharacterInterestTopic.coding.rawValue: .like,
                    CharacterInterestTopic.study.rawValue: .like,
                    CharacterInterestTopic.art.rawValue: .interested,
                    CharacterInterestTopic.anime.rawValue: .interested
                ],
                behaviorPreferences: CharacterBehaviorPreferences(
                    cursorFollowingEnabled: true,
                    cursorFollowingStrength: 0.75,
                    attentionSeekingTendency: 0.6,
                    sleepFrequency: 0.3,
                    explorationTendency: 0.9,
                    commentFrequency: 0.65
                )
            )
            
        case .energetic:
            return PersonalityProfile(
                schemaVersion: 2,
                name: "Energetic",
                preset: .energetic,
                energy: 0.9,
                curiosity: 0.7,
                playfulness: 0.85,
                laziness: 0.15,
                sociability: 0.75,
                mischief: 0.5,
                attentionSeeking: 0.7,
                sarcasm: 0.2,
                supportiveness: 0.8,
                shyness: 0.1,
                independence: 0.4,
                topicPreferences: [
                    CharacterInterestTopic.gaming.rawValue: .like,
                    CharacterInterestTopic.music.rawValue: .like,
                    CharacterInterestTopic.relaxation.rawValue: .dislike
                ],
                behaviorPreferences: CharacterBehaviorPreferences(
                    cursorFollowingEnabled: true,
                    cursorFollowingStrength: 0.85,
                    attentionSeekingTendency: 0.75,
                    sleepFrequency: 0.15,
                    explorationTendency: 0.85,
                    commentFrequency: 0.8
                )
            )
            
        case .mischievous:
            return PersonalityProfile(
                schemaVersion: 2,
                name: "Mischievous",
                preset: .mischievous,
                energy: 0.75,
                curiosity: 0.7,
                playfulness: 0.9,
                laziness: 0.25,
                sociability: 0.6,
                mischief: 0.9,
                attentionSeeking: 0.65,
                sarcasm: 0.75,
                supportiveness: 0.3,
                shyness: 0.15,
                independence: 0.7,
                topicPreferences: [
                    CharacterInterestTopic.gaming.rawValue: .like,
                    CharacterInterestTopic.anime.rawValue: .like
                ],
                behaviorPreferences: CharacterBehaviorPreferences(
                    cursorFollowingEnabled: true,
                    cursorFollowingStrength: 0.6,
                    attentionSeekingTendency: 0.7,
                    sleepFrequency: 0.25,
                    explorationTendency: 0.8,
                    commentFrequency: 0.7
                )
            )
            
        case .shy:
            return PersonalityProfile(
                schemaVersion: 2,
                name: "Shy",
                preset: .shy,
                energy: 0.35,
                curiosity: 0.4,
                playfulness: 0.3,
                laziness: 0.6,
                sociability: 0.2,
                mischief: 0.1,
                attentionSeeking: 0.15,
                sarcasm: 0.15,
                supportiveness: 0.7,
                shyness: 0.85,
                independence: 0.6,
                topicPreferences: [
                    CharacterInterestTopic.art.rawValue: .like,
                    CharacterInterestTopic.anime.rawValue: .like,
                    CharacterInterestTopic.study.rawValue: .interested,
                    CharacterInterestTopic.gaming.rawValue: .dislike
                ],
                behaviorPreferences: CharacterBehaviorPreferences(
                    cursorFollowingEnabled: false,
                    cursorFollowingStrength: 0.1,
                    attentionSeekingTendency: 0.15,
                    sleepFrequency: 0.6,
                    explorationTendency: 0.3,
                    commentFrequency: 0.25
                )
            )
            
        case .balanced:
            return PersonalityProfile(
                schemaVersion: 2,
                name: "Balanced",
                preset: .balanced,
                energy: 0.5,
                curiosity: 0.5,
                playfulness: 0.5,
                laziness: 0.5,
                sociability: 0.5,
                mischief: 0.5,
                attentionSeeking: 0.5,
                sarcasm: 0.3,
                supportiveness: 0.5,
                shyness: 0.3,
                independence: 0.5,
                topicPreferences: [:],
                behaviorPreferences: CharacterBehaviorPreferences(
                    cursorFollowingEnabled: true,
                    cursorFollowingStrength: 0.5,
                    attentionSeekingTendency: 0.5,
                    sleepFrequency: 0.5,
                    explorationTendency: 0.5,
                    commentFrequency: 0.5
                )
            )
            
        case .playful:
            return PersonalityProfile(
                schemaVersion: 2,
                name: "Playful",
                preset: .playful,
                energy: 0.8,
                curiosity: 0.75,
                playfulness: 0.95,
                laziness: 0.2,
                sociability: 0.8,
                mischief: 0.65,
                attentionSeeking: 0.8,
                sarcasm: 0.3,
                supportiveness: 0.7,
                shyness: 0.15,
                independence: 0.35,
                topicPreferences: [
                    CharacterInterestTopic.gaming.rawValue: .like,
                    CharacterInterestTopic.anime.rawValue: .like,
                    CharacterInterestTopic.art.rawValue: .interested
                ],
                behaviorPreferences: CharacterBehaviorPreferences(
                    cursorFollowingEnabled: true,
                    cursorFollowingStrength: 0.8,
                    attentionSeekingTendency: 0.8,
                    sleepFrequency: 0.2,
                    explorationTendency: 0.85,
                    commentFrequency: 0.75
                )
            )
            
        case .calm:
            return PersonalityProfile(
                schemaVersion: 2,
                name: "Calm",
                preset: .calm,
                energy: 0.4,
                curiosity: 0.4,
                playfulness: 0.3,
                laziness: 0.45,
                sociability: 0.5,
                mischief: 0.1,
                attentionSeeking: 0.3,
                sarcasm: 0.15,
                supportiveness: 0.85,
                shyness: 0.35,
                independence: 0.65,
                topicPreferences: [
                    CharacterInterestTopic.relaxation.rawValue: .like,
                    CharacterInterestTopic.study.rawValue: .like,
                    CharacterInterestTopic.music.rawValue: .like
                ],
                behaviorPreferences: CharacterBehaviorPreferences(
                    cursorFollowingEnabled: true,
                    cursorFollowingStrength: 0.35,
                    attentionSeekingTendency: 0.35,
                    sleepFrequency: 0.5,
                    explorationTendency: 0.35,
                    commentFrequency: 0.4
                )
            )
            
        case .sarcastic:
            return PersonalityProfile(
                schemaVersion: 2,
                name: "Sarcastic",
                preset: .sarcastic,
                energy: 0.5,
                curiosity: 0.6,
                playfulness: 0.5,
                laziness: 0.55,
                sociability: 0.45,
                mischief: 0.8,
                attentionSeeking: 0.4,
                sarcasm: 0.95,
                supportiveness: 0.15,
                shyness: 0.2,
                independence: 0.85,
                topicPreferences: [
                    CharacterInterestTopic.coding.rawValue: .interested,
                    CharacterInterestTopic.gaming.rawValue: .like,
                    CharacterInterestTopic.study.rawValue: .dislike
                ],
                behaviorPreferences: CharacterBehaviorPreferences(
                    cursorFollowingEnabled: true,
                    cursorFollowingStrength: 0.4,
                    attentionSeekingTendency: 0.4,
                    sleepFrequency: 0.5,
                    explorationTendency: 0.5,
                    commentFrequency: 0.6
                )
            )
            
        case .supportive:
            return PersonalityProfile(
                schemaVersion: 2,
                name: "Supportive",
                preset: .supportive,
                energy: 0.65,
                curiosity: 0.6,
                playfulness: 0.6,
                laziness: 0.3,
                sociability: 0.85,
                mischief: 0.2,
                attentionSeeking: 0.7,
                sarcasm: 0.05,
                supportiveness: 0.95,
                shyness: 0.15,
                independence: 0.35,
                topicPreferences: [
                    CharacterInterestTopic.study.rawValue: .like,
                    CharacterInterestTopic.coding.rawValue: .like,
                    CharacterInterestTopic.relaxation.rawValue: .like,
                    CharacterInterestTopic.art.rawValue: .interested
                ],
                behaviorPreferences: CharacterBehaviorPreferences(
                    cursorFollowingEnabled: true,
                    cursorFollowingStrength: 0.75,
                    attentionSeekingTendency: 0.7,
                    sleepFrequency: 0.3,
                    explorationTendency: 0.6,
                    commentFrequency: 0.7
                )
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

// MARK: - Behavior Preview Simulator
public struct PersonalityBehaviorSimulator {
    public struct SimulationResult: Equatable {
        public let actionProbabilities: [CharacterAction: Double] // Percentage 0...100
        public let primaryAction: CharacterAction
        public let cursorResponseDescription: String
        public let topicReactions: [CharacterInterestTopic: String]
        public let sampleDialogue: [String]
        public let restingTendencyDescription: String
    }
    
    public static func simulate(profile: PersonalityProfile) -> SimulationResult {
        let engine = BehaviorEngine(profile: profile)
        let scores = engine.calculateScores(eligibleActions: CharacterAction.allCases, eventFrequency: 0.5)
        let total = scores.values.reduce(0.0, +)
        var probs: [CharacterAction: Double] = [:]
        for (action, score) in scores {
            probs[action] = total > 0 ? (score / total) * 100.0 : 25.0
        }
        let primary = scores.max(by: { $0.value < $1.value })?.key ?? .walking
        
        // Cursor reaction simulation
        let cursorDesc: String
        if !profile.behaviorPreferences.cursorFollowingEnabled {
            cursorDesc = "Ignores cursor completely (Cursor following disabled by user preference)."
        } else if profile.independence > 0.7 {
            cursorDesc = "Ignores cursor; pursues independent agenda across screen."
        } else if profile.shyness > 0.55 {
            cursorDesc = "Retreats away cautiously to a quiet corner."
        } else if profile.curiosity > 0.5 || profile.sociability > 0.5 {
            let strength = Int(profile.behaviorPreferences.cursorFollowingStrength * 100)
            cursorDesc = "Approaches and investigates cursor (\(strength)% strength)."
        } else if profile.mischief > 0.7 {
            cursorDesc = "Playfully darts in opposite direction when cursor nears."
        } else {
            cursorDesc = "Notices cursor casually and continues wandering."
        }
        
        // Topic reactions
        var topicReactions: [CharacterInterestTopic: String] = [:]
        for topic in CharacterInterestTopic.allCases {
            let pref = profile.preference(for: topic)
            switch pref {
            case .like:
                topicReactions[topic] = "Enthusiastic! Performed with high curiosity and joyful commentary."
            case .interested:
                topicReactions[topic] = "Inquisitive; watches attentively and asks questions."
            case .dislike:
                topicReactions[topic] = "Avoidant; groans or takes a nap during this activity."
            case .neutral:
                topicReactions[topic] = "Standard mild reaction without special bias."
            }
        }
        
        // Sample dialogue tailored to profile traits
        var dialogueSamples: [String] = []
        let preferredTone = RuleBasedDialogueProvider.resolveToneForPersonality(profile)
        let sampleEntries = DialogueLibrary.entries.filter { $0.tone == preferredTone }
        for entry in sampleEntries.prefix(3) {
            dialogueSamples.append("\"\(entry.text)\"")
        }
        if dialogueSamples.isEmpty {
            dialogueSamples.append("\"Hello there! Ready when you are.\"")
        }
        
        // Resting tendency
        let restingDesc: String
        if profile.behaviorPreferences.sleepFrequency > 0.7 || profile.laziness > 0.75 {
            restingDesc = "High sleep preference: naps readily when idle or fatigued."
        } else if profile.behaviorPreferences.sleepFrequency < 0.3 || profile.energy > 0.75 {
            restingDesc = "Low sleep preference: stays awake, roaming and active."
        } else {
            restingDesc = "Balanced sleep schedule based on activity fatigue."
        }
        
        return SimulationResult(
            actionProbabilities: probs,
            primaryAction: primary,
            cursorResponseDescription: cursorDesc,
            topicReactions: topicReactions,
            sampleDialogue: dialogueSamples,
            restingTendencyDescription: restingDesc
        )
    }
}
