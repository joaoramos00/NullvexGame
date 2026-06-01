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
	_zone_tilesets.clear()
	var id := StageManager.current_stage_id
	if id < 1 or id > 8:
		return
	for z in range(1, 5):
		var path := "res://stages/stage_%02d/Stage_%02dT_z%d.png" % [id, id, z]
		_zone_tilesets.append(load(path) as Texture2D if ResourceLoader.exists(path) else null)
	if _zone_tilesets.is_empty():
		return
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
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
		return _zone_tilesets[0]  # may be null — caller handles it
	var t := (center.y - _zone_min) / span if _zone_use_y else (center.x - _zone_min) / span
	var idx := mini(maxi(0, int(t * _zone_tilesets.size())), _zone_tilesets.size() - 1)
	return _zone_tilesets[idx]  # may be null — caller handles it

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
			var tex: Texture2D = null
			if child.has_meta("tileset_override"):
				var path: String = child.get_meta("tileset_override")
				if ResourceLoader.exists(path):
					tex = load(path) as Texture2D
			if tex == null:
				tex = _get_zone_tileset(center)
			if tex != null:
				if child.has_meta("tileset_override"):
					_draw_fill_tiles(rect, tex)
				else:
					_draw_platform_tiles(rect, tex)
			else:
				draw_rect(rect, platform_color)

func _draw_fill_tiles(rect: Rect2, tex: Texture2D) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	var cols := ceili(rect.size.x / ts)
	var rows := ceili(rect.size.y / ts)
	var src := Rect2(2 * src_ts, 1 * src_ts, src_ts, src_ts)
	for row in rows:
		for col in cols:
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var dh := minf(ts, rect.position.y + rect.size.y - dy)
			draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh),
				Rect2(src.position, Vector2(src_ts * dw / ts, src_ts * dh / ts)))

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
