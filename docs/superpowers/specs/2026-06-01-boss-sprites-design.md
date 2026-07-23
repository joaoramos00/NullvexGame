# Boss Sprites — Design Spec

**Data:** 2026-06-01  
**Status:** Aprovado

---

## Objetivo

Gerar sprites pixel art HD para os 8 bosses elementais via PixelLab e integrá-los ao sistema de animação existente (Sprite2D + sprite sheets, padrão intro_boss/miniboss).

---

## 1. Aparência dos Bosses

Estilo visual: animal híbrido com armadura elemental, Mega Man X style, 128×128 px.

| Boss | Elemento | Animal base | Descrição PixelLab (`create-character-with-4-directions`) |
|------|----------|-------------|----------------------------------------------------------|
| **Ignarath** | Fogo | Salamandra | `"Ignarath fire salamander boss, massive reptilian body with molten armor plates, large curved horns glowing orange at tips, lava cracks running through thick hide, flaming tail, hunched aggressive stance, red and orange palette, Mega Man X style pixel art, side view"` |
| **Cryovex** | Gelo | Lobo da neve | `"Cryovex frost wolf boss, lean armored wolf body with crystalline ice fur mane, frost spikes along spine, clawed ice gauntlets, glowing cold blue eyes, frozen breath visible, pale blue and white palette, Mega Man X style pixel art, side view"` |
| **Voltrix** | Raio | Falcão trovão | `"Voltrix thunder hawk boss, large armored bird of prey with metallic feathers charged with electricity, jagged yellow and black plumage, crackling talons and beak, electric coils wrapped around wings, wings half-spread battle stance, Mega Man X style pixel art, side view"` |
| **Gravitus** | Gravidade | Urso cósmico | `"Gravitus gravity bear boss, massive armored bear with crushing claws, dark purple crystalline plates, gravitational orbs orbiting like rings around body, heavy hunched powerful stance, Mega Man X style pixel art, side view"` |
| **Galerix** | Vento | Raposa tempestade | `"Galerix storm fox boss, lean agile armored fox body, teal and white wind-swept armor plates, long flowing tail made of streaming wind energy, sharp narrow ears, wind vortex swirling around paws, crouched low fierce dash-ready stance, Mega Man X style pixel art, side view"` |
| **Umbraex** | Sombra | Pantera das sombras | `"Umbraex shadow panther boss, sleek dark feline body with layered black and dark purple armor, shadow tendrils extending from body, multiple glowing purple eyes, partially intangible form dissolving into darkness, predatory low crouched stance, Mega Man X style pixel art, side view"` |
| **Luxar** | Luz | Touro solar (bípede) | `"Luxar solar bull boss, anthropomorphic humanoid warrior with a bull head and armored torso, standing upright on two straight humanoid legs ONLY — no front legs, no quadruped stance, not on all fours — two muscular arms ending in golden clawed gauntlets, radiant white and gold armor plates, large curved golden horns glowing with light rays at the tips, blinding solar energy core in chest, mane of light-ray spikes down the neck, proud regal battle stance like a Mega Man X boss (e.g. Chill Penguin, Flame Mammoth), Mega Man X style pixel art, side view"` |
| **Terragor** | Terra | Gorila de pedra | `"Terragor stone gorilla boss, massive armored gorilla with boulder-sized fists, stone-plated body with rock spikes along back and shoulders, earth brown and grey, knuckle-dragging powerful stance, Mega Man X style pixel art, side view"` |

**Parâmetros fixos para criação:**
```json
{
  "image_size": {"width": 128, "height": 128},
  "view": "side",
  "proportions": {"type": "preset", "name": "heroic"},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```

---

## 2. Pipeline de Geração

**Por boss: 1 job de criação + 3 jobs de animação = 4 jobs PixelLab**  
**Total: 32 jobs para os 8 bosses**

### Jobs por boss

| Job | API call | Parâmetros-chave | Output |
|-----|----------|-----------------|--------|
| Referência estática | `create-character-with-4-directions` | `image_size: 128×128` | `<name>_west.png`, `<name>_east.png`, `<name>_south.png`, `<name>_north.png` |
| Walk west | `animate-character` | `directions: ["west"]`, `frame_count: 8` | `<name>_walk_west_f00-07.png` |
| Walk east | `animate-character` | `directions: ["east"]`, `frame_count: 8` | `<name>_walk_east_f00-07.png` |
| Entrada south | `animate-character` | `directions: ["south"]`, `frame_count: 6` | `<name>_entry_south_f00-05.png` |

**Parâmetros fixos de animação:** `frame_count` conforme acima, `mode: "v3"`.

### Action descriptions por boss

