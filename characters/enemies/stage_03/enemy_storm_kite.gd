extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyStormKite

# Pipa de tempestade (molde do EnemyCinderFlyer): hover/dive + arco ocasional.
const _PROJ := preload("res://characters/enemies/stage_03/arc_projectile.tscn")
const SHOOT_INTERVAL := 2.6
const SHOOT_RANGE := 500.0
const BOLT_SPEED := 260.0
const BOLT_DAMAGE := 5

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
	bob_amplitude = 12.0

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
	proj.setup(dir * BOLT_SPEED, BOLT_DAMAGE, "storm_kite")
	get_parent().add_child(proj)
	var ov := HitboxData.proj_offset(_hitbox_id(), 1.0)
	var off := ov if ov != Vector2.INF else Vector2(0.0, 30.0)
	proj.global_position = global_position + off
