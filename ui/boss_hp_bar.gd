extends Control

const _SEG_H := 13.0
const _GAP   :=  3.0

var current_hp: int = 0
var max_hp: int     = 1

func set_hp(current: int, maximum: int) -> void:
	current_hp = current
	max_hp     = maximum
	queue_redraw()

func _draw() -> void:
	var pct    := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	var bw     := size.x
	var bh     := size.y
	var segs   := max(1, int((bh + _GAP) / (_SEG_H + _GAP)))
	var filled := roundi(pct * segs)

	draw_rect(Rect2(0, 0, bw, bh), Color(0.07, 0.05, 0.12))

	for i in segs:
		var y   := bh - (i + 1) * _SEG_H - i * _GAP
		var lit := i < filled
		var color: Color
		if lit:
			color = Color(0.70, 0.15, 1.00)  # violet lit
		else:
			color = Color(0.10, 0.03, 0.18)  # dark unlit
		draw_rect(Rect2(3.0, y, bw - 6.0, _SEG_H), color)

	draw_rect(Rect2(0, 0, bw, bh), Color(0.55, 0.40, 0.70), false, 2.0)
