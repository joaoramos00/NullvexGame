extends Area2D
class_name ZaelBullet

const SPEED := 500.0

const _TEX_L1 := preload("res://assets/generated/zael_buster/buster_L1.png")
const _TEX_L2 := preload("res://assets/generated/zael_buster/buster_L2.png")
const _TEX_L3 := preload("res://assets/generated/zael_buster/buster_L3.png")

const _N_FRAMES    := 9
const _FPS         := 12.0
const _FRAME_SIZE  := 32.0

var damage: int = 5
var direction: float = 1.0
var source_id: String = "single"
var level: int = 1
var _hit: bool = false
var _deflected: bool = false
var _deflect_velocity: Vector2 = Vector2.ZERO
var _frame: int = 0
var _frame_timer: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group("player_bullet")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	$Timer.timeout.connect(queue_free)
	queue_redraw()

func _tex() -> Texture2D:
	match clampi(level, 1, 3):
		1: return _TEX_L1
		2: return _TEX_L2
		_: return _TEX_L3

func _process(delta: float) -> void:
	if _hit:
		return
	_frame_timer += delta
	if _frame_timer >= 1.0 / _FPS:
		_frame_timer -= 1.0 / _FPS
		_frame = (_frame + 1) % _N_FRAMES
		queue_redraw()

func _draw() -> void:
	var half: float = _FRAME_SIZE * 0.5
	var src := Rect2(_frame * _FRAME_SIZE, 0.0, _FRAME_SIZE, _FRAME_SIZE)
	var dst := Rect2(-half, -half, _FRAME_SIZE, _FRAME_SIZE)
	if direction < 0.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect_region(_tex(), dst, src)

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
	for area in get_overlapping_areas():
		_on_area_entered(area)
		return
	for body in get_overlapping_bodies():
		_on_body_entered(body)
		return

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
		AudioManager.play_sfx(AudioLibrary.sfx_shot_wall)
	$Timer.stop()
	queue_free()
