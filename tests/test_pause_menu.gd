extends Node

func _ready() -> void:
    test_starts_hidden()
    test_toggle_pauses_tree()
    test_resume_unpauses()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_starts_hidden() -> void:
    var menu: CanvasLayer = load("res://ui/pause_menu.tscn").instantiate()
    add_child(menu)
    assert(not menu.visible)
    menu.queue_free()
    print("PASS: starts_hidden")

func test_toggle_pauses_tree() -> void:
    var menu: CanvasLayer = load("res://ui/pause_menu.tscn").instantiate()
    add_child(menu)
    assert(not get_tree().paused)
    menu.toggle_pause()
    assert(get_tree().paused)
    assert(menu.visible)
    menu.toggle_pause()
    assert(not get_tree().paused)
    assert(not menu.visible)
    menu.queue_free()
    print("PASS: toggle_pauses_tree")

func test_resume_unpauses() -> void:
    var menu: CanvasLayer = load("res://ui/pause_menu.tscn").instantiate()
    add_child(menu)
    menu.toggle_pause()
    assert(get_tree().paused)
    menu._on_resume_pressed()
    assert(not get_tree().paused)
    assert(not menu.visible)
    menu.queue_free()
    print("PASS: resume_unpauses")
