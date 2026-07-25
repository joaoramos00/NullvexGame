#!/usr/bin/env python3
"""One-off downloader: Voltrix's 3 new animations (entrada, preparacao, thunderbolt).

Generated via mcp__pixellab__animate_character (v3 mode) in this session. The MCP tool
does not expose raw background_job_ids usable by tools/pixellab_download.py's `animation`
subcommand (which polls GET /v2/background-jobs/{id}), so frames are fetched directly by
URL from the character's animation groups instead, following the same pattern as
tools/download_voltrix_hover.py from Task 1. Output naming matches the pixellab_download.py
convention: <name>_<action>_<direction>_f<NN>.png + <name>_<action>_<direction>.gif.
"""
from pathlib import Path
import urllib.request

try:
    from PIL import Image
except ImportError:
    raise SystemExit("Pillow required: pip install Pillow")

DEST = Path("characters/bosses/voltrix")
DEST.mkdir(parents=True, exist_ok=True)

ANIMATIONS = {
    "entrada": [
        f"https://backblaze.pixellab.ai/file/pixellab-characters/a9da7a16-f3eb-4cf3-9cd5-75a1df14979e/a40e732b-e933-4026-bea6-7ef964f2c977/animations/de686df3-167f-4aeb-9be6-0c6dd1ddca7b/south/{i}.png"
        for i in range(9)
    ],
    "preparacao": [
        f"https://backblaze.pixellab.ai/file/pixellab-characters/a9da7a16-f3eb-4cf3-9cd5-75a1df14979e/a40e732b-e933-4026-bea6-7ef964f2c977/animations/9b627586-1b62-4cf4-9ce0-9567a2f65ed6/south/{i}.png"
        for i in range(9)
    ],
    "thunderbolt": [
        f"https://backblaze.pixellab.ai/file/pixellab-characters/a9da7a16-f3eb-4cf3-9cd5-75a1df14979e/a40e732b-e933-4026-bea6-7ef964f2c977/animations/98ce2378-79f9-49d8-90dd-fd0ab9f33c6d/south/{i}.png"
        for i in range(7)
    ],
}


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "voltrix-downloader/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def main() -> None:
    for action, urls in ANIMATIONS.items():
        print(f"Downloading {action} ({len(urls)} frames)...")
        frames: list[Image.Image] = []
        for i, url in enumerate(urls):
            raw = fetch(url)
            frame_path = DEST / f"voltrix_{action}_south_f{i:02d}.png"
            frame_path.write_bytes(raw)
            frames.append(Image.open(frame_path))
            print(f"  Saved {frame_path.name}")

        gif_path = DEST / f"voltrix_{action}_south.gif"
        frames[0].save(
            gif_path,
            save_all=True,
            append_images=frames[1:],
            loop=0,
            duration=100,
        )
        print(f"  GIF: {gif_path}")

    print("Done.")


if __name__ == "__main__":
    main()
