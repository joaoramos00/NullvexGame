# Zael Gameplay Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corrigir alinhamento do tiro e da carga, consertar e ampliar o dash+pulo, e adicionar sprites de jump_shoot e dash_shoot ao Zael.

**Architecture:** Três grupos independentes de mudanças, todos em `characters/ranged/zael.gd`: (A) duas constantes de posição, (B) constantes de timing e lógica do dash-jump, (C) geração de sprites via script Python + integração no AnimatedSprite2D e no ImgDebug. Sem novas dependências ou arquivos de cena.

**Tech Stack:** GDScript (Godot 4.6.2), Python 3 + Pillow (geração de sprites), ImgDebug → MOVIMENTOS para teste visual.

---

## Arquivos

| Arquivo | Ação |
|---------|------|
| `characters/ranged/zael.gd` | Modificar — constantes, lógica dash-jump, animações |
| `scripts/generate_zael_sprites.py` | Modificar — adicionar JumpShoot e DashShoot |
| `characters/ranged/ZaelJumpShoot.png` | Criar — gerado pelo script |
| `characters/ranged/ZaelDashShoot.png` | Criar — gerado pelo script |
| `ui/img_debug.gd` | Modificar — adicionar 5 entradas ao _SPRITES |

---

## Task 1: Gerar ZaelJumpShoot.png e ZaelDashShoot.png

**Files:**
- Modify: `scripts/generate_zael_sprites.py`
- Create: `characters/ranged/ZaelJumpShoot.png`
- Create: `characters/ranged/ZaelDashShoot.png`

- [ ] **Step 1: Adicionar geração de JumpShoot e DashShoot ao final do script**

Abrir `scripts/generate_zael_sprites.py` e adicionar ANTES de `print("\nTodos os sprites gerados com sucesso!")`:

```python
# ── ZaelJumpShoot (2 frames) ──────────────────────────────────────────────────
arm = shoot_f4.crop((32, 16, FW, 52))

jump_shoot_f0 = jump_f2.copy()
jump_shoot_f0.paste(arm, (32, 16), arm)

jump_shoot_f1 = jump_f2.copy()
jump_shoot_f1.paste(arm, (33, 15), arm)

make_sheet([jump_shoot_f0, jump_shoot_f1]).save(CHARS / "ZaelJumpShoot.png")
print("ZaelJumpShoot.png ✓")

# ── ZaelDashShoot (2 frames) ──────────────────────────────────────────────────
arm = shoot_f4.crop((32, 16, FW, 52))

dash_shoot_f0 = dash_f0.copy()
dash_shoot_f0.paste(arm, (32, 16), arm)

dash_shoot_f1 = dash_f1.copy()
dash_shoot_f1.paste(arm, (32, 16), arm)

make_sheet([dash_shoot_f0, dash_shoot_f1]).save(CHARS / "ZaelDashShoot.png")
print("ZaelDashShoot.png ✓")
```

Nota: `dash_f0`, `dash_f1`, `jump_f2`, `shoot_f4` e `arm` já são definidos mais acima no script. Reuse as variáveis existentes.

- [ ] **Step 2: Rodar o script**

```powershell
cd "C:\Users\Usuário\SnesGame"
python scripts/generate_zael_sprites.py
```

Saída esperada (últimas linhas):
```
ZaelJumpShoot.png ✓
ZaelDashShoot.png ✓

Todos os sprites gerados com sucesso!
```

- [ ] **Step 3: Verificar arquivos gerados**

```powershell
ls characters/ranged/ZaelJumpShoot.png, characters/ranged/ZaelDashShoot.png
```

Ambos devem existir com tamanho > 0.

- [ ] **Step 4: Commit**

```powershell
git add scripts/generate_zael_sprites.py characters/ranged/ZaelJumpShoot.png characters/ranged/ZaelDashShoot.png
git commit -m "feat: gerar sprites ZaelJumpShoot e ZaelDashShoot"
```

---

## Task 2: Grupo A — Alinhamento de tiro e carga (zael.gd)

**Files:**
- Modify: `characters/ranged/zael.gd:21,27`

- [ ] **Step 1: Corrigir _SPAWN_OFFSET_Y (linha 21)**

