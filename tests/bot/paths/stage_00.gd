# tests/bot/paths/stage_00.gd — segmentos do caminho da fase 00
# Spawn no começo da zona1 (x~300). Fase corre para a DIREITA até o boss.
# Zona1: chão + plataformas com vãos. Zona2: escada de degraus (wall-jump). Zona3: corredor.
extends RefCounted

func path() -> Array:
	return [
		{"t": "screenshot", "label": "00_spawn"},
		# ── Bloco 1 (Debug_Plat 550): pulo — walk_to auto-pula nele ──
		{"t": "walk_to", "x": 2360.0},               # passa pelo Debug_Plat até a beirada do Floor_Z1A
		# ── Bloco 2 (degrau 2600): pula, ANDA no topo, pula no fim ──
		{"t": "jump_to", "x": 2540.0},               # 1 pulo: sobe no degrau
		{"t": "screenshot", "label": "01_degrau"},
		{"t": "walk_to", "x": 2700.0},               # anda no topo até a beirada (sem pular)
		{"t": "jump_to", "x": 2900.0},               # 1 pulo: desce na beirada → Floor_Z1B
		# ── Bloco 3 (Block_Z1A 3400): wall-jump ──
		{"t": "walk_to", "x": 3210.0},               # até a face do Block_Z1A
		{"t": "climb_to", "y": 880.0, "side": "right"},
		{"t": "screenshot", "label": "02_block_topo"},
		{"t": "walk_to", "x": 4180.0},               # topo do Block_Z1A + Floor_Z1B até a beirada do vão 2
		# ── Plat_Z1B fina (vão 2): pula no vão + wall-jump na face ──
		{"t": "climb_to", "y": 900.0, "side": "right", "leap": true},
		{"t": "screenshot", "label": "03_platz1b_topo"},
		{"t": "walk_to", "x": 5500.0},               # anda no topo da Plat_Z1B, cai no Floor_Z1C e segue
		{"t": "screenshot", "label": "04_zona1_fim"},
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
		# ── Zona 3: gauntlet "Exame Final" (dash → wall-jump → plataforma móvel) ──
		{"t": "walk_to", "x": 13380.0},              # entry floor, beirada do vão de dash
		{"t": "screenshot", "label": "06_z3_entrada"},
		{"t": "dash_to", "x": 13760.0, "leap": true},  # DASH-JUMP atravessa o vão de 260px → Floor A
		{"t": "walk_to", "x": 14080.0},              # até a face da parede de wall-jump
		{"t": "climb_to", "y": 150.0, "side": "right"},  # wall-jump sobe a parede (topo y120)
		{"t": "screenshot", "label": "07_z3_wall"},
		{"t": "walk_to", "x": 14520.0},              # desce do topo da parede p/ FloorA (pista de corrida)
		{"t": "dash_to", "x": 15500.0, "leap": true, "jump_x": 14746.0},  # DASH-JUMP cruza o fosso (450px) → CorrZ3_Cont
		{"t": "screenshot", "label": "08_z3_fosso"},
		{"t": "walk_to", "x": 16524.0},              # Cont floor → corredor do boss
		{"t": "screenshot", "label": "09_corredor_boss"},
		# Encosta na porta (abre por proximidade, leva alguns seg) e ENTRA na sala antes
		# do selo de 1s reativar a Boss_LWall — pressão contínua à direita, patience alta.
		{"t": "walk_to", "x": 17700.0, "patience": 12.0},  # sala do boss / goal (interior 17154–17986)
		{"t": "screenshot", "label": "10_sala_boss"},
	]
