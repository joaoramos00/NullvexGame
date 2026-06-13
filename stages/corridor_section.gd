# stages/corridor_section.gd
# Corredor reutilizável: troque tileset/glass_tex e ajuste os exports.
# A stage instancia, chama setup(player) e conecta os sinais.
class_name CorridorSection
extends Node2D

const _DOOR_SCENE := preload("res://stages/checkpoint_door.tscn")
const _TS  := 64
const _SRC := 32

# ─── Visual ───────────────────────────────────────────────────────────────────
@export var tileset:   Texture2D  ## tiles de plataforma (floor/walls)
@export var glass_tex: Texture2D  ## tiles do teto de glass (null = sem glass)
@export var door_tex:  Texture2D  ## textura da porta de checkpoint

# ─── Geometria (coordenadas absolutas no mundo) ───────────────────────────────
@export var floor_center:  Vector2 = Vector2(5982, 1120)
@export var floor_size:    Vector2 = Vector2(896, 64)
@export var ceil_center:   Vector2 = Vector2(5982, 928)
@export var ceil_size:     Vector2 = Vector2(896, 64)
@export var wall_l_center: Vector2 = Vector2(5534, 1024)
@export var wall_l_size:   Vector2 = Vector2(64, 256)
@export var wall_r_center: Vector2 = Vector2(6462, 1024)
@export var wall_r_size:   Vector2 = Vector2(64, 256)

# ─── Portas ───────────────────────────────────────────────────────────────────
@export var entry_x:     float = 5566.0
@export var exit_x:      float = 6430.0
@export var door_height: float = 200.0
@export var door_cy:     float = 1024.0

# ─── Câmera ───────────────────────────────────────────────────────────────────
@export var cam_center: Vector2 = Vector2(5982, 1024)
@export var cam_zoom:   float   = 2.0

# ─── Glass ────────────────────────────────────────────────────────────────────
@export var glass_lateral_x: float = 5480.0
@export var glass_fill_x:    float = 5544.0
@export var glass_fill_cols: int   = 14
@export var glass_col_rows:  int   = 33
@export var glass_col_bot:   float = 960.0
@export var glass_mirror:    bool  = false  # lateral na direita (fills à esq, lateral espelhada à dir)
@export var glass_cap_right: bool  = false  # fecha a direita com tile-espelho (3,2) sobre a porta de saída

# ─── Checkpoint ───────────────────────────────────────────────────────────────
@export var checkpoint_index:     int   = 1
@export var checkpoint_respawn_x: float = 6558.0

# ─── Comportamento da entry door ──────────────────────────────────────────────
@export var entry_manual:    bool = false  # stage abre entry door via open_entry()
@export var save_checkpoint: bool = true
@export var heal_on_entry:      bool = false
@export var exit_retriggerable: bool = false  # mantém exit door acionável no retry

# ─── Sinais para a stage ──────────────────────────────────────────────────────
signal camera_lock_requested(center: Vector2, zoom: float)
signal checkpoint_triggered(respawn: Vector2, index: int)
signal player_healed
signal player_traversed   # player saiu pela porta de saída
signal exit_opening        # exit door começou a abrir (antes do auto-walk)

var _player: CharacterBase  = null
var _entry_door: Node       = null
var _exit_door:  Node       = null

# ─── Setup ────────────────────────────────────────────────────────────────────

func setup(player: CharacterBase) -> void:
	_player = player
	# Calibra porta e vidro ao piso (face onde o player anda). Sem isto, valores
	# mal ajustados fazem a colisão do vidro bater na cabeça do player e a porta
	# ficar alta demais — selando a entrada (bug Corridor1/2 da stage 01).
	var floor_top := floor_center.y - floor_size.y * 0.5
	door_cy       = floor_top - 64.0    # porta abraça o corpo do player
	glass_col_bot = floor_top - 128.0   # fundo do vidro acima da cabeça (porta de 128px no chão)
	_build_collision()
	_setup_doors()
	queue_redraw()

func _build_collision() -> void:
	_add_static(floor_center,  floor_size,  1)
	_add_static(ceil_center, ceil_size, 1)
	# Paredes SÓLIDAS acima da abertura da porta — a porta faz o vão no nível do chão.
	# Antes ficavam desabilitadas (só a porta de 200px barrava), deixando um vão acima:
	# o player pulava por cima / atravessava a "parede" pelo lado da zona seguinte.
	_add_wall_above_door(wall_l_center, wall_l_size)
	_add_wall_above_door(wall_r_center, wall_r_size)
	if glass_tex != null:
		_add_glass_lateral_collision()

