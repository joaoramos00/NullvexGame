extends Node

func _ready() -> void:
	var scene := load("res://characters/bosses/voltrix.tscn") as PackedScene
	var boss := scene.instantiate()
	add_child(boss)
	assert(boss.max_hp == 40, "max_hp == 40")
	assert(boss.contact_damage == 2, "contact_damage == 2")
	assert(boss.has_method("_do_talon_dive"), "_do_talon_dive existe")
	assert(boss.has_method("_do_static_pulse"), "_do_static_pulse existe")
	print("PASS: voltrix instantiates and loads all frame arrays without error")
	boss.queue_free()
	print("ALL TESTS PASSED")
	get_tree().quit(0)
