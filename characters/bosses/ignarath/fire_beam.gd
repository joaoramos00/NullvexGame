extends Node2D
# Firebreath do Ignarath: feixe que sai da BOCA até o CHÃO e VARRE da horizontal
# para a vertical (90°) em direção ao chão. A linha inteira machuca
# (distância ponto-a-segmento por frame). Autodestrói ao fim da varredura.

const _TEX_ORIGIN   := preload("res://characters/bosses/ignarath/fire_beam_origin.png")
const _TEX_BODY     := preload("res://characters/bosses/ignarath/fire_beam_body.png")
const _TEX_END      := preload("res://characters/bosses/ignarath/fire_beam_end.png")
const _TEX_IMPACT   := preload("res://characters/bosses/ignarath/fx_beam_impact.png")
const _SHEET_COLS   := 2
const _SHEET_ROWS   := 2
const _SHEET_FRAMES := 4
const _IMPACT_FRAMES := 9
const _IMPACT_FPS    := 12.0
const _TEX_BEAM_BODY_FX  := preload("res://characters/bosses/ignarath/fx_beam_body.png")
const _BEAM_BODY_FRAMES  := 9
const _BEAM_BODY_FPS     := 12.0
const _BEAM_BODY_SPACING := 40.0
const _MAX_BODY_SPRITES  := 14
const _TIP_EXTRA_MARGIN  := 48.0  # alcance de dano na ponta (> margem do corpo, 24.0)

var player: CharacterBase = null
var origin: Vector2 = Vector2.ZERO      # boca, em coords de mundo
var facing: float = 1.0                  # +1 direita, -1 esquerda
var floor_y: float = 0.0
var sweep_time: float = 1.0
var max_angle_deg: float = 70.0          # ângulo de início a partir da vertical (90 = horizontal)
var half_width: float = 20.0
var damage: int = 12
var source_id: String = "ignarath"
var _t: float = 0.0
var _end: Vector2 = Vector2.ZERO
var _origin_sprite: Sprite2D = null
var _body_line: Line2D = null
var _body_atlas: AtlasTexture = null
var _body_inner: Line2D = null  # núcleo amarelo
var _end_sprite: Sprite2D = null
var _impact_fxs: Array[AnimatedSprite2D] = []
var _body_sprites: Array = []
var _hit_normal: Vector2 = Vector2(0.0, -1.0)  # normal da superfície do último raycast
var _frame_w: float = 0.0
var _frame_h: float = 0.0

func _ready() -> void:
	z_index = 3
	position = Vector2.ZERO               # desenho em coords de mundo
	_build_visuals()
	_end = _compute_end(0.0)              # começa vertical (apontando para o chão)
	_update_visuals()
	queue_redraw()

func _physics_process(delta: float) -> void:
	_t += delta
	var prog: float = clampf(_t / sweep_time, 0.0, 1.0)
	_end = _compute_end(prog)
	if is_instance_valid(player) and not player.is_dead:
		var hit := _point_seg_dist(player.global_position, origin, _end) < half_width + 24.0
		# Ponta tem alcance extra: o impacto visual ali (fx_beam_impact + ponta
		# 2x maior) é bem maior que a margem do corpo do feixe.
		if not hit:
			hit = player.global_position.distance_to(_end) < half_width + _TIP_EXTRA_MARGIN
		if hit:
			player.take_damage(damage, source_id)
	_update_visuals()
	queue_redraw()
	if _t >= sweep_time + 0.15:
		queue_free()

# Sweep vertical → horizontal: ang parte de 0° (vertical, chão) e cresce até
# max_angle_deg (ex: 90° = horizontal). Usa sin/cos para suportar 90° sem tan(∞).
func _compute_end(prog: float) -> Vector2:
	var depth := maxf(8.0, floor_y - origin.y)
	var ang := deg_to_rad(max_angle_deg * prog)  # 0 → max_angle_deg
	var sin_a := sin(ang) * facing
	var cos_a := cos(ang)
	var geom: Vector2
	if cos_a < 0.06:   # perto de 90° (horizontal) — limita comprimento
		geom = origin + Vector2(sin_a * depth * 15.0, cos_a * depth * 15.0)
	else:
		geom = origin + (depth / cos_a) * Vector2(sin_a, cos_a)
	return _wall_clip(geom)

func _wall_clip(geom: Vector2) -> Vector2:
	if not is_inside_tree():
		return geom
	var space := get_world_2d().direct_space_state
	if space == null:
		return geom
	var query := PhysicsRayQueryParameters2D.create(origin, geom)
	query.collision_mask = 1  # layer 1 = world geometry (StaticBody2D)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return geom
	_hit_normal = hit["normal"]  # salva normal real da superfície atingida
	return hit["position"]

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

	_body_inner = Line2D.new()
	_body_inner.name = "BodyLineInner"
	_body_inner.default_color = Color(1.0, 0.92, 0.5, 0.9)
	_body_inner.joint_mode = Line2D.LINE_JOINT_ROUND
	_body_inner.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_body_inner.end_cap_mode = Line2D.LINE_CAP_ROUND
	_body_inner.width = half_width * 0.7
	_body_inner.z_index = 4
	add_child(_body_inner)

	_end_sprite = Sprite2D.new()
	_end_sprite.name = "EndSprite"
	_configure_sheet_sprite(_end_sprite, _TEX_END)
	_end_sprite.z_index = 5
	add_child(_end_sprite)

	var impact_sf := SpriteFrames.new()
	impact_sf.add_animation("burn")
	impact_sf.set_animation_loop("burn", true)
	impact_sf.set_animation_speed("burn", _IMPACT_FPS)
	for i in _IMPACT_FRAMES:
		var at := AtlasTexture.new()
		at.atlas = _TEX_IMPACT
		at.region = Rect2(i * 64.0, 0.0, 64.0, 64.0)
		impact_sf.add_frame("burn", at)
	# 3 nuvens de poeira: escala 0.45 (–70%), defasadas para não sincronizar
	var offsets := [-22.0, 0.0, 22.0]
	for idx in 3:
		var sp := AnimatedSprite2D.new()
		sp.name = "ImpactFX%d" % idx
		sp.sprite_frames = impact_sf
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.z_index = 6
		sp.scale = Vector2.ONE * 0.495
		add_child(sp)
		sp.play("burn")
		sp.frame = (idx * 3) % _IMPACT_FRAMES  # defasagem inicial
		_impact_fxs.append(sp)

	# _body_line já está visível por padrão — corpo contínuo via Line2D

