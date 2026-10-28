/**
 * Animatto Cross-Platform Core Types
 * Mirrors the native Swift models in a platform-agnostic, portable format.
 */

export type PetAction =
  | 'idle'
  | 'walking'
  | 'sitting'
  | 'sleeping'
  | 'playing'
  | 'dragging'
  | 'falling';

export type PersonalityPreset =
  | 'balanced'
  | 'energetic'
  | 'lazy'
  | 'curious'
  | 'playful'
  | 'shy'
  | 'mischievous'
  | 'calm'
  | 'sarcastic'
  | 'supportive';

export type TopicInterest = 'dislike' | 'neutral' | 'interested' | 'love';

export interface TopicPreferences {
  coding?: TopicInterest;
  gaming?: TopicInterest;
  music?: TopicInterest;
  art?: TopicInterest;
  anime?: TopicInterest;
  study?: TopicInterest;
  relaxation?: TopicInterest;
}

export interface CharacterBehaviorPreferences {
  cursorFollowingEnabled: boolean;
  cursorFollowStrength: number; // 0.0 - 1.0
  sleepAllowed: boolean;
  dialogueMuted: boolean;
  socialInteractionsAllowed: boolean;
  boundaryLimits?: {
    clampToSingleDisplay: boolean;
    respectTaskbar: boolean;
  };
}

export interface PersonalityProfile {
  version: number;
  id: string; // UUID v4
  name: string;
  preset?: PersonalityPreset | null;
  
  // The 10 Personality Dimensions (0.0 to 1.0)
  energy: number;
  laziness: number;
  curiosity: number;
  playfulness: number;
  sarcasm: number;
  supportiveness: number;
  shyness: number;
  sociability: number;
  mischief: number;
  independence: number;
  
  favoriteAction?: PetAction | null;
  topicPreferences: TopicPreferences;
  behaviorPreferences: CharacterBehaviorPreferences;
}

export interface CharacterNeeds {
  energy: number;     // 0.0 (exhausted) to 1.0 (fully rested)
  boredom: number;    // 0.0 (entertained) to 1.0 (restless)
  social: number;     // 0.0 (lonely) to 1.0 (socially satisfied)
  curiosity: number;  // 0.0 (satiated) to 1.0 (eager to explore)
}

export interface ActionScore {
  action: PetAction;
  rawScore: number;
  finalScore: number;
}

export interface CompanionMetadata {
  companionId: string;
  assetName: string;
  format: 'gif' | 'png' | 'apng' | 'webp' | 'shimeji_pack';
  frameCount?: number;
  frameDurationMs?: number;
  dimensions?: {
    width: number;
    height: number;
  };
  attribution?: {
    creator?: string;
    sourceUrl?: string;
    license?: string;
    importTimestamp?: string;
  };
}
