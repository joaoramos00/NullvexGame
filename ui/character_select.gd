extends Control

signal character_chosen(character: String)

@onready var _stage_label: Label = $Panel/VBox/StageLabel

func _ready() -> void:
    visible = false
    $Panel/VBox/ZaelButton.pressed.connect(func(): _choose("zael"))
    $Panel/VBox/ZaraButton.pressed.connect(func(): _choose("zara"))
    $Panel/VBox/CancelButton.pressed.connect(func(): visible = false)

func show_for_stage(stage_id: int, boss_name: String) -> void:
    _stage_label.text = "Stage %d — %s" % [stage_id, boss_name]
    visible = true

func _choose(character: String) -> void:
    visible = false
    character_chosen.emit(character)
