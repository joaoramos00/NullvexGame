extends Node

func _ready() -> void:
    test_heart_collected()
    test_already_collected_disappears()
    test_subtank_collected()
    test_armor_zael_collected()
    test_shot_unlocked()
    test_ignores_enemy()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_heart_collected() -> void:
    GameManager.reset()
    var c := _spawn(Collectible.Type.HEART, {stage_id = 5})
    var p := _spawn_player()
    c._on_body_entered(p)
    assert(GameManager.collected_hearts.has(5))
    assert(c.is_queued_for_deletion())
    p.queue_free()
    print("PASS: heart_collected")

func test_already_collected_disappears() -> void:
    GameManager.reset()
    GameManager.collect_heart(7)
    var c := _spawn(Collectible.Type.HEART, {stage_id = 7})
    assert(c.is_queued_for_deletion())
    print("PASS: already_collected_disappears")

func test_subtank_collected() -> void:
    GameManager.reset()
    var c := _spawn(Collectible.Type.SUBTANK, {subtank_index = 2})
    var p := _spawn_player()
    c._on_body_entered(p)
    assert(GameManager.collected_subtanks.has(2))
    p.queue_free(); c.queue_free()
    print("PASS: subtank_collected")

func test_armor_zael_collected() -> void:
    GameManager.reset()
    var c := _spawn(Collectible.Type.ARMOR_ZAEL, {armor_piece = "helmet"})
    var p := _spawn_player()
    c._on_body_entered(p)
    assert(GameManager.zael_armor["helmet"] == true)
    p.queue_free()
    print("PASS: armor_zael_collected")

func test_shot_unlocked() -> void:
    GameManager.reset()
    var c := _spawn(Collectible.Type.SHOT_ZAEL, {ability_id = "spread"})
    var p := _spawn_player()
    c._on_body_entered(p)
    assert(GameManager.zael_shot_types.has("spread"))
    p.queue_free()
    print("PASS: shot_unlocked")

func test_ignores_enemy() -> void:
    GameManager.reset()
    var c := _spawn(Collectible.Type.HEART, {stage_id = 3})
    var enemy_scene := load("res://characters/enemies/enemy_base.tscn")
    var enemy: EnemyBase = enemy_scene.instantiate()
    add_child(enemy)
    c._on_body_entered(enemy)
    assert(not GameManager.collected_hearts.has(3))
    assert(not c.is_queued_for_deletion())
    enemy.queue_free(); c.queue_free()
    print("PASS: ignores_enemy")

func _spawn(type: Collectible.Type, props: Dictionary = {}) -> Collectible:
    var scene := load("res://stages/collectible.tscn")
    var c: Collectible = scene.instantiate()
    c.collectible_type = type
    for key in props:
        c.set(key, props[key])
    add_child(c)
    return c

func _spawn_player() -> CharacterBase:
    var scene := load("res://characters/base/character_base.tscn")
    var p: CharacterBase = scene.instantiate()
    add_child(p)
    return p
