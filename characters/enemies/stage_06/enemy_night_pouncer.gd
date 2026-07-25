extends EnemyBase
class_name EnemyNightPouncer

# Predador que salta em arco periodicamente, vira nas bordas/paredes.
const FRAMES := 9
const FPS := 10.0
const HOP_INTERVAL := 0.9
const HOP_VY := -460.0
const HOP_VX := 150.0

var _hop_timer := 0.6

func _init() -> void:
	max_hp = 2
	contact_damage = 1

func _ready() -> void:
	max_hp = 2
	contact_damage = 1
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor():
		if not _has_floor_ahead():
			_direction = -_direction
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			_hop_timer = HOP_INTERVAL
			velocity.y = HOP_VY
			velocity.x = HOP_VX * _direction
		else:
			velocity.x = 0.0
	move_and_slide()
	if is_on_wall():
		_direction = -_direction
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if (_invincible and int(Time.get_ticks_msec() / 80) % 2 == 0) else 1.0
	_advance_sprite_frame_loop(delta, FRAMES, FPS)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
