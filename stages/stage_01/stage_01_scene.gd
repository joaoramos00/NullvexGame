# stages/stage_01/stage_01_scene.gd
extends "res://stages/stage_scene.gd"

const _MOVPLAT := preload("res://stages/stage_01/moving_platform.gd")
const _VPLAT   := preload("res://stages/stage_01/vertical_platform.gd")
const _GEYSER  := preload("res://stages/stage_01/geyser.gd")
const _LAVA    := preload("res://stages/stage_01/lava_floor.gd")
const _RISING_LAVA := preload("res://stages/stage_01/rising_lava.gd")
const _LAVA_SHADER := preload("res://stages/stage_01/lava_flow.gdshader")
const _SPIKES_TEX := preload("res://stages/stage_01/spikes.png")
const _FLYER_SCENE := preload("res://characters/enemies/enemy_flyer.tscn")
const _LAVA_TILE := "res://stages/stage_01/Stage_01_lava_v2.png"  # toda lava da fase usa v2 (case-sensitive no PCK web!)
const _Z2_FLOOR_TILE := "res://stages/stage_01/Stage_01T_z2.png"  # mesmo tile do floor
const _ROOM_TILE := preload("res://stages/stage_01/Stage_01T_z1.png")  # rocha escura: câmara do boss
const _Z1_TILE_PATH := "res://stages/stage_01/Stage_01T_z1.png"  # shaft Z4 usa a rocha da zona 1 (lava_override = só visual)
const _DOOR_TEX  := preload("res://stages/door_pixellab.png")
const _CRACKED_WALL := preload("res://stages/stage_01/cracked_wall.gd")
const _COLLECTIBLE_SCENE := preload("res://stages/collectible.tscn")
const _FIRE := {
	"grunt":   preload("res://characters/enemies/stage_01/enemy_magma_grunt.tscn"),
	"ram":     preload("res://characters/enemies/stage_01/enemy_molten_ram.tscn"),
	"hopper":  preload("res://characters/enemies/stage_01/enemy_ash_hopper.tscn"),
	"orbiter": preload("res://characters/enemies/stage_01/enemy_ember_orbiter.tscn"),
	"skimmer": preload("res://characters/enemies/stage_01/enemy_flame_skimmer.tscn"),
	"cinder":  preload("res://characters/enemies/stage_01/enemy_cinder_flyer.tscn"),
	"mortar":  preload("res://characters/enemies/stage_01/enemy_heat_mortar.tscn"),
	"turret":  preload("res://characters/enemies/stage_01/enemy_magma_turret.tscn"),
	"serpent": preload("res://characters/enemies/stage_01/enemy_lava_serpent.tscn"),
}

var _corr_boss: CorridorSection = null

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
		z1lf.set_meta("lava_override", _LAVA_TILE)   # lava de verdade: topo (3,0) + corpo (2,1)
	# Final em vulcão: fora o shaft de wall-kick e o Corridor2 (substituídos pela
	# ascensão da zona 4). Abre um vão no teto do boss p/ a queda da cratera entrar.
	for n in ["ShaftUpWallL", "ShaftUpWallR", "ShaftUpP1", "ShaftUpP2", "ShaftUpP3",
			"ShaftUpP4", "ShaftUpP5", "Corridor2",
			"Z4Floor", "Z4Ceil", "Z4Lava", "Z4Plat1", "Z4Plat2", "Z4Plat3",
			"Z4MovingPlat", "Z4Grunt1", "Z4Grunt2", "Z4Flyer1",
			"BossFloor", "BossWallL", "BossWallR", "BossCeil", "BossLava", "Ignarath"]:
		var node := get_node_or_null(n)
		if node:
			node.queue_free()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	for corr in get_children():
		if corr is CorridorSection and not corr.is_queued_for_deletion():
			corr.setup(_player)
			corr.camera_lock_requested.connect(_on_camera_lock)
	_spawn_fire_roster()

# Arena do boss deslocada -1622 em Y p/ acompanhar o topo do shaft reduzido (y-1026).
# X inalterado. (tscn y=832 − 1622 = −790.)
const _BOSS_L          := 18900.0
const _BOSS_R          := 21716.0
const _BOSS_FLOOR_TOP  := -986.0
const _BOSS_CEIL_TOP   := -1286.0
const _BOSS_DOOR_LO    := -1094.0
const _BOSS_DOOR_HI    := -986.0

const _SHAFT_SEGS := [
	# y_top, y_bot, x_l, x_r  (interior = x_r - x_l)
	# seg0: parede esq é a #1 quebrável do segredo (face 17424, NÃO mover); sem
	# projeção no centro, então 192 basta. Demais segs alargados p/ caber saliências
	# (≥256) e saliência+espinho opostos (≥320). Coluna centrada ~x17520.
	# ATENÇÃO: segs com saliência/espinho têm vão livre EXATAMENTE 192px (= alcance
	# de pulo 196 arredondado à grade, margem zero). Qualquer ±32px num espinho ou
	# foothold deve ser revalidado com test_z4_shaft_dims antes do commit.
	# TRIPLICADO em ambos os eixos: altura ×3 ancorada no fundo y2208 (shaft cresce p/
	# cima até y-3336; bloco boss/pré-boss/segredo-topo deslocado -3696 p/ acompanhar),
	# largura ×3 estendendo a face DIREITA (lado aberto). seg5 (topo) fica estreito:
	# é a boca de saída p/ a sala pré-boss (x17424–17616).
	# Face ESQUERDA fixa em 17424 (a parede esq do shaft é o Z4SecretWR do segredo, que
	# já sela e serve de wall-jump). NÃO há mais Z4ShaftWL (eram redundantes e invadiam
	# o segredo — as "barras laranja" duplicadas). Direita estendida = folga lateral.
	[1284.0,  2208.0, 17424.0, 17712.0],   # entrada (tamanho original restaurado)
	[ 804.0,  1284.0, 17424.0, 17872.0],   # saliência+espinho opostos
	[ 324.0,   804.0, 17424.0, 17792.0],   # saliência (R)
	[-156.0,   324.0, 17424.0, 17872.0],   # saliência+espinho opostos
	[-636.0,  -156.0, 17424.0, 17792.0],   # saliência (R)
	[-1026.0, -636.0, 17424.0, 17520.0],   # topo (boca pré-boss, estreito)
]

