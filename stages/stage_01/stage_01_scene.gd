# stages/stage_01/stage_01_scene.gd
extends "res://stages/stage_scene.gd"

const _MOVPLAT := preload("res://stages/stage_01/moving_platform.gd")
const _VPLAT   := preload("res://stages/stage_01/vertical_platform.gd")
const _GEYSER  := preload("res://stages/stage_01/geyser.gd")
const _LAVA    := preload("res://stages/stage_01/lava_floor.gd")
const _RISING_LAVA := preload("res://stages/stage_01/rising_lava.gd")
const _LAVA_SHADER := preload("res://stages/stage_01/lava_flow.gdshader")
const _SPIKES_TEX := preload("res://stages/stage_01/spikes.png")
const _LAVA_TILE := "res://stages/stage_01/stage_01_lava_v2.png"  # toda lava da fase usa v2
const _Z2_FLOOR_TILE := "res://stages/stage_01/Stage_01T_z2.png"  # mesmo tile do floor

func _ready() -> void:
	if StageManager.current_stage_id < 0:
		StageManager.current_stage_id = 1
	super._ready()
	# Paredes do shaft de DESCIDA: lisas (no_wall_grab) — desce pulando nas ShaftP,
	# não escalando. Sem isso o player agarra a parede e fica pendurado.
	for wn in ["ShaftWallL", "ShaftWallR"]:
		var w := get_node_or_null(wn)
		if w:
			w.add_to_group("no_wall_grab")
	# Lava da zona 1 usa a textura v2 (consistente com o resto da fase).
	var z1lf := get_node_or_null("Z1LavaFloor")
	if z1lf:
		z1lf.set_meta("tileset_override", _LAVA_TILE)
	# Final em vulcão: fora o shaft de wall-kick e o Corridor2 (substituídos pela
	# ascensão da zona 4). Abre um vão no teto do boss p/ a queda da cratera entrar.
	for n in ["ShaftUpWallL", "ShaftUpWallR", "ShaftUpP1", "ShaftUpP2", "ShaftUpP3",
			"ShaftUpP4", "ShaftUpP5", "Corridor2",
			"Z4Floor", "Z4Ceil", "Z4Lava", "Z4Plat1", "Z4Plat2", "Z4Plat3",
			"Z4MovingPlat", "Z4Grunt1", "Z4Grunt2", "Z4Flyer1"]:
		var node := get_node_or_null(n)
		if node:
			node.queue_free()
	_open_boss_ceiling_gap()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	for corr in get_children():
		if corr is CorridorSection and not corr.is_queued_for_deletion():
			corr.setup(_player)
			corr.camera_lock_requested.connect(_on_camera_lock)

# Abre um vão no teto da câmara do boss (BossCeil) na coluna da cratera, p/ a queda da
# cratera entrar. Substitui o BossCeil único por 2 segmentos com um vão no meio-direita.
func _open_boss_ceiling_gap() -> void:
	var ceil_node := get_node_or_null("BossCeil")
	if ceil_node == null:
		return
	# BossCeil atual: centro (21184, 448), tamanho (2816, 64) → x19776–22592, y416–480.
	var gap_cx := 21000.0   # coluna da cratera
	var gap_w := 256.0
	var left_x := 19776.0
	var right_x := 22592.0
	var top := 416.0
	var h := 64.0
	ceil_node.queue_free()
	var lw := (gap_cx - gap_w * 0.5) - left_x
	var lb := _z2_static("BossCeilL", Vector2(left_x + lw * 0.5, top + h * 0.5), Vector2(lw, h))
	lb.set_meta("tileset_override", _Z2_FLOOR_TILE)
	var rw := right_x - (gap_cx + gap_w * 0.5)
	var rb := _z2_static("BossCeilR", Vector2((gap_cx + gap_w * 0.5) + rw * 0.5, top + h * 0.5), Vector2(rw, h))
	rb.set_meta("tileset_override", _Z2_FLOOR_TILE)

func _on_camera_lock(center: Vector2, zoom: float) -> void:
	$Camera2D.zoom = Vector2(zoom, zoom)
	# câmera volta a seguir o player automaticamente pelo _process herdado

