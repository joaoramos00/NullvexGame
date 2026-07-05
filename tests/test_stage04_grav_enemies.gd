extends Node

# Carrega cada cena do roster gravitacional, confirma instanciação + dano/morte, e o
# projétil compartilhado (molde do test_stage01_fire_enemies).
const ENEMIES := {
	"res://characters/enemies/stage_04/enemy_grav_guard.tscn": "EnemyGravGuard",
	"res://characters/enemies/stage_04/enemy_mass_brute.tscn": "EnemyMassBrute",
	"res://characters/enemies/stage_04/enemy_gravity_mine.tscn": "EnemyGravityMine",
	"res://characters/enemies/stage_04/enemy_crush_pylon.tscn": "EnemyCrushPylon",
	"res://characters/enemies/stage_04/enemy_singularity_turret.tscn": "EnemySingularityTurret",
	"res://characters/enemies/stage_04/enemy_grav_well.tscn": "EnemyGravWell",
	"res://characters/enemies/stage_04/enemy_void_drone.tscn": "EnemyVoidDrone",
	"res://characters/enemies/stage_04/enemy_debris_orbiter.tscn": "EnemyDebrisOrbiter",
	"res://characters/enemies/stage_04/enemy_orbit_mauler.tscn": "EnemyOrbitMauler",
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
			print("FAIL: frame inicial != 0 em ", path); fail = true
		elif int(e.current_hp) != int(e.max_hp):
			print("FAIL: hp inicial em ", path); fail = true
		else:
			var hp0: int = e.current_hp
			e.take_damage(2)
			if int(e.current_hp) != hp0 - 2:
				print("FAIL: take_damage em ", path); fail = true
			else:
				print("OK: ", ENEMIES[path])
		e.free()
	var proj = load("res://characters/enemies/stage_04/grav_projectile.tscn").instantiate()
	add_child(proj)
	proj.setup(Vector2(200, 0), 5, "test")
	if proj.damage != 5 or proj.variant != "gravity_bolt":
		print("FAIL: grav_projectile.setup"); fail = true
	else:
		print("OK: grav_projectile")
	proj.free()
	if fail:
		get_tree().quit(1)
	else:
		print("PASS: all grav enemies")
		get_tree().quit(0)
