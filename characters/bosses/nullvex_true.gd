extends BossBase

var _phase3_entered: bool = false
const PHASE3_THRESHOLD := 0.33

func _do_combat(delta: float) -> void:
	if player == null:
		return
	var speed: float
	if phase >= 3:
		speed = 130.0
	elif phase == 2:
		speed = 100.0
	else:
		speed = 70.0
	var dx: float = player.global_position.x - global_position.x
	if abs(dx) > 200.0:
		velocity.x = sign(dx) * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	_clamp_to_arena()

func _do_attack() -> void:
	_is_attacking = true
	if is_dead or player == null:
		_is_attacking = false
		return
	await get_tree().create_timer(0.3).timeout
	if is_dead:
		_is_attacking = false
		return
	if player == null:
		_is_attacking = false
		return
	var dir: float = sign(player.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	var shots: int
	if phase >= 3:
		shots = 5
	elif phase == 2:
		shots = 3
	else:
		shots = 2
	var spread: float = 0.3
	for i in shots:
		var angle: float = (float(i) - float(shots - 1) * 0.5) * spread
		var vel := Vector2(dir * 320.0, -50.0).rotated(angle)
		_spawn_projectile(global_position, vel, 25, "nullvex_true", Color(0.0, 0.3, 1.0))
	if phase >= 3:
		for i in 3:
			var ox: float = randf_range(-200.0, 200.0)
			var drop_pos := Vector2(player.global_position.x + ox, global_position.y - 200.0)
			_spawn_projectile(drop_pos, Vector2(ox * 0.3, 400.0), 20, "nullvex_true", Color(0.0, 0.5, 1.0))
	_is_attacking = false

func take_damage(amount: int, source_id: String = "") -> void:
	super.take_damage(amount, source_id)
	if is_dead or _phase3_entered:
		return
	if float(current_hp) / float(max_hp) <= PHASE3_THRESHOLD:
		_phase3_entered = true
		phase = 3
		_enter_phase_3()

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.8

func _enter_phase_3() -> void:
	attack_interval_p2 = 1.0
