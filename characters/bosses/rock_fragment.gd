extends Area2D
class_name RockFragment

# Fragmento de pedra que voa em várias direções quando a RollingBoulder
# (ataque StoneShatter do Terragor) quebra numa parede. Sprite: idle
# estático + animação de quebra ao bater em algo (mesmo padrão do
# ice_shard.gd), gerado via PixelLab + skill pixellab-effect.
const TEX_IDLE := preload("res://characters/bosses/terragor/fx_rock_fragment_idle.png")
const TEX_SHATTER := preload("res://characters/bosses/terragor/fx_rock_fragment_shatter.png")
const _SHATTER_FRAMES := 9
const _SHATTER_FPS := 20.0
const _GRAVITY := 500.0

var velocity: Vector2 = Vector2(150.0, -80.0)
var damage: int = 6
var source_id: String = "terragor"
var _lifetime: float = 2.0
var _hit := false
var _shattering := false
var _shatter_frame := 0
var _shatter_anim_timer := 0.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	_sprite.texture = TEX_IDLE
	_sprite.hframes = 1
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	if _shattering:
		_shatter_anim_timer += delta
		if _shatter_anim_timer >= 1.0 / _SHATTER_FPS:
			_shatter_anim_timer -= 1.0 / _SHATTER_FPS
			_shatter_frame += 1
			if _shatter_frame >= _SHATTER_FRAMES:
				queue_free()
				return
			_sprite.frame = _shatter_frame
		return
	if _hit:
		return
	velocity.y += _GRAVITY * delta
	global_position += velocity * delta
	rotation = velocity.angle()
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
		queue_free()
		return
	_shattering = true
	_shatter_frame = 0
	_shatter_anim_timer = 0.0
	_sprite.texture = TEX_SHATTER
	_sprite.hframes = _SHATTER_FRAMES
	_sprite.frame = 0
	rotation = 0.0
