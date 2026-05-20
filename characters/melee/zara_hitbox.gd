extends Area2D
class_name ZaraHitbox

const ATTACK_DURATION := 0.15

var damage: int = 8
var source_id: String = "sword"
var _hit_bodies: Array[Node] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Timer.wait_time = ATTACK_DURATION
	$Timer.start()
	$Timer.timeout.connect(queue_free)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-14, -16, 28, 32), Color(1.0, 0.2, 0.2, 0.4))

func _on_body_entered(body: Node) -> void:
	if body in _hit_bodies:
		return
	_hit_bodies.append(body)
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
