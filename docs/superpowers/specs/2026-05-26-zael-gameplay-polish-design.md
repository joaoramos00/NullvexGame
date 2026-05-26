# Zael — Polimento de Gameplay: Design Spec

**Data:** 2026-05-26
**Escopo:** Ajustes de posição (tiro + carga), dash+pulo, sprites novos (jump_shoot, dash_shoot) e ImgDebug

---

## Grupo A — Alinhamento de Posição (itens 1 e 2)

### 1. Altura do tiro (`_SPAWN_OFFSET_Y`)

**Problema:** O projétil spawna em `_SPAWN_OFFSET_Y = 5.0` (5px abaixo da origem do CharacterBody2D), que fica próximo ao topo do personagem — muito acima do braço esticado no sprite de tiro.

**Geometria da cena:**
- `AnimatedSprite2D.position = (0, 35)` com escala 2× → sprite de 68px ocupa y=−33 a y=103 (local)
- Cano do braço no `ZaelAtirando.png` (frames 4–5): aproximadamente linha 27–30 do source frame
- Posição local do cano: `−33 + 27×2 = 21` a `−33 + 30×2 = 27`

**Fix:** `_SPAWN_OFFSET_Y := 5.0` → `24.0`
- Valor exato confirmado visualmente durante implementação (inspecionar sprite e ajustar se necessário)

---

### 2. Centro da animação de carga (`_CHARGE_CENTER_Y`)

**Problema:** As órbitas de carga giram em torno de `y = 5.0` (próximo ao topo do personagem).

**Fix:** `_CHARGE_CENTER_Y := 5.0` → `35.0`
- Alinha com o node `AnimatedSprite2D` que representa o centro visual do personagem

---

## Grupo B — Dash+Pulo (item 3)

### Bug identificado

Em `zael.gd`, o check de dash-jump roda **antes** de `super._physics_process(delta)`. O `_is_dashing` só se torna `true` dentro de `super` (em `_handle_dash`). Logo, no **primeiro frame do dash**, o check vê `_is_dashing = false` e falha.

O `_jump_buffer_timer` compensa isso no frame seguinte, mas se Z e X são pressionados muito próximos, `_handle_jump` (dentro do super) pode iniciar um squat de pulo normal antes do check de dash-jump ter chance de disparar no próximo frame.

### Fixes

**Janelas de timing** — ampliar para tornar o dash-jump mais tolerante:

| Constante | Atual | Novo |
|-----------|-------|------|
| `_DASH_JUMP_BUFFER` | `0.2s` | `0.35s` |
| `_JUMP_BUFFER_TIME` | `0.15s` | `0.25s` |

**Dash de borda** — permitir dash-jump ao sair de uma plataforma pela lateral. Duas mudanças:

```gdscript
# 1. Check de disparo do dash-jump:
# Antes:
if _is_dashing or (_was_dashing_timer > 0.0 and is_on_floor()):
# Depois:
if _is_dashing or (_was_dashing_timer > 0.0 and (is_on_floor() or _coyote_timer > 0.0)):

# 2. Countdown do _was_dashing_timer (não zerar durante coyote):
# Antes:
elif _was_dashing_timer > 0.0:
    if is_on_floor():
        _was_dashing_timer = max(0.0, _was_dashing_timer - delta)
    else:
        _was_dashing_timer = 0.0
# Depois:
elif _was_dashing_timer > 0.0:
    if is_on_floor() or _coyote_timer > 0.0:
        _was_dashing_timer = max(0.0, _was_dashing_timer - delta)
    else:
        _was_dashing_timer = 0.0
```

**Trajetória no ar (item 3.3)** — manter `_DASH_JUMP_SPEED` ao trocar de direção:

```gdscript
# Em _handle_movement(), branch else (no ar durante dash-jump):
# Antes:
velocity.x = dir * SPEED

# Depois:
velocity.x = dir * _DASH_JUMP_SPEED
```

---

## Grupo C — Sprites (item 4)

### Sprites novos a gerar (`scripts/generate_zael_sprites.py`)

