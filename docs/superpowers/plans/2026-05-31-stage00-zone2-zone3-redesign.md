# Stage 00 — Redesign Zona 2 e Zona 3 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir a geometria plana das Zonas 2 e 3 do Stage 00 pelo design "A Escalada" (Z2) + "Interior Elevado" (Z3), conforme spec `docs/superpowers/specs/2026-05-30-stage00-zone2-zone3-redesign.md`.

**Architecture:** Edição direta do `.tscn` (texto) para adicionar/remover StaticBody2D + CollisionShape2D; edição do `.gd` para atualizar constantes de inimigos, triggers de zona, referências ao Boss_LWall e lógica de porta do Corr3.

**Tech Stack:** Godot 4 GDScript, `.tscn` text format

---

## Posições de referência (y)

| Superfície | y topo (game units) | Nota |
|-----------|---------------------|------|
| Chão original | 1088 | floor de Z1, MiniBoss, boss arena |
| Step_Z2_1 | 848 | primeiro degrau |
| Step_Z2_2 | 656 | segundo degrau |
| Step_Z2_3 | 464 | terceiro degrau |
| Float_A / Float_C | 360 | plats flutuantes |
| Float_B | 296 | plat flutuante central (mais alta) |
| Peak / Z3 piso | 280 | topo da escalada = piso interior Z3 |
| Z3 sub-plats | 180–196 | sub-plataformas nas salas |
| Z3 teto (interior) | 80 | teto das salas Z3 e Corr3 elevado |

Grunt center_y = floor_top − 64 (padrão do jogo).

---

## Task 1: Atualizar constantes de inimigos no GDScript

**Files:**
- Modify: `stages/stage_00/stage_00_scene.gd:17-33`

- [ ] **Step 1.1 — Substituir ZONE2_GRUNTS, ZONE2_FLYERS, ZONE3_GRUNTS, ZONE3_FLYERS**

Abrir `stages/stage_00/stage_00_scene.gd` e substituir as quatro constantes:

```gdscript
const ZONE2_GRUNTS := [
	Vector2(8360, 1024), Vector2(8540, 1024),   # Seção 1 — Entrada
	Vector2(9090, 592),                           # Seção 2 — Degrau 2
	Vector2(9892, 296), Vector2(10292, 232), Vector2(10692, 296),  # Seção 3 — Flutuantes
	Vector2(10960, 216), Vector2(11260, 152),
	Vector2(11460, 152), Vector2(11760, 152),    # Seção 4 — Patamar
]
const ZONE2_FLYERS := [
	Vector2(8950, 700), Vector2(9250, 520),      # entre degraus
	Vector2(10000, 250), Vector2(10400, 250),    # entre flutuantes
	Vector2(11340, 90),  Vector2(11940, 90),     # sobre patamar
]

const ZONE3_GRUNTS := [
	Vector2(13080, 216), Vector2(13260, 216),   # Entrada
	Vector2(13560, 132),                          # Sala A — sub-plat
	Vector2(14000, 116), Vector2(14200, 116),   # Sala B — sub-plat
	Vector2(14620, 132), Vector2(14820, 132),   # Sala C — sub-plat
	Vector2(15340, 216), Vector2(15800, 216),   # Continuação
]
const ZONE3_FLYERS := [
	Vector2(13620, 165),  # Sala A
	Vector2(14100, 165),  # Sala B
]
```

- [ ] **Step 1.2 — Commit**

```bash
git add stages/stage_00/stage_00_scene.gd
git commit -m "fix(stage00): atualizar posições de inimigos Z2 e Z3 redesenhadas"
```

---

## Task 2: Atualizar zone triggers

**Files:**
- Modify: `stages/stage_00/stage_00_scene.gd` — função `_setup_zone_triggers`

- [ ] **Step 2.1 — Substituir os três triggers**

Localizar `func _setup_zone_triggers()` e substituir o corpo:

```gdscript
func _setup_zone_triggers() -> void:
	# Zone 1: x 0–5800
	var z1 := _make_zone_trigger(2900, 800, 5800, 1200)
	z1.body_entered.connect(_on_zone1_entered)
	z1.body_exited.connect(_on_zone1_exited)
	add_child(z1)

	# Zone 2: x 8222–12922 (redesenhada — player pode estar em y=280)
	var z2 := _make_zone_trigger(10572, 600, 4700, 1400)
	z2.body_entered.connect(_on_zone2_entered)
	z2.body_exited.connect(_on_zone2_exited)
	add_child(z2)

	# Zone 3: x 12922–16492 (interior elevado — player em y=280)
	var z3 := _make_zone_trigger(14707, 300, 3570, 800)
	z3.body_entered.connect(_on_zone3_entered)
	z3.body_exited.connect(_on_zone3_exited)
	add_child(z3)
```

