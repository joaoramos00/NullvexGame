"""
Gera SFX para NullvexGame via ElevenLabs Sound Effects API.
Salva MP3 em assets/audio/sfx/.
"""

import os
import sys
import requests

def _load_key() -> str:
    # Tenta env primeiro, depois lê direto do .env
    k = os.environ.get("ELEVENLABS_API_KEY", "")
    if k:
        return k.strip()
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    if os.path.exists(env_path):
        for line in open(env_path).readlines():
            if line.startswith("ELEVENLABS_API_KEY="):
                return line.split("=", 1)[1].strip()
    return ""

API_KEY = _load_key()
if not API_KEY:
    print("ERROR: ELEVENLABS_API_KEY não encontrada")
    sys.exit(1)

URL = "https://api.elevenlabs.io/v1/sound-generation"
HEADERS = {"xi-api-key": API_KEY, "Content-Type": "application/json"}
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "sfx")

SOUNDS = [
    ("sfx_jump",         "retro 8-bit jump sound, short rising tone, classic SNES platformer", 0.6),
    ("sfx_shoot",        "retro laser blaster shot, short snappy 16-bit style, futuristic gun fire", 0.5),
    ("sfx_attack",       "sword slash whoosh, sharp swipe, retro action game, quick", 0.5),
    ("sfx_player_damage","player hit hurt sound, short impact thud, retro SNES game", 0.5),
    ("sfx_player_death", "player death dramatic sound, retro 16-bit game over, descending tones", 1.5),
    ("sfx_enemy_death",  "small enemy explosion pop, retro 8-bit burst, short", 0.5),
    ("sfx_boss_damage",  "heavy boss hit impact, deep thud, retro action boss fight", 0.5),
    ("sfx_boss_death",   "boss defeat large explosion, dramatic retro game, long rumble", 2.0),
    ("sfx_collectible",  "item pickup sparkle chime, bright pleasant retro game sound", 0.6),
]

def generate(name: str, prompt: str, duration: float) -> bool:
    out_path = os.path.join(OUT_DIR, f"{name}.mp3")
    if os.path.exists(out_path):
        print(f"  SKIP  {name} (já existe)")
        return True

    print(f"  GEN   {name} ...", end=" ", flush=True)
    payload = {
        "text": prompt,
        "duration_seconds": duration,
        "prompt_influence": 0.4,
    }
    r = requests.post(URL, headers=HEADERS, json=payload, timeout=30)
    if r.status_code != 200:
        print(f"ERRO {r.status_code}: {r.text[:120]}")
        return False

    with open(out_path, "wb") as f:
        f.write(r.content)
    kb = len(r.content) // 1024
    print(f"OK ({kb} KB)")
    return True

if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    ok = 0
    for name, prompt, dur in SOUNDS:
        if generate(name, prompt, dur):
            ok += 1
    print(f"\n{ok}/{len(SOUNDS)} SFX gerados em assets/audio/sfx/")
