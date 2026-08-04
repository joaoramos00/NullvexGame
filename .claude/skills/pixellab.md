# Skill: pixellab

Use quando o usuário pedir para gerar sprites de inimigos, bosses ou tilesets usando PixelLab.

Para efeitos visuais de habilidades/poderes (burst, projétil, impacto — uma direção só com etapa de escolha entre candidatos), usar a skill `pixellab-effect` ao invés desta.

## Pré-requisitos

**MCP PixelLab carregado.** Confirmar com:
```bash
claude mcp list
```
Deve mostrar `pixellab: https://api.pixellab.ai/mcp (HTTP) - ✔ Connected`. Se não estiver, o MCP foi adicionado à config user (`~/.claude.json`) mas Claude Code precisa ser reiniciado para descobrir as tools. As tools aparecem como `mcp__pixellab__*` na sessão após reinício.

**`.env` com `PIXELLAB_API_KEY`** ainda é necessário — as tools MCP submetem os jobs, mas o `tools/pixellab_download.py` faz o polling e download final direto pela REST API e precisa da chave. Carregar na sessão se necessário:
```powershell
$env:PIXELLAB_API_KEY = (Get-Content .env | Select-String "PIXELLAB_API_KEY").ToString().Split("=")[1]
```

**Checar créditos antes de gerar:** chamar `mcp__pixellab__get_balance` (sem argumentos). Confirmar créditos suficientes antes de disparar jobs.

## Tamanhos Canônicos

| Asset | `size` | Tool MCP |
|-------|--------|---------|
| Inimigo (grunt, flyer) | 64 | `mcp__pixellab__create_character` (n_directions=4) |
| Boss elemental | 128 | `mcp__pixellab__create_character` (n_directions=4) |
| Tileset de fase | tile 32×32 | `mcp__pixellab__create_sidescroller_tileset` |

## Workflow: Gerar Personagem (inimigo ou boss)

### Passo 1 — Submeter geração base

Chamar `mcp__pixellab__create_character` com:
```json
{
  "name": "<nome curto, ex: 'Grunt' ou 'Ignarath'>",
  "description": "<descrição — ver tabela canônica abaixo>",
  "size": 64,
  "view": "side",
  "n_directions": 4,
  "mode": "standard",
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "proportions": "{\"type\": \"preset\", \"name\": \"heroic\"}"
}
```
Para bosses: `size: 128` e `detail: "high detail"`. Guardar o `character_id` retornado.

### Passo 2 — Aguardar (opcional: poll via MCP)

Chamar `mcp__pixellab__get_character` com `{"character_id": "<id>"}` até `status == "completed"` e `rotation_urls` populado. Ou pular direto pro passo 3 — o script de download já faz esse poll.

### Passo 3 — Baixar sprites base (4 direções)

```powershell
python tools/pixellab_download.py character <character_id> characters/enemies/<nome>/
```

Salva: `<nome>_south.png`, `<nome>_west.png`, `<nome>_east.png`, `<nome>_north.png`. Script faz poll automático (~2-5 min).

### Passo 4 — Submeter animações

Chamar `mcp__pixellab__animate_character` uma vez por animação/direção necessária:
```json
{
  "character_id": "<character_id>",
  "action_description": "<descrição do movimento — ex: 'walking cycle, looping'>",
  "directions": ["west", "east"],
  "frame_count": 8,
  "mode": "v3"
}
```
Retorna `background_job_ids[]` — um por direção passada. Guardar cada job_id.

**Notas:**
- `frame_count: 8` produz 9 frames (inclui o frame de fechamento do ciclo)
- `mode: "v3"` é o modelo atual — usar sempre
- Passar múltiplas direções na mesma call é OK; retorna N jobs no array

### Passo 5 — Baixar frames de animação

