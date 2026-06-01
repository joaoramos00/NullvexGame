# Intro Boss Sprites (Commander Vex) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate 4 animated sprite sheets for the Stage 00 intro boss (Commander Vex) via PixelLab MCP and wire them into intro_boss.gd/tscn, replacing the BossBase color-rectangle placeholder.

**Architecture:** PixelLab MCP creates a base character then animates it in 4 sequences (idle, walk, dash, shoot) in the "west" direction. Frames are downloaded via `tools/pixellab_download.py` and stitched into horizontal sprite sheets using Pillow. `intro_boss.gd` gains a `Sprite2D`-based animation controller following the same pattern as `enemy_miniboss.gd`.

**Tech Stack:** GDScript (Godot 4.6.2), PixelLab MCP tools (`create_character`, `animate_character`, `get_character`), Python + Pillow (frame stitching)

---

## File Map

| Action | File |
|--------|------|
| Modify | `tools/pixellab_download.py:166` — add `dash` and `shoot` to `--action` choices |
| Create | `characters/bosses/intro_boss/intro_boss_idle.png` — 4-frame sprite sheet |
| Create | `characters/bosses/intro_boss/intro_boss_walk.png` — 6-frame sprite sheet |
| Create | `characters/bosses/intro_boss/intro_boss_dash.png` — 6-frame sprite sheet |
| Create | `characters/bosses/intro_boss/intro_boss_shoot.png` — 6-frame sprite sheet |
| Modify | `characters/bosses/intro_boss.tscn` — add Sprite2D child node |
| Modify | `characters/bosses/intro_boss.gd` — add animation system, override `_draw()` |

---

## Task 1: Extend download script with dash/shoot action names

**Files:**
- Modify: `tools/pixellab_download.py:166`

The `cmd_animation` function uses `--action` only for file naming. Adding `dash` and `shoot` to the choices list is the only change needed.

- [ ] **Step 1: Edit the choices list**

In `tools/pixellab_download.py`, find line 166:
```python
p_anim.add_argument("--action", required=True, choices=["walk", "idle", "attack", "death", "hit"])
```
Replace with:
```python
p_anim.add_argument("--action", required=True, choices=["walk", "idle", "attack", "death", "hit", "dash", "shoot"])
```

- [ ] **Step 2: Verify the change**

Run:
```bash
python tools/pixellab_download.py animation --help
```
Expected output contains: `choices: ['walk', 'idle', 'attack', 'death', 'hit', 'dash', 'shoot']`

- [ ] **Step 3: Commit**

```bash
git add tools/pixellab_download.py
git commit -m "feat(tools): add dash/shoot action names to pixellab_download.py"
```

---

## Task 2: Generate Commander Vex base character via PixelLab MCP

**Files:** None (MCP call — returns character_id for Task 3)

- [ ] **Step 1: Check balance**

Call the `mcp__pixellab__get_balance` tool (no parameters needed).
Confirm remaining generations > 10 before proceeding.

- [ ] **Step 2: Queue character generation**

Call `mcp__pixellab__create_character` with:

```json
{
  "name": "CommanderVex",
  "description": "cybernetic corrupted soldier commander, dark charcoal tactical armor, glowing neon purple-blue joints and chest panel, single monocular visor helmet glowing blue, left arm humanoid, right arm has integrated energy cannon barrel, HD pixel art sidescroller boss, facing left",
  "size": 96,
  "view": "side",
  "n_directions": 4,
  "mode": "standard",
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "high detail",
  "proportions": "{\"type\": \"preset\", \"name\": \"heroic\"}"
}
```

Save the returned `character_id` — needed for all subsequent tasks.

- [ ] **Step 3: Poll until complete**

Call `mcp__pixellab__get_character` with `{ "character_id": "<id from step 2>" }` every few minutes until `status` is `"completed"` and `rotation_urls` has non-null entries. Typical wait: 2–5 minutes.

