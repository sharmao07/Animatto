#!/usr/bin/env python3
"""
Generates a dreamy soft blue/lavender gradient DMG background for Animatto.
Canvas: 2400x1600 (Retina 2x for 1200x800 coordinate space).
Aesthetic: Soft cyan → white → lavender gradient with aurora streaks,
           sparkle accents, cloud-like blur blobs, and a frosted-glass
           bottom card — inspired by the dreamy installer reference image.

Icon zones (create-dmg, 1x window coords → 2x canvas coords):
  Animatto.app   : center (190, 175) → (380, 350) at 2x
  Applications   : center (570, 175) → (1140, 350) at 2x
  How to install : center (265, 370) → (530, 740) at 2x
  some characters: center (495, 370) → (990, 740) at 2x

All decorative elements are drawn OUTSIDE these zones.
"""

import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(SCRIPT_DIR, "assets")
os.makedirs(ASSETS_DIR, exist_ok=True)

# Canvas is large enough that extending the Finder window never shows a cutoff
W, H = 2400, 1600

# ── 1. Base gradient background ──────────────────────────────────────────────
# Top: soft sky-blue  →  center: near-white  →  bottom: soft lavender
def make_gradient():
    img = Image.new("RGB", (W, H))
    px = img.load()
    # Colors at key row fractions
    stops = [
        (0.00, (190, 225, 255)),   # soft sky blue
        (0.25, (215, 235, 255)),   # pale blue
        (0.50, (240, 245, 255)),   # near-white center
        (0.75, (220, 215, 250)),   # pale lavender
        (1.00, (195, 195, 245)),   # soft purple-blue
    ]
    for y in range(H):
        t = y / (H - 1)
        # Find surrounding stops
        for i in range(len(stops) - 1):
            t0, c0 = stops[i]
            t1, c1 = stops[i + 1]
            if t0 <= t <= t1:
                f = (t - t0) / (t1 - t0)
                r = int(c0[0] + f * (c1[0] - c0[0]))
                g = int(c0[1] + f * (c1[1] - c0[1]))
                b = int(c0[2] + f * (c1[2] - c0[2]))
                break
        # Also add a gentle horizontal tint (slightly lighter in the center-left)
        for x in range(W):
            h_frac = abs(x / W - 0.38)   # lighter around x=38% of width
            adjust = int(12 * (1 - min(h_frac * 3, 1)))
            px[x, y] = (min(r + adjust, 255), min(g + adjust, 255), min(b + adjust, 255))
    return img

img = make_gradient()
draw = ImageDraw.Draw(img)

