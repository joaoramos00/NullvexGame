extends EnemyBase
class_name EnemyFrostTurret

const _PROJECTILE_SCENE := preload("res://characters/enemies/stage_02/enemy_ice_projectile.tscn")

@export var shoot_range: float = 620.0
@export var shoot_interval: float = 1.35
@export var projectile_speed: float = 280.0
@export var projectile_damage: int = 6
@export var shot_frame_count: int = 4
@export var shot_fps: float = 8.0
@export var shot_release_frame: int = 2

var _shoot_timer := 0.2
var _shot_active := false
var _shot_frame := 0
var _shot_frame_timer := 0.0
var _shot_released := false
var _queued_shot_velocity := Vector2.RIGHT

func _init() -> void:
	max_hp = 14
	contact_damage = 6

func _ready() -> void:
	max_hp = 14
	contact_damage = 6
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	velocity = Vector2.ZERO
	_shoot_timer -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not _shot_active and player != null and global_position.distance_to(player.global_position) <= shoot_range:
		var dir := (player.global_position - global_position).normalized()
		if _shoot_timer <= 0.0:
			_queued_shot_velocity = dir * projectile_speed
			_start_shot()
	_tick_shot(delta)
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
	velocity = Vector2.ZERO
	_shot_frame_timer += delta
	var frame_duration: float = 1.0 / shot_fps
	while _shot_frame_timer >= frame_duration:
		_shot_frame_timer -= frame_duration
		_shot_frame += 1
		if _shot_frame == shot_release_frame and not _shot_released:
			_set_sprite_frame(_shot_frame)
			_fire(_queued_shot_velocity)
			_shot_released = true
		if _shot_frame >= shot_frame_count:
			_shot_active = false
			_shoot_timer = shoot_interval
			_shot_frame = 0
		_set_sprite_frame(_shot_frame % shot_frame_count)

func _fire(shot_velocity: Vector2) -> void:
	var projectile := _PROJECTILE_SCENE.instantiate() as EnemyIceProjectile
	projectile.setup(shot_velocity, projectile_damage, "frost_turret")
	get_parent().add_child(projectile)
	projectile.global_position = global_position + shot_velocity.normalized() * 32.0

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false

func _update_sprite() -> void:
	_sprite.modulate.a = 0.35 if _invincible and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
