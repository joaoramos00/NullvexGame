extends Node

func _ready() -> void:
    test_lose_life_on_player_death()
    test_no_respawn_when_dead_already()
    test_checkpoint_saves_position()
    test_checkpoint_not_downgraded()
    test_checkpoint_ignores_non_player()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_lose_life_on_player_death() -> void:
    GameManager.reset()
    var player := _spawn_player()
    var sc := _spawn_controller(player)
    var initial_lives := GameManager.lives
    player.died.emit()
    assert(GameManager.lives == initial_lives - 1)
    sc.queue_free(); player.queue_free()
    print("PASS: lose_life_on_player_death")

func test_no_respawn_when_dead_already() -> void:
    GameManager.reset()
    GameManager.lives = 1
    var player := _spawn_player()
    var sc := _spawn_controller(player)
    player.died.emit()
    assert(GameManager.lives == 0)
    sc.queue_free(); player.queue_free()
    print("PASS: no_respawn_when_dead_already")

func test_checkpoint_saves_position() -> void:
    StageManager.reset()
    StageManager.spawn_position = Vector2(100, 100)
    var cp := _spawn_checkpoint(1)
    cp.global_position = Vector2(500, 200)
    var player := _spawn_player()
    cp._on_body_entered(player)
    assert(StageManager.checkpoint_index == 1)
    assert(StageManager.checkpoint_position == Vector2(500, 200))
    cp.queue_free(); player.queue_free()
    print("PASS: checkpoint_saves_position")

func test_checkpoint_not_downgraded() -> void:
    StageManager.reset()
    StageManager.save_checkpoint(Vector2(1000, 200), 2)
    var cp := _spawn_checkpoint(1)  # lower index than current (2)
    var player := _spawn_player()
    cp._on_body_entered(player)
    assert(StageManager.checkpoint_index == 2)  # unchanged
    cp.queue_free(); player.queue_free()
    print("PASS: checkpoint_not_downgraded")

func test_checkpoint_ignores_non_player() -> void:
    StageManager.reset()
    var cp := _spawn_checkpoint(1)
    var enemy_scene := load("res://characters/enemies/enemy_base.tscn")
    var enemy: EnemyBase = enemy_scene.instantiate()
    add_child(enemy)
    cp._on_body_entered(enemy)
    assert(StageManager.checkpoint_index == 0)  # unchanged
    cp.queue_free(); enemy.queue_free()
    print("PASS: checkpoint_ignores_non_player")

func _spawn_player() -> CharacterBase:
    var scene := load("res://characters/base/character_base.tscn")
    var p: CharacterBase = scene.instantiate()
    add_child(p)
    return p

func _spawn_controller(player: CharacterBase) -> StageController:
    var scene := load("res://stages/stage_controller.tscn")
    var sc: StageController = scene.instantiate()
    sc.player = player
    add_child(sc)
    return sc

func _spawn_checkpoint(index: int) -> Checkpoint:
    var scene := load("res://stages/checkpoint.tscn")
    var cp: Checkpoint = scene.instantiate()
    cp.checkpoint_index = index
    add_child(cp)
    return cp
