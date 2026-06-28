extends Node2D

const ZAEL_SCENE := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE := preload("res://characters/melee/zara.tscn")

const _TS     := 64   # tamanho de destino no mundo (game units)
const _SRC_TS := 32   # tamanho do tile no PNG (pixels)

@export var platform_color: Color = Color(0.35, 0.35, 0.35)

var _player: CharacterBase
var _cam_y := 0.0   # Y lazy: atualiza só no chão ou caindo, não durante pulos
var _zone_tilesets: Array[Texture2D] = []
# Override textures must be held by a persistent strong reference. Loading them
# per-frame inside _draw() drops the reference each frame; on web (WebGL2) the
# GPU re-upload can't keep up with that churn and the texture renders pure white.
var _override_tex_cache: Dictionary = {}
var _zone_min: float = 0.0
var _zone_max: float = 1.0
var _zone_use_y: bool = false
# Rect da área visível pela câmera (world-space). Atualizado em _process a cada frame;
# usado em _draw() para pintar o backdrop antes das plataformas.
var _cam_visible_rect := Rect2()

func _ready() -> void:
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")
	_player = _spawn_player()
	_cam_y = _player.global_position.y - _CAM_RISE
	for child in get_children():
		if DebugBoot.no_enemies and (child is EnemyBase or child is BossBase):
			child.queue_free()
			continue
		if child is BossBase:
			child.player = _player
			$HUD.connect_to_boss(child)
			child.boss_aggro.connect(func():
				_player.velocity = Vector2.ZERO
				_player.process_mode = Node.PROCESS_MODE_DISABLED)
			child.boss_intro_ended.connect(func():
				_player.process_mode = Node.PROCESS_MODE_INHERIT)
	_maybe_spawn_bot()
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)
	StageManager.spawn_position = $PlayerSpawn.global_position
	_apply_debug_zone_spawn()
	# No modo bot, câmera mais afastada p/ enxergar o layout ao calibrar o caminho.
	$Camera2D.zoom = Vector2(1.3, 1.3) if DebugBoot.bot_enabled else Vector2(2.0, 2.0)
	AudioManager.play_bgm(AudioLibrary.get_stage_bgm(StageManager.current_stage_id))
	_apply_kill_plane()
	_load_zone_data()
	queue_redraw()

func _apply_kill_plane() -> void:
	# The kill plane must sit below the level's lowest floor. A fixed value would
	# kill the player on legitimately low platforms (e.g. the vertical shaft in
	# stage 01, whose ShaftP3 at y=1700 fell below the old hardcoded KILL_Y=1500).
	var lowest: float = -INF
	for child in get_children():
		if not (child is StaticBody2D or child is AnimatableBody2D):
			continue
		for sc in (child as Node).get_children():
			if sc is CollisionShape2D and (sc as CollisionShape2D).shape is RectangleShape2D:
				var size: Vector2 = ((sc as CollisionShape2D).shape as RectangleShape2D).size
				var bottom: float = (child as Node2D).position.y + (sc as Node2D).position.y + size.y * 0.5
				lowest = maxf(lowest, bottom)
	if lowest > -INF:
		_player.kill_y = maxf(CharacterBase.KILL_Y, lowest + 600.0)

# Câmera sobe um pouco em relação ao player: foco acima dele → o player fica um
# pouco abaixo do centro, mostrando mais à frente/acima (limites do Camera2D ainda clampam).
# Vertical lazy: só atualiza ao pousar ou cair — não segue o pulo para cima.
const _CAM_RISE := 70.0
func _process(delta: float) -> void:
	if is_instance_valid(_player):
		var ty: float = _player.global_position.y - _CAM_RISE
		if _player.is_on_floor():
			_cam_y = lerpf(_cam_y, ty, minf(10.0 * delta, 1.0))
		elif ty > _cam_y:   # caindo: segue para baixo
			_cam_y = lerpf(_cam_y, ty, minf(5.0 * delta, 1.0))
		$Camera2D.global_position = Vector2(_player.global_position.x, _cam_y)
	# Actualiza o rect visível p/ o backdrop do _draw().
	var zoom := $Camera2D.zoom
	var vp   := get_viewport().get_visible_rect().size
	var half := vp / zoom * 0.5
	_cam_visible_rect = Rect2($Camera2D.global_position - half, half * 2.0)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		$PauseMenu.toggle_pause()

