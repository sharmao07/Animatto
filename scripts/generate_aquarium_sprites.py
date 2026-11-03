#!/usr/bin/env python3
"""
Animatto Aquarium Mode — Starter Species Sprite Asset Generator (Stage 4.3)
Generates 120 original transparent PNG animation frames (30 frames x 4 species) + 4 master artwork images:
1. Finny: Golden Sunfin (Heliochthys splendens) — Pelagic Cruiser
2. Pip: Spotted Pygmy Puffer (Nanochanna guttatus) — Curious Mid-Surface Explorer
3. Glow: Neon Ghost Tetra (Spectrachthys caeruleus) — Schooling Pelagic
4. Barnaby: Mossy Hermit Crab (Paguropsis muscosus) — Benthic Scavenger

States per species (6 states, 30 frames total):
- swim_idle (6 frames @ 100ms, loop=True)
- swim_active (8 frames @ 71ms, loop=True)
- turn (4 frames @ 62ms, loop=False, nextState=swim_active)
- feed (4 frames @ 83ms, loop=False, nextState=swim_idle)
- rest (4 frames @ 166ms, loop=True)
- dart (4 frames @ 50ms, loop=False, nextState=swim_active)

Standards:
- 256x256 RGBA PNG, straight alpha, sRGB
- Anti-aliasing via 4x supersampling (rendered at 1024x1024, downsampled via Lanczos)
- Canonical facing right (+X)
- 100% original, copyright-free artwork (CC0 1.0 Universal)
"""

import os
import math
import json
from PIL import Image, ImageDraw, ImageFilter

CANVAS_SIZE = 256
SS = 4
W = CANVAS_SIZE * SS
H = CANVAS_SIZE * SS

BASE_DIR = "Animatto/DefaultCompanions/Aquarium"

# State configurations
STATE_SPECS = {
    "swim_idle": {"count": 6, "duration": 100, "loop": True},
    "swim_active": {"count": 8, "duration": 71, "loop": True},
    "turn": {"count": 4, "duration": 62, "loop": False, "nextState": "swim_active"},
    "feed": {"count": 4, "duration": 83, "loop": False, "nextState": "swim_idle"},
    "rest": {"count": 4, "duration": 166, "loop": True},
    "dart": {"count": 4, "duration": 50, "loop": False, "nextState": "swim_active"}
}

# --- Drawing Utilities ---

def bezier_point(p0, p1, p2, p3, t):
    it = 1.0 - t
    x = it**3 * p0[0] + 3 * it**2 * t * p1[0] + 3 * it * t**2 * p2[0] + t**3 * p3[0]
    y = it**3 * p0[1] + 3 * it**2 * t * p1[1] + 3 * it * t**2 * p2[1] + t**3 * p3[1]
    return (x, y)

def draw_bezier_curve(draw, p0, p1, p2, p3, width, color, steps=60):
    prev = p0
    for i in range(1, steps + 1):
        t = i / float(steps)
        curr = bezier_point(p0, p1, p2, p3, t)
        draw.line([prev, curr], fill=color, width=int(width))
        prev = curr

def draw_bezier_filled_shape(draw, top_p0, top_p1, top_p2, top_p3, bot_p3, bot_p2, bot_p1, bot_p0, fill_color, outline_color=None, outline_w=1, steps=40):
    points = []
    for i in range(steps + 1):
        t = i / float(steps)
        points.append(bezier_point(top_p0, top_p1, top_p2, top_p3, t))
    for i in range(steps + 1):
        t = i / float(steps)
        points.append(bezier_point(bot_p3, bot_p2, bot_p1, bot_p0, t))
    draw.polygon(points, fill=fill_color, outline=outline_color, width=int(outline_w))

def rotate_point(pt, origin, angle_rad):
    ox, oy = origin
    px, py = pt
    qx = ox + math.cos(angle_rad) * (px - ox) - math.sin(angle_rad) * (py - oy)
    qy = oy + math.sin(angle_rad) * (px - ox) + math.cos(angle_rad) * (py - oy)
    return (qx, qy)

# ==============================================================================
# SPECIES 1: FINNY — Golden Sunfin (Heliochthys splendens)
# ==============================================================================

