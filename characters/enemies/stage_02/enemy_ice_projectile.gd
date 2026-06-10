extends Area2D
class_name EnemyIceProjectile

var projectile_velocity: Vector2 = Vector2(260.0, 0.0)
var damage: int = 6
var source_id: String = "stage02_ice"
var color: Color = Color(0.45, 0.9, 1.0)

var _lifetime: float = 4.0
var _hit := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func setup(velocity_value: Vector2, damage_value: int, source_value: String = "stage02_ice", gravity_value: float = 0.0) -> void:
	projectile_velocity = velocity_value
	damage = damage_value
	source_id = source_value
	gravity = gravity_value

func _physics_process(delta: float) -> void:
	if _hit:
		return
	projectile_velocity.y += gravity * delta
	global_position += projectile_velocity * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, color)
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 16, Color(0.75, 1.0, 1.0, 0.8), 2.0)

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	queue_free()
