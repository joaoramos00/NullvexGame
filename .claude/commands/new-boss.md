# Skill: new-boss

Use quando o usuário pedir para criar um novo boss elemental.

## Informações a Coletar

Pergunte ao usuário (uma por vez se não fornecidas):
1. **nome** — snake_case, ex: `pyrovex`
2. **boss_id** — string identificadora (geralmente = nome)
3. **weakness_id** — ability_id do boss que o derrota (ver tabela em GAME_CONTEXT.md)
4. **ability_id** — string desbloqueada ao derrotá-lo (geralmente = nome)
5. **stage_id** — int (1–11, ou novo número acima de 11)
6. **boss_color** — Color GDScript, ex: `Color(0.9, 0.3, 0.0)`
7. **tema do ataque fase 1** — descrição livre (ex: "dispara 3 projéteis em leque")
8. **diferença fase 2** — (ex: "intervalo menor e 5 projéteis")

## Arquivos a Criar

1. `characters/bosses/<nome>.gd`
2. `characters/bosses/<nome>.tscn`
3. `tests/test_<nome>.gd`
4. `tests/test_<nome>.tscn`

## Template .gd

`characters/bosses/<nome>.gd`:
```gdscript
extends BossBase

func _do_combat(delta: float) -> void:
    if player == null:
        return
    var dx := player.global_position.x - global_position.x
    if abs(dx) > 120.0:
        velocity.x = sign(dx) * 80.0
    else:
        velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
    _face_player()
    _clamp_to_arena()

func _do_attack() -> void:
    _is_attacking = true
    velocity.x = 0.0
    await get_tree().create_timer(0.3).timeout
    if is_dead or player == null:
        _is_attacking = false
        return
    var dir := sign(player.global_position.x - global_position.x)
    if dir == 0.0:
        dir = 1.0
    # FASE 1: <descrição do ataque fase 1>
    var shots := 1
    if phase >= 2:
        shots = 3  # <ajuste fase 2>
    for i in shots:
        var angle := 0.0
        if shots > 1:
            angle = (i - shots / 2.0) * 0.25
        var vel := Vector2(dir * 300.0, 0.0).rotated(angle)
        _spawn_projectile(global_position, vel, 15, "<boss_id>", <boss_color>)
    _is_attacking = false

func _enter_phase_2() -> void:
    attack_interval_p2 = 1.2
    # <ajuste adicional fase 2 se necessário>
```

Ajustar `_do_attack()` conforme o tema informado pelo usuário.

## Template .tscn

`characters/bosses/<nome>.tscn`:
```
[gd_scene format=3 uid="uid://<nome>"]

[ext_resource type="PackedScene" uid="uid://boss_base" path="res://characters/bosses/boss_base.tscn" id="1_base"]
[ext_resource type="Script" path="res://characters/bosses/<nome>.gd" id="2_script"]

[node name="<NomePascal>" instance=ExtResource("1_base")]
script = ExtResource("2_script")
boss_id = "<boss_id>"
weakness_id = "<weakness_id>"
ability_id = "<ability_id>"
stage_id = <stage_id>
max_hp = 200
boss_color = <boss_color>
arena_left = 100.0
arena_right = 1820.0
arena_floor = 500.0
```

## Template de Teste

`tests/test_<nome>.gd`:
```gdscript
extends Node

func _ready() -> void:
    test_initial_hp()
    test_take_damage()
    test_weakness_multiplier()
    test_no_damage_when_idle()
    test_phase_transition()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_initial_hp() -> void:
    var b = _spawn()
    assert(b.current_hp == b.max_hp)
    assert(not b.is_dead)
    b.queue_free()
    print("PASS: initial_hp")

func test_take_damage() -> void:
    var b = _spawn()
    b.state = b.State.COMBAT
    b.take_damage(20)
    assert(b.current_hp == b.max_hp - 20)
    b.queue_free()
    print("PASS: take_damage")

func test_weakness_multiplier() -> void:
    var b = _spawn()
    b.state = b.State.COMBAT
    b.take_damage(10, b.weakness_id)
    # dano dobrado: 20
    assert(b.current_hp == b.max_hp - 20)
    b.queue_free()
    print("PASS: weakness_multiplier")

func test_no_damage_when_idle() -> void:
    var b = _spawn()
    # state == IDLE por padrão — dano ignorado
    b.take_damage(50)
    assert(b.current_hp == b.max_hp)
    b.queue_free()
    print("PASS: no_damage_when_idle")

func test_phase_transition() -> void:
    var b = _spawn()
    b.state = b.State.COMBAT
    b.take_damage(int(b.max_hp * 0.6))  # cai abaixo de 50%
    assert(b.phase == 2)
    b.queue_free()
    print("PASS: phase_transition")

func _spawn():
    var scene := load("res://characters/bosses/<nome>.tscn")
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

1. Rodar: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_<nome>.tscn`
2. Verificar `ALL TESTS PASSED`
3. Commitar: `git add characters/bosses/<nome>.* tests/test_<nome>.* && git commit -m "feat: novo boss <nome>"`
