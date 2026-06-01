#!/usr/bin/env python3
"""Download Commander Vex animation frames from PixelLab zip and stitch sprite sheets.

Frame 000 in each animation is the reference pose — skipped.
Animated frames start at frame_001.
Output: characters/bosses/intro_boss/intro_boss_{action}.png (horizontal strip)
"""
import json, urllib.request, io, zipfile
from pathlib import Path
from PIL import Image

BASE_REST = "https://api.pixellab.ai/v2"
CHAR_ID   = "2291f98f-dd2c-4d1a-bae1-b9f21afaa8fa"
OUT_DIR   = Path("characters/bosses/intro_boss")

EXPECTED_FRAMES = {"idle": 4, "walk": 6, "dash": 6, "shoot": 6}


def load_key() -> str:
    env = Path(__file__).parent.parent / ".env"
    for line in env.read_text(encoding="utf-8").splitlines():
        if line.startswith("PIXELLAB_API_KEY="):
            return line.split("=", 1)[1].strip()
    raise SystemExit("PIXELLAB_API_KEY not in .env")


def fetch(url: str, key: str) -> bytes:
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def main() -> None:
    key = load_key()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Get character data to map animation_group_id → animation_type
    char_data = json.loads(fetch(f"{BASE_REST}/characters/{CHAR_ID}", key))
    group_to_type: dict[str, str] = {}
    for anim in char_data.get("animations", []):
        gid = anim["animation_group_id"].replace("-", "")[:8]  # first 8 hex chars
        group_to_type[gid] = anim["animation_type"]
    print(f"Animation groups: {group_to_type}")

    # Download zip
    print("Downloading character zip...")
    raw_zip = fetch(f"{BASE_REST}/characters/{CHAR_ID}/zip", key)
    print(f"Zip size: {len(raw_zip) // 1024} KB")

    # Group frames by animation type, skip frame_000 (reference pose)
    anim_frames: dict[str, list[tuple[str, bytes]]] = {k: [] for k in EXPECTED_FRAMES}

    with zipfile.ZipFile(io.BytesIO(raw_zip)) as z:
        for member in sorted(z.namelist()):
            if "animations/" not in member or not member.endswith(".png"):
                continue
            parts = member.split("/")
            # parts: [char_folder, "animations", anim_folder, direction, frame_file]
            if len(parts) < 5:
                continue
            anim_folder = parts[2]   # e.g. "aggressive_dash_...-a67ce1e3"
            direction   = parts[3]   # "west"
            frame_file  = parts[4]   # "frame_000.png"
            if direction != "west":
                continue
            if frame_file == "frame_000.png":
                continue  # skip reference pose
            # Match by group ID suffix (last 8 chars of folder name)
            folder_suffix = anim_folder.split("-")[-1]  # e.g. "a67ce1e3"
            anim_type = group_to_type.get(folder_suffix)
            if anim_type not in anim_frames:
                continue
            anim_frames[anim_type].append((frame_file, z.read(member)))

    # Stitch sprite sheets
    for action, expected in EXPECTED_FRAMES.items():
        frames_data = anim_frames[action]
        if not frames_data:
            print(f"  MISSING frames for {action}")
            continue
        if len(frames_data) != expected:
            print(f"  WARNING {action}: expected {expected}, got {len(frames_data)}")

        images = [Image.open(io.BytesIO(raw)).convert("RGBA") for _, raw in frames_data]
        w, h = images[0].size
        sheet = Image.new("RGBA", (w * len(images), h), (0, 0, 0, 0))
        for i, img in enumerate(images):
            sheet.paste(img, (i * w, 0))

        out_path = OUT_DIR / f"intro_boss_{action}.png"
        sheet.save(out_path)
        print(f"  {action}: {out_path}  ({len(images)} frames, {w}×{h}px each)")

    print("\nDone.")


if __name__ == "__main__":
    main()
