# stages/stage_01/moving_platform.gd
# AnimatableBody2D (não StaticBody2D): com sync_to_physics, mover via position no
# _physics_process faz o player PARADO ser carregado junto (move_and_slide lê a
# velocidade da plataforma). StaticBody2D movido por position não carrega o rider.
extends AnimatableBody2D

@export var move_distance: float = 320.0   # pixels de deslocamento total (metade p/ cada lado)
@export var speed:         float = 80.0    # pixels/s

var _dir:      float = 1.0
var _traveled: float = 0.0   # offset acumulado (não lê position de volta — sync_to_physics
                             #  não atualiza a leitura no mesmo frame; igual ao vertical_platform)

func _ready() -> void:
	sync_to_physics = true

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return   # debug do bot: plataformas paradas (valida o layout, não o timing)
	var half := move_distance * 0.5
	var step := _dir * speed * delta
	_traveled += step
	if _traveled >= half:
		_traveled = half
		_dir = -1.0
	elif _traveled <= -half:
		_traveled = -half
		_dir = 1.0
	position.x += step
