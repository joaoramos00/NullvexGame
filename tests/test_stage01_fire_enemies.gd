extends Node

# Carrega cada cena de inimigo de fogo, confirma instanciação e frame inicial 0 (idle).
const MELEE := {
	"res://characters/enemies/stage_01/enemy_magma_grunt.tscn": "EnemyMagmaGrunt",
	"res://characters/enemies/stage_01/enemy_molten_ram.tscn": "EnemyMoltenRam",
	"res://characters/enemies/stage_01/enemy_ash_hopper.tscn": "EnemyAshHopper",
}

func _ready() -> void:
	var fail := false
	for path in MELEE:
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
			print("OK: ", MELEE[path])
		e.free()
	if fail:
		get_tree().quit(1)
	else:
		print("PASS: melee fire enemies")
		get_tree().quit(0)
