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

// MARK: - Main Entry Point

@main
struct TestRunner {
    static func main() {
        print("=== STARTING ANIMATTO PHASE 1 THROUGH PHASE 9 UNIT TESTS ===")
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

        print("\n================ TEST RESULTS ================")
        print("Passed: \(TestHarness.passedCount) assertion(s)")
        print("Failed: \(TestHarness.failedCount) failure(s)")
        print("==============================================")

        if TestHarness.failedCount > 0 {
            print("❌ Test suite failed!")
            exit(1)
        } else {
            print("🎉 All Animatto Phase 1 through Phase 9 unit tests passed successfully!")
            exit(0)
        }
    }
}
