extends BossBase

func _ready() -> void:
	super._ready()
	gravity_scale = 0.0

func _do_combat(_delta: float) -> void:
	if player == null:
		return
	var dx := player.global_position.x - global_position.x
	var target_y := player.global_position.y - 100.0
	var dy := target_y - global_position.y
	velocity.x = sign(dx) * 100.0 if abs(dx) > 200.0 else 0.0
	velocity.y = sign(dy) * 80.0 if abs(dy) > 30.0 else 0.0
	_clamp_to_arena()

func _do_attack() -> void:
	_is_attacking = true
	await get_tree().create_timer(0.5).timeout
	if is_dead:
		_is_attacking = false
		return
	if player == null:
		_is_attacking = false
		return
	var dir: float = sign(player.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	var beams := 3 if phase == 2 else 2
	for i in beams:
		var oy := (i - (beams - 1) * 0.5) * 40.0
		_spawn_projectile(
			global_position + Vector2(0.0, oy),
			Vector2(dir * 600.0, 0.0),
			20, "luxar", Color(1.0, 1.0, 0.8)
		)
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.0
