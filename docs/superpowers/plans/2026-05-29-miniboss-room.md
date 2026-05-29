# Miniboss Room — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar sala selada 640×256px logo após o corredor CP1 do Stage 00, com um MiniBoss (PATROL/CHARGE/STOMP/RECOVER) e shockwave no stomp.

**Architecture:** A sala usa StaticBody2D nodes adicionados no `.tscn`; o script `stage_00_scene.gd` gerencia o trigger de entrada, o seal/unseal via collision toggle e o spawn do MiniBoss. O MiniBoss e o ShockwaveEffect são cenas independentes instanciadas dinamicamente.

**Tech Stack:** Godot 4.6.2, GDScript, `extends EnemyBase`, `extends Area2D`

---

### Task 1: Shockwave Effect

**Files:**
- Create: `effects/shockwave_effect.gd`
- Create: `effects/shockwave_effect.tscn`

- [ ] **Step 1: Criar `effects/shockwave_effect.gd`**

```gdscript
# effects/shockwave_effect.gd
extends Area2D

@export var damage: int = 3

var _alpha: float = 1.0

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 2
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(0.4).timeout.connect(queue_free)

func _process(delta: float) -> void:
	_alpha = max(0.0, _alpha - delta * 2.5)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-150.0, -24.0, 300.0, 48.0), Color(1.0, 0.6, 0.0, _alpha * 0.4))

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
```

- [ ] **Step 2: Criar `effects/shockwave_effect.tscn`**

```
[gd_scene format=3 uid="uid://shockwave_effect"]

[ext_resource type="Script" path="res://effects/shockwave_effect.gd" id="1_script"]

[sub_resource type="RectangleShape2D" id="shape_sw"]
size = Vector2(300, 48)

[node name="ShockwaveEffect" type="Area2D"]
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("shape_sw")
```

- [ ] **Step 3: Commit**

```bash
git add effects/shockwave_effect.gd effects/shockwave_effect.tscn
git commit -m "feat: shockwave_effect — Area2D 300x48px, damage=3, fade 0.4s"
```

---

### Task 2: EnemyMiniBoss Script

**Files:**
- Create: `characters/enemies/enemy_miniboss.gd`

- [ ] **Step 1: Criar `characters/enemies/enemy_miniboss.gd`**

```gdscript
# characters/enemies/enemy_miniboss.gd
extends EnemyBase
class_name EnemyMiniBoss

const _SHOCKWAVE_SCENE := preload("res://effects/shockwave_effect.tscn")

enum State { PATROL, CHARGE, STOMP, RECOVER }

const MINI_PATROL_SPEED := 50.0
const CHARGE_SPEED      := 220.0
const CHARGE_DURATION   := 0.5
const CHARGE_DIST       := 300.0
const STOMP_IMPULSE     := -400.0
const RECOVER_TIME      := 0.6
const STOMP_COOLDOWN    := 4.0
const FEET_OFFSET_Y     := 60.0

var _state        : State = State.PATROL
var _state_timer  : float = 0.0
var _stomp_cd     : float = 0.0
var _was_airborne : bool  = false

func _ready() -> void:
	max_hp         = 18
	contact_damage = 3
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_stomp_cd = max(0.0, _stomp_cd - delta)

	match _state:
		State.PATROL:  _tick_patrol(delta)
		State.CHARGE:  _tick_charge(delta)
		State.STOMP:   _tick_stomp()
		State.RECOVER: _tick_recover(delta)

	move_and_slide()

	if _was_airborne and is_on_floor() and _state == State.STOMP:
		_on_stomp_land()
	_was_airborne = not is_on_floor()

	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0.0
	if _invincible:
		_sprite.modulate.a = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _tick_patrol(delta: float) -> void:
	var player := _get_player()
	if player == null:
		velocity.x = MINI_PATROL_SPEED * _direction
		return
	var dx: float = player.global_position.x - global_position.x
	_direction = sign(dx) if dx != 0.0 else _direction
	velocity.x = MINI_PATROL_SPEED * _direction
	if abs(dx) <= CHARGE_DIST:
		_state_timer = CHARGE_DURATION
		_state       = State.CHARGE
	elif _stomp_cd <= 0.0:
		velocity.y = STOMP_IMPULSE
		_state      = State.STOMP

func _tick_charge(delta: float) -> void:
	_state_timer -= delta
	velocity.x = CHARGE_SPEED * _direction
	if _state_timer <= 0.0:
		velocity.x = 0.0
		velocity.y = STOMP_IMPULSE
		_state      = State.STOMP

func _tick_stomp() -> void:
	pass

func _on_stomp_land() -> void:
	_stomp_cd    = STOMP_COOLDOWN
	velocity     = Vector2.ZERO
	_state_timer = RECOVER_TIME
	_state       = State.RECOVER
	var sw := _SHOCKWAVE_SCENE.instantiate() as Node2D
	sw.global_position = Vector2(global_position.x, global_position.y + FEET_OFFSET_Y)
	get_parent().add_child(sw)

func _tick_recover(delta: float) -> void:
	velocity.x   = 0.0
	_state_timer -= delta
	if _state_timer <= 0.0:
		_state = State.PATROL
```

