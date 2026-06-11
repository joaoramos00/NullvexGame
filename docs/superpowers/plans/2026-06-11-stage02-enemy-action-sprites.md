# Stage 02 Enemy Action Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate and integrate real animation sheets for Stage 02 common enemies, excluding miniboss and bosses.

**Architecture:** Keep enemy scenes as `Sprite2D` frame sheets and replace temporary procedural sprite offsets with frame-based animation helpers. Shot enemies use a small local shot state so projectile creation happens once on a configured release frame. Generated raw/QC assets remain under `assets/generated/...`; runtime sheets live in `characters/enemies/stage_02/`.

**Tech Stack:** Godot 4.6 GDScript, `Sprite2D` hframes/vframes, local `generate2dsprite.py` processor, built-in `image_gen`, existing headless Godot tests, Web export, Playwright.

---

## File Structure

- `characters/enemies/enemy_base.gd`: keep shared frame helpers; add a helper for advancing one-shot frame animations if needed.
- `characters/enemies/stage_02/enemy_ice_grunt.tscn`: point to running sheet and set its frame grid.
- `characters/enemies/stage_02/enemy_ice_archer.gd`: convert timer-only shooting to shot animation state and release-frame projectile spawn.
- `characters/enemies/stage_02/enemy_ice_archer.tscn`: point to shot sheet and set frame grid.
- `characters/enemies/stage_02/enemy_frost_turret.gd`: convert timer-only shooting to shot animation state and release-frame projectile spawn.
- `characters/enemies/stage_02/enemy_frost_turret.tscn`: point to shot sheet and set frame grid.
- `characters/enemies/stage_02/enemy_cryo_bomber.gd`: convert timer-only lob to shot animation state and release-frame projectile spawn.
- `characters/enemies/stage_02/enemy_cryo_bomber.tscn`: point to shot sheet and set frame grid.
- `characters/enemies/stage_02/enemy_glacier_shield.gd`: use shield-lowering frame animation and remove temporary procedural sprite offset.
- `characters/enemies/stage_02/enemy_glacier_shield.tscn`: point to shield sheet and set frame grid.
- `characters/enemies/stage_02/enemy_ice_wisp.gd`: use hover frame animation and remove temporary procedural sprite offset.
- `characters/enemies/stage_02/enemy_ice_wisp.tscn`: point to hover sheet and set frame grid.
- `characters/enemies/stage_02/enemy_ice_flyer.gd`: keep current behavior; no new asset task unless verification fails.
- `tests/test_stage02_enemies.gd`: add tests for frame grids, loop frame advance, and release-frame projectile spawning.
- `assets/generated/stage02_<enemy>/<action>/`: raw generated sheets, processed transparent sheets, frames, GIFs, and metadata.
- `characters/enemies/stage_02/*.png`: final runtime-ready sheets.

---

### Task 1: Lock Animation Contracts With Failing Tests

**Files:**
- Modify: `tests/test_stage02_enemies.gd`

- [ ] **Step 1: Add tests for runtime sheet grids and action timing**

Add these helpers and tests to `tests/test_stage02_enemies.gd`. Place the test calls in `_ready()` before `_test_stage02_loads_new_enemy_scenes()`.

