# Boss Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gerar sprites pixel art para os 8 bosses elementais via PixelLab e integrá-los ao sistema Sprite2D+sprite-sheet do projeto.

**Architecture:** Sprites gerados via REST API PixelLab, frames compostos em sprite sheets horizontais por `tools/compose_spritesheet.py`, integrados a cada boss via `Sprite2D` + animação manual idêntica ao padrão `intro_boss.gd`/`enemy_miniboss.gd`. Sprites são gerados primeiro; código de integração só é adicionado depois que todos os assets existem (evita erros de `preload()` em arquivos ausentes).

**Tech Stack:** GDScript 4.6.2, Python 3 (Pillow), PixelLab REST API (`/v2/create-character-with-4-directions`, `/v2/animate-character`), `tools/pixellab_download.py`.

**Spec:** `docs/superpowers/specs/2026-06-01-boss-sprites-design.md`

---

## Estrutura de Arquivos

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `tools/compose_spritesheet.py` | Criar | Compõe frames individuais em PNG horizontal |
| `characters/bosses/<name>/` | Criar (8 dirs) | Assets gerados por boss |
| `characters/bosses/<name>.tscn` | Modificar (8) | Adicionar nó `Sprite2D` filho |
| `characters/bosses/<name>.gd` | Modificar (8) | Adicionar constantes + `_update_animation()` |

**Ordem de execução:** Task 1 (compose_spritesheet.py) → Tasks 2–9 (geração por boss) → Task 10 (código de integração) → Task 11 (web export).

---

## Task 1: Criar `tools/compose_spritesheet.py`

**Files:**
- Create: `tools/compose_spritesheet.py`

- [ ] **Step 1: Criar o script**

```python
#!/usr/bin/env python3
"""Compõe frames individuais de animação PixelLab em sprite sheet horizontal."""
import sys
from pathlib import Path
from PIL import Image


def main() -> None:
    if len(sys.argv) != 4:
        print("Usage: compose_spritesheet.py <name> <action> <direction>")
        print("  action:    walk | entry")
        print("  direction: west | east | south")
        sys.exit(1)

    name, action, direction = sys.argv[1], sys.argv[2], sys.argv[3]
    folder = Path("characters/bosses") / name
    frame_count = 8 if action == "walk" else 6

    frames = []
    for i in range(frame_count):
        p = folder / f"{name}_{action}_{direction}_f{i:02d}.png"
        if not p.exists():
            print(f"ERROR: {p} not found")
            sys.exit(1)
        frames.append(Image.open(p).convert("RGBA"))

    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * frame_count, h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * w, 0))

    out = folder / (f"{name}_entry.png" if action == "entry" else f"{name}_{action}_{direction}.png")
    sheet.save(out)
    print(f"Saved: {out}  ({w * frame_count}x{h}, {frame_count} frames)")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Testar com arquivo de teste**

```powershell
python -c "
from PIL import Image; from pathlib import Path
Path('characters/bosses/_test').mkdir(parents=True, exist_ok=True)
for i in range(8):
    img = Image.new('RGBA', (128,128), (i*30, 0, 0, 255))
    img.save(f'characters/bosses/_test/_test_walk_west_f{i:02d}.png')
for i in range(6):
    img = Image.new('RGBA', (128,128), (0, i*40, 0, 255))
    img.save(f'characters/bosses/_test/_test_entry_south_f{i:02d}.png')
