# characters/enemies/enemy_miniboss.gd
extends EnemyBase
class_name EnemyMiniBoss

const _SHOCKWAVE_SCENE := preload("res://effects/shockwave_effect.tscn")

enum State { PATROL, CHARGE, STOMP, RECOVER }

const MINI_PATROL_SPEED := 50.0
const CHARGE_SPEED      := 220.0
const CHARGE_DURATION   := 0.5
const CHARGE_DIST       := 300.0
const STOMP_IMPULSE     := -400.0
const RECOVER_TIME      := 0.6
const STOMP_COOLDOWN    := 4.0
const FEET_OFFSET_Y     := 60.0

var _state        : State = State.PATROL
var _state_timer  : float = 0.0
var _stomp_cd     : float = 0.0
var _was_airborne : bool  = false

func _ready() -> void:
	max_hp         = 18
	contact_damage = 3
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_stomp_cd = max(0.0, _stomp_cd - delta)

	match _state:
		State.PATROL:  _tick_patrol(delta)
		State.CHARGE:  _tick_charge(delta)
		State.STOMP:   _tick_stomp()
		State.RECOVER: _tick_recover(delta)

	move_and_slide()

	if _was_airborne and is_on_floor() and _state == State.STOMP:
		_on_stomp_land()
	_was_airborne = not is_on_floor()

	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0.0
	if _invincible:
		_sprite.modulate.a = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _tick_patrol(delta: float) -> void:
	var player := _get_player()
	if player == null:
		velocity.x = MINI_PATROL_SPEED * _direction
		return
	var dx: float = player.global_position.x - global_position.x
	_direction = sign(dx) if dx != 0.0 else _direction
	velocity.x = MINI_PATROL_SPEED * _direction
	if abs(dx) <= CHARGE_DIST:
		_state_timer = CHARGE_DURATION
		_state       = State.CHARGE
	elif _stomp_cd <= 0.0:
		velocity.y = STOMP_IMPULSE
		_state      = State.STOMP

func _tick_charge(delta: float) -> void:
	_state_timer -= delta
	velocity.x = CHARGE_SPEED * _direction
	if _state_timer <= 0.0:
		velocity.x = 0.0
		velocity.y = STOMP_IMPULSE
		_state      = State.STOMP

func _tick_stomp() -> void:
	pass

func _on_stomp_land() -> void:
	_stomp_cd    = STOMP_COOLDOWN
	velocity     = Vector2.ZERO
	_state_timer = RECOVER_TIME
	_state       = State.RECOVER
	var sw := _SHOCKWAVE_SCENE.instantiate() as Node2D
	sw.global_position = Vector2(global_position.x, global_position.y + FEET_OFFSET_Y)
	get_parent().add_child(sw)

func _tick_recover(delta: float) -> void:
	velocity.x   = 0.0
	_state_timer -= delta
	if _state_timer <= 0.0:
		_state = State.PATROL
