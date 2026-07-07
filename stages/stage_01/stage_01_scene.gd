# stages/stage_01/stage_01_scene.gd
extends "res://stages/stage_scene.gd"

const _MOVPLAT := preload("res://stages/stage_01/moving_platform.gd")
const _VPLAT   := preload("res://stages/stage_01/vertical_platform.gd")
const _GEYSER  := preload("res://stages/stage_01/geyser.gd")
const _LAVA    := preload("res://stages/stage_01/lava_floor.gd")
const _RISING_LAVA := preload("res://stages/stage_01/rising_lava.gd")
const _LAVA_SHADER := preload("res://stages/stage_01/lava_flow.gdshader")
const _SPIKES_TEX := preload("res://stages/stage_01/spikes.png")
const _CHECKPOINT_SCENE := preload("res://stages/checkpoint.tscn")
const _LAVA_TILE := "res://stages/stage_01/Stage_01_lava_v2.png"  # toda lava da fase usa v2 (case-sensitive no PCK web!)
const _Z2_FLOOR_TILE := "res://stages/stage_01/Stage_01T_z2.png"  # mesmo tile do floor
const _ROOM_TILE := preload("res://stages/stage_01/Stage_01T_z1.png")  # rocha escura: câmara do boss
const _Z1_TILE_PATH := "res://stages/stage_01/Stage_01T_z1.png"  # shaft Z4 usa a rocha da zona 1 (lava_override = só visual)
const _DOOR_TEX  := preload("res://stages/door_pixellab.png")
const _CRACKED_WALL := preload("res://stages/stage_01/cracked_wall.gd")
const _COLLECTIBLE_SCENE := preload("res://stages/collectible.tscn")
const _FIRE_WAVE_SCRIPT := preload("res://characters/bosses/ignarath/fire_wave.gd")
const _FIRE_BEAM_SCRIPT := preload("res://characters/bosses/ignarath/fire_beam.gd")
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
var _ignarath: BossBase = null
var _ignarath_spawned := false

func _ready() -> void:
	if StageManager.current_stage_id < 0:
		StageManager.current_stage_id = 1
	super._ready()
	# Morrer não recarrega a cena (só respawn no checkpoint 5, dentro do
	# corredor) — sem isto a câmera ficava travada na sala vazia e o Ignarath
	# continuava existindo (com HP/estado da luta anterior) até o player
	# atravessar de novo. Mesmo padrão de stage_00::_on_player_died_reset.
	_player.died.connect(_on_ignarath_died_reset)
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
	# Tetos desenhados com room-tiles (face (1,2)) em _draw_stage01_ceilings()
	# Só o teto da sala da armadura segue como faixa reta (room-tiles); os tetos
	# das zonas 1-3 viraram massa que segue o terreno (_build_zone_ceilings).
	for ceil_n in ["SecretArmorCeil"]:
		var cn := get_node_or_null(ceil_n)
		if cn:
			cn.set_meta("skip_base_draw", true)
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_zone_ceilings()
	for corr in get_children():
		if corr is CorridorSection and not corr.is_queued_for_deletion():
			corr.setup(_player)
			corr.camera_lock_requested.connect(_on_camera_lock)
	_spawn_fire_roster()
	var shaft_area := get_node_or_null("Z4ShaftCamArea") as Area2D
	if shaft_area:
		shaft_area.body_entered.connect(_on_shaft_body_entered)
		shaft_area.body_exited.connect(_on_shaft_body_exited)
	# Segredo da armadura (capacete Zael): sala x1632–2944 selada pela CrackedWall
	# no lado do corredor de descida — coberta de rocha até a parede quebrar,
	# mesmo padrão do segredo da Z4 (cobre também o coletável e os inimigos de lá).
	var acover: Node2D = preload("res://stages/secret_cover.gd").new()
	acover.name = "ArmorSecretCover"
	acover.tex = _cached_override_tex(_Z1_TILE_PATH)
	acover.z_index = 7
	acover.rects = [Rect2(1632.0, 2208.0, 1312.0, 416.0)]
	add_child(acover)
	var cw := get_node_or_null("CrackedWall")
	if cw:
		cw.connect("wall_destroyed", func():
			if is_instance_valid(acover):
				acover.queue_free())

# Sala do boss = cópia exata das dimensões de Boss_Floor/Ceil/LWall/RWall do
# stage_00 (896×64 piso/teto, 64×512 parede, interior 384px) — mesma largura
# do corredor, piso nivelado com ele (sem degrau). BossPlat1/2 (arena antiga,
# 2816px) foram removidas: não fazem mais sentido numa sala do tamanho padrão.
# _BOSS_L = exit_x do _corr_boss (18864): a porta É a parede, centralizada
# nela — não sobreposta/deslocada. Playtest: a versão anterior (18832) deixava
# a porta visualmente fora do corpo da parede.
const _BOSS_L          := 18864.0
const _BOSS_R          := 19760.0   # _BOSS_L + 896
const _BOSS_FLOOR_TOP  := -1074.0   # = piso do corredor (_corr_boss), sem degrau
const _BOSS_CEIL_TOP   := -1458.0   # interior = -1074 − (−1458) = 384px = 6 tiles
# Deriva do MESMO cálculo que CorridorSection.setup() usa pra calibrar a
# porta do checkpoint (door_cy = floor_top-64; door_height = 200, default
# do CorridorSection) — mesmo padrão do stage_00 (_DOOR_CY/_DOOR_H em
# stage_00_scene.gd:58-59). O vão da parede TEM que bater com o tamanho
# real da porta: um valor solto (-1182, "108px de abertura") deixava a
# parede sólida invadir 56px do espaço onde a porta de verdade opera —
# bug de playtest "wall007 passando um pouco a door004".
const _BOSS_DOOR_CY    := _BOSS_FLOOR_TOP - 64.0   # = door_cy calibrado por setup()
const _BOSS_DOOR_H     := 200.0                    # = door_height (default do CorridorSection)
const _BOSS_DOOR_LO    := _BOSS_DOOR_CY - _BOSS_DOOR_H * 0.5   # topo real da porta (-1238)
const _BOSS_DOOR_HI    := _BOSS_FLOOR_TOP   # porta encosta no chão
# Câmera fixa mostrando a sala inteira (mesmo zoom do stage_00: 1920/2=960 de
# largura visível > 896 de interior; 1080/2=540 de altura > 384 de interior).
const _BOSS_CAM_CENTER := Vector2(19312.0, -1266.0)   # centro de (_BOSS_L+_BOSS_R)/2, (_BOSS_FLOOR_TOP+_BOSS_CEIL_TOP)/2
const _BOSS_CAM_ZOOM    := 2.0

# Shaft Z4 — zigue-zague por BAFFLES (pisos de switchback alternados) num envelope
# CONSTANTE: corpo único de 448px de interior + boca estreita no topo.
#   Face esquerda fixa x17424 = Z4SecretWR (sela o segredo E é parede de escalada;
#   a parede #1 quebrável do segredo fica na base — NÃO mover a face).
#   Face direita fixa x17872 = Z4ShaftWR (corpo); boca x17424–17520 (Z4MouthWR).
# O zigue-zague geométrico vem dos _Z4_BAFFLES: pisos de 256px presos alternadamente
# nas paredes, deixando vão de 192px (= alcance de pulo) no lado oposto — o player
# sobe em S. Envelope constante ⇒ lava única da largura do interior, sem vazamento.
# Qualquer ±32px em elemento deve ser revalidado com test_z4_shaft_dims (o gate
# cobre baffles, tiras de espinho sob baffle, saliências e espinhos de parede).
const _SHAFT_SEGS := [
	# y_top, y_bot, x_l, x_r  (interior = x_r - x_l)
	[ -636.0,  2208.0, 17424.0, 17872.0],   # corpo do shaft (448 de interior)
	[-1026.0,  -636.0, 17424.0, 17520.0],   # boca de saída p/ a sala pré-boss (96)
]

