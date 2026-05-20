extends Node

func _ready() -> void:
    test_initial_hp()
    test_take_damage()
    test_invincibility_after_hit()
    test_death_on_lethal_damage()
    test_no_damage_when_dead()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_initial_hp() -> void:
    var enemy = _spawn()
    assert(enemy.current_hp == enemy.max_hp)
    assert(not enemy.is_dead)
    enemy.queue_free()
    print("PASS: initial_hp")

func test_take_damage() -> void:
    var enemy = _spawn()
    enemy.take_damage(10)
    assert(enemy.current_hp == enemy.max_hp - 10)
    enemy.queue_free()
    print("PASS: take_damage")

func test_invincibility_after_hit() -> void:
    var enemy = _spawn()
    enemy.take_damage(5)
    enemy.take_damage(5)  # blocked by invincibility
    assert(enemy.current_hp == enemy.max_hp - 5)
    enemy.queue_free()
    print("PASS: invincibility_after_hit")

func test_death_on_lethal_damage() -> void:
    var enemy = _spawn()
    var died_flag := [false]  # Array captured by reference in lambda
    enemy.died.connect(func(): died_flag[0] = true)
    enemy.take_damage(enemy.max_hp)
    assert(enemy.is_dead)
    assert(enemy.current_hp == 0)
    assert(died_flag[0])
    print("PASS: death_on_lethal_damage")

func test_no_damage_when_dead() -> void:
    var enemy = _spawn()
    enemy.take_damage(enemy.max_hp)
    assert(enemy.is_dead)
    # queue_free is deferred so node still accessible
    enemy.take_damage(999)  # should be ignored
    assert(enemy.current_hp == 0)
    print("PASS: no_damage_when_dead")

func _spawn() -> EnemyBase:
    var scene := load("res://characters/enemies/enemy_base.tscn")
    var enemy: EnemyBase = scene.instantiate()
    add_child(enemy)
    return enemy
