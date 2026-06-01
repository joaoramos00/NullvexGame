# PixelLab Asset Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrar o MCP do PixelLab ao Claude Code e criar `tools/pixellab_download.py` + `.claude/skills/pixellab.md` para geração e download automático de sprites de inimigos/bosses e tilesets.

**Architecture:** MCP server do PixelLab registrado em `.claude/settings.local.json` (local, não commitado). Script Python CLI cuida de poll + download + conversão rgba_bytes→PNG. Skill documenta o workflow completo com request bodies canônicos para cada tipo de asset.

**Tech Stack:** Python 3 stdlib (`urllib.request`, `zipfile`, `argparse`, `base64`), Pillow 12.2.0, PixelLab REST API v2.

---

## Arquivos

| Ação | Arquivo | Responsabilidade |
|------|---------|-----------------|
| Modify | `.gitignore` | Ignorar settings.local.json para proteger o token |
| Modify | `.claude/settings.local.json` | Adicionar bloco mcpServers com token PixelLab |
| Modify | `.claude/settings.json` | Registrar skill `pixellab` |
| Create | `tools/pixellab_download.py` | CLI: download de character/animation/tileset |
| Create | `.claude/skills/pixellab.md` | Skill: workflow completo com bodies canônicos |

---

## Task 1: Proteger settings.local.json e configurar MCP

**Files:**
- Modify: `.gitignore`
- Modify: `.claude/settings.local.json`

- [ ] **Step 1: Adicionar settings.local.json ao .gitignore**

Abrir `.gitignore` e adicionar ao final:
```
.claude/settings.local.json
```

- [ ] **Step 2: Destrackear o arquivo do git**

```bash
git rm --cached .claude/settings.local.json
```

Expected output: `rm '.claude/settings.local.json'`

- [ ] **Step 3: Adicionar bloco mcpServers ao settings.local.json**

Ler o arquivo atual e adicionar `mcpServers` antes do fechamento do objeto. Ler o token do `.env` primeiro:

```powershell
$key = (Get-Content .env | Select-String "PIXELLAB_API_KEY").ToString().Split("=")[1]
```

O arquivo final `.claude/settings.local.json` deve ter esta estrutura (preservar tudo que já existe em `permissions` e `enabledPlugins`, adicionar `mcpServers`):

```json
{
  "permissions": {
    "allow": [ ... (manter existente) ... ],
    "deny": [ ... (manter existente) ... ],
    "defaultMode": "bypassPermissions"
  },
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true
  },
  "mcpServers": {
    "pixellab": {
      "url": "https://api.pixellab.ai/mcp",
      "transport": "http",
      "headers": {
        "Authorization": "Bearer c8ba7078-5b42-4d98-8a5f-ed8d57b1e0f1"
      }
    }
  }
}
```

- [ ] **Step 4: Registrar skill pixellab em settings.json**

Em `.claude/settings.json`, adicionar `"pixellab": ".claude/skills/pixellab.md"` ao objeto `skills`:

```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true
  },
  "skills": {
    "new-enemy":  ".claude/skills/new-enemy.md",
    "new-boss":   ".claude/skills/new-boss.md",
    "new-stage":  ".claude/skills/new-stage.md",
    "run-tests":  ".claude/skills/run-tests.md",
    "web-export": ".claude/skills/web-export.md",
    "pixellab":   ".claude/skills/pixellab.md"
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add .gitignore .claude/settings.json
git commit -m "feat(pixellab): register MCP server and pixellab skill"
```

---

## Task 2: Criar tools/pixellab_download.py

**Files:**
- Create: `tools/pixellab_download.py`

- [ ] **Step 1: Criar diretório e arquivo**

```bash
mkdir -p tools
```

Criar `tools/pixellab_download.py` com o seguinte conteúdo completo:

```python
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
            if not member.endswith(".png"):
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

    p_char = sub.add_parser("character", help="Download character sprites ZIP → PNG")
    p_char.add_argument("character_id", help="ID returned by create-character-with-4-directions")
    p_char.add_argument("dest", help="Destination folder, e.g. characters/enemies/grunt")

    p_anim = sub.add_parser("animation", help="Poll animation job and save frames")
    p_anim.add_argument("job_id", help="background_job_id from animate-character response")
    p_anim.add_argument("dest", help="Destination folder, e.g. characters/enemies/grunt")
    p_anim.add_argument("--direction", required=True, choices=["west", "east", "south", "north"])
    p_anim.add_argument("--action", required=True, choices=["walk", "idle", "attack", "death", "hit"])

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
```

- [ ] **Step 2: Smoke test — help output**

```bash
python tools/pixellab_download.py --help
```

Expected output:
```
usage: pixellab_download.py [-h] {character,animation,tileset} ...

PixelLab asset downloader

positional arguments:
  {character,animation,tileset}
    character           Download character sprites ZIP → PNG
    animation           Poll animation job and save frames
    tileset             Poll and download sidescroller tileset
```

