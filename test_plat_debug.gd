extends Node
func _ready() -> void:
	var s: Node = load("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(s)
	for i in 4: await get_tree().physics_frame
	for i in range(1, 6):
		var plat = s.get_node_or_null("Z4Plat%d" % i)
		if plat:
			print("FOUND: Z4Plat%d" % i)
		else:
			print("MISSING: Z4Plat%d" % i)
	get_tree().quit(0)