def render_sunfin_frame(state, frame_idx, total_frames):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    t_norm = frame_idx / float(total_frames)
    sin_t = math.sin(t_norm * 2.0 * math.pi)
    cos_t = math.cos(t_norm * 2.0 * math.pi)
    
    # State-based dynamics
    cx = W * 0.48
    cy = H * 0.50
    body_bob = 0.0
    tail_angle = 0.0
    fin_phase = t_norm * 2.0 * math.pi
    mouth_open = 0.0
    body_scale_x = 1.0
    body_scale_y = 1.0
    
    if state == "swim_idle":
        body_bob = sin_t * 8.0 * SS
        tail_angle = sin_t * 0.18
    elif state == "swim_active":
        body_bob = sin_t * 12.0 * SS
        tail_angle = sin_t * 0.38
        cx += cos_t * 6.0 * SS
    elif state == "turn":
        # Banking turn: body shortens slightly horizontally, tail sweeps wide
        body_scale_x = 0.88 + 0.12 * math.cos(t_norm * math.pi)
        body_scale_y = 1.05
        tail_angle = math.sin(t_norm * math.pi) * 0.55
        cy -= math.sin(t_norm * math.pi) * 8.0 * SS
    elif state == "feed":
        body_bob = math.sin(t_norm * math.pi) * 10.0 * SS
        tail_angle = sin_t * 0.15
        cx += (1.0 - math.cos(t_norm * math.pi)) * 8.0 * SS
        if frame_idx in (1, 2):
            mouth_open = 1.0 if frame_idx == 1 else 0.6
    elif state == "rest":
        body_bob = sin_t * 4.0 * SS
        tail_angle = sin_t * 0.08
    elif state == "dart":
        # Sudden acceleration burst
        if frame_idx == 0:
            cx -= 15.0 * SS
            body_scale_x = 0.92
            tail_angle = -0.45
        elif frame_idx == 1:
            cx += 25.0 * SS
            body_scale_x = 1.15
            body_scale_y = 0.88
            tail_angle = 0.55
        elif frame_idx == 2:
            cx += 40.0 * SS
            body_scale_x = 1.10
            tail_angle = -0.25
        else:
            cx += 30.0 * SS
            body_scale_x = 1.02
            tail_angle = 0.10

    cy += body_bob

    # Colors
    GOLD_MAIN = (251, 176, 59, 255)
    GOLD_DARK = (247, 147, 30, 255)
    GOLD_SHADOW = (214, 114, 10, 255)
    GOLD_HIGHLIGHT = (255, 230, 140, 255)
    FIN_COLOR = (255, 215, 64, 190)
    FIN_EDGE = (255, 245, 180, 230)
    OUTLINE = (50, 25, 5, 255)
    EYE_DARK = (20, 15, 30, 255)
    EYE_CYAN = (0, 220, 240, 255)
    WHITE = (255, 255, 255, 255)

    # 1. Caudal Tail Fin (Flowing bifurcated gossamer fin)
    tail_root = (cx - 70.0 * SS * body_scale_x, cy)
    tail_len = 80.0 * SS
    t_ang = tail_angle
    
    # Upper lobe
    top_tip = (tail_root[0] - tail_len * math.cos(t_ang) - 20.0 * SS, tail_root[1] - 45.0 * SS + tail_len * math.sin(t_ang))
    top_ctrl1 = (tail_root[0] - 30.0 * SS, tail_root[1] - 35.0 * SS)
    top_ctrl2 = (tail_root[0] - 60.0 * SS, tail_root[1] - 60.0 * SS)
    
    # Lower lobe
    bot_tip = (tail_root[0] - tail_len * math.cos(t_ang) - 15.0 * SS, tail_root[1] + 45.0 * SS + tail_len * math.sin(t_ang))
    bot_ctrl1 = (tail_root[0] - 30.0 * SS, tail_root[1] + 35.0 * SS)
    bot_ctrl2 = (tail_root[0] - 60.0 * SS, tail_root[1] + 60.0 * SS)
    
    fork_indent = (tail_root[0] - 45.0 * SS * math.cos(t_ang), tail_root[1])
    
    tail_poly = [tail_root, top_ctrl1, top_ctrl2, top_tip, fork_indent, bot_tip, bot_ctrl2, bot_ctrl1]
    draw.polygon(tail_poly, fill=FIN_COLOR, outline=OUTLINE, width=int(2.5 * SS))
    # Tail fin fin-rays
    for f_idx in range(4):
        f_ratio = (f_idx + 1) / 5.0
        p_mid = (tail_root[0] * (1.0 - f_ratio) + top_tip[0] * f_ratio, tail_root[1] * (1.0 - f_ratio) + top_tip[1] * f_ratio)
        draw.line([tail_root, p_mid], fill=FIN_EDGE, width=int(1.5 * SS))

    # 2. Dorsal Fin (Top flowing gossamer fin)
    dorsal_p0 = (cx - 30.0 * SS * body_scale_x, cy - 35.0 * SS * body_scale_y)
    dorsal_p1 = (cx - 20.0 * SS, cy - 70.0 * SS + math.sin(fin_phase) * 6.0 * SS)
    dorsal_p2 = (cx + 25.0 * SS, cy - 75.0 * SS + math.cos(fin_phase) * 6.0 * SS)
    dorsal_p3 = (cx + 40.0 * SS * body_scale_x, cy - 30.0 * SS * body_scale_y)
    dorsal_bot = (cx + 10.0 * SS, cy - 32.0 * SS)
    draw.polygon([dorsal_p0, dorsal_p1, dorsal_p2, dorsal_p3, dorsal_bot], fill=FIN_COLOR, outline=OUTLINE, width=int(2.0 * SS))

    # 3. Ventral / Anal Fin (Bottom)
    ventral_p0 = (cx - 40.0 * SS * body_scale_x, cy + 25.0 * SS * body_scale_y)
    ventral_p1 = (cx - 25.0 * SS, cy + 55.0 * SS + math.sin(fin_phase + 1.0) * 5.0 * SS)
    ventral_p2 = (cx + 15.0 * SS, cy + 50.0 * SS)
    ventral_p3 = (cx + 25.0 * SS * body_scale_x, cy + 25.0 * SS * body_scale_y)
    draw.polygon([ventral_p0, ventral_p1, ventral_p2, ventral_p3], fill=FIN_COLOR, outline=OUTLINE, width=int(2.0 * SS))

    # 4. Main Body: Teardrop Amber-Gold
    rx = 75.0 * SS * body_scale_x
    ry = 38.0 * SS * body_scale_y
    body_box = [cx - rx, cy - ry, cx + rx, cy + ry]
    
    # Base body ellipse
    draw.ellipse(body_box, fill=GOLD_MAIN, outline=OUTLINE, width=int(3.0 * SS))
    
    # Belly highlight curve (lower softer tone)
    belly_box = [cx - rx * 0.85, cy - ry * 0.2, cx + rx * 0.85, cy + ry * 0.95]
    draw.ellipse(belly_box, fill=GOLD_DARK)
    
    # Upper back highlight
    back_box = [cx - rx * 0.70, cy - ry * 0.85, cx + rx * 0.60, cy - ry * 0.15]
    draw.ellipse(back_box, fill=GOLD_HIGHLIGHT)

    # 5. Pectoral Fin
    pec_root = (cx + 5.0 * SS, cy + 5.0 * SS)
    pec_sweep = math.sin(fin_phase) * 12.0 * SS
    pec_tip = (pec_root[0] - 30.0 * SS, pec_root[1] + 25.0 * SS + pec_sweep)
    pec_ctrl = (pec_root[0] - 15.0 * SS, pec_root[1] + 35.0 * SS + pec_sweep * 0.5)
    draw.polygon([pec_root, pec_tip, pec_ctrl], fill=FIN_COLOR, outline=OUTLINE, width=int(2.0 * SS))

    # 6. Expressive Eye
    eye_cx = cx + rx * 0.55
    eye_cy = cy - ry * 0.25
    eye_r = 12.0 * SS
    
    # Eye ring
    draw.ellipse([eye_cx - eye_r, eye_cy - eye_r, eye_cx + eye_r, eye_cy + eye_r], fill=EYE_DARK, outline=OUTLINE, width=int(2.0 * SS))
    # Cyan limbus crescent
    draw.arc([eye_cx - eye_r + 2*SS, eye_cy - eye_r + 2*SS, eye_cx + eye_r - 2*SS, eye_cy + eye_r - 2*SS], start=45, end=225, fill=EYE_CYAN, width=int(2.0 * SS))
    # Specular spark
    spark_r = 3.5 * SS
    draw.ellipse([eye_cx + 2.0*SS - spark_r, eye_cy - 3.0*SS - spark_r, eye_cx + 2.0*SS + spark_r, eye_cy - 3.0*SS + spark_r], fill=WHITE)
    # Secondary tiny spark
    draw.ellipse([eye_cx - 3.0*SS, eye_cy + 2.0*SS, eye_cx - 1.0*SS, eye_cy + 4.0*SS], fill=WHITE)

    # 7. Mouth
    snout_x = cx + rx * 0.96
    snout_y = cy + ry * 0.12
    if mouth_open > 0.1:
        # Open mouth for feeding
        mouth_gap = mouth_open * 8.0 * SS
        draw.polygon([(snout_x - 10*SS, snout_y - mouth_gap), (snout_x + 6*SS, snout_y), (snout_x - 10*SS, snout_y + mouth_gap)], fill=EYE_DARK, outline=OUTLINE, width=int(2.0 * SS))
    else:
        draw.arc([snout_x - 12*SS, snout_y - 6*SS, snout_x, snout_y + 6*SS], start=300, end=60, fill=OUTLINE, width=int(2.5 * SS))

    # 8. Gill slit arch
    gill_x = cx + rx * 0.22
    draw.arc([gill_x - 12*SS, cy - ry * 0.55, gill_x + 8*SS, cy + ry * 0.55], start=280, end=80, fill=GOLD_SHADOW, width=int(2.0 * SS))

    # Downsample to target size 256x256
    return img.resize((CANVAS_SIZE, CANVAS_SIZE), Image.Resampling.LANCZOS)

