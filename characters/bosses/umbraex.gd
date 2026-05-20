extends BossBase

func _do_combat(_delta: float) -> void:
	velocity.x = 0.0

func _do_attack() -> void:
	_is_attacking = true
	if player != null:
		var behind := -120.0 if player.facing_right else 120.0
		var tx: float = clamp(
			player.global_position.x + behind,
			arena_left + 60.0, arena_right - 60.0
		)
		global_position = Vector2(tx, player.global_position.y)
		queue_redraw()
	await get_tree().create_timer(0.15).timeout
	if is_dead:
		_is_attacking = false
		return
	if player == null:
		_is_attacking = false
		return
	var dir: float = sign(player.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	var count := 5 if phase == 2 else 2
	for i in count:
		var angle := (i - (count - 1) * 0.5) * 0.3
		var vel := Vector2(dir * 200.0, 0.0).rotated(angle)
		_spawn_projectile(global_position, vel, 15, "umbraex", Color(0.3, 0.0, 0.5))
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 0.9
