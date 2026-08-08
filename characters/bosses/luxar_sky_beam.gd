extends Area2D
class_name LuxarSkyBeam

# FX do sky_attack do Luxar. Coluna vertical de luz solar que aparece no chão,
# brilha no pico por alguns frames (janela de dano), e some. Múltiplas
# instâncias spawnam em posições x aleatórias durante o sky_call do boss.
#
# Sprite gerado via PixelLab (object 3e35c61c, anim e8169a09, 9 frames)
# stitched em spritesheet horizontal via tools/stitch_frames.ps1.

const _TEX := preload("res://characters/bosses/luxar/luxar_sky_beam.png")
const _FRAMES := 9
const _FPS := 14.0
const _DAMAGE := 5
# Damage window: frames em que o beam está no pico (evita dar dano no fade).
const _DMG_FRAME_START := 2
const _DMG_FRAME_END   := 5

var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _hit_landed: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)
	_sprite.texture = _TEX
	_sprite.hframes = _FRAMES
	_sprite.frame = 0

func _physics_process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 1.0 / _FPS:
		_anim_timer -= 1.0 / _FPS
		_anim_frame += 1
		if _anim_frame >= _FRAMES:
			queue_free()
			return
		_sprite.frame = _anim_frame
		# Desativa collision fora da janela de dano pra não bater cedo/tarde.
		var in_window := _anim_frame >= _DMG_FRAME_START and _anim_frame <= _DMG_FRAME_END
		_collision.set_deferred("disabled", not in_window)

func _on_body_entered(body: Node) -> void:
	if _hit_landed:
		return
	if body.has_method("take_damage"):
		body.take_damage(_DAMAGE, "luxar")
		_hit_landed = true
