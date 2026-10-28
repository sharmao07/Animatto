import Foundation
import SwiftUI
import AppKit
import Combine

// MARK: - Visual Activity Category
public enum VisualActivityCategory: String, Codable, CaseIterable {
    case coding
    case gaming
    case video
    case readingBrowsing
    case creativeWork
    case generalDesktop
    case unknown
    
    public var displayName: String {
        switch self {
        case .coding: return "Coding & Development"
        case .gaming: return "Gaming"
        case .video: return "Video & Animation"
        case .readingBrowsing: return "Reading & Browsing"
        case .creativeWork: return "Design & Creative Work"
        case .generalDesktop: return "General Desktop"
        case .unknown: return "Unknown"
        }
    }
}

// MARK: - Dialogue Trigger
public enum DialogueTrigger: Equatable {
    case greeting
    case wakingUp
    case resting
    case walking
    case exploring
    case boredom
    case cursorInteraction
    case petClicked
    case petDragged
    case dragReleased
    case appActivated(appName: String)
    case visualObservation(category: VisualActivityCategory, summary: String)
    case userInactivity(threshold: InactivityThreshold)
    case userReturned
    case playfulReaction
    case falling
    case landing
    case musicPlaying(track: String)
    case ledgeOrObstacle(obstacle: String)
}

// MARK: - Dialogue Category
public enum DialogueCategory: String, Codable, CaseIterable {
    case greeting
    case waking
    case resting
    case walking
    case exploring
    case idle
    case interaction
    case appObservation
    case visualObservation
    case inactivity
    case playful
    case falling
    case music
    case environmental
}

// MARK: - Dialogue Message
public struct DialogueMessage: Equatable, Identifiable {
    public let id: String
    public let text: String
    public let category: DialogueCategory
    public let duration: TimeInterval
    public let timestamp: Date
    
    public init(id: String, text: String, category: DialogueCategory, duration: TimeInterval = 4.5, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.category = category
        self.duration = duration
        self.timestamp = timestamp
    }
}

// MARK: - Dialogue Context
public struct DialogueContext {
    public let characterId: UUID
    public let characterName: String
    public let personality: PersonalityProfile
    public let currentNeeds: CharacterNeeds
    public let currentAction: CharacterAction
    public let trigger: DialogueTrigger
    public let appName: String?
    public let referenceDate: Date
    
    public init(
        characterId: UUID,
        characterName: String,
        personality: PersonalityProfile,
        currentNeeds: CharacterNeeds,
        currentAction: CharacterAction,
        trigger: DialogueTrigger,
        appName: String? = nil,
        referenceDate: Date = Date()
    ) {
        self.characterId = characterId
        self.characterName = characterName
        self.personality = personality
        self.currentNeeds = currentNeeds
        self.currentAction = currentAction
        self.trigger = trigger
        self.appName = appName
        self.referenceDate = referenceDate
    }
}

// MARK: - Dialogue Profile
public struct DialogueProfile: Codable, Equatable {
    public var communicationFrequency: Double // 0.1 ... 1.0 (multiplier)
    public var preferredCategories: [DialogueCategory]
    public var cheerfulness: Double // 0.0 ... 1.0
    public var curiosity: Double // 0.0 ... 1.0
    public var playfulness: Double // 0.0 ... 1.0
    public var isReserved: Bool // Shy/reserved vs expressive
    public var contextualCommentsEnabled: Bool
    public var directInteractionEnabled: Bool
    
    public init(
        communicationFrequency: Double = 0.5,
        preferredCategories: [DialogueCategory] = DialogueCategory.allCases,
        cheerfulness: Double = 0.5,
        curiosity: Double = 0.5,
        playfulness: Double = 0.5,
        isReserved: Bool = false,
        contextualCommentsEnabled: Bool = true,
        directInteractionEnabled: Bool = true
    ) {
        self.communicationFrequency = min(max(communicationFrequency, 0.1), 1.0)
        self.preferredCategories = preferredCategories
        self.cheerfulness = min(max(cheerfulness, 0.0), 1.0)
        self.curiosity = min(max(curiosity, 0.0), 1.0)
        self.playfulness = min(max(playfulness, 0.0), 1.0)
        self.isReserved = isReserved
        self.contextualCommentsEnabled = contextualCommentsEnabled
        self.directInteractionEnabled = directInteractionEnabled
    }
    
    public static func fromPersonality(_ personality: PersonalityProfile) -> DialogueProfile {
        let isShy = personality.shyness > 0.55 || (personality.sociability < 0.35 && personality.attentionSeeking < 0.35)
        let baseFreq = personality.behaviorPreferences.commentFrequency
        let freq = isShy ? min(baseFreq, 0.30) : baseFreq
        
        var preferred: [DialogueCategory] = []
        if personality.curiosity > 0.6 {
            preferred.append(contentsOf: [.exploring, .appObservation, .visualObservation])
        }
        if personality.laziness > 0.6 {
            preferred.append(.resting)
        }
        if personality.mischief > 0.6 || personality.sarcasm > 0.6 {
            preferred.append(.playful)
        }
        if personality.sociability > 0.6 || personality.supportiveness > 0.6 {
            preferred.append(contentsOf: [.greeting, .interaction])
        }
        if personality.energy > 0.6 {
            preferred.append(contentsOf: [.walking, .playful, .falling])
        }
        if personality.preference(for: .music) == .like {
            preferred.append(.music)
        }
        if preferred.isEmpty {
            preferred = DialogueCategory.allCases
        }
        
        return DialogueProfile(
            communicationFrequency: freq,
            preferredCategories: preferred,
            cheerfulness: personality.playfulness,
            curiosity: personality.curiosity,
            playfulness: personality.mischief,
            isReserved: isShy,
            contextualCommentsEnabled: true,
            directInteractionEnabled: true
        )
    }
}

// MARK: - Future-Compatible Dialogue Provider Protocol
public protocol DialogueProvider {
    func selectDialogue<R: RandomSource>(
        context: DialogueContext,
        profile: DialogueProfile,
        recentIds: [String],
        randomSource: inout R
    ) -> DialogueMessage?
}

// MARK: - Structured Dialogue Library
public struct DialogueLibrary {
    public struct Entry: Equatable {
        public let id: String
        public let category: DialogueCategory
        public let text: String
        public let tone: PersonalityTone
    }
    
