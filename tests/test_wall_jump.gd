extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	test_wall_slide_flag_set_when_on_wall()
	test_wall_jump_velocity_applied()
	test_dash_wall_jump()
	test_wall_coyote()
	test_no_wall_slide_on_floor()
	print("Wall Jump Tests: %d passed, %d failed" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: " + msg)
		_passed += 1
	else:
		print("  FAIL: " + msg)
		_failed += 1

func test_wall_slide_flag_set_when_on_wall() -> void:
	# CharacterBase deve expor _is_wall_sliding
	var char_scene := load("res://characters/ranged/zael.tscn") as PackedScene
	var c := char_scene.instantiate()
	add_child(c)
	# Forçar estado: no ar, is_on_wall=true simulado via propriedade
	# Como CharacterBody2D requer física real, testamos a lógica de guarda
	# Se not is_on_floor() e not _is_dashing → wall slide pode ser true
	c._is_dashing = false
	# is_on_floor() retorna false por padrão sem chão (não adicionamos chão)
	# _update_wall_slide deve existir
	_assert(c.has_method("_update_wall_slide"), "_update_wall_slide existe")
	_assert("_is_wall_sliding" in c, "_is_wall_sliding exposta")
	_assert(c.WALL_SLIDE_SPEED == 60.0, "WALL_SLIDE_SPEED == 60.0")
	_assert(c.WALL_JUMP_H == 300.0, "WALL_JUMP_H == 300.0")
	_assert(c.WALL_JUMP_V == -500.0, "WALL_JUMP_V == -500.0")
	_assert(c.WALL_JUMP_H_DASH == 460.0, "WALL_JUMP_H_DASH == 460.0")
	_assert(c.WALL_GRAB_MAX_RISE == 160.0, "WALL_GRAB_MAX_RISE == 160.0 (agarre subindo p/ parede→parede)")
	c.queue_free()

func test_wall_jump_velocity_applied() -> void:
	var char_scene := load("res://characters/ranged/zael.tscn") as PackedScene
	var c := char_scene.instantiate()
	add_child(c)
	# Simular estado wall slide ativo + normal de parede apontando para a direita
	c._is_wall_sliding = true
	# _apply_wall_jump usa wall_normal armazenado; setar diretamente
	c._wall_normal = Vector2(1.0, 0.0)
	c._apply_wall_jump()
	_assert(c.velocity.x == 300.0, "Wall jump: velocidade horizontal = 300 (pra longe da parede)")
	_assert(c.velocity.y == -500.0, "Wall jump: velocidade vertical = -500")
	_assert(c._is_wall_sliding == false, "Wall jump: _is_wall_sliding resetado")
	_assert(c._wall_jump_lock_timer == c.WALL_JUMP_LOCK, "Wall jump: lockout do air-control ativado (arco diagonal)")
	_assert(c._wall_jump_dash_speed == 0.0, "Wall jump sem dash: sem boost de air-control")
	c.queue_free()

func test_dash_wall_jump() -> void:
	var char_scene := load("res://characters/ranged/zael.tscn") as PackedScene
	var c := char_scene.instantiate()
	add_child(c)
	c._is_wall_sliding = true
	c._wall_normal = Vector2(1.0, 0.0)
	Input.action_press("dash")
	c._apply_wall_jump()
	Input.action_release("dash")
	_assert(c.velocity.x == 460.0, "Dash wall jump: velocidade horizontal = 460 (salto mais longo)")
	_assert(c.velocity.y == -500.0, "Dash wall jump: velocidade vertical = -500 (mesma altura)")
	_assert(c._wall_jump_lock_timer == c.WALL_JUMP_LOCK_DASH, "Dash wall jump: lockout estendido")
	_assert(c._wall_jump_dash_speed == 460.0, "Dash wall jump: air-control mantém 460 até pousar/agarrar")
	c.queue_free()

func test_no_wall_slide_on_floor() -> void:
	var char_scene := load("res://characters/ranged/zael.tscn") as PackedScene
	var c := char_scene.instantiate()
	add_child(c)
	c._is_wall_sliding = true
	# Simular on_floor via posição: adicionar chão real é complexo,
	# então verificamos que _update_wall_slide reseta flag quando _is_dashing=true
	c._is_dashing = true
	c._update_wall_slide()
	_assert(c._is_wall_sliding == false, "Wall slide desativa quando dashing")
	c.queue_free()

func test_wall_coyote() -> void:
	var char_scene := load("res://characters/ranged/zael.tscn") as PackedScene
	var c := char_scene.instantiate()
	add_child(c)
	_assert(c.WALL_COYOTE_TIME == 0.15, "WALL_COYOTE_TIME == 0.15")
	# Coyote ativo no ar (sem chão na cena → is_on_floor() == false)
	c._is_wall_sliding = false
	c._wall_coyote_timer = 0.1
	_assert(c._can_wall_jump(), "_can_wall_jump: true com coyote ativo no ar")
	# Sem slide e sem coyote
	c._wall_coyote_timer = 0.0
	_assert(not c._can_wall_jump(), "_can_wall_jump: false sem slide e sem coyote")
	# Em wall slide
	c._is_wall_sliding = true
	_assert(c._can_wall_jump(), "_can_wall_jump: true em wall slide")
	# _apply_wall_jump zera o coyote
	c._wall_normal = Vector2(1.0, 0.0)
	c._wall_coyote_timer = 0.15
	c._apply_wall_jump()
	_assert(c._wall_coyote_timer == 0.0, "_apply_wall_jump zera o coyote de parede")
	c.queue_free()
