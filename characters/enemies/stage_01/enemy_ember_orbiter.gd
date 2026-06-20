extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyEmberOrbiter

const FIRE_PROJECTILE_PATH := "res://characters/enemies/stage_01/fire_projectile.tscn"
const SHOOT_INTERVAL := 1.6
const SHOOT_RANGE := 480.0
const BOLT_SPEED := 320.0
const BOLT_DAMAGE := 6

var _shoot_timer := 0.8

func _ready() -> void:
	super._ready()
	max_hp = 8
	contact_damage = 6
	current_hp = max_hp
	dive_speed = 0.0          # orbiter não mergulha; fica em hover
	detect_radius = 0.0       # nunca entra em WINDUP/DIVE
	patrol_range = 120.0

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
	if not ResourceLoader.exists(FIRE_PROJECTILE_PATH):
		return
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var proj = load(FIRE_PROJECTILE_PATH).instantiate()
	proj.setup(dir * BOLT_SPEED, BOLT_DAMAGE, "ember_orbiter", 0.0, "fire_bolt")
	get_parent().add_child(proj)
	proj.global_position = global_position