"
python tools/compose_spritesheet.py _test walk west
python tools/compose_spritesheet.py _test entry south
```

Expected:
- `characters/bosses/_test/_test_walk_west.png` — 1024×128
- `characters/bosses/_test/_test_entry.png` — 768×128

```powershell
python -c "
from PIL import Image
w = Image.open('characters/bosses/_test/_test_walk_west.png')
e = Image.open('characters/bosses/_test/_test_entry.png')
assert w.size == (1024, 128), f'walk wrong: {w.size}'
assert e.size == (768, 128), f'entry wrong: {e.size}'
print('PASS: walk', w.size, '/ entry', e.size)
"
```

- [ ] **Step 3: Limpar arquivos de teste e commitar**

```powershell
Remove-Item -Recurse -Force characters/bosses/_test
```

```bash
git add tools/compose_spritesheet.py
git commit -m "feat(tools): compose_spritesheet.py — stitch PixelLab frames into sprite sheet"
```

---

## Task 2: Gerar sprites — Ignarath (Salamandra de Fogo)

**Files:**
- Create: `characters/bosses/ignarath/ignarath_west.png`, `_east.png`, `_south.png`, `_north.png`
- Create: `characters/bosses/ignarath/ignarath_walk_west.png`, `_walk_east.png`, `_entry.png`

- [ ] **Step 1: Carregar API key**

```powershell
$env:PL_KEY = (Get-Content .env | Select-String "PIXELLAB_API_KEY").ToString().Split("=")[1].Trim()
python -c "import os; print('Key OK:', bool(os.environ.get('PIXELLAB_API_KEY')))" 2>$null; python -c "
import os, urllib.request, json
key = open('.env').read().split('PIXELLAB_API_KEY=')[1].split()[0]
req = urllib.request.Request('https://api.pixellab.ai/v2/balance', headers={'Authorization': f'Bearer {key}'})
with urllib.request.urlopen(req) as r: print(json.loads(r.read()))
"
```

- [ ] **Step 2: Criar personagem**

```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "description": "Ignarath fire salamander boss, massive reptilian body with molten armor plates, large curved horns glowing orange at tips, lava cracks running through thick hide, flaming tail, hunched aggressive stance, red and orange palette, Mega Man X style pixel art, side view",
    "image_size": {"width": 128, "height": 128},
    "view": "side",
    "proportions": {"type": "preset", "name": "heroic"},
    "outline": "single color outline",
    "shading": "basic shading",
    "detail": "medium detail"
}).encode()
req = urllib.request.Request(
    "https://api.pixellab.ai/v2/create-character-with-4-directions",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("character_id:", data["character_id"])
```

Anotar `character_id` como **CHAR_ID**.

- [ ] **Step 3: Baixar sprites de referência**

```bash
python tools/pixellab_download.py character <CHAR_ID> characters/bosses/ignarath/
```

Poll automático (~2–5 min). Expected: `ignarath_west.png`, `ignarath_east.png`, `ignarath_south.png`, `ignarath_north.png` em `characters/bosses/ignarath/`.

- [ ] **Step 4: Submeter walk animation (west + east)**

```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "aggressive walking combat cycle, heavy stomping, molten fire salamander",
    "directions": ["west", "east"],
    "frame_count": 8,
    "mode": "v3"
}).encode()
req = urllib.request.Request(
    "https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("walk jobs:", data["background_job_ids"])
# [0] = west, [1] = east
```

Anotar `background_job_ids[0]` como **WALK_W_JOB** e `[1]` como **WALK_E_JOB**.

- [ ] **Step 5: Submeter entry animation (south)**

```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "dramatic battle entrance, rising up with lava burst from ground, facing forward",
    "directions": ["south"],
    "frame_count": 6,
    "mode": "v3"
}).encode()
req = urllib.request.Request(
    "https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("entry job:", data["background_job_ids"][0])
```

Anotar `background_job_ids[0]` como **ENTRY_JOB**.

- [ ] **Step 6: Baixar animações**

```bash
python tools/pixellab_download.py animation <WALK_W_JOB> characters/bosses/ignarath/ --direction west --action walk
python tools/pixellab_download.py animation <WALK_E_JOB> characters/bosses/ignarath/ --direction east --action walk
python tools/pixellab_download.py animation <ENTRY_JOB> characters/bosses/ignarath/ --direction south --action entry
```

Cada poll ~2–3 min. Expected: `ignarath_walk_west_f00-f08.png`, `ignarath_walk_east_f00-f08.png`, `ignarath_entry_south_f00-f05.png`.

- [ ] **Step 7: Compor sprite sheets**

```bash
python tools/compose_spritesheet.py ignarath walk west
python tools/compose_spritesheet.py ignarath walk east
python tools/compose_spritesheet.py ignarath entry south
```

Expected:
- `ignarath_walk_west.png` (1024×128)
- `ignarath_walk_east.png` (1024×128)
- `ignarath_entry.png` (768×128)

- [ ] **Step 8: Commitar**

```bash
git add characters/bosses/ignarath/
git commit -m "assets(ignarath): PixelLab sprites — idle 4-dir, walk west/east, entry south"
```

---

## Task 3: Gerar sprites — Cryovex (Lobo da Neve)

**Files:**
- Create: `characters/bosses/cryovex/cryovex_west.png`, `_east.png`, `_south.png`, `_north.png`
- Create: `characters/bosses/cryovex/cryovex_walk_west.png`, `_walk_east.png`, `_entry.png`

- [ ] **Step 1: Criar personagem**

```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "description": "Cryovex frost wolf boss, lean armored wolf body with crystalline ice fur mane, frost spikes along spine, clawed ice gauntlets, glowing cold blue eyes, frozen breath visible, pale blue and white palette, Mega Man X style pixel art, side view",
    "image_size": {"width": 128, "height": 128},
    "view": "side",
    "proportions": {"type": "preset", "name": "heroic"},
    "outline": "single color outline",
    "shading": "basic shading",
    "detail": "medium detail"
}).encode()
req = urllib.request.Request(
    "https://api.pixellab.ai/v2/create-character-with-4-directions",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("character_id:", data["character_id"])
```

Anotar como **CHAR_ID**.

- [ ] **Step 2: Baixar referência + submeter animações**

```bash
python tools/pixellab_download.py character <CHAR_ID> characters/bosses/cryovex/
```

Walk (west + east):
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "prowling wolf walking cycle, low predatory stance, frost wolf",
    "directions": ["west", "east"],
    "frame_count": 8,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("walk jobs:", data["background_job_ids"])
```

Entry (south):
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "dramatic entrance, frost wolf leaping forward and skidding to a halt, facing camera, ice forming on ground",
    "directions": ["south"],
    "frame_count": 6,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("entry job:", data["background_job_ids"][0])
```

- [ ] **Step 3: Baixar animações e compor sheets**

```bash
python tools/pixellab_download.py animation <WALK_W_JOB> characters/bosses/cryovex/ --direction west --action walk
python tools/pixellab_download.py animation <WALK_E_JOB> characters/bosses/cryovex/ --direction east --action walk
python tools/pixellab_download.py animation <ENTRY_JOB> characters/bosses/cryovex/ --direction south --action entry
python tools/compose_spritesheet.py cryovex walk west
python tools/compose_spritesheet.py cryovex walk east
python tools/compose_spritesheet.py cryovex entry south
```

- [ ] **Step 4: Commitar**

```bash
git add characters/bosses/cryovex/
git commit -m "assets(cryovex): PixelLab sprites — idle 4-dir, walk west/east, entry south"
```

---

## Task 4: Gerar sprites — Voltrix (Falcão Trovão)

**Files:**
- Create: `characters/bosses/voltrix/` (mesma estrutura)

- [ ] **Step 1: Criar personagem**

```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "description": "Voltrix thunder hawk boss, large armored bird of prey with metallic feathers charged with electricity, jagged yellow and black plumage, crackling talons and beak, electric coils wrapped around wings, wings half-spread battle stance, Mega Man X style pixel art, side view",
    "image_size": {"width": 128, "height": 128},
    "view": "side",
    "proportions": {"type": "preset", "name": "heroic"},
    "outline": "single color outline",
    "shading": "basic shading",
    "detail": "medium detail"
}).encode()
req = urllib.request.Request(
    "https://api.pixellab.ai/v2/create-character-with-4-directions",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("character_id:", data["character_id"])
```

- [ ] **Step 2: Baixar referência + submeter animações**

```bash
python tools/pixellab_download.py character <CHAR_ID> characters/bosses/voltrix/
```

Walk:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "thunder hawk battle walking cycle, wings half-spread, electric sparks",
    "directions": ["west", "east"],
    "frame_count": 8,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("walk jobs:", data["background_job_ids"])
```

Entry:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "dramatic aerial landing entrance, thunder hawk diving down and landing with electric discharge, facing camera",
    "directions": ["south"],
    "frame_count": 6,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("entry job:", data["background_job_ids"][0])
```

- [ ] **Step 3: Baixar e compor**

```bash
python tools/pixellab_download.py animation <WALK_W_JOB> characters/bosses/voltrix/ --direction west --action walk
python tools/pixellab_download.py animation <WALK_E_JOB> characters/bosses/voltrix/ --direction east --action walk
python tools/pixellab_download.py animation <ENTRY_JOB> characters/bosses/voltrix/ --direction south --action entry
python tools/compose_spritesheet.py voltrix walk west
python tools/compose_spritesheet.py voltrix walk east
python tools/compose_spritesheet.py voltrix entry south
```

- [ ] **Step 4: Commitar**

```bash
git add characters/bosses/voltrix/
git commit -m "assets(voltrix): PixelLab sprites — idle 4-dir, walk west/east, entry south"
```

---

## Task 5: Gerar sprites — Gravitus (Urso Cósmico)

**Files:**
- Create: `characters/bosses/gravitus/` (mesma estrutura)

- [ ] **Step 1: Criar personagem**

```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "description": "Gravitus gravity bear boss, massive armored bear with crushing claws, dark purple crystalline plates, gravitational orbs orbiting like rings around body, heavy hunched powerful stance, Mega Man X style pixel art, side view",
    "image_size": {"width": 128, "height": 128},
    "view": "side",
    "proportions": {"type": "preset", "name": "heroic"},
    "outline": "single color outline",
    "shading": "basic shading",
    "detail": "medium detail"
}).encode()
req = urllib.request.Request(
    "https://api.pixellab.ai/v2/create-character-with-4-directions",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("character_id:", data["character_id"])
```

- [ ] **Step 2: Baixar referência + submeter animações**

```bash
python tools/pixellab_download.py character <CHAR_ID> characters/bosses/gravitus/
```

Walk:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "heavy stomping walking cycle, gravitational bear, slow powerful steps",
    "directions": ["west", "east"],
    "frame_count": 8,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("walk jobs:", data["background_job_ids"])
```

Entry:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "dramatic entrance, gravity bear rising with gravitational orbs swirling around, facing camera",
    "directions": ["south"],
    "frame_count": 6,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("entry job:", data["background_job_ids"][0])
```

- [ ] **Step 3: Baixar e compor**

```bash
python tools/pixellab_download.py animation <WALK_W_JOB> characters/bosses/gravitus/ --direction west --action walk
python tools/pixellab_download.py animation <WALK_E_JOB> characters/bosses/gravitus/ --direction east --action walk
python tools/pixellab_download.py animation <ENTRY_JOB> characters/bosses/gravitus/ --direction south --action entry
python tools/compose_spritesheet.py gravitus walk west
python tools/compose_spritesheet.py gravitus walk east
python tools/compose_spritesheet.py gravitus entry south
```

- [ ] **Step 4: Commitar**

```bash
git add characters/bosses/gravitus/
git commit -m "assets(gravitus): PixelLab sprites — idle 4-dir, walk west/east, entry south"
```

---

## Task 6: Gerar sprites — Galerix (Falcão Tempestade)

**Files:**
- Create: `characters/bosses/galerix/` (mesma estrutura)

- [ ] **Step 1: Criar personagem**

```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "description": "Galerix storm hawk boss, sleek aerodynamic bird of prey, teal and white feathered armor, streamlined wind turbine wings, flowing energy feather trails, sharp curved beak, fierce attack dive posture, Mega Man X style pixel art, side view",
    "image_size": {"width": 128, "height": 128},
    "view": "side",
    "proportions": {"type": "preset", "name": "heroic"},
    "outline": "single color outline",
    "shading": "basic shading",
    "detail": "medium detail"
}).encode()
req = urllib.request.Request(
    "https://api.pixellab.ai/v2/create-character-with-4-directions",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("character_id:", data["character_id"])
```

- [ ] **Step 2: Baixar referência + submeter animações**

```bash
python tools/pixellab_download.py character <CHAR_ID> characters/bosses/galerix/
```

Walk:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "swift gliding walk cycle, storm hawk, wind energy trailing",
    "directions": ["west", "east"],
    "frame_count": 8,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("walk jobs:", data["background_job_ids"])
```

Entry:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "dramatic entrance, storm hawk diving in at high speed and landing in battle stance, facing camera",
    "directions": ["south"],
    "frame_count": 6,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("entry job:", data["background_job_ids"][0])
```

- [ ] **Step 3: Baixar e compor**

```bash
python tools/pixellab_download.py animation <WALK_W_JOB> characters/bosses/galerix/ --direction west --action walk
python tools/pixellab_download.py animation <WALK_E_JOB> characters/bosses/galerix/ --direction east --action walk
python tools/pixellab_download.py animation <ENTRY_JOB> characters/bosses/galerix/ --direction south --action entry
python tools/compose_spritesheet.py galerix walk west
python tools/compose_spritesheet.py galerix walk east
python tools/compose_spritesheet.py galerix entry south
```

- [ ] **Step 4: Commitar**

```bash
git add characters/bosses/galerix/
git commit -m "assets(galerix): PixelLab sprites — idle 4-dir, walk west/east, entry south"
```

---

## Task 7: Gerar sprites — Umbraex (Pantera das Sombras)

**Files:**
- Create: `characters/bosses/umbraex/` (mesma estrutura)

- [ ] **Step 1: Criar personagem**

```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "description": "Umbraex shadow panther boss, sleek dark feline body with layered black and dark purple armor, shadow tendrils extending from body, multiple glowing purple eyes, partially intangible form dissolving into darkness, predatory low crouched stance, Mega Man X style pixel art, side view",
    "image_size": {"width": 128, "height": 128},
    "view": "side",
    "proportions": {"type": "preset", "name": "heroic"},
    "outline": "single color outline",
    "shading": "basic shading",
    "detail": "medium detail"
}).encode()
req = urllib.request.Request(
    "https://api.pixellab.ai/v2/create-character-with-4-directions",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("character_id:", data["character_id"])
```

- [ ] **Step 2: Baixar referência + submeter animações**

```bash
python tools/pixellab_download.py character <CHAR_ID> characters/bosses/umbraex/
```

Walk:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "stalking predator walk cycle, shadow panther, low crouched",
    "directions": ["west", "east"],
    "frame_count": 8,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("walk jobs:", data["background_job_ids"])
```

Entry:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "dramatic entrance, shadow panther materializing from darkness, facing camera, shadow tendrils spreading",
    "directions": ["south"],
    "frame_count": 6,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("entry job:", data["background_job_ids"][0])
```

- [ ] **Step 3: Baixar e compor**

```bash
python tools/pixellab_download.py animation <WALK_W_JOB> characters/bosses/umbraex/ --direction west --action walk
python tools/pixellab_download.py animation <WALK_E_JOB> characters/bosses/umbraex/ --direction east --action walk
python tools/pixellab_download.py animation <ENTRY_JOB> characters/bosses/umbraex/ --direction south --action entry
python tools/compose_spritesheet.py umbraex walk west
python tools/compose_spritesheet.py umbraex walk east
python tools/compose_spritesheet.py umbraex entry south
```

- [ ] **Step 4: Commitar**

```bash
git add characters/bosses/umbraex/
git commit -m "assets(umbraex): PixelLab sprites — idle 4-dir, walk west/east, entry south"
```

---

## Task 8: Gerar sprites — Luxar (Leão Solar)

**Files:**
- Create: `characters/bosses/luxar/` (mesma estrutura)

- [ ] **Step 1: Criar personagem**

```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "description": "Luxar solar lion boss, majestic armored lion, radiant white and gold mane with light rays, blinding energy core in chest, halo crown of sunrays, golden claws, proud regal battle stance, Mega Man X style pixel art, side view",
    "image_size": {"width": 128, "height": 128},
    "view": "side",
    "proportions": {"type": "preset", "name": "heroic"},
    "outline": "single color outline",
    "shading": "basic shading",
    "detail": "medium detail"
}).encode()
req = urllib.request.Request(
    "https://api.pixellab.ai/v2/create-character-with-4-directions",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("character_id:", data["character_id"])
```

- [ ] **Step 2: Baixar referência + submeter animações**

```bash
python tools/pixellab_download.py character <CHAR_ID> characters/bosses/luxar/
```

Walk:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "regal powerful walking cycle, solar lion, mane radiating light",
    "directions": ["west", "east"],
    "frame_count": 8,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("walk jobs:", data["background_job_ids"])
```

Entry:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "dramatic entrance, solar lion descending in pillar of light, landing in proud stance, facing camera",
    "directions": ["south"],
    "frame_count": 6,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("entry job:", data["background_job_ids"][0])
```

- [ ] **Step 3: Baixar e compor**

```bash
python tools/pixellab_download.py animation <WALK_W_JOB> characters/bosses/luxar/ --direction west --action walk
python tools/pixellab_download.py animation <WALK_E_JOB> characters/bosses/luxar/ --direction east --action walk
python tools/pixellab_download.py animation <ENTRY_JOB> characters/bosses/luxar/ --direction south --action entry
python tools/compose_spritesheet.py luxar walk west
python tools/compose_spritesheet.py luxar walk east
python tools/compose_spritesheet.py luxar entry south
```

- [ ] **Step 4: Commitar**

```bash
git add characters/bosses/luxar/
git commit -m "assets(luxar): PixelLab sprites — idle 4-dir, walk west/east, entry south"
```

---

## Task 9: Gerar sprites — Terragor (Gorila de Pedra)

**Files:**
- Create: `characters/bosses/terragor/` (mesma estrutura)

- [ ] **Step 1: Criar personagem**

```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "description": "Terragor stone gorilla boss, massive armored gorilla with boulder-sized fists, stone-plated body with rock spikes along back and shoulders, earth brown and grey, knuckle-dragging powerful stance, Mega Man X style pixel art, side view",
    "image_size": {"width": 128, "height": 128},
    "view": "side",
    "proportions": {"type": "preset", "name": "heroic"},
    "outline": "single color outline",
    "shading": "basic shading",
    "detail": "medium detail"
}).encode()
req = urllib.request.Request(
    "https://api.pixellab.ai/v2/create-character-with-4-directions",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("character_id:", data["character_id"])
```

- [ ] **Step 2: Baixar referência + submeter animações**

```bash
python tools/pixellab_download.py character <CHAR_ID> characters/bosses/terragor/
```

Walk:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "knuckle-dragging gorilla walking cycle, stone golem, heavy shaking steps",
    "directions": ["west", "east"],
    "frame_count": 8,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("walk jobs:", data["background_job_ids"])
```

Entry:
```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "character_id": "<CHAR_ID>",
    "action_description": "dramatic entrance, stone gorilla crashing through ground, rising to full height, facing camera, rocks falling",
    "directions": ["south"],
    "frame_count": 6,
    "mode": "v3"
}).encode()
req = urllib.request.Request("https://api.pixellab.ai/v2/animate-character",
    data=body, headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("entry job:", data["background_job_ids"][0])
```

- [ ] **Step 3: Baixar e compor**

```bash
python tools/pixellab_download.py animation <WALK_W_JOB> characters/bosses/terragor/ --direction west --action walk
python tools/pixellab_download.py animation <WALK_E_JOB> characters/bosses/terragor/ --direction east --action walk
python tools/pixellab_download.py animation <ENTRY_JOB> characters/bosses/terragor/ --direction south --action entry
python tools/compose_spritesheet.py terragor walk west
python tools/compose_spritesheet.py terragor walk east
python tools/compose_spritesheet.py terragor entry south
```

- [ ] **Step 4: Commitar**

```bash
git add characters/bosses/terragor/
git commit -m "assets(terragor): PixelLab sprites — idle 4-dir, walk west/east, entry south"
```

---

## Task 10: Integrar sprites em todos os 8 bosses (.tscn + .gd)

**Files:**
- Modify: `characters/bosses/ignarath.tscn`, `cryovex.tscn`, `voltrix.tscn`, `gravitus.tscn`, `galerix.tscn`, `umbraex.tscn`, `luxar.tscn`, `terragor.tscn`
- Modify: `characters/bosses/ignarath.gd`, `cryovex.gd`, `voltrix.gd`, `gravitus.gd`, `galerix.gd`, `umbraex.gd`, `luxar.gd`, `terragor.gd`

- [ ] **Step 1: Adicionar Sprite2D a cada .tscn**

Cada arquivo `.tscn` termina com as propriedades do nó root. Adicionar a linha abaixo ao final de **cada um dos 8 arquivos** (ignarath.tscn, cryovex.tscn, ... terragor.tscn):

```
[node name="Sprite2D" type="Sprite2D" parent="."]
```

Exemplo — `characters/bosses/ignarath.tscn` após a edição:
```
[gd_scene format=3 uid="uid://ignarath"]

[ext_resource type="PackedScene" uid="uid://boss_base" path="res://characters/bosses/boss_base.tscn" id="1_base"]
[ext_resource type="Script" path="res://characters/bosses/ignarath.gd" id="2_script"]

[node name="Ignarath" instance=ExtResource("1_base")]
script = ExtResource("2_script")
boss_id = "ignarath"
weakness_id = "galerix"
ability_id = "ignarath"
stage_id = 1
max_hp = 200
boss_color = Color(0.9, 0.3, 0.0, 1)

[node name="Sprite2D" type="Sprite2D" parent="."]
```

Aplicar o mesmo padrão aos outros 7 arquivos .tscn (apenas o nó root muda de nome/uid/propriedades).

- [ ] **Step 2: Adicionar bloco de sprites a cada .gd**

O bloco de animação abaixo é **idêntico** para todos os 8 bosses exceto pelas 5 linhas de `preload`. Adicionar imediatamente após `extends BossBase` em cada arquivo:

**Tabela de preload por boss** (substituir `<name>` pelo nome do boss):

| Boss | `<name>` no preload |
|------|---------------------|
| ignarath | `ignarath` |
| cryovex | `cryovex` |
| voltrix | `voltrix` |
| gravitus | `gravitus` |
| galerix | `galerix` |
| umbraex | `umbraex` |
| luxar | `luxar` |
| terragor | `terragor` |

**Bloco a adicionar** (inserir logo após `extends BossBase`, antes de qualquer outra linha):

```gdscript
const _TEX_IDLE_W := preload("res://characters/bosses/<name>/<name>_west.png")
const _TEX_IDLE_E := preload("res://characters/bosses/<name>/<name>_east.png")
const _TEX_WALK_W := preload("res://characters/bosses/<name>/<name>_walk_west.png")
const _TEX_WALK_E := preload("res://characters/bosses/<name>/<name>_walk_east.png")
const _TEX_ENTRY  := preload("res://characters/bosses/<name>/<name>_entry.png")

const _WALK_FRAMES  := 8
const _WALK_FPS     := 8.0
const _ENTRY_FRAMES := 6
const _ENTRY_FPS    := 8.0

var _anim_timer : float = 0.0
var _anim_frame : int   = 0
var _facing     : float = -1.0

@onready var _sprite: Sprite2D = $Sprite2D

func _draw() -> void:
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	draw_rect(Rect2(-24, -52, 48, 6), Color.BLACK)
	draw_rect(Rect2(-24, -52, 48.0 * pct, 6), Color.GREEN)

func _face_player() -> void:
	pass

func _physics_process(delta: float) -> void:
	super(delta)
	_update_animation(delta)

func _update_animation(delta: float) -> void:
	if state == State.INTRO:
		_sprite.texture = _TEX_ENTRY
		_sprite.hframes = _ENTRY_FRAMES
		_anim_timer += delta
		if _anim_timer >= 1.0 / _ENTRY_FPS:
			_anim_timer -= 1.0 / _ENTRY_FPS
			_anim_frame = mini(_anim_frame + 1, _ENTRY_FRAMES - 1)
		_sprite.frame    = _anim_frame
		_sprite.modulate = Color.WHITE
		return
	if state in [State.DYING, State.DEAD]:
		return
	if   velocity.x >  10.0: _facing =  1.0
	elif velocity.x < -10.0: _facing = -1.0
	var tex   : Texture2D
	var frames: int
	var fps   : float
	if absf(velocity.x) > 10.0:
		tex = _TEX_WALK_E if _facing > 0.0 else _TEX_WALK_W
		frames = _WALK_FRAMES; fps = _WALK_FPS
	else:
		tex = _TEX_IDLE_E if _facing > 0.0 else _TEX_IDLE_W
		frames = 1; fps = 4.0
	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = frames
		_anim_frame = 0; _anim_timer = 0.0
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var a := 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, a)
	else:
		_sprite.modulate = Color.WHITE
	_anim_timer += delta
	if frames > 1 and _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		_anim_frame = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame
```

- [ ] **Step 3: Rodar testes headless**

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```

Expected: exit code 0 em todos. Se algum falhar, verificar se `preload()` tem path correto nos 8 bosses.

- [ ] **Step 4: Commitar**

```bash
git add characters/bosses/
git commit -m "feat(bosses): Sprite2D + animation system — idle/walk/entry for all 8 elemental bosses"
```

---

## Task 11: Web export + verificação visual

**Files:**
- No code changes

- [ ] **Step 1: Web export**

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" "C:\Users\Usuário\SnesGame\export\web\index.html" 2>&1
```

- [ ] **Step 2: Verificar PCK**

```powershell
Get-Item "C:\Users\Usuário\SnesGame\export\web\index.pck" | Select-Object LastWriteTime, Length
```

`LastWriteTime` deve ser recente. Se não mudou → erro no export, parar.

- [ ] **Step 3: Reiniciar servidor e confirmar 200**

```powershell
powershell -Command "
  \$pids = (netstat -ano | findstr ':8080' | ForEach-Object { (\$_ -split '\s+')[-1] } | Sort-Object -Unique);
  foreach (\$p in \$pids) { Stop-Process -Id \$p -Force -ErrorAction SilentlyContinue };
  Start-Process python -ArgumentList 'C:\Users\Usuário\SnesGame\serve_web.py' -WindowStyle Hidden;
  Start-Sleep 2;
  (Invoke-WebRequest http://localhost:8080 -UseBasicParsing).StatusCode
"
```

Expected: `200`.

- [ ] **Step 4: Commitar e fazer push**

```bash
git add -f export/web/
git commit -m "chore: web export — boss sprites 8 elemental bosses (idle/walk/entry)"
git push origin master
```
