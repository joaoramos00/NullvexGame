extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyPrismOrbiter

# Núcleo prismático flutuante: hover puro (sem mergulho) + tiro de light_bolt.
const _PROJ := preload("res://characters/enemies/stage_07/light_projectile.tscn")
const SHOOT_INTERVAL := 1.6
const SHOOT_RANGE := 420.0
const BOLT_SPEED := 310.0
const BOLT_DAMAGE := 6

var _shoot_timer := 0.6

func _ready() -> void:
	super._ready()
	max_hp = 7
	contact_damage = 5
	current_hp = max_hp
	dive_speed = 0.0
	detect_radius = 0.0
	patrol_range = 110.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p != null and global_position.distance_to(p.global_position) <= SHOOT_RANGE:
			_shoot_timer = SHOOT_INTERVAL
			_fire_bolt(p)

func _fire_bolt(target: Node2D) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var proj := _PROJ.instantiate() as LightProjectile
	proj.setup(dir * BOLT_SPEED, BOLT_DAMAGE, "prism_orbiter", 0.0, "light_bolt")
	get_parent().add_child(proj)
	proj.global_position = global_position
