import Foundation
import SwiftUI
import AppKit
import Combine

// MARK: - 1. The Global Manager (The Factory)
class PetManager: ObservableObject {
    @Published var isPetActive = false
    
    @AppStorage("upsideDownMenuMode") var upsideDownMenuMode = false
    @AppStorage("isPhysicsPaused") var isPhysicsPaused = false
    @AppStorage("isMuted") var isMuted = false
    @AppStorage("isPrivacyShieldActive") var isPrivacyShieldActive = false
    
    @AppStorage("gravityStrength") var gravityStrength: Double = 0.8
    @AppStorage("walkSpeed") var walkSpeed: Double = 2.0
    @AppStorage("eventFrequency") var eventFrequency: Double = 0.5
    
    @AppStorage("discordRPCEnabled") var discordRPCEnabled = true
    @AppStorage("musicSyncEnabled") var musicSyncEnabled = true
    
    // MARK: - Environmental Awareness Settings
    @AppStorage("environmentAwarenessEnabled") var environmentAwarenessEnabled = true
    @AppStorage("appAwarenessEnabled") var appAwarenessEnabled = true
    @AppStorage("cursorTrackingEnabled") var cursorTrackingEnabled = true
    @AppStorage("inactivityTrackingEnabled") var inactivityTrackingEnabled = true
    @AppStorage("reactionFrequency") var reactionFrequency: Double = 0.6
    
    // MARK: - Speech & Dialogue Settings
    @AppStorage("dialogueEnabled") var dialogueEnabled = true
    @AppStorage("contextualCommentaryEnabled") var contextualCommentaryEnabled = true
    @AppStorage("directInteractionResponsesEnabled") var directInteractionResponsesEnabled = true
    @AppStorage("quietModeEnabled") var quietModeEnabled = false
    @AppStorage("dialogueFrequency") var dialogueFrequency: Double = 0.5
    
    // MARK: - Social Behavior & Memory Settings
    @AppStorage("socialInteractionsEnabled") var socialInteractionsEnabled = true
    @AppStorage("memoryEnabled") var memoryEnabled = true
    
    @Published var activePets: [UUID: PetInstance] = [:]
    let musicMonitor = MusicMonitor.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var socialTimer: Timer?
    
    init() {
        // Safe migration: if eventFrequency was stored in legacy 0-100 scale, normalize to 0.0-1.0
        let storedFreq = UserDefaults.standard.double(forKey: "eventFrequency")
        if storedFreq > 1.0 {
            let normalized = min(max(storedFreq / 100.0, 0.0), 1.0)
            self.eventFrequency = normalized
            UserDefaults.standard.set(normalized, forKey: "eventFrequency")
        }
        
        UserDefaults.standard.register(defaults: [
            "environmentAwarenessEnabled": true,
            "appAwarenessEnabled": true,
            "cursorTrackingEnabled": true,
            "inactivityTrackingEnabled": true,
            "reactionFrequency": 0.6,
            "dialogueEnabled": true,
            "contextualCommentaryEnabled": true,
            "directInteractionResponsesEnabled": true,
            "quietModeEnabled": false,
            "dialogueFrequency": 0.5,
            "socialInteractionsEnabled": true,
            "memoryEnabled": true
        ])
        
        syncEnvironmentMonitorSettings()
        
        EnvironmentMonitor.shared.petCentersProvider = { [weak self] in
            guard let self = self else { return [:] }
            return self.activePets.mapValues { $0.centerPoint }
        }
        
        EnvironmentMonitor.shared.onEvent = { [weak self] event in
            self?.dispatchEnvironmentEvent(event)
        }
        
        setupIntegrationObservers()
        setupProductivityObservers()
        startSocialLoop()
    }
    
    private func setupProductivityObservers() {
        ProductivityTimerManager.shared.onPhaseChange = { [weak self] phase, mode in
            DispatchQueue.main.async {
                self?.handleProductivityPhaseChange(phase, mode: mode)
            }
        }
        ProductivityTimerManager.shared.onTimerComplete = { [weak self] mode in
            DispatchQueue.main.async {
                self?.handleProductivityTimerComplete(mode: mode)
            }
        }
    }
    
