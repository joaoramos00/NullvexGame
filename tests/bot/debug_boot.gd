# tests/bot/debug_boot.gd — autoload "DebugBoot"
extends Node

var bot_enabled: bool = false
var no_enemies:  bool = false
var white_bg:    bool = false   # fundo branco de debug (?whitebg=1) — só pra visualizar tiles
var z3debug:     bool = false   # marcadores de debug na zona 3 (?z3debug=1) — bordas de pisos/curso da plataforma
var stage_id:    int  = -1
var zone:        int  = -1   # spawna direto numa zona da fase (debug). -1 = início normal
var active_char: String = "zael"
var _booted: bool = false

static func parse_params(query: String) -> Dictionary:
	var out := {}
	var q := query.lstrip("?")
	if q == "":
		return out
	for pair in q.split("&", false):
		var kv := pair.split("=", true, 1)
		var key: String = kv[0]
		var val: String = kv[1] if kv.size() > 1 else ""
		if key != "":
			out[key] = val
	return out

func _ready() -> void:
	var params := parse_params(_get_query_string())
	if not params.has("stage"):
		return  # inerte — jogo inicia normal pelo título
	stage_id    = int(params.get("stage", "-1"))
	bot_enabled = params.get("bot", "0") == "1"
	no_enemies  = params.get("noenemies", "0") == "1"
	white_bg    = params.get("whitebg", "0") == "1"
	z3debug     = params.get("z3debug", "0") == "1"
	active_char = params.get("char", "zael")
	# zona: aceita "zone=3" e também o formato-flag "zone01"/"zone3"
	zone = int(params.get("zone", "-1"))
	if zone < 0:
		for k: String in params:
			if k.begins_with("zone") and k.substr(4).is_valid_int():
				zone = int(k.substr(4))
				break
	call_deferred("_boot")

func _get_query_string() -> String:
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("window.location.search", true))
	var parts := PackedStringArray()
	for arg in OS.get_cmdline_user_args():
		parts.append(arg.lstrip("-"))
	return "&".join(parts)

func _boot() -> void:
	if _booted or stage_id < 0:
		return
	_booted = true
	GameManager.reset()
	GameManager.set_active_character(active_char)
	StageManager.current_stage_id = stage_id
	var path := "res://stages/stage_%02d/stage_%02d.tscn" % [stage_id, stage_id]
	if not ResourceLoader.exists(path):
		push_error("DebugBoot: cena inexistente %s" % path)
		return
	get_tree().change_scene_to_file(path)
