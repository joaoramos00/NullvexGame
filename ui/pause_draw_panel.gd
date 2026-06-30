extends Control

# Fixed stage order — slot 0 = primary (no boss ability), slots 1-8 = bosses 01-08
# boss_id matches GameManager.boss_abilities_unlocked entries
# "" = primary slot (always unlocked)
const _SLOTS: Array = [
	{"boss_id": "",          "label": "PRIMARY",  "elem": "",       "color": Color(0.85, 0.90, 1.00)},
	{"boss_id": "ignarath",  "label": "IGNARATH", "elem": "FOGO",   "color": Color(1.00, 0.35, 0.10)},
	{"boss_id": "cryovex",   "label": "CRYOVEX",  "elem": "GELO",   "color": Color(0.30, 0.85, 1.00)},
	{"boss_id": "voltrix",   "label": "VOLTRIX",  "elem": "RAIO",   "color": Color(1.00, 1.00, 0.20)},
	{"boss_id": "gravitus",  "label": "GRAVITUS", "elem": "GRAV.",  "color": Color(0.75, 0.30, 1.00)},
	{"boss_id": "galerix",   "label": "GALERIX",  "elem": "VENTO",  "color": Color(0.30, 1.00, 0.50)},
	{"boss_id": "umbraex",   "label": "UMBRAEX",  "elem": "SOMBRA", "color": Color(0.60, 0.20, 0.90)},
	{"boss_id": "luxar",     "label": "LUXAR",    "elem": "LUZ",    "color": Color(1.00, 0.95, 0.30)},
	{"boss_id": "terragor",  "label": "TERRAGOR", "elem": "TERRA",  "color": Color(0.70, 0.50, 0.20)},
]

# Layout — 3x3 centred on 1920x1080
const _SW: float = 1920.0
const _SH: float = 1080.0

const _COLS: int   = 3
const _ROWS: int   = 3
const _CW: float   = 520.0
const _CH: float   = 290.0
const _CGAP: float = 14.0

const _GRID_W: float = _COLS * _CW + (_COLS - 1) * _CGAP
const _GRID_H: float = _ROWS * _CH + (_ROWS - 1) * _CGAP
const _GX: float     = (_SW - _GRID_W) * 0.5
const _GY: float     = 108.0

const _STATUS_Y: float = _GY + _GRID_H + 44.0
const _STATUS_X: float = _GX
const _STATUS_W: float = _GRID_W

const _TANK_Y: float   = _STATUS_Y + 110.0
const _TCW: float      = (_GRID_W - 3.0 * _CGAP) * 0.25
const _TCH: float      = 70.0

const _C_BG:       Color = Color(0.00, 0.00, 0.00, 0.88)
const _C_TITLE_BG: Color = Color(0.02, 0.03, 0.14, 1.00)
const _C_BORDER:   Color = Color(0.50, 0.80, 1.00, 1.00)
const _C_TITLE:    Color = Color(0.92, 0.92, 1.00, 1.00)
const _C_LABEL:    Color = Color(0.45, 0.56, 0.78, 1.00)
const _C_LOCKED:   Color = Color(0.06, 0.07, 0.14, 1.00)
const _C_LOCKED_BD:Color = Color(0.18, 0.20, 0.30, 1.00)
const _C_HP_FG:    Color = Color(0.20, 0.95, 0.40, 1.00)
const _C_HP_BG:    Color = Color(0.04, 0.14, 0.07, 1.00)
const _C_LIFE:     Color = Color(1.00, 0.25, 0.35, 1.00)
const _C_TANK:     Color = Color(0.25, 0.62, 1.00, 1.00)

var current_player: Node = null
var sel_idx: int = 0   # index in _get_nav_list() from pause_menu

# Cached textures — never load inside _draw() (breaks web export)
var _placeholder_tex: Texture2D = null
var _bg_tex: Texture2D = null
var _card_frame_tex: Texture2D = null

func _ready() -> void:
	_placeholder_tex = load("res://assets/buster/buster_L1.png")
	_bg_tex = load("res://assets/ui/pause_bg.png")
	_card_frame_tex = load("res://assets/ui/pause_card_pipes.png")

func _draw() -> void:
	var fnt: Font = ThemeDB.fallback_font
	_draw_background()
	draw_rect(Rect2(0.0, 0.0, _SW, 88.0), _C_TITLE_BG)
	draw_line(Vector2(0.0, 88.0), Vector2(_SW, 88.0), _C_BORDER, 2.0)
	draw_string(fnt, Vector2(0.0, 58.0), "— PAUSA —",
			HORIZONTAL_ALIGNMENT_CENTER, _SW, 36, _C_TITLE)
	_draw_power_grid(fnt)
	_draw_status(fnt)
	_draw_subtanks(fnt)