    private func handleProductivityPhaseChange(_ phase: ProductivitySessionPhase, mode: ProductivitySessionMode) {
        for pet in activePets.values {
            switch phase {
            case .focus:
                switch ProductivityTimerManager.shared.companionFocusBehavior {
                case .sleepQuietly:
                    pet.currentState = .sleeping
                    pet.behaviorEngine.forceAction(.sleeping)
                case .sitIdle:
                    pet.currentState = .idle
                    pet.behaviorEngine.forceAction(.idle)
                case .normal:
                    break
                }
                pet.triggerDialogue(.focusStarted)
            case .breakTime:
                pet.currentState = .walking
                pet.behaviorEngine.forceAction(.walking)
                pet.triggerDialogue(.breakStarted)
            case .completed:
                pet.walkBobOffset = -8.0
                pet.triggerDialogue(.timerFinished)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    pet.walkBobOffset = 0
                }
            case .idle:
                break
            }
        }
    }
    
    private func handleProductivityTimerComplete(mode: ProductivitySessionMode) {
        for pet in activePets.values {
            pet.walkBobOffset = -8.0
            pet.triggerDialogue(.timerFinished)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                pet.walkBobOffset = 0
            }
        }
    }
    
    private func startSocialLoop() {
        socialTimer?.invalidate()
        socialTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPhysicsPaused, self.socialInteractionsEnabled else { return }
            let participants = self.activePets.mapValues { $0 as any SocialParticipant }
            SocialInteractionManager.shared.checkOpportunities(activeParticipants: participants)
            SocialInteractionManager.shared.updateEncounters(activeParticipants: participants)
        }
    }
    
    func syncEnvironmentMonitorSettings() {
        let env = EnvironmentMonitor.shared
        env.isEnabled = environmentAwarenessEnabled
        env.appAwarenessEnabled = appAwarenessEnabled
        env.cursorTrackingEnabled = cursorTrackingEnabled
        env.inactivityTrackingEnabled = inactivityTrackingEnabled
        env.reactionFrequency = reactionFrequency
        
        SocialInteractionManager.shared.isEnabled = socialInteractionsEnabled
        CharacterMemoryStore.shared.isMemoryEnabledGlobally = memoryEnabled
    }
    
    func dismissAllSpeechBubbles() {
        for pet in activePets.values {
            pet.speechBubbleController.hide()
        }
    }
    
    // MARK: - Privacy Shield & Emergency Freeze Controls
    public func pauseAllCompanionsAndMonitoring() {
        isPrivacyShieldActive = true
        isPhysicsPaused = true
        isMuted = true
        dismissAllSpeechBubbles()
        EnvironmentMonitor.shared.stop()
        ScreenAwarenessService.shared.stopPeriodicObservation()
        SocialInteractionManager.shared.cancelActiveEncounters()
    }
    
    public func resumeAllCompanionsAndMonitoring() {
        isPrivacyShieldActive = false
        isPhysicsPaused = false
        isMuted = false
        if environmentAwarenessEnabled {
            EnvironmentMonitor.shared.start()
        }
        if ScreenAwarenessService.shared.isEnabled && ScreenAwarenessService.shared.periodicObservationEnabled {
            ScreenAwarenessService.shared.startPeriodicObservation(companionProvider: { [weak self] in
                self?.activePets.values.first
            })
        }
    }
    
    func dispatchEnvironmentEvent(_ event: EnvironmentEvent) {
        if let targetId = event.targetPetId, let targetPet = activePets[targetId] {
            targetPet.handleEnvironmentEvent(event)
        } else {
            for pet in activePets.values {
                pet.handleEnvironmentEvent(event)
            }
        }
    }
    
    private func setupIntegrationObservers() {
        UserDefaults.standard.publisher(for: \.discordRPCEnabled)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self = self else { return }
                if enabled && !self.activePets.isEmpty {
                    if let firstPet = self.activePets.values.first {
                        DiscordRPC.shared.updateActivity(petName: firstPet.name, state: "Chilling on Desktop")
                    }
                } else {
                    DiscordRPC.shared.clearActivity()
                }
            }
            .store(in: &cancellables)
            
        UserDefaults.standard.publisher(for: \.musicSyncEnabled)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self = self else { return }
                if enabled && !self.activePets.isEmpty {
                    self.musicMonitor.startMonitoring()
                } else {
                    self.musicMonitor.stopMonitoring()
                }
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.syncEnvironmentMonitorSettings()
                if !self.dialogueEnabled || self.quietModeEnabled {
                    self.dismissAllSpeechBubbles()
                }
            }
            .store(in: &cancellables)
    }
    
    func launchPet(url: URL, size: CGFloat) {
        let newPet = PetInstance(url: url, size: size, globalManager: self)
        activePets[newPet.id] = newPet
        isPetActive = true
        
        if discordRPCEnabled {
            DiscordRPC.shared.updateActivity(petName: newPet.name, state: "Chilling on Desktop")
        }
        if musicSyncEnabled {
            musicMonitor.startMonitoring()
        }
    }
    
    func removePet(id: UUID) {
        SocialInteractionManager.shared.cancelEncounter(involving: id, reason: .petDismissed)
        activePets[id]?.closePet()
        activePets.removeValue(forKey: id)
        
        if activePets.isEmpty {
            isPetActive = false
            DiscordRPC.shared.clearActivity()
            musicMonitor.stopMonitoring()
        } else if discordRPCEnabled, let nextPet = activePets.values.first {
            DiscordRPC.shared.updateActivity(petName: nextPet.name, state: "Chilling on Desktop")
        }
    }
    
    func updateProfile(for url: URL, newProfile: PersonalityProfile) {
        PersonalityStorage.shared.saveProfile(newProfile, for: url)
        for pet in activePets.values where pet.url == url {
            pet.updatePersonalityProfile(newProfile)
        }
    }
}

