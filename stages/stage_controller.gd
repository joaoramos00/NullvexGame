extends Node
class_name StageController

const RESPAWN_DELAY := 1.0
const GAME_OVER_DELAY := 2.0

@export var player: CharacterBase

func _ready() -> void:
    assert(player != null, "StageController: player node not assigned")
    player.died.connect(_on_player_died)

func _on_player_died() -> void:
    GameManager.lose_life()
    if GameManager.lives <= 0:
        _game_over()
    else:
        _respawn()

func _respawn() -> void:
    await get_tree().create_timer(RESPAWN_DELAY).timeout
    if not is_instance_valid(player):
        return
    player.respawn(StageManager.get_respawn_position())

func _game_over() -> void:
    await get_tree().create_timer(GAME_OVER_DELAY).timeout
    GameManager.lives = GameManager.DEFAULT_LIVES
    StageManager.reset_checkpoints()
    if StageManager.current_stage_id >= 0:
        StageManager.reload_current_stage()
    else:
        get_tree().reload_current_scene()