```gdscript
func _test_stage02_action_sprite_grids() -> void:
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_ice_grunt.tscn") == Vector2i(3, 2), "ice grunt uses 6-frame running grid")
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_ice_archer.tscn") == Vector2i(3, 2), "ice archer uses 6-frame shot grid")
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_frost_turret.tscn") == Vector2i(2, 2), "frost turret uses 4-frame shot grid")
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_cryo_bomber.tscn") == Vector2i(3, 2), "cryo bomber uses 6-frame shot grid")
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_glacier_shield.tscn") == Vector2i(2, 2), "glacier shield uses 4-frame shield grid")
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_ice_wisp.tscn") == Vector2i(2, 2), "ice wisp uses 4-frame hover grid")

func _test_stage02_looping_enemy_frames_advance() -> void:
	_assert(_advances_frame_after_tick("res://characters/enemies/stage_02/enemy_ice_grunt.tscn", 0.25), "ice grunt running advances frames")
	_assert(_advances_frame_after_tick("res://characters/enemies/stage_02/enemy_ice_wisp.tscn", 0.25), "ice wisp hover advances frames")

func _test_stage02_shot_release_frames_spawn_projectiles() -> void:
	_assert(_shot_enemy_spawns_one_projectile("res://characters/enemies/stage_02/enemy_ice_archer.tscn", "ice_archer"), "ice archer fires once during shot release frame")
	_assert(_shot_enemy_spawns_one_projectile("res://characters/enemies/stage_02/enemy_frost_turret.tscn", "frost_turret"), "frost turret fires once during shot release frame")
	_assert(_shot_enemy_spawns_one_projectile("res://characters/enemies/stage_02/enemy_cryo_bomber.tscn", "cryo_bomber"), "cryo bomber fires once during shot release frame")

func _sprite_grid(path: String) -> Vector2i:
	var scene := load(path) as PackedScene
	if scene == null:
		return Vector2i.ZERO
	var enemy := scene.instantiate()
	var sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
	var grid := Vector2i.ZERO
	if sprite != null:
		grid = Vector2i(sprite.hframes, sprite.vframes)
	enemy.free()
	return grid

func _advances_frame_after_tick(path: String, delta: float) -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	var enemy := scene.instantiate() as EnemyBase
	add_child(enemy)
	var sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		enemy.queue_free()
		return false
	var before := sprite.frame
	enemy._physics_process(delta)
	var advanced := sprite.frame != before
	enemy.queue_free()
	return advanced

func _shot_enemy_spawns_one_projectile(path: String, source: String) -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	var enemy := scene.instantiate() as EnemyBase
	add_child(enemy)
	enemy.set("_shoot_timer", 0.0)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	player.global_position = enemy.global_position + Vector2(180.0, 0.0)
	for i in 12:
		enemy._physics_process(0.12)
	var projectiles := 0
	for child in get_children():
		if child is EnemyIceProjectile and child.get("source") == source:
			projectiles += 1
			child.queue_free()
	player.queue_free()
	enemy.queue_free()
	return projectiles == 1
```

