# Raio da tempestade (tema da Z3): cicla OCIOSO → AVISO (linha vertical tênue
# tremeluzindo no ponto de queda) → DESCARGA (coluna brilhante, dano forte).
# position = ponto de impacto no piso; a coluna sobe column_height a partir daí.
# No modo bot fica congelado OCIOSO.
extends Area2D

@export var column_height: float = 340.0
@export var idle_time: float = 2.2
@export var warn_time: float = 0.7
@export var strike_time: float = 0.25
@export var phase_offset: float = 0.0
@export var damage: int = 20

var _t: float = 0.0
var _tick: float = 0.0
var _bodies: Array[Node] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 5
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(48.0, column_height)
	cs.shape = sh
	cs.position = Vector2(0.0, -column_height * 0.5)
	add_child(cs)
	body_entered.connect(func(b: Node) -> void:
		if not _bodies.has(b):
			_bodies.append(b))
	body_exited.connect(func(b: Node) -> void:
		_bodies.erase(b))
	_t = fmod(phase_offset, _cycle())

func _cycle() -> float:
	return idle_time + warn_time + strike_time

func _is_strike() -> bool:
	return _t >= idle_time + warn_time

func _is_warn() -> bool:
	return _t >= idle_time and _t < idle_time + warn_time

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return
	_t = fmod(_t + delta, _cycle())
	queue_redraw()
	if not _is_strike():
		_tick = 0.0
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.3
		for b in _bodies:
			if is_instance_valid(b) and b.has_method("take_damage"):
				b.take_damage(damage)

func _draw() -> void:
	if _is_strike():
		var a := 0.75 + 0.25 * sin(_t * 90.0)
		draw_rect(Rect2(-20.0, -column_height, 40.0, column_height), Color(0.55, 0.85, 1.0, 0.4 * a))
		draw_rect(Rect2(-7.0, -column_height, 14.0, column_height), Color(1.0, 1.0, 0.92, a))
		# clarão no ponto de impacto
		draw_circle(Vector2.ZERO, 26.0, Color(1.0, 0.98, 0.7, 0.55 * a))
	elif _is_warn():
		var blink := 0.15 + 0.30 * absf(sin(_t * 24.0))
		var seg := 0.0
		while seg < column_height:
			draw_line(Vector2(0.0, -seg), Vector2(0.0, -minf(seg + 18.0, column_height)),
				Color(0.8, 0.92, 1.0, blink), 2.0)
			seg += 30.0
		draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.95, 0.6, blink))
