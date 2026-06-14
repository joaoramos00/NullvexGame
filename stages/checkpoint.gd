extends Area2D
class_name Checkpoint

@export var checkpoint_index: int = 1

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if not body is CharacterBase:
        return
    if StageManager.checkpoint_index >= checkpoint_index:
        return
    StageManager.save_checkpoint(global_position, checkpoint_index)
    AudioManager.play_sfx(AudioLibrary.sfx_checkpoint)
