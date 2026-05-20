# Plan 01: Foundation — Godot Project + Autoloads + CharacterBase

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Initialize the Godot 4 project with folder structure, three autoload singletons (GameManager, StageManager, AudioManager), and a tested CharacterBase with movement, double jump, dash, HP, damage, and invincibility.

**Architecture:** Three autoloads communicate via Godot signals only — no direct cross-calls. CharacterBase owns in-game HP; GameManager owns persistent state (lives, max_hp, unlocks). A StageController (Plan 05) will bridge the two at runtime.

**Tech Stack:** Godot 4.2+, GDScript, headless test scripts using `assert()` + `print()`, no external test framework required.

---

## Planos Subsequentes (visão geral)

| Plano | Conteúdo |
|-------|----------|
| Plan 02 | Zael — tiros, sistema de carga, 5 tipos de tiro |
| Plan 03 | Zara — armas, sistema de combo, 5 armas |
| Plan 04 | Sistema de combate — Hitbox/Hurtbox, inimigos base |
| Plan 05 | Sistema de fases — carregamento, checkpoints, vidas, StageController |
| Plan 06 | Colectáveis — corações, sub-tanks, armaduras, armas/tiros |
| Plan 07 | Bosses — base, 8 bosses com fraquezas, Nullvex |
| Plan 08 | UI/Menus — HUD, pausa, stage select, title screen |
| Plan 09 | Save/Load final + fluxo completo de jogo |

---

## File Map

| Arquivo | Responsabilidade |
|---------|-----------------|
| `project.godot` | Config do projeto: resolução 1080p, input map, autoloads, pixel filter |
| `autoloads/game_manager.gd` | Estado persistente: lives, max_hp, unlocks, armaduras, save/load |
| `autoloads/stage_manager.gd` | Fase atual, checkpoints, spawn, carregamento de cenas |
| `autoloads/audio_manager.gd` | BGM com fade, pool de SFX |
| `characters/base/character_base.gd` | Movimento, pulo duplo, dash, HP, dano, invencibilidade |
| `characters/base/character_base.tscn` | Cena base reutilizada por Zael e Zara |
| `tests/test_game_manager.gd` | Testes unitários do GameManager |
| `tests/test_stage_manager.gd` | Testes unitários do StageManager |
| `tests/test_character_base.gd` | Testes da lógica de combate do CharacterBase |
| `scenes/test_level.tscn` | Cena de teste manual de movimento |
| `scenes/test_level.gd` | Script da cena de teste |

---

## Task 1: Inicializar Projeto Godot

**Files:**
- Create: `project.godot`
- Create: estrutura de pastas

- [ ] **Step 1: Criar project.godot**

```ini
[application]
config/name="NullvexGame"
config/features=PackedStringArray("4.2", "Forward Plus")
run/main_scene="res://scenes/test_level.tscn"

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/size/resizable=true
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[rendering]
textures/canvas_textures/default_texture_filter=0

[autoload]
GameManager="*res://autoloads/game_manager.gd"
StageManager="*res://autoloads/stage_manager.gd"
AudioManager="*res://autoloads/audio_manager.gd"

[input]
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"echo":false,"script":null)]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"echo":false,"script":null)]
}
jump={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":90,"key_label":0,"unicode":122,"echo":false,"script":null)]
}
dash={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":88,"key_label":0,"unicode":120,"echo":false,"script":null)]
}
attack={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":74,"key_label":0,"unicode":106,"echo":false,"script":null)]
}
special={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":75,"key_label":0,"unicode":107,"echo":false,"script":null)]
}
ability_prev={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":81,"key_label":0,"unicode":113,"echo":false,"script":null)]
}
ability_next={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":101,"echo":false,"script":null)]
}
pause={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194305,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
```

- [ ] **Step 2: Criar estrutura de pastas**

```bash
mkdir -p autoloads
mkdir -p characters/base characters/ranged characters/melee
mkdir -p enemies/bosses
mkdir -p stages
mkdir -p collectibles
mkdir -p ui
mkdir -p shaders
mkdir -p resources
mkdir -p tests
mkdir -p scenes
```

- [ ] **Step 3: Inicializar git e fazer commit**

```bash
git init
git add project.godot
git commit -m "feat: initialize Godot 4 project — 1080p, pixel filter, input map, autoloads"
```

---

## Task 2: GameManager Autoload

**Files:**
- Create: `autoloads/game_manager.gd`
- Create: `tests/test_game_manager.gd`

- [ ] **Step 1: Escrever teste que falha**

Criar `tests/test_game_manager.gd`:

```gdscript
extends SceneTree

func _init() -> void:
    run_tests()
    quit()

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
```