- [ ] **Step 2: Run RED**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --disable-crash-handler --log-file test-logs/test_stage02_action_sprites_red.log --path . res://tests/test_stage02_enemies.tscn
```

Expected: FAIL because Archer/Turret/Bomber/Shield/Wisp scenes still use single-frame images, and shot enemies fire from timers instead of release frames.

- [ ] **Step 3: Commit the failing tests only**

```powershell
git add tests/test_stage02_enemies.gd
git commit -m "test: define stage 02 enemy action sprite contracts"
```

---

### Task 2: Generate And Process Runtime Sprite Sheets

**Files:**
- Create: `assets/generated/stage02_ice_grunt/running/*`
- Create: `assets/generated/stage02_ice_archer/shot/*`
- Create: `assets/generated/stage02_frost_turret/shot/*`
- Create: `assets/generated/stage02_cryo_bomber/shot/*`
- Create: `assets/generated/stage02_glacier_shield/guard/*`
- Create: `assets/generated/stage02_ice_wisp/hover/*`
- Create/Modify: `characters/enemies/stage_02/enemy_ice_grunt_running.png`
- Create/Modify: `characters/enemies/stage_02/enemy_ice_archer_shot.png`
- Create/Modify: `characters/enemies/stage_02/enemy_frost_turret_shot.png`
- Create/Modify: `characters/enemies/stage_02/enemy_cryo_bomber_shot.png`
- Create/Modify: `characters/enemies/stage_02/enemy_glacier_shield_guard.png`
- Create/Modify: `characters/enemies/stage_02/enemy_ice_wisp_hover.png`

- [ ] **Step 1: Generate raw sheets with image_gen**

Use `generate2dsprite` rules: each prompt must request a solid `#FF00FF` background, side-view, centered subject, consistent scale, no cell edge crossing, and exact grid. Generate these six raw sheets:

```text
Ice Grunt running: 2 rows x 3 columns, 6 frames, side-view ice armored grunt sprinting aggressively, compact humanoid enemy, feet on stable bottom anchor, blue-white ice armor, dark joints, no projectile or detached effects.

Ice Archer shot: 2 rows x 3 columns, 6 frames, side-view ice archer standing planted, draw bow, hold tension, release arrow, recover to ready stance, projectile not detached from body sheet except the held arrow, stable feet, icy bow readable.

Frost Turret shot: 2 rows x 2 columns, 4 frames, fixed ice turret charges energy, muzzle opens, fires, settles, no detached projectile, stable base, glowing cyan core.

Cryo Bomber shot: 2 rows x 3 columns, 6 frames, heavy ice bomber standing planted, winds up, raises bomb, throws forward, recovers, no detached explosion, stable feet, readable bomb silhouette.

Glacier Shield guard: 2 rows x 2 columns, 4 frames, heavy shield enemy lowers the shield slightly, eyes glow bright cyan behind the shield, returns to guarded stance, stable feet, shield remains close to body.

Ice Wisp hover: 2 rows x 2 columns, 4 frames, small floating ice spirit hovering, subtle vertical float, glowing core, wispy ice shards, stable scale, no projectile.
```

Save each generated raw image under its `assets/generated/.../<action>/raw-sheet.png`. Also save the exact prompt as `prompt-used.txt` in the same folder.

- [ ] **Step 2: Process each generated sheet**

Run these commands, replacing `raw-sheet.png` if the generated file name differs:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage02_ice_grunt/running/raw-sheet.png --target creature --mode run --output-dir assets/generated/stage02_ice_grunt/running --rows 2 --cols 3 --label-prefix running --align feet --shared-scale --component-mode largest --fit-scale 0.92 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage02_ice_archer/shot/raw-sheet.png --target creature --mode shoot --output-dir assets/generated/stage02_ice_archer/shot --rows 2 --cols 3 --label-prefix shot --align feet --shared-scale --component-mode largest --fit-scale 0.90 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage02_frost_turret/shot/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage02_frost_turret/shot --rows 2 --cols 2 --label-prefix shot --align bottom --shared-scale --component-mode largest --fit-scale 0.92 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage02_cryo_bomber/shot/raw-sheet.png --target creature --mode shoot --output-dir assets/generated/stage02_cryo_bomber/shot --rows 2 --cols 3 --label-prefix shot --align feet --shared-scale --component-mode largest --fit-scale 0.90 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage02_glacier_shield/guard/raw-sheet.png --target creature --mode idle --output-dir assets/generated/stage02_glacier_shield/guard --rows 2 --cols 2 --label-prefix guard --align feet --shared-scale --component-mode largest --fit-scale 0.90 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage02_ice_wisp/hover/raw-sheet.png --target creature --mode hover --output-dir assets/generated/stage02_ice_wisp/hover --rows 2 --cols 2 --label-prefix hover --align center --shared-scale --component-mode largest --fit-scale 0.92 --reject-edge-touch
```

Expected: each output folder contains `sheet-transparent.png`, individual frame PNGs, `animation.gif`, and `pipeline-meta.json` with no edge-touch rejection.

- [ ] **Step 3: Copy accepted sheets to runtime names**

```powershell
Copy-Item assets/generated/stage02_ice_grunt/running/sheet-transparent.png characters/enemies/stage_02/enemy_ice_grunt_running.png -Force
Copy-Item assets/generated/stage02_ice_archer/shot/sheet-transparent.png characters/enemies/stage_02/enemy_ice_archer_shot.png -Force
Copy-Item assets/generated/stage02_frost_turret/shot/sheet-transparent.png characters/enemies/stage_02/enemy_frost_turret_shot.png -Force
Copy-Item assets/generated/stage02_cryo_bomber/shot/sheet-transparent.png characters/enemies/stage_02/enemy_cryo_bomber_shot.png -Force
Copy-Item assets/generated/stage02_glacier_shield/guard/sheet-transparent.png characters/enemies/stage_02/enemy_glacier_shield_guard.png -Force
Copy-Item assets/generated/stage02_ice_wisp/hover/sheet-transparent.png characters/enemies/stage_02/enemy_ice_wisp_hover.png -Force
```

- [ ] **Step 4: Import assets through Godot**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --disable-crash-handler --log-file test-logs/import_stage02_action_sprites.log --path . --quit
```

Expected: exit code `0`; `.import` files are generated for the runtime PNGs.

- [ ] **Step 5: Commit generated assets**

```powershell
git add assets/generated/stage02_ice_grunt/running assets/generated/stage02_ice_archer/shot assets/generated/stage02_frost_turret/shot assets/generated/stage02_cryo_bomber/shot assets/generated/stage02_glacier_shield/guard assets/generated/stage02_ice_wisp/hover characters/enemies/stage_02/enemy_ice_grunt_running.png characters/enemies/stage_02/enemy_ice_archer_shot.png characters/enemies/stage_02/enemy_frost_turret_shot.png characters/enemies/stage_02/enemy_cryo_bomber_shot.png characters/enemies/stage_02/enemy_glacier_shield_guard.png characters/enemies/stage_02/enemy_ice_wisp_hover.png characters/enemies/stage_02/*.import
git commit -m "feat: add stage 02 enemy action sprite sheets"
```

---

### Task 3: Add Frame Animation And Shot-State Helpers

**Files:**
- Modify: `characters/enemies/enemy_base.gd`
- Modify: `tests/test_stage02_enemies.gd`

- [ ] **Step 1: Add failing helper tests if Task 1 tests need a shared helper contract**

If Task 1 tests do not already fail on missing shot frame properties, add these assertions inside `_test_stage02_action_sprite_grids()`:

```gdscript
var archer := load("res://characters/enemies/stage_02/enemy_ice_archer.tscn").instantiate()
_assert(archer.get("shot_release_frame") == 3, "ice archer release frame is configured")
archer.free()
var turret := load("res://characters/enemies/stage_02/enemy_frost_turret.tscn").instantiate()
_assert(turret.get("shot_release_frame") == 2, "frost turret release frame is configured")
turret.free()
var bomber := load("res://characters/enemies/stage_02/enemy_cryo_bomber.tscn").instantiate()
_assert(bomber.get("shot_release_frame") == 3, "cryo bomber release frame is configured")
bomber.free()
```

- [ ] **Step 2: Add minimal animation helpers**

In `characters/enemies/enemy_base.gd`, add:

```gdscript
func _advance_sprite_frame_loop(delta: float, frame_count: int, fps: float) -> int:
	_animate_sprite_frames(delta, frame_count, fps)
	return _sprite.frame if is_instance_valid(_sprite) else 0

func _set_sprite_frame(frame_index: int) -> void:
	if is_instance_valid(_sprite):
		_sprite.frame = frame_index
```

- [ ] **Step 3: Run tests**

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --disable-crash-handler --log-file test-logs/test_stage02_animation_helpers.log --path . res://tests/test_stage02_enemies.tscn
```

Expected: helper-related assertions pass; shot/frame-grid tests may still fail until scenes and enemy scripts are integrated.

- [ ] **Step 4: Commit helper**

```powershell
git add characters/enemies/enemy_base.gd tests/test_stage02_enemies.gd
git commit -m "feat: add enemy sprite frame helpers"
```

---

### Task 4: Wire Runtime Sheets Into Scenes

**Files:**
- Modify: `characters/enemies/stage_02/enemy_ice_grunt.tscn`
- Modify: `characters/enemies/stage_02/enemy_ice_archer.tscn`
- Modify: `characters/enemies/stage_02/enemy_frost_turret.tscn`
- Modify: `characters/enemies/stage_02/enemy_cryo_bomber.tscn`
- Modify: `characters/enemies/stage_02/enemy_glacier_shield.tscn`
- Modify: `characters/enemies/stage_02/enemy_ice_wisp.tscn`

- [ ] **Step 1: Update scene texture resources and frame grids**

Patch each `.tscn` Sprite2D resource:

```gdscene
# enemy_ice_grunt.tscn
[ext_resource type="Texture2D" path="res://characters/enemies/stage_02/enemy_ice_grunt_running.png" id="2_tex"]
[node name="Sprite2D" type="Sprite2D" parent="."]
hframes = 3
vframes = 2

# enemy_ice_archer.tscn
[ext_resource type="Texture2D" path="res://characters/enemies/stage_02/enemy_ice_archer_shot.png" id="2_tex"]
[node name="Sprite2D" type="Sprite2D" parent="."]
hframes = 3
vframes = 2

# enemy_frost_turret.tscn
[ext_resource type="Texture2D" path="res://characters/enemies/stage_02/enemy_frost_turret_shot.png" id="2_tex"]
[node name="Sprite2D" type="Sprite2D" parent="."]
hframes = 2
vframes = 2

# enemy_cryo_bomber.tscn
[ext_resource type="Texture2D" path="res://characters/enemies/stage_02/enemy_cryo_bomber_shot.png" id="2_tex"]
[node name="Sprite2D" type="Sprite2D" parent="."]
hframes = 3
vframes = 2

# enemy_glacier_shield.tscn
[ext_resource type="Texture2D" path="res://characters/enemies/stage_02/enemy_glacier_shield_guard.png" id="2_tex"]
[node name="Sprite2D" type="Sprite2D" parent="."]
hframes = 2
vframes = 2

# enemy_ice_wisp.tscn
[ext_resource type="Texture2D" path="res://characters/enemies/stage_02/enemy_ice_wisp_hover.png" id="2_tex"]
[node name="Sprite2D" type="Sprite2D" parent="."]
hframes = 2
vframes = 2
```

Keep existing `position`, `scale`, collision shapes, and contact zones during this task. If visual QC proves a sprite is misaligned, fix that in Task 8 as a focused code change.

- [ ] **Step 2: Run grid tests**

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --disable-crash-handler --log-file test-logs/test_stage02_scene_grids.log --path . res://tests/test_stage02_enemies.tscn
```

Expected: grid assertions pass; shot state assertions may still fail.

- [ ] **Step 3: Commit scene wiring**

```powershell
git add characters/enemies/stage_02/enemy_ice_grunt.tscn characters/enemies/stage_02/enemy_ice_archer.tscn characters/enemies/stage_02/enemy_frost_turret.tscn characters/enemies/stage_02/enemy_cryo_bomber.tscn characters/enemies/stage_02/enemy_glacier_shield.tscn characters/enemies/stage_02/enemy_ice_wisp.tscn
git commit -m "feat: wire stage 02 enemy action sprite sheets"
```

---

### Task 5: Implement Looping Enemies

**Files:**
- Modify: `characters/enemies/stage_02/enemy_ice_grunt.gd`
- Modify: `characters/enemies/stage_02/enemy_ice_wisp.gd`

- [ ] **Step 1: Update Ice Grunt running loop**

Replace `enemy_ice_grunt.gd` with:

```gdscript
extends EnemyBase
class_name EnemyIceGrunt

const RUN_FRAMES := 6
const RUN_FPS := 10.0

func _init() -> void:
	max_hp = 10
	contact_damage = 8

func _ready() -> void:
	max_hp = 10
	contact_damage = 8
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_advance_sprite_frame_loop(delta, RUN_FRAMES, RUN_FPS)
```

- [ ] **Step 2: Update Ice Wisp hover loop**

In `enemy_ice_wisp.gd`, remove the call to `_animate_sprite_motion(...)` and add this after `move_and_slide()`/wall handling and before `_update_sprite()`:

```gdscript
_advance_sprite_frame_loop(delta, 4, 8.0)
```

- [ ] **Step 3: Run loop tests**

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --disable-crash-handler --log-file test-logs/test_stage02_looping_frames.log --path . res://tests/test_stage02_enemies.tscn
```

Expected: Ice Grunt and Ice Wisp frame-advance assertions pass.

- [ ] **Step 4: Commit looping enemies**

```powershell
git add characters/enemies/stage_02/enemy_ice_grunt.gd characters/enemies/stage_02/enemy_ice_wisp.gd tests/test_stage02_enemies.gd
git commit -m "feat: animate stage 02 looping enemies with sheets"
```

---

### Task 6: Implement Shot-State Enemies

**Files:**
- Modify: `characters/enemies/stage_02/enemy_ice_archer.gd`
- Modify: `characters/enemies/stage_02/enemy_frost_turret.gd`
- Modify: `characters/enemies/stage_02/enemy_cryo_bomber.gd`

- [ ] **Step 1: Implement Ice Archer shot state**

Patch `enemy_ice_archer.gd` with these properties and helpers:

```gdscript
@export var shot_frame_count: int = 6
@export var shot_fps: float = 10.0
@export var shot_release_frame: int = 3

var _shot_active := false
var _shot_frame := 0
var _shot_frame_timer := 0.0
var _shot_released := false

func _start_shot() -> void:
	_shot_active = true
	_shot_frame = 0
	_shot_frame_timer = 0.0
	_shot_released = false
	_set_sprite_frame(0)

func _tick_shot(delta: float) -> void:
	if not _shot_active:
		return
	velocity.x = 0.0
	_shot_frame_timer += delta
	var frame_duration := 1.0 / shot_fps
	while _shot_frame_timer >= frame_duration:
		_shot_frame_timer -= frame_duration
		_shot_frame += 1
		if _shot_frame == shot_release_frame and not _shot_released:
			_fire(Vector2(_direction * projectile_speed, 0.0), "ice_archer")
			_shot_released = true
		if _shot_frame >= shot_frame_count:
			_shot_active = false
			_shoot_timer = shoot_interval
			_shot_frame = 0
		_set_sprite_frame(_shot_frame % shot_frame_count)
```

In `_physics_process`, replace direct `_fire(...)` call with `_start_shot()`, and call `_tick_shot(delta)` before `move_and_slide()`.

- [ ] **Step 2: Implement Frost Turret shot state**

Use the same state shape in `enemy_frost_turret.gd`, with:

```gdscript
@export var shot_frame_count: int = 4
@export var shot_fps: float = 8.0
@export var shot_release_frame: int = 2
var _queued_shot_velocity := Vector2.RIGHT
```

When starting the shot, set:

```gdscript
_queued_shot_velocity = dir * projectile_speed
_start_shot()
```

At release, call:

```gdscript
_fire(_queued_shot_velocity)
```

- [ ] **Step 3: Implement Cryo Bomber shot state**

Use the same state shape in `enemy_cryo_bomber.gd`, with:

```gdscript
@export var shot_frame_count: int = 6
@export var shot_fps: float = 9.0
@export var shot_release_frame: int = 3
```

At release, call:

```gdscript
_lob()
```

During active shot, keep `velocity.x = 0.0` so the bomber stays planted.

- [ ] **Step 4: Remove temporary procedural motion from shot enemies**

Delete these lines:

```gdscript
_animate_sprite_motion(delta, 2.5, 9.0, 1.5, 1.0)
_animate_sprite_motion(delta, 1.5, 7.5, 1.0, 0.6)
_animate_sprite_motion(delta, 3.0, 6.5, 2.0, 1.3)
```

- [ ] **Step 5: Run shot-state tests**

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --disable-crash-handler --log-file test-logs/test_stage02_shot_states.log --path . res://tests/test_stage02_enemies.tscn
```

Expected: Archer, Turret, and Bomber each spawn exactly one projectile during one shot cycle.

- [ ] **Step 6: Commit shot-state enemies**

```powershell
git add characters/enemies/stage_02/enemy_ice_archer.gd characters/enemies/stage_02/enemy_frost_turret.gd characters/enemies/stage_02/enemy_cryo_bomber.gd tests/test_stage02_enemies.gd
git commit -m "feat: sync stage 02 enemy shots to animation frames"
```

---

### Task 7: Implement Glacier Shield Animation

**Files:**
- Modify: `characters/enemies/stage_02/enemy_glacier_shield.gd`
- Modify: `tests/test_stage02_enemies.gd`

- [ ] **Step 1: Add shield frame advance test if missing**

Ensure `_test_stage02_looping_enemy_frames_advance()` includes:

```gdscript
_assert(_advances_frame_after_tick("res://characters/enemies/stage_02/enemy_glacier_shield.tscn", 0.25), "glacier shield guard animation advances frames")
```

- [ ] **Step 2: Replace procedural shield motion with frame loop**

In `enemy_glacier_shield.gd`, remove:

```gdscript
_animate_sprite_motion(delta, 1.6, 5.0, 1.2, 0.8)
```

Add before sprite flip/modulate:

```gdscript
_advance_sprite_frame_loop(delta, 4, 6.0)
```

- [ ] **Step 3: Run shield test**

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --disable-crash-handler --log-file test-logs/test_stage02_glacier_shield_frames.log --path . res://tests/test_stage02_enemies.tscn
```

Expected: Glacier Shield frame-advance assertion passes.

- [ ] **Step 4: Commit shield animation**

```powershell
git add characters/enemies/stage_02/enemy_glacier_shield.gd tests/test_stage02_enemies.gd
git commit -m "feat: animate glacier shield guard action"
```

---

### Task 8: Verify ImgDebug And Web Export

**Files:**
- No code changes unless verification exposes an issue.

- [ ] **Step 1: Run focused tests**

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --disable-crash-handler --log-file test-logs/test_stage02_action_sprites_green.log --path . res://tests/test_stage02_enemies.tscn
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --disable-crash-handler --log-file test-logs/test_img_debug_action_sprites.log --path . res://tests/test_img_debug.tscn
```

Expected:

```text
=== test_stage02_enemies: ... passed, 0 failed ===
ALL TESTS PASSED
```

- [ ] **Step 2: Export Web**

```powershell
$godot = 'D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe'
$args = @('--headless', '--disable-crash-handler', '--log-file', 'test-logs/web_export_stage02_action_sprites.log', '--path', '.', '--export-debug', 'Web', 'export/web/index.html')
$p = Start-Process -FilePath $godot -ArgumentList $args -NoNewWindow -PassThru
if (-not $p.WaitForExit(120000)) { Stop-Process -Id $p.Id -Force; Write-Output "TIMEOUT_KILLED:$($p.Id)" } else { Write-Output "EXIT:$($p.ExitCode)" }
Get-Content test-logs/web_export_stage02_action_sprites.log -Tail 25
Get-ChildItem .\export\web\index.pck | Select-Object Name, Length, LastWriteTime
```

Expected: `EXIT:0` and an updated `export/web/index.pck`.

- [ ] **Step 3: Validate ImgDebug with Playwright**

```powershell
node -e "const { chromium } = require('./tests/bot/node_modules/playwright'); (async()=>{ const browser=await chromium.launch({headless:true}); const page=await browser.newPage({viewport:{width:1280,height:720}}); await page.goto('http://localhost:8000/web/index.html',{waitUntil:'load',timeout:30000}); await page.waitForSelector('canvas',{timeout:30000}); await page.waitForTimeout(5000); await page.mouse.click(640,580); await page.waitForTimeout(1000); await page.mouse.click(220,68); await page.waitForTimeout(1200); await page.mouse.click(1230,139); await page.waitForTimeout(1800); await page.locator('canvas').screenshot({path:'test-logs/playwright_stage02_action_sprites.png'}); console.log('shot:test-logs/playwright_stage02_action_sprites.png'); await browser.close(); })().catch(e=>{ console.error(e); process.exit(1); })"
```

Expected: screenshot exists and shows ImgDebug Movimentos rendering the selected enemy without a blank canvas.

- [ ] **Step 4: Commit final verification-related code fixes only if any**

If verification required code/test changes:

```powershell
git add <changed-code-or-test-files>
git commit -m "fix: polish stage 02 action sprite integration"
```

Do not commit `export/web/*`, `.godot/exported/*`, `.godot/editor/*`, or `test-logs/*`.

---

## Self-Review

- Spec coverage: asset generation, runtime frame animation, release-frame projectile sync, ImgDebug, Web export, and exclusion of miniboss/boss are covered.
- Red-flag scan: no unresolved planning markers or unspecified implementation steps remain.
- Type consistency: tests and implementation use existing `EnemyBase`, `EnemyIceProjectile`, `Sprite2D`, `hframes`, `vframes`, `_shoot_timer`, and existing projectile methods.
