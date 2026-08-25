extends Control

const BOSS_NAMES: Dictionary = {
    1: "Ignarath",  2: "Cryovex",  3: "Voltrix",  4: "Gravitus",
    5: "Galerix",   6: "Umbraex",  7: "Luxar",    8: "Terragor",
}

const BOSS_THEMES: Dictionary = {
    1: "Fire",     2: "Ice",      3: "Lightning", 4: "Gravity",
    5: "Wind",     6: "Shadow",   7: "Light",     8: "Earth",
}

const BOSS_WEAKNESS: Dictionary = {
    1: "Galerix (Wind)",     2: "Ignarath (Fire)",  3: "Terragor (Earth)", 4: "Luxar (Light)",
    5: "Gravitus (Gravity)", 6: "Voltrix (Lightning)", 7: "Umbraex (Shadow)", 8: "Cryovex (Ice)",
}

const BOSS_DESCRIPTION: Dictionary = {
    1: "Fire elemental. Molten armor, flaming shoulders. Boss of Volcano Stage.",
    2: "Ice elemental. Crystalline plating, frost breath. Boss of Frozen Peak.",
    3: "Lightning elemental. Electric coils and sparking gauntlets. Boss of Storm Tower.",
    4: "Gravity elemental. Heavy titan with orbital energy. Boss of Void Depths.",
    5: "Wind elemental. Sleek aerodynamic frame. Boss of Skyward Ridge.",
    6: "Shadow elemental. Phantom armor with tendrils. Boss of Umbral Vault.",
    7: "Light elemental. Radiant halo core. Boss of Solar Citadel.",
    8: "Earth elemental. Stone-plated golem. Boss of Deep Mines.",
}

# Path do portrait derivado do nome do boss (lowercase).
const _PORTRAIT_PATH_FMT := "res://characters/bosses/%s/%s_portrait.png"

# Sprites pra HUD de HEARTS · SUB-TANKS no corner BR — sprites únicos 256×256.
const _HEART_TEX := preload("res://characters/pickups/heart_tank.png")
const _TANK_TEX := preload("res://characters/pickups/subtank.png")
const _HP_BAR_SCRIPT := preload("res://ui/hp_bar.gd")
const _ICON_SIZE := Vector2(48, 48)
const _DIMMED := Color(1, 1, 1, 0.20)
const _BRIGHT := Color(1, 1, 1, 1)
# Regras fiéis ao HUD do jogo (ui/hud.gd::_update_bar_height).
# Bar height = max_hp * _HP_PER_PIXEL; largura fixa 40px.
# _HP_PER_PIXEL mantido em sync com ui/hud.gd (12.0).
const _HP_BAR_WIDTH := 40
const _HP_PER_PIXEL := 12.0

static func _heart_icon() -> Texture2D:
    return _HEART_TEX

static func _tank_icon() -> Texture2D:
    return _TANK_TEX

# Mapa índice de célula (0..15 no grid 4x4) → o que essa célula representa.
# CENTER: 5, 6, 9, 10 são fillers vazios ocultos pelo painel central sobreposto.
enum CellKind { EMPTY, BOSS, CORNER_ZAEL_SHOTS, CORNER_ZARA_WEAPONS, CORNER_ARMOR, CORNER_HEARTS }

