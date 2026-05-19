# Zael Single Shot — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar Zael com Single Shot hold-and-release (3 níveis de carga) e atualizar o input map (setas, Space, Z).

**Architecture:** `zael.gd` estende `CharacterBase` e adiciona lógica de carga/disparo sem modificar a base. `ZaelBullet` é um `Area2D` independente que se move por `_physics_process` e se auto-destrói ao colidir com `StaticBody2D` ou ao expirar o timer de 3s. `zael.tscn` instancia `character_base.tscn` como base e substitui o script pelo `zael.gd`.

**Tech Stack:** Godot 4.6.2, GDScript

---

### Task 1: Atualizar Input Map

**Files:**
- Modify: `project.godot`

- [ ] **Step 1: Substituir `move_left` (A → seta esquerda)**

Em `project.godot`, localizar e substituir o bloco completo de `move_left`:

```
# ANTES
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)
]
}

# DEPOIS
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194319,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

- [ ] **Step 2: Substituir `move_right` (D → seta direita)**

```
# ANTES
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)
]
}

# DEPOIS
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194321,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

- [ ] **Step 3: Substituir `jump` (Z → Space)**

```
# ANTES
jump={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":90,"key_label":0,"unicode":122,"location":0,"echo":false,"script":null)
]
}

# DEPOIS
jump={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"location":0,"echo":false,"script":null)
]
}
```

- [ ] **Step 4: Substituir `attack` (J → Z)**

```
# ANTES
attack={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":74,"key_label":0,"unicode":106,"location":0,"echo":false,"script":null)
]
}

# DEPOIS
attack={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":90,"key_label":0,"unicode":122,"location":0,"echo":false,"script":null)
]
}
```

- [ ] **Step 5: Commit**

```bash
git add project.godot
git commit -m "feat: update input map — arrows move, space jump, z attack"
```

---

### Task 2: Criar ZaelBullet

**Files:**
- Create: `characters/ranged/zael_bullet.gd`
- Create: `characters/ranged/zael_bullet.tscn`
- Create: `tests/test_zael.gd`
- Create: `tests/test_zael.tscn`

- [ ] **Step 1: Escrever o teste que falha**

Criar `tests/test_zael.gd`:

```gdscript
extends Node

func _ready() -> void:
    test_bullet_properties()
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
```

- [ ] **Step 2: Criar `tests/test_zael.tscn`**

```
[gd_scene load_steps=2 format=3 uid="uid://test_zael"]

[ext_resource type="Script" path="res://tests/test_zael.gd" id="1_test"]

[node name="TestZael" type="Node"]
script = ExtResource("1_test")
```

- [ ] **Step 3: Rodar o teste para confirmar que falha**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_zael.tscn
```

Resultado esperado: erro — `zael_bullet.tscn` não existe.

- [ ] **Step 4: Criar `characters/ranged/zael_bullet.gd`**

```gdscript
extends Area2D
class_name ZaelBullet

const SPEED := 500.0

var damage: int = 5
var direction: float = 1.0

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    $Timer.timeout.connect(queue_free)
    queue_redraw()

func _physics_process(delta: float) -> void:
    global_position.x += direction * SPEED * delta

func _draw() -> void:
    draw_circle(Vector2.ZERO, 6.0, Color.YELLOW)

func _on_body_entered(_body: Node) -> void:
    queue_free()
```

- [ ] **Step 5: Criar `characters/ranged/zael_bullet.tscn`**

```
[gd_scene load_steps=4 format=3 uid="uid://zael_bullet"]

[ext_resource type="Script" path="res://characters/ranged/zael_bullet.gd" id="1_bullet"]