func _add_wall_above_door(wall_center: Vector2, wall_size: Vector2) -> void:
	var door_top := door_cy - door_height * 0.5
	var wall_top := wall_center.y - wall_size.y * 0.5
	if door_top <= wall_top:
		return  # porta já cobre toda a parede; nada a selar acima
	var seg_h := door_top - wall_top
	# Segmento menor que 1 tile = gap impassável (personagem não cabe) — não criar
	# colisão para evitar "piso invisível" em salas de boss (player não precisa do selo).
	if seg_h < float(_TS):
		return
	var seg_center := Vector2(wall_center.x, wall_top + seg_h * 0.5)
	_add_static(seg_center, Vector2(wall_size.x, seg_h), 1)

func _add_glass_lateral_collision() -> void:
	# Bloqueia o player de passar por cima do painel de vidro.
	# Collision 1 tile mais curta que o visual (para não cobrir o chão do corredor).
	var col_rows := glass_col_rows - 1
	var col_bot  := glass_col_bot - float(_TS)
	var col_top  := col_bot - col_rows * float(_TS)
	var height   := col_bot - col_top
	# Normal: cobre lateral (esq) + 1º fill. Mirror: cobre último fill + lateral (dir).
	var cx := glass_lateral_x + float(_TS) if not glass_mirror else glass_lateral_x + float(_TS) * 0.5
	var body := StaticBody2D.new()
	body.name            = "Glass_Lateral"
	body.collision_layer = 1
	body.collision_mask  = 0
	body.global_position = Vector2(cx, (col_top + col_bot) * 0.5)
	var cs    := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(float(_TS) * 2.0, height)
	cs.shape   = shape
	body.add_child(cs)
	add_child(body)
	body.add_to_group("no_wall_grab")

func _add_static(center: Vector2, size: Vector2, layer: int, disabled: bool = false) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = layer
	body.collision_mask  = 0
	body.global_position = center
	var cs    := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size  = size
	cs.shape    = shape
	cs.disabled = disabled
	body.add_child(cs)
	add_child(body)

func _setup_doors() -> void:
	var door_v   := door_height / 3.0
	var open_y   := (wall_l_center.y - wall_l_size.y * 0.5 - door_cy) - door_height - 2.0

	_entry_door = _make_door(entry_x, door_v, door_height, open_y)
	(_entry_door as CheckpointDoor).door_opening.connect(_on_door_opening)
	(_entry_door as CheckpointDoor).door_opened.connect(_on_entry_opened.bind(_entry_door))
	if entry_manual:
		var trig := (_entry_door as Node).get_node_or_null("TriggerArea") as Area2D
		if trig:
			trig.monitoring = false
	add_child(_entry_door)

	_exit_door  = _make_door(exit_x,  door_v, door_height, open_y)
	(_exit_door as CheckpointDoor).door_opening.connect(_on_exit_door_opening)
	(_exit_door as CheckpointDoor).door_opened.connect(_on_exit_opened.bind(_exit_door))
	add_child(_exit_door)

func _make_door(x: float, w: float, h: float, open_offset: float) -> CheckpointDoor:
	var door     := _DOOR_SCENE.instantiate() as CheckpointDoor
	door.position       = Vector2(x, door_cy)
	door.open_offset    = open_offset
	door.open_from_side = -1   # corredor é left→right: só abre vindo da esquerda
	var col := door.get_node("CollisionShape2D") as CollisionShape2D
	var body_shape := (col.shape as RectangleShape2D).duplicate() as RectangleShape2D
	body_shape.size = Vector2(w, h)
	col.shape = body_shape
	var trig := door.get_node("TriggerArea/CollisionShape2D") as CollisionShape2D
	var trig_shape := (trig.shape as RectangleShape2D).duplicate() as RectangleShape2D
	trig_shape.size = Vector2(w + 32.0, h + 32.0)
	trig.shape = trig_shape
	var sprite := door.get_node("ColorRect") as ColorRect
	sprite.color = Color(0, 0, 0, 0)
	return door

