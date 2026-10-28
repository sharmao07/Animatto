/**
 * Animatto Web — Official Interactive macOS Desktop & Application Showcase
 * Architecture: Zero-dependency Vanilla ES Module, 60fps Physics & Ambient Engine
 * Replicating: Native Swift/AppKit mechanics, Phase 6 Personality Matrix,
 * Phase 9 Social Interactions, Phase 10 Focus Timer, Phase 17 Ambient Worlds.
 */

// =============================================================================
// 1. DATA DEFINITIONS & ASSET REGISTRY
// =============================================================================

const COMPANIONS_DATA = {
  umamusume: {
    id: 'umamusume',
    name: 'Umamusume',
    title: 'Special Week',
    sprite: 'sprites/umamusume.png',
    archetype: 'curious',
    color: '#e87a90',
    scale: 0.9,
    width: 90,
    height: 90,
    needs: { energy: 90, happiness: 94, curiosity: 88, boredom: 12 },
    speechPool: [
      "Pacing my breath... gotta win the Twinkle Series!",
      "Did you know horses sprint up to 40 mph? Let's race!",
      "Carrot treats are the ultimate coding fuel! 🥕",
      "The grass on this desktop looks so lush!",
      "Stay hydrated while you work on that pull request!",
      "Leaping between your window titlebars is my favorite workout!"
    ]
  },
  miku: {
    id: 'miku',
    name: 'Hatsune Miku',
    title: 'Virtual Singer',
    sprite: 'sprites/miku.png',
    archetype: 'playful',
    color: '#39c5bb',
    scale: 0.95,
    width: 86,
    height: 88,
    needs: { energy: 85, happiness: 98, curiosity: 80, boredom: 8 },
    speechPool: [
      "Miku Miku ni shite ageru♪",
      "Composing a 16-bit synth melody in my head~",
      "Singing keeps my CPU nice and warm! 🎤",
      "39! Thank you for having me on your Mac desktop!",
      "Your mouse cursor dances to the rhythm!",
      "Leek energy is 100% renewable and zero emissions!"
    ]
  },
  chiikawa: {
    id: 'chiikawa',
    name: 'Chiikawa',
    title: 'Small & Gentle Friend',
    sprite: 'sprites/chiikawa.png',
    archetype: 'gentle',
    color: '#ffc1d0',
    scale: 0.9,
    width: 82,
    height: 84,
    needs: { energy: 65, happiness: 82, curiosity: 60, boredom: 20 },
    speechPool: [
      "Wa... wawa! (Looking around curiously)",
      "Yaha! Doing my very best weeding work today!",
      "Found a delicious sweet pudding treat! 🍮",
      "Please don't shake the mouse too fast... (trembles happily)",
      "Fuu... taking a peaceful nap on this window ledge."
    ]
  },
  sayori: {
    id: 'sayori',
    name: 'Sayori',
    title: 'Sunshine Friend',
    sprite: 'sprites/sayori.png',
    archetype: 'friendly',
    color: '#ff9aa2',
    scale: 0.9,
    width: 80,
    height: 88,
    needs: { energy: 78, happiness: 90, curiosity: 82, boredom: 14 },
    speechPool: [
      "Don't forget to take a break and stretch! ✨",
      "Warm cookies make everything twenty percent better!",
      "I'm so happy to hang out with you today!",
      "The weather on this screen is so lovely~",
      "Yay! You're doing absolutely fantastic work today!"
    ]
  },
  usagi: {
    id: 'usagi',
    name: 'Usagi',
    title: 'Chaotic Bunny',
    sprite: 'sprites/usagi.png',
    archetype: 'chaotic',
    color: '#ffea79',
    scale: 0.85,
    width: 78,
    height: 88,
    needs: { energy: 100, happiness: 96, curiosity: 98, boredom: 2 },
    speechPool: [
      "Uuuuuurrraaaahhhaaa!! ⚡️",
      "HA-IT! *bounces wildly across menu bar*",
      "Pulululululu!! (spins in circles excitedly)",
      "YAH-HA! *eats an imaginary carrot baton*",
      "Chak-chak-chak-chak! No stopping now!"
    ]
  },
  taiyaki: {
    id: 'taiyaki',
    name: 'Taiyaki',
    title: 'Cozy Pastry',
    sprite: 'sprites/taiyaki.png',
    archetype: 'stoic',
    color: '#d48d5b',
    scale: 0.9,
    width: 90,
    height: 85,
    needs: { energy: 45, happiness: 86, curiosity: 50, boredom: 30 },
    speechPool: [
      "Crispy on the outside, sweet red bean paste inside.",
      "Slow down... life isn't a benchmark test.",
      "A warm cup of green tea goes well with writing code. 🍵",
      "Floating gently... no need to rush anywhere.",
      "Zen state achieved on this window ledge."
    ]
  },
  nyancat: {
    id: 'nyancat',
    name: 'Nyan Cat',
    title: 'Cosmic Poptart',
    sprite: 'sprites/nyancat.png',
    archetype: 'playful',
    color: '#ff77a9',
    scale: 0.85,
    width: 95,
    height: 48,
    needs: { energy: 99, happiness: 99, curiosity: 92, boredom: 0 },
    speechPool: [
      "Nyan nyan nyan nyan nyan nyan~♪ 🌈",
      "Zooming at Warp 9 through your macOS dock!",
      "Look at this sparkling strawberry frosting!",
      "Cosmic poptarts leave rainbow trails everywhere!",
      "Zero gravity is undeniably the best gravity!"
    ]
  },
  fattie: {
    id: 'fattie',
    name: 'Fattie',
    title: 'Sleepy Chonk',
    sprite: 'sprites/fattie.png',
    archetype: 'sleepy',
    color: '#a0a0a0',
    scale: 0.95,
    width: 88,
    height: 88,
    needs: { energy: 25, happiness: 75, curiosity: 35, boredom: 65 },
    speechPool: [
      "Prrr... your MacBook processor runs warm. Perfect bed. 💤",
      "Yaaaawn... is it lunchtime yet?",
      "If it fits, I sits.",
      "Don't move this window, I'm basking in screen glow.",
      "Zzzz... *happy rhythmic purring sounds*"
    ]
  }
};

const ARCHETYPES_CONFIG = {
  curious: {
    name: 'Curious Explorer',
    hopChance: 0.20,
    sleepChance: 0.04,
    speedMul: 1.15,
    remark: "Ooh! What does this button do?"
  },
  playful: {
    name: 'Playful Companion',
    hopChance: 0.35,
    sleepChance: 0.05,
    speedMul: 1.30,
    remark: "Let's play a game together!"
  },
  gentle: {
    name: 'Gentle Guardian',
    hopChance: 0.08,
    sleepChance: 0.15,
    speedMul: 0.75,
    remark: "I'll watch over your desktop quietly."
  },
  friendly: {
    name: 'Friendly Sidekick',
    hopChance: 0.20,
    sleepChance: 0.10,
    speedMul: 1.0,
    remark: "You're doing awesome work today!"
  },
  chaotic: {
    name: 'Chaotic Jester',
    hopChance: 0.50,
    sleepChance: 0.02,
    speedMul: 1.70,
    remark: "YAH-HA!! ZOOMIES TIME!"
  },
  sleepy: {
    name: 'Sleepy Loaf',
    hopChance: 0.02,
    sleepChance: 0.45,
    speedMul: 0.50,
    remark: "Just five more minutes of napping..."
  },
  stoic: {
    name: 'Stoic Thinker',
    hopChance: 0.05,
    sleepChance: 0.18,
    speedMul: 0.65,
    remark: "Patience and steady focus."
  },
  philosophical: {
    name: 'Philosopher',
    hopChance: 0.06,
    sleepChance: 0.16,
    speedMul: 0.70,
    remark: "Does a pixel companion truly exist?"
  },
  mischievous: {
    name: 'Mischievous Sprite',
    hopChance: 0.30,
    sleepChance: 0.06,
    speedMul: 1.35,
    remark: "Hehehe, I touched the traffic lights!"
  },
  scholarly: {
    name: 'Scholarly Reader',
    hopChance: 0.10,
    sleepChance: 0.12,
    speedMul: 0.85,
    remark: "Fascinating terminal commands today."
  }
};

