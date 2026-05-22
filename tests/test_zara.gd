extends Node

func _ready() -> void:
	test_hitbox_properties()
	test_combo_progression()
	test_combo_damage()
	test_zara_run_animation()
	print("ALL TESTS PASSED")
	get_tree().quit(0)

func test_hitbox_properties() -> void:
	var scene := load("res://characters/melee/zara_hitbox.tscn")
	var hitbox = scene.instantiate()
	add_child(hitbox)
	hitbox.damage = 20
	assert(hitbox.damage == 20)
	assert(hitbox.ATTACK_DURATION == 0.15)
	hitbox.queue_free()
	print("PASS: hitbox_properties")

func test_combo_progression() -> void:
	assert(Zara.next_combo_step(0) == 1)
	assert(Zara.next_combo_step(1) == 2)
	assert(Zara.next_combo_step(2) == 0)
	print("PASS: combo_progression")

func test_combo_damage() -> void:
	assert(Zara.COMBO_DAMAGE[1] == 8)
	assert(Zara.COMBO_DAMAGE[2] == 12)
	assert(Zara.COMBO_DAMAGE[3] == 20)
	print("PASS: combo_damage")

func test_zara_run_animation() -> void:
	var zara_scene := load("res://characters/melee/zara.tscn")
	var zara = zara_scene.instantiate()
	add_child(zara)
	var sf: SpriteFrames = zara.get_node("AnimatedSprite2D").sprite_frames
	assert(sf.has_animation("run"), "Zara deve ter animação 'run'")
	assert(not sf.has_animation("walk"), "Zara não deve ter animação 'walk'")
	assert(sf.get_frame_count("run") == 3, "run deve ter 3 frames")
	zara.queue_free()
	print("PASS: zara_run_animation")