func _spawn_player() -> CharacterBase:
	var scene := ZARA_SCENE if GameManager.active_character == "zara" else ZAEL_SCENE
	var p: CharacterBase = scene.instantiate()
	p.global_position = $PlayerSpawn.global_position
	add_child(p)
	# As portas de checkpoint (CorridorSection) abrem via TriggerArea que checa
	# is_in_group("player"); sem este grupo a porta nunca abre (bug stage 01).
	p.add_to_group("player")
	return p

func _load_zone_data() -> void:
	_zone_tilesets.clear()
	var id := StageManager.current_stage_id
	if id < 1 or id > 8:
		return
	for z in range(1, 5):
		var path := "res://stages/stage_%02d/Stage_%02dT_z%d.png" % [id, id, z]
		_zone_tilesets.append(load(path) as Texture2D if ResourceLoader.exists(path) else null)
	if _zone_tilesets.is_empty():
		return
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
	for child in get_children():
		if not child is StaticBody2D:
			continue
		var p: Vector2 = (child as Node2D).position
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	_zone_use_y = (max_y - min_y) > (max_x - min_x)
	_zone_min = min_y if _zone_use_y else min_x
	_zone_max = max_y if _zone_use_y else max_x

func _get_zone_tileset(center: Vector2) -> Texture2D:
	if _zone_tilesets.is_empty():
		return null
	var span := _zone_max - _zone_min
	if span <= 0.0:
		return _zone_tilesets[0]  # may be null — caller handles it
	var t := (center.y - _zone_min) / span if _zone_use_y else (center.x - _zone_min) / span
	var idx := mini(maxi(0, int(t * _zone_tilesets.size())), _zone_tilesets.size() - 1)
	return _zone_tilesets[idx]  # may be null — caller handles it

func _cached_override_tex(path: String) -> Texture2D:
	if _override_tex_cache.has(path):
		return _override_tex_cache[path]
	var t: Texture2D = (load(path) as Texture2D) if ResourceLoader.exists(path) else null
	_override_tex_cache[path] = t
	return t

func _draw() -> void:
	# Backdrop: preenche a área visível com o tile de preenchimento (2,1) da zona atual.
	# Desenhado ANTES das plataformas; as plataformas sobreescrevem com seu tile próprio.
	# Elimina o vazio preto fora das paredes (shaft, laterais de corredores, etc.).
	# Ativo apenas para fases 1-8 (que têm zone_tilesets carregados).
	if not _zone_tilesets.is_empty() and _cam_visible_rect.size.x > 0.0:
		var bdr_tex := _get_zone_tileset(_cam_visible_rect.get_center())
		if bdr_tex:
			# Expande às bordas de tile para não aparecer borda branca.
			var tl := (_cam_visible_rect.position / float(_TS)).floor() * _TS
			var br := (_cam_visible_rect.end   / float(_TS)).ceil()  * _TS
			_draw_fill_tiles(Rect2(tl, br - tl), bdr_tex)
	for child in get_children():
		if not child is StaticBody2D:
			continue
		if child.has_meta("skip_base_draw"):
			continue   # desenhado por um render dedicado (ex.: sala do boss unificada)
		if child.has_meta("fp_params"):
			_draw_fp_node(child)   # peça piso+plataforma (heightfield) — desenho próprio
			continue
		for shape_child in child.get_children():
			if not shape_child is CollisionShape2D:
				continue
			if not shape_child.shape is RectangleShape2D:
				continue
			var size: Vector2 = (shape_child.shape as RectangleShape2D).size
			var center: Vector2 = (child as Node2D).position + (shape_child as Node2D).position
			var rect := Rect2(center - size * 0.5, size)
			var tex: Texture2D = null
			var mode := "lava"   # default: estático sem meta = poça/floor de lava
			if child.has_meta("lava_override"):
				# textura custom desenhada como LAVA (topo tile (3,0) + corpo (2,1))
				tex = _cached_override_tex(child.get_meta("lava_override"))
				mode = "lava"
			elif child.has_meta("tileset_override"):
				tex = _cached_override_tex(child.get_meta("tileset_override"))
				mode = "fill"
			elif child.has_meta("platform_override"):
				tex = _cached_override_tex(child.get_meta("platform_override"))
				mode = "platform"
			if tex == null:
				tex = _get_zone_tileset(center)
			if tex != null:
				match mode:
					"fill":     _draw_fill_tiles(rect, tex)
					"platform": _draw_platform_tiles(rect, tex)
					_:          _draw_lava_tiles(rect, tex, child.get_meta("floor_holes", PackedFloat32Array()), child.get_meta("lava_skip_holes", PackedFloat32Array()))
			else:
				draw_rect(rect, platform_color)

