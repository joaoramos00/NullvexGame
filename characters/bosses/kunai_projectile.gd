extends Area2D
class_name KunaiProjectile

# Kunai reta do Umbraex (sem curva/homing, diferente do shuriken). Voa
# parada visualmente; ao bater em algo que não seja o player, crava e gira
# no lugar por um tempo — rotação só por código, sem animação do PixelLab.
const TEX := preload("res://characters/bosses/umbraex/fx_kunai.png")
const _SPEED := 320.0
const _SPIN_SPEED := 18.0   # rad/s ao cravar
const _EMBED_DURATION := 0.5
const _LIFETIME := 3.0

var velocity: Vector2 = Vector2(-1.0, 0.0)
var damage: int = 10
var source_id: String = "umbraex"
var _embedded := false
var _embed_timer := 0.0
var _lifetime := _LIFETIME

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	_sprite.texture = TEX
	velocity = velocity.normalized() * _SPEED
	_sprite.rotation = velocity.angle() - PI
	AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)

func _physics_process(delta: float) -> void:
	if _embedded:
		_sprite.rotation += _SPIN_SPEED * delta
		_embed_timer -= delta
		if _embed_timer <= 0.0:
			queue_free()
		return
	global_position += velocity * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _embedded:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
		queue_free()
		return
	_embedded = true
	_embed_timer = _EMBED_DURATION
	velocity = Vector2.ZERO
