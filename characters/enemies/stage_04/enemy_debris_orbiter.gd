extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyDebrisOrbiter

# Orbitador de arco (molde do EnemyEmberOrbiter): hover puro + arco mirado.
const _PROJ := preload("res://characters/enemies/stage_04/grav_projectile.tscn")
const SHOOT_INTERVAL := 1.8
const SHOOT_RANGE := 460.0
const BOLT_SPEED := 320.0
const BOLT_DAMAGE := 6

var _shoot_timer := 0.8

func _ready() -> void:
	super._ready()
	max_hp = 8
	contact_damage = 6
	current_hp = max_hp
	dive_speed = 0.0
	detect_radius = 0.0
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
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var proj = _PROJ.instantiate()
	proj.setup(dir * BOLT_SPEED, BOLT_DAMAGE, "debris_orbiter", 0.0, "orbit_shard")
	get_parent().add_child(proj)
	var ov := HitboxData.proj_offset(_hitbox_id(), 1.0)
	var off := ov if ov != Vector2.INF else Vector2(0.0, 0.0)
	proj.global_position = global_position + off