func _draw_fill_tiles(rect: Rect2, tex: Texture2D) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	var cols := ceili(rect.size.x / ts)
	var rows := ceili(rect.size.y / ts)
	var src := Rect2(2 * src_ts, 1 * src_ts, src_ts, src_ts)
	for row in rows:
		for col in cols:
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var dh := minf(ts, rect.position.y + rect.size.y - dy)
			draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh),
				Rect2(src.position, Vector2(src_ts * dw / ts, src_ts * dh / ts)))

func _draw_lava_tiles(rect: Rect2, tex: Texture2D, holes: PackedFloat32Array = PackedFloat32Array(),
		skip_holes: PackedFloat32Array = PackedFloat32Array()) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	var cols := ceili(rect.size.x / ts)
	var phys_rows := ceili(rect.size.y / ts)
	var rows := maxi(phys_rows, 7 if phys_rows >= 2 else 0)
	for row in rows:
		for col in cols:
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts - src_ts
			var dh := minf(float(ts), rect.position.y + rect.size.y - dy) if row < phys_rows else float(ts)
			var dw := minf(float(ts), rect.position.x + rect.size.x - dx)
			var cxw := dx + ts * 0.5
			# skip_holes: corta a coluna por completo (lava de fundo) → fica VAZIO (fundo da cena).
			if _in_hole(cxw, skip_holes):
				continue
			# Buraco: poço 2×2 no piso. Célula do poço = tile da parede (interior transparente
			# = vazio). Abaixo das 2 linhas, o corpo do piso volta.
			var pit := _pit_tile_at(cxw, row, holes)
			if pit.x >= 0:
				draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh),
					Rect2(pit.x * src_ts, pit.y * src_ts, src_ts * dw / ts, src_ts * dh / ts))
				continue
			var tx := (3 * src_ts) if row == 0 else (2 * src_ts)   # piso normal: topo (3,0), corpo (2,1)
			var ty := 0 if row == 0 else src_ts
			draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh),
				Rect2(tx, ty, src_ts * dw / ts, src_ts * dh / ts))

func _in_hole(cxw: float, holes: PackedFloat32Array) -> bool:
	for i in holes.size():
		if absf(cxw - holes[i]) < 64.0:
			return true
	return false

# Tile do poço numa coluna do buraco. Retorna (-1,-1) = não é poço (piso normal);
# senão Vector2i(col,row) do tile no tileset. Poço = só 2 linhas (rows 0-1); abaixo
# volta o corpo do piso (esconde a lava). col esq (cxw<hx): topo (0,0), baixo (2,0) |
# col dir (cxw>=hx): topo (1,3), baixo (1,1).
func _pit_tile_at(cxw: float, row: int, holes: PackedFloat32Array) -> Vector2i:
	if row > 1:
		return Vector2i(-1, -1)
	for i in holes.size():
		if absf(cxw - holes[i]) < 64.0:
			var left := cxw < holes[i]
			if row == 0:
				return Vector2i(0, 0) if left else Vector2i(1, 3)
			return Vector2i(2, 0) if left else Vector2i(1, 1)
	return Vector2i(-1, -1)

func _draw_platform_tiles(rect: Rect2, tex: Texture2D) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	var cols := ceili(rect.size.x / ts)
	var phys_rows := ceili(rect.size.y / ts)
	var rows := maxi(phys_rows, 7 if phys_rows >= 2 else 0)
	for row in rows:
		for col in cols:
			var tile := _tile_at(col, cols, row, rows)
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts - src_ts
			var dh := minf(float(ts), rect.position.y + rect.size.y - dy) if row < phys_rows else float(ts)
			if cols > 1:
				var fill := _gap_fill_tile(row, rows)
				if col == 0:
					dx -= src_ts
					draw_texture_rect_region(tex,
						Rect2(rect.position.x + ts / 2.0, dy, ts / 2.0, dh),
						Rect2(fill.x * src_ts, fill.y * src_ts, src_ts / 2, src_ts))
				elif col == cols - 1:
					dx += src_ts
					draw_texture_rect_region(tex,
						Rect2(rect.position.x + (cols - 1) * ts, dy, ts / 2.0, dh),
						Rect2(fill.x * src_ts + src_ts / 2, fill.y * src_ts, src_ts / 2, src_ts))
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var src := Rect2(tile.x * src_ts, tile.y * src_ts, src_ts * dw / ts, src_ts * dh / ts)
			draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh), src)

