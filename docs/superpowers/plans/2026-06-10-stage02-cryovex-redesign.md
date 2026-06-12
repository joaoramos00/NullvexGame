# Stage 02 Cryovex Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild `stage_02` as an ambitious complex ice stage with four zones, three `CorridorSection` checkpoints, MB02, ice hazards, gated collectibles, abundant new ice enemies, and no Cryovex implementation changes.

**Architecture:** Keep `stage_02_scene.gd` as the stage orchestrator: player spawn, camera, corridors, zone triggers, enemy spawning, and terrain drawing. Put hazards/gates in small local scripts under `stages/stage_02/`; put ice enemies under `characters/enemies/stage_02/`; generate sprites with `generate2dsprite` before wiring final textures.

**Tech Stack:** Godot 4.6.2, GDScript, `CorridorSection`, `EnemyBase`/`EnemyFlyer`, existing `Collectible`, existing tests style (`extends Node` + `.tscn`), `generate2dsprite` for sprite PNG/GIF assets.

---

## File Structure

Create:

- `stages/stage_02/stage_02_scene.gd` — complex stage controller for Stage 02.
- `stages/stage_02/ice_floor.gd` — local Area2D that marks bodies as standing on ice.
- `stages/stage_02/ice_spikes.gd` — local Area2D damage hazard for crystals/spikes.
- `stages/stage_02/blizzard_zone.gd` — local Area2D wind hazard that applies lateral force to player bodies.
- `stages/stage_02/ice_gate.gd` — StaticBody2D gate destroyed by a required unlocked ability.
- `characters/enemies/stage_02/enemy_ice_grunt.gd` — icy ground enemy derived from `EnemyBase`.
- `characters/enemies/stage_02/enemy_ice_grunt.tscn` — ground enemy scene.
- `characters/enemies/stage_02/enemy_ice_flyer.gd` — icy flyer derived from `EnemyFlyer`.
- `characters/enemies/stage_02/enemy_ice_flyer.tscn` — flyer scene.
- `characters/enemies/stage_02/enemy_ice_miniboss.gd` — MB02 logic.
- `characters/enemies/stage_02/enemy_ice_miniboss.tscn` — MB02 scene.
- `tests/test_stage02_hazards.gd` and `.tscn` — tests local hazards/gates.
- `tests/test_stage_02.gd` and `.tscn` — tests Stage 02 structure.

Modify:

- `stages/stage_02/stage_02.tscn` — replace simple stage with complex stage root using `stage_02_scene.gd`.
- `characters/base/character_base.gd` — add optional ice-surface hooks only if no existing movement hook can be used locally.

Do not modify:

- `characters/bosses/cryovex.gd`
- `characters/bosses/cryovex.tscn`

---

## Task 1: Stage 02 Hazard and Gate Tests

**Files:**
- Create: `tests/test_stage02_hazards.gd`
- Create: `tests/test_stage02_hazards.tscn`
- The implementation files covered by this test are created in Task 2.

- [ ] **Step 1: Write failing hazard/gate tests**

Create `tests/test_stage02_hazards.gd`:

```gdscript
extends Node

var _passed := 0
var _failed := 0

class DummyPlayer:
	extends CharacterBody2D
	var damage_taken := 0
	var blizzard_push := Vector2.ZERO
	var on_ice := false
	func take_damage(amount: int) -> void:
		damage_taken += amount
	func apply_stage_wind(force: Vector2) -> void:
		blizzard_push += force
	func set_stage_ice(value: bool) -> void:
		on_ice = value

func _ready() -> void:
	_test_ice_floor_marks_player()
	_test_ice_spikes_damage_player()
	_test_blizzard_pushes_player()
	_test_ice_gate_requires_ability()
	_print_results()
	get_tree().quit(0 if _failed == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: " + msg)
	else:
		_failed += 1
		print("  FAIL: " + msg)

func _test_ice_floor_marks_player() -> void:
	var ice := preload("res://stages/stage_02/ice_floor.gd").new()
	var player := DummyPlayer.new()
	add_child(ice)
	add_child(player)
	ice._on_body_entered(player)
	_assert(player.on_ice, "ice_floor marks player on ice")
	ice._on_body_exited(player)
	_assert(not player.on_ice, "ice_floor clears player ice state")
	ice.queue_free()
	player.queue_free()

func _test_ice_spikes_damage_player() -> void:
	var spikes := preload("res://stages/stage_02/ice_spikes.gd").new()
	var player := DummyPlayer.new()
	add_child(spikes)
	add_child(player)
	spikes.damage = 7
	spikes._on_body_entered(player)
	_assert(player.damage_taken == 7, "ice_spikes damage player once on enter")
	spikes.queue_free()
	player.queue_free()

func _test_blizzard_pushes_player() -> void:
	var blizzard := preload("res://stages/stage_02/blizzard_zone.gd").new()
	var player := DummyPlayer.new()
	add_child(blizzard)
	add_child(player)
	blizzard.force = Vector2(120.0, 0.0)
	blizzard._on_body_entered(player)
	blizzard._physics_process(0.5)
	_assert(player.blizzard_push == Vector2(60.0, 0.0), "blizzard applies force * delta")
	blizzard._on_body_exited(player)
	blizzard._physics_process(0.5)
	_assert(player.blizzard_push == Vector2(60.0, 0.0), "blizzard stops after exit")
	blizzard.queue_free()
	player.queue_free()

func _test_ice_gate_requires_ability() -> void:
	GameManager.boss_abilities_unlocked.clear()
	var gate := preload("res://stages/stage_02/ice_gate.gd").new()
	add_child(gate)
	gate.required_ability = "ignarath"
	gate.try_destroy()
	_assert(not gate.is_queued_for_deletion(), "ice_gate stays without required ability")
	GameManager.boss_abilities_unlocked.append("ignarath")
	gate.try_destroy()
	_assert(gate.is_queued_for_deletion(), "ice_gate queues free with required ability")
	GameManager.boss_abilities_unlocked.clear()
	gate.queue_free()

func _print_results() -> void:
	print("\n=== test_stage02_hazards: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TESTS FAILED")
```

