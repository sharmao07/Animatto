#!/usr/bin/env python3
"""
Animatto Official Cat Companion — Sprite Frame Generator (Stage 3.1)
Renders exactly 45 original, consistent transparent PNG frames across 9 animation states:
- idle (6)
- walk (8)
- run (6)
- jump (4)
- fall (4)
- land (3)
- sit (4)
- sleep (4)
- grooming (6)
Sum: 6 + 8 + 6 + 4 + 4 + 3 + 4 + 4 + 6 = 45 frames.

Specifications (from docs/CAT_ANIMATION_ARCHITECTURE.md):
- Canvas Size: 256x256 px RGBA
- Ground baseline: Y = 224 (32 px above canvas bottom)
- Anti-aliasing via 4x supersampling (rendered at 1024x1024, Lanczos downsampling)
- Canonical facing: Right (+X)
- Palette:
    Body: #FFFFFF (White)
    Shadow: #EBEEF8 (Soft Cool Gray/Shadow)
    Contour Outline: #2D304E (Deep Charcoal Navy)
    Eyes & Mouth: #292A48 (Dark Indigo)
    Inner Ears / Blush / Nose / Toe beans: #FFBECD (Pastel Soft Pink)
    Sparkle Star: #FFE15F (Golden Star)
"""

import os
import glob
import math
from PIL import Image, ImageDraw

CANVAS_SIZE = 256
SS = 4
W = CANVAS_SIZE * SS
H = CANVAS_SIZE * SS
GROUND_Y = 224 * SS

# Colors
WHITE = (255, 255, 255, 255)
SHADOW = (235, 238, 248, 255)
OUTLINE = (45, 48, 78, 255)
DARK = (41, 42, 72, 255)
PINK_INNER = (255, 185, 205, 255)
PINK_CHEEK = (255, 195, 215, 255)
PINK_NOSE = (255, 175, 195, 255)
GOLD = (255, 225, 95, 255)

OUTLINE_W = int(3 * SS)

def rotate_point(pt, origin, angle_rad):
    ox, oy = origin
    px, py = pt
    qx = ox + math.cos(angle_rad) * (px - ox) - math.sin(angle_rad) * (py - oy)
    qy = oy + math.sin(angle_rad) * (px - ox) + math.cos(angle_rad) * (py - oy)
    return (qx, qy)

def draw_star(draw, cx, cy, r_outer, r_inner, rotation=0.0):
    points = []
    for i in range(8):
        angle = i * math.pi / 4.0 - math.pi / 2.0 + rotation
        r = r_outer if i % 2 == 0 else r_inner
        points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(points, fill=GOLD, outline=OUTLINE, width=int(2.5 * SS))

def draw_smooth_curve(draw, p0, p1, p2, p3, width, fill_color, outline_color=OUTLINE, outline_w=OUTLINE_W):
    steps = 120
    points = []
    for i in range(steps + 1):
        t = i / float(steps)
        x = (1-t)**3 * p0[0] + 3*(1-t)**2 * t * p1[0] + 3*(1-t) * t**2 * p2[0] + t**3 * p3[0]
        y = (1-t)**3 * p0[1] + 3*(1-t)**2 * t * p1[1] + 3*(1-t) * t**2 * p2[1] + t**3 * p3[1]
        points.append((x, y))
    
    # Outline pass
    r_out = (width + outline_w * 2) / 2.0
    for px, py in points:
        draw.ellipse([px - r_out, py - r_out, px + r_out, py + r_out], fill=outline_color)
    # Fill pass
    r_fill = width / 2.0
    for px, py in points:
        draw.ellipse([px - r_fill, py - r_fill, px + r_fill, py + r_fill], fill=fill_color)

def draw_leg(draw, x_top, y_top, x_bottom, y_bottom, width, fill_color=WHITE, outline_color=OUTLINE):
    # Paw bottom edge contacts y_bottom.
    hw = width / 2.0
    hwo = hw + OUTLINE_W
    y_bot_center = y_bottom - hwo
    x_bot_center = x_bottom
    
    dx = x_bot_center - x_top
    dy = y_bot_center - y_top
    length = math.hypot(dx, dy)
    if length < 1:
        return
    
    angle = math.atan2(dy, dx)
    nx = -math.sin(angle) * hw
    ny = math.cos(angle) * hw
    nxo = -math.sin(angle) * hwo
    nyo = math.cos(angle) * hwo
    
    # Outline pass
    p1o = (x_top + nxo, y_top + nyo)
    p2o = (x_bot_center + nxo, y_bot_center + nyo)
    p3o = (x_bot_center - nxo, y_bot_center - nyo)
    p4o = (x_top - nxo, y_top - nyo)
    draw.polygon([p1o, p2o, p3o, p4o], fill=outline_color)
    draw.ellipse([x_top - hwo, y_top - hwo, x_top + hwo, y_top + hwo], fill=outline_color)
    draw.ellipse([x_bot_center - hwo, y_bot_center - hwo, x_bot_center + hwo, y_bot_center + hwo], fill=outline_color)
    
    # Fill pass
    p1 = (x_top + nx, y_top + ny)
    p2 = (x_bot_center + nx, y_bot_center + ny)
    p3 = (x_bot_center - nx, y_bot_center - ny)
    p4 = (x_top - nx, y_top - ny)
    draw.polygon([p1, p2, p3, p4], fill=fill_color)
    draw.ellipse([x_top - hw, y_top - hw, x_top + hw, y_top + hw], fill=fill_color)
    draw.ellipse([x_bot_center - hw, y_bot_center - hw, x_bot_center + hw, y_bot_center + hw], fill=fill_color)

