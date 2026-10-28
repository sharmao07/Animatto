import Foundation
import SwiftUI
import Combine

// MARK: - Social Participant Protocol
public protocol SocialParticipant: AnyObject {
    var id: UUID { get }
    var name: String { get }
    var characterId: String { get }
    var centerPoint: NSPoint { get }
    var currentX: CGFloat { get set }
    var currentY: CGFloat { get set }
    var isFalling: Bool { get }
    var isHovering: Bool { get }
    var isDragging: Bool { get }
    var isUpsideDown: Bool { get }
    var isSleeping: Bool { get }
    var walkDirectionRight: Bool { get set }
    var walkBobOffset: CGFloat { get set }
    var behaviorEngine: BehaviorEngine { get }
    func setWalkingState()
    func setIdleState()
    func triggerDialogue(_ trigger: DialogueTrigger, appName: String?)
}

// MARK: - Social Action Type
public enum SocialActionType: String, Codable, CaseIterable {
    case greeting            // Brief hello / acknowledgment
    case approachAndObserve  // Walking up to nearby character and observing
    case playfulHop          // Synchronized playful hop or tag
    case friendlyChat        // Short conversational exchange
    case disengage           // Concluding encounter and turning away
    
    public var displayName: String {
        switch self {
        case .greeting: return "Greeting"
        case .approachAndObserve: return "Approach & Observe"
        case .playfulHop: return "Playful Hop"
        case .friendlyChat: return "Friendly Chat"
        case .disengage: return "Disengage"
        }
    }
}

// MARK: - Social Interaction Phase
public enum SocialInteractionPhase: Equatable {
    case idle
    case initiating(action: SocialActionType)
    case approaching(action: SocialActionType, targetLocation: CGFloat, timeout: Date)
    case interacting(action: SocialActionType, concludesAt: Date, step: Int)
    case concluding(action: SocialActionType)
}

// MARK: - Encounter Cancel Reason
public enum EncounterCancelReason: String {
    case userInterrupted    // User clicked or dragged pet
    case physicsPaused      // Physics simulation paused
    case petDismissed       // Companion was closed/removed
    case targetUnreachable  // Target moved away or path blocked
    case declined           // Target declined interaction
}

// MARK: - Active Social Encounter
public struct ActiveSocialEncounter: Equatable, Identifiable {
    public let id: UUID
    public let initiatorId: UUID
    public let targetId: UUID
    public var phase: SocialInteractionPhase
    public var action: SocialActionType
    public var startedAt: Date
    public var lastStateChange: Date
    
    public init(
        id: UUID = UUID(),
        initiatorId: UUID,
        targetId: UUID,
        phase: SocialInteractionPhase,
        action: SocialActionType,
        startedAt: Date = Date(),
        lastStateChange: Date = Date()
    ) {
        self.id = id
        self.initiatorId = initiatorId
        self.targetId = targetId
        self.phase = phase
        self.action = action
        self.startedAt = startedAt
        self.lastStateChange = lastStateChange
    }
    
    public func involves(petId: UUID) -> Bool {
        return initiatorId == petId || targetId == petId
    }
    
    public func partnerId(for petId: UUID) -> UUID? {
        if initiatorId == petId { return targetId }
        if targetId == petId { return initiatorId }
        return nil
    }
}

// MARK: - Social Pair Cooldown Manager
public class SocialPairCooldownManager {
    public var pairCooldownDuration: TimeInterval = 40.0 // 40 seconds between identical pair encounters
    private var lastInteractionTimes: [String: Date] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    private func pairKey(idA: UUID, idB: UUID) -> String {
        let first = min(idA.uuidString, idB.uuidString)
        let second = max(idA.uuidString, idB.uuidString)
        return "\(first)_\(second)"
    }
    
    public func canInteract(petA: UUID, petB: UUID, now: Date) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let key = pairKey(idA: petA, idB: petB)
        guard let lastTime = lastInteractionTimes[key] else { return true }
        return now.timeIntervalSince(lastTime) >= pairCooldownDuration
    }
    
    public func recordInteraction(petA: UUID, petB: UUID, now: Date) {
        lock.lock()
        defer { lock.unlock() }
        let key = pairKey(idA: petA, idB: petB)
        lastInteractionTimes[key] = now
    }
    
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        lastInteractionTimes.removeAll()
    }
}

// MARK: - Social Interaction Manager
public class SocialInteractionManager: ObservableObject {
    public static let shared = SocialInteractionManager()
    