# Saliências agarráveis (verde na referência) — wall-grab/jump padrão.
# [nome, wall_x (face real de _SHAFT_SEGS), cy, side ("L"/"R"), h]
const _Z4_FOOTHOLDS := [
	["Z4Foot1", 17424.0, 1044.0, "L", 96.0],    # seg1 esq (face do Z4SecretWR)
	["Z4Foot2", 17792.0,  564.0, "R", 96.0],    # seg2 dir (face reduzida)
	["Z4Foot3", 17424.0,   84.0, "L", 96.0],    # seg3 esq (face do Z4SecretWR)
	["Z4Foot4", 17792.0, -396.0, "R", 96.0],    # seg4 dir (face reduzida)
]

# Espinhos instant-kill (vermelho na referência) — projetam da face da parede.
# [nome, wall_x (face real), cy, side, h]
const _Z4_SPIKES := [
	["Z4SpikeR1", 17872.0, 1044.0, "R", 200.0],    # seg1 dir (face reduzida), opõe Z4Foot1
	["Z4SpikeR3", 17872.0,   84.0, "R", 200.0],    # seg3 dir (face reduzida), opõe Z4Foot3
]

# Plataformas andáveis (amarelo na referência) — rests escalonados, encostados num
# lado deixando vão de wall-jump do outro. [nome, cx, cy(topo), w, h]
const _Z4_PLATFORMS := [
	["Z4Plat1", 17440.0,  924.0, 160.0, 32.0],    # seg1, encostada à esq
	["Z4Plat2", 17712.0,  444.0, 160.0, 32.0],    # seg2, encostada à dir (face reduzida)
	["Z4Plat3", 17440.0,  -36.0, 160.0, 32.0],    # seg3, encostada à esq
	["Z4Plat4", 17712.0, -516.0, 160.0, 32.0],    # seg4, encostada à dir (face reduzida)
	["Z4Plat5", 17472.0, -846.0,  64.0, 32.0],    # seg5 topo (estreita, 64px p/ caber em 96px)
]

# A luta do Ignarath só começa quando o player ENTRA na sala pela porta lateral,
# não por proximidade — senão o boss ataca enquanto o player ainda está no corredor.
# Desliga o auto-aggro por distância e cria um Area2D cobrindo o interior da arena.
# Chamado por _build_z4_boss() após a arena ser construída.
func _setup_boss_room_trigger() -> void:
	var ign := get_node_or_null("Ignarath")
	if ign == null:
		return
	# auto_aggro já foi desligado em _build_z4_boss(); reforça para segurança.
	ign.set("auto_aggro", false)
	# Trigger cobre o interior da nova arena (porta lateral, esquerda).
	# Usa _BOSS_DOOR_LO como topo do gatilho — dispara logo ao entrar pela porta.
	var left  := _BOSS_L + 64.0
	var right := _BOSS_R - 64.0
	var trig_top := _BOSS_DOOR_LO
	var trig_bot := _BOSS_FLOOR_TOP
	var trig := Area2D.new()
	trig.name = "BossRoomTrigger"
	trig.collision_layer = 0
	trig.collision_mask = 2   # camada do player
	trig.position = Vector2((left + right) * 0.5, (trig_top + trig_bot) * 0.5)
	trig.add_child(_z2_shape(Vector2(right - left, trig_bot - trig_top)))
	add_child(trig)
	trig.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBase:
			ign.call("aggro"))

func _on_camera_lock(center: Vector2, zoom: float) -> void:
	$Camera2D.zoom = Vector2(zoom, zoom)
	# câmera volta a seguir o player automaticamente pelo _process herdado

func _draw() -> void:
	super._draw()       # terreno/lava/plataformas (pula o perímetro do boss via skip_base_draw)
	_draw_boss_room()

