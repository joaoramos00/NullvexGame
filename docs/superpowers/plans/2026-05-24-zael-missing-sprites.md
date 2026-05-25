# Zael Missing Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gerar os 5 sprites faltantes do Zael (dash, wall_slide, hurt, death, run_shoot) via Python PIL e conectar no código GDScript.

**Architecture:** Script Python manipula frames existentes (ZaelCorrendo, ZaelIdle, ZaelJump_new, ZaelAtirando) para gerar os PNGs. `character_base.gd` ganha um método virtual `_play_death_animation()` para que Zael possa atrasar o sinal `died` até o fim da animação. `zael.gd` carrega os novos sprites e implementa a lógica de hurt/death/dash/wall_slide/run_shoot em `_update_animation()`.

**Tech Stack:** Python 3 + Pillow, Godot 4.6.2 GDScript

---

## Task 1: Script Python — Gerar os 5 PNGs

**Files:**
- Create: `scripts/generate_zael_sprites.py`

- [ ] **Step 1: Verificar se Pillow está instalado**

```bash
python -c "from PIL import Image; print('OK')"
```

Expected output: `OK`
Se falhar: `pip install Pillow`

- [ ] **Step 2: Criar o script de geração**

Criar `scripts/generate_zael_sprites.py` com o conteúdo abaixo. O script lê os sprites existentes de `characters/ranged/` e salva os novos PNGs no mesmo diretório.

