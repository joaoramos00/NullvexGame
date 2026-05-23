# Skill: new-stage

Use quando o usuário pedir para criar uma nova fase.

## Informações a Coletar

1. **stage_id** — int (próximo disponível após 11, ou novo)
2. **nome descritivo** — ex: `volcano`, `ice_cave`
3. **boss** — nome do boss (deve existir em `characters/bosses/`)
4. **estilo** — `simple` (usa stage_scene.gd) | `complex` (GD customizado com zonas/doors)
5. **platform_color** — Color das plataformas
6. **tema visual** — descrição do cenário para gerar `_draw()` (apenas para `complex`)

## Arquivos a Criar

**Simple:**
- `stages/stage_<id>/stage_<id>.tscn`
- `tests/test_stage_<id>.gd`
- `tests/test_stage_<id>.tscn`

**Complex:**
- `stages/stage_<id>/stage_<id>.tscn`
- `stages/stage_<id>/stage_<id>_scene.gd`
- `tests/test_stage_<id>.gd`
- `tests/test_stage_<id>.tscn`

---

## Template Simple

Baseado em `stages/stage_01/stage_01.tscn`. Adaptar `<id>`, `<NomePascal>`, `<BossNomePascal>`, `uid://boss_<nome>`, `platform_color`, posições.

`stages/stage_<id>/stage_<id>.tscn`:
```
[gd_scene format=3 uid="uid://stage_<id>"]

[ext_resource type="Script" path="res://stages/stage_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://checkpoint" path="res://stages/checkpoint.tscn" id="3_cp"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="4_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://<boss_nome>" path="res://characters/bosses/<boss_nome>.tscn" id="9_boss"]
[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="10_grunt"]
[ext_resource type="PackedScene" uid="uid://enemy_flyer" path="res://characters/enemies/enemy_flyer.tscn" id="11_flyer"]

[sub_resource type="RectangleShape2D" id="FloorA"]
size = Vector2(800, 40)

[sub_resource type="RectangleShape2D" id="FloorB"]
size = Vector2(600, 40)

[sub_resource type="RectangleShape2D" id="FloorPre"]
size = Vector2(500, 40)

[sub_resource type="RectangleShape2D" id="FloorBoss"]
size = Vector2(1200, 40)

[sub_resource type="RectangleShape2D" id="P1"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="P2"]
size = Vector2(180, 20)

[sub_resource type="RectangleShape2D" id="P3"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="P4"]
size = Vector2(220, 20)

[node name="Stage<Id>" type="Node2D"]
platform_color = <platform_color>
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 760)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Checkpoint1" parent="." instance=ExtResource("3_cp")]
position = Vector2(2000, 850)
checkpoint_index = 1

[node name="Checkpoint2" parent="." instance=ExtResource("3_cp")]
position = Vector2(3500, 850)
checkpoint_index = 2

[node name="FloorA" type="StaticBody2D" parent="."]
position = Vector2(400, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorA"]
shape = SubResource("FloorA")

[node name="FloorB" type="StaticBody2D" parent="."]
position = Vector2(1900, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorB"]
shape = SubResource("FloorB")

[node name="FloorPre" type="StaticBody2D" parent="."]
position = Vector2(3500, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorPre"]
shape = SubResource("FloorPre")

[node name="FloorBoss" type="StaticBody2D" parent="."]
position = Vector2(4700, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorBoss"]
shape = SubResource("FloorBoss")

[node name="Plat1" type="StaticBody2D" parent="."]
position = Vector2(850, 820)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat1"]
shape = SubResource("P1")

[node name="Plat2" type="StaticBody2D" parent="."]
position = Vector2(1100, 760)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat2"]
shape = SubResource("P2")

[node name="Plat3" type="StaticBody2D" parent="."]
position = Vector2(1350, 700)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat3"]
shape = SubResource("P3")

[node name="Plat4" type="StaticBody2D" parent="."]
position = Vector2(1650, 640)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat4"]
shape = SubResource("P4")

[node name="<BossNomePascal>" parent="." instance=ExtResource("9_boss")]
position = Vector2(4600, 760)
arena_left = 4100.0
arena_right = 5100.0
arena_floor = 900.0

[node name="Grunt1" parent="." instance=ExtResource("10_grunt")]
position = Vector2(850, 790)

[node name="Grunt2" parent="." instance=ExtResource("10_grunt")]
position = Vector2(1350, 670)

[node name="Grunt3" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2600, 670)

[node name="Grunt4" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2900, 730)

[node name="Flyer1" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1700, 600)

[node name="Heart" parent="." instance=ExtResource("4_col")]
position = Vector2(1350, 660)
stage_id = <id>

[node name="HUD" parent="." instance=ExtResource("5_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]
[node name="GameOver" parent="." instance=ExtResource("7_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_top = 0
limit_bottom = 1080
limit_right = 5300
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

---

## Template Complex

Para stage complexo, usar `stage_00_scene.gd` e `stage_00.tscn` como referência direta:
- Ler `stages/stage_00/stage_00_scene.gd` e `stages/stage_00/stage_00.tscn`
- Adaptar: id, nome, posições de zonas, cores do `_draw_background()`, boss

Estrutura mínima do GD customizado:
```gdscript
extends Node2D

