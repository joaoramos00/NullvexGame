extends Node

func _ready() -> void:
	var ledge = preload("res://stages/stage_01/crumbling_ledge.gd").new()
	ledge.crumble_delay = 0.5
	ledge.respawn_delay = 1.0
	var cs := CollisionShape2D.new()
	cs.shape = RectangleShape2D.new()
	ledge.add_child(cs)
	add_child(ledge)
	await get_tree().process_frame
	if cs.disabled:
		print("FAIL: começa desabilitada"); get_tree().quit(1); return
	ledge.touched()
	ledge._tick(0.3)               # antes do crumble_delay (0.5)
	await get_tree().process_frame
	if cs.disabled:
		print("FAIL: desmoronou cedo demais"); get_tree().quit(1); return
	ledge._tick(0.6)
	await get_tree().process_frame      # set_deferred aplica no fim do frame
	if not cs.disabled:
		print("FAIL: não desmoronou após delay"); get_tree().quit(1); return
	ledge._tick(1.1)
	await get_tree().process_frame      # set_deferred aplica no fim do frame
	if cs.disabled:
		print("FAIL: não respawnou"); get_tree().quit(1); return
	print("PASS: crumbling ledge")
	get_tree().quit(0)