const SOCIAL_PAIRS = [
  {
    pair: ['chiikawa', 'usagi'],
    textA: "Wawa... Usagi-chan?! (quivers)",
    textB: "URAAAAHH! YAH-HA!! ⚡️"
  },
  {
    pair: ['miku', 'nyancat'],
    textA: "Nyan-chan! Duet with my synthesizer! 🎤",
    textB: "Nyan nyan nyan! ♪🌈"
  },
  {
    pair: ['umamusume', 'fattie'],
    textA: "Come on Fattie! 3 sprint laps around the Xcode window!",
    textB: "No thanks... this warm title bar is my home. 💤"
  },
  {
    pair: ['sayori', 'chiikawa'],
    textA: "Here's a fresh cookie just for you! 🍪",
    textB: "Wa... arigato! (sniffs cookie happily)"
  },
  {
    pair: ['miku', 'sayori'],
    textA: "Let's sing an upbeat song for our user!",
    textB: "Yay! Songs make study time so bright! ✨"
  },
  {
    pair: ['umamusume', 'usagi'],
    textA: "Ready, set, GO! Race to the dock!",
    textB: "PULULULULU! FAST AS LIGHTNING!"
  }
];

// =============================================================================
// 2. AUDIO SYNTHESIZER (Apple Web Audio API — No External Files Needed)
// =============================================================================

class SoundFX {
  constructor() {
    this.ctx = null;
    this.muted = false;
  }

  init() {
    if (!this.ctx && (window.AudioContext || window.webkitAudioContext)) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioCtx();
    }
  }

  playPop() {
    if (this.muted) return;
    this.init();
    if (!this.ctx) return;
    try {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      const now = this.ctx.currentTime;
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(600, now);
      osc.frequency.exponentialRampToValueAtTime(150, now + 0.08);
      gain.gain.setValueAtTime(0.18, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.08);
    } catch (e) {}
  }

  playHop() {
    if (this.muted) return;
    this.init();
    if (!this.ctx) return;
    try {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      const now = this.ctx.currentTime;
      osc.type = 'sine';
      osc.frequency.setValueAtTime(380, now);
      osc.frequency.exponentialRampToValueAtTime(780, now + 0.12);
      gain.gain.setValueAtTime(0.15, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.12);
    } catch (e) {}
  }

  playCollect() {
    if (this.muted) return;
    this.init();
    if (!this.ctx) return;
    try {
      const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
      const now = this.ctx.currentTime;
      notes.forEach((freq, i) => {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        const startTime = now + (i * 0.04);
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, startTime);
        gain.gain.setValueAtTime(0.12, startTime);
        gain.gain.exponentialRampToValueAtTime(0.001, startTime + 0.18);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(startTime);
        osc.stop(startTime + 0.18);
      });
    } catch (e) {}
  }

  playChime() {
    if (this.muted) return;
    this.init();
    if (!this.ctx) return;
    try {
      const now = this.ctx.currentTime;
      [880, 1108.73, 1318.51].forEach((freq, i) => {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        const startTime = now + (i * 0.08);
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, startTime);
        gain.gain.setValueAtTime(0.15, startTime);
        gain.gain.exponentialRampToValueAtTime(0.001, startTime + 0.35);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(startTime);
        osc.stop(startTime + 0.35);
      });
    } catch (e) {}
  }
}

const soundFX = new SoundFX();

// =============================================================================
// 3. PHASE 17 AMBIENT WORLDS CANVAS ENGINE (Decoupled High-Performance Particles)
// =============================================================================

class AmbientEngine {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.weather = 'none'; // none, rain, snow, fog, sunlight, wind, leaves
    this.intensity = 0.7;  // 0.1 - 1.0
    this.qualityTier = 'medium'; // low, medium, high
    this.reducedMotion = false;
    this.inverted = false;
    this.particles = [];
    this.width = 0;
    this.height = 0;
    this.animId = null;

    this.tierLimits = {
      low: 40,
      medium: 110,
      high: 260
    };

