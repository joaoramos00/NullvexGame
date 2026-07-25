extends Area2D
# Rajada de vento (Sonic Boom) da habilidade Galerix do Zael.
# Lâmina crescente giratória que atravessa em linha reta, sem sumir no
# primeiro contato — cada inimigo no caminho só toma dano uma vez.

const _TEX        := preload("res://characters/bosses/galerix/fx_wind_slash.png")
const _N_FRAMES    := 9
const _FPS         := 28.0
const _FRAME_SIZE  := 64.0
const _LIFETIME    := 1.2

var dir: float = 1.0
var speed: float = 420.0
var damage: int = 1
var source_id: String = "galerix"

var _hit_bodies: Array = []

func _ready() -> void:
	collision_layer = 8  # projéteis — sem isso o HitDetector das paredes quebráveis (mask=8) nunca detecta a rajada
	collision_mask = 4  # enemy layer
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48.0, 48.0)
	cs.shape = shape
	add_child(cs)

	var sf := SpriteFrames.new()
	sf.add_animation("spin")
	sf.set_animation_loop("spin", true)
	sf.set_animation_speed("spin", _FPS)
	for i in _N_FRAMES:
		var at := AtlasTexture.new()
		at.atlas = _TEX
		at.region = Rect2(i * _FRAME_SIZE, 0.0, _FRAME_SIZE, _FRAME_SIZE)
		sf.add_frame("spin", at)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = sf
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.flip_h = dir < 0.0
	add_child(sprite)
	sprite.play("spin")

	body_entered.connect(_on_body_entered)

	var timer := Timer.new()
	timer.wait_time = _LIFETIME
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _physics_process(delta: float) -> void:
	global_position.x += dir * speed * delta

func _on_body_entered(body: Node) -> void:
	if body in _hit_bodies:
		return
	if body.has_method("take_damage"):
		_hit_bodies.append(body)
		body.take_damage(damage, source_id)
