# Stage Tilesets 01–09 — Design Spec

**Data:** 2026-06-01  
**Status:** Aprovado

---

## Objetivo

Gerar tilesets visuais para os stages 01 a 09 usando PixelLab `create_sidescroller_tileset`, integrar ao `stage_scene.gd` com suporte a múltiplas zonas por fase, e referenciar os tilesets existentes no stage 09 (gauntlet).

---

## 1. Geração de Tilesets

### Volume

- **Stages 01–08:** 4 zonas temáticas + 1 parede lisa por stage = **5 tilesets × 8 = 40 tilesets**
- **Stage 09:** sem geração nova — reutiliza tilesets dos stages 01–08

### Parâmetros fixos (todos os tilesets)

```
tile_size: {width: 32, height: 32}
outline: "single color outline"
shading: "basic shading"
detail: "medium detail"
transition_size: 0.25
```

### Descriptions por Stage

#### Stage 01 — Ignarath (Fogo/Vulcão)

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_01T_z1.png` | `"volcanic rock, molten lava cracks, dark basalt, glowing magma veins"` | `"jagged burnt rock edge, glowing lava rim"` |
| `Stage_01T_z2.png` | `"magma tunnel, lava tube walls, glowing orange cracks in dark rock"` | `"cracked magma edge, dripping lava border"` |
| `Stage_01T_z3.png` | `"industrial forge, molten metal panels, fire furnace brickwork, extreme heat"` | `"scorched metal edge, fire glow border"` |
| `Stage_01T_z4.png` | `"full lava chamber, ceiling of molten rock, submerged volcanic stone"` | `"melting rock edge, lava overflow border"` |
| `stage_01_glass.png` | `"polished dark metal wall, heat shimmer surface, smooth volcanic obsidian"` | `"clean obsidian edge, heat distortion border"` |

#### Stage 02 — Cryovex (Gelo)

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_02T_z1.png` | `"frozen tundra stone, snow-covered rock, pale ice blue surface"` | `"cracked ice edge, snowdrift border"` |
| `Stage_02T_z2.png` | `"ice cave walls, blue crystal formations embedded in rock, frost veins"` | `"crystal shard edge, frost crystal border"` |
| `Stage_02T_z3.png` | `"deep glacier, compressed blue ice, translucent frozen stone"` | `"fractured glacier edge, ice layer border"` |
| `Stage_02T_z4.png` | `"pure crystal chamber, reflective ice panels, deep cold blue"` | `"mirror ice edge, cold light border"` |
| `stage_02_glass.png` | `"smooth translucent ice panel, glass-clear frozen surface, pale blue"` | `"clean ice edge, glass frost border"` |

#### Stage 03 — Voltrix (Raio)

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_03T_z1.png` | `"overloaded power plant exterior, exposed cables, industrial metal plates"` | `"sparking electric edge, frayed cable border"` |
| `Stage_03T_z2.png` | `"generator room, yellow warning stripes, electric conduit panels"` | `"electric arc edge, circuit line border"` |
| `Stage_03T_z3.png` | `"coil chamber, electromagnetic coils wrapped around metal, electric arcs"` | `"high voltage edge, coil discharge border"` |
| `Stage_03T_z4.png` | `"lightning core chamber, ceiling with discharge bolts, charged metal panels"` | `"lightning bolt edge, plasma border"` |
| `stage_03_glass.png` | `"sealed electric panel, brushed metal surface, conductive smooth wall"` | `"clean metal edge, electric sheen border"` |

#### Stage 04 — Gravitus (Gravidade)

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_04T_z1.png` | `"space station exterior, dark vacuum panels, modular metallic structure"` | `"void edge, space station hull border"` |
| `Stage_04T_z2.png` | `"zero-G corridor, floating stone fragments, dark purple metallic tiles"` | `"crumbling dark stone edge, anti-gravity shimmer"` |
| `Stage_04T_z3.png` | `"gravity field chamber, deep purple panels, gravitational field line etchings"` | `"gravity distortion edge, field line border"` |
| `Stage_04T_z4.png` | `"gravity core, inverted rock formations, deep purple with energy orbs"` | `"singularity edge, gravitational collapse border"` |
| `stage_04_glass.png` | `"smooth dark metallic panel, zero-G module surface, matte space grey"` | `"clean dark edge, space hull border"` |

