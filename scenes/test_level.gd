extends Node2D

@onready var character: CharacterBase = $CharacterBase
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
    GameManager.reset()
    GameManager.set_active_character("zael")
    StageManager.spawn_position = character.global_position

func _process(_delta: float) -> void:
    camera.global_position = character.global_position
