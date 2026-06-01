#!/usr/bin/env python3
"""PixelLab asset downloader — character sprites, animation frames, tilesets."""

import argparse
import base64
import io
import json
import os
import time
import urllib.request
import zipfile
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    raise SystemExit("Pillow required: pip install Pillow")

BASE_URL = "https://api.pixellab.ai/v2"


def load_api_key() -> str:
    env_path = Path(__file__).parent.parent / ".env"
    if env_path.exists():
        for line in env_path.read_text(encoding="utf-8").splitlines():
            if line.startswith("PIXELLAB_API_KEY="):
                return line.split("=", 1)[1].strip()
    key = os.environ.get("PIXELLAB_API_KEY", "")
    if not key:
        raise SystemExit("PIXELLAB_API_KEY not found in .env or environment")
    return key


def api_get(path: str, key: str) -> dict:
    req = urllib.request.Request(
        f"{BASE_URL}{path}",
        headers={"Authorization": f"Bearer {key}"},
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def api_get_url(url: str, key: str) -> bytes:
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def poll_character(character_id: str, key: str) -> dict:
    """Poll GET /v2/characters/{id} until rotation_urls are populated."""
    print(f"Polling character {character_id}...")
    for attempt in range(20):
        data = api_get(f"/characters/{character_id}", key)
        urls = data.get("rotation_urls", {})
        if any(v is not None for v in urls.values()):
            print(f"  Ready after {attempt + 1} poll(s)")
            return data
        print(f"  [{attempt + 1}] processing — waiting 15s...")
        time.sleep(15)
    raise SystemExit(f"Character {character_id} did not complete after 20 polls")


def poll_job(job_id: str, key: str) -> dict:
    """Poll GET /v2/background-jobs/{id} until status == completed."""
    print(f"Polling job {job_id}...")
    for attempt in range(30):
        data = api_get(f"/background-jobs/{job_id}", key)
        if data.get("status") == "completed":
            print(f"  Ready after {attempt + 1} poll(s)")
            return data
        print(f"  [{attempt + 1}] {data.get('status', '?')} — waiting 15s...")
        time.sleep(15)
    raise SystemExit(f"Job {job_id} did not complete after 30 polls")


def cmd_character(character_id: str, dest: str, key: str) -> None:
    """Download character sprites ZIP and extract to dest folder."""
    poll_character(character_id, key)

    dest_path = Path(dest)
    dest_path.mkdir(parents=True, exist_ok=True)
    folder_name = dest_path.name

    raw = api_get_url(f"{BASE_URL}/characters/{character_id}/zip", key)
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        for member in z.namelist():
            if not member.endswith(".png") or "rotations/" not in member:
                continue
            direction = Path(member).stem  # south / west / east / north
            target = dest_path / f"{folder_name}_{direction}.png"
            target.write_bytes(z.read(member))
            print(f"  Saved: {target}")


def cmd_animation(job_id: str, dest: str, direction: str, action: str, key: str) -> None:
    """Poll animation job and save frames as PNG + GIF."""
    data = poll_job(job_id, key)

    dest_path = Path(dest)
    dest_path.mkdir(parents=True, exist_ok=True)
    folder_name = dest_path.name

    images = data["last_response"]["images"]
    frames: list[Image.Image] = []

    for i, img in enumerate(images):
        raw = base64.b64decode(img["base64"])
        w: int = img["width"]
        h: int = len(raw) // (w * 4)
        frame = Image.frombytes("RGBA", (w, h), raw)
        frame_path = dest_path / f"{folder_name}_{action}_{direction}_f{i:02d}.png"
        frame.save(frame_path)
        frames.append(frame)
        print(f"  Frame {i:02d}: {frame_path}")

    gif_path = dest_path / f"{folder_name}_{action}_{direction}.gif"
    frames[0].save(
        gif_path,
        save_all=True,
        append_images=frames[1:],
        loop=0,
        duration=100,
    )
    print(f"  GIF: {gif_path}")


def cmd_tileset(tileset_id: str, dest: str, key: str) -> None:
    """Poll tileset job and download the spritesheet PNG."""
    print(f"Polling tileset {tileset_id}...")
    data = None
    for attempt in range(20):
        data = api_get(f"/tilesets-sidescroller/{tileset_id}", key)
        if data.get("status") == "completed":
            print(f"  Ready after {attempt + 1} poll(s)")
            break
        print(f"  [{attempt + 1}] {data.get('status', '?')} — waiting 15s...")
        time.sleep(15)
    else:
        raise SystemExit(f"Tileset {tileset_id} did not complete")

    download_url = data.get("download_url") or data.get("url") or data.get("image_url")
    if not download_url:
        raise SystemExit(f"No download URL in response: {json.dumps(data, indent=2)}")

    dest_path = Path(dest)
    dest_path.mkdir(parents=True, exist_ok=True)
    raw = api_get_url(download_url, key)
    out = dest_path / "tileset.png"
    out.write_bytes(raw)
    print(f"  Saved: {out}")


def main() -> None:
    parser = argparse.ArgumentParser(description="PixelLab asset downloader")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_char = sub.add_parser("character", help="Download character sprites ZIP -> PNG")
    p_char.add_argument("character_id", help="ID returned by create-character-with-4-directions")
    p_char.add_argument("dest", help="Destination folder, e.g. characters/enemies/grunt")

    p_anim = sub.add_parser("animation", help="Poll animation job and save frames")
    p_anim.add_argument("job_id", help="background_job_id from animate-character response")
    p_anim.add_argument("dest", help="Destination folder, e.g. characters/enemies/grunt")
    p_anim.add_argument("--direction", required=True, choices=["west", "east", "south", "north"])
    p_anim.add_argument("--action", required=True, choices=["walk", "idle", "attack", "death", "hit", "dash", "shoot"])

    p_tile = sub.add_parser("tileset", help="Poll and download sidescroller tileset")
    p_tile.add_argument("tileset_id", help="Tileset ID from create_sidescroller_tileset")
    p_tile.add_argument("dest", help="Destination folder, e.g. stages/stage_00/tileset")

    args = parser.parse_args()
    key = load_api_key()

    if args.cmd == "character":
        cmd_character(args.character_id, args.dest, key)
    elif args.cmd == "animation":
        cmd_animation(args.job_id, args.dest, args.direction, args.action, key)
    elif args.cmd == "tileset":
        cmd_tileset(args.tileset_id, args.dest, key)


if __name__ == "__main__":
    main()
