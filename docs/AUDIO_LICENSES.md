# Animatto Audio Assets & Provenance

This document details the origin, mathematical synthesis methodology, licensing, and attribution for all bundled audio assets in Animatto.

---

## 1. Overview & Licensing Policy

All bundled audio assets in Animatto are **100% original, synthesized algorithmically**, and released under the **MIT License** (matching Animatto's primary license) and **Creative Commons Zero (CC0 1.0 Universal)** dedication.

- **Author:** Sharma / Animatto Open Source Maintainers
- **Provenance:** Algorithmic synthesis via Python (`scripts/generate_audio_assets.py`) using discrete mathematical waveform generators, digital state-variable filtering, frequency modulation, and crossfade windowing.
- **Third-Party Copyright / Samples:** None. No copyrighted samples, commercial sound libraries, or unverified recordings were used.
- **Redistribution & Modification:** Fully permitted under the MIT License for open-source distribution, packaging, and commercial use.

---

## 2. Bundled Audio Catalog

| Asset Filename | Category | Format / Spec | Synthesis Technique | License |
| :--- | :--- | :--- | :--- | :--- |
| `ambient_rain_thunder.wav` | Ambient Audio | 44.1 kHz, 16-bit PCM, Seamless Loop | Voss-McCartney pink noise filtered at 800 Hz paired with periodic sub-bass decaying rumble (52 Hz & 74 Hz harmonics). Crossfaded over 800ms boundaries. | MIT / CC0 |
| `ambient_forest_birdsong.wav` | Ambient Audio | 44.1 kHz, 16-bit PCM, Seamless Loop | Low-frequency white noise foliage murmur combined with 3 melodic bird chirps utilizing frequency-modulated sinusoidal sweeps (2.6 kHz - 4.6 kHz) with 18 Hz vibrato. | MIT / CC0 |
| `ambient_winter_wind.wav` | Ambient Audio | 44.1 kHz, 16-bit PCM, Seamless Loop | Two-pole resonant bandpass noise filter undulated by slow dual LFOs (0.18 Hz and 0.07 Hz) sweeping 260 Hz to 680 Hz for a natural winter breeze. | MIT / CC0 |
| `character_footstep.wav` | Character Audio | 44.1 kHz, 16-bit PCM, 45ms One-shot | 130 Hz damped acoustic thump with an exponentially decayed 1.1 kHz transient tap. | MIT / CC0 |
| `character_sleep_purr.wav` | Character Audio | 44.1 kHz, 16-bit PCM, 1.8s Loop | 75 Hz harmonic warmth tone modulated by a 26 Hz purr tremor and a 0.55 Hz gentle inhale/exhale respiratory envelope. | MIT / CC0 |
| `companion_voice_happy.wav` | Character Audio | 44.1 kHz, 16-bit PCM, 225ms One-shot | Three-tone ascending harmonic arpeggio (C6 1046.5 Hz, E6 1318.5 Hz, G6 1567.98 Hz) with soft bell windowing. | MIT / CC0 |
| `companion_voice_curious.wav` | Character Audio | 44.1 kHz, 16-bit PCM, 180ms One-shot | Inquiring upward frequency sweep (A5 880 Hz to D6 1174.6 Hz) with power-law ramp. | MIT / CC0 |
| `companion_voice_sleepy.wav` | Character Audio | 44.1 kHz, 16-bit PCM, 260ms One-shot | Cozy descending coo (G5 783.99 Hz down to C5 523.25 Hz) with warm sub-octave blending. | MIT / CC0 |
| `ui_click.wav` | UI Audio | 44.1 kHz, 16-bit PCM, 12ms One-shot | Crisp 1.75 kHz micro-transient with high-damping exponential decay for responsive tactile clicks. | MIT / CC0 |
| `ui_select.wav` | UI Audio | 44.1 kHz, 16-bit PCM, 35ms One-shot | Dual-harmonic water-drop blip (987.77 Hz fundamental + 1975.5 Hz overtone). | MIT / CC0 |
| `ui_toggle.wav` | UI Audio | 44.1 kHz, 16-bit PCM, 50ms One-shot | Two-phase tactile switch confirmation (523.25 Hz primary followed by 783.99 Hz confirmation). | MIT / CC0 |

---

## 3. Reproducibility

Any developer or auditor can inspect and reproduce the exact binary assets by executing:

```bash
python3 scripts/generate_audio_assets.py
```
