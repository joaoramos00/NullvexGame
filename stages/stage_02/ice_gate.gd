extends StaticBody2D

signal gate_destroyed

@export var required_ability: String = "ignarath"

func _ready() -> void:
	add_to_group("ice_gate")
	var detector := get_node_or_null("HitDetector") as Area2D
	if detector != null:
		detector.area_entered.connect(_on_hit)

func _on_hit(_area: Area2D) -> void:
	try_destroy()

func try_destroy() -> void:
	if GameManager.boss_abilities_unlocked.has(required_ability):
		gate_destroyed.emit()
		queue_free()
