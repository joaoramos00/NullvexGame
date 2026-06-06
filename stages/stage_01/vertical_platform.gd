extends AnimatableBody2D

@export var move_distance: float = 256.0
@export var speed: float = 70.0
@export var start_going_up: bool = false
@export var up_only: bool = false   # elevador: parte da base (start) e sobe move_distance, só pra cima

var _dir: float = 1.0
var _traveled: float = 0.0

func _ready() -> void:
	sync_to_physics = true
	_dir = -1.0 if (start_going_up or up_only) else 1.0

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return   # debug do bot: plataformas paradas (valida o layout, não o timing)
	var step := _dir * speed * delta
	_traveled += step
	if up_only:
		# oscila entre o start (base, 0) e o topo (-move_distance) — nunca abaixo da base.
		if _traveled <= -move_distance:
			_traveled = -move_distance
			_dir = 1.0
		elif _traveled >= 0.0:
			_traveled = 0.0
			_dir = -1.0
	elif _traveled >= move_distance * 0.5:
		_traveled = move_distance * 0.5
		_dir = -1.0
	elif _traveled <= -move_distance * 0.5:
		_traveled = -move_distance * 0.5
		_dir = 1.0
	# AnimatableBody2D com sync_to_physics carrega o player ao mover via
	# position; move_and_collide é proibido nesse modo (gera erro e não carrega).
	position.y += step
