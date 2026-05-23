extends Area2D
class_name ZaelBullet

const SPEED := 500.0

var damage: int = 5
var direction: float = 1.0
var source_id: String = "single"
var _hit: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    $Timer.timeout.connect(queue_free)
    queue_redraw()

func _physics_process(delta: float) -> void:
    if _hit:
        return
    global_position.x += direction * SPEED * delta
    for body in get_overlapping_bodies():
        _on_body_entered(body)
        return

func _draw() -> void:
    draw_circle(Vector2.ZERO, 6.0, Color.YELLOW)

func _on_body_entered(body: Node) -> void:
    if _hit:
        return
    _hit = true
    if body.has_method("take_damage"):
        body.take_damage(damage, source_id)
    $Timer.stop()
    queue_free()