# Parede+plataformas do zigue-zague: [nome, side ("L"/"R"), top_y, espinhos embaixo?]
# Piso pisável de _Z4_WALL_PLAT_DEPTH×32 preso à parede `side` (elemento
# "Parede+Plat" da skill new-wall-element). Cadência ~480px = rests principais
# da subida (o primeiro a 448px da entrada — o trecho morto acabou).
# Espinhos embaixo (1, 2 e 4 = composto "Espinhos Plat"): tira de 128px pendurada
# na parte INTERNA da base — pune abraçar a parede por baixo do rest; os 128px
# junto à parede ficam limpos (zona de montaria).
# Topos SEMPRE ≡ 32 (mod 64): células de junção caem exatas no grid da parede.
const _Z4_WALL_PLAT_DEPTH := 256.0
const _Z4_WALL_PLATS := [
	["Z4WallPlat1", "L", 1760.0, true],    # composto já na 1ª: ensina o espinho embaixo à vista da entrada
	["Z4WallPlat2", "R", 1312.0, true],
	["Z4WallPlat3", "L",  800.0, false],
	["Z4WallPlat4", "R",  352.0, true],
	["Z4WallPlat5", "L", -160.0, false],
]

# Saliências agarráveis — apoios de respiro fora dos baffles.
# [nome, wall_x (face real de _SHAFT_SEGS), cy, side ("L"/"R"), h]
# Alturas em grid global de 64px (topo ≡32 mod 64): junção e face caem exatos.
# Foot3/4/5 = topo dos COMPOSTOS das wall plats 2/3/4 (plat → espinho de 1 tile
# a 2 tiles do topo → saliência flush acima do espinho): o espinho nega o grab
# da parede logo acima do rest; a saliência é o ponto de regrab após o wall-kick.
const _Z4_FOOTHOLDS := [
	["Z4Foot1", 17872.0, 1984.0, "R", 64.0],   # trecho de entrada (antes do WallPlat1); topo 1952
	["Z4Foot2", 17872.0, -320.0, "R", 64.0],   # respiro da reta final; topo -352
	["Z4Foot3", 17872.0, 1088.0, "R", 64.0],   # composto WallPlat2 (topo 1056)
	["Z4Foot4", 17424.0,  576.0, "L", 64.0],   # composto WallPlat3 (topo 544)
	["Z4Foot5", 17872.0,  128.0, "R", 64.0],   # composto WallPlat4 (topo 96)
]

# Espinhos instant-kill nas FACES das paredes — negam a parede errada em cada
# trecho ("a parede certa é a oposta à parede+plat de onde você saiu"). O 1º
# perigo da subida é a tira sob o WallPlat1 (composto), não um espinho de parede.
# Clímax na reta final: L4 nega a esquerda (y-280..-480) e R4 a direita
# (y-476..-636) em bandas escalonadas → troca obrigatória pivotando no Z4Crumble2.
# [nome, wall_x (face real; o helper converte pro centro), cy, side, h]
const _Z4_SPIKES := [
	# Espinhos de 1 tile dos COMPOSTOS (junto à plat, 2 tiles acima do topo =
	# 128px de folga p/ ficar em pé; saliência Foot3/4/5 flush acima de cada um):
	["Z4SpikeR2", 17872.0, 1152.0, "R", 64.0],    # composto WallPlat2 (banda 1120-1184)
	["Z4SpikeL3", 17424.0,  640.0, "L", 64.0],    # composto WallPlat3 (banda 608-672)
	["Z4SpikeR3", 17872.0,  192.0, "R", 64.0],    # composto WallPlat4 (banda 160-224)
	# Reta final (clímax): bandas escalonadas → troca de parede no Z4Crumble2.
	["Z4SpikeL4", 17424.0, -380.0, "L", 200.0],   # reta final ┐
	["Z4SpikeR4", 17872.0, -556.0, "R", 160.0],   # reta final ┘ (flush no teto -636)
]

# Plataformas sólidas avulsas: nenhuma (o apoio da boca, Z4Plat5, foi removido —
# redundante em jogo, os demais rests já viraram baffles).
# [nome, cx, cy(topo), w, h]
const _Z4_PLATFORMS := []

# Crumbles (desmoronam _Z4_CRUMBLE_DELAY após o pouso, respawn 1.2s) — pousos
# transitórios: 1 = estreia isolada da mecânica (ANTES da aceleração da lava,
# uma novidade por vez); 2 = pivô da troca de parede no clímax (entre as bandas
# L4/R4). Delay reduzido de 0.5s (default do script) por playtest — quebrava
# devagar demais.
# [nome, cx, top_y, w]
const _Z4_CRUMBLE_DELAY := 0.35
const _Z4_CRUMBLES := [
	["Z4Crumble1", 17592.0,   76.0, 128.0],   # +32 direita, +16 baixo (playtest)
	["Z4Crumble2", 17648.0, -420.0, 128.0],
]

# Lava-chase: pressão constante; acelera só na reta final (topo do WallPlat5),
# DEPOIS da estreia dos crumbles em y60.
const _Z4_LAVA_RISE_SPEED := 70.0
const _Z4_LAVA_FAST_SPEED := 105.0
const _Z4_LAVA_ACCEL_Y    := -160.0
const _Z4_LAVA_CAP_Y      := -958.0

# A luta do Ignarath só começa quando o player ENTRA na sala (spawn + aggro
# imediato em _on_corr_boss_traversed); este trigger é o BACKUP — mesmo padrão
# do stage_00 (_setup_boss_aggro_trigger), necessário porque o auto-walk da
# porta às vezes para o player um pouco antes do aggro imediato surtir efeito
# em algum caminho de retry. Chamado por _spawn_ignarath() após a arena existir.
func _setup_boss_room_trigger() -> void:
	if not is_instance_valid(_ignarath):
		return
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
		if b is CharacterBase and is_instance_valid(_ignarath):
			_ignarath.aggro())

func _on_camera_lock(center: Vector2, zoom: float) -> void:
	$Camera2D.zoom = Vector2(zoom, zoom)
	# câmera volta a seguir o player automaticamente pelo _process herdado

func _on_shaft_body_entered(body: Node2D) -> void:
	if body == _player and _cam_ctrl != null:
		_cam_ctrl.set_shaft_mode(true)

func _on_shaft_body_exited(body: Node2D) -> void:
	if body == _player and _cam_ctrl != null:
		_cam_ctrl.set_shaft_mode(false)

func _draw() -> void:
	super._draw()       # terreno/lava/plataformas (pula o perímetro do boss via skip_base_draw)
	_draw_boss_room()
	_draw_stage01_ceilings()
	_draw_zone_ceilings()
	_draw_z4_shaft_walls()
	_draw_z4_footholds()
	_draw_z4_wall_plats()

# Saliências do shaft: nub de 1 tile projetando da parede, desenhado num grid de
# MEIA-célula (32 world px = 16 src px, mesma escala 2x do resto). A arte dos tiles
# fica em quadrantes/metades ((0,0) sólido no quadrante inf-esq, faces sólidas em
# meia-largura etc. — medido no PNG), então compomos quadrantes: coluna da parede =
# borda reta (topo/fill/fundo), coluna exposta = cantos convexos arredondados + face.
# Paredes do shaft com COLUNA DE FACE a cavalo da linha de colisão (metade rocha
# dentro do corpo, metade transparente dentro do shaft): a rocha visível fica
# exatamente na colisão E a junção dos elementos pode SUBSTITUIR o tile de face,
# aplicando literalmente a tabela do grupo "Parede" do imgdebug (skill
# new-wall-element). Face esq (3,2) / dir (1,0); miolo (2,1) atrás.
# Extensões espelham os corpos criados em _build_z4_shaft/_build_z4_secret.
func _draw_z4_shaft_walls() -> void:
	var tex := _cached_override_tex(_Z1_TILE_PATH)
	if tex == null:
		return
	# Lado de FORA do shaft: preenchimento com o miolo (2,1), desenhado ANTES
	# das colunas de face. Direita da parede direita até x18192 (além do alcance
	# da câmera travada; -668 = topo do Z4TopCap, sem cobrir a arte dele) e o
	# bolsão morto à direita da boca (entre o teto e o piso da sala pré-boss).
	# O lado esquerdo NÃO é preenchido: é o interior da passagem secreta.
	_z4_fill_rect(tex, Rect2(17872.0, -668.0, 320.0, 3004.0))   # x17872-18192, y-668..2336
	_z4_fill_rect(tex, Rect2(17584.0, -946.0, 608.0, 278.0))    # bolsão da boca, y-946..-668
	# [face_x, y_top, y_bot, side ("L" = parede à esquerda do shaft)]
	for w: Array in [
		[17424.0, -1042.0, 1900.0, "L"],   # Z4SecretWR (corpo + boca, lado esq)
		[17872.0,  -636.0, 2208.0, "R"],   # Z4ShaftWR  (corpo, lado dir)
		[17520.0, -1026.0, -636.0, "R"],   # Z4MouthWR  (boca, lado dir)
	]:
		_z4_draw_wall_face(tex, w[0], w[1], w[2], w[3])

