extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyMirrorMoth

# Mariposa-espelho: hover puro + arremesso de prism_shard.
const _PROJ := preload("res://characters/enemies/stage_07/light_projectile.tscn")
const SHOOT_INTERVAL := 1.5
const SHOOT_RANGE := 380.0
const SHARD_SPEED := 280.0
const SHARD_DAMAGE := 5

var _shoot_timer := 0.5

func _ready() -> void:
	super._ready()
	max_hp = 6
	contact_damage = 6
	current_hp = max_hp
	dive_speed = 0.0
	detect_radius = 0.0
	patrol_range = 90.0
	bob_amplitude = 12.0
	bob_speed = 3.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p != null and global_position.distance_to(p.global_position) <= SHOOT_RANGE:
			_shoot_timer = SHOOT_INTERVAL
			_fire_shard(p)

func _fire_shard(target: Node2D) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var proj := _PROJ.instantiate() as LightProjectile
	proj.setup(dir * SHARD_SPEED, SHARD_DAMAGE, "mirror_moth", 0.0, "prism_shard")
	get_parent().add_child(proj)
	proj.global_position = global_position
