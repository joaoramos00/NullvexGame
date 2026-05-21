# Run & Shoot Animations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the walk animation with new running sprites for Zael and Zara, and give Zael a 3-frame shoot animation that visually reflects charge level in real time.

**Architecture:** Generate three new PNG sprite sheets via Pixel Lab API; update `zael.gd` (rename "walk"→"run", replace shoot with 3-frame charge-visible animation), `zara.gd` (rename "walk"→"run"), and `character_select.gd` (preview uses new run sprites). Tests added to `test_zael.gd` and `test_zara.gd`.

**Tech Stack:** Godot 4.6.2, GDScript, Pixel Lab API (sprite generation), PNG sprite sheets.

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `characters/ranged/ZaelCorrendo.png` | Create | 5-frame run strip (340×68) |
| `characters/melee/ZaraCorrendo.png` | Create | 5-frame run strip (340×68) |
| `characters/ranged/ZaelAtirando.png` | Create | 3-frame shoot strip (204×68) |
| `characters/ranged/zael.gd` | Modify | run + charge-visible shoot animations |
| `characters/melee/zara.gd` | Modify | run animation |
| `ui/character_select.gd` | Modify | preview loads run sprites |
| `tests/test_zael.gd` | Modify | test_zael_run_animation() |
| `tests/test_zara.gd` | Modify | test_zara_run_animation() |

---

## Task 1: Generate sprite sheets via Pixel Lab API

**Files:**
- Create: `characters/ranged/ZaelCorrendo.png`
- Create: `characters/melee/ZaraCorrendo.png`
- Create: `characters/ranged/ZaelAtirando.png`

This task generates the three new PNG sprite sheets using the Pixel Lab API (pixellab.ai). Use WebFetch to call the API. If the exact API endpoint is unclear, use WebSearch to find the current Pixel Lab REST API documentation. The API key is needed from the user.

- [ ] **Step 1: Generate ZaelCorrendo.png**

Use WebFetch (POST) to the Pixel Lab image generation endpoint with:

```
Prompt: "male pixel art game character running animation, 5-frame horizontal sprite sheet, each frame 68x68 pixels, total size 340x68, blue and white sci-fi armor, buster cannon on right arm, body leaning forward, legs in full running cycle, right-facing, transparent background, HD pixel art, Mega Man X style"
Width: 340
Height: 68
```

Save response image to `characters/ranged/ZaelCorrendo.png`.

- [ ] **Step 2: Generate ZaraCorrendo.png**

Use WebFetch (POST) to the Pixel Lab image generation endpoint with:

```
Prompt: "female pixel art game character running animation, 5-frame horizontal sprite sheet, each frame 68x68 pixels, total size 340x68, red sci-fi armor, sword in hand, long hair flowing back, body leaning forward, legs in full running cycle, right-facing, transparent background, HD pixel art, Mega Man X style"
Width: 340
Height: 68
```

Save response image to `characters/melee/ZaraCorrendo.png`.

- [ ] **Step 3: Generate ZaelAtirando.png**

Use WebFetch (POST) to the Pixel Lab image generation endpoint with:

```
Prompt: "male pixel art game character shooting animation, 3-frame horizontal sprite sheet, each frame 68x68 pixels, total size 204x68, blue and white sci-fi armor, buster cannon on right arm aimed forward: frame 0 faint blue glow at cannon tip, frame 1 medium blue energy aura around arm, frame 2 intense full-body blue glow, right-facing, transparent background, HD pixel art, Mega Man X style"
Width: 204
Height: 68
```

Save response image to `characters/ranged/ZaelAtirando.png`.

- [ ] **Step 4: Verify dimensions**

Run the Godot headless process to trigger import of the new PNGs — OR check file sizes manually. Confirm:
- `ZaelCorrendo.png`: 340×68
- `ZaraCorrendo.png`: 340×68
- `ZaelAtirando.png`: 204×68

- [ ] **Step 5: Commit**

```bash
git add characters/ranged/ZaelCorrendo.png characters/melee/ZaraCorrendo.png characters/ranged/ZaelAtirando.png
git commit -m "assets: sprites de corrida (Zael/Zara) e tiro com charge (Zael)"
```