# Câmara do boss desenhada como grid unificado (molde do stage_00 _draw_boss_room): perímetro
# de rocha (z1) com cantos côncavos corretos em uma passada. A abertura fica na PAREDE ESQUERDA
# — a porta lateral por onde o player entra vindo do corredor pré-boss.
# Mapeamento (screen-space): TL=(3,1) TR=(2,2) BL=(2,0) BR=(1,1),
# teto=(1,2) chão=(3,0) parede_esq=(3,2) parede_dir=(1,0).
func _draw_boss_room() -> void:
	var lwall   := get_node_or_null("BossWallL")  as Node2D
	var rwall   := get_node_or_null("BossWallR")  as Node2D
	var ceil_n  := get_node_or_null("BossCeil")   as Node2D
	var floor_n := get_node_or_null("BossFloor")  as Node2D
	if not (lwall and rwall and ceil_n and floor_n):
		return
	var ts     := _TS
	var src_ts := _SRC_TS
	var left   := lwall.position.x  - ts * 0.5
	var right  := rwall.position.x  + ts * 0.5
	var top    := ceil_n.position.y  - ts * 0.5
	var bottom := floor_n.position.y + ts * 0.5
	var cols := int(round((right - left)   / ts))
	var rows := int(round((bottom - top)   / ts))
	# Abertura da porta na parede esquerda: linhas cobrindo _BOSS_DOOR_LO.._BOSS_DOOR_HI.
	var door_lo := int(ceil((_BOSS_DOOR_LO - top) / ts))
	var door_hi := int(floor((_BOSS_DOOR_HI - top) / ts)) - 1
	for row in rows:
		for col in cols:
			var is_l := col == 0
			var is_r := col == cols - 1
			var is_t := row == 0
			var is_b := row == rows - 1
			if not (is_l or is_r or is_t or is_b):
				continue   # interior vazio
			if is_l and not is_t and not is_b and row >= door_lo and row <= door_hi:
				continue   # abertura da porta lateral
			# Porta encosta no chão? O piso atravessa reto (rente ao corredor), sem canto.
			var door_to_floor := door_hi >= rows - 2
			var bl_is_floor   := is_b and is_l and door_to_floor
			var tile: Vector2i
			# Shifts de meia-célula p/ a face sólida coincidir com a colisão (igual stage_00).
			var tx := 0
			var ty := 0
			if   is_t and is_l:   tile = Vector2i(3, 1); tx =  src_ts; ty =  src_ts
			elif is_t and is_r:   tile = Vector2i(2, 2); tx = -src_ts; ty =  src_ts
			elif bl_is_floor:     tile = Vector2i(3, 0);               ty = -src_ts
			elif is_b and is_l:   tile = Vector2i(2, 0); tx =  src_ts; ty = -src_ts
			elif is_b and is_r:   tile = Vector2i(1, 1); tx = -src_ts; ty = -src_ts
			elif is_t:            tile = Vector2i(1, 2);               ty =  src_ts
			elif is_b:            tile = Vector2i(3, 0);               ty = -src_ts
			elif is_l:            tile = Vector2i(3, 2); tx =  src_ts
			else:                 tile = Vector2i(1, 0); tx = -src_ts
			var dx := left + col * ts + tx
			var dy := top + row * ts + ty
			draw_texture_rect_region(_ROOM_TILE,
				Rect2(dx, dy, ts, ts),
				Rect2(tile.x * src_ts, tile.y * src_ts, src_ts, src_ts))

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
	# Corpo visível alinhado com a superfície de kill (Z2NewLava topo 2700): topo do rect
	# em 2700 (centro 2820 p/ altura 240) → crosta ~2668, logo abaixo das plataformas. Antes
	# ficava em 2840 → havia uma faixa que matava sem mostrar lava (parecia vazio).
	var z2lf := _z2_static("Z2NewLavaFloor", Vector2(6450, 2820), Vector2(7000, 240))
	z2lf.set_meta("lava_override", _LAVA_TILE)  # lava da zona 2: topo (3,0) + corpo (2,1)
	# Corta a lava de fundo nas colunas dos gêiseres → o buraco do piso fica VAZIO (fundo da
	# cena), sem lava aparecendo dentro dele.
	z2lf.set_meta("lava_skip_holes", PackedFloat32Array([5010.0, 5310.0, 6110.0, 6410.0, 6710.0]))
	# Teto + espinhos só na região dos elevadores (perigo ao subir). Teto com tile de
	# fill (igual base do floor) + PNG de espinhos apontando pra baixo.
	var ceil_body := _z2_static("Z2Ceiling", Vector2(5200, 2080), Vector2(1600, 80))
	ceil_body.set_meta("tileset_override", _Z2_FLOOR_TILE)
	_z2_lava("Z2Spikes", Vector2(5200, 2150), Vector2(1600, 60), true)
	_z2_spikes_visual(5200.0, 2120.0, 1600.0)
	# Entrada (saída do shaft) e saída (→ Corredor1) sólidas.
	_z2_static("Z2Entry", Vector2(3350, 2688), Vector2(700, 128))   # x3000–3700 topo 2624
	_z2_static("Z2Exit",  Vector2(8620, 2688), Vector2(2560, 128))  # x7340–9900 topo 2624
	# Rafts horizontais (deslizam na lava; congelam no bot). y2640: fundo (2672) na crosta
	# da lava (~2668) → boiando na lava; topo 2608, ainda 92px acima da superfície que mata (2700).
	_z2_raft("Z2Raft1", Vector2(3940, 2640), Vector2(200, 64), 300.0, 70.0)
	_z2_raft("Z2Raft2", Vector2(4280, 2640), Vector2(200, 64), 300.0, 70.0)
	_z2_raft("Z2Raft3", Vector2(7100, 2640), Vector2(200, 64), 300.0, 70.0)
	# Elevadores de gêiser (sobem da base aos espinhos; congelam na base no bot).
	_z2_elev("Z2Elev1", Vector2(4632, 2592), Vector2(160, 64), 320.0, 60.0)
	_z2_elev("Z2Elev2", Vector2(5740, 2592), Vector2(160, 64), 320.0, 60.0)
	# Ledges sólidos com gêiseres encadeados. floor_holes = x dos gêiseres → o render do
	# piso corta o tile ali e desenha o poço (o vulcão fica dentro do buraco).
	var ledge_med := _z2_static("Z2LedgeMed",  Vector2(5160, 2688), Vector2(700, 128))  # x4810–5510
	ledge_med.set_meta("floor_holes", PackedFloat32Array([5010.0, 5310.0]))
	var ledge_hard := _z2_static("Z2LedgeHard", Vector2(6410, 2688), Vector2(900, 128))  # x5960–6860
	ledge_hard.set_meta("floor_holes", PackedFloat32Array([6110.0, 6410.0, 6710.0]))
	# Médio: 2 gêiseres (timing offset).
	_z2_geyser("Z2GeyMed1", Vector2(5010, 2520), Vector2(64, 200), 1.4, 2.0, 0.0, Vector2(-8, -8))
	_z2_geyser("Z2GeyMed2", Vector2(5310, 2520), Vector2(64, 200), 1.4, 2.0, 1.0, Vector2(14, -8))
	# Difícil: 3 gêiseres em onda (timing mais apertado).
	_z2_geyser("Z2GeyHard1", Vector2(6110, 2520), Vector2(64, 200), 1.2, 1.4, 0.0, Vector2(-22, -8))
	_z2_geyser("Z2GeyHard2", Vector2(6410, 2520), Vector2(64, 200), 1.2, 1.1, 0.8, Vector2(-2, -8))
	_z2_geyser("Z2GeyHard3", Vector2(6710, 2520), Vector2(64, 200), 1.2, 0.85, 1.6, Vector2(18, -8))

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
	var b := AnimatableBody2D.new()   # carrega o player parado (sync_to_physics no script)
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