- [ ] **Step 2.2 — Commit**

```bash
git add stages/stage_00/stage_00_scene.gd
git commit -m "fix(stage00): atualizar zone triggers para novo layout Z2/Z3"
```

---

## Task 3: Atualizar referências ao Boss_LWall no GDScript

**Files:**
- Modify: `stages/stage_00/stage_00_scene.gd` — `_ready()` e `_on_boss_door_opened()`

- [ ] **Step 3.1 — Atualizar _ready() para desabilitar ambos os segmentos**

Localizar este trecho em `_ready()`:

```gdscript
	# Boss_LWall collision starts disabled — only re-enabled once boss door opens
	var lwall := $Boss_LWall
	lwall.get_node("CollisionShape2D").disabled = true
```

Substituir por:

```gdscript
	# Boss_LWall split em Top/Bot — colisão começa desabilitada
	for lwall_name: String in ["Boss_LWall_Top", "Boss_LWall_Bot"]:
		var lwall := get_node_or_null(lwall_name)
		if lwall:
			lwall.get_node("CollisionShape2D").disabled = true
```

- [ ] **Step 3.2 — Atualizar _on_boss_door_opened() para reabilitar ambos**

Localizar em `_on_boss_door_opened`:

```gdscript
	await get_tree().create_timer(1.0).timeout
	var lwall := $Boss_LWall
	if is_instance_valid(lwall):
		lwall.get_node("CollisionShape2D").set_deferred("disabled", false)
```

Substituir por:

```gdscript
	await get_tree().create_timer(1.0).timeout
	for lwall_name: String in ["Boss_LWall_Top", "Boss_LWall_Bot"]:
		var lwall := get_node_or_null(lwall_name)
		if is_instance_valid(lwall):
			lwall.get_node("CollisionShape2D").set_deferred("disabled", false)
```

- [ ] **Step 3.3 — Commit**

```bash
git add stages/stage_00/stage_00_scene.gd
git commit -m "fix(stage00): adaptar Boss_LWall split Top/Bot no código"
```

---

## Task 4: Atualizar porta e checkpoint do Corr3 elevado

**Files:**
- Modify: `stages/stage_00/stage_00_scene.gd`

O Corr3 agora está em y=280 (piso). O centro interior é y=212. A porta e o checkpoint precisam refletir isso.

- [ ] **Step 4.1 — Adicionar constante _CORR3_DOOR_CY**

Logo após as constantes `_DOOR_*` existentes, adicionar:

```gdscript
const _CORR3_DOOR_CY := 212.0   # centro do Corr3 elevado: (80+344)/2
```

- [ ] **Step 4.2 — Atualizar _setup_doors() para usar nova altura**

Localizar `func _setup_doors()`:

```gdscript
func _setup_doors() -> void:
	var cp2_entry := _make_door(CP2_ENTRY_X)
	cp2_entry.connect("door_opening", _on_door_opening)
	cp2_entry.connect("door_opened",  _on_cp2_entry_opened.bind(cp2_entry))
	_doors.append(cp2_entry)

	var boss_door := _make_door(CP2_EXIT_X)
	boss_door.connect("door_opened",  _on_boss_door_opened.bind(boss_door))
	_doors.append(boss_door)
```

Substituir por:

```gdscript
func _setup_doors() -> void:
	var cp2_entry := _make_door(CP2_ENTRY_X, _CORR3_DOOR_CY)
	cp2_entry.connect("door_opening", _on_door_opening)
	cp2_entry.connect("door_opened",  _on_cp2_entry_opened.bind(cp2_entry))
	_doors.append(cp2_entry)

	var boss_door := _make_door(CP2_EXIT_X, _CORR3_DOOR_CY)
	boss_door.connect("door_opened",  _on_boss_door_opened.bind(boss_door))
	_doors.append(boss_door)
```

- [ ] **Step 4.3 — Atualizar _make_door para aceitar cy opcional**

