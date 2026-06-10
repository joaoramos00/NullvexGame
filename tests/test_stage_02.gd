extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	_test_scene_loads()
	_test_required_nodes_exist()
	_test_collectibles_are_configured()
	_print_results()
	get_tree().quit(0 if _failed == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: " + msg)
	else:
		_failed += 1
		print("  FAIL: " + msg)

func _instance_stage() -> Node:
	var scene := load("res://stages/stage_02/stage_02.tscn") as PackedScene
	_assert(scene != null, "stage_02 scene loads")
	if scene == null:
		return null
	var inst := scene.instantiate()
	add_child(inst)
	return inst

func _test_scene_loads() -> void:
	var inst := _instance_stage()
	_assert(inst != null, "stage_02 scene instantiates")
	if inst != null:
		inst.queue_free()

func _test_required_nodes_exist() -> void:
	var inst := _instance_stage()
	if inst == null:
		return
	for node_name in [
		"PlayerSpawn", "StageController", "HUD", "PauseMenu", "GameOver", "StageComplete", "Camera2D",
		"Z1Marker", "Z2Marker", "MB02Marker", "Z3Marker", "Z4Marker", "BossEntryMarker",
		"Heart", "SubTank", "ArmorZaraHelmet", "SpreadZael"
	]:
		_assert(inst.get_node_or_null(node_name) != null, "%s exists" % node_name)
	_assert(inst.get_script() != null, "stage root has custom script")
	inst.queue_free()

func _test_collectibles_are_configured() -> void:
	var inst := _instance_stage()
	if inst == null:
		return
	var heart := inst.get_node_or_null("Heart") as Collectible
	var subtank := inst.get_node_or_null("SubTank") as Collectible
	var helmet := inst.get_node_or_null("ArmorZaraHelmet") as Collectible
	var spread := inst.get_node_or_null("SpreadZael") as Collectible
	_assert(heart != null and heart.stage_id == 2, "heart stage_id is 2")
	_assert(subtank != null and subtank.collectible_type == Collectible.Type.SUBTANK, "subtank type configured")
	_assert(subtank != null and subtank.subtank_index == 0, "subtank index is 0")
	_assert(helmet != null and helmet.collectible_type == Collectible.Type.ARMOR_ZARA, "Zara helmet type configured")
	_assert(helmet != null and helmet.armor_piece == "helmet", "Zara helmet armor_piece configured")
	_assert(spread != null and spread.collectible_type == Collectible.Type.SHOT_ZAEL, "Spread type configured")
	_assert(spread != null and spread.ability_id == "spread", "Spread ability_id configured")
	inst.queue_free()

func _print_results() -> void:
	print("\n=== test_stage_02: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TESTS FAILED")