    public enum PersonalityTone: String, Equatable {
        case neutral
        case curious
        case sleepy
        case shy
        case playful
        case cheerful
        case sarcastic
        case supportive
    }
    
    // Curated, original, high-quality dialogue pools
    public static let entries: [Entry] = [
        // MARK: Greetings
        Entry(id: "greet_neu_01", category: .greeting, text: "Hello there!", tone: .neutral),
        Entry(id: "greet_neu_02", category: .greeting, text: "Glad to be here with you.", tone: .neutral),
        Entry(id: "greet_cur_01", category: .greeting, text: "Ooh, what are we discovering today?", tone: .curious),
        Entry(id: "greet_cur_02", category: .greeting, text: "Lots to explore on this screen!", tone: .curious),
        Entry(id: "greet_slp_01", category: .greeting, text: "*Yawn*... Good morning... or afternoon...", tone: .sleepy),
        Entry(id: "greet_slp_02", category: .greeting, text: "Hello... Can we take things slow today?", tone: .sleepy),
        Entry(id: "greet_shy_01", category: .greeting, text: "...H-hello.", tone: .shy),
        Entry(id: "greet_shy_02", category: .greeting, text: "I'll just keep you company right here.", tone: .shy),
        Entry(id: "greet_ply_01", category: .greeting, text: "Ready for some fun!", tone: .playful),
        Entry(id: "greet_ply_02", category: .greeting, text: "Look who's awake and ready to cause chaos!", tone: .playful),
        Entry(id: "greet_chf_01", category: .greeting, text: "Yay! Let's have a great day!", tone: .cheerful),
        Entry(id: "greet_sarc_01", category: .greeting, text: "Oh, look who decided to grace the desktop.", tone: .sarcastic),
        Entry(id: "greet_sarc_02", category: .greeting, text: "Try not to break anything today.", tone: .sarcastic),
        Entry(id: "greet_supp_01", category: .greeting, text: "You've got this today! I believe in you!", tone: .supportive),
        Entry(id: "greet_supp_02", category: .greeting, text: "So happy to accompany you today!", tone: .supportive),
        
        // MARK: Waking
        Entry(id: "wake_neu_01", category: .waking, text: "Oh, I'm awake!", tone: .neutral),
        Entry(id: "wake_neu_02", category: .waking, text: "Stretching my legs a bit.", tone: .neutral),
        Entry(id: "wake_cur_01", category: .waking, text: "Did I miss anything exciting?", tone: .curious),
        Entry(id: "wake_cur_02", category: .waking, text: "What's happening around here?", tone: .curious),
        Entry(id: "wake_slp_01", category: .waking, text: "Five more minutes, please...", tone: .sleepy),
        Entry(id: "wake_slp_02", category: .waking, text: "My cozy spot was so warm...", tone: .sleepy),
        Entry(id: "wake_shy_01", category: .waking, text: "...Is it safe to wake up?", tone: .shy),
        Entry(id: "wake_ply_01", category: .waking, text: "Nap over! Time to wander!", tone: .playful),
        Entry(id: "wake_sarc_01", category: .waking, text: "Consciousness restored. Unfortunately.", tone: .sarcastic),
        Entry(id: "wake_supp_01", category: .waking, text: "Good morning! Ready to cheer you on!", tone: .supportive),
        
        // MARK: Resting
        Entry(id: "rest_neu_01", category: .resting, text: "Taking a quick breather.", tone: .neutral),
        Entry(id: "rest_neu_02", category: .resting, text: "Recharging my battery.", tone: .neutral),
        Entry(id: "rest_cur_01", category: .resting, text: "Resting my eyes so I can explore later.", tone: .curious),
        Entry(id: "rest_slp_01", category: .resting, text: "Zzz... Do not disturb.", tone: .sleepy),
        Entry(id: "rest_slp_02", category: .resting, text: "Best part of the day: sleep.", tone: .sleepy),
        Entry(id: "rest_slp_03", category: .resting, text: "This spot is remarkably comfortable.", tone: .sleepy),
        Entry(id: "rest_shy_01", category: .resting, text: "Resting quietly in the corner.", tone: .shy),
        Entry(id: "rest_ply_01", category: .resting, text: "Recharging so I can play more later!", tone: .playful),
        Entry(id: "rest_sarc_01", category: .resting, text: "I'll be resting. Try to manage without me.", tone: .sarcastic),
        Entry(id: "rest_supp_01", category: .resting, text: "Take a break too if you need one! Rest is important.", tone: .supportive),
        
        // MARK: Walking & Exploring
        Entry(id: "walk_neu_01", category: .walking, text: "Going for a stroll.", tone: .neutral),
        Entry(id: "walk_neu_02", category: .walking, text: "Just pacing across your desktop.", tone: .neutral),
        Entry(id: "expl_cur_01", category: .exploring, text: "What's over on this side?", tone: .curious),
        Entry(id: "expl_cur_02", category: .exploring, text: "I haven't seen this corner before!", tone: .curious),
        Entry(id: "expl_cur_03", category: .exploring, text: "Inspecting the desktop perimeter!", tone: .curious),
        Entry(id: "walk_shy_01", category: .walking, text: "Tip-toeing along carefully...", tone: .shy),
        Entry(id: "walk_sarc_01", category: .walking, text: "Just pacing while you contemplate life choices.", tone: .sarcastic),
        Entry(id: "walk_supp_01", category: .walking, text: "Keeping you company one step at a time!", tone: .supportive),
        Entry(id: "expl_ply_01", category: .exploring, text: "Exploring territory like a master adventurer!", tone: .playful),
        Entry(id: "expl_ply_02", category: .exploring, text: "Sneaking around your windows!", tone: .playful),
        Entry(id: "expl_sarc_01", category: .exploring, text: "Searching for something thrilling on this desktop... still searching.", tone: .sarcastic),
        Entry(id: "expl_supp_01", category: .exploring, text: "Exploring the space! Everything looks great around here.", tone: .supportive),
        
        // MARK: Inactivity / Idle
        Entry(id: "idle_neu_01", category: .idle, text: "Standing by.", tone: .neutral),
        Entry(id: "inac_neu_01", category: .inactivity, text: "Quiet around here...", tone: .neutral),
        Entry(id: "inac_cur_01", category: .inactivity, text: "I wonder what you're working on.", tone: .curious),
        Entry(id: "inac_cur_02", category: .inactivity, text: "Waiting patiently for our next adventure!", tone: .curious),
        Entry(id: "inac_slp_01", category: .inactivity, text: "Since you're away, might as well nap.", tone: .sleepy),
        Entry(id: "inac_slp_02", category: .inactivity, text: "Peace and quiet...", tone: .sleepy),
        Entry(id: "inac_ply_01", category: .inactivity, text: "If you leave me alone, I might tap your icons!", tone: .playful),
        Entry(id: "inac_sarc_01", category: .inactivity, text: "Are we doing staring contest practice today?", tone: .sarcastic),
        Entry(id: "inac_supp_01", category: .inactivity, text: "Take your time! I'll hold down the fort.", tone: .supportive),
        
        // MARK: Cursor Interaction & Clicking
        Entry(id: "inte_neu_01", category: .interaction, text: "Hey there!", tone: .neutral),
        Entry(id: "inte_neu_02", category: .interaction, text: "Did you need me?", tone: .neutral),
        Entry(id: "inte_cur_01", category: .interaction, text: "What's that cursor pointing at?", tone: .curious),
        Entry(id: "inte_cur_02", category: .interaction, text: "Looking for me? Here I am!", tone: .curious),
        Entry(id: "inte_shy_01", category: .interaction, text: "...Oh! Careful with the pointer!", tone: .shy),
        Entry(id: "inte_shy_02", category: .interaction, text: "A little gentle, please...", tone: .shy),
        Entry(id: "inte_ply_01", category: .interaction, text: "Boop! Tag, you're it!", tone: .playful),
        Entry(id: "inte_ply_02", category: .interaction, text: "Can't catch me with that mouse!", tone: .playful),
        Entry(id: "inte_chf_01", category: .interaction, text: "Hehe, that tickles!", tone: .cheerful),
        Entry(id: "inte_sarc_01", category: .interaction, text: "Yes, yes, I am very clickable.", tone: .sarcastic),
        Entry(id: "inte_supp_01", category: .interaction, text: "Always here whenever you need a boost!", tone: .supportive),
        
        // MARK: Playful Reactions
        Entry(id: "play_ply_01", category: .playful, text: "Watch this fancy hop!", tone: .playful),
        Entry(id: "play_ply_02", category: .playful, text: "Whoosh! Speedy pet on the run!", tone: .playful),
        Entry(id: "play_cur_01", category: .playful, text: "Found a shiny pixel over here!", tone: .curious),
        
        // MARK: App Observation (Fallbacks if no app name)
        Entry(id: "app_neu_01", category: .appObservation, text: "A change of scenery!", tone: .neutral),
        Entry(id: "app_cur_01", category: .appObservation, text: "Something new is happening!", tone: .curious),
        Entry(id: "app_slp_01", category: .appObservation, text: "New window open? As long as it's quiet...", tone: .sleepy),
        Entry(id: "app_ply_01", category: .appObservation, text: "Ooh, switching tasks? Don't forget me!", tone: .playful),
        
        // MARK: Visual Observations (Level B Context)
        Entry(id: "vis_code_cur_01", category: .visualObservation, text: "Lines of code! Working on something cool?", tone: .curious),
        Entry(id: "vis_code_cur_02", category: .visualObservation, text: "Ooh, development mode! Let's build it!", tone: .curious),
        Entry(id: "vis_code_slp_01", category: .visualObservation, text: "All this code... makes me want to nap.", tone: .sleepy),
        Entry(id: "vis_code_ply_01", category: .visualObservation, text: "Don't let any bugs sneak into production!", tone: .playful),
        Entry(id: "vis_code_neu_01", category: .visualObservation, text: "Coding session in progress.", tone: .neutral),
        Entry(id: "vis_code_sarc_01", category: .visualObservation, text: "Another semicolon, another mystery.", tone: .sarcastic),
        Entry(id: "vis_code_supp_01", category: .visualObservation, text: "Great coding session! You're making real progress!", tone: .supportive),
        
        Entry(id: "vis_game_ply_01", category: .visualObservation, text: "Game time! Go for the high score!", tone: .playful),
        Entry(id: "vis_game_cur_01", category: .visualObservation, text: "Whoa, intense gameplay! What level is this?", tone: .curious),
        Entry(id: "vis_game_shy_01", category: .visualObservation, text: "Looks exciting... I'll cheer from the corner!", tone: .shy),
        Entry(id: "vis_game_neu_01", category: .visualObservation, text: "Good luck with your game!", tone: .neutral),
        Entry(id: "vis_game_sarc_01", category: .visualObservation, text: "Was that move part of a grand master strategy?", tone: .sarcastic),
        Entry(id: "vis_game_supp_01", category: .visualObservation, text: "You can do this! Epic gaming moments!", tone: .supportive),
        
        Entry(id: "vis_vid_cur_01", category: .visualObservation, text: "Ooh, what are we watching?", tone: .curious),
        Entry(id: "vis_vid_slp_01", category: .visualObservation, text: "Nice video... good background noise for a nap.", tone: .sleepy),
        Entry(id: "vis_vid_ply_01", category: .visualObservation, text: "Best seat in the house for this show!", tone: .playful),
        Entry(id: "vis_vid_neu_01", category: .visualObservation, text: "Enjoying the screen view.", tone: .neutral),
        Entry(id: "vis_vid_sarc_01", category: .visualObservation, text: "Very productive screen viewing, I see.", tone: .sarcastic),
        Entry(id: "vis_vid_supp_01", category: .visualObservation, text: "Enjoy your show! Well-deserved downtime.", tone: .supportive),
        
        Entry(id: "vis_read_cur_01", category: .visualObservation, text: "Reading something interesting?", tone: .curious),
        Entry(id: "vis_read_slp_01", category: .visualObservation, text: "Reading time... feels like story time.", tone: .sleepy),
        Entry(id: "vis_read_neu_01", category: .visualObservation, text: "Browsing along quietly.", tone: .neutral),
        Entry(id: "vis_read_supp_01", category: .visualObservation, text: "Deep in study! You're expanding your mind!", tone: .supportive),
        Entry(id: "vis_read_sarc_01", category: .visualObservation, text: "Ah yes, more tabs to never read again.", tone: .sarcastic),
        
        Entry(id: "vis_art_cur_01", category: .visualObservation, text: "Making art? The colors look fantastic!", tone: .curious),
        Entry(id: "vis_art_ply_01", category: .visualObservation, text: "Creative mode! Can you draw me next?", tone: .playful),
        Entry(id: "vis_art_neu_01", category: .visualObservation, text: "Creative canvas looking good.", tone: .neutral),
        Entry(id: "vis_art_supp_01", category: .visualObservation, text: "Your creative vision is inspiring!", tone: .supportive),
        
        Entry(id: "vis_desk_neu_01", category: .visualObservation, text: "Desktop is looking clean today.", tone: .neutral),
        Entry(id: "vis_desk_cur_01", category: .visualObservation, text: "Standing by on your screen!", tone: .curious),
        
        // MARK: Falling
        Entry(id: "fall_neu_01", category: .falling, text: "Whoaaa, going down!", tone: .neutral),
        Entry(id: "fall_cur_01", category: .falling, text: "Wheee! Gravity in action!", tone: .curious),
        Entry(id: "fall_slp_01", category: .falling, text: "Falling... please let there be a pillow.", tone: .sleepy),
        Entry(id: "fall_shy_01", category: .falling, text: "...Eep! Too high!", tone: .shy),
        Entry(id: "fall_ply_01", category: .falling, text: "Skydiving mode activated!", tone: .playful),
        Entry(id: "fall_sarc_01", category: .falling, text: "Down we go. Dignity not included.", tone: .sarcastic),
        Entry(id: "fall_supp_01", category: .falling, text: "Hang on tight, we'll land safely!", tone: .supportive),
        
        // MARK: Landing & Environmental Encounters
        Entry(id: "land_neu_01", category: .environmental, text: "Landed safely on solid ground.", tone: .neutral),
        Entry(id: "land_cur_01", category: .environmental, text: "Touchdown! What's down here?", tone: .curious),
        Entry(id: "land_slp_01", category: .environmental, text: "Flat on the floor... I'll just stay here.", tone: .sleepy),
        Entry(id: "land_shy_01", category: .environmental, text: "Phew... safe ground again.", tone: .shy),
        Entry(id: "land_ply_01", category: .environmental, text: "Superhero landing! Ten out of ten!", tone: .playful),
        Entry(id: "land_sarc_01", category: .environmental, text: "Gravity wins, as expected.", tone: .sarcastic),
        Entry(id: "land_supp_01", category: .environmental, text: "Stuck the landing! Good as new!", tone: .supportive),
        
        Entry(id: "obs_neu_01", category: .environmental, text: "Reached the edge of the window.", tone: .neutral),
        Entry(id: "obs_cur_01", category: .environmental, text: "A border! Can we explore beyond this?", tone: .curious),
        Entry(id: "obs_slp_01", category: .environmental, text: "Can't go further? Guess I'll nap here.", tone: .sleepy),
        Entry(id: "obs_shy_01", category: .environmental, text: "Too close to the edge...", tone: .shy),
        Entry(id: "obs_ply_01", category: .environmental, text: "Boing! Rebounding off the obstacle!", tone: .playful),
        Entry(id: "obs_sarc_01", category: .environmental, text: "An immovable edge. Classic.", tone: .sarcastic),
        Entry(id: "obs_supp_01", category: .environmental, text: "Just an edge! Turning around!", tone: .supportive),
        
        // MARK: Music Playing
        Entry(id: "mus_neu_01", category: .music, text: "Nice soundtrack playing!", tone: .neutral),
        Entry(id: "mus_cur_01", category: .music, text: "Ooh, what track is this?", tone: .curious),
        Entry(id: "mus_slp_01", category: .music, text: "This melody is perfect for a cozy nap.", tone: .sleepy),
        Entry(id: "mus_shy_01", category: .music, text: "I like listening along quietly...", tone: .shy),
        Entry(id: "mus_ply_01", category: .music, text: "Dancin' along with the music!", tone: .playful),
        Entry(id: "mus_sarc_01", category: .music, text: "Quite a soundtrack you've chosen today.", tone: .sarcastic),
        Entry(id: "mus_supp_01", category: .music, text: "Great music to keep you inspired!", tone: .supportive)
    ]
}