# ─── Eventos das portas ───────────────────────────────────────────────────────

func open_entry() -> void:
	(_entry_door as CheckpointDoor).open()

func _on_door_opening() -> void:
	if is_instance_valid(_player):
		_player.door_locked = true

func _on_entry_opened(door: Node2D) -> void:
	if is_instance_valid(_player):
		_player.door_locked     = false
		_player.door_walk_speed = CharacterBase.SPEED
	if save_checkpoint:
		var respawn := Vector2(checkpoint_respawn_x, floor_center.y - floor_size.y * 0.5 - 32.0)
		StageManager.save_checkpoint(respawn, checkpoint_index)
		checkpoint_triggered.emit(respawn, checkpoint_index)
	if heal_on_entry and is_instance_valid(_player):
		_player.heal(_player.max_hp)
		player_healed.emit()
	var target_x := door.position.x + 96.0
	while is_instance_valid(_player) and _player.global_position.x < target_x:
		await get_tree().process_frame
	if is_instance_valid(_player):
		_player.door_walk_speed = 0.0
	if is_instance_valid(door):
		door.call("close")
		var trig := door.get_node_or_null("TriggerArea") as Area2D
		if trig:
			trig.monitoring = false
	camera_lock_requested.emit(cam_center, cam_zoom)

func _on_exit_door_opening() -> void:
	if is_instance_valid(_player):
		_player.door_locked = true
	exit_opening.emit()

func _on_exit_opened(door: Node2D) -> void:
	if is_instance_valid(_player):
		_player.door_locked     = false
		_player.door_walk_speed = CharacterBase.SPEED
	var target_x := door.position.x + 96.0
	while is_instance_valid(_player) and _player.global_position.x < target_x:
		await get_tree().process_frame
	if is_instance_valid(_player):
		_player.door_walk_speed = 0.0
	if is_instance_valid(door):
		door.call("close")
		var trig := door.get_node_or_null("TriggerArea") as Area2D
		if trig and not exit_retriggerable:
			trig.monitoring = false
	player_traversed.emit()

# ─── Desenho ──────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if tileset == null:
		return
	_draw_floor_tiles()
	_draw_ceil_tiles()
	if glass_tex != null:
		_draw_glass()
	if door_tex != null:
		_draw_door_underlays()

func _draw_door_underlays() -> void:
	var dv := door_height / 3.0
	for door in [_entry_door, _exit_door]:
		if not is_instance_valid(door):
			continue
		var anim_y: float = (door as CheckpointDoor).anim_offset
		var cx: float = (door as Node2D).position.x
		var cy: float = (door as Node2D).position.y + anim_y
		draw_texture_rect(door_tex, Rect2(cx - dv * 0.5, cy - door_height * 0.5, dv, door_height), false)

func _draw_floor_tiles() -> void:
	var rect := Rect2(floor_center - floor_size * 0.5, floor_size)
	_draw_platform(rect, tileset)

func _draw_ceil_tiles() -> void:
	_draw_room(Rect2(ceil_center - ceil_size * 0.5, ceil_size), "Ceil")

func _draw_wall_tiles() -> void:
	# Paredes sem colisão — desenhadas visualmente mas sem bloqueio físico
	_draw_room(Rect2(wall_l_center - wall_l_size * 0.5, wall_l_size), "Wall_L")
	_draw_room(Rect2(wall_r_center - wall_r_size * 0.5, wall_r_size), "Wall_R")

func _draw_glass() -> void:
	var lat_src  := Rect2(1 * _SRC, 0 * _SRC, _SRC, _SRC)
	var fill_src := Rect2(2 * _SRC, 1 * _SRC, _SRC, _SRC)
	var col_top  := glass_col_bot - glass_col_rows * _TS
	if glass_mirror:
		var right_lat_src := Rect2(3 * _SRC, 2 * _SRC, _SRC, _SRC)  # tile (3,2) — face esquerda
		for row in glass_col_rows:
			var dy := col_top + row * _TS
			for col in glass_fill_cols:
				draw_texture_rect_region(glass_tex, Rect2(glass_fill_x + col * _TS, dy, _TS, _TS), fill_src)
			draw_texture_rect_region(glass_tex, Rect2(glass_lateral_x, dy, _TS, _TS), right_lat_src)
	else:
		var cap_src := Rect2(3 * _SRC, 2 * _SRC, _SRC, _SRC)  # tile (3,2) — borda lisa (espelho)
		for row in glass_col_rows:
			var dy := col_top + row * _TS
			draw_texture_rect_region(glass_tex, Rect2(glass_lateral_x, dy, _TS, _TS), lat_src)
			for col in glass_fill_cols:
				draw_texture_rect_region(glass_tex, Rect2(glass_fill_x + col * _TS, dy, _TS, _TS), fill_src)
			if glass_cap_right:
				draw_texture_rect_region(glass_tex, Rect2(glass_fill_x + glass_fill_cols * _TS, dy, _TS, _TS), cap_src)