def draw_cat_head(draw, hx, hy, hr=45*SS, tilt_deg=0.0, eye_mode="open", mouth_mode="smile", ear_r_fold=False, ear_l_fold=False, star_size=16*SS):
    origin = (hx, hy)
    rad = math.radians(tilt_deg)
    
    # Ears
    # Left Ear base
    el1 = rotate_point((hx - 36*SS, hy - 27*SS), origin, rad)
    el2 = rotate_point((hx - 42*SS if not ear_l_fold else hx - 48*SS, hy - 66*SS if not ear_l_fold else hy - 35*SS), origin, rad)
    el3 = rotate_point((hx - 10*SS, hy - 38*SS), origin, rad)
    draw.polygon([el1, el2, el3], fill=WHITE, outline=OUTLINE)
    
    el_in1 = rotate_point((hx - 33*SS, hy - 31*SS), origin, rad)
    el_in2 = rotate_point((hx - 37*SS if not ear_l_fold else hx - 42*SS, hy - 58*SS if not ear_l_fold else hy - 36*SS), origin, rad)
    el_in3 = rotate_point((hx - 15*SS, hy - 38*SS), origin, rad)
    draw.polygon([el_in1, el_in2, el_in3], fill=PINK_INNER)
    
    # Right Ear base
    er1 = rotate_point((hx + 10*SS, hy - 38*SS), origin, rad)
    er2 = rotate_point((hx + 42*SS if not ear_r_fold else hx + 48*SS, hy - 66*SS if not ear_r_fold else hy - 35*SS), origin, rad)
    er3 = rotate_point((hx + 36*SS, hy - 27*SS), origin, rad)
    draw.polygon([er1, er2, er3], fill=WHITE, outline=OUTLINE)
    
    er_in1 = rotate_point((hx + 15*SS, hy - 38*SS), origin, rad)
    er_in2 = rotate_point((hx + 37*SS if not ear_r_fold else hx + 42*SS, hy - 58*SS if not ear_r_fold else hy - 36*SS), origin, rad)
    er_in3 = rotate_point((hx + 33*SS, hy - 31*SS), origin, rad)
    draw.polygon([er_in1, er_in2, er_in3], fill=PINK_INNER)
    
    # Head circle
    draw.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=WHITE, outline=OUTLINE, width=OUTLINE_W)
    
    # Star on Right Ear tip
    star_pt = rotate_point((hx + 42*SS if not ear_r_fold else hx + 48*SS, hy - 66*SS if not ear_r_fold else hy - 35*SS), origin, rad)
    draw_star(draw, star_pt[0], star_pt[1], star_size, star_size / 3.0, rotation=rad)
    
    # Cheeks
    c1 = rotate_point((hx - 16*SS, hy + 18*SS), origin, rad)
    c2 = rotate_point((hx + 24*SS, hy + 18*SS), origin, rad)
    cr_w = 9 * SS
    cr_h = 7 * SS
    draw.ellipse([c1[0] - cr_w, c1[1] - cr_h, c1[0] + cr_w, c1[1] + cr_h], fill=PINK_CHEEK)
    draw.ellipse([c2[0] - cr_w, c2[1] - cr_h, c2[0] + cr_w, c2[1] + cr_h], fill=PINK_CHEEK)
    
    # Eyes
    e1 = rotate_point((hx - 6*SS, hy + 1*SS), origin, rad)
    e2 = rotate_point((hx + 20*SS, hy + 1*SS), origin, rad)
    ew = 5 * SS
    eh = 7 * SS
    
    if eye_mode == "open":
        draw.ellipse([e1[0] - ew, e1[1] - eh, e1[0] + ew, e1[1] + eh], fill=DARK)
        draw.ellipse([e1[0] - ew/2.0, e1[1] - eh/1.5, e1[0] + ew/2.0, e1[1] - eh/4.0], fill=WHITE)
        draw.ellipse([e2[0] - ew, e2[1] - eh, e2[0] + ew, e2[1] + eh], fill=DARK)
        draw.ellipse([e2[0] - ew/2.0, e2[1] - eh/1.5, e2[0] + ew/2.0, e2[1] - eh/4.0], fill=WHITE)
    elif eye_mode == "half":
        draw.arc([e1[0] - ew, e1[1] - eh/2.0, e1[0] + ew, e1[1] + eh], start=0, end=180, fill=DARK, width=int(2.5*SS))
        draw.arc([e2[0] - ew, e2[1] - eh/2.0, e2[0] + ew, e2[1] + eh], start=0, end=180, fill=DARK, width=int(2.5*SS))
    elif eye_mode in ("closed_happy", "closed_sleep"):
        draw.arc([e1[0] - ew*1.2, e1[1] - eh, e1[0] + ew*1.2, e1[1] + eh*0.5], start=180, end=360, fill=DARK, width=int(3*SS))
        draw.arc([e2[0] - ew*1.2, e2[1] - eh, e2[0] + ew*1.2, e2[1] + eh*0.5], start=180, end=360, fill=DARK, width=int(3*SS))
    elif eye_mode == "focused_down":
        draw.ellipse([e1[0] - ew, e1[1] - eh, e1[0] + ew, e1[1] + eh], fill=DARK)
        draw.ellipse([e1[0] - ew/3.0, e1[1], e1[0] + ew/3.0, e1[1] + eh/2.0], fill=WHITE)
        draw.ellipse([e2[0] - ew, e2[1] - eh, e2[0] + ew, e2[1] + eh], fill=DARK)
        draw.ellipse([e2[0] - ew/3.0, e2[1], e2[0] + ew/3.0, e2[1] + eh/2.0], fill=WHITE)
    
    # Mouth
    m_center = rotate_point((hx + 8*SS, hy + 15*SS), origin, rad)
    if mouth_mode == "smile":
        draw.arc([m_center[0] - 7*SS, m_center[1] - 3*SS, m_center[0], m_center[1] + 4*SS], start=0, end=180, fill=DARK, width=int(2.5*SS))
        draw.arc([m_center[0], m_center[1] - 3*SS, m_center[0] + 7*SS, m_center[1] + 4*SS], start=0, end=180, fill=DARK, width=int(2.5*SS))
    elif mouth_mode == "tongue":
        draw.arc([m_center[0] - 7*SS, m_center[1] - 3*SS, m_center[0], m_center[1] + 4*SS], start=0, end=180, fill=DARK, width=int(2.5*SS))
        draw.arc([m_center[0], m_center[1] - 3*SS, m_center[0] + 7*SS, m_center[1] + 4*SS], start=0, end=180, fill=DARK, width=int(2.5*SS))
        draw.ellipse([m_center[0] - 3*SS, m_center[1] + 2*SS, m_center[0] + 4*SS, m_center[1] + 9*SS], fill=PINK_NOSE, outline=OUTLINE, width=int(1.5*SS))
    elif mouth_mode == "open_happy":
        draw.chord([m_center[0] - 6*SS, m_center[1] - 2*SS, m_center[0] + 6*SS, m_center[1] + 8*SS], start=0, end=180, fill=DARK, outline=OUTLINE)
        draw.ellipse([m_center[0] - 3*SS, m_center[1] + 3*SS, m_center[0] + 3*SS, m_center[1] + 7*SS], fill=PINK_NOSE)