# ─── Zona 2 redesenhada: "Rio de Lava" ────────────────────────────────────────
# Lava instant-kill embaixo; rafts horizontais + elevadores de gêiser (teto com
# espinhos instant-kill) + gêiseres encadeados (médio 2, difícil 3) sobre ledges.
# No debug do bot, rafts/elevadores congelam → valida o layout fixo.
func _build_zone2() -> void:
	# Remove a zona 2 antiga.
	for n in ["Z2Floor","Z2Ceil","Z2Plat1","Z2Plat2","Z2Plat3","Z2Plat4","Z2Plat5",
			"Z2Plat6","Z2Plat7","LavaFossa1","LavaFossa2","LavaFossa3","LavaFossa4",
			"LavaFossa5","Z2Bridge1","Z2Bridge2","Z2Bridge3","Z2Grunt1","Z2Grunt2",
			"Z2Grunt3","Z2Flyer1","Z2Flyer2"]:
		var node := get_node_or_null(n)
		if node:
			node.queue_free()
	# Lava instant-kill (superfície) + corpo sólido de lava (visual) por toda a extensão.
	_z2_lava("Z2NewLava", Vector2(6450, 2800), Vector2(7000, 200), true)
	var z2lf := _z2_static("Z2NewLavaFloor", Vector2(6450, 2960), Vector2(7000, 240))
	z2lf.set_meta("tileset_override", _LAVA_TILE)  # lava da zona 2 usa a textura v2
	# Teto + espinhos só na região dos elevadores (perigo ao subir). Teto com tile de
	# fill (igual base do floor) + PNG de espinhos apontando pra baixo.
	var ceil_body := _z2_static("Z2Ceiling", Vector2(5200, 2080), Vector2(1600, 80))
	ceil_body.set_meta("tileset_override", _Z2_FLOOR_TILE)
	_z2_lava("Z2Spikes", Vector2(5200, 2150), Vector2(1600, 60), true)
	_z2_spikes_visual(5200.0, 2120.0, 1600.0)
	# Entrada (saída do shaft) e saída (→ Corredor1) sólidas.
	_z2_static("Z2Entry", Vector2(3350, 2688), Vector2(700, 128))   # x3000–3700 topo 2624
	_z2_static("Z2Exit",  Vector2(8620, 2688), Vector2(2560, 128))  # x7340–9900 topo 2624
	# Rafts horizontais (deslizam na lava; congelam no bot).
	_z2_raft("Z2Raft1", Vector2(3940, 2592), Vector2(200, 64), 300.0, 70.0)
	_z2_raft("Z2Raft2", Vector2(4280, 2592), Vector2(200, 64), 300.0, 70.0)
	_z2_raft("Z2Raft3", Vector2(7100, 2592), Vector2(200, 64), 300.0, 70.0)
	# Elevadores de gêiser (sobem da base aos espinhos; congelam na base no bot).
	_z2_elev("Z2Elev1", Vector2(4632, 2592), Vector2(160, 64), 320.0, 60.0)
	_z2_elev("Z2Elev2", Vector2(5740, 2592), Vector2(160, 64), 320.0, 60.0)
	# Ledges sólidos com gêiseres encadeados.
	_z2_static("Z2LedgeMed",  Vector2(5160, 2688), Vector2(700, 128))  # x4810–5510
	_z2_static("Z2LedgeHard", Vector2(6410, 2688), Vector2(900, 128))  # x5960–6860
	# Médio: 2 gêiseres (timing offset).
	_z2_geyser("Z2GeyMed1", Vector2(5010, 2440), Vector2(64, 360), 1.4, 2.0, 0.0)
	_z2_geyser("Z2GeyMed2", Vector2(5310, 2440), Vector2(64, 360), 1.4, 2.0, 1.0)
	# Difícil: 3 gêiseres em onda (timing mais apertado).
	_z2_geyser("Z2GeyHard1", Vector2(6110, 2440), Vector2(64, 360), 1.2, 1.4, 0.0)
	_z2_geyser("Z2GeyHard2", Vector2(6410, 2440), Vector2(64, 360), 1.2, 1.4, 0.8)
	_z2_geyser("Z2GeyHard3", Vector2(6710, 2440), Vector2(64, 360), 1.2, 1.4, 1.6)

