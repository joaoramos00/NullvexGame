extends Area2D
# Onda de fogo rasteira do Ignarath (lançada pela garra): viaja em LINHA RETA pelo
# chão até a parede oposta. A altura (wave_h) é parametrizada pelo chamador; no uso
# atual é baixa (~56px) → dá pra PULAR por cima. Some ao chegar na parede
# (despawn_x) ou no fim do lifetime.

const _FILL_TEX_PATH := "res://stages/stage_01/lava_fill.png"

var dir: float = 1.0           # +1 direita, -1 esquerda
var speed: float = 300.0
var damage: int = 12
var source_id: String = "ignarath"
var despawn_x: float = 0.0
var wave_w: float = 90.0
var wave_h: float = 150.0
var _life: float = 6.0
var _spr: Sprite2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2             # só detecta o player (layer 2)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(wave_w, wave_h)
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
	_spr.region_rect = Rect2(0, 0, wave_w, wave_h)
	_spr.modulate = Color(1.0, 0.55, 0.15)
	_spr.z_index = 2
	add_child(_spr)

func _draw() -> void:
	# fallback se a textura não carregar
	draw_rect(Rect2(-wave_w * 0.5, -wave_h * 0.5, wave_w, wave_h), Color(0.95, 0.35, 0.0, 0.85))

func _physics_process(delta: float) -> void:
	global_position.x += dir * speed * delta
	if _spr != null:                # flicker de chama (só cor — hitbox constante)
		var f: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 35.0)
		_spr.modulate = Color(1.0, 0.4 + 0.25 * f, 0.1, 1.0)
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if (dir > 0.0 and global_position.x >= despawn_x) or (dir < 0.0 and global_position.x <= despawn_x):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
