extends Node

# Player limitante = Zael (caixa 40×80). Pulo: altura 118, alcance 196 (→192 no grid).
# Gate automático = vão livre horizontal nas faixas de y COM projeção — cada
# projeção com a própria profundidade: saliências 64px, espinhos 24px na
# parede L / 29px na R (embeds assimétricos de playtest — kill Area2D é mais
# largo, mas isso não bloqueia passagem), parede+plats e
# tiras de espinho sob plat _Z4_WALL_PLAT_DEPTH (a tira conta da parede até a
# borda interna, pois o corredor de montaria junto à parede não é passagem).
# Crumbles e plataformas avulsas ficam FORA do gate: são pousos transitórios no
# meio do vão (cai-se pelos dois lados; o modelo "vão a partir de uma parede"
# não os representa). Passo vertical ≤118 e folga ≥80 seguem checagem manual.
const MIN_CLEAR_H := 192.0   # vão livre mínimo onde há projeção
const MIN_PASS_W  := 96.0    # largura mínima de passagem do seg (player 40 + folga)

func _ready() -> void:
	var stage := preload("res://stages/stage_01/stage_01_scene.gd").new()
	var segs: Array = stage.get("_SHAFT_SEGS")
	var footholds: Array = stage.get("_Z4_FOOTHOLDS") if stage.get("_Z4_FOOTHOLDS") != null else []
	var spikes: Array = stage.get("_Z4_SPIKES") if stage.get("_Z4_SPIKES") != null else []
	var baffles: Array = stage.get("_Z4_WALL_PLATS") if stage.get("_Z4_WALL_PLATS") != null else []
	var baffle_depth: float = stage.get("_Z4_WALL_PLAT_DEPTH")
	stage.free()

	if footholds.is_empty() or spikes.is_empty() or baffles.is_empty():
		print("FAIL: tabelas do shaft vazias (layout não carregou?)")
		get_tree().quit(1); return

	# Projeções: [wall_x, cy, h, side, depth]
	var xl: float = segs[0][2]
	var xr: float = segs[0][3]
	var projs: Array = []
	for f in footholds: projs.append([f[1], f[2], f[4], f[3], 64.0])
	for s in spikes:
		var spike_depth: float = 24.0 if s[3] == "L" else 29.0
		projs.append([s[1], s[2], s[4], s[3], spike_depth])
	for bf in baffles:
		var wall_x: float = xl if bf[1] == "L" else xr
		# parede+plat: 64px de espessura (colisão [top, top+64])
		projs.append([wall_x, bf[2] + 32.0, 64.0, bf[1], baffle_depth])
		if bf[3]:
			# tira de espinhos sob a plat: 64px com base 1/4 tile embutida na
			# rocha (kill top+48..top+112)
			projs.append([wall_x, bf[2] + 80.0, 64.0, bf[1], baffle_depth])

	var violations := _validate(segs, projs)
	if not violations.is_empty():
		for v: String in violations:
			print("FAIL: %s" % v)
		get_tree().quit(1); return
	print("PASS: shaft Z4 vão livre ≥192px (passo/folga = calibração manual)")
	get_tree().quit(0)

# Vão livre horizontal por faixa de y: varre em passos de 32px de yt a yb (inclusive),
# calcula o vão livre em cada amostra COM projeção (largura do seg menos a
# profundidade de cada projeção que cobre aquele y) e usa o PIOR CASO (mínimo).
# Falha se mínimo < MIN_CLEAR_H. Amostras sem projeção não entram no pior caso —
# para elas vale só a largura de passagem do seg (≥ MIN_PASS_W).
func _validate(segs: Array, projs: Array) -> Array:
	var out: Array = []
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
				if p[0] < xl or p[0] > xr:
					continue   # projeção de outra parede (fora deste seg)
				covered = true
				if p[3] == "L":
					left = maxf(left, p[0] + (p[4] as float))
				else:
					right = minf(right, p[0] - (p[4] as float))
			var clear: float = right - left
			if covered and clear < worst_clear:
				worst_clear = clear
				worst_y = sample_y
			sample_y += 32.0
		if worst_clear < MIN_CLEAR_H:
			out.append("vão livre %.0fpx < %.0f no seg y[%.0f-%.0f] (pior em y=%.0f)" % [worst_clear, MIN_CLEAR_H, yt, yb, worst_y])
	return out
