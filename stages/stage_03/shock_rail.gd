# Trilho eletrificado pulsante (tema Raio): cicla DESLIGADO → AVISO (barra
# piscando fraca) → LIGADO (dano periódico enquanto o corpo estiver dentro).
# Atravessa-se no ritmo, pela janela desligada. O piso sólido é da stage; este
# nó é só a Area de dano + o visual (desenho próprio, sem arte externa).
# No modo bot fica congelado DESLIGADO (o bot não sabe temporizar).
extends Area2D

@export var width: float = 320.0
@export var off_time: float = 1.6
@export var warn_time: float = 0.5
@export var on_time: float = 1.2
@export var phase_offset: float = 0.0
@export var damage: int = 12

var _t: float = 0.0
var _tick: float = 0.0
var _bodies: Array[Node] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 5
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(width, 40.0)
	cs.shape = sh
	add_child(cs)
	body_entered.connect(func(b: Node) -> void:
		if not _bodies.has(b):
			_bodies.append(b))
	body_exited.connect(func(b: Node) -> void:
		_bodies.erase(b))
	_t = fmod(phase_offset, _cycle())

func _cycle() -> float:
	return off_time + warn_time + on_time

func _is_on() -> bool:
	return _t >= off_time + warn_time

func _is_warn() -> bool:
	return _t >= off_time and _t < off_time + warn_time

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return
	_t = fmod(_t + delta, _cycle())
	queue_redraw()
	if not _is_on():
		_tick = 0.0
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		for b in _bodies:
			if is_instance_valid(b) and b.has_method("take_damage"):
				b.take_damage(damage)

func _draw() -> void:
	var hw := width * 0.5
	if _is_on():
		var a := 0.85 + 0.15 * sin(_t * 40.0)
		draw_rect(Rect2(-hw, 8.0, width, 8.0), Color(1.0, 0.98, 0.55, a))
		draw_rect(Rect2(-hw, 0.0, width, 22.0), Color(0.45, 0.85, 1.0, 0.35 * a))
		# arcos em zigue-zague por cima da barra
		var x := -hw
		while x < hw - 32.0:
			draw_line(Vector2(x, 6.0), Vector2(x + 16.0, -12.0), Color(0.85, 0.95, 1.0, 0.8 * a), 2.0)
			draw_line(Vector2(x + 16.0, -12.0), Vector2(x + 32.0, 8.0), Color(0.85, 0.95, 1.0, 0.8 * a), 2.0)
			x += 64.0
	elif _is_warn():
		var blink := 0.25 + 0.35 * absf(sin(_t * 30.0))
		draw_rect(Rect2(-hw, 8.0, width, 6.0), Color(1.0, 0.95, 0.5, blink))
