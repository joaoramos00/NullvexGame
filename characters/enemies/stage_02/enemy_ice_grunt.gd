extends EnemyBase
class_name EnemyIceGrunt

func _init() -> void:
	max_hp = 10
	contact_damage = 8

func _ready() -> void:
	max_hp = 10
	contact_damage = 8
	super._ready()