- [ ] **Step 2: Commit**

```bash
git add characters/enemies/enemy_miniboss.gd
git commit -m "feat: enemy_miniboss — PATROL/CHARGE/STOMP/RECOVER state machine"
```

---

### Task 3: EnemyMiniBoss Scene

**Files:**
- Create: `characters/enemies/enemy_miniboss.tscn`

- [ ] **Step 1: Criar `characters/enemies/enemy_miniboss.tscn`**

```
[gd_scene format=3 uid="uid://enemy_miniboss"]

[ext_resource type="Script" path="res://characters/enemies/enemy_miniboss.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/GruntCorrendo.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="shape_miniboss"]
radius = 28.0
height = 96.0

[node name="EnemyMiniBoss" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("shape_miniboss")

[node name="Sprite2D" type="Sprite2D" parent="."]
position = Vector2(0, -8)
texture = ExtResource("2_tex")
hframes = 6
vframes = 1
scale = Vector2(3, 3)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("shape_miniboss")
```

- [ ] **Step 2: Commit**

```bash
git add characters/enemies/enemy_miniboss.tscn
git commit -m "feat: enemy_miniboss.tscn — CharacterBody2D, capsule 28/96, scale 3x"
```

---

### Task 4: Geometria da Sala no stage_00.tscn

**Files:**
- Modify: `stages/stage_00/stage_00.tscn`

- [ ] **Step 1: Adicionar sub_resources das shapes (após `shape_StepUp3`, antes do primeiro `[node`)** 

Encontrar a linha `size = Vector2(128, 64)` do `shape_StepUp3` e adicionar logo depois:

```
[sub_resource type="RectangleShape2D" id="shape_MiniBossFloor"]
size = Vector2(640, 64)

[sub_resource type="RectangleShape2D" id="shape_MiniBossCeil"]
size = Vector2(640, 64)

[sub_resource type="RectangleShape2D" id="shape_MiniBossRWall"]
size = Vector2(64, 384)
```

- [ ] **Step 2: Adicionar nós da sala (após o nó `Corr1_Wall_R` e seu filho)**

Encontrar o bloco:
```
[node name="Corr1_Wall_R" type="StaticBody2D" parent="."]
position = Vector2(6430, 1024)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Corr1_Wall_R"]
shape = SubResource("shape_Corr1WallR")
```

E adicionar depois:

```
[node name="MiniBoss_Floor" type="StaticBody2D" parent="."]
position = Vector2(6750, 1120)

[node name="CollisionShape2D" type="CollisionShape2D" parent="MiniBoss_Floor"]
shape = SubResource("shape_MiniBossFloor")

[node name="MiniBoss_Ceil" type="StaticBody2D" parent="."]
position = Vector2(6750, 800)

[node name="CollisionShape2D" type="CollisionShape2D" parent="MiniBoss_Ceil"]
shape = SubResource("shape_MiniBossCeil")

[node name="MiniBoss_RWall" type="StaticBody2D" parent="."]
position = Vector2(7070, 960)

[node name="CollisionShape2D" type="CollisionShape2D" parent="MiniBoss_RWall"]
shape = SubResource("shape_MiniBossRWall")
```

- [ ] **Step 3: Commit**

```bash
git add stages/stage_00/stage_00.tscn
git commit -m "feat: stage_00 — geometria sala miniboss (Floor/Ceil/RWall)"
```

---

### Task 5: stage_00_scene.gd — Trigger, Seal e Spawn

**Files:**
- Modify: `stages/stage_00/stage_00_scene.gd`

- [ ] **Step 1: Adicionar preload e variáveis de estado do MiniBoss**

Após a linha `const _DOOR_SCENE  := preload("res://stages/checkpoint_door.tscn")`, adicionar:

