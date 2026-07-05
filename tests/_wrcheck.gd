extends Node
func _ready() -> void:
	GameManager.set_active_character("zael")
	StageManager.current_stage_id = 1
	var s = load("res://stages/stage_01/stage_01_scene.gd").new()
	StageManager.current_stage_id = 1
	# build only zone 4 directly (avoid full _ready/player spawn)
	add_child(s)
	await get_tree().process_frame
	for n in ["Z4SecretWR", "Z4SecretWL", "Z4ShaftEntry", "Z4PreR", "Z4ShaftWR"]:
		var b = s.get_node_or_null(n)
		if b == null:
			print("CHK ", n, " MISSING"); continue
		print("CHK ", n, " meta=", b.has_meta("lava_override"))
	get_tree().quit(0)