Create `tests/test_stage02_hazards.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://tests/test_stage02_hazards.gd" id="1_script"]

[node name="TestStage02Hazards" type="Node"]
script = ExtResource("1_script")
```

- [ ] **Step 2: Run tests and confirm failure**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage02_hazards.tscn
```

Expected: FAIL because `ice_floor.gd`, `ice_spikes.gd`, `blizzard_zone.gd`, and `ice_gate.gd` do not exist.

- [ ] **Step 3: Commit failing tests**

```bash
git add tests/test_stage02_hazards.gd tests/test_stage02_hazards.tscn
git commit -m "test: add stage 02 hazard specs"
```

---

## Task 2: Stage 02 Hazards and Gates

**Files:**
- Create: `stages/stage_02/ice_floor.gd`
- Create: `stages/stage_02/ice_spikes.gd`
- Create: `stages/stage_02/blizzard_zone.gd`
- Create: `stages/stage_02/ice_gate.gd`
- Modify: `characters/base/character_base.gd` for `set_stage_ice()` and `apply_stage_wind()` hooks.

- [ ] **Step 1: Implement `ice_floor.gd`**

Create `stages/stage_02/ice_floor.gd`:

```gdscript
extends Area2D
class_name Stage02IceFloor

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.has_method("set_stage_ice"):
		body.set_stage_ice(true)
	else:
		body.set_meta("stage_ice", true)

func _on_body_exited(body: Node) -> void:
	if body.has_method("set_stage_ice"):
		body.set_stage_ice(false)
	else:
		body.set_meta("stage_ice", false)
```

- [ ] **Step 2: Add character ice hook**

Modify `characters/base/character_base.gd` so ice floors have a concrete movement effect.

Add variables near other movement state:

```gdscript
var _stage_ice_contacts: int = 0
var _stage_on_ice: bool = false
```

Add method:

```gdscript
func set_stage_ice(value: bool) -> void:
	if value:
		_stage_ice_contacts += 1
	else:
		_stage_ice_contacts = maxi(0, _stage_ice_contacts - 1)
	_stage_on_ice = _stage_ice_contacts > 0
```

In horizontal movement logic, use reduced acceleration/friction only while `_stage_on_ice and is_on_floor()`. Preserve existing max speed and dash behavior. If movement uses direct assignment, replace the normal ground branch with:

```gdscript
var input_axis := Input.get_axis("move_left", "move_right")
var target_speed := input_axis * SPEED
if _stage_on_ice and is_on_floor() and not _is_dashing:
	var accel := 420.0 if input_axis != 0.0 else 180.0
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)
else:
	velocity.x = target_speed
```

- [ ] **Step 3: Implement `ice_spikes.gd`**

Create `stages/stage_02/ice_spikes.gd`:

```gdscript
extends Area2D
class_name Stage02IceSpikes

@export var damage: int = 12

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
```

- [ ] **Step 4: Implement `blizzard_zone.gd`**

Create `stages/stage_02/blizzard_zone.gd`:

```gdscript
extends Area2D
class_name Stage02BlizzardZone

@export var force: Vector2 = Vector2(180.0, 0.0)

var _bodies_inside: Array[Node] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body not in _bodies_inside:
		_bodies_inside.append(body)

func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)

func _physics_process(delta: float) -> void:
	for body in _bodies_inside:
		if not is_instance_valid(body):
			continue
		if body.has_method("apply_stage_wind"):
			body.apply_stage_wind(force * delta)
		elif body is CharacterBody2D:
			(body as CharacterBody2D).velocity += force * delta
```

If `CharacterBase` needs a hook, add:

```gdscript
func apply_stage_wind(force_delta: Vector2) -> void:
	velocity += force_delta
```

- [ ] **Step 5: Implement `ice_gate.gd`**

Create `stages/stage_02/ice_gate.gd`:

```gdscript
extends StaticBody2D
class_name Stage02IceGate

signal gate_destroyed

@export var required_ability: String = "ignarath"

func _ready() -> void:
	add_to_group("stage02_ice_gate")
	var detector := get_node_or_null("HitDetector") as Area2D
	if detector != null:
		detector.collision_layer = 0
		detector.collision_mask = 8
		detector.area_entered.connect(_on_hit)

func _on_hit(_area: Area2D) -> void:
	try_destroy()

func try_destroy() -> void:
	if GameManager.boss_abilities_unlocked.has(required_ability):
		gate_destroyed.emit()
		queue_free()
```

- [ ] **Step 6: Run hazard tests**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage02_hazards.tscn
```

Expected: output contains `=== test_stage02_hazards: 7 passed, 0 failed ===` and exit code 0.

- [ ] **Step 7: Commit hazards**

```bash
git add stages/stage_02/ice_floor.gd stages/stage_02/ice_spikes.gd stages/stage_02/blizzard_zone.gd stages/stage_02/ice_gate.gd characters/base/character_base.gd tests/test_stage02_hazards.gd tests/test_stage02_hazards.tscn
git commit -m "feat: add stage 02 ice hazards"
```

---

## Task 3: Ice Enemy Scripts and Tests

**Files:**
- Create: `characters/enemies/stage_02/enemy_ice_grunt.gd`
- Create: `characters/enemies/stage_02/enemy_ice_flyer.gd`
- Create: `characters/enemies/stage_02/enemy_ice_miniboss.gd`
- Create: `tests/test_stage02_enemies.gd`
- Create: `tests/test_stage02_enemies.tscn`

- [ ] **Step 1: Write failing enemy tests**

Create `tests/test_stage02_enemies.gd`:

