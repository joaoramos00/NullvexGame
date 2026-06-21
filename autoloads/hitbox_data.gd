extends Node

signal reloaded

const _PATH := "res://data/hitbox_overrides.json"

var _data: Dictionary = {}

func _ready() -> void:
	_load_baked()

func _load_baked() -> void:
	if not FileAccess.file_exists(_PATH):
		_data = {}
		return
	var f := FileAccess.open(_PATH, FileAccess.READ)
	if f == null:
		_data = {}
		return
	var parsed = JSON.parse_string(f.get_as_text())
	_data = parsed if parsed is Dictionary else {}

func reload() -> void:
	_load_baked()
	reloaded.emit()

func set_data(d: Dictionary) -> void:
	_data = d
	reloaded.emit()

func has(id: String) -> bool:
	return _data.has(id)

func entry(id: String) -> Dictionary:
	return _data.get(id, {})

func proj_offset(id: String, direction: float) -> Vector2:
	var e := entry(id)
	if not e.has("projectile"):
		return Vector2.INF
	var o = e["projectile"].get("offset", null)
	if not (o is Array) or o.size() < 2:
		return Vector2.INF
	return Vector2(float(o[0]) * (1.0 if direction >= 0.0 else -1.0), float(o[1]))

func frame_shapes(id: String, frame: int) -> Array:
	var out: Array = []
	var e := entry(id)
	for s in e.get("shapes", []):
		var fr = s.get("frames", "all")
		if (fr is String and fr == "all") or (fr is Array and fr.has(frame)):
			out.append(s)
	return out
