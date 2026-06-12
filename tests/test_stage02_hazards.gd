extends Node

var _passed := 0
var _failed := 0

class DummyPlayer:
	extends CharacterBody2D
	var damage_taken := 0
	var blizzard_push := Vector2.ZERO
	var on_ice := false
	func take_damage(amount: int) -> void:
		damage_taken += amount
	func apply_stage_wind(force: Vector2) -> void:
		blizzard_push += force
	func set_stage_ice(value: bool) -> void:
		on_ice = value

func _ready() -> void:
	_test_ice_floor_marks_player()
	_test_ice_spikes_damage_player()
	_test_blizzard_pushes_player()
	_test_ice_gate_requires_ability()
	_print_results()
	get_tree().quit(0 if _failed == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: " + msg)
	else:
		_failed += 1
		print("  FAIL: " + msg)

func _load_stage02_script(path: String) -> Script:
	var script := load(path) as Script
	_assert(script != null, path + " exists")
	return script

func _test_ice_floor_marks_player() -> void:
	var script := _load_stage02_script("res://stages/stage_02/ice_floor.gd")
	if script == null:
		return
	var ice: Node = script.new()
	var player := DummyPlayer.new()
	add_child(ice)
	add_child(player)
	ice._on_body_entered(player)
	_assert(player.on_ice, "ice_floor marks player on ice")
	ice._on_body_exited(player)
	_assert(not player.on_ice, "ice_floor clears player ice state")
	ice.queue_free()
	player.queue_free()

func _test_ice_spikes_damage_player() -> void:
	var script := _load_stage02_script("res://stages/stage_02/ice_spikes.gd")
	if script == null:
		return
	var spikes: Node = script.new()
	var player := DummyPlayer.new()
	add_child(spikes)
	add_child(player)
	spikes.damage = 7
	spikes._on_body_entered(player)
	_assert(player.damage_taken == 7, "ice_spikes damage player once on enter")
	spikes.queue_free()
	player.queue_free()

func _test_blizzard_pushes_player() -> void:
	var script := _load_stage02_script("res://stages/stage_02/blizzard_zone.gd")
	if script == null:
		return
	var blizzard: Node = script.new()
	var player := DummyPlayer.new()
	add_child(blizzard)
	add_child(player)
	blizzard.force = Vector2(120.0, 0.0)
	blizzard._on_body_entered(player)
	blizzard._physics_process(0.5)
	_assert(player.blizzard_push == Vector2(60.0, 0.0), "blizzard applies force * delta")
	blizzard._on_body_exited(player)
	blizzard._physics_process(0.5)
	_assert(player.blizzard_push == Vector2(60.0, 0.0), "blizzard stops after exit")
	blizzard.queue_free()
	player.queue_free()

func _test_ice_gate_requires_ability() -> void:
	GameManager.boss_abilities_unlocked.clear()
	var script := _load_stage02_script("res://stages/stage_02/ice_gate.gd")
	if script == null:
		return
	var gate: Node = script.new()
	add_child(gate)
	gate.required_ability = "ignarath"
	gate.try_destroy()
	_assert(not gate.is_queued_for_deletion(), "ice_gate stays without required ability")
	GameManager.boss_abilities_unlocked.append("ignarath")
	gate.try_destroy()
	_assert(gate.is_queued_for_deletion(), "ice_gate queues free with required ability")
	GameManager.boss_abilities_unlocked.clear()
	gate.queue_free()

func _print_results() -> void:
	print("\n=== test_stage02_hazards: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TESTS FAILED")
