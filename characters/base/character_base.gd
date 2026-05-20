extends CharacterBody2D
class_name CharacterBase

signal died
signal damaged(amount: int)
signal hp_changed(current: int, maximum: int)

const GRAVITY := 980.0
const SPEED := 200.0
const JUMP_VELOCITY := -480.0
const DOUBLE_JUMP_VELOCITY := -420.0
const DASH_SPEED := 500.0
const DASH_DURATION := 0.18
const DASH_COOLDOWN := 0.4
const COYOTE_TIME := 0.12
const INVINCIBILITY_DURATION := 1.5
const AIR_WALK_DURATION := 0.3

@export var max_hp: int = 100
var current_hp: int = 100
var is_dead: bool = false
var is_invincible: bool = false
var active_ability: String = ""
var facing_right: bool = true
var gravity_scale: float = 1.0

var _can_double_jump: bool = false
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _coyote_timer: float = 0.0
var _invincibility_timer: float = 0.0
var _air_walk_timer: float = 0.0
var _dash_direction: float = 1.0

func _ready() -> void:
    max_hp = GameManager.max_hp
    current_hp = max_hp
    queue_redraw()

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    _tick_timers(delta)
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
    if is_on_floor():
        _coyote_timer = COYOTE_TIME
        _can_double_jump = true
    elif _coyote_timer > 0.0:
        _coyote_timer -= delta

func _apply_gravity(delta: float) -> void:
    if _is_dashing:
        return
    if _air_walk_timer > 0.0:
        velocity.y = 0.0
        return
    if not is_on_floor():
        velocity.y += GRAVITY * gravity_scale * delta

func _handle_movement() -> void:
    if _is_dashing:
        velocity.x = DASH_SPEED * _dash_direction
        return
    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0.0:
        velocity.x = direction * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0.0, SPEED)

func _handle_jump() -> void:
    if _is_dashing:
        return
    if Input.is_action_just_pressed("jump"):
        if is_on_floor() or _coyote_timer > 0.0:
            velocity.y = JUMP_VELOCITY
            _coyote_timer = 0.0
            AudioManager.play_sfx(AudioLibrary.sfx_jump)
        elif _can_double_jump:
            velocity.y = DOUBLE_JUMP_VELOCITY
            _can_double_jump = false
            AudioManager.play_sfx(AudioLibrary.sfx_jump)

func _handle_dash(delta: float) -> void:
    if _is_dashing:
        _dash_timer -= delta
        if _dash_timer <= 0.0:
            _is_dashing = false
        return
    if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0:
        _start_dash()

func _start_dash() -> void:
    _is_dashing = true
    _dash_timer = DASH_DURATION
    _dash_cooldown_timer = DASH_COOLDOWN
    _dash_direction = 1.0 if facing_right else -1.0
    velocity.y = 0.0

func _update_facing() -> void:
    if velocity.x > 0.0:
        facing_right = true
    elif velocity.x < 0.0:
        facing_right = false

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
    died.emit()

func respawn(position: Vector2) -> void:
    global_position = position
    current_hp = GameManager.max_hp
    is_dead = false
    is_invincible = false
    _invincibility_timer = 0.0
    velocity = Vector2.ZERO
    hp_changed.emit(current_hp, max_hp)

func activate_air_walk() -> void:
    _air_walk_timer = AIR_WALK_DURATION
