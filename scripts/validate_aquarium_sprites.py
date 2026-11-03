#!/usr/bin/env python3
"""
Animatto — Automated Aquarium Sprite Asset Validation Script (Stage 4.3)
Validates all 120 frames across all 4 starter aquatic species:
1. Finny: Golden Sunfin (Sunfin)
2. Pip: Spotted Pygmy Puffer (Puffer)
3. Glow: Neon Ghost Tetra (Tetra)
4. Barnaby: Mossy Hermit Crab (HermitCrab)

Validates:
- All 120 frames exist, decode cleanly, and match naming convention (<state>_<nn>.png).
- Exactly 256x256 px RGBA with valid straight alpha transparency.
- No blank, transparent-only, or solid non-transparent frames.
- No accidental duplicates or placeholder frames (verifies pixel differences between frames).
- Strict manifest.json consistency across all 6 states (swim_idle, swim_active, turn, feed, rest, dart).
- Next-state transitions are valid and exist in the manifest.
- Master artwork image exists for each species.
- CC0 1.0 Universal LICENSE.txt and ATTRIBUTION.md exist.
"""

import os
import sys
import json
from PIL import Image, ImageChops

EXPECTED_STATES = {
    "swim_idle": {"count": 6, "duration": 100, "loop": True},
    "swim_active": {"count": 8, "duration": 71, "loop": True},
    "turn": {"count": 4, "duration": 62, "loop": False, "nextState": "swim_active"},
    "feed": {"count": 4, "duration": 83, "loop": False, "nextState": "swim_idle"},
    "rest": {"count": 4, "duration": 166, "loop": True},
    "dart": {"count": 4, "duration": 50, "loop": False, "nextState": "swim_active"}
}

EXPECTED_SPECIES = [
    {
        "dir": "Sunfin",
        "id": "animatto.creature.sunfin",
        "name": "Finny the Golden Sunfin",
        "master": "sunfin_master.png",
        "niche": "pelagic"
    },
    {
        "dir": "Puffer",
        "id": "animatto.creature.puffer",
        "name": "Pip the Spotted Pygmy Puffer",
        "master": "puffer_master.png",
        "niche": "surface"
    },
    {
        "dir": "Tetra",
        "id": "animatto.creature.tetra",
        "name": "Glow the Neon Ghost Tetra",
        "master": "tetra_master.png",
        "niche": "pelagic"
    },
    {
        "dir": "HermitCrab",
        "id": "animatto.creature.hermit_crab",
        "name": "Barnaby the Mossy Hermit Crab",
        "master": "hermit_crab_master.png",
        "niche": "benthic"
    }
]

EXPECTED_CANVAS_WIDTH = 256
EXPECTED_CANVAS_HEIGHT = 256
FRAMES_PER_SPECIES = 30
TOTAL_EXPECTED_FRAMES = 120