- [ ] **Step 4: Commit the character ID to a note**

Create `characters/bosses/intro_boss/.pixellab_ids` (plaintext, gitignored) with the character_id for reference:
```
character_id=<id>
```

Add to .gitignore:
```
characters/bosses/intro_boss/.pixellab_ids
```

---

## Task 3: Generate 4 animations via PixelLab MCP

**Files:** None (MCP calls — returns 4 job IDs for Task 4)

All 4 calls use `mode: "v3"` and `directions: ["west"]`. Record all job IDs.

- [ ] **Step 1: Queue idle animation**

Call `mcp__pixellab__animate_character` with:
```json
{
  "character_id": "<character_id from Task 2>",
  "action_description": "standing idle, subtle breathing motion, cannon arm lowered, weight shifted slightly, ready for combat",
  "directions": ["west"],
  "frame_count": 4,
  "mode": "v3"
}
```
Save: `job_idle = background_job_ids[0]`

- [ ] **Step 2: Queue walk animation**

Call `mcp__pixellab__animate_character` with:
```json
{
  "character_id": "<character_id from Task 2>",
  "action_description": "heavy tactical walk forward, cannon arm raised slightly, deliberate combat stride",
  "directions": ["west"],
  "frame_count": 6,
  "mode": "v3"
}
```
Save: `job_walk = background_job_ids[0]`

- [ ] **Step 3: Queue dash animation**

Call `mcp__pixellab__animate_character` with:
```json
{
  "character_id": "<character_id from Task 2>",
  "action_description": "aggressive dash lunge forward, body leaning forward hard, propulsion jets firing on boots and back with purple glow, building speed then peak velocity",
  "directions": ["west"],
  "frame_count": 6,
  "mode": "v3"
}
```
Save: `job_dash = background_job_ids[0]`

- [ ] **Step 4: Queue shoot animation**

Call `mcp__pixellab__animate_character` with:
```json
{
  "character_id": "<character_id from Task 2>",
  "action_description": "cannon arm raises and aims forward, energy charges in the barrel with blue glow building up, fires projectile with bright flash, cannon recoils back",
  "directions": ["west"],
  "frame_count": 6,
  "mode": "v3"
}
```
Save: `job_shoot = background_job_ids[0]`

- [ ] **Step 5: Append job IDs to .pixellab_ids**

Append to `characters/bosses/intro_boss/.pixellab_ids`:
```
job_idle=<job_idle>
job_walk=<job_walk>
job_dash=<job_dash>
job_shoot=<job_shoot>
```

---

## Task 4: Download frames and stitch sprite sheets

**Files:**
- Create: `characters/bosses/intro_boss/intro_boss_idle.png`
- Create: `characters/bosses/intro_boss/intro_boss_walk.png`
- Create: `characters/bosses/intro_boss/intro_boss_dash.png`
- Create: `characters/bosses/intro_boss/intro_boss_shoot.png`

The download script polls until each job completes (~2–4 min each) then saves individual frames. After downloading, a stitch step merges frames into a horizontal sprite sheet per animation.

- [ ] **Step 1: Create output directory**

```bash
mkdir characters/bosses/intro_boss
```

- [ ] **Step 2: Download character base sprite (west direction)**

```bash
python tools/pixellab_download.py character <character_id> characters/bosses/intro_boss/
```

Expected output: `intro_boss_west.png` (and other directions — only west is used in-game).

- [ ] **Step 3: Download idle frames**

```bash
python tools/pixellab_download.py animation <job_idle_id> characters/bosses/intro_boss/ --direction west --action idle
```

Expected: `intro_boss_idle_west_f00.png` through `intro_boss_idle_west_f03.png` (4 files) + a GIF preview.

- [ ] **Step 4: Download walk frames**

```bash
python tools/pixellab_download.py animation <job_walk_id> characters/bosses/intro_boss/ --direction west --action walk
```

Expected: `intro_boss_walk_west_f00.png` through `intro_boss_walk_west_f05.png` (6 files).

