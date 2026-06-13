extends Control

const _SEG_H := 13.0  # altura fixa de cada segmento (px) — não estica com a barra
const _GAP   :=  3.0  # espaço entre segmentos

var current_hp: int = 50
var max_hp: int     = 50

func set_hp(current: int, maximum: int) -> void:
	current_hp = current
	max_hp = maximum
	queue_redraw()

func _draw() -> void:
	var pct  := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	var bw   := size.x
	var bh   := size.y
	# Número de segmentos que cabem na barra com seg_h fixo
	var segs := max(1, int((bh + _GAP) / (_SEG_H + _GAP)))
	var filled := roundi(pct * segs)

	draw_rect(Rect2(0, 0, bw, bh), Color(0.07, 0.07, 0.12))

	for i in segs:
		var y   := bh - (i + 1) * _SEG_H - i * _GAP
		var lit := i < filled
		var t1  := segs / 3
		var t2  := segs * 2 / 3
		var color: Color
		if i < t1:
			color = Color(0.90, 0.10, 0.10) if lit else Color(0.15, 0.03, 0.03)
		elif i < t2:
			color = Color(1.00, 0.82, 0.08) if lit else Color(0.15, 0.10, 0.01)
		else:
			color = Color(0.10, 0.50, 1.00) if lit else Color(0.02, 0.08, 0.18)
		draw_rect(Rect2(3.0, y, bw - 6.0, _SEG_H), color)

	draw_rect(Rect2(0, 0, bw, bh), Color(0.55, 0.60, 0.70), false, 2.0)
