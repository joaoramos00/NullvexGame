extends Node

signal stage_loaded(stage_id: int)
signal transition_started
signal transition_finished
signal checkpoint_reached(index: int, position: Vector2)

const STAGE_PATHS := {
    0:  "res://stages/stage_00/stage_00.tscn",
    1:  "res://stages/stage_01/stage_01.tscn",
    2:  "res://stages/stage_02/stage_02.tscn",
    3:  "res://stages/stage_03/stage_03.tscn",
    4:  "res://stages/stage_04/stage_04.tscn",
    5:  "res://stages/stage_05/stage_05.tscn",
    6:  "res://stages/stage_06/stage_06.tscn",
    7:  "res://stages/stage_07/stage_07.tscn",
    8:  "res://stages/stage_08/stage_08.tscn",
    9:  "res://stages/stage_09/stage_09.tscn",
    10: "res://stages/stage_10/stage_10.tscn",
    11: "res://stages/stage_11/stage_11.tscn",
}

var current_stage_id: int = -1
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_index: int = 0
var spawn_position: Vector2 = Vector2.ZERO

func reset() -> void:
    current_stage_id = -1
    checkpoint_position = Vector2.ZERO
    checkpoint_index = 0
    spawn_position = Vector2.ZERO

func save_checkpoint(position: Vector2, index: int) -> void:
    checkpoint_position = position
    checkpoint_index = index
    checkpoint_reached.emit(index, position)

func reset_checkpoints() -> void:
    checkpoint_position = Vector2.ZERO
    checkpoint_index = 0

func get_respawn_position() -> Vector2:
    return checkpoint_position if checkpoint_index > 0 else spawn_position

func load_stage(stage_id: int) -> void:
    transition_started.emit()
    current_stage_id = stage_id
    reset_checkpoints()
    var path: String = STAGE_PATHS.get(stage_id, "")
    if path.is_empty():
        push_error("StageManager: no scene path for stage_id %d" % stage_id)
        return
    get_tree().change_scene_to_file(path)
    stage_loaded.emit(stage_id)
    transition_finished.emit()

func reload_current_stage() -> void:
    if current_stage_id < 0:
        return
    reset_checkpoints()
    get_tree().change_scene_to_file(STAGE_PATHS[current_stage_id])