// MARK: - 2. The Individual Pet Controller
class PetInstance: ObservableObject, Identifiable {
    let id = UUID()
    let url: URL
    var globalManager: PetManager
    private var petWindow: NSWindow?
    
    @Published public var behaviorEngine: BehaviorEngine
    @Published public var dialogueEngine: DialogueEngine
    public let speechBubbleController = SpeechBubbleController()
    private var lastBehaviorTickTime = Date()
    
    private var cancellables = Set<AnyCancellable>()
    private var physicsTimer: Timer?
    private var behaviorTimer: Timer?
    
    @Published var petSize: CGFloat
    
    var currentX: CGFloat = CGFloat.random(in: 100...500)
    var currentY: CGFloat = 0
    var isDragging = false
    
    var dragStartMousePos: NSPoint = .zero
    var dragStartWindowPos: NSPoint = .zero
    
    @Published var walkDirectionRight = true
    @Published var isHovering = false
    
    // --- Walking Animation Variables ---
    @Published var walkBobOffset: CGFloat = 0
    private var walkTime: Double = 0
    
    var isFalling = false
    var yVelocity: CGFloat = 0
    
    var name: String {
        url.deletingPathExtension().lastPathComponent
    }
    
    var characterId: String {
        PersonalityStorage.shared.characterId(for: url)
    }
    
    public enum PetState {
        case walking, idle, sleeping
    }
    @Published public var currentState: PetState = .walking
    
