extends Node2D
class_name FrostImpact

# Efeito visual puro (sem colisão/dano — o dano já foi aplicado por quem
# spawna isso) tocado no instante em que a mordida do Cryovex acerta o
# jogador. 9 frames, sprite sheet gerada via PixelLab + skill pixellab-effect.
const TEX := preload("res://characters/bosses/cryovex/fx_bite_impact.png")
const _FRAMES := 9
const _FPS := 20.0

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