Localizar assinatura de `_make_door`:

```gdscript
func _make_door(x: float) -> CheckpointDoor:
	var door := _DOOR_SCENE.instantiate() as CheckpointDoor
	door.position    = Vector2(x, _DOOR_CY)
```

Substituir por:

```gdscript
func _make_door(x: float, cy: float = _DOOR_CY) -> CheckpointDoor:
	var door := _DOOR_SCENE.instantiate() as CheckpointDoor
	door.position    = Vector2(x, cy)
```

- [ ] **Step 4.4 — Atualizar checkpoint save position**

Localizar em `_on_cp2_entry_opened`:

```gdscript
	StageManager.save_checkpoint(Vector2(CP2_EXIT_X + 128, 992), 2)
```

Substituir por:

```gdscript
	StageManager.save_checkpoint(Vector2(CP2_EXIT_X + 128, 184), 2)
```

(y=184 = piso Corr3 y=280 − 96, mesma lógica do checkpoint original em relação ao piso.)

- [ ] **Step 4.5 — Commit**

```bash
git add stages/stage_00/stage_00_scene.gd
git commit -m "fix(stage00): porta e checkpoint do Corr3 elevados para y=212/184"
```

---

## Task 5: Atualizar _draw_platforms para Boss_LWall_Top/Bot

**Files:**
- Modify: `stages/stage_00/stage_00_scene.gd` — função `_draw_platforms`

- [ ] **Step 5.1 — Adicionar case para Boss_LWall_Top e Boss_LWall_Bot**

Localizar em `_draw_platforms`:

```gdscript
			elif n.begins_with("Corr") or n.begins_with("Boss_") or n.begins_with("MiniBoss_"):
				_draw_room_tiles(rect, n)
```

Substituir por:

```gdscript
			elif n == "Boss_LWall_Top" or n == "Boss_LWall_Bot":
				_draw_room_tiles(rect, "Boss_LWall")
			elif n.begins_with("Corr") or n.begins_with("Boss_") or n.begins_with("MiniBoss_"):
				_draw_room_tiles(rect, n)
```

Isso faz os dois segmentos renderizarem com o tile de parede esquerda correto.

- [ ] **Step 5.2 — Commit**

```bash
git add stages/stage_00/stage_00_scene.gd
git commit -m "fix(stage00): _draw_platforms trata Boss_LWall_Top/Bot como parede esquerda"
```

---

## Task 6: Remover 16 nós antigos do stage_00.tscn

**Files:**
- Modify: `stages/stage_00/stage_00.tscn`

Remover os blocos `[sub_resource ...]` e `[node ...]` correspondentes (cada nó tem 1 sub_resource + 1 StaticBody2D + 1 CollisionShape2D filho).

- [ ] **Step 6.1 — Remover sub_resources das zonas antigas**

No `.tscn`, apagar os seguintes blocos `[sub_resource]` (cada um tem 2 linhas):

```
[sub_resource type="RectangleShape2D" id="shape_FloorPilar"]
[sub_resource type="RectangleShape2D" id="shape_FloorZ2A"]
[sub_resource type="RectangleShape2D" id="shape_BlockZ2A"]
[sub_resource type="RectangleShape2D" id="shape_PlatZ2B"]
[sub_resource type="RectangleShape2D" id="shape_PlatZ2C"]
[sub_resource type="RectangleShape2D" id="shape_PlatDesc1"]
[sub_resource type="RectangleShape2D" id="shape_FloorZ3Start"]
[sub_resource type="RectangleShape2D" id="shape_PlatZ3A"]
[sub_resource type="RectangleShape2D" id="shape_FloorZ3B"]
[sub_resource type="RectangleShape2D" id="shape_FloorZ3C"]
[sub_resource type="RectangleShape2D" id="shape_LedgeA"]
[sub_resource type="RectangleShape2D" id="shape_PilarA"]
[sub_resource type="RectangleShape2D" id="shape_LedgeB"]
[sub_resource type="RectangleShape2D" id="shape_PilarB"]
[sub_resource type="RectangleShape2D" id="shape_LedgeC"]
[sub_resource type="RectangleShape2D" id="shape_PilarC"]
```

Também remover `[sub_resource type="RectangleShape2D" id="shape_BossLWall"]` (será substituído por Top/Bot).

- [ ] **Step 6.2 — Remover blocos de nós das zonas antigas**

