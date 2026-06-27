extends Node

## Regressão de dois bugs do boss do Stage 00:
##  1) Ao ENTRAR na sala (auto-walk do Corr3), o boss deve dar aggro na hora
##     (antes ficava IDLE até o player dar o 1º passo — o trigger de aggro ficava
##     à direita de onde o auto-walk parava o player).
##  2) Ao MORRER, a stage deve destravar a câmera e despawnar o boss (a cena não
##     recarrega; só respawn no checkpoint). Antes a câmera ficava na sala e o boss
##     continuava lutando.

var _failed := false

func _ready() -> void:
	await _run()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failed = true
		print("FAIL: ", msg)

func _run() -> void:
	var scene: Node = load("res://stages/stage_00/stage_00.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# ── Bug 1: aggro imediato ao atravessar o Corr3 (entrada na sala) ──────────
	scene.call("_on_corr3_traversed")   # coroutine: roda síncrono até o 1º await
	await get_tree().process_frame

	var boss: Node = scene.get("_boss")
	_check(boss != null and is_instance_valid(boss), "boss deve existir após atravessar o Corr3")
	if boss != null and is_instance_valid(boss):
		# aggro() leva o estado de IDLE(0) para INTRO(1)/COMBAT(2). Se ficou IDLE, não deu aggro.
		_check(boss.state != BossBase.State.IDLE,
			"boss deve sair de IDLE ao entrar na sala (aggro imediato), veio state=%d" % boss.state)
	_check(scene.get("_camera_locked") == true, "câmera deve travar na sala do boss ao atravessar")

	# ── Bug 2: morte reseta a sala do boss ────────────────────────────────────
	scene.call("_on_player_died_reset")
	await get_tree().process_frame

	_check(scene.get("_camera_locked") == false, "câmera deve destravar ao morrer")
	_check(scene.get("_boss") == null, "_boss deve ser null após a morte (despawnado)")
	_check(scene.get("_boss_spawned") == false, "_boss_spawned deve voltar a false após a morte")

	# ── Re-entrada após a morte: boss recriado e câmera re-travada ─────────────
	scene.call("_on_corr3_traversed")
	await get_tree().process_frame
	var boss2: Node = scene.get("_boss")
	_check(boss2 != null and is_instance_valid(boss2), "boss deve ser recriado ao re-atravessar")
	_check(scene.get("_camera_locked") == true, "câmera deve re-travar na re-entrada (mesmo após destravar na morte)")

	if _failed:
		print("TESTS FAILED")
		get_tree().quit(1)
	else:
		print("PASS: stage00_boss_aggro_death")
		print("ALL TESTS PASSED")
		get_tree().quit(0)
