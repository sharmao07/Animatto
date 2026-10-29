/**
 * Animatto Web — Master Application & Desktop Playground Controller
 * Reproduces the native macOS Swift/AppKit application interface,
 * Phase 6 Personality Matrix, Phase 9 Social Interactions,
 * and Phase 17 Ambient Worlds.
 */

// =============================================================================
// 1. DATA DEFINITIONS & AUTHENTIC COMPANION REGISTRY
// =============================================================================

const COMPANIONS = {
  umamusume: {
    id: 'umamusume',
    name: 'Umamusume',
    role: 'Special Week',
    sprite: 'sprites/umamusume.png',
    archetype: 'curious',
    width: 84,
    height: 84,
    needs: { energy: 90, happiness: 94, curiosity: 88, boredom: 12 },
    speechPool: [
      "Pacing my breath... gotta win the Twinkle Series! 🥕",
      "Did you know horses sprint up to 40 mph? Let's race!",
      "Carrot treats are the ultimate coding fuel!",
      "The grass on this desktop looks so lush!",
      "Stay hydrated while you push that commit!",
      "Running laps across your window titlebars is my favorite workout!"
    ]
  },
  miku: {
    id: 'miku',
    name: 'Hatsune Miku',
    role: 'Virtual Singer',
    sprite: 'sprites/miku.png',
    archetype: 'playful',
    width: 80,
    height: 82,
    needs: { energy: 85, happiness: 98, curiosity: 80, boredom: 8 },
    speechPool: [
      "Miku Miku ni shite ageru♪",
      "Composing a 16-bit synth melody in my head~ 🎤",
      "Singing keeps my CPU nice and warm!",
      "39! Thank you for having me on your Mac desktop!",
      "Your mouse cursor dances right to the rhythm!",
      "Leek energy is 100% renewable and zero emissions!"
    ]
  },
  chiikawa: {
    id: 'chiikawa',
    name: 'Chiikawa',
    role: 'Small & Gentle',
    sprite: 'sprites/chiikawa.png',
    archetype: 'gentle',
    width: 76,
    height: 78,
    needs: { energy: 65, happiness: 82, curiosity: 60, boredom: 20 },
    speechPool: [
      "Wa... wawa! (Looking around curiously)",
      "Yaha! Doing my very best weeding work today!",
      "Found a sweet little pudding treat! 🍮",
      "Please don't shake the mouse too fast... (trembles happily)",
      "Fuu... taking a peaceful nap on this window ledge."
    ]
  },
  sayori: {
    id: 'sayori',
    name: 'Sayori',
    role: 'Sunshine Friend',
    sprite: 'sprites/sayori.png',
    archetype: 'friendly',
    width: 78,
    height: 82,
    needs: { energy: 78, happiness: 90, curiosity: 82, boredom: 14 },
    speechPool: [
      "Don't forget to take a break and stretch! ✨",
      "Warm cookies make everything twenty percent better!",
      "I'm so happy to hang out on your screen today!",
      "The weather on this Mac is so lovely~",
      "Yay! You're doing absolutely fantastic work today!"
    ]
  },
  usagi: {
    id: 'usagi',
    name: 'Usagi',
    role: 'Chaotic Bunny',
    sprite: 'sprites/usagi.png',
    archetype: 'chaotic',
    width: 74,
    height: 82,
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
    role: 'Cozy Pastry',
    sprite: 'sprites/taiyaki.png',
    archetype: 'stoic',
    width: 84,
    height: 78,
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
    role: 'Cosmic Poptart',
    sprite: 'sprites/nyancat.png',
    archetype: 'playful',
    width: 88,
    height: 44,
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
    role: 'Sleepy Chonk',
    sprite: 'sprites/fattie.png',
    archetype: 'sleepy',
    width: 82,
    height: 82,
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

const ARCHETYPES = {
  curious: { name: 'Curious Explorer', hopChance: 0.20, sleepChance: 0.04, speedMul: 1.15, quote: "Ooh! What does this window do?" },
  playful: { name: 'Playful Companion', hopChance: 0.35, sleepChance: 0.05, speedMul: 1.30, quote: "Let's play a game together!" },
  gentle: { name: 'Gentle Guardian', hopChance: 0.08, sleepChance: 0.15, speedMul: 0.75, quote: "I'll watch over your desktop quietly." },
  friendly: { name: 'Friendly Sidekick', hopChance: 0.20, sleepChance: 0.10, speedMul: 1.00, quote: "You're doing awesome work today!" },
  chaotic: { name: 'Chaotic Jester', hopChance: 0.50, sleepChance: 0.02, speedMul: 1.70, quote: "YAH-HA!! ZOOMIES TIME!" },
  sleepy: { name: 'Sleepy Loaf', hopChance: 0.02, sleepChance: 0.45, speedMul: 0.50, quote: "Just five more minutes of napping..." },
  stoic: { name: 'Stoic Thinker', hopChance: 0.05, sleepChance: 0.18, speedMul: 0.65, quote: "Patience and steady focus." },
  philosophical: { name: 'Philosopher', hopChance: 0.06, sleepChance: 0.16, speedMul: 0.70, quote: "Does a pixel companion truly exist?" },
  mischievous: { name: 'Mischievous Sprite', hopChance: 0.30, sleepChance: 0.06, speedMul: 1.35, quote: "Hehehe, I touched the traffic lights!" },
  scholarly: { name: 'Scholarly Reader', hopChance: 0.10, sleepChance: 0.12, speedMul: 0.85, quote: "Fascinating terminal commands today." }
};

const SOCIAL_DIALOGUES = [
  { pair: ['chiikawa', 'usagi'], a: "Wawa... Usagi-chan?! (quivers)", b: "URAAAAHH! YAH-HA!! ⚡️" },
  { pair: ['miku', 'nyancat'], a: "Nyan-chan! Duet with my synthesizer! 🎤", b: "Nyan nyan nyan! ♪🌈" },
  { pair: ['umamusume', 'fattie'], a: "Come on Fattie! 3 sprint laps around the window!", b: "No thanks... this warm title bar is my home. 💤" },
  { pair: ['sayori', 'chiikawa'], a: "Here's a fresh cookie just for you! 🍪", b: "Wa... arigato! (sniffs cookie happily)" },
  { pair: ['miku', 'sayori'], a: "Let's sing an upbeat song together!", b: "Yay! Music makes coding so joyful! ✨" }
];

// =============================================================================
// 2. AUDIO SYNTHESIZER (Apple Web Audio API — No Missing External Files)
// =============================================================================

class SoundFX {
  constructor() {
    this.ctx = null;
    this.enabled = true;
    this.setupGestureUnlock();
  }

  setupGestureUnlock() {
    const unlock = () => {
      if (this.ctx && this.ctx.state === 'suspended') {
        this.ctx.resume().catch(() => {});
      }
      window.removeEventListener('pointerdown', unlock);
      window.removeEventListener('keydown', unlock);
    };
    if (typeof window !== 'undefined') {
      window.addEventListener('pointerdown', unlock, { passive: true });
      window.addEventListener('keydown', unlock, { passive: true });
    }
  }

  init() {
    if (!this.ctx && typeof window !== 'undefined' && (window.AudioContext || window.webkitAudioContext)) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioCtx();
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume().catch(() => {});
    }
    return this.ctx;
  }

  playPop() {
    if (!this.enabled) return;
    const ctx = this.init();
    if (!ctx) return;
    try {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      const now = ctx.currentTime;
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(540, now);
      osc.frequency.exponentialRampToValueAtTime(140, now + 0.07);
      gain.gain.setValueAtTime(0.16, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.07);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.07);
    } catch (e) {}
  }

  playHop() {
    if (!this.enabled) return;
    const ctx = this.init();
    if (!ctx) return;
    try {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      const now = ctx.currentTime;
      osc.type = 'sine';
      osc.frequency.setValueAtTime(360, now);
      osc.frequency.exponentialRampToValueAtTime(740, now + 0.11);
      gain.gain.setValueAtTime(0.14, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.11);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.11);
    } catch (e) {}
  }

  playCollect() {
    if (!this.enabled) return;
    const ctx = this.init();
    if (!ctx) return;
    try {
      const notes = [523.25, 659.25, 783.99, 1046.50];
      const now = ctx.currentTime;
      notes.forEach((freq, idx) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        const start = now + (idx * 0.04);
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, start);
        gain.gain.setValueAtTime(0.12, start);
        gain.gain.exponentialRampToValueAtTime(0.001, start + 0.16);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(start);
        osc.stop(start + 0.16);
      });
    } catch (e) {}
  }
}

