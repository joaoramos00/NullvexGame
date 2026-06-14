extends CanvasLayer

@export var show_delay: float = 1.0

@onready var _stage_label: Label = $Panel/VBox/StageLabel
@onready var _ability_label: Label = $Panel/VBox/AbilityLabel

var _completed_stage_id: int = -1

func _ready() -> void:
    visible = false
    process_mode = Node.PROCESS_MODE_ALWAYS
    GameManager.stage_completed.connect(_on_stage_completed)
    $Panel/VBox/ContinueButton.pressed.connect(_on_continue_pressed)

func _on_stage_completed(stage_id: int) -> void:
    _completed_stage_id = stage_id
    GameManager.save_game()
    AudioManager.play_sfx(AudioLibrary.sfx_stage_complete)
    var boss_ability := _boss_ability_for(stage_id)
    _stage_label.text = "STAGE %d COMPLETE!" % stage_id
    _ability_label.text = "Ability unlocked: %s" % boss_ability if boss_ability != "" else ""
    await get_tree().create_timer(show_delay).timeout
    visible = true
    get_tree().paused = true

func _on_continue_pressed() -> void:
    get_tree().paused = false
    match _completed_stage_id:
        9:
            StageManager.load_stage(10)
        10:
            StageManager.load_stage(11)
        11:
            get_tree().change_scene_to_file("res://ui/title_screen.tscn")
        _:
            get_tree().change_scene_to_file("res://ui/stage_select.tscn")

func _boss_ability_for(stage_id: int) -> String:
    var abilities := {1: "ignarath", 2: "cryovex", 3: "voltrix", 4: "gravitus",
                      5: "galerix",  6: "umbraex", 7: "luxar",   8: "terragor"}
    return abilities.get(stage_id, "")