def draw_torso_capsule(draw, x1, y1, x2, y2, radius, fill_color=WHITE, outline_color=OUTLINE):
    draw.rounded_rectangle([x1, y1, x2, y2], radius=radius, fill=fill_color, outline=outline_color, width=OUTLINE_W)

def export_frame(img, path):
    out = img.resize((CANVAS_SIZE, CANVAS_SIZE), Image.Resampling.LANCZOS)
    r, g, b, a = out.split()
    # Clean sub-perceptual Lanczos sinc ringing (alpha < 8) to maintain crisp boundary at Y=224
    a = a.point(lambda p: 0 if p < 8 else p)
    out.putalpha(a)
    out.save(path)

def clear_existing_frames(folder_path):
    os.makedirs(folder_path, exist_ok=True)
    for f in glob.glob(os.path.join(folder_path, "*.png")):
        os.remove(f)

# ==============================================================================
# STATE GENERATORS
# ==============================================================================

def generate_idle(base_dir):
    folder = os.path.join(base_dir, "idle")
    clear_existing_frames(folder)
    # Exactly 6 frames: breathing and blinking
    dy_list = [0.0, -1.2, -2.4, -1.8, -0.6, 0.4]
    eye_list = ["open", "open", "open", "closed_happy", "open", "open"]
    tilt_list = [0.0, 0.8, 1.4, 1.0, 0.4, -0.2]
    tail_tip_y = [60, 56, 53, 55, 59, 61]
    
    for i in range(6):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        dy = dy_list[i] * SS
        
        # 1. Tail
        draw_smooth_curve(
            draw,
            p0=(75*SS, 158*SS + dy*0.5),
            p1=(20*SS, 155*SS + dy*0.5),
            p2=(25*SS, 70*SS),
            p3=(60*SS, tail_tip_y[i]*SS),
            width=13*SS,
            fill_color=WHITE
        )
        
        # 2. Back legs
        draw_leg(draw, 86*SS, 160*SS + dy, 86*SS, GROUND_Y, width=18*SS, fill_color=SHADOW)
        draw_leg(draw, 146*SS, 160*SS + dy, 146*SS, GROUND_Y, width=18*SS, fill_color=SHADOW)
        
        # 3. Torso
        draw_torso_capsule(draw, 68*SS, 130*SS + dy, 165*SS, 198*SS + dy, radius=34*SS)
        
        # 4. Front legs
        draw_leg(draw, 108*SS, 165*SS + dy, 108*SS, GROUND_Y, width=18*SS, fill_color=WHITE)
        draw_leg(draw, 168*SS, 165*SS + dy, 168*SS, GROUND_Y, width=18*SS, fill_color=WHITE)
        
        # 5. Head
        star_sz = (18 if eye_list[i] == "closed_happy" else 15) * SS
        draw_cat_head(
            draw,
            hx=152*SS,
            hy=112*SS + dy,
            tilt_deg=tilt_list[i],
            eye_mode=eye_list[i],
            mouth_mode="smile",
            star_size=star_sz
        )
        
        path = os.path.join(folder, f"idle_{i:02d}.png")
        export_frame(img, path)
    print("Generated 6 idle frames.")


