extends Node
class_name StageController

const RESPAWN_DELAY  := 1.0
const FADE_DURATION  := 0.4

@export var player: CharacterBase:
	set(p):
		if player != null and is_instance_valid(player) and player.died.is_connected(_on_player_died):
			player.died.disconnect(_on_player_died)
		player = p
		if p != null:
			p.died.connect(_on_player_died)

var _fade_rect: ColorRect = null

func _ready() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 8   # above HUD (5), below GameOver/PauseMenu (10+)
	add_child(cl)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.anchor_right  = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_fade_rect)

func setup(p: CharacterBase) -> void:
	player = p

func _fade_to(target_alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", target_alpha, FADE_DURATION)
	await tw.finished

func _on_player_died() -> void:
	await _fade_to(1.0)
	GameManager.lose_life()
	if GameManager.lives > 0:
		await _respawn()
	await _fade_to(0.0)

func _respawn() -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if not is_instance_valid(player):
		return
	player.respawn(StageManager.get_respawn_position())