# ==============================================================================
# SPECIES 2: PIP — Spotted Pygmy Puffer (Nanochanna guttatus)
# ==============================================================================

def render_puffer_frame(state, frame_idx, total_frames):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    t_norm = frame_idx / float(total_frames)
    sin_t = math.sin(t_norm * 2.0 * math.pi)
    cos_t = math.cos(t_norm * 2.0 * math.pi)
    
    cx = W * 0.50
    cy = H * 0.50
    puff_scale = 1.0
    body_tilt = 0.0
    pectoral_flap = (frame_idx % 2 == 0)
    mouth_open = 0.0
    tail_wag = sin_t * 0.30
    
    if state == "swim_idle":
        cy += sin_t * 5.0 * SS
    elif state == "swim_active":
        cy += sin_t * 8.0 * SS
        cx += cos_t * 6.0 * SS
        body_tilt = -0.08
        tail_wag = sin_t * 0.50
    elif state == "turn":
        body_tilt = math.sin(t_norm * math.pi) * 0.22
        tail_wag = math.sin(t_norm * math.pi) * 0.65
        cx -= math.sin(t_norm * math.pi) * 8.0 * SS
    elif state == "feed":
        cy += math.sin(t_norm * math.pi) * 6.0 * SS
        cx += (1.0 - math.cos(t_norm * math.pi)) * 6.0 * SS
        mouth_open = 1.0 if frame_idx in (1, 2) else 0.2
    elif state == "rest":
        cy += sin_t * 3.0 * SS
        tail_wag = sin_t * 0.10
    elif state == "dart":
        # Pygmy puffer cute puffing reaction!
        if frame_idx == 0:
            puff_scale = 1.05
            cx -= 8.0 * SS
        elif frame_idx == 1:
            puff_scale = 1.28  # Puffs up round!
            cx += 10.0 * SS
            body_tilt = -0.12
        elif frame_idx == 2:
            puff_scale = 1.22
            cx += 25.0 * SS
        else:
            puff_scale = 1.08
            cx += 18.0 * SS

    # Colors
    GREEN_PEA = (123, 192, 67, 255)
    GREEN_DARK = (62, 117, 40, 255)
    GREEN_SPOT = (45, 95, 30, 255)
    WHITE_BELLY = (245, 248, 238, 255)
    OUTLINE = (30, 45, 25, 255)
    DARK_EYE = (25, 30, 25, 255)
    GOLD_IRIS = (255, 215, 0, 255)
    FIN_TRANS = (180, 230, 160, 200)
    WHITE = (255, 255, 255, 255)

    rx = 58.0 * SS * puff_scale
    ry = 50.0 * SS * puff_scale

    # 1. Caudal Tail
    tail_root = (cx - rx * 0.88, cy)
    tail_dx = -35.0 * SS
    tail_dy = tail_wag * 22.0 * SS
    tail_tip1 = (tail_root[0] + tail_dx, tail_root[1] - 16.0 * SS + tail_dy)
    tail_tip2 = (tail_root[0] + tail_dx, tail_root[1] + 16.0 * SS + tail_dy)
    draw.polygon([tail_root, tail_tip1, (tail_root[0] + tail_dx * 0.8, tail_root[1] + tail_dy), tail_tip2], fill=FIN_TRANS, outline=OUTLINE, width=int(2.0 * SS))

    # 2. Tiny Dorsal Fin
    d_x = cx - rx * 0.50
    d_y = cy - ry * 0.88
    draw.polygon([(d_x - 10*SS, d_y), (d_x, d_y - 18*SS), (d_x + 12*SS, d_y)], fill=FIN_TRANS, outline=OUTLINE, width=int(1.5 * SS))

    # 3. Main Round Puffer Body
    body_box = [cx - rx, cy - ry, cx + rx, cy + ry]
    draw.ellipse(body_box, fill=GREEN_PEA, outline=OUTLINE, width=int(3.0 * SS))

    # 4. Round White Belly
    belly_rx = rx * 0.85
    belly_ry = ry * 0.55
    belly_cy = cy + ry * 0.35
    belly_box = [cx - belly_rx * 0.8, belly_cy - belly_ry, cx + belly_rx * 0.9, belly_cy + belly_ry]
    draw.ellipse(belly_box, fill=WHITE_BELLY)

    # 5. Olive Spots
    spots = [
        (-0.25, -0.45, 9.0),
        (0.05, -0.55, 11.0),
        (-0.45, -0.15, 8.0),
        (0.35, -0.35, 7.5),
        (-0.15, -0.05, 10.0),
        (0.15, -0.10, 8.5),
        (-0.35, 0.20, 7.0)
    ]
    for sx, sy, sr in spots:
        sp_cx = cx + sx * rx
        sp_cy = cy + sy * ry
        sp_r = sr * SS * (1.1 if puff_scale > 1.1 else 1.0)
        draw.ellipse([sp_cx - sp_r, sp_cy - sp_r, sp_cx + sp_r, sp_cy + sp_r], fill=GREEN_SPOT)

    # Tiny soft spikes when puffed
    if puff_scale > 1.15:
        for angle_deg in range(20, 340, 30):
            rad = math.radians(angle_deg)
            px = cx + (rx + 2.0*SS) * math.cos(rad)
            py = cy + (ry + 2.0*SS) * math.sin(rad)
            tip_x = cx + (rx + 8.0*SS) * math.cos(rad)
            tip_y = cy + (ry + 8.0*SS) * math.sin(rad)
            draw.line([(px, py), (tip_x, tip_y)], fill=OUTLINE, width=int(2.0 * SS))

    # 6. Buzzing Pectoral Fin
    pec_x = cx - 5.0 * SS
    pec_y = cy + 10.0 * SS
    pec_ang = -0.5 if pectoral_flap else 0.4
    pec_tip = (pec_x - 22.0 * SS * math.cos(pec_ang), pec_y + 22.0 * SS * math.sin(pec_ang))
    draw.polygon([ (pec_x, pec_y), pec_tip, (pec_x - 12*SS, pec_y + 18*SS) ], fill=FIN_TRANS, outline=OUTLINE, width=int(2.0 * SS))

    # 7. Big Cute Eyes
    eye_cx = cx + rx * 0.42
    eye_cy = cy - ry * 0.20
    eye_r = 14.0 * SS
    # Iris
    draw.ellipse([eye_cx - eye_r, eye_cy - eye_r, eye_cx + eye_r, eye_cy + eye_r], fill=GOLD_IRIS, outline=OUTLINE, width=int(2.5 * SS))
    # Dark pupil
    pupil_r = eye_r * 0.68
    draw.ellipse([eye_cx - pupil_r + 2*SS, eye_cy - pupil_r, eye_cx + pupil_r + 2*SS, eye_cy + pupil_r], fill=DARK_EYE)
    # Bright highlights
    draw.ellipse([eye_cx + 1*SS, eye_cy - pupil_r + 2*SS, eye_cx + 7*SS, eye_cy - pupil_r + 8*SS], fill=WHITE)
    draw.ellipse([eye_cx - 4*SS, eye_cy + 2*SS, eye_cx - 1*SS, eye_cy + 5*SS], fill=WHITE)

    # 8. Puckered Lips / Beak
    snout_x = cx + rx * 0.94
    snout_y = cy + ry * 0.05
    if mouth_open > 0.1:
        draw.ellipse([snout_x - 6*SS, snout_y - 8*SS, snout_x + 10*SS, snout_y + 8*SS], fill=OUTLINE)
        draw.ellipse([snout_x - 3*SS, snout_y - 5*SS, snout_x + 7*SS, snout_y + 5*SS], fill=(230, 100, 100, 255))
    else:
        # Cute puckered beak
        draw.polygon([(snout_x, snout_y - 6*SS), (snout_x + 8*SS, snout_y), (snout_x, snout_y + 6*SS)], fill=(255, 180, 160, 255), outline=OUTLINE, width=int(2.0 * SS))

    return img.resize((CANVAS_SIZE, CANVAS_SIZE), Image.Resampling.LANCZOS)

