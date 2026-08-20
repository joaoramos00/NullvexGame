extends Control

const BOSS_NAMES: Dictionary = {
    1: "Ignarath",  2: "Cryovex",  3: "Voltrix",  4: "Gravitus",
    5: "Galerix",   6: "Umbraex",  7: "Luxar",    8: "Terragor",
}

const BOSS_THEMES: Dictionary = {
    1: "Fire",     2: "Ice",      3: "Lightning", 4: "Gravity",
    5: "Wind",     6: "Shadow",   7: "Light",     8: "Earth",
}

# Path do portrait derivado do nome do boss (lowercase).
# Cards viram TextureButton mostrando o portrait, clique seleciona o stage.
const _PORTRAIT_PATH_FMT := "res://characters/bosses/%s/%s_portrait.png"

var _pending_stage_id: int = -1

@onready var _char_select: Control = $CharacterSelect

func _ready() -> void:
    _char_select.character_chosen.connect(_on_character_chosen)
    _build_cards()

func _build_cards() -> void:
    var grid: GridContainer = $Grid
    for i in range(grid.get_child_count()):
        var card: PanelContainer = grid.get_child(i)
        var stage_id: int = i + 1
        var boss_name: String = BOSS_NAMES.get(stage_id, "Stage %d" % stage_id)
        var name_lower: String = boss_name.to_lower()
        var label: Label = card.get_node("VBox/NameLabel")
        var theme_label: Label = card.get_node("VBox/ThemeLabel")
        var portrait: TextureButton = card.get_node("VBox/Portrait")
        var completed := GameManager.completed_stages.has(stage_id)
        label.text = boss_name
        theme_label.text = BOSS_THEMES.get(stage_id, "")
        # Load portrait — falha silenciosa se ainda não existir
        # (evita crash em stages futuros sem portrait gerado).
        var tex := load(_PORTRAIT_PATH_FMT % [name_lower, name_lower]) as Texture2D
        if tex:
            portrait.texture_normal = tex
        # Tinta verde quando já foi completado, branco caso contrário.
        portrait.modulate = Color(0.6, 1.0, 0.6) if completed else Color.WHITE
        portrait.pressed.connect(_on_stage_selected.bind(stage_id))

func _on_stage_selected(stage_id: int) -> void:
    _pending_stage_id = stage_id
    _char_select.show_for_stage(stage_id, BOSS_NAMES.get(stage_id, "Stage %d" % stage_id))

func _on_character_chosen(character: String) -> void:
    GameManager.set_active_character(character)
    StageManager.load_stage(_pending_stage_id)
