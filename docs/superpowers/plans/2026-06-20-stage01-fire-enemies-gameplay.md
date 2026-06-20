# Stage 01 Fire Enemies — Gameplay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar comportamento de jogo e posicionamento aos 9 inimigos de fogo do `stage_01` (arte já existe), reusando o padrão do `stage_02`, entregue em 4 PRs (3 trios + wiring).

**Architecture:** Cada inimigo é um `CharacterBody2D` (layer 4 / mask 1) com script `extends EnemyBase` (terrestres/ranged) ou `EnemyFlyer` (voadores), `Sprite2D` com a sheet (grade fixa), `ContactZone` (Area2D layer 0 / mask 2) e animação via helpers de `EnemyBase`. Os ranged usam um projétil compartilhado `fire_projectile` (Area2D com `Sprite2D` texturizado + `setup(velocity, damage, source, gravity, variant)`). O wiring substitui as placements genéricas e spawna ~43 inimigos pelas zonas.

**Tech Stack:** Godot 4.6.2, GDScript. Testes headless: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/<x>.tscn`.

**Spec:** `docs/superpowers/specs/2026-06-20-stage01-fire-enemies-gameplay-design.md`

---

## Tabela de referência (sheets, grades, stats)

| Inimigo | Sheet (px) | hframes×vframes | frames | fps anim | base | max_hp | contact |
|---------|-----------|------|--------|-----|------|--------|---------|
| magma_grunt | 256×256 | 2×2 | 4 | 6 | EnemyBase | 10 | 8 |
| molten_ram | 384×384 | 3×3 | 9 | 9 | EnemyBase | 22 | 14 |
| ash_hopper | 384×256 | 3×2 | 6 | 10 | EnemyBase | 7 | 7 |
| ember_orbiter | 384×256 | 3×2 | 6 | 8 | EnemyFlyer | 8 | 6 |
| flame_skimmer | 384×384 | 3×3 | 9 | 10 | EnemyFlyer | 9 | 10 |
| cinder_flyer | 256×256 | 2×2 | 4 | 8 | EnemyFlyer | 8 | 7 |
| heat_mortar | 384×256 | 3×2 | 6 | 10 | EnemyBase | 14 | 9 |
| magma_turret | 256×256 | 2×2 | 4 | 8 | EnemyBase | 18 | 9 |
| lava_serpent | 384×384 | 4×4 | 16 | 10 | EnemyBase | 14 | 11 |
| fire_bolt | 256×256 | 2×2 | 4 | 12 | — | — | — |
| fire_glob | 256×256 | 2×2 | 4 | 12 | — | — | — |
| fire_spit | 256×256 | 2×2 | 4 | 12 | — | — | — |
| heat_mortar_shell | 256×256 | 2×2 | 4 | 12 | — | — | — |

Texturas finais já em `characters/enemies/stage_01/<nome>.png` e (projéteis também) `characters/enemies/stage_01/<proj>.png`.

**Convenções de cena** (todas as cenas de inimigo):
- `CharacterBody2D` raiz: `collision_layer = 4`, `collision_mask = 1`, script.
- `CollisionShape2D` cápsula (radius 20, height 80) — exceto serpente (ver Task 12).
- `Sprite2D`: `texture`, `hframes`, `vframes`, `scale` (0.7 p/ células 128px; 0.9 p/ serpente 96px), `frame = 0`.
- `ContactZone` (Area2D, `collision_layer = 0`, `collision_mask = 2`) + `CollisionShape2D` cápsula igual.

**Padrão de animação:**
- Patrulha simples (magma_grunt): chama `super._physics_process(delta)` e depois `_advance_sprite_frame_loop(delta, FRAMES, FPS)` (padrão idêntico ao `enemy_ice_grunt`).
- Comportamentos especiais: **não** chamam `super._physics_process`; gerenciam física+animação próprias usando `_set_sprite_frame()` / `_advance_sprite_frame_loop()` e `_tick_invincibility()`.

---

# FASE 1 — Trio melee (PR 1)

### Task 1: `enemy_magma_grunt` (patrulha simples)

**Files:**
- Create: `characters/enemies/stage_01/enemy_magma_grunt.gd`
- Create: `characters/enemies/stage_01/enemy_magma_grunt.tscn`

- [ ] **Step 1: Script**

`characters/enemies/stage_01/enemy_magma_grunt.gd`:
```gdscript
extends EnemyBase
class_name EnemyMagmaGrunt

const IDLE_FRAMES := 4
const IDLE_FPS := 6.0

func _init() -> void:
	max_hp = 10
	contact_damage = 8

func _ready() -> void:
	max_hp = 10
	contact_damage = 8
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_advance_sprite_frame_loop(delta, IDLE_FRAMES, IDLE_FPS)
```

- [ ] **Step 2: Cena**

`characters/enemies/stage_01/enemy_magma_grunt.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_01/enemy_magma_grunt.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_01/enemy_magma_grunt.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 20.0
height = 80.0

[node name="EnemyMagmaGrunt" type="CharacterBody2D"]
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
scale = Vector2(0.7, 0.7)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: Verificar load headless**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://characters/enemies/stage_01/enemy_magma_grunt.tscn --quit-after 2 2>&1 | grep -iE "SCRIPT ERROR|Parse Error" || echo NO-ERRORS`
Expected: `NO-ERRORS`.

- [ ] **Step 4: Commit**
```bash
git add characters/enemies/stage_01/enemy_magma_grunt.gd characters/enemies/stage_01/enemy_magma_grunt.tscn
git commit -m "feat(stage01): enemy_magma_grunt (patrulha simples)"
```

---

### Task 2: `enemy_molten_ram` (investida)

**Files:**
- Create: `characters/enemies/stage_01/enemy_molten_ram.gd`
- Create: `characters/enemies/stage_01/enemy_molten_ram.tscn`

