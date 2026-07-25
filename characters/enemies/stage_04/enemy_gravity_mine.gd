extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyGravityMine

# Mina de gravidade: flutua e "gravita" devagar até o player quando o detecta —
# contato forte, HP baixo. (Dive lento contínuo do EnemyFlyer faz a perseguição.)
func _ready() -> void:
	super._ready()
	max_hp = 1
	contact_damage = 5
	current_hp = max_hp
	detect_radius = 340.0
	dive_speed = 150.0
	retreat_speed = 60.0
	patrol_range = 80.0
	bob_amplitude = 16.0
