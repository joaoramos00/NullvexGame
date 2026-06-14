extends Area2D
class_name BossProjectile

var projectile_velocity: Vector2 = Vector2(200.0, 0.0)
var damage: int = 10
var source_id: String = ""
var color: Color = Color.ORANGE_RED
var _lifetime: float = 4.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)
	queue_redraw()

func _physics_process(delta: float) -> void:
	global_position += projectile_velocity * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, color)

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	queue_free()
