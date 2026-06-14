extends Area2D
class_name ZaelBullet

const SPEED := 500.0

var damage: int = 5
var direction: float = 1.0
var source_id: String = "single"
var _hit: bool = false
var _deflected: bool = false
var _deflect_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("player_bullet")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	$Timer.timeout.connect(queue_free)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _hit:
		return
	if _deflected:
		_deflect_velocity.y += 980.0 * delta
		global_position += _deflect_velocity * delta
		for area in get_overlapping_areas():
			_on_area_entered(area)
			return
		for body in get_overlapping_bodies():
			_on_body_entered(body)
			return
		return
	global_position.x += direction * SPEED * delta
	# Checa áreas primeiro (hurtboxes têm prioridade sobre paredes)
	for area in get_overlapping_areas():
		_on_area_entered(area)
		return
	for body in get_overlapping_bodies():
		_on_body_entered(body)
		return

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color.YELLOW)

func deflect_upward() -> void:
	if _deflected:
		return
	_deflected = true
	source_id = "deflected"
	_deflect_velocity = Vector2(direction * SPEED, -SPEED)

func _on_area_entered(area: Area2D) -> void:
	if _hit:
		return
	if area.has_method("take_damage"):
		_hit = true
		area.take_damage(damage, source_id)
		$Timer.stop()
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	else:
		AudioManager.play_sfx(AudioLibrary.sfx_shot_wall)   # bateu na parede/chão
	$Timer.stop()
	queue_free()
