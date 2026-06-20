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

# Tint translúcido sobre o tile da zona: pista visual de que a parede é quebrável.
# O pai (stage_scene._draw) desenha a rocha; este overlay (filho) renderiza por cima
# e some junto com a parede ao quebrar (queue_free).
const _TINT := Color(0.95, 0.45, 0.2, 0.38)

func _draw() -> void:
	for c in get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			var sz: Vector2 = ((c as CollisionShape2D).shape as RectangleShape2D).size
			var pos: Vector2 = (c as Node2D).position
			draw_rect(Rect2(pos - sz * 0.5, sz), _TINT)

func _ready() -> void:
	add_to_group("cracked_wall")
	queue_redraw()
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
