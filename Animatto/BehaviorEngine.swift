import Foundation
import Combine

// MARK: - Character Action
public enum CharacterAction: String, Codable, CaseIterable {
    case walking
    case idle
    case sleeping
    case exploring
    
    public var displayName: String {
        switch self {
        case .walking: return "Walking"
        case .idle: return "Idle"
        case .sleeping: return "Sleeping"
        case .exploring: return "Exploring"
        }
    }
    
    public var minimumDuration: TimeInterval {
        switch self {
        case .walking: return 3.0
        case .exploring: return 4.0
        case .idle: return 2.5
        case .sleeping: return 6.0
        }
    }
    
    public var cooldown: TimeInterval {
        switch self {
        case .walking: return 0.0
        case .exploring: return 10.0
        case .idle: return 2.0
        case .sleeping: return 18.0
        }
    }
}

// MARK: - Action History
public struct ActionRecord: Codable, Equatable {
    public let action: CharacterAction
    public let startedAt: Date
    public var duration: TimeInterval
}

public class ActionHistory {
    private(set) var recentActions: [ActionRecord] = []
    private var lastActionEndTime: [CharacterAction: Date] = [:]
    public let maxHistoryCount = 12
    
    public init() {}
    
    public func record(action: CharacterAction, duration: TimeInterval, at date: Date = Date()) {
        let record = ActionRecord(action: action, startedAt: date, duration: duration)
        recentActions.append(record)
        if recentActions.count > maxHistoryCount {
            recentActions.removeFirst()
        }
        lastActionEndTime[action] = date.addingTimeInterval(duration)
    }
    
    public func countOfRecent(_ action: CharacterAction, within count: Int = 3) -> Int {
        let slice = recentActions.suffix(count)
        return slice.filter { $0.action == action }.count
    }
    
    public func timeSinceLast(_ action: CharacterAction, from now: Date = Date()) -> TimeInterval? {
        guard let endTime = lastActionEndTime[action] else { return nil }
        return now.timeIntervalSince(endTime)
    }
    
    public func lastAction() -> CharacterAction? {
        return recentActions.last?.action
    }
    
    public func clear() {
        recentActions.removeAll()
        lastActionEndTime.removeAll()
    }
}

// MARK: - Random Source Protocol
public protocol RandomSource {
    mutating func nextDouble() -> Double
}

public struct SystemRandomSource: RandomSource {
    public init() {}
    public mutating func nextDouble() -> Double {
        return Double.random(in: 0.0..<1.0)
    }
}

public struct SeededRandomSource: RandomSource {
    private var state: UInt64
    public init(seed: UInt64) {
        self.state = seed
    }
    public mutating func nextDouble() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let value = Double(state >> 11) / Double(1 << 53)
        return min(max(value, 0.0), 0.999999999999)
    }
}

// MARK: - Dedicated Behavior Engine
public class BehaviorEngine: ObservableObject {
    @Published public var profile: PersonalityProfile
    @Published public var needs: CharacterNeeds
    @Published public var currentAction: CharacterAction = .walking
    
    public let history = ActionHistory()
    public private(set) var currentActionStartTime: Date = Date()
    public private(set) var isAutonomousPaused = false
    
    public init(profile: PersonalityProfile = PersonalityProfile.preset(.balanced), initialNeeds: CharacterNeeds = CharacterNeeds()) {
        self.profile = profile.clamped()
        self.needs = initialNeeds
        self.currentActionStartTime = Date()
        self.history.record(action: .walking, duration: 1.0, at: currentActionStartTime)
    }
    
    // MARK: - Scoring Algorithm
    
