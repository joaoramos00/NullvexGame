extends Node

func _ready() -> void:
	var scene := preload("res://ui/touch_controls.tscn")
	var tc: CanvasLayer = scene.instantiate()
	add_child(tc)
	# Fora do Web (headless), deve estar oculto
	assert(not tc.visible, "FAIL: TouchControls deveria estar oculto fora do Web")
	print("PASS: touch_controls oculto em plataforma nao-Web")
	tc.queue_free()
	get_tree().quit()
