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

const DASH_SPEED       := 320.0
const DASH_DURATION    := 0.45
const SHOOT_COOLDOWN   := 2.2
const PROJECTILE_SPEED := 260.0

var _attack_phase     : int   = 0
var _is_dashing       : bool  = false
var _dash_timer       : float = 0.0
var _is_shooting      : bool  = false
var _shoot_anim_timer : float = 0.0
var _anim_frame       : int   = 0
var _anim_timer       : float = 0.0
var _facing           : float = -1.0  # -1 = left (west, default); 1 = right (flip_h)

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	stage_id           = 0
	ability_id         = ""
	max_hp             = 28
	boss_color         = Color(0.5, 0.0, 0.1, 1)
	attack_interval_p1 = SHOOT_COOLDOWN
	attack_interval_p2 = SHOOT_COOLDOWN * 0.7
	super()

func _draw() -> void:
	pass  # suppress BossBase color-rectangle placeholder

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
			if absf(dx) > 80.0:
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
	_is_shooting = true
	_shoot_anim_timer = float(_SHOOT_FRAMES) / _SHOOT_FPS
	velocity.x = 0.0
	var dir := (player.global_position - global_position).normalized()
	_spawn_projectile(global_position, dir * PROJECTILE_SPEED, 8, "intro_boss", Color(0.7, 0.1, 0.2))
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.2

func _update_animation(delta: float) -> void:
	if velocity.x > 0.0:
		_facing = 1.0
	elif velocity.x < 0.0:
		_facing = -1.0
	_sprite.flip_h = _facing > 0.0

	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var alpha: float = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	else:
		_sprite.modulate = Color.WHITE

	var tex: Texture2D
	var frames: int
	var fps: float
	if _is_shooting:
		tex = _TEX_SHOOT
		frames = _SHOOT_FRAMES
		fps = _SHOOT_FPS
	elif _is_dashing:
		tex = _TEX_DASH
		frames = _DASH_FRAMES
		fps = _DASH_FPS
	elif absf(velocity.x) > 10.0:
		tex = _TEX_WALK
		frames = _WALK_FRAMES
		fps = _WALK_FPS
	else:
		tex = _TEX_IDLE
		frames = _IDLE_FRAMES
		fps = _IDLE_FPS

	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = frames
		_anim_frame = 0
		_anim_timer = 0.0

	if _is_dashing:
		_sprite.frame = _DASH_FRAMES - 1
		return

	_anim_timer += delta
	if _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		_anim_frame = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame
