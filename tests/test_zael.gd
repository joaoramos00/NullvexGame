extends Node

func _ready() -> void:
    test_bullet_properties()
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