    this.resize();
    window.addEventListener('resize', () => this.resize());
    this.startLoop();
  }

  resize() {
    const rect = this.canvas.parentElement.getBoundingClientRect();
    this.width = rect.width;
    this.height = rect.height;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    this.canvas.width = this.width * dpr;
    this.canvas.height = this.height * dpr;
    this.ctx.scale(dpr, dpr);
    this.initParticles();
  }

  setWeather(type) {
    this.weather = type;
    this.initParticles();
  }

  setIntensity(val) {
    this.intensity = Math.max(0.1, Math.min(1.0, val));
    this.initParticles();
  }

  setQuality(tier) {
    if (this.tierLimits[tier]) {
      this.qualityTier = tier;
      this.initParticles();
    }
  }

  getTargetCount() {
    if (this.weather === 'none') return 0;
    const base = this.tierLimits[this.qualityTier] || 110;
    let count = Math.round(base * this.intensity);
    if (this.weather === 'fog') count = Math.max(8, Math.round(count * 0.15));
    if (this.weather === 'sunlight') count = Math.max(16, Math.round(count * 0.35));
    if (this.weather === 'leaves') count = Math.max(12, Math.round(count * 0.40));
    return count;
  }

  initParticles() {
    this.particles = [];
    const count = this.getTargetCount();
    for (let i = 0; i < count; i++) {
      this.particles.push(this.createParticle(true));
    }
  }

  createParticle(randomY = false) {
    const yPos = randomY ? Math.random() * this.height : (this.inverted ? this.height + 10 : -15);
    const speedScale = this.reducedMotion ? 0.3 : 1.0;
    const dir = this.inverted ? -1 : 1;

    switch (this.weather) {
      case 'rain':
        return {
          x: Math.random() * (this.width + 100) - 50,
          y: yPos,
          length: (14 + Math.random() * 16) * this.intensity,
          speedY: (12 + Math.random() * 8) * this.intensity * speedScale * dir,
          speedX: (-2 - Math.random() * 2) * speedScale,
          alpha: 0.25 + Math.random() * 0.4,
          thickness: 1 + Math.random() * 1.5,
          color: 'rgba(164, 214, 255,'
        };

      case 'snow':
        return {
          x: Math.random() * this.width,
          y: yPos,
          radius: 1.5 + Math.random() * 3.5,
          speedY: (1.2 + Math.random() * 2.2) * this.intensity * speedScale * dir,
          speedX: (Math.random() - 0.5) * 1.2 * speedScale,
          swaySpeed: 0.02 + Math.random() * 0.03,
          swayAngle: Math.random() * Math.PI * 2,
          alpha: 0.4 + Math.random() * 0.5,
          color: 'rgba(255, 255, 255,'
        };

      case 'fog':
        return {
          x: Math.random() * this.width,
          y: Math.random() * this.height,
          radius: 80 + Math.random() * 120,
          speedX: (0.3 + Math.random() * 0.5) * speedScale * (Math.random() > 0.5 ? 1 : -1),
          speedY: (Math.random() - 0.5) * 0.2 * speedScale,
          alpha: (0.04 + Math.random() * 0.06) * this.intensity,
          color: 'rgba(215, 205, 240,'
        };

      case 'sunlight':
        return {
          x: Math.random() * this.width,
          y: Math.random() * this.height,
          radius: 2 + Math.random() * 5,
          speedY: (-0.4 - Math.random() * 0.6) * speedScale * dir,
          speedX: (Math.random() - 0.5) * 0.5 * speedScale,
          alpha: 0.2 + Math.random() * 0.5,
          pulseSpeed: 0.03 + Math.random() * 0.04,
          pulse: Math.random() * Math.PI,
          color: 'rgba(255, 224, 130,'
        };

      case 'wind':
        return {
          x: Math.random() * this.width,
          y: Math.random() * this.height,
          length: 25 + Math.random() * 45,
          speedX: (8 + Math.random() * 10) * this.intensity * speedScale,
          speedY: (Math.random() - 0.5) * 1.5 * speedScale,
          alpha: 0.15 + Math.random() * 0.3,
          thickness: 1.2,
          color: 'rgba(180, 220, 255,'
        };

      case 'leaves':
        const leafColors = ['#e06c4b', '#e6a13b', '#c24b38', '#d49b43'];
        return {
          x: Math.random() * (this.width + 100) - 50,
          y: yPos,
          size: 7 + Math.random() * 8,
          speedY: (1.5 + Math.random() * 2.5) * this.intensity * speedScale * dir,
          speedX: (1.5 + Math.random() * 2) * speedScale,
          rot: Math.random() * Math.PI * 2,
          rotSpeed: (Math.random() - 0.5) * 0.08 * speedScale,
          color: leafColors[Math.floor(Math.random() * leafColors.length)],
          alpha: 0.7 + Math.random() * 0.3
        };

      default:
        return null;
    }
  }

  startLoop() {
    const loop = () => {
      this.updateAndDraw();
      this.animId = requestAnimationFrame(loop);
    };
    this.animId = requestAnimationFrame(loop);
  }

  updateAndDraw() {
    this.ctx.clearRect(0, 0, this.width, this.height);
    if (this.weather === 'none' || this.particles.length === 0) return;

    // Draw Sunlight Sunbeams overlay if sunlight mode
    if (this.weather === 'sunlight') {
      const grad = this.ctx.createLinearGradient(0, 0, this.width, this.height);
      grad.addColorStop(0, `rgba(255, 235, 160, ${0.12 * this.intensity})`);
      grad.addColorStop(0.5, `rgba(255, 210, 120, ${0.05 * this.intensity})`);
      grad.addColorStop(1, 'rgba(255, 210, 120, 0)');
      this.ctx.fillStyle = grad;
      this.ctx.fillRect(0, 0, this.width, this.height);
    }

    const count = this.particles.length;
    for (let i = 0; i < count; i++) {
      const p = this.particles[i];
      if (!p) continue;

      if (this.weather === 'rain') {
        p.x += p.speedX;
        p.y += p.speedY;
        this.ctx.strokeStyle = `${p.color} ${p.alpha})`;
        this.ctx.lineWidth = p.thickness;
        this.ctx.beginPath();
        this.ctx.moveTo(p.x, p.y);
        this.ctx.lineTo(p.x + p.speedX * 1.5, p.y + p.length * (this.inverted ? -1 : 1));
        this.ctx.stroke();

        if ((!this.inverted && p.y > this.height) || (this.inverted && p.y < 0)) {
          this.particles[i] = this.createParticle(false);
        }
      } else if (this.weather === 'snow') {
        p.swayAngle += p.swaySpeed;
        p.x += p.speedX + Math.sin(p.swayAngle) * 0.8;
        p.y += p.speedY;

        this.ctx.fillStyle = `${p.color} ${p.alpha})`;
        this.ctx.beginPath();
        this.ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        this.ctx.fill();

        if ((!this.inverted && p.y > this.height) || (this.inverted && p.y < 0)) {
          this.particles[i] = this.createParticle(false);
        }
      } else if (this.weather === 'fog') {
        p.x += p.speedX;
        p.y += p.speedY;

        const radGrad = this.ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.radius);
        radGrad.addColorStop(0, `${p.color} ${p.alpha})`);
        radGrad.addColorStop(1, `${p.color} 0)`);
        this.ctx.fillStyle = radGrad;
        this.ctx.beginPath();
        this.ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        this.ctx.fill();

        if (p.x < -p.radius) p.x = this.width + p.radius;
        if (p.x > this.width + p.radius) p.x = -p.radius;
      } else if (this.weather === 'sunlight') {
        p.pulse += p.pulseSpeed;
        p.x += p.speedX;
        p.y += p.speedY;
        const currentAlpha = p.alpha * (0.6 + 0.4 * Math.sin(p.pulse));

        this.ctx.fillStyle = `${p.color} ${currentAlpha})`;
        this.ctx.beginPath();
        this.ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        this.ctx.fill();

        if (p.y < 0) p.y = this.height;
        if (p.y > this.height) p.y = 0;
      } else if (this.weather === 'wind') {
        p.x += p.speedX;
        p.y += p.speedY;

        this.ctx.strokeStyle = `${p.color} ${p.alpha})`;
        this.ctx.lineWidth = p.thickness;
        this.ctx.beginPath();
        this.ctx.moveTo(p.x, p.y);
        this.ctx.lineTo(p.x + p.length, p.y);
        this.ctx.stroke();

        if (p.x > this.width) {
          p.x = -p.length;
          p.y = Math.random() * this.height;
        }
      } else if (this.weather === 'leaves') {
        p.x += p.speedX;
        p.y += p.speedY;
        p.rot += p.rotSpeed;

        this.ctx.save();
        this.ctx.translate(p.x, p.y);
        this.ctx.rotate(p.rot);
        this.ctx.fillStyle = p.color;
        this.ctx.globalAlpha = p.alpha;
        this.ctx.beginPath();
        this.ctx.ellipse(0, 0, p.size, p.size * 0.5, 0, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.restore();

        if ((!this.inverted && p.y > this.height) || (this.inverted && p.y < 0) || p.x > this.width + 50) {
          this.particles[i] = this.createParticle(false);
        }
      }
    }
  }
}

// =============================================================================
// 4. COMPANION INSTANCE & PHYSICS SIMULATION
// =============================================================================

class CompanionInstance {
  constructor(data, stageEl, app) {
    this.data = data;
    this.stageEl = stageEl;
    this.app = app;
    this.id = data.id;
    this.name = data.name;
    this.sprite = data.sprite;
    this.archetype = data.archetype;
    this.needs = { ...data.needs };

    this.width = data.width || 88;
    this.height = data.height || 88;

    // Physical coordinates relative to #companionStage
    this.x = 40 + Math.random() * (Math.max(100, this.stageEl.offsetWidth - 200));
    this.y = 100;
    this.vx = (Math.random() - 0.5) * 2;
    this.vy = 0;
    this.facing = Math.random() > 0.5 ? 1 : -1; // 1 = right, -1 = left

    // States: 'idle', 'walking', 'hopping', 'sleeping', 'dragging', 'menubar'
    this.state = 'idle';
    this.stateTimer = 60 + Math.random() * 120;
    this.speechTimeout = null;

    // Momentum dragging tracking
    this.isDragging = false;
    this.dragStartX = 0;
    this.dragStartY = 0;
    this.lastPointerX = 0;
    this.lastPointerY = 0;
    this.recentDeltas = [];

    // DOM Element setup
    this.element = this.createDOM();
    this.stageEl.appendChild(this.element);
    this.updatePosition();
  }

  createDOM() {
    const el = document.createElement('div');
    el.className = 'sim-companion-entity';
    el.dataset.id = this.id;
    el.style.width = `${this.width}px`;
    el.style.height = `${this.height}px`;

    const img = document.createElement('img');
    img.src = this.sprite;
    img.alt = this.name;
    img.className = 'companion-sprite-img';
    img.draggable = false;
    el.appendChild(img);

    // Pointer events for smooth desktop dragging & momentum fling
    el.addEventListener('pointerdown', (e) => this.onPointerDown(e));

    return el;
  }

