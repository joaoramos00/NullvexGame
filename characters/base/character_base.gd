extends CharacterBody2D
class_name CharacterBase

signal died
signal damaged(amount: int)
signal hp_changed(current: int, maximum: int)

const GRAVITY := 980.0
const SPEED := 200.0
const JUMP_VELOCITY := -480.0
const DASH_SPEED := 720.0
const KILL_Y := 1500.0  # default; stages override via `kill_y` (see stage_scene._apply_kill_plane)
const DASH_DURATION := 0.22
const DASH_COOLDOWN := 0.4
const DOUBLE_TAP_WINDOW := 0.25
const COYOTE_TIME := 0.12
const INVINCIBILITY_DURATION := 1.5
const AIR_WALK_DURATION := 0.3
const WALL_SLIDE_SPEED := 60.0
const WALL_JUMP_H := 280.0
const WALL_JUMP_V := -480.0
const WALL_CLING_TIME := 0.18
const JUMP_BUFFER_TIME := 0.10
const WALL_JUMP_DIAGONAL_V := -560.0
const WALL_JUMP_DIAGONAL_H := 140.0

@export var max_hp: int = 100
var current_hp: int = 100
var is_dead: bool = false
var is_invincible: bool = false
var active_ability: String = ""
var facing_right: bool = true
var gravity_scale: float = 1.0
var kill_y: float = KILL_Y  # world-space Y below which the player dies; set per-stage

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _coyote_timer: float = 0.0
var _invincibility_timer: float = 0.0
var _air_walk_timer: float = 0.0
var _dash_direction: float = 1.0
var _double_tap_timer: float = 0.0
var _double_tap_dir: float = 0.0
var _is_wall_sliding := false
var _wall_normal := Vector2.ZERO
var _wall_cling_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _wall_dash_available: bool = false
var _was_wall_sliding: bool = false
var door_walk_speed: float = 0.0
var door_locked: bool = false

func _ready() -> void:
	max_hp = GameManager.max_hp
	current_hp = max_hp
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if global_position.y > kill_y:
		_die()
		return
	_tick_timers(delta)
	_update_wall_slide()
	_apply_gravity(delta)
	_handle_dash(delta)
	_handle_movement()
	_handle_jump()
	move_and_slide()
	_update_facing()

