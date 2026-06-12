extends Node

# Regressão: pisos retos da fase 00 devem fechar na grade de 64px para o tile de
# canto final (0,0) ser cheio (Floor_Z1B = 1408 = 22 tiles, borda esq. em 2800).
# NÃO testar "desligar o preenchimento de borda": os tiles de canto (0,0)/(1,3) têm
# ~metade transparente, então o preenchimento de meia-tile é necessário — sem ele a
# borda sólida recua e abre vão horizontal entre personagem e piso.
# assert() não aborta headless → usamos _check + exit code.

var _failed := false

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failed = true
		printerr("FAIL: " + msg)

func _ready() -> void:
	await _run()

func _run() -> void:
	var scene: Node = load("res://stages/stage_00/stage_00.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# Floor_Z1B com largura múltipla de 64 (último tile = (0,0) cheio).
	# (O preenchimento de meia-tile nas bordas é mantido — os tiles de canto têm
	# ~metade transparente; removê-lo abriria vão horizontal. Ver _draw_platform_tiles.)
	var fz1b: Node = scene.get_node_or_null("Floor_Z1B")
	_check(fz1b != null, "Floor_Z1B deve existir")
	if fz1b != null:
		var cs := fz1b.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var w: float = (cs.shape as RectangleShape2D).size.x
		_check(int(round(w)) % 64 == 0, "Floor_Z1B largura múltipla de 64; veio %f" % w)
		# Borda esquerda preservada em x=2800.
		var left: float = (fz1b as Node2D).position.x + cs.position.x - w * 0.5
		_check(absf(left - 2800.0) < 0.5, "borda esquerda do Floor_Z1B deve continuar em 2800; veio %f" % left)
		# 3) Última coluna seleciona o cap (0,0); primeira seleciona (1,3).
		var cols: int = ceili(w / 64.0)
		_check(scene.call("_tile_at", cols - 1, cols, 0, 1) == Vector2i(0, 0), "última col do piso = (0,0) cap")
		_check(scene.call("_tile_at", 0, cols, 0, 1) == Vector2i(1, 3), "primeira col do piso = (1,3) cap")

	if _failed:
		print("TESTS FAILED")
		get_tree().quit(1)
	else:
		print("ALL TESTS PASSED")
		get_tree().quit(0)
