extends Node2D
class_name IceOrbCharge

# Efeito visual puro (sem colisão) do carregamento do 3º ataque do Cryovex:
# fragmentos de gelo convergindo na boca até virar uma esfera espinhosa
# sólida, tocado durante a janela de boca aberta da animação Bite. 17
# frames, sprite sheet gerada via PixelLab + skill pixellab-effect.
const TEX := preload("res://characters/bosses/cryovex/fx_ice_orb_charge.png")
const _FRAMES := 17
const _FPS := 18.0

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
