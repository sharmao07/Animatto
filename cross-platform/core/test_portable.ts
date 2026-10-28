import { createPresetProfile, sanitizeAndMigrateProfile, clampTrait } from "./personality.ts";
import { PortableBehaviorEngine } from "./behaviorEngine.ts";
import { UnsupportedPlatformAdapter } from "./adapters.ts";

function assert(condition: boolean, message: string) {
  if (!condition) {
    console.error(`❌ Assertion Failed: ${message}`);
    process.exit(1);
  }
}

console.log("=== RUNNING ANIMATTO CROSS-PLATFORM PORTABLE CORE TESTS ===");

// 1. Clamping & Preset Tests
assert(clampTrait(1.5) === 1.0, "Clamping above 1.0 succeeds");
assert(clampTrait(-0.5) === 0.0, "Clamping below 0.0 succeeds");
assert(clampTrait(NaN, 0.7) === 0.7, "NaN fallback works");

const presets = ['balanced', 'energetic', 'lazy', 'curious', 'playful', 'shy', 'mischievous', 'calm', 'sarcastic', 'supportive'] as const;
for (const p of presets) {
  const prof = createPresetProfile(p, `id-${p}`, `Pet-${p}`);
  assert(prof.preset === p, `Preset ${p} matches`);
  assert(prof.energy >= 0 && prof.energy <= 1, "Energy bounded");
  assert(prof.laziness >= 0 && prof.laziness <= 1, "Laziness bounded");
  assert(prof.playfulness >= 0 && prof.playfulness <= 1, "Playfulness bounded");
  assert(prof.curiosity >= 0 && prof.curiosity <= 1, "Curiosity bounded");
}

// 2. Schema Migration Tests
const v1Json = {
  version: 1,
  id: "550e8400-e29b-41d4-a716-446655440000",
  name: "LegacyPet",
  energy: 0.95,
  laziness: 0.05,
  curiosity: 0.8,
  playfulness: 0.85,
  shyness: 0.1,
  sociability: 0.9
};
const migrated = sanitizeAndMigrateProfile(v1Json);
assert(migrated.version === 2, "Migrated to schema v2");
assert(migrated.id === v1Json.id, "ID preserved");
assert(migrated.sarcasm === 0.2, "Default sarcasm assigned");
assert(migrated.supportiveness === 0.5, "Default supportiveness assigned");
assert(migrated.behaviorPreferences.cursorFollowingEnabled === true, "Default behavior preferences populated");

// 3. Behavior Engine Scoring & Repetition
const engine = new PortableBehaviorEngine(createPresetProfile('energetic', 'uuid-e', 'EnergeticPet'));
const initialWalking = engine.scoreAction('walking');
assert(initialWalking.rawScore > 50, "Energetic pet scores walking high");

// Simulate consecutive walking actions
engine.transitionTo('walking');
engine.transitionTo('walking');
const penalizedWalking = engine.scoreAction('walking');
assert(penalizedWalking.finalScore < initialWalking.finalScore, "Repetition penalty reduces score");

// Cooldown test
engine.cooldowns.set('playing', 10);
const cdPlaying = engine.scoreAction('playing');
assert(cdPlaying.finalScore < cdPlaying.rawScore * 0.2, "Active cooldown heavily penalizes action");

// 4. Platform Adapter Stubs
const adapter = new UnsupportedPlatformAdapter('linux');
assert(adapter.platformName === 'linux', "Adapter identifies as linux");
assert(!adapter.supportsTransparency(), "Linux Wayland default transparency flagged as restricted");

console.log("🎉 All 14 portable core assertions passed successfully!");
