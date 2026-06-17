extends Node

func _ready() -> void:
	var lava = preload("res://stages/stage_01/rising_lava.gd").new()
	lava.mode = "chase"
	lava.low_y = 2000.0
	lava.rise_speed = 80.0
	lava.cap_y = 400.0
	lava.accel_y = 1000.0      # acima disso (y < 1000) acelera
	lava.accel_speed = 150.0
	lava.position = Vector2(0, 2000.0)
	lava.activate()
	# longe do topo (y=2000 > accel_y) -> velocidade normal
	var y0 = lava.position.y
	lava._tick(1.0)
	var slow = y0 - lava.position.y
	# pula pra perto do topo (y=900 < accel_y) -> acelerada
	lava.position.y = 900.0
	var y1 = lava.position.y
	lava._tick(1.0)
	var fast = y1 - lava.position.y
	print("slow=", slow, " fast=", fast)
	if abs(slow - 80.0) > 0.5 or abs(fast - 150.0) > 0.5:
		print("FAIL: aceleração da lava errada"); get_tree().quit(1); return
	print("PASS: lava acelera no terço final")
	get_tree().quit(0)