- [ ] **Step 1: Script**

`characters/enemies/stage_01/enemy_molten_ram.gd`:
```gdscript
extends EnemyBase
class_name EnemyMoltenRam

const FRAMES := 9
const FPS := 9.0
const PATROL := 50.0
const CHARGE_SPEED := 360.0
const DETECT_X := 460.0
const DETECT_Y := 90.0
const CHARGE_TIME := 0.9
const COOLDOWN := 1.1

enum S { PATROL, CHARGE, COOLDOWN }
var _state: S = S.PATROL
var _timer := 0.0

func _init() -> void:
	max_hp = 22
	contact_damage = 14

func _ready() -> void:
	max_hp = 22
	contact_damage = 14
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	match _state:
		S.PATROL:
			if is_on_floor() and not _has_floor_ahead():
				_direction = -_direction
			velocity.x = PATROL * _direction
			var p := _player()
			if p != null:
				var off: Vector2 = p.global_position - global_position
				if absf(off.y) <= DETECT_Y and absf(off.x) <= DETECT_X and signf(off.x) == _direction:
					_state = S.CHARGE
					_timer = CHARGE_TIME
		S.CHARGE:
			velocity.x = CHARGE_SPEED * _direction
			_timer -= delta
			if _timer <= 0.0 or is_on_wall():
				_state = S.COOLDOWN
				_timer = COOLDOWN
		S.COOLDOWN:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_state = S.PATROL
	move_and_slide()
	if is_on_wall() and _state == S.PATROL:
		_direction = -_direction
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if (_invincible and int(Time.get_ticks_msec() / 80) % 2 == 0) else 1.0
	_advance_sprite_frame_loop(delta, FRAMES, FPS)

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
```

- [ ] **Step 2: Cena**

`characters/enemies/stage_01/enemy_molten_ram.tscn` (igual ao molde de Task 1, trocando script/tex/grade):
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_01/enemy_molten_ram.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_01/enemy_molten_ram.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 24.0
height = 84.0

[node name="EnemyMoltenRam" type="CharacterBody2D"]
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

- [ ] **Step 3: Verificar load headless** (como Task 1 Step 3, trocando o path). Expected `NO-ERRORS`.

- [ ] **Step 4: Commit**
```bash
git add characters/enemies/stage_01/enemy_molten_ram.gd characters/enemies/stage_01/enemy_molten_ram.tscn
git commit -m "feat(stage01): enemy_molten_ram (investida/charge)"
```

---

### Task 3: `enemy_ash_hopper` (saltador)

**Files:**
- Create: `characters/enemies/stage_01/enemy_ash_hopper.gd`
- Create: `characters/enemies/stage_01/enemy_ash_hopper.tscn`

- [ ] **Step 1: Script**

`characters/enemies/stage_01/enemy_ash_hopper.gd`:
```gdscript
extends EnemyBase
class_name EnemyAshHopper

const FRAMES := 6
const FPS := 10.0
const HOP_INTERVAL := 0.9
const HOP_VY := -460.0
const HOP_VX := 150.0

var _hop_timer := 0.6

func _init() -> void:
	max_hp = 7
	contact_damage = 7

func _ready() -> void:
	max_hp = 7
	contact_damage = 7
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor():
		if is_on_floor() and not _has_floor_ahead():
			_direction = -_direction
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			_hop_timer = HOP_INTERVAL
			velocity.y = HOP_VY
			velocity.x = HOP_VX * _direction
		else:
			velocity.x = 0.0
	move_and_slide()
	if is_on_wall():
		_direction = -_direction
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if (_invincible and int(Time.get_ticks_msec() / 80) % 2 == 0) else 1.0
	_advance_sprite_frame_loop(delta, FRAMES, FPS)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
```

- [ ] **Step 2: Cena**

`characters/enemies/stage_01/enemy_ash_hopper.tscn` (grade 3×2):
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_01/enemy_ash_hopper.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_01/enemy_ash_hopper.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 16.0
height = 60.0

[node name="EnemyAshHopper" type="CharacterBody2D"]
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
scale = Vector2(0.6, 0.6)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: Verificar load headless** (como Task 1 Step 3). Expected `NO-ERRORS`.

- [ ] **Step 4: Commit**
```bash
git add characters/enemies/stage_01/enemy_ash_hopper.gd characters/enemies/stage_01/enemy_ash_hopper.tscn
git commit -m "feat(stage01): enemy_ash_hopper (saltador)"
```

---

### Task 4: Teste do trio melee + PR 1

**Files:**
- Create: `tests/test_stage01_fire_enemies.gd`
- Create: `tests/test_stage01_fire_enemies.tscn`

- [ ] **Step 1: Teste**

`tests/test_stage01_fire_enemies.gd`:
```gdscript
extends Node

# Carrega cada cena de inimigo de fogo, confirma instanciação e frame inicial 0 (idle).
const MELEE := {
	"res://characters/enemies/stage_01/enemy_magma_grunt.tscn": "EnemyMagmaGrunt",
	"res://characters/enemies/stage_01/enemy_molten_ram.tscn": "EnemyMoltenRam",
	"res://characters/enemies/stage_01/enemy_ash_hopper.tscn": "EnemyAshHopper",
}

func _ready() -> void:
	var fail := false
	for path in MELEE:
		var scn = load(path)
		if scn == null:
			print("FAIL: não carregou ", path); fail = true; continue
		var e = scn.instantiate()
		add_child(e)
		var spr = e.get_node_or_null("Sprite2D")
		if spr == null:
			print("FAIL: sem Sprite2D em ", path); fail = true
		elif spr.frame != 0:
			print("FAIL: frame inicial != 0 em ", path, " (", spr.frame, ")"); fail = true
		else:
			print("OK: ", MELEE[path])
		e.free()
	if fail:
		get_tree().quit(1)
	else:
		print("PASS: melee fire enemies")
		get_tree().quit(0)
```