- [ ] **Step 5: Download dash frames**

```bash
python tools/pixellab_download.py animation <job_dash_id> characters/bosses/intro_boss/ --direction west --action dash
```

Expected: `intro_boss_dash_west_f00.png` through `intro_boss_dash_west_f05.png` (6 files).

- [ ] **Step 6: Download shoot frames**

```bash
python tools/pixellab_download.py animation <job_shoot_id> characters/bosses/intro_boss/ --direction west --action shoot
```

Expected: `intro_boss_shoot_west_f00.png` through `intro_boss_shoot_west_f05.png` (6 files).

- [ ] **Step 7: Stitch sprite sheets**

Save this as `tools/stitch_intro_boss.py` and run it:

```python
#!/usr/bin/env python3
"""Stitch individual PixelLab frames into horizontal sprite sheets."""
from PIL import Image
import glob, sys
from pathlib import Path

SRC = Path("characters/bosses/intro_boss")

def stitch(action: str, expected_frames: int) -> None:
    pattern = str(SRC / f"intro_boss_{action}_west_f*.png")
    files = sorted(glob.glob(pattern))
    if len(files) != expected_frames:
        print(f"WARNING: {action}: expected {expected_frames} frames, got {len(files)}")
    frames = [Image.open(f).convert("RGBA") for f in files]
    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        sheet.paste(fr, (i * w, 0))
    out = SRC / f"intro_boss_{action}.png"
    sheet.save(out)
    print(f"Saved {out}  ({len(frames)} frames, each {w}×{h}px)")

stitch("idle",  4)
stitch("walk",  6)
stitch("dash",  6)
stitch("shoot", 6)
```

```bash
python tools/stitch_intro_boss.py
```

Expected output:
```
Saved characters/bosses/intro_boss/intro_boss_idle.png  (4 frames, each Nx${H}px)
Saved characters/bosses/intro_boss/intro_boss_walk.png  (6 frames, ...)
Saved characters/bosses/intro_boss/intro_boss_dash.png  (6 frames, ...)
Saved characters/bosses/intro_boss/intro_boss_shoot.png (6 frames, ...)
```

- [ ] **Step 8: Commit sprite sheets**

```bash
git add characters/bosses/intro_boss/intro_boss_idle.png \
        characters/bosses/intro_boss/intro_boss_walk.png \
        characters/bosses/intro_boss/intro_boss_dash.png \
        characters/bosses/intro_boss/intro_boss_shoot.png \
        tools/stitch_intro_boss.py \
        .gitignore
git commit -m "feat(assets): add Commander Vex sprite sheets (idle/walk/dash/shoot)"
```

---

## Task 5: Add Sprite2D to intro_boss.tscn

**Files:**
- Modify: `characters/bosses/intro_boss.tscn`

The `.tscn` currently only has the root node inheriting from `boss_base.tscn`. We add a `Sprite2D` child with nearest-neighbor filtering.

- [ ] **Step 1: Edit intro_boss.tscn**

Current content of `characters/bosses/intro_boss.tscn`:
```
[gd_scene format=3 uid="uid://intro_boss"]

[ext_resource type="PackedScene" uid="uid://boss_base" path="res://characters/bosses/boss_base.tscn" id="1_base"]
[ext_resource type="Script" path="res://characters/bosses/intro_boss.gd" id="2_script"]

[node name="IntroBoss" instance=ExtResource("1_base")]
script = ExtResource("2_script")
boss_id = "intro_boss"
weakness_id = ""
ability_id = ""
stage_id = 0
max_hp = 28
boss_color = Color(0.5, 0.0, 0.1, 1)
```

