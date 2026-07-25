extends EnemyBase
class_name EnemyIceArcher

const _PROJECTILE_SCENE := preload("res://characters/enemies/stage_02/enemy_ice_projectile.tscn")

@export var shoot_range: float = 520.0
@export var shoot_interval: float = 1.45
@export var projectile_speed: float = 330.0
@export var projectile_damage: int = 7
@export var aim_y_tolerance: float = 150.0
@export var shot_frame_count: int = 6
@export var shot_fps: float = 10.0
@export var shot_release_frame: int = 4

var _shoot_timer := 0.35
var _shot_active := false
var _shot_frame := 0
var _shot_frame_timer := 0.0
var _shot_released := false

func _init() -> void:
	max_hp = 2
	contact_damage = 1

func _ready() -> void:
	max_hp = 2
	contact_damage = 1
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	_shoot_timer -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not _shot_active and player != null:
		var offset := player.global_position - global_position
		if absf(offset.x) <= shoot_range and absf(offset.y) <= aim_y_tolerance:
			_direction = signf(offset.x) if offset.x != 0.0 else _direction
			velocity.x = 0.0
			if _shoot_timer <= 0.0:
				_start_shot()
	_tick_shot(delta)
	move_and_slide()
	_update_sprite()

func _start_shot() -> void:
	_shot_active = true
	_shot_frame = 0
	_shot_frame_timer = 0.0
	_shot_released = false
	_set_sprite_frame(0)

func _tick_shot(delta: float) -> void:
	if not _shot_active:
		return
	velocity.x = 0.0
	_shot_frame_timer += delta
	var frame_duration: float = 1.0 / shot_fps
	while _shot_frame_timer >= frame_duration:
		_shot_frame_timer -= frame_duration
		_shot_frame += 1
		if _shot_frame == shot_release_frame and not _shot_released:
			_set_sprite_frame(_shot_frame)
			_fire(Vector2(_direction * projectile_speed, 0.0), "ice_archer")
			_shot_released = true
		if _shot_frame >= shot_frame_count:
			_shot_active = false
			_shoot_timer = shoot_interval
			_shot_frame = 0
		_set_sprite_frame(_shot_frame % shot_frame_count)

func _fire(shot_velocity: Vector2, source: String) -> void:
	var projectile := _PROJECTILE_SCENE.instantiate() as EnemyIceProjectile
	projectile.setup(shot_velocity, projectile_damage, source, 0.0, "ice_arrow")
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(_direction * 36.0, -18.0)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false

func _update_sprite() -> void:
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if _invincible and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
