extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var ok := true
	ok = await _test_fire_beam_uses_modular_visuals() and ok
	ok = await _test_fire_wave_uses_modular_visuals() and ok
	if ok:
		print("PASS: ignarath attack fx modular visuals")
		get_tree().quit(0)
	else:
		printerr("FAIL: ignarath attack fx modular visuals")
		get_tree().quit(1)

func _test_fire_beam_uses_modular_visuals() -> bool:
	var beam: Node2D = load("res://characters/bosses/ignarath/fire_beam.gd").new()
	beam.origin = Vector2(100.0, 100.0)
	beam.floor_y = 260.0
	beam.sweep_time = 1.0
	add_child(beam)
	await get_tree().process_frame

	var origin_spr := beam.get_node_or_null("OriginSprite") as Sprite2D
	var body := beam.get_node_or_null("BodyLine") as Line2D
	var end_spr := beam.get_node_or_null("EndSprite") as Sprite2D

	var ok := true
	ok = _check(origin_spr != null, "fire_beam has OriginSprite") and ok
	ok = _check(body != null, "fire_beam has BodyLine") and ok
	ok = _check(end_spr != null, "fire_beam has EndSprite") and ok
	if origin_spr != null:
		ok = _check(origin_spr.texture != null, "OriginSprite texture loaded") and ok
		ok = _check(origin_spr.hframes == 2 and origin_spr.vframes == 2, "OriginSprite is 2x2 sheet") and ok
	if body != null:
		ok = _check(body.texture is AtlasTexture or body.default_color.r > 0.8, "BodyLine has fire appearance") and ok
		ok = _check(body.points.size() == 2, "BodyLine spans beam endpoints") and ok
		ok = _check(absf(body.width - beam.half_width * 2.0) < 0.1, "BodyLine width follows half_width") and ok
	if end_spr != null:
		ok = _check(end_spr.texture != null, "EndSprite texture loaded") and ok
		ok = _check(end_spr.hframes == 2 and end_spr.vframes == 2, "EndSprite is 2x2 sheet") and ok
	beam.queue_free()
	return ok

func _test_fire_wave_uses_modular_visuals() -> bool:
	var wave: Area2D = load("res://characters/bosses/ignarath/fire_wave.gd").new()
	wave.wave_w = 180.0
	wave.wave_h = 56.0
	wave.despawn_x = 10000.0
	add_child(wave)
	await get_tree().process_frame

	var start_spr := wave.get_node_or_null("WaveStartSprite") as Sprite2D
	var body := wave.get_node_or_null("WaveBodyLine") as Line2D
	var end_spr := wave.get_node_or_null("WaveEndSprite") as Sprite2D
	var collision := wave.get_node_or_null("CollisionShape2D") as CollisionShape2D

	var ok := true
	ok = _check(start_spr != null, "fire_wave has WaveStartSprite") and ok
	ok = _check(body != null, "fire_wave has WaveBodyLine") and ok
	ok = _check(end_spr != null, "fire_wave has WaveEndSprite") and ok
	ok = _check(collision != null, "fire_wave keeps collision shape") and ok
	if start_spr != null:
		ok = _check(start_spr.texture != null, "WaveStartSprite texture loaded") and ok
		ok = _check(start_spr.hframes == 2 and start_spr.vframes == 2, "WaveStartSprite is 2x2 sheet") and ok
	if body != null:
		ok = _check(body.texture is AtlasTexture, "WaveBodyLine has AtlasTexture (frame sub-region)") and ok
		ok = _check(body.points.size() == 2, "WaveBodyLine spans wave body") and ok
		ok = _check(absf(body.width - wave.wave_h) < 0.1, "WaveBodyLine width follows wave_h") and ok
	if end_spr != null:
		ok = _check(end_spr.texture != null, "WaveEndSprite texture loaded") and ok
		ok = _check(end_spr.hframes == 2 and end_spr.vframes == 2, "WaveEndSprite is 2x2 sheet") and ok
	wave.queue_free()
	return ok

func _check(cond: bool, msg: String) -> bool:
	if cond:
		print("  PASS: " + msg)
	else:
		printerr("  FAIL: " + msg)
	return cond
