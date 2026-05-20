extends BossBase

func _do_combat(delta: float) -> void:
	if player == null:
		return
	var dx := player.global_position.x - global_position.x
	if abs(dx) > 100.0:
		velocity.x = sign(dx) * 70.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	_clamp_to_arena()

func _do_attack() -> void:
	_is_attacking = true
	velocity.x = 0.0
	await get_tree().create_timer(0.2).timeout
	if is_dead:
		_is_attacking = false
		return
	var count := 4 if phase == 2 else 2
	for i in count:
		var dir := 1.0 if i % 2 == 0 else -1.0
		# Phase 2: extra pair fires slightly upward
		var vy := -200.0 if phase == 2 and i >= 2 else 0.0
		_spawn_projectile(
			global_position, Vector2(dir * 200.0, vy),
			12, "gravitus", Color(0.6, 0.2, 0.8)
		)
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.3
