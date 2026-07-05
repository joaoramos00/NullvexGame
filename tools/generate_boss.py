#!/usr/bin/env python3
"""
Queue boss character creation + walk + entry animations via PixelLab REST API.
Saves all IDs for use with pixellab_download.py.

Usage:
  python tools/generate_boss.py <name> <description> <walk_desc> <entry_desc>

Or import and call generate_boss() directly.
"""
import json
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

BASE = "https://api.pixellab.ai/v2"


def load_key() -> str:
    env = Path(__file__).parent.parent / ".env"
    for line in env.read_text(encoding="utf-8").splitlines():
        if line.startswith("PIXELLAB_API_KEY="):
            return line.split("=", 1)[1].strip()
    raise SystemExit("PIXELLAB_API_KEY not in .env")


def post(path: str, body: dict, key: str) -> dict:
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        f"{BASE}{path}", data=data,
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def get_api(path: str, key: str) -> dict:
    req = urllib.request.Request(
        f"{BASE}{path}", headers={"Authorization": f"Bearer {key}"}
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def poll_character(character_id: str, key: str, max_polls: int = 40) -> None:
    """Poll until character rotation_urls are populated."""
    print(f"  Polling character {character_id}...")
    for attempt in range(max_polls):
        data = get_api(f"/characters/{character_id}", key)
        urls = data.get("rotation_urls", {})
        if any(v is not None for v in urls.values()):
            print(f"  Character ready after {attempt + 1} poll(s)")
            return
        print(f"  [{attempt + 1}] character processing — waiting 15s...")
        time.sleep(15)
    raise SystemExit(f"Character {character_id} timed out after {max_polls} polls")


def generate_boss(
    name: str,
    description: str,
    walk_desc: str,
    entry_desc: str,
    key: str,
) -> dict:
    """Create character + queue all animations. Returns dict with all IDs."""
    out_dir = Path("characters/bosses") / name
    out_dir.mkdir(parents=True, exist_ok=True)
    ids_file = out_dir / ".pixellab_ids"

    # Check if IDs already saved
    if ids_file.exists():
        ids = dict(
            line.split("=", 1)
            for line in ids_file.read_text(encoding="utf-8").splitlines()
            if "=" in line
        )
        print(f"  Loaded existing IDs from {ids_file}")
        return ids

    # Balance check
    bal = get_api("/balance", key)
    print(f"  Balance — credits: {bal.get('usd_credit_balance', '?')}  "
          f"generations: {bal.get('subscription_generation_balance', '?')}")

    # Create character
    print(f"\n  Creating {name} character...")
    char = post("/create-character-with-4-directions", {
        "description": description,
        "image_size": {"width": 128, "height": 128},
        "view": "side",
        "proportions": {"type": "preset", "name": "heroic"},
        "outline": "single color outline",
        "shading": "basic shading",
        "detail": "medium detail",
    }, key)
    character_id = char["character_id"]
    print(f"  character_id: {character_id}")

    # Poll until character ready
    poll_character(character_id, key)

    # Queue walk animation (west + east)
    print(f"\n  Queuing walk animation (west+east)...")
    walk_resp = post("/animate-character", {
        "character_id": character_id,
        "action_description": walk_desc,
        "directions": ["west", "east"],
        "frame_count": 8,
        "mode": "v3",
    }, key)
    walk_job_ids = walk_resp["background_job_ids"]  # list of 2 IDs
    print(f"  walk job ids: {walk_job_ids}")

    # Queue entry animation (south)
    print(f"\n  Queuing entry animation (south)...")
    entry_resp = post("/animate-character", {
        "character_id": character_id,
        "action_description": entry_desc,
        "directions": ["south"],
        "frame_count": 6,
        "mode": "v3",
    }, key)
    entry_job_ids = entry_resp["background_job_ids"]  # list of 1 ID
    print(f"  entry job ids: {entry_job_ids}")

    ids = {
        "character_id": character_id,
        "job_walk_west": walk_job_ids[0],
        "job_walk_east": walk_job_ids[1],
        "job_entry_south": entry_job_ids[0],
    }

    # Save IDs
    lines = [f"{k}={v}" for k, v in ids.items()]
    ids_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"\n  Saved IDs to {ids_file}")
    return ids


def download_boss(name: str, ids: dict) -> None:
    """Download character + animations and compose sprite sheets."""
    import subprocess

    dest = f"characters/bosses/{name}/"

    print(f"\n--- Downloading {name} character sprites ---")
    subprocess.run(
        ["python", "tools/pixellab_download.py", "character", ids["character_id"], dest],
        check=True,
    )

    print(f"\n--- Downloading {name} walk west ---")
    subprocess.run(
        ["python", "tools/pixellab_download.py", "animation", ids["job_walk_west"],
         dest, "--direction", "west", "--action", "walk"],
        check=True,
    )

    print(f"\n--- Downloading {name} walk east ---")
    subprocess.run(
        ["python", "tools/pixellab_download.py", "animation", ids["job_walk_east"],
         dest, "--direction", "east", "--action", "walk"],
        check=True,
    )

    print(f"\n--- Downloading {name} entry south ---")
    subprocess.run(
        ["python", "tools/pixellab_download.py", "animation", ids["job_entry_south"],
         dest, "--direction", "south", "--action", "entry"],
        check=True,
    )

    print(f"\n--- Composing {name} sprite sheets ---")
    subprocess.run(["python", "tools/compose_spritesheet.py", name, "walk", "west"], check=True)
    subprocess.run(["python", "tools/compose_spritesheet.py", name, "walk", "east"], check=True)
    subprocess.run(["python", "tools/compose_spritesheet.py", name, "entry", "south"], check=True)

    print(f"\n  {name} COMPLETE!")


