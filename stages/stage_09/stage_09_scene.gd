extends Node2D

const ZAEL_SCENE := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE := preload("res://characters/melee/zara.tscn")

var _player: CharacterBase
var _bosses: Array[BossBase] = []
var _walls: Array[StaticBody2D] = []

func _ready() -> void:
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")
	_player = _spawn_player()
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)
	StageManager.spawn_position = $PlayerSpawn.global_position
	_collect_nodes()
	_setup_bosses()
	AudioManager.play_bgm(AudioLibrary.bgm_gauntlet)
	queue_redraw()

func _collect_nodes() -> void:
	for bname: String in ["Ignarath", "Cryovex", "Voltrix", "Gravitus", "Galerix", "Umbraex", "Luxar", "Terragor"]:
		_bosses.append(get_node(bname) as BossBase)
	for wname: String in ["Wall1", "Wall2", "Wall3", "Wall4", "Wall5", "Wall6", "Wall7"]:
		_walls.append(get_node(wname) as StaticBody2D)

func _setup_bosses() -> void:
	for i in _bosses.size():
		var boss := _bosses[i]
		boss.player = _player
		boss.stage_id = -1
		boss.ability_id = ""
		var idx_arr := [i]
		boss.boss_defeated.connect(func(_ab: String): _on_boss_defeated(idx_arr[0]))

func _on_boss_defeated(idx: int) -> void:
	if idx < _walls.size():
		_walls[idx].queue_free()
	if idx == _bosses.size() - 1:
		_finish_gauntlet()

func _finish_gauntlet() -> void:
	GameManager.complete_stage(9)
	GameManager.save_game()

func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		$Camera2D.global_position = _player.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		$PauseMenu.toggle_pause()

func _spawn_player() -> CharacterBase:
	var scene := ZARA_SCENE if GameManager.active_character == "zara" else ZAEL_SCENE
	var p: CharacterBase = scene.instantiate()
	p.global_position = $PlayerSpawn.global_position
	add_child(p)
	return p

func _draw() -> void:
	for child in get_children():
		if not child is StaticBody2D:
			continue
		for shape_child in child.get_children():
			if not shape_child is CollisionShape2D:
				continue
			if not shape_child.shape is RectangleShape2D:
				continue
			var size: Vector2 = (shape_child.shape as RectangleShape2D).size
			var center: Vector2 = (child as Node2D).position + (shape_child as Node2D).position
			draw_rect(Rect2(center - size * 0.5, size), Color(0.35, 0.35, 0.35))