```gdscript
extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	_test_ice_grunt_defaults()
	_test_ice_flyer_defaults()
	_test_ice_miniboss_defaults()
	_print_results()
	get_tree().quit(0 if _failed == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: " + msg)
	else:
		_failed += 1
		print("  FAIL: " + msg)

func _test_ice_grunt_defaults() -> void:
	var enemy := preload("res://characters/enemies/stage_02/enemy_ice_grunt.gd").new()
	add_child(enemy)
	_assert(enemy.max_hp >= 10, "ice grunt has stronger hp than base grunt")
	_assert(enemy.contact_damage >= 8, "ice grunt keeps meaningful contact damage")
	enemy.queue_free()

func _test_ice_flyer_defaults() -> void:
	var enemy := preload("res://characters/enemies/stage_02/enemy_ice_flyer.gd").new()
	add_child(enemy)
	_assert(enemy.detect_radius >= 220.0, "ice flyer detects from long range")
	_assert(enemy.dive_speed >= 300.0, "ice flyer dives faster than base flyer")
	enemy.queue_free()

func _test_ice_miniboss_defaults() -> void:
	var enemy := preload("res://characters/enemies/stage_02/enemy_ice_miniboss.gd").new()
	add_child(enemy)
	_assert(enemy.max_hp >= 40, "MB02 has miniboss hp")
	_assert(enemy.has_signal("died"), "MB02 inherits died signal")
	enemy.queue_free()

func _print_results() -> void:
	print("\n=== test_stage02_enemies: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TESTS FAILED")
```

Create `tests/test_stage02_enemies.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://tests/test_stage02_enemies.gd" id="1_script"]

[node name="TestStage02Enemies" type="Node"]
script = ExtResource("1_script")
```

- [ ] **Step 2: Run tests and confirm failure**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage02_enemies.tscn
```

Expected: FAIL because enemy scripts do not exist.

- [ ] **Step 3: Implement ice enemy scripts**

Create `characters/enemies/stage_02/enemy_ice_grunt.gd`:

```gdscript
extends EnemyBase
class_name EnemyIceGrunt

func _ready() -> void:
	max_hp = 10
	contact_damage = 8
	super._ready()
```

Create `characters/enemies/stage_02/enemy_ice_flyer.gd`:

```gdscript
extends EnemyFlyer
class_name EnemyIceFlyer

func _ready() -> void:
	max_hp = 9
	contact_damage = 7
	detect_radius = 240.0
	dive_speed = 310.0
	retreat_speed = 170.0
	super._ready()
```

Create `characters/enemies/stage_02/enemy_ice_miniboss.gd`:

```gdscript
extends EnemyBase
class_name EnemyIceMiniBoss

const SLAM_DAMAGE := 10
const SLIDE_SPEED := 320.0
const HOP_IMPULSE := -360.0

enum State { ADVANCE, SLIDE, HOP, RECOVER }

@export var arena_left: float = 0.0
@export var arena_right: float = 1000.0

var _state: State = State.ADVANCE
var _cooldown := 1.0
var _recover_timer := 0.0

func _ready() -> void:
	max_hp = 44
	contact_damage = 8
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_cooldown = maxf(0.0, _cooldown - delta)
	match _state:
		State.ADVANCE:
			_tick_advance()
		State.SLIDE:
			_tick_slide()
		State.HOP:
			_tick_hop()
		State.RECOVER:
			_tick_recover(delta)
	move_and_slide()
	if is_on_wall():
		_direction = -_direction
		_enter_recover(0.45)
	global_position.x = clampf(global_position.x, arena_left, arena_right)

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _tick_advance() -> void:
	var player := _get_player()
	if player != null:
		var dx := player.global_position.x - global_position.x
		_direction = sign(dx) if dx != 0.0 else _direction
	velocity.x = PATROL_SPEED * 0.9 * _direction
	if _cooldown <= 0.0:
		if randf() < 0.55:
			_state = State.SLIDE
		else:
			velocity.y = HOP_IMPULSE
			_state = State.HOP

func _tick_slide() -> void:
	velocity.x = SLIDE_SPEED * _direction
	if global_position.x <= arena_left or global_position.x >= arena_right:
		_direction = -_direction
		_enter_recover(0.5)

func _tick_hop() -> void:
	velocity.x = PATROL_SPEED * 1.4 * _direction
	if is_on_floor():
		_enter_recover(0.65)

func _tick_recover(delta: float) -> void:
	velocity.x = 0.0
	_recover_timer -= delta
	if _recover_timer <= 0.0:
		_cooldown = 1.2
		_state = State.ADVANCE

func _enter_recover(duration: float) -> void:
	_recover_timer = duration
	_state = State.RECOVER
```

- [ ] **Step 4: Run enemy tests**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage02_enemies.tscn
```

Expected: `=== test_stage02_enemies: 6 passed, 0 failed ===`.

- [ ] **Step 5: Commit enemy scripts**

```bash
git add characters/enemies/stage_02/enemy_ice_grunt.gd characters/enemies/stage_02/enemy_ice_flyer.gd characters/enemies/stage_02/enemy_ice_miniboss.gd tests/test_stage02_enemies.gd tests/test_stage02_enemies.tscn
git commit -m "feat: add stage 02 ice enemies"
```

---

## Task 4: Generate Ice Enemy Sprites with `generate2dsprite`

**Files:**
- Create generated outputs under `assets/generated/stage02_ice_grunt/`
- Create generated outputs under `assets/generated/stage02_ice_flyer/`
- Create generated outputs under `assets/generated/stage02_ice_miniboss/`
- Copy accepted transparent sheets to `characters/enemies/stage_02/`
- Create: `characters/enemies/stage_02/enemy_ice_grunt.tscn`
- Create: `characters/enemies/stage_02/enemy_ice_flyer.tscn`
- Create: `characters/enemies/stage_02/enemy_ice_miniboss.tscn`

- [ ] **Step 1: Use `generate2dsprite` for ice grunt**

Invoke `generate2dsprite` for a side-view enemy walk sheet:

```text
asset_type=creature
action=walk
view=side
sheet=2x3
frames=6
bundle=single_asset
anchor=feet
art_style=pixel_art
name=stage02_ice_grunt
prompt=HD pixel art Mega Man X inspired side-view ice grunt robot enemy for an icy stage, compact biped silhouette, pale blue armor, frost cracks, dark outline, visible feet, 6-frame walking loop, centered in each cell, solid #FF00FF background, consistent scale, no detached effects
```

Process with `generate2dsprite.py process` using rows `2`, cols `3`, shared scale, feet anchor, and reject edge touch. Save accepted output as:

```text
characters/enemies/stage_02/enemy_ice_grunt_walk.png
```

