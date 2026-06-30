extends CanvasLayer

@onready var _draw_panel: Control = $DrawPanel
@onready var _button_bar: HBoxContainer = $ButtonBar
@onready var _pause_btn: Button = $PauseButton

# Stage order for navigation (primary="" first, then bosses 01-08)
const _ABILITY_ORDER: Array = [
	"", "ignarath", "cryovex", "voltrix", "gravitus",
	"galerix", "umbraex", "luxar", "terragor",
]

var _is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_draw_panel.visible = false
	_button_bar.visible = false
	$ButtonBar/ResumeButton.pressed.connect(_on_resume_pressed)
	$ButtonBar/StageSelectButton.pressed.connect(_on_stage_select_pressed)
	$ButtonBar/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	_pause_btn.pressed.connect(toggle_pause)

func _input(event: InputEvent) -> void:
	var is_toggle: bool = event.is_action_just_pressed("pause")
	if not is_toggle and event is InputEventKey:
		var ke := event as InputEventKey
		is_toggle = ke.pressed and not ke.echo and ke.keycode == KEY_ENTER
	if is_toggle:
		toggle_pause()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not _is_paused:
		return
	if event.is_action_just_pressed("ability_prev") or event.is_action_just_pressed("ui_left"):
		_draw_panel.move_grid(-1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_just_pressed("ability_next") or event.is_action_just_pressed("ui_right"):
		_draw_panel.move_grid(1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_just_pressed("ui_up"):
		_draw_panel.move_grid(0, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_just_pressed("ui_down"):
		_draw_panel.move_grid(0, 1)
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	_is_paused = not _is_paused
	_draw_panel.visible = _is_paused
	_button_bar.visible = _is_paused
	get_tree().paused = _is_paused
	_pause_btn.text = "▶" if _is_paused else "⏸"
	if _is_paused:
		_sync_state()
		_draw_panel.queue_redraw()
		_pause_btn.grab_focus()

func _sync_state() -> void:
	var nav: Array = _get_nav_list()
	var cur: String = GameManager.selected_boss_ability
	_draw_panel.sel_idx = max(0, nav.find(cur))
	# Sync sel_grid from current boss ability
	for i: int in 9:
		if (_draw_panel._SLOTS[i]["boss_id"] as String) == cur:
			_draw_panel.sel_grid = i
			break
	var players: Array = get_tree().get_nodes_in_group("player")
	_draw_panel.current_player = players[0] if not players.is_empty() else null

func _change_selection(dir: int) -> void:
	var nav: Array = _get_nav_list()
	if nav.is_empty():
		return
	_draw_panel.sel_idx = (_draw_panel.sel_idx + dir + nav.size()) % nav.size()
	GameManager.selected_boss_ability = nav[_draw_panel.sel_idx] as String
	_draw_panel.queue_redraw()

# Returns available abilities in stage order: primary first, then unlocked bosses
func _get_nav_list() -> Array:
	var result: Array = [""]   # primary always available
	for bid: String in _ABILITY_ORDER.slice(1):
		if GameManager.boss_abilities_unlocked.has(bid):
			result.append(bid)
	return result

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_stage_select_pressed() -> void:
	_is_paused = false
	get_tree().paused = false
	GameManager.save_game()
	get_tree().change_scene_to_file("res://ui/stage_select.tscn")

func _on_main_menu_pressed() -> void:
	_is_paused = false
	get_tree().paused = false
	GameManager.save_game()
	get_tree().change_scene_to_file("res://ui/title_screen.tscn")
