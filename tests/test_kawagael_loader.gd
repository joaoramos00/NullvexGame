extends Node

const _FIXTURE_DIR := "user://test_kawa_fixtures/anims/testrun/"

func _ready() -> void:
	_setup_fixtures()
	await test_loader_reads_all_frames_in_order()
	await test_loader_handles_missing_dir()
	await test_loader_respects_loop_and_speed()
	print("=== All Kawagael loader tests passed ===")
	get_tree().quit()

func _setup_fixtures() -> void:
	DirAccess.make_dir_recursive_absolute(_FIXTURE_DIR)
	for i in 3:
		var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color(float(i) / 2.0, 1.0 - float(i) / 2.0, 0.5, 1.0))
		img.save_png(_FIXTURE_DIR + "f%02d.png" % i)

func _new_kawagael() -> Node:
	var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
	var k = scene.instantiate()
	add_child(k)
	await get_tree().process_frame
	return k

func test_loader_reads_all_frames_in_order() -> void:
	var k = await _new_kawagael()
	var frames := SpriteFrames.new()
	k._add_anim_from_frames(frames, "testrun", _FIXTURE_DIR, 10.0, true)
	assert(frames.get_frame_count("testrun") == 3,
			"expected 3 frames, got %d" % frames.get_frame_count("testrun"))
	k.queue_free()
	print("PASS: test_loader_reads_all_frames_in_order")

func test_loader_handles_missing_dir() -> void:
	var k = await _new_kawagael()
	var frames := SpriteFrames.new()
	k._add_anim_from_frames(frames, "ghost", "user://nonexistent_dir_xyz/", 10.0, true)
	assert(frames.get_frame_count("ghost") == 0,
			"missing dir should yield 0 frames, got %d" % frames.get_frame_count("ghost"))
	k.queue_free()
	print("PASS: test_loader_handles_missing_dir")

func test_loader_respects_loop_and_speed() -> void:
	var k = await _new_kawagael()
	var frames := SpriteFrames.new()
	k._add_anim_from_frames(frames, "testrun2", _FIXTURE_DIR, 12.5, false)
	assert(frames.get_animation_loop("testrun2") == false, "loop flag wrong")
	assert(is_equal_approx(frames.get_animation_speed("testrun2"), 12.5),
			"speed wrong: expected 12.5, got %f" % frames.get_animation_speed("testrun2"))
	k.queue_free()
	print("PASS: test_loader_respects_loop_and_speed")