func _z2_geyser(n: String, center: Vector2, size: Vector2, act: float, inact: float, delay: float, t_off: Vector2 = Vector2.ZERO) -> void:
	var a := Area2D.new()
	a.name = n
	a.set_script(_GEYSER)
	a.collision_layer = 0
	a.collision_mask = 2
	a.set("active_time", act)
	a.set("inactive_time", inact)
	a.set("start_delay", delay)
	a.set("turbine_offset", t_off)
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
# Base → escada-chase (lava perseguindo) → shaft → topo → arena do boss → segredo.
# Lavas congelam no bot.
func _build_zone4() -> void:
	_z3_static_floor("Z4Base", Vector2(16320, 2688), Vector2(320, 128))
	_z4_stair("Z4ChaseStep", 16480.0, 2520.0, 192.0, 104.0, 3, 128.0)   # step0..2 (step3 era redundante c/ Z4ShaftEntry)
	_build_z4_shaft()
	_build_z4_top()
	_build_z4_boss()
	_build_z4_secret()
	# Tile da zona 1 também nas paredes/pisos ESTRUTURAIS do shaft (sem override antes
	# usavam o tile z4 laranja/vulcânico, destoando das paredes de escalada já em z1).
	for n in ["Z4ShaftEntry", "Z4SecretWL", "Z4SecretWR", "Z4SecretFloor",
			"Z4CollectFloorL", "Z4CollectFloorR", "Z4CollectWL", "Z4CollectCeil",
			"Z4PreL", "Z4PreR"]:
		var b := get_node_or_null(n)
		if b:
			b.set_meta("lava_override", _Z1_TILE_PATH)

func _z4_wall(n: String, cx: float, cy: float, w: float, h: float, no_grab := false) -> StaticBody2D:
	var b := _z2_static(n, Vector2(cx, cy), Vector2(w, h))
	b.set_meta("lava_override", _Z1_TILE_PATH)   # rocha da zona 1 (só visual)
	if no_grab:
		b.add_to_group("no_wall_grab")
	return b

# Saliência agarrável (foothold): parede curta agarrável (SEM no_wall_grab) que se
# projeta 1 tile (64px) pra dentro do shaft a partir da face `wall_x` da parede do
# lado `side` ("L" = parede à esquerda, projeta pra direita; "R" = à direita,
# projeta pra esquerda). Mecânica = wall-grab/wall-jump padrão. Ver skill new-foothold.
func _z4_foothold(n: String, wall_x: float, cy: float, side: String, h: float = 96.0) -> StaticBody2D:
	const DEPTH := 64.0
	var cx: float = wall_x + DEPTH * 0.5 if side == "L" else wall_x - DEPTH * 0.5
	var b := _z2_static(n, Vector2(cx, cy), Vector2(DEPTH, h))
	b.set_meta("lava_override", _Z1_TILE_PATH)   # rocha da zona 1 (só visual)
	return b

func _build_z4_shaft() -> void:
	for i in _SHAFT_SEGS.size():
		var s = _SHAFT_SEGS[i]
		var yt: float = s[0]; var yb: float = s[1]; var xl: float = s[2]; var xr: float = s[3]
		var h: float = yb - yt
		var cy: float = (yt + yb) * 0.5
		# Parede ESQUERDA do shaft = Z4SecretWR (montado em _build_z4_secret, x17360–17424):
		# sela o segredo E serve de wall-jump. Não criamos Z4ShaftWL (eram redundantes e
		# invadiam o segredo). Só a parede DIREITA por seg.
		_z4_wall("Z4ShaftWR%d" % i, xr + 32.0, cy, 64.0, h)       # parede direita (grabbable)
	# Piso de ENTRADA: liga o topo da escada (step3, x17056–17184) à boca do shaft,
	# cobrindo o antigo buraco da passagem secreta. O player anda da escada direto pro
	# shaft pelo vão da parede #1 (y2056–2208) e faz wall-jump pra cima. topo y2208.
	_z3_static_floor("Z4ShaftEntry", Vector2(17308.0, 2272.0), Vector2(616.0, 128.0))
	# lava única (chase) cobrindo o shaft
	# Shaft 3× alto → lava sobe até o topo (cap -3200), 3× mais rápido. Largura = seg0
	# (boca de entrada, x17424–18000) pra NÃO vazar além das paredes (z_index=1 renderiza
	# na frente; lava mais larga aparecia como coluna laranja fora da parede).
	var lava := _z4_lava("Z4ShaftLava", "chase", 17568.0, 2360.0, 288.0, 3400.0)
	lava.set("rise_speed", 60.0)
	lava.set("cap_y", -958.0)
	lava.set("accel_y", -102.0)
	lava.set("accel_speed", 110.0)
	# gatilho na ENTRADA do shaft (boca de baixo, dentro da coluna seg0) → a lava só
	# começa a subir quando o player de fato entra no shaft. Antes ela espera parada em
	# low_y (2360), 152px abaixo do piso do shaft (2208), sem aparecer na coluna.
	var trig := Area2D.new()
	trig.name = "Z4ChaseTrigger"
	trig.collision_layer = 0
	trig.collision_mask = 2
	trig.position = Vector2(17568, 2150)
	trig.add_child(_z2_shape(Vector2(288, 116)))
	add_child(trig)
	trig.body_entered.connect(func(b): if b is CharacterBase: lava.call("activate"))
	# Ao morrer, a lava-chase volta ao fundo e desliga (senão respawna já no alto e
	# mata o player em loop). Re-ativa quando ele reentra no Z4ChaseTrigger.
	if is_instance_valid(_player):
		_player.died.connect(func(): lava.call("reset"))
	# Saliências, espinhos e plataformas: tabelas (fonte única, validadas por
	# test_z4_shaft_dims). wall_x das tabelas é uma face real de _SHAFT_SEGS.
	for f in _Z4_FOOTHOLDS:
		_z4_foothold(f[0], f[1], f[2], f[3], f[4])
	for s in _Z4_SPIKES:
		_z4_spike_face(s[0], s[1] + (32.0 if s[3] == "L" else -32.0), s[2], 64.0, s[4], s[3])
	for p in _Z4_PLATFORMS:
		var _old_p := get_node_or_null(p[0])
		if _old_p:
			_old_p.free()   # free imediato: queue_free é deferido e causaria rename silencioso (cf. _z4_spawn_flyer)
		var pb := _z3_static_floor(p[0], Vector2(p[1], p[2] + p[4] * 0.5), Vector2(p[3], p[4]))
		pb.set_meta("lava_override", _Z1_TILE_PATH)   # rocha da zona 1 (só visual)
	# Saliência que desmorona — rest central no limite seg3/seg4 (sem espinho oposto)
	_z4_crumble("Z4Crumble4", Vector2(17632.0, -186.0), Vector2(128.0, 32.0))
	# Flyer no seg5
	_z4_spawn_flyer("Z4Flyer1", Vector2(17632.0, -426.0))