## Grid 6 colunas × 3 linhas = 18 cells. Row 1 (índices 6-11) são fillers ocultos
## pelo CenterInfo (painel horizontal wide). Row 0 e Row 2 têm 6 cells cada:
## corners nos extremos, 4 bosses no meio.
const _CELL_MAP: Array = [
    # Row 0 (topo)
    [CellKind.CORNER_ZAEL_SHOTS,   0],   # 0  (col 0)
    [CellKind.BOSS,                1],   # 1  Ignarath
    [CellKind.BOSS,                2],   # 2  Cryovex
    [CellKind.BOSS,                3],   # 3  Voltrix
    [CellKind.BOSS,                4],   # 4  Gravitus
    [CellKind.CORNER_ZARA_WEAPONS, 0],   # 5  (col 5)
    # Row 1 (fillers do painel central overlay)
    [CellKind.EMPTY,               0],   # 6
    [CellKind.EMPTY,               0],   # 7
    [CellKind.EMPTY,               0],   # 8
    [CellKind.EMPTY,               0],   # 9
    [CellKind.EMPTY,               0],   # 10
    [CellKind.EMPTY,               0],   # 11
    # Row 2 (base)
    [CellKind.CORNER_ARMOR,        0],   # 12 (col 0) — armaduras Zael+Zara
    [CellKind.BOSS,                5],   # 13 Galerix
    [CellKind.BOSS,                6],   # 14 Umbraex
    [CellKind.BOSS,                7],   # 15 Luxar
    [CellKind.BOSS,                8],   # 16 Terragor
    [CellKind.CORNER_HEARTS,       0],   # 17 (col 5) — corações + sub-tanks
]

# Índices focusáveis (skip fillers da row 1).
const _FOCUSABLE_INDICES: Array[int] = [0, 1, 2, 3, 4, 5, 12, 13, 14, 15, 16, 17]
const _GRID_COLS := 6
const _GRID_ROWS := 3

# Cores base + hover.
const _MOD_NORMAL := Color(1.0, 1.0, 1.0, 1.0)
const _MOD_FOCUS := Color(1.25, 1.4, 1.6, 1.0)
const _MOD_COMPLETED := Color(0.6, 1.0, 0.6, 1.0)
const _MOD_COMPLETED_FOCUS := Color(0.8, 1.3, 0.9, 1.0)

var _pending_stage_id: int = -1

@onready var _char_select: Control = $CharacterSelect
@onready var _info_title: Label = $CenterInfo/Margin/HBox/TextVBox/InfoTitle
@onready var _info_body: Label = $CenterInfo/Margin/HBox/TextVBox/InfoBody
@onready var _info_footer: Label = $CenterInfo/Margin/HBox/TextVBox/InfoFooter
@onready var _info_subtitle: Label = $CenterInfo/Margin/HBox/TextVBox/InfoSubtitle
@onready var _info_vbox: VBoxContainer = $CenterInfo/Margin/HBox/TextVBox
@onready var _sprite_slot: TextureRect = $CenterInfo/Margin/HBox/SpriteSlot

var _hearts_row: HBoxContainer = null   # wrapper: hp bar + collectibles grid side-by-side
var _collectibles_grid: GridContainer = null  # 4 cols × 3 rows: hearts (8) + tanks (4)
var _hp_bar: Control = null             # instance de hp_bar.gd
var _tank_cells: Array = []             # refs pros VBox de cada tank (icon + charge bar)

func _ready() -> void:
    _char_select.character_chosen.connect(_on_character_chosen)
    _build_hearts_tanks_hud()
    _build_cards()
    _setup_focus_neighbors()
    _reset_center_info()
    # Foco inicial no primeiro boss (célula 1 = Ignarath), pra setas funcionarem.
    var grid: GridContainer = $Grid
    grid.get_child(1).grab_focus.call_deferred()

## HUD unificado: HP bar à esquerda + GRID 4×3 (2 linhas de hearts + 1 linha de
## tanks c/ barra de carga por tank). Fica hidden por padrão, aparece só quando
## corner HEARTS focado.
func _build_hearts_tanks_hud() -> void:
    _hearts_row = HBoxContainer.new()
    _hearts_row.alignment = BoxContainer.ALIGNMENT_CENTER
    _hearts_row.add_theme_constant_override("separation", 24)
    _hearts_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _hp_bar = Control.new()
    _hp_bar.set_script(_HP_BAR_SCRIPT)
    _hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    _hearts_row.add_child(_hp_bar)
    # GRID 4 colunas × 3 linhas: 8 hearts (2 linhas) + 4 tanks (última linha).
    _collectibles_grid = GridContainer.new()
    _collectibles_grid.columns = 4
    _collectibles_grid.add_theme_constant_override("h_separation", 6)
    _collectibles_grid.add_theme_constant_override("v_separation", 6)
    _collectibles_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    # Rows 0-1 = 8 hearts (TextureRects diretos como células).
    for i in 8:
        var tr := TextureRect.new()
        tr.texture = _heart_icon()
        tr.custom_minimum_size = _ICON_SIZE
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        tr.modulate = _DIMMED
        _collectibles_grid.add_child(tr)
    # Row 2 = 4 tanks, cada célula = VBox [tank icon + mini charge bar].
    _tank_cells.clear()
    for i in 4:
        var cell := VBoxContainer.new()
        cell.alignment = BoxContainer.ALIGNMENT_CENTER
        cell.add_theme_constant_override("separation", 2)
        var tr := TextureRect.new()
        tr.texture = _tank_icon()
        tr.custom_minimum_size = _ICON_SIZE
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        tr.modulate = _DIMMED
        cell.add_child(tr)
        var pb := ProgressBar.new()
        pb.min_value = 0.0
        pb.max_value = 1.0
        pb.value = 0.0
        pb.show_percentage = false
        pb.custom_minimum_size = Vector2(_ICON_SIZE.x, 6)
        cell.add_child(pb)
        _tank_cells.append(cell)
        _collectibles_grid.add_child(cell)
    _hearts_row.add_child(_collectibles_grid)
    _hearts_row.visible = false
    _info_vbox.add_child(_hearts_row)

func _build_cards() -> void:
    var grid: GridContainer = $Grid
    for i in _CELL_MAP.size():
        var entry: Array = _CELL_MAP[i]
        var kind: int = entry[0]
        var payload: int = entry[1]
        var card: Control = grid.get_child(i)
        match kind:
            CellKind.EMPTY:
                pass  # filler central: sem conteúdo, sem foco (Control base, focus_mode = 0 default)
            CellKind.BOSS:
                _setup_boss_card(card, payload)
            _:
                _setup_corner_card(card, kind)

func _setup_boss_card(card: PanelContainer, stage_id: int) -> void:
    var boss_name: String = BOSS_NAMES.get(stage_id, "Stage %d" % stage_id)
    var name_lower: String = boss_name.to_lower()
    var portrait: TextureRect = card.get_node("Portrait")
    var completed := GameManager.completed_stages.has(stage_id)
    var tex := load(_PORTRAIT_PATH_FMT % [name_lower, name_lower]) as Texture2D
    if tex:
        portrait.texture = tex
    portrait.modulate = _MOD_COMPLETED if completed else _MOD_NORMAL
    card.focus_entered.connect(_on_boss_focus.bind(card, stage_id, completed))
    card.focus_exited.connect(_on_card_unfocus.bind(card, completed))
    card.gui_input.connect(_on_boss_gui_input.bind(stage_id))
    card.mouse_entered.connect(card.grab_focus)  # hover = foco = atualiza center

