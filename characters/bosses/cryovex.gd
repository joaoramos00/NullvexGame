extends BossBase

func _do_combat(delta: float) -> void:
	if player == null:
		return
	var dx := player.global_position.x - global_position.x
	if abs(dx) > 120.0:
		velocity.x = sign(dx) * 60.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	_clamp_to_arena()

func _do_attack() -> void:
	_is_attacking = true
	velocity.x = 0.0
	await get_tree().create_timer(0.25).timeout
	if is_dead:
		_is_attacking = false
		return
	if player == null:
		_is_attacking = false
		return
	var dir: float = sign(player.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	var shots := 3 if phase == 2 else 2
	# low angle, high angle, straight
	var shard_angles: Array[float] = [-0.35, 0.35, 0.0]
	for i in shots:
		var vel := Vector2(dir * 240.0, 0.0).rotated(shard_angles[i])
		_spawn_projectile(global_position, vel, 12, "cryovex", Color(0.4, 0.8, 1.0))
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.2
