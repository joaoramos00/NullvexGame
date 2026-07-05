#!/usr/bin/env python3
"""
Download boss animations directly from character API animation URLs.
Polls until all animations are ready (no background job IDs needed).

Usage:
  python tools/download_from_character.py <character_id> <boss_name>

Example:
  python tools/download_from_character.py 2d5d38d3-45ea-4f61-8b04-c2aeb5cbe083 cryovex
"""
import json
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    raise SystemExit("Pillow required: pip install Pillow")

BASE = "https://api.pixellab.ai/v2"


def load_key() -> str:
    env = Path(__file__).parent.parent / ".env"
    for line in env.read_text(encoding="utf-8").splitlines():
        if line.startswith("PIXELLAB_API_KEY="):
            return line.split("=", 1)[1].strip()
    raise SystemExit("PIXELLAB_API_KEY not in .env")


def fetch_url(url: str, key: str | None = None) -> bytes:
    headers = {"User-Agent": "pixellab-downloader/1.0"}
    if key:
        headers["Authorization"] = f"Bearer {key}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def get_character(char_id: str, key: str) -> dict:
    req = urllib.request.Request(
        f"{BASE}/characters/{char_id}",
        headers={"Authorization": f"Bearer {key}"},
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def wait_for_all_animations(char_id: str, key: str, expected_count: int = 3, max_polls: int = 60) -> list:
    """Poll until animation_count reaches expected_count. Returns animations list."""
    print(f"Waiting for {expected_count} animations to complete...")
    for i in range(max_polls):
        data = get_character(char_id, key)
        anims = data.get("animations", [])
        count = data.get("animation_count", len(anims))
        print(f"  [{i+1}] animations ready: {count}/{expected_count}")
        if count >= expected_count:
            print("  All animations ready!")
            return anims
        time.sleep(20)
    raise SystemExit(f"Timed out: only {count}/{expected_count} animations after {max_polls} polls")


def download_animation_frames(anim_type: str, direction: str, frame_urls: list, dest: Path, boss_name: str) -> list[str]:
    """Download frames from animation URL list. Returns list of saved file paths."""
    import io as _io

    if not frame_urls:
        print(f"  WARNING: No frames for {anim_type}/{direction}")
        return []

    frames = []
    saved_paths = []
    for i, url in enumerate(frame_urls):
        print(f"  Downloading {anim_type}_{direction} frame {i:02d}...")
        raw = fetch_url(url)
        img = Image.open(_io.BytesIO(raw)).convert("RGBA")
        frame_path = dest / f"{boss_name}_{anim_type}_{direction}_f{i:02d}.png"
        img.save(frame_path)
        saved_paths.append(str(frame_path))
        frames.append(img)

    # Save GIF
    gif_path = dest / f"{boss_name}_{anim_type}_{direction}.gif"
    frames[0].save(
        gif_path,
        save_all=True,
        append_images=frames[1:],
        loop=0,
        duration=100,
    )
    print(f"  GIF: {gif_path}")
    return saved_paths


def main() -> None:
    if len(sys.argv) < 3:
        print("Usage: python tools/download_from_character.py <character_id> <boss_name>")
        sys.exit(1)

    char_id = sys.argv[1]
    boss_name = sys.argv[2].lower()
    key = load_key()

    dest = Path("characters/bosses") / boss_name
    dest.mkdir(parents=True, exist_ok=True)

    # Wait for all 3 animations
    animations = wait_for_all_animations(char_id, key, expected_count=3)

    print(f"\nDownloading animations for {boss_name}...")
    # Each animation has animation_type + directions list
    # Structure: animations[].directions[].frames (list of URLs)
    for anim in animations:
        anim_type = anim.get("animation_type", "?")
        for dir_data in anim.get("directions", []):
            direction = dir_data.get("direction", "south")
            frame_urls = dir_data.get("frames", [])
            print(f"\n  {anim_type}/{direction}: {len(frame_urls)} frames")
            download_animation_frames(anim_type, direction, frame_urls, dest, boss_name)

    print(f"\nAll animations downloaded for {boss_name}!")


if __name__ == "__main__":
    main()
