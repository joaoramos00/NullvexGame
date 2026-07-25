extends Area2D
class_name GravitusMissile

# Míssil do ataque Missile Barrage do Gravitus. Voa reto tocando a animação
# "fly" (exaustor pulsando); ao acertar o alvo ou bater em terreno, toca a
# animação "explosion" (implosão gravitacional) antes de sumir — ambas
# geradas via PixelLab a partir do mesmo objeto.
const TEX_FLY := preload("res://characters/bosses/gravitus/fx_missile_fly.png")
const TEX_EXPLOSION := preload("res://characters/bosses/gravitus/fx_missile_explosion.png")
const _FLY_FRAMES := 9
const _FLY_FPS    := 16.0
const _EXPLOSION_FRAMES := 9
const _EXPLOSION_FPS    := 20.0
const _SPEED := 260.0
const _LIFETIME := 3.0

var velocity: Vector2 = Vector2(-1.0, 0.0)
var damage: int = 8
var source_id: String = "gravitus"
var _lifetime := _LIFETIME
var _exploding := false
var _anim_frame := 0
var _anim_timer := 0.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	velocity = velocity.normalized() * _SPEED
	_sprite.texture = TEX_FLY
	_sprite.hframes = _FLY_FRAMES
	rotation = velocity.angle() - PI
	AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)

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
	global_position += velocity * delta
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
	velocity = Vector2.ZERO
	rotation = 0.0
	_sprite.texture = TEX_EXPLOSION
	_sprite.hframes = _EXPLOSION_FRAMES
	_sprite.frame = 0
	set_deferred("monitoring", false)
