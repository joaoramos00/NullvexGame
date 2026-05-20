extends BossBase

var _dash_dir: float = 1.0
var _dash_flip_timer: float = 1.8

func _do_combat(delta: float) -> void:
	_dash_flip_timer -= delta
	if _dash_flip_timer <= 0.0:
		_dash_dir *= -1.0
		_dash_flip_timer = 1.8
	if global_position.x <= arena_left + 60.0:
		_dash_dir = 1.0
		_dash_flip_timer = 1.8
	elif global_position.x >= arena_right - 60.0:
		_dash_dir = -1.0
		_dash_flip_timer = 1.8
	velocity.x = _dash_dir * 220.0
	_clamp_to_arena()

func _do_attack() -> void:
	_is_attacking = true
	await get_tree().create_timer(0.15).timeout
	if is_dead:
		_is_attacking = false
		return
	var count := 3 if phase == 2 else 1
	# spread: 0°, -30°, +30°
	var spread_angles: Array[float] = [0.0, -0.52, 0.52]
	for i in count:
		var vel := Vector2(_dash_dir * 120.0, 0.0).rotated(spread_angles[i] * _dash_dir)
		_spawn_projectile(global_position, vel, 10, "galerix", Color(0.2, 0.9, 0.4))
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.0