# Retângulo de preenchimento com o miolo (2,1) — rocha sólida fora do shaft.
func _z4_fill_rect(tex: Texture2D, rect: Rect2) -> void:
	var ts := _TS
	var sts := _SRC_TS
	var y := rect.position.y
	while y < rect.end.y:
		var dh := minf(ts, rect.end.y - y)
		var x := rect.position.x
		while x < rect.end.x:
			var dw := minf(ts, rect.end.x - x)
			draw_texture_rect_region(tex, Rect2(x, y, dw, dh),
				Rect2(2.0 * sts, 1.0 * sts, sts * dw / ts, sts * dh / ts))
			x += ts
		y += ts

func _z4_draw_wall_face(tex: Texture2D, face_x: float, y0: float, y1: float, side: String) -> void:
	var ts := _TS
	var sts := _SRC_TS
	var face_src := Rect2(3.0 * sts, 2.0 * sts, sts, sts) if side == "L" \
			else Rect2(1.0 * sts, 0.0, sts, sts)
	var fx: float = face_x - 32.0                                  # coluna de face a cavalo
	var slice_x: float = face_x - ts if side == "L" else face_x + 32.0   # miolo restante (32px)
	# Células no GRID GLOBAL de 64 (yc ≡ 0 mod 64), com clip nas pontas: as
	# células de junção dos elementos (topos ≡ 32 mod 64) caem exatas na grade.
	var yc: float = floorf(y0 / ts) * ts
	while yc < y1:
		var seg_top: float = maxf(yc, y0)
		var seg_bot: float = minf(yc + ts, y1)
		if seg_bot > seg_top:
			var v0: float = (seg_top - yc) / ts * sts
			var sh: float = (seg_bot - seg_top) / ts * sts
			draw_texture_rect_region(tex, Rect2(fx, seg_top, ts, seg_bot - seg_top),
				Rect2(face_src.position + Vector2(0.0, v0), Vector2(sts, sh)))
			draw_texture_rect_region(tex, Rect2(slice_x, seg_top, 32.0, seg_bot - seg_top),
				Rect2(2.0 * sts + 8.0, 1.0 * sts + v0, sts * 0.5, sh))   # fatia do miolo (2,1)
		yc += ts

# Junção côncava SUBSTITUINDO o tile de face na coluna a cavalo, na linha do
# topo e da base do elemento (tabela da skill): esq (2,0)/(3,1); dir (1,1)/(2,2).
# Células centradas nas superfícies (a linha de rocha dos tiles fica no meio da
# célula, como a crosta (3,0) — todos da mesma fileira do tileset se alinham).
func _z4_draw_wall_junction(tex: Texture2D, face_x: float, side: String,
		top: float, bottom: float) -> void:
	var ts := _TS
	var sts := _SRC_TS
	var fx: float = face_x - 32.0
	if side == "L":
		draw_texture_rect_region(tex, Rect2(fx, top - 32.0, ts, ts),
			Rect2(2.0 * sts, 0.0, sts, sts))          # (2,0) topo
		draw_texture_rect_region(tex, Rect2(fx, bottom - 32.0, ts, ts),
			Rect2(3.0 * sts, 1.0 * sts, sts, sts))    # (3,1) base
	else:
		draw_texture_rect_region(tex, Rect2(fx, top - 32.0, ts, ts),
			Rect2(1.0 * sts, 1.0 * sts, sts, sts))    # (1,1) topo
		draw_texture_rect_region(tex, Rect2(fx, bottom - 32.0, ts, ts),
			Rect2(2.0 * sts, 2.0 * sts, sts, sts))    # (2,2) base

func _draw_z4_footholds() -> void:
	var tex := _cached_override_tex(_Z1_TILE_PATH)
	if tex == null:
		return
	for f in _Z4_FOOTHOLDS:
		var side: String = f[3]
		var wall_x: float = f[1]
		var cy: float = f[2]
		var h: float = f[4]
		var x: float = wall_x if side == "L" else wall_x - 64.0
		var top: float = cy - h * 0.5
		_draw_foothold_tiles(Rect2(x, top, 64.0, h), tex, side)
		# Junção substituindo o tile de face na coluna a cavalo (regra da skill).
		_z4_draw_wall_junction(tex, wall_x, side, top, top + h)

func _draw_foothold_tiles(rect: Rect2, tex: Texture2D, side: String) -> void:
	var hs := 32.0   # meia-célula no mundo
	var q  := 16.0   # quadrante no src (metade de _SRC_TS)
	var rows := int(round(rect.size.y / hs))
	# Offsets (px no tileset) do quadrante de cada papel. Cantos convexos: (0,0) quad
	# inf-esq, (1,3) quad inf-dir, (0,2) quad sup-dir, (3,3) quad sup-esq. Faces:
	# (3,2) metade esq (borda à dir), (1,0) metade dir (borda à esq). Retas: (3,0)
	# metade inferior (crosta no topo), (1,2) metade superior (borda embaixo).
	var s_fill := Vector2(2 * 32 + 8, 1 * 32 + 8)   # miolo do fill (2,1)
	var s_top_w: Vector2; var s_top_c: Vector2; var s_face: Vector2
	var s_bot_w: Vector2; var s_bot_c: Vector2
	if side == "L":
		s_top_w = Vector2(3 * 32,      16)            # topo reto: (3,0) quad inf-esq
		s_top_c = Vector2(0,           16)            # canto sup-dir: (0,0) quad inf-esq
		s_face  = Vector2(3 * 32,      2 * 32 + 8)    # face dir: (3,2) metade esq
		s_bot_w = Vector2(1 * 32,      2 * 32)        # fundo reto: (1,2) quad sup-esq
		s_bot_c = Vector2(3 * 32,      3 * 32)        # canto inf-dir: (3,3) quad sup-esq
	else:
		s_top_w = Vector2(3 * 32 + 16, 16)            # topo reto: (3,0) quad inf-dir
		s_top_c = Vector2(1 * 32 + 16, 3 * 32 + 16)   # canto sup-esq: (1,3) quad inf-dir
		s_face  = Vector2(1 * 32 + 16, 8)             # face esq: (1,0) metade dir
		s_bot_w = Vector2(1 * 32 + 16, 2 * 32)        # fundo reto: (1,2) quad sup-dir
		s_bot_c = Vector2(16,          2 * 32)        # canto inf-esq: (0,2) quad sup-dir
	var wall_col := 0 if side == "L" else 1
	for r in rows:
		for c in 2:
			var src: Vector2
			if r == 0:
				src = s_top_w if c == wall_col else s_top_c
			elif r == rows - 1:
				src = s_bot_w if c == wall_col else s_bot_c
			else:
				src = s_fill if c == wall_col else s_face
			draw_texture_rect_region(tex,
				Rect2(rect.position.x + c * hs, rect.position.y + r * hs, hs, hs),
				Rect2(src, Vector2(q, q)))

