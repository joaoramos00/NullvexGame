#!/usr/bin/env python3
"""One-off downloader: Voltrix's new character base pose + existing hover-loop animations.

Fetches the south rotation (idle pose) and the two already-generated "Flutuar1"/"Flutuar2"
animation groups (9 frames each, south direction) directly by URL. These predate this script —
they were generated in an earlier PixelLab session, not by animate_character here.
"""
from pathlib import Path
import urllib.request

DEST = Path("characters/bosses/voltrix")
DEST.mkdir(parents=True, exist_ok=True)

ROTATION_SOUTH_URL = "https://backblaze.pixellab.ai/file/pixellab-characters/a9da7a16-f3eb-4cf3-9cd5-75a1df14979e/a40e732b-e933-4026-bea6-7ef964f2c977/rotations/south.png"

HOVER1_FRAME_URLS = [
    f"https://backblaze.pixellab.ai/file/pixellab-characters/a9da7a16-f3eb-4cf3-9cd5-75a1df14979e/a40e732b-e933-4026-bea6-7ef964f2c977/animations/b563441e-abc1-4387-9e6d-4d3f2a44135e/south/{i}.png"
    for i in range(9)
]
HOVER2_FRAME_URLS = [
    f"https://backblaze.pixellab.ai/file/pixellab-characters/a9da7a16-f3eb-4cf3-9cd5-75a1df14979e/a40e732b-e933-4026-bea6-7ef964f2c977/animations/1180ac10-8d05-49a8-b879-63b1e29a6d30/south/{i}.png"
    for i in range(9)
]


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "voltrix-downloader/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def main() -> None:
    print("Downloading base pose (south)...")
    (DEST / "voltrix_south.png").write_bytes(fetch(ROTATION_SOUTH_URL))
    print("  Saved voltrix_south.png")

    for i, url in enumerate(HOVER1_FRAME_URLS):
        data = fetch(url)
        (DEST / f"voltrix_hover1_south_f{i:02d}.png").write_bytes(data)
        print(f"  Saved voltrix_hover1_south_f{i:02d}.png")

    for i, url in enumerate(HOVER2_FRAME_URLS):
        data = fetch(url)
        (DEST / f"voltrix_hover2_south_f{i:02d}.png").write_bytes(data)
        print(f"  Saved voltrix_hover2_south_f{i:02d}.png")

    print("Done.")


if __name__ == "__main__":
    main()
