import { PortableBehaviorEngine } from '../../core/behaviorEngine.ts';
import { createPresetProfile } from '../../core/personality.ts';
import type { PetAction } from '../../core/types.ts';

// Initialize Portable Behavior Engine with Balanced/Playful Preset
const profile = createPresetProfile('playful', 'prototype-001', 'PrototypePet');
const behaviorEngine = new PortableBehaviorEngine(profile);

const canvas = document.getElementById('character-canvas') as HTMLCanvasElement;
const ctx = canvas.getContext('2d')!;
const speechBubble = document.getElementById('speech-bubble')!;
const statusPill = document.getElementById('status-pill')!;

let frame = 0;
let posX = 80;
let posY = 100;
let velX = 0;
let hopY = 0;
let isDragging = false;

// Voice pool matching Swift curated dialogue
const dialogueMap: Record<PetAction, string[]> = {
  idle: ["Observing the desktop...", "Nice and peaceful.", "Just hanging out!"],
  walking: ["On the move!", "Exploring new corners.", "Walking around!"],
  playing: ["Wheee! So much energy!", "Let's play!", "Boing boing!"],
  sitting: ["Taking a little breather.", "Cozy spot right here.", "Resting my paws."],
  sleeping: ["Zzz... Dreaming...", "Nap time.", "*snore*"],
  dragging: ["Whoa, where are we flying?!", "Put me down gently!"],
  falling: ["Wheeee! Down we go!"]
};

function showSpeechBubble(text: string, durationMs = 3500) {
  speechBubble.textContent = text;
  speechBubble.style.display = 'block';
  setTimeout(() => {
    speechBubble.style.display = 'none';
  }, durationMs);
}

// Draw the companion mascot directly onto the transparent canvas
function renderMascot(action: PetAction) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  
  const cx = posX;
  const cy = posY - hopY;
  
  // Ear wiggle offset
  const earWiggle = Math.sin(frame * 0.1) * 2;
  const breath = Math.sin(frame * 0.05) * 1.5;
  
  // Mascot Ears
  ctx.fillStyle = '#6366F1';
  ctx.beginPath();
  ctx.moveTo(cx - 24, cy - 10 + breath);
  ctx.lineTo(cx - 32, cy - 36 + earWiggle);
  ctx.lineTo(cx - 8, cy - 24 + breath);
  ctx.fill();
  
  ctx.beginPath();
  ctx.moveTo(cx + 8, cy - 24 + breath);
  ctx.lineTo(cx + 32, cy - 36 - earWiggle);
  ctx.lineTo(cx + 24, cy - 10 + breath);
  ctx.fill();
  
  // Inner Ears
  ctx.fillStyle = '#FFAAA6';
  ctx.beginPath();
  ctx.moveTo(cx - 22, cy - 12 + breath);
  ctx.lineTo(cx - 28, cy - 30 + earWiggle);
  ctx.lineTo(cx - 12, cy - 22 + breath);
  ctx.fill();
  
  ctx.beginPath();
  ctx.moveTo(cx + 12, cy - 22 + breath);
  ctx.lineTo(cx + 28, cy - 30 - earWiggle);
  ctx.lineTo(cx + 22, cy - 12 + breath);
  ctx.fill();
  
  // Head / Body
  ctx.fillStyle = '#FFFFFF';
  ctx.beginPath();
  ctx.arc(cx, cy + breath, 30, 0, Math.PI * 2);
  ctx.fill();
  ctx.lineWidth = 2;
  ctx.strokeStyle = '#E0E7FF';
  ctx.stroke();
  
  // Eyes
  ctx.fillStyle = '#1E1B4B';
  if (action === 'sleeping') {
    // Sleeping closed eyes (curved lines)
    ctx.lineWidth = 2;
    ctx.strokeStyle = '#1E1B4B';
    ctx.beginPath();
    ctx.arc(cx - 10, cy - 2 + breath, 5, 0.1 * Math.PI, 0.9 * Math.PI);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(cx + 10, cy - 2 + breath, 5, 0.1 * Math.PI, 0.9 * Math.PI);
    ctx.stroke();
  } else {
    ctx.beginPath();
    ctx.ellipse(cx - 10, cy - 2 + breath, 4, 6, 0, 0, Math.PI * 2);
    ctx.ellipse(cx + 10, cy - 2 + breath, 4, 6, 0, 0, Math.PI * 2);
    ctx.fill();
    
    // Eye Sparkles
    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.arc(cx - 11, cy - 4 + breath, 1.5, 0, Math.PI * 2);
    ctx.arc(cx + 9, cy - 4 + breath, 1.5, 0, Math.PI * 2);
    ctx.fill();
  }
  
  // Rosy Cheeks
  ctx.fillStyle = 'rgba(255, 128, 160, 0.5)';
  ctx.beginPath();
  ctx.arc(cx - 18, cy + 6 + breath, 4, 0, Math.PI * 2);
  ctx.arc(cx + 18, cy + 6 + breath, 4, 0, Math.PI * 2);
  ctx.fill();
  
  // Mouth
  ctx.strokeStyle = '#4338CA';
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.arc(cx - 3, cy + 4 + breath, 3, 0, Math.PI);
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(cx + 3, cy + 4 + breath, 3, 0, Math.PI);
  ctx.stroke();
}

// Behavior loop running at 10-second intervals
setInterval(() => {
  if (isDragging) return;
  
  behaviorEngine.updateNeeds(10.0);
  const nextAction = behaviorEngine.selectNextAction();
  
  if (nextAction === 'walking') {
    velX = (Math.random() - 0.5) * 1.5;
  } else {
    velX = 0;
  }
  
  statusPill.textContent = `${profile.name}: ${nextAction.toUpperCase()}`;
  
  // Spontaneous contextual dialogue
  const lines = dialogueMap[nextAction] ?? ["..."];
  const line = lines[Math.floor(Math.random() * lines.length)];
  if (Math.random() < 0.6) {
    showSpeechBubble(line);
  }
}, 8000);

// Interaction click
canvas.addEventListener('click', () => {
  const current = behaviorEngine.currentAction;
  const lines = dialogueMap[current] ?? ["*Happy chirp!*"];
  const line = lines[Math.floor(Math.random() * lines.length)];
  showSpeechBubble(line);
  hopY = 12;
});

// Dragging
canvas.addEventListener('mousedown', () => {
  isDragging = true;
  behaviorEngine.transitionTo('dragging');
  statusPill.textContent = `${profile.name}: DRAGGING`;
});

window.addEventListener('mouseup', () => {
  if (isDragging) {
    isDragging = false;
    behaviorEngine.transitionTo('idle');
    statusPill.textContent = `${profile.name}: IDLE`;
  }
});

// Animation Frame (60 FPS)
function animate() {
  frame++;
  
  if (behaviorEngine.currentAction === 'walking') {
    posX += velX;
    if (posX < 40) { posX = 40; velX = Math.abs(velX); }
    if (posX > 120) { posX = 120; velX = -Math.abs(velX); }
    hopY = Math.abs(Math.sin(frame * 0.15)) * 4;
  } else if (behaviorEngine.currentAction === 'playing') {
    hopY = Math.abs(Math.sin(frame * 0.2)) * 8;
  } else {
    hopY *= 0.85;
  }
  
  renderMascot(behaviorEngine.currentAction);
  requestAnimationFrame(animate);
}

// Initial announcement
showSpeechBubble("Hi! Animatto Cross-Platform Prototype is running!");
animate();
