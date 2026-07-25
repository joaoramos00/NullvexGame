extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyOrbitMauler

# Espancador orbital: mergulho rápido e agressivo, sem tiro.
func _ready() -> void:
	super._ready()
	max_hp = 3
	contact_damage = 2
	current_hp = max_hp
	detect_radius = 280.0
	dive_speed = 400.0
	retreat_speed = 180.0
	patrol_range = 180.0
	bob_amplitude = 8.0
