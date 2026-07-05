# Poço de gravidade: puxa o player em direção ao CENTRO do nó (força radial
# via apply_stage_wind). Visual = anéis concêntricos pulsando. Inerte no bot.
extends Area2D

@export var pull_strength: float = 220.0
@export var radius: float = 240.0

var _bodies: Array[Node] = []
var _t: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 4
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = radius
	cs.shape = sh
	add_child(cs)
	body_entered.connect(func(b: Node) -> void:
		if not _bodies.has(b):
			_bodies.append(b))
	body_exited.connect(func(b: Node) -> void:
		_bodies.erase(b))

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return
	_t += delta
	queue_redraw()
	for b in _bodies:
		if is_instance_valid(b) and b.has_method("apply_stage_wind"):
			var dir: Vector2 = (global_position - (b as Node2D).global_position)
			if dir.length() > 8.0:
				b.apply_stage_wind(dir.normalized() * pull_strength * delta)

func _draw() -> void:
	# anéis colapsando pro centro (período 1.2s)
	for i: int in 3:
		var ph := fmod(_t / 1.2 + float(i) / 3.0, 1.0)
		var r := radius * (1.0 - ph)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(0.72, 0.5, 1.0, 0.35 * ph), 2.0)
	draw_circle(Vector2.ZERO, 10.0, Color(0.5, 0.3, 0.9, 0.6))
