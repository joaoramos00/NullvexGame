extends Node

signal lives_changed(lives: int)
signal max_hp_changed(max_hp: int)
signal stage_completed(stage_id: int)
signal ability_unlocked(ability_id: String)
signal character_changed(character: String)
signal game_over

const SAVE_PATH := "user://savegame.json"
const DEFAULT_LIVES := 3
const BASE_HP := 100
const HEART_HP_BONUS := 20

var active_character: String = "zael"
var lives: int = DEFAULT_LIVES
var max_hp: int = BASE_HP
var completed_stages: Array[int] = []
var collected_hearts: Array[int] = []
var collected_subtanks: Array[int] = []
var subtank_charges: Array[float] = [0.0, 0.0, 0.0, 0.0]
var boss_abilities_unlocked: Array[String] = []
var zael_armor: Dictionary = {"helmet": false, "torso": false, "arms": false, "legs": false}
var zara_armor: Dictionary = {"helmet": false, "torso": false, "arms": false, "legs": false}
var zael_shot_types: Array[String] = ["single"]
var zara_weapons: Array[String] = ["sword"]
var zael_selected_shot: String = "single"
var zara_selected_weapon: String = "sword"

func reset() -> void:
    active_character = "zael"
    lives = DEFAULT_LIVES
    max_hp = BASE_HP
    completed_stages.clear()
    collected_hearts.clear()
    collected_subtanks.clear()
    subtank_charges = [0.0, 0.0, 0.0, 0.0]
    boss_abilities_unlocked.clear()
    zael_armor = {"helmet": false, "torso": false, "arms": false, "legs": false}
    zara_armor = {"helmet": false, "torso": false, "arms": false, "legs": false}
    zael_shot_types = ["single"]
    zara_weapons = ["sword"]
    zael_selected_shot = "single"
    zara_selected_weapon = "sword"

func set_active_character(character: String) -> void:
    assert(character in ["zael", "zara"], "invalid character: " + character)
    active_character = character
    character_changed.emit(character)

func collect_heart(stage_id: int) -> void:
    if collected_hearts.has(stage_id):
        return
    collected_hearts.append(stage_id)
    max_hp += HEART_HP_BONUS
    max_hp_changed.emit(max_hp)

func collect_subtank(subtank_index: int) -> void:
    if not collected_subtanks.has(subtank_index):
        collected_subtanks.append(subtank_index)

func charge_subtank(subtank_index: int, amount: float) -> void:
    if subtank_index < subtank_charges.size():
        subtank_charges[subtank_index] = min(1.0, subtank_charges[subtank_index] + amount)

func use_subtank(subtank_index: int) -> float:
    if subtank_index >= subtank_charges.size():
        return 0.0
    var charge := subtank_charges[subtank_index]
    subtank_charges[subtank_index] = 0.0
    return charge

func complete_stage(stage_id: int) -> void:
    if not completed_stages.has(stage_id):
        completed_stages.append(stage_id)
    stage_completed.emit(stage_id)

func unlock_ability(ability_id: String) -> void:
    if not boss_abilities_unlocked.has(ability_id):
        boss_abilities_unlocked.append(ability_id)
        ability_unlocked.emit(ability_id)

func unlock_zael_shot(shot_type: String) -> void:
    if not zael_shot_types.has(shot_type):
        zael_shot_types.append(shot_type)

func unlock_zara_weapon(weapon: String) -> void:
    if not zara_weapons.has(weapon):
        zara_weapons.append(weapon)

func set_zael_armor(piece: String, value: bool) -> void:
    assert(piece in zael_armor, "invalid armor piece: " + piece)
    zael_armor[piece] = value

func set_zara_armor(piece: String, value: bool) -> void:
    assert(piece in zara_armor, "invalid armor piece: " + piece)
    zara_armor[piece] = value

func get_active_armor() -> Dictionary:
    return zael_armor if active_character == "zael" else zara_armor

func has_full_armor() -> bool:
    var armor := get_active_armor()
    return armor["helmet"] and armor["torso"] and armor["arms"] and armor["legs"]

func lose_life() -> void:
    lives -= 1
    lives_changed.emit(lives)
    if lives <= 0:
        game_over.emit()

func add_life() -> void:
    lives += 1
    lives_changed.emit(lives)

func all_main_stages_complete() -> bool:
    for i in range(1, 9):
        if not completed_stages.has(i):
            return false
    return true

func save_game() -> void:
    var data := {
        "active_character": active_character,
        "lives": lives,
        "max_hp": max_hp,
        "completed_stages": Array(completed_stages),
        "collected_hearts": Array(collected_hearts),
        "collected_subtanks": Array(collected_subtanks),
        "subtank_charges": Array(subtank_charges),
        "boss_abilities_unlocked": Array(boss_abilities_unlocked),
        "zael_armor": zael_armor.duplicate(),
        "zara_armor": zara_armor.duplicate(),
        "zael_shot_types": Array(zael_shot_types),
        "zara_weapons": Array(zara_weapons),
        "zael_selected_shot": zael_selected_shot,
        "zara_selected_weapon": zara_selected_weapon,
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(data))
    file.close()

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    var text := file.get_as_text()
    file.close()
    var data: Variant = JSON.parse_string(text)
    if not data is Dictionary:
        return false
    active_character = data.get("active_character", "zael")
    lives = int(data.get("lives", DEFAULT_LIVES))
    max_hp = int(data.get("max_hp", BASE_HP))
    completed_stages = _to_int_array(data.get("completed_stages", []))
    collected_hearts = _to_int_array(data.get("collected_hearts", []))
    collected_subtanks = _to_int_array(data.get("collected_subtanks", []))
    subtank_charges = _to_float_array(data.get("subtank_charges", [0.0, 0.0, 0.0, 0.0]))
    boss_abilities_unlocked = _to_string_array(data.get("boss_abilities_unlocked", []))
    zael_armor = data.get("zael_armor", {"helmet": false, "torso": false, "arms": false, "legs": false})
    zara_armor = data.get("zara_armor", {"helmet": false, "torso": false, "arms": false, "legs": false})
    zael_shot_types = _to_string_array(data.get("zael_shot_types", ["single"]))
    zara_weapons = _to_string_array(data.get("zara_weapons", ["sword"]))
    zael_selected_shot = data.get("zael_selected_shot", "single")
    zara_selected_weapon = data.get("zara_selected_weapon", "sword")
    return true

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)

func _to_int_array(raw: Array) -> Array[int]:
    var result: Array[int] = []
    for v in raw:
        result.append(int(v))
    return result

func _to_float_array(raw: Array) -> Array[float]:
    var result: Array[float] = []
    for v in raw:
        result.append(float(v))
    return result

func _to_string_array(raw: Array) -> Array[String]:
    var result: Array[String] = []
    for v in raw:
        result.append(str(v))
    return result
