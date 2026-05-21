# Stage Layouts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign stages 01-08 with thematic platforming gimmicks and per-stage platform colors.

**Architecture:** Add `@export var platform_color` to `stage_scene.gd` and use it in `_draw()`. Rewrite each stage's `.tscn` with new floor segments, platforms, and enemy/collectible positions matching the theme spec.

**Tech Stack:** Godot 4.6.2, GDScript, `.tscn` text scene format.

---

## Collectible type enum (reference)
```
0 = HEART, 1 = SUBTANK, 2 = ARMOR_ZAEL, 3 = ARMOR_ZARA, 4 = SHOT_ZAEL, 5 = WEAPON_ZARA
```

---

## Task 1: Add platform_color to stage_scene.gd

**Files:**
- Modify: `stages/stage_scene.gd`

- [ ] **Step 1: Edit stage_scene.gd**

Replace the `_draw()` function and add the export variable. Final file:

```gdscript
extends Node2D

const ZAEL_SCENE := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE := preload("res://characters/melee/zara.tscn")

@export var platform_color: Color = Color(0.35, 0.35, 0.35)

var _player: CharacterBase

func _ready() -> void:
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")
	_player = _spawn_player()
	for child in get_children():
		if child is BossBase:
			child.player = _player
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)
	StageManager.spawn_position = $PlayerSpawn.global_position
	AudioManager.play_bgm(AudioLibrary.get_stage_bgm(StageManager.current_stage_id))
	queue_redraw()

func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		$Camera2D.global_position = _player.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		$PauseMenu.toggle_pause()

func _spawn_player() -> CharacterBase:
	var scene := ZARA_SCENE if GameManager.active_character == "zara" else ZAEL_SCENE
	var p: CharacterBase = scene.instantiate()
	p.global_position = $PlayerSpawn.global_position
	add_child(p)
	return p

func _draw() -> void:
	for child in get_children():
		if not child is StaticBody2D:
			continue
		for shape_child in child.get_children():
			if not shape_child is CollisionShape2D:
				continue
			if not shape_child.shape is RectangleShape2D:
				continue
			var size: Vector2 = (shape_child.shape as RectangleShape2D).size
			var center: Vector2 = (child as Node2D).position + (shape_child as Node2D).position
			draw_rect(Rect2(center - size * 0.5, size), platform_color)
```

- [ ] **Step 2: Commit**
```bash
git add stages/stage_scene.gd
git commit -m "feat: platform_color export em stage_scene"
```

---

## Task 2: Stage 01 — Ignarath (Fogo)

**Files:** Modify `stages/stage_01/stage_01.tscn`

- [ ] **Step 1: Rewrite stage_01.tscn**

```
[gd_scene format=3 uid="uid://stage_01"]

[ext_resource type="Script" path="res://stages/stage_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://checkpoint" path="res://stages/checkpoint.tscn" id="3_cp"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="4_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://ignarath" path="res://characters/bosses/ignarath.tscn" id="9_boss"]
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

[sub_resource type="RectangleShape2D" id="P5"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="P6"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="P7"]
size = Vector2(220, 20)

[sub_resource type="RectangleShape2D" id="P8"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="P9"]
size = Vector2(250, 20)

[sub_resource type="RectangleShape2D" id="P10"]
size = Vector2(200, 20)

[node name="Stage01" type="Node2D"]
platform_color = Color(0.9, 0.3, 0.1, 1)
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 400)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Checkpoint1" parent="." instance=ExtResource("3_cp")]
position = Vector2(2000, 490)
checkpoint_index = 1

[node name="Checkpoint2" parent="." instance=ExtResource("3_cp")]
position = Vector2(3500, 490)
checkpoint_index = 2

[node name="FloorA" type="StaticBody2D" parent="."]
position = Vector2(400, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorA"]
shape = SubResource("FloorA")

[node name="FloorB" type="StaticBody2D" parent="."]
position = Vector2(1900, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorB"]
shape = SubResource("FloorB")

[node name="FloorPre" type="StaticBody2D" parent="."]
position = Vector2(3500, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorPre"]
shape = SubResource("FloorPre")

[node name="FloorBoss" type="StaticBody2D" parent="."]
position = Vector2(4700, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorBoss"]
shape = SubResource("FloorBoss")

[node name="Plat1" type="StaticBody2D" parent="."]
position = Vector2(850, 460)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat1"]
shape = SubResource("P1")

[node name="Plat2" type="StaticBody2D" parent="."]
position = Vector2(1100, 400)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat2"]
shape = SubResource("P2")

[node name="Plat3" type="StaticBody2D" parent="."]
position = Vector2(1350, 340)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat3"]
shape = SubResource("P3")

[node name="Plat4" type="StaticBody2D" parent="."]
position = Vector2(1650, 280)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat4"]
shape = SubResource("P4")

[node name="Plat5" type="StaticBody2D" parent="."]
position = Vector2(1950, 220)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat5"]
shape = SubResource("P5")

[node name="Plat6" type="StaticBody2D" parent="."]
position = Vector2(2300, 280)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat6"]
shape = SubResource("P6")

[node name="Plat7" type="StaticBody2D" parent="."]
position = Vector2(2600, 340)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat7"]
shape = SubResource("P7")

[node name="Plat8" type="StaticBody2D" parent="."]
position = Vector2(2900, 400)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat8"]
shape = SubResource("P8")

[node name="Plat9" type="StaticBody2D" parent="."]
position = Vector2(3200, 460)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat9"]
shape = SubResource("P9")

[node name="Plat10" type="StaticBody2D" parent="."]
position = Vector2(3700, 380)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat10"]
shape = SubResource("P10")

[node name="Heart" parent="." instance=ExtResource("4_col")]
position = Vector2(1350, 300)
stage_id = 1

[node name="ArmorZaelHelmet" parent="." instance=ExtResource("4_col")]
position = Vector2(1950, 180)
collectible_type = 2
armor_piece = "helmet"

[node name="DualBladesZara" parent="." instance=ExtResource("4_col")]
position = Vector2(2900, 360)
collectible_type = 5
ability_id = "dual_blades"

[node name="Ignarath" parent="." instance=ExtResource("9_boss")]
position = Vector2(4600, 400)
arena_left = 4100.0
arena_right = 5100.0
arena_floor = 540.0

[node name="Grunt1" parent="." instance=ExtResource("10_grunt")]
position = Vector2(850, 430)

[node name="Grunt2" parent="." instance=ExtResource("10_grunt")]
position = Vector2(1350, 310)

[node name="Grunt3" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2600, 310)

[node name="Grunt4" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2900, 370)

[node name="Flyer1" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1700, 240)

[node name="Flyer2" parent="." instance=ExtResource("11_flyer")]
position = Vector2(2150, 220)

[node name="HUD" parent="." instance=ExtResource("5_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]
[node name="GameOver" parent="." instance=ExtResource("7_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_right = 5300
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

- [ ] **Step 2: Commit**
```bash
git add stages/stage_01/stage_01.tscn
git commit -m "feat: layout stage 01 - vulcão ascendente (Ignarath)"
```

---

## Task 3: Stage 02 — Cryovex (Gelo)

**Files:** Modify `stages/stage_02/stage_02.tscn`

- [ ] **Step 1: Rewrite stage_02.tscn**

```
[gd_scene format=3 uid="uid://stage_02"]

