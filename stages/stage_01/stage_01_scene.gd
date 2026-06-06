# stages/stage_01/stage_01_scene.gd
extends "res://stages/stage_scene.gd"

const _MOVPLAT := preload("res://stages/stage_01/moving_platform.gd")
const _VPLAT   := preload("res://stages/stage_01/vertical_platform.gd")
const _GEYSER  := preload("res://stages/stage_01/geyser.gd")
const _LAVA    := preload("res://stages/stage_01/lava_floor.gd")
const _SPIKES_TEX := preload("res://stages/stage_01/spikes.png")
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
	_build_zone2()
	for corr in get_children():
		if corr is CorridorSection:
			corr.setup(_player)
			corr.camera_lock_requested.connect(_on_camera_lock)

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
	_z2_static("Z2NewLavaFloor", Vector2(6450, 2960), Vector2(7000, 240))
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

# Debug ?zone=N: pontos de spawn no início de cada zona (calibração do bot).
func _zone_spawn(zone: int) -> Vector2:
	match zone:
		2: return Vector2(3300, 2540)    # zona 2 nova — sobre a Z2Entry (pós shaft ↓)
		3: return Vector2(11300, 2480)   # zona 3 — sobre Z3Plat1
		4: return Vector2(16960, 816)    # zona 4 — sobre Z4Plat1 (pós shaft ↑)
		5: return Vector2(20160, 740)    # boss — sobre BossPlat1
		6: return Vector2(2640, 540)     # DEBUG: shaft ↓ — sobre a Z1Plat4 (testar descida)
		_: return Vector2.ZERO           # zona 1 = início normal