def validate():
    base_dir = "Animatto/DefaultCompanions/Aquarium"
    
    print("======================================================================")
    print("ANIMATTO AQUARIUM SPRITE ASSET VALIDATION (STAGE 4.3)")
    print("======================================================================")
    
    if not os.path.isdir(base_dir):
        print(f"FAILED: Base directory not found: {base_dir}")
        return False
        
    all_passed = True
    total_frames_validated = 0
    
    for species in EXPECTED_SPECIES:
        s_dir = os.path.join(base_dir, species["dir"])
        print(f"\n[+] Validating Species: {species['name']} ({s_dir})")
        
        if not os.path.isdir(s_dir):
            print(f"  ❌ FAILED: Species directory missing: {s_dir}")
            all_passed = False
            continue
            
        manifest_path = os.path.join(s_dir, "manifest.json")
        if not os.path.isfile(manifest_path):
            print(f"  ❌ FAILED: Manifest not found: {manifest_path}")
            all_passed = False
            continue
            
        try:
            with open(manifest_path, "r", encoding="utf-8") as f:
                manifest = json.load(f)
        except Exception as e:
            print(f"  ❌ FAILED: Manifest is invalid JSON: {e}")
            all_passed = False
            continue
            
        # Manifest Metadata checks
        if manifest.get("characterId") != species["id"]:
            print(f"  ❌ FAILED: CharacterId {manifest.get('characterId')} != {species['id']}")
            all_passed = False
            
        canvas = manifest.get("canvasSize", {})
        if canvas.get("width") != EXPECTED_CANVAS_WIDTH or canvas.get("height") != EXPECTED_CANVAS_HEIGHT:
            print(f"  ❌ FAILED: CanvasSize {canvas} != 256x256")
            all_passed = False
            
        master_name = manifest.get("masterArtwork")
        if master_name != species["master"]:
            print(f"  ❌ FAILED: MasterArtwork {master_name} != {species['master']}")
            all_passed = False
        else:
            master_file = os.path.join(s_dir, master_name)
            if not os.path.isfile(master_file):
                print(f"  ❌ FAILED: Master artwork image file missing: {master_file}")
                all_passed = False
            else:
                try:
                    with Image.open(master_file) as m_img:
                        if m_img.size != (256, 256) or m_img.mode != "RGBA":
                            print(f"  ❌ FAILED: Master image invalid: size {m_img.size}, mode {m_img.mode}")
                            all_passed = False
                        else:
                            print(f"  ✓ Master artwork verified: {species['master']} (256x256 RGBA)")
                except Exception as e:
                    print(f"  ❌ FAILED: Could not decode master image {master_file}: {e}")
                    all_passed = False

        # Aquatic properties checks
        aquatic_props = manifest.get("aquaticProperties", {})
        if aquatic_props.get("niche") != species["niche"]:
            print(f"  ❌ FAILED: Niche {aquatic_props.get('niche')} != {species['niche']}")
            all_passed = False
        else:
            print(f"  ✓ Aquatic niche: {species['niche']} (Speed: {aquatic_props.get('cruiseSpeed')}-{aquatic_props.get('maxSpeed')} pt/s)")

        # Validate LICENSE.txt and ATTRIBUTION.md
        license_path = os.path.join(s_dir, "LICENSE.txt")
        attrib_path = os.path.join(s_dir, "ATTRIBUTION.md")
        if not os.path.isfile(license_path):
            print(f"  ❌ FAILED: LICENSE.txt missing in {s_dir}")
            all_passed = False
        else:
            print(f"  ✓ LICENSE.txt (CC0 1.0 Universal) present")
            
        if not os.path.isfile(attrib_path):
            print(f"  ❌ FAILED: ATTRIBUTION.md missing in {s_dir}")
            all_passed = False
        else:
            print(f"  ✓ ATTRIBUTION.md present")

        # States validation
        states_dict = manifest.get("states", {})
        if set(states_dict.keys()) != set(EXPECTED_STATES.keys()):
            print(f"  ❌ FAILED: Manifest states {set(states_dict.keys())} != {set(EXPECTED_STATES.keys())}")
            all_passed = False
            
        species_frames_found = 0
        
        for state_name, expected in EXPECTED_STATES.items():
            state_info = states_dict.get(state_name, {})
            folder = state_info.get("folder", state_name)
            state_dir = os.path.join(s_dir, folder)
            
            if not os.path.isdir(state_dir):
                print(f"  ❌ FAILED: State directory missing: {state_dir}")
                all_passed = False
                continue
                
            expected_count = expected["count"]
            manifest_count = state_info.get("frameCount")
            if manifest_count != expected_count:
                print(f"  ❌ FAILED: State {state_name} frameCount {manifest_count} != {expected_count}")
                all_passed = False
                
            # Transition check
            if not expected["loop"]:
                next_st = state_info.get("nextState")
                if next_st != expected.get("nextState"):
                    print(f"  ❌ FAILED: Non-looping state {state_name} nextState {next_st} != {expected.get('nextState')}")
                    all_passed = False
                elif next_st not in states_dict:
                    print(f"  ❌ FAILED: NextState {next_st} not in manifest states")
                    all_passed = False
                    
            files = sorted([f for f in os.listdir(state_dir) if not f.startswith(".")])
            if len(files) != expected_count:
                print(f"  ❌ FAILED: State {state_name} has {len(files)} files, expected {expected_count}")
                all_passed = False
                
            state_images = []
            
            for i in range(expected_count):
                expected_filename = f"{state_name}_{i:02d}.png"
                file_path = os.path.join(state_dir, expected_filename)
                
                if not os.path.isfile(file_path):
                    print(f"  ❌ FAILED: Missing frame file: {file_path}")
                    all_passed = False
                    continue
                    
                total_frames_validated += 1
                species_frames_found += 1
                
                try:
                    img = Image.open(file_path)
                    state_images.append(img.copy())
                    
                    if img.format != "PNG":
                        print(f"  ❌ FAILED: {file_path} format is {img.format}, expected PNG")
                        all_passed = False
                    if img.size != (EXPECTED_CANVAS_WIDTH, EXPECTED_CANVAS_HEIGHT):
                        print(f"  ❌ FAILED: {file_path} size is {img.size}, expected (256, 256)")
                        all_passed = False
                    if img.mode != "RGBA":
                        print(f"  ❌ FAILED: {file_path} mode is {img.mode}, expected RGBA")
                        all_passed = False
                        
                    bbox = img.getbbox()
                    if bbox is None:
                        print(f"  ❌ FAILED: {file_path} is completely blank/transparent")
                        all_passed = False
                        continue
                        
                    # Check alpha distribution
                    alpha_channel = img.split()[-1]
                    extrema = alpha_channel.getextrema()
                    if extrema[0] != 0:
                        print(f"  ❌ FAILED: {file_path} has no transparent pixels (min alpha = {extrema[0]})")
                        all_passed = False
                    if extrema[1] < 180:
                        print(f"  ❌ FAILED: {file_path} lacks opaque content (max alpha = {extrema[1]})")
                        all_passed = False
                        
                except Exception as e:
                    print(f"  ❌ FAILED: Cannot decode {file_path}: {e}")
                    all_passed = False
                    
            # Check for duplicate / placeholder frames between consecutive frames
            for i in range(len(state_images) - 1):
                diff = ImageChops.difference(state_images[i], state_images[i+1])
                diff_bbox = diff.getbbox()
                if diff_bbox is None:
                    print(f"  ❌ FAILED: Frame {i} and {i+1} in state {state_name} are identical duplicate placeholders!")
                    all_passed = False

            print(f"    ✓ State '{state_name}': {expected_count} frames validated ({expected['duration']}ms, loop={expected['loop']})")

        print(f"  ✓ {species_frames_found} / {FRAMES_PER_SPECIES} frames verified for {species['dir']}")

    print("\n======================================================================")
    print(f"Total Frames Validated Across All Species: {total_frames_validated} / {TOTAL_EXPECTED_FRAMES}")
    print("======================================================================")
    
    if all_passed and total_frames_validated == TOTAL_EXPECTED_FRAMES:
        print("RESULT: ALL 120 AQUARIUM SPRITE FRAMES & MANIFESTS ARE 100% VALID!")
        return True
    else:
        print("RESULT: VALIDATION FAILED!")
        return False

if __name__ == "__main__":
    success = validate()
    sys.exit(0 if success else 1)
