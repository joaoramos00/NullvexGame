extends Node

func _ready() -> void:
	test_starts_idle()
	test_no_damage_when_idle()
	test_weakness_multiplier()
	test_no_weakness_normal_damage()
	test_phase_transition_at_50_percent()
	test_invincibility_blocks_repeat_hits()
	test_death_emits_signal()
	await test_death_sequence_completes_stage()
	print("ALL TESTS PASSED")
	get_tree().quit(0)

func test_starts_idle() -> void:
	var boss := _spawn_ignarath()
	assert(boss.state == BossBase.State.IDLE, "boss not IDLE")
	assert(boss.phase == 1, "boss phase not 1")
	assert(boss.current_hp == boss.max_hp, "boss hp not full")
	boss.queue_free()
	print("PASS: starts_idle")

func test_no_damage_when_idle() -> void:
	var boss := _spawn_ignarath()
	boss.take_damage(50)
	assert(boss.current_hp == boss.max_hp, "boss took damage while IDLE")
	boss.queue_free()
	print("PASS: no_damage_when_idle")

func test_weakness_multiplier() -> void:
	var boss := _spawn_ignarath()
	boss.state = BossBase.State.COMBAT
	boss.take_damage(10, "galerix")  # ignarath weak to galerix → 2× damage
	assert(boss.current_hp == boss.max_hp - 20, "weakness multiplier wrong: got %d" % boss.current_hp)
	boss.queue_free()
	print("PASS: weakness_multiplier")

func test_no_weakness_normal_damage() -> void:
	var boss := _spawn_ignarath()
	boss.state = BossBase.State.COMBAT
	boss.take_damage(10, "cryovex")  # not ignarath's weakness
	assert(boss.current_hp == boss.max_hp - 10, "normal damage wrong: got %d" % boss.current_hp)
	boss.queue_free()
	print("PASS: no_weakness_normal_damage")

func test_phase_transition_at_50_percent() -> void:
	var boss := _spawn_ignarath()
	boss.state = BossBase.State.COMBAT
	# Hit just above 50% threshold — should remain phase 1
	boss.take_damage(boss.max_hp / 2 - 1)  # 99 damage → 101 HP (50.5%)
	assert(boss.phase == 1, "phase changed too early")
	# Reset invincibility, then push below 50%
	boss._invincible = false
	boss.take_damage(2)  # 2 more damage → 99 HP (49.5%)
	assert(boss.phase == 2, "phase 2 not triggered at 50%")
	boss.queue_free()
	print("PASS: phase_transition_at_50_percent")

func test_invincibility_blocks_repeat_hits() -> void:
	var boss := _spawn_ignarath()
	boss.state = BossBase.State.COMBAT
	boss.take_damage(10)
	var hp_after_first := boss.current_hp
	boss.take_damage(10)  # should be blocked by invincibility
	assert(boss.current_hp == hp_after_first, "invincibility did not block second hit")
	boss.queue_free()
	print("PASS: invincibility_blocks_repeat_hits")

func test_death_emits_signal() -> void:
	var boss := _spawn_ignarath()
	boss.state = BossBase.State.COMBAT
	boss.death_duration = 100.0  # prevent sequence from completing during test
	var died_received := [false]
	boss.died.connect(func(): died_received[0] = true)
	boss.take_damage(boss.max_hp)
	assert(died_received[0], "died signal not received")
	assert(boss.is_dead, "boss.is_dead not set")
	assert(boss.state == BossBase.State.DYING, "boss not in DYING state")
	boss.queue_free()
	print("PASS: death_emits_signal")

func test_death_sequence_completes_stage() -> void:
	GameManager.reset()
	var boss := _spawn_ignarath()
	boss.state = BossBase.State.COMBAT
	boss.death_duration = 0.05
	boss.take_damage(boss.max_hp)
	assert(boss.is_dead)
	await get_tree().create_timer(0.2).timeout
	assert(GameManager.completed_stages.has(1), "stage 1 not completed after death sequence")
	assert(GameManager.boss_abilities_unlocked.has("ignarath"), "ignarath ability not unlocked")
	GameManager.reset()
	print("PASS: death_sequence_completes_stage")

func _spawn_ignarath() -> BossBase:
	var b: BossBase = load("res://characters/bosses/ignarath.tscn").instantiate()
	add_child(b)
	return b
