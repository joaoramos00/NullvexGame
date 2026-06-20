extends Node

# Carrega cada cena de inimigo de fogo, confirma instanciação e frame inicial 0 (idle).
const ENEMIES := {
	"res://characters/enemies/stage_01/enemy_magma_grunt.tscn": "EnemyMagmaGrunt",
	"res://characters/enemies/stage_01/enemy_molten_ram.tscn": "EnemyMoltenRam",
	"res://characters/enemies/stage_01/enemy_ash_hopper.tscn": "EnemyAshHopper",
	"res://characters/enemies/stage_01/enemy_flame_skimmer.tscn": "EnemyFlameSkimmer",
	"res://characters/enemies/stage_01/enemy_ember_orbiter.tscn": "EnemyEmberOrbiter",
	"res://characters/enemies/stage_01/enemy_cinder_flyer.tscn": "EnemyCinderFlyer",
}

func _ready() -> void:
	var fail := false
	for path in ENEMIES:
		var scn = load(path)
		if scn == null:
			print("FAIL: não carregou ", path); fail = true; continue
		var e = scn.instantiate()
		add_child(e)
		var spr = e.get_node_or_null("Sprite2D")
		if spr == null:
			print("FAIL: sem Sprite2D em ", path); fail = true
		elif spr.frame != 0:
			print("FAIL: frame inicial != 0 em ", path, " (", spr.frame, ")"); fail = true
		else:
			print("OK: ", ENEMIES[path])
		e.free()
	if fail:
		get_tree().quit(1)
	else:
		print("PASS: melee+fly fire enemies")
		get_tree().quit(0)
