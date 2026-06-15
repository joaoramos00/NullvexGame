# stages/stage_01/cracked_wall.gd
# StaticBody2D com CollisionShape2D filho.
# Destruída quando um projétil (Area2D, collision_layer=8) entra num
# filho HitDetector enquanto o player tiver "galerix" desbloqueada.
# @export break_side: "" = qualquer lado; "left"/"right" = só esse detector.
extends StaticBody2D

signal wall_destroyed

@export var break_side: String = ""

func can_break_from(side: String) -> bool:
	if not GameManager.boss_abilities_unlocked.has("galerix"):
		return false
	return break_side == "" or break_side == side

func _ready() -> void:
	add_to_group("cracked_wall")
	# Detectores: sufixo "L" → quebra só pela esquerda, "R" → só pela direita, sem sufixo → qualquer lado.
	for child in get_children():
		if child is Area2D and child.name.begins_with("HitDetector"):
			var side := "left" if child.name.ends_with("L") else ("right" if child.name.ends_with("R") else "")
			(child as Area2D).area_entered.connect(func(_a): _on_hit_side(side))

func _on_hit_side(side: String) -> void:
	if is_queued_for_deletion():
		return
	if can_break_from(side):
		wall_destroyed.emit()
		queue_free()

# Kept for backwards compatibility — called by tests/test_stage01_hazards.gd
# Ignora break_side (usa ""), então só destrói paredes default/qualquer-lado —
# intencional para os callers existentes do teste de hazards.
func try_destroy() -> void:
	if is_queued_for_deletion():
		return
	if can_break_from(""):
		wall_destroyed.emit()
		queue_free()
