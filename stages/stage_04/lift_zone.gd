# Câmara de empuxo (baixa gravidade): força constante pra CIMA dentro da área —
# pulos viram flutuação lenta; usada pra cruzar abismos largos e subir colunas.
# Visual = traços subindo. Inerte no bot.
extends Area2D

@export var lift_force: float = 700.0
@export var size: Vector2 = Vector2(600.0, 500.0)

var _bodies: Array[Node] = []
var _t: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 4
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
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
			b.apply_stage_wind(Vector2(0.0, -lift_force) * delta)

func _draw() -> void:
	# traços ascendentes (loop 1.6s), espaçados a cada 96px
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	var col := Color(0.55, 0.85, 1.0, 0.30)
	var x := -hw + 48.0
	while x < hw:
		var ph := fmod(_t / 1.6 + fmod(absf(x) * 0.013, 1.0), 1.0)
		var y := hh - size.y * ph
		draw_line(Vector2(x, y), Vector2(x, y - 26.0), col, 2.0)
		x += 96.0
