extends Control

signal character_chosen(character: String)

var _standalone: bool = false

@onready var _stage_label: Label = $Panel/VBox/StageLabel

func _ready() -> void:
    _standalone = get_parent() == get_tree().root
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    if _standalone:
        _stage_label.text = "New Game"
        visible = true
    else:
        visible = false
    $Panel/VBox/ZaelButton.pressed.connect(func(): _choose("zael"))
    $Panel/VBox/ZaraButton.pressed.connect(func(): _choose("zara"))
    $Panel/VBox/CancelButton.pressed.connect(_on_cancel)

func show_for_stage(stage_id: int, boss_name: String) -> void:
    _stage_label.text = "Stage %d — %s" % [stage_id, boss_name]
    visible = true

func _choose(character: String) -> void:
    if _standalone:
        GameManager.set_active_character(character)
        StageManager.load_stage(0)
    else:
        visible = false
        character_chosen.emit(character)

func _on_cancel() -> void:
    if _standalone:
        get_tree().change_scene_to_file("res://ui/title_screen.tscn")
    else:
        visible = false
