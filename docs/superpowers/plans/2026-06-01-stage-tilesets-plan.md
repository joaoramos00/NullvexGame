# Stage Tilesets 01–09 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gerar 40 tilesets PixelLab (8 stages × 4 zonas + 8 paredes lisas), integrar ao `stage_scene.gd` com seleção automática de zona por posição de plataforma, e adicionar suporte por sala ao `stage_09_scene.gd`.

**Architecture:** `stage_scene.gd` carrega tilesets dinamicamente por `load()` usando `StageManager.current_stage_id` — zero mudanças em .tscn. Zona é selecionada pela posição X (ou Y para stages verticais) da plataforma, detectado automaticamente. `stage_09_scene.gd` mapeia cada plataforma à sala do boss correspondente usando posições dos `_walls`.

**Tech Stack:** GDScript 4, PixelLab MCP (`create_sidescroller_tileset`, `get_sidescroller_tileset`), `tools/pixellab_download.py`, PowerShell.

**Spec:** `docs/superpowers/specs/2026-06-01-stage-tilesets-design.md`

> **Nota sobre .tscn:** O spec original previa updates nos arquivos `.tscn` para atribuir `zone_tilesets` via `@export`. Esta implementação usa **dynamic loading** (`load()` com `StageManager.current_stage_id`) eliminando completamente a necessidade de editar qualquer `.tscn`. O `smooth_texture` gerado por stage é para uso futuro em `CorridorSection` — não é exposto como `@export` em `stage_scene.gd` nesta versão.

---

## Estrutura de Arquivos

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `stages/stage_scene.gd` | Modificar | Adicionar carga dinâmica de zone_tilesets + funções de tile rendering |
| `stages/stage_09/stage_09_scene.gd` | Modificar | Adicionar room_tilesets + room detection + tile rendering |
| `stages/stage_01/Stage_01T_z1-z4.png` | Criar | Tilesets gerados pelo PixelLab (4 zonas) |
| `stages/stage_01/stage_01_glass.png` | Criar | Tileset parede lisa stage 01 |
| `stages/stage_02/` … `stages/stage_08/` | Criar | Mesma estrutura (5 PNGs por stage) |

---

## Task 1: Extend stage_scene.gd — zone tileset rendering

**Files:**
- Modify: `stages/stage_scene.gd`

- [ ] **Step 1: Substituir o conteúdo de stage_scene.gd**

Reescrever o arquivo completo com suporte a tilesets de zona:

```gdscript
extends Node2D

const ZAEL_SCENE := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE := preload("res://characters/melee/zara.tscn")

const _TS     := 64   # tamanho de destino no mundo (game units)
const _SRC_TS := 32   # tamanho do tile no PNG (pixels)

@export var platform_color: Color = Color(0.35, 0.35, 0.35)

var _player: CharacterBase
var _zone_tilesets: Array[Texture2D] = []
var _zone_min: float = 0.0
var _zone_max: float = 1.0
var _zone_use_y: bool = false

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
	$Camera2D.zoom = Vector2(2.2, 2.2)
	AudioManager.play_bgm(AudioLibrary.get_stage_bgm(StageManager.current_stage_id))
	_load_zone_data()
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

func _load_zone_data() -> void:
	var id := StageManager.current_stage_id
	if id < 1 or id > 8:
		return
	for z in range(1, 5):
		var path := "res://stages/stage_%02d/Stage_%02dT_z%d.png" % [id, id, z]
		if ResourceLoader.exists(path):
			_zone_tilesets.append(load(path) as Texture2D)
	if _zone_tilesets.is_empty():
		return
	var min_x := INF as float
	var max_x := -INF as float
	var min_y := INF as float
	var max_y := -INF as float
	for child in get_children():
		if not child is StaticBody2D:
			continue
		var p: Vector2 = (child as Node2D).position
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	_zone_use_y = (max_y - min_y) > (max_x - min_x)
	_zone_min = min_y if _zone_use_y else min_x
	_zone_max = max_y if _zone_use_y else max_x

func _get_zone_tileset(center: Vector2) -> Texture2D:
	if _zone_tilesets.is_empty():
		return null
	var span := _zone_max - _zone_min
	if span <= 0.0:
		return _zone_tilesets[0]
	var t := (center.y - _zone_min) / span if _zone_use_y else (center.x - _zone_min) / span
	var idx := mini(maxi(0, int(t * _zone_tilesets.size())), _zone_tilesets.size() - 1)
	return _zone_tilesets[idx]

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
			var rect := Rect2(center - size * 0.5, size)
			var tex := _get_zone_tileset(center)
			if tex != null:
				_draw_platform_tiles(rect, tex)
			else:
				draw_rect(rect, platform_color)

func _draw_platform_tiles(rect: Rect2, tex: Texture2D) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	var cols := ceili(rect.size.x / ts)
	var rows := ceili(rect.size.y / ts)
	for row in rows:
		for col in cols:
			var tile := _tile_at(col, cols, row, rows)
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts - src_ts
			var dh := minf(ts, rect.position.y + rect.size.y - dy)
			if cols > 1:
				var fill := _gap_fill_tile(row, rows)
				if col == 0:
					dx -= src_ts
					draw_texture_rect_region(tex,
						Rect2(rect.position.x + ts / 2.0, dy, ts / 2.0, dh),
						Rect2(fill.x * src_ts, fill.y * src_ts, src_ts / 2, src_ts))
				elif col == cols - 1:
					dx += src_ts
					draw_texture_rect_region(tex,
						Rect2(rect.position.x + (cols - 1) * ts, dy, ts / 2.0, dh),
						Rect2(fill.x * src_ts + src_ts / 2, fill.y * src_ts, src_ts / 2, src_ts))
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var src := Rect2(tile.x * src_ts, tile.y * src_ts, src_ts * dw / ts, src_ts * dh / ts)
			draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh), src)

func _gap_fill_tile(row: int, rows: int) -> Vector2i:
	if row == 0:        return Vector2i(3, 0)
	if row == rows - 1: return Vector2i(1, 2)
	return Vector2i(2, 1)

func _tile_at(col: int, cols: int, row: int, rows: int) -> Vector2i:
	var is_left   := col == cols - 1
	var is_right  := col == 0
	var is_top    := row == rows - 1
	var is_bottom := row == 0
	if cols == 1:
		if is_top:    return Vector2i(1, 2)
		if is_bottom: return Vector2i(3, 0)
		return Vector2i(2, 1)
	if rows == 1:
		if is_left:  return Vector2i(0, 0)
		if is_right: return Vector2i(1, 3)
		return Vector2i(3, 0)
	if is_top:
		if is_left:  return Vector2i(3, 3)
		if is_right: return Vector2i(0, 2)
		return Vector2i(1, 2)
	if is_bottom:
		if is_left:  return Vector2i(0, 0)
		if is_right: return Vector2i(1, 3)
		return Vector2i(3, 0)
	if is_left:  return Vector2i(3, 2)
	if is_right: return Vector2i(1, 0)
	return Vector2i(2, 1)
```