// MARK: - Rule-Based Dialogue Provider
public class RuleBasedDialogueProvider: DialogueProvider {
    public init() {}
    
    public func selectDialogue<R: RandomSource>(
        context: DialogueContext,
        profile: DialogueProfile,
        recentIds: [String],
        randomSource: inout R
    ) -> DialogueMessage? {
        // 1. Direct App Observation with dynamic App Name
        if case .appActivated(let appName) = context.trigger {
            guard profile.contextualCommentsEnabled else { return nil }
            return generateAppComment(appName: appName, context: context, recentIds: recentIds)
        }
        
        // 1b. Visual Observation (Level B screen awareness)
        if case .visualObservation(let cat, let summary) = context.trigger {
            guard profile.contextualCommentsEnabled else { return nil }
            return generateVisualComment(category: cat, summary: summary, context: context, recentIds: recentIds, randomSource: &randomSource)
        }
        
        // 1c. Music Playing acknowledgment with dynamic track name
        if case .musicPlaying(let track) = context.trigger {
            guard profile.contextualCommentsEnabled else { return nil }
            return generateMusicComment(track: track, context: context, recentIds: recentIds)
        }
        
        // 1d. Obstacle / Ledge encounter
        if case .ledgeOrObstacle(let obstacle) = context.trigger {
            guard profile.contextualCommentsEnabled else { return nil }
            return generateObstacleComment(obstacle: obstacle, context: context, recentIds: recentIds, randomSource: &randomSource)
        }
        
        // 2. Drag Released acknowledgment
        if context.trigger == .dragReleased {
            guard profile.directInteractionEnabled else { return nil }
            return generateDragReleasedComment(context: context)
        }
        
        // 3. User Returned acknowledgment
        if context.trigger == .userReturned {
            return generateUserReturnedComment(context: context)
        }
        
        // 4. Map Trigger to Category
        guard let category = categoryForTrigger(context.trigger) else { return nil }
        
        // Check profile category preferences
        if !profile.preferredCategories.contains(category) && category != .interaction {
            // Half chance of skipping if not in preferred categories
            if randomSource.nextDouble() < 0.5 { return nil }
        }
        
        // 5. Filter Candidate Entries
        let candidates = DialogueLibrary.entries.filter { entry in
            entry.category == category && !recentIds.contains(entry.id)
        }
        
        let pool = candidates.isEmpty ? DialogueLibrary.entries.filter { $0.category == category } : candidates
        guard !pool.isEmpty else { return nil }
        
        // 6. Score candidate entries by personality tone match
        let preferredTone = resolvePreferredTone(context.personality)
        var scoredEntries: [(entry: DialogueLibrary.Entry, weight: Double)] = []
        
        for entry in pool {
            var weight = 1.0
            if entry.tone == preferredTone {
                weight += 2.5
            } else if entry.tone == .neutral {
                weight += 1.0
            } else {
                weight += 0.3
            }
            scoredEntries.append((entry, weight))
        }
        
        // 7. Weighted random selection
        let totalWeight = scoredEntries.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }
        