| Boss | Walk action_description | Entrance action_description |
|------|------------------------|----------------------------|
| Ignarath | `"aggressive walking combat cycle, heavy stomping, molten fire salamander"` | `"dramatic battle entrance, rising up with lava burst from ground, facing forward"` |
| Cryovex | `"prowling wolf walking cycle, low predatory stance, frost wolf"` | `"dramatic entrance, frost wolf leaping forward and skidding to a halt, facing camera, ice forming on ground"` |
| Voltrix | `"thunder hawk battle walking cycle, wings half-spread, electric sparks"` | `"dramatic aerial landing entrance, thunder hawk diving down and landing with electric discharge, facing camera"` |
| Gravitus | `"heavy stomping walking cycle, gravitational bear, slow powerful steps"` | `"dramatic entrance, gravity bear rising with gravitational orbs swirling around, facing camera"` |
| Galerix | `"swift low-crouched running cycle, storm fox, wind energy trailing off the tail"` | `"dramatic entrance, storm fox dashing in at high speed and skidding to a halt in battle stance, facing camera, wind gust kicking up dust"` |
| Umbraex | `"stalking predator walk cycle, shadow panther, low crouched"` | `"dramatic entrance, shadow panther materializing from darkness, facing camera, shadow tendrils spreading"` |
| Luxar | `"regal powerful bipedal walking cycle, solar bull standing upright, horns and mane radiating light"` | `"dramatic entrance, solar bull descending in pillar of light, landing upright in proud bipedal stance, facing camera"` |
| Terragor | `"knuckle-dragging gorilla walking cycle, stone golem, heavy shaking steps"` | `"dramatic entrance, stone gorilla crashing through ground, rising to full height, facing camera, rocks falling"` |

### Folder output por boss

```
characters/bosses/<name>/
  <name>_west.png               ← idle west (1 frame, runtime)
  <name>_east.png               ← idle east (1 frame, runtime)
  <name>_south.png              ← referência (não usada em runtime)
  <name>_north.png              ← referência (não usada em runtime)
  <name>_walk_west_f00-07.png   ← frames individuais (composição)
  <name>_walk_east_f00-07.png   ← frames individuais (composição)
  <name>_entry_south_f00-05.png ← frames individuais (composição)
  <name>_walk_west.png          ← sprite sheet composto (1024×128, 8 frames)
  <name>_walk_east.png          ← sprite sheet composto (1024×128, 8 frames)
  <name>_entry.png              ← sprite sheet composto (768×128, 6 frames)
```

### Composição de sprite sheets

Novo script `tools/compose_spritesheet.py` usando PIL:

```bash
python tools/compose_spritesheet.py <name> walk west    # → <name>_walk_west.png
python tools/compose_spritesheet.py <name> walk east    # → <name>_walk_east.png
python tools/compose_spritesheet.py <name> entry south  # → <name>_entry.png
```

---

## 3. Integração de Código

### Padrão de animação

Segue exatamente o padrão `intro_boss.gd` e `enemy_miniboss.gd`:
- `Sprite2D` (não `AnimatedSprite2D`)
- Sprite sheets horizontais com `hframes` + `frame` manual
- `flip_h` **não usado** — direção via textura west/east
- Hit flash via `modulate = Color(2, 2, 2, 1)`
- Invencibilidade via flicker de alpha

### Mapeamento de estados → animação

| `State` (boss_base) | Textura | Frames | FPS |
|--------------------|---------|--------|-----|
| `IDLE` | `_TEX_IDLE_W` ou `_TEX_IDLE_E` | 1 | — |
| `INTRO` | `_TEX_ENTRY` | 6 | 8.0 |
| `COMBAT` (movendo) | `_TEX_WALK_W` ou `_TEX_WALK_E` | 8 | 8.0 |
| `COMBAT` (parado) | `_TEX_IDLE_W` ou `_TEX_IDLE_E` | 1 | — |
| `DYING / DEAD` | congela no frame atual | — | — |

### Alterações por boss `.tscn`

Adicionar nó filho via edição de texto:
```
[node name="Sprite2D" type="Sprite2D" parent="."]
```

### Código adicionado a cada boss `.gd`

```gdscript
# --- Sprites ---
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
var _facing     : float = -1.0  # -1 = west, 1 = east

@onready var _sprite: Sprite2D = $Sprite2D

# Suprime retângulo placeholder; mantém barra de HP
func _draw() -> void:
    var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
    draw_rect(Rect2(-24, -52, 48, 6), Color.BLACK)
    draw_rect(Rect2(-24, -52, 48.0 * pct, 6), Color.GREEN)

# Direção via textura — scale.x permanece 1.0
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
        _sprite.frame   = _anim_frame
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

### `tools/compose_spritesheet.py` — interface

```python
# Uso:
# python tools/compose_spritesheet.py <name> <action> <direction>
# action: "walk" (8 frames) | "entry" (6 frames)
# direction: "west" | "east" | "south"
#
# Lê:  characters/bosses/<name>/<name>_<action>_<direction>_f<nn>.png
# Grava: characters/bosses/<name>/<name>_<action>_<direction>.png  (walk)
#        characters/bosses/<name>/<name>_entry.png                 (entry)
```

---

## 4. Fora de Escopo

- Animações de ataque por boss (adicionadas individualmente em futuras iterações)
- Modificações em `boss_base.gd` (zero mudanças na base compartilhada)
- Sprites dos bosses das fases finais (Nullvex)
- Tileset do stage 09 para Terragor (stage 08 já cobre)
