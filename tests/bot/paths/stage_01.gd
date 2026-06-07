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

		# ── Zona 2 "Rio de Lava": entrada → rafts → elev → ledge(2 gêis) → elev →
		# ledge(3 gêis) → raft → saída. Plats em 2560 (rafts/elev) e 2624 (ledges);
		# rafts/elev congelam no bot. Gêiseres dão dano (bot tanka). ──
		{"t": "zone", "n": 2},
		{"t": "screenshot", "label": "03_z2_spawn"},
		{"t": "jump_to", "x": 3940.0, "jump_x": 3690.0},  # Z2Entry → Raft1
		{"t": "jump_to", "x": 4280.0, "jump_x": 4030.0},  # → Raft2
		{"t": "jump_to", "x": 4632.0, "jump_x": 4370.0},  # → Elev1 (base)
		{"t": "jump_to", "x": 4900.0, "jump_x": 4700.0},  # → LedgeMed
		{"t": "screenshot", "label": "04_z2_med"},
		{"t": "walk_to", "x": 5420.0},                    # atravessa ledge médio (2 gêiseres)
		{"t": "jump_to", "x": 5740.0, "jump_x": 5500.0},  # → Elev2 (base)
		{"t": "jump_to", "x": 6050.0, "jump_x": 5810.0},  # → LedgeHard
		{"t": "screenshot", "label": "05_z2_hard"},
		{"t": "walk_to", "x": 6800.0},                    # atravessa ledge difícil (3 gêiseres)
		{"t": "jump_to", "x": 7100.0, "jump_x": 6850.0},  # → Raft3
		{"t": "jump_to", "x": 7480.0, "jump_x": 7190.0},  # → Z2Exit
		{"t": "walk_to", "x": 9800.0},                    # saída → Corredor1
		{"t": "screenshot", "label": "06_z2_exit"},

		# ── Zona 3 "Maré de Lava": piso+plataforma+buraco (entrada) → pula as passagens
		# sobre a maré (congelada baixa no bot) → piso+plataforma+buraco (saída) → shaft.
		# Entrada: piso 10560–11072 (2624) → plataforma 11072–11328 (topo 2560) → penhasco.
		# Passagens (topo 2624): 11600/12080/12560/13040/13520/14000/14480/14960 (vãos ~160).
		# Saída: plataforma 15240–15496 (topo 2560) → piso 15496–16392 (2624). Spawn 10800. ──
		{"t": "zone", "n": 3},
		{"t": "screenshot", "label": "05_z3_spawn"},
		{"t": "jump_to", "x": 11200.0, "jump_x": 10980.0},  # piso → plataforma de entrada (sobe 64)
		{"t": "jump_to", "x": 11600.0, "jump_x": 11300.0},  # plataforma → passagem 1 (penhasco)
		{"t": "jump_to", "x": 12080.0, "jump_x": 11740.0},  # → passagem 2
		{"t": "jump_to", "x": 12560.0, "jump_x": 12220.0},  # → passagem 3
		{"t": "jump_to", "x": 13040.0, "jump_x": 12700.0},  # → passagem 4
		{"t": "screenshot", "label": "06_z3_mid"},
		{"t": "jump_to", "x": 13520.0, "jump_x": 13180.0},  # → passagem 5
		{"t": "jump_to", "x": 14000.0, "jump_x": 13660.0},  # → passagem 6
		{"t": "jump_to", "x": 14480.0, "jump_x": 14140.0},  # → passagem 7
		{"t": "jump_to", "x": 14960.0, "jump_x": 14620.0},  # → passagem 8
		{"t": "jump_to", "x": 15368.0, "jump_x": 15100.0},  # → plataforma de saída (sobe 64)
		{"t": "walk_to", "x": 16150.0},                      # desce p/ piso da saída (para antes do shaft ↑)
		{"t": "screenshot", "label": "07_z3_exit"},

		# ── Zona 4 "Ascensão do Vulcão": base → escada-chase → patamar → escada-coupled
		# → topo(checkpoint) → cratera → cai no boss. Lavas congelam baixo no bot. ──
		{"t": "zone", "n": 4},
		{"t": "screenshot", "label": "07_z4_base"},
		# Escada-chase: degraus topo0 2520, dx192/dy104, largura256. Centro i=16608+i*192,
		# muro do próximo degrau = 16672+i*192 → jump_x dispara antes do muro.
		{"t": "jump_to", "x": 16608.0, "jump_x": 16432.0},   # base → degrau 0
		{"t": "jump_to", "x": 16800.0, "jump_x": 16624.0},   # → degrau 1
		{"t": "jump_to", "x": 16992.0, "jump_x": 16816.0},   # → degrau 2
		{"t": "jump_to", "x": 17184.0, "jump_x": 17008.0},   # → degrau 3
		{"t": "jump_to", "x": 17376.0, "jump_x": 17200.0},   # → degrau 4
		{"t": "screenshot", "label": "08_z4_chase_mid"},
		{"t": "jump_to", "x": 17568.0, "jump_x": 17392.0},   # → degrau 5
		{"t": "jump_to", "x": 17760.0, "jump_x": 17584.0},   # → degrau 6
		{"t": "jump_to", "x": 17952.0, "jump_x": 17776.0},   # → degrau 7
		{"t": "jump_to", "x": 18144.0, "jump_x": 17968.0},   # → degrau 8
		{"t": "jump_to", "x": 18336.0, "jump_x": 18160.0},   # → degrau 9 (último)
		{"t": "walk_to", "x": 18800.0, "land": true},        # patamar do meio
		{"t": "screenshot", "label": "09_z4_patamar"},
		# Escada-coupled: degraus largos256, dx140/dy104. Centro i=19648+i*140,
		# muro do degrau i=19520+i*140 → jump_x dispara antes do muro.
		{"t": "jump_to", "x": 19648.0, "jump_x": 19480.0},   # patamar → degrau 0
		{"t": "jump_to", "x": 19788.0, "jump_x": 19620.0},   # → degrau 1
		{"t": "jump_to", "x": 19928.0, "jump_x": 19760.0},   # → degrau 2
		{"t": "jump_to", "x": 20068.0, "jump_x": 19900.0},   # → degrau 3
		{"t": "jump_to", "x": 20208.0, "jump_x": 20040.0},   # → degrau 4
		{"t": "screenshot", "label": "10_z4_coup_mid"},
		{"t": "jump_to", "x": 20348.0, "jump_x": 20180.0},   # → degrau 5
		{"t": "jump_to", "x": 20488.0, "jump_x": 20320.0},   # → degrau 6
		{"t": "jump_to", "x": 20628.0, "jump_x": 20460.0},   # → degrau 7
		{"t": "jump_to", "x": 20768.0, "jump_x": 20600.0},   # → degrau 8
		{"t": "jump_to", "x": 20908.0, "jump_x": 20740.0},   # → degrau 9 (último)
		{"t": "walk_to", "x": 21150.0, "land": true},        # sobe no Z4Top (topo + checkpoint)
		{"t": "screenshot", "label": "11_z4_top"},
		{"t": "walk_to", "x": 21410.0},                      # anda até a borda da cratera (x21400)
		{"t": "drop", "dir": 1.0},                           # cai pela boca da cratera → arena
		{"t": "wait", "seconds": 1.5},
		{"t": "screenshot", "label": "12_boss"},
	]
