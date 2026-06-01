# stages/stage_01/cracked_wall.gd
# StaticBody2D com CollisionShape2D filho.
# Destruída quando um projétil (Area2D, collision_layer=8) entra no
# filho HitDetector enquanto o player tiver "galerix" desbloqueada.
extends StaticBody2D

signal wall_destroyed

func _ready() -> void:
	add_to_group("cracked_wall")
	# HitDetector: Area2D filho, collision_layer=0, collision_mask=8
	var detector := get_node_or_null("HitDetector") as Area2D
	if detector != null:
		detector.area_entered.connect(_on_hit)

func _on_hit(_area: Area2D) -> void:
	try_destroy()

func try_destroy() -> void:
	if GameManager.boss_abilities_unlocked.has("galerix"):
		wall_destroyed.emit()
		queue_free()
