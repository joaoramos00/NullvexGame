extends Node

func _ready() -> void:
	GameManager.boss_abilities_unlocked = ["galerix"]
	var wall = preload("res://stages/stage_01/cracked_wall.gd").new()
	wall.break_side = "left"
	var ok_right := wall.can_break_from("right")
	var ok_left := wall.can_break_from("left")
	if ok_right or not ok_left:
		print("FAIL: break_side não respeitado (left=%s right=%s)" % [ok_left, ok_right]); get_tree().quit(1); return
	print("PASS: cracked_wall break_side")
	get_tree().quit(0)
