# tests/bot/paths/stage_00.gd — segmentos do caminho da fase 00
extends RefCounted

func path() -> Array:
	return [
		{"t": "screenshot", "label": "00_spawn"},
		{"t": "walk_to", "x": 3000.0},
		{"t": "screenshot", "label": "01_corredor1"},
		{"t": "walk_to", "x": 6470.0},   # sala do miniboss (vazia em no_enemies)
		{"t": "screenshot", "label": "02_sala_miniboss"},
		{"t": "walk_to", "x": 8222.0},   # corredor 2
		{"t": "screenshot", "label": "03_corredor2"},
		{"t": "walk_to", "x": 17000.0},  # sala do boss (boss removido)
		{"t": "screenshot", "label": "04_sala_boss"},
	]