#### Stage 05 — Galerix (Vento)

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_05T_z1.png` | `"sky platform stone, wind-carved light grey rock, cloud streak etchings"` | `"eroded smooth edge, wind-blown dust border"` |
| `Stage_05T_z2.png` | `"wind tunnel walls, polished stone, airflow grooves carved in surface"` | `"wind groove edge, air current border"` |
| `Stage_05T_z3.png` | `"storm eye chamber, pale teal stone, swirling pattern etchings"` | `"cyclone edge, storm spiral border"` |
| `Stage_05T_z4.png` | `"atmospheric core, cloud-white stone panels, high-altitude light"` | `"cloud edge, atmospheric glow border"` |
| `stage_05_glass.png` | `"aerodynamic smooth surface, wind-polished pale stone, sleek wall"` | `"clean aero edge, polished wind border"` |

#### Stage 06 — Umbraex (Sombra)

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_06T_z1.png` | `"shadow realm entrance, black stone portal, dark crystalline panels"` | `"dissolving shadow edge, dark mist border"` |
| `Stage_06T_z2.png` | `"dark corridor, black and purple crystal stone, shadow tendrils etched"` | `"void tendril edge, shadow crystal border"` |
| `Stage_06T_z3.png` | `"void chamber, deep black stone, absence of light, dark mist embedded"` | `"void collapse edge, darkness border"` |
| `Stage_06T_z4.png` | `"shadow core, pure black crystalline panels, shadow energy emanating"` | `"shadow pulse edge, dark energy border"` |
| `stage_06_glass.png` | `"smooth black void panel, absorbing dark surface, matte shadow wall"` | `"clean shadow edge, void surface border"` |

#### Stage 07 — Luxar (Luz)

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_07T_z1.png` | `"radiant temple exterior, white stone with gold trim, glowing rune etchings"` | `"golden glowing edge, light ray border"` |
| `Stage_07T_z2.png` | `"light hall, white and gold panels, pillar bases with luminous veins"` | `"luminous pillar edge, gold trim border"` |
| `Stage_07T_z3.png` | `"sacred chamber, pure white stone, glowing runic inscriptions"` | `"sacred glow edge, holy light border"` |
| `Stage_07T_z4.png` | `"light core, blinding white panels, radiant energy embedded in stone"` | `"radiant burst edge, light overflow border"` |
| `stage_07_glass.png` | `"polished golden marble surface, luminous smooth wall, divine glow"` | `"clean gold edge, marble light border"` |

#### Stage 08 — Terragor (Terra)

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_08T_z1.png` | `"cave entrance, rough earth and rock, embedded fossils and roots"` | `"earthy crumbled edge, root and moss border"` |
| `Stage_08T_z2.png` | `"deep cave, layered stone with mineral veins, dark brown rock"` | `"layered rock edge, mineral vein border"` |
| `Stage_08T_z3.png` | `"underground ruins, ancient stone blocks, cracked earth with fossils"` | `"ancient ruin edge, crumbled stone border"` |
| `Stage_08T_z4.png` | `"earth core, compressed deep stone, massive rock crystal formations"` | `"crystal rock edge, deep earth border"` |
| `stage_08_glass.png` | `"smooth compressed stone surface, dense mineral wall, flat cave rock"` | `"clean dense edge, polished stone border"` |

---

## 2. Compatibilidade do Tileset

O `create_sidescroller_tileset` gera um grid 4×4 de tiles 32×32px (128×128px total) — exatamente o formato esperado por `_draw_platform_tiles()` e `_tile_at()` em `stage_00_scene.gd`. Nenhuma conversão ou adaptação de formato é necessária.

---

## 3. Alterações de Código

### `stages/stage_scene.gd`

Adicionar exports:
```gdscript
@export var zone_tilesets: Array[Texture2D] = []
@export var smooth_texture: Texture2D
@export var zone_bounds: PackedFloat32Array = []  # 3 valores: divide o stage em 4 zonas
@export var zone_use_y: bool = false              # false = zonas por X, true = por Y (stages verticais)
```

Lógica de seleção de zona em `_draw()`:
```gdscript
func _get_zone_tileset(center: Vector2) -> Texture2D:
    if zone_tilesets.is_empty(): return null
    var pos: float = center.y if zone_use_y else center.x
    var idx: int = 0
    for bound in zone_bounds:
        if pos > bound: idx += 1
    return zone_tilesets[mini(idx, zone_tilesets.size() - 1)]
```