- [ ] **Step 2: Use `generate2dsprite` for ice flyer**

Invoke `generate2dsprite`:

```text
asset_type=creature
action=hover
view=side
sheet=2x2
frames=4
bundle=single_asset
anchor=center
art_style=pixel_art
name=stage02_ice_flyer
prompt=HD pixel art Mega Man X inspired side-view flying ice drone enemy, crystal wings, pale cyan body, glowing blue core, 4-frame hover loop, centered in each cell, solid #FF00FF background, consistent scale, no detached projectile effects
```

Save accepted output as:

```text
characters/enemies/stage_02/enemy_ice_flyer_hover.png
```

- [ ] **Step 3: Use `generate2dsprite` for MB02**

Generate at least idle and attack/slide body sheets:

```text
asset_type=creature
action=idle
view=side
sheet=3x3
frames=9
bundle=single_asset
anchor=feet
art_style=pixel_art
name=stage02_ice_miniboss_idle
prompt=Large HD pixel art Mega Man X inspired ice guardian miniboss, bulky crystalline armored body, glacier shoulders, heavy feet, pale blue and white palette, side-view idle loop, centered in each cell, full body in safe area, solid #FF00FF background, consistent scale, no detached effects
```

```text
asset_type=creature
action=attack
view=side
sheet=3x3
frames=9
bundle=single_asset
anchor=feet
art_style=pixel_art
name=stage02_ice_miniboss_slide
prompt=Large HD pixel art Mega Man X inspired ice guardian miniboss sliding attack body animation, same identity as idle, icy shoulder charge pose, heavy feet and crystal armor, side-view, centered in each cell, full body in safe area, solid #FF00FF background, consistent scale, body-only, no detached slash or snow effects
```

Save accepted outputs as:

```text
characters/enemies/stage_02/enemy_ice_miniboss_idle.png
characters/enemies/stage_02/enemy_ice_miniboss_slide.png
```

- [ ] **Step 4: Create enemy scenes**

Create `characters/enemies/stage_02/enemy_ice_grunt.tscn`:

```ini
[gd_scene format=3 uid="uid://enemy_ice_grunt"]

[ext_resource type="Script" path="res://characters/enemies/stage_02/enemy_ice_grunt.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_02/enemy_ice_grunt_walk.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_icegrunt"]
radius = 20.0
height = 40.0

[sub_resource type="RectangleShape2D" id="ContactShape_icegrunt"]
size = Vector2(44, 84)

[node name="EnemyIceGrunt" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, 0)
shape = SubResource("CapsuleShape2D_icegrunt")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 6
vframes = 1

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("ContactShape_icegrunt")
```

Create `characters/enemies/stage_02/enemy_ice_flyer.tscn`:

```ini
[gd_scene format=3 uid="uid://enemy_ice_flyer"]

[ext_resource type="Script" path="res://characters/enemies/stage_02/enemy_ice_flyer.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_02/enemy_ice_flyer_hover.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="CircleShape2D_iceflyer"]
radius = 24.0

[sub_resource type="CircleShape2D" id="ContactShape_iceflyer"]
radius = 28.0

[node name="EnemyIceFlyer" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_iceflyer")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 4
vframes = 1

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("ContactShape_iceflyer")
```

Create `characters/enemies/stage_02/enemy_ice_miniboss.tscn` with:

```ini
[gd_scene format=3 uid="uid://enemy_ice_miniboss"]

[ext_resource type="Script" path="res://characters/enemies/stage_02/enemy_ice_miniboss.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_02/enemy_ice_miniboss_idle.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_mb02"]
radius = 42.0
height = 120.0

[sub_resource type="RectangleShape2D" id="ContactShape_mb02"]
size = Vector2(96, 150)

[node name="EnemyIceMiniBoss" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CapsuleShape2D_mb02")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 9
vframes = 1

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("ContactShape_mb02")
```