- [ ] **Step 2: Verificar que o teste falha**

```bash
godot --headless --script tests/test_game_manager.gd
```
Esperado: erro de `GameManager` não encontrado ou método ausente.

- [ ] **Step 3: Implementar GameManager**

Criar `autoloads/game_manager.gd`:

```gdscript
extends Node

signal lives_changed(lives: int)
signal max_hp_changed(max_hp: int)
signal stage_completed(stage_id: int)
signal ability_unlocked(ability_id: String)
signal character_changed(character: String)

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
```

- [ ] **Step 4: Verificar que o teste passa**

```bash
godot --headless --script tests/test_game_manager.gd
```
Esperado: `=== All GameManager tests passed ===`

- [ ] **Step 5: Commit**

```bash
git add autoloads/game_manager.gd tests/test_game_manager.gd
git commit -m "feat: add GameManager with persistent state, unlocks, and save/load"
```

---

## Task 3: StageManager Autoload

**Files:**
- Create: `autoloads/stage_manager.gd`
- Create: `tests/test_stage_manager.gd`

- [ ] **Step 1: Escrever teste que falha**

Criar `tests/test_stage_manager.gd`:

```gdscript
extends SceneTree

func _init() -> void:
    run_tests()
    quit()

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
```

- [ ] **Step 2: Verificar que o teste falha**

```bash
godot --headless --script tests/test_stage_manager.gd
```
Esperado: erro de `StageManager` não implementado.

- [ ] **Step 3: Implementar StageManager**

Criar `autoloads/stage_manager.gd`:

```gdscript
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
```

- [ ] **Step 4: Verificar que o teste passa**

```bash
godot --headless --script tests/test_stage_manager.gd
```
Esperado: `=== All StageManager tests passed ===`

- [ ] **Step 5: Commit**

```bash
git add autoloads/stage_manager.gd tests/test_stage_manager.gd
git commit -m "feat: add StageManager with checkpoint system and stage loading"
```

---

## Task 4: AudioManager Autoload

**Files:**
- Create: `autoloads/audio_manager.gd`

- [ ] **Step 1: Implementar AudioManager**

Criar `autoloads/audio_manager.gd`:

```gdscript
extends Node

const SFX_POOL_SIZE := 8

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _tween: Tween

func _ready() -> void:
    _music_player = AudioStreamPlayer.new()
    _music_player.bus = "Music"
    add_child(_music_player)
    for i in SFX_POOL_SIZE:
        var p := AudioStreamPlayer.new()
        p.bus = "SFX"
        add_child(p)
        _sfx_pool.append(p)

func play_bgm(stream: AudioStream, fade_in: float = 0.5) -> void:
    if _music_player.playing:
        await _fade_out_music(fade_in * 0.5)
    _music_player.stream = stream
    _music_player.volume_db = -80.0
    _music_player.play()
    _fade_in_music(fade_in)

func stop_bgm(fade_out: float = 0.5) -> void:
    if not _music_player.playing:
        return
    await _fade_out_music(fade_out)
    _music_player.stop()

func play_sfx(stream: AudioStream) -> void:
    for player in _sfx_pool:
        if not player.playing:
            player.stream = stream
            player.play()
            return
    _sfx_pool[0].stream = stream
    _sfx_pool[0].play()

func _fade_in_music(duration: float) -> void:
    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(_music_player, "volume_db", 0.0, duration)

func _fade_out_music(duration: float) -> void:
    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(_music_player, "volume_db", -80.0, duration)
    await _tween.finished
```

- [ ] **Step 2: Commit**

```bash
git add autoloads/audio_manager.gd
git commit -m "feat: add AudioManager with BGM fade and 8-slot SFX pool"
```

---

## Task 5: CharacterBase — Lógica de Combate

**Files:**
- Create: `characters/base/character_base.gd`
- Create: `tests/test_character_base.gd`

- [ ] **Step 1: Escrever teste que falha**

Criar `tests/test_character_base.gd`:

