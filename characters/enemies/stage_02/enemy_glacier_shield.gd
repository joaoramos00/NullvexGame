extends EnemyBase
class_name EnemyGlacierShield

const _PROJECTILE_SCENE := preload("res://characters/enemies/stage_02/enemy_ice_projectile.tscn")

@export var shielded_patrol_speed: float = 48.0
@export var front_damage_multiplier: float = 0.25
@export var guard_frame_count: int = 4
@export var guard_fps: float = 6.0
@export var shoot_range: float = 560.0
@export var shoot_interval: float = 1.6
@export var projectile_speed: float = 260.0
@export var projectile_damage: int = 8
@export var shot_release_frame: int = 2

var _shoot_timer := 0.3
var _shot_active := false
var _shot_frame := 0
var _shot_frame_timer := 0.0
var _shot_released := false

@onready var _shield_barrier := get_node_or_null("ShieldBarrier") as Area2D

func _init() -> void:
	max_hp = 18
	contact_damage = 10

func _ready() -> void:
	max_hp = 18
	contact_damage = 10
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
	velocity.x = 0.0
	_shoot_timer -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not _shot_active and player != null and global_position.distance_to(player.global_position) <= shoot_range:
		if _shoot_timer <= 0.0:
			_start_shot()
	_tick_shot(delta)
	move_and_slide()
	if not _shot_active:
		_advance_sprite_frame_loop(delta, guard_frame_count, guard_fps)
	_sprite.modulate.a = 0.35 if _invincible and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0

func _start_shot() -> void:
	_shot_active = true
	_shot_frame = 0
	_shot_frame_timer = 0.0
	_shot_released = false
	_set_shield_barrier_lowered(false)
	_set_sprite_frame(0)

func _tick_shot(delta: float) -> void:
	if not _shot_active:
		return
	velocity.x = 0.0
	_shot_frame_timer += delta
	var frame_duration: float = 1.0 / guard_fps
	while _shot_frame_timer >= frame_duration:
		_shot_frame_timer -= frame_duration
		_shot_frame += 1
		if _shot_frame == shot_release_frame and not _shot_released:
			_set_sprite_frame(_shot_frame)
			_set_shield_barrier_lowered(true)
			_fire()
			_shot_released = true
		if _shot_frame >= guard_frame_count:
			_shot_active = false
			_shoot_timer = shoot_interval
			_shot_frame = 0
			_set_shield_barrier_lowered(false)
		_set_sprite_frame(_shot_frame % guard_frame_count)

func _set_shield_barrier_lowered(lowered: bool) -> void:
	if not is_instance_valid(_shield_barrier):
		return
	_shield_barrier.position = Vector2(38.0, -40.0 if lowered else -56.0)

func _fire() -> void:
	var projectile := _PROJECTILE_SCENE.instantiate() as EnemyIceProjectile
	projectile.setup(Vector2(_direction * projectile_speed, 0.0), projectile_damage, "glacier_shield")
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(_direction * 34.0, -18.0)

func take_damage(amount: int, source: String = "") -> void:
	var actual_amount := amount
	if source == "front" or source == "shield_front":
		actual_amount = max(1, int(ceil(amount * front_damage_multiplier)))
	super.take_damage(actual_amount, source)