```python
import math
import sys
from pathlib import Path
from PIL import Image, ImageDraw

FW = 68
FH = 68
ROOT = Path(__file__).parent.parent
CHARS = ROOT / "characters" / "ranged"


def get_frame(img: Image.Image, index: int) -> Image.Image:
    return img.crop((index * FW, 0, (index + 1) * FW, FH)).convert("RGBA")


def make_sheet(frames: list) -> Image.Image:
    sheet = Image.new("RGBA", (FW * len(frames), FH), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * FW, 0))
    return sheet


def flash_white(frame: Image.Image, alpha: float) -> Image.Image:
    overlay = Image.new("RGBA", frame.size, (255, 255, 255, int(255 * alpha)))
    result = frame.copy()
    return Image.alpha_composite(result, overlay)


def shift_frame(frame: Image.Image, dx: int, dy: int) -> Image.Image:
    result = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    result.paste(frame, (dx, dy))
    return result


def stretch_down(frame: Image.Image, scale_x: float, push_y: int) -> Image.Image:
    new_w = int(FW * scale_x)
    new_h = FH - push_y
    stretched = frame.resize((new_w, new_h), Image.NEAREST)
    result = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    x_off = (FW - new_w) // 2
    result.paste(stretched, (x_off, push_y))
    return result


def remove_checkerboard(frame: Image.Image, keep_fraction: float) -> Image.Image:
    """Remove pixels leaving approximately keep_fraction of non-transparent pixels."""
    result = frame.copy()
    pixels = result.load()
    # step controls density: step=2 keeps 50%, step=1 keeps 25% of checkerboard
    if keep_fraction >= 0.75:
        step = 4; offset = 1
    elif keep_fraction >= 0.50:
        step = 2; offset = 1
    else:
        step = 2; offset = 0
    for y in range(FH):
        for x in range(FW):
            if (x + y) % step == offset:
                r, g, b, a = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
    return result


# ── Load sources ──────────────────────────────────────────────────────────────
idle  = Image.open(CHARS / "ZaelIdle.png").convert("RGBA")
run   = Image.open(CHARS / "ZaelCorrendo.png").convert("RGBA")
jump  = Image.open(CHARS / "ZaelJump_new.png").convert("RGBA")
shoot = Image.open(CHARS / "ZaelAtirando.png").convert("RGBA")

idle_f0  = get_frame(idle, 0)
run_f2   = get_frame(run, 2)
run_f3   = get_frame(run, 3)
jump_f2  = get_frame(jump, 2)
jump_f3  = get_frame(jump, 3)
shoot_f4 = get_frame(shoot, 4)

# ── ZaelDash (2 frames) ───────────────────────────────────────────────────────
# Frame 0: run frame 2, corpo levemente agachado
dash_f0 = stretch_down(run_f2, 1.05, 3)
# Frame 1: run frame 3, mais agachado + rastro de pixels atrás
dash_f1_base = stretch_down(run_f3, 1.10, 5)
trail = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
left_strip = run_f3.crop((0, 0, 8, FH))
trail.paste(left_strip, (0, 0))
tp = trail.load()
for y in range(FH):
    for x in range(8):
        r, g, b, a = tp[x, y]
        tp[x, y] = (r, g, b, int(a * 0.3))
dash_f1 = Image.alpha_composite(dash_f1_base, trail)

make_sheet([dash_f0, dash_f1]).save(CHARS / "ZaelDash.png")
print("ZaelDash.png ✓")

# ── ZaelWallSlide (2 frames) ──────────────────────────────────────────────────
# Personagem encostado na parede da direita: inclinar CW (ângulo negativo = PIL CW)
# flip_h no código cuida de paredes à esquerda
ws_f0 = jump_f2.rotate(-15, fillcolor=(0, 0, 0, 0))
ws_f1_base = idle_f0.rotate(-20, fillcolor=(0, 0, 0, 0))
ws_f1 = shift_frame(ws_f1_base, 4, 2)

make_sheet([ws_f0, ws_f1]).save(CHARS / "ZaelWallSlide.png")
print("ZaelWallSlide.png ✓")

# ── ZaelHurt (3 frames) ───────────────────────────────────────────────────────
hurt_f0 = flash_white(idle_f0, 0.85)                          # flash
hurt_f1 = flash_white(shift_frame(idle_f0, -6, -4), 0.40)    # recuo
hurt_f2 = flash_white(shift_frame(idle_f0, -3, -2), 0.15)    # recuperação

make_sheet([hurt_f0, hurt_f1, hurt_f2]).save(CHARS / "ZaelHurt.png")
print("ZaelHurt.png ✓")

# ── ZaelDeath (6 frames) ──────────────────────────────────────────────────────
# f0: flash branco total
death_f0 = flash_white(idle_f0, 0.85)

# f1: tint vermelho, levemente elevado
death_f1_base = shift_frame(jump_f2, 0, -4)
red = Image.new("RGBA", death_f1_base.size, (255, 80, 80, int(255 * 0.4)))
death_f1 = Image.alpha_composite(death_f1_base, red)

# f2-f4: dissolução progressiva (75% → 50% → 25% de pixels visíveis)
death_f2 = remove_checkerboard(jump_f3.copy(), 0.75)
death_f3 = remove_checkerboard(jump_f3.copy(), 0.50)
death_f4_base = remove_checkerboard(jump_f3.copy(), 0.25)
draw4 = ImageDraw.Draw(death_f4_base)
for i in range(8):
    angle = (math.tau / 8) * i
    px = int(FW / 2 + math.cos(angle) * 20)
    py = int(FH / 2 + math.sin(angle) * 20)
    draw4.ellipse([px - 3, py - 3, px + 3, py + 3], fill=(30, 100, 220, 180))
death_f4 = death_f4_base

# f5: só partículas — canvas vazio
death_f5 = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
draw5 = ImageDraw.Draw(death_f5)
for i in range(8):
    angle = (math.tau / 8) * i
    px = int(FW / 2 + math.cos(angle) * 28)
    py = int(FH / 2 + math.sin(angle) * 28)
    draw5.ellipse([px - 3, py - 3, px + 3, py + 3], fill=(30, 100, 220, 120))
for i in range(4):
    angle = (math.tau / 4) * i + math.tau / 8
    px = int(FW / 2 + math.cos(angle) * 14)
    py = int(FH / 2 + math.sin(angle) * 14)
    draw5.ellipse([px - 2, py - 2, px + 2, py + 2], fill=(200, 50, 50, 120))

make_sheet([death_f0, death_f1, death_f2, death_f3, death_f4, death_f5]).save(CHARS / "ZaelDeath.png")
print("ZaelDeath.png ✓")

# ── ZaelRunShoot (6 frames) ───────────────────────────────────────────────────
# Extrair região do braço+canhão de shoot frame 4 (metade direita superior)
arm = shoot_f4.crop((32, 16, FW, 52))   # x=32..68, y=16..52

frames_rs = []
for i in range(6):
    base = get_frame(run, i)
    result = base.copy()
    result.paste(arm, (32, 16), arm)
    frames_rs.append(result)

make_sheet(frames_rs).save(CHARS / "ZaelRunShoot.png")
print("ZaelRunShoot.png ✓")

print("\nTodos os sprites gerados com sucesso!")
```

