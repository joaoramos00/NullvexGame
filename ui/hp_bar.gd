extends Control

# HP de referência para altura máxima da barra (valor original antes da redução).
# A barra ocupa 400px quando max_hp == FULL_HP; metade quando max_hp == FULL_HP/2.
const FULL_HP     := 100
const FULL_BAR_H  := 400.0  # px quando max_hp == FULL_HP
const BOTTOM_Y    := 462.0  # y fixo da borda inferior (âncora, não muda)

var current_hp: int = 100
var max_hp: int = 100

func set_hp(current: int, maximum: int) -> void:
	current_hp = current
	max_hp = maximum
	# Altura proporcional — meia barra no HP inicial reduzido (50), cresce com corações
	var new_h := clampf(maximum * FULL_BAR_H / FULL_HP, 1.0, FULL_BAR_H)
	size.y = new_h
	position.y = BOTTOM_Y - new_h  # cresce para cima mantendo borda inferior fixa
	queue_redraw()

func _draw() -> void:
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	var bw := size.x
	var bh := size.y
	# Número de segmentos proporcional a max_hp (12 no HP inicial 50, 24 no HP original 100)
	var segs := clampi(roundi(float(max_hp) / float(FULL_HP) * 24.0), 1, 24)
	var gap := 3.0
	var seg_h := (bh - gap * (segs - 1)) / float(segs)
	var filled := roundi(pct * segs)

	draw_rect(Rect2(0, 0, bw, bh), Color(0.07, 0.07, 0.12))

	var red_max    := roundi(segs / 3.0)
	var yellow_max := roundi(segs * 2.0 / 3.0)
	for i in segs:
		var y := bh - (i + 1) * seg_h - i * gap
		var lit := i < filled
		var color: Color
		if i < red_max:
			color = Color(0.90, 0.10, 0.10) if lit else Color(0.15, 0.03, 0.03)
		elif i < yellow_max:
			color = Color(1.00, 0.82, 0.08) if lit else Color(0.15, 0.10, 0.01)
		else:
			color = Color(0.10, 0.50, 1.00) if lit else Color(0.02, 0.08, 0.18)
		draw_rect(Rect2(3.0, y, bw - 6.0, seg_h), color)

	draw_rect(Rect2(0, 0, bw, bh), Color(0.55, 0.60, 0.70), false, 2.0)