    public func calculateScores(
        eligibleActions: [CharacterAction] = CharacterAction.allCases,
        eventFrequency: Double = 0.5,
        referenceDate: Date = Date()
    ) -> [CharacterAction: Double] {
        var scores: [CharacterAction: Double] = [:]
        
        let normalizedFreq = min(max(eventFrequency, 0.0), 1.0)
        let lastAction = history.lastAction()
        
        for action in eligibleActions {
            var score = 1.0 // Base baseline
            
            switch action {
            case .walking:
                // Walking is driven by energy, restlessness, and energy trait
                score += needs.energy * 4.0
                score += profile.energy * 3.5
                score -= profile.laziness * 3.0
                score += needs.boredom * 2.0
                if needs.energy < 0.20 {
                    score -= 5.0
                }
                
            case .exploring:
                // Exploration is driven heavily by curiosity, boredom, and mischief
                score += profile.curiosity * 5.0
                score += needs.curiosityDrive * 4.0
                score += needs.boredom * 3.0
                score += profile.mischief * 2.5
                score += needs.energy * 2.0
                // High event frequency encourages curiosity excursions
                score += normalizedFreq * 2.0
                if needs.energy < 0.25 {
                    score -= 6.0
                }
                
            case .idle:
                // Idle is driven by laziness and moderate fatigue
                score += profile.laziness * 3.0
                score += (1.0 - needs.energy) * 2.5
                score += profile.shy * 1.5
                // High boredom makes idling unattractive
                score -= needs.boredom * 3.0
                score -= profile.curiosity * 2.0
                
            case .sleeping:
                // Sleep is heavily driven by fatigue and laziness
                let fatigue = (1.0 - needs.energy)
                score += fatigue * 6.5
                score += profile.laziness * 4.5
                score -= profile.energy * 3.0
                // Disincentivize sleep when energy is high unless extremely lazy
                if needs.energy > 0.85 {
                    score -= 10.0
                }
                // High event frequency gives occasional unexpected catnaps
                score += (normalizedFreq - 0.5) * 1.0
            }
            
            // --- Action History Penalties & Cooldowns ---
            
            // Repetition penalty: penalize repeating the exact same action
            if lastAction == action {
                score -= 3.0
            }
            
            // Immediate consecutive repeats penalty (e.g. 2 of the last 3)
            let recentOccurrences = history.countOfRecent(action, within: 3)
            if recentOccurrences >= 2 {
                score -= Double(recentOccurrences) * 2.5
            }
            
            // Cooldown penalty
            if let elapsedSinceLast = history.timeSinceLast(action, from: referenceDate) {
                if elapsedSinceLast < action.cooldown {
                    let remainingCooldown = action.cooldown - elapsedSinceLast
                    score -= remainingCooldown * 0.5
                }
            }
            
            // Floor scores at small positive epsilon so low-scoring actions have a tiny chance
            scores[action] = max(score, 0.05)
        }
        
        return scores
    }
    
    // MARK: - Weighted Action Selection
    
    public func selectAction<R: RandomSource>(
        eligibleActions: [CharacterAction] = CharacterAction.allCases,
        eventFrequency: Double = 0.5,
        randomSource: inout R,
        referenceDate: Date = Date()
    ) -> CharacterAction {
        let scores = calculateScores(eligibleActions: eligibleActions, eventFrequency: eventFrequency, referenceDate: referenceDate)
        
        // Sum of all weights
        var totalWeight: Double = 0.0
        for action in eligibleActions {
            totalWeight += scores[action] ?? 0.05
        }
        
        guard totalWeight > 0.0 else {
            return eligibleActions.first ?? .walking
        }
        
        let roll = randomSource.nextDouble() * totalWeight
        var cumulative: Double = 0.0
        
        for action in eligibleActions {
            let weight = scores[action] ?? 0.05
            cumulative += weight
            if roll <= cumulative {
                return action
            }
        }
        
        return eligibleActions.last ?? .walking
    }
    
    // MARK: - Periodic Engine Tick
    
    public func tick(
        elapsed: TimeInterval,
        eligibleActions: [CharacterAction] = CharacterAction.allCases,
        eventFrequency: Double = 0.5,
        referenceDate: Date = Date()
    ) -> CharacterAction? {
        guard !isAutonomousPaused else { return nil }
        
        // 1. Advance internal needs over elapsed time
        needs.update(elapsedSeconds: elapsed, currentAction: currentAction, profile: profile)
        
        // 2. Check if current action has satisfied its minimum duration
        let durationInCurrent = referenceDate.timeIntervalSince(currentActionStartTime)
        guard durationInCurrent >= currentAction.minimumDuration else {
            return nil // Keep performing current action until minimum duration passes
        }
        
        // 3. Evaluate next candidate action
        var systemRandom = SystemRandomSource()
        let next = selectAction(
            eligibleActions: eligibleActions,
            eventFrequency: eventFrequency,
            randomSource: &systemRandom,
            referenceDate: referenceDate
        )
        
        // If action changed, record transition and return new action
        if next != currentAction {
            history.record(action: currentAction, duration: durationInCurrent, at: currentActionStartTime)
            currentAction = next
            currentActionStartTime = referenceDate
            return next
        }
        
        return nil
    }
    
    // MARK: - Control Overrides
    
    public func pauseAutonomousBehavior() {
        isAutonomousPaused = true
    }
    
    public func resumeAutonomousBehavior(at date: Date = Date()) {
        isAutonomousPaused = false
        currentActionStartTime = date
    }
    
    public func forceAction(_ action: CharacterAction, at date: Date = Date()) {
        let duration = date.timeIntervalSince(currentActionStartTime)
        history.record(action: currentAction, duration: duration, at: currentActionStartTime)
        currentAction = action
        currentActionStartTime = date
    }
}

// Extension to get shy factor cleanly
private extension PersonalityProfile {
    var shy: Double {
        return (1.0 - sociability) * 0.5 + (1.0 - attentionSeeking) * 0.5
    }
}
