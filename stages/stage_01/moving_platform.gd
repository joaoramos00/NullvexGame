# stages/stage_01/moving_platform.gd
extends StaticBody2D

@export var move_distance: float = 320.0   # pixels de deslocamento total (metade p/ cada lado)
@export var speed:         float = 80.0    # pixels/s

var _start_x: float = 0.0
var _dir:     float = 1.0

func _ready() -> void:
	_start_x = global_position.x

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return   # debug do bot: plataformas paradas (valida o layout, não o timing)
	var half := move_distance * 0.5
	global_position.x += _dir * speed * delta
	if global_position.x >= _start_x + half:
		global_position.x = _start_x + half
		_dir = -1.0
	elif global_position.x <= _start_x - half:
		global_position.x = _start_x - half
		_dir = 1.0