func _draw_background() -> void:
	# Base — dark navy
	draw_rect(Rect2(0.0, 0.0, _SW, _SH), Color(0.02, 0.03, 0.09, 1.00))
	# Imagem gerada (esticada para preencher a tela)
	if _bg_tex != null:
		draw_texture_rect(_bg_tex, Rect2(0.0, 0.0, _SW, _SH), false)
	# Scanlines — linha escura a cada 4px
	var scan_c := Color(0.0, 0.0, 0.0, 0.22)
	var y := 0.0
	while y < _SH:
		draw_line(Vector2(0.0, y), Vector2(_SW, y), scan_c, 2.0)
		y += 4.0
	# Dot grid — pontos azulados a cada 48px
	var dot_c := Color(0.25, 0.50, 0.90, 0.12)
	var gx := 24.0
	while gx < _SW:
		var gy := 24.0
		while gy < _SH:
			draw_rect(Rect2(gx - 1.0, gy - 1.0, 2.0, 2.0), dot_c)
			gy += 48.0
		gx += 48.0
	# Vinheta lateral — escurece as bordas esquerda e direita
	for i: int in 6:
		var a := (1.0 - float(i) / 6.0) * 0.30
		var w := float(6 - i) * 48.0
		draw_rect(Rect2(0.0, 0.0, w, _SH), Color(0.0, 0.0, 0.0, a))
		draw_rect(Rect2(_SW - w, 0.0, w, _SH), Color(0.0, 0.0, 0.0, a))

func _draw_power_grid(fnt: Font) -> void:
	var unlocked: Array = GameManager.boss_abilities_unlocked
	var selected: String = GameManager.selected_boss_ability

	for i: int in 9:
		var slot: Dictionary = _SLOTS[i]
		var col: int  = i % _COLS
		var row: int  = i / _COLS
		var cx: float = _GX + float(col) * (_CW + _CGAP)
		var cy: float = _GY + float(row) * (_CH + _CGAP)
		var bid: String = slot["boss_id"] as String
		var bc: Color   = slot["color"] as Color

		var is_unlocked: bool = true # DEBUG: mostrar todos ativos
		var is_sel: bool = bid == selected

		if is_unlocked:
			if _card_frame_tex != null:
				var alpha := 1.0 if is_sel else 0.80
				draw_texture_rect(_card_frame_tex, Rect2(cx, cy, _CW, _CH), false,
						Color(1.0, 1.0, 1.0, alpha))
			else:
				var bg_mul: float = 0.28 if is_sel else 0.16
				draw_rect(Rect2(cx, cy, _CW, _CH),
						Color(bc.r * bg_mul, bc.g * bg_mul, bc.b * bg_mul, 1.0))
				draw_rect(Rect2(cx, cy, _CW, _CH), bc, false, 3.0 if is_sel else 2.0)
			# Borda rosa externa
			var pink_alpha := 1.0 if is_sel else 0.55
			draw_rect(Rect2(cx - 3.0, cy - 3.0, _CW + 6.0, _CH + 6.0),
					Color(1.0, 0.30, 0.65, pink_alpha), false, 3.0)

			const _PADH: float  = 82.0   # distância lateral
			const _PADV: float  = 62.0   # distância vertical
			const _SPLIT: float = 160.0
			const _SPR: float   = 80.0
			var _spr_zone_w: float = _CW - _PADH - _SPLIT - _PADH
			var _SPR_X: float = _PADH + _SPLIT + (_spr_zone_w - _SPR) * 0.5
			const _SPR_Y: float = _PADV

			# Sprite
			if _placeholder_tex != null:
				var pivot := Vector2(cx + _SPR_X + _SPR * 0.5, cy + _SPR_Y + _SPR * 0.5)
				draw_set_transform(pivot, -PI * 0.5, Vector2.ONE)
				draw_texture_rect_region(_placeholder_tex,
						Rect2(-_SPR * 0.5, -_SPR * 0.5, _SPR, _SPR),
						Rect2(0, 0, 32, 32))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

			# Ammo counter
			if bid != "":
				var ammo: int         = GameManager.get_ability_ammo(bid)
				var max_ammo: int     = GameManager.ABILITY_MAX_AMMO
				var ammo_ratio: float = float(ammo) / float(max_ammo)
				var ammo_col: Color   = bc.lerp(Color(1.0, 0.25, 0.25), 1.0 - ammo_ratio)
				var ammo_str: String  = "%d / %d" % [ammo, max_ammo]
				var pill_x: float = cx + _PADH + _SPLIT + 4.0
				var pill_w: float = _spr_zone_w - 4.0
				var pill_y: float = cy + _SPR_Y + _SPR + 8.0
				draw_rect(Rect2(pill_x, pill_y, pill_w, 26.0), Color(0.0, 0.0, 0.0, 0.55))
				draw_string(fnt, Vector2(pill_x + 4.0, pill_y + 18.0),
						ammo_str, HORIZONTAL_ALIGNMENT_LEFT, pill_w - 8.0, 16, ammo_col)

			# Boss name
			draw_string(fnt, Vector2(cx + _PADH, cy + _PADV + 22.0),
					slot["label"] as String,
					HORIZONTAL_ALIGNMENT_LEFT, _SPLIT, 22,
					Color(bc.r, bc.g, bc.b, 0.80))

			# Elemento / primário
			var elem: String = slot["elem"] as String
			var elem_label: String = elem if elem != "" else \
					("BUSTER" if GameManager.active_character == "zael" else "ESPADA")
			draw_string(fnt, Vector2(cx + _PADH, cy + _CH - _PADV - 4.0),
					elem_label, HORIZONTAL_ALIGNMENT_LEFT, _SPLIT, 28, bc)

			# "ATIVO" badge
			if is_sel:
				draw_string(fnt, Vector2(cx + _PADH, cy + _CH - _PADV - 36.0),
						"▶ ATIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
						Color(bc.r, bc.g, bc.b, 0.70))
		else:
			draw_rect(Rect2(cx, cy, _CW, _CH), _C_LOCKED)
			draw_rect(Rect2(cx, cy, _CW, _CH),
					Color(bc.r * 0.35, bc.g * 0.35, bc.b * 0.35, 1.0), false, 1.5)
			draw_string(fnt, Vector2(cx + 10.0, cy + 26.0),
					slot["label"] as String,
					HORIZONTAL_ALIGNMENT_LEFT, _CW - 20.0, 15,
					Color(bc.r * 0.40, bc.g * 0.40, bc.b * 0.40, 1.0))
			draw_string(fnt, Vector2(cx + _CW * 0.5 - 12.0, cy + _CH * 0.5 + 14.0),
					"?", HORIZONTAL_ALIGNMENT_LEFT, -1, 36,
					Color(bc.r * 0.38, bc.g * 0.38, bc.b * 0.38, 1.0))

	draw_string(fnt, Vector2(_GX, _GY + _GRID_H + 16.0),
			"Q ◀  selecionar habilidade  ▶ E",
			HORIZONTAL_ALIGNMENT_LEFT, _GRID_W, 14, _C_LABEL)

