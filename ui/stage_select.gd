extends Control

const BOSS_NAMES: Dictionary = {
    1: "Ignarath",  2: "Cryovex",  3: "Voltrix",  4: "Gravitus",
    5: "Galerix",   6: "Umbraex",  7: "Luxar",    8: "Terragor",
}

const BOSS_THEMES: Dictionary = {
    1: "Fire",     2: "Ice",      3: "Lightning", 4: "Gravity",
    5: "Wind",     6: "Shadow",   7: "Light",     8: "Earth",
}

func _ready() -> void:
    $BackButton.pressed.connect(_on_back_pressed)
    _build_cards()

func _build_cards() -> void:
    var grid: GridContainer = $Grid
    for i in range(grid.get_child_count()):
        var card: PanelContainer = grid.get_child(i)
        var stage_id: int = i + 1
        var label: Label = card.get_node("VBox/NameLabel")
        var theme_label: Label = card.get_node("VBox/ThemeLabel")
        var btn: Button = card.get_node("VBox/SelectButton")
        var completed := GameManager.completed_stages.has(stage_id)
        label.text = BOSS_NAMES.get(stage_id, "Stage %d" % stage_id)
        theme_label.text = BOSS_THEMES.get(stage_id, "")
        btn.text = "CLEAR" if completed else "SELECT"
        btn.pressed.connect(_on_stage_selected.bind(stage_id))

func _on_stage_selected(stage_id: int) -> void:
    StageManager.current_stage_id = stage_id
    GameManager.set_active_character(GameManager.active_character)
    # Scene transition wired up when individual stage scenes are built (Plan 09)
    print("Stage %d selected — %s" % [stage_id, BOSS_NAMES.get(stage_id, "?")])

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://ui/title_screen.tscn")
