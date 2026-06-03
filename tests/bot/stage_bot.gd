# tests/bot/stage_bot.gd — autopilot que atravessa a fase (Approach A)
extends Node

const TOL := 24.0
const STUCK_EPS := 2.0
const STUCK_TIMEOUT := 4.0
const JUMP_HOLD := 0.12

var _player: CharacterBody2D = null
var _path: Array = []
var _idx: int = 0
var _seg_time: float = 0.0
var _last_dist: float = INF
var _stuck_timer: float = 0.0
var _jump_hold: float = 0.0
var _done: bool = false

func _ready() -> void:
	if _player == null:
		_player = _find_player()
	_path = _load_path()
	if _path.is_empty():
		print("BOT_STUCK:no_path@0,0")
		_done = true
		return
	print("BOT_START")

func _find_player() -> CharacterBody2D:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] if nodes.size() > 0 else null

func _load_path() -> Array:
	var path := "res://tests/bot/paths/stage_%02d.gd" % StageManager.current_stage_id
	if not ResourceLoader.exists(path):
		return []
	var inst: Object = (load(path) as GDScript).new()
	return inst.path() if inst.has_method("path") else []

func _physics_process(delta: float) -> void:
	if _done or _player == null:
		return
	if _jump_hold > 0.0:
		_jump_hold -= delta
		if _jump_hold <= 0.0:
			Input.action_release("jump")
	if _idx >= _path.size():
		_finish()
		return
	var seg: Dictionary = _path[_idx]
	var t := str(seg.get("t", ""))
	var complete := false
	match t:
		"walk_to":    complete = _do_walk_to(seg)
		"climb_to":   complete = _do_climb_to(seg)
		"drop":       complete = _do_drop(seg)
		"wait":       complete = _do_wait(seg, delta)
		"screenshot": complete = _do_screenshot(seg)
		_:            complete = true
	if not complete and (t == "walk_to" or t == "climb_to"):
		if _check_stuck(seg, delta):
			return
	if complete:
		_release_dirs()
		_advance()

func _advance() -> void:
	_idx += 1
	_seg_time = 0.0
	_stuck_timer = 0.0
	_last_dist = INF

func _finish() -> void:
	_done = true
	_release_dirs()
	print("BOT_DONE")

# ── Segmentos ───────────────────────────────────────────────────────────────

func _do_walk_to(seg: Dictionary) -> bool:
	var tx := float(seg.get("x", _player.global_position.x))
	var dx := tx - _player.global_position.x
	if absf(dx) < TOL:
		return true
	_press_dir(signf(dx))
	if _player.is_on_wall() and _player.is_on_floor():
		_tap_jump()
	return false

func _do_climb_to(seg: Dictionary) -> bool:
	var ty := float(seg.get("y", _player.global_position.y))
	if _player.global_position.y <= ty:
		return true
	var dir := -1.0 if str(seg.get("side", "left")) == "left" else 1.0
	_press_dir(dir)
	if _player.is_on_wall():
		_tap_jump()
	return false

func _do_drop(seg: Dictionary) -> bool:
	_press_dir(float(seg.get("dir", 1.0)))
	return (not _player.is_on_floor()) and _player.velocity.y > 0.0

func _do_wait(seg: Dictionary, delta: float) -> bool:
	_seg_time += delta
	return _seg_time >= float(seg.get("seconds", 0.5))

func _do_screenshot(seg: Dictionary) -> bool:
	print("BOT_SHOT:%02d:%s" % [StageManager.current_stage_id, str(seg.get("label", "shot"))])
	return true

# ── Travamento ──────────────────────────────────────────────────────────────

func _check_stuck(seg: Dictionary, delta: float) -> bool:
	var d := _dist_to_goal(seg)
	if d < _last_dist - STUCK_EPS:
		_last_dist = d
		_stuck_timer = 0.0
	else:
		_stuck_timer += delta
		if _stuck_timer >= STUCK_TIMEOUT:
			var p := _player.global_position
			print("BOT_STUCK:%s@%d,%d" % [str(seg.get("label", seg.get("t", "?"))), int(p.x), int(p.y)])
			_done = true
			_release_dirs()
			return true
	return false

func _dist_to_goal(seg: Dictionary) -> float:
	var p := _player.global_position
	match str(seg.get("t", "")):
		"walk_to":  return absf(float(seg.get("x", p.x)) - p.x)
		"climb_to": return absf(p.y - float(seg.get("y", p.y)))
		_:          return 0.0

# ── Input ─────────────────────────────────────────────────────────────────────

func _press_dir(dir: float) -> void:
	if dir < 0.0:
		Input.action_press("move_left")
		Input.action_release("move_right")
	elif dir > 0.0:
		Input.action_press("move_right")
		Input.action_release("move_left")

func _release_dirs() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")

func _tap_jump() -> void:
	if _jump_hold <= 0.0 and not Input.is_action_pressed("jump"):
		Input.action_press("jump")
		_jump_hold = JUMP_HOLD