## Corner cells (4 cantos): mostram inventário/progressão + também têm foco/hover.
func _setup_corner_card(card: PanelContainer, kind: int) -> void:
    var vbox := VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 6)
    card.add_child(vbox)
    var title := _corner_title(kind)
    var tl := Label.new()
    tl.text = title
    tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tl.add_theme_font_size_override("font_size", 18)
    tl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.95, 1))
    vbox.add_child(tl)
    match kind:
        CellKind.CORNER_HEARTS:
            vbox.add_child(_build_hearts_tanks_short())
        CellKind.CORNER_ZAEL_SHOTS:
            # Coluna dupla: Shots à esquerda + Armor Zael à direita.
            vbox.add_child(_build_character_columns(
                ["single", "spread", "rapid", "laser", "cannon"],
                GameManager.zael_shot_types,
                GameManager.zael_armor))
        CellKind.CORNER_ZARA_WEAPONS:
            vbox.add_child(_build_character_columns(
                ["sword", "dual_blades", "glaive", "claws", "war_axe"],
                GameManager.zara_weapons,
                GameManager.zara_armor))
        CellKind.CORNER_ARMOR:
            vbox.add_child(_build_armor_grid())
        _:
            var cl := Label.new()
            cl.text = _corner_short_line(kind)
            cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            cl.add_theme_font_size_override("font_size", 44)
            cl.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 1))
            vbox.add_child(cl)
    card.focus_entered.connect(_on_corner_focus.bind(kind))
    card.focus_exited.connect(_on_card_unfocus.bind(card, false))
    card.mouse_entered.connect(card.grab_focus)  # hover = foco = atualiza center

## HBox com 2 colunas: [Shots/Weapons] · [Armor 4 peças]. Usado nos corners
## ZAEL e ZARA pra dar visão completa de tudo do personagem num só painel.
func _build_character_columns(items: Array, owned_items: Array, armor: Dictionary) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 12)
    row.add_child(_build_item_list(items, owned_items))
    row.add_child(_build_armor_column(armor))
    return row

## Coluna vertical com as 4 peças de armadura (helmet/torso/arms/legs).
func _build_armor_column(armor: Dictionary) -> VBoxContainer:
    var col := VBoxContainer.new()
    col.alignment = BoxContainer.ALIGNMENT_CENTER
    col.add_theme_constant_override("separation", 2)
    var pieces := ["helmet", "torso", "arms", "legs"]
    for p in pieces:
        var lbl := Label.new()
        var owned_now := armor.get(p, false)
        var mark: String = "✓" if owned_now else "·"
        lbl.text = "%s %s" % [mark, p.capitalize()]
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.add_theme_font_size_override("font_size", 15)
        var c: Color = Color(0.85, 0.95, 1.0, 1) if owned_now else Color(0.45, 0.50, 0.55, 1)
        lbl.add_theme_color_override("font_color", c)
        col.add_child(lbl)
    return col

## Coluna de labels ✓/· pra items de arma/tiro (5 items típicos).
func _build_item_list(items: Array, owned: Array) -> VBoxContainer:
    var col := VBoxContainer.new()
    col.alignment = BoxContainer.ALIGNMENT_CENTER
    col.add_theme_constant_override("separation", 2)
    for item in items:
        var lbl := Label.new()
        var pretty: String = str(item).capitalize().replace("_", " ")
        var mark: String = "✓" if owned.has(item) else "·"
        var owned_now := owned.has(item)
        lbl.text = "%s %s" % [mark, pretty]
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.add_theme_font_size_override("font_size", 15)
        var c: Color = Color(0.85, 0.95, 1.0, 1) if owned_now else Color(0.45, 0.50, 0.55, 1)
        lbl.add_theme_color_override("font_color", c)
        col.add_child(lbl)
    return col

## Zael | Zara — 4 peças pareadas.
func _build_armor_grid() -> VBoxContainer:
    var col := VBoxContainer.new()
    col.alignment = BoxContainer.ALIGNMENT_CENTER
    col.add_theme_constant_override("separation", 2)
    var pieces := ["helmet", "torso", "arms", "legs"]
    var header := Label.new()
    header.text = "       Zael Zara"
    header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    header.add_theme_font_size_override("font_size", 13)
    header.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75, 1))
    col.add_child(header)
    for p in pieces:
        var lbl := Label.new()
        var l: String = "✓" if GameManager.zael_armor.get(p, false) else "·"
        var r: String = "✓" if GameManager.zara_armor.get(p, false) else "·"
        lbl.text = "%-7s %s   %s" % [p.capitalize(), l, r]
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.add_theme_font_size_override("font_size", 15)
        lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 1))
        col.add_child(lbl)
    return col

