"""
Gera BGM para NullvexGame via udioapi.pro (Suno v4).
Salva MP3 em assets/audio/bgm/.
"""

import os
import sys
import time
import requests

def _load_key() -> str:
    k = os.environ.get("UDIOAPI_KEY", "")
    if k:
        return k.strip()
    env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
    if os.path.exists(env_path):
        for line in open(env_path, encoding="utf-8").readlines():
            if line.startswith("UDIOAPI_KEY="):
                return line.split("=", 1)[1].strip()
    return ""

API_KEY = _load_key()
if not API_KEY:
    print("ERROR: UDIOAPI_KEY não encontrada no .env")
    sys.exit(1)

BASE_URL = "https://udioapi.pro/api/v2"
HEADERS  = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}
OUT_DIR  = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "bgm")

TRACKS = [
    ("bgm_intro",
     "SNES 16-bit chiptune action platformer intro stage, mysterious tense atmosphere, square wave leads, "
     "retro game music, instrumental loopable, Mega Man X style"),

    ("bgm_stage_01",
     "SNES 16-bit chiptune fire volcano stage, intense fast-paced action platformer, blazing square wave melody, "
     "energetic drums, retro game music, instrumental loopable, Mega Man X style"),

    ("bgm_stage_02",
     "SNES 16-bit chiptune ice glacier stage, cold crystalline atmosphere, sparkling high-pitched arpeggios, "
     "retro game music, instrumental loopable, Mega Man X style"),

    ("bgm_stage_03",
     "SNES 16-bit chiptune electric lightning stage, fast energetic electro beats, buzzing synth leads, "
     "retro game music, instrumental loopable, Mega Man X style"),

    ("bgm_stage_04",
     "SNES 16-bit chiptune gravity space stage, heavy oppressive atmosphere, deep bass pulses, "
     "retro game music, instrumental loopable, Mega Man X style"),

    ("bgm_stage_05",
     "SNES 16-bit chiptune wind sky stage, light airy fast melody, flute-like square waves, "
     "retro game music, instrumental loopable, Mega Man X style"),

    ("bgm_stage_06",
     "SNES 16-bit chiptune shadow dark stage, mysterious sinister atmosphere, minor key, "
     "retro game music, instrumental loopable, Mega Man X style"),

    ("bgm_stage_07",
     "SNES 16-bit chiptune light holy stage, bright radiant uplifting melody, shimmering arpeggios, "
     "retro game music, instrumental loopable, Mega Man X style"),

    ("bgm_stage_08",
     "SNES 16-bit chiptune earth cave stage, heavy rumbling rhythm, powerful bass, earthy tone, "
     "retro game music, instrumental loopable, Mega Man X style"),

    ("bgm_gauntlet",
     "SNES 16-bit chiptune final gauntlet all bosses rush, epic intense relentless action, "
     "fast-paced adrenaline, retro game music, instrumental loopable, Mega Man X style"),

    ("bgm_nullvex",
     "SNES 16-bit chiptune final villain humanoid boss battle, dramatic dark epic confrontation, "
     "powerful driving beat, retro game music, instrumental loopable, Mega Man X final boss style"),

    ("bgm_nullvex_true",
     "SNES 16-bit chiptune true final boss ultimate form, intense overwhelming epic climax, "
     "fast aggressive lead, choir-like pads, retro game music, instrumental loopable, Mega Man X final boss style"),
]

def generate(name: str, prompt: str) -> bool:
    out_path = os.path.join(OUT_DIR, f"{name}.mp3")
    if os.path.exists(out_path):
        print(f"  SKIP  {name} (já existe)")
        return True

    print(f"  GEN   {name} ...", end=" ", flush=True)

    payload = {
        "model": "chirp-v4",
        "gpt_description_prompt": prompt,
        "make_instrumental": True,
    }
    r = requests.post(f"{BASE_URL}/generate", headers=HEADERS, json=payload, timeout=30)
    if r.status_code != 200:
        print(f"ERRO {r.status_code}: {r.text[:200]}")
        return False

    data = r.json()
    work_id = data.get("workId") or (data.get("data") or {}).get("task_id")
    if not work_id:
        print(f"ERRO sem workId: {str(data)[:200]}")
        return False

    # Polling: GET /api/v2/feed?workId=...
    for _ in range(60):
        time.sleep(5)
        try:
            sr = requests.get(f"{BASE_URL}/feed?workId={work_id}", headers=HEADERS, timeout=30)
        except requests.exceptions.Timeout:
            print(".", end="", flush=True)
            continue
        if sr.status_code != 200:
            print(".", end="", flush=True)
            continue
        sd = sr.json()
        status = (sd.get("data") or {}).get("type", "")
        if status == "SUCCESS":
            clips = (sd.get("data") or {}).get("response_data", [])
            if clips:
                audio_url = clips[0].get("audio_url")
                if audio_url:
                    return _download(audio_url, out_path)
            print("ERRO sem audio_url")
            return False
        if status in ("FAILED", "ERROR"):
            print(f"ERRO geração falhou: {str(sd)[:150]}")
            return False
        print(".", end="", flush=True)

    print("TIMEOUT")
    return False

def _download(url: str, path: str) -> bool:
    dl = requests.get(url, timeout=60)
    if dl.status_code != 200:
        print(f"ERRO download {dl.status_code}")
        return False
    with open(path, "wb") as f:
        f.write(dl.content)
    kb = len(dl.content) // 1024
    print(f"OK ({kb} KB)")
    return True

if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    ok = 0
    for name, prompt in TRACKS:
        if generate(name, prompt):
            ok += 1
    print(f"\n{ok}/{len(TRACKS)} BGMs gerados em assets/audio/bgm/")