func _draw_room_tiles(rect: Rect2, piece_name: String, skip_bottom_corner: bool = false) -> void:
	var ts     := _TS
	var src_ts := _SRC_TS
	var tex: Texture2D = _get_zone_tileset(rect.get_center())
	if tex == null:
		return
	var base_xs := 0
	var base_ys := 0
	if   piece_name.ends_with("_Floor"):                                      base_ys = -src_ts
	elif piece_name.ends_with("_Ceil"):                                       base_ys =  src_ts
	elif piece_name.ends_with("_Wall_L") or piece_name.ends_with("LWall"):   base_xs =  src_ts
	elif piece_name.ends_with("_Wall_R") or piece_name.ends_with("RWall"):   base_xs = -src_ts
	var cols := ceili(rect.size.x / ts)
	var rows := ceili(rect.size.y / ts)
	for row in rows:
		for col in cols:
			var is_left   := col == cols - 1
			var is_right  := col == 0
			var is_top    := row == rows - 1 and not skip_bottom_corner
			var is_bottom := row == 0
			var tile: Vector2i
			if piece_name.ends_with("_Ceil"):
				# base_ys=+src_ts desloca row=1 para fora do rect (dh=0); só row=0 visível.
				if is_left:        tile = Vector2i(3, 3)   # canto inf-dir
				elif is_right:     tile = Vector2i(0, 2)   # canto inf-esq
				else:              tile = Vector2i(1, 2)   # face de teto
			elif piece_name.ends_with("_Wall_L") or piece_name.ends_with("LWall"):
				if is_bottom:      tile = Vector2i(2, 2)
				elif is_top:       tile = Vector2i(1, 1)
				else:              tile = Vector2i(1, 0)
			elif piece_name.ends_with("_Wall_R") or piece_name.ends_with("RWall"):
				if is_bottom:      tile = Vector2i(3, 1)
				elif is_top:       tile = Vector2i(2, 0)
				else:              tile = Vector2i(3, 2)
			else:  # _Floor
				tile = Vector2i(3, 0)
			var tx := base_xs
			var ty := base_ys
			if piece_name.ends_with("_Wall_L") or piece_name.ends_with("LWall"):
				if is_bottom:   ty =  src_ts
				elif is_top:    ty = -src_ts
			elif piece_name.ends_with("_Wall_R") or piece_name.ends_with("RWall"):
				if is_bottom:   ty =  src_ts
				elif is_top:    ty = -src_ts
			var dx := rect.position.x + col * ts + tx
			var dy := rect.position.y + row * ts + ty
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var dh := minf(ts, rect.position.y + rect.size.y - dy)
			var src := Rect2(float(tile.x) * src_ts, float(tile.y) * src_ts, src_ts * dw / ts, src_ts * dh / ts)
			draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh), src)

func _gap_fill_tile(row: int, rows: int) -> Vector2i:
	if row == 0:        return Vector2i(3, 0)  # TOP — linha visual superior
	if row == rows - 1: return Vector2i(1, 2)  # BOTTOM — linha visual inferior
	return Vector2i(2, 1)                       # FILL — interior

func _tile_at(col: int, cols: int, row: int, rows: int) -> Vector2i:
	var is_left   := col == cols - 1
	var is_right  := col == 0
	var is_top    := row == rows - 1
	var is_bottom := row == 0
	if cols == 1:
		if is_top:    return Vector2i(1, 2)
		if is_bottom: return Vector2i(3, 0)
		return Vector2i(2, 1)
	if rows == 1:
		if is_left:  return Vector2i(0, 0)
		if is_right: return Vector2i(1, 3)
		return Vector2i(3, 0)
	if is_top:
		if is_left:  return Vector2i(3, 3)
		if is_right: return Vector2i(0, 2)
		return Vector2i(1, 2)
	if is_bottom:
		if is_left:  return Vector2i(0, 0)
		if is_right: return Vector2i(1, 3)
		return Vector2i(3, 0)
	if is_left:  return Vector2i(3, 2)
	if is_right: return Vector2i(1, 0)
	return Vector2i(2, 1)

