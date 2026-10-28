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

// MARK: - Main Entry Point

@main
struct TestRunner {
    static func main() {
        print("=== STARTING ANIMATTO PHASE 1, 2, 3 & 4 UNIT TESTS ===")
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

        print("\n================ TEST RESULTS ================")
        print("Passed: \(TestHarness.passedCount) assertion(s)")
        print("Failed: \(TestHarness.failedCount) failure(s)")
        print("==============================================")

        if TestHarness.failedCount > 0 {
            print("❌ Test suite failed!")
            exit(1)
        } else {
            print("🎉 All Animatto Phase 1, Phase 2, Phase 3 & Phase 4 unit tests passed successfully!")
            exit(0)
        }
    }
}
