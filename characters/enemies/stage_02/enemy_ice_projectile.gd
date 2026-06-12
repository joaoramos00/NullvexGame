extends Area2D
class_name EnemyIceProjectile

var projectile_velocity: Vector2 = Vector2(260.0, 0.0)
var damage: int = 6
var source_id: String = "stage02_ice"
var projectile_variant: String = "ice_ball"
var color: Color = Color(0.45, 0.9, 1.0)

var _lifetime: float = 4.0
var _hit := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func setup(
	velocity_value: Vector2,
	damage_value: int,
	source_value: String = "stage02_ice",
	gravity_value: float = 0.0,
	variant_value: String = "ice_ball"
) -> void:
	projectile_velocity = velocity_value
	damage = damage_value
	source_id = source_value
	projectile_variant = variant_value
	gravity = gravity_value
	rotation = projectile_velocity.angle() if projectile_velocity.length_squared() > 0.0 else 0.0
	_apply_variant_collision()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _hit:
		return
	projectile_velocity.y += gravity * delta
	global_position += projectile_velocity * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	match projectile_variant:
		"ice_arrow":
			draw_polygon(
				PackedVector2Array([Vector2(17, 0), Vector2(3, -6), Vector2(-17, -4), Vector2(-10, 0), Vector2(-17, 4), Vector2(3, 6)]),
				PackedColorArray([Color(0.65, 1.0, 1.0), Color(0.35, 0.78, 1.0), Color(0.18, 0.45, 0.9), Color(0.5, 0.9, 1.0), Color(0.18, 0.45, 0.9), Color(0.35, 0.78, 1.0)])
			)
			draw_line(Vector2(-14, 0), Vector2(10, 0), Color(0.9, 1.0, 1.0), 2.0)
		"ice_cannonball":
			draw_circle(Vector2.ZERO, 10.0, Color(0.35, 0.82, 1.0))
			draw_circle(Vector2(-3, -3), 4.0, Color(0.85, 1.0, 1.0, 0.9))
			draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 18, Color(0.1, 0.45, 0.9, 0.8), 2.0)
		"eye_beam":
			draw_rect(Rect2(Vector2(-4, -5), Vector2(40, 10)), Color(0.38, 0.95, 1.0, 0.75))
			draw_rect(Rect2(Vector2(-1, -2), Vector2(36, 4)), Color(0.9, 1.0, 1.0, 0.95))
			draw_circle(Vector2(-5, 0), 4.0, Color(0.65, 1.0, 1.0))
		_:
			draw_circle(Vector2.ZERO, 8.0, Color(0.55, 0.92, 1.0))
			draw_circle(Vector2(-3, -3), 3.0, Color(0.9, 1.0, 1.0, 0.85))
			draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 16, Color(0.2, 0.6, 1.0, 0.8), 2.0)

func _apply_variant_collision() -> void:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return
	match projectile_variant:
		"ice_arrow":
			var shape := RectangleShape2D.new()
			shape.size = Vector2(34.0, 10.0)
			collision_shape.position = Vector2.ZERO
			collision_shape.shape = shape
		"eye_beam":
			var shape := RectangleShape2D.new()
			shape.size = Vector2(42.0, 12.0)
			collision_shape.position = Vector2(16.0, 0.0)
			collision_shape.shape = shape
		"ice_cannonball":
			var shape := CircleShape2D.new()
			shape.radius = 12.0
			collision_shape.position = Vector2.ZERO
			collision_shape.shape = shape
		_:
			var shape := CircleShape2D.new()
			shape.radius = 9.0
			collision_shape.position = Vector2.ZERO
			collision_shape.shape = shape

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	queue_free()
