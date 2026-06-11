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
	_test_stage02_non_miniboss_enemies_have_visible_motion()
	_test_stage02_action_sprite_grids()
	_test_stage02_looping_enemy_frames_advance()
	_test_stage02_shot_release_frames_spawn_projectiles()
	_test_stage02_ranged_ground_enemies_hold_position()
	_test_stage02_fixed_facing_ranged_enemies_do_not_turn()
	_test_stage02_ranged_enemy_hitboxes_use_tuned_body_bounds()
	_test_stage02_ranged_enemy_sprites_are_lifted_over_hitboxes()
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
		_assert(is_equal_approx(sprite.position.y, -1.0), "ice grunt visual bottom aligns with floor line")
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

func _test_stage02_non_miniboss_enemies_have_visible_motion() -> void:
	for path in [
		"res://characters/enemies/stage_02/enemy_ice_flyer.tscn",
		"res://characters/enemies/stage_02/enemy_glacier_shield.tscn",
		"res://characters/enemies/stage_02/enemy_ice_wisp.tscn",
	]:
		var scene := load(path) as PackedScene
		_assert(scene != null, path + " scene exists for visible motion")
		if scene == null:
			continue
		var enemy := scene.instantiate() as EnemyBase
		add_child(enemy)
		var sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
		_assert(sprite != null, path + " has Sprite2D for visible motion")
		if sprite != null:
			var frame_before := sprite.frame
			var pos_before := sprite.position
			var rot_before := sprite.rotation
			enemy._physics_process(0.25)
			var moved_visually := sprite.frame != frame_before \
				or not sprite.position.is_equal_approx(pos_before) \
				or not is_equal_approx(sprite.rotation, rot_before)
			_assert(moved_visually, path + " advances visible enemy motion")
		enemy.queue_free()

func _test_stage02_action_sprite_grids() -> void:
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_ice_grunt.tscn") == Vector2i(3, 2), "ice grunt uses 6-frame running grid")
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_ice_archer.tscn") == Vector2i(3, 2), "ice archer uses 6-frame shot grid")
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_frost_turret.tscn") == Vector2i(2, 2), "frost turret uses 4-frame shot grid")
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_cryo_bomber.tscn") == Vector2i(3, 2), "cryo bomber uses 6-frame shot grid")
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_glacier_shield.tscn") == Vector2i(2, 2), "glacier shield uses 4-frame shield grid")
	_assert(_sprite_grid("res://characters/enemies/stage_02/enemy_ice_wisp.tscn") == Vector2i(2, 2), "ice wisp uses 4-frame hover grid")

func _test_stage02_looping_enemy_frames_advance() -> void:
	_assert(_advances_frame_after_tick("res://characters/enemies/stage_02/enemy_ice_grunt.tscn", 0.25), "ice grunt running advances frames")
	_assert(_advances_frame_after_tick("res://characters/enemies/stage_02/enemy_glacier_shield.tscn", 0.25), "glacier shield guard advances frames")
	_assert(_advances_frame_after_tick("res://characters/enemies/stage_02/enemy_ice_wisp.tscn", 0.25), "ice wisp hover advances frames")

func _test_stage02_shot_release_frames_spawn_projectiles() -> void:
	_assert(_shot_enemy_spawns_one_projectile("res://characters/enemies/stage_02/enemy_ice_archer.tscn", "ice_archer", 3), "ice archer fires once during shot release frame")
	_assert(_shot_enemy_spawns_one_projectile("res://characters/enemies/stage_02/enemy_frost_turret.tscn", "frost_turret", 2), "frost turret fires once during shot release frame")
	_assert(_shot_enemy_spawns_one_projectile("res://characters/enemies/stage_02/enemy_cryo_bomber.tscn", "cryo_bomber", 3), "cryo bomber fires once during shot release frame")
	_assert(_shot_enemy_spawns_one_projectile("res://characters/enemies/stage_02/enemy_glacier_shield.tscn", "glacier_shield", 2), "glacier shield fires once during shot release frame")