```powershell
python tools/pixellab_download.py animation <job_west_id> characters/enemies/<nome>/ --direction west --action walk
python tools/pixellab_download.py animation <job_east_id> characters/enemies/<nome>/ --direction east --action walk
```
Salva:
- PNGs: `<nome>_walk_west_f00.png` … `<nome>_walk_west_f08.png`
- GIF preview: `<nome>_walk_west.gif`

## Workflow: Gerar Tileset de Fase

### Passo 1 — Submeter tileset base (primeira zona)

Chamar `mcp__pixellab__create_sidescroller_tileset`:
```json
{
  "lower_description": "<material principal — ex: 'volcanic rock, dark basalt, glowing magma veins'>",
  "transition_description": "<topo — ex: 'cracked burnt rock top surface, glowing lava pools'>",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
Guardar o `tileset_id`.

### Passo 2 — Baixar

```powershell
python tools/pixellab_download.py tileset <tileset_id> stages/<stage>/
```
Salva: `stages/<stage>/tileset.png`. Renomear conforme necessário (ex: `Stage_01T_z1.png`).

### Passo 3 (encadeamento) — Zonas seguintes na mesma fase

Se a fase tem múltiplas zonas visuais que devem parecer parte do mesmo mundo, encadear via `base_tile_id`:

1. Chamar `mcp__pixellab__get_sidescroller_tileset` com `{"tileset_id": "<Z1_ID>"}` — anotar o campo `base_tile_id` da resposta.
2. Chamar `mcp__pixellab__create_sidescroller_tileset` da próxima zona incluindo `"base_tile_id": "<Z1_base_tile_id>"` no body.

Isso mantém paleta e estilo consistentes entre zonas encadeadas.

## Descriptions Canônicas

### Inimigos
| Nome | Description |
|------|-------------|
| grunt | `"armored grunt soldier, side-scrolling enemy, blue metallic armor, visor helmet, Mega Man X style pixel art"` |
| flyer | `"flying drone enemy, side-scrolling, metallic body, glowing engine thruster, Mega Man X style pixel art"` |

### Bosses (size: 128, detail: high)
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
characters/bosses/ignarath/     ignarath_south.png, ignarath_walk_west.gif, ...
characters/bosses/cryovex/
characters/bosses/voltrix/
characters/bosses/gravitus/
characters/bosses/galerix/
characters/bosses/umbraex/
characters/bosses/luxar/
characters/bosses/terragor/
stages/stage_00/tileset/        tileset.png
```

## Notas Técnicas

- `create_character` retorna `character_id` imediatamente — a geração é assíncrona (~2-5 min); o script de download faz poll
- `animate_character` retorna `background_job_ids[]`, um por direção passada
- Frames de animação chegam como `rgba_bytes` (base64 de bytes RGBA crus, não PNG) — o script converte via Pillow
- `frame_count: N` produz `N+1` frames (inclui frame de fechamento)
- Canvas real pode ser ligeiramente maior que o `size` solicitado (ex: 64→92px) por ajuste interno do template mannequin
- URLs diretas do Backblaze retornam 403 para characters/animations — o download script usa `GET /v2/characters/{id}/zip` com Bearer token
- Tilesets vêm em URLs públicas do Backblaze (sem Bearer) — download direto

## Fallback: REST puro sem MCP

Se o MCP não estiver disponível (ex: sessão sem tools carregadas), os mesmos endpoints existem via REST — usar `urllib.request` com `Authorization: Bearer $PIXELLAB_API_KEY`. Endpoints equivalentes:

| Tool MCP | Endpoint REST |
|----------|---------------|
| `get_balance` | `GET /v2/balance` |
| `create_character` | `POST /v2/create-character-with-4-directions` (body igual, sem `name` obrigatório) |
| `get_character` | `GET /v2/characters/{id}` |
| `animate_character` | `POST /v2/animate-character` |
| `create_sidescroller_tileset` | `POST /v2/tilesets-sidescroller` |
| `get_sidescroller_tileset` | `GET /v2/tilesets-sidescroller/{id}` |

Preferir sempre o MCP quando disponível — chama direto na conversa, sem boilerplate de HTTP.
