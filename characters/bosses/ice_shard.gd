extends Area2D
class_name IceShard

# Projétil do IcyBlast do Cryovex — substitui o círculo genérico de
# _spawn_projectile() (boss_base.gd) por um estilhaço de gelo animado
# (9 frames, sprite sheet gerada via PixelLab + skill pixellab-effect).
const TEX := preload("res://characters/bosses/cryovex/fx_iceblast_projectile.png")
const _FRAMES := 9
const _FPS := 14.0

var projectile_velocity: Vector2 = Vector2(240.0, 0.0)
var damage: int = 12
var source_id: String = "cryovex"
var _lifetime: float = 4.0
var _hit := false
var _anim_timer := 0.0
var _frame := 0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)
	_sprite.texture = TEX
	_sprite.hframes = _FRAMES

func _physics_process(delta: float) -> void:
	if _hit:
		return
	global_position += projectile_velocity * delta
	_anim_timer += delta
	if _anim_timer >= 1.0 / _FPS:
		_anim_timer -= 1.0 / _FPS
		_frame = (_frame + 1) % _FRAMES
		_sprite.frame = _frame
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
