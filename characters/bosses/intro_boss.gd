extends BossBase
class_name IntroBoss

const _TEX_IDLE  := preload("res://characters/bosses/intro_boss/intro_boss_idle.png")
const _TEX_WALK  := preload("res://characters/bosses/intro_boss/intro_boss_walk.png")
const _TEX_DASH  := preload("res://characters/bosses/intro_boss/intro_boss_dash.png")
const _TEX_SHOOT := preload("res://characters/bosses/intro_boss/intro_boss_shoot.png")

const _IDLE_FRAMES  := 4
const _IDLE_FPS     := 6.0
const _WALK_FRAMES  := 6
const _WALK_FPS     := 8.0
const _DASH_FRAMES  := 6
const _DASH_FPS     := 12.0
const _SHOOT_FRAMES := 6
const _SHOOT_FPS    := 12.0

const DASH_SPEED_P1       := 320.0
const DASH_SPEED_P2       := 420.0
const DASH_DURATION       := 0.45
const WALK_SPEED_P1       := 60.0
const WALK_SPEED_P2       := 100.0
const SHOOT_SPEED_P1      := 260.0
const SHOOT_SPEED_P2      := 340.0
const BURST_SPEED_P1      := 240.0
const BURST_SPEED_P2      := 320.0
const BURST_COUNT_P1      := 3
const BURST_COUNT_P2      := 5
const BURST_SPREAD_P1     := 30.0   # degrees total
const BURST_SPREAD_P2     := 50.0   # degrees total
const SHOOT_DAMAGE        := 8
const BURST_DAMAGE        := 6
const RAGE_FLASH_DURATION := 0.5

var _attack_phase     : int   = 0      # 0=dash  1=shoot  2=burst
var _is_dashing       : bool  = false
var _dash_timer       : float = 0.0
var _is_shooting      : bool  = false  # true for both shoot and burst animations
var _shoot_anim_timer : float = 0.0
var _anim_frame       : int   = 0
var _anim_timer       : float = 0.0
var _facing           : float = -1.0   # -1=left(west/default)  1=right(flip_h)
var _phase2_rage      : bool  = false

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	stage_id           = 0
	ability_id         = ""
	max_hp             = 28
	boss_color         = Color(0.5, 0.0, 0.1, 1)
	attack_interval_p1 = 2.2
	attack_interval_p2 = 1.0
	super()

# Suppress BossBase color-rectangle placeholder.
func _draw() -> void:
	pass

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_dead:
		_update_animation(delta)

func _do_combat(delta: float) -> void:
	if _is_shooting:
		_shoot_anim_timer = maxf(0.0, _shoot_anim_timer - delta)
		if _shoot_anim_timer <= 0.0:
			_is_shooting = false
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
			velocity.x = 0.0
	else:
		if player != null:
			var dx: float = player.global_position.x - global_position.x
			var walk_spd := WALK_SPEED_P2 if phase >= 2 else WALK_SPEED_P1
			if absf(dx) > 80.0:
				velocity.x = sign(dx) * walk_spd
			else:
				velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	_clamp_to_arena()

func _do_attack() -> void:
	match _attack_phase:
		0: _do_dash()
		1: _do_shoot()
		2: _do_burst()
	_attack_phase = (_attack_phase + 1) % 3

func _do_dash() -> void:
	if player == null:
		return
	var dir: float = sign(player.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	var spd := DASH_SPEED_P2 if phase >= 2 else DASH_SPEED_P1
	velocity.x = dir * spd
	_is_dashing = true
	_dash_timer = DASH_DURATION

func _do_shoot() -> void:
	if player == null:
		return
	_is_attacking = true
	_is_shooting = true
	_shoot_anim_timer = float(_SHOOT_FRAMES) / _SHOOT_FPS
	velocity.x = 0.0
	var spd := SHOOT_SPEED_P2 if phase >= 2 else SHOOT_SPEED_P1
	var dir := (player.global_position - global_position).normalized()
	_spawn_projectile(global_position, dir * spd, SHOOT_DAMAGE, "intro_boss", Color(0.7, 0.1, 0.2))
	_is_attacking = false

func _do_burst() -> void:
	if player == null:
		return
	_is_attacking = true
	_is_shooting = true
	_shoot_anim_timer = float(_SHOOT_FRAMES) / _SHOOT_FPS
	velocity.x = 0.0
	var count  : int   = BURST_COUNT_P2  if phase >= 2 else BURST_COUNT_P1
	var spread : float = deg_to_rad(BURST_SPREAD_P2 if phase >= 2 else BURST_SPREAD_P1)
	var spd    : float = BURST_SPEED_P2  if phase >= 2 else BURST_SPEED_P1
	var base_dir := (player.global_position - global_position).normalized()
	var step := spread / float(count - 1) if count > 1 else 0.0
	for i in count:
		var angle := -spread * 0.5 + step * float(i)
		var dir   := base_dir.rotated(angle)
		_spawn_projectile(global_position, dir * spd, BURST_DAMAGE, "intro_boss", Color(0.5, 0.1, 0.8))
	_is_attacking = false

func _enter_phase_2() -> void:
	_phase2_rage    = true
	_hit_flash_timer = RAGE_FLASH_DURATION
	_is_attacking   = true   # pauses attack timer during rage flash
	_resume_after_rage()

func _resume_after_rage() -> void:
	await get_tree().create_timer(RAGE_FLASH_DURATION).timeout
	_is_attacking = false

func _update_animation(delta: float) -> void:
	if velocity.x > 0.0:
		_facing = 1.0
	elif velocity.x < 0.0:
		_facing = -1.0
	_sprite.flip_h = _facing > 0.0

	# Priority: hit flash > invincibility flicker > phase 2 rage tint > normal
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var alpha: float = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	elif _phase2_rage:
		_sprite.modulate = Color(1.3, 0.6, 1.3, 1.0)
	else:
		_sprite.modulate = Color.WHITE

	var tex    : Texture2D
	var frames : int
	var fps    : float
	if _is_shooting:
		tex = _TEX_SHOOT; frames = _SHOOT_FRAMES; fps = _SHOOT_FPS
	elif _is_dashing:
		tex = _TEX_DASH;  frames = _DASH_FRAMES;  fps = _DASH_FPS
	elif absf(velocity.x) > 10.0:
		tex = _TEX_WALK;  frames = _WALK_FRAMES;  fps = _WALK_FPS
	else:
		tex = _TEX_IDLE;  frames = _IDLE_FRAMES;  fps = _IDLE_FPS

	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = frames
		_anim_frame     = 0
		_anim_timer     = 0.0

	# Dash: freeze on last frame during the lunge
	if _is_dashing:
		_sprite.frame = _DASH_FRAMES - 1
		return

	_anim_timer += delta
	if _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		_anim_frame = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame
