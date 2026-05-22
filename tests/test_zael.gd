extends Node

func _ready() -> void:
    test_bullet_properties()
    test_charge_levels()
    test_zael_run_animation()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_bullet_properties() -> void:
    var scene := load("res://characters/ranged/zael_bullet.tscn")
    var bullet = scene.instantiate()
    add_child(bullet)
    bullet.damage = 12
    bullet.direction = -1.0
    assert(bullet.damage == 12, "damage deve ser 12")
    assert(bullet.direction == -1.0, "direction deve ser -1.0")
    assert(bullet.SPEED == 500.0, "SPEED deve ser 500.0")
    bullet.queue_free()
    print("PASS: bullet_properties")

func test_charge_levels() -> void:
    assert(Zael.get_charge_level(0.0) == 1, "L1: timer 0.0")
    assert(Zael.get_charge_level(0.39) == 1, "L1: timer 0.39")
    assert(Zael.get_charge_level(0.4) == 2, "L2: timer 0.4")
    assert(Zael.get_charge_level(1.19) == 2, "L2: timer 1.19")
    assert(Zael.get_charge_level(1.2) == 3, "L3: timer 1.2")
    assert(Zael.get_charge_level(2.0) == 3, "L3: timer 2.0")
    print("PASS: charge_levels")

func test_zael_run_animation() -> void:
    var zael_scene := load("res://characters/ranged/zael.tscn")
    var zael = zael_scene.instantiate()
    add_child(zael)
    var sf: SpriteFrames = zael.get_node("AnimatedSprite2D").sprite_frames
    assert(sf.has_animation("run"), "Zael deve ter animação 'run'")
    assert(not sf.has_animation("walk"), "Zael não deve ter animação 'walk'")
    assert(sf.get_frame_count("run") == 6, "run deve ter 6 frames")
    assert(sf.get_frame_count("shoot") == 3, "shoot deve ter 3 frames")
    zael.queue_free()
    print("PASS: zael_run_animation")
