extends Node

# Regressão: o fim de um piso reto (1 linha) deve terminar com o tile de canto
# (0,0) limpo. O gap-fill de meia-tile (commit 5854bce) era pra paredes laterais de
# plataforma MULTI-linha, mas rodava também em piso de 1 linha, sobrescrevendo o cap.
# Além disso a largura precisa fechar na grade de 64px pro último (0,0) ser tile cheio.
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

	# 1) Gate: o edge-fill (meia-tile) só se aplica a plataforma multi-linha.
	_check(scene.call("_edge_fill_applies", 22, 1) == false, "piso 1-linha NÃO usa edge-fill")
	_check(scene.call("_edge_fill_applies", 3, 3) == true, "bloco multi-linha usa edge-fill")
	_check(scene.call("_edge_fill_applies", 1, 1) == false, "1x1 não usa edge-fill")

	# 2) Floor_Z1B com largura múltipla de 64 (último tile = (0,0) cheio).
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
