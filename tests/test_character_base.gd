extends Node

func _ready() -> void:
    run_tests()
    get_tree().quit()

func run_tests() -> void:
    test_initial_hp()
    test_take_damage_reduces_hp()
    test_damage_triggers_invincibility()
    test_invincibility_blocks_second_hit()
    test_death_signal_on_lethal_damage()
    test_is_dead_flag_set()
    test_no_grab_wall_returns_false_with_no_collisions()
    print("=== All CharacterBase tests passed ===")

func test_initial_hp() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 100
    cb._ready()
    assert(cb.current_hp == 100, "current_hp equals max_hp on ready")
    assert(cb.is_dead == false, "not dead on init")
    cb.queue_free()
    print("PASS: test_initial_hp")

func test_take_damage_reduces_hp() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 100
    cb._ready()
    cb.take_damage(30)
    assert(cb.current_hp == 70, "hp is 70 after 30 damage")
    cb.queue_free()
    print("PASS: test_take_damage_reduces_hp")

func test_damage_triggers_invincibility() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 100
    cb._ready()
    cb.take_damage(10)
    assert(cb.is_invincible == true, "invincible after first hit")
    cb.queue_free()
    print("PASS: test_damage_triggers_invincibility")

func test_invincibility_blocks_second_hit() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 100
    cb._ready()
    cb.take_damage(10)
    cb.take_damage(10)
    assert(cb.current_hp == 90, "second hit blocked during invincibility")
    cb.queue_free()
    print("PASS: test_invincibility_blocks_second_hit")

func test_death_signal_on_lethal_damage() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 50
    cb._ready()
    var died_received := [false]
    cb.died.connect(func(): died_received[0] = true)
    cb.take_damage(999)
    assert(died_received[0] == true, "died signal emitted on lethal damage")
    cb.queue_free()
    print("PASS: test_death_signal_on_lethal_damage")

func test_is_dead_flag_set() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 50
    cb._ready()
    cb.take_damage(999)
    assert(cb.is_dead == true, "is_dead true after lethal damage")
    cb.queue_free()
    print("PASS: test_is_dead_flag_set")

func test_no_grab_wall_returns_false_with_no_collisions() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 100
    cb._ready()
    # Sem nenhum move_and_slide chamado, get_slide_collision_count() == 0
    # _touching_no_grab_wall() deve retornar false (nenhuma colisão).
    assert(cb._touching_no_grab_wall() == false, "_touching_no_grab_wall false sem colisões")
    cb.queue_free()
    print("PASS: test_no_grab_wall_returns_false_with_no_collisions")
