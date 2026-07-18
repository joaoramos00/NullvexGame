extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyOreOrbiter

# Orbitador de minério suspenso: flutua e avança devagar até o player quando
# detecta — contato pesado, HP alto (arquétipo "elite").
func _ready() -> void:
	super._ready()
	max_hp = 12
	contact_damage = 8
	current_hp = max_hp
	detect_radius = 320.0
	dive_speed = 130.0
	retreat_speed = 70.0
	patrol_range = 70.0
	bob_amplitude = 14.0
