extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyTurbineWisp

# Núcleo de vento flutuante: hover puro (sem mergulho) + tiro de gale_bolt.
const _PROJ := preload("res://characters/enemies/stage_05/wind_projectile.tscn")
const SHOOT_INTERVAL := 1.7
const SHOOT_RANGE := 420.0
const BOLT_SPEED := 300.0
const BOLT_DAMAGE := 6

var _shoot_timer := 0.7

func _ready() -> void:
	super._ready()
	max_hp = 2
	contact_damage = 1
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
	var proj := _PROJ.instantiate() as WindProjectile
	proj.setup(dir * BOLT_SPEED, BOLT_DAMAGE, "turbine_wisp", 0.0, "gale_bolt")
	get_parent().add_child(proj)
	proj.global_position = global_position
