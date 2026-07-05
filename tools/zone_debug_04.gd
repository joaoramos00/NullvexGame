extends Node

## Gerador de SVG de debug por zona da FASE 04 (headless, ZERO GPU).
##
## Igual ao tools/zone_debug.gd (fase 00), mas com as zonas do stage_01
## (Z1 / Z2 Rio de Lava / Z3 maré / Z4 cratera / Boss) e tipos extras de hazard
## (lava, geyser, spikes) coloridos à parte — útil pra depurar posicionamento de lava.
##
## Roda headless:
##   Godot --headless --path . res://tools/zone_debug_04.tscn -- --area=all
## Args: --area=all|z1|z2|z3|z4|boss   (default all)

const _STAGE_SCENE := preload("res://stages/stage_04/stage_04.tscn")
const _OUT_DIR := "res://docs/stage_04/zones/"
const _PAD: float = 96.0
const _DISPLAY_MAX: float = 2800.0
const _FS: int = 24

const _AREA_ORDER: Array[String] = ["Z1", "Z2", "Z3", "Z4", "Boss"]
const _AREA_FILE := { "Z1": "z1", "Z2": "z2", "Z3": "z3", "Z4": "z4", "Boss": "boss" }
const _AREA_TITLE := {
	"Z1": "Z1 — poços de gravidade", "Z2": "Z2 — câmaras de empuxo",
	"Z3": "Z3 — esmagadores", "Z4": "Z4 — singularidade", "Boss": "Boss — Gravitus",
}

const _TYPE_COLOR := {
	"floor": Color(0.55, 0.55, 0.55),
	"plat":  Color(0.30, 0.85, 0.35),
	"sub":   Color(0.55, 0.95, 0.55),
	"step":  Color(0.65, 0.65, 0.25),
	"movp":  Color(0.20, 0.90, 0.90),
	"block": Color(0.60, 0.42, 0.25),
	"wall":  Color(0.30, 0.50, 0.95),
	"ceil":  Color(0.20, 0.30, 0.70),
	"glass": Color(0.45, 0.75, 0.95),
	"door":  Color(0.95, 0.85, 0.20),
	"zone":  Color(0.95, 0.55, 0.15),
	"lava":  Color(0.95, 0.30, 0.10),    # hazard de lava (Area instant-kill / maré / chase / coupled)
	"geyser":Color(0.95, 0.75, 0.30),    # gêiser / vapor
	"spikes":Color(0.85, 0.20, 0.45),    # espinhos
	"goal":  Color(0.90, 0.25, 0.85),
	"bound": Color(0.70, 0.15, 0.15),
	"spawn": Color(0.95, 0.95, 0.95),
	"grunt": Color(0.90, 0.25, 0.25),
	"flyer": Color(0.95, 0.45, 0.70),
	"boss":  Color(0.60, 0.10, 0.20),
	"misc":  Color(0.70, 0.70, 0.70),
}

var _areas_filter := ""
var _stage: Node2D
var _items: Array = []
var _bboxes: Dictionary = {}


func _ready() -> void:
	DebugBoot.no_enemies = false
	_parse_args()
	await _run()
	get_tree().quit(0)


func _parse_args() -> void:
	var area := "all"
	for raw in OS.get_cmdline_user_args():
		var a := raw.lstrip("-")
		if a.begins_with("area="):
			area = a.substr(5)
	_areas_filter = "" if area == "all" else area.to_lower()


func _run() -> void:
	_stage = _STAGE_SCENE.instantiate()
	add_child(_stage)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var records := _collect_records(_stage)
	var zc := ZoneClassifier.new()
	# Tipo: classificador genérico + override de hazard por nome (lava/gey/spikes).
	for rec in records:
		rec.type = _type_of(zc, rec.name, rec.get("kind", ""))
	# Área: por prefixo de nome (Z1..Z4/Boss); o resto, pela faixa X mais próxima.
	var ext := _area_extents(records)
	for rec in records:
		var center: Vector2 = rec.rect.position + rec.rect.size * 0.5
		rec.area = _classify_area(rec.name, center, ext)
	zc.assign_ids(records)

	_items = records
	_bboxes = {}
	for rec in records:
		var a: String = rec.area
		if _bboxes.has(a):
			_bboxes[a] = (_bboxes[a] as Rect2).merge(rec.rect)
		else:
			_bboxes[a] = rec.rect

	_ensure_out_dir()
	var made := 0
	for area_name in _AREA_ORDER:
		if not _bboxes.has(area_name):
			continue
		if _areas_filter != "" and _AREA_FILE.get(area_name, "") != _areas_filter:
			continue
		var area_items := _items.filter(func(it): return it.area == area_name)
		if area_items.is_empty():
			continue
		area_items.sort_custom(func(a, b): return a.rect.get_area() > b.rect.get_area())
		_write_svg(area_name, area_items)
		made += 1

	_write_legend()
	_write_index()
	print("zone_debug_04: concluído. %d SVG + legenda + index em %s" % [made, _OUT_DIR])


