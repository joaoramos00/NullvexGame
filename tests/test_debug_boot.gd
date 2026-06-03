# tests/test_debug_boot.gd
extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	_test_empty()
	_test_basic()
	_test_leading_question_mark()
	_test_flag_without_value()
	_print_results()
	get_tree().quit()

func _assert(cond: bool, msg: String) -> void:
	if cond: _passed += 1; print("  PASS: " + msg)
	else:    _failed += 1; print("  FAIL: " + msg)

func _test_empty() -> void:
	var d := preload("res://tests/bot/debug_boot.gd").parse_params("")
	_assert(d.is_empty(), "query vazia → dict vazio")

func _test_basic() -> void:
	var d := preload("res://tests/bot/debug_boot.gd").parse_params("stage=00&bot=1&noenemies=1")
	_assert(d.get("stage") == "00", "stage parseado")
	_assert(d.get("bot") == "1", "bot parseado")
	_assert(d.get("noenemies") == "1", "noenemies parseado")

func _test_leading_question_mark() -> void:
	var d := preload("res://tests/bot/debug_boot.gd").parse_params("?stage=01")
	_assert(d.get("stage") == "01", "remove '?' inicial")

func _test_flag_without_value() -> void:
	var d := preload("res://tests/bot/debug_boot.gd").parse_params("bot")
	_assert(d.has("bot") and d.get("bot") == "", "chave sem valor vira string vazia")

func _print_results() -> void:
	print("\n=== %d passed, %d failed ===" % [_passed, _failed])
