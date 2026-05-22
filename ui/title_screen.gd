extends Control

const _IMG_DEBUG_SCENE := preload("res://ui/img_debug.tscn")

var _debug_panel: Node = null

func _ready() -> void:
    $VBox/ContinueButton.disabled = not GameManager.has_save()
    $VBox/NewGameButton.pressed.connect(_on_new_game_pressed)
    $VBox/ContinueButton.pressed.connect(_on_continue_pressed)
    $VBox/QuitButton.pressed.connect(_on_quit_pressed)
    $VBox/ImgDebugButton.pressed.connect(_on_img_debug_pressed)
    $VBox/NewGameButton.grab_focus()

func _on_img_debug_pressed() -> void:
    if is_instance_valid(_debug_panel):
        _debug_panel.queue_free()
        _debug_panel = null
    else:
        _debug_panel = _IMG_DEBUG_SCENE.instantiate()
        add_child(_debug_panel)

func _on_new_game_pressed() -> void:
    GameManager.reset()
    get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_continue_pressed() -> void:
    if GameManager.load_game():
        get_tree().change_scene_to_file("res://ui/stage_select.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()
