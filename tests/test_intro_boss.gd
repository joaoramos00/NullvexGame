extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	test_boss_stats()
	test_boss_has_patterns()
	await test_boss_defeat_emits_signal()
	print("IntroBoss Tests: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: " + msg)
		_passed += 1
	else:
		print("  FAIL: " + msg)
		_failed += 1

func test_boss_stats() -> void:
	var scene := load("res://characters/bosses/intro_boss.tscn") as PackedScene
	var boss := scene.instantiate()
	add_child(boss)
	_assert(boss.stage_id == 0, "stage_id == 0")
	_assert(boss.ability_id == "", "ability_id vazio")
	_assert(boss.max_hp == 20, "max_hp == 20")
	_assert(boss.has_method("_do_dash"), "_do_dash existe")
	_assert(boss.has_method("_do_shoot"), "_do_shoot existe")
	boss.queue_free()

func test_boss_has_patterns() -> void:
	var scene := load("res://characters/bosses/intro_boss.tscn") as PackedScene
	var boss := scene.instantiate()
	add_child(boss)
	_assert(boss.DASH_SPEED_P1 > 0.0, "DASH_SPEED_P1 positivo")
	_assert(boss.DASH_SPEED_P2 > 0.0, "DASH_SPEED_P2 positivo")
	_assert(boss.SHOOT_SPEED_P1 > 0.0, "SHOOT_SPEED_P1 positivo")
	_assert(boss.SHOOT_SPEED_P2 > 0.0, "SHOOT_SPEED_P2 positivo")
	boss.queue_free()

var _defeated_flag := false

func _on_boss_defeated(_aid: String) -> void:
	_defeated_flag = true

func test_boss_defeat_emits_signal() -> void:
	var scene := load("res://characters/bosses/intro_boss.tscn") as PackedScene
	var boss := scene.instantiate()
	boss.death_duration = 0.05
	boss.stage_id = -1
	add_child(boss)
	_defeated_flag = false
	boss.boss_defeated.connect(_on_boss_defeated)
	boss.state = boss.State.COMBAT
	boss.take_damage(boss.max_hp)
	_assert(boss.is_dead, "boss morreu ao tomar dano total")
	# wait for death sequence to fire boss_defeated (death_duration=0.05 + margin)
	await get_tree().create_timer(0.5).timeout
	_assert(_defeated_flag, "boss_defeated emitido ao morrer")