    init(url: URL, size: CGFloat, globalManager: PetManager) {
        self.url = url
        self.petSize = size
        self.globalManager = globalManager
        
        let initialProfile = PersonalityStorage.shared.getProfile(for: url)
        self.behaviorEngine = BehaviorEngine(profile: initialProfile)
        let diagProfile = DialogueProfile.fromPersonality(initialProfile)
        self.dialogueEngine = DialogueEngine(characterId: id, characterName: url.deletingPathExtension().lastPathComponent, profile: diagProfile)
        
        createTransparentWindow()
        startPhysicsLoop()
        startBehaviorLoop()
        
        UserDefaults.standard.publisher(for: \.upsideDownMenuMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyGravity() }
            .store(in: &cancellables)
            
        // React to background music updates
        globalManager.musicMonitor.$currentTrack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] track in
                guard let self = self else { return }
                if track != nil && self.currentState == .sleeping {
                    self.currentState = .walking
                    self.behaviorEngine.forceAction(.walking)
                }
            }
            .store(in: &cancellables)
            
        // Reposition if screen topology or display connection changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleScreenParametersChanged()
            }
            .store(in: &cancellables)
            
        // Delayed initial greeting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.triggerDialogue(.greeting)
        }
    }
    
    func updatePersonalityProfile(_ newProfile: PersonalityProfile) {
        behaviorEngine.profile = newProfile.clamped()
        dialogueEngine.profile = DialogueProfile.fromPersonality(newProfile)
    }
    
    var centerPoint: NSPoint {
        let windowSize = petSize + 80
        return NSPoint(x: currentX + (windowSize / 2), y: currentY + (windowSize / 2))
    }
    
    func triggerDialogue(_ trigger: DialogueTrigger, appName: String? = nil) {
        guard globalManager.dialogueEnabled, !globalManager.quietModeEnabled, !isDragging else { return }
        guard !behaviorEngine.profile.behaviorPreferences.dialogueMuted else { return }
        let now = Date()
        if let message = dialogueEngine.evaluateTrigger(
            trigger,
            personality: behaviorEngine.profile,
            needs: behaviorEngine.needs,
            currentAction: behaviorEngine.currentAction,
            appName: appName,
            isDragging: isDragging,
            dialogueEnabled: globalManager.dialogueEnabled,
            contextualCommentsEnabled: globalManager.contextualCommentaryEnabled,
            directInteractionResponsesEnabled: globalManager.directInteractionResponsesEnabled,
            quietModeEnabled: globalManager.quietModeEnabled,
            dialogueFrequency: globalManager.dialogueFrequency,
            referenceDate: now
        ) {
            let screen = currentScreen()
            let windowSize = petSize + 80
            let center = centerPoint
            let topY = currentY + windowSize - 40
            let bottomY = currentY + 40
            speechBubbleController.show(
                message: message,
                petCenter: center,
                petTopY: topY,
                petBottomY: bottomY,
                isUpsideDown: globalManager.upsideDownMenuMode,
                screen: screen
            )
        }
    }
    
    func handleEnvironmentEvent(_ event: EnvironmentEvent) {
        guard !globalManager.isPhysicsPaused, !isFalling, !isHovering, !isDragging else { return }
        let center = centerPoint
        if let newAction = behaviorEngine.handleEnvironmentEvent(
            event,
            petCenter: center,
            walkDirectionRight: &walkDirectionRight,
            eventFrequency: globalManager.eventFrequency,
            reactionFrequency: globalManager.reactionFrequency,
            referenceDate: Date()
        ) {
            applyAction(newAction)
        }
        
        // Trigger contextual dialogue reactions
        switch event.type {
        case .appActivated(_, let appName):
            triggerDialogue(.appActivated(appName: appName), appName: appName)
        case .cursorApproached:
            triggerDialogue(.cursorInteraction)
        case .userInactivityReached(let threshold):
            triggerDialogue(.userInactivity(threshold: threshold))
        case .userInteracted(let type):
            if type == .dragEnd {
                triggerDialogue(.dragReleased)
            } else if type == .click {
                triggerDialogue(.petClicked)
            }
        case .musicTrackChanged(let track):
            if let track = track, !track.isEmpty {
                triggerDialogue(.musicPlaying(track: track))
            }
        case .userReturned:
            triggerDialogue(.userReturned)
        default:
            break
        }
    }
    
    func handleVisualObservation(_ result: ScreenUnderstandingResult) {
        guard globalManager.dialogueEnabled, !globalManager.quietModeEnabled, !isDragging else { return }
        
        // Sleepy low-energy pets ignore visual observations while sleeping
        if currentState == .sleeping && behaviorEngine.profile.laziness > 0.65 {
            return
        }
        
        // Shy pets require higher confidence to comment
        let isShy = (behaviorEngine.profile.sociability < 0.35 && behaviorEngine.profile.attentionSeeking < 0.35)
        if isShy && result.confidence < 0.75 {
            return
        }
        
        triggerDialogue(.visualObservation(category: result.category, summary: result.summary))
    }
    
    func closePet() {
        SocialInteractionManager.shared.cancelEncounter(involving: id, reason: .petDismissed)
        speechBubbleController.close()
        petWindow?.close()
        petWindow = nil
        physicsTimer?.invalidate()
        physicsTimer = nil
        behaviorTimer?.invalidate()
        behaviorTimer = nil
        cancellables.removeAll()
    }
    
    func triggerAlarm(minutes: Int) {
        ProductivityTimerManager.shared.start(mode: .countdown(minutes: minutes))
    }
    
    private func createTransparentWindow() {
        let windowSize = petSize + 80
        
        let window = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: windowSize, height: windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        
        window.contentView = NSHostingView(rootView: PetSpriteView(pet: self))
        window.makeKeyAndOrderFront(nil)
        self.petWindow = window
        
        applyGravity()
    }
    
    func currentScreen() -> NSScreen {
        let windowSize = petSize + 80
        let petMidPoint = NSPoint(x: currentX + (windowSize / 2), y: currentY + (windowSize / 2))
        return NSScreen.screens.first(where: { $0.frame.contains(petMidPoint) }) ?? NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }
    
    private func applyGravity() {
        let screen = currentScreen()
        let totalHeight = petSize + 80
        
        if globalManager.upsideDownMenuMode {
            currentY = screen.visibleFrame.maxY - totalHeight + 40
        } else {
            currentY = screen.visibleFrame.maxY - totalHeight
            isFalling = true
            yVelocity = 0
        }
        updatePosition()
    }
    
    private func startBehaviorLoop() {
        behaviorTimer?.invalidate()
        lastBehaviorTickTime = Date()
        
        // Evaluates personality decisions on a scheduled cadence decoupled from physics
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.globalManager.isPhysicsPaused, !self.isFalling, !self.isHovering, !self.isDragging else { return }
            guard !SocialInteractionManager.shared.isParticipating(petId: self.id) else { return }
            
            let now = Date()
            let elapsed = now.timeIntervalSince(self.lastBehaviorTickTime)
            self.lastBehaviorTickTime = now
            
            if let newAction = self.behaviorEngine.tick(
                elapsed: elapsed,
                eligibleActions: CharacterAction.allCases,
                eventFrequency: self.globalManager.eventFrequency,
                referenceDate: now
            ) {
                self.applyAction(newAction)
            }
        }
    }
    
    private func applyAction(_ action: CharacterAction) {
        let previousState = self.currentState
        switch action {
        case .walking:
            self.currentState = .walking
            if Bool.random() { self.walkDirectionRight.toggle() }
            if previousState == .sleeping {
                triggerDialogue(.wakingUp)
            } else {
                triggerDialogue(.walking)
            }
        case .exploring:
            self.currentState = .walking
            self.walkDirectionRight.toggle()
            triggerDialogue(.exploring)
        case .idle:
            self.currentState = .idle
        case .sleeping:
            self.currentState = .sleeping
            triggerDialogue(.resting)
        }
    }
    
    private func startPhysicsLoop() {
        physicsTimer?.invalidate()
        physicsTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            guard let self = self, !self.globalManager.isPhysicsPaused, !self.isDragging else { return }
            self.physicsTick()
        }
    }
    
    private func physicsTick() {
        let screen = currentScreen()
        let windowSize = petSize + 80
        let currentSpeed = CGFloat(max(globalManager.walkSpeed, 0.5))
        
        if globalManager.upsideDownMenuMode {
            currentY = screen.visibleFrame.maxY - windowSize + 40
            if currentState == .walking && !isHovering {
                currentX += walkDirectionRight ? currentSpeed : -currentSpeed
                
                // --- UPSIDE DOWN BOBBING ---
                walkTime += (0.15 * Double(currentSpeed))
                walkBobOffset = CGFloat(sin(walkTime) * 3.0)
            } else {
                walkTime = 0
                walkBobOffset = 0
            }
            bounceOffScreenEdges(screen: screen)
            updatePosition()
            return
        }
        
        let mainWindow = NSApp.windows.first(where: { $0.title == "Animatto" || ($0.styleMask.contains(.titled) && $0 != self.petWindow) })
        
        var currentFloor = screen.visibleFrame.minY - 40
        var isWalkingOnWindow = false
        
        if let mw = mainWindow, mw.isVisible {
            let mwFrame = mw.frame
            let petMidX = currentX + (windowSize / 2)
            let visualFeetY = currentY + 40
            
            if petMidX >= mwFrame.minX && petMidX <= mwFrame.maxX {
                if visualFeetY >= mwFrame.maxY - 50 {
                    currentFloor = mwFrame.maxY - 40
                    isWalkingOnWindow = true
                } else if visualFeetY >= mwFrame.minY - 50 {
                    currentFloor = mwFrame.minY - 40
                    isWalkingOnWindow = true
                }
            }
        }
        
        if isFalling {
            let sim = CompanionPhysicsSimulator.stepFalling(
                currentY: currentY,
                yVelocity: yVelocity,
                gravity: globalManager.gravityStrength,
                currentFloor: currentFloor
            )
            currentY = sim.newY
            yVelocity = sim.newVelocity
            walkBobOffset = 0 // Reset bob while falling
            
            if sim.didLand {
                isFalling = false
                triggerDialogue(.landing)
            }
        } else {
            if CompanionPhysicsSimulator.shouldStartFalling(currentY: currentY, currentFloor: currentFloor) {
                isFalling = true
                yVelocity = 0
                triggerDialogue(.falling)
            } else {
                let isMusicPlaying = globalManager.musicSyncEnabled && (globalManager.musicMonitor.currentTrack != nil)
                
                if currentState == .walking && !isHovering {
                    currentX += walkDirectionRight ? currentSpeed : -currentSpeed
                    
                    let bobMultiplier = isMusicPlaying ? 0.25 : 0.15
                    let bobHeight = isMusicPlaying ? -6.0 : -4.0
                    walkTime += (bobMultiplier * Double(currentSpeed))
                    walkBobOffset = CGFloat(abs(sin(walkTime)) * bobHeight)
                } else if isMusicPlaying && currentState != .sleeping && !isHovering {
                    walkTime += 0.15
                    walkBobOffset = CGFloat(abs(sin(walkTime)) * -3.0)
                } else {
                    walkTime = 0
                    walkBobOffset = 0 // Reset when standing still
                }
                
                if isWalkingOnWindow, let mw = mainWindow, currentFloor != screen.visibleFrame.minY - 40 {
                    if currentX + windowSize > mw.frame.maxX {
                        walkDirectionRight = false
                        currentX = mw.frame.maxX - windowSize
                        triggerDialogue(.ledgeOrObstacle(obstacle: "window_edge"))
                    } else if currentX < mw.frame.minX {
                        walkDirectionRight = true
                        currentX = mw.frame.minX
                        triggerDialogue(.ledgeOrObstacle(obstacle: "window_edge"))
                    }
                } else {
                    bounceOffScreenEdges(screen: screen)
                }
            }
        }
        updatePosition()
    }
    
    private func bounceOffScreenEdges(screen: NSScreen) {
        let windowSize = petSize + 80
        let targetRightX = currentX + windowSize + 10
        let targetLeftX = currentX - 10
        let midY = currentY + (windowSize / 2)
        
        if currentX + windowSize > screen.visibleFrame.maxX {
            // Check if there is an adjacent screen to the right that the companion can walk onto
            let hasScreenToRight = NSScreen.screens.contains { otherScreen in
                otherScreen != screen && otherScreen.frame.contains(NSPoint(x: targetRightX, y: midY))
            }
            if !hasScreenToRight {
                walkDirectionRight = false
                currentX = screen.visibleFrame.maxX - windowSize
                triggerDialogue(.ledgeOrObstacle(obstacle: "screen_edge"))
            }
        } else if currentX < screen.visibleFrame.minX {
            // Check if there is an adjacent screen to the left that the companion can walk onto
            let hasScreenToLeft = NSScreen.screens.contains { otherScreen in
                otherScreen != screen && otherScreen.frame.contains(NSPoint(x: targetLeftX, y: midY))
            }
            if !hasScreenToLeft {
                walkDirectionRight = true
                currentX = screen.visibleFrame.minX
                triggerDialogue(.ledgeOrObstacle(obstacle: "screen_edge"))
            }
        }
    }
    
    func handleScreenParametersChanged() {
        let windowSize = petSize + 80
        let petRect = NSRect(x: currentX, y: currentY, width: windowSize, height: windowSize)
        let isVisibleOnAnyScreen = NSScreen.screens.contains(where: { screen in
            screen.frame.intersects(petRect)
        })
        
        if !isVisibleOnAnyScreen, let targetScreen = NSScreen.main ?? NSScreen.screens.first {
            currentX = targetScreen.visibleFrame.midX - (windowSize / 2)
            currentY = targetScreen.visibleFrame.minY + 20
            isFalling = true
            yVelocity = 0
            updatePosition()
        }
    }
    
    func updatePosition() {
        petWindow?.setFrameOrigin(NSPoint(x: currentX, y: currentY))
        let windowSize = petSize + 80
        let center = centerPoint
        let topY = currentY + windowSize - 40
        let bottomY = currentY + 40
        speechBubbleController.updatePosition(
            petCenter: center,
            petTopY: topY,
            petBottomY: bottomY,
            isUpsideDown: globalManager.upsideDownMenuMode,
            screen: currentScreen()
        )
    }
}