`tests/test_stage01_fire_enemies.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://tests/test_stage01_fire_enemies.gd" id="1"]

[node name="T" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Rodar o teste**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage01_fire_enemies.tscn`
Expected: `PASS: melee fire enemies`, exit 0.

- [ ] **Step 3: Commit + push + PR + merge**
```bash
git checkout -b feat/stage01-fire-melee
git add tests/test_stage01_fire_enemies.gd tests/test_stage01_fire_enemies.tscn
git commit -m "test(stage01): smoke do trio melee de fogo"
git push -u origin feat/stage01-fire-melee
gh pr create --base master --title "Stage 01: trio melee de fogo" --body "magma_grunt, molten_ram, ash_hopper + smoke test."
gh pr merge --merge
```

---

# FASE 2 — Trio fly (PR 2)

### Task 5: `enemy_flame_skimmer` (dive/retreat)

Mapeia direto ao ciclo do `EnemyFlyer`. Só ajusta stats, grade e parâmetros.

**Files:**
- Create: `characters/enemies/stage_01/enemy_flame_skimmer.gd`
- Create: `characters/enemies/stage_01/enemy_flame_skimmer.tscn`

- [ ] **Step 1: Script**

`characters/enemies/stage_01/enemy_flame_skimmer.gd`:
```gdscript
extends EnemyFlyer
class_name EnemyFlameSkimmer

func _ready() -> void:
	super._ready()
	max_hp = 9
	contact_damage = 10
	current_hp = max_hp
	dive_speed = 340.0
	retreat_speed = 170.0
	detect_radius = 260.0
	patrol_range = 180.0
```

- [ ] **Step 2: Cena**

`characters/enemies/stage_01/enemy_flame_skimmer.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_01/enemy_flame_skimmer.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_01/enemy_flame_skimmer.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 22.0
height = 70.0

[node name="EnemyFlameSkimmer" type="CharacterBody2D"]
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

Nota: `EnemyFlyer` anima com `_animate_sprite_frames(delta, 4, 8.0)` fixo. Para sheets com mais frames (skimmer 9), sobrescrever ao final do `_physics_process` não é necessário — o flyer usa 4 frames do ciclo; aceitável para leitura. (Se quiser todos os frames, ver Task 7 para o padrão de override de animação.)

- [ ] **Step 3: Verificar load headless** (como Task 1 Step 3). Expected `NO-ERRORS`.

- [ ] **Step 4: Commit**
```bash
git add characters/enemies/stage_01/enemy_flame_skimmer.gd characters/enemies/stage_01/enemy_flame_skimmer.tscn
git commit -m "feat(stage01): enemy_flame_skimmer (dive/retreat)"
```

---

### Task 6: `enemy_ember_orbiter` (hover + dispara fire_bolt)

**Files:**
- Create: `characters/enemies/stage_01/enemy_ember_orbiter.gd`
- Create: `characters/enemies/stage_01/enemy_ember_orbiter.tscn`

> Depende de `fire_projectile` (Task 9). Para manter a Fase 2 independente, o orbiter usa um preload condicional: se o projétil ainda não existir, o disparo é no-op. Após a Fase 3, o disparo passa a funcionar sem mudar o orbiter.

- [ ] **Step 1: Script**

`characters/enemies/stage_01/enemy_ember_orbiter.gd`:
```gdscript
extends EnemyFlyer
class_name EnemyEmberOrbiter

const FIRE_PROJECTILE_PATH := "res://characters/enemies/stage_01/fire_projectile.tscn"
const SHOOT_INTERVAL := 1.6
const SHOOT_RANGE := 480.0
const BOLT_SPEED := 320.0
const BOLT_DAMAGE := 6

var _shoot_timer := 0.8

func _ready() -> void:
	super._ready()
	max_hp = 8
	contact_damage = 6
	current_hp = max_hp
	dive_speed = 0.0          # orbiter não mergulha; fica em hover
	detect_radius = 0.0       # nunca entra em WINDUP/DIVE
	patrol_range = 120.0

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
	if not ResourceLoader.exists(FIRE_PROJECTILE_PATH):
		return
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var proj = load(FIRE_PROJECTILE_PATH).instantiate()
	proj.setup(dir * BOLT_SPEED, BOLT_DAMAGE, "ember_orbiter", 0.0, "fire_bolt")
	get_parent().add_child(proj)
	proj.global_position = global_position
```

- [ ] **Step 2: Cena**

`characters/enemies/stage_01/enemy_ember_orbiter.tscn` (grade 3×2):
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_01/enemy_ember_orbiter.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_01/enemy_ember_orbiter.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 18.0
height = 56.0

[node name="EnemyEmberOrbiter" type="CharacterBody2D"]
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
scale = Vector2(0.65, 0.65)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: Verificar load headless** (como Task 1 Step 3). Expected `NO-ERRORS`.

- [ ] **Step 4: Commit**
```bash
git add characters/enemies/stage_01/enemy_ember_orbiter.gd characters/enemies/stage_01/enemy_ember_orbiter.tscn
git commit -m "feat(stage01): enemy_ember_orbiter (hover + fire_bolt, disparo no-op até a Fase 3)"
```

---

### Task 7: `enemy_cinder_flyer` (patrulha aérea de assédio)

**Files:**
- Create: `characters/enemies/stage_01/enemy_cinder_flyer.gd`
- Create: `characters/enemies/stage_01/enemy_cinder_flyer.tscn`

- [ ] **Step 1: Script** (hover patrulhando, sem dive; assédio via contato)

`characters/enemies/stage_01/enemy_cinder_flyer.gd`:
```gdscript
extends EnemyFlyer
class_name EnemyCinderFlyer