# Espinho no_wall_grab: parede de colisão (no_grab) + Area2D de kill (lava_floor, instant_kill)
# sobrepostos + visual girado da textura da zona 2.
# side "R" = parede direita, espinhos apontam pra esquerda; "L" = esquerda, apontam direita.
func _z4_spike_face(n: String, cx: float, cy: float, w: float, h: float, side: String = "R") -> void:
	_z4_wall(n, cx, cy, w, h, true)   # parede no_grab
	var hurt := Area2D.new()
	hurt.name = n + "Hurt"
	hurt.set_script(_LAVA)
	hurt.collision_layer = 0
	hurt.collision_mask = 2
	hurt.set("instant_kill", true)
	hurt.position = Vector2(cx, cy)
	hurt.add_child(_z2_shape(Vector2(w, h)))
	add_child(hurt)
	# Visual: mesma textura dos espinhos da zona 2 (spikes.png, tips apontando UP).
	# Rotação +PI/2 (90° horário) → tips apontam ESQUERDA (parede "R").
	# Rotação -PI/2 (90° anti-horário) → tips apontam DIREITA (parede "L").
	# region_rect: h*0.5 px de largura (= h px na escala 2) ao longo da parede,
	#              32 px de altura (= 64 px na escala 2) = profundidade do espinho.
	var spr := Sprite2D.new()
	spr.name = n + "Vis"
	spr.texture = _SPIKES_TEX
	spr.centered = true
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0.0, 0.0, h * 0.5, 32.0)
	spr.scale = Vector2(2.0, 2.0)
	spr.rotation = PI * 0.5 if side == "R" else -PI * 0.5
	spr.position = Vector2(cx, cy)
	spr.z_index = 5
	add_child(spr)

# Saliência que desmorona: StaticBody2D com crumbling_ledge.gd + LandDetector no topo.
func _z4_crumble(n: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = n
	body.set_script(preload("res://stages/stage_01/crumbling_ledge.gd"))
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	body.add_child(_z2_shape(size))
	var det := Area2D.new()
	det.name = "LandDetector"
	det.collision_layer = 0
	det.collision_mask = 2
	var ds := _z2_shape(Vector2(size.x, 16.0))
	ds.position = Vector2(0.0, -size.y * 0.5 - 8.0)
	det.add_child(ds)
	det.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBase:
			body.call("touched"))
	body.add_child(det)
	add_child(body)

# Spawna um EnemyFlyer pelo padrão canônico do projeto (preload .tscn + instantiate).
# Remove imediatamente qualquer nó com o mesmo nome antes de adicionar o novo —
# necessário porque queue_free() é deferido e causaria renaming silencioso pelo Godot.
func _z4_spawn_flyer(n: String, pos: Vector2) -> void:
	if DebugBoot.no_enemies:
		return   # respeita ?noenemies=1 / bot (spawn por script ocorre após a remoção do stage_scene)
	assert(_FLYER_SCENE != null, "enemy_flyer.tscn não carregou")
	var old := get_node_or_null(n)
	if old:
		old.free()
	var e: Node2D = _FLYER_SCENE.instantiate()
	e.name = n
	e.position = pos
	add_child(e)

func _spawn_fire(kind: String, n: String, pos: Vector2, face_dir: float = 0.0) -> Node2D:
	if DebugBoot.no_enemies:
		return null
	var old := get_node_or_null(n)
	if old:
		old.free()
	var e: Node2D = _FIRE[kind].instantiate()
	e.name = n
	e.position = pos
	# face_dir só vale p/ a turret (que não vira); setar antes do add_child pois o
	# _ready dela lê face_dir. 0.0 = mantém o default da cena (esquerda).
	if face_dir != 0.0 and kind == "turret":
		e.set("face_dir", face_dir)
	add_child(e)
	return e

