#!/usr/bin/env python3
"""
Prepares the multi-resolution DMG background for Animatto.
Uses the high-resolution dreamy blue/lavender aesthetic background design (1024x682),
generates 1x and 2x Retina PNG assets, and combines them using macOS tiffutil into a
multi-resolution TIFF image (dmg_background.tiff) for native HiDPI Finder support.
"""

import os
import subprocess
import sys
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(SCRIPT_DIR, "assets")
os.makedirs(ASSETS_DIR, exist_ok=True)

SOURCE_PATH = os.path.join(ASSETS_DIR, "dmg_background_source.png")
OUT_1X_PATH = os.path.join(ASSETS_DIR, "dmg_background.png")
OUT_2X_PATH = os.path.join(ASSETS_DIR, "dmg_background@2x.png")
OUT_TIFF_PATH = os.path.join(ASSETS_DIR, "dmg_background.tiff")

def main():
    if not os.path.exists(SOURCE_PATH):
        print(f"Error: Source artwork not found at {SOURCE_PATH}", file=sys.stderr)
        sys.exit(1)

    print(f"Loading source artwork from {SOURCE_PATH}...")
    im = Image.open(SOURCE_PATH).convert("RGBA")
    w, h = im.size
    print(f"Source artwork dimensions: {w} x {h}")

    # 1. 1x image (1024 x 682)
    im_1x = im.copy()
    im_1x.save(OUT_1X_PATH, dpi=(72, 72))
    print(f"Saved 1x background ({im_1x.width}x{im_1x.height}) to {OUT_1X_PATH}")

    # 2. 2x Retina image (2048 x 1364)
    im_2x = im.resize((w * 2, h * 2), Image.Resampling.LANCZOS)
    im_2x.save(OUT_2X_PATH, dpi=(72, 72))
    print(f"Saved 2x Retina background ({im_2x.width}x{im_2x.height}) to {OUT_2X_PATH}")

    # 3. Multi-resolution TIFF using macOS tiffutil
    cmd = ["tiffutil", "-cathidpicheck", OUT_1X_PATH, OUT_2X_PATH, "-out", OUT_TIFF_PATH]
    print(f"Generating multi-resolution TIFF via tiffutil...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"tiffutil failed: {result.stderr}", file=sys.stderr)
        sys.exit(result.returncode)

    print(f"Successfully created {OUT_TIFF_PATH}")
    print("Multi-resolution DMG background ready.")

if __name__ == "__main__":
    main()