# ==============================================================================
# SPECIES 3: GLOW — Neon Ghost Tetra (Spectrachthys caeruleus)
# ==============================================================================

def render_tetra_frame(state, frame_idx, total_frames):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    t_norm = frame_idx / float(total_frames)
    sin_t = math.sin(t_norm * 2.0 * math.pi)
    cos_t = math.cos(t_norm * 2.0 * math.pi)
    
    cx = W * 0.48
    cy = H * 0.50
    tail_wag = sin_t * 0.35
    glow_pulse = 0.85 + 0.15 * math.sin(t_norm * 2.0 * math.pi)
    body_angle = 0.0
    mouth_open = 0.0
    
    if state == "swim_idle":
        cy += sin_t * 6.0 * SS
        cx += cos_t * 4.0 * SS
        tail_wag = cos_t * 0.38
        glow_pulse = 0.85 + 0.15 * math.sin((t_norm + 0.15) * 2.0 * math.pi)
    elif state == "swim_active":
        cy += sin_t * 10.0 * SS
        cx += cos_t * 8.0 * SS
        tail_wag = sin_t * 0.60
        glow_pulse = 0.90 + 0.20 * math.sin(t_norm * 4.0 * math.pi)
    elif state == "turn":
        tail_wag = math.sin(t_norm * math.pi) * 0.75
        body_angle = math.sin(t_norm * math.pi) * 0.20
        cx -= math.sin(t_norm * math.pi) * 8.0 * SS
    elif state == "feed":
        cy -= math.sin(t_norm * math.pi) * 12.0 * SS
        body_angle = -math.sin(t_norm * math.pi) * 0.25
        mouth_open = 1.0 if frame_idx in (1, 2) else 0.0
        glow_pulse = 1.15
    elif state == "rest":
        cy += sin_t * 3.0 * SS
        cx += cos_t * 2.0 * SS
        tail_wag = cos_t * 0.12
        glow_pulse = 0.70 + 0.08 * sin_t
    elif state == "dart":
        # Bioluminescent dash
        if frame_idx == 0:
            cx -= 18.0 * SS
            tail_wag = -0.55
            glow_pulse = 1.25
        elif frame_idx == 1:
            cx += 35.0 * SS
            tail_wag = 0.65
            glow_pulse = 1.40
        elif frame_idx == 2:
            cx += 50.0 * SS
            tail_wag = -0.30
            glow_pulse = 1.30
        else:
            cx += 30.0 * SS
            tail_wag = 0.15
            glow_pulse = 1.00

    # Colors
    GHOST_BODY = (195, 230, 250, 185)       # Translucent crystalline
    GHOST_SHADOW = (150, 195, 230, 190)
    GHOST_FIN = (210, 240, 255, 150)
    CYAN_NEON = (0, 240, 255, int(255 * min(1.0, glow_pulse)))
    MAGENTA_NEON = (255, 20, 147, int(255 * min(1.0, glow_pulse)))
    OUTLINE = (25, 45, 75, 240)
    SILVER_EYE = (220, 245, 255, 255)
    DARK_PUPIL = (10, 20, 35, 255)
    WHITE = (255, 255, 255, 255)

    rx = 78.0 * SS
    ry = 32.0 * SS

    # 1. Forked Translucent Caudal Tail
    tail_root = (cx - rx * 0.95, cy)
    tail_len = 65.0 * SS
    top_fork = (tail_root[0] - tail_len, tail_root[1] - 38.0 * SS + tail_wag * 30.0 * SS)
    bot_fork = (tail_root[0] - tail_len, tail_root[1] + 38.0 * SS + tail_wag * 30.0 * SS)
    indent = (tail_root[0] - tail_len * 0.45, tail_root[1] + tail_wag * 15.0 * SS)
    draw.polygon([tail_root, top_fork, indent, bot_fork], fill=GHOST_FIN, outline=OUTLINE, width=int(2.0 * SS))
    # Glowing tail fin accents
    draw.line([indent, top_fork], fill=CYAN_NEON, width=int(1.5 * SS))
    draw.line([indent, bot_fork], fill=MAGENTA_NEON, width=int(1.5 * SS))

    # 2. Dorsal & Adipose Fins
    d_root = (cx - 10.0 * SS, cy - ry * 0.88)
    draw.polygon([d_root, (d_root[0] + 5*SS, d_root[1] - 35*SS), (d_root[0] + 25*SS, d_root[1])], fill=GHOST_FIN, outline=OUTLINE, width=int(2.0 * SS))
    # Tiny adipose fin
    ad_x = cx - rx * 0.60
    draw.polygon([(ad_x, cy - ry * 0.65), (ad_x - 6*SS, cy - ry * 0.88), (ad_x + 8*SS, cy - ry * 0.65)], fill=GHOST_FIN)

    # 3. Ventral Long Anal Fin
    an_root = (cx - rx * 0.70, cy + ry * 0.75)
    draw.polygon([an_root, (cx - 20*SS, cy + ry + 22*SS), (cx + 15*SS, cy + ry * 0.75)], fill=GHOST_FIN, outline=OUTLINE, width=int(2.0 * SS))

    # 4. Main Crystalline Translucent Body
    body_box = [cx - rx, cy - ry, cx + rx, cy + ry]
    draw.ellipse(body_box, fill=GHOST_BODY, outline=OUTLINE, width=int(2.5 * SS))

    # Internal silver abdominal sac (gives authentic ghost tetra anatomy)
    sac_box = [cx - rx * 0.15, cy - ry * 0.1, cx + rx * 0.45, cy + ry * 0.75]
    draw.ellipse(sac_box, fill=(230, 245, 255, 210))

    # 5. BIOLUMINESCENT LATERAL LINES (Signature Feature!)
    # Upper Electric Cyan Stripe
    cyan_p0 = (cx - rx * 0.85, cy - 2.0 * SS)
    cyan_p1 = (cx - 15.0 * SS, cy - 4.0 * SS)
    cyan_p2 = (cx + 25.0 * SS, cy - 6.0 * SS)
    cyan_p3 = (cx + rx * 0.65, cy - 8.0 * SS)
    draw_bezier_curve(draw, cyan_p0, cyan_p1, cyan_p2, cyan_p3, width=int(5.5 * SS), color=CYAN_NEON)
    draw_bezier_curve(draw, cyan_p0, cyan_p1, cyan_p2, cyan_p3, width=int(2.5 * SS), color=WHITE)

    # Lower Vibrant Magenta Stripe (runs from midbody to tail)
    mag_p0 = (cx - rx * 0.85, cy + 5.0 * SS)
    mag_p1 = (cx - rx * 0.50, cy + 6.0 * SS)
    mag_p2 = (cx - rx * 0.10, cy + 7.0 * SS)
    mag_p3 = (cx + rx * 0.15, cy + 6.0 * SS)
    draw_bezier_curve(draw, mag_p0, mag_p1, mag_p2, mag_p3, width=int(5.0 * SS), color=MAGENTA_NEON)
    draw_bezier_curve(draw, mag_p0, mag_p1, mag_p2, mag_p3, width=int(2.0 * SS), color=WHITE)

    # 6. Eye (Silver iris with bright cyan specular rim)
    eye_cx = cx + rx * 0.58
    eye_cy = cy - ry * 0.22
    eye_r = 11.0 * SS
    draw.ellipse([eye_cx - eye_r, eye_cy - eye_r, eye_cx + eye_r, eye_cy + eye_r], fill=SILVER_EYE, outline=OUTLINE, width=int(2.0 * SS))
    # Cyan limbus
    draw.arc([eye_cx - eye_r + 1*SS, eye_cy - eye_r + 1*SS, eye_cx + eye_r - 1*SS, eye_cy + eye_r - 1*SS], start=60, end=240, fill=CYAN_NEON, width=int(2.0 * SS))
    # Dark pupil
    draw.ellipse([eye_cx - eye_r * 0.55, eye_cy - eye_r * 0.55, eye_cx + eye_r * 0.55, eye_cy + eye_r * 0.55], fill=DARK_PUPIL)
    # White highlight spark
    draw.ellipse([eye_cx + 1*SS, eye_cy - 4*SS, eye_cx + 6*SS, eye_cy + 1*SS], fill=WHITE)

    # 7. Snout & Mouth
    snout_x = cx + rx * 0.96
    snout_y = cy + ry * 0.05
    if mouth_open > 0.1:
        draw.polygon([(snout_x - 8*SS, snout_y - 6*SS), (snout_x + 6*SS, snout_y), (snout_x - 8*SS, snout_y + 6*SS)], fill=DARK_PUPIL, outline=OUTLINE, width=int(1.5 * SS))
    else:
        draw.line([(snout_x - 6*SS, snout_y), (snout_x + 2*SS, snout_y)], fill=OUTLINE, width=int(2.0 * SS))

    return img.resize((CANVAS_SIZE, CANVAS_SIZE), Image.Resampling.LANCZOS)

