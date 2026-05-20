extends Node
class_name StageController

const RESPAWN_DELAY := 1.0

@export var player: CharacterBase:
	set(p):
		if player != null and is_instance_valid(player) and player.died.is_connected(_on_player_died):
			player.died.disconnect(_on_player_died)
		player = p
		if p != null:
			p.died.connect(_on_player_died)

func setup(p: CharacterBase) -> void:
	player = p

func _on_player_died() -> void:
	GameManager.lose_life()
	if GameManager.lives > 0:
		_respawn()

func _respawn() -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if not is_instance_valid(player):
		return
	player.respawn(StageManager.get_respawn_position())
