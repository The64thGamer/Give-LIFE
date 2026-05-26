#!/usr/bin/env python3
"""
Split Cutout.json into one .json file per GLB animatronic.
Usage: python split_json.py Cutout.json [output_dir]
"""

import json
import sys
import os

# Maps each JSON key -> which GLB file it belongs to
KEY_TO_GLB = {
    # Direct matches
    "Bee":           "Bee",
    "Clam":          "Clam",
    "Comedy":        "Comedy",
    "Coral":         "Coral",
    "Dragonfly":     "Dragonfly",
    "Fish":          "Fish",
    "Frog Cutout":   "Frog Cutout",
    "Hanging Cloud": "Hanging Cloud",
    "King Frog":     "King Frog",
    "Lion":          "Lion",
    "Palm Tree":     "Palm Tree",
    "Shark":         "Shark",
    "Snail":         "Snail",
    "Squirrel":      "Squirrel",
    "Starfish":      "Starfish",
    "Tragedy":       "Tragedy",
    "Turtle":        "Turtle",

    # Renamed/abbreviated
    "Mice":          "Balloon Mice",
    "Cotton Candy":  "Cotton Candy Sheep",
    "Popcorn":       "Popcorn Sheep",
    "Snake":         "Purple Snake",
    "Seal Tail":     "Seal Bucket",

    # Sub-parts of Hanging Cloud
    "Cloud L":       "Hanging Cloud",
    "Cloud R":       "Hanging Cloud",

    # Sub-parts of Sun Moons
    "Moon L":        "Sun Moons",
    "Moon R":        "Sun Moons",
    "Sun":           "Sun Moons",
    "Star 1 L":      "Sun Moons",
    "Star 1 R":      "Sun Moons",
    "Star 2 L":      "Sun Moons",
    "Star 2 R":      "Sun Moons",
    "Star 3 R":      "Sun Moons",

    # Blue Balloon animations shared across multiple GLBs
    "Blue Balloon":      "Blue Balloon Dog",
    "Blue Balloon_001":  "Blue Balloon Dog",

    # Balloon dogs and others that share the Blue Balloon animation
    # (duplicated into each GLB's own json)
    # handled separately below via SHARED_BALLOON_GLBS

    # Crab sub-part
    "Chest":         "Crab",

    # Birds Nest sub-parts
    "Baby Bird L":   "Birds Nest",
    "Baby Bird R":   "Birds Nest",
    "Mother Bird":   "Birds Nest",

    # Flower Wagon sub-parts
    "Ballora":       "Flower Wagon",
    "David":         "Flower Wagon",
    "Elizabeth":     "Flower Wagon",
    "Michael":       "Flower Wagon",
    "William":       "Flower Wagon",
}

# These GLBs all share the same Blue Balloon / Blue Balloon_001 entries
SHARED_BALLOON_GLBS = [
    "Blue Balloon Dog",
    "Green Balloon Dog",
    "Orange Balloon Dog",
    "Red Balloon Dog",
    "Snail",
    "Present Cutout",
]


def main():
    if len(sys.argv) < 2:
        print("Usage: python split_json.py <input.json> [output_dir]")
        sys.exit(1)

    input_path = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.dirname(input_path) or "."
    os.makedirs(output_dir, exist_ok=True)

    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Build per-GLB dicts
    glb_data = {}

    for key, entry in data.items():
        glb = KEY_TO_GLB.get(key)
        if glb is None:
            print(f"  WARNING: no GLB mapping for key '{key}', skipping.")
            continue
        glb_data.setdefault(glb, {})[key] = entry

    # Duplicate balloon entries into the other balloon-dog GLBs
    balloon_entries = glb_data.get("Blue Balloon Dog", {})
    for glb in SHARED_BALLOON_GLBS:
        if glb == "Blue Balloon Dog":
            continue
        glb_data.setdefault(glb, {}).update(balloon_entries)

    # Write one file per GLB
    for glb, entries in sorted(glb_data.items()):
        out_path = os.path.join(output_dir, f"{glb}.json")
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(entries, f, indent=2)
        print(f"  Written: {out_path}  ({len(entries)} entries)")

    print(f"Done. {len(glb_data)} files written.")


if __name__ == "__main__":
    main()
