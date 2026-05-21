extends CanvasLayer

const _COLOR_MOVE   := Color(0.9,  0.27, 0.38)  # red — directional
const _COLOR_JUMP   := Color(0.15, 0.68, 0.38)  # green
const _COLOR_ATTACK := Color(0.29, 0.56, 0.85)  # blue
const _COLOR_PAUSE  := Color(0.31, 0.31, 0.39)  # grey

func _ready() -> void:
	if not (OS.get_name() == "Web" or DisplayServer.is_touchscreen_available()):
		visible = false
		return
	await get_tree().process_frame
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_add_button("move_left",  Vector2(10,           vp.y - 62), 52, 52, _COLOR_MOVE)
	_add_button("move_right", Vector2(68,           vp.y - 62), 52, 52, _COLOR_MOVE)
	_add_button("jump",       Vector2(vp.x - 120,  vp.y - 62), 52, 52, _COLOR_JUMP)
	_add_button("attack",     Vector2(vp.x - 62,   vp.y - 62), 52, 52, _COLOR_ATTACK)
	_add_button("pause",      Vector2(vp.x - 46,   8),         36, 28, _COLOR_PAUSE)

func _add_button(action: String, pos: Vector2, w: int, h: int, color: Color) -> void:
	var btn := TouchScreenButton.new()
	btn.action = action
	btn.passby_press = true
	btn.position = pos
	btn.texture_normal = _make_tex(color, w, h)
	btn.texture_pressed = _make_tex(color.lightened(0.35), w, h)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	btn.shape = shape
	btn.shape_centered = false
	btn.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	btn.modulate = Color(1.0, 1.0, 1.0, 0.65)
	add_child(btn)

static func _make_tex(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
