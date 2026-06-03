# tests/test_stage_bot.gd
extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	_test_walk_to_completion()
	_test_screenshot_completes()
	_test_dist_to_goal()
	_print_results()
	get_tree().quit()

func _assert(cond: bool, msg: String) -> void:
	if cond: _passed += 1; print("  PASS: " + msg)
	else:    _failed += 1; print("  FAIL: " + msg)

func _make_bot_with_player() -> Node:
	var bot: Node = preload("res://tests/bot/stage_bot.gd").new()
	var p := CharacterBody2D.new()
	p.add_to_group("player")
	add_child(p)
	bot._player = p
	add_child(bot)
	return bot

func _test_walk_to_completion() -> void:
	var bot := _make_bot_with_player()
	bot._player.global_position = Vector2(100, 0)
	var done_far: bool = bot._do_walk_to({"x": 1000.0})
	_assert(not done_far, "walk_to incompleto quando longe do alvo")
	bot._player.global_position = Vector2(1000, 0)
	var done_near: bool = bot._do_walk_to({"x": 1000.0})
	_assert(done_near, "walk_to completo ao chegar no alvo (dentro da TOL)")
	bot._player.queue_free(); bot.queue_free()

func _test_screenshot_completes() -> void:
	var bot := _make_bot_with_player()
	StageManager.current_stage_id = 7
	var done: bool = bot._do_screenshot({"label": "teste"})
	_assert(done, "screenshot completa imediatamente (imprime BOT_SHOT:07:teste acima)")
	bot._player.queue_free(); bot.queue_free()

func _test_dist_to_goal() -> void:
	var bot := _make_bot_with_player()
	bot._player.global_position = Vector2(300, 50)
	var d: float = bot._dist_to_goal({"t": "walk_to", "x": 800.0})
	_assert(absf(d - 500.0) < 0.5, "_dist_to_goal de walk_to = |alvo - x|")
	bot._player.queue_free(); bot.queue_free()

func _print_results() -> void:
	print("\n=== %d passed, %d failed ===" % [_passed, _failed])