# Parede+plats desenhadas como plataforma PRESA na parede (tabela da skill
# new-wall-element / grupo "Parede" do imgdebug): fileira de crosta (3,0) com
# ponta arredondada SÓ no lado externo (shim + canto, mesmo padrão do
# _draw_platform_tiles); no lado da parede a crosta encosta reta na face e a
# junção côncava vai na coluna de face — esq: (2,0) topo / (3,1) base;
# dir: (1,1) topo / (2,2) base. Cada lado tem peças próprias, nunca flipar.
func _draw_z4_wall_plats() -> void:
	var tex := _cached_override_tex(_Z1_TILE_PATH)
	if tex == null:
		return
	var ts := _TS
	var sts := _SRC_TS
	var xl: float = _SHAFT_SEGS[0][2]
	var xr: float = _SHAFT_SEGS[0][3]
	for bf in _Z4_WALL_PLATS:
		var side: String = bf[1]
		var top: float = bf[2]
		var x0: float = xl if side == "L" else xr - _Z4_WALL_PLAT_DEPTH
		var cols := int(_Z4_WALL_PLAT_DEPTH / ts)
		# Duas fileiras de arte (tabela do usuário): A = [top-32, top+32] com
		# crosta (3,0) e canto externo (0,0)/(1,3); B = [top+32, top+96] com
		# fundo (1,2) e canto externo (3,3)/(0,2). Rocha visível [top, top+64]
		# = colisão. Células no grid global de 64 (mesmo das paredes).
		for row in 2:
			var dy: float = top - sts + row * ts
			var straight := Vector2(3.0 * sts, 0.0) if row == 0 else Vector2(1.0 * sts, 2.0 * sts)
			var cap: Vector2
			if side == "L":
				cap = Vector2(0.0, 0.0) if row == 0 else Vector2(3.0 * sts, 3.0 * sts)
			else:
				cap = Vector2(1.0 * sts, 3.0 * sts) if row == 0 else Vector2(0.0, 2.0 * sts)
			for c in cols:
				var dx: float = x0 + c * ts
				var outer: bool = (c == cols - 1) if side == "L" else (c == 0)
				if not outer:
					draw_texture_rect_region(tex, Rect2(dx, dy, ts, ts),
						Rect2(straight, Vector2(sts, sts)))
					continue
				if side == "L":
					# ponta à DIREITA: shim (metade dir da reta) + metade esq do canto
					draw_texture_rect_region(tex, Rect2(dx, dy, ts * 0.5, ts),
						Rect2(straight + Vector2(sts * 0.5, 0.0), Vector2(sts * 0.5, sts)))
					draw_texture_rect_region(tex, Rect2(dx + ts * 0.5, dy, ts * 0.5, ts),
						Rect2(cap, Vector2(sts * 0.5, sts)))
				else:
					# ponta à ESQUERDA: canto deslocado meia célula pra fora + shim
					draw_texture_rect_region(tex, Rect2(dx - ts * 0.5, dy, ts, ts),
						Rect2(cap, Vector2(sts, sts)))
					draw_texture_rect_region(tex, Rect2(dx + ts * 0.5, dy, ts * 0.5, ts),
						Rect2(straight, Vector2(sts * 0.5, sts)))
		# Junção substituindo o tile de face na coluna a cavalo (regra da skill):
		# topo em [top-32, top+32], base em [top+32, top+96] — mesmas células
		# das fileiras A/B, encaixe exato no grid da parede.
		_z4_draw_wall_junction(tex, xl if side == "L" else xr, side, top, top + 64.0)

# ─── Tetos das zonas 1-3 no estilo stage 00 ─────────────────────────────────
# Teto que ACOMPANHA o perfil do terreno a folga ~328px (arredondada: superfícies
# em múltiplos de 64 = fim das fileiras da massa bate exato na colisão), com
# aberturas nas transições. Colisão = um StaticBody2D por zona com SegmentShape2D
# (só a superfície inferior — sem paredes invisíveis nos degraus, cf. stage 00);
# visual = massa de rocha até acima do alcance da câmera, marching-squares com
# curvas côncavas (3,1)/(2,2) nos degraus.
# [x0, x1, y_surface, com_colisão] — o trecho 4416-5984 da Z2 é o teto-armadilha
# dos elevadores (Z2Ceiling+Z2Spikes, corpo próprio): a massa só desenha por
# cima dele (até y2048), sem colisão nova.
const _CEIL_SEGS := {
	"Z1": [
		[ 448.0, 1024.0,  576.0, true],    # Plat1 (912)
		[1024.0, 1600.0,  512.0, true],    # MovPlat1 (829) + Plat2 (816)
		[1600.0, 1856.0,  448.0, true],    # MovPlat2 (758)
		[1856.0, 2240.0,  384.0, true],    # Plat3 (720)
		[2240.0, 2944.0,  320.0, true],    # MovPlat3 (629) + Plat4 (624)
		[2944.0, 3328.0,  448.0, true],    # boca do shaft de descida (pinch preservado)
	],
	"Z2": [
		[3328.0, 4416.0, 2304.0, true],    # entrada + rafts (piso 2624)
		[4416.0, 5984.0, 2048.0, false],   # teto-armadilha dos elevadores (corpo próprio)
		[5984.0, 9792.0, 2304.0, true],    # ledges + saída até o Corridor1
	],
	"Z3": [
		[10752.0, 11776.0, 2304.0, true],
		[11776.0, 12352.0, 2240.0, true],  # refúgio Z3Ref12080 (topo 2540) + aberturas
		[12352.0, 12736.0, 2304.0, true],
		[12736.0, 13312.0, 2240.0, true],  # Z3Ref13040
		[13312.0, 13696.0, 2304.0, true],
		[13696.0, 14272.0, 2240.0, true],  # Z3Ref14000
		[14272.0, 16384.0, 2304.0, true],
	],
}
const _CEIL_TOP := { "Z1": 64.0, "Z2": 1728.0, "Z3": 1728.0 }

func _build_zone_ceilings() -> void:
	# Substitui o Z1Ceil reto do .tscn (Z2Ceil/Z3Ceil já eram removidos pelos
	# rebuilds das zonas 2/3).
	var old := get_node_or_null("Z1Ceil")
	if old:
		old.queue_free()
	for zk: String in _CEIL_SEGS:
		var body := StaticBody2D.new()
		body.name = "%sCeilSegs" % zk
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		for s: Array in _CEIL_SEGS[zk]:
			if not (s[3] as bool):
				continue
			var cs := CollisionShape2D.new()
			var sh := SegmentShape2D.new()
			sh.a = Vector2(s[0], s[2])
			sh.b = Vector2(s[1], s[2])
			cs.shape = sh
			body.add_child(cs)

func _ceil_surface_at(zk: String, wx: float) -> float:
	for s: Array in _CEIL_SEGS[zk]:
		if wx >= (s[0] as float) and wx < (s[1] as float):
			return s[2]
	return -1.0   # fora do alcance do teto

func _ceil_solid(zk: String, wx: float, y: float) -> bool:
	var yb := _ceil_surface_at(zk, wx)
	return yb > 0.0 and y < yb

func _draw_zone_ceilings() -> void:
	var ts := _TS
	var sts := _SRC_TS
	for zk: String in _CEIL_SEGS:
		var segs: Array = _CEIL_SEGS[zk]
		var x0f: float = segs[0][0]
		var x1f: float = segs[segs.size() - 1][1]
		var tex := _get_zone_tileset(Vector2((x0f + x1f) * 0.5, segs[0][2]))
		if tex == null:
			continue
		var y_top: float = _CEIL_TOP[zk]
		var x := x0f
		while x < x1f:
			var yb := _ceil_surface_at(zk, x)
			var y := y_top
			while y < yb:
				var ed := not _ceil_solid(zk, x, y + ts)
				var el := not _ceil_solid(zk, x - ts, y)
				var er := not _ceil_solid(zk, x + ts, y)
				var tile: Vector2i
				if   ed and el: tile = Vector2i(0, 2)
				elif ed and er: tile = Vector2i(3, 3)
				elif ed:        tile = Vector2i(1, 2)
				elif el:        tile = Vector2i(1, 0)
				elif er:        tile = Vector2i(3, 2)
				elif not _ceil_solid(zk, x - ts, y + ts): tile = Vector2i(2, 2)
				elif not _ceil_solid(zk, x + ts, y + ts): tile = Vector2i(3, 1)
				else:           tile = Vector2i(2, 1)
				draw_texture_rect_region(tex, Rect2(x, y, ts, ts),
					Rect2(tile.x * sts, tile.y * sts, sts, sts))
				y += ts
			x += ts