func _draw_status(fnt: Font) -> void:
	var ox: float = _STATUS_X
	var oy: float = _STATUS_Y
	var hp_cur: int = GameManager.max_hp
	var hp_max: int = GameManager.max_hp
	if is_instance_valid(current_player):
		hp_cur = int(current_player.get("current_hp"))
		hp_max = int(current_player.get("max_hp"))

	draw_string(fnt, Vector2(ox, oy + 18.0), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, _C_LABEL)
	var bx: float = ox + 42.0
	var bw: float = _STATUS_W - 120.0
	draw_rect(Rect2(bx, oy, bw, 28.0), _C_HP_BG)
	var fill: float = bw * float(hp_cur) / float(max(hp_max, 1))
	draw_rect(Rect2(bx, oy, fill, 28.0), _C_HP_FG)
	draw_rect(Rect2(bx, oy, bw, 28.0), Color(0.20, 0.70, 0.30, 0.40), false, 1.0)
	draw_string(fnt, Vector2(bx + bw + 10.0, oy + 20.0),
			"%d/%d" % [hp_cur, hp_max], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, _C_TITLE)

	draw_string(fnt, Vector2(ox, oy + 58.0), "VIDAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, _C_LABEL)
	for i: int in GameManager.lives:
		draw_string(fnt, Vector2(ox + 68.0 + float(i) * 36.0, oy + 72.0),
				"❤", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, _C_LIFE)

func _draw_subtanks(fnt: Font) -> void:
	var oy: float = _TANK_Y
	draw_string(fnt, Vector2(_STATUS_X, oy + 18.0), "SUB-TANKS",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, _C_LABEL)
	oy += 28.0
	for i: int in 4:
		var tx: float = _STATUS_X + float(i) * (_TCW + _CGAP)
		var collected: bool  = GameManager.collected_subtanks.has(i)
		var charge: float    = GameManager.subtank_charges[i] if i < GameManager.subtank_charges.size() else 0.0
		var bdr_c: Color     = _C_TANK if collected else _C_LOCKED_BD
		var bg_c: Color      = Color(0.04, 0.10, 0.22, 1.0) if collected else _C_LOCKED
		draw_rect(Rect2(tx, oy, _TCW, _TCH), bg_c)
		draw_rect(Rect2(tx, oy, _TCW, _TCH), bdr_c, false, 2.0)
		draw_string(fnt, Vector2(tx + 8.0, oy + 22.0), "T%d" % (i + 1),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, bdr_c)
		if collected:
			var fill_w: float = (_TCW - 6.0) * charge
			draw_rect(Rect2(tx + 3.0, oy + _TCH - 14.0, _TCW - 6.0, 8.0),
					Color(0.10, 0.22, 0.40, 1.0))
			draw_rect(Rect2(tx + 3.0, oy + _TCH - 14.0, fill_w, 8.0), _C_TANK)
			draw_string(fnt, Vector2(tx + 8.0, oy + _TCH - 17.0),
					"%d%%" % int(charge * 100.0),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.75, 0.90, 1.00))
		else:
			draw_string(fnt, Vector2(tx + _TCW * 0.5 - 8.0, oy + _TCH * 0.5 + 8.0),
					"--", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, _C_LOCKED_BD)
