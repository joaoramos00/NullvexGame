extends Node

func _ready() -> void:
    test_hidden_by_default()
    await test_shows_after_stage_completed()
    await test_autosaves_on_stage_completed()
    test_save_load_full_round_trip()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_hidden_by_default() -> void:
    var sc: CanvasLayer = _spawn_stage_complete()
    assert(not sc.visible)
    sc.queue_free()
    print("PASS: hidden_by_default")

func test_shows_after_stage_completed() -> void:
    GameManager.reset()
    var sc: CanvasLayer = _spawn_stage_complete()
    GameManager.complete_stage(1)
    await get_tree().create_timer(0.15).timeout
    assert(sc.visible)
    assert(get_tree().paused)
    get_tree().paused = false
    sc.queue_free()
    print("PASS: shows_after_stage_completed")

func test_autosaves_on_stage_completed() -> void:
    GameManager.reset()
    GameManager.delete_save()
    assert(not GameManager.has_save())
    var sc: CanvasLayer = _spawn_stage_complete()
    GameManager.complete_stage(2)
    await get_tree().create_timer(0.15).timeout
    assert(GameManager.has_save())
    get_tree().paused = false
    GameManager.delete_save()
    sc.queue_free()
    print("PASS: autosaves_on_stage_completed")

func test_save_load_full_round_trip() -> void:
    GameManager.reset()
    GameManager.complete_stage(1)
    GameManager.unlock_ability("ignarath")
    GameManager.collect_heart(1)
    GameManager.set_zael_armor("helmet", true)
    GameManager.save_game()

    GameManager.reset()
    assert(not GameManager.completed_stages.has(1))

    var ok := GameManager.load_game()
    assert(ok)
    assert(GameManager.completed_stages.has(1))
    assert(GameManager.boss_abilities_unlocked.has("ignarath"))
    assert(GameManager.collected_hearts.has(1))
    assert(GameManager.zael_armor["helmet"] == true)

    GameManager.delete_save()
    print("PASS: save_load_full_round_trip")

func _spawn_stage_complete() -> CanvasLayer:
    var sc: CanvasLayer = load("res://ui/stage_complete.tscn").instantiate()
    sc.show_delay = 0.05
    add_child(sc)
    return sc