```gdscript
const _MINIBOSS_SCENE := preload("res://characters/enemies/enemy_miniboss.tscn")
```

Após `var _boss_spawned := false`, adicionar:

```gdscript
var _miniboss: Node = null
var _miniboss_spawned := false
```

- [ ] **Step 2: Atualizar `_draw_platforms` para rotear nós "MiniBoss_" para `_draw_room_tiles`**

Encontrar:
```gdscript
			if n.begins_with("Corr") or n.begins_with("Boss_"):
```

Substituir por:
```gdscript
			if n.begins_with("Corr") or n.begins_with("Boss_") or n.begins_with("MiniBoss_"):
```

- [ ] **Step 3: Adicionar `_setup_miniboss_trigger()` na `_ready()`**

Encontrar a chamada `_setup_doors()` e adicionar depois:
```gdscript
	_setup_miniboss_trigger()
```

- [ ] **Step 4: Adicionar `_setup_miniboss_trigger()` e callbacks**

Adicionar antes da seção `# ─── Zone Triggers`:

```gdscript
# ─── MiniBoss Room ────────────────────────────────────────────────────────────

func _setup_miniboss_trigger() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2
	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(80.0, 256.0)
	shape.shape = rect
	area.add_child(shape)
	area.position = Vector2(6470.0, 960.0)
	area.body_entered.connect(_on_miniboss_room_entered)
	add_child(area)

func _on_miniboss_room_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	# Sela a entrada re-habilitando Corr1_Wall_R
	var seal := get_node_or_null("Corr1_Wall_R")
	if seal:
		seal.get_node("CollisionShape2D").disabled = false
	# Spawn MiniBoss uma única vez
	if _miniboss_spawned:
		return
	_miniboss_spawned = true
	_miniboss = _MINIBOSS_SCENE.instantiate()
	_miniboss.global_position = Vector2(6900.0, 1024.0)
	add_child(_miniboss)
	_miniboss.died.connect(_on_miniboss_defeated)

func _on_miniboss_defeated() -> void:
	# Abre a saída desabilitando MiniBoss_RWall
	var rwall := get_node_or_null("MiniBoss_RWall")
	if rwall:
		rwall.get_node("CollisionShape2D").disabled = true
		queue_redraw()
```

- [ ] **Step 5: Commit**

```bash
git add stages/stage_00/stage_00_scene.gd
git commit -m "feat: stage_00 — sala miniboss, trigger seal/unseal, spawn MiniBoss"
```

---

### Task 6: Verificação e Export

- [ ] **Step 1: Rodar testes existentes**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\Usuário\SnesGame" res://tests/test_character_base.tscn
```

Expected: todos os testes PASS, sem erros de script.

- [ ] **Step 2: Web export**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\Usuário\SnesGame" --export-release "Web" "C:\Users\Usuário\SnesGame\export\web\index.html"
```

Expected: `[ DONE ] savepack` sem ERRORs.

- [ ] **Step 3: Reiniciar servidor e verificar**

```powershell
$pids = netstat -ano | findstr ':8080' | ForEach-Object { ($_ -split '\s+')[-1] } | Sort-Object -Unique
foreach ($p in $pids) { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue }
Start-Process python -ArgumentList 'C:\Users\Usuário\SnesGame\serve_web.py' -WindowStyle Hidden
Start-Sleep -Seconds 2
(Invoke-WebRequest http://localhost:8080 -UseBasicParsing).StatusCode
```

Expected: `200`

- [ ] **Step 4: Teste manual em http://localhost:8080**

Percurso de teste:
1. Chegar até o corredor CP1 (X≈5800)
2. Passar pela porta de entrada — porta fecha atrás
3. Sair pela porta de saída (X≈6398) — entrar na sala do MiniBoss
4. Verificar que `Corr1_Wall_R` está selado (não consegue voltar)
5. MiniBoss aparece em X≈6900 e começa a patrulhar
6. Verificar PATROL → CHARGE quando player se aproxima
7. Verificar STOMP: boss pula e ao cair aparece shockwave laranja no chão
8. Derrotar o MiniBoss → `MiniBoss_RWall` desaparece e player pode continuar
9. Verificar tiles da sala renderizando corretamente (teto, chão, parede direita)

- [ ] **Step 5: Commit final**

```bash
git add .
git commit -m "feat: sala miniboss Stage 00 — geometria, trigger, seal/unseal, PATROL/CHARGE/STOMP/RECOVER"
```
