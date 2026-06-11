extends EnemyBase
class_name EnemyFrostTurret

const _PROJECTILE_SCENE := preload("res://characters/enemies/stage_02/enemy_ice_projectile.tscn")

@export var shoot_range: float = 620.0
@export var shoot_interval: float = 1.35
@export var projectile_speed: float = 280.0
@export var projectile_damage: int = 6

var _shoot_timer := 0.2

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
	if player != null and global_position.distance_to(player.global_position) <= shoot_range:
		var dir := (player.global_position - global_position).normalized()
		_direction = signf(dir.x) if dir.x != 0.0 else _direction
		if _shoot_timer <= 0.0:
			_fire(dir * projectile_speed)
			_shoot_timer = shoot_interval
	_animate_sprite_motion(delta, 1.5, 7.5, 1.0, 0.6)
	_update_sprite()

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
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if _invincible and int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