        let roll = randomSource.nextDouble() * totalWeight
        var accum = 0.0
        var chosenEntry = pool[0]
        
        for item in scoredEntries {
            accum += item.weight
            if roll <= accum {
                chosenEntry = item.entry
                break
            }
        }
        
        return DialogueMessage(
            id: chosenEntry.id,
            text: chosenEntry.text,
            category: chosenEntry.category,
            duration: 4.5,
            timestamp: context.referenceDate
        )
    }
    
    private func categoryForTrigger(_ trigger: DialogueTrigger) -> DialogueCategory? {
        switch trigger {
        case .greeting: return .greeting
        case .wakingUp: return .waking
        case .resting: return .resting
        case .walking: return .walking
        case .exploring: return .exploring
        case .boredom, .userInactivity: return .inactivity
        case .cursorInteraction, .petClicked, .petDragged: return .interaction
        case .appActivated: return .appObservation
        case .visualObservation: return .visualObservation
        case .playfulReaction: return .playful
        case .dragReleased, .userReturned, .landing: return .interaction
        case .falling: return .falling
        case .musicPlaying: return .music
        case .ledgeOrObstacle: return .environmental
        }
    }
    
    private func generateVisualComment<R: RandomSource>(
        category: VisualActivityCategory,
        summary: String,
        context: DialogueContext,
        recentIds: [String],
        randomSource: inout R
    ) -> DialogueMessage {
        let prefix: String
        switch category {
        case .coding: prefix = "vis_code"
        case .gaming: prefix = "vis_game"
        case .video: prefix = "vis_vid"
        case .readingBrowsing: prefix = "vis_read"
        case .creativeWork: prefix = "vis_art"
        case .generalDesktop: prefix = "vis_desk"
        case .unknown: prefix = "vis_desk"
        }
        
        let matchingEntries = DialogueLibrary.entries.filter { $0.id.hasPrefix(prefix) && !recentIds.contains($0.id) }
        let pool = matchingEntries.isEmpty ? DialogueLibrary.entries.filter { $0.id.hasPrefix(prefix) } : matchingEntries
        
        let topic = CharacterInterestTopic.topicForContext(visualCategoryName: category.rawValue)
        let pref = topic.map { context.personality.preference(for: $0) } ?? .neutral
        
        let preferredTone = resolvePreferredTone(context.personality)
        var scored: [(entry: DialogueLibrary.Entry, weight: Double)] = []
        for entry in pool {
            var w = 1.0
            if entry.tone == preferredTone { w += 3.0 }
            else if entry.tone == .neutral { w += 1.0 }
            
            if pref == .like && (entry.tone == .supportive || entry.tone == .playful || entry.tone == .curious) {
                w += 4.0
            } else if pref == .dislike && (entry.tone == .sarcastic || entry.tone == .sleepy) {
                w += 4.0
            } else if pref == .interested && entry.tone == .curious {
                w += 4.0
            }
            
            scored.append((entry, w))
        }
        
        let total = scored.reduce(0.0) { $0 + $1.weight }
        let roll = randomSource.nextDouble() * max(total, 0.1)
        var chosen = pool.first?.text ?? "Observing the screen..."
        var chosenId = pool.first?.id ?? "vis_default"
        var accum = 0.0
        for item in scored {
            accum += item.weight
            if roll <= accum {
                chosen = item.entry.text
                chosenId = item.entry.id
                break
            }
        }
        
        return DialogueMessage(
            id: chosenId,
            text: chosen,
            category: .visualObservation,
            duration: 4.5,
            timestamp: context.referenceDate
        )
    }
    
    public static func resolveToneForPersonality(_ personality: PersonalityProfile) -> DialogueLibrary.PersonalityTone {
        if personality.sarcasm > 0.65 { return .sarcastic }
        if personality.supportiveness > 0.65 { return .supportive }
        if personality.shyness > 0.55 || (personality.sociability < 0.35 && personality.attentionSeeking < 0.35) { return .shy }
        if personality.laziness > 0.65 { return .sleepy }
        if personality.curiosity > 0.65 { return .curious }
        if personality.mischief > 0.65 { return .playful }
        if personality.playfulness > 0.65 { return .cheerful }
        return .neutral
    }
    
    private func resolvePreferredTone(_ personality: PersonalityProfile) -> DialogueLibrary.PersonalityTone {
        return RuleBasedDialogueProvider.resolveToneForPersonality(personality)
    }
    
    private func generateAppComment(appName: String, context: DialogueContext, recentIds: [String]) -> DialogueMessage {
        let safeName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = "app_active_\(safeName.lowercased())"
        
        // Topic-Aware Dialogue Preference
        let topic = CharacterInterestTopic.topicForContext(appName: appName)
        let pref = topic.map { context.personality.preference(for: $0) } ?? .neutral
        
        var text: String
        if pref == .like, let topic = topic {
            text = "Ooh, \(safeName)! You know I love \(topic.displayName)!"
        } else if pref == .dislike, let topic = topic {
            if context.personality.sarcasm > 0.5 {
                text = "More \(topic.displayName)? Truly thrilling."
            } else {
                text = "\(safeName) again? I might take a nap while you do that."
            }
        } else if pref == .interested, let topic = topic {
            text = "Curious what you're working on in \(topic.displayName)!"
        } else if context.personality.sarcasm > 0.65 {
            text = "Back to \(safeName)? Don't let me interrupt the genius at work."
        } else if context.personality.supportiveness > 0.65 {
            text = "Focus mode in \(safeName)! You've got this!"
        } else if context.personality.curiosity > 0.6 {
            text = "Switching to \(safeName)? Let's see what you create!"
        } else if context.personality.laziness > 0.6 {
            text = "Working in \(safeName)? Good, I'll take a nap."
        } else if context.personality.mischief > 0.6 {
            text = "Don't let \(safeName) distract you from giving me treats!"
        } else {
            text = "Focus mode in \(safeName)!"
        }
        
        return DialogueMessage(id: id, text: text, category: .appObservation, duration: 4.5, timestamp: context.referenceDate)
    }
    
    private func generateDragReleasedComment(context: DialogueContext) -> DialogueMessage {
        var text: String
        if context.personality.curiosity > 0.6 {
            text = "New vantage point unlocked!"
        } else if context.personality.laziness > 0.6 {
            text = "Soft landing... right back to resting."
        } else if context.personality.mischief > 0.6 {
            text = "Wheeee! Airborne companion incoming!"
        } else if (context.personality.sociability < 0.35 && context.personality.attentionSeeking < 0.35) {
            text = "Whew, back on solid ground..."
        } else {
            text = "Safe landing! Thanks for the ride."
        }
        
        return DialogueMessage(
            id: "drag_released_\(UUID().uuidString.prefix(6))",
            text: text,
            category: .interaction,
            duration: 4.0,
            timestamp: context.referenceDate
        )
    }
    
    private func generateUserReturnedComment(context: DialogueContext) -> DialogueMessage {
        var text: String
        if context.personality.sociability > 0.6 {
            text = "Welcome back! I missed you!"
        } else if context.personality.supportiveness > 0.6 {
            text = "Welcome back! Ready when you are!"
        } else if context.personality.sarcasm > 0.6 {
            text = "Look who decided to return to duty."
        } else if context.personality.laziness > 0.6 {
            text = "*Yawn*... Oh, you're back already?"
        } else if (context.personality.sociability < 0.35 && context.personality.attentionSeeking < 0.35) {
            text = "...Welcome back."
        } else {
            text = "Welcome back to your desktop!"
        }
        
        return DialogueMessage(
            id: "user_returned_\(UUID().uuidString.prefix(6))",
            text: text,
            category: .greeting,
            duration: 4.5,
            timestamp: context.referenceDate
        )
    }
    
    private func generateMusicComment(track: String, context: DialogueContext, recentIds: [String]) -> DialogueMessage {
        let safeTrack = track.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = "mus_track_\(abs(safeTrack.hashValue))"
        let topicPref = context.personality.preference(for: .music)
        
        var text: String
        if topicPref == .like {
            text = "Grooving to \"\(safeTrack)\"! Such a great track!"
        } else if topicPref == .dislike {
            if context.personality.sarcasm > 0.5 {
                text = "\"\(safeTrack)\"? Really? Our standards have plummeted."
            } else {
                text = "Is \"\(safeTrack)\" almost over? It's a bit loud for me."
            }
        } else if topicPref == .interested {
            text = "Listening to \"\(safeTrack)\"... I wonder who made this?"
        } else if context.personality.sarcasm > 0.65 {
            text = "Now playing: \"\(safeTrack)\". Bold soundtrack choice."
        } else if context.personality.supportiveness > 0.65 {
            text = "\"\(safeTrack)\" is setting a wonderful vibe for you!"
        } else if context.personality.mischief > 0.6 {
            text = "Time to dance around to \"\(safeTrack)\"!"
        } else if context.personality.laziness > 0.6 {
            text = "\"\(safeTrack)\" is so relaxing... might drift to sleep."
        } else {
            text = "Now playing: \"\(safeTrack)\"!"
        }
        
        return DialogueMessage(
            id: id,
            text: text,
            category: .music,
            duration: 4.5,
            timestamp: context.referenceDate
        )
    }
    
    private func generateObstacleComment<R: RandomSource>(
        obstacle: String,
        context: DialogueContext,
        recentIds: [String],
        randomSource: inout R
    ) -> DialogueMessage {
        let matching = DialogueLibrary.entries.filter { $0.id.hasPrefix("obs_") && !recentIds.contains($0.id) }
        let pool = matching.isEmpty ? DialogueLibrary.entries.filter { $0.id.hasPrefix("obs_") } : matching
        let tone = resolvePreferredTone(context.personality)
        let chosen = pool.first(where: { $0.tone == tone }) ?? pool.first ?? DialogueLibrary.Entry(id: "obs_def", category: .environmental, text: "Hit a boundary! Turning around.", tone: .neutral)
        
        return DialogueMessage(
            id: chosen.id,
            text: chosen.text,
            category: .environmental,
            duration: 3.5,
            timestamp: context.referenceDate
        )
    }
}

