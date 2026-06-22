extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	ok = await _test_fire_beam_uses_modular_visuals() and ok
	ok = await _test_fire_wave_uses_modular_visuals() and ok
	if ok:
		print("PASS: ignarath attack fx modular visuals")
		quit(0)
	else:
		printerr("FAIL: ignarath attack fx modular visuals")
		quit(1)

func _test_fire_beam_uses_modular_visuals() -> bool:
	var beam: Node2D = load("res://characters/bosses/ignarath/fire_beam.gd").new()
	beam.origin = Vector2(100.0, 100.0)
	beam.floor_y = 260.0
	beam.sweep_time = 1.0
	root.add_child(beam)
	await process_frame
	beam._physics_process(0.1)

	var origin := beam.get_node_or_null("OriginSprite") as Sprite2D
	var body := beam.get_node_or_null("BodyLine") as Line2D
	var end := beam.get_node_or_null("EndSprite") as Sprite2D

	var ok := true
	ok = _check(origin != null, "fire_beam has OriginSprite") and ok
	ok = _check(body != null, "fire_beam has BodyLine") and ok
	ok = _check(end != null, "fire_beam has EndSprite") and ok
	if origin != null:
		ok = _check(origin.texture != null, "OriginSprite texture loaded") and ok
		ok = _check(origin.hframes == 2 and origin.vframes == 2, "OriginSprite is 2x2 sheet") and ok
	if body != null:
		ok = _check(body.texture != null, "BodyLine texture loaded") and ok
		ok = _check(body.points.size() == 2, "BodyLine spans beam endpoints") and ok
		ok = _check(absf(body.width - beam.half_width * 2.0) < 0.1, "BodyLine width follows half_width") and ok
	if end != null:
		ok = _check(end.texture != null, "EndSprite texture loaded") and ok
		ok = _check(end.hframes == 2 and end.vframes == 2, "EndSprite is 2x2 sheet") and ok
	beam.queue_free()
	return ok

func _test_fire_wave_uses_modular_visuals() -> bool:
	var wave: Area2D = load("res://characters/bosses/ignarath/fire_wave.gd").new()
	wave.wave_w = 180.0
	wave.wave_h = 56.0
	wave.despawn_x = 10000.0
	root.add_child(wave)
	await process_frame
	wave._physics_process(0.1)

	var start := wave.get_node_or_null("WaveStartSprite") as Sprite2D
	var body := wave.get_node_or_null("WaveBodyLine") as Line2D
	var end := wave.get_node_or_null("WaveEndSprite") as Sprite2D
	var collision := wave.get_node_or_null("CollisionShape2D") as CollisionShape2D

	var ok := true
	ok = _check(start != null, "fire_wave has WaveStartSprite") and ok
	ok = _check(body != null, "fire_wave has WaveBodyLine") and ok
	ok = _check(end != null, "fire_wave has WaveEndSprite") and ok
	ok = _check(collision != null, "fire_wave keeps collision shape") and ok
	if start != null:
		ok = _check(start.texture != null, "WaveStartSprite texture loaded") and ok
		ok = _check(start.hframes == 2 and start.vframes == 2, "WaveStartSprite is 2x2 sheet") and ok
	if body != null:
		ok = _check(body.texture != null, "WaveBodyLine texture loaded") and ok
		ok = _check(body.points.size() == 2, "WaveBodyLine spans wave body") and ok
		ok = _check(absf(body.width - wave.wave_h) < 0.1, "WaveBodyLine width follows wave_h") and ok
	if end != null:
		ok = _check(end.texture != null, "WaveEndSprite texture loaded") and ok
		ok = _check(end.hframes == 2 and end.vframes == 2, "WaveEndSprite is 2x2 sheet") and ok
	wave.queue_free()
	return ok

func _check(cond: bool, msg: String) -> bool:
	if cond:
		print("  PASS: " + msg)
	else:
		printerr("  FAIL: " + msg)
	return cond