func _test_stage02_ranged_ground_enemies_hold_position() -> void:
	for path in [
		"res://characters/enemies/stage_02/enemy_ice_archer.tscn",
		"res://characters/enemies/stage_02/enemy_frost_turret.tscn",
		"res://characters/enemies/stage_02/enemy_cryo_bomber.tscn",
		"res://characters/enemies/stage_02/enemy_glacier_shield.tscn",
	]:
		_assert(_enemy_holds_x_position(path, 0.5), path + " stays planted while processing")
		_assert(_enemy_keeps_zero_horizontal_velocity(path, 0.5), path + " keeps zero horizontal velocity")

func _test_stage02_fixed_facing_ranged_enemies_do_not_turn() -> void:
	_assert(_enemy_keeps_fixed_facing("res://characters/enemies/stage_02/enemy_frost_turret.tscn"), "frost turret keeps fixed facing")
	_assert(_enemy_keeps_fixed_facing("res://characters/enemies/stage_02/enemy_glacier_shield.tscn"), "glacier shield keeps fixed facing")

func _test_stage02_ranged_enemy_hitboxes_use_tuned_body_bounds() -> void:
	_assert(
		_enemy_capsule_hitbox_matches("res://characters/enemies/stage_02/enemy_ice_archer.tscn", Vector2(0, -52), 18.0, 70.0),
		"ice archer hitbox tracks body instead of lower sprite frame"
	)
	_assert(
		_enemy_rectangle_hitbox_matches("res://characters/enemies/stage_02/enemy_frost_turret.tscn", Vector2(0, -40), Vector2(60, 64)),
		"frost turret hitbox tracks compact turret body"
	)
	_assert(
		_enemy_circle_hitbox_matches("res://characters/enemies/stage_02/enemy_cryo_bomber.tscn", Vector2(0, -50), 34.0),
		"cryo bomber hitbox tracks body instead of full sprite frame"
	)
	_assert(
		_enemy_rectangle_hitbox_matches("res://characters/enemies/stage_02/enemy_glacier_shield.tscn", Vector2(0, -56), Vector2(64, 88)),
		"glacier shield hitbox tracks shield body"
	)

func _test_stage02_ranged_enemy_sprites_are_lifted_over_hitboxes() -> void:
	_assert(_enemy_sprite_position_matches("res://characters/enemies/stage_02/enemy_ice_archer.tscn", Vector2(0, -70)), "ice archer sprite is lifted 32px")
	_assert(_enemy_sprite_position_matches("res://characters/enemies/stage_02/enemy_frost_turret.tscn", Vector2(0, -66)), "frost turret sprite is lifted 32px")
	_assert(_enemy_sprite_position_matches("res://characters/enemies/stage_02/enemy_cryo_bomber.tscn", Vector2(0, -76)), "cryo bomber sprite is lifted 32px")
	_assert(_enemy_sprite_position_matches("res://characters/enemies/stage_02/enemy_glacier_shield.tscn", Vector2(0, -80)), "glacier shield sprite is lifted 32px")

func _sprite_grid(path: String) -> Vector2i:
	var scene := load(path) as PackedScene
	if scene == null:
		return Vector2i.ZERO
	var enemy := scene.instantiate()
	var sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
	var grid := Vector2i.ZERO
	if sprite != null:
		grid = Vector2i(sprite.hframes, sprite.vframes)
	enemy.free()
	return grid

func _advances_frame_after_tick(path: String, delta: float) -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	var enemy := scene.instantiate() as EnemyBase
	add_child(enemy)
	var sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		enemy.queue_free()
		return false
	var before := sprite.frame
	enemy._physics_process(delta)
	var advanced := sprite.frame != before
	enemy.queue_free()
	return advanced

func _shot_enemy_spawns_one_projectile(path: String, source_id: String, expected_release_frame: int) -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	var enemy := scene.instantiate() as EnemyBase
	add_child(enemy)
	var sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		enemy.free()
		return false
	enemy.set("_shoot_timer", 0.0)
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	player.global_position = enemy.global_position + Vector2(180.0, 0.0)
	var known_projectiles := {}
	for child in get_children():
		if child is EnemyIceProjectile:
			known_projectiles[child.get_instance_id()] = true
	var projectile_count := 0
	var observed_source_id := ""
	var observed_frame := -1
	for i in 30:
		enemy._physics_process(0.04)
		for child in get_children():
			if child is EnemyIceProjectile and not known_projectiles.has(child.get_instance_id()):
				known_projectiles[child.get_instance_id()] = true
				projectile_count += 1
				if projectile_count == 1:
					observed_source_id = child.get("source_id")
					observed_frame = sprite.frame
				child.free()
	player.free()
	enemy.free()
	return projectile_count == 1 and observed_source_id == source_id and observed_frame == expected_release_frame