```gdscript
extends Node

func _ready() -> void:
    run_tests()

func run_tests() -> void:
    test_initial_hp()
    test_take_damage_reduces_hp()
    test_damage_triggers_invincibility()
    test_invincibility_blocks_second_hit()
    test_death_signal_on_lethal_damage()
    test_is_dead_flag_set()
    print("=== All CharacterBase tests passed ===")

func test_initial_hp() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 100
    cb._ready()
    assert(cb.current_hp == 100, "current_hp equals max_hp on ready")
    assert(cb.is_dead == false, "not dead on init")
    cb.queue_free()
    print("PASS: test_initial_hp")

func test_take_damage_reduces_hp() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 100
    cb._ready()
    cb.take_damage(30)
    assert(cb.current_hp == 70, "hp is 70 after 30 damage")
    cb.queue_free()
    print("PASS: test_take_damage_reduces_hp")

func test_damage_triggers_invincibility() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 100
    cb._ready()
    cb.take_damage(10)
    assert(cb.is_invincible == true, "invincible after first hit")
    cb.queue_free()
    print("PASS: test_damage_triggers_invincibility")

func test_invincibility_blocks_second_hit() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 100
    cb._ready()
    cb.take_damage(10)
    cb.take_damage(10)
    assert(cb.current_hp == 90, "second hit blocked during invincibility")
    cb.queue_free()
    print("PASS: test_invincibility_blocks_second_hit")

func test_death_signal_on_lethal_damage() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 50
    cb._ready()
    var died_received := false
    cb.died.connect(func(): died_received = true)
    cb.take_damage(999)
    assert(died_received == true, "died signal emitted on lethal damage")
    cb.queue_free()
    print("PASS: test_death_signal_on_lethal_damage")

func test_is_dead_flag_set() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 50
    cb._ready()
    cb.take_damage(999)
    assert(cb.is_dead == true, "is_dead true after lethal damage")
    cb.queue_free()
    print("PASS: test_is_dead_flag_set")
```

- [ ] **Step 2: Verificar que o teste falha**

```bash
godot --headless --script tests/test_character_base.gd
```
Esperado: erro — classe `CharacterBase` não encontrada.

- [ ] **Step 3: Implementar CharacterBase**

Criar `characters/base/character_base.gd`:

```gdscript
extends CharacterBody2D
class_name CharacterBase

signal died
signal damaged(amount: int)
signal hp_changed(current: int, maximum: int)

const GRAVITY := 980.0
const SPEED := 200.0
const JUMP_VELOCITY := -480.0
const DOUBLE_JUMP_VELOCITY := -420.0
const DASH_SPEED := 500.0
const DASH_DURATION := 0.18
const DASH_COOLDOWN := 0.4
const COYOTE_TIME := 0.12
const INVINCIBILITY_DURATION := 1.5
const AIR_WALK_DURATION := 0.3  # Zael legs armor — set > 0 from subclass

@export var max_hp: int = 100
var current_hp: int = 100
var is_dead: bool = false
var is_invincible: bool = false
var active_ability: String = ""
var facing_right: bool = true

var _can_double_jump: bool = false
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _coyote_timer: float = 0.0
var _invincibility_timer: float = 0.0
var _air_walk_timer: float = 0.0
var _dash_direction: float = 1.0

func _ready() -> void:
    current_hp = max_hp

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    _tick_timers(delta)
    _apply_gravity(delta)
    _handle_dash(delta)
    _handle_movement()
    _handle_jump()
    move_and_slide()
    _update_facing()

func _tick_timers(delta: float) -> void:
    if _invincibility_timer > 0.0:
        _invincibility_timer -= delta
        if _invincibility_timer <= 0.0:
            is_invincible = false
    if _dash_cooldown_timer > 0.0:
        _dash_cooldown_timer -= delta
    if _air_walk_timer > 0.0:
        _air_walk_timer -= delta
    if is_on_floor():
        _coyote_timer = COYOTE_TIME
        _can_double_jump = true
    elif _coyote_timer > 0.0:
        _coyote_timer -= delta

func _apply_gravity(delta: float) -> void:
    if _is_dashing:
        return
    if _air_walk_timer > 0.0:
        velocity.y = 0.0
        return
    if not is_on_floor():
        velocity.y += GRAVITY * delta

func _handle_movement() -> void:
    if _is_dashing:
        velocity.x = DASH_SPEED * _dash_direction
        return
    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0.0:
        velocity.x = direction * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0.0, SPEED)

func _handle_jump() -> void:
    if _is_dashing:
        return
    if Input.is_action_just_pressed("jump"):
        if is_on_floor() or _coyote_timer > 0.0:
            velocity.y = JUMP_VELOCITY
            _coyote_timer = 0.0
        elif _can_double_jump:
            velocity.y = DOUBLE_JUMP_VELOCITY
            _can_double_jump = false

func _handle_dash(delta: float) -> void:
    if _is_dashing:
        _dash_timer -= delta
        if _dash_timer <= 0.0:
            _is_dashing = false
        return
    if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0:
        _start_dash()

func _start_dash() -> void:
    _is_dashing = true
    _dash_timer = DASH_DURATION
    _dash_cooldown_timer = DASH_COOLDOWN
    _dash_direction = 1.0 if facing_right else -1.0
    velocity.y = 0.0

func _update_facing() -> void:
    if velocity.x > 0.0:
        facing_right = true
        scale.x = 1.0
    elif velocity.x < 0.0:
        facing_right = false
        scale.x = -1.0

func take_damage(amount: int) -> void:
    if is_invincible or is_dead:
        return
    current_hp = max(0, current_hp - amount)
    is_invincible = true
    _invincibility_timer = INVINCIBILITY_DURATION
    damaged.emit(amount)
    hp_changed.emit(current_hp, max_hp)
    if current_hp == 0:
        _die()

func _die() -> void:
    is_dead = true
    velocity = Vector2.ZERO
    died.emit()

func respawn(position: Vector2) -> void:
    global_position = position
    current_hp = GameManager.max_hp
    is_dead = false
    is_invincible = false
    _invincibility_timer = 0.0
    velocity = Vector2.ZERO
    hp_changed.emit(current_hp, max_hp)

func activate_air_walk() -> void:
    _air_walk_timer = AIR_WALK_DURATION
```

