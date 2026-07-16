# Stage 05 Galerix Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework Stage 05 (Galerix, tema vento) do esqueleto atual (196 linhas, plataformas soltas) pra uma fase completa com 4 zonas temáticas, roster de 9 inimigos com IA funcional, 3 mecânicas de vento e sala do boss — mesmo nível de profundidade dos reworks já completos de stage_01/02/03/04.

**Architecture:** `stages/stage_05/stage_05_scene.gd extends "res://stages/stage_scene.gd"` (mesmo padrão de stage_04), construindo zonas em código via helpers de terreno copiados do vocabulário já validado (`_floor_seg`/`_solid_block`/`_glass_wall`/`_fp`/`_fixed_plat`). Vento aplicado via `CharacterBase.apply_stage_wind(force_delta)` (já existe), reaproveitando `stages/stage_02/blizzard_zone.gd` (corrente horizontal) e `stages/stage_04/lift_zone.gd` (updraft vertical) sem modificação. Componente novo `sliding_platform.gd` (`AnimatableBody2D`, técnica de acumulador) para as plataformas deslizantes de Z3. 9 scripts de inimigo em `characters/enemies/stage_05/`, cada um estendendo `EnemyBase` ou `res://characters/enemies/enemy_flyer.gd` seguindo o template mais próximo já em produção (stages 02/04).

**Tech Stack:** Godot 4.6.2 GDScript, headless parse-check, PixelLab já usado pros sprites (não precisa de asset novo neste plano — os 9 sprites + 4 projéteis já existem em `characters/enemies/stage_05/*.png`).

## Global Constraints

- Nomes de arquivo/script em snake_case; `class_name` em PascalCase — mesma convenção de stages 01-04.
- Toda coordenada de piso/parede/sala deve respeitar múltiplos de 64px na sala do boss e nos corredores (skill `new-boss-room`).
- `CorridorSection` sempre 896×64 / zoom 2.0 (memória `feedback_corridor_same_as_stage00`) — nunca variar a largura do corredor.
- Nenhuma cura em checkpoints/corredores (`heal_on_entry = false`, memória `feedback_no_heal_checkpoints`).
- Teto por zona usa `_CEIL_FACE_GAP` (colisão 32px acima do nominal, visual intocado) e fallback cross-zone em `_ceil05_surface_at` desde a primeira versão — não introduzir de novo o bug já corrigido em stage_01/02/03/04 este ciclo (memórias `reference_ceiling_collision_gap` e `reference_ceiling_zone_boundary`).
- `sign()`/`clamp()`/`abs()` sempre tipados explicitamente com `: float` no build web (memória `feedback_web_export_types`).
- Após cada task: parse-check headless (`--headless --path . res://<cena>.tscn`) antes de seguir pra próxima.
- `sliding_platform.gd` e qualquer zona nova devem ficar PARADAS/neutras quando `DebugBoot.bot_enabled` (mesmo padrão de `lift_zone.gd`/`crusher.gd`).

---

### Task 1: Projétil compartilhado do roster de vento

**Files:**
- Create: `characters/enemies/stage_05/wind_projectile.gd`
- Create: `characters/enemies/stage_05/wind_projectile.tscn`

**Interfaces:**
- Produces: `WindProjectile.setup(velocity_value: Vector2, damage_value: int, source_value := "stage05_wind", gravity_value := 0.0, variant_value := "gale_bolt") -> void` — usado pelas Tasks 3-5 pra disparar projéteis.

- [ ] **Step 1: Criar o script do projétil**

`characters/enemies/stage_05/wind_projectile.gd`:
```gdscript
extends Area2D
class_name WindProjectile

# Projétil de vento compartilhado do roster do stage 05 (molde do grav_projectile).
const TEX := {
	"gale_bolt": preload("res://characters/enemies/stage_05/gale_bolt.png"),
	"wind_slash": preload("res://characters/enemies/stage_05/wind_slash.png"),
	"feather_dart": preload("res://characters/enemies/stage_05/feather_dart.png"),
}

var projectile_velocity: Vector2 = Vector2(300.0, 0.0)
var damage: int = 6
var source_id: String = "stage05_wind"
var variant: String = "gale_bolt"
var _lifetime: float = 4.0
var _hit := false
var _anim_timer := 0.0
var _frame := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_enemy_shoot)

func setup(velocity_value: Vector2, damage_value: int, source_value := "stage05_wind",
		gravity_value := 0.0, variant_value := "gale_bolt") -> void:
	projectile_velocity = velocity_value
	damage = damage_value
	source_id = source_value
	gravity = gravity_value
	variant = variant_value
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null and TEX.has(variant):
		spr.texture = TEX[variant]
		spr.hframes = 2
		spr.vframes = 2
		spr.frame = 0

func _physics_process(delta: float) -> void:
	if _hit:
		return
	projectile_velocity.y += gravity * delta
	global_position += projectile_velocity * delta
	rotation = projectile_velocity.angle()
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		_anim_timer += delta
		if _anim_timer >= 1.0 / 12.0:
			_anim_timer -= 1.0 / 12.0
			_frame = (_frame + 1) % 4
			spr.frame = _frame
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	queue_free()
```

- [ ] **Step 2: Criar a cena do projétil**

`characters/enemies/stage_05/wind_projectile.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_05/wind_projectile.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_05/gale_bolt.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="Circ_1"]
radius = 10.0

[node name="WindProjectile" type="Area2D"]
collision_layer = 0
collision_mask = 2
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Circ_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 2
vframes = 2
frame = 0
```

- [ ] **Step 3: Parse-check headless**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/enemies/stage_05/wind_projectile.gd`
Expected: sem `SCRIPT ERROR`/`Parse Error` na saída.

- [ ] **Step 4: Commit**

```bash
git add characters/enemies/stage_05/wind_projectile.gd characters/enemies/stage_05/wind_projectile.tscn
git commit -m "feat(stage05): projétil de vento compartilhado do roster"
```

---

### Task 2: Componente `sliding_platform.gd`

**Files:**
- Create: `stages/stage_05/sliding_platform.gd`

**Interfaces:**
- Produces: `SlidingPlatform` (`AnimatableBody2D`), `@export var slide_distance: float`, `@export var slide_speed: float`, `@export var settle_time: float` — instanciado pela Task 8 (Zona 3).

- [ ] **Step 1: Criar o componente**

`stages/stage_05/sliding_platform.gd`:
```gdscript
# Plataforma que desliza horizontalmente enquanto o player está em cima —
# solta e volta devagar pro início quando ninguém pisa nela por settle_time.
# AnimatableBody2D + sync_to_physics: mesma técnica de acumulador de
# stages/stage_01/moving_platform.gd (nunca ler position de volta).
extends AnimatableBody2D

@export var slide_distance: float = 220.0   # px que a plataforma desliza a partir do repouso
@export var slide_speed: float = 140.0      # px/s enquanto alguém está em cima
@export var return_speed: float = 60.0      # px/s ao voltar sozinha pro início
@export var settle_time: float = 0.6        # tempo sem ninguém em cima até começar a voltar
@export var slide_dir: float = 1.0          # +1 desliza pra direita, -1 pra esquerda

var _offset: float = 0.0     # deslocamento acumulado a partir do repouso (nunca lê position)
var _occupied: bool = false
var _settle_timer: float = 0.0
var _rider_count: int = 0

