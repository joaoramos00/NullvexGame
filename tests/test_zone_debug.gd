extends Node

## Testa ZoneClassifier (puro, sem GPU) com fixtures espelhando nós reais da fase 00.

func _ready() -> void:
	test_classify_type()
	test_area_by_name()
	test_classify_area_by_x()
	test_assign_ids_global_per_type()
	test_classify_full_fixtures()
	print("ALL TESTS PASSED")
	get_tree().quit(0)


func _rec(name: String, kind: String, rect: Rect2) -> Dictionary:
	return { "name": name, "kind": kind, "rect": rect }


func test_classify_type() -> void:
	var zc := ZoneClassifier.new()
	# movp e sub ANTES de plat (colisão de substring).
	assert(zc.classify_type("Z3MovingPlat", "movp") == "movp", "Z3MovingPlat → movp")
	assert(zc.classify_type("SubPlat_Z3_A", "static") == "sub", "SubPlat → sub")
	assert(zc.classify_type("Plat_Z1A", "static") == "plat", "Plat → plat")
	# Inimigos por kind.
	assert(zc.classify_type("@EnemyBase@5", "grunt") == "grunt", "grunt por kind")
	assert(zc.classify_type("@EnemyFlyer@7", "flyer") == "flyer", "flyer por kind")
	assert(zc.classify_type("IntroBoss", "boss") == "boss", "boss por kind")
	assert(zc.classify_type("EnemyMiniBoss", "mboss") == "mboss", "mboss por kind")
	# Estruturais.
	assert(zc.classify_type("Floor_Z1A", "static") == "floor", "Floor → floor")
	assert(zc.classify_type("Corr1_Wall_L", "static") == "wall", "Wall → wall")
	assert(zc.classify_type("Div_Z3_X", "static") == "wall", "Div → wall")
	assert(zc.classify_type("Glass_Z3_Ceil", "static") == "glass", "Glass antes de Ceil → glass")
	assert(zc.classify_type("MiniBoss_Ceil", "static") == "ceil", "Ceil → ceil")
	assert(zc.classify_type("Block_Z1A", "static") == "block", "Block → block")
	assert(zc.classify_type("Step_Z2_1", "static") == "step", "Step → step")
	assert(zc.classify_type("Cover_Z2", "static") == "cover", "Cover → cover")
	# Especiais.
	assert(zc.classify_type("GoalZone", "goal") == "goal", "GoalZone → goal")
	assert(zc.classify_type("PlayerSpawn", "spawn") == "spawn", "PlayerSpawn → spawn")
	assert(zc.classify_type("LBoundary", "static") == "bound", "Boundary → bound")
	assert(zc.classify_type("Corr1_door", "door") == "door", "door por kind")
	print("PASS: classify_type")


func test_area_by_name() -> void:
	var zc := ZoneClassifier.new()
	assert(zc.area_by_name("Plat_Z1A") == "Z1", "Z1")
	assert(zc.area_by_name("Corr1_Wall_L") == "Corr1", "Corr1")
	# Crítico: MiniBoss antes de Boss.
	assert(zc.area_by_name("MiniBoss_Floor") == "MiniBoss", "MiniBoss não Boss")
	assert(zc.area_by_name("Corr2_Ceil") == "Corr2", "Corr2")
	assert(zc.area_by_name("CorrZ3_Entry_Ceil") == "Z3", "CorrZ3 → Z3")
	assert(zc.area_by_name("SubPlat_Z3_A") == "Z3", "Z3")
	assert(zc.area_by_name("Step_Z2_1") == "Z2", "Z2")
	assert(zc.area_by_name("Boss_Floor") == "Boss", "Boss")
	assert(zc.area_by_name("GoalZone") == "Boss", "GoalZone → Boss")
	assert(zc.area_by_name("PlayerSpawn") == "", "PlayerSpawn sem área por nome")
	print("PASS: area_by_name")