---

## Task 2: Add failing animation tests (TDD)

**Files:**
- Modify: `tests/test_zael.gd`
- Modify: `tests/test_zara.gd`

- [ ] **Step 1: Add test_zael_run_animation to test_zael.gd**

The current `test_zael.gd` ends at line 28. Add the new test function and call it from `_ready()`:

```gdscript
extends Node

func _ready() -> void:
    test_bullet_properties()
    test_charge_levels()
    test_zael_run_animation()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_bullet_properties() -> void:
    var scene := load("res://characters/ranged/zael_bullet.tscn")
    var bullet = scene.instantiate()
    add_child(bullet)
    bullet.damage = 12
    bullet.direction = -1.0
    assert(bullet.damage == 12, "damage deve ser 12")
    assert(bullet.direction == -1.0, "direction deve ser -1.0")
    assert(bullet.SPEED == 500.0, "SPEED deve ser 500.0")
    bullet.queue_free()
    print("PASS: bullet_properties")

func test_charge_levels() -> void:
    assert(Zael.get_charge_level(0.0) == 1, "L1: timer 0.0")
    assert(Zael.get_charge_level(0.39) == 1, "L1: timer 0.39")
    assert(Zael.get_charge_level(0.4) == 2, "L2: timer 0.4")
    assert(Zael.get_charge_level(1.19) == 2, "L2: timer 1.19")
    assert(Zael.get_charge_level(1.2) == 3, "L3: timer 1.2")
    assert(Zael.get_charge_level(2.0) == 3, "L3: timer 2.0")
    print("PASS: charge_levels")

func test_zael_run_animation() -> void:
    var zael_scene := load("res://characters/ranged/zael.tscn")
    var zael = zael_scene.instantiate()
    add_child(zael)
    var sf: SpriteFrames = zael.get_node("AnimatedSprite2D").sprite_frames
    assert(sf.has_animation("run"), "Zael deve ter animação 'run'")
    assert(not sf.has_animation("walk"), "Zael não deve ter animação 'walk'")
    assert(sf.get_frame_count("run") == 5, "run deve ter 5 frames")
    assert(sf.get_frame_count("shoot") == 3, "shoot deve ter 3 frames")
    zael.queue_free()
    print("PASS: zael_run_animation")
```

- [ ] **Step 2: Run test to verify it FAILS**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_zael.tscn
```

Expected: FAIL on `test_zael_run_animation` (Zael still has "walk" not "run", shoot has 1 frame not 3).

- [ ] **Step 3: Add test_zara_run_animation to test_zara.gd**

Replace the entire `tests/test_zara.gd` with:

```gdscript
extends Node

func _ready() -> void:
    test_hitbox_properties()
    test_combo_progression()
    test_combo_damage()
    test_zara_run_animation()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_hitbox_properties() -> void:
    var scene := load("res://characters/melee/zara_hitbox.tscn")
    var hitbox = scene.instantiate()
    add_child(hitbox)
    hitbox.damage = 20
    assert(hitbox.damage == 20)
    assert(hitbox.ATTACK_DURATION == 0.15)
    hitbox.queue_free()
    print("PASS: hitbox_properties")

func test_combo_progression() -> void:
    assert(Zara.next_combo_step(0) == 1)
    assert(Zara.next_combo_step(1) == 2)
    assert(Zara.next_combo_step(2) == 0)
    print("PASS: combo_progression")

func test_combo_damage() -> void:
    assert(Zara.COMBO_DAMAGE[1] == 8)
    assert(Zara.COMBO_DAMAGE[2] == 12)
    assert(Zara.COMBO_DAMAGE[3] == 20)
    print("PASS: combo_damage")

func test_zara_run_animation() -> void:
    var zara_scene := load("res://characters/melee/zara.tscn")
    var zara = zara_scene.instantiate()
    add_child(zara)
    var sf: SpriteFrames = zara.get_node("AnimatedSprite2D").sprite_frames
    assert(sf.has_animation("run"), "Zara deve ter animação 'run'")
    assert(not sf.has_animation("walk"), "Zara não deve ter animação 'walk'")
    assert(sf.get_frame_count("run") == 5, "run deve ter 5 frames")
    zara.queue_free()
    print("PASS: zara_run_animation")