Apagar os três blocos `[node ...]` + filho para cada um dos seguintes StaticBody2D:

```
Floor_Pilar, Floor_Z2A, Block_Z2A, Plat_Z2B, Plat_Z2C, Plat_Desc1
Floor_Z3Start, Plat_Z3A, Floor_Z3B, Floor_Z3C
Ledge_A, Pilar_A, Ledge_B, Pilar_B, Ledge_C, Pilar_C
Boss_LWall
```

Cada bloco a remover tem o formato:
```
[node name="Floor_Pilar" type="StaticBody2D" parent="."]
position = Vector2(...)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Floor_Pilar"]
shape = SubResource("shape_FloorPilar")
```

- [ ] **Step 6.3 — Commit**

```bash
git add stages/stage_00/stage_00.tscn
git commit -m "chore(stage00): remover 16 nós antigos das Zonas 2 e 3"
```

---

## Task 7: Adicionar geometria da Zona 2 ao TSCN

**Files:**
- Modify: `stages/stage_00/stage_00.tscn`

Inserir após o bloco `[sub_resource ... id="shape_LBoundary"]` todos os sub_resources, e após os nós existentes todos os nós novos (antes do `[node name="Camera2D" ...]`).

- [ ] **Step 7.1 — Adicionar sub_resources da Zona 2**

```
[sub_resource type="RectangleShape2D" id="shape_FloorZ2Entry"]
size = Vector2(478, 64)

[sub_resource type="RectangleShape2D" id="shape_StepZ2_1"]
size = Vector2(320, 240)

[sub_resource type="RectangleShape2D" id="shape_StepZ2_2"]
size = Vector2(320, 432)

[sub_resource type="RectangleShape2D" id="shape_StepZ2_3"]
size = Vector2(320, 624)

[sub_resource type="RectangleShape2D" id="shape_PlatZ2FloatA"]
size = Vector2(384, 64)

[sub_resource type="RectangleShape2D" id="shape_PlatZ2FloatB"]
size = Vector2(384, 64)

[sub_resource type="RectangleShape2D" id="shape_PlatZ2FloatC"]
size = Vector2(384, 64)

[sub_resource type="RectangleShape2D" id="shape_FloorZ2Peak"]
size = Vector2(1300, 64)

[sub_resource type="RectangleShape2D" id="shape_SubPlatZ2_1"]
size = Vector2(320, 64)

[sub_resource type="RectangleShape2D" id="shape_SubPlatZ2_2"]
size = Vector2(320, 64)

[sub_resource type="RectangleShape2D" id="shape_CoverZ2"]
size = Vector2(192, 128)

[sub_resource type="RectangleShape2D" id="shape_FloorZ2Trans"]
size = Vector2(722, 64)
```

- [ ] **Step 7.2 — Adicionar nós da Zona 2**

```
[node name="Floor_Z2_Entry" type="StaticBody2D" parent="."]
position = Vector2(8461, 1120)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Floor_Z2_Entry"]
shape = SubResource("shape_FloorZ2Entry")

[node name="Step_Z2_1" type="StaticBody2D" parent="."]
position = Vector2(8860, 968)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Step_Z2_1"]
shape = SubResource("shape_StepZ2_1")

[node name="Step_Z2_2" type="StaticBody2D" parent="."]
position = Vector2(9160, 872)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Step_Z2_2"]
shape = SubResource("shape_StepZ2_2")

[node name="Step_Z2_3" type="StaticBody2D" parent="."]
position = Vector2(9460, 776)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Step_Z2_3"]
shape = SubResource("shape_StepZ2_3")

[node name="Plat_Z2_Float_A" type="StaticBody2D" parent="."]
position = Vector2(9892, 392)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat_Z2_Float_A"]
shape = SubResource("shape_PlatZ2FloatA")

[node name="Plat_Z2_Float_B" type="StaticBody2D" parent="."]
position = Vector2(10292, 328)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat_Z2_Float_B"]
shape = SubResource("shape_PlatZ2FloatB")

[node name="Plat_Z2_Float_C" type="StaticBody2D" parent="."]
position = Vector2(10692, 392)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat_Z2_Float_C"]
shape = SubResource("shape_PlatZ2FloatC")

[node name="Floor_Z2_Peak" type="StaticBody2D" parent="."]
position = Vector2(11550, 312)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Floor_Z2_Peak"]
shape = SubResource("shape_FloorZ2Peak")

[node name="SubPlat_Z2_1" type="StaticBody2D" parent="."]
position = Vector2(11260, 248)

[node name="CollisionShape2D" type="CollisionShape2D" parent="SubPlat_Z2_1"]
shape = SubResource("shape_SubPlatZ2_1")

[node name="SubPlat_Z2_2" type="StaticBody2D" parent="."]
position = Vector2(11860, 248)

[node name="CollisionShape2D" type="CollisionShape2D" parent="SubPlat_Z2_2"]
shape = SubResource("shape_SubPlatZ2_2")

[node name="Cover_Z2" type="StaticBody2D" parent="."]
position = Vector2(11496, 280)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Cover_Z2"]
shape = SubResource("shape_CoverZ2")

[node name="Floor_Z2_Trans" type="StaticBody2D" parent="."]
position = Vector2(12561, 312)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Floor_Z2_Trans"]
shape = SubResource("shape_FloorZ2Trans")
```

