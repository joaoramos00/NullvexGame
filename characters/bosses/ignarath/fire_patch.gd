extends Area2D
# Rastro de fogo deixado pela garra do Ignarath: um arco/poça no chão À FRENTE.
# Negação de área curta — dá dano em quem entra e em quem fica em cima (os i-frames
# do player espaçam os hits). Some após `lifetime`, com fade no fim.

const _FILL_TEX_PATH := "res://stages/stage_01/lava_fill.png"

var damage: int = 10
var source_id: String = "ignarath"
var patch_w: float = 180.0
var patch_h: float = 44.0
var lifetime: float = 1.1
var _t: float = 0.0
var _tick: float = 0.0
var _spr: Sprite2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2             # só detecta o player (layer 2)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(patch_w, patch_h)
	cs.shape = rect
	add_child(cs)
	_build_visual()
	body_entered.connect(_on_body_entered)

func _build_visual() -> void:
	var tex := load(_FILL_TEX_PATH) as Texture2D
	if tex == null:
		queue_redraw()             # fallback _draw
		return
	_spr = Sprite2D.new()
	_spr.texture = tex
	_spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_spr.region_enabled = true
	_spr.region_rect = Rect2(0, 0, patch_w, patch_h)
	_spr.modulate = Color(1.0, 0.5, 0.12)
	_spr.z_index = 2
	add_child(_spr)

func _draw() -> void:
	# fallback se a textura não carregar
	draw_rect(Rect2(-patch_w * 0.5, -patch_h * 0.5, patch_w, patch_h), Color(0.95, 0.35, 0.0, 0.8))

func _physics_process(delta: float) -> void:
	_t += delta
	if _spr != null:               # flicker + fade nos últimos 0.35s
		var fl: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 30.0)
		var a: float = clampf((lifetime - _t) / 0.35, 0.0, 1.0)
		_spr.modulate = Color(1.0, 0.35 + 0.25 * fl, 0.1, a)
	if _t >= lifetime:
		queue_free()
		return
	# dano contínuo de área — os i-frames do player (0.5s) espaçam os hits
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.3
		for b in get_overlapping_bodies():
			if b.has_method("take_damage"):
				b.take_damage(damage, source_id)

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
