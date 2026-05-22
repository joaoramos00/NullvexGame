extends Node2D

const ZAEL_SCENE := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE := preload("res://characters/melee/zara.tscn")
const _TILESET   := preload("res://stages/stage_00/Stage_00T.png")
const _TS        := 32

var _player: CharacterBase

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")
	_player = _spawn_player()
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)
	StageManager.spawn_position = $PlayerSpawn.global_position
	$GoalZone.body_entered.connect(_on_goal_entered)
	AudioManager.play_bgm(AudioLibrary.bgm_intro)
	queue_redraw()

func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		$Camera2D.global_position = _player.global_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pause"):
		$PauseMenu.toggle_pause()

func _on_goal_entered(body: Node) -> void:
	if body == _player:
		GameManager.complete_stage(0)
		GameManager.save_game()

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
			_draw_platform_tiles(Rect2(center - size * 0.5, size))

func _draw_platform_tiles(rect: Rect2) -> void:
	var ts := _TS
	var cols := ceili(rect.size.x / ts)
	var rows := ceili(rect.size.y / ts)
	for row in rows:
		for col in cols:
			var tx := _tile_col(col, cols)
			var ty := _tile_row(row, rows)
			var src := Rect2(tx * ts, ty * ts, ts, ts)
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var dh := minf(ts, rect.position.y + rect.size.y - dy)
			src.size.x = src.size.x * dw / ts
			src.size.y = src.size.y * dh / ts
			draw_texture_rect_region(_TILESET, Rect2(dx, dy, dw, dh), src)

func _tile_col(col: int, cols: int) -> int:
	if col == 0:
		return 0
	if col == cols - 1:
		return 3
	return 1 + (col % 2)  # alterna tiles 1 e 2 para variedade

func _tile_row(row: int, rows: int) -> int:
	if rows == 1:
		return 0
	if row == 0:
		return 0
	if row == rows - 1:
		return 2
	return 1