func _ready() -> void:
	sync_to_physics = true
	var top := Area2D.new()
	top.name = "RiderDetect"
	top.collision_layer = 0
	top.collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(96.0, 12.0)
	cs.shape = sh
	cs.position = Vector2(0.0, -22.0)   # logo acima do topo da plataforma (96×32)
	top.add_child(cs)
	add_child(top)
	top.body_entered.connect(func(_b: Node) -> void:
		_rider_count += 1
		_occupied = true)
	top.body_exited.connect(func(_b: Node) -> void:
		_rider_count = maxi(0, _rider_count - 1)
		_occupied = _rider_count > 0)

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return   # bot: plataforma parada, valida o layout sem depender do timing
	if _occupied:
		_settle_timer = 0.0
		var step: float = minf(slide_speed * delta, slide_distance - _offset)
		_offset += step
		position.x += slide_dir * step
	else:
		_settle_timer += delta
		if _settle_timer >= settle_time and _offset > 0.0:
			var step: float = minf(return_speed * delta, _offset)
			_offset -= step
			position.x -= slide_dir * step
```

- [ ] **Step 2: Parse-check headless**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script stages/stage_05/sliding_platform.gd`
Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_05/sliding_platform.gd
git commit -m "feat(stage05): componente de plataforma deslizante"
```

---

### Task 3: Inimigos terrestres (gale_runner, claw_glider, airfoil_lancer)

**Files:**
- Create: `characters/enemies/stage_05/enemy_gale_runner.gd` + `.tscn`
- Create: `characters/enemies/stage_05/enemy_claw_glider.gd` + `.tscn`
- Create: `characters/enemies/stage_05/enemy_airfoil_lancer.gd` + `.tscn`

**Interfaces:**
- Consumes: `WindProjectile.setup(...)` (Task 1).
- Produces: 3 `PackedScene` prontas pra `preload()` na Task 6 (`enemy_gale_runner.tscn`, `enemy_claw_glider.tscn`, `enemy_airfoil_lancer.tscn`).

- [ ] **Step 1: `enemy_gale_runner` — grunt com arrancada (molde `enemy_mass_brute`)**

`characters/enemies/stage_05/enemy_gale_runner.gd`:
```gdscript
extends EnemyBase
class_name EnemyGaleRunner

# Corredor leve: patrulha normal; ao ver o player no mesmo nível, dispara uma
# arrancada rápida (turbinas de tornozelo) até bater em parede ou esgotar o tempo.
const FRAMES := 6
const FPS := 10.0
const DETECT_X := 300.0
const DETECT_Y := 60.0
const DASH_SPEED := 220.0
const DASH_TIME := 0.7
const DASH_COOLDOWN := 1.4

var _dash_timer := 0.0
var _cooldown := 0.5

func _init() -> void:
	max_hp = 9
	contact_damage = 6

func _ready() -> void:
	max_hp = 9
	contact_damage = 6
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _dash_timer > 0.0:
		_dash_timer -= delta
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = DASH_SPEED * _direction
		move_and_slide()
		if is_on_wall():
			_dash_timer = 0.0
		if _dash_timer <= 0.0:
			_cooldown = DASH_COOLDOWN
		_advance_sprite_frame_loop(delta, FRAMES, FPS * 1.5)
		_sprite.flip_h = (_direction < 0)
		return
	super._physics_process(delta)
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null:
		var off: Vector2 = p.global_position - global_position
		if absf(off.x) <= DETECT_X and absf(off.y) <= DETECT_Y:
			_direction = signf(off.x)
			_dash_timer = DASH_TIME
```

`characters/enemies/stage_05/enemy_gale_runner.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_05/enemy_gale_runner.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_05/enemy_gale_runner.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 18.0
height = 72.0