Localizar:
```gdscript
const _SPAWN_OFFSET_Y := 5.0
```

Substituir por:
```gdscript
const _SPAWN_OFFSET_Y := 24.0
```

- [ ] **Step 2: Corrigir _CHARGE_CENTER_Y (linha 27)**

Localizar:
```gdscript
const _CHARGE_CENTER_Y := 5.0
```

Substituir por:
```gdscript
const _CHARGE_CENTER_Y := 35.0
```

- [ ] **Step 3: Testar visualmente — tiro**

1. Abrir `http://localhost:8080` no browser
2. Ir em **ImgDebug → MOVIMENTOS**
3. Pressionar J para atirar
4. Verificar: o projétil spawna na altura do cano do braço esticado (meio-superior do sprite)
5. Se ainda estiver alto ou baixo demais, ajustar `_SPAWN_OFFSET_Y` em ±2 até alinhar

- [ ] **Step 4: Testar visualmente — carga**

1. Segurar J até carregar L2 (0.4s) e L3 (1.2s)
2. Verificar: as órbitas giram ao redor do centro do sprite (área do torso), não do topo
3. Se deslocado, ajustar `_CHARGE_CENTER_Y` em ±5

- [ ] **Step 5: Commit**

```powershell
git add characters/ranged/zael.gd
git commit -m "fix: alinhar spawn do tiro e centro da carga com o sprite do Zael"
```

---

## Task 3: Grupo B — Dash+Pulo: timing e comportamento (zael.gd)

**Files:**
- Modify: `characters/ranged/zael.gd:48,50,214-222,239-255`

- [ ] **Step 1: Ampliar janelas de timing (linhas 48 e 50)**

Localizar:
```gdscript
const _DASH_JUMP_BUFFER   := 0.2   # janela após o dash terminar para ainda fazer dash-jump
```
Substituir por:
```gdscript
const _DASH_JUMP_BUFFER   := 0.35  # janela após o dash terminar para ainda fazer dash-jump
```

Localizar:
```gdscript
const _JUMP_BUFFER_TIME   := 0.15  # buffer de input: pulo pressionado antes do dash ainda dispara
```
Substituir por:
```gdscript
const _JUMP_BUFFER_TIME   := 0.25  # buffer de input: pulo pressionado antes do dash ainda dispara
```

- [ ] **Step 2: Manter _DASH_JUMP_SPEED ao trocar direção no ar (linhas 214-222)**

Localizar o bloco em `_handle_movement()`:
```gdscript
func _handle_movement() -> void:
    if _dash_jump:
        if is_on_floor():
            velocity.x = _DASH_JUMP_SPEED * _dash_jump_dir
        else:
            var dir := Input.get_axis("move_left", "move_right")
            if dir != 0.0:
                velocity.x = dir * SPEED
        return
    super._handle_movement()
```

Substituir por:
```gdscript
func _handle_movement() -> void:
    if _dash_jump:
        if is_on_floor():
            velocity.x = _DASH_JUMP_SPEED * _dash_jump_dir
        else:
            var dir := Input.get_axis("move_left", "move_right")
            if dir != 0.0:
                velocity.x = dir * _DASH_JUMP_SPEED
        return
    super._handle_movement()
```

- [ ] **Step 3: Permitir dash-jump com coyote time (linhas 239-255)**

Localizar o bloco do check de dash-jump e o countdown do timer:
```gdscript
    if _jump_buffer_timer > 0.0 and not _dash_jump:
        if _is_dashing or (_was_dashing_timer > 0.0 and is_on_floor()):
            _jump_squat_timer = -1.0
            _dash_jump = true
            _dash_jump_dir = _dash_direction
            _is_dashing = false
            _was_dashing_timer = 0.0
            _jump_buffer_timer = 0.0
            velocity.y = JUMP_VELOCITY
            AudioManager.play_sfx(AudioLibrary.sfx_jump)
    if _is_dashing:
        _was_dashing_timer = _DASH_JUMP_BUFFER
    elif _was_dashing_timer > 0.0:
        if is_on_floor():
            _was_dashing_timer = max(0.0, _was_dashing_timer - delta)
        else:
            _was_dashing_timer = 0.0
```