func _ready() -> void:
	super._ready()
	max_hp = 8
	contact_damage = 7
	current_hp = max_hp
	detect_radius = 220.0
	dive_speed = 300.0
	retreat_speed = 160.0
	patrol_range = 220.0
	bob_amplitude = 10.0
```

- [ ] **Step 2: Cena**

`characters/enemies/stage_01/enemy_cinder_flyer.tscn` (grade 2×2):
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_01/enemy_cinder_flyer.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_01/enemy_cinder_flyer.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 18.0
height = 56.0

[node name="EnemyCinderFlyer" type="CharacterBody2D"]
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
scale = Vector2(0.65, 0.65)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: Verificar load headless** (como Task 1 Step 3). Expected `NO-ERRORS`.

- [ ] **Step 4: Commit**
```bash
git add characters/enemies/stage_01/enemy_cinder_flyer.gd characters/enemies/stage_01/enemy_cinder_flyer.tscn
git commit -m "feat(stage01): enemy_cinder_flyer (patrulha aérea)"
```

---

### Task 8: Estender teste com o trio fly + PR 2

**Files:**
- Modify: `tests/test_stage01_fire_enemies.gd`

- [ ] **Step 1: Adicionar voadores ao dicionário**

Em `tests/test_stage01_fire_enemies.gd`, trocar a constante `MELEE` por `ENEMIES` cobrindo melee + fly e atualizar o loop/mensagem:
```gdscript
const ENEMIES := {
	"res://characters/enemies/stage_01/enemy_magma_grunt.tscn": "EnemyMagmaGrunt",
	"res://characters/enemies/stage_01/enemy_molten_ram.tscn": "EnemyMoltenRam",
	"res://characters/enemies/stage_01/enemy_ash_hopper.tscn": "EnemyAshHopper",
	"res://characters/enemies/stage_01/enemy_flame_skimmer.tscn": "EnemyFlameSkimmer",
	"res://characters/enemies/stage_01/enemy_ember_orbiter.tscn": "EnemyEmberOrbiter",
	"res://characters/enemies/stage_01/enemy_cinder_flyer.tscn": "EnemyCinderFlyer",
}
```
Trocar `for path in MELEE:` → `for path in ENEMIES:`, `MELEE[path]` → `ENEMIES[path]`, e a mensagem final para `print("PASS: melee+fly fire enemies")`.

- [ ] **Step 2: Rodar o teste**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage01_fire_enemies.tscn`
Expected: `PASS: melee+fly fire enemies`, exit 0.

- [ ] **Step 3: Commit + PR + merge**
```bash
git checkout -b feat/stage01-fire-fly
git add characters/enemies/stage_01/enemy_flame_skimmer.* characters/enemies/stage_01/enemy_ember_orbiter.* characters/enemies/stage_01/enemy_cinder_flyer.* tests/test_stage01_fire_enemies.gd
git commit -m "feat(stage01): trio fly de fogo (skimmer, orbiter, cinder_flyer)"
git push -u origin feat/stage01-fire-fly
gh pr create --base master --title "Stage 01: trio fly de fogo" --body "flame_skimmer, ember_orbiter, cinder_flyer + smoke test estendido."
gh pr merge --merge
```

---

# FASE 3 — Trio ranged + projétil (PR 3)

### Task 9: `fire_projectile` compartilhado

**Files:**
- Create: `characters/enemies/stage_01/fire_projectile.gd`
- Create: `characters/enemies/stage_01/fire_projectile.tscn`

- [ ] **Step 1: Script** (molde de `enemy_ice_projectile`, com `Sprite2D` texturizado por variante)

`characters/enemies/stage_01/fire_projectile.gd`:
```gdscript
extends Area2D
class_name FireProjectile

const TEX := {
	"fire_bolt": "res://characters/enemies/stage_01/fire_bolt.png",
	"fire_glob": "res://characters/enemies/stage_01/fire_glob.png",
	"fire_spit": "res://characters/enemies/stage_01/fire_spit.png",
	"heat_mortar_shell": "res://characters/enemies/stage_01/heat_mortar_shell.png",
}

var projectile_velocity: Vector2 = Vector2(300.0, 0.0)
var damage: int = 6
var source_id: String = "stage01_fire"
var variant: String = "fire_bolt"
var _lifetime: float = 4.0
var _hit := false
var _anim_timer := 0.0
var _frame := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_enemy_shoot)

func setup(velocity_value: Vector2, damage_value: int, source_value := "stage01_fire",
		gravity_value := 0.0, variant_value := "fire_bolt") -> void:
	projectile_velocity = velocity_value
	damage = damage_value
	source_id = source_value
	gravity = gravity_value
	variant = variant_value
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null and TEX.has(variant):
		spr.texture = load(TEX[variant])
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

- [ ] **Step 2: Cena**

`characters/enemies/stage_01/fire_projectile.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_01/fire_projectile.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_01/fire_bolt.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="C_1"]
radius = 12.0

[node name="FireProjectile" type="Area2D"]
collision_layer = 0
collision_mask = 2
script = ExtResource("1_script")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 2
vframes = 2
frame = 0
scale = Vector2(0.35, 0.35)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("C_1")
```

- [ ] **Step 3: Teste isolado do projétil**

Adicionar ao fim de `_ready` de `tests/test_stage01_fire_enemies.gd` (antes do `if fail:`), um bloco que instancia o projétil e confirma setup:
```gdscript
	var proj = load("res://characters/enemies/stage_01/fire_projectile.tscn").instantiate()
	add_child(proj)
	proj.setup(Vector2(200, 0), 5, "test", 0.0, "fire_glob")
	if proj.damage != 5 or proj.variant != "fire_glob":
		print("FAIL: fire_projectile.setup"); fail = true
	else:
		print("OK: fire_projectile")
	proj.free()
