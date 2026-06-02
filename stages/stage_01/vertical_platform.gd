extends StaticBody2D

@export var move_distance: float = 256.0
@export var speed: float = 70.0
@export var start_going_up: bool = false

var _start_y: float = 0.0
var _dir: float = 1.0

func _ready() -> void:
	_start_y = global_position.y
	_dir = -1.0 if start_going_up else 1.0

func _physics_process(delta: float) -> void:
	var half := move_distance * 0.5
	global_position.y += _dir * speed * delta
	if global_position.y >= _start_y + half:
		global_position.y = _start_y + half
		_dir = -1.0
	elif global_position.y <= _start_y - half:
		global_position.y = _start_y - half
		_dir = 1.0