def generate_walk(base_dir):
    folder = os.path.join(base_dir, "walk")
    clear_existing_frames(folder)
    # Exactly 8 frames: diagonal quadruped trot cycle
    # Footstep triggers at frame 2 & frame 6
    stride = 18 * SS
    for i in range(8):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        phase = i * (2.0 * math.pi / 8.0)
        body_bob = -math.sin(phase * 2.0) * 3.0 * SS
        head_bob = body_bob * 1.2
        
        s1 = math.sin(phase)
        c1 = math.cos(phase)
        s2 = math.sin(phase + math.pi)
        c2 = math.cos(phase + math.pi)
        
        # Leg positions
        hb_x = 86*SS + c1 * stride
        hb_lift = max(0.0, s1) * 12 * SS
        hb_y = GROUND_Y - hb_lift
        
        fb_x = 146*SS + c2 * stride
        fb_lift = max(0.0, s2) * 12 * SS
        fb_y = GROUND_Y - fb_lift
        
        hf_x = 108*SS + c2 * stride
        hf_lift = max(0.0, s2) * 12 * SS
        hf_y = GROUND_Y - hf_lift
        
        ff_x = 168*SS + c1 * stride
        ff_lift = max(0.0, s1) * 12 * SS
        ff_y = GROUND_Y - ff_lift
        
        # 1. Tail with walk rhythm
        tail_tip_x = 60*SS - c1 * 8 * SS
        tail_tip_y = (60 + s1 * 5) * SS
        draw_smooth_curve(
            draw,
            p0=(75*SS, 158*SS + body_bob),
            p1=(20*SS, 155*SS + body_bob),
            p2=(25*SS, 70*SS),
            p3=(tail_tip_x, tail_tip_y),
            width=13*SS,
            fill_color=WHITE
        )
        
        # 2. Back legs
        draw_leg(draw, 86*SS, 160*SS + body_bob, hb_x, hb_y, width=17*SS, fill_color=SHADOW)
        draw_leg(draw, 146*SS, 160*SS + body_bob, fb_x, fb_y, width=17*SS, fill_color=SHADOW)
        
        # 3. Torso
        draw_torso_capsule(draw, 68*SS, 130*SS + body_bob, 165*SS, 198*SS + body_bob, radius=34*SS)
        
        # 4. Front legs
        draw_leg(draw, 108*SS, 165*SS + body_bob, hf_x, hf_y, width=17*SS, fill_color=WHITE)
        draw_leg(draw, 168*SS, 165*SS + body_bob, ff_x, ff_y, width=17*SS, fill_color=WHITE)
        
        # 5. Head
        draw_cat_head(
            draw,
            hx=152*SS,
            hy=112*SS + head_bob,
            tilt_deg=c1 * 2.0,
            eye_mode="open",
            mouth_mode="smile"
        )
        
        path = os.path.join(folder, f"walk_{i:02d}.png")
        export_frame(img, path)
    print("Generated 8 walk frames.")


