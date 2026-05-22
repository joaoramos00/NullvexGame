extends Node

var _passed := 0
var _failed := 0

var _door_opened_received := false
var _door_closed_received := false

func _ready() -> void:
	await test_door_opens_and_emits_signal()
	await test_door_closes_on_demand()
	print("CheckpointDoor Tests: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: " + msg)
		_passed += 1
	else:
		print("  FAIL: " + msg)
		_failed += 1

func _on_door_opened() -> void:
	_door_opened_received = true

func _on_door_closed() -> void:
	_door_closed_received = true

func test_door_opens_and_emits_signal() -> void:
	var door_scene := load("res://stages/checkpoint_door.tscn") as PackedScene
	var door := door_scene.instantiate()
	add_child(door)
	_assert(door.has_method("open"), "door.open() existe")
	_assert(door.has_method("close"), "door.close() existe")
	_assert(door.has_signal("door_opened"), "sinal door_opened existe")
	_assert(door.has_signal("door_closed"), "sinal door_closed existe")
	_door_opened_received = false
	door.door_opened.connect(_on_door_opened)
	door.open()
	await get_tree().create_timer(0.1).timeout
	_assert(_door_opened_received, "door_opened emitido apos open()")
	door.queue_free()

func test_door_closes_on_demand() -> void:
	var door_scene := load("res://stages/checkpoint_door.tscn") as PackedScene
	var door := door_scene.instantiate()
	add_child(door)
	_door_closed_received = false
	door.door_closed.connect(_on_door_closed)
	door.open()
	await get_tree().create_timer(0.1).timeout
	door.close()
	await get_tree().create_timer(0.1).timeout
	_assert(_door_closed_received, "door_closed emitido apos close()")
	door.queue_free()