# ==============================================================================
# SPECIES 4: BARNABY — Mossy Hermit Crab (Paguropsis muscosus)
# ==============================================================================

def render_hermit_crab_frame(state, frame_idx, total_frames):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    t_norm = frame_idx / float(total_frames)
    sin_t = math.sin(t_norm * 2.0 * math.pi)
    
    # Ground baseline contact: substrate baseline at Y = 224 * SS = 896
    ground_y = 224.0 * SS
    cx = W * 0.46
    cy = ground_y - 60.0 * SS
    
    hide_progress = 0.0     # 0.0 = fully out, 1.0 = tucked in shell
    claw_feed = 0.0
    walk_stride = 0.0
    shell_bob = 0.0
    
    if state == "swim_idle":
        # Slow walking / scuttling gait
        walk_stride = sin_t
        shell_bob = math.cos(t_norm * 2.0 * math.pi) * 3.5 * SS
        cx += sin_t * 4.0 * SS
    elif state == "swim_active":
        # Active brisk scuttle
        walk_stride = math.sin(t_norm * 4.0 * math.pi)
        shell_bob = abs(math.sin(t_norm * 4.0 * math.pi)) * 6.0 * SS
        cx += math.cos(t_norm * 2.0 * math.pi) * 8.0 * SS
    elif state == "turn":
        walk_stride = math.sin(t_norm * 2.0 * math.pi) * 0.5
        cx -= math.sin(t_norm * math.pi) * 6.0 * SS
    elif state == "feed":
        # Claws pinching food and raising to mouth
        claw_feed = math.sin(t_norm * math.pi)
    elif state == "rest":
        # Relaxed breathing & subtle sensory twitch on substrate
        hide_progress = 0.25 + 0.06 * sin_t
        shell_bob = math.cos(t_norm * 2.0 * math.pi) * 2.5 * SS
        cy += 4.0 * SS
    elif state == "dart":
        # Startled! Pulls into shell!
        if frame_idx == 0:
            hide_progress = 0.10
        elif frame_idx == 1:
            hide_progress = 0.85 # Snaps into shell
        elif frame_idx == 2:
            hide_progress = 0.95 # Peeking out eye-stalks
        else:
            hide_progress = 0.50 # Beginning to venture out

    cy -= shell_bob

    # Colors
    SHELL_MAIN = (141, 110, 99, 255)
    SHELL_DARK = (109, 76, 65, 255)
    SHELL_LIGHT = (188, 170, 164, 255)
    MOSS_LIGHT = (76, 175, 80, 255)
    MOSS_DARK = (46, 125, 50, 255)
    MOSS_PALE = (129, 199, 132, 255)
    CRAB_ORANGE = (255, 112, 67, 255)
    CRAB_DARK = (216, 67, 21, 255)
    OUTLINE = (45, 30, 20, 255)
    EYE_BLACK = (25, 25, 25, 255)
    WHITE = (255, 255, 255, 255)

    # 1. Back Walking Legs (Behind shell)
    leg_ext = 1.0 - hide_progress
    if leg_ext > 0.05:
        # Leg 3 (Back)
        leg3_hip = (cx - 15.0 * SS, cy + 15.0 * SS)
        leg3_knee = (cx - 45.0 * SS * leg_ext, cy + 25.0 * SS - walk_stride * 8.0 * SS)
        leg3_foot = (cx - 55.0 * SS * leg_ext, ground_y)
        draw.line([leg3_hip, leg3_knee, leg3_foot], fill=CRAB_DARK, width=int(6.0 * SS))
        draw.ellipse([leg3_foot[0] - 3*SS, leg3_foot[1] - 3*SS, leg3_foot[0] + 3*SS, leg3_foot[1] + 3*SS], fill=OUTLINE)

    # 2. Spiral River-Snail Shell
    shell_w = 70.0 * SS
    shell_h = 55.0 * SS
    shell_box = [cx - shell_w, cy - shell_h, cx + 15.0 * SS, cy + 30.0 * SS]
    
    # Outer main shell dome
    draw.ellipse(shell_box, fill=SHELL_MAIN, outline=OUTLINE, width=int(3.0 * SS))
    # Spiral apex whorl
    whorl1 = [cx - shell_w + 5*SS, cy - shell_h * 0.7, cx - shell_w * 0.35, cy + 10*SS]
    draw.ellipse(whorl1, fill=SHELL_DARK, outline=OUTLINE, width=int(2.0 * SS))
    whorl2 = [cx - shell_w + 12*SS, cy - shell_h * 0.45, cx - shell_w * 0.55, cy - 2*SS]
    draw.ellipse(whorl2, fill=SHELL_LIGHT, outline=OUTLINE, width=int(1.5 * SS))
    # Shell aperture lip
    aperture_box = [cx - 8.0 * SS, cy - 10.0 * SS, cx + 25.0 * SS, cy + 38.0 * SS]
    draw.ellipse(aperture_box, fill=SHELL_DARK, outline=OUTLINE, width=int(2.5 * SS))

    # 3. Sprout of Moss on top of shell
    moss_cx = cx - shell_w * 0.45
    moss_cy = cy - shell_h * 0.85
    moss_tufts = [
        (0.0, 0.0, 16.0, MOSS_DARK),
        (-12.0, 6.0, 14.0, MOSS_LIGHT),
        (12.0, 8.0, 13.0, MOSS_LIGHT),
        (-6.0, -10.0, 12.0, MOSS_PALE),
        (8.0, -8.0, 11.0, MOSS_PALE),
        (0.0, -16.0, 9.0, MOSS_LIGHT)
    ]
    for mx, my, mr, mc in moss_tufts:
        m_x = moss_cx + mx * SS
        m_y = moss_cy + my * SS
        m_r = mr * SS
        draw.ellipse([m_x - m_r, m_y - m_r, m_x + m_r, m_y + m_r], fill=mc)
    # Moss leafy sprigs
    for i in range(3):
        ang = -1.2 + float(i) * 0.6
        sx1 = moss_cx + math.cos(ang) * 15.0 * SS
        sy1 = moss_cy + math.sin(ang) * 18.0 * SS
        sx2 = moss_cx + math.cos(ang) * 28.0 * SS
        sy2 = moss_cy + math.sin(ang) * 32.0 * SS
        draw.line([(sx1, sy1), (sx2, sy2)], fill=MOSS_LIGHT, width=int(2.5 * SS))
        draw.ellipse([sx2 - 3*SS, sy2 - 3*SS, sx2 + 3*SS, sy2 + 3*SS], fill=MOSS_PALE)

    # 4. Front Walking Legs (In front of shell)
    if leg_ext > 0.05:
        # Leg 1 (Front walking)
        leg1_hip = (cx + 10.0 * SS, cy + 22.0 * SS)
        leg1_knee = (cx + 38.0 * SS * leg_ext, cy + 28.0 * SS + walk_stride * 10.0 * SS)
        leg1_foot = (cx + 52.0 * SS * leg_ext, ground_y)
        draw.line([leg1_hip, leg1_knee, leg1_foot], fill=CRAB_ORANGE, width=int(7.0 * SS))
        draw.ellipse([leg1_foot[0] - 4*SS, leg1_foot[1] - 4*SS, leg1_foot[0] + 4*SS, leg1_foot[1] + 4*SS], fill=OUTLINE)

        # Leg 2 (Middle walking)
        leg2_hip = (cx + 2.0 * SS, cy + 20.0 * SS)
        leg2_knee = (cx + 15.0 * SS * leg_ext, cy + 30.0 * SS - walk_stride * 10.0 * SS)
        leg2_foot = (cx + 22.0 * SS * leg_ext, ground_y)
        draw.line([leg2_hip, leg2_knee, leg2_foot], fill=CRAB_DARK, width=int(6.5 * SS))
        draw.ellipse([leg2_foot[0] - 3.5*SS, leg2_foot[1] - 3.5*SS, leg2_foot[0] + 3.5*SS, leg2_foot[1] + 3.5*SS], fill=OUTLINE)

    # 5. Claws (Chelae)
    if leg_ext > 0.15:
        claw_y_mod = -claw_feed * 24.0 * SS
        claw_x_mod = claw_feed * 12.0 * SS
        
        # Major Chela (Large right claw)
        claw_root = (cx + 18.0 * SS * leg_ext, cy + 18.0 * SS)
        claw_cx = cx + 55.0 * SS * leg_ext + claw_x_mod
        claw_cy = cy + 18.0 * SS + claw_y_mod
        draw.line([claw_root, (claw_cx - 15*SS, claw_cy + 5*SS)], fill=CRAB_ORANGE, width=int(8.0 * SS))
        
        # Chela pincer bulb
        c_rx = 22.0 * SS
        c_ry = 15.0 * SS
        draw.ellipse([claw_cx - c_rx, claw_cy - c_ry, claw_cx + c_rx, claw_cy + c_ry], fill=CRAB_ORANGE, outline=OUTLINE, width=int(2.5 * SS))
        # Pincer opening
        pin_ang = 0.2 if claw_feed > 0.3 else 0.05
        draw.polygon([(claw_cx + c_rx * 0.7, claw_cy - 4*SS), (claw_cx + c_rx * 1.3, claw_cy - 10*SS), (claw_cx + c_rx * 0.6, claw_cy)], fill=CRAB_DARK)
        draw.polygon([(claw_cx + c_rx * 0.7, claw_cy + 4*SS), (claw_cx + c_rx * 1.2, claw_cy + 8*SS), (claw_cx + c_rx * 0.6, claw_cy)], fill=CRAB_DARK)

    # 6. Eye-Stalks & Eyes (Periscope stalks)
    stalk_retract = hide_progress * 18.0 * SS
    stalk_base_y = cy - 2.0 * SS + stalk_retract
    stalk_x1 = cx + 18.0 * SS
    stalk_x2 = cx + 28.0 * SS
    stalk_h = 24.0 * SS * (1.0 - hide_progress * 0.6)
    
    # Left eye stalk
    draw.line([(stalk_x1, stalk_base_y), (stalk_x1 - 4*SS, stalk_base_y - stalk_h)], fill=CRAB_ORANGE, width=int(4.0 * SS))
    draw.ellipse([stalk_x1 - 4*SS - 6*SS, stalk_base_y - stalk_h - 6*SS, stalk_x1 - 4*SS + 6*SS, stalk_base_y - stalk_h + 6*SS], fill=EYE_BLACK, outline=OUTLINE, width=int(1.5 * SS))
    draw.ellipse([stalk_x1 - 4*SS - 2*SS, stalk_base_y - stalk_h - 4*SS, stalk_x1 - 4*SS + 2*SS, stalk_base_y - stalk_h], fill=WHITE)

    # Right eye stalk
    draw.line([(stalk_x2, stalk_base_y), (stalk_x2 + 4*SS, stalk_base_y - stalk_h)], fill=CRAB_ORANGE, width=int(4.0 * SS))
    draw.ellipse([stalk_x2 + 4*SS - 6*SS, stalk_base_y - stalk_h - 6*SS, stalk_x2 + 4*SS + 6*SS, stalk_base_y - stalk_h + 6*SS], fill=EYE_BLACK, outline=OUTLINE, width=int(1.5 * SS))
    draw.ellipse([stalk_x2 + 4*SS - 2*SS, stalk_base_y - stalk_h - 4*SS, stalk_x2 + 4*SS + 2*SS, stalk_base_y - stalk_h], fill=WHITE)

    # 7. Antennae
    if hide_progress < 0.6:
        ant_base = (cx + 24.0 * SS, stalk_base_y - 6.0 * SS)
        ant_t = math.sin(t_norm * 4.0 * math.pi) * 8.0 * SS
        draw.line([ant_base, (ant_base[0] + 45.0 * SS, ant_base[1] - 22.0 * SS + ant_t)], fill=(255, 167, 38, 255), width=int(1.5 * SS))
        draw.line([ant_base, (ant_base[0] + 35.0 * SS, ant_base[1] - 12.0 * SS - ant_t)], fill=(255, 167, 38, 255), width=int(1.5 * SS))

    return img.resize((CANVAS_SIZE, CANVAS_SIZE), Image.Resampling.LANCZOS)