// MARK: - Dialogue Cooldown Manager
public class DialogueCooldownManager {
    public static let shared = DialogueCooldownManager()
    
    // Global speech throttling
    public var globalMinimumInterval: TimeInterval = 12.0
    public private(set) var lastGlobalSpeechTime: Date = .distantPast
    
    // Per-character tracking
    private var lastSpontaneousDialogueTime: [UUID: Date] = [:]
    private var lastDirectInteractionDialogueTime: [UUID: Date] = [:]
    private var lastCategoryDialogueTime: [UUID: [DialogueCategory: Date]] = [:]
    private var recentMessageIds: [UUID: [String]] = [:]
    
    // Injectable clock for deterministic unit testing
    public var nowProvider: () -> Date = { Date() }
    
    public init() {}
    
    public func canSpeak(
        characterId: UUID,
        category: DialogueCategory,
        isDirectInteraction: Bool,
        dialogueEnabled: Bool,
        quietModeEnabled: Bool,
        frequency: Double,
        referenceDate: Date? = nil
    ) -> Bool {
        let now = referenceDate ?? nowProvider()
        
        // 1. Master kill-switches
        guard dialogueEnabled else { return false }
        guard !quietModeEnabled else { return false }
        
        // 2. Global Minimum Interval (prevents simultaneous overlapping speech on desktop)
        guard now.timeIntervalSince(lastGlobalSpeechTime) >= globalMinimumInterval else {
            return false
        }
        
        // 3. Direct Interaction vs Spontaneous Contextual rules
        if isDirectInteraction {
            let lastInteraction = lastDirectInteractionDialogueTime[characterId] ?? .distantPast
            // Short 8-second cooldown for direct interaction (clicks, drops)
            guard now.timeIntervalSince(lastInteraction) >= 8.0 else {
                return false
            }
        } else {
            // Spontaneous Contextual Cooldown:
            // Base cooldown of 600s (10 min) scaled inversely by frequency (0.1...1.0)
            let baseCooldown: TimeInterval = 600.0
            let effectiveCooldown = baseCooldown / max(frequency, 0.1)
            let lastSpontaneous = lastSpontaneousDialogueTime[characterId] ?? .distantPast
            
            guard now.timeIntervalSince(lastSpontaneous) >= effectiveCooldown else {
                return false
            }
            
            // Category-specific debounce (at least 60s between identical category comments)
            let catTimes = lastCategoryDialogueTime[characterId] ?? [:]
            let lastCatTime = catTimes[category] ?? .distantPast
            guard now.timeIntervalSince(lastCatTime) >= 60.0 else {
                return false
            }
        }
        
        return true
    }
    
