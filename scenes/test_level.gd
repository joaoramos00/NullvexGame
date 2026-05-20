extends Node2D

@onready var character: Zael = $Zael
@onready var _hud: CanvasLayer = $HUD

func _ready() -> void:
    GameManager.reset()
    GameManager.set_active_character("zael")
    StageManager.spawn_position = character.global_position
    _hud.connect_to_player(character)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-500, 500, 3000, 40), Color(0.3, 0.3, 0.3))
    draw_rect(Rect2(600, 390, 200, 20), Color(0.4, 0.4, 0.4))