Substituir por:
```gdscript
    if _jump_buffer_timer > 0.0 and not _dash_jump:
        if _is_dashing or (_was_dashing_timer > 0.0 and (is_on_floor() or _coyote_timer > 0.0)):
            _jump_squat_timer = -1.0
            _dash_jump = true
            _dash_jump_dir = _dash_direction
            _is_dashing = false
            _was_dashing_timer = 0.0
            _jump_buffer_timer = 0.0
            velocity.y = JUMP_VELOCITY
            AudioManager.play_sfx(AudioLibrary.sfx_jump)
    if _is_dashing:
        _was_dashing_timer = _DASH_JUMP_BUFFER
    elif _was_dashing_timer > 0.0:
        if is_on_floor() or _coyote_timer > 0.0:
            _was_dashing_timer = max(0.0, _was_dashing_timer - delta)
        else:
            _was_dashing_timer = 0.0
```

- [ ] **Step 4: Testar dash+pulo no ImgDebug → MOVIMENTOS**

Abrir `http://localhost:8080` → **ImgDebug → MOVIMENTOS**

Testar as três formas de ativar:
1. **Durante o dash**: pressionar D+X (dash), soltar, pressionar Z dentro de 0.35s → deve pular com velocidade horizontal alta
2. **Z antes de X**: pressionar Z, depois X dentro de 0.25s → deve ativar dash-jump
3. **Borda**: andar até a borda da arena, pressionar X (dash) na borda e imediatamente Z → deve pular mesmo caindo

Verificar também: ao pressionar A durante o dash-jump no ar, a velocidade horizontal permanece alta (620) na direção oposta.

- [ ] **Step 5: Commit**

```powershell
git add characters/ranged/zael.gd
git commit -m "fix: dash+pulo — ampliar janelas de timing, manter velocidade na troca, suporte a coyote"
```

---

## Task 4: Grupo C — Integrar animações jump_shoot e dash_shoot (zael.gd)

**Files:**
- Modify: `characters/ranged/zael.gd:187-199,364-385`

- [ ] **Step 1: Adicionar animações em _setup_sprite_frames()**

Localizar o bloco do `run_shoot` que termina assim:
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

    _sprite.sprite_frames = frames
```

Inserir ENTRE o bloco `run_shoot` e `_sprite.sprite_frames = frames`:
```gdscript
    var jump_shoot_tex := load("res://characters/ranged/ZaelJumpShoot.png") as Texture2D
    frames.add_animation("jump_shoot")
    frames.set_animation_loop("jump_shoot", true)
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

- [ ] **Step 2: Atualizar _update_animation() para priorizar dash e jump_shoot**

Localizar o bloco `elif not is_on_floor():` até `elif _is_dashing:` (linhas 364–377):
```gdscript
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
```

Substituir por:
```gdscript
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
    elif _landing_timer > 0.0:
        if not _is_shooting:
            _sprite.stop()
            _sprite.animation = "jump"
            _sprite.frame = 3
```

- [ ] **Step 3: Testar animações no ImgDebug → MOVIMENTOS**

Abrir `http://localhost:8080` → **ImgDebug → MOVIMENTOS**

1. Pular (Z) e atirar (J) no ar → deve mostrar animação jump_shoot (Zael em pose de pulo com braço estendido)
2. Dash (X) e atirar (J) → deve mostrar animação dash_shoot (Zael em pose de dash com braço estendido)
3. Andar (D) e atirar (J) → deve continuar mostrando run_shoot (sem regressão)
4. Parar e atirar (J) → deve mostrar shoot_1/2/3 (sem regressão)

- [ ] **Step 4: Commit**

```powershell
git add characters/ranged/zael.gd
git commit -m "feat: animações jump_shoot e dash_shoot no Zael"
```

---

## Task 5: Grupo C — Adicionar sprites ao ImgDebug (img_debug.gd)

**Files:**
- Modify: `ui/img_debug.gd:4-11`

- [ ] **Step 1: Adicionar entradas ao array _SPRITES**

