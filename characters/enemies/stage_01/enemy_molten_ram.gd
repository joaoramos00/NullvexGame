extends EnemyBase
class_name EnemyMoltenRam

const FRAMES := 9
const FPS := 9.0
const PATROL := 50.0
const CHARGE_SPEED := 360.0
const DETECT_X := 460.0
const DETECT_Y := 90.0
const CHARGE_TIME := 0.9
const COOLDOWN := 1.1

enum S { PATROL, CHARGE, COOLDOWN }
var _state: S = S.PATROL
var _timer := 0.0

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
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	match _state:
		S.PATROL:
			if is_on_floor() and not _has_floor_ahead():
				_direction = -_direction
			velocity.x = PATROL * _direction
			var p := _player()
			if p != null:
				var off: Vector2 = p.global_position - global_position
				if absf(off.y) <= DETECT_Y and absf(off.x) <= DETECT_X and signf(off.x) == _direction:
					_state = S.CHARGE
					_timer = CHARGE_TIME
		S.CHARGE:
			velocity.x = CHARGE_SPEED * _direction
			_timer -= delta
			if _timer <= 0.0 or is_on_wall():
				_state = S.COOLDOWN
				_timer = COOLDOWN
		S.COOLDOWN:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_state = S.PATROL
	move_and_slide()
	if is_on_wall() and _state == S.PATROL:
		_direction = -_direction
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if (_invincible and int(Time.get_ticks_msec() / 80) % 2 == 0) else 1.0
	_advance_sprite_frame_loop(delta, FRAMES, FPS)

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
