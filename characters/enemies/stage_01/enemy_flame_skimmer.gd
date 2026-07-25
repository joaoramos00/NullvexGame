extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyFlameSkimmer

func _ready() -> void:
	super._ready()
	max_hp = 2
	contact_damage = 1
	current_hp = max_hp
	dive_speed = 340.0
	retreat_speed = 170.0
	detect_radius = 260.0
	patrol_range = 180.0
