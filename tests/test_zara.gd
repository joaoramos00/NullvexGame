extends Node

func _ready() -> void:
	test_hitbox_properties()
	test_combo_progression()
	test_combo_damage()
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
