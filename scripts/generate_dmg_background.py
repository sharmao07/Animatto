#!/usr/bin/env python3
"""
Generates high-resolution background graphics for the Animatto DMG installer.
"""

from PIL import Image, ImageDraw, ImageFont
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(SCRIPT_DIR, "assets")
os.makedirs(ASSETS_DIR, exist_ok=True)

W, H = 1400, 960  # 2x Retina for 700x480 window
img = Image.new('RGB', (W, H), color='#13151f')
draw = ImageDraw.Draw(img)

# Deep gradient
for y in range(H):
    factor = y / H
    r = int(18 + (28 - 18) * factor)
    g = int(21 + (34 - 21) * factor)
    b = int(32 + (50 - 32) * factor)
    draw.line([(0, y), (W, y)], fill=(r, g, b))

# Subtle top highlight
draw.line([(0, 0), (W, 0)], fill=(70, 85, 120))

# Fonts
font_bold = '/System/Library/Fonts/SFNS.ttf'
try:
    font_title = ImageFont.truetype(font_bold, 54)
    font_sub = ImageFont.truetype(font_bold, 28)
    font_pill = ImageFont.truetype(font_bold, 24)
    font_label = ImageFont.truetype(font_bold, 24)
    font_tip = ImageFont.truetype(font_bold, 22)
except Exception:
    font_title = font_sub = font_pill = font_label = font_tip = ImageFont.load_default()

# Title & Subtitle
title = '🐾 Animatto'
bbox = draw.textbbox((0, 0), title, font=font_title)
draw.text(((W - (bbox[2] - bbox[0])) / 2, 45), title, fill=(255, 255, 255), font=font_title)

sub = 'Desktop Companions for macOS'
bbox_s = draw.textbbox((0, 0), sub, font=font_sub)
draw.text(((W - (bbox_s[2] - bbox_s[0])) / 2, 115), sub, fill=(160, 175, 205), font=font_sub)

# Middle Drag Arrow between app (x=175*2=350, y=170*2=340) and Applications (x=525*2=1050, y=340)
arrow_y = 340
arrow_x1 = 490
arrow_x2 = 910

# 'Drag to Install' pill in center above arrow
pill_text = 'DRAG TO INSTALL'
bbox_p = draw.textbbox((0, 0), pill_text, font=font_pill)
pw = bbox_p[2] - bbox_p[0]
pill_cx = (arrow_x1 + arrow_x2) / 2
draw.rounded_rectangle([pill_cx - pw/2 - 20, arrow_y - 48, pill_cx + pw/2 + 20, arrow_y - 12], radius=14, fill=(35, 45, 65), outline=(56, 189, 248), width=2)
draw.text((pill_cx - pw/2, arrow_y - 44), pill_text, fill=(56, 189, 248), font=font_pill)

# Cyan arrow line
draw.line([(arrow_x1, arrow_y + 10), (arrow_x2, arrow_y + 10)], fill=(56, 189, 248), width=8)
# Arrow head
head = 26
draw.polygon([
    (arrow_x2 + head, arrow_y + 10),
    (arrow_x2 - head, arrow_y + 10 - head),
    (arrow_x2 - 8, arrow_y + 10),
    (arrow_x2 - head, arrow_y + 10 + head)
], fill=(56, 189, 248))

# Bottom Card Container (y from 560 to 880)
card_x1, card_y1, card_x2, card_y2 = 140, 560, W - 140, 880
draw.rounded_rectangle([card_x1, card_y1, card_x2, card_y2], radius=24, fill=(23, 26, 38), outline=(48, 58, 80), width=2)

# Divider line in middle of bottom card
draw.line([(W/2, card_y1 + 20), (W/2, card_y2 - 20)], fill=(45, 54, 74), width=2)

# Left label: under 'How to install.txt' (at x=240*2=480)
lbl_left1 = '📄 Installation Guide'
lbl_left2 = 'Read before first launch'
bbox_l1 = draw.textbbox((0, 0), lbl_left1, font=font_label)
bbox_l2 = draw.textbbox((0, 0), lbl_left2, font=font_tip)
draw.text((480 - (bbox_l1[2] - bbox_l1[0]) / 2, 805), lbl_left1, fill=(240, 245, 255), font=font_label)
draw.text((480 - (bbox_l2[2] - bbox_l2[0]) / 2, 838), lbl_left2, fill=(140, 155, 180), font=font_tip)

# Right label: under 'some characters' (at x=460*2=920)
lbl_right1 = '📁 Starter Companions'
lbl_right2 = 'Copy & import to your Mac'
bbox_r1 = draw.textbbox((0, 0), lbl_right1, font=font_label)
bbox_r2 = draw.textbbox((0, 0), lbl_right2, font=font_tip)
draw.text((920 - (bbox_r1[2] - bbox_r1[0]) / 2, 805), lbl_right1, fill=(240, 245, 255), font=font_label)
draw.text((920 - (bbox_r2[2] - bbox_r2[0]) / 2, 838), lbl_right2, fill=(140, 155, 180), font=font_tip)

# Bottom gatekeeper tip
tip = '💡 First launch: Right-click Animatto.app in Applications and select Open'
bbox_t = draw.textbbox((0, 0), tip, font=font_tip)
draw.text(((W - (bbox_t[2] - bbox_t[0])) / 2, 905), tip, fill=(130, 145, 175), font=font_tip)

# Save @2x and 1x
img.save(os.path.join(ASSETS_DIR, 'dmg_background@2x.png'))
img_1x = img.resize((700, 480), Image.Resampling.LANCZOS)
img_1x.save(os.path.join(ASSETS_DIR, 'dmg_background.png'))
print("Generated DMG background assets successfully.")