def generate_run(base_dir):
    folder = os.path.join(base_dir, "run")
    clear_existing_frames(folder)
    # Exactly 6 frames: rotary gallop bound
    run_configs = [
        # (body_x1, body_y1, body_x2, body_y2, tilt, hx, hy, [hb_x, hb_y], [fb_x, fb_y], [hf_x, hf_y], [ff_x, ff_y], tail_end)
        # 0: Coil
        (75, 135, 155, 195, -5, 145, 118, (80, 224), (130, 218), (95, 224), (145, 218), (40, 95)),
        # 1: Push-off (Hind on ground 224, front launching forward)
        (70, 126, 165, 190, 8, 155, 106, (72, 224), (160, 205), (88, 224), (175, 205), (30, 110)),
        # 2: Full Aerial Flight (stretch!)
        (65, 120, 175, 182, 4, 165, 102, (60, 200), (185, 195), (75, 195), (200, 190), (20, 130)),
        # 3: Forelegs Reach
        (68, 122, 172, 185, -4, 162, 106, (68, 190), (175, 215), (82, 185), (190, 215), (25, 120)),
        # 4: Forepaw Impact (Front on ground 224, hind trailing)
        (70, 130, 165, 192, -10, 152, 115, (75, 195), (150, 224), (90, 190), (165, 224), (35, 105)),
        # 5: Overstep
        (72, 134, 158, 195, -7, 148, 117, (78, 215), (140, 224), (92, 215), (155, 224), (40, 100))
    ]
    
    for i, cfg in enumerate(run_configs):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        bx1, by1, bx2, by2, tilt, hx, hy, (hbx, hby), (fbx, fby), (hfx, hfy), (ffx, ffy), (tx, ty) = cfg
        
        # Tail streaming back
        draw_smooth_curve(
            draw,
            p0=(bx1*SS, (by1+20)*SS),
            p1=((bx1-25)*SS, (by1+15)*SS),
            p2=((tx-10)*SS, (ty+10)*SS),
            p3=(tx*SS, ty*SS),
            width=12*SS,
            fill_color=WHITE
        )
        
        # Back legs
        draw_leg(draw, (bx1+15)*SS, (by1+35)*SS, hbx*SS, hby*SS, width=16*SS, fill_color=SHADOW)
        draw_leg(draw, (bx2-20)*SS, (by1+35)*SS, fbx*SS, fby*SS, width=16*SS, fill_color=SHADOW)
        
        # Torso
        draw_torso_capsule(draw, bx1*SS, by1*SS, bx2*SS, by2*SS, radius=32*SS)
        
        # Front legs
        draw_leg(draw, (bx1+35)*SS, (by1+40)*SS, hfx*SS, hfy*SS, width=16*SS, fill_color=WHITE)
        draw_leg(draw, (bx2-5)*SS, (by1+40)*SS, ffx*SS, ffy*SS, width=16*SS, fill_color=WHITE)
        
        # Head
        draw_cat_head(
            draw,
            hx=hx*SS,
            hy=hy*SS,
            tilt_deg=tilt,
            eye_mode="open",
            mouth_mode="open_happy" if i in (1, 2) else "smile",
            star_size=18*SS if i == 2 else 15*SS
        )
        
        path = os.path.join(folder, f"run_{i:02d}.png")
        export_frame(img, path)
    print("Generated 6 run frames.")


def generate_jump(base_dir):
    folder = os.path.join(base_dir, "jump")
    clear_existing_frames(folder)
    # Exactly 4 frames: crouch -> launch -> ascending -> apex
    jump_configs = [
        # Frame 0: Crouch Prep (low, loaded on ground 224)
        {
            "torso": (70, 145, 160, 205, 30),
            "head": (148, 130, -5),
            "legs": [(80, 224), (135, 224), (95, 224), (150, 224)],
            "tail": (40, 130),
            "mouth": "smile",
            "eyes": "open"
        },
        # Frame 1: Launch Extension (pushing off ground 224 at 35 deg angle)
        {
            "torso": (68, 120, 165, 185, 34),
            "head": (158, 98, 15),
            "legs": [(75, 224), (160, 210), (90, 224), (175, 205)],
            "tail": (30, 135),
            "mouth": "open_happy",
            "eyes": "open"
        },
        # Frame 2: Ascending Arc (airborne! paws tucked forward-up)
        {
            "torso": (65, 105, 165, 170, 32),
            "head": (160, 85, 20),
            "legs": [(65, 180), (165, 170), (80, 175), (180, 165)],
            "tail": (25, 120),
            "mouth": "open_happy",
            "eyes": "open"
        },
        # Frame 3: Apex Reach (highest point, ready to transition to fall)
        {
            "torso": (65, 95, 168, 162, 32),
            "head": (162, 75, 10),
            "legs": [(68, 168), (170, 160), (82, 165), (185, 155)],
            "tail": (22, 100),
            "mouth": "smile",
            "eyes": "open"
        }
    ]
    
    for i, cfg in enumerate(jump_configs):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        x1, y1, x2, y2, rad = cfg["torso"]
        hx, hy, tilt = cfg["head"]
        (hbx, hby), (fbx, fby), (hfx, hfy), (ffx, ffy) = cfg["legs"]
        tx, ty = cfg["tail"]
        
        draw_smooth_curve(
            draw,
            p0=(x1*SS, (y1+25)*SS),
            p1=((x1-20)*SS, (y1+30)*SS),
            p2=((tx-10)*SS, (ty+15)*SS),
            p3=(tx*SS, ty*SS),
            width=12*SS,
            fill_color=WHITE
        )
        
        draw_leg(draw, (x1+15)*SS, (y1+35)*SS, hbx*SS, hby*SS, width=17*SS, fill_color=SHADOW)
        draw_leg(draw, (x2-20)*SS, (y1+35)*SS, fbx*SS, fby*SS, width=17*SS, fill_color=SHADOW)
        
        draw_torso_capsule(draw, x1*SS, y1*SS, x2*SS, y2*SS, radius=rad*SS)
        
        draw_leg(draw, (x1+35)*SS, (y1+40)*SS, hfx*SS, hfy*SS, width=17*SS, fill_color=WHITE)
        draw_leg(draw, (x2-5)*SS, (y1+40)*SS, ffx*SS, ffy*SS, width=17*SS, fill_color=WHITE)
        
        draw_cat_head(
            draw,
            hx=hx*SS,
            hy=hy*SS,
            tilt_deg=tilt,
            eye_mode=cfg["eyes"],
            mouth_mode=cfg["mouth"]
        )
        
        path = os.path.join(folder, f"jump_{i:02d}.png")
        export_frame(img, path)
    print("Generated 4 jump frames.")


