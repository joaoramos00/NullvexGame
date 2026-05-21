extends Control

func _ready() -> void:
    $VBox/ContinueButton.disabled = not GameManager.has_save()
    $VBox/NewGameButton.pressed.connect(_on_new_game_pressed)
    $VBox/ContinueButton.pressed.connect(_on_continue_pressed)
    $VBox/QuitButton.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed() -> void:
    GameManager.reset()
    get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_continue_pressed() -> void:
    if GameManager.load_game():
        get_tree().change_scene_to_file("res://ui/stage_select.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()