[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 6.0

[node name="ZaelBullet" type="Area2D"]
script = ExtResource("1_bullet")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_1")

[node name="Timer" type="Timer" parent="."]
wait_time = 3.0
one_shot = true
autostart = true
```

- [ ] **Step 6: Rodar o teste para confirmar que passa**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_zael.tscn
```

Resultado esperado:
```
PASS: bullet_properties
ALL TESTS PASSED
```

- [ ] **Step 7: Commit**

```bash
git add characters/ranged/zael_bullet.gd characters/ranged/zael_bullet.tscn tests/test_zael.gd tests/test_zael.tscn
git commit -m "feat: add ZaelBullet with movement and self-destruct"
```

---

### Task 3: Criar Zael com sistema de carga

**Files:**
- Create: `characters/ranged/zael.gd`
- Modify: `tests/test_zael.gd`

- [ ] **Step 1: Adicionar `test_charge_levels` ao arquivo de teste**

Substituir `tests/test_zael.gd` por:

```gdscript
extends Node

func _ready() -> void:
    test_bullet_properties()
    test_charge_levels()
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
```

- [ ] **Step 2: Rodar o teste para confirmar que falha**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_zael.tscn
```

Resultado esperado: erro de compilação — `Identifier not found: Zael`.

- [ ] **Step 3: Criar `characters/ranged/zael.gd`**

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

var _charge_timer: float = 0.0
var _is_charging: bool = false

@onready var _bullet_spawn: Marker2D = $BulletSpawn

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if is_dead:
        return
    _handle_shooting(delta)

func _handle_shooting(delta: float) -> void:
    if Input.is_action_just_pressed("attack"):
        _is_charging = true
    if _is_charging:
        _charge_timer += delta
    if Input.is_action_just_released("attack") and _is_charging:
        _fire(get_charge_level(_charge_timer))
        _is_charging = false
        _charge_timer = 0.0

static func get_charge_level(timer: float) -> int:
    if timer >= CHARGE_L3_THRESHOLD:
        return 3
    if timer >= CHARGE_L2_THRESHOLD:
        return 2
    return 1

func _fire(level: int) -> void:
    var bullet: ZaelBullet = _BULLET_SCENE.instantiate()
    bullet.damage = BULLET_DAMAGE[level]
    bullet.direction = 1.0 if facing_right else -1.0
    bullet.scale = BULLET_SCALE[level]
    get_parent().add_child(bullet)
    bullet.global_position = _bullet_spawn.global_position
```

- [ ] **Step 4: Rodar o teste para confirmar que passa**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_zael.tscn
```

Resultado esperado:
```
PASS: bullet_properties
PASS: charge_levels
ALL TESTS PASSED
```

- [ ] **Step 5: Commit**

```bash
git add characters/ranged/zael.gd tests/test_zael.gd
git commit -m "feat: add Zael script with Single Shot charge system"
```

---

### Task 4: Criar cena do Zael

**Files:**
- Create: `characters/ranged/zael.tscn`

- [ ] **Step 1: Criar `characters/ranged/zael.tscn`**

```
[gd_scene load_steps=3 format=3 uid="uid://zael"]

[ext_resource type="PackedScene" uid="uid://character_base" path="res://characters/base/character_base.tscn" id="1_base"]
[ext_resource type="Script" path="res://characters/ranged/zael.gd" id="2_zael"]

[node name="Zael" instance=ExtResource("1_base")]
script = ExtResource("2_zael")

[node name="BulletSpawn" type="Marker2D" parent="."]
position = Vector2(20, -10)
```

- [ ] **Step 2: Commit**

```bash
git add characters/ranged/zael.tscn
git commit -m "feat: add Zael scene with BulletSpawn marker"
```

---

### Task 5: Atualizar test_level para usar Zael

**Files:**
- Modify: `scenes/test_level.tscn`
- Modify: `scenes/test_level.gd`

- [ ] **Step 1: Atualizar `scenes/test_level.tscn`**

Substituir o `ext_resource` de `character_base.tscn` por `zael.tscn` e renomear o nó:

```
# ANTES
[ext_resource type="PackedScene" uid="uid://character_base" path="res://characters/base/character_base.tscn" id="1_char"]
...
[node name="CharacterBase" parent="." instance=ExtResource("1_char")]
position = Vector2(400, 380)

# DEPOIS
[ext_resource type="PackedScene" uid="uid://zael" path="res://characters/ranged/zael.tscn" id="1_char"]
...
[node name="Zael" parent="." instance=ExtResource("1_char")]
position = Vector2(400, 380)
```

- [ ] **Step 2: Atualizar `scenes/test_level.gd`**

```gdscript
# ANTES
@onready var character: CharacterBase = $CharacterBase

# DEPOIS
@onready var character: Zael = $Zael
```

- [ ] **Step 3: Commit**

```bash
git add scenes/test_level.tscn scenes/test_level.gd
git commit -m "feat: wire test level to Zael"
```

---

### Task 6: Smoke test manual

- [ ] **Step 1: Abrir o projeto no Godot e pressionar Play (F5)**

Verificar na ordem:

| Ação | Resultado esperado |
|------|-------------------|
| Seta direita | Zael (retângulo ciano) move para direita |
| Seta esquerda | Zael move para esquerda |
| Space | Pulo; Space no ar = pulo duplo |
| X | Dash na direção que está olhando |
| Z (tap rápido) | Projétil amarelo pequeno, some ao bater no chão |
| Z (segurar ~0.5s, soltar) | Projétil amarelo médio (1.6× maior) |
| Z (segurar ~1.5s, soltar) | Projétil amarelo grande (2.5× maior) |
| Projétil chega na parede | Desaparece |
| Zael vira para esquerda, Z | Projétil vai para esquerda |

- [ ] **Step 2: Commit final**

```bash
git add -A
git commit -m "feat: Plan 02 complete — Zael Single Shot with 3-level charge"
```