  onPointerDown(e) {
    e.preventDefault();
    soundFX.playPop();
    this.isDragging = true;
    this.state = 'dragging';
    this.element.classList.remove('walking', 'sleeping', 'hopping');
    this.element.setPointerCapture(e.pointerId);

    const rect = this.element.getBoundingClientRect();
    this.dragOffsetX = e.clientX - rect.left;
    this.dragOffsetY = e.clientY - rect.top;

    this.lastPointerX = e.clientX;
    this.lastPointerY = e.clientY;
    this.recentDeltas = [];

    const onPointerMove = (ev) => {
      if (!this.isDragging) return;
      const stageRect = this.stageEl.getBoundingClientRect();
      this.x = ev.clientX - stageRect.left - this.dragOffsetX;
      this.y = ev.clientY - stageRect.top - this.dragOffsetY;

      // Track last velocities for fling
      const dx = ev.clientX - this.lastPointerX;
      const dy = ev.clientY - this.lastPointerY;
      this.recentDeltas.push({ dx, dy });
      if (this.recentDeltas.length > 5) this.recentDeltas.shift();

      this.lastPointerX = ev.clientX;
      this.lastPointerY = ev.clientY;

      if (dx > 0) this.facing = 1;
      else if (dx < 0) this.facing = -1;

      this.updatePosition();
    };

    const onPointerUp = (ev) => {
      this.isDragging = false;
      this.element.releasePointerCapture(ev.pointerId);
      window.removeEventListener('pointermove', onPointerMove);
      window.removeEventListener('pointerup', onPointerUp);

      // Calculate fling momentum
      let avgDx = 0, avgDy = 0;
      if (this.recentDeltas.length > 0) {
        this.recentDeltas.forEach(d => { avgDx += d.dx; avgDy += d.dy; });
        avgDx /= this.recentDeltas.length;
        avgDy /= this.recentDeltas.length;
      }

      const dragDistance = Math.hypot(ev.clientX - this.lastPointerX, ev.clientY - this.lastPointerY);
      if (Math.abs(avgDx) < 1.5 && Math.abs(avgDy) < 1.5 && dragDistance < 6) {
        // Simple tap / click: speak and playful hop!
        this.hop();
        this.speak();
        this.app.selectCompanionForInspector(this);
      } else {
        // Fling momentum!
        this.vx = Math.max(-14, Math.min(14, avgDx * 1.2));
        this.vy = Math.max(-14, Math.min(14, avgDy * 1.2));
      }

      this.state = 'idle';
      this.stateTimer = 40;
    };

    window.addEventListener('pointermove', onPointerMove);
    window.addEventListener('pointerup', onPointerUp);

    this.app.selectCompanionForInspector(this);
  }

  updatePhysics(stageWidth, stageHeight, obstacleWindowRect, invertGravity) {
    if (this.isDragging || this.app.simulationPaused) return;

    // Archetype traits
    const arch = ARCHETYPES_CONFIG[this.archetype] || ARCHETYPES_CONFIG.curious;
    const speedMul = arch.speedMul || 1.0;

    // Gravity: standard pulls down; invertGravity pulls up toward menu bar
    const gravity = invertGravity ? -0.65 : 0.65;
    this.vy += gravity;

    // Terminal velocity clamp to avoid window tunneling (per native macOS physics spec)
    this.vy = Math.max(-18, Math.min(18, this.vy));

    // Apply horizontal friction
    this.vx *= 0.94;

    this.x += this.vx;
    this.y += this.vy;

    // Floor and Ceiling bounds
    const floorY = stageHeight - this.height - 24; // Above dock
    const ceilingY = 0; // Menu bar bottom

    // Surface Obstacle Collisions (Simulated Application Window)
    let onWindowSurface = false;
    if (obstacleWindowRect && obstacleWindowRect.visible) {
      const winTop = obstacleWindowRect.top;
      const winLeft = obstacleWindowRect.left;
      const winRight = obstacleWindowRect.right;

      // Landing on top edge of window
      if (!invertGravity && this.vy >= 0) {
        const footY = this.y + this.height;
        if (footY >= winTop && footY <= winTop + 24) {
          if (this.x + this.width * 0.7 >= winLeft && this.x + this.width * 0.3 <= winRight) {
            this.y = winTop - this.height;
            this.vy = 0;
            onWindowSurface = true;
          }
        }
      }
    }

    if (!invertGravity) {
      if (this.y >= floorY) {
        this.y = floorY;
        this.vy = 0;
      }
      if (this.y < ceilingY) {
        this.y = ceilingY;
        this.vy = 0;
      }
    } else {
      // Inverted gravity: ceiling is floor (menu bar walking)
      if (this.y <= ceilingY) {
        this.y = ceilingY;
        this.vy = 0;
      }
      if (this.y > floorY) {
        this.y = floorY;
        this.vy = 0;
      }
    }

    // Left and Right stage boundaries
    if (this.x < 0) {
      this.x = 0;
      this.vx = Math.abs(this.vx) * 0.7;
      this.facing = 1;
    } else if (this.x > stageWidth - this.width) {
      this.x = stageWidth - this.width;
      this.vx = -Math.abs(this.vx) * 0.7;
      this.facing = -1;
    }

    // Behavior State Machine Tick
    this.stateTimer--;
    if (this.stateTimer <= 0) {
      this.decideNextState(arch, onWindowSurface);
    }

    // Perform active state behavior
    if (this.state === 'walking') {
      const walkSpeed = 1.4 * speedMul * this.facing;
      this.x += walkSpeed;
      if (Math.random() < 0.02) this.facing *= -1;
    }

    this.updatePosition(invertGravity);
  }

  decideNextState(arch, onWindowSurface) {
    const roll = Math.random();

    if (roll < arch.sleepChance) {
      this.state = 'sleeping';
      this.stateTimer = 160 + Math.random() * 200;
      this.element.className = 'sim-companion-entity sleeping';
    } else if (roll < arch.sleepChance + arch.hopChance) {
      this.hop();
      this.stateTimer = 40 + Math.random() * 50;
    } else if (roll < 0.70) {
      this.state = 'walking';
      this.facing = Math.random() > 0.5 ? 1 : -1;
      this.stateTimer = 80 + Math.random() * 120;
      this.element.className = 'sim-companion-entity walking';
    } else {
      this.state = 'idle';
      this.stateTimer = 60 + Math.random() * 90;
      this.element.className = 'sim-companion-entity';
    }
  }

  hop() {
    soundFX.playHop();
    this.state = 'hopping';
    this.element.className = 'sim-companion-entity hopping';
    this.vy = this.app.invertGravity ? 9 : -9;
    setTimeout(() => {
      if (this.state === 'hopping') {
        this.state = 'idle';
        this.element.className = 'sim-companion-entity';
      }
    }, 450);
  }

  speak(customText = null) {
    const text = customText || this.data.speechPool[Math.floor(Math.random() * this.data.speechPool.length)];
    if (!text) return;

    soundFX.playPop();

    // Remove existing bubble if present
    const existing = this.element.querySelector('.companion-speech-bubble');
    if (existing) existing.remove();
    if (this.speechTimeout) clearTimeout(this.speechTimeout);

    const bubble = document.createElement('div');
    bubble.className = 'companion-speech-bubble';
    bubble.textContent = text;
    this.element.appendChild(bubble);

    this.speechTimeout = setTimeout(() => {
      bubble.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
      bubble.style.opacity = '0';
      bubble.style.transform = 'translateX(-50%) translateY(-10px)';
      setTimeout(() => bubble.remove(), 320);
    }, 4500);
  }

  toggleSleep() {
    if (this.state === 'sleeping') {
      this.state = 'idle';
      this.element.className = 'sim-companion-entity';
    } else {
      this.state = 'sleeping';
      this.element.className = 'sim-companion-entity sleeping';
    }
  }

  updatePosition(invertGravity = false) {
    const scaleX = this.facing;
    const scaleY = invertGravity ? -1 : 1;
    this.element.style.transform = `translate3d(${Math.round(this.x)}px, ${Math.round(this.y)}px, 0) scale(${scaleX}, ${scaleY})`;
  }

  destroy() {
    if (this.speechTimeout) clearTimeout(this.speechTimeout);
    this.element.remove();
  }
}

// =============================================================================
// 5. MAIN ANIMATTO APPLICATION ORCHESTRATOR
// =============================================================================