func _z2_shape(size: Vector2) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	return cs

func _z2_static(n: String, center: Vector2, size: Vector2) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = n
	b.collision_layer = 1
	b.position = center
	b.add_child(_z2_shape(size))
	add_child(b)
	return b

func _z2_spikes_visual(center_x: float, top_y: float, width: float) -> void:
	# Tira de espinhos (PNG) repetida apontando pra baixo, pendurada no teto.
	var spr := Sprite2D.new()
	spr.name = "Z2SpikesVis"
	spr.texture = _SPIKES_TEX
	spr.centered = false
	spr.flip_v = true                                   # espinhos do PNG apontam pra cima → vira pra baixo
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, width * 0.5, 32)      # *0.5 compensa o scale 2 (cada cluster = 64px)
	spr.scale = Vector2(2, 2)
	spr.position = Vector2(center_x - width * 0.5, top_y)
	spr.z_index = 5
	add_child(spr)

func _z2_lava(n: String, center: Vector2, size: Vector2, instakill: bool) -> void:
	var a := Area2D.new()
	a.name = n
	a.set_script(_LAVA)
	a.collision_layer = 0
	a.collision_mask = 2
	a.set("instant_kill", instakill)
	a.position = center
	a.add_child(_z2_shape(size))
	add_child(a)

func _z2_raft(n: String, center: Vector2, size: Vector2, dist: float, spd: float) -> void:
	var b := StaticBody2D.new()
	b.name = n
	b.set_script(_MOVPLAT)
	b.collision_layer = 1
	b.set("move_distance", dist)
	b.set("speed", spd)
	b.position = center
	b.add_child(_z2_shape(size))
	add_child(b)

func _z2_elev(n: String, center: Vector2, size: Vector2, dist: float, spd: float) -> void:
	var b := AnimatableBody2D.new()
	b.name = n
	b.set_script(_VPLAT)
	b.collision_layer = 1
	b.set("move_distance", dist)
	b.set("speed", spd)
	b.set("up_only", true)
	b.position = center
	b.add_child(_z2_shape(size))
	add_child(b)

func _z2_geyser(n: String, center: Vector2, size: Vector2, act: float, inact: float, delay: float) -> void:
	var a := Area2D.new()
	a.name = n
	a.set_script(_GEYSER)
	a.collision_layer = 0
	a.collision_mask = 2
	a.set("active_time", act)
	a.set("inactive_time", inact)
	a.set("start_delay", delay)
	a.position = center
	a.add_child(_z2_shape(size))
	add_child(a)

