extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	_test_ice_grunt_defaults()
	_test_ice_grunt_visual_scale()
	_test_ice_flyer_defaults()
	_test_ice_miniboss_defaults()
	_test_ice_projectile_defaults()
	_test_ice_archer_defaults()
	_test_frost_turret_defaults()
	_test_cryo_bomber_defaults()
	_test_glacier_shield_defaults()
	_test_ice_wisp_defaults()
	_test_stage02_loads_new_enemy_scenes()
	_test_stage02_spawns_new_enemy_mix()
	_print_results()
	get_tree().quit(0 if _failed == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: " + msg)
	else:
		_failed += 1
		print("  FAIL: " + msg)

func _load_enemy_script(path: String) -> Script:
	var script := load(path) as Script
	_assert(script != null, path + " exists")
	return script

func _test_ice_grunt_defaults() -> void:
	var script := _load_enemy_script("res://characters/enemies/stage_02/enemy_ice_grunt.gd")
	if script == null:
		return
	var enemy: EnemyBase = script.new()
	_assert(enemy.max_hp >= 10, "ice grunt has stronger hp than base grunt")
	_assert(enemy.contact_damage >= 8, "ice grunt keeps meaningful contact damage")
	enemy.free()

func _test_ice_grunt_visual_scale() -> void:
	var scene := load("res://characters/enemies/stage_02/enemy_ice_grunt.tscn") as PackedScene
	_assert(scene != null, "ice grunt scene exists for visual scale check")
	if scene == null:
		return
	var enemy := scene.instantiate()
	var sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
	_assert(sprite != null, "ice grunt has Sprite2D")
	if sprite != null:
		_assert(sprite.scale.is_equal_approx(Vector2(0.7, 0.7)), "ice grunt visual scale stays below oversized 2x zoom")
		_assert(is_equal_approx(sprite.position.y, -5.0), "ice grunt visual bottom aligns with floor line")
	enemy.free()

func _test_ice_flyer_defaults() -> void:
	var script := _load_enemy_script("res://characters/enemies/stage_02/enemy_ice_flyer.gd")
	if script == null:
		return
	var enemy: EnemyBase = script.new()
	_assert(enemy.detect_radius >= 220.0, "ice flyer detects from long range")
	_assert(enemy.dive_speed >= 300.0, "ice flyer dives faster than base flyer")
	enemy.free()

func _test_ice_miniboss_defaults() -> void:
	var script := _load_enemy_script("res://characters/enemies/stage_02/enemy_ice_miniboss.gd")
	if script == null:
		return
	var enemy: EnemyBase = script.new()
	_assert(enemy.max_hp >= 40, "MB02 has miniboss hp")
	_assert(enemy.has_signal("died"), "MB02 inherits died signal")
	enemy.free()

func _test_ice_projectile_defaults() -> void:
	var scene := load("res://characters/enemies/stage_02/enemy_ice_projectile.tscn") as PackedScene
	_assert(scene != null, "ice projectile scene exists")
	if scene == null:
		return
	var projectile := scene.instantiate()
	_assert(projectile.has_method("setup"), "ice projectile exposes setup")
	_assert(projectile.get("damage") >= 4, "ice projectile has damage")
	_assert(projectile.get("gravity") >= 0.0, "ice projectile supports gravity")
	projectile.free()

func _test_ice_archer_defaults() -> void:
	var script := _load_enemy_script("res://characters/enemies/stage_02/enemy_ice_archer.gd")
	if script == null:
		return
	var enemy: EnemyBase = script.new()
	_assert(enemy.max_hp >= 12, "ice archer is tougher than grunt")
	_assert(enemy.get("shoot_range") >= 420.0, "ice archer shoots from range")
	_assert(enemy.get("projectile_speed") >= 260.0, "ice archer projectile is fast enough")
	enemy.free()

func _test_frost_turret_defaults() -> void:
	var script := _load_enemy_script("res://characters/enemies/stage_02/enemy_frost_turret.gd")
	if script == null:
		return
	var enemy: EnemyBase = script.new()
	_assert(enemy.max_hp >= 14, "frost turret has armored hp")
	_assert(enemy.get("shoot_interval") <= 1.6, "frost turret fires frequently")
	_assert(enemy.get("projectile_speed") >= 220.0, "frost turret projectile has pressure")
	enemy.free()

func _test_cryo_bomber_defaults() -> void:
	var script := _load_enemy_script("res://characters/enemies/stage_02/enemy_cryo_bomber.gd")
	if script == null:
		return
	var enemy: EnemyBase = script.new()
	_assert(enemy.max_hp >= 16, "cryo bomber has heavy hp")
	_assert(enemy.get("projectile_gravity") > 0.0, "cryo bomber uses arcing projectile gravity")
	_assert(enemy.get("lob_velocity").y < 0.0, "cryo bomber launches upward")
	enemy.free()

func _test_glacier_shield_defaults() -> void:
	var script := _load_enemy_script("res://characters/enemies/stage_02/enemy_glacier_shield.gd")
	if script == null:
		return
	var enemy: EnemyBase = script.new()
	_assert(enemy.max_hp >= 18, "glacier shield has heavy hp")
	_assert(enemy.get("front_damage_multiplier") < 1.0, "glacier shield reduces front damage")
	_assert(enemy.get("shielded_patrol_speed") <= 60.0, "glacier shield advances slowly")
	enemy.free()

func _test_ice_wisp_defaults() -> void:
	var script := _load_enemy_script("res://characters/enemies/stage_02/enemy_ice_wisp.gd")
	if script == null:
		return
	var enemy: EnemyBase = script.new()
	_assert(enemy.max_hp >= 8, "ice wisp has light hp")
	_assert(enemy.get("hover_amplitude") >= 16.0, "ice wisp hovers visibly")
	_assert(enemy.get("burst_count") >= 2, "ice wisp fires bursts")
	enemy.free()

func _test_stage02_loads_new_enemy_scenes() -> void:
	var scene := load("res://stages/stage_02/stage_02.tscn") as PackedScene
	_assert(scene != null, "stage_02 scene loads for enemy scene check")
	if scene == null:
		return
	var inst := scene.instantiate()
	inst._load_resources()
	_assert(inst.get("_archer_scene") != null, "stage02 loads ice archer scene")
	_assert(inst.get("_turret_scene") != null, "stage02 loads frost turret scene")
	_assert(inst.get("_bomber_scene") != null, "stage02 loads cryo bomber scene")
	_assert(inst.get("_shield_scene") != null, "stage02 loads glacier shield scene")
	_assert(inst.get("_wisp_scene") != null, "stage02 loads ice wisp scene")
	inst.free()

func _test_stage02_spawns_new_enemy_mix() -> void:
	var scene := load("res://stages/stage_02/stage_02.tscn") as PackedScene
	_assert(scene != null, "stage_02 scene loads for enemy spawn check")
	if scene == null:
		return
	var inst := scene.instantiate()
	inst._load_resources()
	for zone in [1, 2, 3, 4]:
		inst._spawn_zone_enemies(zone)
	_assert(_has_child_of_type(inst, "EnemyIceArcher"), "stage02 spawns ice archers")
	_assert(_has_child_of_type(inst, "EnemyFrostTurret"), "stage02 spawns frost turrets")
	_assert(_has_child_of_type(inst, "EnemyCryoBomber"), "stage02 spawns cryo bombers")
	_assert(_has_child_of_type(inst, "EnemyGlacierShield"), "stage02 spawns glacier shields")
	_assert(_has_child_of_type(inst, "EnemyIceWisp"), "stage02 spawns ice wisps")
	inst.free()

func _has_child_of_type(root: Node, type_name: String) -> bool:
	for child in root.get_children():
		if child.get_script() != null and child.get_script().get_global_name() == type_name:
			return true
	return false

func _print_results() -> void:
	print("\n=== test_stage02_enemies: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TESTS FAILED")
