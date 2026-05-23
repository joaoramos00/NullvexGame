extends Control

var current_hp: int = 100
var max_hp: int = 100

func set_hp(current: int, maximum: int) -> void:
	current_hp = current
	max_hp = maximum
	queue_redraw()

func _draw() -> void:
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	var bw := size.x
	var bh := size.y
	var segs := 24
	var gap := 3.0
	var seg_h := (bh - gap * (segs - 1)) / float(segs)
	var filled := roundi(pct * segs)

	draw_rect(Rect2(0, 0, bw, bh), Color(0.07, 0.07, 0.12))

	for i in segs:
		var y := bh - (i + 1) * seg_h - i * gap
		var lit := i < filled
		var color: Color
		if i < 8:
			color = Color(0.90, 0.10, 0.10) if lit else Color(0.15, 0.03, 0.03)
		elif i < 16:
			color = Color(1.00, 0.82, 0.08) if lit else Color(0.15, 0.10, 0.01)
		else:
			color = Color(0.10, 0.50, 1.00) if lit else Color(0.02, 0.08, 0.18)
		draw_rect(Rect2(3.0, y, bw - 6.0, seg_h), color)

	draw_rect(Rect2(0, 0, bw, bh), Color(0.55, 0.60, 0.70), false, 2.0)