func _enemy_holds_x_position(path: String, delta: float) -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	var enemy := scene.instantiate() as EnemyBase
	add_child(enemy)
	var before_x := enemy.global_position.x
	enemy._physics_process(delta)
	var stayed := is_equal_approx(enemy.global_position.x, before_x)
	enemy.free()
	return stayed

func _enemy_keeps_zero_horizontal_velocity(path: String, delta: float) -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	var enemy := scene.instantiate() as EnemyBase
	add_child(enemy)
	enemy._physics_process(delta)
	var stopped := is_zero_approx(enemy.velocity.x)
	enemy.free()
	return stopped

func _enemy_keeps_fixed_facing(path: String) -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	var enemy := scene.instantiate() as EnemyBase
	add_child(enemy)
	var sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		enemy.free()
		return false
	sprite.flip_h = false
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	player.global_position = enemy.global_position + Vector2(-180.0, 0.0)
	enemy.set("_shoot_timer", 0.0)
	enemy._physics_process(0.1)
	var kept := sprite.flip_h == false
	player.free()
	enemy.free()
	return kept

func _enemy_capsule_hitbox_matches(path: String, expected_position: Vector2, expected_radius: float, expected_height: float) -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	var enemy := scene.instantiate() as EnemyBase
	var body_shape := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var contact_shape := enemy.get_node_or_null("ContactZone/CollisionShape2D") as CollisionShape2D
	var shape := body_shape.shape as CapsuleShape2D if body_shape != null else null
	var contact := contact_shape.shape as CapsuleShape2D if contact_shape != null else null
	var matched := body_shape != null \
		and contact_shape != null \
		and shape != null \
		and contact != null \
		and body_shape.position.is_equal_approx(expected_position) \
		and contact_shape.position.is_equal_approx(expected_position) \
		and is_equal_approx(shape.radius, expected_radius) \
		and is_equal_approx(shape.height, expected_height) \
		and is_equal_approx(contact.radius, expected_radius) \
		and is_equal_approx(contact.height, expected_height)
	enemy.free()
	return matched

func _enemy_rectangle_hitbox_matches(path: String, expected_position: Vector2, expected_size: Vector2) -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	var enemy := scene.instantiate() as EnemyBase
	var body_shape := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var contact_shape := enemy.get_node_or_null("ContactZone/CollisionShape2D") as CollisionShape2D
	var shape := body_shape.shape as RectangleShape2D if body_shape != null else null
	var contact := contact_shape.shape as RectangleShape2D if contact_shape != null else null
	var matched := body_shape != null \
		and contact_shape != null \
		and shape != null \
		and contact != null \
		and body_shape.position.is_equal_approx(expected_position) \
		and contact_shape.position.is_equal_approx(expected_position) \
		and shape.size.is_equal_approx(expected_size) \
		and contact.size.is_equal_approx(expected_size)
	enemy.free()
	return matched

func _enemy_circle_hitbox_matches(path: String, expected_position: Vector2, expected_radius: float) -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	var enemy := scene.instantiate() as EnemyBase
	var body_shape := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var contact_shape := enemy.get_node_or_null("ContactZone/CollisionShape2D") as CollisionShape2D
	var shape := body_shape.shape as CircleShape2D if body_shape != null else null
	var contact := contact_shape.shape as CircleShape2D if contact_shape != null else null
	var matched := body_shape != null \
		and contact_shape != null \
		and shape != null \
		and contact != null \
		and body_shape.position.is_equal_approx(expected_position) \
		and contact_shape.position.is_equal_approx(expected_position) \
		and is_equal_approx(shape.radius, expected_radius) \
		and is_equal_approx(contact.radius, expected_radius)
	enemy.free()
	return matched

func _enemy_sprite_position_matches(path: String, expected_position: Vector2) -> bool:
	var scene := load(path) as PackedScene
	if scene == null:
		return false
	var enemy := scene.instantiate()
	var sprite := enemy.get_node_or_null("Sprite2D") as Sprite2D
	var matched := sprite != null and sprite.position.is_equal_approx(expected_position)
	enemy.free()
	return matched

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