- [ ] **Step 7.3 — Commit**

```bash
git add stages/stage_00/stage_00.tscn
git commit -m "feat(stage00): adicionar geometria Zona 2 redesenhada (escalada)"
```

---

## Task 8: Adicionar geometria da Zona 3 ao TSCN

**Files:**
- Modify: `stages/stage_00/stage_00.tscn`

- [ ] **Step 8.1 — Adicionar sub_resources da Zona 3**

```
[sub_resource type="RectangleShape2D" id="shape_CorrZ3EntryFloor"]
size = Vector2(478, 64)

[sub_resource type="RectangleShape2D" id="shape_CorrZ3EntryCeil"]
size = Vector2(478, 64)

[sub_resource type="RectangleShape2D" id="shape_CorrZ3EntryWallL"]
size = Vector2(64, 264)

[sub_resource type="RectangleShape2D" id="shape_CorrZ3RoomsCeil"]
size = Vector2(1800, 64)

[sub_resource type="RectangleShape2D" id="shape_CorrZ3RoomsFloor"]
size = Vector2(1800, 64)

[sub_resource type="RectangleShape2D" id="shape_DivZ3_1Top"]
size = Vector2(64, 82)

[sub_resource type="RectangleShape2D" id="shape_DivZ3_1Bot"]
size = Vector2(64, 124)

[sub_resource type="RectangleShape2D" id="shape_DivZ3_2Top"]
size = Vector2(64, 82)

[sub_resource type="RectangleShape2D" id="shape_DivZ3_2Bot"]
size = Vector2(64, 124)

[sub_resource type="RectangleShape2D" id="shape_DivZ3_3Top"]
size = Vector2(64, 82)

[sub_resource type="RectangleShape2D" id="shape_DivZ3_3Bot"]
size = Vector2(64, 124)

[sub_resource type="RectangleShape2D" id="shape_SubPlatZ3A"]
size = Vector2(240, 48)

[sub_resource type="RectangleShape2D" id="shape_SubPlatZ3B"]
size = Vector2(320, 48)

[sub_resource type="RectangleShape2D" id="shape_SubPlatZ3C"]
size = Vector2(320, 48)

[sub_resource type="RectangleShape2D" id="shape_SubPlatZ3D"]
size = Vector2(120, 48)

[sub_resource type="RectangleShape2D" id="shape_CorrZ3ContFloor"]
size = Vector2(1292, 64)

[sub_resource type="RectangleShape2D" id="shape_CorrZ3ContCeil"]
size = Vector2(1292, 64)
```

- [ ] **Step 8.2 — Adicionar nós da Zona 3**