# ── 2. Soft cloud-blob corners ─────────────────────────────────────────────
def add_cloud_blob(base_img, cx, cy, rx, ry, color_rgba, passes=6):
    layer = Image.new("RGBA", base_img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for i in range(passes):
        shrink = 1.0 - i * 0.12
        alpha = int(color_rgba[3] * (1.0 - i / passes) * 0.6)
        d.ellipse(
            [cx - rx * shrink, cy - ry * shrink, cx + rx * shrink, cy + ry * shrink],
            fill=(*color_rgba[:3], alpha),
        )
    layer = layer.filter(ImageFilter.GaussianBlur(radius=110))
    base_img = base_img.convert("RGBA")
    base_img.alpha_composite(layer)
    return base_img.convert("RGB")

# Top-left blue blob
img = add_cloud_blob(img, -80,  -60,  560, 380, (130, 175, 245, 200))
# Bottom-left lavender blob
img = add_cloud_blob(img, -100, H + 50, 600, 380, (165, 145, 240, 180))
# Bottom-right blue blob
img = add_cloud_blob(img, W + 80, H + 40, 580, 360, (120, 165, 250, 190))
# Top-right lavender blob
img = add_cloud_blob(img, W + 60, -80,  520, 360, (170, 150, 245, 170))
# Center-top subtle bright glow (keeps the header area airy)
img = add_cloud_blob(img, W // 2, -180, 620, 380, (210, 230, 255, 150))

draw = ImageDraw.Draw(img)

# ── 3. Aurora / light-streak curves ───────────────────────────────────────
def draw_aurora_streak(draw_obj, x0, y0, x1, y1, cx_off, cy_off,
                       color, width, alpha_steps=8):
    """Draw a bezier-like aurora curve with feathered width using multiple passes."""
    # Approximate bezier with many line segments using quadratic formula
    ctrl_x = (x0 + x1) / 2 + cx_off
    ctrl_y = (y0 + y1) / 2 + cy_off
    steps = 120
    pts = []
    for i in range(steps + 1):
        t = i / steps
        px_ = (1 - t) ** 2 * x0 + 2 * (1 - t) * t * ctrl_x + t ** 2 * x1
        py_ = (1 - t) ** 2 * y0 + 2 * (1 - t) * t * ctrl_y + t ** 2 * y1
        pts.append((px_, py_))

    for pass_i in range(alpha_steps):
        # Outer passes are wider + more transparent → feathered glow
        extra_w = (alpha_steps - pass_i - 1) * 4
        pass_alpha = int(255 * (pass_i + 1) / alpha_steps * 0.55)
        r, g, b = color
        pass_color = (r, g, b, pass_alpha)
        streak_layer = Image.new("RGBA", draw_obj._image.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(streak_layer)
        sd.line(pts, fill=pass_color, width=max(1, width + extra_w))
        img_rgba = draw_obj._image.convert("RGBA")
        img_rgba.alpha_composite(streak_layer)
        draw_obj._image.paste(img_rgba.convert("RGB"))

# Wrap draw to use img directly (we need to paste back)
class AuroraCanvas:
    def __init__(self, image):
        self.img = image

    def streak(self, x0, y0, x1, y1, cx_off, cy_off, color, width):
        ctrl_x = (x0 + x1) / 2 + cx_off
        ctrl_y = (y0 + y1) / 2 + cy_off
        steps = 150
        pts = []
        for i in range(steps + 1):
            t = i / steps
            px_ = (1-t)**2*x0 + 2*(1-t)*t*ctrl_x + t**2*x1
            py_ = (1-t)**2*y0 + 2*(1-t)*t*ctrl_y + t**2*y1
            pts.append((int(px_), int(py_)))

        for pass_i in range(8):
            extra_w = (7 - pass_i) * 5
            alpha = int(220 * (pass_i + 1) / 8 * 0.5)
            r, g, b = color
            layer = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
            ld = ImageDraw.Draw(layer)
            ld.line(pts, fill=(r, g, b, alpha), width=max(1, width + extra_w))
            layer = layer.filter(ImageFilter.GaussianBlur(radius=max(1, (7 - pass_i) * 2)))
            base = self.img.convert("RGBA")
            base.alpha_composite(layer)
            self.img = base.convert("RGB")

        draw_obj = ImageDraw.Draw(self.img)
        draw_obj.line(pts, fill=(*color, 200), width=width)
        self.img = self.img  # finalize

ac = AuroraCanvas(img)

# Top-left to center-right (sweeping curve, white glow)
ac.streak( -100,  80, W + 100,  420,  200, -220, (200, 230, 255), 3)
# Bottom-left arc sweeping upward
ac.streak( -80,  H - 60, W//2 + 300, 380, -300, -400, (180, 210, 255), 2)
# Top-right down to bottom-left
ac.streak(W + 80, 120, 100, H - 80, -260, -180, (210, 220, 255), 2)
# Small bright streak across the top
ac.streak(200, 40, W - 200, 160, 0, -80, (230, 240, 255), 2)

img = ac.img
draw = ImageDraw.Draw(img)

# ── 4. Sparkle / star accents ──────────────────────────────────────────────
def draw_sparkle(d, cx, cy, size, color):
    """Draw a 4-pointed star sparkle."""
    s = size
    pts_h = [(cx - s, cy), (cx + s, cy)]
    pts_v = [(cx, cy - s), (cx, cy + s)]
    pts_d1 = [(cx - s*0.4, cy - s*0.4), (cx + s*0.4, cy + s*0.4)]
    pts_d2 = [(cx + s*0.4, cy - s*0.4), (cx - s*0.4, cy + s*0.4)]
    for pts in [pts_h, pts_v, pts_d1, pts_d2]:
        d.line(pts, fill=color, width=max(1, int(size * 0.15)))
    d.ellipse([cx - size*0.1, cy - size*0.1, cx + size*0.1, cy + size*0.1], fill=color)

# Sparkles scattered in safe zones (away from icon areas)
# Icon NO-GO zones (2x coords, ±120px buffer):
# Animatto.app  : ~(380, 350)
# Applications  : ~(1140, 350)
# How to install: ~(530, 740)
# some characters: ~(990, 740)
sparkle_positions = [
    # Top-left corner cluster
    (90, 55, 18, (255, 255, 255, 220)),
    (170, 110, 12, (200, 230, 255, 200)),
    (55, 175, 10, (220, 240, 255, 180)),
    # Top-right cluster
    (W - 95, 65, 16, (255, 255, 255, 220)),
    (W - 180, 130, 11, (210, 225, 255, 190)),
    (W - 60, 210, 9,  (230, 245, 255, 170)),
    # Mid-left
    (75, 420, 14, (200, 220, 255, 180)),
    (130, 560, 9,  (215, 230, 255, 160)),
    # Mid-right
    (W - 85, 380, 13, (210, 225, 255, 185)),
    (W - 150, 510, 8,  (220, 235, 255, 160)),
    # Between app icons (clear zone x=500-1000, y=300-400 is risky — skip)
    # Safe: far top center
    (W // 2 - 280, 60, 10, (235, 245, 255, 190)),
    (W // 2 + 310, 70, 8,  (235, 245, 255, 180)),
    # Bottom corners
    (110, H - 120, 12, (200, 215, 250, 170)),
    (W - 120, H - 100, 14, (205, 220, 250, 175)),
    (220, H - 180, 8,  (215, 225, 255, 150)),
    (W - 250, H - 160, 9, (215, 225, 255, 150)),
    # Bottom center (below card)
    (W//2 - 350, H - 60, 7, (220, 230, 255, 140)),
    (W//2 + 380, H - 70, 8, (220, 230, 255, 145)),
]

for (sx, sy, ss, sc) in sparkle_positions:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(layer)
    draw_sparkle(sd, sx, sy, ss, sc)
    base = img.convert("RGBA")
    base.alpha_composite(layer)
    img = base.convert("RGB")

draw = ImageDraw.Draw(img)

# ── 5. Load app logo ──────────────────────────────────────────────────────
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
LOGO_PATH = os.path.join(REPO_ROOT, "Animatto", "Assets.xcassets",
                          "AppIcon.appiconset", "icon_512x512@2x.png")

LOGO_SIZE_2X = 180   # 90px @1x → nice header size

if os.path.exists(LOGO_PATH):
    logo = Image.open(LOGO_PATH).convert("RGBA")
    logo = logo.resize((LOGO_SIZE_2X, LOGO_SIZE_2X), Image.LANCZOS)

    # Add subtle white glow halo behind the logo
    halo = Image.new("RGBA", img.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    logo_cx = W // 2
    logo_cy = 115
    hd.ellipse(
        [logo_cx - LOGO_SIZE_2X * 0.7, logo_cy - LOGO_SIZE_2X * 0.7,
         logo_cx + LOGO_SIZE_2X * 0.7, logo_cy + LOGO_SIZE_2X * 0.7],
        fill=(255, 255, 255, 90)
    )
    halo = halo.filter(ImageFilter.GaussianBlur(radius=30))
    base = img.convert("RGBA")
    base.alpha_composite(halo)
    img = base.convert("RGB")

    # Paste logo centered at top
    logo_x = logo_cx - LOGO_SIZE_2X // 2
    logo_y = logo_cy - LOGO_SIZE_2X // 2
    tmp = img.convert("RGBA")
    tmp.alpha_composite(logo, dest=(logo_x, logo_y))
    img = tmp.convert("RGB")
    logo_bottom_y = logo_y + LOGO_SIZE_2X
    print(f"Logo composited at ({logo_x}, {logo_y})")
else:
    print(f"WARNING: Logo not found at {LOGO_PATH}")
    logo_bottom_y = 60

draw = ImageDraw.Draw(img)

# ── 6. Title & subtitle ───────────────────────────────────────────────────
font_path = "/System/Library/Fonts/SFNS.ttf"
if not os.path.exists(font_path):
    font_path = "/System/Library/Fonts/Helvetica.ttc"

# Font sizes in 2x pixels
font_title  = ImageFont.truetype(font_path, 72)   # ~36pt @1x
font_sub    = ImageFont.truetype(font_path, 34)   # ~17pt @1x
font_pill   = ImageFont.truetype(font_path, 28)   # ~14pt @1x
font_card   = ImageFont.truetype(font_path, 30)   # ~15pt @1x
font_tip    = ImageFont.truetype(font_path, 26)   # ~13pt @1x

title_color = (25, 40, 80)      # dark navy
sub_color   = (80, 100, 150)    # muted steel blue
card_color  = (55, 75, 120)     # card header text

title_text = "Animatto"
sub_text   = "Desktop Companions for macOS"

title_bbox = draw.textbbox((0, 0), title_text, font=font_title)
title_w = title_bbox[2] - title_bbox[0]
title_x = W // 2 - title_w // 2
title_y = logo_bottom_y + 18

draw.text((title_x, title_y), title_text, fill=title_color, font=font_title)

sub_bbox = draw.textbbox((0, 0), sub_text, font=font_sub)
sub_w = sub_bbox[2] - sub_bbox[0]
sub_x = W // 2 - sub_w // 2
sub_y = title_y + (title_bbox[3] - title_bbox[1]) + 10

draw.text((sub_x, sub_y), sub_text, fill=sub_color, font=font_sub)

# ── 7. Drag-to-install arrow between app (x=190) and applications (x=570) ──
# At 2x: app center ≈ (380, 350), Applications center ≈ (1140, 350)
# Arrow should span the GAP between them, not cover the icons.
# Safe gap: roughly x=490 to x=1030, y=350

arrow_y   = 350          # same row as top icons
arrow_x0  = 530          # just past Animatto icon right edge
arrow_x1  = 1020         # just before Applications left edge
arrow_mid = (arrow_x0 + arrow_x1) // 2

# "DRAG TO INSTALL" label above the arrow
pill_text = "DRAG TO INSTALL"
pill_bbox = draw.textbbox((0, 0), pill_text, font=font_pill)
pill_w    = pill_bbox[2] - pill_bbox[0]
pill_h    = pill_bbox[3] - pill_bbox[1]
pill_pad_x = 22
pill_pad_y = 12
pill_cx   = arrow_mid
pill_cy   = arrow_y - 52   # above arrow, well clear of header text

# Draw pill with frosted white fill
pill_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
pd = ImageDraw.Draw(pill_layer)
pd.rounded_rectangle(
    [pill_cx - pill_w//2 - pill_pad_x, pill_cy - pill_h//2 - pill_pad_y,
     pill_cx + pill_w//2 + pill_pad_x, pill_cy + pill_h//2 + pill_pad_y],
    radius=30,
    fill=(255, 255, 255, 200),
    outline=(150, 185, 235, 180),
    width=3
)
base = img.convert("RGBA")
base.alpha_composite(pill_layer)
img = base.convert("RGB")

draw = ImageDraw.Draw(img)
draw.text((pill_cx - pill_w // 2, pill_cy - pill_h // 2), pill_text,
          fill=(35, 55, 110), font=font_pill)

# Gradient arrow: teal-to-navy with arrowhead
# Draw as multiple passes for a glowing gradient look
arrow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
ad = ImageDraw.Draw(arrow_layer)

# Glow pass
ad.line([(arrow_x0, arrow_y), (arrow_x1 - 20, arrow_y)],
        fill=(100, 180, 255, 80), width=14)
# Main shaft
ad.line([(arrow_x0, arrow_y), (arrow_x1 - 20, arrow_y)],
        fill=(60, 140, 240, 230), width=5)

# Arrowhead (filled triangle)
head_len = 28
head_w   = 16
ax, ay = arrow_x1, arrow_y
ad.polygon(
    [(ax, ay),
     (ax - head_len, ay - head_w),
     (ax - head_len, ay + head_w)],
    fill=(40, 100, 210, 240)
)

arrow_layer = arrow_layer.filter(ImageFilter.GaussianBlur(radius=1))
base = img.convert("RGBA")
base.alpha_composite(arrow_layer)
img = base.convert("RGB")
draw = ImageDraw.Draw(img)

# ── 8. Frosted glass card at bottom ───────────────────────────────────────
# Below both bottom icon rows (icon centers at y=370 @1x = y=740 @2x)
# Card should sit well below those icons.
card_x1 = 220
card_x2 = W - 220
card_y1 = 880          # well below icons at 740
card_y2 = 1020
card_mid_x = (card_x1 + card_x2) // 2
card_mid_y = (card_y1 + card_y2) // 2

card_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
cd = ImageDraw.Draw(card_layer)
cd.rounded_rectangle(
    [card_x1, card_y1, card_x2, card_y2],
    radius=24,
    fill=(220, 230, 255, 140),
    outline=(180, 205, 245, 200),
    width=3
)
# Center divider
cd.line([(card_mid_x, card_y1 + 20), (card_mid_x, card_y2 - 20)],
        fill=(160, 185, 230, 160), width=2)

card_layer = card_layer.filter(ImageFilter.GaussianBlur(radius=4))
base = img.convert("RGBA")
base.alpha_composite(card_layer)
img = base.convert("RGB")
draw = ImageDraw.Draw(img)

# Card labels
left_label  = "Installation Guide"
right_label = "Starter Characters Pack"

lb_bbox = draw.textbbox((0, 0), left_label,  font=font_card)
rb_bbox = draw.textbbox((0, 0), right_label, font=font_card)

left_cx  = (card_x1 + card_mid_x) // 2
right_cx = (card_mid_x + card_x2) // 2

draw.text(
    (left_cx  - (lb_bbox[2] - lb_bbox[0]) // 2, card_mid_y - (lb_bbox[3] - lb_bbox[1]) // 2),
    left_label,  fill=card_color, font=font_card
)
draw.text(
    (right_cx - (rb_bbox[2] - rb_bbox[0]) // 2, card_mid_y - (rb_bbox[3] - rb_bbox[1]) // 2),
    right_label, fill=card_color, font=font_card
)

# ── 9. Bottom tip text ────────────────────────────────────────────────────
tip_text = "First launch: Right-click Animatto.app in Applications and select Open"
tip_bbox = draw.textbbox((0, 0), tip_text, font=font_tip)
tip_x = W // 2 - (tip_bbox[2] - tip_bbox[0]) // 2
tip_y = card_y2 + 22
draw.text((tip_x, tip_y), tip_text, fill=(110, 130, 180), font=font_tip)

# ── 10. Save ──────────────────────────────────────────────────────────────
bg_2x_path = os.path.join(ASSETS_DIR, "dmg_background@2x.png")
bg_1x_path = os.path.join(ASSETS_DIR, "dmg_background.png")

img.save(bg_2x_path)
# 1x version: same 2400x1600 large canvas so Finder can always tile/fit it
img.save(bg_1x_path)

print(f"Saved {bg_2x_path}")
print(f"Saved {bg_1x_path}")
print(f"Canvas: {W}x{H} — dreamy blue gradient, aurora streaks, sparkles, frosted card")