[node name="EnemyGaleRunner" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 2
frame = 0
scale = Vector2(0.75, 0.75)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 2: `enemy_claw_glider` — melee agachado com investida curta (molde `enemy_mass_brute`, alcance menor)**

`characters/enemies/stage_05/enemy_claw_glider.gd`:
```gdscript
extends EnemyBase
class_name EnemyClawGlider

# Melee agachado: investida de garra curta e rápida quando o player está perto.
const FRAMES := 6
const FPS := 9.0
const DETECT_X := 160.0
const DETECT_Y := 50.0
const LUNGE_SPEED := 280.0
const LUNGE_TIME := 0.35
const LUNGE_COOLDOWN := 1.2

var _lunge_timer := 0.0
var _cooldown := 0.4

func _init() -> void:
	max_hp = 10
	contact_damage = 9

func _ready() -> void:
	max_hp = 10
	contact_damage = 9
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _lunge_timer > 0.0:
		_lunge_timer -= delta
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = LUNGE_SPEED * _direction
		move_and_slide()
		if is_on_wall():
			_lunge_timer = 0.0
		if _lunge_timer <= 0.0:
			_cooldown = LUNGE_COOLDOWN
		_advance_sprite_frame_loop(delta, FRAMES, FPS * 1.8)
		_sprite.flip_h = (_direction < 0)
		return
	super._physics_process(delta)
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null:
		var off: Vector2 = p.global_position - global_position
		if absf(off.x) <= DETECT_X and absf(off.y) <= DETECT_Y:
			_direction = signf(off.x)
			_lunge_timer = LUNGE_TIME
```

`characters/enemies/stage_05/enemy_claw_glider.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_05/enemy_claw_glider.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_05/enemy_claw_glider.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 20.0
height = 64.0

[node name="EnemyClawGlider" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 2
frame = 0
scale = Vector2(0.75, 0.75)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: `enemy_airfoil_lancer` — atirador de lança curta (molde `enemy_ice_archer`)**

`characters/enemies/stage_05/enemy_airfoil_lancer.gd`:
```gdscript
extends EnemyBase
class_name EnemyAirfoilLancer

const _PROJECTILE_SCENE := preload("res://characters/enemies/stage_05/wind_projectile.tscn")

@export var shoot_range: float = 380.0
@export var shoot_interval: float = 1.3
@export var projectile_speed: float = 420.0
@export var projectile_damage: int = 8
@export var aim_y_tolerance: float = 130.0
@export var shot_frame_count: int = 9
@export var shot_fps: float = 12.0
@export var shot_release_frame: int = 5

var _shoot_timer := 0.3
var _shot_active := false
var _shot_frame := 0
var _shot_frame_timer := 0.0
var _shot_released := false

func _init() -> void:
	max_hp = 11
	contact_damage = 6

func _ready() -> void:
	max_hp = 11
	contact_damage = 6
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	_shoot_timer -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not _shot_active and player != null:
		var offset: Vector2 = player.global_position - global_position
		if absf(offset.x) <= shoot_range and absf(offset.y) <= aim_y_tolerance:
			_direction = signf(offset.x) if offset.x != 0.0 else _direction
			velocity.x = 0.0
			if _shoot_timer <= 0.0:
				_start_shot()
	_tick_shot(delta)
	move_and_slide()
	_update_sprite()

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
	var frame_duration: float = 1.0 / shot_fps
	while _shot_frame_timer >= frame_duration:
		_shot_frame_timer -= frame_duration
		_shot_frame += 1
		if _shot_frame == shot_release_frame and not _shot_released:
			_set_sprite_frame(_shot_frame)
			_fire(Vector2(_direction * projectile_speed, 0.0))
			_shot_released = true
		if _shot_frame >= shot_frame_count:
			_shot_active = false
			_shoot_timer = shoot_interval
			_shot_frame = 0
		_set_sprite_frame(_shot_frame % shot_frame_count)

func _fire(shot_velocity: Vector2) -> void:
	var projectile := _PROJECTILE_SCENE.instantiate() as WindProjectile
	projectile.setup(shot_velocity, projectile_damage, "airfoil_lancer", 0.0, "wind_slash")
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(_direction * 34.0, -16.0)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false

func _update_sprite() -> void:
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if _invincible and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
```

`characters/enemies/stage_05/enemy_airfoil_lancer.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_05/enemy_airfoil_lancer.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_05/enemy_airfoil_lancer.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 18.0
height = 68.0

[node name="EnemyAirfoilLancer" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 3
frame = 0
scale = Vector2(0.75, 0.75)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 4: Parse-check headless dos 3 scripts**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/enemies/stage_05/enemy_gale_runner.gd
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/enemies/stage_05/enemy_claw_glider.gd
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/enemies/stage_05/enemy_airfoil_lancer.gd
```
Expected: sem `SCRIPT ERROR`/`Parse Error` em nenhuma das 3.

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_05/enemy_gale_runner.* characters/enemies/stage_05/enemy_claw_glider.* characters/enemies/stage_05/enemy_airfoil_lancer.*
git commit -m "feat(stage05): inimigos terrestres (gale_runner, claw_glider, airfoil_lancer)"
```

---

### Task 4: Inimigos voadores (sky_harrier, turbine_wisp, feather_swarm, gale_grappler)

**Files:**
- Create: `characters/enemies/stage_05/enemy_sky_harrier.gd` + `.tscn`
- Create: `characters/enemies/stage_05/enemy_turbine_wisp.gd` + `.tscn`
- Create: `characters/enemies/stage_05/enemy_feather_swarm.gd` + `.tscn`
- Create: `characters/enemies/stage_05/enemy_gale_grappler.gd` + `.tscn`

**Interfaces:**
- Consumes: `WindProjectile.setup(...)` (Task 1), `res://characters/enemies/enemy_flyer.gd` (base já existente).
- Produces: 4 `PackedScene` prontas pra Task 7 (`enemy_sky_harrier.tscn`, `enemy_turbine_wisp.tscn`, `enemy_feather_swarm.tscn`, `enemy_gale_grappler.tscn`).

- [ ] **Step 1: `enemy_sky_harrier` — mergulhador padrão (molde `enemy_void_drone`)**

`characters/enemies/stage_05/enemy_sky_harrier.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemySkyHarrier

# Raptor patrulheiro: mergulhador padrão, dive rápido quando detecta o player.
func _ready() -> void:
	super._ready()
	max_hp = 8
	contact_damage = 9
	current_hp = max_hp
	detect_radius = 260.0
	dive_speed = 380.0
	retreat_speed = 190.0
	patrol_range = 200.0
	bob_amplitude = 10.0
```

`characters/enemies/stage_05/enemy_sky_harrier.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_05/enemy_sky_harrier.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_05/enemy_sky_harrier.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(70.0, 60.0)

[node name="EnemySkyHarrier" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 3
frame = 0
scale = Vector2(0.7, 0.7)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 2: `enemy_turbine_wisp` — hover-atirador (molde `enemy_debris_orbiter`)**

`characters/enemies/stage_05/enemy_turbine_wisp.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyTurbineWisp

# Núcleo de vento flutuante: hover puro (sem mergulho) + tiro de gale_bolt.
const _PROJ := preload("res://characters/enemies/stage_05/wind_projectile.tscn")
const SHOOT_INTERVAL := 1.7
const SHOOT_RANGE := 420.0
const BOLT_SPEED := 300.0
const BOLT_DAMAGE := 6

var _shoot_timer := 0.7

func _ready() -> void:
	super._ready()
	max_hp = 7
	contact_damage = 5
	current_hp = max_hp
	dive_speed = 0.0
	detect_radius = 0.0
	patrol_range = 110.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p != null and global_position.distance_to(p.global_position) <= SHOOT_RANGE:
			_shoot_timer = SHOOT_INTERVAL
			_fire_bolt(p)

func _fire_bolt(target: Node2D) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var proj := _PROJ.instantiate() as WindProjectile
	proj.setup(dir * BOLT_SPEED, BOLT_DAMAGE, "turbine_wisp", 0.0, "gale_bolt")
	get_parent().add_child(proj)
	proj.global_position = global_position
```

`characters/enemies/stage_05/enemy_turbine_wisp.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_05/enemy_turbine_wisp.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_05/enemy_turbine_wisp.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="Cap_1"]
radius = 26.0

[node name="EnemyTurbineWisp" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 2
frame = 0
scale = Vector2(0.7, 0.7)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: `enemy_feather_swarm` — enxame orbital atirador (molde `enemy_debris_orbiter`)**

`characters/enemies/stage_05/enemy_feather_swarm.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyFeatherSwarm

# Enxame de penas metálicas: hover puro + arremesso de feather_dart.
const _PROJ := preload("res://characters/enemies/stage_05/wind_projectile.tscn")
const SHOOT_INTERVAL := 1.5
const SHOOT_RANGE := 380.0
const DART_SPEED := 280.0
const DART_DAMAGE := 5

var _shoot_timer := 0.5

func _ready() -> void:
	super._ready()
	max_hp = 6
	contact_damage = 6
	current_hp = max_hp
	dive_speed = 0.0
	detect_radius = 0.0
	patrol_range = 90.0
	bob_amplitude = 12.0
	bob_speed = 3.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p != null and global_position.distance_to(p.global_position) <= SHOOT_RANGE:
			_shoot_timer = SHOOT_INTERVAL
			_fire_dart(p)

func _fire_dart(target: Node2D) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var proj := _PROJ.instantiate() as WindProjectile
	proj.setup(dir * DART_SPEED, DART_DAMAGE, "feather_swarm", 0.0, "feather_dart")
	get_parent().add_child(proj)
	proj.global_position = global_position
```

`characters/enemies/stage_05/enemy_feather_swarm.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_05/enemy_feather_swarm.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_05/enemy_feather_swarm.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="Cap_1"]
radius = 24.0

[node name="EnemyFeatherSwarm" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 3
frame = 0
scale = Vector2(0.7, 0.7)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 4: `enemy_gale_grappler` — drone pesado que persegue devagar (molde `enemy_gravity_mine`)**

`characters/enemies/stage_05/enemy_gale_grappler.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyGaleGrappler

# Drone de captura: flutua e avança devagar até o player quando detecta —
# contato pesado, HP alto (arquétipo "heavy" do _DROP_TABLE).
func _ready() -> void:
	super._ready()
	max_hp = 16
	contact_damage = 13
	current_hp = max_hp
	detect_radius = 320.0
	dive_speed = 130.0
	retreat_speed = 70.0
	patrol_range = 70.0
	bob_amplitude = 14.0
```

`characters/enemies/stage_05/enemy_gale_grappler.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_05/enemy_gale_grappler.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_05/enemy_gale_grappler.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(76.0, 70.0)

[node name="EnemyGaleGrappler" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 3
frame = 0
scale = Vector2(0.72, 0.72)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 5: Parse-check headless dos 4 scripts**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/enemies/stage_05/enemy_sky_harrier.gd
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/enemies/stage_05/enemy_turbine_wisp.gd
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/enemies/stage_05/enemy_feather_swarm.gd
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/enemies/stage_05/enemy_gale_grappler.gd
```
Expected: sem `SCRIPT ERROR`/`Parse Error` em nenhum dos 4.

- [ ] **Step 6: Commit**

```bash
git add characters/enemies/stage_05/enemy_sky_harrier.* characters/enemies/stage_05/enemy_turbine_wisp.* characters/enemies/stage_05/enemy_feather_swarm.* characters/enemies/stage_05/enemy_gale_grappler.*
git commit -m "feat(stage05): inimigos voadores (sky_harrier, turbine_wisp, feather_swarm, gale_grappler)"
```

---

### Task 5: Inimigos estáticos (gale_turret, updraft_fan)

**Files:**
- Create: `characters/enemies/stage_05/enemy_gale_turret.gd` + `.tscn`
- Create: `characters/enemies/stage_05/enemy_updraft_fan.gd` + `.tscn`

**Interfaces:**
- Consumes: `WindProjectile.setup(...)` (Task 1), `CharacterBase.apply_stage_wind(force_delta)` (já existente).
- Produces: 2 `PackedScene` prontas pra Task 7/9 (`enemy_gale_turret.tscn`, `enemy_updraft_fan.tscn`).

- [ ] **Step 1: `enemy_gale_turret` — canhão fixo (molde `enemy_singularity_turret`)**

`characters/enemies/stage_05/enemy_gale_turret.gd`:
```gdscript
extends EnemyBase
class_name EnemyGaleTurret

# Torre de vento fixa: não vira; atira gale_bolt quando o player entra na
# janela do lado configurado (face_dir).
const _PROJ := preload("res://characters/enemies/stage_05/wind_projectile.tscn")
const FRAMES := 4
const FPS := 8.0
const SHOOT_RANGE := 520.0
const AIM_Y := 110.0
const SHOOT_INTERVAL := 1.4
const BOLT_SPEED := 320.0
const BOLT_DAMAGE := 7

@export var face_dir: float = -1.0

var _shoot_timer := 0.4

func _init() -> void:
	max_hp = 15
	contact_damage = 8

func _ready() -> void:
	max_hp = 15
	contact_damage = 8
	super._ready()
	_direction = face_dir
	_sprite.flip_h = _direction < 0.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	move_and_slide()
	_shoot_timer -= delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null and _shoot_timer <= 0.0:
		var off: Vector2 = p.global_position - global_position
		if absf(off.y) <= AIM_Y and absf(off.x) <= SHOOT_RANGE and signf(off.x) == _direction:
			_shoot_timer = SHOOT_INTERVAL
			_fire()
	_sprite.modulate.a = 0.35 if (_invincible and int(Time.get_ticks_msec() / 80) % 2 == 0) else 1.0
	_advance_sprite_frame_loop(delta, FRAMES, FPS)

func _fire() -> void:
	var proj := _PROJ.instantiate() as WindProjectile
	proj.setup(Vector2(_direction * BOLT_SPEED, 0.0), BOLT_DAMAGE, "gale_turret", 0.0, "gale_bolt")
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(_direction * 36.0, -6.0)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
```

`characters/enemies/stage_05/enemy_gale_turret.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_05/enemy_gale_turret.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_05/enemy_gale_turret.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(60.0, 56.0)

[node name="EnemyGaleTurret" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 2
vframes = 2
frame = 0
scale = Vector2(0.75, 0.75)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 2: `enemy_updraft_fan` — hazard estático com aura de empuxo pra cima (molde `enemy_grav_well`)**

`characters/enemies/stage_05/enemy_updraft_fan.gd`:
```gdscript
extends EnemyBase
class_name EnemyUpdraftFan

# Fã industrial fixo: enquanto vivo, empurra pra CIMA quem entrar na coluna
# vertical acima dele (apply_stage_wind). Matar o fã desliga o empuxo.
const FRAMES := 6
const FPS := 6.0
const COLUMN_WIDTH := 90.0
const COLUMN_HEIGHT := 420.0
const PUSH := 260.0

var _column: Area2D = null
var _pushed: Array[Node] = []

func _init() -> void:
	max_hp = 13
	contact_damage = 6

func _ready() -> void:
	max_hp = 13
	contact_damage = 6
	super._ready()
	_column = Area2D.new()
	_column.collision_layer = 0
	_column.collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(COLUMN_WIDTH, COLUMN_HEIGHT)
	cs.shape = sh
	cs.position = Vector2(0.0, -COLUMN_HEIGHT * 0.5)
	_column.add_child(cs)
	add_child(_column)
	_column.body_entered.connect(func(b: Node) -> void:
		if not _pushed.has(b):
			_pushed.append(b))
	_column.body_exited.connect(func(b: Node) -> void:
		_pushed.erase(b))

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	velocity = Vector2.ZERO
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	if DebugBoot.bot_enabled:
		return
	for b in _pushed:
		if is_instance_valid(b) and b.has_method("apply_stage_wind"):
			b.apply_stage_wind(Vector2(0.0, -PUSH) * delta)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
```

`characters/enemies/stage_05/enemy_updraft_fan.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_05/enemy_updraft_fan.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_05/enemy_updraft_fan.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(64.0, 96.0)

[node name="EnemyUpdraftFan" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 2
frame = 0
scale = Vector2(0.85, 0.85)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: Parse-check headless dos 2 scripts**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/enemies/stage_05/enemy_gale_turret.gd
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/enemies/stage_05/enemy_updraft_fan.gd
```
Expected: sem `SCRIPT ERROR`/`Parse Error` em nenhum dos 2.

- [ ] **Step 4: Commit**

```bash
git add characters/enemies/stage_05/enemy_gale_turret.* characters/enemies/stage_05/enemy_updraft_fan.*
git commit -m "feat(stage05): inimigos estáticos (gale_turret, updraft_fan)"
```

---

### Task 6: Scaffold `stage_05_scene.gd` + Zona 1 (corrente horizontal)

**Files:**
- Create: `stages/stage_05/stage_05_scene.gd`
- Modify: `stages/stage_05/stage_05.tscn:3` (trocar `res://stages/stage_scene.gd` pelo novo script) e remover os nós antigos de plataforma/checkpoint/collectível (linhas 55-196 do arquivo atual)

**Interfaces:**
- Consumes: `stages/stage_02/blizzard_zone.gd` (já existe, sem alteração), `characters/enemies/stage_05/enemy_gale_runner.tscn`/`enemy_claw_glider.tscn`/`enemy_airfoil_lancer.tscn` (Task 3).
- Produces: `Stage05` script base com `_zone_tile_path`, `_floor_seg`, `_solid_block`, `_glass_wall`, `_wind_current`, `_setup_corridors`/`_make_corridor`, `_setup_zone_triggers`/`_make_zone_trigger`, `_spawn_zone_enemies` — consumidos pelas Tasks 7-9.

- [ ] **Step 1: Reescrever `stage_05.tscn`**

Substituir o conteúdo de `stages/stage_05/stage_05.tscn` por:
```
[gd_scene format=3 uid="uid://stage_05"]

[ext_resource type="Script" path="res://stages/stage_05/stage_05_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://galerix" path="res://characters/bosses/galerix.tscn" id="9_boss"]

[node name="Stage05" type="Node2D"]
platform_color = Color(0.2, 0.8, 0.5, 1)
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 760)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Camera2D" type="Camera2D" parent="."]
zoom = Vector2(2, 2)

[node name="HUD" parent="." instance=ExtResource("5_hud")]

[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]

[node name="GameOver" parent="." instance=ExtResource("7_gameover")]

[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Galerix" parent="." instance=ExtResource("9_boss")]
position = Vector2(11040, 736)
visible = false
```
(Removidos os nós antigos `FloorStart`/`FloorLand`/`FloorBoss`/`AP1-11`/`Checkpoint1-2`/colectáveis — a Task 6-9 recria tudo via código, no mesmo padrão de stage_04. `Galerix` some do padrão dinâmico do stage_00 pra um nó fixo `visible=false` que a Task 9 ativa — mais simples, igual ao padrão A usado em `_build_boss_arena` do stage_04.)

- [ ] **Step 2: Criar o scaffold do script**

`stages/stage_05/stage_05_scene.gd`:
```gdscript
# stages/stage_05/stage_05_scene.gd — Galerix (vento)
# Rebuild completo no molde dos stages 02/03/04: estende a base stage_scene.gd,
# zonas construídas em código, 2 corredores com checkpoint e arena de boss.
# Identidade de vento:
#   Z1 corrente horizontal — rajadas empurram o jogador ao longo do piso
#   Z2 coluna de updraft   — shaft vertical erguido por câmaras de empuxo
#   Z3 plataformas soltas  — deslizam quando pisadas, sobre abismo
#   Z4 corredor final      — canhões de vento até a sala do Galerix
extends "res://stages/stage_scene.gd"

const _BLIZZARD := preload("res://stages/stage_02/blizzard_zone.gd")
const _LIFT := preload("res://stages/stage_04/lift_zone.gd")
const _SLIDER := preload("res://stages/stage_05/sliding_platform.gd")
const _GALE := {
	"runner":   preload("res://characters/enemies/stage_05/enemy_gale_runner.tscn"),
	"glider":   preload("res://characters/enemies/stage_05/enemy_claw_glider.tscn"),
	"lancer":   preload("res://characters/enemies/stage_05/enemy_airfoil_lancer.tscn"),
	"harrier":  preload("res://characters/enemies/stage_05/enemy_sky_harrier.tscn"),
	"wisp":     preload("res://characters/enemies/stage_05/enemy_turbine_wisp.tscn"),
	"swarm":    preload("res://characters/enemies/stage_05/enemy_feather_swarm.tscn"),
	"grappler": preload("res://characters/enemies/stage_05/enemy_gale_grappler.tscn"),
	"turret":   preload("res://characters/enemies/stage_05/enemy_gale_turret.tscn"),
	"fan":      preload("res://characters/enemies/stage_05/enemy_updraft_fan.tscn"),
}

const FLOOR_Y := 800.0     # piso de Z1 e do shaft (base)
const FLOOR_Y2 := -800.0   # piso elevado de Z2(topo)/Z3/Z4/boss
const _CORR_INTERIOR := 192.0

const _CP1_ENTRY_X := 3136.0
const _CP1_EXIT_X := 4032.0
const _CP2_ENTRY_X := 8000.0
const _CP2_EXIT_X := 8896.0
const _BOSS_L := 10240.0
const _BOSS_R := 11648.0

# Roster de vento por zona: kind (chave de _GALE) → posições.
const Z1_ENEMIES := {
	"runner": [Vector2(700.0, 760.0), Vector2(2100.0, 760.0)],
	"glider": [Vector2(1400.0, 760.0)],
	"lancer": [Vector2(2700.0, 760.0)],
}
const Z2_ENEMIES := {
	"harrier": [Vector2(4200.0, 400.0), Vector2(4300.0, -300.0)],
	"wisp":    [Vector2(4100.0, 0.0), Vector2(4350.0, -500.0)],
}
const Z3_ENEMIES := {
	"swarm":    [Vector2(5600.0, -850.0), Vector2(7200.0, -850.0)],
	"grappler": [Vector2(6400.0, -900.0)],
}
const Z4_ENEMIES := {
	"turret": [Vector2(9200.0, 736.0), Vector2(9900.0, 736.0)],
}

var _door_tex: Texture2D = null
var _glass_tex: Texture2D = null
var _camera_locked := false
var _camera_target := Vector2.ZERO
var _camera_zoom_tgt := 2.0
var _zone1_enemies: Array[Node] = []
var _zone2_enemies: Array[Node] = []
var _zone3_enemies: Array[Node] = []
var _zone4_enemies: Array[Node] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if StageManager.current_stage_id < 0:
		StageManager.current_stage_id = 5
	super._ready()
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_glass_tex = load("res://stages/stage_05/stage_05_glass.png") as Texture2D
	_setup_corridors()
	_build_zone1()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _zone_tile_path(zone: String) -> String:
	# Case EXATO do arquivo (PCK web é case-sensitive). Arena do boss usa z4.
	var z := zone.to_lower()
	if z == "boss":
		z = "z4"
	return "res://stages/stage_05/Stage_05T_%s.png" % z

func _process(delta: float) -> void:
	var cam := $Camera2D as Camera2D
	if _camera_locked:
		cam.global_position = cam.global_position.lerp(_camera_target, 0.12)
		cam.zoom = cam.zoom.lerp(Vector2(_camera_zoom_tgt, _camera_zoom_tgt), 0.12)
		queue_redraw()
		return
	if not DebugBoot.bot_enabled:
		cam.zoom = cam.zoom.lerp(Vector2(2.0, 2.0), 0.12)
	super._process(delta)

# ── Corredores (checkpoints) ─────────────────────────────────────────────────

func _setup_corridors() -> void:
	_make_corridor("CP1", _CP1_ENTRY_X, _CP1_EXIT_X, "z1", FLOOR_Y, 1)
	_make_corridor("CP2", _CP2_ENTRY_X, _CP2_EXIT_X, "z3", FLOOR_Y2, 2)

func _make_corridor(name_prefix: String, entry_x: float, exit_x: float, zone: String, floor_y: float, checkpoint_index: int) -> CorridorSection:
	var width := exit_x - entry_x
	var corr := CorridorSection.new()
	corr.name = name_prefix
	corr.tileset = _cached_override_tex(_zone_tile_path(zone))
	corr.glass_tex = _glass_tex
	corr.door_tex = _door_tex
	var floor_cy := floor_y + 32.0
	var ceil_cy := floor_y - _CORR_INTERIOR - 32.0
	var mid_y := (floor_cy + ceil_cy) * 0.5
	corr.floor_center = Vector2(entry_x + width * 0.5, floor_cy)
	corr.floor_size = Vector2(width, 64.0)
	corr.ceil_center = Vector2(entry_x + width * 0.5, ceil_cy)
	corr.ceil_size = Vector2(width, 64.0)
	corr.wall_l_center = Vector2(entry_x, mid_y)
	corr.wall_l_size = Vector2(64.0, _CORR_INTERIOR + 64.0)
	corr.wall_r_center = Vector2(exit_x, mid_y)
	corr.wall_r_size = Vector2(64.0, _CORR_INTERIOR + 64.0)
	corr.entry_x = entry_x
	corr.exit_x = exit_x
	corr.save_checkpoint = true
	corr.heal_on_entry = false
	corr.checkpoint_index = checkpoint_index
	corr.checkpoint_respawn_x = exit_x + 128.0
	corr.cam_center = Vector2(entry_x + width * 0.5, mid_y)
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

# ── Spawn de inimigos por zona ───────────────────────────────────────────────

func _setup_zone_triggers() -> void:
	_make_zone_trigger("Z2Trigger", Rect2(_CP1_EXIT_X, -1600.0, 3200.0, 2500.0), 2)
	_make_zone_trigger("Z3Trigger", Rect2(4800.0, -1600.0, 3200.0, 900.0), 3)
	_make_zone_trigger("Z4Trigger", Rect2(_CP2_EXIT_X, -1600.0, 2200.0, 900.0), 4)

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
			_spawn_zone_enemies(zone))
	add_child(area)

func _spawn_zone_enemies(zone: int) -> void:
	if DebugBoot.no_enemies:
		return
	var target: Array[Node]
	var table: Dictionary
	match zone:
		1: target = _zone1_enemies; table = Z1_ENEMIES
		2: target = _zone2_enemies; table = Z2_ENEMIES
		3: target = _zone3_enemies; table = Z3_ENEMIES
		4: target = _zone4_enemies; table = Z4_ENEMIES
		_: return
	if not target.is_empty():
		return
	for kind: String in table:
		var scene: PackedScene = _GALE[kind]
		for pos in table[kind]:
			var e := scene.instantiate()
			(e as Node2D).global_position = pos
			add_child(e)
			target.append(e)

# ── Helpers de terreno (mesmo vocabulário dos stages 02/03/04) ───────────────

func _floor_seg(zone: String, x0: float, x1: float, surface_y: float, dr: int = 3) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = "%s_Floor_%d" % [zone, int(x0)]
	b.collision_layer = 1
	b.collision_mask = 0
	var w := x1 - x0
	var h := dr * float(_TS)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	cs.shape = shape
	cs.position = Vector2(x0 + w * 0.5, surface_y + h * 0.5)
	b.add_child(cs)
	b.set_meta("lava_override", _zone_tile_path(zone))
	add_child(b)
	return b

func _solid_block(zone: String, n: String, cx: float, cy: float, w: float, h: float) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = n
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = Vector2(cx, cy)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	b.add_child(cs)
	b.set_meta("lava_override", _zone_tile_path(zone))
	add_child(b)
	return b

func _glass_wall(x_center: float, top_y: float, height: float) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = "Z_Glass_%d" % int(x_center)
	b.collision_layer = 1
	b.collision_mask = 0
	b.add_to_group("no_wall_grab")
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64.0, height)
	cs.shape = shape
	cs.position = Vector2(x_center, top_y + height * 0.5)
	b.add_child(cs)
	b.set_meta("tileset_override", "res://stages/stage_05/stage_05_glass.png")
	add_child(b)
	return b

func _fixed_plat(n: String, zone: String, cx: float, top_y: float, w: float = 128.0) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = n
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = Vector2(cx, top_y + 16.0)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, 32.0)
	cs.shape = sh
	b.add_child(cs)
	b.set_meta("platform_override", _zone_tile_path(zone))
	add_child(b)
	return b

func _wind_current(n: String, pos: Vector2, size: Vector2, force: Vector2) -> void:
	var w: Area2D = _BLIZZARD.new()
	w.name = n
	w.set("force", force)
	w.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	w.add_child(cs)
	add_child(w)

func _updraft_column(n: String, pos: Vector2, size: Vector2, force: float = 700.0) -> void:
	var l: Area2D = _LIFT.new()
	l.name = n
	l.set("lift_force", force)
	l.set("size", size)
	l.position = pos
	add_child(l)

func _sliding_plat(n: String, zone: String, pos: Vector2, dir: float = 1.0, dist: float = 220.0) -> void:
	var p: AnimatableBody2D = _SLIDER.new()
	p.name = n
	p.set("slide_dir", dir)
	p.set("slide_distance", dist)
	p.collision_layer = 1
	p.collision_mask = 0
	p.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(96.0, 32.0)
	cs.shape = sh
	p.add_child(cs)
	p.set_meta("platform_override", _zone_tile_path(zone))
	add_child(p)

# ── Zona 1 — Entrada / corrente de vento horizontal ──────────────────────────

func _build_zone1() -> void:
	_floor_seg("z1", 0.0, _CP1_ENTRY_X, FLOOR_Y)
	# Trechos de corrente: empurra a favor (ajuda travessia) e contra
	# (obriga cronometrar pulo) alternados ao longo da zona.
	_wind_current("Z1Wind_A", Vector2(900.0, 700.0), Vector2(700.0, 200.0), Vector2(140.0, 0.0))
	_wind_current("Z1Wind_B", Vector2(2400.0, 700.0), Vector2(700.0, 200.0), Vector2(-160.0, 0.0))
```

- [ ] **Step 2: Parse-check headless (script scaffold ainda sem `_build_zone2/3/4`, chamadas nas próximas tasks — o `Stage05.tscn` não deve ser carregado ainda; validar só o `.gd`)**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script stages/stage_05/stage_05_scene.gd`
Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_05/stage_05.tscn stages/stage_05/stage_05_scene.gd
git commit -m "feat(stage05): scaffold do script + zona 1 (corrente de vento)"
```

---

### Task 7: Zona 2 — Coluna de updraft vertical

**Files:**
- Modify: `stages/stage_05/stage_05_scene.gd` (adicionar `_build_zone2()` + chamada em `_ready()`)

**Interfaces:**
- Consumes: `_solid_block`, `_updraft_column`, `_fixed_plat` (Task 6).
- Produces: `_build_zone2()`, consumido pela Task 10 (integração final).

- [ ] **Step 1: Adicionar `_build_zone2()`**

Em `stages/stage_05/stage_05_scene.gd`, adicionar chamada em `_ready()` logo após `_build_zone1()`:
```gdscript
	_build_zone1()
	_build_zone2()
	_setup_zone_triggers()
```

E adicionar a função (depois de `_build_zone1`):
```gdscript
# ── Zona 2 — Coluna de updraft vertical ──────────────────────────────────────
# Shaft estreito (448px, 7 tiles) subindo de FLOOR_Y (piso) até FLOOR_Y2 (topo,
# 1600px acima) — câmara de empuxo cobre quase toda a altura, erguendo o
# jogador. Alcova lateral no meio do shaft guarda a armadura de Braços do Zael.

const _Z2_SHAFT_L := 4032.0
const _Z2_SHAFT_R := 4480.0
const _Z2_SHAFT_TOP := FLOOR_Y2
const _Z2_SHAFT_BOTTOM := FLOOR_Y
const _Z2_ARMOR_ALCOVE_Y := 0.0

func _build_zone2() -> void:
	# Paredes do shaft (chão até o topo, 32px de folga acima do topo pra fechar com a Z3).
	var shaft_h := _Z2_SHAFT_BOTTOM - _Z2_SHAFT_TOP + 64.0
	var shaft_cy := (_Z2_SHAFT_BOTTOM + _Z2_SHAFT_TOP) * 0.5
	_solid_block("z2", "Z2_WallL", _Z2_SHAFT_L, shaft_cy, 64.0, shaft_h)
	_solid_block("z2", "Z2_WallR", _Z2_SHAFT_R, shaft_cy, 64.0, shaft_h)
	# Câmara de empuxo cobrindo quase toda a coluna (deixa uma folga no topo
	# pra desacelerar antes de aterrissar na plataforma de Z2->Z3).
	_updraft_column("Z2_Updraft", Vector2((_Z2_SHAFT_L + _Z2_SHAFT_R) * 0.5, _Z2_SHAFT_BOTTOM - 200.0),
		Vector2(_Z2_SHAFT_R - _Z2_SHAFT_L - 32.0, _Z2_SHAFT_BOTTOM - _Z2_SHAFT_TOP - 100.0), 700.0)
	# Alcova lateral pro colectável (armadura Braços do Zael), acessível saindo
	# um pouco do fluxo principal do updraft no meio do shaft.
	_solid_block("z2", "Z2_ArmorFloor", _Z2_SHAFT_R + 96.0, _Z2_ARMOR_ALCOVE_Y + 32.0, 192.0, 64.0)
	_fixed_plat("Z2_ArmorLedge", "z2", _Z2_SHAFT_R + 96.0, _Z2_ARMOR_ALCOVE_Y, 128.0)
	var armor := preload("res://stages/collectible.tscn").instantiate()
	armor.set("collectible_type", "armor_zael_arms")
	armor.global_position = Vector2(_Z2_SHAFT_R + 96.0, _Z2_ARMOR_ALCOVE_Y - 40.0)
	add_child(armor)
	# Aterrissagem no topo do shaft — plataforma plana levando pra Z3.
	_floor_seg("z2", _Z2_SHAFT_L, 4800.0, FLOOR_Y2)
```

- [ ] **Step 2: Parse-check headless**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script stages/stage_05/stage_05_scene.gd`
Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_05/stage_05_scene.gd
git commit -m "feat(stage05): zona 2 (shaft de updraft + armadura)"
```

---

### Task 8: Zona 3 — Plataformas deslizantes sobre abismo

**Files:**
- Modify: `stages/stage_05/stage_05_scene.gd` (adicionar `_build_zone3()` + chamada em `_ready()`)

**Interfaces:**
- Consumes: `_sliding_plat`, `_floor_seg`, `_fixed_plat` (Tasks 2, 6).
- Produces: `_build_zone3()`, consumido pela Task 10.

- [ ] **Step 1: Adicionar `_build_zone3()`**

Em `_ready()`:
```gdscript
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_setup_zone_triggers()
```

Função nova:
```gdscript
# ── Zona 3 — Plataformas deslizantes sobre abismo ────────────────────────────
# Piso fixo nas pontas (chegada de Z2 e chegada no corredor CP2), 3
# plataformas deslizantes no meio cobrindo o abismo — cada uma desliza numa
# direção diferente pra exigir timing, não só posição estática.

func _build_zone3() -> void:
	_floor_seg("z3", 4800.0, 5400.0, FLOOR_Y2)
	_sliding_plat("Z3_Slide1", "z3", Vector2(5700.0, FLOOR_Y2 - 16.0), 1.0, 220.0)
	_sliding_plat("Z3_Slide2", "z3", Vector2(6300.0, FLOOR_Y2 - 16.0), -1.0, 220.0)
	_sliding_plat("Z3_Slide3", "z3", Vector2(6900.0, FLOOR_Y2 - 16.0), 1.0, 260.0)
	_floor_seg("z3", 7400.0, _CP2_ENTRY_X, FLOOR_Y2)
	# Extra de Zara (Garras) + coração num desvio elevado, acessível parando
	# em cima do Z3_Slide2 no ponto mais à esquerda do curso dele.
	_fixed_plat("Z3_ExtraLedge", "z3", 6100.0, FLOOR_Y2 - 180.0, 160.0)
	var claws := preload("res://stages/collectible.tscn").instantiate()
	claws.set("collectible_type", "extra_zara_claws")
	claws.global_position = Vector2(6100.0, FLOOR_Y2 - 220.0)
	add_child(claws)
	var heart := preload("res://stages/collectible.tscn").instantiate()
	heart.set("collectible_type", "heart")
	heart.global_position = Vector2(6180.0, FLOOR_Y2 - 220.0)
	add_child(heart)
```

- [ ] **Step 2: Parse-check headless**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script stages/stage_05/stage_05_scene.gd`
Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_05/stage_05_scene.gd
git commit -m "feat(stage05): zona 3 (plataformas deslizantes + colectáveis)"
```

---

### Task 9: Zona 4 + sala do boss

**Files:**
- Modify: `stages/stage_05/stage_05_scene.gd` (adicionar `_build_zone4()`, `_build_boss_arena()` + chamadas em `_ready()`)

**Interfaces:**
- Consumes: `_floor_seg`, `_solid_block` (Task 6), nó `Galerix` já presente na `.tscn` (Task 6 Step 1).
- Produces: `_build_zone4()`, `_build_boss_arena()`, consumidos pela Task 10.

- [ ] **Step 1: Adicionar `_build_zone4()` e `_build_boss_arena()`**

Em `_ready()`:
```gdscript
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_boss_arena()
	_setup_zone_triggers()
```

Funções novas (padrão B — porta aberta + trigger, mesmo do stage_01, já que a arena precisa ficar acessível caso o player queira recuar):
```gdscript
# ── Zona 4 — Corredor final com canhões de vento ─────────────────────────────

func _build_zone4() -> void:
	_floor_seg("z4", _CP2_EXIT_X, _BOSS_L, FLOOR_Y2)

# ── Sala do boss (Galerix) ────────────────────────────────────────────────────
# Padrão B (porta aberta + trigger, skill new-boss-room): arena aberta,
# aggro por Area2D de entrada — não por distância.

func _build_boss_arena() -> void:
	_floor_seg("boss", _BOSS_L, _BOSS_R, FLOOR_Y2)
	_solid_block("boss", "Boss_WallR", _BOSS_R + 32.0, FLOOR_Y2 - 240.0, 64.0, 480.0)
	_solid_block("boss", "Boss_WallL_Top", _BOSS_L + 32.0, FLOOR_Y2 - 352.0, 64.0, 256.0)
	var galerix := get_node_or_null("Galerix")
	if galerix:
		galerix.visible = true
		galerix.global_position = Vector2((_BOSS_L + _BOSS_R) * 0.5, FLOOR_Y2 - 64.0)
		galerix.set("auto_aggro", false)
		var trig := Area2D.new()
		trig.name = "BossRoomTrigger"
		trig.collision_layer = 0
		trig.collision_mask = 2
		trig.position = Vector2((_BOSS_L + _BOSS_R) * 0.5, FLOOR_Y2 - 150.0)
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(_BOSS_R - _BOSS_L - 200.0, 300.0)
		cs.shape = sh
		trig.add_child(cs)
		add_child(trig)
		trig.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBase:
				galerix.call("aggro"))
		$HUD.connect_to_boss(galerix)
		if galerix.has_signal("boss_defeated"):
			galerix.connect("boss_defeated", _on_boss_defeated)

func _on_boss_defeated(_ability_id: String) -> void:
	GameManager.save_game()
```

- [ ] **Step 2: Parse-check headless**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script stages/stage_05/stage_05_scene.gd`
Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_05/stage_05_scene.gd
git commit -m "feat(stage05): zona 4 + sala do boss Galerix"
```

---

### Task 10: Teto por zona + integração final

**Files:**
- Modify: `stages/stage_05/stage_05_scene.gd` (adicionar `_CEIL05_SEGS`, `_build_zone_ceilings05()`, `_ceil05_surface_at()`, `_draw_zone_ceilings05()`, `_draw()`, chamada em `_ready()`)

**Interfaces:**
- Consumes: todas as zonas das Tasks 6-9.
- Produces: fase jogável completa, testada headless + StageBot + export web.

- [ ] **Step 1: Adicionar sistema de teto (com os fixes de gap/fronteira já aplicados desde o início)**

Em `_ready()`, adicionar como ÚLTIMA chamada de construção (antes de `_setup_zone_triggers`):
```gdscript
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_boss_arena()
	_build_zone_ceilings05()
	_setup_zone_triggers()
```

Constantes e funções novas (mesmo padrão FACE_GAP/fallback cross-zone aplicado em stage_01/02/03/04 este ciclo — ver memórias `reference_ceiling_collision_gap` e `reference_ceiling_zone_boundary`):
```gdscript
# ── Teto por zona ─────────────────────────────────────────────────────────────
# [x0, x1, y_surface] por zona. Z2 não tem teto próprio (é o shaft vertical,
# coberto pelas paredes) — Z3/Z4/Boss ficam a 300px acima de FLOOR_Y2.
const _CEIL05_SEGS := {
	"Z1":   [[0.0, 4032.0, FLOOR_Y - 500.0]],
	"Z3":   [[4800.0, 8896.0, FLOOR_Y2 - 300.0]],
	"Z4":   [[8896.0, 10240.0, FLOOR_Y2 - 300.0]],
	"Boss": [[10240.0, 11648.0, FLOOR_Y2 - 352.0 - 256.0]],
}
const _CEIL05_TEX := { "Z1": "z1", "Z3": "z3", "Z4": "z4", "Boss": "z4" }
const _CEIL05_TOP := 128.0
const _CEIL05_FACE_GAP := 32.0

func _build_zone_ceilings05() -> void:
	for zk: String in _CEIL05_SEGS:
		var body := StaticBody2D.new()
		body.name = "%sCeilSegs" % zk
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		for s: Array in _CEIL05_SEGS[zk]:
			var cs := CollisionShape2D.new()
			var sh := SegmentShape2D.new()
			sh.a = Vector2(s[0], (s[2] as float) - _CEIL05_FACE_GAP)
			sh.b = Vector2(s[1], (s[2] as float) - _CEIL05_FACE_GAP)
			cs.shape = sh
			body.add_child(cs)

func _ceil05_surface_at(zk: String, wx: float) -> float:
	for s: Array in _CEIL05_SEGS[zk]:
		if wx >= (s[0] as float) and wx < (s[1] as float):
			return s[2]
	for zk2: String in _CEIL05_SEGS:
		if zk2 == zk:
			continue
		for s: Array in _CEIL05_SEGS[zk2]:
			if wx >= (s[0] as float) and wx < (s[1] as float):
				return s[2]
	return -1.0

func _ceil05_solid(zk: String, wx: float, y: float) -> bool:
	var yb := _ceil05_surface_at(zk, wx)
	return yb > 0.0 and y < yb

func _draw() -> void:
	super._draw()
	_draw_zone_ceilings05()

func _draw_zone_ceilings05() -> void:
	var ts := float(_TS)
	var sts := float(_SRC_TS)
	for zk: String in _CEIL05_SEGS:
		var segs: Array = _CEIL05_SEGS[zk]
		var tex := _cached_override_tex(_zone_tile_path(_CEIL05_TEX[zk] as String))
		if tex == null:
			continue
		var x0f: float = segs[0][0]
		var x1f: float = segs[segs.size() - 1][1]
		var x := x0f
		while x < x1f:
			var yb := _ceil05_surface_at(zk, x)
			var y := _CEIL05_TOP
			while y < yb:
				var ed := not _ceil05_solid(zk, x, y + ts)
				var el := not _ceil05_solid(zk, x - ts, y)
				var er := not _ceil05_solid(zk, x + ts, y)
				var tile: Vector2i
				if   ed and el: tile = Vector2i(0, 2)
				elif ed and er: tile = Vector2i(3, 3)
				elif ed:        tile = Vector2i(1, 2)
				elif el:        tile = Vector2i(1, 0)
				elif er:        tile = Vector2i(3, 2)
				elif not _ceil05_solid(zk, x - ts, y + ts): tile = Vector2i(2, 2)
				elif not _ceil05_solid(zk, x + ts, y + ts): tile = Vector2i(3, 1)
				else:           tile = Vector2i(2, 1)
				draw_texture_rect_region(tex, Rect2(x, y - sts, ts, ts),
					Rect2(float(tile.x) * sts, float(tile.y) * sts, sts, sts))
				y += ts
			x += ts
```

- [ ] **Step 2: Parse-check headless do script**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script stages/stage_05/stage_05_scene.gd`
Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 3: Parse-check headless da cena completa**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://stages/stage_05/stage_05.tscn`
Expected: nenhuma linha contendo `SCRIPT ERROR`/`Parse Error` na saída (processo pode não sair sozinho — usar timeout de 60s e checar o log, mesmo padrão da memória `reference_godot_headless_assert`).

- [ ] **Step 4: Rodar os testes automatizados existentes (garantir que nada quebrou globalmente)**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```
Expected: saída sem `SCRIPT ERROR`/`Parse Error`/assert falho (skill `run-tests`).

- [ ] **Step 5: Gerar SVG de debug pra conferir geometria (zone_debug_01.gd)**

Rodar a skill/tool de debug SVG já existente no projeto (`tools/zone_debug_01.gd`) apontando pra `stage_05` — conferir visualmente as 4 zonas, a costura Z2→Z3 (updraft terminando na altura certa) e a sala do boss (múltiplos de 64px, sem vão na porta). Ajustar constantes numéricas em `stage_05_scene.gd` conforme o que o SVG revelar — esperado que a geometria de primeira tentativa precise de pequenos ajustes de coordenada, mesmo padrão iterativo usado em Z4 do stage_01 (não é falha do plano, é o fluxo normal do projeto).

- [ ] **Step 6: Export web + smoke test**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --export-release "Web" "export/web/index.html"
```
Expected: `EXIT 0`, `export/web/index.pck` com timestamp atualizado. Reiniciar o servidor local (skill `web-export`) e confirmar no browser (`localhost:8080/index.html?stage=5` ou fluxo de stage select) que a fase carrega sem erro no console.

- [ ] **Step 7: Commit final**

```bash
git add stages/stage_05/stage_05_scene.gd export/web/index.pck export/web/index.html
git commit -m "feat(stage05): teto por zona + integração final"
```

---

## Self-Review

**1. Cobertura do spec:** Z1 (Task 6) ✓, Z2 updraft+armadura (Task 7) ✓, Z3 deslizantes+extra+coração (Task 8) ✓, Z4+boss (Task 9) ✓, roster de 9 (Tasks 3-5) ✓, 2 checkpoints (Task 6) ✓, teto com FACE_GAP/fallback (Task 10) ✓, kill plane e StageBot — cobertos como verificação na Task 10 Steps 4-5 (o kill plane herdado de `stage_scene.gd` já cobre `y > kill_y` calculado por fase; não precisa de código novo, só validação visual).

**2. Placeholders:** nenhum "TBD"/"implementar depois" — todo passo tem código completo. Coordenadas numéricas são um primeiro layout real (não fictício), com iteração visual explicitamente prevista na Task 10 Step 5 (mesmo processo usado em todo o projeto até aqui).

**3. Consistência de tipos:** `WindProjectile.setup()` (Task 1) usado identicamente pelas Tasks 3, 4, 5 (`airfoil_lancer`, `turbine_wisp`, `feather_swarm`, `gale_turret`) com a mesma assinatura. `_GALE` (Task 6) referencia exatamente os nomes de arquivo `.tscn` criados nas Tasks 3-5. `_sliding_plat`/`SlidingPlatform` (Task 2) com `slide_dir`/`slide_distance` batendo entre definição e uso na Task 8.

---

**Plan complete and saved to `docs/superpowers/plans/2026-07-16-stage05-galerix-redesign.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
