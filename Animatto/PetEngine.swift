import Foundation
import SwiftUI
import AppKit
import Combine

// MARK: - 1. The Global Manager (The Factory)
class PetManager: ObservableObject {
    public static var shared: PetManager?
    
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
        PetManager.shared = self
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
        updateSharedPhysicsTimer()
        dismissAllSpeechBubbles()
        EnvironmentMonitor.shared.stop()
        ScreenAwarenessService.shared.stopPeriodicObservation()
        SocialInteractionManager.shared.cancelActiveEncounters()
    }
    
    public func resumeAllCompanionsAndMonitoring() {
        isPrivacyShieldActive = false
        isPhysicsPaused = false
        isMuted = false
        updateSharedPhysicsTimer()
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
    
    // Coordinated central physics loop for battery & CPU efficiency
    private var sharedPhysicsTimer: Timer?
    
    public var isSharedPhysicsTimerActive: Bool {
        return sharedPhysicsTimer != nil
    }
    
    public func updateSharedPhysicsTimer() {
        let hasActiveCompanions = activePets.values.contains { !$0.isAquariumTransformed }
        if activePets.isEmpty || isPhysicsPaused || !hasActiveCompanions {
            sharedPhysicsTimer?.invalidate()
            sharedPhysicsTimer = nil
        } else if sharedPhysicsTimer == nil {
            sharedPhysicsTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
                guard let self = self, !self.isPhysicsPaused else { return }
                for pet in self.activePets.values {
                    guard !pet.isDragging else { continue }
                    pet.physicsTick()
                }
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
                self.updateSharedPhysicsTimer()
                if !self.dialogueEnabled || self.quietModeEnabled {
                    self.dismissAllSpeechBubbles()
                }
            }
            .store(in: &cancellables)
            
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.screensDidSleepNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPhysicsPaused = true
                self?.updateSharedPhysicsTimer()
            }
            .store(in: &cancellables)

        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.screensDidWakeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isPhysicsPaused = false
                self?.updateSharedPhysicsTimer()
            }
            .store(in: &cancellables)
    }
    
    func ensureDefaultWidget() {
        guard activePets.isEmpty else { return }
        let storage = PetStorage()
        if let first = storage.savedPets.first {
            launchPet(url: first, size: 128)
        } else if let catURL = Bundle.main.url(forResource: "animatto_cat", withExtension: "png") {
            launchPet(url: catURL, size: 128)
        } else {
            let defaultURL = PetStorage.getStorageDirectory().appendingPathComponent("animatto_cat.png")
            launchPet(url: defaultURL, size: 128)
        }
    }
    
    func launchPet(url: URL, size: CGFloat) {
        let newPet = PetInstance(url: url, size: size, globalManager: self)
        newPet.isManagedExternally = true
        newPet.stopIndependentPhysicsTimer()
        activePets[newPet.id] = newPet
        isPetActive = true
        updateSharedPhysicsTimer()
        
        // If Aquarium Mode is currently active, transform the new desktop widget immediately
        if AquariumManager.shared.isVisible {
            newPet.transformToAquarium(settings: AquariumManager.shared.settings)
            updateSharedPhysicsTimer()
        }
        
        if discordRPCEnabled {
            DiscordRPC.shared.updateActivity(petName: newPet.name, state: "Chilling on Desktop")
        }
        if musicSyncEnabled {
            musicMonitor.startMonitoring()
        }
    }
    
    @discardableResult
    func launchAquariumForDesktopWidget(frame: CGRect, settings: AquariumSettings, widgetTitle: String = "Desktop Widget") -> PetInstance {
        let storage = PetStorage()
        let url = storage.savedPets.first ??
                  Bundle.main.url(forResource: "widget_aquarium", withExtension: "png") ??
                  PetStorage.getStorageDirectory().appendingPathComponent("widget_aquarium.png")
        
        let newPet = PetInstance(url: url, size: min(frame.width, frame.height), globalManager: self, isDesktopWidgetReplacement: true)
        newPet.isManagedExternally = true
        newPet.stopIndependentPhysicsTimer()
        
        // Position directly at the desktop widget's exact frame
        newPet.currentX = frame.origin.x
        newPet.currentY = frame.origin.y
        newPet.customWidgetDimensions = frame.size
        newPet.petWindow?.setFrame(frame, display: true, animate: false)
        // Anchor strictly to desktop Space so it never floats over full-screen apps or other Spaces
        newPet.petWindow?.collectionBehavior = [.stationary]
        // Higher than macOS desktop widgets (-2147483601), and below normal app windows (0)
        newPet.petWindow?.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) + 3)
        
        newPet.transformToAquarium(settings: settings)
        newPet.applyAquariumDimensions(frame.size)
        
        activePets[newPet.id] = newPet
        isPetActive = true
        updateSharedPhysicsTimer()
        newPet.petWindow?.orderFront(nil)
        return newPet
    }
    
    func removePet(id: UUID) {
        guard let pet = activePets[id] else { return }
        SocialInteractionManager.shared.cancelEncounter(involving: id, reason: .petDismissed)
        // Immediately order out window so it vanishes with zero visual artifact flash
        pet.petWindow?.orderOut(nil)
        pet.closePet()
        activePets.removeValue(forKey: id)
        updateSharedPhysicsTimer()
        
        if activePets.isEmpty {
            isPetActive = false
            DiscordRPC.shared.clearActivity()
            musicMonitor.stopMonitoring()
        } else if discordRPCEnabled, let nextPet = activePets.values.first {
            DiscordRPC.shared.updateActivity(petName: nextPet.name, state: "Chilling on Desktop")
        }
    }
    
    func dismissAllCompanions() {
        let allPets = Array(activePets.values)
        for pet in allPets {
            SocialInteractionManager.shared.cancelEncounter(involving: pet.id, reason: .petDismissed)
            pet.petWindow?.orderOut(nil)
            pet.closePet()
        }
        activePets.removeAll()
        updateSharedPhysicsTimer()
        isPetActive = false
        DiscordRPC.shared.clearActivity()
        musicMonitor.stopMonitoring()
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
    var petWindow: NSWindow?
    
    func bringToFront() {
        petWindow?.orderFrontRegardless()
    }
    
    func toggleVisibility() {
        guard let win = petWindow else { return }
        if win.isVisible {
            win.orderOut(nil)
        } else {
            win.orderFrontRegardless()
        }
    }
    
    @Published public var behaviorEngine: BehaviorEngine
    @Published public var dialogueEngine: DialogueEngine
    public let speechBubbleController = SpeechBubbleController()
    private var lastBehaviorTickTime = Date()
    
    public var isManagedExternally: Bool = false
    private var cachedScreen: NSScreen?
    
    public func stopIndependentPhysicsTimer() {
        physicsTimer?.invalidate()
        physicsTimer = nil
    }
    
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
    public var currentPlatform: WindowPlatform? = nil
    private var lastRenderedOrigin: NSPoint = NSPoint(x: -9999, y: -9999)
    public private(set) var completedPhysicsTicks: UInt64 = 0
    
    // Aquarium Observation (Stage 4.5)
    public private(set) var isObservingAquarium: Bool = false
    public var aquariumObservationCooldown: TimeInterval = 0.0
    private var aquariumObservationTimer: TimeInterval = 0.0
    
    // MARK: - Aquarium Mode Transformation State
    @Published public var isAquariumTransformed: Bool = false
    @Published public var aquariumState: AquariumWidgetState? = nil
    @Published public var customWidgetDimensions: CGSize? = nil
    public var isDesktopWidgetReplacement: Bool = false
    
    public var currentWidgetSize: CGSize {
        if let custom = customWidgetDimensions {
            return custom
        }
        let base = petSize + 80
        return CGSize(width: base, height: base)
    }
    
    public func transformToAquarium(settings: AquariumSettings) {
        guard !isAquariumTransformed else { return }
        isAquariumTransformed = true
        isFalling = false
        yVelocity = 0
        walkBobOffset = 0
        speechBubbleController.hide()
        speechBubbleController.close()
        
        // Anchor strictly to desktop Space so it never floats onto full-screen apps
        petWindow?.collectionBehavior = [.stationary]
        
        let size = currentWidgetSize
        let bounds = AquaticBounds(
            minX: 0.0,
            maxX: Double(size.width),
            minY: 0.0,
            maxY: Double(size.height),
            minZ: 0.0,
            maxZ: 1.0,
            margin: 20.0
        )
        self.aquariumState = AquariumWidgetState(bounds: bounds, settings: settings)
        updateWindowLevel(staysOnTop: settings.staysOnTop)
    }
    
    public func restoreFromAquarium() {
        guard isAquariumTransformed else { return }
        isAquariumTransformed = false
        aquariumState = nil
        
        // Restore original dimensions if customized
        customWidgetDimensions = nil
        let base = petSize + 80
        let restoredFrame = NSRect(x: currentX, y: currentY, width: base, height: base)
        petWindow?.setFrame(restoredFrame, display: true, animate: true)
        petWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        petWindow?.level = .floating
        
        currentState = .idle
        behaviorEngine.forceAction(.idle)
    }
    
    public func updateWindowLevel(staysOnTop: Bool? = nil) {
        guard let win = petWindow else { return }
        if isAquariumTransformed {
            let onTop = staysOnTop ?? AquariumManager.shared.settings.staysOnTop
            if onTop {
                win.level = .floating
            } else {
                win.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)) + 1)
            }
        } else {
            win.level = .floating
        }
    }
    
    public func applyAquariumDimensions(_ dim: CGSize) {
        customWidgetDimensions = dim
        let newFrame = NSRect(x: currentX, y: currentY, width: dim.width, height: dim.height)
        petWindow?.setFrame(newFrame, display: true, animate: false)
        if isAquariumTransformed {
            aquariumState?.updateDimensions(width: Double(dim.width), height: Double(dim.height))
        }
    }
    
    public func stepAquarium(dt: TimeInterval) {
        guard isAquariumTransformed, let state = aquariumState else { return }
        state.update(deltaTime: dt, settings: AquariumManager.shared.settings)
    }
    
    public func feedAquarium(at location: CGPoint? = nil) {
        guard isAquariumTransformed, let state = aquariumState else { return }
        state.feed(at: location)
    }
    
    public func tapAquariumGlass(at location: CGPoint) {
        guard isAquariumTransformed, let state = aquariumState else { return }
        state.tapGlass(at: location)
    }
    
    // MARK: - Monotonic Animation Timing & Clamping State
    private var lastAnimationTimestamp: TimeInterval = 0.0
    
    /// Target nominal physics tick duration (33.33 Hz)
    public static let nominalPhysicsDeltaTime: TimeInterval = 0.03
    
    /// Maximum catch-up clamp per physics tick (100 ms ~ 3 physics ticks) to prevent animation jumping after long pauses or freezes
    public static let maxAnimationDeltaTimeClamp: TimeInterval = 0.10
    
    /// Minimum animation delta time to advance (avoid zero/negative steps or sub-millisecond churn)
    public static let minAnimationDeltaTime: TimeInterval = 0.001
    
    /// Resets the monotonic animation clock (called during drag interruptions, pauses, or state resets)
    public func resetAnimationTiming() {
        lastAnimationTimestamp = 0.0
    }
    
    var name: String {
        url.deletingPathExtension().lastPathComponent
    }
    
    var characterId: String {
        PersonalityStorage.shared.characterId(for: url)
    }
    
    public enum PetState: String, CaseIterable {
        case idle
        case walk
        case run
        case jump
        case fall
        case land
        case sit
        case sleep
        case grooming
        
        // Backward-compatibility aliases
        public static var walking: PetState { .walk }
        public static var sleeping: PetState { .sleep }
        
        public var animationName: String {
            return rawValue
        }
    }
    
    public private(set) var sequencePlayer: SpriteSequencePlayer?
    
    @Published public var currentState: PetState = .walk {
        didSet {
            guard oldValue != currentState else { return }
            
            // Advance/transition sequence player if companion supports animation states
            sequencePlayer?.transition(to: currentState.animationName)
            
            if currentState == .sleep {
                let sleepingCount = globalManager.activePets.values.filter({ $0.currentState == .sleep }).count
                AudioEngine.shared.startSleepSound(forPetId: id.uuidString, totalSleepingPets: max(1, sleepingCount))
            } else if oldValue == .sleep {
                AudioEngine.shared.stopSleepSound(forPetId: id.uuidString)
            }
        }
    }
    
    init(url: URL, size: CGFloat, globalManager: PetManager, isDesktopWidgetReplacement: Bool = false) {
        self.url = url
        self.petSize = size
        self.globalManager = globalManager
        self.isDesktopWidgetReplacement = isDesktopWidgetReplacement
        
        if let animDir = AnimationAssetCache.resolveAnimationDirectory(for: url) {
            do {
                let player = try SpriteSequencePlayer(directoryURL: animDir, initialState: PetState.walk.animationName)
                self.sequencePlayer = player
            } catch {
                print("Failed to initialize SpriteSequencePlayer for \(url.lastPathComponent): \(error.localizedDescription)")
                self.sequencePlayer = nil
            }
        } else {
            self.sequencePlayer = nil
        }
        
        let initialProfile = PersonalityStorage.shared.getProfile(for: url)
        self.behaviorEngine = BehaviorEngine(profile: initialProfile)
        let diagProfile = DialogueProfile.fromPersonality(initialProfile)
        self.dialogueEngine = DialogueEngine(characterId: id, characterName: url.deletingPathExtension().lastPathComponent, profile: diagProfile)
        
        setupAnimationCallbacks()
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
        guard !isAquariumTransformed && !isDesktopWidgetReplacement && !AquariumManager.shared.isAquariumModeActive else { return }
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
    
    private func setupAnimationCallbacks() {
        guard let player = sequencePlayer else { return }
        
        player.onFootstep = { [weak self] frameIndex in
            guard let self = self else { return }
            // Only play footstep when grounded, not dragging, not hovering, and not airborne
            guard !self.isFalling, !self.isHovering, !self.isDragging else { return }
            let scr = self.currentScreen()
            let screenWidth = scr.frame.width
            let screenX = (self.currentX - scr.frame.minX) / max(1.0, screenWidth)
            AudioEngine.shared.playFootstep(petCount: self.globalManager.activePets.count, screenXFraction: screenX)
        }
        
        player.onOneShotComplete = { [weak self] completedState in
            guard let self = self else { return }
            if completedState == "land" {
                // Recover from landing impact
                if self.isFalling { return }
                let currentSpeed = CGFloat(max(self.globalManager.walkSpeed, 0.5))
                if self.behaviorEngine.currentAction == .walking || self.behaviorEngine.currentAction == .exploring {
                    self.currentState = (currentSpeed > 3.0 || self.behaviorEngine.currentAction == .exploring) ? .run : .walk
                } else {
                    self.currentState = .idle
                }
            } else if completedState == "grooming" {
                // Return to idle state after grooming cycle
                if self.currentState == .grooming {
                    self.currentState = .idle
                }
            }
        }
        
        player.onSleepCycle = { [weak self] _ in
            guard let self = self, self.currentState == .sleep else { return }
            let sleepingCount = self.globalManager.activePets.values.filter({ $0.currentState == .sleep }).count
            AudioEngine.shared.startSleepSound(forPetId: self.id.uuidString, totalSleepingPets: max(1, sleepingCount))
        }
    }
    
    func closePet() {
        petWindow?.orderOut(nil)
        sequencePlayer?.stop()
        sequencePlayer = nil
        SocialInteractionManager.shared.cancelEncounter(involving: id, reason: .petDismissed)
        speechBubbleController.close()
        AudioEngine.shared.cleanupPet(id: id.uuidString)
        petWindow?.close()
        petWindow = nil
        physicsTimer?.invalidate()
        physicsTimer = nil
        behaviorTimer?.invalidate()
        behaviorTimer = nil
        cancellables.removeAll()
    }
    
    public func onDragStart() {
        guard !isDragging else { return }
        isDragging = true
        resetAnimationTiming()
        currentState = .idle
        AudioEngine.shared.playCompanionVoice(.happy)
        speechBubbleController.hide()
        SocialInteractionManager.shared.cancelEncounter(involving: id, reason: .userInterrupted)
        behaviorEngine.pauseAutonomousBehavior()
        behaviorEngine.needs.interactWithUser()
        EnvironmentMonitor.shared.recordUserInteraction(type: .dragStart, petId: id)
        dragStartMousePos = NSEvent.mouseLocation
        dragStartWindowPos = NSPoint(x: currentX, y: currentY)
    }
    
    public func onDragEnd(to dropPoint: NSPoint? = nil) {
        isDragging = false
        resetAnimationTiming()
        if !isAquariumTransformed {
            isFalling = true
            currentState = .fall
        }
        EnvironmentMonitor.shared.recordUserInteraction(type: .dragEnd, petId: id)
        if !AquariumManager.shared.isAquariumModeActive {
            triggerDialogue(.dragReleased)
        }
        behaviorEngine.resumeAutonomousBehavior()
        if let pt = dropPoint {
            currentX = pt.x
            currentY = pt.y
        }
        let screen = currentScreen()
        let windowSize = petSize + 80
        currentX = min(max(currentX, screen.visibleFrame.minX), screen.visibleFrame.maxX - windowSize)
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
        
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        
        let hostingView = CompanionHostingView(rootView: PetSpriteView(pet: self), pet: self)
        window.contentView = hostingView
        if !isDesktopWidgetReplacement {
            window.makeKeyAndOrderFront(nil)
        }
        self.petWindow = window
        
        applyGravity()
    }
    
    func currentScreen() -> NSScreen {
        let windowSize = petSize + 80
        let petMidPoint = NSPoint(x: currentX + (windowSize / 2), y: currentY + (windowSize / 2))
        if let cached = cachedScreen, cached.frame.contains(petMidPoint) {
            return cached
        }
        let matched = NSScreen.screens.first(where: { $0.frame.contains(petMidPoint) }) ?? NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        cachedScreen = matched
        return matched
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
                ambientEnvironment: AmbientEngine.shared.currentEnvironment,
                referenceDate: now
            ) {
                self.applyAction(newAction)
            }
        }
    }
    
    public func applyAction(_ action: CharacterAction) {
        behaviorEngine.forceAction(action)
        let previousState = self.currentState
        switch action {
        case .walking:
            let isRunning = (globalManager.walkSpeed > 3.0) || (behaviorEngine.profile.energy > 0.8)
            self.currentState = isRunning ? .run : .walk
            if Bool.random() { self.walkDirectionRight.toggle() }
            if previousState == .sleep {
                triggerDialogue(.wakingUp)
            } else {
                triggerDialogue(.walking)
            }
        case .exploring:
            self.currentState = .run
            self.walkDirectionRight.toggle()
            triggerDialogue(.exploring)
        case .idle:
            if sequencePlayer != nil {
                let roll = Double.random(in: 0.0...1.0)
                let laziness = behaviorEngine.profile.laziness
                let sitThreshold = 0.70 - (laziness * 0.20)
                let groomThreshold = 0.90
                
                if roll >= groomThreshold {
                    self.currentState = .grooming
                } else if roll >= sitThreshold {
                    self.currentState = .sit
                } else {
                    self.currentState = .idle
                }
            } else {
                self.currentState = .idle
            }
        case .sleeping:
            self.currentState = .sleep
            triggerDialogue(.resting)
        }
    }
    
    private func startPhysicsLoop() {
        guard !isManagedExternally else { return }
        physicsTimer?.invalidate()
        physicsTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            guard let self = self, !self.globalManager.isPhysicsPaused, !self.isDragging else { return }
            self.physicsTick()
        }
    }
    
    // MARK: - Animation Timing Advance with Clamping & Catch-Up Policy
    private func advanceAnimationTiming(overrideDeltaTime: TimeInterval? = nil) {
        guard let player = sequencePlayer else { return }
        
        let elapsed: TimeInterval
        if let override = overrideDeltaTime {
            // Allows deterministic test execution of irregular or delayed ticks
            elapsed = override
        } else {
            let now = CACurrentMediaTime()
            if lastAnimationTimestamp <= 0.0 {
                // First tick or resumed from drag/pause: initialize timestamp and use nominal timestep
                lastAnimationTimestamp = now
                elapsed = Self.nominalPhysicsDeltaTime
            } else {
                let diff = now - lastAnimationTimestamp
                lastAnimationTimestamp = now
                elapsed = diff
            }
        }
        
        // Documented Catch-Up & Clamping Policy:
        // 1. If elapsed is below threshold (< 1ms), do not advance to avoid sub-millisecond churn.
        // 2. If elapsed is above maxAnimationDeltaTimeClamp (0.10s, e.g. after system sleep or modal pause),
        //    clamp to 0.10s to prevent abrupt multi-frame teleporting or skipping one-shot animations.
        // 3. Otherwise, advance by the exact elapsed monotonic interval to prevent animation drift.
        if elapsed < Self.minAnimationDeltaTime {
            return
        }
        
        let dt = min(elapsed, Self.maxAnimationDeltaTimeClamp)
        player.advance(by: dt)
    }
    
    public func physicsTick(overrideDeltaTime: TimeInterval? = nil) {
        completedPhysicsTicks &+= 1
        if isAquariumTransformed {
            if isDragging {
                updatePosition()
            }
            return
        }
        let screen = currentScreen()
        let windowSize = petSize + 80
        let currentSpeed = CGFloat(max(globalManager.walkSpeed, 0.5))
        
        // Advance animation sequence using monotonic elapsed time with documented catch-up / clamping policy
        advanceAnimationTiming(overrideDeltaTime: overrideDeltaTime)
        
        if globalManager.upsideDownMenuMode {
            currentY = screen.visibleFrame.maxY - windowSize + 40
            if (currentState == .walk || currentState == .run) && !isHovering {
                let prevStepPhase = Int(walkTime / Double.pi)
                currentX += walkDirectionRight ? currentSpeed : -currentSpeed
                
                // --- UPSIDE DOWN BOBBING ---
                if sequencePlayer == nil {
                    walkTime += (0.15 * Double(currentSpeed))
                    let newBob = CGFloat(sin(walkTime) * 3.0)
                    if abs(walkBobOffset - newBob) > 0.05 {
                        walkBobOffset = newBob
                    }
                    
                    let newStepPhase = Int(walkTime / Double.pi)
                    if newStepPhase != prevStepPhase {
                        let screenX = (currentX - screen.frame.minX) / max(1.0, screen.frame.width)
                        AudioEngine.shared.playFootstep(petCount: globalManager.activePets.count, screenXFraction: screenX)
                    }
                }
            } else {
                walkTime = 0
                if walkBobOffset != 0 {
                    walkBobOffset = 0
                }
            }
            bounceOffScreenEdges(screen: screen)
            updatePosition()
            return
        }
        
        let screenFloor = screen.visibleFrame.minY - 40
        let petMidX = currentX + (windowSize / 2)
        let visualFeetY = currentY + 40
        
        // Performance optimization: when stationary on the screen floor in idle, sit, grooming, or sleep state,
        // the floor cannot disappear and does not need continuous WindowPlatformTracker queries.
        let isMovingHorizontally = (currentState == .walk || currentState == .run)
        let isStationaryOnScreenFloor = !isFalling && !isMovingHorizontally && currentPlatform == nil && !isHovering
        
        let currentFloor: CGFloat
        let isWalkingOnWindow: Bool
        
        if isStationaryOnScreenFloor {
            currentFloor = screenFloor
            isWalkingOnWindow = false
        } else {
            let support = WindowPlatformTracker.shared.resolveSupportingFloor(
                petMidX: petMidX,
                visualFeetY: visualFeetY,
                screenFloor: screenFloor,
                currentPlatform: currentPlatform
            )
            currentFloor = support.floorY
            self.currentPlatform = support.platform
            isWalkingOnWindow = support.isOnWindow
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
            if walkBobOffset != 0 {
                walkBobOffset = 0 // Reset bob while falling
            }
            
            if sim.didLand {
                isFalling = false
                currentState = .land
                triggerDialogue(.landing)
                AudioEngine.shared.playCompanionVoice(.curious)
            } else {
                if yVelocity < -1.0 {
                    if currentState != .jump { currentState = .jump }
                } else {
                    if currentState != .fall { currentState = .fall }
                }
            }
        } else {
            if CompanionPhysicsSimulator.shouldStartFalling(currentY: currentY, currentFloor: currentFloor) {
                isFalling = true
                yVelocity = 0
                currentState = .fall
                triggerDialogue(.falling)
            } else {
                let isMusicPlaying = globalManager.musicSyncEnabled && (globalManager.musicMonitor.currentTrack != nil)
                
                // Cat-to-Aquarium Observer Interaction (Stage 4.5)
                aquariumObservationCooldown = max(0.0, aquariumObservationCooldown - 0.033)
                if isObservingAquarium {
                    aquariumObservationTimer -= 0.033
                    if aquariumObservationTimer <= 0.0 {
                        isObservingAquarium = false
                        behaviorEngine.forceAction(.walking)
                        currentState = .walk
                    }
                } else if aquariumObservationCooldown <= 0.0 && AquariumManager.shared.isVisible {
                    let windowSize = petSize + 80
                    let petFrame = NSRect(x: currentX, y: currentY, width: windowSize, height: windowSize)
                    
                    // 1. Check transformed aquarium widgets in activePets
                    for otherPet in globalManager.activePets.values where otherPet.id != self.id && otherPet.isAquariumTransformed {
                        if let tankPanel = otherPet.petWindow {
                            let tankFrame = tankPanel.frame
                            let hDist: CGFloat
                            if petFrame.maxX < tankFrame.minX {
                                hDist = tankFrame.minX - petFrame.maxX
                            } else if petFrame.minX > tankFrame.maxX {
                                hDist = petFrame.minX - tankFrame.maxX
                            } else {
                                hDist = 0
                            }
                            let vOverlap = (petFrame.maxY >= tankFrame.minY - 50) && (petFrame.minY <= tankFrame.maxY + 50)
                            if hDist < 120.0 && vOverlap && !isFalling && !isDragging {
                                isObservingAquarium = true
                                aquariumObservationTimer = 6.0
                                aquariumObservationCooldown = 45.0
                                walkDirectionRight = (petFrame.midX < tankFrame.midX)
                                behaviorEngine.forceAction(.idle)
                                currentState = (behaviorEngine.profile.laziness > 0.5) ? .sit : .idle
                                triggerDialogue(.aquariumObserved)
                                break
                            }
                        }
                    }
                    

                }
                
                if isObservingAquarium {
                    walkTime = 0
                    if walkBobOffset != 0 { walkBobOffset = 0 }
                } else if (currentState == .walk || currentState == .run) && !isHovering {
                    currentX += walkDirectionRight ? currentSpeed : -currentSpeed
                    
                    if sequencePlayer == nil {
                        let prevStepPhase = Int(walkTime / Double.pi)
                        let bobMultiplier = isMusicPlaying ? 0.25 : 0.15
                        let bobHeight = isMusicPlaying ? -6.0 : -4.0
                        walkTime += (bobMultiplier * Double(currentSpeed))
                        let newBob = CGFloat(abs(sin(walkTime)) * bobHeight)
                        if abs(walkBobOffset - newBob) > 0.05 {
                            walkBobOffset = newBob
                        }
                        
                        let newStepPhase = Int(walkTime / Double.pi)
                        if newStepPhase != prevStepPhase {
                            let screenX = (currentX - screen.frame.minX) / max(1.0, screen.frame.width)
                            AudioEngine.shared.playFootstep(petCount: globalManager.activePets.count, screenXFraction: screenX)
                        }
                    } else {
                        // Dynamically balance walk vs run for animated companions
                        let targetState: PetState = (currentSpeed > 3.0 || behaviorEngine.currentAction == .exploring) ? .run : .walk
                        if currentState != targetState && currentState != .land {
                            currentState = targetState
                        }
                    }
                } else if isMusicPlaying && currentState != .sleep && !isHovering {
                    if sequencePlayer == nil {
                        walkTime += 0.15
                        let newBob = CGFloat(abs(sin(walkTime)) * -3.0)
                        if abs(walkBobOffset - newBob) > 0.05 {
                            walkBobOffset = newBob
                        }
                    }
                } else {
                    walkTime = 0
                    if walkBobOffset != 0 {
                        walkBobOffset = 0 // Reset when standing still
                    }
                }
                
                if isWalkingOnWindow, let platform = currentPlatform {
                    let midPetX = currentX + (windowSize / 2)
                    if midPetX > platform.maxX || midPetX < platform.minX {
                        // Stepped off the window edge! Drop platform support to fall naturally
                        self.currentPlatform = nil
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
        cachedScreen = nil
        let targetSize = currentWidgetSize
        let petRect = NSRect(x: currentX, y: currentY, width: targetSize.width, height: targetSize.height)
        let isVisibleOnAnyScreen = NSScreen.screens.contains(where: { screen in
            screen.frame.intersects(petRect)
        })
        
        if !isVisibleOnAnyScreen, let targetScreen = NSScreen.main ?? NSScreen.screens.first {
            currentX = targetScreen.visibleFrame.midX - (targetSize.width / 2)
            currentY = targetScreen.visibleFrame.minY + 20
            if !isAquariumTransformed {
                isFalling = true
                yVelocity = 0
            }
            updatePosition()
        }
    }
    
    func updatePosition() {
        let newOrigin = NSPoint(x: currentX, y: currentY)
        if abs(newOrigin.x - lastRenderedOrigin.x) > 0.05 || abs(newOrigin.y - lastRenderedOrigin.y) > 0.05 {
            petWindow?.setFrameOrigin(newOrigin)
            lastRenderedOrigin = newOrigin
            
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
            if pet.isAquariumTransformed, let state = pet.aquariumState {
                AquariumWidgetSurfaceView(
                    widgetState: state,
                    manager: AquariumManager.shared,
                    pet: pet,
                    size: pet.currentWidgetSize
                )
            } else if pet.isDesktopWidgetReplacement {
                // When aquarium mode is turned off, desktop widget replacement directly vanishes (zero sprite flash)
                Color.clear
            } else {
                ZStack {
                    if let player = pet.sequencePlayer {
                        SpriteSequencePlayerView(player: player)
                            .frame(width: pet.petSize, height: pet.petSize)
                            .scaleEffect(x: pet.walkDirectionRight ? 1 : -1)
                    } else {
                        CompanionMediaView(url: pet.url)
                            .frame(width: pet.petSize, height: pet.petSize)
                            .scaleEffect(x: pet.walkDirectionRight ? 1 : -1)
                            // --- APPLIES THE VISUAL HOP TO THE SPRITE ---
                            .offset(y: pet.walkBobOffset)
                    }
                }
                .frame(width: pet.petSize + 80, height: pet.petSize + 80)
                .rotationEffect(.degrees(pet.globalManager.upsideDownMenuMode ? 180 : 0))
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: pet.globalManager.upsideDownMenuMode)
            }
        }
        .frame(width: pet.currentWidgetSize.width, height: pet.currentWidgetSize.height)
        .contentShape(Rectangle())
        .onHover { isHovered in
            pet.isHovering = isHovered
            if isHovered && !pet.isAquariumTransformed {
                EnvironmentMonitor.shared.recordUserInteraction(type: .hover, petId: pet.id)
                pet.behaviorEngine.needs.interactWithUser()
                if pet.currentState == .sleeping && pet.behaviorEngine.profile.attentionSeeking > 0.4 {
                    pet.currentState = .idle
                    pet.behaviorEngine.forceAction(.idle)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { _ in
                    if !pet.isDragging {
                        pet.onDragStart()
                    }
                    
                    let currentMouse = NSEvent.mouseLocation
                    let deltaX = currentMouse.x - pet.dragStartMousePos.x
                    let deltaY = currentMouse.y - pet.dragStartMousePos.y
                    
                    pet.currentX = pet.dragStartWindowPos.x + deltaX
                    pet.currentY = pet.dragStartWindowPos.y + deltaY
                    pet.updatePosition()
                }
                .onEnded { _ in
                    pet.onDragEnd()
                }
        )
        .onTapGesture(count: 2) {
            if !pet.isAquariumTransformed {
                EnvironmentMonitor.shared.recordUserInteraction(type: .click, petId: pet.id)
                pet.triggerDialogue(.petClicked)
                showMenu = true
            }
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

// MARK: - Native Companion Hosting View (Task 3: Reliable Context Menus, Mouse Dragging & First-Mouse Response)
final class CompanionHostingView<Content: View>: NSHostingView<Content> {
    weak var petInstance: PetInstance?
    private var isDraggingPet: Bool = false
    private var hasMovedDuringDrag: Bool = false
    private var dragStartMousePos: NSPoint = .zero
    private var dragStartWindowPos: NSPoint = .zero
    
    init(rootView: Content, pet: PetInstance) {
        self.petInstance = pet
        super.init(rootView: rootView)
    }
    
    @MainActor required init(rootView: Content) {
        super.init(rootView: rootView)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Crucial: Accepts clicks, drags, and right-clicks even when other apps are active
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        guard let pet = petInstance else { return nil }
        return CompanionContextMenuHelper.buildMenu(for: pet)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        guard let pet = petInstance else {
            super.rightMouseDown(with: event)
            return
        }
        let menu = CompanionContextMenuHelper.buildMenu(for: pet)
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
    
    override func mouseDown(with event: NSEvent) {
        guard let pet = petInstance else {
            super.mouseDown(with: event)
            return
        }
        
        // Double-click interaction: tap glass for aquarium or trigger interaction for pet
        if event.clickCount == 2 {
            if pet.isAquariumTransformed {
                let loc = convert(event.locationInWindow, from: nil)
                pet.tapAquariumGlass(at: CGPoint(x: loc.x, y: loc.y))
                AudioEngine.shared.playAquariumSound(.glassTap)
            } else {
                EnvironmentMonitor.shared.recordUserInteraction(type: .click, petId: pet.id)
                pet.triggerDialogue(.petClicked)
            }
        }
        
        // Mouse drag tracking for every pet and aquarium
        isDraggingPet = true
        hasMovedDuringDrag = false
        dragStartMousePos = NSEvent.mouseLocation
        dragStartWindowPos = NSPoint(x: pet.currentX, y: pet.currentY)
        pet.onDragStart()
        super.mouseDown(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let pet = petInstance, isDraggingPet else {
            super.mouseDragged(with: event)
            return
        }
        
        let currentMouse = NSEvent.mouseLocation
        let deltaX = currentMouse.x - dragStartMousePos.x
        let deltaY = currentMouse.y - dragStartMousePos.y
        
        if abs(deltaX) > 2 || abs(deltaY) > 2 {
            hasMovedDuringDrag = true
        }
        
        pet.currentX = dragStartWindowPos.x + deltaX
        pet.currentY = dragStartWindowPos.y + deltaY
        pet.updatePosition()
        super.mouseDragged(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        if isDraggingPet, let pet = petInstance {
            isDraggingPet = false
            // Single tap without mouse drag on aquarium triggers feeding
            if !hasMovedDuringDrag && pet.isAquariumTransformed && event.clickCount == 1 {
                let loc = convert(event.locationInWindow, from: nil)
                pet.feedAquarium(at: CGPoint(x: loc.x, y: loc.y))
                AudioEngine.shared.playAquariumSound(.feedFlake)
            }
            pet.onDragEnd()
        }
        super.mouseUp(with: event)
    }
}

// MARK: - Companion Context Menu Builder
final class CompanionContextMenuHelper: NSObject {
    static let shared = CompanionContextMenuHelper()
    
    static func buildMenu(for pet: PetInstance) -> NSMenu {
        if pet.isAquariumTransformed {
            return buildAquariumMenu(for: pet)
        }
        let menu = NSMenu(title: "CompanionMenu")
        menu.autoenablesItems = false
        
        // 1. Header: Companion Name & Mood
        let headerText = "\(pet.behaviorEngine.profile.name) • \(pet.behaviorEngine.needs.mood.displayName)"
        let headerItem = NSMenuItem(title: headerText, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Open Library / Settings
        let openItem = NSMenuItem(title: "Open Animatto Library", action: #selector(shared.handleOpenLibrary(_:)), keyEquivalent: "")
        openItem.target = shared
        openItem.representedObject = pet
        openItem.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil)
        menu.addItem(openItem)
        
        // 3. Pause / Resume Physics
        let isPaused = pet.globalManager.isPhysicsPaused
        let pauseTitle = isPaused ? "Resume Physics" : "Pause Physics"
        let pauseItem = NSMenuItem(title: pauseTitle, action: #selector(shared.handleTogglePhysics(_:)), keyEquivalent: "")
        pauseItem.target = shared
        pauseItem.representedObject = pet
        pauseItem.image = NSImage(systemSymbolName: isPaused ? "play.fill" : "pause.fill", accessibilityDescription: nil)
        menu.addItem(pauseItem)
        
        // 4. Force Sleep / Wake Up
        let isSleeping = pet.currentState == .sleeping
        let sleepTitle = isSleeping ? "Wake Up" : "Force Sleep"
        let sleepItem = NSMenuItem(title: sleepTitle, action: #selector(shared.handleToggleSleep(_:)), keyEquivalent: "")
        sleepItem.target = shared
        sleepItem.representedObject = pet
        sleepItem.image = NSImage(systemSymbolName: isSleeping ? "sun.max.fill" : "moon.zzz.fill", accessibilityDescription: nil)
        menu.addItem(sleepItem)
        
        // 5. Timers & Focus Submenu
        let timerItem = NSMenuItem(title: "Timers & Focus", action: nil, keyEquivalent: "")
        timerItem.image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
        let timerSubmenu = NSMenu(title: "Timers")
        timerSubmenu.autoenablesItems = false
        
        let pomodoroItem = NSMenuItem(title: "Pomodoro (25m Focus)", action: #selector(shared.handleStartPomodoro(_:)), keyEquivalent: "")
        pomodoroItem.target = shared
        timerSubmenu.addItem(pomodoroItem)
        
        let longFocusItem = NSMenuItem(title: "Deep Work (50m Focus)", action: #selector(shared.handleStartLongFocus(_:)), keyEquivalent: "")
        longFocusItem.target = shared
        timerSubmenu.addItem(longFocusItem)
        
        let break5Item = NSMenuItem(title: "Short Break (5m)", action: #selector(shared.handleStart5mBreak(_:)), keyEquivalent: "")
        break5Item.target = shared
        timerSubmenu.addItem(break5Item)
        
        let rest15Item = NSMenuItem(title: "Rest (15m)", action: #selector(shared.handleStart15mRest(_:)), keyEquivalent: "")
        rest15Item.target = shared
        timerSubmenu.addItem(rest15Item)
        
        if ProductivityTimerManager.shared.currentPhase != .idle {
            timerSubmenu.addItem(NSMenuItem.separator())
            let stopTimerItem = NSMenuItem(title: "Stop Active Timer (\(ProductivityTimerManager.shared.formattedRemainingTime))", action: #selector(shared.handleStopTimer(_:)), keyEquivalent: "")
            stopTimerItem.target = shared
            timerSubmenu.addItem(stopTimerItem)
        }
        
        timerItem.submenu = timerSubmenu
        menu.addItem(timerItem)
        
        // 6. Center Companion on Screen
        let centerItem = NSMenuItem(title: "Reset Position to Center", action: #selector(shared.handleCenterPet(_:)), keyEquivalent: "")
        centerItem.target = shared
        centerItem.representedObject = pet
        centerItem.image = NSImage(systemSymbolName: "scope", accessibilityDescription: nil)
        menu.addItem(centerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 7. Dismiss Companion
        let dismissItem = NSMenuItem(title: "Dismiss Companion", action: #selector(shared.handleDismissPet(_:)), keyEquivalent: "")
        dismissItem.target = shared
        dismissItem.representedObject = pet
        dismissItem.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
        menu.addItem(dismissItem)
        
        return menu
    }
    
    @objc private func handleOpenLibrary(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { !($0 is NSPanel) && $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func handleTogglePhysics(_ sender: NSMenuItem) {
        guard let pet = sender.representedObject as? PetInstance else { return }
        pet.globalManager.isPhysicsPaused.toggle()
    }
    
    @objc private func handleToggleSleep(_ sender: NSMenuItem) {
        guard let pet = sender.representedObject as? PetInstance else { return }
        if pet.currentState == .sleeping {
            pet.currentState = .idle
            pet.behaviorEngine.forceAction(.idle)
            pet.triggerDialogue(.greeting)
        } else {
            pet.currentState = .sleeping
            pet.behaviorEngine.forceAction(.sleeping)
            AudioEngine.shared.playCompanionVoice(.sleepy)
        }
    }
    
    @objc private func handleStartPomodoro(_ sender: NSMenuItem) {
        ProductivityTimerManager.shared.start(mode: .pomodoro)
    }
    
    @objc private func handleStartLongFocus(_ sender: NSMenuItem) {
        ProductivityTimerManager.shared.start(mode: .longFocus)
    }
    
    @objc private func handleStart5mBreak(_ sender: NSMenuItem) {
        ProductivityTimerManager.shared.start(mode: .countdown(minutes: 5))
    }
    
    @objc private func handleStart15mRest(_ sender: NSMenuItem) {
        ProductivityTimerManager.shared.start(mode: .countdown(minutes: 15))
    }
    
    @objc private func handleStopTimer(_ sender: NSMenuItem) {
        ProductivityTimerManager.shared.stop()
    }
    
    @objc private func handleCenterPet(_ sender: NSMenuItem) {
        guard let pet = sender.representedObject as? PetInstance else { return }
        let screen = pet.currentScreen()
        let size = pet.petSize + 80
        pet.currentX = screen.visibleFrame.midX - (size / 2)
        pet.currentY = screen.visibleFrame.midY - (size / 2)
        pet.yVelocity = 0
        pet.isFalling = false
        pet.updatePosition()
    }
    
    @objc private func handleDismissPet(_ sender: NSMenuItem) {
        guard let pet = sender.representedObject as? PetInstance else { return }
        pet.globalManager.removePet(id: pet.id)
    }
    
    // MARK: - Transformed Aquarium Context Menu
    static func buildAquariumMenu(for pet: PetInstance) -> NSMenu {
        let menu = NSMenu(title: "AquariumWidgetMenu")
        menu.autoenablesItems = false
        
        let themeName = AquariumManager.shared.settings.waterTheme.displayName
        let headerItem = NSMenuItem(title: "Aquarium Mode • \(themeName)", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let feedItem = NSMenuItem(title: "Feed Food Flakes", action: #selector(shared.handleAquariumFeed(_:)), keyEquivalent: "")
        feedItem.target = shared
        feedItem.representedObject = pet
        feedItem.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: nil)
        menu.addItem(feedItem)
        
        let tapItem = NSMenuItem(title: "Tap Tank Glass", action: #selector(shared.handleAquariumTap(_:)), keyEquivalent: "")
        tapItem.target = shared
        tapItem.representedObject = pet
        tapItem.image = NSImage(systemSymbolName: "hand.tap.fill", accessibilityDescription: nil)
        menu.addItem(tapItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Water Theme Submenu
        let themeItem = NSMenuItem(title: "Water Theme", action: nil, keyEquivalent: "")
        themeItem.image = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: nil)
        let themeSub = NSMenu(title: "Water Themes")
        for theme in WaterAtmosphereTheme.allCases {
            let sub = NSMenuItem(title: theme.displayName, action: #selector(shared.handleAquariumTheme(_:)), keyEquivalent: "")
            sub.target = shared
            sub.representedObject = theme
            sub.state = (AquariumManager.shared.settings.waterTheme == theme) ? .on : .off
            themeSub.addItem(sub)
        }
        themeItem.submenu = themeSub
        menu.addItem(themeItem)
        
        // Sound toggle
        let isMuted = !AquariumManager.shared.settings.soundEnabled
        let soundTitle = isMuted ? "Unmute Water Sounds" : "Mute Water Sounds"
        let soundItem = NSMenuItem(title: soundTitle, action: #selector(shared.handleAquariumToggleSound(_:)), keyEquivalent: "")
        soundItem.target = shared
        soundItem.image = NSImage(systemSymbolName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill", accessibilityDescription: nil)
        menu.addItem(soundItem)
        
        // Presets Submenu
        let sizeItem = NSMenuItem(title: "Widget Size", action: nil, keyEquivalent: "")
        sizeItem.image = NSImage(systemSymbolName: "aspectratio", accessibilityDescription: nil)
        let sizeSub = NSMenu(title: "Widget Sizes")
        let presets: [(String, TankSizePreset)] = [
            ("Small (280×180)", .small),
            ("Medium (420×280)", .medium),
            ("Large (560×360)", .large),
            ("Panoramic (640×240)", .panoramicWidget)
        ]
        for (title, preset) in presets {
            let sub = NSMenuItem(title: title, action: #selector(shared.handleAquariumPreset(_:)), keyEquivalent: "")
            sub.target = shared
            sub.representedObject = (pet, preset)
            sub.state = (AquariumManager.shared.settings.tankSizePreset == preset) ? .on : .off
            sizeSub.addItem(sub)
        }
        sizeItem.submenu = sizeSub
        menu.addItem(sizeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Timers Submenu
        let timerItem = NSMenuItem(title: "Timers & Focus", action: nil, keyEquivalent: "")
        timerItem.image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
        let timerSubmenu = NSMenu(title: "Timers")
        timerSubmenu.autoenablesItems = false
        let pomodoroItem = NSMenuItem(title: "Pomodoro (25m Focus)", action: #selector(shared.handleStartPomodoro(_:)), keyEquivalent: "")
        pomodoroItem.target = shared
        timerSubmenu.addItem(pomodoroItem)
        let longFocusItem = NSMenuItem(title: "Deep Work (50m Focus)", action: #selector(shared.handleStartLongFocus(_:)), keyEquivalent: "")
        longFocusItem.target = shared
        timerSubmenu.addItem(longFocusItem)
        let break5Item = NSMenuItem(title: "Short Break (5m)", action: #selector(shared.handleStart5mBreak(_:)), keyEquivalent: "")
        break5Item.target = shared
        timerSubmenu.addItem(break5Item)
        let rest15Item = NSMenuItem(title: "Rest (15m)", action: #selector(shared.handleStart15mRest(_:)), keyEquivalent: "")
        rest15Item.target = shared
        timerSubmenu.addItem(rest15Item)
        if ProductivityTimerManager.shared.currentPhase != .idle {
            timerSubmenu.addItem(NSMenuItem.separator())
            let stopTimerItem = NSMenuItem(title: "Stop Active Timer (\(ProductivityTimerManager.shared.formattedRemainingTime))", action: #selector(shared.handleStopTimer(_:)), keyEquivalent: "")
            stopTimerItem.target = shared
            timerSubmenu.addItem(stopTimerItem)
        }
        timerItem.submenu = timerSubmenu
        menu.addItem(timerItem)
        
        // Open Settings
        let openItem = NSMenuItem(title: "Open Animatto Settings", action: #selector(shared.handleOpenLibrary(_:)), keyEquivalent: "")
        openItem.target = shared
        openItem.representedObject = pet
        openItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Turn Off Aquarium Mode
        let exitItem = NSMenuItem(title: "Turn Off Aquarium Mode", action: #selector(shared.handleExitAquariumMode(_:)), keyEquivalent: "")
        exitItem.target = shared
        exitItem.image = NSImage(systemSymbolName: "arrow.uturn.backward", accessibilityDescription: nil)
        menu.addItem(exitItem)
        
        // Dismiss Widget
        let dismissItem = NSMenuItem(title: "Dismiss Widget", action: #selector(shared.handleDismissPet(_:)), keyEquivalent: "")
        dismissItem.target = shared
        dismissItem.representedObject = pet
        dismissItem.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
        menu.addItem(dismissItem)
        
        return menu
    }
    
    @objc private func handleAquariumFeed(_ sender: NSMenuItem) {
        guard let pet = sender.representedObject as? PetInstance else { return }
        pet.feedAquarium()
        AudioEngine.shared.playAquariumSound(.feedFlake)
    }
    
    @objc private func handleAquariumTap(_ sender: NSMenuItem) {
        guard let pet = sender.representedObject as? PetInstance else { return }
        let center = CGPoint(x: pet.currentWidgetSize.width * 0.5, y: pet.currentWidgetSize.height * 0.5)
        pet.tapAquariumGlass(at: center)
        AudioEngine.shared.playAquariumSound(.glassTap)
    }
    
    @objc private func handleAquariumTheme(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? WaterAtmosphereTheme else { return }
        AquariumManager.shared.settings.waterTheme = theme
    }
    
    @objc private func handleAquariumToggleSound(_ sender: NSMenuItem) {
        AquariumManager.shared.settings.soundEnabled.toggle()
        if AquariumManager.shared.settings.soundEnabled {
            AudioEngine.shared.startAquariumAmbience(
                aeratorVolume: AquariumManager.shared.settings.aeratorVolume,
                waterSoundVolume: AquariumManager.shared.settings.waterSoundVolume
            )
        } else {
            AudioEngine.shared.stopAquariumAmbience()
        }
    }
    
    @objc private func handleAquariumPreset(_ sender: NSMenuItem) {
        if let tuple = sender.representedObject as? (PetInstance, TankSizePreset) {
            AquariumManager.shared.applyPreset(tuple.1)
        }
    }
    
    @objc private func handleExitAquariumMode(_ sender: NSMenuItem) {
        AquariumManager.shared.closeAquarium()
    }
}
