extends EnemyBase
class_name EnemyIceWisp

const _PROJECTILE_SCENE := preload("res://characters/enemies/stage_02/enemy_ice_projectile.tscn")

@export var hover_amplitude: float = 24.0
@export var hover_speed: float = 2.6
@export var patrol_range: float = 180.0
@export var shoot_range: float = 520.0
@export var shoot_interval: float = 1.8
@export var burst_count: int = 3
@export var projectile_speed: float = 240.0
@export var projectile_damage: int = 5

var _spawn_position := Vector2.ZERO
var _hover_time := 0.0
var _shoot_timer := 0.45

func _init() -> void:
	max_hp = 1
	contact_damage = 1

func _ready() -> void:
	max_hp = 1
	contact_damage = 1
	super._ready()
	_spawn_position = global_position

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	_hover_time += delta
	if absf(global_position.x - _spawn_position.x) >= patrol_range:
		_direction = -_direction
	velocity.x = PATROL_SPEED * 0.6 * _direction
	velocity.y = sin(_hover_time * hover_speed) * hover_amplitude
	_shoot_timer -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and global_position.distance_to(player.global_position) <= shoot_range:
		var dir := (player.global_position - global_position).normalized()
		_direction = signf(dir.x) if dir.x != 0.0 else _direction
		if _shoot_timer <= 0.0:
			_fire_burst(dir)
			_shoot_timer = shoot_interval
	move_and_slide()
	if is_on_wall():
		_direction = -_direction
	_advance_sprite_frame_loop(delta, 4, 8.0)
	_update_sprite()

func _fire_burst(dir: Vector2) -> void:
	for i in burst_count:
		var angle_offset := deg_to_rad((float(i) - float(burst_count - 1) * 0.5) * 12.0)
		var shot_dir := dir.rotated(angle_offset).normalized()
		var projectile := _PROJECTILE_SCENE.instantiate() as EnemyIceProjectile
		projectile.setup(shot_dir * projectile_speed, projectile_damage, "ice_wisp")
		get_parent().add_child(projectile)
		projectile.global_position = global_position + shot_dir * 24.0

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false

func _update_sprite() -> void:
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if _invincible and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