func _corner_title(kind: int) -> String:
    match kind:
        CellKind.CORNER_ZAEL_SHOTS: return "ZAEL"
        CellKind.CORNER_ZARA_WEAPONS: return "ZARA"
        CellKind.CORNER_ARMOR: return "ARMOR"
        CellKind.CORNER_HEARTS: return "HEARTS · TANKS"
    return ""

func _corner_short_line(kind: int) -> String:
    match kind:
        CellKind.CORNER_ZAEL_SHOTS:
            return "%d / 5" % GameManager.zael_shot_types.size()
        CellKind.CORNER_ZARA_WEAPONS:
            return "%d / 5" % GameManager.zara_weapons.size()
        CellKind.CORNER_ARMOR:
            return "%d / 8" % (_armor_count(GameManager.zael_armor) + _armor_count(GameManager.zara_armor))
    return ""

## HBox com [sprite_heart] [count] · [sprite_tank] [count] pra ficar visualmente
## consistente com o HUD grande do centro.
func _build_hearts_tanks_short() -> HBoxContainer:
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 6)
    var heart_icon := TextureRect.new()
    heart_icon.texture = _heart_icon()
    heart_icon.custom_minimum_size = Vector2(40, 40)
    heart_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    heart_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    row.add_child(heart_icon)
    var heart_count := Label.new()
    heart_count.text = str(GameManager.collected_hearts.size())
    heart_count.add_theme_font_size_override("font_size", 36)
    heart_count.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 1))
    row.add_child(heart_count)
    var sep := Label.new()
    sep.text = "  "
    row.add_child(sep)
    var tank_icon := TextureRect.new()
    tank_icon.texture = _tank_icon()
    tank_icon.custom_minimum_size = Vector2(40, 40)
    tank_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tank_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tank_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    row.add_child(tank_icon)
    var tank_count := Label.new()
    tank_count.text = str(GameManager.collected_subtanks.size())
    tank_count.add_theme_font_size_override("font_size", 36)
    tank_count.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 1))
    row.add_child(tank_count)
    return row

## Computa focus_neighbor_* de cada célula focusável — arrow keys funcionam
## nativamente com esses NodePaths setados. Skip fillers do centro em cada
## direção; se não achar vizinho, deixa NodePath vazio (sem wrap).
func _setup_focus_neighbors() -> void:
    var grid: GridContainer = $Grid
    var cells: Array = grid.get_children()
    for i in _FOCUSABLE_INDICES:
        var cell: Control = cells[i]
        var row := i / _GRID_COLS
        var col := i % _GRID_COLS
        cell.focus_neighbor_top    = _find_neighbor(cells, row, col,  0, -1)
        cell.focus_neighbor_bottom = _find_neighbor(cells, row, col,  0,  1)
        cell.focus_neighbor_left   = _find_neighbor(cells, row, col, -1,  0)
        cell.focus_neighbor_right  = _find_neighbor(cells, row, col,  1,  0)

func _find_neighbor(cells: Array, row: int, col: int, dcol: int, drow: int) -> NodePath:
    var r := row + drow
    var c := col + dcol
    while r >= 0 and r < _GRID_ROWS and c >= 0 and c < _GRID_COLS:
        var idx := r * _GRID_COLS + c
        if _FOCUSABLE_INDICES.has(idx):
            return cells[idx].get_path()
        r += drow
        c += dcol
    return NodePath()

