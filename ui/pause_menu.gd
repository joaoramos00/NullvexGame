extends CanvasLayer

func _ready() -> void:
    visible = false
    process_mode = Node.PROCESS_MODE_ALWAYS
    $Panel/VBox/ResumeButton.pressed.connect(_on_resume_pressed)
    $Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
    if event.is_action_just_pressed("pause"):
        toggle_pause()

func toggle_pause() -> void:
    visible = not visible
    get_tree().paused = visible

func _on_resume_pressed() -> void:
    toggle_pause()

func _on_quit_pressed() -> void:
    get_tree().paused = false
    get_tree().quit()
