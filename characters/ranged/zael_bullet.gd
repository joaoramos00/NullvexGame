extends Area2D
class_name ZaelBullet

const SPEED := 500.0

var damage: int = 5
var direction: float = 1.0

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    $Timer.timeout.connect(queue_free)
    queue_redraw()

func _physics_process(delta: float) -> void:
    global_position.x += direction * SPEED * delta

func _draw() -> void:
    draw_circle(Vector2.ZERO, 6.0, Color.YELLOW)

func _on_body_entered(_body: Node) -> void:
    queue_free()