```

- [ ] **Step 4: Run test to verify it FAILS**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_zara.tscn
```

Expected: FAIL on `test_zara_run_animation` (Zara still has "walk" not "run").

- [ ] **Step 5: Commit**

```bash
git add tests/test_zael.gd tests/test_zara.gd
git commit -m "test: testes de animação run para Zael e Zara (TDD - falham antes da impl)"
```

---

## Task 3: Update zael.gd — run + shoot animations

**Files:**
- Modify: `characters/ranged/zael.gd`

- [ ] **Step 1: Replace zael.gd with updated version**

Full updated `characters/ranged/zael.gd`:

```gdscript
extends CharacterBase
class_name Zael

const CHARGE_L2_THRESHOLD := 0.4
const CHARGE_L3_THRESHOLD := 1.2

const BULLET_DAMAGE := [0, 5, 12, 25]
const BULLET_SCALE := [
    Vector2.ZERO,
    Vector2(1.0, 1.0),
    Vector2(1.6, 1.6),
    Vector2(2.5, 2.5),
]

const _BULLET_SCENE := preload("res://characters/ranged/zael_bullet.tscn")

const _FRAME_W := 68
const _FRAME_H := 68
const _ROW_RIGHT := 0

# bullet spawn offset from character center
const _SPAWN_OFFSET := Vector2(30.0, -10.0)

var _charge_timer: float = 0.0
var _is_charging: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    super._ready()
    _setup_sprite_frames()

func _setup_sprite_frames() -> void:
    var frames := SpriteFrames.new()
    var walk_tex := load("res://characters/ranged/ZaelAndando.png") as Texture2D
    var run_tex := load("res://characters/ranged/ZaelCorrendo.png") as Texture2D
    var shoot_tex := load("res://characters/ranged/ZaelAtirando.png") as Texture2D
    var fw := _FRAME_W
    var fh := _FRAME_H
    var ry := _ROW_RIGHT * fh

    frames.add_animation("idle")
    frames.set_animation_loop("idle", true)
    frames.set_animation_speed("idle", 1.0)
    var idle_at := AtlasTexture.new()
    idle_at.atlas = walk_tex
    idle_at.region = Rect2(2 * fw, ry, fw, fh)
    frames.add_frame("idle", idle_at)

    frames.add_animation("run")
    frames.set_animation_loop("run", true)
    frames.set_animation_speed("run", 8.0)
    for i in 5:
        var at := AtlasTexture.new()
        at.atlas = run_tex
        at.region = Rect2(i * fw, ry, fw, fh)
        frames.add_frame("run", at)

    frames.add_animation("jump")
    frames.set_animation_loop("jump", false)
    frames.set_animation_speed("jump", 1.0)
    var jump_at := AtlasTexture.new()
    jump_at.atlas = walk_tex
    jump_at.region = Rect2(2 * fw, ry, fw, fh)
    frames.add_frame("jump", jump_at)

    frames.add_animation("shoot")
    frames.set_animation_loop("shoot", false)
    frames.set_animation_speed("shoot", 8.0)
    for i in 3:
        var at := AtlasTexture.new()
        at.atlas = shoot_tex
        at.region = Rect2(i * fw, ry, fw, fh)
        frames.add_frame("shoot", at)

    _sprite.sprite_frames = frames
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sprite.play("idle")

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if is_dead:
        return
    _handle_shooting(delta)
    _update_animation()

func _handle_shooting(delta: float) -> void:
    if is_dead:
        return
    if Input.is_action_just_pressed("attack"):
        _is_charging = true
    if _is_charging:
        _charge_timer += delta
    if Input.is_action_just_released("attack") and _is_charging:
        _fire(get_charge_level(_charge_timer))
        _is_charging = false
        _charge_timer = 0.0

func _update_animation() -> void:
    var shooting := _sprite.animation == "shoot" and _sprite.is_playing()
    if not shooting:
        _sprite.flip_h = not facing_right
    if not is_on_floor():
        _sprite.play("jump")
    elif shooting:
        pass
    elif _is_charging:
        var level := get_charge_level(_charge_timer)
        _sprite.play("shoot")
        _sprite.set_frame_and_progress(level - 1, 0.0)
        _sprite.stop()
    elif velocity.x != 0.0:
        _sprite.play("run")
    else:
        _sprite.play("idle")

static func get_charge_level(timer: float) -> int:
    if timer >= CHARGE_L3_THRESHOLD:
        return 3
    if timer >= CHARGE_L2_THRESHOLD:
        return 2
    return 1

func _fire(level: int) -> void:
    assert(level >= 1 and level <= 3, "charge level deve ser 1, 2 ou 3")
    AudioManager.play_sfx(AudioLibrary.sfx_shoot)
    _sprite.play("shoot")
    _sprite.set_frame_and_progress(level - 1, 0.0)
    var bullet: ZaelBullet = _BULLET_SCENE.instantiate()
    bullet.damage = BULLET_DAMAGE[level]
    bullet.direction = 1.0 if facing_right else -1.0
    bullet.scale = BULLET_SCALE[level]
    bullet.source_id = GameManager.zael_selected_shot
    get_parent().add_child(bullet)
    var offset_x := _SPAWN_OFFSET.x if facing_right else -_SPAWN_OFFSET.x
    bullet.global_position = global_position + Vector2(offset_x, _SPAWN_OFFSET.y)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        _is_charging = false
        _charge_timer = 0.0
```