# Roster de fogo (~43) — coordenadas derivadas da geometria real das zonas.
# Terrestres ficam sobre pisos andáveis; voadores acima; serpentes sobre a lava.
func _spawn_fire_roster() -> void:
	# Z1 — início (piso SecretArmorFloor topo y2624)
	_spawn_fire("grunt", "F_Z1Grunt1", Vector2(1800, 2560))
	_spawn_fire("grunt", "F_Z1Grunt2", Vector2(2150, 2560))
	_spawn_fire("grunt", "F_Z1Grunt3", Vector2(2550, 2560))
	_spawn_fire("grunt", "F_Z1Grunt4", Vector2(2950, 2560))
	_spawn_fire("hopper", "F_Z1Hop1", Vector2(1950, 2560))
	_spawn_fire("hopper", "F_Z1Hop2", Vector2(2400, 2560))
	_spawn_fire("hopper", "F_Z1Hop3", Vector2(2850, 2560))
	_spawn_fire("cinder", "F_Z1Cin1", Vector2(2000, 2350))
	_spawn_fire("cinder", "F_Z1Cin2", Vector2(2550, 2350))
	_spawn_fire("cinder", "F_Z1Cin3", Vector2(3050, 2350))
	# Z2 — Rio de Lava (ledges topo y2624; lava topo y2700)
	_spawn_fire("ram", "F_Z2Ram1", Vector2(4950, 2560))
	_spawn_fire("ram", "F_Z2Ram2", Vector2(6100, 2560))
	_spawn_fire("ram", "F_Z2Ram3", Vector2(7500, 2560))
	_spawn_fire("turret", "F_Z2Tur1", Vector2(5350, 2560), 1.0)   # vira p/ direita: pega o player depois que passa
	_spawn_fire("turret", "F_Z2Tur2", Vector2(6600, 2560), -1.0)  # vira p/ esquerda: pega na aproximação
	_spawn_fire("turret", "F_Z2Tur3", Vector2(8300, 2560), 1.0)   # vira p/ direita: cobre a saída
	_spawn_fire("orbiter", "F_Z2Orb1", Vector2(5000, 2380))
	_spawn_fire("orbiter", "F_Z2Orb2", Vector2(6300, 2380))
	_spawn_fire("orbiter", "F_Z2Orb3", Vector2(7900, 2380))
	_spawn_fire("serpent", "F_Z2Ser1", Vector2(4250, 2700))
	_spawn_fire("serpent", "F_Z2Ser2", Vector2(7100, 2700))
	# Z3 — maré (passes topo y2624; maré topo y2748)
	_spawn_fire("mortar", "F_Z3Mor1", Vector2(10900, 2560))
	_spawn_fire("mortar", "F_Z3Mor2", Vector2(12550, 2560))
	_spawn_fire("mortar", "F_Z3Mor3", Vector2(14400, 2560))
	_spawn_fire("skimmer", "F_Z3Ski1", Vector2(11600, 2350))
	_spawn_fire("skimmer", "F_Z3Ski2", Vector2(12900, 2350))
	_spawn_fire("skimmer", "F_Z3Ski3", Vector2(14200, 2350))
	_spawn_fire("hopper", "F_Z3Hop1", Vector2(11050, 2560))
	_spawn_fire("hopper", "F_Z3Hop2", Vector2(13050, 2560))
	_spawn_fire("hopper", "F_Z3Hop3", Vector2(14900, 2560))
	_spawn_fire("serpent", "F_Z3Ser1", Vector2(12320, 2748))
	_spawn_fire("serpent", "F_Z3Ser2", Vector2(13280, 2748))
	# Z4 — shaft de wall-jump (voadores no poço; terrestres em pisos/plataformas)
	# Orbitadores: centros dos segs largos (448px=seg1/3, 368px=seg4). Cinder topo no seg5.
	# Grunt3 sobre Z4Plat4 (seg4). Skimmers perto das plataformas de descanso.
	_spawn_fire("cinder",  "F_Z4Cin1",  Vector2(17560, 1284))   # seg0/seg1 boundary
	_spawn_fire("cinder",  "F_Z4Cin2",  Vector2(17560, -216))   # seg4 (yt=-636, yb=-156)
	_spawn_fire("cinder",  "F_Z4Cin3",  Vector2(17472, -750))   # seg5 (yt=-1026, yb=-636)
	_spawn_fire("orbiter", "F_Z4Orb1",  Vector2(17648, 1044))   # seg1 center (448px wide)
	_spawn_fire("orbiter", "F_Z4Orb2",  Vector2(17648,   84))   # seg3 center (448px wide)
	_spawn_fire("orbiter", "F_Z4Orb3",  Vector2(17608, -396))   # seg4 center (368px wide)
	_spawn_fire("grunt",   "F_Z4Grunt1", Vector2(16400, 2540))  # base / escada Z4
	_spawn_fire("grunt",   "F_Z4Grunt2", Vector2(17100, 2140))  # entrada do shaft
	_spawn_fire("grunt",   "F_Z4Grunt3", Vector2(17712, -548))  # seg4, sobre Z4Plat4 (top -516)
	_spawn_fire("skimmer", "F_Z4Ski1",  Vector2(17560, 940))    # seg1, perto de Z4Plat1 (top 924)
	_spawn_fire("skimmer", "F_Z4Ski2",  Vector2(17560, -56))    # seg3, perto de Z4Plat3 (top -36)

func _build_z4_top() -> void:
	# Câmara pré-chefe: piso seco com vão (boca do shaft, seg5 alargado) em x17424–17616.
	# (Task 5 alargou o seg5 topo de x17456–17584 p/ x17424–17616 = 192px; Z4PreL/Z4PreR
	# realinhados pra deixar a boca toda livre, senão o piso pré-boss invadia a subida.)
	# Trecho esquerdo: tampa a parede esquerda do topo do shaft (Z4ShaftWL5, x17360–17424);
	# face direita = x17424 (= face esquerda do interior do seg5).
	# Z4PreL/Z4PreR reusam o helper _z3_static_floor de propósito: piso seco com o
	# mesmo tile/desenho de chão do corredor (não é plataforma elevada, só piso reto).
	_z3_static_floor("Z4PreL", Vector2(17392.0, -1010.0), Vector2(64.0, 128.0))   # x17360–17424 (offset -1622)
	# Trecho direito: começa em x17616 (= face direita do interior do seg5, sobre o
	# Z4ShaftWR5) e segue até a entrada do boss corridor (x17616–18200).
	_z3_static_floor("Z4PreR", Vector2(17860.0, -1010.0), Vector2(680.0, 128.0))  # x17520–18200 (offset -1622)
	# Corredor pré-boss com checkpoint 2 e câmera bloqueada.
	_corr_boss = CorridorSection.new()
	_corr_boss.tileset              = _ROOM_TILE
	_corr_boss.glass_tex            = null       # sem painel de vidro neste corredor
	_corr_boss.door_tex             = _DOOR_TEX
	_corr_boss.floor_center         = Vector2(18530.0, -1002.0)
	_corr_boss.floor_size           = Vector2(660.0, 64.0)
	_corr_boss.ceil_center          = Vector2(18530.0, -1102.0)
	_corr_boss.ceil_size            = Vector2(660.0, 64.0)
	_corr_boss.wall_l_center        = Vector2(18200.0, -1052.0)
	_corr_boss.wall_l_size          = Vector2(64.0, 264.0)
	_corr_boss.wall_r_center        = Vector2(18860.0, -1052.0)
	_corr_boss.wall_r_size          = Vector2(64.0, 264.0)
	_corr_boss.entry_x              = 18260.0
	_corr_boss.exit_x               = 18800.0
	_corr_boss.save_checkpoint      = true
	_corr_boss.checkpoint_index     = 2          # terceiro checkpoint (antes do boss)
	_corr_boss.checkpoint_respawn_x = 18300.0
	_corr_boss.heal_on_entry        = false
	_corr_boss.exit_retriggerable   = true
	_corr_boss.cam_center           = Vector2(18530.0, -1052.0)
	_corr_boss.cam_zoom             = 2.0
	# setup() e conexão do sinal são feitos pelo loop em _ready() (evita double-connect).
	add_child(_corr_boss)

