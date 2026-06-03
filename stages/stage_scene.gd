extends Node2D

const ZAEL_SCENE := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE := preload("res://characters/melee/zara.tscn")

const _TS     := 64   # tamanho de destino no mundo (game units)
const _SRC_TS := 32   # tamanho do tile no PNG (pixels)

@export var platform_color: Color = Color(0.35, 0.35, 0.35)

var _player: CharacterBase
var _zone_tilesets: Array[Texture2D] = []
# Override textures must be held by a persistent strong reference. Loading them
# per-frame inside _draw() drops the reference each frame; on web (WebGL2) the
# GPU re-upload can't keep up with that churn and the texture renders pure white.
var _override_tex_cache: Dictionary = {}
var _zone_min: float = 0.0
var _zone_max: float = 1.0
var _zone_use_y: bool = false

func _ready() -> void:
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")
	_player = _spawn_player()
	for child in get_children():
		if DebugBoot.no_enemies and (child is EnemyBase or child is BossBase):
			child.queue_free()
			continue
		if child is BossBase:
			child.player = _player
	_maybe_spawn_bot()
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)
	StageManager.spawn_position = $PlayerSpawn.global_position
	$Camera2D.zoom = Vector2(2.2, 2.2)
	AudioManager.play_bgm(AudioLibrary.get_stage_bgm(StageManager.current_stage_id))
	_apply_kill_plane()
	_load_zone_data()
	queue_redraw()

func _apply_kill_plane() -> void:
	# The kill plane must sit below the level's lowest floor. A fixed value would
	# kill the player on legitimately low platforms (e.g. the vertical shaft in
	# stage 01, whose ShaftP3 at y=1700 fell below the old hardcoded KILL_Y=1500).
	var lowest: float = -INF
	for child in get_children():
		if not (child is StaticBody2D or child is AnimatableBody2D):
			continue
		for sc in (child as Node).get_children():
			if sc is CollisionShape2D and (sc as CollisionShape2D).shape is RectangleShape2D:
				var size: Vector2 = ((sc as CollisionShape2D).shape as RectangleShape2D).size
				var bottom: float = (child as Node2D).position.y + (sc as Node2D).position.y + size.y * 0.5
				lowest = maxf(lowest, bottom)
	if lowest > -INF:
		_player.kill_y = maxf(CharacterBase.KILL_Y, lowest + 600.0)

func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		$Camera2D.global_position = _player.global_position
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		$PauseMenu.toggle_pause()

func _spawn_player() -> CharacterBase:
	var scene := ZARA_SCENE if GameManager.active_character == "zara" else ZAEL_SCENE
	var p: CharacterBase = scene.instantiate()
	p.global_position = $PlayerSpawn.global_position
	add_child(p)
	# As portas de checkpoint (CorridorSection) abrem via TriggerArea que checa
	# is_in_group("player"); sem este grupo a porta nunca abre (bug stage 01).
	p.add_to_group("player")
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

func _cached_override_tex(path: String) -> Texture2D:
	if _override_tex_cache.has(path):
		return _override_tex_cache[path]
	var t: Texture2D = (load(path) as Texture2D) if ResourceLoader.exists(path) else null
	_override_tex_cache[path] = t
	return t

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
			var use_fill := false
			if child.has_meta("tileset_override"):
				tex = _cached_override_tex(child.get_meta("tileset_override"))
				use_fill = true
			elif child.has_meta("platform_override"):
				tex = _cached_override_tex(child.get_meta("platform_override"))
			if tex == null:
				tex = _get_zone_tileset(center)
			if tex != null:
				if use_fill:
					_draw_fill_tiles(rect, tex)
				else:
					_draw_lava_tiles(rect, tex)
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

func _draw_lava_tiles(rect: Rect2, tex: Texture2D) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	var cols := ceili(rect.size.x / ts)
	var phys_rows := ceili(rect.size.y / ts)
	var rows := maxi(phys_rows, 7 if phys_rows >= 2 else 0)
	for row in rows:
		var tx := 3 * src_ts if row == 0 else 2 * src_ts
		var ty := 0           if row == 0 else src_ts
		for col in cols:
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts - src_ts
			var dh := minf(float(ts), rect.position.y + rect.size.y - dy) if row < phys_rows else float(ts)
			var dw := minf(float(ts), rect.position.x + rect.size.x - dx)
			draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh),
				Rect2(tx, ty, src_ts * dw / ts, src_ts * dh / ts))

func _draw_platform_tiles(rect: Rect2, tex: Texture2D) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	var cols := ceili(rect.size.x / ts)
	var phys_rows := ceili(rect.size.y / ts)
	var rows := maxi(phys_rows, 7 if phys_rows >= 2 else 0)
	for row in rows:
		for col in cols:
			var tile := _tile_at(col, cols, row, rows)
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts - src_ts
			var dh := minf(float(ts), rect.position.y + rect.size.y - dy) if row < phys_rows else float(ts)
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

func _maybe_spawn_bot() -> void:
	if not DebugBoot.bot_enabled:
		return
	var bot := preload("res://tests/bot/stage_bot.gd").new()
	bot.name = "StageBot"
	add_child(bot)
