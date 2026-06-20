extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyCinderFlyer

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