def generate_fall(base_dir):
    folder = os.path.join(base_dir, "fall")
    clear_existing_frames(folder)
    # Exactly 4 frames: aerial parachute descent with righting reflex
    tilts = [-2.0, 1.0, 3.0, 0.0]
    tail_x_offsets = [0, 5, -4, 2]
    
    for i in range(4):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        tilt = tilts[i]
        
        bx1, by1, bx2, by2 = 68*SS, 115*SS, 165*SS, 180*SS
        
        tx = (45 + tail_x_offsets[i]) * SS
        ty = 50 * SS
        draw_smooth_curve(
            draw,
            p0=(75*SS, 140*SS),
            p1=(35*SS, 130*SS),
            p2=(30*SS, 80*SS),
            p3=(tx, ty),
            width=13*SS,
            fill_color=WHITE
        )
        
        draw_leg(draw, 78*SS, 145*SS, 62*SS, 202*SS, width=17*SS, fill_color=SHADOW)
        draw_leg(draw, 148*SS, 145*SS, 172*SS, 200*SS, width=17*SS, fill_color=SHADOW)
        
        draw_torso_capsule(draw, bx1, by1, bx2, by2, radius=32*SS)
        
        draw_leg(draw, 95*SS, 150*SS, 82*SS, 205*SS, width=17*SS, fill_color=WHITE)
        draw_leg(draw, 160*SS, 150*SS, 186*SS, 202*SS, width=17*SS, fill_color=WHITE)
        
        draw_cat_head(
            draw,
            hx=152*SS,
            hy=105*SS,
            tilt_deg=tilt,
            eye_mode="focused_down",
            mouth_mode="smile"
        )
        
        path = os.path.join(folder, f"fall_{i:02d}.png")
        export_frame(img, path)
    print("Generated 4 fall frames.")


def generate_land(base_dir):
    folder = os.path.join(base_dir, "land")
    clear_existing_frames(folder)
    # Exactly 3 frames: touchdown -> deep compression squash -> spring recoil
    land_configs = [
        # Frame 0: Touchdown (paws reach ground 224, legs straight)
        {
            "torso": (68, 128, 165, 195, 34),
            "head": (152, 114, 0),
            "legs": [(80, 224), (142, 224), (102, 224), (164, 224)],
            "tail": (45, 90),
            "mouth": "smile",
            "eyes": "open"
        },
        # Frame 1: Full Squash Compression (deep shock absorption!)
        {
            "torso": (65, 148, 172, 208, 30),
            "head": (152, 134, 0),
            "legs": [(74, 224), (146, 224), (96, 224), (168, 224)],
            "tail": (35, 120),
            "mouth": "smile",
            "eyes": "closed_happy"
        },
        # Frame 2: Spring Recoil (rising up cheerfully, ready for idle)
        {
            "torso": (68, 126, 165, 194, 34),
            "head": (152, 110, 0),
            "legs": [(86, 224), (146, 224), (108, 224), (168, 224)],
            "tail": (55, 68),
            "mouth": "open_happy",
            "eyes": "open"
        }
    ]
    
    for i, cfg in enumerate(land_configs):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        x1, y1, x2, y2, rad = cfg["torso"]
        hx, hy, tilt = cfg["head"]
        (hbx, hby), (fbx, fby), (hfx, hfy), (ffx, ffy) = cfg["legs"]
        tx, ty = cfg["tail"]
        
        draw_smooth_curve(
            draw,
            p0=(x1*SS, (y1+25)*SS),
            p1=((x1-20)*SS, (y1+25)*SS),
            p2=((tx-10)*SS, (ty+15)*SS),
            p3=(tx*SS, ty*SS),
            width=13*SS,
            fill_color=WHITE
        )
        
        draw_leg(draw, (x1+15)*SS, (y1+30)*SS, hbx*SS, hby*SS, width=18*SS, fill_color=SHADOW)
        draw_leg(draw, (x2-20)*SS, (y1+30)*SS, fbx*SS, fby*SS, width=18*SS, fill_color=SHADOW)
        
        draw_torso_capsule(draw, x1*SS, y1*SS, x2*SS, y2*SS, radius=rad*SS)
        
        draw_leg(draw, (x1+35)*SS, (y1+35)*SS, hfx*SS, hfy*SS, width=18*SS, fill_color=WHITE)
        draw_leg(draw, (x2-5)*SS, (y1+35)*SS, ffx*SS, ffy*SS, width=18*SS, fill_color=WHITE)
        
        draw_cat_head(
            draw,
            hx=hx*SS,
            hy=hy*SS,
            tilt_deg=tilt,
            eye_mode=cfg["eyes"],
            mouth_mode=cfg["mouth"],
            star_size=18*SS if i == 2 else 15*SS
        )
        
        path = os.path.join(folder, f"land_{i:02d}.png")
        export_frame(img, path)
    print("Generated 3 land frames.")