func _on_boss_focus(card: PanelContainer, stage_id: int, completed: bool) -> void:
    _hide_hearts_tanks_hud()
    var portrait: TextureRect = card.get_node("Portrait")
    portrait.modulate = _MOD_COMPLETED_FOCUS if completed else _MOD_FOCUS
    var boss_name: String = BOSS_NAMES.get(stage_id, "Stage %d" % stage_id)
    var theme_name: String = BOSS_THEMES.get(stage_id, "")
    var boss_id := boss_name.to_lower()
    var ability_line := ""
    if GameManager.boss_abilities_unlocked.has(boss_id):
        ability_line = "Ability: UNLOCKED"
    # Sprite slot fixo à esquerda do CenterInfo mostra o portrait do boss focado.
    _sprite_slot.texture = portrait.texture
    _sprite_slot.modulate = _MOD_NORMAL
    _sprite_slot.visible = true
    _info_subtitle.text = ""
    _info_title.text = "%s — %s" % [boss_name.to_upper(), theme_name.to_upper()]
    _info_body.text = BOSS_DESCRIPTION.get(stage_id, "")
    var footer_lines: Array[String] = []
    footer_lines.append("Weakness: %s" % BOSS_WEAKNESS.get(stage_id, "?"))
    if completed:
        footer_lines.append("COMPLETED ✓")
    if ability_line != "":
        footer_lines.append(ability_line)
    _info_footer.text = "\n".join(footer_lines)

func _on_corner_focus(kind: int) -> void:
    _hide_hearts_tanks_hud()
    _sprite_slot.visible = false  # corners não têm sprite fixo — área vira texto puro
    var title := ""
    var body := ""
    var footer := ""
    match kind:
        CellKind.CORNER_ZAEL_SHOTS:
            title = "ZAEL"
            body = "SHOTS\n%s\n\nARMOR\n%s" % [
                _format_list(["single", "spread", "rapid", "laser", "cannon"], GameManager.zael_shot_types),
                _format_armor(GameManager.zael_armor),
            ]
            footer = "Active shot: %s" % GameManager.zael_selected_shot.capitalize()
            if _armor_count(GameManager.zael_armor) == 4:
                footer += "  ·  NOVA BUSTER unlocked"
        CellKind.CORNER_ZARA_WEAPONS:
            title = "ZARA"
            body = "WEAPONS\n%s\n\nARMOR\n%s" % [
                _format_list(["sword", "dual_blades", "glaive", "claws", "war_axe"], GameManager.zara_weapons),
                _format_armor(GameManager.zara_armor),
            ]
            footer = "Active weapon: %s" % GameManager.zara_selected_weapon.capitalize().replace("_", " ")
            if _armor_count(GameManager.zara_armor) == 4:
                footer += "  ·  FÚRIA LIMITLESS unlocked"
        CellKind.CORNER_ARMOR:
            title = "ARMOR"
            body = _format_armor_both(GameManager.zael_armor, GameManager.zara_armor)
            var zael_full := _armor_count(GameManager.zael_armor) == 4
            var zara_full := _armor_count(GameManager.zara_armor) == 4
            var lines: Array[String] = []
            if zael_full: lines.append("Zael: NOVA BUSTER")
            if zara_full: lines.append("Zara: FÚRIA LIMITLESS")
            footer = "\n".join(lines)
        CellKind.CORNER_HEARTS:
            title = "HEARTS · SUB-TANKS"
            _show_hearts_tanks_hud()
            # Sem footer texto — a HP bar visual já expressa o max_hp atual.
    _info_subtitle.text = ""
    _info_title.text = title
    _info_body.text = body
    _info_footer.text = footer

func _on_card_unfocus(_card: Control, completed: bool) -> void:
    # Restaura tint do portrait se boss card; sem hover destaca ninguém, reseta info.
    if _card is PanelContainer and _card.has_node("Portrait"):
        var portrait: TextureRect = _card.get_node("Portrait")
        portrait.modulate = _MOD_COMPLETED if completed else _MOD_NORMAL
    # Como focus_exited dispara antes de focus_entered do próximo, o novo texto
    # sobrescreve isso. Só reseta se realmente nada mais tá com foco.
    call_deferred("_maybe_reset_center_info")

func _maybe_reset_center_info() -> void:
    if get_viewport().gui_get_focus_owner() == null:
        _reset_center_info()

