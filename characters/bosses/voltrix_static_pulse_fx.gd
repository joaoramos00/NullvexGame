extends Sprite2D
class_name VoltrixStaticPulseFX

# Anel de choque do static_pulse do Voltrix -- toca uma vez (9 frames
# individuais, sem spritesheet) e some. Spawnado no centro do boss quando o
# ataque acerta o player.
const _FRAMES := 9
const _FPS := 14.0

var _frame_textures: Array[Texture2D] = []
var _frame := 0
var _timer := 0.0

func _ready() -> void:
	for i in _FRAMES:
		_frame_textures.append(load("res://characters/bosses/voltrix_fx/fx_static_pulse_f%02d.png" % i))
	texture = _frame_textures[0]

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 1.0 / _FPS:
		_timer -= 1.0 / _FPS
		_frame += 1
		if _frame >= _FRAMES:
			queue_free()
			return
		texture = _frame_textures[_frame]
