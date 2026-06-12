extends Node

## Regressão: o Debug_Plat (bloco de debug solto, commit ca28558) deve ter sido
## fundido ao Floor_Z1A como peça "piso + plataforma" (heightfield fp). E o fundo
## branco de debug só pode aparecer atrás da flag DebugBoot.white_bg (default false).

func _ready() -> void:
	await _run()

func _run() -> void:
	var scene: Node = load("res://stages/stage_00/stage_00.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# 1) Não pode mais existir o bloco de debug solto.
	assert(scene.get_node_or_null("Debug_Plat") == null,
		"Debug_Plat não deve mais existir (fundido ao piso)")

	# 2) Floor_Z1A vira peça piso+plataforma (heightfield).
	var floor_node: Node = scene.get_node_or_null("Floor_Z1A")
	assert(floor_node != null, "Floor_Z1A deve existir")
	assert(floor_node.has_meta("fp_params"), "Floor_Z1A deve ter meta fp_params (heightfield)")
	var p: Dictionary = floor_node.get_meta("fp_params")
	assert(p["plat_cols"] == 4, "plataforma deve ter 4 tiles de largura (256px)")
	assert(p["elev_rows"] == 1, "plataforma deve subir 1 tile (64px, saltável)")
	assert(p["depth_rows"] >= 2, "depth_rows>=2 para a junção côncava renderizar")

	# 3) Colisão dupla: piso + plataforma.
	var shapes := 0
	for c in floor_node.get_children():
		if c is CollisionShape2D:
			shapes += 1
	assert(shapes == 2, "Floor_Z1A deve ter 2 CollisionShape2D (piso + plataforma), veio %d" % shapes)

	# 4) Fundo branco só em debug.
	assert(DebugBoot.white_bg == false, "white_bg deve ser false por padrão (sem fundo branco no jogo)")

	# 5) _fp_tile do stage_00 bate com o canônico (eixos invertidos, marching-squares).
	# Grade: lc=7, pc=4, er=1, dr=2 → total_c grande, total_r=3.
	assert(scene.call("_fp_tile", 7, 0, 7, 4, 1, 38, 3, 0) == Vector2i(1, 3), "canto sup-esq da plataforma")
	assert(scene.call("_fp_tile", 10, 0, 7, 4, 1, 38, 3, 0) == Vector2i(0, 0), "canto sup-dir da plataforma")
	assert(scene.call("_fp_tile", 8, 0, 7, 4, 1, 38, 3, 0) == Vector2i(3, 0), "topo reto da plataforma")
	assert(scene.call("_fp_tile", 7, 1, 7, 4, 1, 38, 3, 0) == Vector2i(1, 1), "junção côncava esquerda")
	assert(scene.call("_fp_tile", 10, 1, 7, 4, 1, 38, 3, 0) == Vector2i(2, 0), "junção côncava direita")
	assert(scene.call("_fp_tile", 6, 1, 7, 4, 1, 38, 3, 0) == Vector2i(3, 0), "superfície do piso (TOP)")

	print("PASS: stage00_floor_platform")
	print("ALL TESTS PASSED")
	get_tree().quit(0)