const soundFX = new SoundFX();

// =============================================================================
// 3. PHASE 17 AMBIENT WORLDS CANVAS PARTICLE ENGINE
// =============================================================================

class AmbientEngine {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.weather = 'none'; // 'none', 'rain', 'snow', 'fog', 'sunlight', 'wind', 'leaves'
    this.intensity = 0.70;
    this.qualityTier = 'medium'; // 'low', 'medium', 'high'
    this.reducedMotion = false;
    this.inverted = false;
    this.particles = [];
    this.width = 0;
    this.height = 0;
    this.animId = null;

    this.qualityLimits = {
      low: 40,
      medium: 100,
      high: 240
    };

    this.resize();
    window.addEventListener('resize', () => this.resize());
    this.startLoop();
  }

  resize() {
    const parent = this.canvas.parentElement;
    if (!parent) return;
    this.width = parent.offsetWidth;
    this.height = parent.offsetHeight;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    this.canvas.width = this.width * dpr;
    this.canvas.height = this.height * dpr;
    this.ctx.scale(dpr, dpr);
    this.initParticles();
  }

  setWeather(w) {
    this.weather = w;
    this.initParticles();
  }

  setIntensity(val) {
    this.intensity = Math.max(0.1, Math.min(1.0, val));
    this.initParticles();
  }

  setQuality(tier) {
    if (this.qualityLimits[tier]) {
      this.qualityTier = tier;
      this.initParticles();
    }
  }

  getTargetCount() {
    if (this.weather === 'none') return 0;
    const base = this.qualityLimits[this.qualityTier] || 100;
    let count = Math.round(base * this.intensity);
    if (this.weather === 'fog') count = Math.max(6, Math.round(count * 0.15));
    if (this.weather === 'sunlight') count = Math.max(14, Math.round(count * 0.35));
    if (this.weather === 'leaves') count = Math.max(10, Math.round(count * 0.38));
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
    const yPos = randomY ? Math.random() * this.height : (this.inverted ? this.height + 15 : -15);
    const speedScale = this.reducedMotion ? 0.3 : 1.0;
    const dir = this.inverted ? -1 : 1;

    switch (this.weather) {
      case 'rain':
        return {
          x: Math.random() * (this.width + 80) - 40,
          y: yPos,
          length: (14 + Math.random() * 16) * this.intensity,
          speedY: (11 + Math.random() * 7) * this.intensity * speedScale * dir,
          speedX: (-1.5 - Math.random() * 1.5) * speedScale,
          alpha: 0.25 + Math.random() * 0.45,
          thickness: 1 + Math.random() * 1.2,
          color: 'rgba(160, 210, 255,'
        };

      case 'snow':
        return {
          x: Math.random() * this.width,
          y: yPos,
          radius: 1.5 + Math.random() * 3.5,
          speedY: (1.1 + Math.random() * 1.9) * this.intensity * speedScale * dir,
          speedX: (Math.random() - 0.5) * 1.2 * speedScale,
          swayAngle: Math.random() * Math.PI * 2,
          swaySpeed: 0.02 + Math.random() * 0.03,
          alpha: 0.4 + Math.random() * 0.5,
          color: 'rgba(255, 255, 255,'
        };

      case 'fog':
        return {
          x: Math.random() * this.width,
          y: Math.random() * this.height,
          radius: 90 + Math.random() * 130,
          speedX: (0.25 + Math.random() * 0.4) * speedScale * (Math.random() > 0.5 ? 1 : -1),
          speedY: (Math.random() - 0.5) * 0.15 * speedScale,
          alpha: (0.04 + Math.random() * 0.05) * this.intensity,
          color: 'rgba(210, 218, 238,'
        };

      case 'sunlight':
        return {
          x: Math.random() * this.width,
          y: Math.random() * this.height,
          radius: 2 + Math.random() * 4.5,
          speedY: (-0.3 - Math.random() * 0.5) * speedScale * dir,
          speedX: (Math.random() - 0.5) * 0.4 * speedScale,
          alpha: 0.2 + Math.random() * 0.5,
          pulse: Math.random() * Math.PI,
          pulseSpeed: 0.03 + Math.random() * 0.04,
          color: 'rgba(255, 226, 130,'
        };

      case 'wind':
        return {
          x: Math.random() * this.width,
          y: Math.random() * this.height,
          length: 28 + Math.random() * 50,
          speedX: (7 + Math.random() * 9) * this.intensity * speedScale,
          speedY: (Math.random() - 0.5) * 1.2 * speedScale,
          alpha: 0.15 + Math.random() * 0.25,
          thickness: 1.2,
          color: 'rgba(180, 220, 255,'
        };

      case 'leaves':
        const foliage = ['#e06c4b', '#e6a13b', '#c24b38', '#d49b43'];
        return {
          x: Math.random() * (this.width + 80) - 40,
          y: yPos,
          size: 7 + Math.random() * 7,
          speedY: (1.5 + Math.random() * 2.2) * this.intensity * speedScale * dir,
          speedX: (1.2 + Math.random() * 1.8) * speedScale,
          rot: Math.random() * Math.PI * 2,
          rotSpeed: (Math.random() - 0.5) * 0.08 * speedScale,
          color: foliage[Math.floor(Math.random() * foliage.length)],
          alpha: 0.75 + Math.random() * 0.25
        };

      default:
        return null;
    }
  }

  startLoop() {
    const loop = () => {
      this.render();
      this.animId = requestAnimationFrame(loop);
    };
    this.animId = requestAnimationFrame(loop);
  }

  render() {
    this.ctx.clearRect(0, 0, this.width, this.height);
    if (this.weather === 'none' || this.particles.length === 0) return;

    if (this.weather === 'sunlight') {
      const grad = this.ctx.createLinearGradient(0, 0, this.width, this.height);
      grad.addColorStop(0, `rgba(255, 235, 160, ${0.10 * this.intensity})`);
      grad.addColorStop(0.5, `rgba(255, 210, 120, ${0.04 * this.intensity})`);
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
        p.x += p.speedX + Math.sin(p.swayAngle) * 0.7;
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

        if ((!this.inverted && p.y > this.height) || (this.inverted && p.y < 0) || p.x > this.width + 40) {
          this.particles[i] = this.createParticle(false);
        }
      }
    }
  }
}

