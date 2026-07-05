# Esmagador: bloco que cicla ESPERA (em cima) → QUEDA rápida → PAUSA embaixo →
# SUBIDA lenta. Corpo sólido (AnimatableBody2D carrega/empurra) + Area de dano
# na face inferior ativa só durante a queda. Parado em cima no modo bot.
extends AnimatableBody2D

@export var travel: float = 260.0
@export var wait_time: float = 1.2
@export var hold_time: float = 0.8
@export var fall_speed: float = 900.0
@export var rise_speed: float = 120.0
@export var damage: int = 15

var _phase := 0        # 0 espera / 1 queda / 2 pausa / 3 subida
var _timer := 0.0
var _offset := 0.0     # deslocamento acumulado a partir do repouso (topo)
var _hurt: Area2D = null

func _ready() -> void:
	sync_to_physics = true
	_timer = wait_time
	_hurt = Area2D.new()
	_hurt.collision_layer = 0
	_hurt.collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(120.0, 18.0)
	cs.shape = sh
	cs.position = Vector2(0.0, 57.0)   # logo abaixo da face inferior (bloco 128×96)
	_hurt.add_child(cs)
	add_child(_hurt)
	_hurt.body_entered.connect(func(b: Node) -> void:
		if _phase == 1 and b.has_method("take_damage"):
			b.take_damage(damage))

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return
	match _phase:
		0:
			_timer -= delta
			if _timer <= 0.0:
				_phase = 1
		1:
			var step := minf(fall_speed * delta, travel - _offset)
			_offset += step
			position.y += step
			if _offset >= travel:
				_phase = 2
				_timer = hold_time
		2:
			_timer -= delta
			if _timer <= 0.0:
				_phase = 3
		3:
			var step := minf(rise_speed * delta, _offset)
			_offset -= step
			position.y -= step
			if _offset <= 0.0:
				_phase = 0
				_timer = wait_time
