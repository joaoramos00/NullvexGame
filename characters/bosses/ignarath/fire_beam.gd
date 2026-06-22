extends Node2D
# Firebreath do Ignarath: feixe que sai da BOCA até o CHÃO e VARRE da vertical
# (90°) pra FORA em direção ao player (o contato no chão avança). A linha inteira
# machuca (distância ponto-a-segmento por frame). Autodestrói ao fim da varredura.

const _ORIGIN_TEX_PATH := "res://characters/bosses/ignarath/fire_beam_origin.png"
const _BODY_TEX_PATH := "res://characters/bosses/ignarath/fire_beam_body.png"
const _END_TEX_PATH := "res://characters/bosses/ignarath/fire_beam_end.png"
const _SHEET_COLS := 2
const _SHEET_ROWS := 2
const _SHEET_FRAMES := 4

var player: Node = null
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
var _end_sprite: Sprite2D = null

func _ready() -> void:
	z_index = 3
	position = Vector2.ZERO               # desenho em coords de mundo
	_build_visuals()
	var depth: float = maxf(8.0, floor_y - origin.y)
	_end = origin + Vector2(0.0, depth)   # começa vertical
	_update_visuals()
	queue_redraw()

func _physics_process(delta: float) -> void:
	_t += delta
	var prog: float = clampf(_t / sweep_time, 0.0, 1.0)
	var ang: float = deg_to_rad(max_angle_deg * prog)   # 0 (vertical) → max (pra fora)
	var depth: float = maxf(8.0, floor_y - origin.y)
	_end = origin + Vector2(facing * depth * tan(ang), depth)
	if is_instance_valid(player) and not player.is_dead:
		if _point_seg_dist(player.global_position, origin, _end) < half_width + 24.0:
			player.take_damage(damage, source_id)
	_update_visuals()
	queue_redraw()
	if _t >= sweep_time + 0.15:
		queue_free()

func _build_visuals() -> void:
	var origin_tex := _load_texture(_ORIGIN_TEX_PATH)
	var body_tex := _load_texture(_BODY_TEX_PATH)
	var end_tex := _load_texture(_END_TEX_PATH)

	if origin_tex != null:
		_origin_sprite = Sprite2D.new()
		_origin_sprite.name = "OriginSprite"
		_configure_sheet_sprite(_origin_sprite, origin_tex)
		_origin_sprite.z_index = 4
		add_child(_origin_sprite)

	if body_tex != null:
		_body_line = Line2D.new()
		_body_line.name = "BodyLine"
		_body_line.texture = body_tex
		_body_line.texture_mode = Line2D.LINE_TEXTURE_TILE
		_body_line.joint_mode = Line2D.LINE_JOINT_ROUND
		_body_line.begin_cap_mode = Line2D.LINE_CAP_NONE
		_body_line.end_cap_mode = Line2D.LINE_CAP_NONE
		_body_line.width = half_width * 2.0
		_body_line.z_index = 3
		add_child(_body_line)

	if end_tex != null:
		_end_sprite = Sprite2D.new()
		_end_sprite.name = "EndSprite"
		_configure_sheet_sprite(_end_sprite, end_tex)
		_end_sprite.z_index = 4
		add_child(_end_sprite)

func _configure_sheet_sprite(sprite: Sprite2D, texture: Texture2D) -> void:
	sprite.texture = texture
	sprite.hframes = _SHEET_COLS
	sprite.vframes = _SHEET_ROWS
	sprite.centered = true

func _update_visuals() -> void:
	var frame := int(_t * 12.0) % _SHEET_FRAMES
	var beam_vec := _end - origin
	var beam_angle := beam_vec.angle()
	var cap_scale := maxf(0.75, (half_width * 2.4) / 64.0)

	if _origin_sprite != null:
		_origin_sprite.position = origin
		_origin_sprite.frame = frame
		_origin_sprite.scale = Vector2.ONE * cap_scale
		_origin_sprite.rotation = beam_angle

	if _body_line != null:
		_body_line.points = PackedVector2Array([origin, _end])
		_body_line.width = half_width * 2.0

	if _end_sprite != null:
		_end_sprite.position = _end
		_end_sprite.frame = frame
		_end_sprite.scale = Vector2.ONE * cap_scale
		_end_sprite.rotation = beam_angle

func _draw() -> void:
	if _body_line != null:
		return
	var fl: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 30.0)
	draw_line(origin, _end, Color(1.0, 0.35 + 0.25 * fl, 0.05, 0.9), half_width * 2.0)
	draw_line(origin, _end, Color(1.0, 0.85, 0.3, 0.95), half_width)

func _load_texture(path: String) -> Texture2D:
	var tex := load(path) as Texture2D
	if tex != null:
		return tex
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)

func _point_seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var denom: float = ab.length_squared()
	var t: float = 0.0
	if denom > 0.0:
		t = clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)
