extends BossBase

var _shielded: bool = true
var _shield_timer: float = 0.5
var _open_timer: float = 0.0
var _shield_duration: float = 3.0
var _open_duration: float = 2.0

func _do_combat(delta: float) -> void:
	if player == null:
		return
	_tick_shield(delta)
	var dx: float = player.global_position.x - global_position.x
	if abs(dx) > 120.0:
		velocity.x = sign(dx) * 90.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	_clamp_to_arena()

func _tick_shield(delta: float) -> void:
	if _shielded:
		_shield_timer -= delta
		if _shield_timer <= 0.0:
			_shielded = false
			_open_timer = _open_duration
	else:
		_open_timer -= delta
		if _open_timer <= 0.0:
			_shielded = true
			_shield_timer = _shield_duration

func take_damage(amount: int, source_id: String = "") -> void:
	if _shielded:
		return
	super.take_damage(amount, source_id)

func _do_attack() -> void:
	_is_attacking = true
	if player == null:
		_is_attacking = false
		return
	_shielded = false
	_open_timer = _open_duration
	var dir: float = sign(player.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	velocity.x = dir * 350.0
	await get_tree().create_timer(0.4).timeout
	if is_dead:
		_is_attacking = false
		return
	velocity.x = 0.0
	if player == null:
		_is_attacking = false
		return
	var shots: int = 3 if phase >= 2 else 2
	var spread: float = 0.35
	for i in shots:
		var angle: float = (float(i) - float(shots - 1) * 0.5) * spread
		var vel := Vector2(dir * 280.0, 0.0).rotated(angle)
		_spawn_projectile(global_position, vel, 20, "nullvex", Color(0.5, 0.0, 1.0))
	if phase >= 2:
		_spawn_projectile(global_position, Vector2(-dir * 280.0, -50.0), 20, "nullvex", Color(0.5, 0.0, 1.0))
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.2
	_shield_duration = 2.0
