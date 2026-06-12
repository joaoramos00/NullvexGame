extends Node

## Gerador de SVG de debug por zona da fase 00 (headless, ZERO GPU).
##
## Instancia a cena real stage_00 só para coletar a geometria viva (inimigos,
## elementos criados em código, corredores), classifica via ZoneClassifier e emite
## um .svg por área — retângulos coloridos por tipo + rótulo com o ID de cada
## elemento. Também escreve docs/stage_00/zones/legenda.md.
##
## SVG é vetorial: abre no navegador, zoom infinito, texto selecionável, e não
## depende de render por GPU (evita travar máquinas com GPU fraca). Roda headless:
##   Godot --headless --path . res://tools/zone_debug.tscn -- --area=all
##
## Args (OS.get_cmdline_user_args()):
##   --area=all|z1|corr1|miniboss|corr2|z2|z3|boss   (default all)

const _STAGE_SCENE := preload("res://stages/stage_00/stage_00.tscn")
const _OUT_DIR := "res://docs/stage_00/zones/"
const _PAD: float = 96.0
const _DISPLAY_MAX: float = 2400.0   # maior lado do SVG no tamanho default (zoom ainda livre)
const _FS: int = 24                  # tamanho da fonte dos rótulos (unidades de mundo)

const _AREA_FILE := {
	"Z1": "z1", "Corr1": "corr1", "MiniBoss": "miniboss", "Corr2": "corr2",
	"Z2": "z2", "Z3": "z3", "Boss": "boss",
}

# Cor por tipo (preenchimento do retângulo + contorno claro).
const _TYPE_COLOR := {
	"floor": Color(0.55, 0.55, 0.55),
	"plat":  Color(0.30, 0.85, 0.35),
	"sub":   Color(0.55, 0.95, 0.55),
	"movp":  Color(0.20, 0.90, 0.90),
	"step":  Color(0.65, 0.65, 0.25),
	"block": Color(0.60, 0.42, 0.25),
	"wall":  Color(0.30, 0.50, 0.95),
	"ceil":  Color(0.20, 0.30, 0.70),
	"glass": Color(0.45, 0.75, 0.95),
	"cover": Color(0.50, 0.55, 0.65),
	"door":  Color(0.95, 0.85, 0.20),
	"zone":  Color(0.95, 0.55, 0.15),
	"goal":  Color(0.90, 0.25, 0.85),
	"bound": Color(0.70, 0.15, 0.15),
	"spawn": Color(0.95, 0.95, 0.95),
	"grunt": Color(0.90, 0.25, 0.25),
	"flyer": Color(0.95, 0.45, 0.70),
	"mboss": Color(0.65, 0.30, 0.85),
	"boss":  Color(0.60, 0.10, 0.20),
	"misc":  Color(0.70, 0.70, 0.70),
}

var _areas_filter := ""   # "" = todas
var _stage: Node2D
var _items: Array = []
var _bboxes: Dictionary = {}


func _ready() -> void:
	DebugBoot.no_enemies = false   # garante inimigos spawnados para captura
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

	# _ready do stage + spawns de código (call_deferred/await internos).
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_map_corridors(_stage)
	var records := _collect_records(_stage)
	var zc := ZoneClassifier.new()
	var out := zc.classify(records)
	_items = out.items
	_bboxes = out.area_bboxes

	_ensure_out_dir()

	var made := 0
	for area_name in ZoneClassifier.AREA_ORDER:
		if not _bboxes.has(area_name):
			continue
		if _areas_filter != "" and _AREA_FILE.get(area_name, "") != _areas_filter:
			continue
		var area_items := _items.filter(func(it): return it.area == area_name)
		if area_items.is_empty():
			push_warning("Área %s sem membros — pulando." % area_name)
			continue
		# Caixas grandes ao fundo: ordena por área de rect decrescente, então as
		# pequenas (e seus rótulos) ficam por cima e legíveis.
		area_items.sort_custom(func(a, b):
			return a.rect.get_area() > b.rect.get_area())
		_write_svg(area_name, area_items)
		made += 1

	_write_legend()
	print("zone_debug: concluído. %d SVG + legenda em %s" % [made, _OUT_DIR])


# --- Coleta -----------------------------------------------------------------

# CorridorSections têm corpos internos auto-nomeados (sem prefixo de área). Mapeia
# cada section → "Corr1"/"Corr2" pela ordem em X (esquerda→direita), usado como
# hint de área para os filhos durante o walk.
var _corr_hint: Dictionary = {}   # instance_id (int) → nome da área

func _map_corridors(root: Node) -> void:
	var sections: Array = []
	_find_corridors(root, sections)
	sections.sort_custom(func(a, b):
		return (a as Node2D).global_position.x < (b as Node2D).global_position.x)
	for i in sections.size():
		var area := "Corr1" if i == 0 else ("Corr2" if i == 1 else "Corr%d" % (i + 1))
		_corr_hint[(sections[i] as Node).get_instance_id()] = area