# ==============================================================================
# MASTER ARTWORK & BATCH GENERATION
# ==============================================================================

SPECIES_METADATA = [
    {
        "id": "animatto.creature.sunfin",
        "name": "Finny the Golden Sunfin",
        "species": "Heliochthys splendens",
        "dir": "Sunfin",
        "master": "sunfin_master.png",
        "niche": "pelagic",
        "depthPreference": {"minZ": 0.1, "maxZ": 0.8, "preferredZ": 0.4},
        "buoyancyType": "neutral",
        "cruiseSpeed": 65.0,
        "maxSpeed": 140.0,
        "turningSpeedDegPerSec": 180.0,
        "schoolingAffinity": 0.75,
        "renderer": render_sunfin_frame,
        "desc": "Amber-gold pelagic fish with flowing gossamer fins and expressive eyes."
    },
    {
        "id": "animatto.creature.puffer",
        "name": "Pip the Spotted Pygmy Puffer",
        "species": "Nanochanna guttatus",
        "dir": "Puffer",
        "master": "puffer_master.png",
        "niche": "surface",
        "depthPreference": {"minZ": 0.05, "maxZ": 0.6, "preferredZ": 0.25},
        "buoyancyType": "positive",
        "cruiseSpeed": 50.0,
        "maxSpeed": 110.0,
        "turningSpeedDegPerSec": 210.0,
        "schoolingAffinity": 0.30,
        "renderer": render_puffer_frame,
        "desc": "Miniature pea-green puffer with soft olive spots and buzzing pectoral fins."
    },
    {
        "id": "animatto.creature.tetra",
        "name": "Glow the Neon Ghost Tetra",
        "species": "Spectrachthys caeruleus",
        "dir": "Tetra",
        "master": "tetra_master.png",
        "niche": "pelagic",
        "depthPreference": {"minZ": 0.2, "maxZ": 0.9, "preferredZ": 0.65},
        "buoyancyType": "neutral",
        "cruiseSpeed": 70.0,
        "maxSpeed": 160.0,
        "turningSpeedDegPerSec": 190.0,
        "schoolingAffinity": 0.95,
        "renderer": render_tetra_frame,
        "desc": "Semi-transparent crystalline tetra with iridescent electric cyan and magenta lateral lines."
    },
    {
        "id": "animatto.creature.hermit_crab",
        "name": "Barnaby the Mossy Hermit Crab",
        "species": "Paguropsis muscosus",
        "dir": "HermitCrab",
        "master": "hermit_crab_master.png",
        "niche": "benthic",
        "depthPreference": {"minZ": 0.2, "maxZ": 0.85, "preferredZ": 0.50},
        "buoyancyType": "negative",
        "cruiseSpeed": 35.0,
        "maxSpeed": 80.0,
        "turningSpeedDegPerSec": 140.0,
        "schoolingAffinity": 0.10,
        "renderer": render_hermit_crab_frame,
        "desc": "Warm apricot hermit crab in a spiral river-snail shell with an emerald moss sprout."
    }
]

