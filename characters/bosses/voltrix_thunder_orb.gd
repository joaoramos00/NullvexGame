extends Area2D
class_name VoltrixThunderOrb

# Projétil do thunder_bolt/storm_barrage do Voltrix. Visual: orb de
# eletricidade amarelo-esverdeada, crepitando em loop enquanto voa (9 frames
# individuais, sem spritesheet -- mesmo padrão de troca de textura usado em
# voltrix.gd). Sprites gerados via PixelLab + skill pixellab-effect.
const _FRAMES := 9
const _FPS := 14.0

var _frame_textures: Array[Texture2D] = []
var projectile_velocity: Vector2 = Vector2(240.0, 0.0)
var damage: int = 3
var source_id: String = "voltrix"
var _lifetime: float = 4.0
var _anim_frame := 0
var _anim_timer := 0.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)
	for i in _FRAMES:
		_frame_textures.append(load("res://characters/bosses/voltrix_fx/fx_thunder_orb_f%02d.png" % i))
	_sprite.texture = _frame_textures[0]

func _physics_process(delta: float) -> void:
	global_position += projectile_velocity * delta
	_anim_timer += delta
	if _anim_timer >= 1.0 / _FPS:
		_anim_timer -= 1.0 / _FPS
		_anim_frame = (_anim_frame + 1) % _FRAMES
		_sprite.texture = _frame_textures[_anim_frame]
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	queue_free()
