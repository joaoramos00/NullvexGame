extends Node

# Player limitante = Zael (caixa 40×80). Pulo: altura 118, alcance 196 (→192 no grid).
# Gate automático = vão livre horizontal (regra que o layout atual viola). Passo
# vertical ≤118 e folga ≥80 são checagem assistida no calibrar (Task 5, Step 4).
const MIN_CLEAR_H := 192.0   # vão livre horizontal mínimo

func _ready() -> void:
	var stage := preload("res://stages/stage_01/stage_01_scene.gd").new()
	var segs: Array = stage.get("_SHAFT_SEGS")
	var footholds: Array = stage.get("_Z4_FOOTHOLDS") if stage.get("_Z4_FOOTHOLDS") != null else []
	var spikes: Array = stage.get("_Z4_SPIKES") if stage.get("_Z4_SPIKES") != null else []
	stage.free()

	var violations := _validate(segs, footholds, spikes)
	if not violations.is_empty():
		for v: String in violations:
			print("FAIL: %s" % v)
		get_tree().quit(1); return
	print("PASS: shaft Z4 respeita pulo do Zael (vão≥192, passo≤118, folga≥80)")
	get_tree().quit(0)

# Vão livre horizontal por faixa de y: largura do seg menos 64px por saliência/espinho
# que projeta naquele y. Falha se < MIN_CLEAR_H.
func _validate(segs: Array, footholds: Array, spikes: Array) -> Array:
	var out: Array = []
	var projs: Array = []   # [wall_x, cy, h, side] de footholds+spikes
	for f in footholds: projs.append([f[1], f[2], f[4], f[3]])
	for s in spikes:    projs.append([s[1], s[2], s[4], s[3]])
	for seg in segs:
		var yt: float = seg[0]; var yb: float = seg[1]
		var xl: float = seg[2]; var xr: float = seg[3]
		var sample_y: float = (yt + yb) * 0.5
		var left := xl
		var right := xr
		for p in projs:
			var pcy: float = p[1]; var ph: float = p[2]
			if absf(pcy - sample_y) > ph * 0.5:
				continue   # projeção não cobre o centro do seg
			if p[3] == "L":
				left = maxf(left, p[0] + 64.0)
			else:
				right = minf(right, p[0] - 64.0)
		var clear: float = right - left
		if clear < MIN_CLEAR_H:
			out.append("vão livre %.0fpx < %.0f no seg y[%.0f-%.0f]" % [clear, MIN_CLEAR_H, yt, yb])
	return out