```

- [ ] **Step 4: Rodar** (como Task 4 Step 2). Expected: ainda `PASS`, com `OK: fire_projectile`.

- [ ] **Step 5: Commit**
```bash
git add characters/enemies/stage_01/fire_projectile.gd characters/enemies/stage_01/fire_projectile.tscn tests/test_stage01_fire_enemies.gd
git commit -m "feat(stage01): fire_projectile compartilhado (textura por variante + gravity)"
```

---

### Task 10: `enemy_heat_mortar` (tiro parabólico)

**Files:**
- Create: `characters/enemies/stage_01/enemy_heat_mortar.gd`
- Create: `characters/enemies/stage_01/enemy_heat_mortar.tscn`

- [ ] **Step 1: Script** (molde de `enemy_ice_archer`, com gravity no projétil)

`characters/enemies/stage_01/enemy_heat_mortar.gd`:
```gdscript
extends EnemyBase
class_name EnemyHeatMortar

const _PROJ := preload("res://characters/enemies/stage_01/fire_projectile.tscn")
const FRAMES := 6
const FPS := 10.0
const RELEASE_FRAME := 4
const SHOOT_RANGE := 620.0
const SHOOT_INTERVAL := 1.8
const SHELL_SPEED := 360.0
const SHELL_GRAVITY := 520.0
const SHELL_DAMAGE := 9

var _shoot_timer := 0.5
var _shot_active := false
var _shot_frame := 0
var _shot_frame_timer := 0.0
var _released := false

func _init() -> void:
	max_hp = 14
	contact_damage = 9

func _ready() -> void:
	max_hp = 14
	contact_damage = 9
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	_shoot_timer -= delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if not _shot_active and p != null:
		var off: Vector2 = p.global_position - global_position
		if absf(off.x) <= SHOOT_RANGE:
			_direction = signf(off.x) if off.x != 0.0 else _direction
			if _shoot_timer <= 0.0:
				_shot_active = true
				_shot_frame = 0
				_shot_frame_timer = 0.0
				_released = false
				_set_sprite_frame(0)
	_tick_shot(delta)
	move_and_slide()
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if (_invincible and int(Time.get_ticks_msec() / 80) % 2 == 0) else 1.0

func _tick_shot(delta: float) -> void:
	if not _shot_active:
		return
	_shot_frame_timer += delta
	var dur := 1.0 / FPS
	while _shot_frame_timer >= dur:
		_shot_frame_timer -= dur
		_shot_frame += 1
		if _shot_frame == RELEASE_FRAME and not _released:
			_fire()
			_released = true
		if _shot_frame >= FRAMES:
			_shot_active = false
			_shoot_timer = SHOOT_INTERVAL
			_shot_frame = 0
		_set_sprite_frame(_shot_frame % FRAMES)

func _fire() -> void:
	var proj = _PROJ.instantiate()
	proj.setup(Vector2(_direction * SHELL_SPEED, -380.0), SHELL_DAMAGE, "heat_mortar", SHELL_GRAVITY, "heat_mortar_shell")
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(_direction * 30.0, -30.0)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
```

- [ ] **Step 2: Cena**

`characters/enemies/stage_01/enemy_heat_mortar.tscn` (grade 3×2):
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_01/enemy_heat_mortar.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_01/enemy_heat_mortar.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 22.0
height = 76.0

[node name="EnemyHeatMortar" type="CharacterBody2D"]
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

- [ ] **Step 3: Verificar load headless** (como Task 1 Step 3). Expected `NO-ERRORS`.

- [ ] **Step 4: Commit**
```bash
git add characters/enemies/stage_01/enemy_heat_mortar.gd characters/enemies/stage_01/enemy_heat_mortar.tscn
git commit -m "feat(stage01): enemy_heat_mortar (tiro parabólico)"
```

---

### Task 11: `enemy_magma_turret` (estacionária)

**Files:**
- Create: `characters/enemies/stage_01/enemy_magma_turret.gd`
- Create: `characters/enemies/stage_01/enemy_magma_turret.tscn`

- [ ] **Step 1: Script** (não vira, dispara fire_glob horizontal)

`characters/enemies/stage_01/enemy_magma_turret.gd`:
```gdscript
extends EnemyBase
class_name EnemyMagmaTurret

const _PROJ := preload("res://characters/enemies/stage_01/fire_projectile.tscn")
const FRAMES := 4
const FPS := 8.0
const SHOOT_RANGE := 560.0
const AIM_Y := 120.0
const SHOOT_INTERVAL := 1.4
const GLOB_SPEED := 300.0
const GLOB_DAMAGE := 9

@export var face_dir: float = -1.0   # turret não vira; define o lado no posicionamento
var _shoot_timer := 0.4

func _init() -> void:
	max_hp = 18
	contact_damage = 9

func _ready() -> void:
	max_hp = 18
	contact_damage = 9
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
	var proj = _PROJ.instantiate()
	proj.setup(Vector2(_direction * GLOB_SPEED, 0.0), GLOB_DAMAGE, "magma_turret", 0.0, "fire_glob")
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(_direction * 28.0, -8.0)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
```

- [ ] **Step 2: Cena**

`characters/enemies/stage_01/enemy_magma_turret.tscn` (grade 2×2):
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_01/enemy_magma_turret.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_01/enemy_magma_turret.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 24.0
height = 72.0

[node name="EnemyMagmaTurret" type="CharacterBody2D"]
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
scale = Vector2(0.7, 0.7)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: Verificar load headless** (como Task 1 Step 3). Expected `NO-ERRORS`.

- [ ] **Step 4: Commit**
```bash
git add characters/enemies/stage_01/enemy_magma_turret.gd characters/enemies/stage_01/enemy_magma_turret.tscn
git commit -m "feat(stage01): enemy_magma_turret (estacionária, fire_glob)"
```

---

### Task 12: `enemy_lava_serpent` (ciclo emergir/cuspir)

**Files:**
- Create: `characters/enemies/stage_01/enemy_lava_serpent.gd`
- Create: `characters/enemies/stage_01/enemy_lava_serpent.tscn`

- [ ] **Step 1: Script** (máquina de estados; invulnerável submersa)

`characters/enemies/stage_01/enemy_lava_serpent.gd`:
```gdscript
extends EnemyBase
class_name EnemyLavaSerpent

