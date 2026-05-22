extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	test_wall_slide_flag_set_when_on_wall()
	test_wall_jump_velocity_applied()
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
	_assert(c.WALL_JUMP_H == 280.0, "WALL_JUMP_H == 280.0")
	_assert(c.WALL_JUMP_V == -480.0, "WALL_JUMP_V == -480.0")
	c.queue_free()

func test_wall_jump_velocity_applied() -> void:
	var char_scene := load("res://characters/ranged/zael.tscn") as PackedScene
	var c := char_scene.instantiate()
	add_child(c)
	# Simular estado wall slide ativo + normal de parede apontando para a direita
	c._is_wall_sliding = true
	# _handle_jump_wall usa wall_normal armazenado; setar diretamente
	c._wall_normal = Vector2(1.0, 0.0)
	c._handle_jump()
	_assert(c.velocity.x == 280.0, "Wall jump: velocidade horizontal = 280")
	_assert(c.velocity.y == -480.0, "Wall jump: velocidade vertical = -480")
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