- [ ] **Step 2: Verificar que os testes headless existentes ainda passam**

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```

Expected: todos os testes terminam com exit code 0. Se algum falhar, não prosseguir — investigar a causa antes de commitar.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_scene.gd
git commit -m "feat(stage_scene): zone tileset rendering — dynamic load by stage_id, auto orientation detect"
```

---

## Task 2: Extend stage_09_scene.gd — room tileset rendering

**Files:**
- Modify: `stages/stage_09/stage_09_scene.gd`

- [ ] **Step 1: Substituir o conteúdo de stage_09_scene.gd**

```gdscript
extends Node2D

const ZAEL_SCENE := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE := preload("res://characters/melee/zara.tscn")

const _TS     := 64
const _SRC_TS := 32

var _player: CharacterBase
var _bosses: Array[BossBase] = []
var _walls: Array[StaticBody2D] = []
var _room_tilesets: Array[Texture2D] = []

func _ready() -> void:
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")
	_player = _spawn_player()
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)
	StageManager.spawn_position = $PlayerSpawn.global_position
	_collect_nodes()
	_setup_bosses()
	_load_room_tilesets()
	AudioManager.play_bgm(AudioLibrary.bgm_gauntlet)
	queue_redraw()

func _collect_nodes() -> void:
	for bname: String in ["Ignarath", "Cryovex", "Voltrix", "Gravitus", "Galerix", "Umbraex", "Luxar", "Terragor"]:
		_bosses.append(get_node(bname) as BossBase)
	for wname: String in ["Wall1", "Wall2", "Wall3", "Wall4", "Wall5", "Wall6", "Wall7"]:
		_walls.append(get_node(wname) as StaticBody2D)

func _load_room_tilesets() -> void:
	for id in range(1, 9):
		var path := "res://stages/stage_%02d/Stage_%02dT_z1.png" % [id, id]
		if ResourceLoader.exists(path):
			_room_tilesets.append(load(path) as Texture2D)
		else:
			_room_tilesets.append(null)

func _setup_bosses() -> void:
	for i in _bosses.size():
		var boss := _bosses[i]
		boss.player = _player
		boss.stage_id = -1
		boss.ability_id = ""
		var idx_arr := [i]
		boss.boss_defeated.connect(func(_ab: String): _on_boss_defeated(idx_arr[0]))

func _on_boss_defeated(idx: int) -> void:
	if idx < _walls.size():
		_walls[idx].queue_free()
	if idx == _bosses.size() - 1:
		_finish_gauntlet()

func _finish_gauntlet() -> void:
	GameManager.complete_stage(9)
	GameManager.save_game()

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

func _get_room_idx(center_x: float) -> int:
	var wall_xs: Array[float] = []
	for w in _walls:
		if is_instance_valid(w):
			wall_xs.append(w.position.x)
	wall_xs.sort()
	var idx: int = 0
	for wx in wall_xs:
		if center_x > wx:
			idx += 1
	return mini(idx, _room_tilesets.size() - 1)

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
			var rect := Rect2(center - size * 0.5, size)
			if not _room_tilesets.is_empty():
				var room_idx := _get_room_idx(center.x)
				var tex: Texture2D = _room_tilesets[room_idx]
				if tex != null:
					_draw_platform_tiles(rect, tex)
					continue
			draw_rect(rect, Color(0.35, 0.35, 0.35))

func _draw_platform_tiles(rect: Rect2, tex: Texture2D) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	var cols := ceili(rect.size.x / ts)
	var rows := ceili(rect.size.y / ts)
	for row in rows:
		for col in cols:
			var tile := _tile_at(col, cols, row, rows)
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts - src_ts
			var dh := minf(ts, rect.position.y + rect.size.y - dy)
			if cols > 1:
				var fill := _gap_fill_tile(row, rows)
				if col == 0:
					dx -= src_ts
					draw_texture_rect_region(tex,
						Rect2(rect.position.x + ts / 2.0, dy, ts / 2.0, dh),
						Rect2(fill.x * src_ts, fill.y * src_ts, src_ts / 2, src_ts))
				elif col == cols - 1:
					dx += src_ts
					draw_texture_rect_region(tex,
						Rect2(rect.position.x + (cols - 1) * ts, dy, ts / 2.0, dh),
						Rect2(fill.x * src_ts + src_ts / 2, fill.y * src_ts, src_ts / 2, src_ts))
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var src := Rect2(tile.x * src_ts, tile.y * src_ts, src_ts * dw / ts, src_ts * dh / ts)
			draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh), src)

func _gap_fill_tile(row: int, rows: int) -> Vector2i:
	if row == 0:        return Vector2i(3, 0)
	if row == rows - 1: return Vector2i(1, 2)
	return Vector2i(2, 1)

func _tile_at(col: int, cols: int, row: int, rows: int) -> Vector2i:
	var is_left   := col == cols - 1
	var is_right  := col == 0
	var is_top    := row == rows - 1
	var is_bottom := row == 0
	if cols == 1:
		if is_top:    return Vector2i(1, 2)
		if is_bottom: return Vector2i(3, 0)
		return Vector2i(2, 1)
	if rows == 1:
		if is_left:  return Vector2i(0, 0)
		if is_right: return Vector2i(1, 3)
		return Vector2i(3, 0)
	if is_top:
		if is_left:  return Vector2i(3, 3)
		if is_right: return Vector2i(0, 2)
		return Vector2i(1, 2)
	if is_bottom:
		if is_left:  return Vector2i(0, 0)
		if is_right: return Vector2i(1, 3)
		return Vector2i(3, 0)
	if is_left:  return Vector2i(3, 2)
	if is_right: return Vector2i(1, 0)
	return Vector2i(2, 1)
```