const _PROJ := preload("res://characters/enemies/stage_01/fire_projectile.tscn")
const FRAMES := 16
const FPS := 10.0
const RISE := 140.0           # px que sobe ao emergir
const T_SUBMERGED := 1.6
const T_EMERGE := 0.7
const T_EXPOSED := 1.2
const T_SUBMERGE := 0.6
const SPIT_SPEED := 320.0
const SPIT_DAMAGE := 8

enum S { SUBMERGED, EMERGING, EXPOSED, SPIT, SUBMERGING }
var _state: S = S.SUBMERGED
var _timer := T_SUBMERGED
var _base_y := 0.0
var _spat := false

func _init() -> void:
	max_hp = 14
	contact_damage = 11

func _ready() -> void:
	max_hp = 14
	contact_damage = 11
	super._ready()
	_base_y = global_position.y
	_enter(S.SUBMERGED)

func _enter(s: S) -> void:
	_state = s
	match s:
		S.SUBMERGED:
			_timer = T_SUBMERGED
			_invincible = true
			global_position.y = _base_y
			_set_visible_contact(false)
		S.EMERGING:
			_timer = T_EMERGE
		S.EXPOSED:
			_timer = T_EXPOSED
			_invincible = false
			_set_visible_contact(true)
		S.SPIT:
			_spat = false
		S.SUBMERGING:
			_timer = T_SUBMERGE

func _set_visible_contact(on: bool) -> void:
	visible = on
	var cz := get_node_or_null("ContactZone") as Area2D
	if cz != null:
		cz.monitoring = on
		cz.monitorable = on

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_timer -= delta
	match _state:
		S.SUBMERGED:
			if _timer <= 0.0:
				visible = true
				_enter(S.EMERGING)
		S.EMERGING:
			var t: float = clampf(1.0 - _timer / T_EMERGE, 0.0, 1.0)
			global_position.y = _base_y - RISE * t
			if _timer <= 0.0:
				_enter(S.EXPOSED)
		S.EXPOSED:
			if _timer <= 0.0:
				_enter(S.SPIT)
		S.SPIT:
			if not _spat:
				_spat = true
				_fire()
				_timer = 0.4
			elif _timer <= 0.0:
				_enter(S.SUBMERGING)
		S.SUBMERGING:
			var t2: float = clampf(_timer / T_SUBMERGE, 0.0, 1.0)
			global_position.y = _base_y - RISE * t2
			if _timer <= 0.0:
				_enter(S.SUBMERGED)
	if _state in [S.EMERGING, S.EXPOSED, S.SPIT, S.SUBMERGING]:
		_advance_sprite_frame_loop(delta, FRAMES, FPS)

func _fire() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var dir := Vector2(_direction, -0.2)
	if p != null:
		dir = (p.global_position - global_position).normalized()
	var proj = _PROJ.instantiate()
	proj.setup(dir * SPIT_SPEED, SPIT_DAMAGE, "lava_serpent", 0.0, "fire_spit")
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(0.0, -20.0)

func take_damage(amount: int, source: String = "") -> void:
	if _state == S.SUBMERGED:
		return   # invulnerável submersa
	super.take_damage(amount, source)
```

- [ ] **Step 2: Cena**

`characters/enemies/stage_01/enemy_lava_serpent.tscn` (grade 4×4):
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_01/enemy_lava_serpent.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_01/enemy_lava_serpent.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 26.0
height = 96.0

[node name="EnemyLavaSerpent" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 4
vframes = 4
frame = 0
scale = Vector2(0.9, 0.9)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: Verificar load headless** (como Task 1 Step 3). Expected `NO-ERRORS`.

- [ ] **Step 4: Commit**
```bash
git add characters/enemies/stage_01/enemy_lava_serpent.gd characters/enemies/stage_01/enemy_lava_serpent.tscn
git commit -m "feat(stage01): enemy_lava_serpent (ciclo emergir/cuspir, invuln submersa)"
```

---

### Task 13: Estender teste com ranged + PR 3

**Files:**
- Modify: `tests/test_stage01_fire_enemies.gd`

- [ ] **Step 1: Adicionar ranged ao dicionário e checar serpente submersa**

Em `ENEMIES`, adicionar:
```gdscript
	"res://characters/enemies/stage_01/enemy_heat_mortar.tscn": "EnemyHeatMortar",
	"res://characters/enemies/stage_01/enemy_magma_turret.tscn": "EnemyMagmaTurret",
	"res://characters/enemies/stage_01/enemy_lava_serpent.tscn": "EnemyLavaSerpent",
```
A serpente começa submersa (`visible == false` após `_ready`) e frame 0. Trocar a checagem de frame para tolerar a serpente invisível:
```gdscript
		elif spr.frame != 0:
			print("FAIL: frame inicial != 0 em ", path, " (", spr.frame, ")"); fail = true
