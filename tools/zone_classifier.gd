class_name ZoneClassifier
extends RefCounted

## Classificador puro (sem GPU/cena) usado pelo gerador de PNG de debug da fase 00.
##
## Entrada: lista de registros { name: String, kind: String, rect: Rect2 }
##   - kind é a tag já resolvida pelo chamador (zone_debug) a partir da classe do nó:
##     "boss","mboss","grunt","flyer","door","goal","spawn","movp","zone","static".
## Saída de classify(): { items: Array, area_bboxes: Dictionary }
##   - cada item: { id, type, area, name, rect }
##
## Substrings de nome colidem ("MiniBoss" contém "Boss", "SubPlat" contém "Plat"),
## então a ORDEM de avaliação é obrigatória — ver classify_type/classify_area.

# Ordem de área: MiniBoss antes de Boss; Z3 antes de Z2 não é exigido por colisão,
# mas mantém o corredor CorrZ3 junto da Z3.
const AREA_ORDER: Array[String] = ["Z1", "Corr1", "MiniBoss", "Corr2", "Z3", "Z2", "Boss"]


func classify_type(node_name: String, kind: String) -> String:
	# Inimigos e nós singulares vêm com kind resolvido pelo chamador.
	match kind:
		"boss":  return "boss"
		"mboss": return "mboss"
		"flyer": return "flyer"
		"grunt": return "grunt"
		"door":  return "door"

	if kind == "goal" or node_name == "GoalZone":
		return "goal"
	if kind == "spawn" or node_name == "PlayerSpawn":
		return "spawn"
	if node_name.contains("Boundary"):
		return "bound"

	# movp e sub ANTES de plat (ambos contêm "Plat").
	if kind == "movp" or kind == "animatable" or node_name.contains("Moving"):
		return "movp"
	if node_name.contains("SubPlat"):
		return "sub"
	if node_name.contains("Plat"):
		return "plat"

	if node_name.contains("Step"):
		return "step"
	if node_name.contains("Block"):
		return "block"
	if node_name.contains("Glass"):
		return "glass"
	if node_name.contains("Cover"):
		return "cover"
	if node_name.contains("Ceil"):
		return "ceil"
	if node_name.contains("Wall") or node_name.contains("Div"):
		return "wall"
	if node_name.contains("Floor"):
		return "floor"
	if kind == "zone":
		return "zone"
	return "misc"


## Área por prefixo de nome. Retorna "" se o nome não codifica área
## (resolvido depois por posição X em classify_area).
func area_by_name(node_name: String) -> String:
	if node_name.contains("Z1"):
		return "Z1"
	if node_name.begins_with("Corr1"):
		return "Corr1"
	if node_name.contains("MiniBoss"):
		return "MiniBoss"
	if node_name.begins_with("Corr2"):
		return "Corr2"
	if node_name.contains("CorrZ3") or node_name.contains("Z3"):
		return "Z3"
	if node_name.contains("Z2"):
		return "Z2"
	if node_name.contains("Boss") or node_name == "GoalZone":
		return "Boss"
	return ""


## Área final: nome primeiro, senão pela faixa X do centro.
## area_extents: { area: [min_x, max_x] } computado dos membros já atribuídos por nome.
func classify_area(node_name: String, center: Vector2, area_extents: Dictionary) -> String:
	var by_name := area_by_name(node_name)
	if by_name != "":
		return by_name
	# Fallback por X: a área cujo intervalo contém center.x; se nenhum, a mais próxima.
	var best := ""
	var best_dist := INF
	for area in AREA_ORDER:
		if not area_extents.has(area):
			continue
		var ext: Array = area_extents[area]
		var lo: float = ext[0]
		var hi: float = ext[1]
		if center.x >= lo and center.x <= hi:
			return area
		var d: float = minf(absf(center.x - lo), absf(center.x - hi))
		if d < best_dist:
			best_dist = d
			best = area
	return best


## Faixa X [min, max] por área, considerando só registros resolvidos por nome.
func area_extents(records: Array) -> Dictionary:
	var ext: Dictionary = {}
	for rec in records:
		var area := area_by_name(rec.name)
		if area == "":
			continue
		var cx: float = rec.rect.position.x + rec.rect.size.x * 0.5
		if ext.has(area):
			var e: Array = ext[area]
			e[0] = minf(e[0], cx)
			e[1] = maxf(e[1], cx)
		else:
			ext[area] = [cx, cx]
	return ext


## Atribui IDs por tipo, global na fase, ordenado por (x, y) asc.
## records esperado já com { name, type, area, rect }. Retorna a mesma lista com `id`.
func assign_ids(records: Array) -> Array:
	var by_type: Dictionary = {}
	for rec in records:
		var t: String = rec.type
		if not by_type.has(t):
			by_type[t] = []
		by_type[t].append(rec)
	for t in by_type:
		var group: Array = by_type[t]
		group.sort_custom(func(a, b):
			if a.rect.position.x != b.rect.position.x:
				return a.rect.position.x < b.rect.position.x
			return a.rect.position.y < b.rect.position.y)
		var n: int = 1
		for rec in group:
			rec.id = "%s%03d" % [t, n]
			n += 1
	return records


## Orquestra: type → extents → area → ids; bbox por área.
func classify(records: Array) -> Dictionary:
	for rec in records:
		rec.type = classify_type(rec.name, rec.get("kind", ""))
	var ext := area_extents(records)
	for rec in records:
		var center: Vector2 = rec.rect.position + rec.rect.size * 0.5
		rec.area = classify_area(rec.name, center, ext)
	assign_ids(records)

	var bboxes: Dictionary = {}
	for rec in records:
		var a: String = rec.area
		if bboxes.has(a):
			bboxes[a] = bboxes[a].merge(rec.rect)
		else:
			bboxes[a] = rec.rect
	return { "items": records, "area_bboxes": bboxes }