// =============================================================================
// 4. COMPANION AGENT INSTANCE (Physics, Momentum, Needs & States)
// =============================================================================

class CompanionAgent {
  constructor(data, stageEl, app) {
    this.data = data;
    this.stageEl = stageEl;
    this.app = app;
    this.id = data.id;
    this.name = data.name;
    this.sprite = data.sprite;
    this.archetype = data.archetype;
    this.needs = { ...data.needs };

    this.width = data.width || 80;
    this.height = data.height || 80;

    this.x = 40 + Math.random() * Math.max(100, this.stageEl.offsetWidth - 200);
    this.y = 80;
    this.vx = (Math.random() - 0.5) * 2;
    this.vy = 0;
    this.facing = Math.random() > 0.5 ? 1 : -1;

    // States: 'idle', 'walking', 'hopping', 'sleeping', 'dragging'
    this.state = 'idle';
    this.stateTimer = 50 + Math.random() * 90;
    this.speechTimeout = null;

    // Dragging & Velocity Tracking
    this.isDragging = false;
    this.dragOffsetX = 0;
    this.dragOffsetY = 0;
    this.lastPointerX = 0;
    this.lastPointerY = 0;
    this.recentDeltas = [];

    this.element = this.createDOM();
    this.stageEl.appendChild(this.element);
    this.updatePosition();
  }

  createDOM() {
    const el = document.createElement('div');
    el.className = 'companion-agent';
    el.dataset.id = this.id;
    el.style.width = `${this.width}px`;
    el.style.height = `${this.height}px`;

    const img = document.createElement('img');
    img.src = this.sprite;
    img.alt = this.name;
    img.className = 'companion-agent-sprite';
    img.draggable = false;
    el.appendChild(img);

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

      let avgDx = 0, avgDy = 0;
      if (this.recentDeltas.length > 0) {
        this.recentDeltas.forEach(d => { avgDx += d.dx; avgDy += d.dy; });
        avgDx /= this.recentDeltas.length;
        avgDy /= this.recentDeltas.length;
      }

      const dist = Math.hypot(ev.clientX - this.lastPointerX, ev.clientY - this.lastPointerY);
      if (Math.abs(avgDx) < 1.5 && Math.abs(avgDy) < 1.5 && dist < 6) {
        this.hop();
        this.speak();
      } else {
        // Momentum fling
        this.vx = Math.max(-14, Math.min(14, avgDx * 1.2));
        this.vy = Math.max(-14, Math.min(14, avgDy * 1.2));
      }

      this.state = 'idle';
      this.stateTimer = 40;
    };

    window.addEventListener('pointermove', onPointerMove);
    window.addEventListener('pointerup', onPointerUp);

