#!/usr/bin/env python3
"""
Generates high-resolution white background with black ambient dots for the Animatto DMG installer.
Canvas size is 2400x1600 (Retina 2x for a 1200x800 coordinate space) so extending or maximizing
the Finder window displays a continuous, seamless ambient dot pattern with zero cut-offs.
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(SCRIPT_DIR, "assets")
os.makedirs(ASSETS_DIR, exist_ok=True)

W, H = 2400, 1600
S = 2  # Scale factor for Retina 2x

img = Image.new('RGB', (W, H), color='#ffffff')
draw = ImageDraw.Draw(img)

# 1. Elegant Ambient Black Dots Grid across the entire canvas
grid_spacing = 30  # 30px in 2x (15px in 1x)
dot_radius = 2.0   # 2px radius in 2x (1px in 1x)

# Focal area center is (380*S, 250*S) = (760, 500)
focal_cx, focal_cy = 760, 500

for x in range(0, W, grid_spacing):
    for y in range(0, H, grid_spacing):
        dist = math.hypot(x - focal_cx, y - focal_cy)
        
        # Ambient opacity modulation (subtle wavy variations for organic depth)
        alpha = int(28 + 12 * math.sin(x * 0.012 + y * 0.015))
        
        # Keep dots slightly lighter in the focal area so icons and text remain ultra-readable
        if dist < 450:
            factor = (dist / 450.0) * 0.6 + 0.4
            alpha = int(alpha * factor)
            
        dot_val = max(0, 255 - alpha)
        draw.ellipse([x - dot_radius, y - dot_radius, x + dot_radius, y + dot_radius],
                     fill=(dot_val, dot_val, dot_val))

# 2. Typography Fonts
font_path = '/System/Library/Fonts/SFNS.ttf'
if not os.path.exists(font_path):
    font_path = '/System/Library/Fonts/Helvetica.ttc'

font_title = ImageFont.truetype(font_path, 32 * S)
font_sub = ImageFont.truetype(font_path, 15 * S)
font_pill = ImageFont.truetype(font_path, 12 * S)
font_card_hdr = ImageFont.truetype(font_path, 13 * S)
font_tip = ImageFont.truetype(font_path, 12 * S)

# Vector Paw Print
def draw_paw(cx, cy, scale=1.0):
    pad_w, pad_h = int(18 * S * scale), int(15 * S * scale)
    draw.ellipse([cx - pad_w, cy - pad_h, cx + pad_w, cy + pad_h], fill=(30, 41, 59))
    toe_r = int(6 * S * scale)
    toes = [
        (-14 * S * scale, -16 * S * scale),
        (-5 * S * scale, -22 * S * scale),
        (5 * S * scale, -22 * S * scale),
        (14 * S * scale, -16 * S * scale),
    ]
    for tx, ty in toes:
        draw.ellipse([cx + tx - toe_r, cy + ty - toe_r, cx + tx + toe_r, cy + ty + toe_r], fill=(30, 41, 59))

# 3. Header (Centered at x = 380 * S = 760)
cx_main = 380 * S
draw_paw(cx_main - int(95 * S), int(58 * S), scale=0.9)

title_text = "Animatto"
draw.text((cx_main - int(65 * S), int(40 * S)), title_text, fill=(15, 23, 42), font=font_title)

sub_text = "Desktop Companions for macOS"
bbox_s = draw.textbbox((0, 0), sub_text, font=font_sub)
draw.text((cx_main - (bbox_s[2] - bbox_s[0]) / 2, int(82 * S)), sub_text, fill=(100, 116, 139), font=font_sub)

# 4. Drag-to-Install Arrow between App (x=190) and Applications (x=570) at y=175
arrow_y = int(175 * S)
arrow_start_x = int(280 * S)
arrow_end_x = int(480 * S)

# Center pill badge above arrow
pill_text = "DRAG TO INSTALL"
bbox_p = draw.textbbox((0, 0), pill_text, font=font_pill)
pw = bbox_p[2] - bbox_p[0]
pill_cx = (arrow_start_x + arrow_end_x) / 2
pill_top = arrow_y - int(32 * S)
pill_bot = arrow_y - int(8 * S)

draw.rounded_rectangle([pill_cx - pw/2 - 14*S, pill_top, pill_cx + pw/2 + 14*S, pill_bot],
                       radius=10*S, fill=(241, 245, 249), outline=(148, 163, 184), width=int(1.5*S))
draw.text((pill_cx - pw/2, pill_top + int(3*S)), pill_text, fill=(30, 41, 59), font=font_pill)

# Sleek Arrow
arrow_color = (30, 41, 59)
draw.line([(arrow_start_x, arrow_y + int(8*S)), (arrow_end_x, arrow_y + int(8*S))], fill=arrow_color, width=int(4*S))
head_len = int(18 * S)
draw.polygon([
    (arrow_end_x + head_len, arrow_y + int(8*S)),
    (arrow_end_x - head_len/2, arrow_y + int(8*S) - head_len),
    (arrow_end_x - int(4*S), arrow_y + int(8*S)),
    (arrow_end_x - head_len/2, arrow_y + int(8*S) + head_len)
], fill=arrow_color)

# 5. Bottom Section Card (Card around bottom files)
card_x1 = int(140 * S)
card_x2 = int(620 * S)
card_y1 = int(285 * S)
card_y2 = int(445 * S)

draw.rounded_rectangle([card_x1, card_y1, card_x2, card_y2], radius=16*S,
                       fill=(248, 250, 252), outline=(226, 232, 240), width=int(1.5*S))

# Divider line in middle of card
draw.line([(cx_main, card_y1 + int(12*S)), (cx_main, card_y2 - int(12*S))], fill=(226, 232, 240), width=int(1.5*S))

# Section Headers placed ABOVE the icons (at y=300) so Finder file names underneath never collide!
hdr_left = "Installation Guide"
bbox_hl = draw.textbbox((0, 0), hdr_left, font=font_card_hdr)
draw.text((int(265*S) - (bbox_hl[2] - bbox_hl[0])/2, card_y1 + int(14*S)), hdr_left, fill=(51, 65, 85), font=font_card_hdr)

hdr_right = "Starter Characters Pack"
bbox_hr = draw.textbbox((0, 0), hdr_right, font=font_card_hdr)
draw.text((int(495*S) - (bbox_hr[2] - bbox_hr[0])/2, card_y1 + int(14*S)), hdr_right, fill=(51, 65, 85), font=font_card_hdr)

# 6. Bottom Tip
tip_text = "Tip: Right-click Animatto.app in Applications and select Open on first launch"
bbox_t = draw.textbbox((0, 0), tip_text, font=font_tip)
draw.text((cx_main - (bbox_t[2] - bbox_t[0])/2, int(465 * S)), tip_text, fill=(100, 116, 139), font=font_tip)

# Save @2x Retina and 1x standard images
bg_2x_path = os.path.join(ASSETS_DIR, 'dmg_background@2x.png')
bg_1x_path = os.path.join(ASSETS_DIR, 'dmg_background.png')

img.save(bg_2x_path)
img.save(bg_1x_path)
print(f"Generated {bg_1x_path} and {bg_2x_path} ({W}x{H}) successfully.")
