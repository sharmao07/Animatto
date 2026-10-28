import type {
  PersonalityProfile,
  PersonalityPreset,
  CharacterBehaviorPreferences,
  TopicPreferences
} from './types.ts';

export function clampTrait(val: number, fallback = 0.5): number {
  if (typeof val !== 'number' || isNaN(val)) return fallback;
  return Math.max(0.0, Math.min(1.0, val));
}

export function defaultBehaviorPreferences(): CharacterBehaviorPreferences {
  return {
    cursorFollowingEnabled: true,
    cursorFollowStrength: 0.5,
    sleepAllowed: true,
    dialogueMuted: false,
    socialInteractionsAllowed: true,
    boundaryLimits: {
      clampToSingleDisplay: false,
      respectTaskbar: true
    }
  };
}

export function defaultTopicPreferences(): TopicPreferences {
  return {
    coding: 'neutral',
    gaming: 'neutral',
    music: 'neutral',
    art: 'neutral',
    anime: 'neutral',
    study: 'neutral',
    relaxation: 'neutral'
  };
}

export function createPresetProfile(
  preset: PersonalityPreset,
  id: string,
  name: string
): PersonalityProfile {
  const base: PersonalityProfile = {
    version: 2,
    id,
    name,
    preset,
    energy: 0.5,
    laziness: 0.5,
    curiosity: 0.5,
    playfulness: 0.5,
    sarcasm: 0.2,
    supportiveness: 0.5,
    shyness: 0.5,
    sociability: 0.5,
    mischief: 0.3,
    independence: 0.5,
    favoriteAction: null,
    topicPreferences: defaultTopicPreferences(),
    behaviorPreferences: defaultBehaviorPreferences()
  };

  switch (preset) {
    case 'energetic':
      base.energy = 0.9;
      base.laziness = 0.1;
      base.playfulness = 0.8;
      base.favoriteAction = 'walking';
      break;
    case 'lazy':
      base.energy = 0.2;
      base.laziness = 0.9;
      base.playfulness = 0.2;
      base.favoriteAction = 'sleeping';
      break;
    case 'curious':
      base.curiosity = 0.9;
      base.energy = 0.7;
      base.laziness = 0.3;
      base.favoriteAction = 'walking';
      break;
    case 'playful':
      base.playfulness = 0.9;
      base.energy = 0.8;
      base.sociability = 0.8;
      base.favoriteAction = 'playing';
      break;
    case 'shy':
      base.shyness = 0.85;
      base.sociability = 0.2;
      base.curiosity = 0.4;
      base.favoriteAction = 'sitting';
      base.behaviorPreferences.cursorFollowingEnabled = false;
      break;
    case 'mischievous':
      base.mischief = 0.9;
      base.playfulness = 0.8;
      base.energy = 0.75;
      base.favoriteAction = 'playing';
      break;
    case 'calm':
      base.energy = 0.35;
      base.laziness = 0.45;
      base.playfulness = 0.3;
      base.favoriteAction = 'sitting';
      break;
    case 'sarcastic':
      base.sarcasm = 0.9;
      base.supportiveness = 0.2;
      base.playfulness = 0.6;
      break;
    case 'supportive':
      base.supportiveness = 0.95;
      base.sarcasm = 0.05;
      base.sociability = 0.8;
      break;
    case 'balanced':
    default:
      // Balanced default values
      break;
  }

  return base;
}

/**
 * Validates, cleans, and migrates a profile from JSON.
 * Upgrades Schema V1 (without sarcasm/supportiveness/etc.) to Schema V2.
 */
export function sanitizeAndMigrateProfile(raw: Record<string, any>): PersonalityProfile {
  const version = raw.version === 1 || raw.version === 2 ? raw.version : 2;
  const id = typeof raw.id === 'string' && raw.id.length > 0 ? raw.id : '00000000-0000-0000-0000-000000000000';
  const name = typeof raw.name === 'string' && raw.name.trim().length > 0 ? raw.name.trim() : 'Companion';

  return {
    version: 2,
    id,
    name,
    preset: raw.preset ?? null,
    energy: clampTrait(raw.energy, 0.5),
    laziness: clampTrait(raw.laziness, 0.5),
    curiosity: clampTrait(raw.curiosity, 0.5),
    playfulness: clampTrait(raw.playfulness, 0.5),
    sarcasm: clampTrait(raw.sarcasm, 0.2),
    supportiveness: clampTrait(raw.supportiveness, 0.5),
    shyness: clampTrait(raw.shyness, 0.5),
    sociability: clampTrait(raw.sociability, 0.5),
    mischief: clampTrait(raw.mischief, 0.3),
    independence: clampTrait(raw.independence, 0.5),
    favoriteAction: raw.favoriteAction ?? null,
    topicPreferences: {
      ...defaultTopicPreferences(),
      ...(raw.topicPreferences || {})
    },
    behaviorPreferences: {
      ...defaultBehaviorPreferences(),
      ...(raw.behaviorPreferences || {})
    }
  };
}