- [ ] **Step 2: Run tests to verify they PASS**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_zael.tscn
```

Expected output:
```
PASS: bullet_properties
PASS: charge_levels
PASS: zael_run_animation
ALL TESTS PASSED
```

- [ ] **Step 3: Commit**

```bash
git add characters/ranged/zael.gd
git commit -m "feat: animação run + shoot com charge visível para Zael"
```

---

## Task 4: Update zara.gd — run animation

**Files:**
- Modify: `characters/melee/zara.gd`

- [ ] **Step 1: Replace _setup_sprite_frames and rename "walk" → "run" in _update_animation**

Full updated `characters/melee/zara.gd`:

```gdscript
extends CharacterBase
class_name Zara

const COMBO_WINDOW := 0.5
const HITBOX_OFFSET := Vector2(30, -8)
const COMBO_DAMAGE := [0, 8, 12, 20]

const _HITBOX_SCENE := preload("res://characters/melee/zara_hitbox.tscn")

const _FRAME_W := 68
const _FRAME_H := 68
const _ROW_RIGHT := 0

var _combo_step: int = 0
var _combo_timer: float = 0.0
var _is_attacking: bool = false
var _attack_timer: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    super._ready()
    _setup_sprite_frames()

func _setup_sprite_frames() -> void:
    var frames := SpriteFrames.new()
    var walk_tex := load("res://characters/melee/ZaraAndando.png") as Texture2D
    var run_tex := load("res://characters/melee/ZaraCorrendo.png") as Texture2D
    var fw := _FRAME_W
    var fh := _FRAME_H
    var ry := _ROW_RIGHT * fh

    frames.add_animation("idle")
    frames.set_animation_loop("idle", true)
    frames.set_animation_speed("idle", 1.0)
    var idle_at := AtlasTexture.new()
    idle_at.atlas = walk_tex
    idle_at.region = Rect2(2 * fw, ry, fw, fh)
    frames.add_frame("idle", idle_at)

    frames.add_animation("run")
    frames.set_animation_loop("run", true)
    frames.set_animation_speed("run", 8.0)
    for i in 5:
        var at := AtlasTexture.new()
        at.atlas = run_tex
        at.region = Rect2(i * fw, ry, fw, fh)
        frames.add_frame("run", at)

    frames.add_animation("jump")
    frames.set_animation_loop("jump", false)
    frames.set_animation_speed("jump", 1.0)
    var jump_at := AtlasTexture.new()
    jump_at.atlas = walk_tex
    jump_at.region = Rect2(2 * fw, ry, fw, fh)
    frames.add_frame("jump", jump_at)

    frames.add_animation("attack")
    frames.set_animation_loop("attack", false)
    frames.set_animation_speed("attack", 1.0)
    var attack_at := AtlasTexture.new()
    attack_at.atlas = walk_tex
    attack_at.region = Rect2(0, ry, fw, fh)
    frames.add_frame("attack", attack_at)

    _sprite.sprite_frames = frames
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sprite.play("idle")

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if is_dead:
        return
    _handle_combo(delta)
    _update_animation()