[ext_resource type="Script" path="res://stages/stage_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://checkpoint" path="res://stages/checkpoint.tscn" id="3_cp"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="4_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://cryovex" path="res://characters/bosses/cryovex.tscn" id="9_boss"]
[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="10_grunt"]
[ext_resource type="PackedScene" uid="uid://enemy_flyer" path="res://characters/enemies/enemy_flyer.tscn" id="11_flyer"]

[sub_resource type="RectangleShape2D" id="Floor"]
size = Vector2(5400, 40)

[sub_resource type="RectangleShape2D" id="P1"]
size = Vector2(350, 20)

[sub_resource type="RectangleShape2D" id="P2"]
size = Vector2(300, 20)

[sub_resource type="RectangleShape2D" id="P3"]
size = Vector2(400, 20)

[sub_resource type="RectangleShape2D" id="P4"]
size = Vector2(350, 20)

[sub_resource type="RectangleShape2D" id="P5"]
size = Vector2(300, 20)

[node name="Stage02" type="Node2D"]
platform_color = Color(0.4, 0.8, 1.0, 1)
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 400)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Checkpoint1" parent="." instance=ExtResource("3_cp")]
position = Vector2(1700, 490)
checkpoint_index = 1

[node name="Checkpoint2" parent="." instance=ExtResource("3_cp")]
position = Vector2(3100, 490)
checkpoint_index = 2