def generate_manifest(meta):
    states_dict = {}
    for state_name, spec in STATE_SPECS.items():
        st = {
            "folder": state_name,
            "frameCount": spec["count"],
            "frameDurationMs": spec["duration"],
            "loop": spec["loop"]
        }
        if "nextState" in spec:
            st["nextState"] = spec["nextState"]
        states_dict[state_name] = st

    return {
        "characterId": meta["id"],
        "version": "1.0.0",
        "name": meta["name"],
        "species": meta["species"],
        "masterArtwork": meta["master"],
        "canvasSize": {
            "width": 256,
            "height": 256
        },
        "groundBaselineY": 32,
        "aquaticProperties": {
            "niche": meta["niche"],
            "depthPreference": meta["depthPreference"],
            "buoyancyType": meta["buoyancyType"],
            "cruiseSpeed": meta["cruiseSpeed"],
            "maxSpeed": meta["maxSpeed"],
            "turningSpeedDegPerSec": meta["turningSpeedDegPerSec"],
            "schoolingAffinity": meta["schoolingAffinity"]
        },
        "states": states_dict
    }

def generate_attribution_md(meta):
    return f"""# Animatto Official Aquatic Companion — {meta["name"]}

- **Character Name:** {meta["name"]}
- **Species Classification:** *{meta["species"]}*
- **Ecological Niche:** {meta["niche"].capitalize()}
- **Visual Description:** {meta["desc"]}
- **Asset Creator & Maintainer:** Animatto Project Maintainers
- **License:** Creative Commons Zero v1.0 Universal (CC0 1.0) Public Domain Dedication
- **Copyright Status:** 100% Original Artwork. No copyrighted third-party characters, trademarks, or external sprite sheets used.
- **Specifications:**
  - 30 Frames across 6 Animation States (`swim_idle`, `swim_active`, `turn`, `feed`, `rest`, `dart`)
  - Master Artwork: `{meta["master"]}` (256×256 RGBA PNG)
  - Frame Resolution: 256×256 pixels RGBA, straight alpha, sRGB
  - Canonical Orientation: Facing Right (+X)
"""

