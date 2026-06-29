extends Node2D
# Firebreath do Ignarath: feixe que sai da BOCA até o CHÃO e VARRE da vertical
# (90°) pra FORA em direção ao player (o contato no chão avança). A linha inteira
# machuca (distância ponto-a-segmento por frame). Autodestrói ao fim da varredura.

const _TEX_ORIGIN   := preload("res://characters/bosses/ignarath/fire_beam_origin.png")
const _TEX_BODY     := preload("res://characters/bosses/ignarath/fire_beam_body.png")
const _TEX_END      := preload("res://characters/bosses/ignarath/fire_beam_end.png")
const _SHEET_COLS   := 2
const _SHEET_ROWS   := 2
const _SHEET_FRAMES := 4

var player: CharacterBase = null
var origin: Vector2 = Vector2.ZERO      # boca, em coords de mundo
var facing: float = 1.0                  # +1 direita, -1 esquerda
var floor_y: float = 0.0
var sweep_time: float = 1.0
var max_angle_deg: float = 70.0          # ângulo final a partir da vertical
var half_width: float = 20.0
var damage: int = 12
var source_id: String = "ignarath"
var _t: float = 0.0
var _end: Vector2 = Vector2.ZERO
var _origin_sprite: Sprite2D = null
var _body_line: Line2D = null
var _body_atlas: AtlasTexture = null
var _end_sprite: Sprite2D = null
var _frame_w: float = 0.0
var _frame_h: float = 0.0

func _ready() -> void:
	z_index = 3
	position = Vector2.ZERO               # desenho em coords de mundo
	_build_visuals()
	_end = _compute_end(0.0)              # começa horizontal (sprites apontam pra frente)
	_update_visuals()
	queue_redraw()

func _physics_process(delta: float) -> void:
	_t += delta
	var prog: float = clampf(_t / sweep_time, 0.0, 1.0)
	_end = _compute_end(prog)
	if is_instance_valid(player) and not player.is_dead:
		if _point_seg_dist(player.global_position, origin, _end) < half_width + 24.0:
			player.take_damage(damage, source_id)
	_update_visuals()
	queue_redraw()
	if _t >= sweep_time + 0.15:
		queue_free()

# Sweep horizontal → vertical: começa apontando para o lado (max_angle_deg da vertical)
# e varre até apontar reto para o chão (0° da vertical). Usa sin/cos para suportar 90°.
func _compute_end(prog: float) -> Vector2:
	var depth := maxf(8.0, floor_y - origin.y)
	var ang := deg_to_rad(max_angle_deg * (1.0 - prog))  # max_angle_deg → 0
	var sin_a := sin(ang) * facing
	var cos_a := cos(ang)
	if cos_a < 0.06:   # dentro de ~3° da horizontal — evita distância infinita
		return origin + Vector2(sin_a * depth * 15.0, cos_a * depth * 15.0)
	return origin + (depth / cos_a) * Vector2(sin_a, cos_a)

func _build_visuals() -> void:
	_frame_w = float(_TEX_BODY.get_width()) / _SHEET_COLS
	_frame_h = float(_TEX_BODY.get_height()) / _SHEET_ROWS

	_origin_sprite = Sprite2D.new()
	_origin_sprite.name = "OriginSprite"
	_configure_sheet_sprite(_origin_sprite, _TEX_ORIGIN)
	_origin_sprite.z_index = 4
	add_child(_origin_sprite)

	_body_atlas = AtlasTexture.new()
	_body_atlas.atlas = _TEX_BODY
	_body_atlas.region = Rect2(0.0, 0.0, _frame_w, _frame_h)
	_body_line = Line2D.new()
	_body_line.name = "BodyLine"
	_body_line.texture = _body_atlas
	_body_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	_body_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_body_line.begin_cap_mode = Line2D.LINE_CAP_NONE
	_body_line.end_cap_mode = Line2D.LINE_CAP_NONE
	_body_line.width = half_width * 2.0
	_body_line.z_index = 3
	add_child(_body_line)

	_end_sprite = Sprite2D.new()
	_end_sprite.name = "EndSprite"
	_configure_sheet_sprite(_end_sprite, _TEX_END)
	_end_sprite.z_index = 4
	add_child(_end_sprite)

func _configure_sheet_sprite(sprite: Sprite2D, texture: Texture2D) -> void:
	sprite.texture = texture
	sprite.hframes = _SHEET_COLS
	sprite.vframes = _SHEET_ROWS
	sprite.centered = true

func _update_visuals() -> void:
	var frame := int(_t * 12.0) % _SHEET_FRAMES
	var col := frame % _SHEET_COLS
	var row := frame / _SHEET_COLS
	var beam_vec := _end - origin
	var beam_angle := beam_vec.angle()
	var cap_scale := maxf(0.75, (half_width * 2.4) / 64.0)
	var fl: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 30.0)
	var tint := Color(1.0, 0.9 + 0.1 * fl, 0.9 + 0.1 * fl, 1.0)

	if _origin_sprite != null:
		_origin_sprite.position = origin
		_origin_sprite.frame = frame
		_origin_sprite.scale = Vector2.ONE * cap_scale
		_origin_sprite.rotation = beam_angle
		_origin_sprite.modulate = tint

	if _body_line != null and _body_atlas != null:
		_body_atlas.region = Rect2(float(col) * _frame_w, float(row) * _frame_h, _frame_w, _frame_h)
		_body_line.points = PackedVector2Array([origin, _end])
		_body_line.width = half_width * 2.0
		_body_line.modulate = tint

	if _end_sprite != null:
		_end_sprite.position = _end
		_end_sprite.frame = frame
		_end_sprite.scale = Vector2.ONE * cap_scale
		_end_sprite.rotation = beam_angle
		_end_sprite.modulate = tint

func _draw() -> void:
	if _body_line != null:
		return
	var fl: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 30.0)
	draw_line(origin, _end, Color(1.0, 0.35 + 0.25 * fl, 0.05, 0.9), half_width * 2.0)
	draw_line(origin, _end, Color(1.0, 0.85, 0.3, 0.95), half_width)

func _point_seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var denom: float = ab.length_squared()
	var t: float = 0.0
	if denom > 0.0:
		t = clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)
