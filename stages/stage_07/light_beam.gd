# Feixe de luz contínuo definido por uma lista de pontos (polilinha, em
# coordenadas LOCAIS ao nó — o primeiro ponto normalmente é (0,0) e os
# demais relativos a ele). Um feixe reto tem 2 pontos; um feixe "espelhado"
# tem 3+ (dobra num ponto de espelho fixo definido em tempo de design) — o
# mesmo código cobre os dois casos, cada segmento consecutivo vira uma
# Area2D retangular rotacionada. Dano por contato com cooldown por corpo
# (evita dano repetido a cada frame). set_active(false) desliga o feixe
# permanentemente (chamado por light_switch.gd) — sem timer, ao contrário
# de stages/stage_06/phase_platform.gd.
extends Node2D
class_name LightBeam

@export var points: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(400.0, 0.0)]
@export var active: bool = true
@export var damage: int = 10
@export var beam_width: float = 12.0
@export var beam_color: Color = Color(1.0, 0.95, 0.6, 0.85)

const HIT_COOLDOWN := 0.4

var _segments: Array[Area2D] = []
var _cooldowns: Dictionary = {}

func _ready() -> void:
	_build_segments()
	_apply_active()
	queue_redraw()

func _build_segments() -> void:
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var seg_len := a.distance_to(b)
		if seg_len <= 0.0:
			continue
		var mid := (a + b) * 0.5
		var angle := (b - a).angle()
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		area.position = mid
		area.rotation = angle
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(seg_len, beam_width)
		cs.shape = sh
		area.add_child(cs)
		add_child(area)
		area.body_entered.connect(_on_body_entered)
		_segments.append(area)

func set_active(value: bool) -> void:
	active = value
	_apply_active()
	queue_redraw()

func _apply_active() -> void:
	var on: bool = active and not DebugBoot.bot_enabled
	for seg in _segments:
		seg.monitoring = on
		seg.monitorable = on

func _on_body_entered(body: Node) -> void:
	if not active or DebugBoot.bot_enabled:
		return
	if _cooldowns.has(body):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, "light_beam")
	_cooldowns[body] = HIT_COOLDOWN

func _physics_process(delta: float) -> void:
	if _cooldowns.is_empty():
		return
	for b in _cooldowns.keys().duplicate():
		_cooldowns[b] -= delta
		if _cooldowns[b] <= 0.0:
			_cooldowns.erase(b)

func _draw() -> void:
	if not active:
		return
	for i in points.size() - 1:
		draw_line(points[i], points[i + 1], beam_color, beam_width * 0.5)
