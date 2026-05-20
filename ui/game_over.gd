extends CanvasLayer

const SHOW_DELAY := 2.0

func _ready() -> void:
    visible = false
    process_mode = Node.PROCESS_MODE_ALWAYS
    GameManager.game_over.connect(_on_game_over)
    $Panel/VBox/RetryButton.pressed.connect(_on_retry_pressed)
    $Panel/VBox/QuitButton.pressed.connect(_on_quit_pressed)

func _on_game_over() -> void:
    await get_tree().create_timer(SHOW_DELAY).timeout
    visible = true
    get_tree().paused = true

func _on_retry_pressed() -> void:
    get_tree().paused = false
    GameManager.lives = GameManager.DEFAULT_LIVES
    StageManager.reset_checkpoints()
    get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://ui/title_screen.tscn")