func _find_corridors(n: Node, out: Array) -> void:
	if n is CorridorSection:
		out.append(n)
	for c in n.get_children():
		_find_corridors(c, out)


func _collect_records(root: Node) -> Array:
	var recs: Array = []
	_walk(root, recs, "")
	return recs


const _ENEMY_KINDS := ["grunt", "flyer", "mboss", "boss"]
const _LEAF_KINDS := ["grunt", "flyer", "mboss", "boss", "door"]

func _walk(n: Node, recs: Array, area_hint: String) -> void:
	# Entrar num CorridorSection define o hint de área para toda a subárvore.
	if _corr_hint.has(n.get_instance_id()):
		area_hint = _corr_hint[n.get_instance_id()]

	var kind := _kind_of(n)
	if kind != "":
		var rect := _rect_of(n, kind)
		if rect.size.x > 0.0 and rect.size.y > 0.0:
			recs.append({ "name": String(n.name), "kind": kind, "rect": rect, "area_hint": area_hint })
		else:
			push_warning("Sem rect válido, ignorado: %s" % n.name)
		# Inimigos/portas são folhas: seus filhos (ContactZone, TriggerArea,
		# CollisionShape de detecção) não são elementos próprios — não descer.
		if kind in _LEAF_KINDS:
			return
	for c in n.get_children():
		_walk(c, recs, area_hint)


## Resolve a tag de classe. Ordem importa: EnemyFlyer estende EnemyBase, e
## desempata por path do script (enemy_flyer.gd não tem class_name próprio).
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


const _ENEMY_MARKER := Vector2(72, 96)

## Rect global do elemento. Inimigos viram marcador de tamanho fixo na posição
## (o CollisionShape do corpo costuma ser grande demais — detecção/patrulha — e
## polui o mapa). Estruturas usam o primeiro CollisionShape2D+RectangleShape2D.
func _rect_of(n: Node, kind: String) -> Rect2:
	if kind in _ENEMY_KINDS and n is Node2D:
		var pos: Vector2 = (n as Node2D).global_position
		return Rect2(pos - _ENEMY_MARKER * 0.5, _ENEMY_MARKER)
	for c in n.get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			var cs := c as CollisionShape2D
			var size: Vector2 = (cs.shape as RectangleShape2D).size
			var center: Vector2 = cs.global_position
			return Rect2(center - size * 0.5, size)
	if n is Node2D:
		return Rect2((n as Node2D).global_position - Vector2(32, 32), Vector2(64, 64))
	return Rect2()


# --- SVG --------------------------------------------------------------------

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
	# Fundo escuro cobrindo a viewBox.
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
		push_error("Falha ao abrir %s para escrita" % path)
		return
	f.store_string("\n".join(s))
	f.close()
	print("  svg: %s (%d elementos)" % [path, area_items.size()])


func _append_label(s: PackedStringArray, text: String, anchor: Vector2, hexl: String) -> void:
	var fs := _FS
	var char_w: float = float(fs) * 0.62   # monospace aproximado
	var lbl_w: float = text.length() * char_w + 8.0
	var lbl_h: float = float(fs) + 6.0
	var x := anchor.x + 2.0
	var y := anchor.y + 2.0
	# Fundo do rótulo para legibilidade.
	s.append('<rect x="%s" y="%s" width="%s" height="%s" fill="#000000" fill-opacity="0.7"/>' % [
		_n(x), _n(y), _n(lbl_w), _n(lbl_h)])
	s.append('<text x="%s" y="%s" font-size="%d" fill="%s">%s</text>' % [
		_n(x + 4.0), _n(y + float(fs)), fs, hexl, _esc(text)])


# número compacto para atributos SVG
func _n(v: float) -> String:
	return String.num(v, 2).trim_suffix(".00").trim_suffix("0").trim_suffix(".")


func _esc(t: String) -> String:
	return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


# --- Legenda ----------------------------------------------------------------

func _write_legend() -> void:
	var lines: Array[String] = []
	lines.append("# Legenda — debug por zona (fase 00)")
	lines.append("")
	lines.append("IDs por tipo, globais na fase, ordenados por (x, y). Gerado por `tools/zone_debug.gd`.")
	lines.append("Abra os `.svg` da mesma pasta no navegador para o mapa visual de cada área.")
	lines.append("")
	for area_name in ZoneClassifier.AREA_ORDER:
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
	if f == null:
		push_error("Falha ao abrir legenda.md para escrita")
		return
	f.store_string("\n".join(lines))
	f.close()
	print("  legenda: %slegenda.md" % _OUT_DIR)


func _ensure_out_dir() -> void:
	var abs := ProjectSettings.globalize_path(_OUT_DIR)
	if not DirAccess.dir_exists_absolute(abs):
		var err := DirAccess.make_dir_recursive_absolute(abs)
		if err != OK:
			push_error("Não consegui criar %s (err %d)" % [_OUT_DIR, err])