- [ ] **Step 3: Executar o script**

```bash
cd C:/Users/Usuário/SnesGame
python scripts/generate_zael_sprites.py
```

Expected output:
```
ZaelDash.png ✓
ZaelWallSlide.png ✓
ZaelHurt.png ✓
ZaelDeath.png ✓
ZaelRunShoot.png ✓

Todos os sprites gerados com sucesso!
```

- [ ] **Step 4: Verificar que os 5 PNGs existem em `characters/ranged/`**

```bash
ls C:/Users/Usuário/SnesGame/characters/ranged/Zael*.png
```

Expected: listar ZaelDash.png, ZaelWallSlide.png, ZaelHurt.png, ZaelDeath.png, ZaelRunShoot.png entre os outros.

- [ ] **Step 5: Commit**

```bash
git add scripts/generate_zael_sprites.py characters/ranged/ZaelDash.png characters/ranged/ZaelWallSlide.png characters/ranged/ZaelHurt.png characters/ranged/ZaelDeath.png characters/ranged/ZaelRunShoot.png
git commit -m "feat: gerar sprites faltantes do Zael (dash/wall_slide/hurt/death/run_shoot)"
```

---

## Task 2: character_base.gd — Método virtual para animação de morte

**Files:**
- Modify: `characters/base/character_base.gd`

Atualmente `_die()` emite `died` imediatamente. Precisamos que Zael possa atrasar esse sinal até o fim da animação de morte sem quebrar Zara.

- [ ] **Step 1: Modificar `_die()` para chamar método virtual**

Em `character_base.gd`, substituir:

```gdscript
func _die() -> void:
    is_dead = true
    velocity = Vector2.ZERO
    AudioManager.play_sfx(AudioLibrary.sfx_player_death)
    died.emit()
```

Por:

```gdscript
func _die() -> void:
    is_dead = true
    velocity = Vector2.ZERO
    AudioManager.play_sfx(AudioLibrary.sfx_player_death)
    _play_death_animation()

func _play_death_animation() -> void:
    died.emit()
```

`_play_death_animation()` é o ponto de override. O comportamento padrão (emitir `died` imediatamente) mantém Zara funcionando sem alterações.

- [ ] **Step 2: Verificar que Zara não foi afetada**

Abrir `characters/melee/zara.gd` e confirmar que ela **não** sobrescreve `_die()` nem `_play_death_animation()`. Se não sobrescreve, o comportamento dela continua idêntico ao atual.

- [ ] **Step 3: Commit**

```bash
git add characters/base/character_base.gd
git commit -m "refactor: _die() delega animação via _play_death_animation() virtual"
```

---

## Task 3: zael.gd — Carregar os 5 novos sprites em `_setup_sprite_frames()`

**Files:**
- Modify: `characters/ranged/zael.gd`

- [ ] **Step 1: Adicionar carregamento das novas texturas**

Em `_setup_sprite_frames()`, após a linha `var shoot_tex := ...`, adicionar:

```gdscript
var dash_tex      := load("res://characters/ranged/ZaelDash.png")      as Texture2D
var wall_tex      := load("res://characters/ranged/ZaelWallSlide.png")  as Texture2D
var hurt_tex      := load("res://characters/ranged/ZaelHurt.png")       as Texture2D
var death_tex     := load("res://characters/ranged/ZaelDeath.png")      as Texture2D
var run_shoot_tex := load("res://characters/ranged/ZaelRunShoot.png")   as Texture2D
```