    public func recordSpeech(
        characterId: UUID,
        message: DialogueMessage,
        isDirectInteraction: Bool,
        referenceDate: Date? = nil
    ) {
        let now = referenceDate ?? nowProvider()
        lastGlobalSpeechTime = now
        
        if isDirectInteraction {
            lastDirectInteractionDialogueTime[characterId] = now
        } else {
            lastSpontaneousDialogueTime[characterId] = now
            var catTimes = lastCategoryDialogueTime[characterId] ?? [:]
            catTimes[message.category] = now
            lastCategoryDialogueTime[characterId] = catTimes
        }
        
        // Track recent message IDs (bounded to last 5)
        var recents = recentMessageIds[characterId] ?? []
        recents.append(message.id)
        if recents.count > 5 {
            recents.removeFirst()
        }
        recentMessageIds[characterId] = recents
    }
    
    public func recentIds(for characterId: UUID) -> [String] {
        return recentMessageIds[characterId] ?? []
    }
    
    public func resetAll() {
        lastGlobalSpeechTime = .distantPast
        lastSpontaneousDialogueTime.removeAll()
        lastDirectInteractionDialogueTime.removeAll()
        lastCategoryDialogueTime.removeAll()
        recentMessageIds.removeAll()
    }
    
    public func reset(for characterId: UUID) {
        lastSpontaneousDialogueTime.removeValue(forKey: characterId)
        lastDirectInteractionDialogueTime.removeValue(forKey: characterId)
        lastCategoryDialogueTime.removeValue(forKey: characterId)
        recentMessageIds.removeValue(forKey: characterId)
    }
}

