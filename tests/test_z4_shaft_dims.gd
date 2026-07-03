extends Node

# Player limitante = Zael (caixa 40×80). Pulo: altura 118, alcance 196 (→192 no grid).
# Gate automático = vão livre horizontal nas faixas de y COM projeção (espinho ou
# saliência); segs sem projeção (ex.: seg5, boca de saída de 96px) só precisam da
# largura mínima de passagem. Passo vertical ≤118 e folga ≥80 são checagem manual.
const MIN_CLEAR_H := 192.0   # vão livre mínimo onde há espinho/saliência projetando
const MIN_PASS_W  := 96.0    # largura mínima de passagem do seg (player 40 + folga)

func _ready() -> void:
	var stage := preload("res://stages/stage_01/stage_01_scene.gd").new()
	var segs: Array = stage.get("_SHAFT_SEGS")
	var footholds: Array = stage.get("_Z4_FOOTHOLDS") if stage.get("_Z4_FOOTHOLDS") != null else []
	var spikes: Array = stage.get("_Z4_SPIKES") if stage.get("_Z4_SPIKES") != null else []
	stage.free()

	if footholds.is_empty() and spikes.is_empty():
		print("FAIL: tabelas de saliências/espinhos vazias (layout não carregou?)")
		get_tree().quit(1); return

	var violations := _validate(segs, footholds, spikes)
	if not violations.is_empty():
		for v: String in violations:
			print("FAIL: %s" % v)
		get_tree().quit(1); return
	print("PASS: shaft Z4 vão livre ≥192px (passo/folga = calibração manual)")
	get_tree().quit(0)

# Vão livre horizontal por faixa de y: varre em passos de 32px de yt a yb (inclusive),
# calcula o vão livre em cada amostra COM projeção (largura do seg menos 64px por
# saliência/espinho que projeta naquele y) e usa o PIOR CASO (mínimo). Falha se
# mínimo < MIN_CLEAR_H. Amostras sem projeção não entram no pior caso — para elas
# vale só a largura de passagem do seg (≥ MIN_PASS_W).
func _validate(segs: Array, footholds: Array, spikes: Array) -> Array:
	var out: Array = []
	var projs: Array = []   # [wall_x, cy, h, side] de footholds+spikes
	for f in footholds: projs.append([f[1], f[2], f[4], f[3]])
	for s in spikes:    projs.append([s[1], s[2], s[4], s[3]])
	for seg in segs:
		var yt: float = seg[0]; var yb: float = seg[1]
		var xl: float = seg[2]; var xr: float = seg[3]
		if xr - xl < MIN_PASS_W:
			out.append("largura %.0fpx < %.0f no seg y[%.0f-%.0f]" % [xr - xl, MIN_PASS_W, yt, yb])
		var worst_clear: float = INF
		var worst_y: float = yt
		var sample_y: float = yt
		while sample_y <= yb + 0.001:
			var left := xl
			var right := xr
			var covered := false
			for p in projs:
				var pcy: float = p[1]; var ph: float = p[2]
				if absf(pcy - sample_y) > ph * 0.5:
					continue   # projeção não cobre este y
				covered = true
				if p[3] == "L":
					left = maxf(left, p[0] + 64.0)
				else:
					right = minf(right, p[0] - 64.0)
			var clear: float = right - left
			if covered and clear < worst_clear:
				worst_clear = clear
				worst_y = sample_y
			sample_y += 32.0
		if worst_clear < MIN_CLEAR_H:
			out.append("vão livre %.0fpx < %.0f no seg y[%.0f-%.0f] (pior em y=%.0f)" % [worst_clear, MIN_CLEAR_H, yt, yb, worst_y])
	return out
