extends Area2D
# Onda de fogo rasteira do Ignarath (lançada pela garra): viaja em LINHA RETA pelo
# chão até a parede oposta. A altura (wave_h) é parametrizada pelo chamador; no uso
# atual é baixa (~56px) → dá pra PULAR por cima. Some ao chegar na parede
# (despawn_x) ou no fim do lifetime.

const _TEX_START    := preload("res://characters/bosses/ignarath/fire_wave_start.png")
const _TEX_BODY     := preload("res://characters/bosses/ignarath/fire_wave_body.png")
const _TEX_END      := preload("res://characters/bosses/ignarath/fire_wave_end.png")
const _SHEET_COLS   := 2
const _SHEET_ROWS   := 2
const _SHEET_FRAMES := 4
const _TEX_GROUND_BURST  := preload("res://characters/bosses/ignarath/fx_ground_burst.png")
const _BURST_FRAMES      := 9
const _BURST_FPS         := 14.0
const _BURST_SPACING     := 80.0

var dir: float = 1.0           # +1 direita, -1 esquerda
var speed: float = 300.0
var damage: int = 12
var source_id: String = "ignarath"
var despawn_x: float = 0.0
var wave_w: float = 90.0
var wave_h: float = 150.0
var _life: float = 6.0
var _t: float = 0.0
var _dist_since_burst: float = 0.0
var _start_sprite: Sprite2D = null
var _body_line: Line2D = null
var _body_atlas: AtlasTexture = null
var _end_sprite: Sprite2D = null
var _frame_w: float = 0.0
var _frame_h: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2             # só detecta o player (layer 2)
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(wave_w, wave_h)
	cs.shape = rect
	add_child(cs)
	_build_visual()
	_update_visuals()
	body_entered.connect(_on_body_entered)

func _build_visual() -> void:
	_frame_w = float(_TEX_BODY.get_width()) / _SHEET_COLS
	_frame_h = float(_TEX_BODY.get_height()) / _SHEET_ROWS

	_start_sprite = Sprite2D.new()
	_start_sprite.name = "WaveStartSprite"
	_configure_sheet_sprite(_start_sprite, _TEX_START)
	_start_sprite.z_index = 2
	add_child(_start_sprite)

	_body_atlas = AtlasTexture.new()
	_body_atlas.atlas = _TEX_BODY
	_body_atlas.region = Rect2(0.0, 0.0, _frame_w, _frame_h)
	_body_line = Line2D.new()
	_body_line.name = "WaveBodyLine"
	_body_line.texture = _body_atlas
	_body_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	_body_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_body_line.begin_cap_mode = Line2D.LINE_CAP_NONE
	_body_line.end_cap_mode = Line2D.LINE_CAP_NONE
	_body_line.width = wave_h
	_body_line.z_index = 1
	add_child(_body_line)

	_end_sprite = Sprite2D.new()
	_end_sprite.name = "WaveEndSprite"
	_configure_sheet_sprite(_end_sprite, _TEX_END)
	_end_sprite.z_index = 2
	add_child(_end_sprite)

func _draw() -> void:
	if _body_line != null:
		return
	# fallback se a textura não carregar
	draw_rect(Rect2(-wave_w * 0.5, -wave_h * 0.5, wave_w, wave_h), Color(0.95, 0.35, 0.0, 0.85))

func _physics_process(delta: float) -> void:
	_t += delta
	var moved: float = speed * delta
	global_position.x += dir * moved
	_dist_since_burst += moved
	if _dist_since_burst >= _BURST_SPACING:
		_dist_since_burst -= _BURST_SPACING
		_spawn_ground_burst()
	_update_visuals()
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if (dir > 0.0 and global_position.x >= despawn_x) or (dir < 0.0 and global_position.x <= despawn_x):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)

func _spawn_ground_burst() -> void:
	var sf := SpriteFrames.new()
	sf.add_animation("burst")
	sf.set_animation_loop("burst", false)
	sf.set_animation_speed("burst", _BURST_FPS)
	for i in _BURST_FRAMES:
		var at := AtlasTexture.new()
		at.atlas = _TEX_GROUND_BURST
		at.region = Rect2(i * 64.0, 0.0, 64.0, 64.0)
		sf.add_frame("burst", at)
	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = sf
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index = 3
	sp.global_position = Vector2(global_position.x, global_position.y + wave_h * 0.5 - 32.0)
	sp.animation_finished.connect(sp.queue_free)
	get_parent().add_child(sp)
	sp.play("burst")

func _configure_sheet_sprite(sprite: Sprite2D, texture: Texture2D) -> void:
	sprite.texture = texture
	sprite.hframes = _SHEET_COLS
	sprite.vframes = _SHEET_ROWS
	sprite.centered = true

func _update_visuals() -> void:
	var frame := int(_t * 12.0) % _SHEET_FRAMES
	var col := frame % _SHEET_COLS
	var row := frame / _SHEET_COLS
	var travel_dir := 1.0 if dir >= 0.0 else -1.0
	var cap := minf(wave_h * 0.55, wave_w * 0.35)
	var start_x := -travel_dir * wave_w * 0.5
	var end_x := travel_dir * wave_w * 0.5
	var body_start := start_x + travel_dir * cap
	var body_end := end_x - travel_dir * cap
	var cap_scale := maxf(0.75, wave_h / 64.0)
	var flame := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 35.0)
	var tint := Color(1.0, 0.4 + 0.25 * flame, 0.1, 1.0)

	if _start_sprite != null:
		_start_sprite.position = Vector2(start_x, 0.0)
		_start_sprite.frame = frame
		_start_sprite.scale = Vector2(cap_scale * travel_dir, cap_scale)
		_start_sprite.modulate = tint

	if _body_line != null and _body_atlas != null:
		_body_atlas.region = Rect2(float(col) * _frame_w, float(row) * _frame_h, _frame_w, _frame_h)
		_body_line.points = PackedVector2Array([Vector2(body_start, 0.0), Vector2(body_end, 0.0)])
		_body_line.width = wave_h
		_body_line.modulate = tint

	if _end_sprite != null:
		_end_sprite.position = Vector2(end_x, 0.0)
		_end_sprite.frame = frame
		_end_sprite.scale = Vector2(cap_scale * travel_dir, cap_scale)
		_end_sprite.modulate = tint