// MARK: - Dialogue Engine
public class DialogueEngine: ObservableObject {
    public let characterId: UUID
    public let characterName: String
    @Published public var profile: DialogueProfile
    
    public var provider: DialogueProvider
    public let cooldownManager: DialogueCooldownManager
    
    // Testing injection
    public var randomSource: RandomSource = SystemRandomSource()
    
    public init(
        characterId: UUID = UUID(),
        characterName: String = "Companion",
        profile: DialogueProfile = DialogueProfile(),
        provider: DialogueProvider = RuleBasedDialogueProvider(),
        cooldownManager: DialogueCooldownManager = DialogueCooldownManager.shared
    ) {
        self.characterId = characterId
        self.characterName = characterName
        self.profile = profile
        self.provider = provider
        self.cooldownManager = cooldownManager
    }
    
    public func evaluateTrigger(
        _ trigger: DialogueTrigger,
        personality: PersonalityProfile,
        needs: CharacterNeeds,
        currentAction: CharacterAction,
        appName: String? = nil,
        isDragging: Bool = false,
        dialogueEnabled: Bool = true,
        contextualCommentsEnabled: Bool = true,
        directInteractionResponsesEnabled: Bool = true,
        quietModeEnabled: Bool = false,
        dialogueFrequency: Double = 0.5,
        referenceDate: Date = Date()
    ) -> DialogueMessage? {
        // 1. Suppression during dragging
        guard !isDragging else { return nil }
        
        // 1b. Per-character dialogue mute preference
        guard !personality.behaviorPreferences.dialogueMuted else { return nil }
        
        // 1c. Stale context suppression (prevent bursts if app or timer was stalled > 5.0 seconds)
        let now = cooldownManager.nowProvider()
        guard abs(referenceDate.timeIntervalSince(now)) < 5.0 else { return nil }
        
        // 2. Identify if this is a direct interaction or spontaneous contextual event
        let isDirect: Bool
        let category: DialogueCategory
        switch trigger {
        case .petClicked, .petDragged, .dragReleased:
            isDirect = true
            category = .interaction
            guard directInteractionResponsesEnabled else { return nil }
        case .cursorInteraction:
            isDirect = true
            category = .interaction
            guard directInteractionResponsesEnabled else { return nil }
        case .appActivated:
            isDirect = false
            category = .appObservation
            guard contextualCommentsEnabled else { return nil }
        case .visualObservation:
            isDirect = false
            category = .visualObservation
            guard contextualCommentsEnabled else { return nil }
        case .userInactivity, .boredom:
            isDirect = false
            category = .inactivity
            guard contextualCommentsEnabled else { return nil }
        case .greeting, .userReturned:
            isDirect = false
            category = .greeting
            guard contextualCommentsEnabled else { return nil }
        case .wakingUp:
            isDirect = false
            category = .waking
            guard contextualCommentsEnabled else { return nil }
        case .resting:
            isDirect = false
            category = .resting
            guard contextualCommentsEnabled else { return nil }
        case .walking, .exploring:
            isDirect = false
            category = .exploring
            guard contextualCommentsEnabled else { return nil }
        case .playfulReaction:
            isDirect = false
            category = .playful
            guard contextualCommentsEnabled else { return nil }
        case .falling:
            isDirect = false
            category = .falling
            guard contextualCommentsEnabled else { return nil }
        case .landing, .ledgeOrObstacle:
            isDirect = false
            category = .environmental
            guard contextualCommentsEnabled else { return nil }
        case .musicPlaying:
            isDirect = false
            category = .music
            guard contextualCommentsEnabled else { return nil }
        }
        
        // 3. Combined effective frequency
        let effectiveFreq = profile.communicationFrequency * dialogueFrequency
        
        // 4. Check Cooldowns and Anti-spam
        guard cooldownManager.canSpeak(
            characterId: characterId,
            category: category,
            isDirectInteraction: isDirect,
            dialogueEnabled: dialogueEnabled,
            quietModeEnabled: quietModeEnabled,
            frequency: effectiveFreq,
            referenceDate: referenceDate
        ) else {
            return nil
        }
        
        // 5. Build Compact Dialogue Context
        let context = DialogueContext(
            characterId: characterId,
            characterName: characterName,
            personality: personality,
            currentNeeds: needs,
            currentAction: currentAction,
            trigger: trigger,
            appName: appName,
            referenceDate: referenceDate
        )
        
        // 6. Select Dialogue via Provider
        let recent = cooldownManager.recentIds(for: characterId)
        guard let message = provider.selectDialogue(
            context: context,
            profile: profile,
            recentIds: recent,
            randomSource: &randomSource
        ) else {
            return nil
        }
        
        // 7. Record Speech in Cooldown Manager
        cooldownManager.recordSpeech(
            characterId: characterId,
            message: message,
            isDirectInteraction: isDirect,
            referenceDate: referenceDate
        )
        
        return message
    }
}

