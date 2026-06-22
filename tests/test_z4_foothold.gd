extends Node

func _ready() -> void:
	var stage := preload("res://stages/stage_01/stage_01_scene.gd").new()
	# .new() sem entrar na árvore → _ready não dispara (sem build pesado).
	# side "R": parede à direita em x=17600 → saliência projeta pra ESQUERDA.
	var fh_r: StaticBody2D = stage._z4_foothold("TestFootR", 17600.0, 1000.0, "R", 96.0)
	# side "L": parede à esquerda em x=17440 → saliência projeta pra DIREITA.
	var fh_l: StaticBody2D = stage._z4_foothold("TestFootL", 17440.0, 1000.0, "L", 96.0)

	if fh_r.is_in_group("no_wall_grab"):
		print("FAIL: saliência não pode ser no_wall_grab (tem que agarrar)"); get_tree().quit(1); return
	if fh_r.collision_layer != 1:
		print("FAIL: saliência deve estar na layer 1, veio %d" % fh_r.collision_layer); get_tree().quit(1); return
	if fh_r.position.x >= 17600.0:
		print("FAIL: side R deve projetar pra esquerda (x<wall_x), veio %f" % fh_r.position.x); get_tree().quit(1); return
	if fh_l.position.x <= 17440.0:
		print("FAIL: side L deve projetar pra direita (x>wall_x), veio %f" % fh_l.position.x); get_tree().quit(1); return
	var shape: RectangleShape2D = fh_r.get_child(0).shape
	if shape.size != Vector2(64.0, 96.0):
		print("FAIL: saliência deve ter 64×h, veio %s" % str(shape.size)); get_tree().quit(1); return
	# centro projetado a meio tile da face
	if absf(fh_r.position.x - (17600.0 - 32.0)) > 0.1:
		print("FAIL: centro R deve ser wall_x-32, veio %f" % fh_r.position.x); get_tree().quit(1); return
	stage.free()
	print("PASS: _z4_foothold agarrável e projeta corretamente")
	get_tree().quit(0)
