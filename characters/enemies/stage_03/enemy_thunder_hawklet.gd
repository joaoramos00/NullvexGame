extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyThunderHawklet

# Gavião-trovão: mergulhador agressivo, sem tiro — pressão por contato.
func _ready() -> void:
	super._ready()
	max_hp = 1
	contact_damage = 1
	current_hp = max_hp
	detect_radius = 250.0
	dive_speed = 360.0
	retreat_speed = 180.0
	patrol_range = 180.0
	bob_amplitude = 8.0