BOSSES = {
    "cryovex": {
        "description": (
            "Cryovex frost wolf boss, lean armored wolf body with crystalline ice fur mane, "
            "frost spikes along spine, clawed ice gauntlets, glowing cold blue eyes, "
            "frozen breath visible, pale blue and white palette, Mega Man X style pixel art, side view"
        ),
        "walk_desc": "prowling wolf walking cycle, low predatory stance, frost wolf",
        "entry_desc": "dramatic entrance, frost wolf leaping forward and skidding to a halt, facing camera, ice forming on ground",
    },
    "voltrix": {
        "description": (
            "Voltrix thunder hawk boss, large armored bird of prey with metallic feathers "
            "charged with electricity, jagged yellow and black plumage, crackling talons and beak, "
            "electric coils wrapped around wings, wings half-spread battle stance, "
            "Mega Man X style pixel art, side view"
        ),
        "walk_desc": "thunder hawk battle walking cycle, wings half-spread, electric sparks",
        "entry_desc": "dramatic aerial landing entrance, thunder hawk diving down and landing with electric discharge, facing camera",
    },
    "gravitus": {
        "description": (
            "Gravitus gravity bear boss, massive armored bear with crushing claws, "
            "dark purple crystalline plates, gravitational orbs orbiting like rings around body, "
            "heavy hunched powerful stance, Mega Man X style pixel art, side view"
        ),
        "walk_desc": "heavy stomping walking cycle, gravitational bear, slow powerful steps",
        "entry_desc": "dramatic entrance, gravity bear rising with gravitational orbs swirling around, facing camera",
    },
    "galerix": {
        "description": (
            "Galerix storm hawk boss, sleek aerodynamic bird of prey, teal and white feathered armor, "
            "streamlined wind turbine wings, flowing energy feather trails, sharp curved beak, "
            "fierce attack dive posture, Mega Man X style pixel art, side view"
        ),
        "walk_desc": "swift gliding walk cycle, storm hawk, wind energy trailing",
        "entry_desc": "dramatic entrance, storm hawk diving in at high speed and landing in battle stance, facing camera",
    },
    "umbraex": {
        "description": (
            "Umbraex shadow panther boss, sleek dark feline body with layered black and dark purple armor, "
            "shadow tendrils extending from body, multiple glowing purple eyes, "
            "partially intangible form dissolving into darkness, predatory low crouched stance, "
            "Mega Man X style pixel art, side view"
        ),
        "walk_desc": "stalking predator walk cycle, shadow panther, low crouched",
        "entry_desc": "dramatic entrance, shadow panther materializing from darkness, facing camera, shadow tendrils spreading",
    },
    "luxar": {
        "description": (
            "Luxar solar lion boss, majestic armored lion, radiant white and gold mane with light rays, "
            "blinding energy core in chest, halo crown of sunrays, golden claws, "
            "proud regal battle stance, Mega Man X style pixel art, side view"
        ),
        "walk_desc": "regal powerful walking cycle, solar lion, mane radiating light",
        "entry_desc": "dramatic entrance, solar lion descending in pillar of light, landing in proud stance, facing camera",
    },
    "terragor": {
        "description": (
            "Terragor stone gorilla boss, massive armored gorilla with boulder-sized fists, "
            "stone-plated body with rock spikes along back and shoulders, "
            "earth brown and grey, knuckle-dragging powerful stance, Mega Man X style pixel art, side view"
        ),
        "walk_desc": "knuckle-dragging gorilla walking cycle, stone golem, heavy shaking steps",
        "entry_desc": "dramatic entrance, stone gorilla crashing through ground, rising to full height, facing camera, rocks falling",
    },
}


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python tools/generate_boss.py <boss_name>")
        print(f"Available: {list(BOSSES.keys())}")
        sys.exit(1)

    boss_name = sys.argv[1].lower()
    if boss_name not in BOSSES:
        print(f"Unknown boss '{boss_name}'. Available: {list(BOSSES.keys())}")
        sys.exit(1)

    boss = BOSSES[boss_name]
    k = load_key()
    ids = generate_boss(
        name=boss_name,
        description=boss["description"],
        walk_desc=boss["walk_desc"],
        entry_desc=boss["entry_desc"],
        key=k,
    )
    download_boss(boss_name, ids)
