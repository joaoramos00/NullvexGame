extends EnemyBase
class_name EnemyCryoBomber

const _PROJECTILE_SCENE := preload("res://characters/enemies/stage_02/enemy_ice_projectile.tscn")

@export var shoot_range: float = 520.0
@export var shoot_interval: float = 1.9
@export var lob_velocity: Vector2 = Vector2(220.0, -360.0)
@export var projectile_gravity: float = 720.0
@export var projectile_damage: int = 9
@export var shot_frame_count: int = 6
@export var shot_fps: float = 9.0
@export var shot_release_frame: int = 3

var _shoot_timer := 0.65
var _shot_active := false
var _shot_frame := 0
var _shot_frame_timer := 0.0
var _shot_released := false

func _init() -> void:
	max_hp = 16
	contact_damage = 9

func _ready() -> void:
	max_hp = 16
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
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not _shot_active and player != null:
		var offset := player.global_position - global_position
		if absf(offset.x) <= shoot_range:
			_direction = signf(offset.x) if offset.x != 0.0 else _direction
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
			_lob()
			_shot_released = true
		if _shot_frame >= shot_frame_count:
			_shot_active = false
			_shoot_timer = shoot_interval
			_shot_frame = 0
		_set_sprite_frame(_shot_frame % shot_frame_count)

func _lob() -> void:
	var projectile := _PROJECTILE_SCENE.instantiate() as EnemyIceProjectile
	projectile.setup(Vector2(_direction * lob_velocity.x, lob_velocity.y), projectile_damage, "cryo_bomber", projectile_gravity)
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(_direction * 16.0, -56.0)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false

func _update_sprite() -> void:
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if _invincible and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