[node name="Floor" type="StaticBody2D" parent="."]
position = Vector2(2700, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Floor"]
shape = SubResource("Floor")

[node name="Plat1" type="StaticBody2D" parent="."]
position = Vector2(700, 400)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat1"]
shape = SubResource("P1")

[node name="Plat2" type="StaticBody2D" parent="."]
position = Vector2(1500, 320)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat2"]
shape = SubResource("P2")

[node name="Plat3" type="StaticBody2D" parent="."]
position = Vector2(2300, 400)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat3"]
shape = SubResource("P3")

[node name="Plat4" type="StaticBody2D" parent="."]
position = Vector2(3200, 300)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat4"]
shape = SubResource("P4")

[node name="Plat5" type="StaticBody2D" parent="."]
position = Vector2(4000, 380)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat5"]
shape = SubResource("P5")

[node name="Heart" parent="." instance=ExtResource("4_col")]
position = Vector2(1500, 280)
stage_id = 2

[node name="SubTank" parent="." instance=ExtResource("4_col")]
position = Vector2(2300, 360)
collectible_type = 1
subtank_index = 0

[node name="ArmorZaraHelmet" parent="." instance=ExtResource("4_col")]
position = Vector2(3200, 260)
collectible_type = 3
armor_piece = "helmet"

[node name="SpreadZael" parent="." instance=ExtResource("4_col")]
position = Vector2(4000, 340)
collectible_type = 4
ability_id = "spread"

[node name="Cryovex" parent="." instance=ExtResource("9_boss")]
position = Vector2(4600, 400)
arena_left = 4100.0
arena_right = 5100.0
arena_floor = 540.0

[node name="Grunt1" parent="." instance=ExtResource("10_grunt")]
position = Vector2(400, 490)

[node name="Grunt2" parent="." instance=ExtResource("10_grunt")]
position = Vector2(1100, 490)

[node name="Grunt3" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2700, 490)

[node name="Grunt4" parent="." instance=ExtResource("10_grunt")]
position = Vector2(3700, 490)

[node name="Flyer1" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1050, 300)

[node name="Flyer2" parent="." instance=ExtResource("11_flyer")]
position = Vector2(2800, 280)

[node name="HUD" parent="." instance=ExtResource("5_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]
[node name="GameOver" parent="." instance=ExtResource("7_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_right = 5300
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

- [ ] **Step 2: Commit**
```bash
git add stages/stage_02/stage_02.tscn
git commit -m "feat: layout stage 02 - floes de gelo (Cryovex)"
```

---

## Task 4: Stage 03 — Voltrix (Raio)

**Files:** Modify `stages/stage_03/stage_03.tscn`

- [ ] **Step 1: Rewrite stage_03.tscn**

```
[gd_scene format=3 uid="uid://stage_03"]

[ext_resource type="Script" path="res://stages/stage_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://checkpoint" path="res://stages/checkpoint.tscn" id="3_cp"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="4_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://voltrix" path="res://characters/bosses/voltrix.tscn" id="9_boss"]
[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="10_grunt"]
[ext_resource type="PackedScene" uid="uid://enemy_flyer" path="res://characters/enemies/enemy_flyer.tscn" id="11_flyer"]

[sub_resource type="RectangleShape2D" id="FloorStart"]
size = Vector2(1000, 40)

[sub_resource type="RectangleShape2D" id="FloorPost"]
size = Vector2(800, 40)

[sub_resource type="RectangleShape2D" id="FloorBoss"]
size = Vector2(1200, 40)

[sub_resource type="RectangleShape2D" id="WallL"]
size = Vector2(40, 500)

[sub_resource type="RectangleShape2D" id="WallR"]
size = Vector2(40, 500)

[sub_resource type="RectangleShape2D" id="SP1"]
size = Vector2(140, 20)

[sub_resource type="RectangleShape2D" id="SP2"]
size = Vector2(140, 20)

[sub_resource type="RectangleShape2D" id="SP3"]
size = Vector2(140, 20)

[sub_resource type="RectangleShape2D" id="SP4"]
size = Vector2(140, 20)

[sub_resource type="RectangleShape2D" id="PP1"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="PP2"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="PP3"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="PreBoss"]
size = Vector2(200, 20)

[node name="Stage03" type="Node2D"]
platform_color = Color(1.0, 0.9, 0.1, 1)
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 400)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Checkpoint1" parent="." instance=ExtResource("3_cp")]
position = Vector2(1900, 490)
checkpoint_index = 1

[node name="Checkpoint2" parent="." instance=ExtResource("3_cp")]
position = Vector2(3500, 490)
checkpoint_index = 2

[node name="FloorStart" type="StaticBody2D" parent="."]
position = Vector2(500, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorStart"]
shape = SubResource("FloorStart")

[node name="FloorPost" type="StaticBody2D" parent="."]
position = Vector2(2200, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorPost"]
shape = SubResource("FloorPost")

[node name="FloorBoss" type="StaticBody2D" parent="."]
position = Vector2(4700, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorBoss"]
shape = SubResource("FloorBoss")

[node name="ShaftWallLeft" type="StaticBody2D" parent="."]
position = Vector2(1100, 300)
[node name="CollisionShape2D" type="CollisionShape2D" parent="ShaftWallLeft"]
shape = SubResource("WallL")

[node name="ShaftWallRight" type="StaticBody2D" parent="."]
position = Vector2(1600, 300)
[node name="CollisionShape2D" type="CollisionShape2D" parent="ShaftWallRight"]
shape = SubResource("WallR")

[node name="ShaftPlat1" type="StaticBody2D" parent="."]
position = Vector2(1190, 480)
[node name="CollisionShape2D" type="CollisionShape2D" parent="ShaftPlat1"]
shape = SubResource("SP1")

[node name="ShaftPlat2" type="StaticBody2D" parent="."]
position = Vector2(1510, 390)
[node name="CollisionShape2D" type="CollisionShape2D" parent="ShaftPlat2"]
shape = SubResource("SP2")

[node name="ShaftPlat3" type="StaticBody2D" parent="."]
position = Vector2(1190, 300)
[node name="CollisionShape2D" type="CollisionShape2D" parent="ShaftPlat3"]
shape = SubResource("SP3")

[node name="ShaftPlat4" type="StaticBody2D" parent="."]
position = Vector2(1510, 210)
[node name="CollisionShape2D" type="CollisionShape2D" parent="ShaftPlat4"]
shape = SubResource("SP4")

[node name="PostPlat1" type="StaticBody2D" parent="."]
position = Vector2(1750, 290)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PostPlat1"]
shape = SubResource("PP1")

[node name="PostPlat2" type="StaticBody2D" parent="."]
position = Vector2(2000, 390)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PostPlat2"]
shape = SubResource("PP2")

[node name="PostPlat3" type="StaticBody2D" parent="."]
position = Vector2(2300, 460)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PostPlat3"]
shape = SubResource("PP3")

[node name="PreBossPlat" type="StaticBody2D" parent="."]
position = Vector2(3800, 420)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PreBossPlat"]
shape = SubResource("PreBoss")

[node name="Heart" parent="." instance=ExtResource("4_col")]
position = Vector2(2000, 350)
stage_id = 3

[node name="ArmorZaelTorso" parent="." instance=ExtResource("4_col")]
position = Vector2(1190, 260)
collectible_type = 2
armor_piece = "torso"

[node name="GlaiveZara" parent="." instance=ExtResource("4_col")]
position = Vector2(2300, 420)
collectible_type = 5
ability_id = "glaive"

[node name="Voltrix" parent="." instance=ExtResource("9_boss")]
position = Vector2(4600, 400)
arena_left = 4100.0
arena_right = 5100.0
arena_floor = 540.0

[node name="Grunt1" parent="." instance=ExtResource("10_grunt")]
position = Vector2(600, 490)

[node name="Grunt2" parent="." instance=ExtResource("10_grunt")]
position = Vector2(900, 490)

[node name="Grunt3" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2100, 490)

[node name="Grunt4" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2700, 490)

[node name="Flyer1" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1200, 390)

[node name="Flyer2" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1500, 290)

[node name="HUD" parent="." instance=ExtResource("5_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]
[node name="GameOver" parent="." instance=ExtResource("7_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_right = 5300
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

- [ ] **Step 2: Commit**
```bash
git add stages/stage_03/stage_03.tscn
git commit -m "feat: layout stage 03 - shaft vertical (Voltrix)"
```

---

## Task 5: Stage 04 — Gravitus (Gravidade)

**Files:** Modify `stages/stage_04/stage_04.tscn`

- [ ] **Step 1: Rewrite stage_04.tscn**

```
[gd_scene format=3 uid="uid://stage_04"]

[ext_resource type="Script" path="res://stages/stage_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://checkpoint" path="res://stages/checkpoint.tscn" id="3_cp"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="4_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://gravitus" path="res://characters/bosses/gravitus.tscn" id="9_boss"]
[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="10_grunt"]
[ext_resource type="PackedScene" uid="uid://enemy_flyer" path="res://characters/enemies/enemy_flyer.tscn" id="11_flyer"]

[sub_resource type="RectangleShape2D" id="FloorStart"]
size = Vector2(800, 40)

[sub_resource type="RectangleShape2D" id="FloorMid"]
size = Vector2(600, 40)

[sub_resource type="RectangleShape2D" id="FloorReturn"]
size = Vector2(500, 40)

[sub_resource type="RectangleShape2D" id="FloorBoss"]
size = Vector2(1200, 40)

[sub_resource type="RectangleShape2D" id="Ceil"]
size = Vector2(5300, 40)

[sub_resource type="RectangleShape2D" id="PF1"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="PF2"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="PC1"]
size = Vector2(160, 20)

[sub_resource type="RectangleShape2D" id="PC2"]
size = Vector2(160, 20)

[sub_resource type="RectangleShape2D" id="PC3"]
size = Vector2(160, 20)

[sub_resource type="RectangleShape2D" id="CPL1"]
size = Vector2(300, 20)

[sub_resource type="RectangleShape2D" id="CPL2"]
size = Vector2(300, 20)

[sub_resource type="RectangleShape2D" id="CPL3"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="PD1"]
size = Vector2(160, 20)

[sub_resource type="RectangleShape2D" id="PD2"]
size = Vector2(160, 20)

[sub_resource type="RectangleShape2D" id="PD3"]
size = Vector2(160, 20)

[sub_resource type="RectangleShape2D" id="PB1"]
size = Vector2(250, 20)

[sub_resource type="RectangleShape2D" id="PB2"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="PB3"]
size = Vector2(250, 20)

[node name="Stage04" type="Node2D"]
platform_color = Color(0.5, 0.2, 0.8, 1)
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 400)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Checkpoint1" parent="." instance=ExtResource("3_cp")]
position = Vector2(2200, 490)
checkpoint_index = 1

[node name="Checkpoint2" parent="." instance=ExtResource("3_cp")]
position = Vector2(3200, 490)
checkpoint_index = 2

[node name="FloorStart" type="StaticBody2D" parent="."]
position = Vector2(400, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorStart"]
shape = SubResource("FloorStart")

[node name="FloorMid" type="StaticBody2D" parent="."]
position = Vector2(2200, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorMid"]
shape = SubResource("FloorMid")

[node name="FloorReturn" type="StaticBody2D" parent="."]
position = Vector2(3200, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorReturn"]
shape = SubResource("FloorReturn")

[node name="FloorBoss" type="StaticBody2D" parent="."]
position = Vector2(4700, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorBoss"]
shape = SubResource("FloorBoss")

[node name="Ceiling" type="StaticBody2D" parent="."]
position = Vector2(2650, 60)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Ceiling"]
shape = SubResource("Ceil")

[node name="PlatFloor1" type="StaticBody2D" parent="."]
position = Vector2(900, 480)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatFloor1"]
shape = SubResource("PF1")

[node name="PlatFloor2" type="StaticBody2D" parent="."]
position = Vector2(1150, 480)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatFloor2"]
shape = SubResource("PF2")

[node name="PlatClimb1" type="StaticBody2D" parent="."]
position = Vector2(1050, 380)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatClimb1"]
shape = SubResource("PC1")

[node name="PlatClimb2" type="StaticBody2D" parent="."]
position = Vector2(1050, 270)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatClimb2"]
shape = SubResource("PC2")

[node name="PlatClimb3" type="StaticBody2D" parent="."]
position = Vector2(1050, 150)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatClimb3"]
shape = SubResource("PC3")

[node name="PlatCeil1" type="StaticBody2D" parent="."]
position = Vector2(1350, 150)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatCeil1"]
shape = SubResource("CPL1")

[node name="PlatCeil2" type="StaticBody2D" parent="."]
position = Vector2(1750, 150)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatCeil2"]
shape = SubResource("CPL2")

[node name="PlatCeil3" type="StaticBody2D" parent="."]
position = Vector2(2100, 150)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatCeil3"]
shape = SubResource("CPL3")

[node name="PlatDesc1" type="StaticBody2D" parent="."]
position = Vector2(2350, 260)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatDesc1"]
shape = SubResource("PD1")

[node name="PlatDesc2" type="StaticBody2D" parent="."]
position = Vector2(2350, 370)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatDesc2"]
shape = SubResource("PD2")

[node name="PlatDesc3" type="StaticBody2D" parent="."]
position = Vector2(2350, 460)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatDesc3"]
shape = SubResource("PD3")

[node name="PlatBoss1" type="StaticBody2D" parent="."]
position = Vector2(2700, 400)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatBoss1"]
shape = SubResource("PB1")

[node name="PlatBoss2" type="StaticBody2D" parent="."]
position = Vector2(3100, 340)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatBoss2"]
shape = SubResource("PB2")

[node name="PlatBoss3" type="StaticBody2D" parent="."]
position = Vector2(3500, 400)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PlatBoss3"]
shape = SubResource("PB3")

[node name="Heart" parent="." instance=ExtResource("4_col")]
position = Vector2(1050, 110)
stage_id = 4

[node name="SubTank" parent="." instance=ExtResource("4_col")]
position = Vector2(1750, 110)
collectible_type = 1
subtank_index = 1

[node name="ArmorZaraTorso" parent="." instance=ExtResource("4_col")]
position = Vector2(2100, 110)
collectible_type = 3
armor_piece = "torso"

[node name="RapidZael" parent="." instance=ExtResource("4_col")]
position = Vector2(2700, 360)
collectible_type = 4
ability_id = "rapid"

[node name="Gravitus" parent="." instance=ExtResource("9_boss")]
position = Vector2(4600, 400)
arena_left = 4100.0
arena_right = 5100.0
arena_floor = 540.0

[node name="Grunt1" parent="." instance=ExtResource("10_grunt")]
position = Vector2(400, 490)

[node name="Grunt2" parent="." instance=ExtResource("10_grunt")]
position = Vector2(700, 490)

[node name="Grunt3" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2600, 490)

[node name="Grunt4" parent="." instance=ExtResource("10_grunt")]
position = Vector2(3100, 310)

[node name="Flyer1" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1350, 120)

[node name="Flyer2" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1750, 120)

[node name="HUD" parent="." instance=ExtResource("5_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]
[node name="GameOver" parent="." instance=ExtResource("7_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_right = 5300
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

- [ ] **Step 2: Commit**
```bash
git add stages/stage_04/stage_04.tscn
git commit -m "feat: layout stage 04 - plataformas no teto (Gravitus)"
```

---

## Task 6: Stage 05 — Galerix (Vento)

**Files:** Modify `stages/stage_05/stage_05.tscn`

- [ ] **Step 1: Rewrite stage_05.tscn**

```
[gd_scene format=3 uid="uid://stage_05"]

[ext_resource type="Script" path="res://stages/stage_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://checkpoint" path="res://stages/checkpoint.tscn" id="3_cp"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="4_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://galerix" path="res://characters/bosses/galerix.tscn" id="9_boss"]
[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="10_grunt"]
[ext_resource type="PackedScene" uid="uid://enemy_flyer" path="res://characters/enemies/enemy_flyer.tscn" id="11_flyer"]

[sub_resource type="RectangleShape2D" id="FloorStart"]
size = Vector2(700, 40)

[sub_resource type="RectangleShape2D" id="FloorLand"]
size = Vector2(500, 40)

[sub_resource type="RectangleShape2D" id="FloorBoss"]
size = Vector2(1200, 40)

[sub_resource type="RectangleShape2D" id="AP1"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="AP2"]
size = Vector2(180, 20)

[sub_resource type="RectangleShape2D" id="AP3"]
size = Vector2(160, 20)

[sub_resource type="RectangleShape2D" id="AP4"]
size = Vector2(180, 20)

[sub_resource type="RectangleShape2D" id="AP5"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="AP6"]
size = Vector2(160, 20)

[sub_resource type="RectangleShape2D" id="AP7"]
size = Vector2(180, 20)

[sub_resource type="RectangleShape2D" id="AP8"]
size = Vector2(180, 20)

[sub_resource type="RectangleShape2D" id="AP9"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="AP10"]
size = Vector2(180, 20)

[sub_resource type="RectangleShape2D" id="AP11"]
size = Vector2(200, 20)

[node name="Stage05" type="Node2D"]
platform_color = Color(0.2, 0.8, 0.5, 1)
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 400)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Checkpoint1" parent="." instance=ExtResource("3_cp")]
position = Vector2(1700, 420)
checkpoint_index = 1

[node name="Checkpoint2" parent="." instance=ExtResource("3_cp")]
position = Vector2(3300, 490)
checkpoint_index = 2

[node name="FloorStart" type="StaticBody2D" parent="."]
position = Vector2(350, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorStart"]
shape = SubResource("FloorStart")

[node name="FloorLand" type="StaticBody2D" parent="."]
position = Vector2(3450, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorLand"]
shape = SubResource("FloorLand")

[node name="FloorBoss" type="StaticBody2D" parent="."]
position = Vector2(4700, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorBoss"]
shape = SubResource("FloorBoss")

[node name="AerialPlat1" type="StaticBody2D" parent="."]
position = Vector2(800, 450)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AerialPlat1"]
shape = SubResource("AP1")

[node name="AerialPlat2" type="StaticBody2D" parent="."]
position = Vector2(1030, 370)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AerialPlat2"]
shape = SubResource("AP2")

[node name="AerialPlat3" type="StaticBody2D" parent="."]
position = Vector2(1240, 290)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AerialPlat3"]
shape = SubResource("AP3")

[node name="AerialPlat4" type="StaticBody2D" parent="."]
position = Vector2(1460, 370)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AerialPlat4"]
shape = SubResource("AP4")

[node name="AerialPlat5" type="StaticBody2D" parent="."]
position = Vector2(1700, 450)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AerialPlat5"]
shape = SubResource("AP5")

[node name="AerialPlat6" type="StaticBody2D" parent="."]
position = Vector2(1930, 350)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AerialPlat6"]
shape = SubResource("AP6")

[node name="AerialPlat7" type="StaticBody2D" parent="."]
position = Vector2(2150, 260)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AerialPlat7"]
shape = SubResource("AP7")

[node name="AerialPlat8" type="StaticBody2D" parent="."]
position = Vector2(2390, 360)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AerialPlat8"]
shape = SubResource("AP8")

[node name="AerialPlat9" type="StaticBody2D" parent="."]
position = Vector2(2630, 450)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AerialPlat9"]
shape = SubResource("AP9")

[node name="AerialPlat10" type="StaticBody2D" parent="."]
position = Vector2(2870, 370)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AerialPlat10"]
shape = SubResource("AP10")

[node name="AerialPlat11" type="StaticBody2D" parent="."]
position = Vector2(3100, 460)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AerialPlat11"]
shape = SubResource("AP11")

[node name="Heart" parent="." instance=ExtResource("4_col")]
position = Vector2(1240, 250)
stage_id = 5

[node name="ArmorZaelArms" parent="." instance=ExtResource("4_col")]
position = Vector2(2150, 220)
collectible_type = 2
armor_piece = "arms"

[node name="ClawsZara" parent="." instance=ExtResource("4_col")]
position = Vector2(2870, 330)
collectible_type = 5
ability_id = "claws"

[node name="Galerix" parent="." instance=ExtResource("9_boss")]
position = Vector2(4600, 400)
arena_left = 4100.0
arena_right = 5100.0
arena_floor = 540.0

[node name="Grunt1" parent="." instance=ExtResource("10_grunt")]
position = Vector2(200, 490)

[node name="Grunt2" parent="." instance=ExtResource("10_grunt")]
position = Vector2(3350, 490)

[node name="Grunt3" parent="." instance=ExtResource("10_grunt")]
position = Vector2(3600, 490)

[node name="Grunt4" parent="." instance=ExtResource("10_grunt")]
position = Vector2(3800, 490)

[node name="Flyer1" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1030, 300)

[node name="Flyer2" parent="." instance=ExtResource("11_flyer")]
position = Vector2(2150, 200)

[node name="Flyer3" parent="." instance=ExtResource("11_flyer")]
position = Vector2(2870, 300)

[node name="HUD" parent="." instance=ExtResource("5_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]
[node name="GameOver" parent="." instance=ExtResource("7_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_right = 5300
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

- [ ] **Step 2: Commit**
```bash
git add stages/stage_05/stage_05.tscn
git commit -m "feat: layout stage 05 - travessia aérea (Galerix)"
```

---

## Task 7: Stage 06 — Umbraex (Sombra)

**Files:** Modify `stages/stage_06/stage_06.tscn`

- [ ] **Step 1: Rewrite stage_06.tscn**

```
[gd_scene format=3 uid="uid://stage_06"]

[ext_resource type="Script" path="res://stages/stage_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://checkpoint" path="res://stages/checkpoint.tscn" id="3_cp"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="4_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://umbraex" path="res://characters/bosses/umbraex.tscn" id="9_boss"]
[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="10_grunt"]
[ext_resource type="PackedScene" uid="uid://enemy_flyer" path="res://characters/enemies/enemy_flyer.tscn" id="11_flyer"]

[sub_resource type="RectangleShape2D" id="FloorStart"]
size = Vector2(400, 40)

[sub_resource type="RectangleShape2D" id="FloorMid"]
size = Vector2(600, 40)

[sub_resource type="RectangleShape2D" id="FloorPre"]
size = Vector2(400, 40)

[sub_resource type="RectangleShape2D" id="FloorBoss"]
size = Vector2(1200, 40)

[sub_resource type="RectangleShape2D" id="CeilSlab"]
size = Vector2(800, 40)

[sub_resource type="RectangleShape2D" id="NP1"]
size = Vector2(80, 20)

[sub_resource type="RectangleShape2D" id="NP2"]
size = Vector2(80, 20)

[sub_resource type="RectangleShape2D" id="NP3"]
size = Vector2(80, 20)

[sub_resource type="RectangleShape2D" id="NP4"]
size = Vector2(80, 20)

[sub_resource type="RectangleShape2D" id="NP5"]
size = Vector2(80, 20)

[sub_resource type="RectangleShape2D" id="NP6"]
size = Vector2(80, 20)

[sub_resource type="RectangleShape2D" id="NP7"]
size = Vector2(80, 20)

[sub_resource type="RectangleShape2D" id="NP8"]
size = Vector2(80, 20)

[sub_resource type="RectangleShape2D" id="WP1"]
size = Vector2(120, 20)

[sub_resource type="RectangleShape2D" id="WP2"]
size = Vector2(100, 20)

[sub_resource type="RectangleShape2D" id="WP3"]
size = Vector2(120, 20)

[sub_resource type="RectangleShape2D" id="WP4"]
size = Vector2(100, 20)

[sub_resource type="RectangleShape2D" id="WP5"]
size = Vector2(120, 20)

[sub_resource type="RectangleShape2D" id="WP6"]
size = Vector2(100, 20)

[node name="Stage06" type="Node2D"]
platform_color = Color(0.25, 0.1, 0.4, 1)
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 400)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Checkpoint1" parent="." instance=ExtResource("3_cp")]
position = Vector2(1900, 490)
checkpoint_index = 1

[node name="Checkpoint2" parent="." instance=ExtResource("3_cp")]
position = Vector2(3700, 490)
checkpoint_index = 2

[node name="FloorStart" type="StaticBody2D" parent="."]
position = Vector2(200, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorStart"]
shape = SubResource("FloorStart")

[node name="FloorMid" type="StaticBody2D" parent="."]
position = Vector2(2000, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorMid"]
shape = SubResource("FloorMid")

[node name="FloorPre" type="StaticBody2D" parent="."]
position = Vector2(3800, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorPre"]
shape = SubResource("FloorPre")

[node name="FloorBoss" type="StaticBody2D" parent="."]
position = Vector2(4700, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorBoss"]
shape = SubResource("FloorBoss")

[node name="CeilingSlab" type="StaticBody2D" parent="."]
position = Vector2(1400, 240)
[node name="CollisionShape2D" type="CollisionShape2D" parent="CeilingSlab"]
shape = SubResource("CeilSlab")

[node name="NarrowPlat1" type="StaticBody2D" parent="."]
position = Vector2(500, 460)
[node name="CollisionShape2D" type="CollisionShape2D" parent="NarrowPlat1"]
shape = SubResource("NP1")

[node name="NarrowPlat2" type="StaticBody2D" parent="."]
position = Vector2(680, 400)
[node name="CollisionShape2D" type="CollisionShape2D" parent="NarrowPlat2"]
shape = SubResource("NP2")

[node name="NarrowPlat3" type="StaticBody2D" parent="."]
position = Vector2(860, 340)
[node name="CollisionShape2D" type="CollisionShape2D" parent="NarrowPlat3"]
shape = SubResource("NP3")

[node name="NarrowPlat4" type="StaticBody2D" parent="."]
position = Vector2(1040, 380)
[node name="CollisionShape2D" type="CollisionShape2D" parent="NarrowPlat4"]
shape = SubResource("NP4")

[node name="NarrowPlat5" type="StaticBody2D" parent="."]
position = Vector2(1220, 340)
[node name="CollisionShape2D" type="CollisionShape2D" parent="NarrowPlat5"]
shape = SubResource("NP5")

[node name="NarrowPlat6" type="StaticBody2D" parent="."]
position = Vector2(1400, 380)
[node name="CollisionShape2D" type="CollisionShape2D" parent="NarrowPlat6"]
shape = SubResource("NP6")

[node name="NarrowPlat7" type="StaticBody2D" parent="."]
position = Vector2(1580, 340)
[node name="CollisionShape2D" type="CollisionShape2D" parent="NarrowPlat7"]
shape = SubResource("NP7")

[node name="NarrowPlat8" type="StaticBody2D" parent="."]
position = Vector2(1760, 380)
[node name="CollisionShape2D" type="CollisionShape2D" parent="NarrowPlat8"]
shape = SubResource("NP8")

[node name="WidePlat1" type="StaticBody2D" parent="."]
position = Vector2(2100, 420)
[node name="CollisionShape2D" type="CollisionShape2D" parent="WidePlat1"]
shape = SubResource("WP1")

[node name="WidePlat2" type="StaticBody2D" parent="."]
position = Vector2(2400, 360)
[node name="CollisionShape2D" type="CollisionShape2D" parent="WidePlat2"]
shape = SubResource("WP2")

[node name="WidePlat3" type="StaticBody2D" parent="."]
position = Vector2(2700, 420)
[node name="CollisionShape2D" type="CollisionShape2D" parent="WidePlat3"]
shape = SubResource("WP3")

[node name="WidePlat4" type="StaticBody2D" parent="."]
position = Vector2(3000, 360)
[node name="CollisionShape2D" type="CollisionShape2D" parent="WidePlat4"]
shape = SubResource("WP4")

[node name="WidePlat5" type="StaticBody2D" parent="."]
position = Vector2(3300, 420)
[node name="CollisionShape2D" type="CollisionShape2D" parent="WidePlat5"]
shape = SubResource("WP5")

[node name="WidePlat6" type="StaticBody2D" parent="."]
position = Vector2(3600, 380)
[node name="CollisionShape2D" type="CollisionShape2D" parent="WidePlat6"]
shape = SubResource("WP6")

[node name="Heart" parent="." instance=ExtResource("4_col")]
position = Vector2(860, 300)
stage_id = 6

[node name="SubTank" parent="." instance=ExtResource("4_col")]
position = Vector2(1400, 340)
collectible_type = 1
subtank_index = 2

[node name="ArmorZaraArms" parent="." instance=ExtResource("4_col")]
position = Vector2(2700, 380)
collectible_type = 3
armor_piece = "arms"

[node name="LaserZael" parent="." instance=ExtResource("4_col")]
position = Vector2(3300, 380)
collectible_type = 4
ability_id = "laser"

[node name="Umbraex" parent="." instance=ExtResource("9_boss")]
position = Vector2(4600, 400)
arena_left = 4100.0
arena_right = 5100.0
arena_floor = 540.0

[node name="Grunt1" parent="." instance=ExtResource("10_grunt")]
position = Vector2(200, 490)

[node name="Grunt2" parent="." instance=ExtResource("10_grunt")]
position = Vector2(350, 490)

[node name="Grunt3" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2100, 490)

[node name="Grunt4" parent="." instance=ExtResource("10_grunt")]
position = Vector2(3700, 490)

[node name="Flyer1" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1220, 300)

[node name="Flyer2" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1580, 300)

[node name="HUD" parent="." instance=ExtResource("5_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]
[node name="GameOver" parent="." instance=ExtResource("7_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_right = 5300
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

- [ ] **Step 2: Commit**
```bash
git add stages/stage_06/stage_06.tscn
git commit -m "feat: layout stage 06 - corredor sombrio (Umbraex)"
```

---

## Task 8: Stage 07 — Luxar (Luz)

**Files:** Modify `stages/stage_07/stage_07.tscn`

- [ ] **Step 1: Rewrite stage_07.tscn**

```
[gd_scene format=3 uid="uid://stage_07"]

[ext_resource type="Script" path="res://stages/stage_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://checkpoint" path="res://stages/checkpoint.tscn" id="3_cp"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="4_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://luxar" path="res://characters/bosses/luxar.tscn" id="9_boss"]
[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="10_grunt"]
[ext_resource type="PackedScene" uid="uid://enemy_flyer" path="res://characters/enemies/enemy_flyer.tscn" id="11_flyer"]

[sub_resource type="RectangleShape2D" id="FloorStart"]
size = Vector2(600, 40)

[sub_resource type="RectangleShape2D" id="Arena"]
size = Vector2(1400, 40)

[sub_resource type="RectangleShape2D" id="SP1"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="SP2"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="SP3"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="SP4"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="SP5"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="SP6"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="SP7"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="SP8"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="SP9"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="SP10"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="SP11"]
size = Vector2(250, 20)

[sub_resource type="RectangleShape2D" id="SP12"]
size = Vector2(200, 20)

[node name="Stage07" type="Node2D"]
platform_color = Color(1.0, 0.85, 0.2, 1)
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 400)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Checkpoint1" parent="." instance=ExtResource("3_cp")]
position = Vector2(1700, 190)
checkpoint_index = 1

[node name="Checkpoint2" parent="." instance=ExtResource("3_cp")]
position = Vector2(3100, 180)
checkpoint_index = 2

[node name="FloorStart" type="StaticBody2D" parent="."]
position = Vector2(300, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorStart"]
shape = SubResource("FloorStart")

[node name="ArenaPlatform" type="StaticBody2D" parent="."]
position = Vector2(4500, 220)
[node name="CollisionShape2D" type="CollisionShape2D" parent="ArenaPlatform"]
shape = SubResource("Arena")

[node name="SpiralPlat1" type="StaticBody2D" parent="."]
position = Vector2(700, 460)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat1"]
shape = SubResource("SP1")

[node name="SpiralPlat2" type="StaticBody2D" parent="."]
position = Vector2(950, 400)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat2"]
shape = SubResource("SP2")

[node name="SpiralPlat3" type="StaticBody2D" parent="."]
position = Vector2(1200, 340)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat3"]
shape = SubResource("SP3")

[node name="SpiralPlat4" type="StaticBody2D" parent="."]
position = Vector2(1450, 280)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat4"]
shape = SubResource("SP4")

[node name="SpiralPlat5" type="StaticBody2D" parent="."]
position = Vector2(1700, 220)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat5"]
shape = SubResource("SP5")

[node name="SpiralPlat6" type="StaticBody2D" parent="."]
position = Vector2(1950, 160)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat6"]
shape = SubResource("SP6")

[node name="SpiralPlat7" type="StaticBody2D" parent="."]
position = Vector2(2200, 100)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat7"]
shape = SubResource("SP7")

[node name="SpiralPlat8" type="StaticBody2D" parent="."]
position = Vector2(2500, 140)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat8"]
shape = SubResource("SP8")

[node name="SpiralPlat9" type="StaticBody2D" parent="."]
position = Vector2(2800, 180)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat9"]
shape = SubResource("SP9")

[node name="SpiralPlat10" type="StaticBody2D" parent="."]
position = Vector2(3100, 210)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat10"]
shape = SubResource("SP10")

[node name="SpiralPlat11" type="StaticBody2D" parent="."]
position = Vector2(3400, 210)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat11"]
shape = SubResource("SP11")

[node name="SpiralPlat12" type="StaticBody2D" parent="."]
position = Vector2(3750, 210)
[node name="CollisionShape2D" type="CollisionShape2D" parent="SpiralPlat12"]
shape = SubResource("SP12")

[node name="Heart" parent="." instance=ExtResource("4_col")]
position = Vector2(1200, 300)
stage_id = 7

[node name="ArmorZaelLegs" parent="." instance=ExtResource("4_col")]
position = Vector2(2200, 60)
collectible_type = 2
armor_piece = "legs"

[node name="WarAxeZara" parent="." instance=ExtResource("4_col")]
position = Vector2(2800, 140)
collectible_type = 5
ability_id = "war_axe"

[node name="Luxar" parent="." instance=ExtResource("9_boss")]
position = Vector2(4600, 170)
arena_left = 3800.0
arena_right = 5200.0
arena_floor = 200.0

[node name="Grunt1" parent="." instance=ExtResource("10_grunt")]
position = Vector2(300, 490)

[node name="Grunt2" parent="." instance=ExtResource("10_grunt")]
position = Vector2(500, 490)

[node name="Grunt3" parent="." instance=ExtResource("10_grunt")]
position = Vector2(1200, 310)

[node name="Grunt4" parent="." instance=ExtResource("10_grunt")]
position = Vector2(3100, 180)

[node name="Flyer1" parent="." instance=ExtResource("11_flyer")]
position = Vector2(2100, 80)

[node name="Flyer2" parent="." instance=ExtResource("11_flyer")]
position = Vector2(2600, 120)

[node name="HUD" parent="." instance=ExtResource("5_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]
[node name="GameOver" parent="." instance=ExtResource("7_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_right = 5300
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

- [ ] **Step 2: Commit**
```bash
git add stages/stage_07/stage_07.tscn
git commit -m "feat: layout stage 07 - espiral ascendente (Luxar)"
```

---

## Task 9: Stage 08 — Terragor (Terra)

**Files:** Modify `stages/stage_08/stage_08.tscn`

- [ ] **Step 1: Rewrite stage_08.tscn**

```
[gd_scene format=3 uid="uid://stage_08"]

[ext_resource type="Script" path="res://stages/stage_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://checkpoint" path="res://stages/checkpoint.tscn" id="3_cp"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="4_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://terragor" path="res://characters/bosses/terragor.tscn" id="9_boss"]
[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="10_grunt"]
[ext_resource type="PackedScene" uid="uid://enemy_flyer" path="res://characters/enemies/enemy_flyer.tscn" id="11_flyer"]

[sub_resource type="RectangleShape2D" id="FloorStart"]
size = Vector2(700, 40)

[sub_resource type="RectangleShape2D" id="CaveFloorA"]
size = Vector2(800, 40)

[sub_resource type="RectangleShape2D" id="CaveFloorB"]
size = Vector2(600, 40)

[sub_resource type="RectangleShape2D" id="FloorReturn"]
size = Vector2(600, 40)

[sub_resource type="RectangleShape2D" id="FloorBoss"]
size = Vector2(1200, 40)

[sub_resource type="RectangleShape2D" id="CWL1"]
size = Vector2(40, 200)

[sub_resource type="RectangleShape2D" id="CWR1"]
size = Vector2(40, 200)

[sub_resource type="RectangleShape2D" id="CDP1"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="CDP2"]
size = Vector2(180, 20)

[sub_resource type="RectangleShape2D" id="CM1"]
size = Vector2(220, 20)

[sub_resource type="RectangleShape2D" id="CM2"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="CEP1"]
size = Vector2(180, 20)

[sub_resource type="RectangleShape2D" id="CEP2"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="PB1"]
size = Vector2(220, 20)

[sub_resource type="RectangleShape2D" id="PB2"]
size = Vector2(200, 20)

[node name="Stage08" type="Node2D"]
platform_color = Color(0.5, 0.35, 0.15, 1)
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 400)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Checkpoint1" parent="." instance=ExtResource("3_cp")]
position = Vector2(1800, 650)
checkpoint_index = 1

[node name="Checkpoint2" parent="." instance=ExtResource("3_cp")]
position = Vector2(3400, 490)
checkpoint_index = 2

[node name="FloorStart" type="StaticBody2D" parent="."]
position = Vector2(350, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorStart"]
shape = SubResource("FloorStart")

[node name="CaveFloorA" type="StaticBody2D" parent="."]
position = Vector2(1550, 700)
[node name="CollisionShape2D" type="CollisionShape2D" parent="CaveFloorA"]
shape = SubResource("CaveFloorA")

[node name="CaveFloorB" type="StaticBody2D" parent="."]
position = Vector2(2650, 700)
[node name="CollisionShape2D" type="CollisionShape2D" parent="CaveFloorB"]
shape = SubResource("CaveFloorB")

[node name="FloorReturn" type="StaticBody2D" parent="."]
position = Vector2(3350, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorReturn"]
shape = SubResource("FloorReturn")

[node name="FloorBoss" type="StaticBody2D" parent="."]
position = Vector2(4700, 560)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorBoss"]
shape = SubResource("FloorBoss")

[node name="CaveWallLeft" type="StaticBody2D" parent="."]
position = Vector2(730, 630)
[node name="CollisionShape2D" type="CollisionShape2D" parent="CaveWallLeft"]
shape = SubResource("CWL1")

[node name="CaveWallRight" type="StaticBody2D" parent="."]
position = Vector2(3070, 630)
[node name="CollisionShape2D" type="CollisionShape2D" parent="CaveWallRight"]
shape = SubResource("CWR1")

[node name="DescentPlat1" type="StaticBody2D" parent="."]
position = Vector2(800, 600)
[node name="CollisionShape2D" type="CollisionShape2D" parent="DescentPlat1"]
shape = SubResource("CDP1")

[node name="DescentPlat2" type="StaticBody2D" parent="."]
position = Vector2(990, 660)
[node name="CollisionShape2D" type="CollisionShape2D" parent="DescentPlat2"]
shape = SubResource("CDP2")

[node name="CaveMidPlat1" type="StaticBody2D" parent="."]
position = Vector2(2050, 670)
[node name="CollisionShape2D" type="CollisionShape2D" parent="CaveMidPlat1"]
shape = SubResource("CM1")

[node name="CaveMidPlat2" type="StaticBody2D" parent="."]
position = Vector2(2250, 670)
[node name="CollisionShape2D" type="CollisionShape2D" parent="CaveMidPlat2"]
shape = SubResource("CM2")

[node name="AscentPlat1" type="StaticBody2D" parent="."]
position = Vector2(3010, 650)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AscentPlat1"]
shape = SubResource("CEP1")

[node name="AscentPlat2" type="StaticBody2D" parent="."]
position = Vector2(3200, 590)
[node name="CollisionShape2D" type="CollisionShape2D" parent="AscentPlat2"]
shape = SubResource("CEP2")

[node name="PreBossPlat1" type="StaticBody2D" parent="."]
position = Vector2(3700, 420)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PreBossPlat1"]
shape = SubResource("PB1")

[node name="PreBossPlat2" type="StaticBody2D" parent="."]
position = Vector2(3950, 380)
[node name="CollisionShape2D" type="CollisionShape2D" parent="PreBossPlat2"]
shape = SubResource("PB2")

[node name="Heart" parent="." instance=ExtResource("4_col")]
position = Vector2(2050, 630)
stage_id = 8

[node name="SubTank" parent="." instance=ExtResource("4_col")]
position = Vector2(2650, 650)
collectible_type = 1
subtank_index = 3

[node name="ArmorZaraLegs" parent="." instance=ExtResource("4_col")]
position = Vector2(3200, 550)
collectible_type = 3
armor_piece = "legs"

[node name="CannonZael" parent="." instance=ExtResource("4_col")]
position = Vector2(3500, 490)
collectible_type = 4
ability_id = "cannon"

[node name="Terragor" parent="." instance=ExtResource("9_boss")]
position = Vector2(4600, 400)
arena_left = 4100.0
arena_right = 5100.0
arena_floor = 540.0

[node name="Grunt1" parent="." instance=ExtResource("10_grunt")]
position = Vector2(300, 490)

[node name="Grunt2" parent="." instance=ExtResource("10_grunt")]
position = Vector2(1600, 660)

[node name="Grunt3" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2700, 660)

[node name="Grunt4" parent="." instance=ExtResource("10_grunt")]
position = Vector2(3500, 490)

[node name="Flyer1" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1900, 600)

[node name="HUD" parent="." instance=ExtResource("5_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]
[node name="GameOver" parent="." instance=ExtResource("7_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_right = 5300
limit_bottom = 750
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

- [ ] **Step 2: Commit**
```bash
git add stages/stage_08/stage_08.tscn
git commit -m "feat: layout stage 08 - caverna subterrânea (Terragor)"
```

---

## Task 10: Web Export + Push

- [ ] **Step 1: Export web build**
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" export/web/index.html
```

- [ ] **Step 2: Commit and push**
```bash
git add export/web/
git commit -m "build: web export com layouts redesenhados das stages 01-08"
git push
```