```
[node name="CorrZ3_Entry_Floor" type="StaticBody2D" parent="."]
position = Vector2(13161, 312)

[node name="CollisionShape2D" type="CollisionShape2D" parent="CorrZ3_Entry_Floor"]
shape = SubResource("shape_CorrZ3EntryFloor")

[node name="CorrZ3_Entry_Ceil" type="StaticBody2D" parent="."]
position = Vector2(13161, 112)

[node name="CollisionShape2D" type="CollisionShape2D" parent="CorrZ3_Entry_Ceil"]
shape = SubResource("shape_CorrZ3EntryCeil")

[node name="CorrZ3_Entry_Wall_L" type="StaticBody2D" parent="."]
position = Vector2(12890, 212)

[node name="CollisionShape2D" type="CollisionShape2D" parent="CorrZ3_Entry_Wall_L"]
shape = SubResource("shape_CorrZ3EntryWallL")

[node name="CorrZ3_Rooms_Ceil" type="StaticBody2D" parent="."]
position = Vector2(14300, 112)

[node name="CollisionShape2D" type="CollisionShape2D" parent="CorrZ3_Rooms_Ceil"]
shape = SubResource("shape_CorrZ3RoomsCeil")

[node name="CorrZ3_Rooms_Floor" type="StaticBody2D" parent="."]
position = Vector2(14300, 312)

[node name="CollisionShape2D" type="CollisionShape2D" parent="CorrZ3_Rooms_Floor"]
shape = SubResource("shape_CorrZ3RoomsFloor")

[node name="Div_Z3_1_Top" type="StaticBody2D" parent="."]
position = Vector2(13832, 121)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Div_Z3_1_Top"]
shape = SubResource("shape_DivZ3_1Top")

[node name="Div_Z3_1_Bot" type="StaticBody2D" parent="."]
position = Vector2(13832, 282)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Div_Z3_1_Bot"]
shape = SubResource("shape_DivZ3_1Bot")

[node name="Div_Z3_2_Top" type="StaticBody2D" parent="."]
position = Vector2(14432, 121)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Div_Z3_2_Top"]
shape = SubResource("shape_DivZ3_2Top")

[node name="Div_Z3_2_Bot" type="StaticBody2D" parent="."]
position = Vector2(14432, 282)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Div_Z3_2_Bot"]
shape = SubResource("shape_DivZ3_2Bot")

[node name="Div_Z3_3_Top" type="StaticBody2D" parent="."]
position = Vector2(15032, 121)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Div_Z3_3_Top"]
shape = SubResource("shape_DivZ3_3Top")

[node name="Div_Z3_3_Bot" type="StaticBody2D" parent="."]
position = Vector2(15032, 282)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Div_Z3_3_Bot"]
shape = SubResource("shape_DivZ3_3Bot")

[node name="SubPlat_Z3_A" type="StaticBody2D" parent="."]
position = Vector2(13600, 220)

[node name="CollisionShape2D" type="CollisionShape2D" parent="SubPlat_Z3_A"]
shape = SubResource("shape_SubPlatZ3A")

[node name="SubPlat_Z3_B" type="StaticBody2D" parent="."]
position = Vector2(14120, 204)

[node name="CollisionShape2D" type="CollisionShape2D" parent="SubPlat_Z3_B"]
shape = SubResource("shape_SubPlatZ3B")

[node name="SubPlat_Z3_C" type="StaticBody2D" parent="."]
position = Vector2(14720, 220)

[node name="CollisionShape2D" type="CollisionShape2D" parent="SubPlat_Z3_C"]
shape = SubResource("shape_SubPlatZ3C")

[node name="SubPlat_Z3_D" type="StaticBody2D" parent="."]
position = Vector2(15124, 204)

[node name="CollisionShape2D" type="CollisionShape2D" parent="SubPlat_Z3_D"]
shape = SubResource("shape_SubPlatZ3D")

[node name="CorrZ3_Cont_Floor" type="StaticBody2D" parent="."]
position = Vector2(15846, 312)

[node name="CollisionShape2D" type="CollisionShape2D" parent="CorrZ3_Cont_Floor"]
shape = SubResource("shape_CorrZ3ContFloor")

[node name="CorrZ3_Cont_Ceil" type="StaticBody2D" parent="."]
position = Vector2(15846, 112)

[node name="CollisionShape2D" type="CollisionShape2D" parent="CorrZ3_Cont_Ceil"]
shape = SubResource("shape_CorrZ3ContCeil")
```

- [ ] **Step 8.3 — Commit**

```bash
git add stages/stage_00/stage_00.tscn
git commit -m "feat(stage00): adicionar geometria Zona 3 redesenhada (interior elevado)"
```

---

## Task 9: Atualizar Corr3 (nós Corr2_*) no TSCN

**Files:**
- Modify: `stages/stage_00/stage_00.tscn`

Os nós `Corr2_Floor`, `Corr2_Ceil`, `Corr2_Wall_L`, `Corr2_Wall_R` mantêm os nomes mas mudam de posição/tamanho para acompanhar o Corr3 elevado.

