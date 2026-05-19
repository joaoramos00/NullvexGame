extends Node

func _ready() -> void:
    run_tests()
    get_tree().quit()

func run_tests() -> void:
    test_initial_state()
    test_save_checkpoint()
    test_reset_checkpoints()
    test_respawn_position_uses_checkpoint()
    test_respawn_position_uses_spawn_when_no_checkpoint()
    print("=== All StageManager tests passed ===")

func test_initial_state() -> void:
    StageManager.reset()
    assert(StageManager.current_stage_id == -1, "stage_id starts at -1")
    assert(StageManager.checkpoint_index == 0, "checkpoint_index starts at 0")
    assert(StageManager.checkpoint_position == Vector2.ZERO, "checkpoint_position starts at zero")
    print("PASS: test_initial_state")

func test_save_checkpoint() -> void:
    StageManager.reset()
    StageManager.save_checkpoint(Vector2(300.0, 150.0), 1)
    assert(StageManager.checkpoint_position == Vector2(300.0, 150.0), "position saved")
    assert(StageManager.checkpoint_index == 1, "index saved")
    print("PASS: test_save_checkpoint")

func test_reset_checkpoints() -> void:
    StageManager.reset()
    StageManager.save_checkpoint(Vector2(500.0, 200.0), 2)
    StageManager.reset_checkpoints()
    assert(StageManager.checkpoint_position == Vector2.ZERO, "position reset")
    assert(StageManager.checkpoint_index == 0, "index reset")
    print("PASS: test_reset_checkpoints")

func test_respawn_position_uses_checkpoint() -> void:
    StageManager.reset()
    StageManager.spawn_position = Vector2(100.0, 400.0)
    StageManager.save_checkpoint(Vector2(800.0, 400.0), 1)
    assert(StageManager.get_respawn_position() == Vector2(800.0, 400.0), "respawn uses checkpoint when active")
    print("PASS: test_respawn_position_uses_checkpoint")

func test_respawn_position_uses_spawn_when_no_checkpoint() -> void:
    StageManager.reset()
    StageManager.spawn_position = Vector2(100.0, 400.0)
    assert(StageManager.get_respawn_position() == Vector2(100.0, 400.0), "respawn uses spawn when no checkpoint")
    print("PASS: test_respawn_position_uses_spawn_when_no_checkpoint")