// MARK: - Visual Observation Receiver Conformance
extension PetInstance: VisualObservationReceiver {
    var characterName: String { name }
    var personalityName: String { behaviorEngine.profile.name }
}

// MARK: - 3. The Visual Pet
struct PetSpriteView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var pet: PetInstance
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            CompanionMediaView(url: pet.url)
                .frame(width: pet.petSize, height: pet.petSize)
                .scaleEffect(x: pet.walkDirectionRight ? 1 : -1)
                // --- APPLIES THE VISUAL HOP TO THE SPRITE ---
                .offset(y: pet.walkBobOffset)
        }
        .frame(width: pet.petSize + 80, height: pet.petSize + 80)
        .rotationEffect(.degrees(pet.globalManager.upsideDownMenuMode ? 180 : 0))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: pet.globalManager.upsideDownMenuMode)
        .contentShape(Rectangle())
        .onHover { isHovered in
            pet.isHovering = isHovered
            if isHovered {
                EnvironmentMonitor.shared.recordUserInteraction(type: .hover, petId: pet.id)
                pet.behaviorEngine.needs.interactWithUser()
                if pet.currentState == .sleeping && pet.behaviorEngine.profile.attentionSeeking > 0.4 {
                    pet.currentState = .idle
                    pet.behaviorEngine.forceAction(.idle)
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { _ in
                    if !pet.isDragging {
                        pet.isDragging = true
                        pet.currentState = .idle
                        pet.speechBubbleController.hide()
                        SocialInteractionManager.shared.cancelEncounter(involving: pet.id, reason: .userInterrupted)
                        pet.behaviorEngine.pauseAutonomousBehavior()
                        pet.behaviorEngine.needs.interactWithUser()
                        EnvironmentMonitor.shared.recordUserInteraction(type: .dragStart, petId: pet.id)
                        pet.dragStartMousePos = NSEvent.mouseLocation
                        pet.dragStartWindowPos = NSPoint(x: pet.currentX, y: pet.currentY)
                    }
                    
                    let currentMouse = NSEvent.mouseLocation
                    let deltaX = currentMouse.x - pet.dragStartMousePos.x
                    let deltaY = currentMouse.y - pet.dragStartMousePos.y
                    
                    pet.currentX = pet.dragStartWindowPos.x + deltaX
                    pet.currentY = pet.dragStartWindowPos.y + deltaY
                    pet.updatePosition()
                }
                .onEnded { _ in
                    pet.isDragging = false
                    pet.isFalling = true
                    EnvironmentMonitor.shared.recordUserInteraction(type: .dragEnd, petId: pet.id)
                    pet.triggerDialogue(.dragReleased)
                    pet.behaviorEngine.resumeAutonomousBehavior()
                    
                    // Keep pet within the bounds of whatever screen it was dropped on
                    let screen = pet.currentScreen()
                    let windowSize = pet.petSize + 80
                    pet.currentX = min(max(pet.currentX, screen.visibleFrame.minX), screen.visibleFrame.maxX - windowSize)
                }
        )
        .contextMenu {
            Button(pet.globalManager.isPhysicsPaused ? "Resume Physics" : "Pause Physics") {
                pet.globalManager.isPhysicsPaused.toggle()
            }
            Button("Dismiss Pet", role: .destructive) {
                pet.globalManager.removePet(id: pet.id)
            }
        }
        .onTapGesture(count: 2) {
            EnvironmentMonitor.shared.recordUserInteraction(type: .click, petId: pet.id)
            pet.triggerDialogue(.petClicked)
            showMenu = true
        }
        .popover(isPresented: $showMenu, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: pet.behaviorEngine.profile.preset?.iconName ?? "sparkles")
                            .foregroundColor(Color.accentColor)
                        Text(pet.behaviorEngine.profile.name)
                            .font(.headline)
                    }
                    HStack(spacing: 4) {
                        Text("Mood:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(pet.behaviorEngine.needs.mood.displayName)
                            .font(.caption)
                            .bold()
                            .foregroundColor(.primary)
                    }
                }
                Divider()
                
                Button(action: {
                    showMenu = false
                    if let window = NSApp.windows.first(where: { $0.title == "Animatto" || ($0.canBecomeMain && $0.level == .normal) }) {
                        window.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    } else {
                        openWindow(id: "main")
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }) {
                    Label("Open Settings", systemImage: "gearshape")
                }
                .buttonStyle(.plain)
                
                Menu {
                    Button("5 Minutes") { pet.triggerAlarm(minutes: 5); showMenu = false }
                    Button("15 Minutes") { pet.triggerAlarm(minutes: 15); showMenu = false }
                    Button("30 Minutes") { pet.triggerAlarm(minutes: 30); showMenu = false }
                    Button("1 Hour") { pet.triggerAlarm(minutes: 60); showMenu = false }
                    Divider()
                    Button("Pomodoro (25m / 5m)") {
                        ProductivityTimerManager.shared.start(mode: .pomodoro)
                        showMenu = false
                    }
                    Button("Long Focus (50m / 10m)") {
                        ProductivityTimerManager.shared.start(mode: .longFocus)
                        showMenu = false
                    }
                    if ProductivityTimerManager.shared.currentPhase != .idle {
                        Divider()
                        Button("Stop Active Timer") {
                            ProductivityTimerManager.shared.stop()
                            showMenu = false
                        }
                    }
                } label: {
                    if ProductivityTimerManager.shared.currentPhase != .idle {
                        Label("Timer: \(ProductivityTimerManager.shared.formattedRemainingTime)", systemImage: "timer")
                    } else {
                        Label("Set Alarm / Timer", systemImage: "alarm")
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    pet.currentState = .sleeping
                    pet.behaviorEngine.forceAction(.sleeping)
                    showMenu = false
                }) {
                    Label("Force Sleep", systemImage: "moon.zzz")
                }
                .buttonStyle(.plain)
                
                Divider()
                
                Button(action: {
                    showMenu = false
                    pet.globalManager.removePet(id: pet.id)
                }) {
                    Label("Dismiss Pet", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .frame(width: 200)
        }
    }
}

// MARK: - SocialParticipant Conformance
extension PetInstance: SocialParticipant {
    public var isUpsideDown: Bool {
        return globalManager.upsideDownMenuMode
    }
    public var isSleeping: Bool {
        return currentState == .sleeping
    }
    public func setWalkingState() {
        currentState = .walking
        behaviorEngine.forceAction(.walking)
    }
    public func setIdleState() {
        currentState = .idle
        behaviorEngine.forceAction(.idle)
    }
}

// MARK: - UserDefaults Extension for Combine
extension UserDefaults {
    @objc dynamic var upsideDownMenuMode: Bool {
        return bool(forKey: "upsideDownMenuMode")
    }
    @objc dynamic var discordRPCEnabled: Bool {
        return bool(forKey: "discordRPCEnabled")
    }
    @objc dynamic var musicSyncEnabled: Bool {
        return bool(forKey: "musicSyncEnabled")
    }
    @objc dynamic var dialogueEnabled: Bool {
        return bool(forKey: "dialogueEnabled")
    }
    @objc dynamic var quietModeEnabled: Bool {
        return bool(forKey: "quietModeEnabled")
    }
}
