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
		{"t": "jump_to", "x": 2368.0, "jump_x": 2174.0},  # → Z1MovPlat3 (beirada Plat3, gap 128)
		{"t": "jump_to", "x": 2688.0, "jump_x": 2430.0},  # → Z1Plat4 (beirada MovPlat3, gap 128)
		{"t": "screenshot", "label": "02_z1_plat4"},
		# (a calibrar: entrada e descida do shaft → zona 2)

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