# --- Tipo (genérico + hazards por nome) -------------------------------------

func _type_of(zc: ZoneClassifier, nm: String, kind: String) -> String:
	if nm.contains("Lava") or nm.contains("Tide"):
		return "lava"
	if nm.contains("Gey") or nm.contains("Steam") or nm.contains("Turbine"):
		return "geyser"
	if nm.contains("Spike"):
		return "spikes"
	if nm.contains("Raft") or nm.contains("Elev") or nm.contains("MovPlat"):
		return "movp"
	if nm.contains("Step"):
		return "step"
	if nm.contains("Heart") and (nm.contains("Wall") or nm.contains("Floor") or nm.contains("Ceil")):
		return "wall"
	return zc.classify_type(nm, kind)


# --- Área (Z1..Z4/Boss por nome; resto pela faixa X) ------------------------

func _area_by_name(nm: String) -> String:
	if nm.begins_with("Boss"):
		return "Boss"
	for z in ["Z1", "Z2", "Z3", "Z4"]:
		if nm.begins_with(z):
			return z
	return ""


func _area_extents(records: Array) -> Dictionary:
	var ext: Dictionary = {}
	for rec in records:
		var a := _area_by_name(rec.name)
		if a == "":
			continue
		var cx: float = rec.rect.position.x + rec.rect.size.x * 0.5
		if ext.has(a):
			var e: Array = ext[a]
			e[0] = minf(e[0], cx)
			e[1] = maxf(e[1], cx)
		else:
			ext[a] = [cx, cx]
	return ext


func _classify_area(nm: String, center: Vector2, ext: Dictionary) -> String:
	var by_name := _area_by_name(nm)
	if by_name != "":
		return by_name
	var best := ""
	var best_dist := INF
	for area in _AREA_ORDER:
		if not ext.has(area):
			continue
		var e: Array = ext[area]
		if center.x >= e[0] and center.x <= e[1]:
			return area
		var d: float = minf(absf(center.x - e[0]), absf(center.x - e[1]))
		if d < best_dist:
			best_dist = d
			best = area
	return best


# --- Coleta (igual ao zone_debug.gd) ----------------------------------------

func _collect_records(root: Node) -> Array:
	var recs: Array = []
	_walk(root, recs)
	return recs

const _LEAF_KINDS := ["grunt", "flyer", "mboss", "boss", "door"]

func _walk(n: Node, recs: Array) -> void:
	var kind := _kind_of(n)
	if kind != "":
		var rect := _rect_of(n, kind)
		if rect.size.x > 0.0 and rect.size.y > 0.0:
			recs.append({ "name": String(n.name), "kind": kind, "rect": rect })
		if kind in _LEAF_KINDS:
			return
	for c in n.get_children():
		_walk(c, recs)


func _kind_of(n: Node) -> String:
	if n is IntroBoss:
		return "boss"
	if n is EnemyMiniBoss:
		return "mboss"
	if n is EnemyBase:
		var scr: Script = n.get_script() as Script
		if scr != null and scr.resource_path.ends_with("enemy_flyer.gd"):
			return "flyer"
		return "grunt"
	if n is CheckpointDoor:
		return "door"
	if String(n.name) == "GoalZone":
		return "goal"
	if String(n.name) == "PlayerSpawn":
		return "spawn"
	if n is AnimatableBody2D:
		return "movp"
	if n is Area2D:
		return "zone"
	if n is StaticBody2D:
		return "static"
	return ""


const _ENEMY_KINDS := ["grunt", "flyer", "mboss", "boss"]
const _ENEMY_MARKER := Vector2(72, 96)

func _rect_of(n: Node, kind: String) -> Rect2:
	if kind in _ENEMY_KINDS and n is Node2D:
		var pos: Vector2 = (n as Node2D).global_position
		return Rect2(pos - _ENEMY_MARKER * 0.5, _ENEMY_MARKER)
	for c in n.get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			var cs := c as CollisionShape2D
			var size: Vector2 = (cs.shape as RectangleShape2D).size
			return Rect2(cs.global_position - size * 0.5, size)
	if n is Node2D:
		return Rect2((n as Node2D).global_position - Vector2(32, 32), Vector2(64, 64))
	return Rect2()


# --- SVG (igual ao zone_debug.gd) -------------------------------------------

