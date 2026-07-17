# Plataforma que desliza horizontalmente enquanto o player está em cima —
# solta e volta devagar pro início quando ninguém pisa nela por settle_time.
# AnimatableBody2D + sync_to_physics: mesma técnica de acumulador de
# stages/stage_01/moving_platform.gd (nunca ler position de volta).
extends AnimatableBody2D

@export var slide_distance: float = 220.0   # px que a plataforma desliza a partir do repouso
@export var slide_speed: float = 140.0      # px/s enquanto alguém está em cima
@export var return_speed: float = 60.0      # px/s ao voltar sozinha pro início
@export var settle_time: float = 0.6        # tempo sem ninguém em cima até começar a voltar
@export var slide_dir: float = 1.0          # +1 desliza pra direita, -1 pra esquerda

var _offset: float = 0.0     # deslocamento acumulado a partir do repouso (nunca lê position)
var _occupied: bool = false
var _settle_timer: float = 0.0
var _rider_count: int = 0

func _ready() -> void:
	sync_to_physics = true
	var top := Area2D.new()
	top.name = "RiderDetect"
	top.collision_layer = 0
	top.collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(96.0, 12.0)
	cs.shape = sh
	cs.position = Vector2(0.0, -22.0)   # logo acima do topo da plataforma (96×32)
	top.add_child(cs)
	add_child(top)
	top.body_entered.connect(func(_b: Node) -> void:
		_rider_count += 1
		_occupied = true)
	top.body_exited.connect(func(_b: Node) -> void:
		_rider_count = maxi(0, _rider_count - 1)
		_occupied = _rider_count > 0)

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return   # bot: plataforma parada, valida o layout sem depender do timing
	if _occupied:
		_settle_timer = 0.0
		var step: float = minf(slide_speed * delta, slide_distance - _offset)
		_offset += step
		position.x += slide_dir * step
	else:
		_settle_timer += delta
		if _settle_timer >= settle_time and _offset > 0.0:
			var step: float = minf(return_speed * delta, _offset)
			_offset -= step
			position.x -= slide_dir * step