Localizar o array `_SPRITES` (linhas 4–11):
```gdscript
const _SPRITES: Array = [
    {"char": "ZAEL", "anim": "Idle",  "path": "res://characters/ranged/ZaelIdle.png",     "frames": 8, "fps": 8.0},
    {"char": "ZAEL", "anim": "Run",   "path": "res://characters/ranged/ZaelCorrendo.png", "frames": 6, "fps": 10.0},
    {"char": "ZAEL", "anim": "Jump",  "path": "res://characters/ranged/ZaelJump_new.png", "frames": 4, "fps": 10.0},
    {"char": "ZAEL", "anim": "Shot",  "path": "res://characters/ranged/ZaelAtirando.png", "frames": 9, "fps": 10.0},
    {"char": "ZARA", "anim": "Walk",  "path": "res://characters/melee/ZaraAndando.png",   "frames": 5, "fps": 8.0},
    {"char": "ZARA", "anim": "Run",   "path": "res://characters/melee/ZaraCorrendo.png",  "frames": 3, "fps": 10.0},
]
```

Substituir por:
```gdscript
const _SPRITES: Array = [
    {"char": "ZAEL", "anim": "Idle",      "path": "res://characters/ranged/ZaelIdle.png",      "frames": 8, "fps": 8.0},
    {"char": "ZAEL", "anim": "Run",       "path": "res://characters/ranged/ZaelCorrendo.png",  "frames": 6, "fps": 10.0},
    {"char": "ZAEL", "anim": "Jump",      "path": "res://characters/ranged/ZaelJump_new.png",  "frames": 4, "fps": 10.0},
    {"char": "ZAEL", "anim": "Shot",      "path": "res://characters/ranged/ZaelAtirando.png",  "frames": 9, "fps": 10.0},
    {"char": "ZAEL", "anim": "WallSlide", "path": "res://characters/ranged/ZaelWallSlide.png", "frames": 2, "fps": 6.0},
    {"char": "ZAEL", "anim": "Dash",      "path": "res://characters/ranged/ZaelDash.png",      "frames": 2, "fps": 12.0},
    {"char": "ZAEL", "anim": "RunShoot",  "path": "res://characters/ranged/ZaelRunShoot.png",  "frames": 6, "fps": 10.0},
    {"char": "ZAEL", "anim": "JumpShoot", "path": "res://characters/ranged/ZaelJumpShoot.png", "frames": 2, "fps": 10.0},
    {"char": "ZAEL", "anim": "DashShoot", "path": "res://characters/ranged/ZaelDashShoot.png", "frames": 2, "fps": 12.0},
    {"char": "ZARA", "anim": "Walk",      "path": "res://characters/melee/ZaraAndando.png",    "frames": 5, "fps": 8.0},
    {"char": "ZARA", "anim": "Run",       "path": "res://characters/melee/ZaraCorrendo.png",   "frames": 3, "fps": 10.0},
]
```

- [ ] **Step 2: Verificar no ImgDebug → SPRITES → ZAEL**

Abrir `http://localhost:8080` → **ImgDebug → SPRITES → ZAEL**

Navegar com os botões prev/next e confirmar que as novas animações aparecem:
- WallSlide (2 frames)
- Dash (2 frames)
- RunShoot (6 frames)
- JumpShoot (2 frames)
- DashShoot (2 frames)

- [ ] **Step 3: Commit**

```powershell
git add ui/img_debug.gd
git commit -m "feat: adicionar WallSlide, Dash, RunShoot, JumpShoot, DashShoot ao ImgDebug"
```

---

## Task 6: Web Export e push final

- [ ] **Step 1: Exportar web**

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\Usuário\SnesGame" --export-release "Web" "C:\Users\Usuário\SnesGame\export\web\index.html"
```

Saída esperada: export completo sem erros críticos.

- [ ] **Step 2: Push**

```powershell
git push origin master
```

- [ ] **Step 3: Verificar no GitHub Pages**

Aguardar ~2min e testar em `https://joaoramos00.github.io/NullvexGame/`:
1. ImgDebug → SPRITES → ZAEL → navegar até JumpShoot e DashShoot
2. ImgDebug → MOVIMENTOS → testar dash+pulo (X+Z)
3. No ar, atirar (J) → confirmar jump_shoot aparece
