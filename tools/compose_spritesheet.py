#!/usr/bin/env python3
"""Compõe frames individuais de animação PixelLab em sprite sheet horizontal."""
import sys
from pathlib import Path
from PIL import Image


def main() -> None:
    if len(sys.argv) != 4:
        print("Usage: compose_spritesheet.py <name> <action> <direction>")
        print("  action:    walk | entry")
        print("  direction: west | east | south")
        sys.exit(1)

    name, action, direction = sys.argv[1], sys.argv[2], sys.argv[3]

    # Validate action parameter
    if action not in ("walk", "entry"):
        print(f"ERROR: action must be 'walk' or 'entry', got '{action}'")
        sys.exit(1)

    folder = Path("characters/bosses") / name
    # Ensure output directory exists
    folder.mkdir(parents=True, exist_ok=True)

    frame_count = 8 if action == "walk" else 6

    frames = []
    for i in range(frame_count):
        p = folder / f"{name}_{action}_{direction}_f{i:02d}.png"
        if not p.exists():
            print(f"ERROR: {p} not found")
            sys.exit(1)
        # Use context manager to properly close file handles
        with Image.open(p) as img:
            frames.append(img.convert("RGBA"))

    w, h = frames[0].size
    # Validate all frames have consistent dimensions
    for i, frame in enumerate(frames[1:], 1):
        if frame.size != (w, h):
            print(f"ERROR: Frame {i} has size {frame.size}, expected ({w}, {h})")
            sys.exit(1)

    sheet = Image.new("RGBA", (w * frame_count, h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * w, 0))

    out = folder / (f"{name}_entry.png" if action == "entry" else f"{name}_{action}_{direction}.png")
    sheet.save(out)
    print(f"Saved: {out}  ({w * frame_count}x{h}, {frame_count} frames)")


if __name__ == "__main__":
    main()