- [ ] **Step 3: Smoke test — subcommand help**

```bash
python tools/pixellab_download.py character --help
python tools/pixellab_download.py animation --help
```

Expected: cada subcomando exibe seus argumentos sem erros.

- [ ] **Step 4: Smoke test — erro sem API key**

Temporariamente renomear `.env` para `.env.bak`, rodar, restaurar:

```bash
python tools/pixellab_download.py character test-id characters/enemies/grunt
```

Expected output: `PIXELLAB_API_KEY not found in .env or environment`

- [ ] **Step 5: Smoke test — download real (usa test_pixellab existente)**

O character `41149552-0431-495c-bd45-f5bdb784c9f0` já foi gerado na sessão de brainstorming. Testar download:

```bash
python tools/pixellab_download.py character 41149552-0431-495c-bd45-f5bdb784c9f0 test_pixellab/grunt_script_test
```

Expected: 4 arquivos criados (`grunt_script_test_south.png`, `_west.png`, `_east.png`, `_north.png`).

- [ ] **Step 6: Smoke test — download de animação (usa jobs existentes)**

Job west `7390ffd7-e001-4897-8e28-578b161d5a3a` já completou:

```bash
python tools/pixellab_download.py animation 7390ffd7-e001-4897-8e28-578b161d5a3a test_pixellab/grunt_script_test --direction west --action walk
```

Expected: 9 arquivos PNG + 1 GIF criados na pasta.

- [ ] **Step 7: Commit**

```bash
git add tools/pixellab_download.py
git commit -m "feat(pixellab): add download script — character/animation/tileset CLI"
```

---

## Task 3: Criar .claude/skills/pixellab.md

**Files:**
- Create: `.claude/skills/pixellab.md`

- [ ] **Step 1: Criar a skill**

Criar `.claude/skills/pixellab.md` com o seguinte conteúdo:

```markdown
# Skill: pixellab

Use quando o usuário pedir para gerar sprites de inimigos, bosses ou tilesets usando PixelLab.

## Pré-requisitos

`PIXELLAB_API_KEY` deve estar em `.env`. Carregar na sessão se necessário:

```powershell
$env:PIXELLAB_API_KEY = (Get-Content .env | Select-String "PIXELLAB_API_KEY").ToString().Split("=")[1]
echo $env:PIXELLAB_API_KEY
```

Checar créditos antes de gerar:

```python
import urllib.request, json
key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
req = urllib.request.Request("https://api.pixellab.ai/v2/balance", headers={"Authorization": f"Bearer {key}"})
with urllib.request.urlopen(req) as r: print(json.loads(r.read()))
```

## Tamanhos Canônicos

| Asset | Canvas (`image_size`) | Endpoint |
|-------|----------------------|---------|
| Inimigo (grunt, flyer) | 64×64 | `POST /v2/create-character-with-4-directions` |
| Boss elemental | 128×128 | `POST /v2/create-character-with-4-directions` |
| Tileset de fase | 32×32 tile | MCP `create_sidescroller_tileset` |

## Workflow: Gerar Personagem

### Passo 1 — Criar

```python
import urllib.request, json

key = open(".env").read().split("PIXELLAB_API_KEY=")[1].split()[0]
body = json.dumps({
    "description": "<descrição — ver tabela abaixo>",
    "image_size": {"width": 64, "height": 64},  # 128x128 para bosses
    "view": "side",
    "proportions": {"type": "preset", "name": "heroic"},
    "outline": "single color outline",
    "shading": "basic shading",
    "detail": "medium detail"
}).encode()

req = urllib.request.Request(
    "https://api.pixellab.ai/v2/create-character-with-4-directions",
    data=body,
    headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
)
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
print("character_id:", data["character_id"])
```

### Passo 2 — Baixar sprites

```bash
python tools/pixellab_download.py character <character_id> characters/enemies/<nome>/
```

O script faz poll automaticamente até `rotation_urls` estar pronto (~2–5 min).
Salva: `<nome>_south.png`, `<nome>_west.png`, `<nome>_east.png`, `<nome>_north.png`

### Passo 3 — Animar

```python
body = json.dumps({
    "character_id": "<character_id>",
    "action_description": "<descrição — ex: 'walking cycle, looping'>",
    "directions": ["west", "east"],
    "frame_count": 8,
    "mode": "v3"
}).encode()