`_draw_platform_tiles()` e `_gap_fill_tile()` portados de `stage_00_scene.gd` com assinatura `_draw_platform_tiles(rect: Rect2, tex: Texture2D)`. Fallback: se `tex == null`, usa `draw_rect` com `platform_color`.

### `stages/stage_09/stage_09_scene.gd`

Adicionar:
```gdscript
@export var room_tilesets: Array[Texture2D] = []  # 8 entradas, ordem dos bosses
```

`_draw()` determina sala pelo X do centro da plataforma vs posições de `_walls`. Seleciona `room_tilesets[room_idx]`. Fallback: `Color(0.35, 0.35, 0.35)` se array vazio.

### Cenas `.tscn` (stages 01–08)

Cada `stage_0X.tscn` recebe via inspector:
- `zone_tilesets`: array com os 4 PNGs gerados
- `smooth_texture`: o PNG `stage_0X_glass.png` (para uso futuro em `CorridorSection`)
- `zone_bounds`: 3 valores X (ou Y para stages verticais) que dividem o layout em 4 seções

`zone_use_y` é configurado por stage de acordo com o layout: stages com progressão vertical (ex: Voltrix — zigzag vertical) usam `true`; stages horizontais lineares usam `false` (default). Determinado durante a implementação ao revisar cada stage layout.

### `stages/stage_09/stage_09.tscn`

`room_tilesets` recebe as referências aos tilesets z1 dos stages 01–08 (1 tileset representativo por sala de boss).

---

## 4. Estrutura de Arquivos

```
stages/
  stage_01/
    Stage_01T_z1.png  Stage_01T_z2.png  Stage_01T_z3.png  Stage_01T_z4.png
    stage_01_glass.png
  stage_02/ ... (mesma estrutura)
  stage_03/
    Stage_03T_z1.png  Stage_03T_z2.png  Stage_03T_z3.png  Stage_03T_z4.png
    stage_03_glass.png
  ...
  stage_08/
    Stage_08T_z1.png  Stage_08T_z2.png  Stage_08T_z3.png  Stage_08T_z4.png
    stage_08_glass.png
  stage_09/
    (sem novos PNGs — referencia tilesets dos stages 01–08)
```

**Total de tilesets gerados: 40** (8 stages × 5 tilesets)

---

## 5. Stage 09 — Mapeamento de Salas

| Sala | Boss | Tileset Referenciado |
|------|------|----------------------|
| 0 | Ignarath | `stages/stage_01/Stage_01T_z1.png` |
| 1 | Cryovex | `stages/stage_02/Stage_02T_z1.png` |
| 2 | Voltrix | `stages/stage_03/Stage_03T_z1.png` |
| 3 | Gravitus | `stages/stage_04/Stage_04T_z1.png` |
| 4 | Galerix | `stages/stage_05/Stage_05T_z1.png` |
| 5 | Umbraex | `stages/stage_06/Stage_06T_z1.png` |
| 6 | Luxar | `stages/stage_07/Stage_07T_z1.png` |
| 7 | Terragor | `stages/stage_08/Stage_08T_z1.png` |

---

## 6. Nota sobre Stage 01

O arquivo `stages/stage_01/Stage_01T.png` já existe (gerado anteriormente). Será **substituído** pelos novos `Stage_01T_z1.png`–`Stage_01T_z4.png`. O arquivo original pode ser deletado após a geração dos novos tilesets.

---

## 7. Processo de Geração

1. Checar créditos PixelLab antes de iniciar
2. Para cada stage 01–08, em sequência:
   - Chamar `create_sidescroller_tileset` via MCP para cada um dos 5 tilesets
   - Baixar com `python tools/pixellab_download.py tileset <id> stages/stage_0X/`
   - Renomear para convenção `Stage_0XT_zN.png` / `stage_0X_glass.png`
3. Stage 09: nenhuma geração — apenas referenciar nas cenas
4. Implementar alterações de código em `stage_scene.gd` e `stage_09_scene.gd`
5. Atualizar `.tscn` de cada stage via editor Godot
6. Web export + teste

---

## 8. Fora de Escopo

- Geração de sprites de bosses/inimigos (spec separada)
- Alterações em `_draw_room_tiles()` (usado apenas no stage_00)
- Tileset para stages 10–11 (Nullvex)
