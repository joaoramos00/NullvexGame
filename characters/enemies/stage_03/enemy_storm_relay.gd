extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyStormRelay

# Relé de tempestade: hover sem mergulho; periodicamente descarrega DOIS arcos
# horizontais (esquerda e direita) — nega o corredor aéreo em volta dele.
const _PROJ := preload("res://characters/enemies/stage_03/arc_projectile.tscn")
const INTERVAL := 2.8
const RANGE := 560.0
const BOLT_SPEED := 280.0
const BOLT_DAMAGE := 6

var _shoot_timer := 1.4

func _ready() -> void:
	super._ready()
	max_hp = 10
	contact_damage = 6
	current_hp = max_hp
	dive_speed = 0.0
	detect_radius = 0.0
	patrol_range = 100.0
	bob_amplitude = 14.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p != null and global_position.distance_to(p.global_position) <= RANGE:
			_shoot_timer = INTERVAL
			_fire(1.0)
			_fire(-1.0)

func _fire(dir: float) -> void:
	var proj = _PROJ.instantiate()
	proj.setup(Vector2(dir * BOLT_SPEED, 0.0), BOLT_DAMAGE, "storm_relay")
	get_parent().add_child(proj)
	var ov := HitboxData.proj_offset(_hitbox_id(), dir)
	var off := ov if ov != Vector2.INF else Vector2(dir * 30.0, 0.0)
	proj.global_position = global_position + off
