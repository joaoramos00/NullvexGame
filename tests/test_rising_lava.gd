extends Node
# Testa a lógica de modos da rising_lava sem física/_player real.

const RisingLava := preload("res://stages/stage_01/rising_lava.gd")

func _ready() -> void:
	test_chase_rises_to_cap()
	test_coupled_only_rises()
	print("ALL TESTS PASSED")
	get_tree().quit(0)

func test_chase_rises_to_cap() -> void:
	var l := Area2D.new()
	l.set_script(RisingLava)
	add_child(l)
	l.mode = "chase"
	l.low_y = 2000.0
	l.cap_y = 1500.0
	l.rise_speed = 100.0
	l.position.y = 2000.0
	l.activate()
	for i in 700:
		l._tick(1.0 / 60.0)
	assert(absf(l.position.y - 1500.0) < 1.0, "chase deve parar em cap_y")
	print("PASS: chase_rises_to_cap")

func test_coupled_only_rises() -> void:
	var l := Area2D.new()
	l.set_script(RisingLava)
	add_child(l)
	l.mode = "coupled"
	l.coupled_offset = 200.0
	l.position.y = 2000.0
	l._set_coupled_target(1700.0)
	l._tick(1.0)
	assert(l.position.y <= 1901.0, "coupled deve subir até player+offset")
	l._set_coupled_target(1850.0)
	l._tick(1.0)
	assert(absf(l.position.y - 1900.0) < 1.0, "coupled nunca desce")
	print("PASS: coupled_only_rises")