def generate_sit(base_dir):
    folder = os.path.join(base_dir, "sit")
    clear_existing_frames(folder)
    # Exactly 4 frames: upright seated posture, tail wrapped around front paws
    tail_curls = [185, 187, 184, 186]
    eye_modes = ["open", "open", "closed_happy", "open"]
    tilts = [0.0, 1.5, 0.5, 0.0]
    
    for i in range(4):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Seated hindquarters resting on ground plane Y = 224
        draw.ellipse([70*SS, 160*SS, 125*SS, GROUND_Y], fill=WHITE, outline=OUTLINE, width=OUTLINE_W)
        
        # Upright torso
        draw_torso_capsule(draw, 95*SS, 115*SS, 155*SS, 195*SS, radius=28*SS)
        
        # Vertical front legs straight down to Y = 224
        draw_leg(draw, 122*SS, 160*SS, 122*SS, GROUND_Y, width=16*SS, fill_color=WHITE)
        draw_leg(draw, 144*SS, 160*SS, 144*SS, GROUND_Y, width=16*SS, fill_color=WHITE)
        
        # Tail curled around in front of paws (staying within ground baseline)
        tx_curl = tail_curls[i] * SS
        draw_smooth_curve(
            draw,
            p0=(78*SS, 195*SS),
            p1=(65*SS, 212*SS),
            p2=(110*SS, 214*SS),
            p3=(tx_curl, 212*SS),
            width=12*SS,
            fill_color=WHITE
        )
        
        # Head upright
        draw_cat_head(
            draw,
            hx=130*SS,
            hy=98*SS,
            tilt_deg=tilts[i],
            eye_mode=eye_modes[i],
            mouth_mode="smile"
        )
        
        path = os.path.join(folder, f"sit_{i:02d}.png")
        export_frame(img, path)
    print("Generated 4 sit frames.")


def generate_sleep(base_dir):
    folder = os.path.join(base_dir, "sleep")
    clear_existing_frames(folder)
    # Exactly 4 frames: curled loaf posture, slow gentle breathing expansion
    inhalation = [0.0, -1.2, -2.4, -1.0]
    
    for i in range(4):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        dy = inhalation[i] * SS
        
        # Tail wrapped around side of loaf
        draw_smooth_curve(
            draw,
            p0=(65*SS, 185*SS + dy),
            p1=(40*SS, 195*SS + dy),
            p2=(60*SS, 214*SS),
            p3=(120*SS, 214*SS),
            width=13*SS,
            fill_color=WHITE
        )
        
        # Main loaf body resting on ground Y = 224
        draw_torso_capsule(draw, 60*SS, 155*SS + dy, 185*SS, GROUND_Y, radius=35*SS)
        
        # Head curled low against the front of the body
        hx = 162 * SS
        hy = 168 * SS + dy
        hr = 38 * SS
        
        # Ears tilted back gently
        draw.polygon([(hx - 30*SS, hy - 18*SS), (hx - 36*SS, hy - 45*SS), (hx - 10*SS, hy - 25*SS)], fill=WHITE, outline=OUTLINE)
        draw.polygon([(hx - 27*SS, hy - 20*SS), (hx - 32*SS, hy - 40*SS), (hx - 14*SS, hy - 25*SS)], fill=PINK_INNER)
        draw.polygon([(hx + 5*SS, hy - 25*SS), (hx + 30*SS, hy - 45*SS), (hx + 26*SS, hy - 18*SS)], fill=WHITE, outline=OUTLINE)
        draw.polygon([(hx + 8*SS, hy - 25*SS), (hx + 26*SS, hy - 40*SS), (hx + 23*SS, hy - 20*SS)], fill=PINK_INNER)
        
        # Head circle
        draw.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=WHITE, outline=OUTLINE, width=OUTLINE_W)
        
        # Sleeping star on ear tip
        draw_star(draw, hx + 30*SS, hy - 45*SS, 14*SS, 4.5*SS)
        
        # Cheeks
        draw.ellipse([hx - 14*SS, hy + 10*SS, hx + 2*SS, hy + 22*SS], fill=PINK_CHEEK)
        draw.ellipse([hx + 14*SS, hy + 10*SS, hx + 30*SS, hy + 22*SS], fill=PINK_CHEEK)
        
        # Eyes: closed peaceful crescents
        draw.arc([hx - 12*SS, hy - 6*SS, hx, hy + 6*SS], start=180, end=360, fill=DARK, width=int(2.5*SS))
        draw.arc([hx + 8*SS, hy - 6*SS, hx + 20*SS, hy + 6*SS], start=180, end=360, fill=DARK, width=int(2.5*SS))
        
        # Nose & peaceful mouth
        draw.polygon([(hx + 3*SS, hy + 8*SS), (hx + 7*SS, hy + 8*SS), (hx + 5*SS, hy + 11*SS)], fill=PINK_NOSE)
        draw.arc([hx, hy + 10*SS, hx + 5*SS, hy + 15*SS], start=0, end=180, fill=DARK, width=int(2*SS))
        draw.arc([hx + 5*SS, hy + 10*SS, hx + 10*SS, hy + 15*SS], start=0, end=180, fill=DARK, width=int(2*SS))
        
        path = os.path.join(folder, f"sleep_{i:02d}.png")
        export_frame(img, path)
    print("Generated 4 sleep frames.")