# Teto da sala da armadura secreta: tile (1,2) via room-tiles (faixa reta).
func _draw_stage01_ceilings() -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	for n_name in ["SecretArmorCeil"]:
		var node := get_node_or_null(n_name)
		if not is_instance_valid(node):
			continue
		var cs := (node as Node2D).get_node_or_null("CollisionShape2D") as CollisionShape2D
		if not cs or not cs.shape is RectangleShape2D:
			continue
		var size := (cs.shape as RectangleShape2D).size
		var center := (node as Node2D).position + cs.position
		var y_bot := center.y + size.y * 0.5
		_draw_room_tiles(Rect2(center.x - size.x * 0.5, y_bot - ts - src_ts, size.x, ts + src_ts), n_name + "_Ceil")
	# Topo do shaft Z4: Z4CollectCeil (teto da sala secreta) + Z4PreLCeil/Z4PreRCeil
	# (teto da antecâmara pré-boss) — mesma rocha de zona 1 dos tetos do shaft,
	# mesma face (1,2) + preenchimento acima, como um só material (não 3 desenhos
	# diferentes). O vão entre Z4PreLCeil e Z4PreRCeil é a boca do shaft — fica
	# aberto de propósito, não preencher.
	var z1_tex := _cached_override_tex(_Z1_TILE_PATH)
	for n_name in ["Z4CollectCeil", "Z4PreLCeil", "Z4PreRCeil", "Z4ShaftMouthCeil"]:
		var node := get_node_or_null(n_name)
		if not is_instance_valid(node):
			continue
		var cs := (node as Node2D).get_node_or_null("CollisionShape2D") as CollisionShape2D
		if not cs or not cs.shape is RectangleShape2D:
			continue
		var size := (cs.shape as RectangleShape2D).size
		var center := (node as Node2D).position + cs.position
		var y_bot := center.y + size.y * 0.5
		_draw_room_tiles(Rect2(center.x - size.x * 0.5, y_bot - ts - src_ts, size.x, ts + src_ts),
			n_name + "_Ceil", false, z1_tex)

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
	_z2_lava("Z2Spikes", Vector2(5200, 2135), Vector2(1600, 30), true)
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
	# Escala nativa (1x): cada cluster = 32px na tela (metade do tamanho antigo,
	# 64px) — na mesma largura `width`, o dobro de clusters aparece sozinho via
	# texture_repeat, sem precisar contar/posicionar manualmente.
	var spr := Sprite2D.new()
	spr.name = "Z2SpikesVis"
	spr.texture = _SPIKES_TEX
	spr.centered = false
	spr.flip_v = true                                   # espinhos do PNG apontam pra cima → vira pra baixo
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, width, 32)
	spr.scale = Vector2(1, 1)
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
	# Checkpoint na BASE da zona 4 (antes da escada-chase): morrer no shaft custa o
	# shaft, não a fase inteira desde o Corridor1 (x10752). Índice 4 > Corridor1 (1);
	# o corredor pré-boss usa 5 p/ este não re-salvar na volta. Sem cura (regra do projeto).
	var cp: Area2D = _CHECKPOINT_SCENE.instantiate()
	cp.name = "Z4BaseCheckpoint"
	cp.set("checkpoint_index", 4)
	cp.position = Vector2(16320.0, 2496.0)
	var cp_cs := cp.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cp_cs:
		var cp_rect := RectangleShape2D.new()   # shape próprio: o da .tscn é compartilhado
		cp_rect.size = Vector2(64.0, 256.0)     # alto o bastante p/ pegar o player pulando
		cp_cs.shape = cp_rect
	add_child(cp)
	_z4_stair("Z4ChaseStep", 16480.0, 2520.0, 192.0, 104.0, 3, 128.0)   # step0..2 (step3 era redundante c/ Z4ShaftEntry)
	_build_z4_shaft()
	_build_z4_top()
	_build_z4_boss()
	_build_z4_secret()
	# Tile da zona 1 também nas paredes/pisos ESTRUTURAIS do shaft (sem override antes
	# usavam o tile z4 laranja/vulcânico, destoando das paredes de escalada já em z1).
	# Z4SecretWR fica FORA da lista: é a parede esquerda do shaft, desenhada com
	# coluna de face em _draw_z4_shaft_walls (junção substitui o tile de face).
	for n in ["Z4ShaftEntry", "Z4SecretWL", "Z4SecretFloor",
			"Z4CollectFloorL", "Z4CollectFloorR", "Z4CollectWL",
			"Z4PreL", "Z4PreR"]:
		var b := get_node_or_null(n)
		if b:
			b.set_meta("lava_override", _Z1_TILE_PATH)
	var swr := get_node_or_null("Z4SecretWR")
	if swr:
		swr.set_meta("skip_base_draw", true)
	# Z4CollectCeil/Z4PreLCeil/Z4PreRCeil eram 3 tetos desenhados separadamente
	# (modo "lava" genérico, pensado p/ piso — topo+corpo, orientação errada p/ teto).
	# Agora os 3 usam a MESMA rocha de zona 1 e o mesmo desenho de face de teto
	# (1,2) + preenchimento acima via _draw_stage01_ceilings(), como um só material.
	for cn_name in ["Z4CollectCeil", "Z4PreLCeil", "Z4PreRCeil", "Z4ShaftMouthCeil"]:
		var cn := get_node_or_null(cn_name)
		if cn:
			cn.set_meta("skip_base_draw", true)

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
	# skip_base_draw: desenho próprio com cantos convexos em _draw_z4_footholds().
	# O modo "lava" genérico desenhava topo+fill sem cantos e, pelo mínimo de 7
	# linhas, transbordava ~350px de tile abaixo da saliência.
	b.set_meta("skip_base_draw", true)
	return b

func _build_z4_shaft() -> void:
	var body: Array = _SHAFT_SEGS[0]
	var mouth: Array = _SHAFT_SEGS[1]
	var b_yt: float = body[0]; var b_yb: float = body[1]
	var b_xl: float = body[2]; var b_xr: float = body[3]
	var m_yt: float = mouth[0]; var m_xr: float = mouth[3]
	# Parede ESQUERDA = Z4SecretWR (montada em _build_z4_secret, face x17424,
	# y-1042..1900): sela o segredo e cobre todo o corpo do shaft. Abaixo de y1900
	# fica a boca de entrada (vão da parede #1), como sempre foi.
	# Parede DIREITA única do corpo (grabbable) — envelope constante, sem degraus.
	# skip_base_draw: paredes do shaft têm desenho próprio com coluna de face
	# em _draw_z4_shaft_walls (junção dos elementos substitui o tile de face).
	_z4_wall("Z4ShaftWR", b_xr + 32.0, (b_yt + b_yb) * 0.5, 64.0, b_yb - b_yt) \
		.set_meta("skip_base_draw", true)
	# Boca do topo: parede direita própria + teto com abertura à esquerda (a subida
	# termina na face esquerda, que segue reta pra dentro da boca).
	_z4_wall("Z4MouthWR", m_xr + 32.0, (m_yt + b_yt) * 0.5, 64.0, b_yt - m_yt) \
		.set_meta("skip_base_draw", true)
	var cap := _z2_static("Z4TopCap", Vector2((m_xr + b_xr) * 0.5, b_yt - 16.0),
		Vector2(b_xr - m_xr, 32.0))
	cap.add_to_group("no_wall_grab")
	# platform_override, NUNCA lava_override em corpo de 32px (min-7 transborda ~200px)
	cap.set_meta("platform_override", _Z1_TILE_PATH)
	# Piso de ENTRADA: da escada (x17000) até a parede direita do corpo — fecha o
	# fundo do envelope de 448px. topo y2208; entrada pelo vão da parede #1 (y2056–2208).
	_z3_static_floor("Z4ShaftEntry", Vector2((17000.0 + b_xr) * 0.5, 2272.0),
		Vector2(b_xr - 17000.0, 128.0))
	# Lava única (chase) da largura do interior: com o envelope constante nada vaza
	# pelas laterais (acima do teto -636 a sobra fica atrás da sala pré-boss, fora
	# de vista, como no layout antigo).
	var lava := _z4_lava("Z4ShaftLava", "chase", (b_xl + b_xr) * 0.5, 2360.0,
		b_xr - b_xl, 3400.0)
	# Ritmo: 70 px/s pressiona sem alcançar subida limpa (~150-200 px/s de escalada);
	# acelera p/ 105 só na reta final (topo do WallPlat5) — depois da estreia dos crumbles.
	lava.set("rise_speed", _Z4_LAVA_RISE_SPEED)
	lava.set("cap_y", _Z4_LAVA_CAP_Y)
	lava.set("accel_y", _Z4_LAVA_ACCEL_Y)
	lava.set("accel_speed", _Z4_LAVA_FAST_SPEED)
	# gatilho na ENTRADA do shaft → a lava só sobe quando o player entra de fato.
	# Antes ela espera parada em low_y (2360), 152px abaixo do piso (2208).
	var trig := Area2D.new()
	trig.name = "Z4ChaseTrigger"
	trig.collision_layer = 0
	trig.collision_mask = 2
	trig.position = Vector2((b_xl + b_xr) * 0.5, 2150.0)
	trig.add_child(_z2_shape(Vector2(b_xr - b_xl, 116.0)))
	add_child(trig)
	trig.body_entered.connect(func(b): if b is CharacterBase: lava.call("activate"))
	# Ao morrer, a lava-chase volta ao fundo e desliga (senão respawna já no alto e
	# mata o player em loop). Re-ativa quando ele reentra no Z4ChaseTrigger.
	if is_instance_valid(_player):
		_player.died.connect(func(): lava.call("reset"))
	# Elementos do shaft: tabelas (fonte única, validadas por test_z4_shaft_dims).
	for bf in _Z4_WALL_PLATS:
		_z4_wall_plat(bf[0], bf[1], bf[2], bf[3])
	for f in _Z4_FOOTHOLDS:
		_z4_foothold(f[0], f[1], f[2], f[3], f[4])
	for s in _Z4_SPIKES:
		_z4_spike_face(s[0], s[1], s[2], s[4], s[3])
	for p in _Z4_PLATFORMS:
		var _old_p := get_node_or_null(p[0])
		if _old_p:
			_old_p.free()   # free imediato: queue_free é deferido e causaria rename silencioso (cf. _z4_spawn_flyer)
		var pb := _z3_static_floor(p[0], Vector2(p[1], p[2] + p[4] * 0.5), Vector2(p[3], p[4]))
		# Modo PLATFORM com a rocha z1: bordas de ponta (0,0)/(1,3) nas extremidades.
		pb.set_meta("platform_override", _Z1_TILE_PATH)
	for c in _Z4_CRUMBLES:
		_z4_crumble(c[0], Vector2(c[1], c[2] + 16.0), Vector2(c[3], 32.0), _Z4_CRUMBLE_DELAY)

