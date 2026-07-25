extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyShadowSnare

# Armadilha suspensa: flutua e avança devagar até o player quando detecta —
# contato pesado, HP alto.
func _ready() -> void:
	super._ready()
	max_hp = 3
	contact_damage = 2
	current_hp = max_hp
	detect_radius = 320.0
	dive_speed = 130.0
	retreat_speed = 70.0
	patrol_range = 70.0
	bob_amplitude = 14.0