const ZAEL_SCENE   := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE   := preload("res://characters/melee/zara.tscn")
const _GRUNT_SCENE := preload("res://characters/enemies/enemy_base.tscn")
const _FLYER_SCENE := preload("res://characters/enemies/enemy_flyer.tscn")
const _BOSS_SCENE  := preload("res://characters/bosses/<boss_nome>.tscn")
const _DOOR_SCENE  := preload("res://stages/checkpoint_door.tscn")

# Posições por zona (adaptar ao layout)
const ZONE1_GRUNTS := [Vector2(400, 520), Vector2(700, 520)]
const ZONE1_FLYERS := [Vector2(550, 380)]
const ZONE2_GRUNTS := [Vector2(3500, 204), Vector2(3900, 204)]
const ZONE2_FLYERS := [Vector2(3700, 160)]
const ZONE3_GRUNTS := [Vector2(6100, 520), Vector2(6800, 460)]
const ZONE3_FLYERS := [Vector2(6600, 400)]

const BOSS_SPAWN   := Vector2(9100, 400)
const CP1_ENTRY_X  := 2900.0
const CP1_EXIT_X   := 3200.0
const CP2_ENTRY_X  := 8000.0
const CP2_EXIT_X   := 8300.0

# Copiar _ready, _process, _unhandled_input, _spawn_player, _setup_doors,
# _on_cp1_entry_opened, _on_cp2_entry_opened, _on_boss_door_opened, _spawn_boss,
# _setup_zone_triggers, _make_zone_trigger, zone entered/exited callbacks,
# _spawn_zone_enemies, _get_zone_array, _respawn_zone, _clear_zone_enemies
# de stage_00_scene.gd e adaptar boss_id e posições.
#
# Adaptar _draw_background() com as cores e tema do novo stage.
```

---

## Template de Teste

`tests/test_stage_<id>.gd`:
```gdscript
extends Node

func _ready() -> void:
    test_scene_loads()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_scene_loads() -> void:
    var scene := load("res://stages/stage_<id>/stage_<id>.tscn")
    assert(scene != null, "tscn deve existir")
    print("PASS: scene_loads")
```

`tests/test_stage_<id>.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://tests/test_stage_<id>.gd" id="1_script"]

[node name="TestStage<Id>" type="Node"]
script = ExtResource("1_script")
```

## Pós-Criação

1. Rodar: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_<id>.tscn`
2. Verificar `ALL TESTS PASSED`
3. Commitar: `git add stages/stage_<id>/ tests/test_stage_<id>.* && git commit -m "feat: nova fase stage_<id> (<nome>)"`