# Parede+plataforma do zigue-zague ("Parede+Plat" da skill new-wall-element):
# piso de switchback preso à parede `side`, deixando vão de (interior − depth)
# = 192px no lado oposto. Com spikes_under vira o composto "Espinhos Plat":
# tira de espinhos presa na parte INTERNA da base (128px), mantendo 128px limpos
# junto à parede — zona de montaria pra subir a parede e pisar sem morrer.
func _z4_wall_plat(n: String, side: String, top_y: float, spikes_under: bool) -> void:
	var xl: float = _SHAFT_SEGS[0][2]
	var xr: float = _SHAFT_SEGS[0][3]
	var x0: float = xl if side == "L" else xr - _Z4_WALL_PLAT_DEPTH
	# Espessura 64px = 2 fileiras de arte (tabela do usuário: topo (3,0)+cantos,
	# base (1,2)+cantos): rocha visível [top, top+64] = colisão, encaixe exato.
	var b := _z2_static(n, Vector2(x0 + _Z4_WALL_PLAT_DEPTH * 0.5, top_y + 32.0),
		Vector2(_Z4_WALL_PLAT_DEPTH, 64.0))
	# Desenho próprio em _draw_z4_wall_plats() (skill new-wall-element): ponta
	# arredondada só no lado EXTERNO + junção substituindo o tile de face.
	b.set_meta("skip_base_draw", true)
	if spikes_under:
		const STRIP := 128.0   # 4 clusters inteiros de spikes.png (32px cada) — nunca cortar
		# Meio tile de recuo no canto EXTERNO (regra da skill: o tile de ponta é
		# ~50% transparente; sem recuo a tira vaza além da rocha visível). A
		# folga extra fica do lado da parede (zona de montaria: 96px limpos).
		var s0: float = x0 + 32.0 if side == "R" \
				else x0 + _Z4_WALL_PLAT_DEPTH - STRIP - 32.0
		# Base embutida na rocha (o PNG tem margem transparente na base;
		# encostada na borda visível os espinhos parecem flutuar) — offset bem
		# maior que o proporcional (24) porque em jogo ainda pareciam altos
		# demais (+8, +30, depois -5 de ajustes de playtest).
		_z4_spikes_under(n + "Spikes", s0, s0 + STRIP, top_y + 57.0)

# Tira de espinhos pendurada na base de uma parede+plat, apontando pra baixo: Area2D
# instant-kill alinhada às pontas (cobre o corpo todo da tira) + visual do PNG
# rotacionado 180° — rects sempre positivos + rotation (NUNCA Rect2 com tamanho
# negativo: no web export o quad aparece duplicado/espelhado).
func _z4_spikes_under(n: String, x0: float, x1: float, top_y: float) -> void:
	const DEPTH := 32.0   # escala nativa (1x): 32px src = 32px na tela
	var hurt := Area2D.new()
	hurt.name = n + "Hurt"
	hurt.set_script(_LAVA)
	hurt.collision_layer = 0
	hurt.collision_mask = 2
	hurt.set("instant_kill", true)
	hurt.position = Vector2((x0 + x1) * 0.5, top_y + DEPTH * 0.5)
	hurt.add_child(_z2_shape(Vector2(x1 - x0, DEPTH)))
	add_child(hurt)
	var spr := Sprite2D.new()
	spr.name = n + "Vis"
	spr.texture = _SPIKES_TEX
	spr.centered = true
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0.0, 0.0, x1 - x0, 32.0)
	spr.scale = Vector2(1.0, 1.0)
	spr.rotation = PI   # tips do PNG (pra cima) viram pra baixo; padrão simétrico
	spr.position = Vector2((x0 + x1) * 0.5, top_y + DEPTH * 0.5)
	spr.z_index = 5
	add_child(spr)

# Espinho no_wall_grab: parede de colisão (no_grab) + Area2D de kill (lava_floor, instant_kill)
# sobrepostos + visual girado da textura da zona 2.
# side "R" = parede direita, espinhos apontam pra esquerda; "L" = esquerda, apontam direita.
# wall_x = FACE da parede (mesma convenção da tabela e do _z4_foothold) — o centro
# do bloco de 32px é calculado AQUI, não no call site.
func _z4_spike_face(n: String, wall_x: float, cy: float, h: float, side: String = "R") -> void:
	var w := 32.0
	# Embute na parede (visual+sólido) — antes ficavam exatamente flush em
	# wall_x, mas o bevel/transparência do tile de face da rocha faz parecer que
	# sobra um vão. cx desloca o bloco todo pra dentro da parede.
	# Lado R ajustado (playtest): +10px pra fora, depois -5px de volta pra
	# perto da parede — embeds não são mais simétricos.
	const _EMBED_L := 8.0
	const _EMBED_R := 13.0
	var cx: float = wall_x + _EMBED_L if side == "L" else wall_x - _EMBED_R
	# skip_base_draw: o bloco de colisão NÃO desenha tiles — o visual do espinho é só
	# o PNG (fundo transparente). Sem isso o modo "lava" desenhava um bloco de rocha
	# atrás dos espinhos e, pelo mínimo de 7 linhas, transbordava ~250px pra baixo.
	_z4_wall(n, cx, cy, w, h, true).set_meta("skip_base_draw", true)
	# Kill um pouco mais largo (40 vs 32 do visual/sólido): numa faixa fina de
	# 32px, o corpo sólido (mesma posição/tamanho) resolve o encosto antes da
	# Area2D registrar overlap real — "encostar não mata". Alargar só o hurt
	# (nunca o visual) garante sobreposição de verdade sem mudar a aparência.
	const HURT_W := 40.0
	var hurt := Area2D.new()
	hurt.name = n + "Hurt"
	hurt.set_script(_LAVA)
	hurt.collision_layer = 0
	hurt.collision_mask = 2
	hurt.set("instant_kill", true)
	hurt.position = Vector2(cx, cy)
	hurt.add_child(_z2_shape(Vector2(HURT_W, h)))
	add_child(hurt)
	# Visual: mesma textura dos espinhos da zona 2 (spikes.png, tips apontando UP).
	# Em Godot 2D rotação POSITIVA é horária (y pra baixo): +PI/2 vira tips pra
	# DIREITA (parede "L") e -PI/2 vira tips pra ESQUERDA (parede "R").
	# region_rect: h px de largura ao longo da parede, 32 px de altura = profundidade
	# do espinho — escala nativa (1x), sem compensação (era h*0.5 na escala 2x).
	var spr := Sprite2D.new()
	spr.name = n + "Vis"
	spr.texture = _SPIKES_TEX
	spr.centered = true
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0.0, 0.0, h, 32.0)
	spr.scale = Vector2(1.0, 1.0)
	spr.rotation = -PI * 0.5 if side == "R" else PI * 0.5
	spr.position = Vector2(cx, cy)
	spr.z_index = 5
	add_child(spr)

