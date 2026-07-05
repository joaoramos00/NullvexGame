#!/usr/bin/env python3
"""
Complete boss pipeline: download sprites + animations from character API.
Polls until everything is done, then composes sprite sheets.

Usage:
  python tools/boss_pipeline.py <character_id> <boss_name>

Example:
  python tools/boss_pipeline.py 38179eb2-0e34-486a-bf0c-756214158ee7 voltrix
"""
import json
import sys
import time
import io
import urllib.request
import urllib.error
import subprocess
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


def fetch_url(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "pixellab-downloader/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def get_character(char_id: str, key: str) -> dict:
    req = urllib.request.Request(
        f"{BASE}/characters/{char_id}",
        headers={"Authorization": f"Bearer {key}"},
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def download_char_sprites(char_id: str, dest: Path, boss_name: str, key: str) -> None:
    """Download character rotation sprites via ZIP endpoint."""
    import zipfile
    print(f"  Downloading character sprites...")
    # Poll until ZIP is accessible
    for attempt in range(40):
        try:
            req = urllib.request.Request(
                f"{BASE}/characters/{char_id}/zip",
                headers={"Authorization": f"Bearer {key}"},
            )
            with urllib.request.urlopen(req, timeout=60) as r:
                raw = r.read()
            with zipfile.ZipFile(io.BytesIO(raw)) as z:
                for member in z.namelist():
                    if not member.endswith(".png") or "rotations/" not in member:
                        continue
                    direction = Path(member).stem
                    target = dest / f"{boss_name}_{direction}.png"
                    if not target.exists():
                        target.write_bytes(z.read(member))
                        print(f"    Saved: {target}")
                    else:
                        print(f"    Already exists: {target}")
            return
        except urllib.error.HTTPError as e:
            if e.code == 423:
                print(f"    [{attempt+1}] ZIP not ready (423), waiting 15s...")
                time.sleep(15)
            else:
                raise
    raise SystemExit(f"Timeout waiting for ZIP for {char_id}")


def download_anim_frames(anim_type: str, direction: str, frame_urls: list, dest: Path, boss_name: str) -> None:
    """Download individual animation frames."""
    frames = []
    for i, url in enumerate(frame_urls):
        p = dest / f"{boss_name}_{anim_type}_{direction}_f{i:02d}.png"
        if p.exists():
            with Image.open(p) as img:
                frames.append(img.convert("RGBA"))
            continue
        print(f"    Downloading {anim_type}_{direction} frame {i:02d}...")
        raw = fetch_url(url)
        img = Image.open(io.BytesIO(raw)).convert("RGBA")
        img.save(p)
        frames.append(img)

    gif_p = dest / f"{boss_name}_{anim_type}_{direction}.gif"
    if not gif_p.exists() and frames:
        frames[0].save(gif_p, save_all=True, append_images=frames[1:], loop=0, duration=100)
        print(f"    GIF: {gif_p}")


def wait_and_download_animations(char_id: str, dest: Path, boss_name: str, key: str, expected_count: int = 3) -> None:
    """Poll until all animations complete, then download frames."""
    print(f"  Waiting for {expected_count} animations...")
    downloaded = set()

    for attempt in range(60):
        data = get_character(char_id, key)
        anims = data.get("animations", [])
        count = data.get("animation_count", len(anims))
        print(f"  [{attempt+1}] animations ready: {count}/{expected_count}")

        # Download any newly completed animations
        for anim in anims:
            anim_type = anim.get("animation_type", "?")
            for dir_data in anim.get("directions", []):
                direction = dir_data.get("direction", "?")
                key_str = f"{anim_type}_{direction}"
                if key_str not in downloaded:
                    frame_urls = dir_data.get("frames", [])
                    if frame_urls:
                        print(f"  Downloading {anim_type}/{direction} ({len(frame_urls)} frames)...")
                        download_anim_frames(anim_type, direction, frame_urls, dest, boss_name)
                        downloaded.add(key_str)

        if count >= expected_count:
            print(f"  All {expected_count} animations complete!")
            return
        time.sleep(20)

    raise SystemExit(f"Timeout: only {len(downloaded)}/{expected_count} animations after 60 polls")


def compose_sheets(boss_name: str) -> None:
    """Compose sprite sheets."""
    print(f"  Composing sprite sheets...")
    for action, direction in [("walk", "west"), ("walk", "east"), ("entry", "south")]:
        result = subprocess.run(
            ["python", "tools/compose_spritesheet.py", boss_name, action, direction],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"    ERROR composing {action} {direction}: {result.stderr}")
        else:
            print(f"    {result.stdout.strip()}")


def main() -> None:
    if len(sys.argv) < 3:
        print("Usage: python tools/boss_pipeline.py <character_id> <boss_name>")
        sys.exit(1)

    char_id = sys.argv[1]
    boss_name = sys.argv[2].lower()
    key = load_key()

    dest = Path("characters/bosses") / boss_name
    dest.mkdir(parents=True, exist_ok=True)

    print(f"\n=== Processing {boss_name} (char: {char_id}) ===")

    # Step 1: Download character sprites
    if not (dest / f"{boss_name}_south.png").exists():
        download_char_sprites(char_id, dest, boss_name, key)
    else:
        print(f"  Character sprites already downloaded")

    # Step 2: Wait for and download animations
    wait_and_download_animations(char_id, dest, boss_name, key, expected_count=3)

    # Step 3: Compose sprite sheets
    compose_sheets(boss_name)

    print(f"\n=== {boss_name} COMPLETE ===")


if __name__ == "__main__":
    main()
