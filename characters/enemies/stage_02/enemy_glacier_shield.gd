extends EnemyBase
class_name EnemyGlacierShield

@export var shielded_patrol_speed: float = 48.0
@export var front_damage_multiplier: float = 0.25

func _init() -> void:
	max_hp = 18
	contact_damage = 10

func _ready() -> void:
	max_hp = 18
	contact_damage = 10
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor() and not _has_floor_ahead():
		_direction = -_direction
	velocity.x = shielded_patrol_speed * _direction
	move_and_slide()
	if is_on_wall():
		_direction = -_direction
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if _invincible and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0

func take_damage(amount: int, source: String = "") -> void:
	var actual_amount := amount
	if source == "front" or source == "shield_front":
		actual_amount = max(1, int(ceil(amount * front_damage_multiplier)))
	super.take_damage(actual_amount, source)