def generate_license_txt():
    return """Creative Commons Zero v1.0 Universal (CC0 1.0) Public Domain Dedication

The person who associated a work with this deed has dedicated the work to the public domain by waiving all of his or her rights to the work worldwide under copyright law, including all related and neighboring rights, to the extent allowed by law.

You can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission.

Full Legal Code: https://creativecommons.org/publicdomain/zero/1.0/legalcode
"""

def main():
    print("======================================================================")
    print("ANIMATTO AQUARIUM MODE — STARTER SPECIES SPRITE ASSET GENERATOR (STAGE 4.3)")
    print("======================================================================")
    
    total_frames_generated = 0
    total_species = len(SPECIES_METADATA)

    for meta in SPECIES_METADATA:
        species_dir = os.path.join(BASE_DIR, meta["dir"])
        os.makedirs(species_dir, exist_ok=True)
        print(f"\n[+] Generating Species: {meta['name']} ({meta['dir']})...")
        
        # 1. Master Artwork Image (from swim_idle frame 0)
        master_img = meta["renderer"]("swim_idle", 0, 6)
        master_path = os.path.join(species_dir, meta["master"])
        master_img.save(master_path, "PNG")
        print(f"  ✓ Master artwork saved: {master_path}")
        
        # 2. Manifest, License, and Attribution
        manifest_path = os.path.join(species_dir, "manifest.json")
        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(generate_manifest(meta), f, indent=2)
        print(f"  ✓ manifest.json written")
        
        license_path = os.path.join(species_dir, "LICENSE.txt")
        with open(license_path, "w", encoding="utf-8") as f:
            f.write(generate_license_txt())
            
        attrib_path = os.path.join(species_dir, "ATTRIBUTION.md")
        with open(attrib_path, "w", encoding="utf-8") as f:
            f.write(generate_attribution_md(meta))
            
        # 3. Animation States & Frames
        species_frames = 0
        for state_name, spec in STATE_SPECS.items():
            state_dir = os.path.join(species_dir, state_name)
            os.makedirs(state_dir, exist_ok=True)
            count = spec["count"]
            
            for f_idx in range(count):
                frame_img = meta["renderer"](state_name, f_idx, count)
                frame_filename = f"{state_name}_{f_idx:02d}.png"
                frame_path = os.path.join(state_dir, frame_filename)
                frame_img.save(frame_path, "PNG")
                species_frames += 1
                total_frames_generated += 1
                
            print(f"    - State '{state_name}': {count} frames generated ({spec['duration']}ms)")

        print(f"  ✓ {species_frames} frames generated for {meta['dir']}")

    print("\n======================================================================")
    print(f"SUCCESS: Generated {total_frames_generated} frames across {total_species} species!")
    print(f"Target directory: {BASE_DIR}")
    print("======================================================================")

if __name__ == "__main__":
    main()
