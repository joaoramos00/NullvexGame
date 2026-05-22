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
			var tile := _tile_at(col, cols, row, rows)
			var src := Rect2(tile.x * ts, tile.y * ts, ts, ts)
			var dx := rect.position.x + col * ts
			var dy := rect.position.y + row * ts
			var dw := minf(ts, rect.position.x + rect.size.x - dx)
			var dh := minf(ts, rect.position.y + rect.size.y - dy)
			src.size.x = src.size.x * dw / ts
			src.size.y = src.size.y * dh / ts
			draw_texture_rect_region(_TILESET, Rect2(dx, dy, dw, dh), src)

func _tile_at(col: int, cols: int, row: int, rows: int) -> Vector2i:
	var is_left   := col == 0
	var is_right  := col == cols - 1
	var is_top    := row == 0
	var is_bottom := row == rows - 1

	if rows == 1:
		return Vector2i(3, 0)  # Plataforma reta

	if is_top:
		if is_left:  return Vector2i(3, 3)  # Canto superior esquerdo
		if is_right: return Vector2i(0, 2)  # Canto superior direito
		return Vector2i(3, 0)               # Plataforma reta

	if is_bottom:
		if is_left:  return Vector2i(0, 0)  # Canto inferior esquerdo
		if is_right: return Vector2i(1, 3)  # Canto inferior direito
		return Vector2i(1, 2)               # Teto reto

	if is_left:  return Vector2i(3, 2)  # Lateral esquerda da coluna lisa
	if is_right: return Vector2i(1, 0)  # Lateral direita da coluna lisa
	return Vector2i(2, 1)               # Miolo de preenchimento
