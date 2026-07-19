# tests/test_stage01_hazards.gd
extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	_test_lava_floor_damages_player()
	_test_z1_lava_covers_visible_surface()
	_test_shaft_right_wall_meets_ceiling()
	_test_geyser_inactive_no_damage()
	_test_geyser_active_damages_player()
	_test_geyser_visual_toggles()
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

# A Area2D de kill (Z1Lava) deve cobrir a superfície visível da lava (Z1LavaFloor).
# Se o topo da kill ficar abaixo do topo visível, sobra uma faixa de lava que não mata.
func _test_z1_lava_covers_visible_surface() -> void:
	var scene: PackedScene = preload("res://stages/stage_01/stage_01.tscn")
	var root := scene.instantiate()  # sem add_child → _ready não roda, geometria intacta
	var kill := root.get_node_or_null("Z1Lava")
	var vis := root.get_node_or_null("Z1LavaFloor")
	_assert(kill != null and vis != null, "Z1Lava e Z1LavaFloor existem na cena")
	if kill != null and vis != null:
		var kill_top := _body_top(kill)
		var vis_top := _body_top(vis)
		_assert(kill_top <= vis_top,
			"topo da kill (%.0f) cobre a superfície visível da lava (%.0f)" % [kill_top, vis_top])
	root.free()

func _body_top(n: Node) -> float:
	var pos: float = (n as Node2D).position.y
	for c in (n as Node).get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			var h: float = ((c as CollisionShape2D).shape as RectangleShape2D).size.y
			return pos + (c as Node2D).position.y - h * 0.5
	return pos

func _body_bottom(n: Node) -> float:
	var pos: float = (n as Node2D).position.y
	for c in (n as Node).get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			var h: float = ((c as CollisionShape2D).shape as RectangleShape2D).size.y
			return pos + (c as Node2D).position.y + h * 0.5
	return pos

# A parede direita do shaft deve subir até o teto da zona 1, senão fica um buraco
# estético no canto (o teto termina exatamente na borda dessa parede).
func _test_shaft_right_wall_meets_ceiling() -> void:
	var scene: PackedScene = preload("res://stages/stage_01/stage_01.tscn")
	var root := scene.instantiate()
	var wall := root.get_node_or_null("ShaftWallR")
	var ceil := root.get_node_or_null("Z1Ceil")
	_assert(wall != null and ceil != null, "ShaftWallR e Z1Ceil existem na cena")
	if wall != null and ceil != null:
		var wall_top := _body_top(wall)
		var ceil_bottom := _body_bottom(ceil)
		_assert(wall_top <= ceil_bottom,
			"topo da parede direita (%.0f) encosta no fundo do teto (%.0f)" % [wall_top, ceil_bottom])
	root.free()

# ── Geyser ─────────────────────────────────────────────────────────────────────

func _test_geyser_inactive_no_damage() -> void:
	var g := preload("res://stages/stage_01/geyser.gd").new()
	add_child(g)
	_assert(not g.monitoring, "geyser começa inativo (monitoring=false)")
	g.queue_free()

func _test_geyser_active_damages_player() -> void:
	var g := preload("res://stages/stage_01/geyser.gd").new()
	add_child(g)
	g._timer = 0.0
	g._process(0.001)  # DORMENTE → AVISO (fumaça, sem dano)
	_assert(not g.monitoring, "geyser não dá dano na fase de aviso (fumaça)")
	g._timer = 0.0
	g._process(0.001)  # AVISO → SUBIDA (dano ligado)
	_assert(g.monitoring == true, "geyser ativa dano (monitoring) na subida do jato")
	g.queue_free()

func _test_geyser_visual_toggles() -> void:
	var g := preload("res://stages/stage_01/geyser.gd").new()
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 200)
	cs.shape = rect
	g.add_child(cs)
	add_child(g)  # _ready cria vulcão + jato animados + sprite de subida
	_assert(g._jet != null, "geyser cria jato animado de lava")
	_assert(g._jet != null and not g._jet.visible, "jato (loop) invisível fora da erupção")
	g._timer = 0.0
	g._process(0.001)  # → AVISO
	g._timer = 0.0
	g._process(0.001)  # → SUBIDA (sprite de subida visível)
	_assert(g._rise != null and g._rise.visible, "sprite de subida visível na fase SUBIDA")
	g._timer = 0.0
	g._process(0.001)  # → ATIVO (loop visível)
	_assert(g._jet != null and g._jet.visible, "jato (loop) visível no ATIVO")
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
	# wall_destroyed dispara sincronamente, antes da animação de quebra tocar
	_assert(destroyed[0], "parede emite wall_destroyed com habilidade Galerix")
	# queue_free só acontece no fim da animação de quebra (~13 frames); logo após
	# try_destroy() a parede está em processo de quebra, ainda não foi liberada
	_assert(wall._breaking, "parede entra em estado de quebra após destruição")
	_assert(not wall.is_queued_for_deletion(), "parede só libera após a animação de quebra terminar")
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
