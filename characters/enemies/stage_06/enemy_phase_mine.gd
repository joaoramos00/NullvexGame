extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyPhaseMine

# Mina quase-invisível: flutua parada, avança bem devagar até o player
# quando detecta — HP baixo, contato forte.
func _ready() -> void:
	super._ready()
	max_hp = 1
	contact_damage = 3
	current_hp = max_hp
	detect_radius = 340.0
	dive_speed = 150.0
	retreat_speed = 60.0
	patrol_range = 80.0
	bob_amplitude = 16.0