Replace the entire file with:
```
[gd_scene format=3 uid="uid://intro_boss"]

[ext_resource type="PackedScene" uid="uid://boss_base" path="res://characters/bosses/boss_base.tscn" id="1_base"]
[ext_resource type="Script" path="res://characters/bosses/intro_boss.gd" id="2_script"]

[node name="IntroBoss" instance=ExtResource("1_base")]
script = ExtResource("2_script")
boss_id = "intro_boss"
weakness_id = ""
ability_id = ""
stage_id = 0
max_hp = 28
boss_color = Color(0.5, 0.0, 0.1, 1)

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_filter = 1
```

`texture_filter = 1` is `CanvasItem.TEXTURE_FILTER_NEAREST` in Godot 4.

- [ ] **Step 2: Commit**

```bash
git add characters/bosses/intro_boss.tscn
git commit -m "feat(intro_boss): add Sprite2D node for pixel-art rendering"
```

---

## Task 6: Update intro_boss.gd with animation system

**Files:**
- Modify: `characters/bosses/intro_boss.gd`

Replace the entire file. Key changes from original:
- Add 4 texture preloads + animation constants
- Add `@onready var _sprite: Sprite2D = $Sprite2D`
- Add animation state vars (`_is_shooting`, `_shoot_anim_timer`, `_anim_frame`, `_anim_timer`, `_facing`)
- Override `_draw()` with `pass` to suppress BossBase color-rectangle placeholder
- Override `_physics_process(delta)` to call `super` then `_update_animation(delta)`
- Update `_do_combat(delta)` to decrement `_shoot_anim_timer`
- Update `_do_shoot()` to start shoot animation
- Add `_update_animation(delta)` — texture selection, flip, modulate, frame advance

- [ ] **Step 1: Replace intro_boss.gd**

```gdscript
extends BossBase
class_name IntroBoss

const _TEX_IDLE  := preload("res://characters/bosses/intro_boss/intro_boss_idle.png")
const _TEX_WALK  := preload("res://characters/bosses/intro_boss/intro_boss_walk.png")
const _TEX_DASH  := preload("res://characters/bosses/intro_boss/intro_boss_dash.png")
const _TEX_SHOOT := preload("res://characters/bosses/intro_boss/intro_boss_shoot.png")

const _IDLE_FRAMES  := 4;  const _IDLE_FPS  := 6.0
const _WALK_FRAMES  := 6;  const _WALK_FPS  := 8.0
const _DASH_FRAMES  := 6;  const _DASH_FPS  := 12.0
const _SHOOT_FRAMES := 6;  const _SHOOT_FPS := 12.0

const DASH_SPEED       := 320.0
const DASH_DURATION    := 0.45
const SHOOT_COOLDOWN   := 2.2
const PROJECTILE_SPEED := 260.0

var _attack_phase     : int   = 0    # 0=dash, 1=shoot, alternates
var _is_dashing       : bool  = false
var _dash_timer       : float = 0.0
var _is_shooting      : bool  = false
var _shoot_anim_timer : float = 0.0
var _anim_frame       : int   = 0
var _anim_timer       : float = 0.0
var _facing           : float = -1.0  # -1 = left (west, default); 1 = right (east, flip_h)

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	stage_id           = 0
	ability_id         = ""
	max_hp             = 28
	boss_color         = Color(0.5, 0.0, 0.1, 1)
	attack_interval_p1 = SHOOT_COOLDOWN
	attack_interval_p2 = SHOOT_COOLDOWN * 0.7
	super()

# Suppress the BossBase color-rectangle placeholder.
func _draw() -> void:
	pass

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_dead:
		_update_animation(delta)

func _do_combat(delta: float) -> void:
	if _is_shooting:
		_shoot_anim_timer = maxf(0.0, _shoot_anim_timer - delta)
		if _shoot_anim_timer <= 0.0:
			_is_shooting = false
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
			velocity.x = 0.0
	else:
		if player != null:
			var dx: float = player.global_position.x - global_position.x
			if abs(dx) > 80.0:
				velocity.x = sign(dx) * 60.0
			else:
				velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	_clamp_to_arena()

func _do_attack() -> void:
	if _attack_phase == 0:
		_do_dash()
	else:
		_do_shoot()
	_attack_phase = (_attack_phase + 1) % 2

func _do_dash() -> void:
	if player == null:
		return
	var dir: float = sign(player.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	velocity.x = dir * DASH_SPEED
	_is_dashing = true
	_dash_timer = DASH_DURATION

func _do_shoot() -> void:
	if player == null:
		return
	_is_attacking = true
	_is_shooting = true
	_shoot_anim_timer = float(_SHOOT_FRAMES) / _SHOOT_FPS
	velocity.x = 0.0
	var dir := (player.global_position - global_position).normalized()
	_spawn_projectile(global_position, dir * PROJECTILE_SPEED, 8, "intro_boss", Color(0.7, 0.1, 0.2))
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.2

func _update_animation(delta: float) -> void:
	# Track facing from movement; hold last direction when stopped
	if velocity.x > 0.0:
		_facing = 1.0
	elif velocity.x < 0.0:
		_facing = -1.0
	_sprite.flip_h = _facing > 0.0

	# Modulate: hit flash → overbright; invincible → flicker; else normal
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var alpha: float = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	else:
		_sprite.modulate = Color.WHITE

	# Choose texture by priority: shoot > dash > walk > idle
	var tex: Texture2D
	var frames: int
	var fps: float
	if _is_shooting:
		tex = _TEX_SHOOT; frames = _SHOOT_FRAMES; fps = _SHOOT_FPS
	elif _is_dashing:
		tex = _TEX_DASH;  frames = _DASH_FRAMES;  fps = _DASH_FPS
	elif absf(velocity.x) > 10.0:
		tex = _TEX_WALK;  frames = _WALK_FRAMES;  fps = _WALK_FPS
	else:
		tex = _TEX_IDLE;  frames = _IDLE_FRAMES;  fps = _IDLE_FPS

	# Reset frame counter when texture changes
	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = frames
		_anim_frame     = 0
		_anim_timer     = 0.0

	# Dash: freeze on last frame during the lunge
	if _is_dashing:
		_sprite.frame = _DASH_FRAMES - 1
		return

	# Advance frame
	_anim_timer += delta
	if _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		_anim_frame  = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame
```

