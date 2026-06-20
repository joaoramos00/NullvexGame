extends Node

# Invariantes da rota secreta da zona 4 do stage 01 (Task 9):
# parede #1, passagem + elevador up_only, câmara do coletável (Dual Blades), parede #2.
func _ready() -> void:
	var s = load("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(s)
	for i in 4:
		await get_tree().physics_frame
	var fail := false
	for nm in ["Z4SecretElevator", "Z4Crack1", "Z4Crack2",
			"Z4CollectFloorL", "Z4CollectFloorR", "Z4DualBlades"]:
		if s.get_node_or_null(nm) == null:
			print("FAIL: faltou ", nm); fail = true
	# Parede #2 só quebra por dentro (esquerda) — impede cheese pelo lado da pré-chefe.
	var c2 = s.get_node_or_null("Z4Crack2")
	if c2 != null and String(c2.get("break_side")) != "left":
		print("FAIL: parede #2 deveria quebrar só pela esquerda"); fail = true
	# Parede #1 quebra por qualquer lado (com galerix); detector está à direita (shaft).
	var c1 = s.get_node_or_null("Z4Crack1")
	if c1 != null and c1.get_node_or_null("HitDetectorR") == null:
		print("FAIL: parede #1 sem HitDetectorR"); fail = true
	# Elevador é up_only.
	var elev = s.get_node_or_null("Z4SecretElevator")
	if elev != null and not bool(elev.get("up_only")):
		print("FAIL: elevador deveria ser up_only"); fail = true
	# Coletável é a Dual Blades da Zara.
	var col = s.get_node_or_null("Z4DualBlades")
	if col != null and String(col.get("ability_id")) != "dual_blades":
		print("FAIL: coletável deveria ser dual_blades"); fail = true
	if fail:
		get_tree().quit(1)
	else:
		print("PASS: secret geometry")
		get_tree().quit(0)