func _build_z4_boss() -> void:
	# Os nós de boss do .tscn foram queue_free()'d em _ready() mas ainda não foram
	# removidos (queue_free é deferido). Libera-os imediatamente antes de criar os novos,
	# senão o Godot renomeia silenciosamente os novos nós ao adicionar com o mesmo nome.
	for bn in ["BossWallL", "BossWallR", "BossFloor", "BossCeil", "BossLava", "Ignarath"]:
		var old := get_node_or_null(bn)
		if old:
			old.free()
	# BossPlat1/2 vêm da .tscn (não rebuildados); acompanham a arena no offset -3696.
	for pn in ["BossPlat1", "BossPlat2"]:
		var bp := get_node_or_null(pn) as Node2D
		if bp:
			bp.position.y -= 1622.0
	# Paredes, piso e teto da arena — marcados skip_base_draw p/ não serem desenhados
	# pelo loop padrão de plataformas; o visual é gerenciado em _draw_boss_room().
	var h := _BOSS_FLOOR_TOP - _BOSS_CEIL_TOP + 64.0
	var cy := (_BOSS_CEIL_TOP + _BOSS_FLOOR_TOP) * 0.5
	# Parede ESQUERDA com PORTA: a colisão cobre só a seção ACIMA da porta (do teto até
	# _BOSS_DOOR_LO). De _BOSS_DOOR_LO (224) até _BOSS_FLOOR_TOP (440) fica VAZIO — é a
	# abertura por onde o player entra na arena vindo do corredor. A face inferior da
	# parede senta exatamente em y=_BOSS_DOOR_LO. (Antes era parede sólida full-height
	# que bloqueava fisicamente a entrada.)
	var lwall_top := _BOSS_CEIL_TOP - 64.0           # = -224 (encosta na borda externa do teto)
	var lwall_h := _BOSS_DOOR_LO - lwall_top         # = 224 - (-224) = 448
	_z2_static("BossWallL", Vector2(_BOSS_L, lwall_top + lwall_h * 0.5),
		Vector2(64.0, lwall_h)).set_meta("skip_base_draw", true)
	_z2_static("BossWallR", Vector2(_BOSS_R, cy), Vector2(64.0, h)).set_meta("skip_base_draw", true)
	_z2_static("BossFloor", Vector2((_BOSS_L + _BOSS_R) * 0.5, _BOSS_FLOOR_TOP + 32.0),
		Vector2(_BOSS_R - _BOSS_L, 64.0)).set_meta("skip_base_draw", true)
	_z2_static("BossCeil", Vector2((_BOSS_L + _BOSS_R) * 0.5, _BOSS_CEIL_TOP - 32.0),
		Vector2(_BOSS_R - _BOSS_L, 64.0)).set_meta("skip_base_draw", true)
	# Soleira de transição corredor→arena: o corredor (Task 7) termina em floor top≈y376 e
	# a arena começa em _BOSS_FLOOR_TOP=440 (64px mais baixo). Este bloco cobre o vão
	# horizontal entre o corredor e a parede esquerda da arena (x18800→18964) e serve como
	# degrau sólido nivelado com o piso da arena — o player desce o degrau ao entrar.
	_z2_static("BossThreshold", Vector2(18882.0, -970.0), Vector2(164.0, 64.0)).set_meta("skip_base_draw", true)
	# Ignarath — respeita ?noenemies=1 / bot (spawn por script ocorre após a remoção do stage_scene)
	if DebugBoot.no_enemies:
		return
	var ign := preload("res://characters/bosses/ignarath.tscn").instantiate()
	ign.name = "Ignarath"
	ign.position = Vector2((_BOSS_L + _BOSS_R) * 0.5, _BOSS_FLOOR_TOP - 80.0)
	ign.set("arena_left",  _BOSS_L + 64.0)
	ign.set("arena_right", _BOSS_R - 64.0)
	ign.set("arena_floor", _BOSS_FLOOR_TOP)
	ign.set("auto_aggro",  false)
	add_child(ign)
	_setup_boss_room_trigger()

