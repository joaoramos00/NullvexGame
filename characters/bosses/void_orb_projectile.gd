extends Area2D
class_name VoidOrbProjectile

# Canhão de sombra do Umbraex (ataque Punch): orbe de vazio comprimido que
# viaja reto até o player e, enquanto próximo, puxa o player pra perto
# (CharacterBase.apply_stage_wind) — difícil de desviar. Animação "vibrate"
# gerada via PixelLab, tocada em loop contínuo durante todo o voo.
const TEX := preload("res://characters/bosses/umbraex/fx_void_orb.png")
const _FRAMES := 9
const _FPS := 14.0
const _SPEED := 180.0
const _PULL_RADIUS := 220.0
const _PULL_STRENGTH := 340.0
const _LIFETIME := 4.0

var velocity: Vector2 = Vector2(-1.0, 0.0)
var damage: int = 16
var source_id: String = "umbraex"
var target: Node2D = null
var _lifetime := _LIFETIME
var _anim_frame := 0
var _anim_timer := 0.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	_sprite.texture = TEX
	_sprite.hframes = _FRAMES
	velocity = velocity.normalized() * _SPEED
	AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	_anim_timer += delta
	if _anim_timer >= 1.0 / _FPS:
		_anim_timer -= 1.0 / _FPS
		_anim_frame = (_anim_frame + 1) % _FRAMES
		_sprite.frame = _anim_frame
	if is_instance_valid(target):
		var to_orb: Vector2 = global_position - target.global_position
		var dist: float = to_orb.length()
		if dist < _PULL_RADIUS and dist > 1.0 and target.has_method("apply_stage_wind"):
			target.apply_stage_wind(to_orb.normalized() * _PULL_STRENGTH * delta)
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	queue_free()