#### ZaelJumpShoot.png (2 frames)
- Frame 0: `jump_f2` (apex do pulo) com braço de `shoot_f4` sobreposto em `(32, 16)`
- Frame 1: `jump_f2` com braço levemente deslocado `(33, 15)` para microanimação

#### ZaelDashShoot.png (2 frames)
- Frame 0: `dash_f0` com braço de `shoot_f4` sobreposto em `(32, 16)`
- Frame 1: `dash_f1` com braço de `shoot_f4` sobreposto em `(32, 16)`

### Integração em `zael.gd`

**`_setup_sprite_frames()`** — adicionar após o bloco `run_shoot`, mesmo padrão:
```gdscript
var jump_shoot_tex := load("res://characters/ranged/ZaelJumpShoot.png") as Texture2D
frames.add_animation("jump_shoot")
frames.set_animation_loop("jump_shoot", false)
frames.set_animation_speed("jump_shoot", 10.0)
for i in 2:
    var at := AtlasTexture.new()
    at.atlas = jump_shoot_tex
    at.filter_clip = true
    at.region = Rect2(i * fw, 0, fw, fh)
    frames.add_frame("jump_shoot", at)

var dash_shoot_tex := load("res://characters/ranged/ZaelDashShoot.png") as Texture2D
frames.add_animation("dash_shoot")
frames.set_animation_loop("dash_shoot", true)
frames.set_animation_speed("dash_shoot", 12.0)
for i in 2:
    var at := AtlasTexture.new()
    at.atlas = dash_shoot_tex
    at.filter_clip = true
    at.region = Rect2(i * fw, 0, fw, fh)
    frames.add_frame("dash_shoot", at)
```

**`_update_animation()`** — `_is_dashing` sobe ANTES de `not is_on_floor()` (dash durante borda
mostra animação de dash, não de pulo). Trecho completo da região modificada:
```gdscript
# após _landing_timer e antes de run_shoot/run/idle:
elif _is_dashing:
    if _is_shooting:
        _sprite.play("dash_shoot")
    else:
        _sprite.play("dash")
elif not is_on_floor():
    if _is_wall_sliding:
        _sprite.play("wall_slide")
    elif _is_shooting:
        _sprite.play("jump_shoot")
    else:
        _sprite.stop()
        _sprite.animation = "jump"
        _sprite.frame = 2
```

Nota: `_landing_timer` continua checado entre `not is_on_floor()` e `_is_dashing` na ordem ATUAL — a mudança é mover `_is_dashing` para ANTES de `not is_on_floor()`, mantendo `_landing_timer` depois.

### ImgDebug (`ui/img_debug.gd`)

Adicionar ao array `_SPRITES` (item 4.2 — wall_slide agora visível):
```gdscript
{"char": "ZAEL", "anim": "WallSlide", "path": "res://characters/ranged/ZaelWallSlide.png", "frames": 2, "fps": 6.0},
{"char": "ZAEL", "anim": "Dash",      "path": "res://characters/ranged/ZaelDash.png",       "frames": 2, "fps": 12.0},
{"char": "ZAEL", "anim": "RunShoot",  "path": "res://characters/ranged/ZaelRunShoot.png",   "frames": 6, "fps": 10.0},
{"char": "ZAEL", "anim": "JumpShoot", "path": "res://characters/ranged/ZaelJumpShoot.png",  "frames": 2, "fps": 10.0},
{"char": "ZAEL", "anim": "DashShoot", "path": "res://characters/ranged/ZaelDashShoot.png",  "frames": 2, "fps": 12.0},
```

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `characters/ranged/zael.gd` | Modificar — constantes A, timing B, animações C |
| `scripts/generate_zael_sprites.py` | Modificar — adicionar JumpShoot e DashShoot |
| `characters/ranged/ZaelJumpShoot.png` | Criar — gerado pelo script |
| `characters/ranged/ZaelDashShoot.png` | Criar — gerado pelo script |
| `ui/img_debug.gd` | Modificar — adicionar 5 entradas ao _SPRITES |
