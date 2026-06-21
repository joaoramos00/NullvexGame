extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyCinderFlyer

# Patrulha aérea de assédio: hover/dive do EnemyFlyer + tiro leve ocasional (fire_bolt).
const _PROJ := preload("res://characters/enemies/stage_01/fire_projectile.tscn")
const SHOOT_INTERVAL := 2.4
const SHOOT_RANGE := 520.0
const BOLT_SPEED := 260.0
const BOLT_DAMAGE := 4

var _shoot_timer := 1.2

func _ready() -> void:
	super._ready()
	max_hp = 8
	contact_damage = 7
	current_hp = max_hp
	detect_radius = 220.0
	dive_speed = 300.0
	retreat_speed = 160.0
	patrol_range = 220.0
	bob_amplitude = 10.0

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
	var proj = _PROJ.instantiate()
	proj.setup(dir * BOLT_SPEED, BOLT_DAMAGE, "cinder_flyer", 0.0, "fire_bolt")
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(10.0, -10.0)
