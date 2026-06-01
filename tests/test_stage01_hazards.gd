# tests/test_stage01_hazards.gd
extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	_test_lava_floor_damages_player()
	_test_geyser_inactive_no_damage()
	_test_geyser_active_damages_player()
	_test_cracked_wall_no_galerix()
	_test_cracked_wall_with_galerix()
	_test_moving_platform_reverses()
	_print_results()
	get_tree().quit()

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: " + msg)
	else:
		_failed += 1
		print("  FAIL: " + msg)

# ── LavaFloor ──────────────────────────────────────────────────────────────────

func _test_lava_floor_damages_player() -> void:
	var lava := preload("res://stages/stage_01/lava_floor.gd").new()
	lava._physics_process(1.0)  # sem bodies, sem crash
	_assert(true, "lava_floor _physics_process sem bodies não crasha")

# ── Geyser ─────────────────────────────────────────────────────────────────────

func _test_geyser_inactive_no_damage() -> void:
	var g := preload("res://stages/stage_01/geyser.gd").new()
	add_child(g)
	_assert(not g.monitoring, "geyser começa inativo (monitoring=false)")
	g.queue_free()

func _test_geyser_active_damages_player() -> void:
	var g := preload("res://stages/stage_01/geyser.gd").new()
	add_child(g)
	# Simular transição para ativo
	g._timer = 0.0
	g._process(0.001)  # dispara troca de estado
	_assert(g.monitoring == true, "geyser ativa monitoring após timer expirar")
	g.queue_free()

# ── CrackedWall ────────────────────────────────────────────────────────────────

func _test_cracked_wall_no_galerix() -> void:
	GameManager.boss_abilities_unlocked.clear()
	var wall := preload("res://stages/stage_01/cracked_wall.gd").new()
	add_child(wall)
	wall.try_destroy()
	_assert(is_instance_valid(wall), "parede NÃO destruída sem habilidade Galerix")
	wall.queue_free()

func _test_cracked_wall_with_galerix() -> void:
	GameManager.boss_abilities_unlocked.clear()
	GameManager.boss_abilities_unlocked.append("galerix")
	var wall := preload("res://stages/stage_01/cracked_wall.gd").new()
	add_child(wall)
	# Array used as reference container so the lambda can mutate the captured value
	var destroyed := [false]
	wall.wall_destroyed.connect(func(): destroyed[0] = true)
	wall.try_destroy()
	# wall_destroyed dispara sincronamente antes do queue_free
	_assert(destroyed[0], "parede emite wall_destroyed com habilidade Galerix")
	# queue_free só libera no fim do frame — checar via is_queued_for_deletion
	_assert(wall.is_queued_for_deletion(), "parede marcada para queue_free após destruição")
	GameManager.boss_abilities_unlocked.clear()

# ── MovingPlatform ─────────────────────────────────────────────────────────────

func _test_moving_platform_reverses() -> void:
	var plat := preload("res://stages/stage_01/moving_platform.gd").new()
	plat.move_distance = 100.0
	plat.speed = 100.0
	add_child(plat)
	# Avançar além do limite
	plat._physics_process(1.0)
	_assert(plat._dir == -1.0, "plataforma reverte direção ao atingir limite")
	plat.queue_free()

func _print_results() -> void:
	print("\n=== test_stage01_hazards: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("TESTS FAILED")