- [ ] **Step 5: Run enemy tests and import check**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage02_enemies.tscn
```

Expected: PASS and no resource import errors.

- [ ] **Step 6: Commit sprites and scenes**

```bash
git add assets/generated/stage02_ice_grunt assets/generated/stage02_ice_flyer assets/generated/stage02_ice_miniboss characters/enemies/stage_02
git commit -m "feat: add stage 02 enemy sprites"
```

---

## Task 5: Stage 02 Structure Tests

**Files:**
- Create: `tests/test_stage_02.gd`
- Create: `tests/test_stage_02.tscn`
- Later modify: `stages/stage_02/stage_02.tscn`
- Later create: `stages/stage_02/stage_02_scene.gd`

- [ ] **Step 1: Write failing stage structure test**

Create `tests/test_stage_02.gd`:

```gdscript
extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	_test_scene_loads()
	_test_required_nodes_exist()
	_test_collectibles_are_configured()
	_print_results()
	get_tree().quit(0 if _failed == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: " + msg)
	else:
		_failed += 1
		print("  FAIL: " + msg)

func _instance_stage() -> Node:
	var scene := load("res://stages/stage_02/stage_02.tscn") as PackedScene
	_assert(scene != null, "stage_02 scene loads")
	var inst := scene.instantiate()
	add_child(inst)
	return inst

func _test_scene_loads() -> void:
	var inst := _instance_stage()
	_assert(inst != null, "stage_02 scene instantiates")
	inst.queue_free()

func _test_required_nodes_exist() -> void:
	var inst := _instance_stage()
	for node_name in [
		"PlayerSpawn", "StageController", "HUD", "PauseMenu", "GameOver", "StageComplete", "Camera2D",
		"Z1Marker", "Z2Marker", "MB02Marker", "Z3Marker", "Z4Marker", "BossEntryMarker",
		"Heart", "SubTank", "ArmorZaraHelmet", "SpreadZael"
	]:
		_assert(inst.get_node_or_null(node_name) != null, "%s exists" % node_name)
	_assert(inst.get_script() != null, "stage root has custom script")
	inst.queue_free()

func _test_collectibles_are_configured() -> void:
	var inst := _instance_stage()
	var heart := inst.get_node("Heart") as Collectible
	var subtank := inst.get_node("SubTank") as Collectible
	var helmet := inst.get_node("ArmorZaraHelmet") as Collectible
	var spread := inst.get_node("SpreadZael") as Collectible
	_assert(heart.stage_id == 2, "heart stage_id is 2")
	_assert(subtank.collectible_type == Collectible.Type.SUBTANK, "subtank type configured")
	_assert(subtank.subtank_index == 0, "subtank index is 0")
	_assert(helmet.collectible_type == Collectible.Type.ARMOR_ZARA, "Zara helmet type configured")
	_assert(helmet.armor_piece == "helmet", "Zara helmet armor_piece configured")
	_assert(spread.collectible_type == Collectible.Type.SHOT_ZAEL, "Spread type configured")
	_assert(spread.ability_id == "spread", "Spread ability_id configured")
	inst.queue_free()

func _print_results() -> void:
	print("\n=== test_stage_02: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TESTS FAILED")
```

Create `tests/test_stage_02.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://tests/test_stage_02.gd" id="1_script"]

[node name="TestStage02" type="Node"]
script = ExtResource("1_script")
```

- [ ] **Step 2: Run test and confirm failure**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_02.tscn
```

Expected: FAIL because current `stage_02.tscn` is still simple and lacks marker/corridor structure.

- [ ] **Step 3: Commit failing structure test**

```bash
git add tests/test_stage_02.gd tests/test_stage_02.tscn
git commit -m "test: specify stage 02 complex structure"
```

---

## Task 6: Stage 02 Complex Script

**Files:**
- Create: `stages/stage_02/stage_02_scene.gd`

- [ ] **Step 1: Create stage script with preload constants and state**

Create `stages/stage_02/stage_02_scene.gd` with:

```gdscript
extends Node2D

const ZAEL_SCENE := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE := preload("res://characters/melee/zara.tscn")
const _DOOR_TEX := preload("res://stages/door_pixellab.png")
const _TILESET_Z1 := preload("res://stages/stage_02/Stage_02T_z1.png")
const _TILESET_Z2 := preload("res://stages/stage_02/Stage_02T_z2.png")
const _TILESET_Z3 := preload("res://stages/stage_02/Stage_02T_z3.png")
const _TILESET_Z4 := preload("res://stages/stage_02/Stage_02T_z4.png")
const _GLASS_TEX := preload("res://stages/stage_02/stage_02_glass.png")
const _GRUNT_SCENE := preload("res://characters/enemies/stage_02/enemy_ice_grunt.tscn")
const _FLYER_SCENE := preload("res://characters/enemies/stage_02/enemy_ice_flyer.tscn")
const _MB02_SCENE := preload("res://characters/enemies/stage_02/enemy_ice_miniboss.tscn")

const _TS := 64
const _SRC_TS := 32

const Z1_GRUNTS := [Vector2(700, 856), Vector2(1280, 792), Vector2(1840, 728), Vector2(2380, 856)]
const Z1_FLYERS := [Vector2(1050, 650), Vector2(2100, 610)]
const Z2_GRUNTS := [Vector2(3180, 856), Vector2(3650, 792), Vector2(4200, 720), Vector2(4720, 856)]
const Z2_FLYERS := [Vector2(3450, 610), Vector2(4550, 560)]
const Z3_GRUNTS := [Vector2(7300, 856), Vector2(7900, 760), Vector2(8500, 650), Vector2(9100, 760), Vector2(9700, 856)]
const Z3_FLYERS := [Vector2(8100, 560), Vector2(9000, 500), Vector2(10050, 610)]
const Z4_GRUNTS := [Vector2(10800, 856), Vector2(11350, 760), Vector2(11900, 650), Vector2(12600, 760)]
const Z4_FLYERS := [Vector2(11100, 540), Vector2(12150, 500), Vector2(12900, 580)]

const _CP1_ENTRY_X := 5400.0
const _CP1_EXIT_X := 6200.0
const _MB_LEFT := 6300.0
const _MB_RIGHT := 7100.0
const _CP2_ENTRY_X := 7200.0
const _CP2_EXIT_X := 8000.0
const _CP3_ENTRY_X := 13200.0
const _CP3_EXIT_X := 14000.0

var _player: CharacterBase = null
var _camera_locked := false
var _camera_target := Vector2.ZERO
var _camera_zoom_tgt := 2.2
var _corr1: CorridorSection = null
var _corr2: CorridorSection = null
var _corr3: CorridorSection = null
var _mb02: EnemyIceMiniBoss = null
var _mb02_spawned := false
var _zone1_enemies: Array[Node] = []
var _zone2_enemies: Array[Node] = []
var _zone3_enemies: Array[Node] = []
var _zone4_enemies: Array[Node] = []
```

- [ ] **Step 2: Add lifecycle, player spawn and camera**

Append:

```gdscript
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")
	StageManager.spawn_position = $PlayerSpawn.global_position
	_spawn_player()
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)
	$Camera2D.zoom = Vector2(2.2, 2.2)
	AudioManager.play_bgm(AudioLibrary.get_stage_bgm(2))
	_setup_corridors()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _process(_delta: float) -> void:
	var cam := $Camera2D as Camera2D
	if not is_instance_valid(_player):
		return
	if _camera_locked:
		cam.global_position = cam.global_position.lerp(_camera_target, 0.12)
		cam.zoom = cam.zoom.lerp(Vector2(_camera_zoom_tgt, _camera_zoom_tgt), 0.12)
	else:
		cam.zoom = cam.zoom.lerp(Vector2(2.2, 2.2), 0.12)
		cam.global_position = cam.global_position.lerp(_player.global_position - Vector2(0, 70), 0.12)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		$PauseMenu.toggle_pause()

func _spawn_player() -> void:
	var scene := ZARA_SCENE if GameManager.active_character == "zara" else ZAEL_SCENE
	_player = scene.instantiate() as CharacterBase
	_player.add_to_group("player")
	_player.global_position = StageManager.get_respawn_position()
	if _player.global_position == Vector2.ZERO:
		_player.global_position = $PlayerSpawn.global_position
	add_child(_player)
```

- [ ] **Step 3: Add `CorridorSection` setup**

Append:

```gdscript
func _setup_corridors() -> void:
	_corr1 = _make_corridor("CP1", _CP1_ENTRY_X, _CP1_EXIT_X, 1, false, false)
	_corr2 = _make_corridor("CP2", _CP2_ENTRY_X, _CP2_EXIT_X, 2, false, true)
	_corr2.entry_manual = true
	_corr3 = _make_corridor("CP3", _CP3_ENTRY_X, _CP3_EXIT_X, 3, false, true)

func _make_corridor(name_prefix: String, entry_x: float, exit_x: float, checkpoint_index: int, manual: bool, heal: bool) -> CorridorSection:
	var width := exit_x - entry_x
	var corr := CorridorSection.new()
	corr.name = name_prefix
	corr.tileset = _TILESET_Z2 if checkpoint_index == 1 else (_TILESET_Z3 if checkpoint_index == 2 else _TILESET_Z4)
	corr.glass_tex = _GLASS_TEX
	corr.door_tex = _DOOR_TEX
	corr.floor_center = Vector2(entry_x + width * 0.5, 920.0)
	corr.floor_size = Vector2(width, 64.0)
	corr.ceil_center = Vector2(entry_x + width * 0.5, 728.0)
	corr.ceil_size = Vector2(width, 64.0)
	corr.wall_l_center = Vector2(entry_x, 824.0)
	corr.wall_l_size = Vector2(64.0, 256.0)
	corr.wall_r_center = Vector2(exit_x, 824.0)
	corr.wall_r_size = Vector2(64.0, 256.0)
	corr.entry_x = entry_x
	corr.exit_x = exit_x
	corr.entry_manual = manual
	corr.save_checkpoint = true
	corr.heal_on_entry = heal
	corr.checkpoint_index = checkpoint_index
	corr.checkpoint_respawn_x = exit_x + 128.0
	corr.cam_center = Vector2(entry_x + width * 0.5, 824.0)
	corr.cam_zoom = 2.0
	corr.glass_lateral_x = entry_x - 64.0
	corr.glass_fill_x = entry_x
	corr.glass_fill_cols = int(width / 64.0)
	corr.camera_lock_requested.connect(_on_corridor_cam_lock)
	corr.player_traversed.connect(_on_corridor_traversed)
	add_child(corr)
	corr.setup(_player)
	return corr

func _on_corridor_cam_lock(center: Vector2, zoom: float) -> void:
	_camera_locked = true
	_camera_target = center
	_camera_zoom_tgt = zoom

func _on_corridor_traversed() -> void:
	_camera_locked = false
```

- [ ] **Step 4: Add zone triggers and enemies**

Append:

```gdscript
func _setup_zone_triggers() -> void:
	_make_zone_trigger("Z2Trigger", Rect2(2800, 400, 2400, 800), 2)
	_make_zone_trigger("MB02Trigger", Rect2(_CP1_EXIT_X, 400, 900, 800), 5)
	_make_zone_trigger("Z3Trigger", Rect2(_CP2_EXIT_X, 300, 2600, 900), 3)
	_make_zone_trigger("Z4Trigger", Rect2(10400, 300, 2600, 900), 4)

func _make_zone_trigger(node_name: String, rect: Rect2, zone: int) -> void:
	var area := Area2D.new()
	area.name = node_name
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	area.add_child(cs)
	area.position = rect.position + rect.size * 0.5
	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			if zone == 5:
				_spawn_mb02()
			else:
				_spawn_zone_enemies(zone)
	)
	add_child(area)

func _spawn_zone_enemies(zone: int) -> void:
	var target: Array[Node]
	var grunts: Array
	var flyers: Array
	match zone:
		1:
			target = _zone1_enemies
			grunts = Z1_GRUNTS
			flyers = Z1_FLYERS
		2:
			target = _zone2_enemies
			grunts = Z2_GRUNTS
			flyers = Z2_FLYERS
		3:
			target = _zone3_enemies
			grunts = Z3_GRUNTS
			flyers = Z3_FLYERS
		4:
			target = _zone4_enemies
			grunts = Z4_GRUNTS
			flyers = Z4_FLYERS
		_:
			return
	if not target.is_empty():
		return
	for pos in grunts:
		var enemy := _GRUNT_SCENE.instantiate()
		enemy.global_position = pos
		add_child(enemy)
		target.append(enemy)
	for pos in flyers:
		var enemy := _FLYER_SCENE.instantiate()
		enemy.global_position = pos
		add_child(enemy)
		target.append(enemy)

func _spawn_mb02() -> void:
	if _mb02_spawned:
		return
	_mb02_spawned = true
	_camera_locked = true
	_camera_target = Vector2((_MB_LEFT + _MB_RIGHT) * 0.5, 760)
	_camera_zoom_tgt = 2.0
	_mb02 = _MB02_SCENE.instantiate() as EnemyIceMiniBoss
	_mb02.global_position = Vector2((_MB_LEFT + _MB_RIGHT) * 0.5, 820)
	_mb02.arena_left = _MB_LEFT + 64.0
	_mb02.arena_right = _MB_RIGHT - 64.0
	add_child(_mb02)
	_mb02.died.connect(_on_mb02_defeated)

func _on_mb02_defeated() -> void:
	_camera_locked = false
	if _corr2 != null:
		_corr2.open_entry()
```

- [ ] **Step 5: Add terrain drawing helpers**

Append:

```gdscript
func _draw() -> void:
	for child in get_children():
		if child is StaticBody2D:
			_draw_static_terrain(child as StaticBody2D)

func _draw_static_terrain(body: StaticBody2D) -> void:
	var tex := _texture_for_node(body)
	for shape_child in body.get_children():
		if not shape_child is CollisionShape2D:
			continue
		var cs := shape_child as CollisionShape2D
		if not cs.shape is RectangleShape2D:
			continue
		var size := (cs.shape as RectangleShape2D).size
		var center := body.position + cs.position
		var rect := Rect2(center - size * 0.5, size)
		_draw_terrain_block(rect, tex)

func _texture_for_node(node: Node) -> Texture2D:
	if node.name.begins_with("Z1"):
		return _TILESET_Z1
	if node.name.begins_with("Z2"):
		return _TILESET_Z2
	if node.name.begins_with("Z3"):
		return _TILESET_Z3
	if node.name.begins_with("Z4"):
		return _TILESET_Z4
	return _TILESET_Z1

func _draw_terrain_block(rect: Rect2, tex: Texture2D) -> void:
	var cols := ceili(rect.size.x / _TS)
	var rows := ceili(rect.size.y / _TS)
	for row in rows:
		for col in cols:
			var tile := _tile_at(col, cols, row, rows)
			var dx := rect.position.x + col * _TS
			var dy := rect.position.y + row * _TS - _SRC_TS
			var dw := minf(_TS, rect.position.x + rect.size.x - dx)
			var dh := minf(_TS, rect.position.y + rect.size.y - dy)
			draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh), Rect2(tile.x * _SRC_TS, tile.y * _SRC_TS, _SRC_TS * dw / _TS, _SRC_TS * dh / _TS))

func _tile_at(col: int, cols: int, row: int, rows: int) -> Vector2i:
	var is_left := col == cols - 1
	var is_right := col == 0
	var is_top := row == rows - 1
	var is_bottom := row == 0
	if is_top:
		if is_left:
			return Vector2i(3, 3)
		if is_right:
			return Vector2i(0, 2)
		return Vector2i(1, 2)
	if is_bottom:
		if is_left:
			return Vector2i(0, 0)
		if is_right:
			return Vector2i(1, 3)
		return Vector2i(3, 0)
	if is_left:
		return Vector2i(3, 2)
	if is_right:
		return Vector2i(1, 0)
	return Vector2i(2, 1)
```

- [ ] **Step 6: Commit stage script**

```bash
git add stages/stage_02/stage_02_scene.gd
git commit -m "feat: add stage 02 complex controller"
```

---

## Task 7: Rebuild `stage_02.tscn`

**Files:**
- Modify: `stages/stage_02/stage_02.tscn`

- [ ] **Step 1: Replace root and resources**

Rewrite the scene header/resources:

```ini
[gd_scene format=3 uid="uid://stage_02"]

[ext_resource type="Script" path="res://stages/stage_02/stage_02_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="3_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="4_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="5_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="6_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="7_complete"]
[ext_resource type="Script" path="res://stages/stage_02/ice_floor.gd" id="8_icefloor"]
[ext_resource type="Script" path="res://stages/stage_02/ice_spikes.gd" id="9_spikes"]
[ext_resource type="Script" path="res://stages/stage_02/blizzard_zone.gd" id="10_blizzard"]
[ext_resource type="Script" path="res://stages/stage_02/ice_gate.gd" id="11_gate"]
```

- [ ] **Step 2: Add reusable rectangle shapes**

Add enough rectangle resources for terrain blocks and hazards:

```ini
[sub_resource type="RectangleShape2D" id="BlockWide"]
size = Vector2(900, 360)

[sub_resource type="RectangleShape2D" id="BlockMedium"]
size = Vector2(520, 300)

[sub_resource type="RectangleShape2D" id="BlockTall"]
size = Vector2(220, 520)

[sub_resource type="RectangleShape2D" id="HazardWide"]
size = Vector2(700, 120)

[sub_resource type="RectangleShape2D" id="GateShape"]
size = Vector2(96, 260)
```

- [ ] **Step 3: Add root and required service nodes**

Add:

```ini
[node name="Stage02" type="Node2D"]
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(180, 820)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="HUD" parent="." instance=ExtResource("4_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("5_pause")]
[node name="GameOver" parent="." instance=ExtResource("6_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("7_complete")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_top = -400
limit_bottom = 1400
limit_right = 14500
position_smoothing_enabled = true
position_smoothing_speed = 8.0

[node name="Z1Marker" type="Node2D" parent="."]
position = Vector2(800, 820)
[node name="Z2Marker" type="Node2D" parent="."]
position = Vector2(3500, 820)
[node name="MB02Marker" type="Node2D" parent="."]
position = Vector2(6700, 820)
[node name="Z3Marker" type="Node2D" parent="."]
position = Vector2(8700, 760)
[node name="Z4Marker" type="Node2D" parent="."]
position = Vector2(11600, 760)
[node name="BossEntryMarker" type="Node2D" parent="."]
position = Vector2(14150, 820)
```

- [ ] **Step 4: Add terrain blocks**

Add terrain as tall blocks. Use names beginning with `Z1`, `Z2`, `Z3`, `Z4` so `stage_02_scene.gd` selects the right tileset:

```ini
[node name="Z1_BlockA" type="StaticBody2D" parent="."]
position = Vector2(450, 980)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z1_BlockA"]
shape = SubResource("BlockWide")

[node name="Z1_BlockB" type="StaticBody2D" parent="."]
position = Vector2(1300, 1044)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z1_BlockB"]
shape = SubResource("BlockMedium")

[node name="Z1_BlockC" type="StaticBody2D" parent="."]
position = Vector2(2200, 980)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z1_BlockC"]
shape = SubResource("BlockWide")

[node name="Z2_BlockA" type="StaticBody2D" parent="."]
position = Vector2(3200, 980)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z2_BlockA"]
shape = SubResource("BlockWide")

[node name="Z2_BlockB" type="StaticBody2D" parent="."]
position = Vector2(4200, 1044)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z2_BlockB"]
shape = SubResource("BlockMedium")

[node name="Z2_BlockC" type="StaticBody2D" parent="."]
position = Vector2(5000, 980)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z2_BlockC"]
shape = SubResource("BlockWide")

[node name="MB02_Floor" type="StaticBody2D" parent="."]
position = Vector2(6700, 980)
[node name="CollisionShape2D" type="CollisionShape2D" parent="MB02_Floor"]
shape = SubResource("BlockWide")

[node name="Z3_BlockA" type="StaticBody2D" parent="."]
position = Vector2(8300, 1044)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z3_BlockA"]
shape = SubResource("BlockMedium")

[node name="Z3_BlockB" type="StaticBody2D" parent="."]
position = Vector2(9200, 940)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z3_BlockB"]
shape = SubResource("BlockTall")

[node name="Z3_BlockC" type="StaticBody2D" parent="."]
position = Vector2(10000, 980)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z3_BlockC"]
shape = SubResource("BlockWide")

[node name="Z4_BlockA" type="StaticBody2D" parent="."]
position = Vector2(11000, 980)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z4_BlockA"]
shape = SubResource("BlockWide")

[node name="Z4_BlockB" type="StaticBody2D" parent="."]
position = Vector2(12000, 940)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z4_BlockB"]
shape = SubResource("BlockTall")

[node name="Z4_BlockC" type="StaticBody2D" parent="."]
position = Vector2(12800, 980)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z4_BlockC"]
shape = SubResource("BlockWide")
```

This first pass is playable and uses block mass. Additional terrain shaping should preserve the same block-mass rule.

- [ ] **Step 5: Add hazards and gates**

Add ice floor zones:

```ini
[node name="Z1_IceFloor" type="Area2D" parent="."]
position = Vector2(1400, 780)
script = ExtResource("8_icefloor")
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z1_IceFloor"]
shape = SubResource("HazardWide")

[node name="Z2_Spikes" type="Area2D" parent="."]
position = Vector2(4100, 760)
script = ExtResource("9_spikes")
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z2_Spikes"]
shape = SubResource("HazardWide")

[node name="Z3_Blizzard" type="Area2D" parent="."]
position = Vector2(9000, 620)
script = ExtResource("10_blizzard")
force = Vector2(180, 0)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z3_Blizzard"]
shape = SubResource("HazardWide")

[node name="Z2_IgnarathGate" type="StaticBody2D" parent="."]
position = Vector2(3900, 720)
script = ExtResource("11_gate")
required_ability = "ignarath"
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z2_IgnarathGate"]
shape = SubResource("GateShape")
[node name="HitDetector" type="Area2D" parent="Z2_IgnarathGate"]
collision_layer = 0
collision_mask = 8
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z2_IgnarathGate/HitDetector"]
shape = SubResource("GateShape")

[node name="Z4_LuxarGate" type="StaticBody2D" parent="."]
position = Vector2(12100, 720)
script = ExtResource("11_gate")
required_ability = "luxar"
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z4_LuxarGate"]
shape = SubResource("GateShape")
[node name="HitDetector" type="Area2D" parent="Z4_LuxarGate"]
collision_layer = 0
collision_mask = 8
[node name="CollisionShape2D" type="CollisionShape2D" parent="Z4_LuxarGate/HitDetector"]
shape = SubResource("GateShape")
```

- [ ] **Step 6: Add collectibles**

Add:

```ini
[node name="SubTank" parent="." instance=ExtResource("3_col")]
position = Vector2(980, 720)
collectible_type = 1
subtank_index = 0

[node name="ArmorZaraHelmet" parent="." instance=ExtResource("3_col")]
position = Vector2(4100, 650)
collectible_type = 3
armor_piece = "helmet"

[node name="Heart" parent="." instance=ExtResource("3_col")]
position = Vector2(9650, 560)
stage_id = 2

[node name="SpreadZael" parent="." instance=ExtResource("3_col")]
position = Vector2(12350, 620)
collectible_type = 4
ability_id = "spread"
```

- [ ] **Step 7: Run stage structure test**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_02.tscn
```

Expected: `=== test_stage_02:` line with 0 failed.

- [ ] **Step 8: Commit scene rebuild**

```bash
git add stages/stage_02/stage_02.tscn tests/test_stage_02.gd tests/test_stage_02.tscn
git commit -m "feat: rebuild stage 02 complex scene"
```

---

## Task 8: Verification and Integration Pass

**Files:**
- Verify: `stages/stage_02/stage_02_scene.gd`
- Verify: `stages/stage_02/stage_02.tscn`
- Verify: stage 02 hazard/enemy scripts

- [ ] **Step 1: Run focused tests**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage02_hazards.tscn
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage02_enemies.tscn
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_02.tscn
```

Expected: all exit code 0.

- [ ] **Step 2: Run core regression tests**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```

Expected: each prints `ALL TESTS PASSED` or exits 0 with no failures.

- [ ] **Step 3: Manual editor/play check**

Run the project, load Stage 02 from stage select or debug path, and verify:

- Player starts in Z1.
- Z1 and Z2 route reaches CP1.
- CP1 corridor camera locks and unlocks.
- MB02 spawns after CP1.
- Defeating MB02 opens CP2.
- Z3/Z4 route reaches CP3.
- CP3 heals/checkpoints and leads to future boss entry marker.
- Cryovex was not changed and is not required for this stage pass.
- Terrain appears as solid mass down from the top tiles, not thin floating platforms.

- [ ] **Step 4: Commit final fixes**

If verification required small fixes:

```bash
git add stages/stage_02 characters/enemies/stage_02 tests/test_stage02_hazards.gd tests/test_stage02_enemies.gd tests/test_stage_02.gd characters/base/character_base.gd
git commit -m "fix: polish stage 02 integration"
```

If no fixes were needed, do not create an empty commit.

---

## Self-Review

Spec coverage:

- Four zones: Task 6 and Task 7.
- Three `CorridorSection` checkpoints: Task 6.
- No Cryovex implementation: stated in File Structure, Task 6/7 avoid boss scene, Task 8 verifies.
- Existing tiles: Task 6 preloads `Stage_02T_z1-z4` and `stage_02_glass.png`.
- Terrain body down from top tiles: Task 6/7 use tall block terrain and tile drawing.
- Hazards: Task 1/2.
- Abundant enemies and MB02: Task 3/4/6.
- `generate2dsprite`: Task 4.
- Collectible gates: Task 2/7.
- Tests: Tasks 1, 3, 5, 8.

Placeholder scan:

- No `TBD`, `TODO`, or unresolved placeholder markers are used.
- Scene steps include concrete names, paths, node types, and properties.

Type consistency:

- Hazard tests call methods defined in Task 2.
- Enemy tests call properties inherited from `EnemyBase`/`EnemyFlyer` and defined in Task 3.
- Stage tests check node names created in Task 7.
