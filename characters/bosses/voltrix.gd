extends BossBase

func _do_combat(_delta: float) -> void:
	velocity.x = 0.0

func _do_attack() -> void:
	_is_attacking = true
	if player != null:
		var tx := clamp(
			player.global_position.x + randf_range(-250.0, 250.0),
			arena_left + 60.0, arena_right - 60.0
		)
		global_position = Vector2(tx, arena_floor - 60.0)
		queue_redraw()
	await get_tree().create_timer(0.4).timeout
	if is_dead:
		_is_attacking = false
		return
	var count := 3 if phase == 2 else 1
	for i in count:
		var ox := (i - (count - 1) * 0.5) * 80.0
		_spawn_projectile(
			global_position + Vector2(ox, 0.0),
			Vector2(0.0, 700.0), 18, "voltrix", Color(1.0, 0.95, 0.0)
		)
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.1
