extends EnemyBase
class_name EnemyHeatMortar

const _PROJ := preload("res://characters/enemies/stage_01/fire_projectile.tscn")
const FRAMES := 6
const FPS := 10.0
const RELEASE_FRAME := 4
const SHOOT_RANGE := 620.0
const SHOOT_INTERVAL := 1.8
const SHELL_SPEED := 360.0
const SHELL_GRAVITY := 520.0
const SHELL_DAMAGE := 9

var _shoot_timer := 0.5
var _shot_active := false
var _shot_frame := 0
var _shot_frame_timer := 0.0
var _released := false

func _init() -> void:
	max_hp = 14
	contact_damage = 9

func _ready() -> void:
	max_hp = 14
	contact_damage = 9
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	_shoot_timer -= delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if not _shot_active and p != null:
		var off: Vector2 = p.global_position - global_position
		if absf(off.x) <= SHOOT_RANGE:
			_direction = signf(off.x) if off.x != 0.0 else _direction
			if _shoot_timer <= 0.0:
				_shot_active = true
				_shot_frame = 0
				_shot_frame_timer = 0.0
				_released = false
				_set_sprite_frame(0)
	_tick_shot(delta)
	move_and_slide()
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if (_invincible and int(Time.get_ticks_msec() / 80) % 2 == 0) else 1.0

func _tick_shot(delta: float) -> void:
	if not _shot_active:
		return
	_shot_frame_timer += delta
	var dur := 1.0 / FPS
	while _shot_frame_timer >= dur:
		_shot_frame_timer -= dur
		_shot_frame += 1
		if _shot_frame == RELEASE_FRAME and not _released:
			_fire()
			_released = true
		if _shot_frame >= FRAMES:
			_shot_active = false
			_shoot_timer = SHOOT_INTERVAL
			_shot_frame = 0
			_set_sprite_frame(0)
			break
		_set_sprite_frame(_shot_frame % FRAMES)

func _fire() -> void:
	var proj = _PROJ.instantiate()
	proj.setup(Vector2(_direction * SHELL_SPEED, -380.0), SHELL_DAMAGE, "heat_mortar", SHELL_GRAVITY, "heat_mortar_shell")
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(_direction * 20.0, -40.0)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
