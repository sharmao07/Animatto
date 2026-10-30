#!/usr/bin/env python3
"""
Animatto Audio Asset Generator
==============================
Generates pristine, original, 100% mathematically synthesized audio assets for Animatto:
- Ambient: Rain & Thunder, Forest & Birdsong, Gentle Winter Wind (seamless loops)
- Character: Footsteps, Sleep Purr/Breathing, Vocalizations (Happy, Curious, Sleepy)
- UI: Crisp Clicks, Harmonious Selections, Tactile Toggles

All assets are 44.1 kHz 16-bit PCM WAV, licensed under MIT / CC0 for Animatto.
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100

def write_wav(filepath, samples, sample_rate=SAMPLE_RATE, channels=1):
    """Writes a list of normalized floats (-1.0 to 1.0) as 16-bit PCM WAV."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, 'w') as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        packed_frames = bytearray()
        for s in samples:
            # Clamp sample
            clamped = max(-1.0, min(1.0, s))
            int_sample = int(clamped * 32767.0)
            packed_frames.extend(struct.pack('<h', int_sample))
        wf.writeframes(packed_frames)

def crossfade_loop(samples, fade_len):
    """Crossfades the beginning and end of samples to make an artifact-free seamless loop."""
    n = len(samples)
    if n <= fade_len * 2:
        return samples
    out = list(samples)
    for i in range(fade_len):
        t = i / fade_len
        # fade in from tail, fade out to head
        head_sample = out[i]
        tail_idx = n - fade_len + i
        tail_sample = out[tail_idx]
        
        blended = (1.0 - t) * tail_sample + t * head_sample
        out[i] = blended
    return out[:n - fade_len]

# ---------------------------------------------------------
# Ambient 1: Rain & Thunder (Stereo or Mono, 8-second seamless loop)
# ---------------------------------------------------------
def generate_rain_and_thunder(duration=8.0):
    total_samples = int(SAMPLE_RATE * duration)
    rng = random.Random(42)
    
    # 1. Pink/Brown noise generator for rainfall
    # Voss-McCartney filter
    b0, b1, b2, b3, b4, b5, b6 = 0, 0, 0, 0, 0, 0, 0
    rain = []
    for _ in range(total_samples):
        white = rng.uniform(-1.0, 1.0)
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
        b6 = white * 0.115926
        rain.append(pink * 0.06)  # Gentle level
    
    # 2. Thunder rumble events at 1.8s and 5.2s
    rumble = [0.0] * total_samples
    events = [(1.8, 0.45), (5.2, 0.3)]
    for start_t, rumble_amp in events:
        start_idx = int(start_t * SAMPLE_RATE)
        event_len = int(2.2 * SAMPLE_RATE)
        for i in range(event_len):
            idx = start_idx + i
            if idx >= total_samples:
                break
            t = i / SAMPLE_RATE
            # Sub-bass sine frequencies: 48Hz and 68Hz + noisy shudder
            env = math.exp(-t * 1.8) * math.sin(min(1.0, t * 12.0) * math.pi * 0.5)
            sub = (math.sin(2 * math.pi * 52 * t) * 0.7 + 
                   math.sin(2 * math.pi * 74 * t + 0.4) * 0.3 + 
                   rng.uniform(-0.3, 0.3))
            rumble[idx] += sub * env * rumble_amp
    
    combined = [rain[i] + rumble[i] for i in range(total_samples)]
    return crossfade_loop(combined, int(SAMPLE_RATE * 0.8))