func _tick_timers(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			is_invincible = false
	if is_invincible:
		modulate.a = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	else:
		modulate.a = 1.0
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta
	if _air_walk_timer > 0.0:
		_air_walk_timer -= delta
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta
	if _wall_cling_timer > 0.0:
		_wall_cling_timer -= delta
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	elif _coyote_timer > 0.0:
		_coyote_timer -= delta

func _update_wall_slide() -> void:
	_was_wall_sliding = _is_wall_sliding
	if _is_dashing or is_on_floor():
		_is_wall_sliding = false
		_wall_cling_timer = 0.0
		return
	var dir := Input.get_axis("move_left", "move_right")
	if is_on_wall() and dir != 0.0 and velocity.y >= 0.0:
		if _touching_no_grab_wall():
			_is_wall_sliding = false
			_wall_cling_timer = 0.0
			return
		if not _was_wall_sliding:
			_wall_cling_timer = WALL_CLING_TIME
			_wall_dash_available = true
			_on_wall_grabbed()
		_is_wall_sliding = true
		_wall_normal = get_wall_normal()
	else:
		_is_wall_sliding = false

func _touching_no_grab_wall() -> bool:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var n := col.get_normal()
		var collider := col.get_collider()
		if abs(n.x) > abs(n.y) and is_instance_valid(collider) and collider.is_in_group("no_wall_grab"):
			return true
	return false

func _apply_gravity(delta: float) -> void:
	if _is_dashing:
		return
	if _air_walk_timer > 0.0:
		velocity.y = 0.0
		return
	if not is_on_floor():
		if _wall_cling_timer > 0.0:
			velocity.y = 0.0
			return
		velocity.y += GRAVITY * gravity_scale * delta
		if _is_wall_sliding and velocity.y > WALL_SLIDE_SPEED:
			velocity.y = WALL_SLIDE_SPEED

func _handle_movement() -> void:
	if door_locked:
		_is_dashing = false
		velocity.x = 0.0
		return
	if _is_dashing:
		velocity.x = DASH_SPEED * _dash_direction
		return
	if door_walk_speed != 0.0:
		velocity.x = door_walk_speed
		return
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

func _apply_wall_jump(diagonal: bool = false) -> void:
	if diagonal:
		velocity.x = _wall_normal.x * WALL_JUMP_DIAGONAL_H
		velocity.y = WALL_JUMP_DIAGONAL_V
	else:
		velocity.x = _wall_normal.x * WALL_JUMP_H
		velocity.y = WALL_JUMP_V
	_is_wall_sliding = false
	_wall_cling_timer = 0.0
	_jump_buffer_timer = 0.0
	_double_tap_timer = 0.0
	_double_tap_dir = 0.0
	_on_wall_jumped()

func _handle_jump() -> void:
	if _is_dashing or door_walk_speed != 0.0 or door_locked:
		return
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	if _jump_buffer_timer <= 0.0:
		return
	if _is_wall_sliding:
		var dir := Input.get_axis("move_left", "move_right")
		# pressing into the wall → diagonal climb; pressing away → horizontal kick
		var pressing_into_wall := (dir * _wall_normal.x) < 0.0
		_apply_wall_jump(pressing_into_wall)
		return
	if is_on_floor() or _coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		AudioManager.play_sfx(AudioLibrary.sfx_jump)

func _handle_dash(delta: float) -> void:
	if door_walk_speed != 0.0 or door_locked:
		return
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
		return
	if _double_tap_timer > 0.0:
		_double_tap_timer -= delta
	var on_ground := is_on_floor() or _coyote_timer > 0.0
	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0:
		if on_ground:
			_start_dash()
			return
		if _is_wall_sliding and _wall_dash_available:
			_wall_dash_available = false
			_is_wall_sliding = false
			_start_dash(_wall_normal.x)
			return
	if _dash_cooldown_timer <= 0.0 and on_ground:
		for dir in [[1.0, "move_right"], [-1.0, "move_left"]]:
			if Input.is_action_just_pressed(dir[1]):
				if _double_tap_dir == dir[0] and _double_tap_timer > 0.0:
					_double_tap_timer = 0.0
					_double_tap_dir = 0.0
					_start_dash(dir[0])
				else:
					_double_tap_dir = dir[0]
					_double_tap_timer = DOUBLE_TAP_WINDOW

func _start_dash(dir: float = 0.0) -> void:
	_is_dashing = true
	_dash_timer = DASH_DURATION
	_dash_cooldown_timer = DASH_COOLDOWN
	_dash_direction = dir if dir != 0.0 else (1.0 if facing_right else -1.0)
	velocity.y = 0.0

func _update_facing() -> void:
	if velocity.x > 0.0:
		facing_right = true
	elif velocity.x < 0.0:
		facing_right = false

func _on_wall_grabbed() -> void:
	pass

func _on_wall_jumped() -> void:
	AudioManager.play_sfx(AudioLibrary.sfx_jump)

func take_damage(amount: int, _source_id: String = "") -> void:
	if is_invincible or is_dead:
		return
	current_hp = max(0, current_hp - amount)
	is_invincible = true
	_invincibility_timer = INVINCIBILITY_DURATION
	AudioManager.play_sfx(AudioLibrary.sfx_player_damage)
	damaged.emit(amount)
	hp_changed.emit(current_hp, max_hp)
	if current_hp == 0:
		_die()

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	AudioManager.play_sfx(AudioLibrary.sfx_player_death)
	_play_death_animation()

func _play_death_animation() -> void:
	died.emit()

func respawn(position: Vector2) -> void:
	global_position = position
	current_hp = GameManager.max_hp
	is_dead = false
	is_invincible = false
	_invincibility_timer = 0.0
	velocity = Vector2.ZERO
	hp_changed.emit(current_hp, max_hp)

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)

func activate_air_walk() -> void:
	_air_walk_timer = AIR_WALK_DURATION
