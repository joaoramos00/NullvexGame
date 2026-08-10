extends Node

# Testa as transições da FSM de run (idle → starting → cycle → stopping → idle).
# Isola a lógica de física real invocando helpers de teste no Kawagael.

func _ready() -> void:
	await test_initial_phase_is_idle()
	await test_starts_running_when_moving_from_idle()
	await test_starting_becomes_cycle_after_anim_finish()
	await test_moving_to_stop_when_dir_released_from_cycle()
	await test_stopping_becomes_idle_after_anim_finish()
	await test_dir_repress_during_stopping_restarts()
	print("=== All Kawagael FSM tests passed ===")
	get_tree().quit()

func _new_kawagael() -> Node:
	var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
	var k = scene.instantiate()
	add_child(k)
	await get_tree().process_frame
	return k

func test_initial_phase_is_idle() -> void:
	var k = await _new_kawagael()
	assert(k._run_phase == "idle",
			"initial phase must be idle, got %s" % k._run_phase)
	k.queue_free()
	print("PASS: test_initial_phase_is_idle")

func test_starts_running_when_moving_from_idle() -> void:
	var k = await _new_kawagael()
	k._advance_run_fsm_for_testing(true, true)  # on_floor=true, moving=true
	assert(k._run_phase == "starting",
			"expected starting, got %s" % k._run_phase)
	k.queue_free()
	print("PASS: test_starts_running_when_moving_from_idle")

func test_starting_becomes_cycle_after_anim_finish() -> void:
	var k = await _new_kawagael()
	k._run_phase = "starting"
	k._notify_run_start_finished()
	assert(k._run_phase == "cycle",
			"expected cycle, got %s" % k._run_phase)
	k.queue_free()
	print("PASS: test_starting_becomes_cycle_after_anim_finish")

func test_moving_to_stop_when_dir_released_from_cycle() -> void:
	var k = await _new_kawagael()
	k._run_phase = "cycle"
	k._advance_run_fsm_for_testing(true, false)  # on floor, not moving
	assert(k._run_phase == "stopping",
			"expected stopping, got %s" % k._run_phase)
	k.queue_free()
	print("PASS: test_moving_to_stop_when_dir_released_from_cycle")

func test_stopping_becomes_idle_after_anim_finish() -> void:
	var k = await _new_kawagael()
	k._run_phase = "stopping"
	k._notify_run_stop_finished()
	assert(k._run_phase == "idle",
			"expected idle, got %s" % k._run_phase)
	k.queue_free()
	print("PASS: test_stopping_becomes_idle_after_anim_finish")

func test_dir_repress_during_stopping_restarts() -> void:
	var k = await _new_kawagael()
	k._run_phase = "stopping"
	k._advance_run_fsm_for_testing(true, true)  # on floor, moving again
	assert(k._run_phase == "starting",
			"expected starting after repress, got %s" % k._run_phase)
	k.queue_free()
	print("PASS: test_dir_repress_during_stopping_restarts")