# ---------------------------------------------------------
# Ambient 2: Forest & Birdsong (8-second seamless loop)
# ---------------------------------------------------------
def generate_forest_birdsong(duration=8.0):
    total_samples = int(SAMPLE_RATE * duration)
    rng = random.Random(101)
    
    # 1. Soft forest breeze / foliage whisper (gentle lowpass white noise)
    foliage = [0.0] * total_samples
    last = 0.0
    for i in range(total_samples):
        w = rng.uniform(-1.0, 1.0)
        last = last * 0.94 + w * 0.06  # Low-pass filter around 400Hz
        foliage[i] = last * 0.04
    
    # 2. Birdsong chirps (musical frequency sweeps with natural vibrato)
    chirps = [0.0] * total_samples
    bird_phrases = [
        # (start_time, [(start_f, end_f, chirp_dur, delay)])
        (1.0, [(2800, 3400, 0.08, 0.02), (3400, 4100, 0.12, 0.04), (3200, 2900, 0.09, 0.0)]),
        (3.5, [(3100, 3900, 0.10, 0.03), (3900, 4600, 0.14, 0.0)]),
        (6.0, [(2600, 3200, 0.08, 0.02), (3200, 3700, 0.10, 0.02), (3700, 3100, 0.11, 0.0)])
    ]
    
    for phrase_start, notes in bird_phrases:
        current_t = phrase_start
        for start_f, end_f, dur, gap in notes:
            start_i = int(current_t * SAMPLE_RATE)
            n_samples = int(dur * SAMPLE_RATE)
            for j in range(n_samples):
                idx = start_i + j
                if idx >= total_samples:
                    break
                t_rel = j / n_samples
                # Pitch sweep
                freq = start_f + (end_f - start_f) * t_rel
                # Subtle vibrato
                vibrato = 30.0 * math.sin(2 * math.pi * 18.0 * (j / SAMPLE_RATE))
                # Window envelope (attack, sustain, decay)
                env = math.sin(math.pi * t_rel) ** 1.5
                sine = math.sin(2 * math.pi * (freq + vibrato) * (j / SAMPLE_RATE))
                chirps[idx] += sine * env * 0.18
            current_t += dur + gap
            
    combined = [foliage[i] + chirps[i] for i in range(total_samples)]
    return crossfade_loop(combined, int(SAMPLE_RATE * 0.8))

# ---------------------------------------------------------
# Ambient 3: Gentle Winter Wind (8-second seamless loop)
# ---------------------------------------------------------
def generate_winter_wind(duration=8.0):
    total_samples = int(SAMPLE_RATE * duration)
    rng = random.Random(202)
    
    # Resonant sweeping bandpass filter over noise
    wind = [0.0] * total_samples
    y1, y2 = 0.0, 0.0
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        # LFO undulation for wind gusts
        lfo = 0.5 + 0.5 * math.sin(2 * math.pi * 0.18 * t)
        lfo2 = 0.5 + 0.5 * math.sin(2 * math.pi * 0.07 * t + 1.2)
        center_f = 260.0 + 320.0 * lfo + 100.0 * lfo2
        
        w = rng.uniform(-1.0, 1.0)
        # 2-pole resonant filter approximation
        bw = 60.0
        r = 1.0 - (bw * math.pi / SAMPLE_RATE)
        theta = 2.0 * math.pi * center_f / SAMPLE_RATE
        a1 = -2.0 * r * math.cos(theta)
        a2 = r * r
        gain = (1.0 - r) * 0.25 * (0.6 + 0.4 * lfo)
        
        y0 = w * gain - a1 * y1 - a2 * y2
        y2 = y1
        y1 = y0
        wind[i] = y0
        
    return crossfade_loop(wind, int(SAMPLE_RATE * 0.8))

# ---------------------------------------------------------
# Character Sounds
# ---------------------------------------------------------
def generate_footstep():
    """Soft 45ms acoustic step tap."""
    dur = 0.045
    total = int(SAMPLE_RATE * dur)
    samples = []
    rng = random.Random(55)
    for i in range(total):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 90.0)
        # Soft low impact (130Hz) + quick high click (1100Hz)
        thump = math.sin(2 * math.pi * 130.0 * t) * 0.6
        tap = rng.uniform(-0.3, 0.3) * math.exp(-t * 220.0)
        samples.append((thump + tap) * env * 0.4)
    return samples

def generate_sleep_purr():
    """Soft rhythmic purring/breathing loop (1.8 seconds)."""
    dur = 1.8
    total = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        # Inhale/exhale cycle (0.55 Hz)
        breath_env = (0.5 + 0.5 * math.sin(2 * math.pi * (1.0 / dur) * t - math.pi * 0.5)) ** 2
        # Purr oscillation (28 Hz tremor over 75 Hz warm harmonic tone)
        tremor = 0.6 + 0.4 * math.sin(2 * math.pi * 26.0 * t)
        tone = (math.sin(2 * math.pi * 75.0 * t) * 0.7 + 
                math.sin(2 * math.pi * 150.0 * t) * 0.25)
        samples.append(tone * tremor * breath_env * 0.3)
    return crossfade_loop(samples, int(SAMPLE_RATE * 0.1))

