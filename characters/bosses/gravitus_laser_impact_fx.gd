extends Sprite2D
class_name GravitusLaserImpactFX

# Flash + marca de queimadura quando o laser do satélite (GravitusLaser)
# atinge o chão/parede ou o player. Toca uma vez e some.
const TEX := preload("res://characters/bosses/gravitus/fx_laser_impact.png")
const _FRAMES := 9
const _FPS    := 16.0

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
