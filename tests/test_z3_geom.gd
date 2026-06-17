extends Node

const _TS := 64
const _SRC_TS := 32

func _ready() -> void:
	var stage_scene: PackedScene = load("res://stages/stage_00/stage_00.tscn")
	var stage := stage_scene.instantiate()
	add_child(stage)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame

	print("=== Z3 GEOMETRY DUMP ===")
	var floor009_right := -INF
	var floor010_left := INF
	var movp_w := 0.0
	for child in stage.get_children():
		var cn: String = (child as Node).name
		if cn == "Z3_FloorA":
			floor009_right = (child as Node2D).position.x + 1090.0 * 0.5
		elif cn == "CorrZ3_Cont_Floor":
			floor010_left = (child as Node2D).position.x - 1292.0 * 0.5
		elif cn == "Z3MovingPlat":
			for sc in child.get_children():
				if sc is CollisionShape2D and (sc as CollisionShape2D).shape is RectangleShape2D:
					movp_w = (((sc as CollisionShape2D).shape) as RectangleShape2D).size.x
	var dist: float = stage.get_script().get_script_constant_map()["_Z3_MOVPLAT_DIST"]
	var start_x: float = stage.get("_z3_movplat_start_x")
	var left_extreme: float = start_x - dist * 0.5 - movp_w * 0.5
	var right_extreme: float = start_x + dist * 0.5 + movp_w * 0.5
	print("MOVP travel: left_edge_min=%s (floor009_right=%s)  right_edge_max=%s (floor010_left=%s)" % [left_extreme, floor009_right, right_extreme, floor010_left])
	if left_extreme < floor009_right - 0.5 or right_extreme > floor010_left + 0.5:
		print("FAIL: movp001 sobrepoe um piso no curso")
		get_tree().quit(1)
	else:
		print("PASS: movp001 nunca sobrepoe os pisos")

	for child in stage.get_children():
		if not (child is StaticBody2D or child is AnimatableBody2D):
			continue
		var nm: String = (child as Node).name
		if not (nm == "Z3_FloorA" or nm == "Z3MovingPlat" or nm.begins_with("CorrZ3")):
			continue
		if nm.begins_with("Glass_"):
			continue
		for sc in child.get_children():
			if not sc is CollisionShape2D:
				continue
			if not (sc as CollisionShape2D).shape is RectangleShape2D:
				continue
			var cs := sc as CollisionShape2D
			var size: Vector2 = ((cs.shape) as RectangleShape2D).size
			var center: Vector2 = (child as Node2D).position + (cs as Node2D).position
			var rect := Rect2(center - size * 0.5, size)
			print("%s  rect=%s  right_edge=%s  width%%64=%s" % [nm, rect, rect.position.x + rect.size.x, fmod(rect.size.x, 64.0)])
			if nm == "Z3_FloorA":
				_dump_draw_lastcol(rect)
	get_tree().quit()

func _dump_draw_lastcol(rect: Rect2) -> void:
	# Replica EXATAMENTE a lógica corrigida de _draw_platform_tiles para a última
	# coluna e confere que nenhum desenho ultrapassa a borda da colisão.
	var ts := _TS
	var src_ts := _SRC_TS
	var cols := ceili(rect.size.x / ts)
	var coll_right: float = rect.position.x + rect.size.x
	var max_draw_x := -INF

	# gap-fill da última coluna (com clamp)
	var gx: float = rect.position.x + (cols - 1) * ts
	var gw: float = minf(ts / 2.0, coll_right - gx)
	if gw > 0.0:
		max_draw_x = maxf(max_draw_x, gx + gw)

	# tile principal da última coluna (com guarda dw>0)
	var dx_main: float = rect.position.x + (cols - 1) * ts + src_ts
	var dw_main: float = minf(ts, coll_right - dx_main)
	if dw_main > 0.0:
		max_draw_x = maxf(max_draw_x, dx_main + dw_main)

	print("   cols=%d  collision_right=%s  max_draw_x=%s" % [cols, coll_right, max_draw_x])
	if max_draw_x > coll_right + 0.5:
		print("FAIL: floor009 visual ultrapassa a colisão em %s px" % [max_draw_x - coll_right])
		get_tree().quit(1)
	else:
		print("PASS: floor009 sem overhang (visual <= colisão)")
