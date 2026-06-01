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
