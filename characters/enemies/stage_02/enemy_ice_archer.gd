extends EnemyBase
class_name EnemyIceArcher

const _PROJECTILE_SCENE := preload("res://characters/enemies/stage_02/enemy_ice_projectile.tscn")

@export var shoot_range: float = 520.0
@export var shoot_interval: float = 1.45
@export var projectile_speed: float = 330.0
@export var projectile_damage: int = 7
@export var aim_y_tolerance: float = 150.0

var _shoot_timer := 0.35

func _init() -> void:
	max_hp = 12
	contact_damage = 7

func _ready() -> void:
	max_hp = 12
	contact_damage = 7
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor() and not _has_floor_ahead():
		_direction = -_direction
	velocity.x = PATROL_SPEED * 0.55 * _direction
	_shoot_timer -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var offset := player.global_position - global_position
		if absf(offset.x) <= shoot_range and absf(offset.y) <= aim_y_tolerance:
			_direction = signf(offset.x) if offset.x != 0.0 else _direction
			velocity.x = 0.0
			if _shoot_timer <= 0.0:
				_fire(Vector2(_direction * projectile_speed, 0.0), "ice_archer")
				_shoot_timer = shoot_interval
	move_and_slide()
	if is_on_wall():
		_direction = -_direction
	_animate_sprite_motion(delta, 2.5, 9.0, 1.5, 1.0)
	_update_sprite()

func _fire(shot_velocity: Vector2, source: String) -> void:
	var projectile := _PROJECTILE_SCENE.instantiate() as EnemyIceProjectile
	projectile.setup(shot_velocity, projectile_damage, source)
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
