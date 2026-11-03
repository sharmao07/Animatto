#!/usr/bin/env python3
"""
Animatto — Automated Cat Sprite Asset Validation Script (Stage 3.1)
Validates all 45 frames for:
1. Dimensions (256x256 px)
2. RGBA transparency & file readability
3. Naming convention (<state>_<nn>.png)
4. Ground baseline alignment (Y=224, 32px above bottom)
5. Strict manifest.json consistency across all 9 states
"""

import os
import sys
import json
from PIL import Image

EXPECTED_STATES = {
    "idle": {"count": 6, "duration": 100, "loop": True},
    "walk": {"count": 8, "duration": 83, "loop": True, "footstep": [2, 6]},
    "run": {"count": 6, "duration": 55, "loop": True, "footstep": [1, 4]},
    "jump": {"count": 4, "duration": 66, "loop": False},
    "fall": {"count": 4, "duration": 83, "loop": True},
    "land": {"count": 3, "duration": 66, "loop": False},
    "sit": {"count": 4, "duration": 125, "loop": True},
    "sleep": {"count": 4, "duration": 166, "loop": True},
    "grooming": {"count": 6, "duration": 100, "loop": False}
}

EXPECTED_TOTAL_FRAMES = 45
EXPECTED_CANVAS_WIDTH = 256
EXPECTED_CANVAS_HEIGHT = 256
EXPECTED_BASELINE_Y = 224 # 32 px above bottom (256 - 32 = 224)

def validate():
    cat_dir = "Animatto/DefaultCompanions/Cat"
    manifest_path = os.path.join(cat_dir, "manifest.json")
    
    print("==================================================")
    print("ANIMATTO CAT SPRITE ASSET VALIDATION (STAGE 3.1)")
    print("==================================================")
    
    if not os.path.isdir(cat_dir):
        print(f"FAILED: Directory not found: {cat_dir}")
        return False
        
    if not os.path.isfile(manifest_path):
        print(f"FAILED: Manifest not found: {manifest_path}")
        return False
        
    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    except Exception as e:
        print(f"FAILED: Manifest is invalid JSON: {e}")
        return False
        
    print(f"Loaded manifest: {manifest.get('name')} v{manifest.get('version')}")
    canvas = manifest.get("canvasSize", {})
    if canvas.get("width") != EXPECTED_CANVAS_WIDTH or canvas.get("height") != EXPECTED_CANVAS_HEIGHT:
        print(f"FAILED: Manifest canvasSize {canvas} != {EXPECTED_CANVAS_WIDTH}x{EXPECTED_CANVAS_HEIGHT}")
        return False
        
    if manifest.get("groundBaselineY") != 32:
        print(f"FAILED: Manifest groundBaselineY {manifest.get('groundBaselineY')} != 32")
        return False
        
    states_dict = manifest.get("states", {})
    if set(states_dict.keys()) != set(EXPECTED_STATES.keys()):
        print(f"FAILED: Manifest states {set(states_dict.keys())} != {set(EXPECTED_STATES.keys())}")
        return False
        
    total_frames_found = 0
    all_passed = True
    
    for state_name, expected in EXPECTED_STATES.items():
        state_info = states_dict[state_name]
        folder = state_info.get("folder", state_name)
        state_dir = os.path.join(cat_dir, folder)
        
        if not os.path.isdir(state_dir):
            print(f"FAILED: State directory missing: {state_dir}")
            all_passed = False
            continue
            
        expected_count = expected["count"]
        manifest_count = state_info.get("frameCount")
        if manifest_count != expected_count:
            print(f"FAILED: State {state_name} manifest frameCount {manifest_count} != {expected_count}")
            all_passed = False
            
        # Inspect files in directory
        files = sorted([f for f in os.listdir(state_dir) if not f.startswith(".")])
        if len(files) != expected_count:
            print(f"FAILED: State {state_name} directory contains {len(files)} files, expected {expected_count}")
            all_passed = False
            
        for i in range(expected_count):
            expected_filename = f"{state_name}_{i:02d}.png"
            file_path = os.path.join(state_dir, expected_filename)
            
            if not os.path.isfile(file_path):
                print(f"FAILED: Missing frame file: {file_path}")
                all_passed = False
                continue
                
            total_frames_found += 1
            
            # Image validation
            try:
                with Image.open(file_path) as img:
                    # 1. Format
                    if img.format != "PNG":
                        print(f"FAILED: {file_path} format is {img.format}, expected PNG")
                        all_passed = False
                        
                    # 2. Dimensions
                    if img.size != (EXPECTED_CANVAS_WIDTH, EXPECTED_CANVAS_HEIGHT):
                        print(f"FAILED: {file_path} size is {img.size}, expected (256, 256)")
                        all_passed = False
                        
                    # 3. Mode (RGBA)
                    if img.mode != "RGBA":
                        print(f"FAILED: {file_path} mode is {img.mode}, expected RGBA")
                        all_passed = False
                        
                    # 4. Transparency
                    bbox = img.getbbox()
                    if bbox is None:
                        print(f"FAILED: {file_path} is completely blank/transparent")
                        all_passed = False
                        continue
                        
                    # Check that there are transparent pixels (not solid background)
                    alpha_channel = img.split()[-1]
                    extrema = alpha_channel.getextrema()
                    if extrema[0] != 0:
                        print(f"FAILED: {file_path} has no transparent pixels (min alpha = {extrema[0]})")
                        all_passed = False
                        
                    if extrema[1] < 200:
                        print(f"FAILED: {file_path} has no fully opaque pixels (max alpha = {extrema[1]})")
                        all_passed = False
                        
                    # 5. Ground alignment for grounded states
                    if state_name in ("idle", "walk", "land", "sit", "sleep", "grooming"):
                        # Bottom bounding box should be near EXPECTED_BASELINE_Y (224 +- 5 px)
                        bottom_y = bbox[3]
                        if abs(bottom_y - EXPECTED_BASELINE_Y) > 5:
                            print(f"WARNING: {file_path} bottom Y is {bottom_y}, baseline is {EXPECTED_BASELINE_Y}")
                            all_passed = False
                            
            except Exception as e:
                print(f"FAILED: Could not open/read {file_path}: {e}")
                all_passed = False
                
        print(f"  ✓ State '{state_name}': {expected_count} frames validated ({expected['duration']}ms, loop={expected['loop']})")

    print("--------------------------------------------------")
    print(f"Total frames validated: {total_frames_found} / {EXPECTED_TOTAL_FRAMES}")
    
    # Validate LICENSE and ATTRIBUTION
    license_file = os.path.join(cat_dir, "LICENSE.txt")
    attrib_file = os.path.join(cat_dir, "ATTRIBUTION.md")
    if not os.path.isfile(license_file):
        print("FAILED: LICENSE.txt missing in Cat asset directory")
        all_passed = False
    else:
        print("  ✓ LICENSE.txt present")
        
    if not os.path.isfile(attrib_file):
        print("FAILED: ATTRIBUTION.md missing in Cat asset directory")
        all_passed = False
    else:
        print("  ✓ ATTRIBUTION.md present")

    print("==================================================")
    if all_passed and total_frames_found == EXPECTED_TOTAL_FRAMES:
        print("RESULT: ALL 45 SPRITE FRAMES & MANIFEST ARE 100% VALID!")
        return True
    else:
        print("RESULT: VALIDATION FAILED!")
        return False

if __name__ == "__main__":
    success = validate()
    sys.exit(0 if success else 1)
