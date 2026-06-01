#!/usr/bin/env python3
"""Queue Commander Vex character creation + 4 animations via PixelLab REST API.
Prints all IDs so you can pass them to pixellab_download.py.
"""
import json, urllib.request
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

def get(path: str, key: str) -> dict:
    req = urllib.request.Request(
        f"{BASE}{path}", headers={"Authorization": f"Bearer {key}"}
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())

def main() -> None:
    key = load_key()

    # Balance check
    bal = get("/balance", key)
    print(f"Balance — credits: {bal.get('usd_credit_balance', '?')}  "
          f"generations: {bal.get('subscription_generation_balance', '?')}")

    # Create character
    print("\nCreating Commander Vex character...")
    char = post("/create-character-with-4-directions", {
        "description": (
            "cybernetic corrupted soldier commander, dark charcoal tactical armor, "
            "glowing neon purple-blue joints and chest panel, single monocular visor "
            "helmet glowing blue, left arm humanoid, right arm has integrated energy "
            "cannon barrel, HD pixel art sidescroller boss, facing left"
        ),
        "image_size": {"width": 128, "height": 128},
        "view": "side",
        "proportions": {"type": "preset", "name": "heroic"},
        "outline": "single color outline",
        "shading": "basic shading",
        "detail": "high detail",
    }, key)
    character_id = char["character_id"]
    print(f"character_id: {character_id}")

    # Queue 4 animations
    animations = [
        ("idle",  4, "standing idle, subtle breathing motion, cannon arm lowered, weight shifted slightly, ready for combat"),
        ("walk",  6, "heavy tactical walk forward, cannon arm raised slightly, deliberate combat stride"),
        ("dash",  6, "aggressive dash lunge forward, body leaning hard, propulsion jets firing on boots and back with purple glow"),
        ("shoot", 6, "cannon arm raises and aims, energy charges in barrel with blue glow, fires projectile with bright flash, recoils back"),
    ]

    job_ids: dict[str, str] = {}
    for action, frame_count, desc in animations:
        print(f"\nQueuing {action} animation ({frame_count} frames)...")
        resp = post("/animate-character", {
            "character_id": character_id,
            "action_description": desc,
            "directions": ["west"],
            "frame_count": frame_count,
            "mode": "v3",
        }, key)
        job_id = resp["background_job_ids"][0]
        job_ids[action] = job_id
        print(f"  job_{action}: {job_id}")

    # Save IDs
    out_dir = Path("characters/bosses/intro_boss")
    out_dir.mkdir(parents=True, exist_ok=True)
    ids_file = out_dir / ".pixellab_ids"
    lines = [f"character_id={character_id}"]
    for action, job_id in job_ids.items():
        lines.append(f"job_{action}={job_id}")
    ids_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"\nSaved IDs to {ids_file}")

    print("\n=== Next steps ===")
    print(f"python tools/pixellab_download.py character {character_id} characters/bosses/intro_boss/")
    for action, job_id in job_ids.items():
        print(f"python tools/pixellab_download.py animation {job_id} characters/bosses/intro_boss/ --direction west --action {action}")

if __name__ == "__main__":
    main()