func _update_animation() -> void:
    var attacking := _sprite.animation == "attack" and _sprite.is_playing()
    if not attacking:
        _sprite.flip_h = not facing_right
    if not is_on_floor():
        _sprite.play("jump")
    elif attacking:
        pass
    elif velocity.x != 0.0:
        _sprite.play("run")
    else:
        _sprite.play("idle")

func _handle_combo(delta: float) -> void:
    if is_dead:
        return
    if _is_attacking:
        _attack_timer -= delta
        if _attack_timer <= 0.0:
            _is_attacking = false
    if _combo_step > 0 and not _is_attacking:
        _combo_timer += delta
        if _combo_timer >= COMBO_WINDOW:
            _combo_step = 0
            _combo_timer = 0.0
    if Input.is_action_just_pressed("attack") and not _is_attacking:
        _strike()

static func next_combo_step(step: int) -> int:
    return (step + 1) % 3

func _strike() -> void:
    AudioManager.play_sfx(AudioLibrary.sfx_attack)
    var strike_num := _combo_step + 1
    _combo_step = strike_num % 3
    _combo_timer = 0.0
    _is_attacking = true
    _attack_timer = ZaraHitbox.ATTACK_DURATION
    _sprite.play("attack")
    var hitbox: ZaraHitbox = _HITBOX_SCENE.instantiate()
    hitbox.damage = COMBO_DAMAGE[strike_num]
    hitbox.source_id = GameManager.zara_selected_weapon
    var offset_x := HITBOX_OFFSET.x if facing_right else -HITBOX_OFFSET.x
    get_parent().add_child(hitbox)
    hitbox.global_position = global_position + Vector2(offset_x, HITBOX_OFFSET.y)
```

- [ ] **Step 2: Run tests to verify they PASS**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_zara.tscn
```

Expected output:
```
PASS: hitbox_properties
PASS: combo_progression
PASS: combo_damage
PASS: zara_run_animation
ALL TESTS PASSED
```

- [ ] **Step 3: Commit**

```bash
git add characters/melee/zara.gd
git commit -m "feat: animação run para Zara"
```

---

## Task 5: Update character_select.gd — preview uses run sprites

**Files:**
- Modify: `ui/character_select.gd`

- [ ] **Step 1: Update _setup_previews to load run sprites**

In `ui/character_select.gd`, update `_setup_previews()` — change the two texture load lines:

```gdscript
func _setup_previews() -> void:
    var zael_tex := load("res://characters/ranged/ZaelCorrendo.png") as Texture2D
    var zara_tex := load("res://characters/melee/ZaraCorrendo.png") as Texture2D
    var ry := _ROW_RIGHT * _FRAME_H
    for i in 5:
        var at := AtlasTexture.new()
        at.atlas = zael_tex
        at.region = Rect2(i * _FRAME_W, ry, _FRAME_W, _FRAME_H)
        _zael_frames.append(at)
        var at2 := AtlasTexture.new()
        at2.atlas = zara_tex
        at2.region = Rect2(i * _FRAME_W, ry, _FRAME_W, _FRAME_H)
        _zara_frames.append(at2)
    _zael_preview.texture = _zael_frames[0]
    _zara_preview.texture = _zara_frames[0]
```

(Only the first two lines of `_setup_previews` change — `ZaelAndando` → `ZaelCorrendo`, `ZaraAndando` → `ZaraCorrendo`. Everything else stays identical.)

- [ ] **Step 2: Commit**

```bash
git add ui/character_select.gd
git commit -m "feat: preview de personagem usa sprites de corrida"
```

---

## Task 6: Web export + push

- [ ] **Step 1: Export web build**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" export/web/index.html
```

- [ ] **Step 2: Commit and push**

```bash
git add export/web/
git commit -m "build: web export com animações run e shoot com charge"
git push
```
