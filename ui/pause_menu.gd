extends CanvasLayer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/VBox/ResumeButton.pressed.connect(_on_resume_pressed)
	$Panel/VBox/StageSelectButton.pressed.connect(_on_stage_select_pressed)
	$Panel/VBox/MainMenuButton.pressed.connect(_on_main_menu_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	visible = not visible
	get_tree().paused = visible

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_stage_select_pressed() -> void:
	get_tree().paused = false
	GameManager.save_game()
	get_tree().change_scene_to_file("res://ui/stage_select.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.save_game()
	get_tree().change_scene_to_file("res://ui/title_screen.tscn")