```
(continua válido — a serpente mantém frame 0 no estado SUBMERGED).
Atualizar a mensagem final para `print("PASS: all fire enemies")`.

- [ ] **Step 2: Rodar** (como Task 4 Step 2). Expected: `PASS: all fire enemies`, exit 0.

- [ ] **Step 3: Commit + PR + merge**
```bash
git checkout -b feat/stage01-fire-ranged
git add characters/enemies/stage_01/fire_projectile.* characters/enemies/stage_01/enemy_heat_mortar.* characters/enemies/stage_01/enemy_magma_turret.* characters/enemies/stage_01/enemy_lava_serpent.* tests/test_stage01_fire_enemies.gd
git commit -m "feat(stage01): trio ranged de fogo (heat_mortar, magma_turret, lava_serpent) + fire_projectile"
git push -u origin feat/stage01-fire-ranged
gh pr create --base master --title "Stage 01: trio ranged de fogo + projétil" --body "heat_mortar (parabólico), magma_turret (estacionária), lava_serpent (emerge) + fire_projectile compartilhado."
gh pr merge --merge
```

---

# FASE 4 — Wiring no stage 01 (PR 4)

### Task 14: Posicionar o roster (~43) nas zonas

**Files:**
- Modify: `stages/stage_01/stage_01.tscn` (remover placements genéricas da Z1)
- Modify: `stages/stage_01/stage_01_scene.gd` (spawnar o roster por script)

- [ ] **Step 1: Remover placements genéricas antigas da Z1**

Em `stages/stage_01/stage_01.tscn`, remover os nós `Grunt2`, `Grunt3`, `Flyer1` (instâncias do enemy_base/flyer genéricos). As de Z2/Z3/Z4 já são removidas em runtime pelo `_ready`.

- [ ] **Step 2: Consts de cena + helper de spawn**

No topo de `stages/stage_01/stage_01_scene.gd` (após os preloads existentes), adicionar:
```gdscript
const _FIRE := {
	"grunt":   preload("res://characters/enemies/stage_01/enemy_magma_grunt.tscn"),
	"ram":     preload("res://characters/enemies/stage_01/enemy_molten_ram.tscn"),
	"hopper":  preload("res://characters/enemies/stage_01/enemy_ash_hopper.tscn"),
	"orbiter": preload("res://characters/enemies/stage_01/enemy_ember_orbiter.tscn"),
	"skimmer": preload("res://characters/enemies/stage_01/enemy_flame_skimmer.tscn"),
	"cinder":  preload("res://characters/enemies/stage_01/enemy_cinder_flyer.tscn"),
	"mortar":  preload("res://characters/enemies/stage_01/enemy_heat_mortar.tscn"),
	"turret":  preload("res://characters/enemies/stage_01/enemy_magma_turret.tscn"),
	"serpent": preload("res://characters/enemies/stage_01/enemy_lava_serpent.tscn"),
}
```
E um helper (junto dos outros helpers de spawn, ex.: perto de `_z4_spawn_flyer`):
```gdscript
func _spawn_fire(kind: String, n: String, pos: Vector2) -> Node2D:
	if DebugBoot.no_enemies:
		return null
	var old := get_node_or_null(n)
	if old:
		old.free()
	var e: Node2D = _FIRE[kind].instantiate()
	e.name = n
	e.position = pos
	add_child(e)
	return e
```

- [ ] **Step 3: Spawnar o roster por zona**

Adicionar `_spawn_fire_roster()` e chamá-lo no fim de `_ready` (após `_build_zone4()` e o loop de corredores):
```gdscript
func _spawn_fire_roster() -> void:
	# Z1 — início (10)
	_spawn_fire("grunt", "F_Z1Grunt1", Vector2(1500, 2520))
	_spawn_fire("grunt", "F_Z1Grunt2", Vector2(2100, 2520))
	_spawn_fire("grunt", "F_Z1Grunt3", Vector2(2700, 2520))
	_spawn_fire("grunt", "F_Z1Grunt4", Vector2(3300, 2520))
	_spawn_fire("hopper", "F_Z1Hop1", Vector2(1800, 2520))
	_spawn_fire("hopper", "F_Z1Hop2", Vector2(2400, 2520))
	_spawn_fire("hopper", "F_Z1Hop3", Vector2(3000, 2520))
	_spawn_fire("cinder", "F_Z1Cin1", Vector2(2000, 2300))
	_spawn_fire("cinder", "F_Z1Cin2", Vector2(2600, 2280))
	_spawn_fire("cinder", "F_Z1Cin3", Vector2(3200, 2300))
	# Z2 — Rio de Lava (11)
	_spawn_fire("ram", "F_Z2Ram1", Vector2(4200, 2440))
	_spawn_fire("ram", "F_Z2Ram2", Vector2(5200, 2440))
	_spawn_fire("ram", "F_Z2Ram3", Vector2(6200, 2440))
	_spawn_fire("turret", "F_Z2Tur1", Vector2(4600, 2440))
	_spawn_fire("turret", "F_Z2Tur2", Vector2(5600, 2440))
	_spawn_fire("turret", "F_Z2Tur3", Vector2(6600, 2440))
	_spawn_fire("orbiter", "F_Z2Orb1", Vector2(4800, 2200))
	_spawn_fire("orbiter", "F_Z2Orb2", Vector2(5800, 2200))
	_spawn_fire("orbiter", "F_Z2Orb3", Vector2(6800, 2200))
	_spawn_fire("serpent", "F_Z2Ser1", Vector2(5000, 2560))
	_spawn_fire("serpent", "F_Z2Ser2", Vector2(6000, 2560))
	# Z3 — maré (11)
	_spawn_fire("mortar", "F_Z3Mor1", Vector2(11200, 2480))
	_spawn_fire("mortar", "F_Z3Mor2", Vector2(12200, 2480))
	_spawn_fire("mortar", "F_Z3Mor3", Vector2(13200, 2480))
	_spawn_fire("skimmer", "F_Z3Ski1", Vector2(11600, 2250))
	_spawn_fire("skimmer", "F_Z3Ski2", Vector2(12600, 2250))
	_spawn_fire("skimmer", "F_Z3Ski3", Vector2(13600, 2250))
	_spawn_fire("hopper", "F_Z3Hop1", Vector2(11400, 2480))
	_spawn_fire("hopper", "F_Z3Hop2", Vector2(12400, 2480))
	_spawn_fire("hopper", "F_Z3Hop3", Vector2(13400, 2480))
	_spawn_fire("serpent", "F_Z3Ser1", Vector2(11800, 2560))
	_spawn_fire("serpent", "F_Z3Ser2", Vector2(12800, 2560))
	# Z4 — shaft (11)
	_spawn_fire("cinder", "F_Z4Cin1", Vector2(17520, 1900))
	_spawn_fire("cinder", "F_Z4Cin2", Vector2(17520, 1400))
	_spawn_fire("cinder", "F_Z4Cin3", Vector2(17520, 900))
	_spawn_fire("orbiter", "F_Z4Orb1", Vector2(17520, 1700))
	_spawn_fire("orbiter", "F_Z4Orb2", Vector2(17520, 1200))
	_spawn_fire("orbiter", "F_Z4Orb3", Vector2(17520, 700))
	_spawn_fire("grunt", "F_Z4Grunt1", Vector2(16320, 2620))
	_spawn_fire("grunt", "F_Z4Grunt2", Vector2(17892, 320))
	_spawn_fire("grunt", "F_Z4Grunt3", Vector2(16940, 320))
	_spawn_fire("skimmer", "F_Z4Ski1", Vector2(17520, 1100))
	_spawn_fire("skimmer", "F_Z4Ski2", Vector2(17520, 600))