func test_classify_area_by_x() -> void:
	var zc := ZoneClassifier.new()
	# Z1 cobre X 0..2000, Boss cobre 16000..18000.
	var ext := { "Z1": [500.0, 1500.0], "Boss": [16500.0, 17500.0] }
	# Inimigo sem prefixo em X dentro de Z1 → Z1.
	assert(zc.classify_area("@EnemyBase@9", Vector2(800, 300), ext) == "Z1", "enemy em Z1 por X")
	# PlayerSpawn perto de Z1 → Z1 (mais próximo).
	assert(zc.classify_area("PlayerSpawn", Vector2(100, 300), ext) == "Z1", "spawn por X")
	# Nome ganha do X.
	assert(zc.classify_area("Boss_Floor", Vector2(0, 0), ext) == "Boss", "nome > X")
	# Hint (ancestral CorridorSection) entra antes do X para nós auto-nomeados.
	assert(zc.classify_area("@StaticBody2D@17", Vector2(5800, 900), ext, "Corr1") == "Corr1",
		"hint Corr1 para corpo auto-nomeado")
	# Nome ainda ganha do hint.
	assert(zc.classify_area("Boss_Floor", Vector2(0, 0), ext, "Corr1") == "Boss", "nome > hint")
	print("PASS: classify_area_by_x")


func test_assign_ids_global_per_type() -> void:
	var zc := ZoneClassifier.new()
	var recs := [
		{ "name": "Plat_B", "type": "plat", "rect": Rect2(900, 100, 64, 64) },
		{ "name": "Plat_A", "type": "plat", "rect": Rect2(300, 100, 64, 64) },
		{ "name": "Plat_C", "type": "plat", "rect": Rect2(300, 50, 64, 64) },
		{ "name": "Grunt_1", "type": "grunt", "rect": Rect2(500, 0, 32, 32) },
	]
	zc.assign_ids(recs)
	var by_name := {}
	for r in recs:
		by_name[r.name] = r.id
	# Ordenado por (x,y): Plat_C (300,50) < Plat_A (300,100) < Plat_B (900,100).
	assert(by_name["Plat_C"] == "plat001", "menor (x,y) → plat001, veio " + by_name["Plat_C"])
	assert(by_name["Plat_A"] == "plat002", "plat002")
	assert(by_name["Plat_B"] == "plat003", "plat003")
	# Numeração independente por tipo.
	assert(by_name["Grunt_1"] == "grunt001", "grunt começa em 001")
	# Únicos.
	var ids := [by_name["Plat_A"], by_name["Plat_B"], by_name["Plat_C"]]
	assert(ids[0] != ids[1] and ids[1] != ids[2] and ids[0] != ids[2], "IDs únicos")
	print("PASS: assign_ids_global_per_type")


func test_classify_full_fixtures() -> void:
	var zc := ZoneClassifier.new()
	var records := [
		_rec("Plat_Z1A", "static", Rect2(300, 400, 200, 64)),
		_rec("Floor_Z1A", "static", Rect2(0, 600, 800, 128)),
		_rec("Corr1_Wall_L", "static", Rect2(2000, 200, 64, 400)),
		_rec("MiniBoss_Floor", "static", Rect2(3000, 600, 800, 128)),
		_rec("Z3MovingPlat", "movp", Rect2(14000, 300, 200, 32)),
		_rec("SubPlat_Z3_A", "static", Rect2(14100, 250, 128, 32)),
		_rec("GoalZone", "goal", Rect2(17000, 200, 300, 400)),
		# Inimigo sem prefixo, X dentro de Z1.
		_rec("@EnemyBase@3", "grunt", Rect2(400, 500, 48, 48)),
	]
	var out := zc.classify(records)
	var items: Array = out.items
	var by_name := {}
	for it in items:
		by_name[it.name] = it
	assert(by_name["Plat_Z1A"].type == "plat", "Plat_Z1A type")
	assert(by_name["Plat_Z1A"].area == "Z1", "Plat_Z1A area")
	assert(by_name["Corr1_Wall_L"].type == "wall", "wall type")
	assert(by_name["Corr1_Wall_L"].area == "Corr1", "Corr1 area")
	assert(by_name["MiniBoss_Floor"].area == "MiniBoss", "MiniBoss area (não Boss)")
	assert(by_name["Z3MovingPlat"].type == "movp", "movp type")
	assert(by_name["Z3MovingPlat"].area == "Z3", "Z3 area")
	assert(by_name["GoalZone"].type == "goal", "goal type")
	assert(by_name["GoalZone"].area == "Boss", "GoalZone → Boss area")
	assert(by_name["@EnemyBase@3"].type == "grunt", "grunt type")
	assert(by_name["@EnemyBase@3"].area == "Z1", "grunt em Z1 por X")
	# bbox da área existe e engloba os membros.
	assert(out.area_bboxes.has("Z1"), "bbox Z1")
	assert(out.area_bboxes["Z1"].has_point(Vector2(400, 450)), "bbox Z1 contém membro")
	print("PASS: classify_full_fixtures")