class AnimattoApp {
  constructor() {
    this.stageEl = document.getElementById('companionStage');
    this.canvasEl = document.getElementById('ambientCanvas');
    this.collectiblesLayer = document.getElementById('collectiblesLayer');
    this.windowEl = document.getElementById('simAppWindow');
    this.windowTitlebarEl = document.getElementById('simWindowTitlebar');

    this.activeCompanions = [];
    this.selectedCompanion = null;
    this.simulationPaused = false;
    this.invertGravity = false;
    this.minigameScore = 0;
    this.minigameEnabled = true;
    this.socialCooldown = 0;

    // Phase 10 Focus Timer State
    this.timerSeconds = 25 * 60;
    this.timerRunning = false;
    this.timerInterval = null;
    this.timerMode = 'focus'; // 'focus' or 'break'

    // Initialize Subsystems
    this.ambientEngine = new AmbientEngine(this.canvasEl);

    this.initRosterUI();
    this.initArchetypeChips();
    this.initPlaygroundControls();
    this.initSimulatedWindow();
    this.initMenuBar();
    this.initCollectiblesMinigame();
    this.initFocusTimer();
    this.initGalleryTabs();
    this.initFAQAccordion();

    // Spawn 2 initial companions (Umamusume & Chiikawa)
    this.spawnCompanion('umamusume');
    this.spawnCompanion('chiikawa');

    // Start 60fps Physics & Simulation Loop
    this.startMainLoop();
  }

  // ---------------------------------------------------------------------------
  // A. Companion Management
  // ---------------------------------------------------------------------------

  spawnCompanion(id) {
    const data = COMPANIONS_DATA[id];
    if (!data) return;

    // Check if already on stage
    const existing = this.activeCompanions.find(c => c.id === id);
    if (existing) {
      existing.hop();
      existing.speak("Already here with you!");
      this.selectCompanionForInspector(existing);
      return;
    }

    const companion = new CompanionInstance(data, this.stageEl, this);
    this.activeCompanions.push(companion);
    this.updateActiveCountBadge();
    this.selectCompanionForInspector(companion);

    soundFX.playHop();
    companion.speak(`Hi there! I'm ${companion.name}!`);
  }

  removeCompanion(id) {
    const idx = this.activeCompanions.findIndex(c => c.id === id);
    if (idx !== -1) {
      this.activeCompanions[idx].destroy();
      this.activeCompanions.splice(idx, 1);
      this.updateActiveCountBadge();
      if (this.selectedCompanion && this.selectedCompanion.id === id) {
        this.selectedCompanion = this.activeCompanions[0] || null;
        if (this.selectedCompanion) {
          this.selectCompanionForInspector(this.selectedCompanion);
        }
      }
    }
  }

  selectCompanionForInspector(companion) {
    this.selectedCompanion = companion;
    const imgEl = document.getElementById('inspCharImg');
    const nameEl = document.getElementById('inspCharName');
    const tagEl = document.getElementById('inspArchetypeTag');

    if (imgEl) imgEl.src = companion.sprite;
    if (nameEl) nameEl.textContent = companion.name;
    const archInfo = ARCHETYPES_CONFIG[companion.archetype] || ARCHETYPES_CONFIG.curious;
    if (tagEl) tagEl.textContent = `${archInfo.name}`;

    // Highlight archetype chip
    document.querySelectorAll('.archetype-chip').forEach(chip => {
      chip.classList.toggle('active', chip.dataset.archetype === companion.archetype);
    });

    // Update Needs bars
    this.updateNeedsDisplay();
  }

  updateNeedsDisplay() {
    if (!this.selectedCompanion) return;
    const n = this.selectedCompanion.needs;

    const setBar = (idBar, idVal, val) => {
      const bar = document.getElementById(idBar);
      const txt = document.getElementById(idVal);
      if (bar) bar.style.width = `${val}%`;
      if (txt) txt.textContent = `${Math.round(val)}%`;
    };

    setBar('needEnergyBar', 'needEnergyVal', n.energy);
    setBar('needHappyBar', 'needHappyVal', n.happiness);
    setBar('needCuriousBar', 'needCuriousVal', n.curiosity);
    setBar('needBoredBar', 'needBoredVal', n.boredom);
  }

  updateActiveCountBadge() {
    const badge = document.getElementById('popoverActiveCount');
    if (badge) badge.textContent = `${this.activeCompanions.length}`;
  }

  // ---------------------------------------------------------------------------
  // B. UI Initialization
  // ---------------------------------------------------------------------------

  initRosterUI() {
    const grid = document.getElementById('rosterGrid');
    const strip = document.getElementById('spawnButtonStrip');
    if (!grid && !strip) return;

    if (grid) grid.innerHTML = '';
    if (strip) strip.innerHTML = '';

    Object.values(COMPANIONS_DATA).forEach(char => {
      // Grid Card in Window
      if (grid) {
        const card = document.createElement('div');
        card.className = 'companion-roster-card';
        card.innerHTML = `
          <div class="card-sprite-wrap">
            <img src="${char.sprite}" alt="${char.name}" class="roster-thumb" />
          </div>
          <div class="card-info">
            <div class="card-name">${char.name}</div>
            <div class="card-role">${char.title}</div>
          </div>
          <div class="card-actions">
            <button class="btn btn-secondary btn-xs spawn-card-btn">Summon</button>
          </div>
        `;

        card.querySelector('.spawn-card-btn').addEventListener('click', (e) => {
          e.stopPropagation();
          this.spawnCompanion(char.id);
        });

        card.addEventListener('click', () => {
          let instance = this.activeCompanions.find(c => c.id === char.id);
          if (!instance) {
            this.spawnCompanion(char.id);
            instance = this.activeCompanions.find(c => c.id === char.id);
          }
          if (instance) {
            this.selectCompanionForInspector(instance);
            // Switch to inspector tab
            this.switchWindowTab('inspector');
          }
        });

        grid.appendChild(card);
      }

      // Quick spawn button strip in Toolbar
      if (strip) {
        const btn = document.createElement('button');
        btn.className = 'spawn-chip';
        btn.innerHTML = `<img src="${char.sprite}" alt="" class="chip-avatar" /> <span>${char.name}</span>`;
        btn.addEventListener('click', () => this.spawnCompanion(char.id));
        strip.appendChild(btn);
      }
    });
  }

  initArchetypeChips() {
    const container = document.getElementById('archetypeChips');
    if (!container) return;
    container.innerHTML = '';

    Object.entries(ARCHETYPES_CONFIG).forEach(([key, conf]) => {
      const chip = document.createElement('button');
      chip.className = 'archetype-chip';
      chip.dataset.archetype = key;
      chip.textContent = conf.name;
      chip.addEventListener('click', () => {
        if (!this.selectedCompanion) return;
        this.selectedCompanion.archetype = key;
        soundFX.playPop();
        this.selectCompanionForInspector(this.selectedCompanion);
        this.selectedCompanion.speak(conf.remark);
      });
      container.appendChild(chip);
    });
  }