// MARK: - Speech Bubble Pointer Shape
public enum SpeechBubblePointerDirection: Sendable {
    case down // Bubble sits above pet, pointer points down
    case up   // Bubble sits below pet, pointer points up
}

public struct SpeechBubblePointer: Shape {
    public let direction: SpeechBubblePointerDirection
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        if direction == .down {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Speech Bubble View
public struct SpeechBubbleView: View {
    public let text: String
    public let direction: SpeechBubblePointerDirection
    public var onDismiss: (() -> Void)?
    
    public init(text: String, direction: SpeechBubblePointerDirection = .down, onDismiss: (() -> Void)? = nil) {
        self.text = text
        self.direction = direction
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if direction == .up {
                SpeechBubblePointer(direction: .up)
                    .frame(width: 14, height: 7)
                    .foregroundColor(Color(NSColor.windowBackgroundColor).opacity(0.95))
            }
            
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(NSColor.windowBackgroundColor).opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.20), radius: 6, x: 0, y: 3)
                )
            
            if direction == .down {
                SpeechBubblePointer(direction: .down)
                    .frame(width: 14, height: 7)
                    .foregroundColor(Color(NSColor.windowBackgroundColor).opacity(0.95))
            }
        }
        .frame(maxWidth: 210)
        .contentShape(Rectangle())
        .onTapGesture {
            onDismiss?()
        }
    }
}

// MARK: - Speech Bubble Panel
public class SpeechBubblePanel: NSPanel {
    public init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 80),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isReleasedWhenClosed = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.ignoresMouseEvents = false // Catches clicks on the bubble for manual dismissal while outside passes through
    }
    
    open override var canBecomeKey: Bool { false }
    open override var canBecomeMain: Bool { false }
    
    @discardableResult
    public func updatePosition(petCenter: NSPoint, petTopY: CGFloat, petBottomY: CGFloat, isUpsideDown: Bool, screen: NSScreen) -> SpeechBubblePointerDirection {
        let bubbleSize = frame.size
        let visible = screen.visibleFrame
        var direction: SpeechBubblePointerDirection = isUpsideDown ? .up : .down
        var x = petCenter.x - (bubbleSize.width / 2)
        var y: CGFloat
        
        if isUpsideDown {
            // Pet walking upside down along menu bar
            y = petBottomY - bubbleSize.height - 4
            direction = .up
        } else {
            // Pet walking on desktop floor or window
            let proposedY = petTopY + 4
            if proposedY + bubbleSize.height > visible.maxY {
                // Insufficient vertical clearance above pet; flip below with upward pointer
                y = petBottomY - bubbleSize.height - 4
                direction = .up
            } else {
                y = proposedY
                direction = .down
            }
        }
        
        // Clamp inside visibleFrame to avoid off-screen clipping
        x = min(max(x, visible.minX + 8), visible.maxX - bubbleSize.width - 8)
        y = min(max(y, visible.minY + 8), visible.maxY - bubbleSize.height - 8)
        
        setFrameOrigin(NSPoint(x: x, y: y))
        return direction
    }
}

// MARK: - Speech Bubble Controller
public class SpeechBubbleController: ObservableObject {
    public private(set) var bubblePanel: SpeechBubblePanel?
    private var dismissTimer: Timer?
    @Published public private(set) var isVisible = false
    @Published public private(set) var currentMessage: DialogueMessage?
    
    public init() {}
    
    deinit {
        close()
    }
    
    public func show(
        message: DialogueMessage,
        petCenter: NSPoint,
        petTopY: CGFloat,
        petBottomY: CGFloat,
        isUpsideDown: Bool,
        screen: NSScreen
    ) {
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        currentMessage = message
        isVisible = true
        
        let panel: SpeechBubblePanel
        if let existing = bubblePanel {
            panel = existing
        } else {
            panel = SpeechBubblePanel()
            self.bubblePanel = panel
        }
        
        // Initial direction check
        let visible = screen.visibleFrame
        var direction: SpeechBubblePointerDirection = isUpsideDown ? .up : .down
        if !isUpsideDown && (petTopY + 4 + 70 > visible.maxY) {
            direction = .up
        }
        
        let hostingView = NSHostingView(rootView: SpeechBubbleView(text: message.text, direction: direction, onDismiss: { [weak self] in
            self?.hide()
        }))
        let fittingSize = hostingView.fittingSize
        panel.setContentSize(fittingSize)
        panel.contentView = hostingView
        let actualDirection = panel.updatePosition(petCenter: petCenter, petTopY: petTopY, petBottomY: petBottomY, isUpsideDown: isUpsideDown, screen: screen)
        
        if actualDirection != direction {
            let updatedHosting = NSHostingView(rootView: SpeechBubbleView(text: message.text, direction: actualDirection, onDismiss: { [weak self] in
                self?.hide()
            }))
            panel.contentView = updatedHosting
        }
        
        if !panel.isVisible {
            panel.alphaValue = 0.0
            panel.orderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                panel.animator().alphaValue = 1.0
            }
        }
        
        // Auto-dismissal timer
        dismissTimer = Timer.scheduledTimer(withTimeInterval: message.duration, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }
    
    public func updatePosition(petCenter: NSPoint, petTopY: CGFloat, petBottomY: CGFloat, isUpsideDown: Bool, screen: NSScreen) {
        guard isVisible, let panel = bubblePanel else { return }
        panel.updatePosition(petCenter: petCenter, petTopY: petTopY, petBottomY: petBottomY, isUpsideDown: isUpsideDown, screen: screen)
    }
    
    public func hide() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        guard isVisible, let panel = bubblePanel else { return }
        isVisible = false
        currentMessage = nil
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            guard let self = self, !self.isVisible else { return }
            self.bubblePanel?.orderOut(nil)
        })
    }
    
    public func close() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        isVisible = false
        currentMessage = nil
        bubblePanel?.close()
        bubblePanel = nil
    }
}
