extends Area2D
class_name PlayerGravityMissile

# Habilidade "Gravity Missile" do Zael, desbloqueada ao derrotar o Gravitus.
# Reusa as sprites do próprio GravitusMissile (fx_missile_fly.png +
# fx_missile_explosion.png), agora atiradas em linha reta pelo player.
#
# Ciclo idêntico ao do boss:
#   FLY       -> míssil voando (9f loop), impacto -> EXPLOSION
#   EXPLOSION -> implosão gravitacional (9f uma vez) -> queue_free.

const TEX_FLY := preload("res://characters/bosses/gravitus/fx_missile_fly.png")
const TEX_EXPLOSION := preload("res://characters/bosses/gravitus/fx_missile_explosion.png")
const _FLY_FRAMES := 9
const _FLY_FPS := 16.0
const _EXPLOSION_FRAMES := 9
const _EXPLOSION_FPS := 20.0

var dir: float = 1.0
var speed: float = 460.0
var damage: int = 3
var source_id: String = "zael_gravity_missile"
var _lifetime: float = 3.0

var _exploding: bool = false
var _anim_frame: int = 0
var _anim_timer: float = 0.0

var _sprite: Sprite2D
var _collision: CollisionShape2D

func _ready() -> void:
	collision_layer = 8  # projéteis do player
	collision_mask = 5   # enemy (4) + world (1)
	_collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	_collision.shape = shape
	add_child(_collision)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	body_entered.connect(_on_body_entered)
	_sprite.texture = TEX_FLY
	_sprite.hframes = _FLY_FRAMES
	_sprite.frame = 0
	# Arte do fx_missile_fly aponta pra esquerda por default; -PI alinha "pra
	# esquerda" com a direção real de voo. Igual ao GravitusMissile do boss.
	rotation = Vector2(dir, 0.0).angle() - PI

func _physics_process(delta: float) -> void:
	if _exploding:
		_anim_timer += delta
		if _anim_timer >= 1.0 / _EXPLOSION_FPS:
			_anim_timer -= 1.0 / _EXPLOSION_FPS
			_anim_frame += 1
			if _anim_frame >= _EXPLOSION_FRAMES:
				queue_free()
				return
			_sprite.frame = _anim_frame
		return
	global_position.x += dir * speed * delta
	_anim_timer += delta
	if _anim_timer >= 1.0 / _FLY_FPS:
		_anim_timer -= 1.0 / _FLY_FPS
		_anim_frame = (_anim_frame + 1) % _FLY_FRAMES
		_sprite.frame = _anim_frame
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _exploding:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	_start_explosion()

func _start_explosion() -> void:
	_exploding = true
	_anim_frame = 0
	_anim_timer = 0.0
	rotation = 0.0
	_sprite.texture = TEX_EXPLOSION
	_sprite.hframes = _EXPLOSION_FRAMES
	_sprite.frame = 0
	set_deferred("monitoring", false)
