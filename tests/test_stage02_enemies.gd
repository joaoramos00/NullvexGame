extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	_test_ice_grunt_defaults()
	_test_ice_flyer_defaults()
	_test_ice_miniboss_defaults()
	_print_results()
	get_tree().quit(0 if _failed == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: " + msg)
	else:
		_failed += 1
		print("  FAIL: " + msg)

func _load_enemy_script(path: String) -> Script:
	var script := load(path) as Script
	_assert(script != null, path + " exists")
	return script

func _test_ice_grunt_defaults() -> void:
	var script := _load_enemy_script("res://characters/enemies/stage_02/enemy_ice_grunt.gd")
	if script == null:
		return
	var enemy: EnemyBase = script.new()
	_assert(enemy.max_hp >= 10, "ice grunt has stronger hp than base grunt")
	_assert(enemy.contact_damage >= 8, "ice grunt keeps meaningful contact damage")
	enemy.free()

func _test_ice_flyer_defaults() -> void:
	var script := _load_enemy_script("res://characters/enemies/stage_02/enemy_ice_flyer.gd")
	if script == null:
		return
	var enemy: EnemyBase = script.new()
	_assert(enemy.detect_radius >= 220.0, "ice flyer detects from long range")
	_assert(enemy.dive_speed >= 300.0, "ice flyer dives faster than base flyer")
	enemy.free()

func _test_ice_miniboss_defaults() -> void:
	var script := _load_enemy_script("res://characters/enemies/stage_02/enemy_ice_miniboss.gd")
	if script == null:
		return
	var enemy: EnemyBase = script.new()
	_assert(enemy.max_hp >= 40, "MB02 has miniboss hp")
	_assert(enemy.has_signal("died"), "MB02 inherits died signal")
	enemy.free()

func _print_results() -> void:
	print("\n=== test_stage02_enemies: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TESTS FAILED")
