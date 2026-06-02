# Skill: new-enemy

Use quando o usuário pedir para criar um novo tipo de inimigo.

## Informações a Coletar

Pergunte ao usuário (uma por vez se não fornecidas):
1. **nome** — snake_case, ex: `enemy_jumper`
2. **cor** — Color GDScript, ex: `Color(0.8, 0.2, 0.2)`
3. **comportamento** — escolha: `ground_patrol` | `flyer` | `jumper` | `shooter`

## Arquivos a Criar

Substituir `<nome>` pelo nome informado (ex: `enemy_jumper`):

1. `characters/enemies/<nome>.gd`
2. `characters/enemies/<nome>.tscn`
3. `tests/test_<nome>.gd`
4. `tests/test_<nome>.tscn`

## Templates por Comportamento

### ground_patrol

`characters/enemies/<nome>.gd`:
```gdscript
extends EnemyBase
class_name <NomePascal>

func _draw() -> void:
    var c := Color.WHITE if _hit_flash_timer > 0.0 else <cor>
    draw_rect(Rect2(-20, -40, 40, 80), c)
```
Não sobrescreve `_physics_process` — usa o da base (patrol + ledge detection + gravity).

---

### flyer

`characters/enemies/<nome>.gd`:
```gdscript
extends EnemyBase
class_name <NomePascal>

@export var patrol_range: float = 150.0

var _start_x: float = 0.0

func _ready() -> void:
    super._ready()
    _start_x = global_position.x

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    if _invincibility_timer > 0.0:
        _invincibility_timer -= delta
        if _invincibility_timer <= 0.0:
            _invincible = false
    velocity.x = PATROL_SPEED * _direction
    velocity.y = 0.0
    move_and_slide()
    if abs(global_position.x - _start_x) >= patrol_range:
        _direction = -_direction

func _draw() -> void:
    var c := Color.WHITE if _hit_flash_timer > 0.0 else <cor>
    draw_rect(Rect2(-20, -28, 40, 56), c)
```

---

### jumper

`characters/enemies/<nome>.gd`:
```gdscript
extends EnemyBase
class_name <NomePascal>

const JUMP_SPEED := 500.0
const JUMP_INTERVAL := 2.0

var _jump_timer: float = JUMP_INTERVAL

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if is_dead:
        return
    _jump_timer -= delta
    if _jump_timer <= 0.0 and is_on_floor():
        velocity.y = -JUMP_SPEED
        _jump_timer = JUMP_INTERVAL

func _draw() -> void:
    var c := Color.WHITE if _hit_flash_timer > 0.0 else <cor>
    draw_rect(Rect2(-20, -40, 40, 80), c)
```

---

### shooter

`characters/enemies/<nome>.gd`:
```gdscript
extends EnemyBase
class_name <NomePascal>

const _PROJECTILE_SCENE := preload("res://characters/bosses/boss_projectile.tscn")
const SHOOT_INTERVAL := 2.5
const SHOOT_SPEED := 250.0
const SHOOT_DAMAGE := 10

var _shoot_timer: float = SHOOT_INTERVAL

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if is_dead:
        return
    _shoot_timer -= delta
    if _shoot_timer <= 0.0:
        _shoot_timer = SHOOT_INTERVAL
        _fire()

func _fire() -> void:
    if _PROJECTILE_SCENE == null:
        return
    var p = _PROJECTILE_SCENE.instantiate()
    p.global_position = global_position
    p.projectile_velocity = Vector2(_direction * SHOOT_SPEED, 0.0)
    p.damage = SHOOT_DAMAGE
    p.source_id = ""
    p.color = <cor>
    get_parent().add_child(p)

func _draw() -> void:
    var c := Color.WHITE if _hit_flash_timer > 0.0 else <cor>
    draw_rect(Rect2(-20, -40, 40, 80), c)
```

---

## Template .tscn

`characters/enemies/<nome>.tscn`:
```
[gd_scene format=3 uid="uid://<nome>"]

[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="1_base"]
[ext_resource type="Script" path="res://characters/enemies/<nome>.gd" id="2_script"]

[node name="<NomePascal>" instance=ExtResource("1_base")]
script = ExtResource("2_script")
```

Para **flyer**, adicionar `patrol_range = 150.0` após `script = ...`.

---

## Template de Teste

`tests/test_<nome>.gd`:
```gdscript
extends Node

func _ready() -> void:
    test_initial_hp()
    test_take_damage()
    test_invincibility()
    test_death()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_initial_hp() -> void:
    var e = _spawn()
    assert(e.current_hp == e.max_hp)
    assert(not e.is_dead)
    e.queue_free()
    print("PASS: initial_hp")

func test_take_damage() -> void:
    var e = _spawn()
    e.take_damage(2)
    assert(e.current_hp == e.max_hp - 2)
    e.queue_free()
    print("PASS: take_damage")

func test_invincibility() -> void:
    var e = _spawn()
    e.take_damage(1)
    e.take_damage(1)  # bloqueado por invencibilidade
    assert(e.current_hp == e.max_hp - 1)
    e.queue_free()
    print("PASS: invincibility")

func test_death() -> void:
    var e = _spawn()
    var died_flag := [false]
    e.died.connect(func(): died_flag[0] = true)
    e.take_damage(e.max_hp)
    assert(e.is_dead)
    assert(died_flag[0])
    print("PASS: death")

func _spawn():
    var scene := load("res://characters/enemies/<nome>.tscn")
    var inst = scene.instantiate()
    add_child(inst)
    return inst
```

`tests/test_<nome>.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://tests/test_<nome>.gd" id="1_script"]

[node name="Test<NomePascal>" type="Node"]
script = ExtResource("1_script")
```

## Pós-Criação

Após criar os 4 arquivos:
1. Rodar: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_<nome>.tscn`
2. Verificar saída contém `ALL TESTS PASSED`
3. Commitar: `git add characters/enemies/<nome>.* tests/test_<nome>.* && git commit -m "feat: novo inimigo <nome>"`
