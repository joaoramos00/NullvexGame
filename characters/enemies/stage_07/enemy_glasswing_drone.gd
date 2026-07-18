extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyGlasswingDrone

# Drone-vidro patrulheiro: mergulhador padrão, dive rápido quando detecta o player.
func _ready() -> void:
	super._ready()
	max_hp = 8
	contact_damage = 8
	current_hp = max_hp
	detect_radius = 260.0
	dive_speed = 370.0
	retreat_speed = 190.0
	patrol_range = 200.0
	bob_amplitude = 10.0