```
Chamar no `_ready` (após o loop de corredores):
```gdscript
	_spawn_fire_roster()
```
Nota: as coordenadas são alvo inicial. Conferir cada uma contra o SVG de zona (`docs/stage_01/zones/*.svg`) e ajustar para o inimigo nascer sobre piso sólido (terrestres) ou sobre o poço de lava (serpentes), não dentro de parede nem sobre abismo. Serpente: o `_base_y` é a superfície da lava na coluna.

- [ ] **Step 4: Verificar carga headless**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://stages/stage_01/stage_01.tscn --quit-after 3 2>&1 | grep -iE "SCRIPT ERROR|Parse Error" || echo NO-ERRORS`
Expected: `NO-ERRORS`.

- [ ] **Step 5: Commit**
```bash
git add stages/stage_01/stage_01.tscn stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01): wiring do roster de fogo (~43 inimigos) nas zonas"
```

---

### Task 15: Validação completa + SVG + bot + web export + PR 4

**Files:**
- Modify se necessário: `docs/stage_01/zones/*` (regen)

- [ ] **Step 1: Rodar suíte de testes da fase**
```bash
GODOT="D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe"
for t in test_stage01_fire_enemies test_no_enemies test_stage01_hazards; do
  echo -n "$t: "; "$GODOT" --headless --path . res://tests/$t.tscn 2>&1 | grep -iE "PASS|FAIL|ALL TESTS" | head -1
done
```
Expected: todos PASS.

- [ ] **Step 2: Regenerar SVG da fase (conferir posições)**
```bash
"$GODOT" --headless --path . res://tools/zone_debug_01.tscn -- --area=all 2>&1 | grep -iE "svg|concluído|ERROR" | grep -v "still in use"
```
Abrir `docs/stage_01/zones/*.svg`; ajustar coordenadas em `_spawn_fire_roster` que caírem dentro de parede/abismo e re-rodar.

- [ ] **Step 3: Smoke do bot**

Run: `"$GODOT" --headless --path . res://stages/stage_01/stage_01.tscn -- stage=1 bot=1 noenemies=0 2>&1 | grep -iE "SCRIPT ERROR|BOT_" | head -20`
Expected: sem `SCRIPT ERROR`; bot dá boot (`BOT_START`) e progride. Se algum inimigo travar a traversa, ajustar posição.

- [ ] **Step 4: Web export + reiniciar localhost** (skill `web-export`)
```bash
"$GODOT" --headless --path . --export-release "Web" "export/web/index.html" 2>&1 | tail -2
powershell -Command "Get-Item 'D:\SnesGame\export\web\index.pck' | Select-Object LastWriteTime, Length"
```
Expected: `index.pck` com `LastWriteTime` recente.

- [ ] **Step 5: Commit + PR + merge**
```bash
git checkout -b feat/stage01-fire-wiring
git add stages/stage_01/stage_01.tscn stages/stage_01/stage_01_scene.gd docs/stage_01/zones/ 
git add -f export/web/
git commit -m "feat(stage01): roster de fogo posicionado + SVG + web export"
git push -u origin feat/stage01-fire-wiring
gh pr create --base master --title "Stage 01: wiring do roster de fogo" --body "Posiciona ~43 inimigos de fogo pelas 4 zonas + SVG regen + web export."
gh pr merge --merge
```

---

## Self-review (cobertura do spec)

- Arquitetura (reuso stage 02, EnemyBase/EnemyFlyer, projétil compartilhado) → Tasks 1–13.
- 9 inimigos com AI distinta → Tasks 1–3 (melee), 5–7 (fly), 10–12 (ranged).
- Serpente de lava (ciclo + invuln submersa) → Task 12.
- Projétil compartilhado (textura por variante + gravity parabólico) → Task 9; mapeamento → Tasks 6/10/11/12.
- Posicionamento ~43 (densidade pesada) → Task 14.
- Testes (load + frame idle) → Tasks 4/8/13; suíte de fase + bot + web export → Task 15.
- Entrega em 4 PRs por trio → Fases 1–4.

**Pontos a confirmar na implementação (grep/SVG antes de finalizar):** coordenadas de `_spawn_fire_roster` contra `docs/stage_01/zones/*.svg` (piso sólido / poço de lava / sem parede/abismo); o `_base_y` da serpente = superfície da lava; e se `DebugBoot.no_enemies` é o flag correto (grep no `stage_scene.gd`).