# ─── Zona 3 redesenhada: "Maré de Lava" ───────────────────────────────────────
# Lava instant-kill que SOBE e DESCE cobrindo as plataformas de passagem (baixo);
# refúgios em cima (sempre seguros). No bot a lava congela embaixo → valida o caminho.
func _build_zone3() -> void:
	for n in ["Z3FloorA","Z3FloorB","Z3Ceil","Z3Plat1","Z3Plat2","Z3Plat3","Z3Plat4",
			"Z3Plat5","Z3MovingPlat","Z3Geyser1","Z3Geyser2","Z3Geyser3",
			"Z3Grunt1","Z3Grunt2","Z3Grunt3","Z3Flyer1"]:
		var node := get_node_or_null(n)
		if node:
			node.queue_free()
	# Entrada = PISO+PLATAFORMA+BURACO (buraco à direita = penhasco caindo na lava).
	# Piso (corredor, topo 2624) → plataforma (topo 2560, +64; pulo máx ~118px) → penhasco.
	# Penhasco em x11328 (borda direita da plataforma).
	_z3_floor_platform("Z3Entry", 10560.0, 2624.0, 8, 4, 0, 1, 1)   # piso 10560–11072, plat 11072–11328
	# Maré de lava entre os dois penhascos (x11328–15240): baixa 2760 ↔ alta 2580.
	_z3_rising_lava("Z3Tide", 13284.0, 3912.0, 2760.0, 2580.0)
	# Plataformas de PASSAGEM (topo 2624) sobre a maré — vãos ~160px (pulo ~196px).
	var pass_x := [11600.0, 12080.0, 12560.0, 13040.0, 13520.0, 14000.0, 14480.0, 14960.0]
	for i in pass_x.size():
		_z3_static_floor("Z3Pass%d" % i, Vector2(pass_x[i], 2688), Vector2(320, 128))
	# Refúgios (topo 2540, +84) — acima da maré alta (2580); pra esperar a lava baixar.
	for rx in [12080.0, 13040.0, 14000.0]:
		_z3_static_floor("Z3Ref%d" % int(rx), Vector2(rx, 2604), Vector2(320, 128))
	# Saída = PISO+PLATAFORMA+BURACO espelhado (buraco à esquerda = penhasco subindo da
	# lava): maré → penhasco (x15240) → plataforma (topo 2560) → piso (topo 2624) → shaft ↑.
	_z3_floor_platform("Z3Exit", 15240.0, 2624.0, 0, 4, 14, 1, -1)   # plat 15240–15496, piso 15496–16392

func _z3_static_floor(n: String, center: Vector2, size: Vector2) -> StaticBody2D:
	# Chão sólido com o desenho de plataforma do corredor (borda de topo) — distinto
	# da lava da maré, que usa o shader de fluxo.
	var b := _z2_static(n, center, size)
	b.set_meta("platform_override", _Z2_FLOOR_TILE)
	return b

# Peça PISO+PLATAFORMA: piso reto + plataforma elevada (sem vão) + piso reto, como UM
# bloco sólido. Colisão = retângulo do piso (largura total, profundidade dr) +
# retângulo da plataforma (largura plat, da superfície ao topo elevado). Desenho via
# heightfield _draw_fp_node (meta "fp_params"). tile = 64 game units.
func _z3_floor_platform(n: String, left_x: float, surface_y: float,
		lc: int, pc: int, rc: int, er: int, hole: int = 0, dr: int = 2) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = n
	b.collision_layer = 1
	b.position = Vector2.ZERO
	var tile := 64.0
	var total_c := lc + pc + rc
	# Colisão só nas colunas SÓLIDAS (o lado do buraco é abismo — sem piso).
	var c_start := 0
	var c_end := total_c
	if hole > 0:
		c_end = lc + pc            # buraco à direita: piso direito não existe
	elif hole < 0:
		c_start = lc               # buraco à esquerda: piso esquerdo não existe
	# Piso: da superfície (surface_y) pra baixo (dr tiles), só nas colunas sólidas.
	var fw := (c_end - c_start) * tile
	var floor_cs := _z2_shape(Vector2(fw, dr * tile))
	floor_cs.position = Vector2(left_x + (c_start + c_end) * 0.5 * tile, surface_y + dr * tile * 0.5)
	b.add_child(floor_cs)
	# Plataforma: largura plat, do topo elevado até a superfície.
	var pw := pc * tile
	var plat_cs := _z2_shape(Vector2(pw, er * tile))
	plat_cs.position = Vector2(left_x + (lc + pc * 0.5) * tile, surface_y - er * tile * 0.5)
	b.add_child(plat_cs)
	add_child(b)
	b.set_meta("fp_params", {
		"left_cols": lc, "plat_cols": pc, "right_cols": rc,
		"elev_rows": er, "depth_rows": dr, "hole_dir": hole,
		"left_x": left_x, "surface_y": surface_y, "tex_path": _Z2_FLOOR_TILE,
	})
	return b