- [ ] **Step 2: Registrar a animação `dash` (2 frames)**

Após o bloco da animação `"jump"`, adicionar:

```gdscript
frames.add_animation("dash")
frames.set_animation_loop("dash", false)
frames.set_animation_speed("dash", 12.0)
for i in 2:
    var at := AtlasTexture.new()
    at.atlas = dash_tex
    at.filter_clip = true
    at.region = Rect2(i * fw, 0, fw, fh)
    frames.add_frame("dash", at)
```

- [ ] **Step 3: Registrar a animação `wall_slide` (2 frames)**

```gdscript
frames.add_animation("wall_slide")
frames.set_animation_loop("wall_slide", true)
frames.set_animation_speed("wall_slide", 6.0)
for i in 2:
    var at := AtlasTexture.new()
    at.atlas = wall_tex
    at.filter_clip = true
    at.region = Rect2(i * fw, 0, fw, fh)
    frames.add_frame("wall_slide", at)
```

- [ ] **Step 4: Registrar a animação `hurt` (3 frames)**

```gdscript
frames.add_animation("hurt")
frames.set_animation_loop("hurt", false)
frames.set_animation_speed("hurt", 15.0)
for i in 3:
    var at := AtlasTexture.new()
    at.atlas = hurt_tex
    at.filter_clip = true
    at.region = Rect2(i * fw, 0, fw, fh)
    frames.add_frame("hurt", at)
```

- [ ] **Step 5: Registrar a animação `death` (6 frames)**

```gdscript
frames.add_animation("death")
frames.set_animation_loop("death", false)
frames.set_animation_speed("death", 10.0)
for i in 6:
    var at := AtlasTexture.new()
    at.atlas = death_tex
    at.filter_clip = true
    at.region = Rect2(i * fw, 0, fw, fh)
    frames.add_frame("death", at)
```

- [ ] **Step 6: Registrar a animação `run_shoot` (6 frames)**

```gdscript
frames.add_animation("run_shoot")
frames.set_animation_loop("run_shoot", true)
frames.set_animation_speed("run_shoot", 10.0)
for i in 6:
    var at := AtlasTexture.new()
    at.atlas = run_shoot_tex
    at.filter_clip = true
    at.region = Rect2(i * fw, 0, fw, fh)
    frames.add_frame("run_shoot", at)
```

- [ ] **Step 7: Commit**

```bash
git add characters/ranged/zael.gd
git commit -m "feat: registrar animações dash/wall_slide/hurt/death/run_shoot no Zael"
```

---

## Task 4: zael.gd — Sistema de hurt, death override e `_on_animation_finished()`

**Files:**
- Modify: `characters/ranged/zael.gd`

- [ ] **Step 1: Adicionar constante e variáveis de hurt no topo do script**

Após `const _DASH_JUMP_SPEED ...`, adicionar:

```gdscript
const HURT_DURATION := 0.3
```

Após `var _landing_timer: float = 0.0`, adicionar:

```gdscript
var _is_hurt: bool = false
var _hurt_timer: float = 0.0
```

- [ ] **Step 2: Conectar o sinal `damaged` e renomear `_on_shoot_finished`**

Em `_ready()`, após a linha:
```gdscript
_sprite.animation_finished.connect(_on_shoot_finished)
```

Substituir por:
```gdscript
_sprite.animation_finished.connect(_on_animation_finished)
damaged.connect(_on_damaged)
```

- [ ] **Step 3: Substituir `_on_shoot_finished` por `_on_animation_finished`**

Remover:
```gdscript
func _on_shoot_finished() -> void:
    if _sprite.animation.begins_with("shoot_"):
        _is_shooting = false
```

Adicionar:
```gdscript
func _on_animation_finished() -> void:
    match _sprite.animation:
        "shoot_1", "shoot_2", "shoot_3":
            _is_shooting = false
        "hurt":
            _is_hurt = false
        "death":
            died.emit()
```

