extends Node

# Carrega cada cena do roster elétrico, confirma instanciação + dano/morte, e o
# projétil compartilhado (molde do test_stage01_fire_enemies).
const ENEMIES := {
	"res://characters/enemies/stage_03/enemy_volt_guard.tscn": "EnemyVoltGuard",
	"res://characters/enemies/stage_03/enemy_rail_runner.tscn": "EnemyRailRunner",
	"res://characters/enemies/stage_03/enemy_static_interceptor.tscn": "EnemyStaticInterceptor",
	"res://characters/enemies/stage_03/enemy_tesla_coil.tscn": "EnemyTeslaCoil",
	"res://characters/enemies/stage_03/enemy_arc_turret.tscn": "EnemyArcTurret",
	"res://characters/enemies/stage_03/enemy_storm_kite.tscn": "EnemyStormKite",
	"res://characters/enemies/stage_03/enemy_thunder_hawklet.tscn": "EnemyThunderHawklet",
	"res://characters/enemies/stage_03/enemy_arc_orbiter.tscn": "EnemyArcOrbiter",
	"res://characters/enemies/stage_03/enemy_storm_relay.tscn": "EnemyStormRelay",
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
	var proj = load("res://characters/enemies/stage_03/arc_projectile.tscn").instantiate()
	add_child(proj)
	proj.setup(Vector2(200, 0), 5, "test")
	if proj.damage != 5 or proj.variant != "arc_bolt":
		print("FAIL: arc_projectile.setup"); fail = true
	else:
		print("OK: arc_projectile")
	proj.free()
	if fail:
		get_tree().quit(1)
	else:
		print("PASS: all arc enemies")
		get_tree().quit(0)