def generate_vocalization_happy():
    """Cute 3-tone arpeggio (C6, E6, G6)."""
    notes = [1046.5, 1318.5, 1567.98]
    note_dur = 0.075
    samples = []
    for f in notes:
        n = int(SAMPLE_RATE * note_dur)
        for i in range(n):
            t = i / SAMPLE_RATE
            rel = i / n
            env = math.sin(rel * math.pi) ** 1.3
            tone = (math.sin(2 * math.pi * f * t) * 0.8 + 
                    math.sin(2 * math.pi * f * 2 * t) * 0.2)
            samples.append(tone * env * 0.3)
    return samples

def generate_vocalization_curious():
    """Inquiring upward pitch sweep (A5 -> D6)."""
    dur = 0.18
    total = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        rel = i / total
        env = math.sin(rel * math.pi) ** 1.2
        freq = 880.0 + (1174.6 - 880.0) * (rel ** 1.5)
        tone = math.sin(2 * math.pi * freq * t)
        samples.append(tone * env * 0.3)
    return samples

def generate_vocalization_sleepy():
    """Descending cozy coo (G5 -> C5)."""
    dur = 0.26
    total = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        rel = i / total
        env = math.sin(rel * math.pi) ** 1.5
        freq = 783.99 - (783.99 - 523.25) * (rel ** 0.8)
        tone = math.sin(2 * math.pi * freq * t) * 0.85 + math.sin(2 * math.pi * (freq * 0.5) * t) * 0.15
        samples.append(tone * env * 0.25)
    return samples

# ---------------------------------------------------------
# UI Sounds
# ---------------------------------------------------------
def generate_ui_click():
    """Crisp, modern 12ms micro-click."""
    dur = 0.012
    total = int(SAMPLE_RATE * dur)
    samples = []
    rng = random.Random(77)
    for i in range(total):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 350.0)
        pop = math.sin(2 * math.pi * 1750.0 * t) * 0.7 + rng.uniform(-0.3, 0.3)
        samples.append(pop * env * 0.35)
    return samples

def generate_ui_select():
    """Pleasant 35ms harmonic blip."""
    dur = 0.035
    total = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (i / total)) ** 1.2
        tone = (math.sin(2 * math.pi * 987.77 * t) * 0.7 + 
                math.sin(2 * math.pi * 1975.5 * t) * 0.3)
        samples.append(tone * env * 0.3)
    return samples

def generate_ui_toggle():
    """Tactile two-tone switch confirmation."""
    dur1, dur2 = 0.022, 0.028
    samples = []
    for f, d in [(523.25, dur1), (783.99, dur2)]:
        n = int(SAMPLE_RATE * d)
        for i in range(n):
            t = i / SAMPLE_RATE
            env = math.sin(math.pi * (i / n))
            tone = math.sin(2 * math.pi * f * t)
            samples.append(tone * env * 0.28)
    return samples

def main():
    target_dir = os.path.join(os.path.dirname(__file__), "..", "Animatto", "Resources", "Audio")
    os.makedirs(target_dir, exist_ok=True)
    print(f"Generating Animatto audio assets in: {target_dir}")
    
    assets = {
        # Ambient
        "ambient_rain_thunder.wav": generate_rain_and_thunder(),
        "ambient_forest_birdsong.wav": generate_forest_birdsong(),
        "ambient_winter_wind.wav": generate_winter_wind(),
        # Character
        "character_footstep.wav": generate_footstep(),
        "character_sleep_purr.wav": generate_sleep_purr(),
        "companion_voice_happy.wav": generate_vocalization_happy(),
        "companion_voice_curious.wav": generate_vocalization_curious(),
        "companion_voice_sleepy.wav": generate_vocalization_sleepy(),
        # UI
        "ui_click.wav": generate_ui_click(),
        "ui_select.wav": generate_ui_select(),
        "ui_toggle.wav": generate_ui_toggle(),
    }
    
    for filename, data in assets.items():
        path = os.path.join(target_dir, filename)
        write_wav(path, data)
        size_kb = os.path.getsize(path) / 1024.0
        print(f"  ✓ {filename:30s} ({len(data):6d} samples, {size_kb:6.1f} KB)")
        
    print("Audio assets generated successfully.")

if __name__ == "__main__":
    main()
