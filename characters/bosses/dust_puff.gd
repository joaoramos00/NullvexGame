extends Node2D
class_name DustPuff

# Rastro de pó de gelo do ice_shard — efeito visual puro (sem colisão),
# spawnado periodicamente atrás do estilhaço durante o voo. 9 frames,
# sprite sheet gerada via PixelLab + skill pixellab-effect.
const TEX := preload("res://characters/bosses/cryovex/fx_ice_dust_trail.png")
const _FRAMES := 9
const _FPS := 16.0

var _frame := 0
var _anim_timer := 0.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_sprite.texture = TEX
	_sprite.hframes = _FRAMES

func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 1.0 / _FPS:
		_anim_timer -= 1.0 / _FPS
		_frame += 1
		if _frame >= _FRAMES:
			queue_free()
			return
		_sprite.frame = _frame