# ─── Peça "piso + plataforma" (heightfield) ──────────────────────────────────
# Piso reto + plataforma elevada (sem vão embaixo) + piso reto, como UM bloco só.
# Espelha _fp_solid/_fp_tile de ui/img_debug.gd (modo "Piso+Plat"). Parâmetros via
# meta "fp_params": {left_cols, plat_cols, right_cols, elev_rows, depth_rows,
# left_x, surface_y, tex_path}. Colisão = 2 retângulos (piso + plataforma).
func _fp_solid(c: int, r: int, lc: int, pc: int, er: int, total_c: int, total_r: int, hole: int) -> bool:
	if c < 0 or r < 0 or c >= total_c or r >= total_r:
		return false
	var in_plat: bool = c >= lc and c < lc + pc
	if in_plat:
		return true          # plataforma: sólida do topo (row 0) até a base
	if hole > 0 and c >= lc + pc:
		return false         # buraco à direita: piso direito é abismo (vazio total)
	if hole < 0 and c < lc:
		return false         # buraco à esquerda: piso esquerdo é abismo
	return r >= er           # piso lateral: sólido a partir da superfície (row = elev)

func _fp_tile(c: int, r: int, lc: int, pc: int, er: int, total_c: int, total_r: int, hole: int) -> Vector2i:
	var eu := not _fp_solid(c, r - 1, lc, pc, er, total_c, total_r, hole)
	var ed := not _fp_solid(c, r + 1, lc, pc, er, total_c, total_r, hole)
	var el := not _fp_solid(c - 1, r, lc, pc, er, total_c, total_r, hole)
	var er_x := not _fp_solid(c + 1, r, lc, pc, er, total_c, total_r, hole)
	if eu and el: return Vector2i(1, 3)   # canto sup-esq
	if eu and er_x: return Vector2i(0, 0)  # canto sup-dir
	if ed and el: return Vector2i(0, 2)   # canto inf-esq
	if ed and er_x: return Vector2i(3, 3)  # canto inf-dir
	if eu: return Vector2i(3, 0)          # TOP (superfície)
	if ed: return Vector2i(1, 2)          # BOTTOM
	if el: return Vector2i(1, 0)          # parede esquerda visual
	if er_x: return Vector2i(3, 2)        # parede direita visual
	if not _fp_solid(c - 1, r - 1, lc, pc, er, total_c, total_r, hole): return Vector2i(1, 1)  # entalhe sup-esq
	if not _fp_solid(c + 1, r - 1, lc, pc, er, total_c, total_r, hole): return Vector2i(2, 0)  # entalhe sup-dir
	return Vector2i(2, 1)                  # FILL

func _draw_fp_node(node: Node) -> void:
	var p: Dictionary = node.get_meta("fp_params")
	var tex: Texture2D = _cached_override_tex(p["tex_path"])
	if tex == null:
		return
	var lc: int = p["left_cols"]
	var pc: int = p["plat_cols"]
	var rc: int = p["right_cols"]
	var er: int = p["elev_rows"]
	var dr: int = p["depth_rows"]
	var hole: int = p.get("hole_dir", 0)
	var total_c: int = lc + pc + rc
	var total_r: int = er + dr
	var gx: float = p["left_x"]
	var gy: float = float(p["surface_y"]) - er * _TS   # topo da grade (topo da plataforma)
	var ts := _TS
	var src := _SRC_TS
	for r in total_r:
		for c in total_c:
			if not _fp_solid(c, r, lc, pc, er, total_c, total_r, hole):
				continue
			var t := _fp_tile(c, r, lc, pc, er, total_c, total_r, hole)
			var dx := gx + c * ts
			var dy := gy + r * ts - src   # alinha face sólida superior com a colisão
			draw_texture_rect_region(tex,
				Rect2(dx, dy, ts, ts),
				Rect2(t.x * src, t.y * src, src, src))

# Debug: ?zone=N spawna o player direto no início de uma zona (calibração do bot).
# Cada cena define suas zonas em _zone_spawn(); base retorna ZERO (sem spawn).
func _apply_debug_zone_spawn() -> void:
	if DebugBoot.zone <= 0 or not is_instance_valid(_player):
		return
	var pos := _zone_spawn(DebugBoot.zone)
	if pos == Vector2.ZERO:
		return
	_player.global_position = pos
	StageManager.spawn_position = pos

func _zone_spawn(_zone: int) -> Vector2:
	return Vector2.ZERO

func _maybe_spawn_bot() -> void:
	if not DebugBoot.bot_enabled:
		return
	var bot := preload("res://tests/bot/stage_bot.gd").new()
	bot.name = "StageBot"
	add_child(bot)
