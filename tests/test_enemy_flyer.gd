extends Node

# assert() não aborta neste modo headless (só loga) — usamos _check + exit code
# para um veredito inequívoco.
var _failed := false

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failed = true
		printerr("FAIL: " + msg)

func _ready() -> void:
	test_hover_returns_without_jitter_when_displaced()
	test_hover_normal_patrol_flips_at_edge()
	if _failed:
		print("TESTS FAILED")
		get_tree().quit(1)
	else:
		print("ALL TESTS PASSED")
		get_tree().quit(0)

# Regressão: após um DIVE deslocar o flyer muito além do patrol_range (RETREAT só
# restaura Y, nunca X), o HOVER não pode flipar _direction todo frame — isso fazia
# velocity.x alternar +/- a cada frame → sprite "parado trocando esquerda↔direita".
# Estando à direita do _start_x, deve ir CONSISTENTEMENTE de volta (vx<0), sem jitter.
func test_hover_returns_without_jitter_when_displaced() -> void:
	var flyer = _spawn()
	flyer.patrol_range = 150.0
	flyer._start_x = 1000.0
	flyer.global_position = Vector2(1500.0, flyer.global_position.y)  # 500px à direita
	flyer._direction = 1.0

	var signs: Array[float] = []
	for i in 8:
		flyer._tick_hover(0.016)
		signs.append(signf(flyer.velocity.x))

	for i in signs.size():
		_check(signs[i] == -1.0,
			"frame %d: flyer deve ir ao _start_x (esquerda, vx<0); veio sign=%f" % [i, signs[i]])
	for i in range(1, signs.size()):
		_check(signs[i] == signs[i - 1],
			"frame %d: _direction não pode alternar todo frame (jitter de sprite)" % i)

	flyer.queue_free()
	print("done: hover_returns_without_jitter_when_displaced")

# Dentro do range, a patrulha continua: ao cruzar a borda indo pra fora, inverte UMA vez.
func test_hover_normal_patrol_flips_at_edge() -> void:
	var flyer = _spawn()
	flyer.patrol_range = 150.0
	flyer._start_x = 1000.0
	# Exatamente na borda direita, indo pra direita (fora) → deve inverter para esquerda.
	flyer.global_position = Vector2(1150.0, flyer.global_position.y)
	flyer._direction = 1.0
	flyer._tick_hover(0.016)
	_check(flyer._direction == -1.0, "na borda indo pra fora, deve inverter para dentro")
	# Já indo pra dentro: não deve inverter de novo no frame seguinte.
	flyer._tick_hover(0.016)
	_check(flyer._direction == -1.0, "indo pra dentro, não deve inverter (sem jitter)")

	flyer.queue_free()
	print("done: hover_normal_patrol_flips_at_edge")

func _spawn():
	var scene := load("res://characters/enemies/enemy_flyer.tscn")
	var flyer = scene.instantiate()
	add_child(flyer)
	return flyer
