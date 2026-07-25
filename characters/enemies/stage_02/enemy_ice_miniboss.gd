extends EnemyBase
class_name EnemyIceMiniBoss

const SLIDE_SPEED := 320.0
const HOP_IMPULSE := -360.0

enum State { ADVANCE, SLIDE, HOP, RECOVER }

@export var arena_left: float = 0.0
@export var arena_right: float = 1000.0

var _state: State = State.ADVANCE
var _cooldown := 1.0
var _recover_timer := 0.0

func _init() -> void:
	max_hp = 15
	contact_damage = 3

func _ready() -> void:
	max_hp = 15
	contact_damage = 3
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_cooldown = maxf(0.0, _cooldown - delta)
	match _state:
		State.ADVANCE:
			_tick_advance()
		State.SLIDE:
			_tick_slide()
		State.HOP:
			_tick_hop()
		State.RECOVER:
			_tick_recover(delta)
	move_and_slide()
	if is_on_wall():
		_direction = -_direction
		_enter_recover(0.45)
	global_position.x = clampf(global_position.x, arena_left, arena_right)

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _tick_advance() -> void:
	var player := _get_player()
	if player != null:
		var dx := player.global_position.x - global_position.x
		_direction = signf(dx) if dx != 0.0 else _direction
	velocity.x = PATROL_SPEED * 0.9 * _direction
	if _cooldown <= 0.0:
		if randf() < 0.55:
			_state = State.SLIDE
		else:
			velocity.y = HOP_IMPULSE
			_state = State.HOP

func _tick_slide() -> void:
	velocity.x = SLIDE_SPEED * _direction
	if global_position.x <= arena_left or global_position.x >= arena_right:
		_direction = -_direction
		_enter_recover(0.5)

func _tick_hop() -> void:
	velocity.x = PATROL_SPEED * 1.4 * _direction
	if is_on_floor():
		_enter_recover(0.65)

func _tick_recover(delta: float) -> void:
	velocity.x = 0.0
	_recover_timer -= delta
	if _recover_timer <= 0.0:
		_cooldown = 1.2
		_state = State.ADVANCE

func _enter_recover(duration: float) -> void:
	_recover_timer = duration
	_state = State.RECOVER
