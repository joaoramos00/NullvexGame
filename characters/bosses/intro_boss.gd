extends BossBase
class_name IntroBoss

const DASH_SPEED := 320.0
const DASH_DURATION := 0.45
const SHOOT_COOLDOWN := 2.2
const PROJECTILE_SPEED := 260.0

var _attack_phase := 0  # 0=dash, 1=shoot, alternates
var _is_dashing := false
var _dash_timer := 0.0

func _ready() -> void:
	stage_id = 0
	ability_id = ""
	max_hp = 28
	boss_color = Color(0.5, 0.0, 0.1, 1)
	attack_interval_p1 = SHOOT_COOLDOWN
	attack_interval_p2 = SHOOT_COOLDOWN * 0.7
	super()

func _do_combat(delta: float) -> void:
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
			velocity.x = 0.0
	else:
		if player != null:
			var dx: float = player.global_position.x - global_position.x
			if abs(dx) > 80.0:
				velocity.x = sign(dx) * 60.0
			else:
				velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	_clamp_to_arena()

func _do_attack() -> void:
	if _attack_phase == 0:
		_do_dash()
	else:
		_do_shoot()
	_attack_phase = (_attack_phase + 1) % 2

func _do_dash() -> void:
	if player == null:
		return
	var dir: float = sign(player.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	velocity.x = dir * DASH_SPEED
	_is_dashing = true
	_dash_timer = DASH_DURATION

func _do_shoot() -> void:
	if player == null:
		return
	_is_attacking = true
	velocity.x = 0.0
	var dir := (player.global_position - global_position).normalized()
	_spawn_projectile(global_position, dir * PROJECTILE_SPEED, 8, "intro_boss", Color(0.7, 0.1, 0.2))
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.2