- [ ] **Step 2: Verificar testes headless**

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```

Expected: exit code 0 em todos.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_09/stage_09_scene.gd
git commit -m "feat(stage_09): room tileset rendering — dynamic load per boss room via wall positions"
```

---

## Task 3: Gerar tilesets — Stage 01 (Ignarath / Fogo)

**Files:**
- Create: `stages/stage_01/Stage_01T_z1.png` … `Stage_01T_z4.png`, `stage_01_glass.png`

**Parâmetros de geração:**

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_01T_z1.png` | `"volcanic rock, dark basalt, glowing magma veins, lava cracks"` | `"cracked burnt rock top surface, glowing lava pools"` |
| `Stage_01T_z2.png` | `"magma tunnel walls, lava tube interior, glowing orange cracks in dark rock"` | `"dripping lava top surface, molten rock edge"` |
| `Stage_01T_z3.png` | `"industrial forge interior, molten metal panels, fire furnace brickwork"` | `"scorched metal grating top surface, fire embers"` |
| `Stage_01T_z4.png` | `"full molten chamber walls, volcanic rock submerged in lava, extreme heat"` | `"lava overflow top surface, melting rock edge"` |
| `stage_01_glass.png` | `"polished dark obsidian wall, heat shimmer surface, smooth volcanic glass"` | `"clean obsidian top edge, heat shimmer"` |

- [ ] **Step 1: Checar créditos PixelLab** (apenas necessário na primeira tarefa de geração)

Chamar `mcp__pixellab__get_balance`. Verificar que há créditos suficientes antes de prosseguir. Cada tileset consome aproximadamente 1 geração de subscrição.

- [ ] **Step 2: Submeter job z1**

Chamar `mcp__pixellab__create_sidescroller_tileset` com:
```json
{
  "lower_description": "volcanic rock, dark basalt, glowing magma veins, lava cracks",
  "transition_description": "cracked burnt rock top surface, glowing lava pools",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
Anotar o `tileset_id` retornado como **Z1_ID**.

- [ ] **Step 3: Submeter job glass** (independente, pode ser submetido em paralelo)

Chamar `mcp__pixellab__create_sidescroller_tileset` com:
```json
{
  "lower_description": "polished dark obsidian wall, heat shimmer surface, smooth volcanic glass",
  "transition_description": "clean obsidian top edge, heat shimmer",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
Anotar `tileset_id` como **GLASS_ID**.

- [ ] **Step 4: Baixar e renomear z1**

```powershell
python tools/pixellab_download.py tileset <Z1_ID> stages/stage_01/
Rename-Item stages/stage_01/tileset.png Stage_01T_z1.png
```

O script faz poll automático (~100s). Expected: `stages/stage_01/Stage_01T_z1.png` criado.

- [ ] **Step 5: Obter base_tile_id de z1**

Chamar `mcp__pixellab__get_sidescroller_tileset` com `tileset_id: <Z1_ID>`. Anotar o campo `base_tile_id` da resposta como **BASE_Z1**.

- [ ] **Step 6: Submeter job z2 com encadeamento**

Chamar `mcp__pixellab__create_sidescroller_tileset` com:
```json
{
  "lower_description": "magma tunnel walls, lava tube interior, glowing orange cracks in dark rock",
  "transition_description": "dripping lava top surface, molten rock edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z1>"
}
```
Anotar `tileset_id` como **Z2_ID**.

- [ ] **Step 7: Baixar e renomear z2**

```powershell
python tools/pixellab_download.py tileset <Z2_ID> stages/stage_01/
Rename-Item stages/stage_01/tileset.png Stage_01T_z2.png
```

- [ ] **Step 8: Obter base_tile_id de z2, submeter z3**

Chamar `mcp__pixellab__get_sidescroller_tileset` com `tileset_id: <Z2_ID>`. Anotar `base_tile_id` como **BASE_Z2**.

Chamar `mcp__pixellab__create_sidescroller_tileset` com:
```json
{
  "lower_description": "industrial forge interior, molten metal panels, fire furnace brickwork",
  "transition_description": "scorched metal grating top surface, fire embers",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z2>"
}
```
Anotar `tileset_id` como **Z3_ID**.

- [ ] **Step 9: Baixar e renomear z3**

```powershell
python tools/pixellab_download.py tileset <Z3_ID> stages/stage_01/
Rename-Item stages/stage_01/tileset.png Stage_01T_z3.png
```

- [ ] **Step 10: Obter base_tile_id de z3, submeter z4**

Chamar `mcp__pixellab__get_sidescroller_tileset` com `tileset_id: <Z3_ID>`. Anotar `base_tile_id` como **BASE_Z3**.

Chamar `mcp__pixellab__create_sidescroller_tileset` com:
```json
{
  "lower_description": "full molten chamber walls, volcanic rock submerged in lava, extreme heat",
  "transition_description": "lava overflow top surface, melting rock edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z3>"
}
```
Anotar `tileset_id` como **Z4_ID**.

- [ ] **Step 11: Baixar e renomear z4 e glass**

```powershell
python tools/pixellab_download.py tileset <Z4_ID> stages/stage_01/
Rename-Item stages/stage_01/tileset.png Stage_01T_z4.png

python tools/pixellab_download.py tileset <GLASS_ID> stages/stage_01/
Rename-Item stages/stage_01/tileset.png stage_01_glass.png
```

- [ ] **Step 12: Remover tileset legado, verificar arquivos e commitar**

O arquivo `Stage_01T.png` existia antes desta tarefa. Removê-lo pois é substituído pelos novos zN:

```powershell
Remove-Item stages/stage_01/Stage_01T.png -ErrorAction SilentlyContinue
ls stages/stage_01/
# Expected: Stage_01T_z1.png, Stage_01T_z2.png, Stage_01T_z3.png, Stage_01T_z4.png, stage_01_glass.png
# Stage_01T.png NÃO deve aparecer
```

```bash
git add stages/stage_01/
git commit -m "assets(stage_01): PixelLab tilesets — 4 zonas fogo + parede lisa (remove legado Stage_01T.png)"
```

---

## Task 4: Gerar tilesets — Stage 02 (Cryovex / Gelo)

**Files:**
- Create: `stages/stage_02/Stage_02T_z1.png` … `Stage_02T_z4.png`, `stage_02_glass.png`

**Parâmetros de geração:**

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_02T_z1.png` | `"frozen tundra stone, snow-covered rock, pale ice blue surface"` | `"snow top surface, frost crystal edge"` |
| `Stage_02T_z2.png` | `"ice cave walls, blue crystal formations embedded in rock, frost veins"` | `"crystal shard top surface, icy frost"` |
| `Stage_02T_z3.png` | `"deep glacier interior, compressed blue ice, translucent frozen stone"` | `"fractured ice top surface, glacier edge"` |
| `Stage_02T_z4.png` | `"pure crystal chamber walls, deep blue reflective ice panels"` | `"mirror ice top surface, cold light reflection"` |
| `stage_02_glass.png` | `"smooth translucent ice panel, glass-clear frozen surface, pale blue"` | `"clean frost top edge, ice glass"` |

- [ ] **Step 1: Submeter job z1**

Chamar `mcp__pixellab__create_sidescroller_tileset`:
```json
{
  "lower_description": "frozen tundra stone, snow-covered rock, pale ice blue surface",
  "transition_description": "snow top surface, frost crystal edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
Anotar `tileset_id` como **Z1_ID**. Submeter também glass:
```json
{
  "lower_description": "smooth translucent ice panel, glass-clear frozen surface, pale blue",
  "transition_description": "clean frost top edge, ice glass",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
Anotar `tileset_id` como **GLASS_ID**.

- [ ] **Step 2: Baixar z1, obter base_tile_id**

```powershell
python tools/pixellab_download.py tileset <Z1_ID> stages/stage_02/
Rename-Item stages/stage_02/tileset.png Stage_02T_z1.png
```
Chamar `mcp__pixellab__get_sidescroller_tileset(<Z1_ID>)`. Anotar `base_tile_id` como **BASE_Z1**.

- [ ] **Step 3: Submeter z2 (com base_tile_id), baixar, obter base para z3**

Submeter z2:
```json
{
  "lower_description": "ice cave walls, blue crystal formations embedded in rock, frost veins",
  "transition_description": "crystal shard top surface, icy frost",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z1>"
}
```
Anotar como **Z2_ID**. Baixar:
```powershell
python tools/pixellab_download.py tileset <Z2_ID> stages/stage_02/
Rename-Item stages/stage_02/tileset.png Stage_02T_z2.png
```
Chamar `get_sidescroller_tileset(<Z2_ID>)`. Anotar `base_tile_id` como **BASE_Z2**.

- [ ] **Step 4: Submeter z3 (com BASE_Z2), baixar, obter base para z4**

Submeter z3:
```json
{
  "lower_description": "deep glacier interior, compressed blue ice, translucent frozen stone",
  "transition_description": "fractured ice top surface, glacier edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z2>"
}
```
Anotar como **Z3_ID**. Baixar:
```powershell
python tools/pixellab_download.py tileset <Z3_ID> stages/stage_02/
Rename-Item stages/stage_02/tileset.png Stage_02T_z3.png
```
Chamar `get_sidescroller_tileset(<Z3_ID>)`. Anotar `base_tile_id` como **BASE_Z3**.

- [ ] **Step 5: Submeter z4 (com BASE_Z3), baixar z4 e glass, commitar**

Submeter z4:
```json
{
  "lower_description": "pure crystal chamber walls, deep blue reflective ice panels",
  "transition_description": "mirror ice top surface, cold light reflection",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z3>"
}
```
Anotar como **Z4_ID**. Baixar z4 e glass:
```powershell
python tools/pixellab_download.py tileset <Z4_ID> stages/stage_02/
Rename-Item stages/stage_02/tileset.png Stage_02T_z4.png
python tools/pixellab_download.py tileset <GLASS_ID> stages/stage_02/
Rename-Item stages/stage_02/tileset.png stage_02_glass.png
```
Commitar:
```bash
git add stages/stage_02/
git commit -m "assets(stage_02): PixelLab tilesets — 4 zonas gelo + parede lisa"
```

---

## Task 5: Gerar tilesets — Stage 03 (Voltrix / Raio)

**Files:**
- Create: `stages/stage_03/Stage_03T_z1.png` … `Stage_03T_z4.png`, `stage_03_glass.png`

**Parâmetros de geração:**

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_03T_z1.png` | `"overloaded power plant exterior, exposed cables, industrial metal plates"` | `"sparking electric top edge, frayed cable border"` |
| `Stage_03T_z2.png` | `"generator room panels, yellow warning stripes, electric conduit"` | `"electric arc top surface, circuit line border"` |
| `Stage_03T_z3.png` | `"electromagnetic coil chamber, coils on metal walls, electric arcs"` | `"high voltage discharge top surface, coil edge"` |
| `Stage_03T_z4.png` | `"lightning core chamber walls, charged metal panels, plasma field"` | `"lightning bolt top surface, plasma discharge edge"` |
| `stage_03_glass.png` | `"sealed electric panel, brushed conductive metal, smooth wall"` | `"clean metal top edge, electric sheen"` |

- [ ] **Step 1: Submeter z1 e glass**

z1:
```json
{
  "lower_description": "overloaded power plant exterior, exposed cables, industrial metal plates",
  "transition_description": "sparking electric top edge, frayed cable border",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
glass:
```json
{
  "lower_description": "sealed electric panel, brushed conductive metal, smooth wall",
  "transition_description": "clean metal top edge, electric sheen",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
Anotar **Z1_ID** e **GLASS_ID**.

- [ ] **Step 2: Baixar z1, obter base, submeter z2**

```powershell
python tools/pixellab_download.py tileset <Z1_ID> stages/stage_03/
Rename-Item stages/stage_03/tileset.png Stage_03T_z1.png
```
Chamar `get_sidescroller_tileset(<Z1_ID>)` → anotar `base_tile_id` como **BASE_Z1**.

Submeter z2 com `base_tile_id: BASE_Z1`:
```json
{
  "lower_description": "generator room panels, yellow warning stripes, electric conduit",
  "transition_description": "electric arc top surface, circuit line border",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z1>"
}
```
Anotar **Z2_ID**.

- [ ] **Step 3: Baixar z2, obter base, submeter z3**

```powershell
python tools/pixellab_download.py tileset <Z2_ID> stages/stage_03/
Rename-Item stages/stage_03/tileset.png Stage_03T_z2.png
```
Chamar `get_sidescroller_tileset(<Z2_ID>)` → **BASE_Z2**.

Submeter z3 com `base_tile_id: BASE_Z2`:
```json
{
  "lower_description": "electromagnetic coil chamber, coils on metal walls, electric arcs",
  "transition_description": "high voltage discharge top surface, coil edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z2>"
}
```
Anotar **Z3_ID**.

- [ ] **Step 4: Baixar z3, obter base, submeter z4**

```powershell
python tools/pixellab_download.py tileset <Z3_ID> stages/stage_03/
Rename-Item stages/stage_03/tileset.png Stage_03T_z3.png
```
Chamar `get_sidescroller_tileset(<Z3_ID>)` → **BASE_Z3**.

Submeter z4 com `base_tile_id: BASE_Z3`:
```json
{
  "lower_description": "lightning core chamber walls, charged metal panels, plasma field",
  "transition_description": "lightning bolt top surface, plasma discharge edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z3>"
}
```
Anotar **Z4_ID**.

- [ ] **Step 5: Baixar z4 e glass, commitar**

```powershell
python tools/pixellab_download.py tileset <Z4_ID> stages/stage_03/
Rename-Item stages/stage_03/tileset.png Stage_03T_z4.png
python tools/pixellab_download.py tileset <GLASS_ID> stages/stage_03/
Rename-Item stages/stage_03/tileset.png stage_03_glass.png
```
```bash
git add stages/stage_03/
git commit -m "assets(stage_03): PixelLab tilesets — 4 zonas raio + parede lisa"
```

---

## Task 6: Gerar tilesets — Stage 04 (Gravitus / Gravidade)

**Files:**
- Create: `stages/stage_04/Stage_04T_z1.png` … `Stage_04T_z4.png`, `stage_04_glass.png`

**Parâmetros de geração:**

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_04T_z1.png` | `"space station exterior panels, dark vacuum modules, modular metal structure"` | `"space hull top surface, void edge"` |
| `Stage_04T_z2.png` | `"zero-G corridor, floating stone fragments, dark purple metallic tiles"` | `"anti-gravity shimmer top surface, crumbling stone edge"` |
| `Stage_04T_z3.png` | `"gravity field chamber, deep purple panels, field line etchings"` | `"gravity distortion top surface, field line edge"` |
| `Stage_04T_z4.png` | `"gravity core walls, inverted rock formations, deep purple with energy orbs"` | `"singularity effect top surface, gravitational collapse edge"` |
| `stage_04_glass.png` | `"smooth dark metallic space panel, zero-G module surface, matte grey"` | `"clean dark hull top edge"` |

- [ ] **Step 1: Submeter z1 e glass**

z1:
```json
{
  "lower_description": "space station exterior panels, dark vacuum modules, modular metal structure",
  "transition_description": "space hull top surface, void edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
glass:
```json
{
  "lower_description": "smooth dark metallic space panel, zero-G module surface, matte grey",
  "transition_description": "clean dark hull top edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
Anotar **Z1_ID** e **GLASS_ID**.

- [ ] **Step 2: Baixar z1, obter base, submeter z2**

```powershell
python tools/pixellab_download.py tileset <Z1_ID> stages/stage_04/
Rename-Item stages/stage_04/tileset.png Stage_04T_z1.png
```
`get_sidescroller_tileset(<Z1_ID>)` → **BASE_Z1**. Submeter z2:
```json
{
  "lower_description": "zero-G corridor, floating stone fragments, dark purple metallic tiles",
  "transition_description": "anti-gravity shimmer top surface, crumbling stone edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z1>"
}
```
Anotar **Z2_ID**.

- [ ] **Step 3: Baixar z2, obter base, submeter z3**

```powershell
python tools/pixellab_download.py tileset <Z2_ID> stages/stage_04/
Rename-Item stages/stage_04/tileset.png Stage_04T_z2.png
```
`get_sidescroller_tileset(<Z2_ID>)` → **BASE_Z2**. Submeter z3:
```json
{
  "lower_description": "gravity field chamber, deep purple panels, field line etchings",
  "transition_description": "gravity distortion top surface, field line edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z2>"
}
```
Anotar **Z3_ID**.

- [ ] **Step 4: Baixar z3, obter base, submeter z4**

```powershell
python tools/pixellab_download.py tileset <Z3_ID> stages/stage_04/
Rename-Item stages/stage_04/tileset.png Stage_04T_z3.png
```
`get_sidescroller_tileset(<Z3_ID>)` → **BASE_Z3**. Submeter z4:
```json
{
  "lower_description": "gravity core walls, inverted rock formations, deep purple with energy orbs",
  "transition_description": "singularity effect top surface, gravitational collapse edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z3>"
}
```
Anotar **Z4_ID**.

- [ ] **Step 5: Baixar z4 e glass, commitar**

```powershell
python tools/pixellab_download.py tileset <Z4_ID> stages/stage_04/
Rename-Item stages/stage_04/tileset.png Stage_04T_z4.png
python tools/pixellab_download.py tileset <GLASS_ID> stages/stage_04/
Rename-Item stages/stage_04/tileset.png stage_04_glass.png
```
```bash
git add stages/stage_04/
git commit -m "assets(stage_04): PixelLab tilesets — 4 zonas gravidade + parede lisa"
```

---

## Task 7: Gerar tilesets — Stage 05 (Galerix / Vento)

**Files:**
- Create: `stages/stage_05/Stage_05T_z1.png` … `Stage_05T_z4.png`, `stage_05_glass.png`

**Parâmetros de geração:**

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_05T_z1.png` | `"sky platform stone, wind-carved light grey rock, cloud streak etchings"` | `"wind-blown dust top surface, eroded stone edge"` |
| `Stage_05T_z2.png` | `"wind tunnel walls, polished stone, airflow grooves carved in surface"` | `"air current top surface, wind groove edge"` |
| `Stage_05T_z3.png` | `"storm eye chamber walls, pale teal stone, swirling pattern etchings"` | `"cyclone pattern top surface, storm spiral edge"` |
| `Stage_05T_z4.png` | `"atmospheric core, cloud-white stone panels, high-altitude light"` | `"cloud formation top surface, atmospheric glow edge"` |
| `stage_05_glass.png` | `"aerodynamic smooth surface, wind-polished pale stone, sleek wall"` | `"clean aero top edge, polished surface"` |

- [ ] **Step 1: Submeter z1 e glass**

z1:
```json
{
  "lower_description": "sky platform stone, wind-carved light grey rock, cloud streak etchings",
  "transition_description": "wind-blown dust top surface, eroded stone edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
glass:
```json
{
  "lower_description": "aerodynamic smooth surface, wind-polished pale stone, sleek wall",
  "transition_description": "clean aero top edge, polished surface",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
Anotar **Z1_ID** e **GLASS_ID**.

- [ ] **Step 2: Baixar z1, obter base, submeter z2**

```powershell
python tools/pixellab_download.py tileset <Z1_ID> stages/stage_05/
Rename-Item stages/stage_05/tileset.png Stage_05T_z1.png
```
`get_sidescroller_tileset(<Z1_ID>)` → **BASE_Z1**. Submeter z2:
```json
{
  "lower_description": "wind tunnel walls, polished stone, airflow grooves carved in surface",
  "transition_description": "air current top surface, wind groove edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z1>"
}
```
Anotar **Z2_ID**.

- [ ] **Step 3: Baixar z2, obter base, submeter z3**

```powershell
python tools/pixellab_download.py tileset <Z2_ID> stages/stage_05/
Rename-Item stages/stage_05/tileset.png Stage_05T_z2.png
```
`get_sidescroller_tileset(<Z2_ID>)` → **BASE_Z2**. Submeter z3:
```json
{
  "lower_description": "storm eye chamber walls, pale teal stone, swirling pattern etchings",
  "transition_description": "cyclone pattern top surface, storm spiral edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z2>"
}
```
Anotar **Z3_ID**.

- [ ] **Step 4: Baixar z3, obter base, submeter z4**

```powershell
python tools/pixellab_download.py tileset <Z3_ID> stages/stage_05/
Rename-Item stages/stage_05/tileset.png Stage_05T_z3.png
```
`get_sidescroller_tileset(<Z3_ID>)` → **BASE_Z3**. Submeter z4:
```json
{
  "lower_description": "atmospheric core, cloud-white stone panels, high-altitude light",
  "transition_description": "cloud formation top surface, atmospheric glow edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z3>"
}
```
Anotar **Z4_ID**.

- [ ] **Step 5: Baixar z4 e glass, commitar**

```powershell
python tools/pixellab_download.py tileset <Z4_ID> stages/stage_05/
Rename-Item stages/stage_05/tileset.png Stage_05T_z4.png
python tools/pixellab_download.py tileset <GLASS_ID> stages/stage_05/
Rename-Item stages/stage_05/tileset.png stage_05_glass.png
```
```bash
git add stages/stage_05/
git commit -m "assets(stage_05): PixelLab tilesets — 4 zonas vento + parede lisa"
```

---

## Task 8: Gerar tilesets — Stage 06 (Umbraex / Sombra)

**Files:**
- Create: `stages/stage_06/Stage_06T_z1.png` … `Stage_06T_z4.png`, `stage_06_glass.png`

**Parâmetros de geração:**

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_06T_z1.png` | `"shadow realm entrance stone, black crystalline panels, dark void"` | `"dissolving shadow top surface, dark mist edge"` |
| `Stage_06T_z2.png` | `"dark corridor walls, black and dark purple crystal stone, shadow tendrils"` | `"void tendril top surface, shadow crystal edge"` |
| `Stage_06T_z3.png` | `"void chamber walls, deep black stone, absence of light, dark mist"` | `"void collapse top surface, darkness edge"` |
| `Stage_06T_z4.png` | `"shadow core walls, pure black crystalline panels, shadow energy emanating"` | `"shadow pulse top surface, dark energy edge"` |
| `stage_06_glass.png` | `"smooth black void panel, absorbing dark surface, matte shadow wall"` | `"clean shadow top edge, void surface"` |

- [ ] **Step 1: Submeter z1 e glass**

z1:
```json
{
  "lower_description": "shadow realm entrance stone, black crystalline panels, dark void",
  "transition_description": "dissolving shadow top surface, dark mist edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
glass:
```json
{
  "lower_description": "smooth black void panel, absorbing dark surface, matte shadow wall",
  "transition_description": "clean shadow top edge, void surface",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
Anotar **Z1_ID** e **GLASS_ID**.

- [ ] **Step 2: Baixar z1, obter base, submeter z2**

```powershell
python tools/pixellab_download.py tileset <Z1_ID> stages/stage_06/
Rename-Item stages/stage_06/tileset.png Stage_06T_z1.png
```
`get_sidescroller_tileset(<Z1_ID>)` → **BASE_Z1**. Submeter z2:
```json
{
  "lower_description": "dark corridor walls, black and dark purple crystal stone, shadow tendrils",
  "transition_description": "void tendril top surface, shadow crystal edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z1>"
}
```
Anotar **Z2_ID**.

- [ ] **Step 3: Baixar z2, obter base, submeter z3**

```powershell
python tools/pixellab_download.py tileset <Z2_ID> stages/stage_06/
Rename-Item stages/stage_06/tileset.png Stage_06T_z2.png
```
`get_sidescroller_tileset(<Z2_ID>)` → **BASE_Z2**. Submeter z3:
```json
{
  "lower_description": "void chamber walls, deep black stone, absence of light, dark mist",
  "transition_description": "void collapse top surface, darkness edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z2>"
}
```
Anotar **Z3_ID**.

- [ ] **Step 4: Baixar z3, obter base, submeter z4**

```powershell
python tools/pixellab_download.py tileset <Z3_ID> stages/stage_06/
Rename-Item stages/stage_06/tileset.png Stage_06T_z3.png
```
`get_sidescroller_tileset(<Z3_ID>)` → **BASE_Z3**. Submeter z4:
```json
{
  "lower_description": "shadow core walls, pure black crystalline panels, shadow energy emanating",
  "transition_description": "shadow pulse top surface, dark energy edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z3>"
}
```
Anotar **Z4_ID**.

- [ ] **Step 5: Baixar z4 e glass, commitar**

```powershell
python tools/pixellab_download.py tileset <Z4_ID> stages/stage_06/
Rename-Item stages/stage_06/tileset.png Stage_06T_z4.png
python tools/pixellab_download.py tileset <GLASS_ID> stages/stage_06/
Rename-Item stages/stage_06/tileset.png stage_06_glass.png
```
```bash
git add stages/stage_06/
git commit -m "assets(stage_06): PixelLab tilesets — 4 zonas sombra + parede lisa"
```

---

## Task 9: Gerar tilesets — Stage 07 (Luxar / Luz)

**Files:**
- Create: `stages/stage_07/Stage_07T_z1.png` … `Stage_07T_z4.png`, `stage_07_glass.png`

**Parâmetros de geração:**

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_07T_z1.png` | `"radiant temple stone, white with gold trim, glowing rune etchings"` | `"golden glow top surface, light ray edge"` |
| `Stage_07T_z2.png` | `"light hall panels, white and gold, luminous pillar base veins"` | `"luminous top surface, gold trim edge"` |
| `Stage_07T_z3.png` | `"sacred chamber walls, pure white stone, glowing runic inscriptions"` | `"sacred glow top surface, holy light edge"` |
| `Stage_07T_z4.png` | `"light core walls, blinding white panels, radiant energy embedded in stone"` | `"radiant burst top surface, light overflow edge"` |
| `stage_07_glass.png` | `"polished golden marble surface, luminous smooth wall, divine glow"` | `"clean gold marble top edge"` |

- [ ] **Step 1: Submeter z1 e glass**

z1:
```json
{
  "lower_description": "radiant temple stone, white with gold trim, glowing rune etchings",
  "transition_description": "golden glow top surface, light ray edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
glass:
```json
{
  "lower_description": "polished golden marble surface, luminous smooth wall, divine glow",
  "transition_description": "clean gold marble top edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
Anotar **Z1_ID** e **GLASS_ID**.

- [ ] **Step 2: Baixar z1, obter base, submeter z2**

```powershell
python tools/pixellab_download.py tileset <Z1_ID> stages/stage_07/
Rename-Item stages/stage_07/tileset.png Stage_07T_z1.png
```
`get_sidescroller_tileset(<Z1_ID>)` → **BASE_Z1**. Submeter z2:
```json
{
  "lower_description": "light hall panels, white and gold, luminous pillar base veins",
  "transition_description": "luminous top surface, gold trim edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z1>"
}
```
Anotar **Z2_ID**.

- [ ] **Step 3: Baixar z2, obter base, submeter z3**

```powershell
python tools/pixellab_download.py tileset <Z2_ID> stages/stage_07/
Rename-Item stages/stage_07/tileset.png Stage_07T_z2.png
```
`get_sidescroller_tileset(<Z2_ID>)` → **BASE_Z2**. Submeter z3:
```json
{
  "lower_description": "sacred chamber walls, pure white stone, glowing runic inscriptions",
  "transition_description": "sacred glow top surface, holy light edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z2>"
}
```
Anotar **Z3_ID**.

- [ ] **Step 4: Baixar z3, obter base, submeter z4**

```powershell
python tools/pixellab_download.py tileset <Z3_ID> stages/stage_07/
Rename-Item stages/stage_07/tileset.png Stage_07T_z3.png
```
`get_sidescroller_tileset(<Z3_ID>)` → **BASE_Z3**. Submeter z4:
```json
{
  "lower_description": "light core walls, blinding white panels, radiant energy embedded in stone",
  "transition_description": "radiant burst top surface, light overflow edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z3>"
}
```
Anotar **Z4_ID**.

- [ ] **Step 5: Baixar z4 e glass, commitar**

```powershell
python tools/pixellab_download.py tileset <Z4_ID> stages/stage_07/
Rename-Item stages/stage_07/tileset.png Stage_07T_z4.png
python tools/pixellab_download.py tileset <GLASS_ID> stages/stage_07/
Rename-Item stages/stage_07/tileset.png stage_07_glass.png
```
```bash
git add stages/stage_07/
git commit -m "assets(stage_07): PixelLab tilesets — 4 zonas luz + parede lisa"
```

---

## Task 10: Gerar tilesets — Stage 08 (Terragor / Terra)

**Files:**
- Create: `stages/stage_08/Stage_08T_z1.png` … `Stage_08T_z4.png`, `stage_08_glass.png`

**Parâmetros de geração:**

| Arquivo | lower_description | transition_description |
|---------|-------------------|------------------------|
| `Stage_08T_z1.png` | `"cave entrance rock, rough earth, embedded fossils and roots"` | `"earthy crumbled top surface, root and moss edge"` |
| `Stage_08T_z2.png` | `"deep cave rock layers, mineral veins, dark brown stone"` | `"layered rock top surface, mineral vein edge"` |
| `Stage_08T_z3.png` | `"underground ruins stone blocks, cracked earth, ancient fossils"` | `"ancient ruin top surface, crumbled stone edge"` |
| `Stage_08T_z4.png` | `"earth core stone, compressed deep rock, massive crystal formations"` | `"crystal rock top surface, deep earth edge"` |
| `stage_08_glass.png` | `"smooth compressed stone wall, dense mineral surface, flat cave rock"` | `"clean dense stone top edge"` |

- [ ] **Step 1: Submeter z1 e glass**

z1:
```json
{
  "lower_description": "cave entrance rock, rough earth, embedded fossils and roots",
  "transition_description": "earthy crumbled top surface, root and moss edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
glass:
```json
{
  "lower_description": "smooth compressed stone wall, dense mineral surface, flat cave rock",
  "transition_description": "clean dense stone top edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail"
}
```
Anotar **Z1_ID** e **GLASS_ID**.

- [ ] **Step 2: Baixar z1, obter base, submeter z2**

```powershell
python tools/pixellab_download.py tileset <Z1_ID> stages/stage_08/
Rename-Item stages/stage_08/tileset.png Stage_08T_z1.png
```
`get_sidescroller_tileset(<Z1_ID>)` → **BASE_Z1**. Submeter z2:
```json
{
  "lower_description": "deep cave rock layers, mineral veins, dark brown stone",
  "transition_description": "layered rock top surface, mineral vein edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z1>"
}
```
Anotar **Z2_ID**.

- [ ] **Step 3: Baixar z2, obter base, submeter z3**

```powershell
python tools/pixellab_download.py tileset <Z2_ID> stages/stage_08/
Rename-Item stages/stage_08/tileset.png Stage_08T_z2.png
```
`get_sidescroller_tileset(<Z2_ID>)` → **BASE_Z2**. Submeter z3:
```json
{
  "lower_description": "underground ruins stone blocks, cracked earth, ancient fossils",
  "transition_description": "ancient ruin top surface, crumbled stone edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z2>"
}
```
Anotar **Z3_ID**.

- [ ] **Step 4: Baixar z3, obter base, submeter z4**

```powershell
python tools/pixellab_download.py tileset <Z3_ID> stages/stage_08/
Rename-Item stages/stage_08/tileset.png Stage_08T_z3.png
```
`get_sidescroller_tileset(<Z3_ID>)` → **BASE_Z3**. Submeter z4:
```json
{
  "lower_description": "earth core stone, compressed deep rock, massive crystal formations",
  "transition_description": "crystal rock top surface, deep earth edge",
  "transition_size": 0.25,
  "tile_size": {"width": 32, "height": 32},
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "medium detail",
  "base_tile_id": "<BASE_Z3>"
}
```
Anotar **Z4_ID**.

- [ ] **Step 5: Baixar z4 e glass, commitar**

```powershell
python tools/pixellab_download.py tileset <Z4_ID> stages/stage_08/
Rename-Item stages/stage_08/tileset.png Stage_08T_z4.png
python tools/pixellab_download.py tileset <GLASS_ID> stages/stage_08/
Rename-Item stages/stage_08/tileset.png stage_08_glass.png
```
```bash
git add stages/stage_08/
git commit -m "assets(stage_08): PixelLab tilesets — 4 zonas terra + parede lisa"
```

---

## Task 11: Web export + verificação visual

**Files:**
- No changes

- [ ] **Step 1: Web export**

Invocar a skill `web-export` (ou rodar o comando manualmente):
```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" docs/web/index.html
```

- [ ] **Step 2: Verificar no browser**

Abrir `http://localhost:8080` (ou iniciar servidor se não estiver rodando). Navegar até Stage Select e entrar em stage 01. Verificar:
- Plataformas renderizam com tileset temático (não retângulos cinzas)
- Transição de zona visível ao longo do stage (tileset muda progressivamente)
- Sem erros de console

- [ ] **Step 3: Verificar stage 09**

Entrar no stage 09 (requer stages 01–08 completos via GameManager ou debug). Verificar que cada sala de boss usa o tileset da stage correspondente.

- [ ] **Step 4: Commit final**

```bash
git add .
git commit -m "chore: web export — stage tilesets 01-09 + zone rendering"
```