# Saliência que desmorona: StaticBody2D com crumbling_ledge.gd + LandDetector no topo.
func _z4_crumble(n: String, center: Vector2, size: Vector2, crumble_delay: float = 0.5) -> void:
	var body := StaticBody2D.new()
	body.name = n
	body.set_script(preload("res://stages/stage_01/crumbling_ledge.gd"))
	body.set("crumble_delay", crumble_delay)
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	# Mesmo desenho das plataformas de descanso (rocha z1 com pontas); o script
	# alterna skip_base_draw junto com a colisão p/ o tile sumir quando desmorona.
	body.set_meta("platform_override", _Z1_TILE_PATH)
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
	# Skimmers desceram 2350→2380: com o teto novo (superfície 2304) o topo da
	# hitbox deles a 2350 encostava na massa; a 2380 sobra folga de ~28px.
	_spawn_fire("skimmer", "F_Z3Ski1", Vector2(11600, 2380))
	_spawn_fire("skimmer", "F_Z3Ski2", Vector2(12900, 2380))
	_spawn_fire("skimmer", "F_Z3Ski3", Vector2(14200, 2380))
	_spawn_fire("hopper", "F_Z3Hop1", Vector2(11050, 2560))
	_spawn_fire("hopper", "F_Z3Hop2", Vector2(13050, 2560))
	_spawn_fire("hopper", "F_Z3Hop3", Vector2(14900, 2560))
	_spawn_fire("serpent", "F_Z3Ser1", Vector2(12320, 2748))
	_spawn_fire("serpent", "F_Z3Ser2", Vector2(13280, 2748))
	# Z4 — shaft de wall-jump: poucos inimigos e intencionais (o perigo principal é
	# lava-chase + espinhos instant-kill; densidade alta virava morte barata por knockback).
	# 5 no shaft + 2 na base/entrada. Um por trecho, guardando um ponto da rota.
	_spawn_fire("cinder",  "F_Z4Cin1",  Vector2(17560, 1284))   # junto ao WallPlat2 (guarda a montaria)
	_spawn_fire("orbiter", "F_Z4Orb1",  Vector2(17648, 1044))   # entre WallPlat2 e WallPlat3
	_spawn_fire("skimmer", "F_Z4Ski1",  Vector2(17700, 890))    # vão da direita, sob o WallPlat3
	_spawn_fire("cinder",  "F_Z4Cin2",  Vector2(17660, 150))    # entre WallPlat4 e o Z4Crumble1
	_spawn_fire("grunt",   "F_Z4Grunt3", Vector2(17520, -192))  # sobre o WallPlat5 (top -160)
	_spawn_fire("grunt",   "F_Z4Grunt1", Vector2(16400, 2540))  # base / escada Z4
	_spawn_fire("grunt",   "F_Z4Grunt2", Vector2(17100, 2140))  # entrada do shaft

func _build_z4_top() -> void:
	# Câmara pré-chefe + corredor, redesenhados pra seguir a mesma disciplina do
	# Corr1 do stage_00 (docs/stage_00/corredor.md): toda medida em múltiplos de
	# 64px, piso/teto contínuos (mesma altura de superfície do início ao fim, sem
	# degrau nem vão) — resolve 3 defeitos do layout anterior: (1) Z4PreL/Z4PreR
	# não tinham teto nenhum ("céu aberto"); (2) o corredor tinha 660×64/64×264,
	# fora da grade de 64 (linha de tile cortada); (3) o piso do corredor estava
	# 40px mais baixo que o do Z4PreR (degrau invisível na transição).
	# Trecho esquerdo: tampa a parede esquerda do topo do shaft (Z4ShaftWL5, x17360–17424).
	_z3_static_floor("Z4PreL", Vector2(17392.0, -1010.0), Vector2(64.0, 128.0))
	_z2_static("Z4PreLCeil", Vector2(17392.0, -1234.0), Vector2(64.0, 64.0))
	# Trecho direito: da boca do shaft (x17520) até a entrada do corredor (x17520–17968,
	# 448px = 7 tiles). Piso topo -1074 = mesma superfície do Z4PreL e do corredor.
	_z3_static_floor("Z4PreR", Vector2(17744.0, -1010.0), Vector2(448.0, 128.0))
	_z2_static("Z4PreRCeil", Vector2(17744.0, -1234.0), Vector2(448.0, 64.0))
	# Teto sobre a boca do shaft (x17424–17520, 96px): só o TETO fecha aqui — o
	# CHÃO continua aberto (Z4PreL/Z4PreR não têm piso nesse trecho), preservando
	# a abertura vertical por onde o player sobe. Une visualmente Z4PreLCeil e
	# Z4PreRCeil numa faixa 100% contínua.
	_z2_static("Z4ShaftMouthCeil", Vector2(17472.0, -1234.0), Vector2(96.0, 64.0))
	# Corredor pré-boss com checkpoint 5 e câmera bloqueada. Mesma largura,
	# altura interior, altura de parede e zoom do Corr1 do stage_00
	# (docs/stage_00/corredor.md) — 896px = 14 tiles, zoom 2.0. Só a posição
	# muda; a "receita" é idêntica, como pedido.
	_corr_boss = CorridorSection.new()
	_corr_boss.tileset              = _ROOM_TILE
	_corr_boss.glass_tex            = null       # sem painel de vidro neste corredor
	_corr_boss.door_tex             = _DOOR_TEX
	_corr_boss.floor_center         = Vector2(18416.0, -1042.0)  # topo -1074 = Z4PreR
	_corr_boss.floor_size           = Vector2(896.0, 64.0)
	_corr_boss.ceil_center          = Vector2(18416.0, -1234.0)  # base -1202 = Z4PreRCeil
	_corr_boss.ceil_size            = Vector2(896.0, 64.0)
	_corr_boss.wall_l_center        = Vector2(17968.0, -1138.0)
	_corr_boss.wall_l_size          = Vector2(64.0, 256.0)
	_corr_boss.wall_r_center        = Vector2(18864.0, -1138.0)
	_corr_boss.wall_r_size          = Vector2(64.0, 256.0)
	_corr_boss.entry_x              = 18000.0
	_corr_boss.exit_x               = 18864.0
	_corr_boss.save_checkpoint      = true
	_corr_boss.checkpoint_index     = 5          # último checkpoint (antes do boss; 5 > 4 da base da Z4 p/ o standalone não re-salvar na volta)
	_corr_boss.checkpoint_respawn_x = 18300.0
	_corr_boss.heal_on_entry        = false
	_corr_boss.exit_retriggerable   = true
	_corr_boss.cam_center           = Vector2(18416.0, -1138.0)
	_corr_boss.cam_zoom             = 2.0
	# setup() e camera_lock_requested são feitos pelo loop genérico em _ready()
	# (evita double-connect); player_traversed é específico deste corredor (spawna
	# o Ignarath só na entrada da sala — ver _on_corr_boss_traversed).
	add_child(_corr_boss)
	_corr_boss.player_traversed.connect(_on_corr_boss_traversed)

