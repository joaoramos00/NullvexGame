extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyIceFlyer

func _init() -> void:
	max_hp = 2
	contact_damage = 1
	detect_radius = 240.0
	dive_speed = 310.0
	retreat_speed = 170.0

func _ready() -> void:
	max_hp = 2
	contact_damage = 1
	detect_radius = 240.0
	dive_speed = 310.0
	retreat_speed = 170.0
	super._ready()
