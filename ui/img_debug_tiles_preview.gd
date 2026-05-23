extends Node2D

func _ready() -> void:
	var panel: ImgDebug = load("res://ui/img_debug.tscn").instantiate()
	add_child(panel)
	await get_tree().process_frame
	panel._show_section("TILES")