func _build_z4_boss() -> void:
	# Os nós de boss do .tscn foram queue_free()'d em _ready() mas ainda não foram
	# removidos (queue_free é deferido). Libera-os imediatamente antes de criar os novos,
	# senão o Godot renomeia silenciosamente os novos nós ao adicionar com o mesmo nome.
	for bn in ["BossWallL", "BossWallR", "BossFloor", "BossCeil", "BossLava",
			"BossThreshold", "BossPlat1", "BossPlat2", "Ignarath"]:
		var old := get_node_or_null(bn)
		if old:
			old.free()
	# Paredes, piso e teto da arena — marcados skip_base_draw p/ não serem desenhados
	# pelo loop padrão de plataformas; o visual é gerenciado em _draw_boss_room().
	# h = interior + 128 (64 de espessura do piso + 64 do teto): a parede cobre
	# do topo do teto até a base do piso, encaixe exato (mesma fórmula do
	# Boss_LWall/RWall do stage_00: interior 384 + 128 = 512).
	var h := _BOSS_FLOOR_TOP - _BOSS_CEIL_TOP + 128.0
	var cy := (_BOSS_CEIL_TOP + _BOSS_FLOOR_TOP) * 0.5
	# Parede ESQUERDA com PORTA: a colisão cobre só a seção ACIMA da porta (do teto até
	# _BOSS_DOOR_LO). De _BOSS_DOOR_LO até _BOSS_DOOR_HI (=_BOSS_FLOOR_TOP) fica VAZIO —
	# é a abertura por onde o player entra na arena vindo do corredor.
	var lwall_top := _BOSS_CEIL_TOP - 64.0
	var lwall_h := _BOSS_DOOR_LO - lwall_top
	_z2_static("BossWallL", Vector2(_BOSS_L, lwall_top + lwall_h * 0.5),
		Vector2(64.0, lwall_h)).set_meta("skip_base_draw", true)
	_z2_static("BossWallR", Vector2(_BOSS_R, cy), Vector2(64.0, h)).set_meta("skip_base_draw", true)
	_z2_static("BossFloor", Vector2((_BOSS_L + _BOSS_R) * 0.5, _BOSS_FLOOR_TOP + 32.0),
		Vector2(_BOSS_R - _BOSS_L, 64.0)).set_meta("skip_base_draw", true)
	_z2_static("BossCeil", Vector2((_BOSS_L + _BOSS_R) * 0.5, _BOSS_CEIL_TOP - 32.0),
		Vector2(_BOSS_R - _BOSS_L, 64.0)).set_meta("skip_base_draw", true)
	# Sem soleira: o piso da arena (_BOSS_FLOOR_TOP=-1074) é nivelado com o piso
	# do corredor — mesma cota, sem degrau (igual ao Corr3→Boss_Floor do stage_00).
	# Ignarath NÃO nasce aqui — só quando o player atravessa _corr_boss (ver
	# _on_corr_boss_traversed / _spawn_ignarath). Isso corrige 2 bugs de playtest:
	# o boss "já estava lá" antes de entrar na sala, e a HUD não pegava a vida
	# dele porque stage_scene.gd::_ready() só conecta bosses que já existem como
	# child NO MOMENTO do super._ready() (chamado bem antes de _build_z4_boss).
	if DebugBoot.zone == 5:
		# zone=5 pula direto pra dentro da arena — simula a travessia aqui, DEPOIS
		# do loop de limpeza acima (senão o Ignarath recém-criado seria destruído).
		if _cam_ctrl != null:
			_cam_ctrl.lock_to(_BOSS_CAM_CENTER, _BOSS_CAM_ZOOM)
			$Camera2D.zoom = Vector2(_BOSS_CAM_ZOOM, _BOSS_CAM_ZOOM)
		_spawn_ignarath()
		if is_instance_valid(_ignarath):
			_ignarath.aggro()

# Player morreu (a cena não recarrega, só respawn no checkpoint 5 dentro do
# corredor): limpa o estado da sala do boss pro respawn voltar com câmera livre
# e sem Ignarath ativo. Ele é recriado do zero (canto direito, HP cheio) quando
# o player atravessa _corr_boss de novo (exit_retriggerable=true).
func _on_ignarath_died_reset() -> void:
	if _cam_ctrl != null:
		_cam_ctrl.unlock()
	if is_instance_valid(_player):
		_player.process_mode = Node.PROCESS_MODE_INHERIT   # caso tenha morrido congelado (boss_aggro)
	if is_instance_valid(_ignarath):
		_ignarath.queue_free()
	_ignarath = null
	_ignarath_spawned = false
	$HUD.hide_boss_bar()
	var old_trig := get_node_or_null("BossRoomTrigger")
	if old_trig:
		old_trig.free()   # imediato: _setup_boss_room_trigger() recria com o mesmo nome no re-spawn
	# Remove ataques do Ignarath que ainda estejam em voo/no chão na sala.
	# Comparação por script (não class_name): scripts novos sem class_name
	# não entram no cache global do headless (ver skip_base_draw/secret_cover.gd).
	for child in get_children():
		if child.get_script() == _FIRE_WAVE_SCRIPT or child.get_script() == _FIRE_BEAM_SCRIPT:
			child.queue_free()

# Chamado quando o player termina de atravessar _corr_boss (sinal player_traversed).
func _on_corr_boss_traversed() -> void:
	if _cam_ctrl != null:
		_cam_ctrl.lock_to(_BOSS_CAM_CENTER, _BOSS_CAM_ZOOM)
		$Camera2D.zoom = Vector2(_BOSS_CAM_ZOOM, _BOSS_CAM_ZOOM)
	_spawn_ignarath()
	if is_instance_valid(_ignarath):
		_ignarath.aggro()

# Cria o Ignarath só na entrada da sala, no canto DIREITO (longe da porta) —
# mesmo padrão de stage_00::_spawn_boss(): wiring completo (player, HUD,
# aggro/intro) feito aqui à mão, já que o boss nasce tarde demais pro loop
# genérico de stage_scene.gd pegar.
func _spawn_ignarath() -> void:
	if DebugBoot.no_enemies or _ignarath_spawned:
		return
	_ignarath_spawned = true
	var ign: BossBase = preload("res://characters/bosses/ignarath.tscn").instantiate()
	ign.name = "Ignarath"
	ign.position = Vector2(_BOSS_R - 192.0, _BOSS_FLOOR_TOP - 80.0)   # canto direito
	ign.player = _player
	ign.arena_left  = _BOSS_L + 64.0
	ign.arena_right = _BOSS_R - 64.0
	ign.arena_floor = _BOSS_FLOOR_TOP
	# arena_top nunca tinha sido setado (default -200 do BossBase) — a onda de
	# fogo vertical (_do_wall_wave) nasce em arena_floor (~-1074) e sobe até
	# despawn_y=arena_top; com -200 ela já nascia "acima" do teto de despawn e
	# sumia no 1º frame de física, quase sem subir. Bug antigo, só ficou visível
	# agora que o boss agrota de verdade.
	ign.arena_top   = _BOSS_CEIL_TOP
	ign.auto_aggro  = false
	add_child(ign)
	_ignarath = ign
	$HUD.connect_to_boss(ign)
	ign.boss_aggro.connect(func():
		_player.velocity = Vector2.ZERO
		_player.process_mode = Node.PROCESS_MODE_DISABLED)
	ign.boss_intro_ended.connect(func():
		_player.process_mode = Node.PROCESS_MODE_INHERIT)
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
	_z4_cracked("Z4Crack2", Vector2(17392.0, -1098.0), Vector2(64.0, 224.0), "left", "L")   # cx 17412→17392: face dir em x17424 (flush c/ parede esq do shaft)
	# Cobertura de rocha sobre TODO o interior (coluna + câmara): o segredo só é
	# revelado quando a parede #1 quebra. O tint das paredes quebráveis fica fora
	# das rects — a pista visual da parede continua visível pelo lado do shaft.
	var cover: Node2D = preload("res://stages/secret_cover.gd").new()
	cover.name = "Z4SecretCover"
	cover.tex = _cached_override_tex(_Z1_TILE_PATH)
	cover.z_index = 7
	cover.rects = [
		Rect2(17000.0, -986.0, 360.0, 3050.0),   # coluna (interior x17000–17360, y-986..2064)
		Rect2(16800.0, -1210.0, 560.0, 224.0),   # câmara do coletável (interior)
	]
	add_child(cover)
	var crack1 := get_node_or_null("Z4Crack1")
	if crack1:
		crack1.connect("wall_destroyed", func():
			if is_instance_valid(cover):
				cover.queue_free())

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
# zone=5 (dentro da arena) simula a travessia do corredor em _build_z4_boss()
# (DEPOIS do loop de limpeza dele — spawnar aqui seria destruído por ele).
func _zone_spawn(zone: int) -> Vector2:
	match zone:
		2: return Vector2(3760, 2480)    # zona 2 — sobre Z2Plat1 (pós shaft ↓)
		3: return Vector2(10800, 2480)   # zona 3 nova — piso de entrada (runway p/ a plataforma)
		4: return Vector2(16320, 2480)   # zona 4 — base da escada-chase
		5: return Vector2(19312, -1174)  # boss — dentro da arena (896px, x18864–19760, piso -1074)
		6: return Vector2(2640, 540)     # DEBUG: shaft ↓ — sobre a Z1Plat4 (testar descida)
		7: return Vector2(17520, 1100)   # DEBUG: meio do shaft de wall-jump (seg4)
		8: return Vector2(17800, -1150)  # DEBUG: topo do shaft / câmara pré-chefe (Z4PreR, piso -1074)
		9: return Vector2(17180, 2120)   # DEBUG: corredor de entrada (sob a tampa do segredo)
		10: return Vector2(17392, 2120)  # DEBUG: vão de entrada do shaft (deve cair no piso, vão aberto)
		11: return Vector2(17500, 2120)  # DEBUG: interior do shaft, base (paredes dos 2 lados)
		_: return Vector2.ZERO           # zona 1 = início normal