func _z3_rising_lava(n: String, center_x: float, width: float, low_y: float, high_y: float) -> void:
	var a := Area2D.new()
	a.name = n
	a.set_script(_RISING_LAVA)
	a.collision_layer = 0
	a.collision_mask = 2
	a.set("low_y", low_y)
	a.set("high_y", high_y)
	a.position = Vector2(center_x, low_y)   # _ready ajusta o y; corpo desce a partir daqui
	a.z_index = 1                            # na frente das plataformas → cobre/esconde ao subir
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var h := 900.0
	rect.size = Vector2(width, h)
	cs.shape = rect
	cs.position = Vector2(0, h * 0.5)        # topo da hitbox no y do nó (= superfície)
	a.add_child(cs)
	add_child(a)
	# Visual: corpo (fill) + crosta (top) tilados, com shader de fluxo (movimento).
	var mat := ShaderMaterial.new()
	mat.shader = _LAVA_SHADER
	var fill_tex: Texture2D = load("res://stages/stage_01/lava_fill.png")
	var top_tex: Texture2D = load("res://stages/stage_01/lava_top.png")
	if fill_tex:
		var body := Sprite2D.new()
		body.texture = fill_tex
		body.centered = false
		body.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		body.region_enabled = true
		body.region_rect = Rect2(0, 0, width * 0.5, (h - 64.0) * 0.5)  # *0.5 → scale 2
		body.scale = Vector2(2, 2)
		body.position = Vector2(-width * 0.5, 64.0)
		body.material = mat
		a.add_child(body)
	if top_tex:
		var top := Sprite2D.new()
		top.texture = top_tex
		top.centered = false
		top.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		top.region_enabled = true
		top.region_rect = Rect2(0, 0, width * 0.5, 32.0)              # crosta ~64px no mundo
		top.scale = Vector2(2, 2)
		top.position = Vector2(-width * 0.5, 0.0)
		top.material = mat
		a.add_child(top)

# ─── Zona 4: Ascensão do Vulcão ──────────────────────────────────────────────
# Base → escada-chase (lava perseguindo) → patamar → escada-coupled (lava acoplada)
# → topo+checkpoint → cratera (borda) → cai na arena do boss. Lavas congelam no bot.
func _build_zone4() -> void:
	# Base: piso de transição após a Z3Exit (topo 2624).
	_z3_static_floor("Z4Base", Vector2(16320, 2688), Vector2(320, 128))   # x16160–16480

	# Escada-chase: 10 degraus (dy104≤118, dx192≤196) de topo 2520 → 1584.
	_z4_stair("Z4ChaseStep", 16480.0, 2520.0, 192.0, 104.0, 10)
	# Lava-chase: sobe contínua da base até o cap (logo abaixo do patamar).
	var chase := _z4_lava("Z4ChaseLava", "chase", 17400.0, 2820.0, 3600.0, 1200.0)
	chase.set("rise_speed", 80.0)
	chase.set("cap_y", 1640.0)
	# Gatilho: ativa a lava-chase quando o player entra na base.
	var trig := Area2D.new()
	trig.name = "Z4ChaseTrigger"
	trig.collision_layer = 0
	trig.collision_mask = 2
	trig.position = Vector2(16480, 2560)
	trig.add_child(_z2_shape(Vector2(64, 256)))
	add_child(trig)
	trig.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBase:
			chase.call("activate"))

	# Patamar do meio (respiro, topo 1584, acima do cap 1640 da lava-chase).
	_z3_static_floor("Z4MidA", Vector2(18560, 1648), Vector2(640, 128))   # x18240–18880
	_z3_static_floor("Z4MidB", Vector2(19200, 1648), Vector2(640, 128))   # x18880–19520

	# Escada-coupled: 10 degraus (dy104, dx96) de topo 1480 → 544. Último ~x20384.
	_z4_stair("Z4CoupStep", 19520.0, 1480.0, 96.0, 104.0, 10)
	# Lava-coupled: segue a altura do player; só sobe; X limitada (x18800–20600, longe
	# da cratera em 21000, senão o player bate nela ao cair).
	var coup := _z4_lava("Z4CoupLava", "coupled", 19700.0, 1820.0, 1800.0, 1400.0)
	coup.set("coupled_offset", 240.0)
	if is_instance_valid(_player):
		coup.call("set_player", _player)

	# Topo: patamar do fim da escada (~20384) até a borda da cratera (21000). Checkpoint+cura.
	_z3_static_floor("Z4Top", Vector2(20692, 608), Vector2(616, 128))    # x20384–21000, topo 544
	var cp := preload("res://stages/checkpoint.tscn").instantiate()
	cp.name = "Z4Checkpoint"
	cp.position = Vector2(20600, 480)
	cp.set("checkpoint_index", 2)
	add_child(cp)
	# Cura ao chegar no topo (o nó Checkpoint só salva; a cura era do corredor).
	var heal := Area2D.new()
	heal.name = "Z4TopHeal"
	heal.collision_layer = 0
	heal.collision_mask = 2
	heal.position = Vector2(20692, 480)
	heal.add_child(_z2_shape(Vector2(616, 160)))
	add_child(heal)
	var healed := [false]   # Array p/ a lambda capturar por referência (não por valor)
	heal.body_entered.connect(func(b: Node) -> void:
		if not healed[0] and b is CharacterBase:
			healed[0] = true
			(b as CharacterBase).heal((b as CharacterBase).max_hp))

	# Cratera: a borda direita do Z4Top (x21000) sobre o vão do BossCeil → queda na arena.
	# Lip visual de lava (sem colisão) na boca da cratera.
	var lip := Sprite2D.new()
	lip.name = "Z4CraterLip"
	var lip_tex: Texture2D = load("res://stages/stage_01/lava_top.png")
	if lip_tex:
		lip.texture = lip_tex
		lip.centered = false
		lip.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		lip.region_enabled = true
		lip.region_rect = Rect2(0, 0, 128, 32)
		lip.scale = Vector2(2, 2)
		lip.position = Vector2(21000, 528)
		var lmat := ShaderMaterial.new()
		lmat.shader = _LAVA_SHADER
		lip.material = lmat
		add_child(lip)

