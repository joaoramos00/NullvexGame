extends CanvasLayer

# Colors include alpha (0.65 opacity) baked in
const _COLOR_MOVE   := Color(0.9,  0.27, 0.38, 0.65)
const _COLOR_JUMP   := Color(0.15, 0.68, 0.38, 0.65)
const _COLOR_ATTACK := Color(0.29, 0.56, 0.85, 0.65)
const _COLOR_PAUSE  := Color(0.31, 0.31, 0.39, 0.65)

func _ready() -> void:
	print("[TC] OS=", OS.get_name(), " touch=", DisplayServer.is_touchscreen_available())
	if not (OS.get_name() == "Web" or DisplayServer.is_touchscreen_available()):
		visible = false
		return

	# Full-screen Control container — anchors handle all screen sizes automatically
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# [action, anchor_x, anchor_y, offset_left, offset_top, width, height, color]
	# anchor 0.0 = left/top edge, 1.0 = right/bottom edge
	_add_btn(root, "move_left",  0.0, 1.0,  10, -62, 52, 52, _COLOR_MOVE)
	_add_btn(root, "move_right", 0.0, 1.0,  68, -62, 52, 52, _COLOR_MOVE)
	_add_btn(root, "jump",       1.0, 1.0, -120, -62, 52, 52, _COLOR_JUMP)
	_add_btn(root, "attack",     1.0, 1.0,  -62, -62, 52, 52, _COLOR_ATTACK)
	_add_btn(root, "pause",      1.0, 0.0,  -46,   8, 36, 28, _COLOR_PAUSE)

func _add_btn(parent: Control, action: String, ax: float, ay: float, ol: float, ot: float, w: float, h: float, color: Color) -> void:
	var btn := ColorRect.new()
	btn.anchor_left   = ax
	btn.anchor_right  = ax
	btn.anchor_top    = ay
	btn.anchor_bottom = ay
	btn.offset_left   = ol
	btn.offset_top    = ot
	btn.offset_right  = ol + w
	btn.offset_bottom = ot + h
	btn.color = color
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.gui_input.connect(_on_btn_input.bind(action))
	parent.add_child(btn)

func _on_btn_input(event: InputEvent, action: String) -> void:
	if event is InputEventScreenTouch:
		_emit(action, (event as InputEventScreenTouch).pressed)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_emit(action, (event as InputEventMouseButton).pressed)

static func _emit(action: String, pressed: bool) -> void:
	var ie := InputEventAction.new()
	ie.action = action
	ie.pressed = pressed
	ie.strength = 1.0
	Input.parse_input_event(ie)
