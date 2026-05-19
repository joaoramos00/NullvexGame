extends Node

func _ready() -> void:
    run_tests()
    get_tree().quit()

func run_tests() -> void:
    test_initial_state()
    test_heart_increases_max_hp()
    test_duplicate_heart_ignored()
    test_complete_stage()
    test_unlock_ability()
    test_unlock_zael_shot()
    test_unlock_zara_weapon()
    test_save_and_load()
    print("=== All GameManager tests passed ===")

func test_initial_state() -> void:
    GameManager.reset()
    assert(GameManager.lives == 3, "lives should start at 3")
    assert(GameManager.max_hp == 100, "max_hp should start at 100")
    assert(GameManager.active_character == "zael", "default character is zael")
    assert(GameManager.completed_stages.size() == 0, "no stages completed")
    assert(GameManager.zael_shot_types == ["single"], "zael starts with single only")
    assert(GameManager.zara_weapons == ["sword"], "zara starts with sword only")
    assert(GameManager.boss_abilities_unlocked.size() == 0, "no abilities unlocked")
    print("PASS: test_initial_state")

func test_heart_increases_max_hp() -> void:
    GameManager.reset()
    GameManager.collect_heart(1)
    assert(GameManager.max_hp == 120, "heart adds 20 to max_hp")
    print("PASS: test_heart_increases_max_hp")

func test_duplicate_heart_ignored() -> void:
    GameManager.reset()
    GameManager.collect_heart(1)
    GameManager.collect_heart(1)
    assert(GameManager.max_hp == 120, "duplicate heart must not stack")
    assert(GameManager.collected_hearts.size() == 1, "heart recorded once only")
    print("PASS: test_duplicate_heart_ignored")

func test_complete_stage() -> void:
    GameManager.reset()
    GameManager.complete_stage(3)
    assert(GameManager.completed_stages.has(3), "stage 3 marked complete")
    GameManager.complete_stage(3)
    assert(GameManager.completed_stages.size() == 1, "duplicate stage completion ignored")
    print("PASS: test_complete_stage")

func test_unlock_ability() -> void:
    GameManager.reset()
    GameManager.unlock_ability("fire_ball")
    assert(GameManager.boss_abilities_unlocked.has("fire_ball"), "ability unlocked")
    GameManager.unlock_ability("fire_ball")
    assert(GameManager.boss_abilities_unlocked.size() == 1, "duplicate ability ignored")
    print("PASS: test_unlock_ability")

func test_unlock_zael_shot() -> void:
    GameManager.reset()
    GameManager.unlock_zael_shot("spread")
    assert(GameManager.zael_shot_types.has("spread"), "spread unlocked for zael")
    GameManager.unlock_zael_shot("spread")
    assert(GameManager.zael_shot_types.size() == 2, "duplicate shot ignored")
    print("PASS: test_unlock_zael_shot")

func test_unlock_zara_weapon() -> void:
    GameManager.reset()
    GameManager.unlock_zara_weapon("dual_blades")
    assert(GameManager.zara_weapons.has("dual_blades"), "dual_blades unlocked for zara")
    print("PASS: test_unlock_zara_weapon")

func test_save_and_load() -> void:
    GameManager.reset()
    GameManager.active_character = "zara"
    GameManager.lives = 2
    GameManager.collect_heart(5)
    GameManager.complete_stage(2)
    GameManager.unlock_ability("ice_shot")
    GameManager.unlock_zael_shot("rapid")
    GameManager.unlock_zara_weapon("glaive")
    GameManager.zael_armor["helmet"] = true
    GameManager.save_game()

    GameManager.reset()
    assert(GameManager.lives == 3, "reset worked")

    var ok := GameManager.load_game()
    assert(ok == true, "load_game returns true on success")
    assert(GameManager.active_character == "zara", "active_character loaded")
    assert(GameManager.lives == 2, "lives loaded")
    assert(GameManager.collected_hearts.has(5), "heart loaded")
    assert(GameManager.max_hp == 120, "max_hp restored from heart")
    assert(GameManager.completed_stages.has(2), "completed_stages loaded")
    assert(GameManager.boss_abilities_unlocked.has("ice_shot"), "ability loaded")
    assert(GameManager.zael_shot_types.has("rapid"), "zael shot type loaded")
    assert(GameManager.zara_weapons.has("glaive"), "zara weapon loaded")
    assert(GameManager.zael_armor["helmet"] == true, "armor loaded")
    print("PASS: test_save_and_load")
