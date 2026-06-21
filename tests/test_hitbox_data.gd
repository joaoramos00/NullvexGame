extends Node

func _ready() -> void:
	var fail := false
	HitboxData._data = {
		"enemy_x": {
			"sprite": {"pos": [0, -10], "scale": [1.0, 1.0]},
			"projectile": {"offset": [30, -20]},
			"shapes": [
				{"target": "body", "kind": "rect", "pos": [0, 0], "size": [40, 80], "frames": "all"},
				{"target": "body", "kind": "rect", "pos": [0, 5], "size": [50, 30], "frames": [1, 2]},
			],
		}
	}
	if not HitboxData.has("enemy_x") or HitboxData.has("enemy_none"):
		print("FAIL: has()"); fail = true
	var off := HitboxData.proj_offset("enemy_x", -1.0)
	if off != Vector2(-30, -20):
		print("FAIL: proj_offset espelho (", off, ")"); fail = true
	if HitboxData.proj_offset("enemy_none", 1.0) != Vector2.INF:
		print("FAIL: proj_offset ausente"); fail = true
	if HitboxData.frame_shapes("enemy_x", 0).size() != 1:
		print("FAIL: frame_shapes(0)"); fail = true
	if HitboxData.frame_shapes("enemy_x", 1).size() != 2:
		print("FAIL: frame_shapes(1)"); fail = true
	if fail: get_tree().quit(1)
	else: print("PASS: hitbox_data"); get_tree().quit(0)