- [ ] **Step 4: Adicionar `_on_damaged()` para disparar a animação de hurt**

```gdscript
func _on_damaged(_amount: int) -> void:
    if is_dead:
        return
    _is_hurt = true
    _hurt_timer = 0.0
    _sprite.play("hurt")
```

- [ ] **Step 5: Adicionar override de `_play_death_animation()`**

```gdscript
func _play_death_animation() -> void:
    _sprite.play("death")
    # sinal died emitido em _on_animation_finished quando "death" terminar
```

- [ ] **Step 6: Fazer o hurt timer avançar em `_physics_process()`**

Em `_physics_process()`, após `_handle_shooting(delta)`, adicionar:

```gdscript
if _is_hurt:
    _hurt_timer += delta
    if _hurt_timer >= HURT_DURATION:
        _is_hurt = false
```

- [ ] **Step 7: Commit**

```bash
git add characters/ranged/zael.gd
git commit -m "feat: sistema de hurt/death com animações no Zael"
```

---

## Task 5: zael.gd — Atualizar `_update_animation()` com nova prioridade

**Files:**
- Modify: `characters/ranged/zael.gd`

A nova ordem de prioridade (de maior para menor):
`death > hurt > jump_squat/airborne/landing > dash > wall_slide > run_shoot > shoot > run > idle`

- [ ] **Step 1: Substituir `_update_animation()` completamente**

```gdscript
func _update_animation() -> void:
    if not _is_shooting and not is_dead and not _is_hurt:
        _sprite.flip_h = not facing_right

    if is_dead:
        pass  # animação death não deve ser interrompida
    elif _is_hurt:
        pass  # animação hurt não deve ser interrompida
    elif _jump_squat_timer >= 0.0:
        if not _is_shooting:
            _sprite.stop()
            _sprite.animation = "jump"
            _sprite.frame = 0 if _jump_squat_timer < _SQUAT_DURATION * 0.5 else 1
    elif not is_on_floor():
        if _is_wall_sliding:
            _sprite.play("wall_slide")
        elif not _is_shooting:
            _sprite.stop()
            _sprite.animation = "jump"
            _sprite.frame = 2
    elif _landing_timer > 0.0:
        if not _is_shooting:
            _sprite.stop()
            _sprite.animation = "jump"
            _sprite.frame = 3
    elif _is_dashing:
        _sprite.play("dash")
    elif _is_shooting and velocity.x != 0.0:
        _sprite.play("run_shoot")
    elif _is_shooting:
        pass  # shoot_1/2/3 já está tocando
    elif velocity.x != 0.0:
        _sprite.play("run")
    else:
        _sprite.play("idle")
```

- [ ] **Step 2: Commit**

```bash
git add characters/ranged/zael.gd
git commit -m "feat: _update_animation() com dash/wall_slide/hurt/death/run_shoot"
```

---

## Task 6: Testes e verificação final

**Files:**
- Read: `tests/test_character_base.tscn` (verificar que testes existentes passam)

- [ ] **Step 1: Rodar os testes headless existentes**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn 2>&1 | tail -20
```

Expected: todos os testes passam (nenhum FAIL).

- [ ] **Step 2: Rodar os demais testes**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn 2>&1 | tail -10
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn 2>&1 | tail -10
```

Expected: todos passam.

- [ ] **Step 3: Web export para verificação visual**

```bash
# Usar a skill web-export para publicar e verificar visualmente no browser
```

Verificar no jogo que:
- Dash mostra sprite inclinado (não o run normal)
- Wall slide mostra pose encostada na parede
- Tomar dano dispara flash branco
- Morte dispara dissolução antes de respawnar
- Correr + atirar usa run_shoot (braço estendido)

- [ ] **Step 4: Commit final de consolidação**

```bash
git add .
git commit -m "chore: web export — sprites dash/wall_slide/hurt/death/run_shoot Zael"
```