# Lava de modo (chase/coupled). low_y = superfície inicial/congelada (bot).
func _z4_lava(n: String, mode: String, center_x: float, low_y: float, width: float,
		height: float) -> Area2D:
	var a := Area2D.new()
	a.name = n
	a.set_script(_RISING_LAVA)
	a.collision_layer = 0
	a.collision_mask = 2
	a.set("mode", mode)
	a.set("low_y", low_y)
	a.position = Vector2(center_x, low_y)
	var cs := _z2_shape(Vector2(width, height))
	cs.position = Vector2(0, height * 0.5)   # topo da hitbox no y do nó (= superfície)
	a.add_child(cs)
	add_child(a)
	return a

# Escada ascendente de plataformas-degrau (slabs com cara de chão). Cada degrau sobe
# `dy` (≤118) e anda `dx` (≤196) em relação ao anterior. `top0` = topo do 1º degrau.
func _z4_stair(prefix: String, x0: float, top0: float, dx: float, dy: float,
		count: int, step_w: float = 256.0) -> void:
	var x := x0
	var top := top0
	for i in count:
		_z3_static_floor("%s%d" % [prefix, i], Vector2(x + step_w * 0.5, top + 64.0),
			Vector2(step_w, 128.0))   # topo em `top`
		x += dx
		top -= dy

# Debug ?zone=N: pontos de spawn no início de cada zona (calibração do bot).
func _zone_spawn(zone: int) -> Vector2:
	match zone:
		2: return Vector2(3300, 2540)    # zona 2 nova — sobre a Z2Entry (pós shaft ↓)
		3: return Vector2(10800, 2480)   # zona 3 nova — piso de entrada (runway p/ a plataforma)
		4: return Vector2(16320, 2480)   # zona 4 — base da escada-chase
		5: return Vector2(21184, 800)    # boss — dentro da arena
		6: return Vector2(2640, 540)     # DEBUG: shaft ↓ — sobre a Z1Plat4 (testar descida)
		7: return Vector2(18560, 1500)   # DEBUG: patamar do meio da z4
		8: return Vector2(20600, 400)    # DEBUG: topo da escada-coupled (Z4Top)
		_: return Vector2.ZERO           # zona 1 = início normal