    this.app.selectCompanion(this);
  }

  updatePhysics(stageWidth, stageHeight, obstacleRect, invertGravity, gravityStrength, walkSpeedParam) {
    if (this.isDragging || this.app.isPaused) return;

    const arch = ARCHETYPES[this.archetype] || ARCHETYPES.curious;
    const speedMul = (arch.speedMul || 1.0) * (walkSpeedParam / 2.0);

    // Gravity scaled with native gravityStrength
    const gravity = (invertGravity ? -0.65 : 0.65) * (gravityStrength / 0.8);
    this.vy += gravity;

    // Terminal velocity clamp to avoid tunneling through obstacle windows
    this.vy = Math.max(-18, Math.min(18, this.vy));
    this.vx *= 0.94;

    this.x += this.vx;
    this.y += this.vy;

    const floorY = stageHeight - this.height - 18;
    const ceilingY = 0;

    // Window obstacle collision (standing and walking on top edge)
    if (obstacleRect && obstacleRect.visible && !invertGravity && this.vy >= 0) {
      const footY = this.y + this.height;
      if (footY >= obstacleRect.top && footY <= obstacleRect.top + 24) {
        if (this.x + this.width * 0.7 >= obstacleRect.left && this.x + this.width * 0.3 <= obstacleRect.right) {
          this.y = obstacleRect.top - this.height;
          this.vy = 0;
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
      if (this.y <= ceilingY) {
        this.y = ceilingY;
        this.vy = 0;
      }
      if (this.y > floorY) {
        this.y = floorY;
        this.vy = 0;
      }
    }

    if (this.x < 0) {
      this.x = 0;
      this.vx = Math.abs(this.vx) * 0.7;
      this.facing = 1;
    } else if (this.x > stageWidth - this.width) {
      this.x = stageWidth - this.width;
      this.vx = -Math.abs(this.vx) * 0.7;
      this.facing = -1;
    }

    // State Machine
    this.stateTimer--;
    if (this.stateTimer <= 0) {
      const roll = Math.random();
      if (roll < arch.sleepChance) {
        this.state = 'sleeping';
        this.stateTimer = 140 + Math.random() * 180;
        this.element.className = 'companion-agent sleeping';
      } else if (roll < arch.sleepChance + arch.hopChance) {
        this.hop();
        this.stateTimer = 35 + Math.random() * 45;
      } else if (roll < 0.70) {
        this.state = 'walking';
        this.facing = Math.random() > 0.5 ? 1 : -1;
        this.stateTimer = 70 + Math.random() * 110;
        this.element.className = 'companion-agent walking';
      } else {
        this.state = 'idle';
        this.stateTimer = 50 + Math.random() * 80;
        this.element.className = 'companion-agent';
      }
    }

    if (this.state === 'walking') {
      this.x += 1.35 * speedMul * this.facing;
      if (Math.random() < 0.02) this.facing *= -1;
    }

    this.updatePosition(invertGravity);
  }

  hop() {
    soundFX.playHop();
    this.state = 'hopping';
    this.element.className = 'companion-agent hopping';
    this.vy = this.app.invertGravity ? 8.5 : -8.5;
    setTimeout(() => {
      if (this.state === 'hopping') {
        this.state = 'idle';
        this.element.className = 'companion-agent';
      }
    }, 400);
  }

  speak(customText = null) {
    if (!this.app.dialogueEnabled) return;
    const text = customText || this.data.speechPool[Math.floor(Math.random() * this.data.speechPool.length)];
    if (!text) return;

    soundFX.playPop();

    const existing = this.element.querySelector('.agent-speech-bubble');
    if (existing) existing.remove();
    if (this.speechTimeout) clearTimeout(this.speechTimeout);

    const bubble = document.createElement('div');
    bubble.className = 'agent-speech-bubble';
    bubble.textContent = text;
    this.element.appendChild(bubble);

    this.speechTimeout = setTimeout(() => {
      bubble.style.transition = 'opacity 0.25s ease, transform 0.25s ease';
      bubble.style.opacity = '0';
      bubble.style.transform = 'translateX(-50%) translateY(-8px)';
      setTimeout(() => bubble.remove(), 260);
    }, 4200);
  }

  toggleSleep() {
    if (this.state === 'sleeping') {
      this.state = 'idle';
      this.element.className = 'companion-agent';
    } else {
      this.state = 'sleeping';
      this.element.className = 'companion-agent sleeping';
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
// 5. MASTER PLAYGROUND & APPLICATION CONTROLLER
// =============================================================================

class AnimattoApp {
  constructor() {
    this.stageEl = document.getElementById('companionStage');
    this.canvasEl = document.getElementById('ambientCanvas');
    this.collectiblesLayer = document.getElementById('collectiblesLayer');
    this.windowEl = document.getElementById('simAppWindow');
    this.windowHeaderEl = document.getElementById('simWindowHeader');
    this.popoverEl = document.getElementById('menuBarDashboardPopover');

    this.activeAgents = [];
    this.selectedAgent = null;
    this.isPaused = false;
    this.invertGravity = false;
    this.dialogueEnabled = true;
    this.score = 0;
    this.collectiblesEnabled = true;
    this.socialCooldown = 0;

    // Native Settings parameters
    this.gravityStrength = 0.8;
    this.walkSpeed = 2.0;
    this.eventFrequency = 0.5;
    this.appAccentHex = '#007aff';

    // Ambient Engine Instance
    this.ambientEngine = new AmbientEngine(this.canvasEl);

    // Initialize sub-components
    this.initHeroSpotlight();
    this.initNativeWindowTabs();
    this.initNativeLibraryGrid();
    this.initArchetypePills();
    this.initNativeWorkshop();
    this.initNativeSettings();
    this.initMenuBarExtraPopover();
    this.initPlaygroundControls();
    this.initCollectiblesMinigame();
    this.initFAQAccordion();
    this.initClock();

    // Spawn 2 initial companions (Umamusume & Chiikawa)
    this.spawnCompanion('umamusume');
    this.spawnCompanion('chiikawa');

    // Run Physics Loop
    this.startMainLoop();
  }

  // ---------------------------------------------------------------------------
  // Companion Management
  // ---------------------------------------------------------------------------

  spawnCompanion(id) {
    const data = COMPANIONS[id];
    if (!data) return;

    const existing = this.activeAgents.find(a => a.id === id);
    if (existing) {
      existing.hop();
      existing.speak("Already on screen with you!");
      this.selectCompanion(existing);
      return;
    }

    const agent = new CompanionAgent(data, this.stageEl, this);
    this.activeAgents.push(agent);
    this.updateCountBadge();
    this.selectCompanion(agent);

    soundFX.playHop();
    agent.speak(`Hi there! I'm ${agent.name}!`);
  }

  dismissCompanion(id) {
    const idx = this.activeAgents.findIndex(a => a.id === id);
    if (idx !== -1) {
      this.activeAgents[idx].destroy();
      this.activeAgents.splice(idx, 1);
      this.updateCountBadge();
      if (this.selectedAgent && this.selectedAgent.id === id) {
        this.selectedAgent = this.activeAgents[0] || null;
        if (this.selectedAgent) this.selectCompanion(this.selectedAgent);
      }
    }
  }

  selectCompanion(agent) {
    this.selectedAgent = agent;
    const avatarEl = document.getElementById('inspAvatar');
    const nameEl = document.getElementById('inspName');
    const archEl = document.getElementById('inspArchetype');

    if (avatarEl) avatarEl.src = agent.sprite;
    if (nameEl) nameEl.textContent = agent.name;
    const archData = ARCHETYPES[agent.archetype] || ARCHETYPES.curious;
    if (archEl) archEl.textContent = archData.name;

    // Update active archetype pill
    document.querySelectorAll('.arch-chip').forEach(pill => {
      pill.classList.toggle('active', pill.dataset.archetype === agent.archetype);
    });

    // Update meters
    this.updateNeedsMeters();

    // Highlight roster card
    document.querySelectorAll('.native-pet-card').forEach(card => {
      card.classList.toggle('selected', card.dataset.id === agent.id);
    });
  }

  updateNeedsMeters() {
    if (!this.selectedAgent) return;
    const n = this.selectedAgent.needs;

    const setMeter = (valId, barId, val) => {
      const vEl = document.getElementById(valId);
      const bEl = document.getElementById(barId);
      if (vEl) vEl.textContent = `${Math.round(val)}%`;
      if (bEl) bEl.style.width = `${val}%`;
    };

    setMeter('valEnergy', 'barEnergy', n.energy);
    setMeter('valHappy', 'barHappy', n.happiness);
    setMeter('valCurious', 'barCurious', n.curiosity);
    setMeter('valBored', 'barBored', n.boredom);
  }

  updateCountBadge() {
    const badge = document.getElementById('stageCountBadge');
    if (badge) badge.textContent = `${this.activeAgents.length}`;
    const popCount = document.getElementById('popoverPetCount');
    if (popCount) popCount.textContent = `${this.activeAgents.length}`;
  }

  // ---------------------------------------------------------------------------
  // Native Window Navigation & Tabs (MainAppView.swift)
  // ---------------------------------------------------------------------------

  initNativeWindowTabs() {
    const tabBtns = document.querySelectorAll('.native-tab-btn');
    tabBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        tabBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        this.switchNativeTab(btn.dataset.tab);
        soundFX.playPop();
      });
    });

    // Accent Color Swatches
    const swatches = document.querySelectorAll('.accent-color-swatch');
    swatches.forEach(swatch => {
      swatch.addEventListener('click', () => {
        this.setAppAccent(swatch.dataset.accent);
        soundFX.playPop();
      });
    });

    // Drag Window by Topbar
    let isDragging = false;
    let startX = 0, startY = 0;
    let initLeft = 0, initTop = 0;

    this.windowHeaderEl.addEventListener('pointerdown', (e) => {
      if (e.target.closest('.traffic-dot') || e.target.closest('.native-tab-btn') || e.target.closest('.accent-color-swatch')) return;
      isDragging = true;
      startX = e.clientX;
      startY = e.clientY;
      initLeft = this.windowEl.offsetLeft;
      initTop = this.windowEl.offsetTop;
      this.windowHeaderEl.setPointerCapture(e.pointerId);
    });

    this.windowHeaderEl.addEventListener('pointermove', (e) => {
      if (!isDragging) return;
      const dx = e.clientX - startX;
      const dy = e.clientY - startY;
      const parent = this.windowEl.parentElement;
      const maxL = parent.offsetWidth - this.windowEl.offsetWidth - 10;
      const maxT = parent.offsetHeight - this.windowEl.offsetHeight - 20;

      this.windowEl.style.left = `${Math.max(10, Math.min(maxL, initLeft + dx))}px`;
      this.windowEl.style.top = `${Math.max(30, Math.min(maxT, initTop + dy))}px`;
    });

    const stopDrag = (e) => {
      if (isDragging) {
        isDragging = false;
        try { this.windowHeaderEl.releasePointerCapture(e.pointerId); } catch(err) {}
      }
    };
    this.windowHeaderEl.addEventListener('pointerup', stopDrag);
    this.windowHeaderEl.addEventListener('pointercancel', stopDrag);

    // Close button
    const closeBtn = document.getElementById('simWinCloseBtn');
    if (closeBtn) {
      closeBtn.addEventListener('click', () => {
        this.windowEl.style.display = 'none';
        soundFX.playPop();
      });
    }

    // Menu Bar items: Library, Workshop, Settings
    const navMap = {
      menuItemLibrary: 'library',
      menuItemWorkshop: 'workshop',
      menuItemSettings: 'settings'
    };

    Object.entries(navMap).forEach(([id, tabKey]) => {
      const item = document.getElementById(id);
      if (item) {
        item.addEventListener('click', () => {
          this.windowEl.style.display = 'block';
          this.switchNativeTab(tabKey);
          soundFX.playPop();
        });
      }
    });
  }

  switchNativeTab(tabKey) {
    document.querySelectorAll('.native-tab-btn').forEach(b => {
      b.classList.toggle('active', b.dataset.tab === tabKey);
    });

    const panelMap = {
      library: 'panelLibrary',
      workshop: 'panelWorkshop',
      settings: 'panelSettings'
    };

    document.querySelectorAll('.native-panel').forEach(p => p.classList.remove('active'));
    const target = document.getElementById(panelMap[tabKey]);
    if (target) target.classList.add('active');
  }

  setAppAccent(hex) {
    this.appAccentHex = hex;
    document.documentElement.style.setProperty('--app-accent', hex);
    document.documentElement.style.setProperty('--app-accent-hover', hex);
    document.documentElement.style.setProperty('--app-accent-30', `${hex}4d`);
    document.documentElement.style.setProperty('--app-accent-15', `${hex}26`);
    document.documentElement.style.setProperty('--app-accent-10', `${hex}1a`);

    const selectEl = document.getElementById('settingAccentSelect');
    if (selectEl) selectEl.value = hex;
  }

  // ---------------------------------------------------------------------------
  // Native Library View (LibraryView from MainAppView.swift)
  // ---------------------------------------------------------------------------

  initNativeLibraryGrid() {
    const grid = document.getElementById('nativePetGrid');
    if (!grid) return;
    grid.innerHTML = '';

    Object.values(COMPANIONS).forEach(c => {
      const card = document.createElement('div');
      card.className = 'native-pet-card';
      card.dataset.id = c.id;
      card.innerHTML = `
        <div class="native-card-img-wrap">
          <img src="${c.sprite}" alt="${c.name}" class="native-card-sprite" />
        </div>
        <div class="native-card-name">${c.name}</div>
        <div class="native-card-tag">${c.role}</div>
        <div class="native-card-actions">
          <button class="btn-card-spawn" data-action="spawn">Spawn</button>
          <button class="btn-card-remove" data-action="remove">Remove</button>
        </div>
      `;

      card.addEventListener('click', (e) => {
        if (e.target.dataset.action === 'spawn') {
          e.stopPropagation();
          this.spawnCompanion(c.id);
        } else if (e.target.dataset.action === 'remove') {
          e.stopPropagation();
          this.dismissCompanion(c.id);
        } else {
          let instance = this.activeAgents.find(a => a.id === c.id);
          if (!instance) {
            this.spawnCompanion(c.id);
            instance = this.activeAgents.find(a => a.id === c.id);
          }
          if (instance) this.selectCompanion(instance);
        }
      });

      grid.appendChild(card);
    });

    const addPcBtn = document.getElementById('btnAddFromPc');
    if (addPcBtn) {
      addPcBtn.addEventListener('click', () => {
        soundFX.playPop();
        alert("📁 Native App Feature:\nIn the macOS app, 'Add from PC' opens an NSOpenPanel to import PNG sprite sheets or Shimeji XML animation folders directly into PetStorage.");
      });
    }
  }

  initArchetypePills() {
    const wrap = document.getElementById('archetypePillStrip');
    if (!wrap) return;
    wrap.innerHTML = '';

    Object.entries(ARCHETYPES).forEach(([key, arch]) => {
      const pill = document.createElement('button');
      pill.className = 'arch-chip';
      pill.dataset.archetype = key;
      pill.textContent = arch.name;

      pill.addEventListener('click', () => {
        if (!this.selectedAgent) return;
        this.selectedAgent.archetype = key;
        soundFX.playPop();
        this.selectCompanion(this.selectedAgent);
        this.selectedAgent.speak(arch.quote);
      });

      wrap.appendChild(pill);
    });

    // Inspector Action Buttons
    const speakBtn = document.getElementById('actionSpeakBtn');
    if (speakBtn) speakBtn.addEventListener('click', () => { if (this.selectedAgent) this.selectedAgent.speak(); });

    const hopBtn = document.getElementById('actionHopBtn');
    if (hopBtn) hopBtn.addEventListener('click', () => { if (this.selectedAgent) this.selectedAgent.hop(); });

    const sleepBtn = document.getElementById('actionSleepBtn');
    if (sleepBtn) sleepBtn.addEventListener('click', () => { if (this.selectedAgent) { this.selectedAgent.toggleSleep(); soundFX.playPop(); } });
  }

  // ---------------------------------------------------------------------------
  // Native Workshop View (AIToolsView.swift)
  // ---------------------------------------------------------------------------

  initNativeWorkshop() {
    const subtabs = document.querySelectorAll('.workshop-tab-btn');
    const container = document.getElementById('workshopContent');

    subtabs.forEach(btn => {
      btn.addEventListener('click', () => {
        subtabs.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const mode = btn.dataset.subtab;
        soundFX.playPop();
        this.renderWorkshopMode(mode, container);
      });
    });

    const dropzone = document.getElementById('workshopDropzone');
    const runBtn = document.getElementById('btnRunMagicEraser');
    if (dropzone) {
      dropzone.addEventListener('click', () => {
        soundFX.playPop();
        dropzone.innerHTML = '<span>✅ Selected: <strong>sample_runner.png</strong> (Ready for local background removal)</span>';
      });
    }
    if (runBtn) {
      runBtn.addEventListener('click', () => {
        soundFX.playPop();
        alert("✨ On-Device Apple Vision ML:\nIn the native macOS application, Magic Eraser processes images offline using VNGenerateForegroundInstanceMaskRequest without any cloud API.");
      });
    }
  }

  renderWorkshopMode(mode, container) {
    if (!container) return;

    if (mode === 'magicEraser') {
      container.innerHTML = `
        <div class="workshop-tool-card">
          <h4>Apple Vision Magic Eraser</h4>
          <p class="workshop-tool-desc">
            Removes solid and complex backgrounds from sprite sheets and animated GIFs locally on the Neural Engine using VNGenerateForegroundInstanceMaskRequest.
          </p>
          <div class="workshop-dropzone" id="workshopDropzone">
            <span>📁 Drag & Drop Sprite Image or GIF here (or click to browse)</span>
          </div>
          <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 10px;">
            <span style="font-size: 0.8rem; color: var(--mac-text-muted);">Status: Ready for offline processing</span>
            <button class="btn btn-primary btn-sm" id="btnRunMagicEraser">Remove Background (Offline)</button>
          </div>
        </div>
      `;
      const dz = document.getElementById('workshopDropzone');
      const rb = document.getElementById('btnRunMagicEraser');
      if (dz) dz.addEventListener('click', () => { soundFX.playPop(); dz.innerHTML = '<span>✅ Selected: <strong>sample_runner.png</strong> (Ready for local background removal)</span>'; });
      if (rb) rb.addEventListener('click', () => { soundFX.playPop(); alert("✨ On-Device Apple Vision ML:\nMagic Eraser processes frames offline using macOS Neural Engine."); });
    } else if (mode === 'aiGenerator') {
      container.innerHTML = `
        <div class="workshop-tool-card">
          <h4>AI Sprite Generator</h4>
          <p class="workshop-tool-desc">
            Generate customized 4-directional companion sprites from text prompts using cloud diffusion models.
          </p>
          <div style="display: flex; gap: 8px; margin-bottom: 12px;">
            <input type="text" placeholder="e.g. Cyberpunk cat wearing neon goggles running..." class="native-select" style="flex: 1; padding: 7px 10px;" value="A cozy golden retriever puppy walking happily" />
            <button class="btn btn-primary btn-sm btn-ai-generate">Generate</button>
          </div>
          <span style="font-size: 0.76rem; color: var(--mac-text-muted);">Uses opt-in cloud API with local caching.</span>
        </div>
      `;
      const genBtn = container.querySelector('.btn-ai-generate');
      if (genBtn) genBtn.addEventListener('click', () => { soundFX.playPop(); alert('⚡️ Generator API connected in native app.'); });
    } else if (mode === 'shimejiDB') {
      container.innerHTML = `
        <div class="workshop-tool-card">
          <h4>Shimeji Community Database</h4>
          <p class="workshop-tool-desc">
            Browse and download thousands of open-source Shimeji animation packs curated by the global desktop pet community.
          </p>
          <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px;">
            <div style="background: rgba(0,0,0,0.3); padding: 10px; border-radius: 6px; border: 1px solid var(--mac-border-subtle); display: flex; justify-content: space-between; align-items: center;">
              <span>Anime & Gaming Packs (1,420+)</span>
              <button class="btn btn-secondary btn-sm btn-community-import">Import</button>
            </div>
            <div style="background: rgba(0,0,0,0.3); padding: 10px; border-radius: 6px; border: 1px solid var(--mac-border-subtle); display: flex; justify-content: space-between; align-items: center;">
              <span>Pixel Art Animals (890+)</span>
              <button class="btn btn-secondary btn-sm btn-community-import">Import</button>
            </div>
          </div>
        </div>
      `;
      const importBtns = container.querySelectorAll('.btn-community-import');
      importBtns.forEach(btn => {
        btn.addEventListener('click', () => { soundFX.playPop(); alert('Importing package...'); });
      });
    } else if (mode === 'presetGallery') {
      container.innerHTML = `
        <div class="workshop-tool-card">
          <h4>Built-in Companion Preset Gallery</h4>
          <p class="workshop-tool-desc">
            Pre-bundled official companion presets with optimized collision boundaries and localized dialogue banks.
          </p>
          <p style="font-size: 0.8rem; color: var(--app-accent);">All 8 official companion packs are ready to spawn in the Library tab.</p>
        </div>
      `;
    }
  }

  // ---------------------------------------------------------------------------
  // Native Settings View (SettingsView from MainAppView.swift)
  // ---------------------------------------------------------------------------

  initNativeSettings() {
    // Accent select
    const accentSelect = document.getElementById('settingAccentSelect');
    if (accentSelect) {
      accentSelect.addEventListener('change', (e) => this.setAppAccent(e.target.value));
    }

    // Sliders
    const sGrav = document.getElementById('sliderGravity');
    const lGrav = document.getElementById('lblGravity');
    if (sGrav) {
      sGrav.addEventListener('input', (e) => {
        this.gravityStrength = parseFloat(e.target.value);
        if (lGrav) lGrav.textContent = this.gravityStrength.toFixed(1);
      });
    }

    const sSpeed = document.getElementById('sliderSpeed');
    const lSpeed = document.getElementById('lblSpeed');
    if (sSpeed) {
      sSpeed.addEventListener('input', (e) => {
        this.walkSpeed = parseFloat(e.target.value);
        if (lSpeed) lSpeed.textContent = this.walkSpeed.toFixed(1);
      });
    }

    const sEvent = document.getElementById('sliderEventFreq');
    const lEvent = document.getElementById('lblEventFreq');
    if (sEvent) {
      sEvent.addEventListener('input', (e) => {
        this.eventFrequency = parseInt(e.target.value, 10) / 100;
        if (lEvent) lEvent.textContent = `${e.target.value}%`;
      });
    }

    // Atmosphere Controls
    const atmoToggle = document.getElementById('settingAtmosphereToggle');
    if (atmoToggle) {
      atmoToggle.addEventListener('change', (e) => {
        if (!e.target.checked) this.ambientEngine.setWeather('none');
      });
    }

    const presetSelect = document.getElementById('settingPresetSelect');
    if (presetSelect) {
      presetSelect.addEventListener('change', (e) => this.applyAtmospherePreset(e.target.value));
    }

    const atmoSlider = document.getElementById('settingIntensitySlider');
    const atmoLbl = document.getElementById('lblIntensity');
    if (atmoSlider) {
      atmoSlider.addEventListener('input', (e) => {
        const val = parseInt(e.target.value, 10);
        if (atmoLbl) atmoLbl.textContent = `${val}%`;
        this.ambientEngine.setIntensity(val / 100);
      });
    }

    const qSelect = document.getElementById('settingQualitySelect');
    if (qSelect) {
      qSelect.addEventListener('change', (e) => this.ambientEngine.setQuality(e.target.value));
    }

    const collToggle = document.getElementById('settingCollectiblesToggle');
    if (collToggle) {
      collToggle.addEventListener('change', (e) => {
        this.collectiblesEnabled = e.target.checked;
        if (!this.collectiblesEnabled && this.collectiblesLayer) this.collectiblesLayer.innerHTML = '';
      });
    }

    const invToggle = document.getElementById('settingInvertGravityToggle');
    if (invToggle) {
      invToggle.addEventListener('change', (e) => this.setInvertGravity(e.target.checked));
    }

    const dialToggle = document.getElementById('settingDialogueToggle');
    if (dialToggle) {
      dialToggle.addEventListener('change', (e) => {
        this.dialogueEnabled = e.target.checked;
        if (!this.dialogueEnabled) document.querySelectorAll('.agent-speech-bubble').forEach(b => b.remove());
      });
    }

    const soundToggle = document.getElementById('settingSoundToggle');
    if (soundToggle) {
      soundToggle.addEventListener('change', (e) => {
        soundFX.enabled = e.target.checked;
        const audioIcon = document.getElementById('audioIcon');
        if (audioIcon) audioIcon.textContent = soundFX.enabled ? '🔊' : '🔇';
      });
    }

    const shieldBtn = document.getElementById('btnEmergencyShield');
    if (shieldBtn) {
      shieldBtn.addEventListener('click', () => this.triggerPrivacyShield());
    }
  }

  // ---------------------------------------------------------------------------
  // Menu Bar Extra Dashboard (MenuBarDashboard.swift)
  // ---------------------------------------------------------------------------

  initMenuBarExtraPopover() {
    const extraBtn = document.getElementById('menuBarExtraBtn');
    const closeBtn = document.getElementById('popoverCloseBtn');
    const shieldBtn = document.getElementById('popoverShieldBtn');
    const pauseToggle = document.getElementById('popoverPauseToggle');
    const muteToggle = document.getElementById('popoverMuteToggle');
    const walkToggle = document.getElementById('popoverMenuBarWalkToggle');
    const openStudioLink = document.getElementById('popoverOpenStudio');

    if (extraBtn && this.popoverEl) {
      extraBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        const isOpen = this.popoverEl.style.display === 'block';
        this.popoverEl.style.display = isOpen ? 'none' : 'block';
        soundFX.playPop();
      });

      if (closeBtn) closeBtn.addEventListener('click', () => { this.popoverEl.style.display = 'none'; });

      document.addEventListener('click', (e) => {
        if (!this.popoverEl.contains(e.target) && e.target !== extraBtn) {
          this.popoverEl.style.display = 'none';
        }
      });
    }

    if (shieldBtn) shieldBtn.addEventListener('click', () => this.triggerPrivacyShield());

    if (pauseToggle) {
      pauseToggle.addEventListener('change', (e) => {
        this.isPaused = e.target.checked;
        const pBtn = document.getElementById('pauseSimulationBtn');
        const pIcon = document.getElementById('pauseBtnIcon');
        if (pBtn) pBtn.classList.toggle('active', this.isPaused);
        if (pIcon) pIcon.textContent = this.isPaused ? '▶' : '⏸';
      });
    }

    if (muteToggle) {
      muteToggle.addEventListener('change', (e) => {
        soundFX.enabled = !e.target.checked;
        const audioIcon = document.getElementById('audioIcon');
        if (audioIcon) audioIcon.textContent = soundFX.enabled ? '🔊' : '🔇';
        const st = document.getElementById('settingSoundToggle');
        if (st) st.checked = soundFX.enabled;
      });
    }

    if (walkToggle) {
      walkToggle.addEventListener('change', (e) => this.setInvertGravity(e.target.checked));
    }

    if (openStudioLink) {
      openStudioLink.addEventListener('click', () => {
        this.windowEl.style.display = 'block';
        this.switchNativeTab('settings');
        this.popoverEl.style.display = 'none';
      });
    }
  }

  triggerPrivacyShield() {
    this.isPaused = true;
    soundFX.playPop();
    const pauseToggle = document.getElementById('popoverPauseToggle');
    const pBtn = document.getElementById('pauseSimulationBtn');
    const pIcon = document.getElementById('pauseBtnIcon');
    if (pauseToggle) pauseToggle.checked = true;
    if (pBtn) pBtn.classList.add('active');
    if (pIcon) pIcon.textContent = '▶';

    document.querySelectorAll('.agent-speech-bubble').forEach(b => b.remove());
    if (this.collectiblesLayer) this.collectiblesLayer.innerHTML = '';

    alert("🛡️ Emergency Privacy Shield Activated:\nInstant pause of physics and screen observation observers. Fully local and zero-telemetry.");
  }

  setInvertGravity(inverted) {
    this.invertGravity = inverted;
    const invSettings = document.getElementById('settingInvertGravityToggle');
    const invPopover = document.getElementById('popoverMenuBarWalkToggle');
    if (invSettings) invSettings.checked = inverted;
    if (invPopover) invPopover.checked = inverted;

    this.activeAgents.forEach(a => {
      a.vy = inverted ? -8 : 8;
      a.speak(inverted ? "Upside-down menu bar walking!" : "Back down to earth!");
    });
    soundFX.playHop();
  }

  // ---------------------------------------------------------------------------
  // Hero Spotlight & Controls
  // ---------------------------------------------------------------------------

  initHeroSpotlight() {
    const strip = document.getElementById('heroRosterStrip');
    if (!strip) return;
    strip.innerHTML = '';

    Object.values(COMPANIONS).forEach(c => {
      const chip = document.createElement('div');
      chip.className = 'roster-char-chip';
      chip.innerHTML = `
        <img src="${c.sprite}" alt="${c.name}" class="roster-chip-sprite" />
        <span class="roster-chip-name">${c.name}</span>
      `;

      chip.addEventListener('click', () => {
        soundFX.playPop();
        this.spawnCompanion(c.id);
        const playground = document.getElementById('playground');
        if (playground) playground.scrollIntoView({ behavior: 'smooth' });
      });

      strip.appendChild(chip);
    });
  }

  initPlaygroundControls() {
    // Top Atmosphere Buttons
    const weatherBtns = document.querySelectorAll('#weatherControl .weather-btn');
    weatherBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        weatherBtns.forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const w = btn.dataset.weather;
        this.ambientEngine.setWeather(w);
        this.updateWeatherPill(w);
        soundFX.playPop();
      });
    });

    // Pause Button
    const pauseBtn = document.getElementById('pauseSimulationBtn');
    const pauseIcon = document.getElementById('pauseBtnIcon');
    if (pauseBtn) {
      pauseBtn.addEventListener('click', () => {
        this.isPaused = !this.isPaused;
        if (pauseIcon) pauseIcon.textContent = this.isPaused ? '▶' : '⏸';
        pauseBtn.classList.toggle('active', this.isPaused);
        const popPause = document.getElementById('popoverPauseToggle');
        if (popPause) popPause.checked = this.isPaused;
        soundFX.playPop();
      });
    }

    // Reset Button
    const resetBtn = document.getElementById('resetPlaygroundBtn');
    if (resetBtn) {
      resetBtn.addEventListener('click', () => {
        this.activeAgents.forEach(a => a.destroy());
        this.activeAgents = [];
        this.spawnCompanion('umamusume');
        this.spawnCompanion('chiikawa');
        this.score = 0;
        this.updateScore();
        soundFX.playPop();
      });
    }

    // Audio Button in Menu Bar
    const audioBtn = document.getElementById('audioToggleBtn');
    const audioIcon = document.getElementById('audioIcon');
    if (audioBtn) {
      audioBtn.addEventListener('click', () => {
        soundFX.enabled = !soundFX.enabled;
        if (audioIcon) audioIcon.textContent = soundFX.enabled ? '🔊' : '🔇';
        const st = document.getElementById('settingSoundToggle');
        if (st) st.checked = soundFX.enabled;
        const mt = document.getElementById('popoverMuteToggle');
        if (mt) mt.checked = !soundFX.enabled;
        if (soundFX.enabled) soundFX.playPop();
      });
    }
  }

  applyAtmospherePreset(preset) {
    let weather = 'none';
    let intensity = 70;

    switch (preset) {
      case 'gentle_rain': weather = 'rain'; intensity = 65; break;
      case 'autumn_afternoon': weather = 'leaves'; intensity = 70; break;
      case 'winter_wonder': weather = 'snow'; intensity = 80; break;
      case 'golden_hour': weather = 'sunlight'; intensity = 85; break;
      case 'misty_morning': weather = 'fog'; intensity = 60; break;
      case 'mountain_breeze': weather = 'wind'; intensity = 55; break;
    }

    document.querySelectorAll('#weatherControl .weather-btn').forEach(b => {
      b.classList.toggle('active', b.dataset.weather === weather);
    });

    const atmoSlider = document.getElementById('settingIntensitySlider');
    const atmoLbl = document.getElementById('lblIntensity');
    if (atmoSlider) atmoSlider.value = intensity;
    if (atmoLbl) atmoLbl.textContent = `${intensity}%`;

    const presetSelect = document.getElementById('settingPresetSelect');
    if (presetSelect) presetSelect.value = preset;

    this.ambientEngine.setIntensity(intensity / 100);
    this.ambientEngine.setWeather(weather);
    this.updateWeatherPill(weather);
    soundFX.playPop();
  }

  updateWeatherPill(weather) {
    const iconEl = document.getElementById('weatherStatusIcon');
    const textEl = document.getElementById('weatherStatusText');
    const map = {
      none: { icon: '☀️', text: 'Clear' },
      rain: { icon: '🌧️', text: 'Rain' },
      snow: { icon: '❄️', text: 'Snow' },
      fog: { icon: '🌫️', text: 'Fog' },
      sunlight: { icon: '✨', text: 'Sunlight' },
      wind: { icon: '🍃', text: 'Breeze' },
      leaves: { icon: '🍂', text: 'Autumn' }
    };
    const e = map[weather] || map.none;
    if (iconEl) iconEl.textContent = e.icon;
    if (textEl) textEl.textContent = e.text;
  }

  // ---------------------------------------------------------------------------
  // Collectibles Minigame (Phase 17 Feature)
  // ---------------------------------------------------------------------------

  initCollectiblesMinigame() {
    if (!this.collectiblesLayer) return;

    const icons = {
      none: '🌟', rain: '💧', snow: '❄️', fog: '🌫️', sunlight: '✨', wind: '🍃', leaves: '🍂'
    };

    setInterval(() => {
      if (!this.collectiblesEnabled || this.isPaused) return;
      if (this.collectiblesLayer.children.length >= 4) return;

      const item = document.createElement('div');
      item.className = 'sim-collectible';
      item.textContent = icons[this.ambientEngine.weather] || '🌟';

      const stage = this.stageEl.getBoundingClientRect();
      const posX = 30 + Math.random() * (stage.width - 80);
      const posY = 40 + Math.random() * (stage.height - 120);

      item.style.left = `${posX}px`;
      item.style.top = `${posY}px`;

      item.addEventListener('click', (e) => {
        e.stopPropagation();
        soundFX.playCollect();

        this.score += 10;
        this.updateScore();

        const burst = document.createElement('div');
        burst.className = 'sim-score-burst';
        burst.textContent = '+10';
        burst.style.left = `${posX}px`;
        burst.style.top = `${posY}px`;
        this.collectiblesLayer.appendChild(burst);
        setTimeout(() => burst.remove(), 750);

        this.celebrateCollectible(posX, posY);
        item.remove();
      });

      this.collectiblesLayer.appendChild(item);
      setTimeout(() => { if (item.parentElement) item.remove(); }, 14000);
    }, 7500);
  }

  celebrateCollectible(x, y) {
    if (this.activeAgents.length === 0) return;
    let closest = this.activeAgents[0];
    let minDist = Infinity;
    this.activeAgents.forEach(a => {
      const d = Math.hypot(a.x - x, a.y - y);
      if (d < minDist) { minDist = d; closest = a; }
    });

    if (closest) {
      closest.hop();
      const remarks = ["Nice catch! ✨", "+10 points! 🌟", "Ooh, shiny!", "Great reflexes!", "Score!"];
      closest.speak(remarks[Math.floor(Math.random() * remarks.length)]);
    }
  }

  updateScore() {
    const el = document.getElementById('scoreDisplay');
    if (el) {
      el.textContent = `${this.score}`;
      el.style.transform = 'scale(1.35)';
      el.style.transition = 'transform 0.15s ease-out';
      setTimeout(() => { el.style.transform = 'scale(1)'; }, 150);
    }
  }

  // ---------------------------------------------------------------------------
  // FAQ & Clock
  // ---------------------------------------------------------------------------

  initFAQAccordion() {
    document.querySelectorAll('.faq-card').forEach(card => {
      const btn = card.querySelector('.faq-trigger');
      if (btn) {
        btn.addEventListener('click', () => {
          const isOpen = card.classList.contains('open');
          document.querySelectorAll('.faq-card').forEach(c => c.classList.remove('open'));
          if (!isOpen) card.classList.add('open');
          soundFX.playPop();
        });
      }
    });
  }

  initClock() {
    const clockEl = document.getElementById('clockDisplay');
    const update = () => {
      if (clockEl) {
        const now = new Date();
        clockEl.textContent = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      }
    };
    update();
    setInterval(update, 1000);
  }

  // ---------------------------------------------------------------------------
  // Main Physics Tick & Social Proximity (Phase 9)
  // ---------------------------------------------------------------------------

  startMainLoop() {
    const loop = () => {
      this.tick();
      requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
  }

  tick() {
    const w = this.stageEl.offsetWidth;
    const h = this.stageEl.offsetHeight;

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

    const count = this.activeAgents.length;
    for (let i = 0; i < count; i++) {
      this.activeAgents[i].updatePhysics(w, h, obstacle, this.invertGravity, this.gravityStrength, this.walkSpeed);
    }

    // Social Proximity Check
    if (this.socialCooldown > 0) {
      this.socialCooldown--;
    } else if (count >= 2 && !this.isPaused) {
      this.checkSocialProximity();
    }
  }

  checkSocialProximity() {
    const count = this.activeAgents.length;
    for (let i = 0; i < count; i++) {
      for (let j = i + 1; j < count; j++) {
        const a = this.activeAgents[i];
        const b = this.activeAgents[j];
        if (Math.hypot(a.x - b.x, a.y - b.y) < 110) {
          this.triggerSocialDialogue(a, b);
          this.socialCooldown = 400;
          return;
        }
      }
    }
  }

  triggerSocialDialogue(a, b) {
    const found = SOCIAL_DIALOGUES.find(d =>
      (d.pair[0] === a.id && d.pair[1] === b.id) ||
      (d.pair[0] === b.id && d.pair[1] === a.id)
    );

    if (found) {
      const isDirect = (found.pair[0] === a.id);
      a.speak(isDirect ? found.a : found.b);
      setTimeout(() => b.speak(isDirect ? found.b : found.a), 650);
    } else {
      a.speak(`Hey ${b.name}! Beautiful desktop today!`);
      setTimeout(() => b.speak(`Hi ${a.name}! Let's explore together! ✨`), 650);
    }

    a.hop();
    setTimeout(() => b.hop(), 250);
  }
}

// Bootstrap on DOM Ready
window.addEventListener('DOMContentLoaded', () => {
  window.animattoApp = new AnimattoApp();
});