# Passagem secreta = coluna azul-clara à ESQUERDA do shaft (referência shaftStage01Zona4.png),
# altura cheia e paralela ao shaft de escalada. Fluxo (atalho de revisita com galerix):
#   1. Parede #1 quebrável (base, lado direito da coluna) — quebra de FORA, pelo lado do shaft
#      (detector "R"); o player no shaft atira pra ESQUERDA e entra no segredo.
#   2. Elevador up_only (Z4SecretElevator, ativa ao pisar) sobe até a câmara do coletável.
#      A Dual Blades da Zara (Z4DualBlades) fica dentro.
#   3. Parede #2 quebrável (topo, lado direito da coluna) — quebra só de DENTRO (detector "L");
#      o player no topo do segredo atira pra direita e sai no TOPO do shaft, perto da sala pré-boss.
# Segredo TOTALMENTE SELADO: as duas paredes quebráveis são as ÚNICAS entradas/saídas;
# WL/WR + tampa de fundo + piso/teto da câmara fecham todo o resto.
# (Coletável = Dual Blades: stage 01 não tem sub-tank — índices 0–3 já usados por 02/04/06/08 —
# e a Dual Blades era o item da tabela que faltava colocar; coração/capacete-Zael já na .tscn.)
func _build_z4_secret() -> void:
	# Parede #1 (INFERIOR) — slot direito da coluna no seg0 do shaft (x17360–17424, y1900–2056).
	# É a entrada do segredo vinda do shaft: quebra de FORA, pelo lado do shaft (detector "R",
	# break_side="right"); o player no shaft atira pra ESQUERDA pra entrar. Exige galerix.
	# A face direita (x17424) encosta na face esquerda do seg0 do shaft. Abaixo dela
	# (y2056–2208) fica o vão de entrada do shaft (ver _build_z4_shaft).
	# Entrada do segredo: parede quebrável que COMEÇA no piso (base y2024 = topo da tampa,
	# topo y1900 = base do WR). Quebra pelo lado do shaft (detector à direita), exige galerix.
	_z4_cracked("Z4Crack1", Vector2(17392.0, 1982.0), Vector2(64.0, 164.0), "right", "R")   # topo y1900, altura 164 (restaurado)
	# Passagem vertical TOTALMENTE FECHADA (interior x17000–17360): paredes lat. + TAMPA no
	# fundo (Z4SecretFloor) selam tudo; só a parede #1 dá acesso. Sem buraco no piso da escada.
	# Coluna: entrada (y1900–2064) inalterada; câmara deslocada p/ y-1042 (shaft 50% menor).
	_z2_static("Z4SecretWL", Vector2(16968.0, 511.0), Vector2(64.0, 3106.0))   # parede esq (y-1042–2064)
	_z2_static("Z4SecretWR", Vector2(17392.0, 429.0), Vector2(64.0, 2942.0))   # parede dir (y-1042–1900; sela + wall-jump esq do shaft)
	_z2_static("Z4SecretFloor", Vector2(17270.0, 2080.0), Vector2(540.0, 32.0)) # tampa do fundo (restaurado)
	# Elevador up_only: descansa SOBRE a tampa (atrás da parede #1) e sobe até o buraco do
	# piso da câmara. Só alcançável depois de quebrar a parede #1.
	var elev := _VPLAT.new()
	elev.name = "Z4SecretElevator"
	elev.up_only = true
	elev.move_distance = 3018.0
	elev.speed = 90.0
	elev.collision_layer = 1
	elev.collision_mask = 0
	elev.position = Vector2(17180.0, 2048.0)   # descansa sobre a tampa (restaurado)
	elev.add_child(_z2_shape(Vector2(192.0, 32.0)))
	add_child(elev)
	# Câmara do coletável: piso x16800–17380 com buraco x17080–17280 (encaixe do elevador).
	# Interior 224px centrado em y=-1098 (= crack2 center): piso top=-986, teto bottom=-1210.
	_z3_static_floor("Z4CollectFloorL", Vector2(16940.0, -922.0), Vector2(280.0, 128.0))
	_z3_static_floor("Z4CollectFloorR", Vector2(17330.0, -922.0), Vector2(100.0, 128.0))
	_z2_static("Z4CollectWL",   Vector2(16768.0, -1082.0), Vector2(64.0, 256.0))   # parede esq (y-1210–-954)
	_z2_static("Z4CollectCeil", Vector2(17090.0, -1242.0), Vector2(580.0, 64.0))   # teto bottom=-1210
	# Coletável: Dual Blades da Zara (WEAPON_ZARA / "dual_blades").
	var col: Area2D = _COLLECTIBLE_SCENE.instantiate()
	col.name = "Z4DualBlades"
	col.set("collectible_type", Collectible.Type.WEAPON_ZARA)
	col.set("ability_id", "dual_blades")
	col.set("stage_id", 1)
	col.position = Vector2(16940.0, -1014.0)
	add_child(col)
	# Parede #2 (SUPERIOR) — slot direito da câmara do coletável.
	# Separa o segredo da sala pré-boss / topo do shaft. Quebra só de DENTRO (detector "L").
	_z4_cracked("Z4Crack2", Vector2(17412.0, -1098.0), Vector2(64.0, 224.0), "left", "L")

# Parede quebrável (cracked_wall.gd): corpo sólido + HitDetector Area2D só no lado
# permitido. det_side "R"/"L" posiciona o detector à direita/esquerda; break_side
# restringe o lado que pode quebrá-la (ambos exigem galerix, ver cracked_wall.gd).
func _z4_cracked(n: String, center: Vector2, size: Vector2, break_side: String, det_side: String) -> void:
	var w := _CRACKED_WALL.new()
	w.name = n
	w.set("break_side", break_side)
	w.collision_layer = 1
	w.collision_mask = 0
	w.position = center
	# Render em modo FILL com tile z1 (escuro), em vez do default "lava" — senão o
	# _draw_lava_tiles desenha min. 7 linhas e o visual transborda ~448px pra baixo da
	# parede (a "parede passável" laranja abaixo do piso). Fill = exatamente o rect.
	w.set_meta("tileset_override", _Z1_TILE_PATH)
	w.add_child(_z2_shape(size))
	var det := Area2D.new()
	det.name = "HitDetector" + det_side
	det.collision_layer = 0
	det.collision_mask = 8   # projéteis (layer 8)
	var dx: float = (size.x * 0.5 + 16.0) * (1.0 if det_side == "R" else -1.0)
	var d := _z2_shape(Vector2(32.0, size.y))
	d.position = Vector2(dx, 0.0)
	det.add_child(d)
	w.add_child(det)
	add_child(w)

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
	a.z_index = 1                            # na frente das plataformas (igual à lava da z3)
	var cs := _z2_shape(Vector2(width, height))
	cs.position = Vector2(0, height * 0.5)   # topo da hitbox no y do nó (= superfície)
	a.add_child(cs)
	add_child(a)
	# Visual: corpo (fill) + crosta (top) tilados, com shader de fluxo (igual à lava da z3).
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
		body.region_rect = Rect2(0, 0, width * 0.5, (height - 64.0) * 0.5)  # *0.5 → scale 2
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
		2: return Vector2(3760, 2480)    # zona 2 — sobre Z2Plat1 (pós shaft ↓)
		3: return Vector2(10800, 2480)   # zona 3 nova — piso de entrada (runway p/ a plataforma)
		4: return Vector2(16320, 2480)   # zona 4 — base da escada-chase
		5: return Vector2(20300, 360)    # boss — dentro da arena reconstruída (x18900–21716)
		6: return Vector2(2640, 540)     # DEBUG: shaft ↓ — sobre a Z1Plat4 (testar descida)
		7: return Vector2(17520, 1100)   # DEBUG: meio do shaft de wall-jump (seg4)
		8: return Vector2(17800, 280)    # DEBUG: topo do shaft / câmara pré-chefe (Z4PreR)
		9: return Vector2(17180, 2120)   # DEBUG: corredor de entrada (sob a tampa do segredo)
		10: return Vector2(17392, 2120)  # DEBUG: vão de entrada do shaft (deve cair no piso, vão aberto)
		11: return Vector2(17500, 2120)  # DEBUG: interior do shaft, base (paredes dos 2 lados)
		_: return Vector2.ZERO           # zona 1 = início normal