req = urllib.request.Request(
    "https://api.pixellab.ai/v2/animate-character",
    data=body,
    headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
)
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read())
# data["background_job_ids"][0] = job para "west"
# data["background_job_ids"][1] = job para "east"
print("jobs:", data["background_job_ids"])
```

### Passo 4 — Baixar frames de animação

```bash
python tools/pixellab_download.py animation <job_west_id> characters/enemies/<nome>/ --direction west --action walk
python tools/pixellab_download.py animation <job_east_id> characters/enemies/<nome>/ --direction east --action walk
```

O script faz poll (~2–3 min por direção) e salva:
- PNGs: `<nome>_walk_west_f00.png` … `<nome>_walk_west_f08.png`
- GIF preview: `<nome>_walk_west.gif`

## Workflow: Gerar Tileset

Usar MCP tool diretamente na sessão Claude Code:

```
create_sidescroller_tileset({
  "lower_description": "<material — ex: dark stone, metallic panels>",
  "transition_description": "<topo — ex: cracked edge, mossy border>",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
})
```

Depois baixar com o script:

```bash
python tools/pixellab_download.py tileset <tileset_id> stages/<stage>/tileset/
```

## Descriptions Canônicas

### Inimigos
| Nome | Description |
|------|-------------|
| grunt | `"armored grunt soldier, side-scrolling enemy, blue metallic armor, visor helmet, Mega Man X style pixel art"` |
| flyer | `"flying drone enemy, side-scrolling, metallic body, glowing engine thruster, Mega Man X style pixel art"` |

### Bosses (128×128)
| Boss | Description |
|------|-------------|
| Ignarath | `"Ignarath fire elemental boss, hulking armored figure, molten lava cracks in armor, flaming shoulder pads, red and orange palette, Mega Man X style pixel art, side view"` |
| Cryovex | `"Cryovex ice elemental boss, crystalline armor with frost spikes, cold blue and white palette, breath of frozen mist, Mega Man X style pixel art, side view"` |
| Voltrix | `"Voltrix lightning elemental boss, electric coils wrapped around armor, jagged yellow and black plates, sparking gauntlets, Mega Man X style pixel art, side view"` |
| Gravitus | `"Gravitus gravity elemental boss, heavy armored titan, dark purple and black plates, gravitational orbs orbiting the body, Mega Man X style pixel art, side view"` |
| Galerix | `"Galerix wind elemental boss, sleek aerodynamic armor, teal and white, wind turbines mounted on back, flowing energy trails, Mega Man X style pixel art, side view"` |
| Umbraex | `"Umbraex shadow elemental boss, dark phantom figure, black and dark purple layered armor, shadow tendrils extending from body, Mega Man X style pixel art, side view"` |
| Luxar | `"Luxar light elemental boss, radiant white and gold armor, halo-like crown, blinding energy core in chest, Mega Man X style pixel art, side view"` |
| Terragor | `"Terragor earth elemental boss, stone-plated golem, earth brown and grey boulders as armor, rock spikes on shoulders, Mega Man X style pixel art, side view"` |

## Folder Mapping

```
characters/enemies/grunt/       grunt_south.png, grunt_walk_west.gif, ...
characters/enemies/flyer/       flyer_south.png, flyer_walk_west.gif, ...
characters/enemies/ignarath/    ignarath_south.png, ignarath_walk_west.gif, ...
characters/enemies/cryovex/
characters/enemies/voltrix/
characters/enemies/gravitus/
characters/enemies/galerix/
characters/enemies/umbraex/
characters/enemies/luxar/
characters/enemies/terragor/
stages/stage_00/tileset/        tileset.png
```

## Notas Técnicas

- `create-character-with-4-directions` retorna `character_id` + `background_job_id` imediatamente — a geração é assíncrona (~2-5 min)
- URLs diretas do Backblaze retornam 403 — sempre usar `GET /v2/characters/{id}/zip` com Bearer token
- Frames de animação chegam como `rgba_bytes` (base64 de bytes RGBA crus, não PNG) — o script converte via Pillow
- `frame_count: 8` produz 9 frames (inclui frame de fechamento do ciclo de caminhada)
- `image_size` (não `size`) é o campo correto no body
- O canvas real pode ser ligeiramente maior que o solicitado (ex: 64→92px) por ajuste interno do template mannequin
```

- [ ] **Step 2: Verificar que a skill está listada corretamente em settings.json**

```bash
python -c "import json; d=json.load(open('.claude/settings.json')); print(d['skills'].get('pixellab', 'NOT FOUND'))"
```

Expected: `.claude/skills/pixellab.md`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/pixellab.md
git commit -m "feat(pixellab): add pixellab skill with canonical workflow and descriptions"
```

---

## Task 4: Limpar arquivos de teste

**Files:**
- Delete: `test_pixellab/` (pasta temporária criada durante brainstorming)

- [ ] **Step 1: Remover pasta de teste**

```bash
git rm -r test_pixellab/
```

- [ ] **Step 2: Commit**

```bash
git commit -m "chore: remove test_pixellab temp folder from brainstorming session"
```

---

## Verificação Final

- [ ] Rodar `python tools/pixellab_download.py --help` — sem erros
- [ ] Abrir nova sessão Claude Code, digitar `/pixellab` — skill carrega
- [ ] MCP PixelLab aparece disponível em nova sessão (verificar com `claude mcp list` se disponível)