    @Published public var isEnabled: Bool = true
    
    // Spatial constraints
    public var minInteractionRange: CGFloat = 60.0
    public var maxInteractionRange: CGFloat = 380.0
    public var contactDistance: CGFloat = 110.0
    
    // State
    @Published public private(set) var activeEncounters: [UUID: ActiveSocialEncounter] = [:]
    public let pairCooldownManager = SocialPairCooldownManager()
    
    // Injectable clock and randomness for deterministic testing
    public var nowProvider: () -> Date = { Date() }
    public var randomSource: RandomSource = SystemRandomSource()
    
    private let lock = NSLock()
    
    public init() {}
    
    // MARK: - Encounter Lookup
    
    public func isParticipating(petId: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return activeEncounters.values.contains { $0.involves(petId: petId) }
    }
    
    public func encounter(for petId: UUID) -> ActiveSocialEncounter? {
        lock.lock()
        defer { lock.unlock() }
        return activeEncounters.values.first { $0.involves(petId: petId) }
    }
    
    // MARK: - Feasibility Checks
    
    public func checkFeasibility(initiator: any SocialParticipant, target: any SocialParticipant) -> Bool {
        guard isEnabled else { return false }
        guard initiator.id != target.id else { return false }
        
        // Check per-character preferences
        guard initiator.behaviorEngine.profile.behaviorPreferences.socialInteractionsEnabled,
              target.behaviorEngine.profile.behaviorPreferences.socialInteractionsEnabled else {
            return false
        }
        
        // Cannot interact if either is already in an encounter
        guard !isParticipating(petId: initiator.id), !isParticipating(petId: target.id) else {
            return false
        }
        
        // Movement & physics states: neither can be falling, hovering, dragging
        guard !initiator.isFalling, !initiator.isHovering, !initiator.isDragging,
              !target.isFalling, !target.isHovering, !target.isDragging else {
            return false
        }
        
        // Spatial Distance
        let dx = target.centerPoint.x - initiator.centerPoint.x
        let dy = target.centerPoint.y - initiator.centerPoint.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance >= minInteractionRange && distance <= maxInteractionRange else {
            return false
        }
        
        // Surface compatibility:
        // Upside down menu mode must match
        guard initiator.isUpsideDown == target.isUpsideDown else {
            return false
        }
        
        // Floor vertical level must be aligned (within 20pt) so they are on the same floor or window surface
        guard abs(initiator.currentY - target.currentY) <= 25.0 else {
            return false
        }
        
        // Pair Cooldown
        let now = nowProvider()
        guard pairCooldownManager.canInteract(petA: initiator.id, petB: target.id, now: now) else {
            return false
        }
        
        // Sleeping Target Policy:
        // Highly lazy and independent targets decline waking for casual encounters
        if target.isSleeping {
            if target.behaviorEngine.profile.laziness > 0.7 && target.behaviorEngine.profile.independence > 0.6 {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Personality-Driven Intent Selection
    
    public func selectSocialIntent<R: RandomSource>(
        initiator: any SocialParticipant,
        target: any SocialParticipant,
        randomSource: inout R
    ) -> SocialActionType? {
        let pInit = initiator.behaviorEngine.profile
        let pTarget = target.behaviorEngine.profile
        
        // Independence check: very independent characters prefer solo roaming
        if pInit.independence > 0.85 && randomSource.nextDouble() < 0.6 {
            return nil
        }
        
        // Shyness check: very shy characters hesitate to initiate
        if pInit.shyness > 0.75 && randomSource.nextDouble() < 0.5 {
            // Shy companion observes from safe distance rather than initiating conversation
            return .approachAndObserve
        }
        
        // Playful & mischievous characters prefer playful activities
        if (pInit.playfulness > 0.65 || pInit.mischief > 0.65) && pInit.energy > 0.4 {
            if !target.isSleeping && pTarget.shyness < 0.85 {
                return .playfulHop
            }
        }
        
        // Sociable characters prefer greetings and chats
        if pInit.sociability > 0.60 {
            if randomSource.nextDouble() < 0.5 {
                return .greeting
            } else {
                return .friendlyChat
            }
        }
        
        // Curious characters explore and observe
        if pInit.curiosity > 0.60 {
            return .approachAndObserve
        }
        
        // Balanced default
        let roll = randomSource.nextDouble()
        if roll < 0.4 {
            return .greeting
        } else if roll < 0.7 {
            return .approachAndObserve
        } else {
            return .playfulHop
        }
    }
    
    // MARK: - Periodic Opportunity Check
    
    public func checkOpportunities(activeParticipants: [UUID: any SocialParticipant]) {
        guard isEnabled, activeParticipants.count >= 2 else { return }
        
        let pets = activeParticipants.values.sorted(by: { $0.id.uuidString < $1.id.uuidString })
        let now = nowProvider()
        
        for i in 0..<pets.count {
            let initiator = pets[i]
            guard !isParticipating(petId: initiator.id) else { continue }
            
            for j in 0..<pets.count where i != j {
                let target = pets[j]
                guard !isParticipating(petId: target.id) else { continue }
                
                if checkFeasibility(initiator: initiator, target: target) {
                    if let action = selectSocialIntent(initiator: initiator, target: target, randomSource: &randomSource) {
                        startEncounter(initiator: initiator, target: target, action: action, now: now)
                        return // Start one encounter per evaluation cycle to prevent chaos
                    }
                }
            }
        }
    }
    
    // MARK: - Encounter Lifecycle
    
    private func startEncounter(initiator: any SocialParticipant, target: any SocialParticipant, action: SocialActionType, now: Date) {
        lock.lock()
        defer { lock.unlock() }
        
        let encounterId = UUID()
        let distance = abs(target.currentX - initiator.currentX)
        
        let initialPhase: SocialInteractionPhase
        if distance <= contactDistance {
            // Already close enough to immediately engage
            let duration: TimeInterval = (action == .playfulHop) ? 4.0 : 3.0
            initialPhase = .interacting(action: action, concludesAt: now.addingTimeInterval(duration), step: 0)
        } else {
            // Approach needed
            let timeout = now.addingTimeInterval(6.0)
            initialPhase = .approaching(action: action, targetLocation: target.currentX, timeout: timeout)
        }
        
        let encounter = ActiveSocialEncounter(
            id: encounterId,
            initiatorId: initiator.id,
            targetId: target.id,
            phase: initialPhase,
            action: action,
            startedAt: now,
            lastStateChange: now
        )
        
        activeEncounters[encounterId] = encounter
    }
    
    // MARK: - State Machine Tick Update
    
    public func updateEncounters(activeParticipants: [UUID: any SocialParticipant]) {
        guard isEnabled else {
            cancelAllEncounters()
            return
        }
        
        let now = nowProvider()
        var completedIds: [UUID] = []
        
        lock.lock()
        let currentEncounters = Array(activeEncounters.values)
        lock.unlock()
        
        for var encounter in currentEncounters {
            guard let initiator = activeParticipants[encounter.initiatorId],
                  let target = activeParticipants[encounter.targetId] else {
                cancelEncounter(involving: encounter.initiatorId, reason: .petDismissed)
                continue
            }
            
            // Check if user interrupted with drag or pet fell
            if initiator.isDragging || target.isDragging || initiator.isFalling || target.isFalling {
                cancelEncounter(involving: initiator.id, reason: .userInterrupted)
                continue
            }
            
            switch encounter.phase {
            case .idle:
                break
                
            case .initiating(let action):
                let timeout = now.addingTimeInterval(6.0)
                encounter.phase = .approaching(action: action, targetLocation: target.currentX, timeout: timeout)
                encounter.lastStateChange = now
                saveEncounter(encounter)
                
            case .approaching(let action, _, let timeout):
                if now >= timeout {
                    // Timeout approaching target
                    cancelEncounter(involving: initiator.id, reason: .targetUnreachable)
                    continue
                }
                
                let dx = target.currentX - initiator.currentX
                let distance = abs(dx)
                
                if distance <= contactDistance {
                    // Reached interaction proximity!
                    let duration: TimeInterval = (action == .playfulHop) ? 4.0 : 3.0
                    encounter.phase = .interacting(action: action, concludesAt: now.addingTimeInterval(duration), step: 0)
                    encounter.lastStateChange = now
                    saveEncounter(encounter)
                } else {
                    // Steer initiator towards target using normal walking
                    initiator.walkDirectionRight = (dx > 0)
                    initiator.setWalkingState()
                }
                
            case .interacting(let action, let concludesAt, let step):
                // Both pets face each other
                let dx = target.currentX - initiator.currentX
                initiator.walkDirectionRight = (dx > 0)
                target.walkDirectionRight = (dx < 0)
                
                // Wake sleepy target if playful
                if target.isSleeping && action == .playfulHop {
                    target.setIdleState()
                }
                
                // Coordinated Dialogue Execution
                if step == 0 {
                    // Step 0: Initiator triggers opening dialogue
                    executeSocialActionDialogue(initiator: initiator, partner: target, action: action, isInitiator: true)
                    
                    if action == .playfulHop {
                        initiator.walkBobOffset = -6.0
                        target.walkBobOffset = -6.0
                    }
                    
                    encounter.phase = .interacting(action: action, concludesAt: concludesAt, step: 1)
                    encounter.lastStateChange = now
                    saveEncounter(encounter)
                } else if step == 1 && now.timeIntervalSince(encounter.lastStateChange) >= 1.5 {
                    // Step 1: Target responds after a natural 1.5s delay
                    executeSocialActionDialogue(initiator: target, partner: initiator, action: action, isInitiator: false)
                    encounter.phase = .interacting(action: action, concludesAt: concludesAt, step: 2)
                    saveEncounter(encounter)
                }
                
                if now >= concludesAt {
                    encounter.phase = .concluding(action: action)
                    encounter.lastStateChange = now
                    saveEncounter(encounter)
                }
                
            case .concluding(let action):
                // Finish encounter
                concludeEncounter(encounter: encounter, initiator: initiator, target: target, action: action, now: now)
                completedIds.append(encounter.id)
            }
        }
        
        lock.lock()
        for id in completedIds {
            activeEncounters.removeValue(forKey: id)
        }
        lock.unlock()
    }
    
    private func saveEncounter(_ encounter: ActiveSocialEncounter) {
        lock.lock()
        activeEncounters[encounter.id] = encounter
        lock.unlock()
    }
    
    // MARK: - Coordinated Dialogue Execution
    
    private func executeSocialActionDialogue(
        initiator: any SocialParticipant,
        partner: any SocialParticipant,
        action: SocialActionType,
        isInitiator: Bool
    ) {
        let trigger: DialogueTrigger
        switch action {
        case .greeting:
            trigger = isInitiator ? .socialGreeting(partnerName: partner.name) : .socialResponse(partnerName: partner.name)
        case .friendlyChat:
            trigger = isInitiator ? .socialGreeting(partnerName: partner.name) : .socialResponse(partnerName: partner.name)
        case .playfulHop:
            trigger = .socialPlay(partnerName: partner.name)
        case .approachAndObserve:
            if isInitiator {
                trigger = .socialGreeting(partnerName: partner.name)
            } else {
                return // Target quietly acknowledges
            }
        case .disengage:
            trigger = .socialDisengage(partnerName: partner.name)
        }
        
        initiator.triggerDialogue(trigger, appName: nil)
    }
    
    // MARK: - Natural Conclusion
    
    private func concludeEncounter(
        encounter: ActiveSocialEncounter,
        initiator: any SocialParticipant,
        target: any SocialParticipant,
        action: SocialActionType,
        now: Date
    ) {
        // 1. Record in Memory Store
        let store = CharacterMemoryStore.shared
        let isDurable = (action == .playfulHop || action == .friendlyChat)
        store.recordSocialEncounter(
            characterId: initiator.characterId,
            partnerId: target.characterId,
            partnerName: target.name,
            actionType: action.rawValue,
            isDurable: isDurable
        )
        store.recordSocialEncounter(
            characterId: target.characterId,
            partnerId: initiator.characterId,
            partnerName: initiator.name,
            actionType: action.rawValue,
            isDurable: isDurable
        )
        
        // 2. Set Pair Cooldown
        pairCooldownManager.recordInteraction(petA: initiator.id, petB: target.id, now: now)
        
        // 3. Smooth Disengagement: turn slightly away and resume autonomous walking
        initiator.walkDirectionRight.toggle()
        initiator.setWalkingState()
        
        target.walkBobOffset = 0
        initiator.walkBobOffset = 0
    }
    
    // MARK: - Interruption & Cancellation
    
    public func cancelEncounter(involving petId: UUID, reason: EncounterCancelReason = .userInterrupted) {
        lock.lock()
        defer { lock.unlock() }
        
        var toRemove: [UUID] = []
        for (id, enc) in activeEncounters where enc.involves(petId: petId) {
            toRemove.append(id)
        }
        
        for id in toRemove {
            activeEncounters.removeValue(forKey: id)
        }
    }
    
    public func cancelAllEncounters() {
        lock.lock()
        defer { lock.unlock() }
        activeEncounters.removeAll()
    }
}
