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
	if _room_tilesets.is_empty():
		return 0
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
	if row == 0:        return Vector2i(3, 0)  # TOP — linha visual superior
	if row == rows - 1: return Vector2i(1, 2)  # BOTTOM — linha visual inferior
	return Vector2i(2, 1)                       # FILL — interior

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
