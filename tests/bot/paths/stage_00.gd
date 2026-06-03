# tests/bot/paths/stage_00.gd — segmentos do caminho da fase 00
# Spawn no começo da zona1 (x~300). Fase corre para a DIREITA até o boss.
# Zona1: chão + plataformas com vãos. Zona2: escada de degraus (wall-jump). Zona3: corredor.
extends RefCounted

func path() -> Array:
	return [
		{"t": "screenshot", "label": "00_spawn"},
		# ── Zona 1 (chão y~1088 com vãos de ~400px) ──
		{"t": "walk_to", "x": 2380.0},               # beirada do Floor_Z1A
		{"t": "dash_to", "x": 2820.0},               # dash atravessa o vão 1 → Floor_Z1B
		{"t": "walk_to", "x": 4180.0},               # Floor_Z1B
		{"t": "dash_to", "x": 4620.0},               # dash atravessa o vão 2 → Floor_Z1C
		{"t": "walk_to", "x": 5500.0},               # Floor_Z1C
		{"t": "screenshot", "label": "01_zona1"},
		{"t": "walk_to", "x": 6878.0},               # Corr1 → sala do miniboss (vazia)
		{"t": "screenshot", "label": "02_miniboss"},
		# ── Zona 2 (escada de degraus altos — wall-jump normal) ──
		{"t": "walk_to", "x": 8450.0},               # piso de entrada da zona2
		{"t": "screenshot", "label": "03_z2_entrada"},
		{"t": "climb_to", "y": 440.0, "side": "right"},  # sobe os 3 degraus via wall-jump
		{"t": "screenshot", "label": "04_z2_degraus"},
		{"t": "jump_to", "x": 9892.0, "y": 360.0},   # Float_A
		{"t": "jump_to", "x": 10292.0, "y": 296.0},  # Float_B
		{"t": "jump_to", "x": 10692.0, "y": 360.0},  # Float_C
		{"t": "jump_to", "x": 11550.0, "y": 280.0},  # Floor_Z2_Peak
		{"t": "screenshot", "label": "05_z2_topo"},
		# ── Zona 3 (corredor elevado y~312) ──
		{"t": "walk_to", "x": 13161.0},              # entrada zona3
		{"t": "screenshot", "label": "06_z3"},
		{"t": "walk_to", "x": 15846.0},              # continuação zona3
		{"t": "walk_to", "x": 16524.0},              # corredor do boss
		{"t": "screenshot", "label": "07_corredor_boss"},
		{"t": "walk_to", "x": 17120.0},              # porta do boss
		{"t": "wait", "seconds": 2.5},               # porta abre + auto-walk
		{"t": "walk_to", "x": 18322.0},              # sala do boss / goal
		{"t": "screenshot", "label": "08_sala_boss"},
	]