# ─── Utilitários de tile (espelham stage_00_scene.gd) ────────────────────────

func _draw_platform(rect: Rect2, tex: Texture2D) -> void:
	var cols := ceili(rect.size.x / _TS)
	var rows := ceili(rect.size.y / _TS)
	for row in rows:
		for col in cols:
			var tile := _tile_at(col, cols, row, rows)
			var dx   := rect.position.x + col * _TS
			var dy   := rect.position.y + row * _TS - _SRC
			var dh   := minf(_TS, rect.position.y + rect.size.y - dy)
			if cols > 1:
				var fill := _gap_fill(row, rows)
				if col == 0:
					dx -= _SRC
					draw_texture_rect_region(tex,
						Rect2(rect.position.x + _TS / 2.0, dy, _TS / 2.0, dh),
						Rect2(fill.x * _SRC, fill.y * _SRC, _SRC / 2, _SRC))
				elif col == cols - 1:
					dx += _SRC
					draw_texture_rect_region(tex,
						Rect2(rect.position.x + (cols - 1) * _TS, dy, _TS / 2.0, dh),
						Rect2(fill.x * _SRC + _SRC / 2, fill.y * _SRC, _SRC / 2, _SRC))
			var dw := minf(_TS, rect.position.x + rect.size.x - dx)
			draw_texture_rect_region(tex,
				Rect2(dx, dy, dw, dh),
				Rect2(tile.x * _SRC, tile.y * _SRC, _SRC * dw / _TS, _SRC * dh / _TS))

func _draw_room(rect: Rect2, suffix: String) -> void:
	var base_xs := _SRC if suffix == "Wall_L" else (-_SRC if suffix == "Wall_R" else 0)
	var base_ys := _SRC if suffix == "Ceil" else 0
	var cols    := ceili(rect.size.x / _TS)
	var rows    := ceili(rect.size.y / _TS)
	for row in rows:
		for col in cols:
			var is_left   := col == cols - 1
			var is_right  := col == 0
			var is_top    := row == rows - 1
			var is_bottom := row == 0
			var tile: Vector2i
			if suffix == "Wall_L":
				if is_bottom: tile = Vector2i(2, 2)
				elif is_top:  tile = Vector2i(1, 1)
				else:         tile = Vector2i(1, 0)
			elif suffix == "Wall_R":
				if is_bottom: tile = Vector2i(3, 1)
				elif is_top:  tile = Vector2i(2, 0)
				else:         tile = Vector2i(3, 2)
			elif suffix == "Ceil":
				if is_left:   tile = Vector2i(2, 2)
				elif is_right: tile = Vector2i(3, 1)
				else:         tile = Vector2i(1, 2)
			else:
				tile = Vector2i(3, 0)
			var tx := base_xs
			var ty := base_ys
			if suffix in ["Wall_L", "Wall_R"]:
				if is_bottom: ty =  _SRC
				elif is_top:  ty = -_SRC
			var dx := rect.position.x + col * _TS + tx
			var dy := rect.position.y + row * _TS + ty
			var dw := minf(_TS, rect.position.x + rect.size.x - dx)
			var dh := minf(_TS, rect.position.y + rect.size.y - dy)
			draw_texture_rect_region(tileset,
				Rect2(dx, dy, dw, dh),
				Rect2(tile.x * _SRC, tile.y * _SRC, _SRC * dw / _TS, _SRC * dh / _TS))

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

func _gap_fill(row: int, rows: int) -> Vector2i:
	if row == 0:        return Vector2i(3, 0)
	if row == rows - 1: return Vector2i(1, 2)
	return Vector2i(2, 1)
