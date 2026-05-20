extends Node

func _ready() -> void:
	test_idle_no_damage()
	test_normal_damage()
	test_weakness_doubles_damage()
	test_wrong_source_no_multiplier()
	test_invincibility()
	test_die_sets_state()
	await test_defeat_unlocks_ability()
	print("ALL TESTS PASSED")
	get_tree().quit(0)

func test_idle_no_damage() -> void:
	var b := _spawn_boss(100)
	b.state = BossBase.State.IDLE
	b.take_damage(50)
	assert(b.current_hp == 100)
	assert(b.state == BossBase.State.IDLE)
	b.queue_free()
	print("PASS: idle_no_damage")

func test_normal_damage() -> void:
	var b := _spawn_boss(100)
	b.take_damage(30)
	assert(b.current_hp == 70)
	b.queue_free()
	print("PASS: normal_damage")

func test_weakness_doubles_damage() -> void:
	var b := _spawn_boss(100)
	b.take_damage(20, "test_weakness")
	assert(b.current_hp == 60)
	b.queue_free()
	print("PASS: weakness_doubles_damage")

func test_wrong_source_no_multiplier() -> void:
	var b := _spawn_boss(100)
	b.take_damage(20, "other_ability")
	assert(b.current_hp == 80)
	b.queue_free()
	print("PASS: wrong_source_no_multiplier")

func test_invincibility() -> void:
	var b := _spawn_boss(100)
	b.take_damage(10)
	b.take_damage(10)
	assert(b.current_hp == 90)
	b.queue_free()
	print("PASS: invincibility")

func test_die_sets_state() -> void:
	var b := _spawn_boss(10)
	b.take_damage(10)
	assert(b.is_dead)
	assert(b.state == BossBase.State.DYING)
	print("PASS: die_sets_state")

func test_defeat_unlocks_ability() -> void:
	GameManager.reset()
	var b := _spawn_boss(10, "boss_ability")
	b.take_damage(10)
	assert(b.is_dead)
	await get_tree().create_timer(0.2).timeout
	assert(GameManager.boss_abilities_unlocked.has("boss_ability"))
	print("PASS: defeat_unlocks_ability")

func _spawn_boss(hp: int = 100, aid: String = "test_ability") -> BossBase:
	var scene := load("res://characters/bosses/boss_base.tscn")
	var b: BossBase = scene.instantiate()
	b.max_hp = hp
	b.ability_id = aid
	b.weakness_id = "test_weakness"
	b.stage_id = -1
	b.death_duration = 0.05
	b.intro_duration = 0.0
	add_child(b)
	b.state = BossBase.State.COMBAT
	return b