func _write_svg(area_name: String, area_items: Array) -> void:
	var bbox: Rect2 = (_bboxes[area_name] as Rect2).grow(_PAD)
	var w: float = bbox.size.x
	var h: float = bbox.size.y
	var scale: float = 1.0
	var maxside: float = maxf(w, h)
	if maxside > _DISPLAY_MAX:
		scale = _DISPLAY_MAX / maxside

	var s := PackedStringArray()
	s.append('<?xml version="1.0" encoding="UTF-8"?>')
	s.append('<svg xmlns="http://www.w3.org/2000/svg" viewBox="%s %s %s %s" width="%d" height="%d" font-family="monospace">' % [
		_n(bbox.position.x), _n(bbox.position.y), _n(w), _n(h),
		int(round(w * scale)), int(round(h * scale))])
	s.append('<rect x="%s" y="%s" width="%s" height="%s" fill="#0a0a12"/>' % [
		_n(bbox.position.x), _n(bbox.position.y), _n(w), _n(h)])

	for it in area_items:
		var col: Color = _TYPE_COLOR.get(it.type, Color.WHITE)
		var r: Rect2 = it.rect
		var hexc := "#" + col.to_html(false)
		var hexl := "#" + col.lightened(0.35).to_html(false)
		s.append('<rect x="%s" y="%s" width="%s" height="%s" fill="%s" fill-opacity="0.82" stroke="%s" stroke-width="2"/>' % [
			_n(r.position.x), _n(r.position.y), _n(r.size.x), _n(r.size.y), hexc, hexl])
		_append_label(s, it.id, r.position, hexl)

	s.append('</svg>')
	var path := "%s%s.svg" % [_OUT_DIR, _AREA_FILE[area_name]]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Falha ao abrir %s" % path)
		return
	f.store_string("\n".join(s))
	f.close()
	print("  svg: %s (%d elementos)" % [path, area_items.size()])


func _append_label(s: PackedStringArray, text: String, anchor: Vector2, hexl: String) -> void:
	var fs := _FS
	var char_w: float = float(fs) * 0.62
	var lbl_w: float = text.length() * char_w + 8.0
	var lbl_h: float = float(fs) + 6.0
	var x := anchor.x + 2.0
	var y := anchor.y + 2.0
	s.append('<rect x="%s" y="%s" width="%s" height="%s" fill="#000000" fill-opacity="0.7"/>' % [
		_n(x), _n(y), _n(lbl_w), _n(lbl_h)])
	s.append('<text x="%s" y="%s" font-size="%d" fill="%s">%s</text>' % [
		_n(x + 4.0), _n(y + float(fs)), fs, hexl, _esc(text)])


func _n(v: float) -> String:
	return String.num(v, 2).trim_suffix(".00").trim_suffix("0").trim_suffix(".")

func _esc(t: String) -> String:
	return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


# --- Legenda + index --------------------------------------------------------

func _write_legend() -> void:
	var lines: Array[String] = []
	lines.append("# Legenda — debug por zona (fase 01)")
	lines.append("")
	lines.append("IDs por tipo, globais na fase, ordenados por (x, y). Gerado por `tools/zone_debug_01.gd`.")
	lines.append("Hazards de lava aparecem como tipo `lava` (vermelho). Abra os `.svg` no navegador.")
	lines.append("")
	for area_name in _AREA_ORDER:
		var rows := _items.filter(func(it): return it.area == area_name)
		if rows.is_empty():
			continue
		rows.sort_custom(func(a, b): return a.id < b.id)
		lines.append("## %s" % area_name)
		lines.append("")
		lines.append("| ID | nó real | tipo | rect (x, y, w, h) |")
		lines.append("|----|---------|------|-------------------|")
		for it in rows:
			var r: Rect2 = it.rect
			lines.append("| %s | %s | %s | (%d, %d, %d, %d) |" % [
				it.id, it.name, it.type,
				int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)])
		lines.append("")
	var f := FileAccess.open(_OUT_DIR + "legenda.md", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines))
		f.close()
		print("  legenda: %slegenda.md" % _OUT_DIR)


func _write_index() -> void:
	var s := PackedStringArray()
	s.append('<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8">')
	s.append('<title>Debug por zona — Fase 01</title>')
	s.append('<style>body{background:#0a0a12;color:#ddd;font-family:monospace;margin:16px}')
	s.append('h2{margin-top:32px}img{max-width:100%;border:1px solid #333;background:#0a0a12}')
	s.append('.nav a{color:#5cf;margin-right:12px}</style></head><body>')
	s.append('<h1>Debug por zona — Fase 01</h1>')
	s.append('<div class="nav">')
	for area_name in _AREA_ORDER:
		s.append('<a href="#%s">%s</a>' % [_AREA_FILE[area_name], area_name])
	s.append('</div>')
	for area_name in _AREA_ORDER:
		if not _bboxes.has(area_name):
			continue
		s.append('<h2 id="%s">%s</h2>' % [_AREA_FILE[area_name], _AREA_TITLE.get(area_name, area_name)])
		s.append('<div><img src="%s.svg" alt="%s"></div>' % [_AREA_FILE[area_name], area_name])
	s.append('</body></html>')
	var f := FileAccess.open(_OUT_DIR + "index.html", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(s))
		f.close()
		print("  index: %sindex.html" % _OUT_DIR)


func _ensure_out_dir() -> void:
	var abs := ProjectSettings.globalize_path(_OUT_DIR)
	if not DirAccess.dir_exists_absolute(abs):
		DirAccess.make_dir_recursive_absolute(abs)
