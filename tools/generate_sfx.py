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
    # Disparos do Zael por nível de carga
    ("sfx_shot_l1",      "retro laser blaster small shot, very short snappy 16-bit pew, light", 0.5),
    ("sfx_shot_l2",      "retro charged laser shot medium power, 16-bit energy blast, fuller punchy", 0.5),
    ("sfx_shot_l3",      "retro fully charged plasma cannon mega blast, powerful deep 16-bit, big boom", 0.7),
    # Ataques do Ignarath
    ("sfx_ignarath_fire","dragon fire breath roar, whooshing flames blast, retro 16-bit boss attack", 1.0),
    ("sfx_ignarath_clawwave","fire wave whoosh sweeping across ground, flame burst, retro 16-bit", 0.5),
    # Movimento do player
    ("sfx_dash",         "quick dash whoosh, short sharp air swipe, retro 16-bit action game", 0.5),
    ("sfx_wall_jump",    "wall kick jump, short springy thud, retro 16-bit platformer", 0.5),
    ("sfx_charge_ready", "energy charge ready ping, bright rising chime, retro 16-bit", 0.5),
    # Bosses / inimigos
    ("sfx_boss_aggro",   "monster boss roar, menacing deep growl, retro 16-bit boss intro", 1.2),
    ("sfx_boss_shoot",   "boss energy projectile fire, deep powerful retro 16-bit shot", 0.5),
    ("sfx_enemy_shoot",  "small enemy projectile shot, retro 8-bit blip fire, short", 0.5),
    # Fluxo / UI
    ("sfx_checkpoint",   "checkpoint reached, pleasant short confirm jingle, retro 16-bit", 0.8),
    ("sfx_stage_complete","stage clear victory fanfare, triumphant retro 16-bit jingle", 2.5),
    ("sfx_game_over",    "game over sad descending jingle, retro 16-bit", 2.0),
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
