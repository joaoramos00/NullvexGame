extends Node
# Verifica que a arena do boss do stage 01 foi construída corretamente:
# paredes, piso, teto e Ignarath presentes (mesmas dimensões de
# Boss_Floor/Ceil/LWall/RWall do stage_00 — 896x64/64x512, sem soleira, piso
# nivelado com o corredor); door y-range dentro da extensão vertical da
# parede esquerda; nenhum nó com o nome da cratera antiga permanece.
# Ignarath só nasce ao atravessar o corredor (_on_corr_boss_traversed) — usa
# o mesmo atalho ?zone=5 do debug pra simular a entrada na sala.

func _ready() -> void:
	DebugBoot.zone = 5
	var s: Node = load("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(s)
	for i in 4: await get_tree().physics_frame
	DebugBoot.zone = -1
	var fail := false

	# ── Nós estruturais ──────────────────────────────────────────────────────────
	for expected in ["BossWallL", "BossWallR", "BossFloor", "BossCeil",
			"Ignarath", "BossRoomTrigger"]:
		if s.get_node_or_null(expected) == null:
			print("FAIL: nó ausente — %s" % expected)
			fail = true

	# ── Sem cratera antiga nem soleira (arena nivelada com o corredor agora) ──────
	for old in ["BossLava", "Z4Lava", "BossThreshold", "BossPlat1", "BossPlat2"]:
		if s.get_node_or_null(old) != null:
			print("FAIL: nó antigo/removido ainda presente — %s" % old)
			fail = true

	# ── Geometria da parede esquerda vs door range ────────────────────────────────
	var lwall := s.get_node_or_null("BossWallL")
	var ceil_n := s.get_node_or_null("BossCeil")
	var floor_n := s.get_node_or_null("BossFloor")
	if lwall and ceil_n and floor_n:
		const TS := 64.0
		var wall_top    : float = ceil_n.position.y  - TS * 0.5   # topo da parede = topo da sala
		var wall_bottom : float = floor_n.position.y + TS * 0.5   # base da parede = base da sala
		# _BOSS_DOOR_LO e _BOSS_DOOR_HI copiados das consts da stage
		const DOOR_LO := -1182.0
		const DOOR_HI := -1074.0
		if DOOR_LO < wall_top:
			print("FAIL: DOOR_LO (%.0f) acima do topo da parede (%.0f)" % [DOOR_LO, wall_top])
			fail = true
		if DOOR_HI > wall_bottom + 1.0:   # margem de 1px para float
			print("FAIL: DOOR_HI (%.0f) abaixo da base da parede (%.0f)" % [DOOR_HI, wall_bottom])
			fail = true
		# ── Colisão da BossWallL NÃO invade o vão da porta ───────────────────────────
		# A colisão da parede esquerda deve terminar em/acima de _BOSS_DOOR_LO,
		# deixando DOOR_LO..DOOR_HI como abertura livre — senão o player fica fisicamente bloqueado
		# de entrar na arena (bug crítico: parede sólida full-height).
		var lcs: CollisionShape2D = null
		for c in lwall.get_children():
			if c is CollisionShape2D:
				lcs = c
				break
		if lcs == null or not (lcs.shape is RectangleShape2D):
			print("FAIL: BossWallL sem CollisionShape2D retangular")
			fail = true
		else:
			var lwall_coll_bottom: float = lwall.position.y + lcs.position.y + (lcs.shape as RectangleShape2D).size.y * 0.5
			if lwall_coll_bottom > DOOR_LO + 0.5:
				print("FAIL: colisão da BossWallL (base y=%.1f) invade o vão da porta (>%.0f)" % [lwall_coll_bottom, DOOR_LO])
				fail = true

	# ── Sala do mesmo tamanho de Boss_Floor/LWall do stage_00 (896x64/64x512) ─────
	if floor_n:
		var fsh: RectangleShape2D = null
		for c in floor_n.get_children():
			if c is CollisionShape2D:
				fsh = (c as CollisionShape2D).shape as RectangleShape2D
				break
		if fsh == null or absf(fsh.size.x - 896.0) > 0.5 or absf(fsh.size.y - 64.0) > 0.5:
			print("FAIL: BossFloor deveria ser 896x64 (igual ao stage_00), veio %s" % [fsh.size if fsh else "null"])
			fail = true
	if lwall:
		var lsh: RectangleShape2D = null
		for c in lwall.get_children():
			if c is CollisionShape2D:
				lsh = (c as CollisionShape2D).shape as RectangleShape2D
				break
		# BossWallL só cobre a seção acima da porta (não a altura toda de 512) —
		# checa só a largura (64), a mesma de Boss_LWall do stage_00.
		if lsh == null or absf(lsh.size.x - 64.0) > 0.5:
			print("FAIL: BossWallL deveria ter largura 64 (igual ao stage_00), veio %s" % [lsh.size if lsh else "null"])
			fail = true

	# ── Ignarath auto_aggro desligado ────────────────────────────────────────────
	var ign := s.get_node_or_null("Ignarath")
	if ign != null:
		if bool(ign.get("auto_aggro")):
			print("FAIL: Ignarath.auto_aggro deveria ser false")
			fail = true
		var al := float(ign.get("arena_left"))
		var ar := float(ign.get("arena_right"))
		var af := float(ign.get("arena_floor"))
		if al < 18864.0 or ar > 19760.0:
			print("FAIL: arena_left/right fora dos limites esperados (%.0f, %.0f)" % [al, ar])
			fail = true
		if absf(af - (-1074.0)) > 0.5:
			print("FAIL: arena_floor esperado -1074 (nivelado com o corredor), obtido %.1f" % af)
			fail = true

	if fail:
		get_tree().quit(1)
	else:
		print("PASS: boss arena geometry")
		get_tree().quit(0)
