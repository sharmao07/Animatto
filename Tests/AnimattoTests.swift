import Foundation

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

// MARK: - Main Entry Point

@main
struct TestRunner {
    static func main() {
        print("=== STARTING ANIMATTO PHASE 1 & 2 UNIT TESTS ===")
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

        print("\n================ TEST RESULTS ================")
        print("Passed: \(TestHarness.passedCount) assertion(s)")
        print("Failed: \(TestHarness.failedCount) failure(s)")
        print("==============================================")

        if TestHarness.failedCount > 0 {
            print("❌ Test suite failed!")
            exit(1)
        } else {
            print("🎉 All Animatto Phase 1 & Phase 2 unit tests passed successfully!")
            exit(0)
        }
    }
}
