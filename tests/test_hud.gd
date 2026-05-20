extends Node

func _ready() -> void:
    test_hp_bar_updates()
    test_lives_label_updates()
    test_ability_label_updates()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_hp_bar_updates() -> void:
    GameManager.reset()
    var hud: CanvasLayer = load("res://ui/hud.tscn").instantiate()
    add_child(hud)
    var player: CharacterBase = load("res://characters/base/character_base.tscn").instantiate()
    add_child(player)
    hud.connect_to_player(player)
    player.take_damage(30)
    assert(hud._hp_bar.value == 70.0)
    assert(hud._hp_label.text == "70 / 100")
    player.queue_free()
    hud.queue_free()
    print("PASS: hp_bar_updates")

func test_lives_label_updates() -> void:
    GameManager.reset()
    var hud: CanvasLayer = load("res://ui/hud.tscn").instantiate()
    add_child(hud)
    GameManager.lose_life()
    assert(hud._lives_label.text == "LIVES: 2")
    hud.queue_free()
    print("PASS: lives_label_updates")

func test_ability_label_updates() -> void:
    GameManager.reset()
    var hud: CanvasLayer = load("res://ui/hud.tscn").instantiate()
    add_child(hud)
    assert(hud._ability_label.text == "SINGLE")
    hud.queue_free()
    print("PASS: ability_label_updates")