- [ ] **Step 2: Run headless tests to check for parse errors**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
```

Expected: no script parse errors. (These tests don't exercise the boss directly but confirm Godot can load the project without crashes.)

- [ ] **Step 3: Commit**

```bash
git add characters/bosses/intro_boss.gd
git commit -m "feat(intro_boss): add Commander Vex animation system (idle/walk/dash/shoot)"
```

---

## Task 7: Verify in Godot editor

**Files:** None (visual inspection only)

- [ ] **Step 1: Open stage_00 scene in editor**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --path . res://stages/stage_00/stage_00.tscn
```

Or open the editor and load `stages/stage_00/stage_00.tscn`.

- [ ] **Step 2: Play the scene and reach the boss room**

The boss spawns after the second checkpoint door (x ≈ 17120 in world space). Walk through the stage until the boss door opens, or directly set a breakpoint / edit `BOSS_SPAWN` temporarily to a position near the player spawn.

- [ ] **Step 3: Confirm each animation plays**

| Condition | Expected animation |
|-----------|--------------------|
| Boss enters arena, player far | walk texture cycling |
| Boss stops / player near | idle texture cycling |
| Boss dash attack fires | dash texture, freezes on frame 5 during lunge |
| Boss shoot attack fires | shoot texture plays for 0.5s, then returns to idle/walk |
| Player hits boss | sprite flickers white briefly |
| Boss invincible window | sprite alpha flickers 0.35↔1.0 |
| Boss dies | BossBase death sequence (no sprite change needed — handled by BossBase) |

- [ ] **Step 4: Final commit (if any fixes were needed)**

```bash
git add -p
git commit -m "fix(intro_boss): address visual issues found during play test"
```