func _reset_center_info() -> void:
    _hide_hearts_tanks_hud()
    _sprite_slot.visible = false
    _info_title.text = "SELECT STAGE"
    _info_subtitle.text = "↑↓←→ to navigate  ·  ENTER to confirm"
    _info_body.text = ""
    _info_footer.text = ""

## Mostra o HUD unificado: HP bar + grid 4×3 (hearts nas rows 0-1, tanks na
## row 2). Modulate por coletado, HP bar cresce com max_hp, charge bars sob
## cada tank coletado.
func _show_hearts_tanks_hud() -> void:
    _info_body.text = ""
    _hearts_row.visible = true
    # HP bar: mesma altura do HUD do jogo (max_hp × 12px), full (current=max),
    # cresce visualmente com cada heart coletado.
    _hp_bar.custom_minimum_size = Vector2(_HP_BAR_WIDTH, float(GameManager.max_hp) * _HP_PER_PIXEL)
    _hp_bar.set_hp(GameManager.max_hp, GameManager.max_hp)
    # Hearts (rows 0-1): 8 primeiros filhos do grid.
    for i in 8:
        var icon: TextureRect = _collectibles_grid.get_child(i)
        icon.modulate = _BRIGHT if i < GameManager.collected_hearts.size() else _DIMMED
    # Tanks (row 2): 4 VBoxes com icon + charge bar.
    var charges: Array = GameManager.subtank_charges
    for i in 4:
        var cell: VBoxContainer = _tank_cells[i]
        var icon: TextureRect = cell.get_child(0)
        var bar: ProgressBar = cell.get_child(1)
        var owned := GameManager.collected_subtanks.has(i)
        icon.modulate = _BRIGHT if owned else _DIMMED
        bar.value = float(charges[i]) if i < charges.size() else 0.0
        bar.visible = owned

func _hide_hearts_tanks_hud() -> void:
    if _hearts_row: _hearts_row.visible = false

func _on_boss_gui_input(event: InputEvent, stage_id: int) -> void:
    if event.is_action_pressed("ui_accept"):
        _select_stage(stage_id)
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _select_stage(stage_id)

func _select_stage(stage_id: int) -> void:
    _pending_stage_id = stage_id
    _char_select.show_for_stage(stage_id, BOSS_NAMES.get(stage_id, "Stage %d" % stage_id))

func _on_character_chosen(character: String) -> void:
    GameManager.set_active_character(character)
    StageManager.load_stage(_pending_stage_id)

# --- Helpers ---

func _armor_count(armor: Dictionary) -> int:
    var n := 0
    for k in armor:
        if armor[k]:
            n += 1
    return n

func _format_list(all: Array, owned: Array) -> String:
    var lines: Array[String] = []
    for item in all:
        var name_pretty: String = str(item).capitalize().replace("_", " ")
        var mark: String = "✓" if owned.has(item) else "·"
        lines.append("%s %s" % [mark, name_pretty])
    return "\n".join(lines)

func _format_armor(armor: Dictionary) -> String:
    var pieces := ["helmet", "torso", "arms", "legs"]
    var lines: Array[String] = []
    for p in pieces:
        var mark: String = "✓" if armor.get(p, false) else "·"
        lines.append("%s %s" % [mark, p.capitalize()])
    return "\n".join(lines)

## Lista pareada Zael | Zara pra cada peça de armadura — cabe compacto no card.
func _format_armor_both(zael: Dictionary, zara: Dictionary) -> String:
    var pieces := ["helmet", "torso", "arms", "legs"]
    var lines: Array[String] = ["      Zael  Zara"]
    for p in pieces:
        var l: String = "✓" if zael.get(p, false) else "·"
        var r: String = "✓" if zara.get(p, false) else "·"
        lines.append("%-7s  %s     %s" % [p.capitalize(), l, r])
    return "\n".join(lines)

