extends BossBase

func _do_combat(delta: float) -> void:
	if player == null:
		return
	var dx := player.global_position.x - global_position.x
	if abs(dx) > 150.0:
		velocity.x = sign(dx) * 80.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	_clamp_to_arena()

func _do_attack() -> void:
	_is_attacking = true
	velocity.x = 0.0
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
	var shots := 3 if phase == 2 else 1
	var fan_angles: Array[float] = [0.0, -0.26, 0.26]
	for i in shots:
		var vel := Vector2(dir * 300.0, 0.0).rotated(fan_angles[i] * dir)
		_spawn_projectile(global_position, vel, 15, "ignarath", Color(0.9, 0.3, 0.0))
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.3
