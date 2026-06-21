extends Node

# A serpente de lava deve emergir NO LUGAR (a animação de 16 frames faz o visual);
# o nó não deve transladar verticalmente ao surgir/submergir.
func _ready() -> void:
	var s = load("res://characters/enemies/stage_01/enemy_lava_serpent.tscn").instantiate()
	add_child(s)
	s.global_position = Vector2(500.0, 1000.0)
	s.set_physics_process(false)   # dirigimos manualmente
	var dt := 1.0 / 60.0
	# ~3.3s cobre SUBMERGED(1.6)+EMERGING(0.7)+EXPOSED(1.2)+SPIT
	for i in 200:
		s._physics_process(dt)
		if absf(s.global_position.y - 1000.0) > 0.5:
			print("FAIL: serpente deslocou vertical no frame %d (y=%.1f)" % [i, s.global_position.y])
			get_tree().quit(1)
			return
	print("PASS: serpente emerge no lugar (sem deslocamento vertical)")
	get_tree().quit(0)
