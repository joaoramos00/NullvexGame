extends Node
# Verifica que a arena do boss do stage 01 foi construída corretamente:
# paredes, piso, teto, soleira de transição e Ignarath presentes;
# door y-range dentro da extensão vertical da parede esquerda;
# nenhum nó com o nome da cratera antiga permanece.

func _ready() -> void:
	var s: Node = load("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(s)
	for i in 4: await get_tree().physics_frame
	var fail := false

	# ── Nós estruturais ──────────────────────────────────────────────────────────
	for expected in ["BossWallL", "BossWallR", "BossFloor", "BossCeil",
			"BossThreshold", "Ignarath", "BossRoomTrigger"]:
		if s.get_node_or_null(expected) == null:
			print("FAIL: nó ausente — %s" % expected)
			fail = true

	# ── Sem cratera antiga ────────────────────────────────────────────────────────
	for old in ["BossLava", "Z4Lava"]:
		# A lava do shaft (Z4ShaftLava) é esperada; BossLava e Z4Lava não devem existir.
		if s.get_node_or_null(old) != null:
			print("FAIL: nó antigo da cratera ainda presente — %s" % old)
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
		# (arena deslocada -1622 em Y junto com o topo do shaft; piso top -986)
		const DOOR_LO := -1094.0
		const DOOR_HI := -986.0
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

	# ── Ignarath auto_aggro desligado ────────────────────────────────────────────
	var ign := s.get_node_or_null("Ignarath")
	if ign != null:
		if bool(ign.get("auto_aggro")):
			print("FAIL: Ignarath.auto_aggro deveria ser false")
			fail = true
		var al := float(ign.get("arena_left"))
		var ar := float(ign.get("arena_right"))
		var af := float(ign.get("arena_floor"))
		if al < 18900.0 or ar > 21716.0:
			print("FAIL: arena_left/right fora dos limites esperados (%.0f, %.0f)" % [al, ar])
			fail = true
		if absf(af - (-986.0)) > 0.5:
			print("FAIL: arena_floor esperado -986, obtido %.1f" % af)
			fail = true

	# ── Soleira de transição (BossThreshold) ─────────────────────────────────────
	var thr := s.get_node_or_null("BossThreshold")
	if thr != null:
		# Deve estar no intervalo x 18800..18970 e y ~440 (floor top)
		if thr.position.x < 18800.0 or thr.position.x > 18970.0:
			print("FAIL: BossThreshold.x fora do esperado (%.0f)" % thr.position.x)
			fail = true
		# topo = -986 (= _BOSS_FLOOR_TOP); centro até ~70px abaixo do topo
		if thr.position.y < -986.0 or thr.position.y > -916.0:
			print("FAIL: BossThreshold.y fora do esperado (%.0f)" % thr.position.y)
			fail = true

	if fail:
		get_tree().quit(1)
	else:
		print("PASS: boss arena geometry")
		get_tree().quit(0)
