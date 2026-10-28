import type {
  PetAction,
  PersonalityProfile,
  CharacterNeeds,
  ActionScore
} from './types.ts';

export class PortableBehaviorEngine {
  public profile: PersonalityProfile;
  public needs: CharacterNeeds;
  public currentAction: PetAction = 'idle';
  public actionHistory: PetAction[] = [];
  public cooldowns: Map<PetAction, number> = new Map();

  constructor(profile: PersonalityProfile) {
    this.profile = profile;
    this.needs = {
      energy: 0.8,
      boredom: 0.2,
      social: 0.5,
      curiosity: 0.5
    };
  }

  public updateNeeds(deltaTimeSeconds: number): void {
    const decayRate = 0.01 * deltaTimeSeconds;
    
    // Active actions consume energy faster
    if (this.currentAction === 'walking' || this.currentAction === 'playing') {
      this.needs.energy = Math.max(0.0, this.needs.energy - decayRate * 2 * (0.5 + this.profile.energy * 0.5));
    } else if (this.currentAction === 'sleeping') {
      this.needs.energy = Math.min(1.0, this.needs.energy + decayRate * 4);
    }

    // Boredom accumulates when sitting or idle
    if (this.currentAction === 'idle' || this.currentAction === 'sitting') {
      this.needs.boredom = Math.min(1.0, this.needs.boredom + decayRate * (0.5 + this.profile.playfulness * 0.5));
    } else {
      this.needs.boredom = Math.max(0.0, this.needs.boredom - decayRate);
    }
  }

  public scoreAction(action: PetAction): ActionScore {
    let score = 50.0;

    switch (action) {
      case 'walking':
        score += this.profile.energy * 40.0;
        score -= this.profile.laziness * 30.0;
        score += this.needs.boredom * 20.0;
        break;
      case 'playing':
        score += this.profile.playfulness * 45.0;
        score += this.profile.mischief * 25.0;
        score += this.needs.boredom * 30.0;
        score -= (1.0 - this.needs.energy) * 35.0;
        break;
      case 'sleeping':
        score += this.profile.laziness * 40.0;
        score += (1.0 - this.needs.energy) * 50.0;
        score -= this.profile.energy * 30.0;
        if (!this.profile.behaviorPreferences.sleepAllowed) {
          score = -999.0;
        }
        break;
      case 'sitting':
        score += this.profile.laziness * 25.0;
        score += (1.0 - this.profile.energy) * 20.0;
        score -= this.needs.boredom * 20.0;
        break;
      case 'idle':
      default:
        score += 20.0;
        break;
    }

    // Favorite action bonus
    if (this.profile.favoriteAction === action) {
      score += 15.0;
    }

    const rawScore = Math.max(0.0, score);
    let finalScore = rawScore;

    // Repetition penalty: reduce score if this action was recently performed
    const repeatCount = this.actionHistory.slice(-3).filter(a => a === action).length;
    finalScore *= Math.pow(0.5, repeatCount);

    // Cooldown penalty
    const cd = this.cooldowns.get(action) ?? 0;
    if (cd > 0) {
      finalScore *= 0.1;
    }

    return {
      action,
      rawScore,
      finalScore
    };
  }

  public selectNextAction(rng: () => number = Math.random): PetAction {
    const candidateActions: PetAction[] = ['idle', 'walking', 'sitting', 'sleeping', 'playing'];
    const scored = candidateActions.map(a => this.scoreAction(a));

    const totalWeight = scored.reduce((sum, s) => sum + Math.max(0.1, s.finalScore), 0);
    let threshold = rng() * totalWeight;

    for (const item of scored) {
      threshold -= Math.max(0.1, item.finalScore);
      if (threshold <= 0) {
        this.transitionTo(item.action);
        return item.action;
      }
    }

    this.transitionTo('idle');
    return 'idle';
  }

  public transitionTo(action: PetAction): void {
    this.currentAction = action;
    this.actionHistory.push(action);
    if (this.actionHistory.length > 20) {
      this.actionHistory.shift();
    }
  }
}
