# tests/bot/paths/stage_01.gd — segmentos do caminho da fase 01
# Fase grande: zona1 (plats sobre lava instant-kill) → shaft ↓ → zona2 (plats sobre
# lava) → Corr1 → zona3 (plats + gêiseres) → shaft ↑ → zona4 (plats sobre lava) →
# Corr2 → boss. Marcadores {"t":"zone","n":N} permitem ?zone=N começar no trecho.
extends RefCounted

func path() -> Array:
	return [
		# ── Zona 1: sobe degraus (Plat + MovPlat alternados) sobre lava instant-kill.
		# No debug do bot as móveis ficam PARADAS (nas posições do .tscn), então são
		# pulos fixos: gaps ~96px subindo ~50px cada → jump_to comum. ──
		{"t": "zone", "n": 1},
		{"t": "screenshot", "label": "00_spawn"},
		{"t": "jump_to", "x": 1120.0, "jump_x": 948.0},   # → Z1MovPlat1 (beirada Plat1)
		{"t": "jump_to", "x": 1408.0, "jump_x": 1176.0},  # → Z1Plat2 (beirada MovPlat1)
		{"t": "screenshot", "label": "01_z1_plat2"},
		{"t": "jump_to", "x": 1728.0, "jump_x": 1532.0},  # → Z1MovPlat2 (beirada Plat2, gap 128)
		{"t": "jump_to", "x": 2048.0, "jump_x": 1788.0},  # → Z1Plat3 (beirada MovPlat2, gap 128)
		{"t": "jump_to", "x": 2368.0, "jump_x": 2172.0},  # → Z1MovPlat3 (lança na beirada+coyote, gap 128)
		{"t": "jump_to", "x": 2688.0, "jump_x": 2424.0},  # → Z1Plat4 (gap 128)
		{"t": "screenshot", "label": "02_z1_plat4"},
		# ── Shaft de descida (Plat4 → zona 2). Paredes top y640; o apex do pulo (~519)
		# passa por cima da ShaftWallL. ShaftP1-4 alternam x 3072/3200 descendo (zig-zag).
		# ?zone=6 spawna na Plat4 e começa aqui (debug rápido do shaft). ──
		{"t": "zone", "n": 6},
		{"t": "jump_to", "x": 3072.0, "jump_x": 2800.0},  # pula sobre ShaftWallL → ShaftP1 (934)
		{"t": "screenshot", "label": "03_shaft_p1"},
		# Descida zig-zag: mira na metade INTERNA de cada plataforma (longe das paredes,
		# senão o player encosta e o walk_to fica pulando) e no_hop desliga o hop-na-parede.
		# Alvo PASSADO da beirada (3136 +/- TOL 24) p/ o player andar até cair de fato.
		{"t": "walk_to", "x": 3185.0, "no_hop": true},    # anda além da beirada dir → cai na ShaftP2
		{"t": "wait",    "seconds": 3.0},                 # ESPERA pousar antes de trocar de direção
		{"t": "walk_to", "x": 3088.0, "no_hop": true},    # anda além da beirada esq → cai na ShaftP3
		{"t": "wait",    "seconds": 3.0},
		{"t": "walk_to", "x": 3230.0, "no_hop": true},    # → ShaftP4 (aceita pouso na parede dir ~3243)
		{"t": "wait",    "seconds": 3.0},
		{"t": "walk_to", "x": 3050.0, "no_hop": true},    # anda LEFT além da beirada 3136 → cai no Z2Floor
		{"t": "wait",    "seconds": 3.0},
		{"t": "walk_to", "x": 3500.0, "no_hop": true},    # Z2Floor (antes da Z2Plat1) — shaft validado
		{"t": "screenshot", "label": "04_shaft_bottom"},

		# ── Zona 2 ──
		{"t": "zone", "n": 2},
		{"t": "screenshot", "label": "03_z2_spawn"},
		# (a calibrar)

		# ── Zona 3 ──
		{"t": "zone", "n": 3},
		{"t": "screenshot", "label": "05_z3_spawn"},
		# (a calibrar)

		# ── Zona 4 ──
		{"t": "zone", "n": 4},
		{"t": "screenshot", "label": "07_z4_spawn"},
		# (a calibrar)

		# ── Boss ──
		{"t": "zone", "n": 5},
		{"t": "screenshot", "label": "09_boss"},
	]
