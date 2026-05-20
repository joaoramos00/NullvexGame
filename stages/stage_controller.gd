extends Node
class_name StageController

const RESPAWN_DELAY := 1.0

@export var player: CharacterBase

func _ready() -> void:
    assert(player != null, "StageController: player node not assigned")
    player.died.connect(_on_player_died)

func _on_player_died() -> void:
    GameManager.lose_life()
    if GameManager.lives > 0:
        _respawn()
    # lives <= 0: GameManager.game_over signal is emitted by lose_life()

func _respawn() -> void:
    await get_tree().create_timer(RESPAWN_DELAY).timeout
    if not is_instance_valid(player):
        return
    player.respawn(StageManager.get_respawn_position())