func _configure_sheet_sprite(sprite: Sprite2D, texture: Texture2D) -> void:
	sprite.texture = texture
	sprite.hframes = _SHEET_COLS
	sprite.vframes = _SHEET_ROWS
	sprite.centered = true

func _update_visuals() -> void:
	var frame := int(_t * 12.0) % _SHEET_FRAMES
	var beam_vec := _end - origin
	var beam_angle := beam_vec.angle()
	var beam_dir := beam_vec.normalized() if beam_vec.length_squared() > 0.0 else Vector2(0.0, 1.0)
	var cap_scale := maxf(0.35, (half_width * 2.4) / _frame_h)
	var end_cap_scale := cap_scale * 2.0   # ponta maior que a origem
	var fl: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 30.0)
	# Sprite da ponta avança 10px além de _end para sobrepar o chão/parede visualmente.
	var body_end := _end - beam_dir * (end_cap_scale * _frame_h * 0.5) + beam_dir * 10.0

	if _origin_sprite != null:
		_origin_sprite.position = origin
		_origin_sprite.frame = frame
		_origin_sprite.scale = Vector2.ONE * cap_scale
		_origin_sprite.rotation = beam_angle
		_origin_sprite.modulate = Color(1.0, 0.9 + 0.1 * fl, 0.9 + 0.1 * fl, 1.0)

	if _body_line != null and _body_atlas != null:
		var col := frame % _SHEET_COLS
		var row := frame / _SHEET_COLS
		_body_atlas.region = Rect2(float(col) * _frame_w, float(row) * _frame_h, _frame_w, _frame_h)
		_body_line.points = PackedVector2Array([origin, body_end])
		_body_line.width = half_width * 2.0
		_body_line.modulate = Color(1.0, 0.35, 0.05, 0.85)
	elif _body_line != null:
		_body_line.points = PackedVector2Array([origin, body_end])
		_body_line.width = half_width * 2.0
		_body_line.default_color = Color(1.0, 0.35, 0.05, 0.85)

	if _body_inner != null:
		_body_inner.points = PackedVector2Array([origin, body_end])
		_body_inner.width = half_width * 0.7
		_body_inner.default_color = Color(1.0, 0.92, 0.5, 0.9)

	if _end_sprite != null:
		# Centro do sprite alinha com body_end; sprite (z=5) cobre o fim da linha.
		_end_sprite.position = body_end
		_end_sprite.frame = frame
		_end_sprite.scale = Vector2.ONE * end_cap_scale
		_end_sprite.rotation = beam_angle
		_end_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if _impact_fxs.size() > 0:
		# usa a normal real do raycast: piso=(0,-1), parede=(±1,0)
		var is_wall := absf(_hit_normal.x) > absf(_hit_normal.y)
		var tangent  : Vector2
		var fx_rot   : float
		if is_wall:
			tangent = Vector2(0.0, 1.0)
			fx_rot  = PI * 0.5
		else:
			tangent = Vector2(1.0, 0.0)
			fx_rot  = 0.0
		var offsets := [-22.0, 0.0, 22.0]
		for idx in _impact_fxs.size():
			var sp := _impact_fxs[idx]
			sp.position = _end + _hit_normal * 1.0 + tangent * offsets[idx]
			sp.rotation = fx_rot


func _draw() -> void:
	if _body_line == null:
		var fl: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 30.0)
		draw_line(origin, _end, Color(1.0, 0.35 + 0.25 * fl, 0.05, 0.9), half_width * 2.0)
		draw_line(origin, _end, Color(1.0, 0.85, 0.3, 0.95), half_width)
	if DebugBoot.hitbox_debug:
		# Sem Area2D real: o dano usa distância ponto-segmento < half_width+24
		# a cada frame (_physics_process). A linha grossa aqui É essa margem —
		# não só o half_width visual. Círculo na ponta = alcance extra do impacto.
		draw_line(origin, _end, Color(1.0, 0.0, 0.0, 0.9), (half_width + 24.0) * 2.0)
		draw_arc(_end, half_width + _TIP_EXTRA_MARGIN, 0.0, TAU, 24, Color(1.0, 0.0, 0.0, 0.9), 2.0)

func _point_seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var denom: float = ab.length_squared()
	var t: float = 0.0
	if denom > 0.0:
		t = clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)
