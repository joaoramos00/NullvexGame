extends Sprite2D
class_name GravitusBlackholeFX

# Buraco negro residual que aparece após o Crack do satélite orbital —
# puramente visual (a animação já termina encolhendo até sumir sozinha).
const TEX := preload("res://characters/bosses/gravitus/fx_satellite_blackhole.png")
const _FRAMES := 17
const _FPS    := 14.0

var _frame := 0
var _timer := 0.0

func _ready() -> void:
	texture = TEX
	hframes = _FRAMES
	frame = 0

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 1.0 / _FPS:
		_timer -= 1.0 / _FPS
		_frame += 1
		if _frame >= _FRAMES:
			queue_free()
			return
		frame = _frame
