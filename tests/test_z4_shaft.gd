extends Node
const WALLJUMP_MAX := 256.0
func _ready() -> void:
	var s = load("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(s)
	for i in 4: await get_tree().physics_frame
	var fail := false
	for i in 6:
		var wl = s.get_node_or_null("Z4ShaftWL%d" % i)
		var wr = s.get_node_or_null("Z4ShaftWR%d" % i)
		if wl == null or wr == null:
			print("FAIL: faltou parede do seg %d" % i); fail = true; continue
		var inner: float = wr.position.x - wl.position.x - 64.0
		if inner > WALLJUMP_MAX + 0.5:
			print("FAIL: seg %d largura %.0f > %.0f" % [i, inner, WALLJUMP_MAX]); fail = true
	var lava = s.get_node_or_null("Z4ShaftLava")
	if lava == null or float(lava.get("cap_y")) > 520.0:
		print("FAIL: lava cap_y nao protege o topo"); fail = true
	if fail: get_tree().quit(1)
	else: print("PASS: shaft geometry"); get_tree().quit(0)