  initPlaygroundControls() {
    // Ambience Segmented Control
    const segControl = document.getElementById('ambienceSegmentedControl');
    if (segControl) {
      segControl.querySelectorAll('.seg-btn').forEach(btn => {
        btn.addEventListener('click', () => {
          segControl.querySelectorAll('.seg-btn').forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          const weather = btn.dataset.weather;
          this.ambientEngine.setWeather(weather);
          this.updateWeatherStatusDisplay(weather);
          soundFX.playPop();
        });
      });
    }

    // Ambience Presets Select
    const presetSelect = document.getElementById('presetSelect');
    if (presetSelect) {
      presetSelect.addEventListener('change', (e) => {
        const val = e.target.value;
        this.applyAtmospherePreset(val);
      });
    }

    // Intensity Slider
    const slider = document.getElementById('intensitySlider');
    const sliderText = document.getElementById('intensityValText');
    if (slider) {
      slider.addEventListener('input', (e) => {
        const val = parseInt(e.target.value, 10);
        if (sliderText) sliderText.textContent = `${val}%`;
        this.ambientEngine.setIntensity(val / 100);
      });
    }

    // Quality Tier Pills
    const qualityPills = document.getElementById('qualityPills');
    if (qualityPills) {
      qualityPills.querySelectorAll('.quality-pill').forEach(btn => {
        btn.addEventListener('click', () => {
          qualityPills.querySelectorAll('.quality-pill').forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          const tier = btn.dataset.quality;
          this.ambientEngine.setQuality(tier);
          soundFX.playPop();
        });
      });
    }

    // Toggle Simulation Pause
    const pauseBtn = document.getElementById('toggleSimulationPause');
    const pauseIcon = document.getElementById('pauseBtnIcon');
    if (pauseBtn) {
      pauseBtn.addEventListener('click', () => {
        this.simulationPaused = !this.simulationPaused;
        if (pauseIcon) pauseIcon.textContent = this.simulationPaused ? '▶' : '⏸';
        pauseBtn.classList.toggle('active', this.simulationPaused);
        soundFX.playPop();
      });
    }

    // Reset Playground Button
    const resetBtn = document.getElementById('resetPlaygroundBtn');
    if (resetBtn) {
      resetBtn.addEventListener('click', () => {
        this.activeCompanions.forEach(c => c.destroy());
        this.activeCompanions = [];
        this.spawnCompanion('umamusume');
        this.spawnCompanion('chiikawa');
        this.minigameScore = 0;
        this.updateScoreDisplay();
        soundFX.playPop();
      });
    }

    // Inspector Action Buttons
    const speakBtn = document.getElementById('inspTriggerSpeechBtn');
    if (speakBtn) {
      speakBtn.addEventListener('click', () => {
        if (this.selectedCompanion) this.selectedCompanion.speak();
      });
    }

    const hopBtn = document.getElementById('inspHopBtn');
    if (hopBtn) {
      hopBtn.addEventListener('click', () => {
        if (this.selectedCompanion) this.selectedCompanion.hop();
      });
    }

    const sleepBtn = document.getElementById('inspSleepToggleBtn');
    if (sleepBtn) {
      sleepBtn.addEventListener('click', () => {
        if (this.selectedCompanion) {
          this.selectedCompanion.toggleSleep();
          soundFX.playPop();
        }
      });
    }

    // Atmosphere Toggles in tab
    const minigameToggle = document.getElementById('minigameEnabledToggle');
    if (minigameToggle) {
      minigameToggle.addEventListener('change', (e) => {
        this.minigameEnabled = e.target.checked;
        if (!this.minigameEnabled) {
          this.collectiblesLayer.innerHTML = '';
        }
      });
    }

    const reducedMotionToggle = document.getElementById('reducedMotionToggle');
    if (reducedMotionToggle) {
      reducedMotionToggle.addEventListener('change', (e) => {
        this.ambientEngine.reducedMotion = e.target.checked;
        this.ambientEngine.initParticles();
      });
    }

    const invertGravityToggle = document.getElementById('invertGravityToggle');
    if (invertGravityToggle) {
      invertGravityToggle.addEventListener('change', (e) => {
        this.setInvertGravity(e.target.checked);
      });
    }

    const inverseWeatherToggle = document.getElementById('inverseWeatherToggle');
    if (inverseWeatherToggle) {
      inverseWeatherToggle.addEventListener('change', (e) => {
        this.ambientEngine.inverted = e.target.checked;
        this.ambientEngine.initParticles();
      });
    }
  }

  applyAtmospherePreset(preset) {
    const segButtons = document.querySelectorAll('#ambienceSegmentedControl .seg-btn');
    const slider = document.getElementById('intensitySlider');
    const sliderText = document.getElementById('intensityValText');

    let weather = 'none';
    let intensity = 70;

    switch (preset) {
      case 'gentle_rain':
        weather = 'rain';
        intensity = 65;
        break;
      case 'autumn_afternoon':
        weather = 'leaves';
        intensity = 70;
        break;
      case 'winter_wonder':
        weather = 'snow';
        intensity = 80;
        break;
      case 'golden_hour':
        weather = 'sunlight';
        intensity = 85;
        break;
      case 'misty_morning':
        weather = 'fog';
        intensity = 60;
        break;
      case 'cozy_cabin':
        weather = 'wind';
        intensity = 50;
        break;
      default:
        return;
    }

    if (slider) {
      slider.value = intensity;
      if (sliderText) sliderText.textContent = `${intensity}%`;
    }

    segButtons.forEach(b => {
      b.classList.toggle('active', b.dataset.weather === weather);
    });

    this.ambientEngine.setIntensity(intensity / 100);
    this.ambientEngine.setWeather(weather);
    this.updateWeatherStatusDisplay(weather);
    soundFX.playPop();
  }

  updateWeatherStatusDisplay(weather) {
    const iconEl = document.getElementById('weatherStatusIcon');
    const textEl = document.getElementById('weatherStatusText');
    const map = {
      none: { icon: '☀️', text: 'Clear Sky' },
      rain: { icon: '🌧️', text: 'Gentle Rain' },
      snow: { icon: '❄️', text: 'Drifting Snow' },
      fog: { icon: '🌫️', text: 'Morning Fog' },
      sunlight: { icon: '✨', text: 'Golden Sunlight' },
      wind: { icon: '🍃', text: 'Brisk Breeze' },
      leaves: { icon: '🍂', text: 'Autumn Leaves' }
    };

    const entry = map[weather] || map.none;
    if (iconEl) iconEl.textContent = entry.icon;
    if (textEl) textEl.textContent = entry.text;
  }

  setInvertGravity(inverted) {
    this.invertGravity = inverted;
    const popoverCheck = document.getElementById('popoverMenuBarWalking');
    const tabCheck = document.getElementById('invertGravityToggle');
    if (popoverCheck) popoverCheck.checked = inverted;
    if (tabCheck) tabCheck.checked = inverted;

    this.activeCompanions.forEach(c => {
      c.vy = inverted ? -8 : 8;
      c.speak(inverted ? "Upside-down menu bar mode!" : "Back down to earth!");
    });
    soundFX.playHop();
  }

  // ---------------------------------------------------------------------------
  // C. Simulated Application Window
  // ---------------------------------------------------------------------------

