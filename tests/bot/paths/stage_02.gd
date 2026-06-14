# tests/bot/paths/stage_02.gd — segmentos do caminho da fase 02 (gelo, expandida).
# Z1 escorregadio (derrapante OFF no bot) → Z2 espinhos → CP1 → miniboss (noenemies)
# → CP2 → Z3 nevasca → Z4 abismos mortais → CP3 → boss. Poços Z1–Z3 são recuperáveis
# (cai no fundo e sobe via auto-hop do walk_to); abismos Z4 são jump_to precisos.
# Marcadores {"t":"zone","n":N} permitem ?zone=N começar no trecho.
extends RefCounted

func path() -> Array:
	return [
		{"t": "zone", "n": 1},
		{"t": "screenshot", "label": "00_spawn"},
		{"t": "walk_to", "x": 1750.0},
		{"t": "walk_to", "x": 2800.0},
		{"t": "screenshot", "label": "01_z1_pit1"},
		{"t": "walk_to", "x": 3950.0},
		{"t": "walk_to", "x": 5450.0},
		{"t": "screenshot", "label": "02_z1_end"},
		{"t": "zone", "n": 2},
		{"t": "walk_to", "x": 7400.0},
		{"t": "screenshot", "label": "03_z2_mid"},
		{"t": "walk_to", "x": 10400.0},
		{"t": "screenshot", "label": "04_z2_end"},
		{"t": "walk_to", "x": 13000.0},
		{"t": "screenshot", "label": "05_post_mb"},
		{"t": "zone", "n": 3},
		{"t": "walk_to", "x": 15000.0},
		{"t": "walk_to", "x": 17850.0},
		{"t": "screenshot", "label": "06_z3_end"},
		{"t": "zone", "n": 4},
		{"t": "walk_to", "x": 19050.0},
		{"t": "jump_to", "x": 19600.0, "jump_x": 19180.0},
		{"t": "screenshot", "label": "07_z4_jump1"},
		{"t": "walk_to", "x": 20950.0},
		{"t": "jump_to", "x": 21500.0, "jump_x": 21080.0},
		{"t": "walk_to", "x": 22950.0},
		{"t": "jump_to", "x": 23500.0, "jump_x": 23080.0},
		{"t": "screenshot", "label": "08_z4_end"},
		{"t": "walk_to", "x": 24500.0},
		{"t": "screenshot", "label": "09_boss"},
	]
