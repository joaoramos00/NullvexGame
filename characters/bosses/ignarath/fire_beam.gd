extends Node2D
# Firebreath do Ignarath: feixe que sai da BOCA até o CHÃO e VARRE da vertical
# (90°) pra FORA em direção ao player (o contato no chão avança). A linha inteira
# machuca (distância ponto-a-segmento por frame). Autodestrói ao fim da varredura.

var player: CharacterBase = null
var origin: Vector2 = Vector2.ZERO      # boca, em coords de mundo
var facing: float = 1.0                  # +1 direita, -1 esquerda
var floor_y: float = 0.0
var sweep_time: float = 1.0
var max_angle_deg: float = 70.0          # ângulo final a partir da vertical
var half_width: float = 20.0
var damage: int = 12
var source_id: String = "ignarath"
var _t: float = 0.0
var _end: Vector2 = Vector2.ZERO

func _ready() -> void:
	z_index = 3
	position = Vector2.ZERO               # desenho em coords de mundo
	var depth: float = maxf(8.0, floor_y - origin.y)
	_end = origin + Vector2(0.0, depth)   # começa vertical
	queue_redraw()

func _physics_process(delta: float) -> void:
	_t += delta
	var prog: float = clampf(_t / sweep_time, 0.0, 1.0)
	var ang: float = deg_to_rad(max_angle_deg * prog)   # 0 (vertical) → max (pra fora)
	var depth: float = maxf(8.0, floor_y - origin.y)
	_end = origin + Vector2(facing * depth * tan(ang), depth)
	if is_instance_valid(player) and not player.is_dead:
		if _point_seg_dist(player.global_position, origin, _end) < half_width + 24.0:
			player.take_damage(damage, source_id)
	queue_redraw()
	if _t >= sweep_time + 0.15:
		queue_free()

func _draw() -> void:
	var fl: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 30.0)
	draw_line(origin, _end, Color(1.0, 0.35 + 0.25 * fl, 0.05, 0.9), half_width * 2.0)
	draw_line(origin, _end, Color(1.0, 0.85, 0.3, 0.95), half_width)

func _point_seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var denom: float = ab.length_squared()
	var t: float = 0.0
	if denom > 0.0:
		t = clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)
