# tests/test_no_enemies.gd
extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	await _test_enemies_removed()
	await _test_enemies_present_by_default()
	_print_results()
	get_tree().quit()

func _assert(cond: bool, msg: String) -> void:
	if cond: _passed += 1; print("  PASS: " + msg)
	else:    _failed += 1; print("  FAIL: " + msg)

func _count_combatants(scene: Node) -> int:
	var n := 0
	for c in scene.get_children():
		if c is EnemyBase or c is BossBase:
			n += 1
	return n

func _test_enemies_removed() -> void:
	DebugBoot.no_enemies = true
	StageManager.current_stage_id = 1
	var scene: Node = preload("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert(_count_combatants(scene) == 0, "no_enemies remove EnemyBase/BossBase da stage_01")
	scene.queue_free()
	await get_tree().process_frame

func _test_enemies_present_by_default() -> void:
	DebugBoot.no_enemies = false
	StageManager.current_stage_id = 1
	var scene: Node = preload("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	_assert(_count_combatants(scene) > 0, "sem flag, inimigos permanecem")
	scene.queue_free()
	await get_tree().process_frame

func _print_results() -> void:
	print("\n=== %d passed, %d failed ===" % [_passed, _failed])
