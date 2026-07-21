extends Area2D
class_name ShurikenProjectile

# Projétil do ataque ThowShuriken do Umbraex. Gira continuamente em voo
# (código, sem animação gerada) e curva suavemente em direção ao player
# a cada frame — "meio teleguiado", não perseguição perfeita.
const TEX := preload("res://characters/bosses/umbraex/fx_shuriken.png")
const _SPIN_SPEED := 14.0   # rad/s
const _TURN_RATE := 2.2     # rad/s de curva máxima em direção ao alvo
const _SPEED := 240.0

var velocity: Vector2 = Vector2(200.0, 0.0)
var damage: int = 8
var source_id: String = "umbraex"
var target: Node2D = null
var _lifetime: float = 3.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	_sprite.texture = TEX
	velocity = velocity.normalized() * _SPEED
	AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)

func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		var desired_angle: float = (target.global_position - global_position).angle()
		var new_angle: float = rotate_toward(velocity.angle(), desired_angle, _TURN_RATE * delta)
		velocity = Vector2.from_angle(new_angle) * _SPEED
	global_position += velocity * delta
	_sprite.rotation += _SPIN_SPEED * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	queue_free()