- [ ] **Step 9.1 — Atualizar shape_Corr2WallL e shape_Corr2WallR**

Localizar:
```
[sub_resource type="RectangleShape2D" id="shape_Corr2WallL"]
size = Vector2(64, 384)

[sub_resource type="RectangleShape2D" id="shape_Corr2WallR"]
size = Vector2(64, 384)
```

Substituir por:
```
[sub_resource type="RectangleShape2D" id="shape_Corr2WallL"]
size = Vector2(64, 264)

[sub_resource type="RectangleShape2D" id="shape_Corr2WallR"]
size = Vector2(64, 264)
```

- [ ] **Step 9.2 — Atualizar posições dos quatro nós Corr2_***

Localizar e substituir:

```
[node name="Corr2_Floor" type="StaticBody2D" parent="."]
position = Vector2(16822, 1120)
```
→ `position = Vector2(16822, 312)`

```
[node name="Corr2_Ceil" type="StaticBody2D" parent="."]
position = Vector2(16822, 800)
```
→ `position = Vector2(16822, 112)`

```
[node name="Corr2_Wall_L" type="StaticBody2D" parent="."]
position = Vector2(16492, 960)
```
→ `position = Vector2(16492, 212)`

```
[node name="Corr2_Wall_R" type="StaticBody2D" parent="."]
position = Vector2(17152, 960)
```
→ `position = Vector2(17152, 212)`

- [ ] **Step 9.3 — Commit**

```bash
git add stages/stage_00/stage_00.tscn
git commit -m "fix(stage00): elevar Corr3 para y=280 (Corr2_* nodes reposicionados)"
```

---

## Task 10: Dividir Boss_LWall em Top + Bot no TSCN

**Files:**
- Modify: `stages/stage_00/stage_00.tscn`

- [ ] **Step 10.1 — Adicionar sub_resources para os dois segmentos**

```
[sub_resource type="RectangleShape2D" id="shape_BossLWallTop"]
size = Vector2(64, 200)

[sub_resource type="RectangleShape2D" id="shape_BossLWallBot"]
size = Vector2(64, 816)
```

- [ ] **Step 10.2 — Adicionar nós Boss_LWall_Top e Boss_LWall_Bot**

```
[node name="Boss_LWall_Top" type="StaticBody2D" parent="."]
position = Vector2(17124, -20)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Boss_LWall_Top"]
shape = SubResource("shape_BossLWallTop")

[node name="Boss_LWall_Bot" type="StaticBody2D" parent="."]
position = Vector2(17124, 752)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Boss_LWall_Bot"]
shape = SubResource("shape_BossLWallBot")
```

- [ ] **Step 10.3 — Commit**

```bash
git add stages/stage_00/stage_00.tscn
git commit -m "feat(stage00): dividir Boss_LWall em Top+Bot para abertura do Corr3 elevado"
```

---

## Task 11: Teste manual e web export

- [ ] **Step 11.1 — Abrir o jogo e testar**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --path "C:/Users/Usuário/SnesGame"
```

Verificar:
- Player aparece no spawn (dentro do Corr2, x≈7600)
- Zona 2: degraus sobem corretamente, plataformas flutuantes estão no ar sem chão abaixo
- Patamar alto (y≈280) com sub-plataformas e cover visíveis
- Zona 3: teto aparece ao entrar em x≈12922, passagens P1/P2/P3 permitem traversal
- Corr3 posicionado em altura, portas em y=212
- Player cai na sala do boss ao passar pelo Corr3
- Boss_LWall_Bot veda o lado esquerdo quando a luta começa

- [ ] **Step 11.2 — Mover PlayerSpawn para Zona 2 entrada (teste da escalada)**

Para testar a Zona 2 do início, temporariamente mover o `PlayerSpawn` no `.tscn`:

```
[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(8300, 1024)
```

(Reverter para `Vector2(7600, 992)` após o teste ou deixar em 8300 se preferir.)

- [ ] **Step 11.3 — Web export**

Usar a skill `/web-export` para exportar e publicar no GitHub Pages.

- [ ] **Step 11.4 — Commit final se houver ajustes**

```bash
git add stages/stage_00/stage_00.tscn stages/stage_00/stage_00_scene.gd
git commit -m "fix(stage00): ajustes pós-teste zona 2/3 redesign"
```