  initSimulatedWindow() {
    if (!this.windowEl || !this.windowTitlebarEl) return;

    // Window Draggability
    let isDragging = false;
    let startX = 0, startY = 0;
    let initialLeft = 0, initialTop = 0;

    this.windowTitlebarEl.addEventListener('pointerdown', (e) => {
      if (e.target.closest('.traffic-dot') || e.target.closest('.sim-tab')) return;
      isDragging = true;
      startX = e.clientX;
      startY = e.clientY;
      initialLeft = this.windowEl.offsetLeft;
      initialTop = this.windowEl.offsetTop;
      this.windowTitlebarEl.setPointerCapture(e.pointerId);
    });

    this.windowTitlebarEl.addEventListener('pointermove', (e) => {
      if (!isDragging) return;
      const dx = e.clientX - startX;
      const dy = e.clientY - startY;
      const parentRect = this.windowEl.parentElement.getBoundingClientRect();
      const maxLeft = parentRect.width - this.windowEl.offsetWidth - 10;
      const maxTop = parentRect.height - this.windowEl.offsetHeight - 40;

      const newLeft = Math.max(10, Math.min(maxLeft, initialLeft + dx));
      const newTop = Math.max(36, Math.min(maxTop, initialTop + dy));

      this.windowEl.style.left = `${newLeft}px`;
      this.windowEl.style.top = `${newTop}px`;
    });

    const stopDrag = (e) => {
      if (isDragging) {
        isDragging = false;
        try { this.windowTitlebarEl.releasePointerCapture(e.pointerId); } catch(err) {}
      }
    };
    this.windowTitlebarEl.addEventListener('pointerup', stopDrag);
    this.windowTitlebarEl.addEventListener('pointercancel', stopDrag);

    // Traffic Lights
    const closeDot = document.getElementById('simWinClose');
    if (closeDot) {
      closeDot.addEventListener('click', () => {
        this.windowEl.style.display = 'none';
        soundFX.playPop();
      });
    }

    // Tabs
    const tabs = this.windowEl.querySelectorAll('.sim-tab');
    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        this.switchWindowTab(tab.dataset.tab);
        soundFX.playPop();
      });
    });

    // Simulated Dock actions
    document.querySelectorAll('.sim-dock .dock-item').forEach(item => {
      item.addEventListener('click', () => {
        const action = item.dataset.action;
        soundFX.playPop();
        if (action === 'toggle-window') {
          this.windowEl.style.display = (this.windowEl.style.display === 'none') ? 'block' : 'none';
        } else if (action === 'spawn-all') {
          Object.keys(COMPANIONS_DATA).forEach(id => this.spawnCompanion(id));
        } else if (action === 'trigger-weather') {
          const weathers = ['none', 'rain', 'snow', 'fog', 'sunlight', 'wind', 'leaves'];
          const curIdx = weathers.indexOf(this.ambientEngine.weather);
          const nextWeather = weathers[(curIdx + 1) % weathers.length];
          const segBtn = document.querySelector(`#ambienceSegmentedControl .seg-btn[data-weather="${nextWeather}"]`);
          if (segBtn) segBtn.click();
        } else if (action === 'toggle-invert') {
          this.setInvertGravity(!this.invertGravity);
        }
      });
    });
  }

  switchWindowTab(tabKey) {
    if (!this.windowEl) return;
    this.windowEl.querySelectorAll('.sim-tab').forEach(t => {
      t.classList.toggle('active', t.dataset.tab === tabKey);
    });

    const paneMap = {
      library: 'paneLibrary',
      inspector: 'paneInspector',
      ambience: 'paneAmbience',
      focus: 'paneFocus'
    };

    this.windowEl.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
    const targetPane = document.getElementById(paneMap[tabKey]);
    if (targetPane) targetPane.classList.add('active');
  }

  // ---------------------------------------------------------------------------
  // D. Menu Bar & Dashboard Popover
  // ---------------------------------------------------------------------------

  initMenuBar() {
    // Clock
    const clockEl = document.getElementById('menubarClock');
    const updateClock = () => {
      if (clockEl) {
        const now = new Date();
        clockEl.textContent = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      }
    };
    updateClock();
    setInterval(updateClock, 1000);

    // Audio Mute Toggle
    const audioBtn = document.getElementById('audioToggleBtn');
    const audioIcon = document.getElementById('audioIcon');
    const popoverMute = document.getElementById('popoverMuteAudio');

    const toggleAudio = (muted) => {
      soundFX.muted = muted;
      if (audioIcon) audioIcon.textContent = muted ? '🔇' : '🔊';
      if (popoverMute) popoverMute.checked = muted;
    };

    if (audioBtn) {
      audioBtn.addEventListener('click', () => {
        toggleAudio(!soundFX.muted);
        if (!soundFX.muted) soundFX.playPop();
      });
    }

    if (popoverMute) {
      popoverMute.addEventListener('change', (e) => toggleAudio(e.target.checked));
    }

    // Menu Bar Extra Popover
    const petExtra = document.getElementById('menuBarPetExtra');
    const popover = document.getElementById('menuBarDashboardPopover');
    const popoverClose = document.getElementById('popoverCloseBtn');

    if (petExtra && popover) {
      petExtra.addEventListener('click', (e) => {
        e.stopPropagation();
        const isOpen = popover.style.display === 'block';
        popover.style.display = isOpen ? 'none' : 'block';
        soundFX.playPop();
      });

      if (popoverClose) {
        popoverClose.addEventListener('click', () => {
          popover.style.display = 'none';
        });
      }

      document.addEventListener('click', (e) => {
        if (!popover.contains(e.target) && e.target !== petExtra) {
          popover.style.display = 'none';
        }
      });
    }

    // Privacy Shield Button
    const privacyBtn = document.getElementById('privacyShieldBtn');
    if (privacyBtn) {
      privacyBtn.addEventListener('click', () => {
        this.simulationPaused = true;
        const pauseBtn = document.getElementById('toggleSimulationPause');
        const pauseIcon = document.getElementById('pauseBtnIcon');
        if (pauseBtn) pauseBtn.classList.add('active');
        if (pauseIcon) pauseIcon.textContent = '▶';

        // Clear bubbles and collectibles instantly
        document.querySelectorAll('.companion-speech-bubble').forEach(b => b.remove());
        this.collectiblesLayer.innerHTML = '';

        soundFX.playPop();
        alert("🛡️ Emergency Privacy Shield Activated:\nSimulation frozen. Screen observers and background animations halted.");
      });
    }

    // Popover Toggles
    const popoverPause = document.getElementById('popoverPausePhysics');
    if (popoverPause) {
      popoverPause.addEventListener('change', (e) => {
        this.simulationPaused = e.target.checked;
        const pauseBtn = document.getElementById('toggleSimulationPause');
        const pauseIcon = document.getElementById('pauseBtnIcon');
        if (pauseBtn) pauseBtn.classList.toggle('active', this.simulationPaused);
        if (pauseIcon) pauseIcon.textContent = this.simulationPaused ? '▶' : '⏸';
      });
    }

    const popoverWalk = document.getElementById('popoverMenuBarWalking');
    if (popoverWalk) {
      popoverWalk.addEventListener('change', (e) => {
        this.setInvertGravity(e.target.checked);
      });
    }

    // Menu Bar items (File, Companions, Ambience, Window, Help)
    const menuActions = {
      menuItemCompanions: () => {
        this.windowEl.style.display = 'block';
        this.switchWindowTab('library');
      },
      menuItemAmbience: () => {
        this.windowEl.style.display = 'block';
        this.switchWindowTab('ambience');
      },
      menuItemWindow: () => {
        this.windowEl.style.display = (this.windowEl.style.display === 'none') ? 'block' : 'none';
      },
      menuItemHelp: () => {
        const faqSection = document.getElementById('faq');
        if (faqSection) faqSection.scrollIntoView({ behavior: 'smooth' });
      }
    };

    Object.entries(menuActions).forEach(([id, handler]) => {
      const el = document.getElementById(id);
      if (el) {
        el.addEventListener('click', () => {
          soundFX.playPop();
          handler();
        });
      }
    });
  }

  // ---------------------------------------------------------------------------
  // E. Collectibles Minigame (Phase 17 Feature)
  // ---------------------------------------------------------------------------

  initCollectiblesMinigame() {
    if (!this.collectiblesLayer) return;

    const collectibleIcons = {
      none: '🌟',
      rain: '💧',
      snow: '❄️',
      fog: '🌫️',
      sunlight: '✨',
      wind: '🍃',
      leaves: '🍂'
    };

    setInterval(() => {
      if (!this.minigameEnabled || this.simulationPaused) return;
      if (this.collectiblesLayer.children.length >= 5) return;

      const item = document.createElement('div');
      item.className = 'ambient-collectible-item';

      const weather = this.ambientEngine.weather;
      item.textContent = collectibleIcons[weather] || '🌟';

      const stageRect = this.stageEl.getBoundingClientRect();
      const posX = 30 + Math.random() * (stageRect.width - 80);
      const posY = 50 + Math.random() * (stageRect.height - 140);

      item.style.left = `${posX}px`;
      item.style.top = `${posY}px`;

      item.addEventListener('click', (e) => {
        e.stopPropagation();
        soundFX.playCollect();

        // Increment score
        this.minigameScore += 10;
        this.updateScoreDisplay();

        // Spawn burst text
        const burst = document.createElement('div');
        burst.className = 'collectible-burst-score';
        burst.textContent = '+10';
        burst.style.left = `${posX}px`;
        burst.style.top = `${posY}px`;
        this.collectiblesLayer.appendChild(burst);
        setTimeout(() => burst.remove(), 800);

        // Nearest companion celebration hop and speech
        this.celebrateCollectible(posX, posY);

        item.remove();
      });

      this.collectiblesLayer.appendChild(item);

      // Auto-remove after 15s if unclaimed
      setTimeout(() => {
        if (item.parentElement) item.remove();
      }, 15000);
    }, 7000);
  }

  celebrateCollectible(x, y) {
    if (this.activeCompanions.length === 0) return;
    // Find closest companion
    let closest = this.activeCompanions[0];
    let minDist = Infinity;
    this.activeCompanions.forEach(c => {
      const dist = Math.hypot(c.x - x, c.y - y);
      if (dist < minDist) {
        minDist = dist;
        closest = c;
      }
    });

    if (closest) {
      closest.hop();
      const praises = ["Nice catch! ✨", "+10 points!", "Ooh, shiny!", "Great reflexes!", "Score! 🌟"];
      closest.speak(praises[Math.floor(Math.random() * praises.length)]);
    }
  }

  updateScoreDisplay() {
    const scoreEl = document.getElementById('minigameScoreDisplay');
    if (scoreEl) {
      scoreEl.textContent = `${this.minigameScore}`;
      scoreEl.style.transform = 'scale(1.35)';
      scoreEl.style.transition = 'transform 0.15s ease-out';
      setTimeout(() => { scoreEl.style.transform = 'scale(1)'; }, 160);
    }
  }

  // ---------------------------------------------------------------------------
  // F. Focus Timer (Phase 10 Feature)
  // ---------------------------------------------------------------------------

  initFocusTimer() {
    const digitsEl = document.getElementById('timerDigitsDisplay');
    const subTitleEl = document.getElementById('timerPhaseSubtitle');
    const startBtn = document.getElementById('timerStartPauseBtn');
    const resetBtn = document.getElementById('timerResetBtn');
    const breakBtn = document.getElementById('timerBreakBtn');
    const menubarPill = document.getElementById('focusTimerText');

    const updateDisplay = () => {
      const mins = Math.floor(this.timerSeconds / 60);
      const secs = this.timerSeconds % 60;
      const str = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
      if (digitsEl) digitsEl.textContent = str;
      if (menubarPill) menubarPill.textContent = this.timerRunning ? `Focus: ${str}` : 'Focus: Idle';
    };

    if (startBtn) {
      startBtn.addEventListener('click', () => {
        soundFX.playPop();
        if (this.timerRunning) {
          // Pause
          clearInterval(this.timerInterval);
          this.timerRunning = false;
          startBtn.textContent = '▶ Start Focus';
          if (subTitleEl) subTitleEl.textContent = 'Focus Session Paused';
        } else {
          // Start
          this.timerRunning = true;
          startBtn.textContent = '⏸ Pause Focus';
          if (subTitleEl) subTitleEl.textContent = this.timerMode === 'focus' ? 'Active Focus (Companions Tranquil)' : 'Relaxing Break Time';
          
          // Put companions to calm/sleepy state during active focus
          if (this.timerMode === 'focus') {
            this.activeCompanions.forEach(c => {
              if (Math.random() > 0.3) c.toggleSleep();
            });
          }

          this.timerInterval = setInterval(() => {
            if (this.timerSeconds > 0) {
              this.timerSeconds--;
              updateDisplay();
            } else {
              // Timer Finished!
              clearInterval(this.timerInterval);
              this.timerRunning = false;
              soundFX.playChime();
              startBtn.textContent = '▶ Start Focus';

              if (this.timerMode === 'focus') {
                alert("🎉 Focus session completed! Time for a well-earned break.");
                this.activeCompanions.forEach(c => {
                  c.hop();
                  c.speak("Great work! Time for tea! 🍵");
                });
              }
            }
          }, 1000);
        }
        updateDisplay();
      });
    }

    if (resetBtn) {
      resetBtn.addEventListener('click', () => {
        soundFX.playPop();
        clearInterval(this.timerInterval);
        this.timerRunning = false;
        this.timerSeconds = 25 * 60;
        this.timerMode = 'focus';
        if (startBtn) startBtn.textContent = '▶ Start Focus';
        if (subTitleEl) subTitleEl.textContent = 'Classic Pomodoro (25m Focus)';
        updateDisplay();
      });
    }

    if (breakBtn) {
      breakBtn.addEventListener('click', () => {
        soundFX.playPop();
        clearInterval(this.timerInterval);
        this.timerRunning = false;
        this.timerSeconds = 5 * 60;
        this.timerMode = 'break';
        if (startBtn) startBtn.textContent = '▶ Start Break';
        if (subTitleEl) subTitleEl.textContent = 'Quick 5m Tea Break';
        updateDisplay();
      });
    }

    updateDisplay();
  }

  // ---------------------------------------------------------------------------
  // G. Showcase & FAQ Interactions
  // ---------------------------------------------------------------------------

  initGalleryTabs() {
    const tabs = document.querySelectorAll('.viewer-tab');
    const mainImg = document.getElementById('galleryMainImg');
    const captionEl = document.getElementById('galleryCaption');

    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        tabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        const newSrc = tab.dataset.img;
        const newCaption = tab.dataset.caption;

        if (mainImg) {
          mainImg.style.opacity = '0.3';
          mainImg.style.transform = 'scale(0.98)';
          setTimeout(() => {
            mainImg.src = newSrc;
            mainImg.style.opacity = '1';
            mainImg.style.transform = 'scale(1)';
          }, 120);
        }

        if (captionEl) captionEl.textContent = newCaption;
        soundFX.playPop();
      });
    });
  }

  initFAQAccordion() {
    const questions = document.querySelectorAll('.faq-question');
    questions.forEach(btn => {
      btn.addEventListener('click', () => {
        const item = btn.parentElement;
        const isOpen = item.classList.contains('active');
        document.querySelectorAll('.faq-item').forEach(i => i.classList.remove('active'));
        if (!isOpen) item.classList.add('active');
        soundFX.playPop();
      });
    });
  }

  // ---------------------------------------------------------------------------
  // H. Main Loop & Social Interactions (Phase 9)
  // ---------------------------------------------------------------------------

  startMainLoop() {
    const loop = () => {
      this.tick();
      requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
  }

  tick() {
    const stageWidth = this.stageEl.offsetWidth;
    const stageHeight = this.stageEl.offsetHeight;

    // Calculate simulated window obstacle bounds
    let obstacle = null;
    if (this.windowEl && this.windowEl.style.display !== 'none') {
      const winRect = this.windowEl.getBoundingClientRect();
      const stageRect = this.stageEl.getBoundingClientRect();
      obstacle = {
        visible: true,
        top: winRect.top - stageRect.top,
        left: winRect.left - stageRect.left,
        right: winRect.right - stageRect.left
      };
    }

    // Update Companions Physics
    const count = this.activeCompanions.length;
    for (let i = 0; i < count; i++) {
      this.activeCompanions[i].updatePhysics(stageWidth, stageHeight, obstacle, this.invertGravity);
    }

    // Check Social Proximity Interactions (Phase 9)
    if (this.socialCooldown > 0) {
      this.socialCooldown--;
    } else if (count >= 2 && !this.simulationPaused) {
      this.checkSocialEncounters();
    }
  }

  checkSocialEncounters() {
    const count = this.activeCompanions.length;
    for (let i = 0; i < count; i++) {
      for (let j = i + 1; j < count; j++) {
        const a = this.activeCompanions[i];
        const b = this.activeCompanions[j];

        const dist = Math.hypot(a.x - b.x, a.y - b.y);
        if (dist < 110) {
          this.triggerSocialEncounter(a, b);
          this.socialCooldown = 450; // ~7.5 seconds cooldown
          return;
        }
      }
    }
  }

  triggerSocialEncounter(a, b) {
    // Look up tailored pair dialogue
    const found = SOCIAL_PAIRS.find(p => 
      (p.pair[0] === a.id && p.pair[1] === b.id) ||
      (p.pair[0] === b.id && p.pair[1] === a.id)
    );

    if (found) {
      const isDirect = (found.pair[0] === a.id);
      a.speak(isDirect ? found.textA : found.textB);
      setTimeout(() => {
        b.speak(isDirect ? found.textB : found.textA);
      }, 700);
    } else {
      // Generic friendly greeting
      a.speak(`Hey ${b.name}! Beautiful desktop today!`);
      setTimeout(() => {
        b.speak(`Hi ${a.name}! Let's explore together! ✨`);
      }, 700);
    }

    // Small synchronous hop
    a.hop();
    setTimeout(() => b.hop(), 250);
  }
}

// =============================================================================
// 6. BOOTSTRAP ON DOM READY
// =============================================================================

window.addEventListener('DOMContentLoaded', () => {
  window.animattoApp = new AnimattoApp();
});
