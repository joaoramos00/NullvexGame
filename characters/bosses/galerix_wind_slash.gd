extends Area2D
class_name GalerixWindSlash

# Boss variant do wind slash — mesma arte que o player_wind_gust.gd do Zael
# (fx_wind_slash.png, 9 frames de crescente girando a 28fps), mas atirado pelo
# boss no player: collision_layer=16 (boss projectiles) + collision_mask=3
# (world + player), damage maior, dispara reto sem passar pelo player.
#
# Cada corpo (player) só toma dano uma vez — a rajada continua voando até
# expirar ou atingir uma parede.

const _TEX        := preload("res://characters/bosses/galerix/fx_wind_slash.png")
const _N_FRAMES    := 9
const _FPS         := 28.0
const _FRAME_SIZE  := 64.0
const _LIFETIME    := 1.6

var dir: float = 1.0
var speed: float = 340.0
var damage: int = 5
var source_id: String = "galerix"

var _hit_bodies: Array = []

func _ready() -> void:
	collision_layer = 16  # boss projectiles
	collision_mask = 3    # world (1) + player (2)
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