def generate_grooming(base_dir):
    folder = os.path.join(base_dir, "grooming")
    clear_existing_frames(folder)
    # Exactly 6 frames: face washing and paw licking
    # 0: Sit, lift paw
    # 1: Lick paw at mouth (tongue out!)
    # 2: Second lick, eyes closed happy
    # 3: Paw sweeps over ear (ear fold!)
    # 4: Paw wiping cheek, eyes closed happy
    # 5: Paw lowered back down toward ground
    groom_configs = [
        # (paw_x, paw_y, tongue, ear_fold, eye_mode)
        (140, 185, False, False, "open"),
        (138, 114, True, False, "open"),
        (138, 114, True, False, "closed_happy"),
        (172, 75, False, True, "closed_happy"),
        (165, 115, False, False, "closed_happy"),
        (138, 195, False, False, "open")
    ]
    
    for i, (px, py, tongue, ear_fold, eye_mode) in enumerate(groom_configs):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Seated hindquarters on ground plane Y = 224
        draw.ellipse([70*SS, 160*SS, 125*SS, GROUND_Y], fill=WHITE, outline=OUTLINE, width=OUTLINE_W)
        
        # Upright torso
        draw_torso_capsule(draw, 95*SS, 115*SS, 155*SS, 195*SS, radius=28*SS)
        
        # Left foreleg (supporting weight on ground Y = 224)
        draw_leg(draw, 118*SS, 160*SS, 118*SS, GROUND_Y, width=16*SS, fill_color=WHITE)
        
        # Tail curled in front (staying within ground baseline)
        draw_smooth_curve(
            draw,
            p0=(78*SS, 195*SS),
            p1=(65*SS, 212*SS),
            p2=(110*SS, 214*SS),
            p3=(185*SS, 212*SS),
            width=12*SS,
            fill_color=WHITE
        )
        
        # Head
        draw_cat_head(
            draw,
            hx=130*SS,
            hy=98*SS,
            tilt_deg=2.0 if ear_fold else 0.0,
            eye_mode=eye_mode,
            mouth_mode="tongue" if tongue else "smile",
            ear_r_fold=ear_fold
        )
        
        # Right foreleg (active grooming paw!)
        draw_leg(draw, 136*SS, 145*SS, px*SS, py*SS, width=15*SS, fill_color=WHITE)
        # Pink paw pad if paw is lifted
        draw.ellipse([(px - 4)*SS, (py - 4)*SS, (px + 4)*SS, (py + 4)*SS], fill=PINK_NOSE)
        
        path = os.path.join(folder, f"grooming_{i:02d}.png")
        export_frame(img, path)
    print("Generated 6 grooming frames.")


def main():
    target_dir = "Animatto/DefaultCompanions/Cat"
    print(f"Generating all 45 Cat companion animation frames in {target_dir}...")
    generate_idle(target_dir)
    generate_walk(target_dir)
    generate_run(target_dir)
    generate_jump(target_dir)
    generate_fall(target_dir)
    generate_land(target_dir)
    generate_sit(target_dir)
    generate_sleep(target_dir)
    generate_grooming(target_dir)
    print("All 45 frames generated successfully!")

if __name__ == "__main__":
    main()