- [ ] **Step 4: Verificar que o teste passa**

```bash
godot --headless --script tests/test_character_base.gd
```
Esperado: `=== All CharacterBase tests passed ===`

- [ ] **Step 5: Commit**

```bash
git add characters/base/character_base.gd tests/test_character_base.gd
git commit -m "feat: add CharacterBase with movement, double jump, dash, damage, invincibility"
```

---

## Task 6: CharacterBase — Cena + Cena de Teste Manual

**Files:**
- Create: `characters/base/character_base.tscn`
- Create: `scenes/test_level.tscn`
- Create: `scenes/test_level.gd`

- [ ] **Step 1: Criar character_base.tscn**

No editor Godot:
1. Criar nova cena com root `CharacterBody2D`
2. Renomear root para `CharacterBase`
3. Anexar script `res://characters/base/character_base.gd`
4. Adicionar filho `CollisionShape2D` com `CapsuleShape2D` (radius=10, height=28)
5. Adicionar filho `Sprite2D` (placeholder branco — sem textura por enquanto)
6. Adicionar filho `AnimationPlayer`
7. Salvar como `res://characters/base/character_base.tscn`

- [ ] **Step 2: Criar scenes/test_level.gd**

```gdscript
extends Node2D

@onready var character: CharacterBase = $CharacterBase
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
    GameManager.reset()
    GameManager.set_active_character("zael")
    StageManager.spawn_position = character.global_position

func _process(_delta: float) -> void:
    camera.global_position = character.global_position
```

- [ ] **Step 3: Criar scenes/test_level.tscn**

No editor Godot:
1. Criar nova cena com root `Node2D`
2. Anexar script `res://scenes/test_level.gd`
3. Instanciar `CharacterBase` como filho — Position `(200, 400)`
4. Adicionar `StaticBody2D` (chão):
   - Filho `CollisionShape2D` com `WorldBoundaryShape2D`
   - Posição y = 500
5. Adicionar bloco de plataforma extra para testar salto:
   - `StaticBody2D` → `CollisionShape2D` com `RectangleShape2D` (200×20)
   - Posição `(500, 350)`
6. Adicionar `Camera2D` como filho do root
7. Salvar como `res://scenes/test_level.tscn`

- [ ] **Step 4: Verificar manualmente**

Abrir o projeto no editor Godot e rodar `scenes/test_level.tscn`:

| Ação | Tecla | Resultado esperado |
|------|-------|--------------------|
| Mover direita | D | Personagem desloca para direita |
| Mover esquerda | A | Personagem desloca para esquerda, sprite flipado |
| Pular | Z | Personagem sobe e desce com gravidade |
| Pulo duplo | Z+Z no ar | Segundo pulo mais fraco que o primeiro |
| Dash | X | Personagem avança rapidamente na direção atual |
| Cair off platform | — | Coyote time: 0.12s antes de perder o pulo do chão |
| Parar de se mover | — | Personagem desacelera suavemente até parar |

- [ ] **Step 5: Commit**

```bash
git add characters/base/character_base.tscn scenes/
git commit -m "feat: add CharacterBase scene and manual test level"
```

---

## Checklist de Conclusão do Plano 01

- [ ] `project.godot` criado com 1080p, pixel filter, input map e autoloads
- [ ] `GameManager` com estado persistente, unlocks e save/load — testes passando
- [ ] `StageManager` com checkpoints e spawn — testes passando
- [ ] `AudioManager` com BGM fade e pool SFX
- [ ] `CharacterBase` com movimento, pulo duplo, dash, dano e invencibilidade — testes passando
- [ ] Cena de teste manual funcionando: movimento, salto, dash verificados

**Próximo:** Plan 02 — Zael com sistema de tiro, carga e 5 tipos de tiro.
