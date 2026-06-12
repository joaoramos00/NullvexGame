# Testing Configuration

Project-specific testing details for NullvexGame.

**Test framework:** Godot 4.6.2 headless mode — custom GUT-style tests using `extends Node` + paired `.tscn` scene.

## Test Runner

```bash
# PowerShell — run individual test scenes headlessly
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```

Also see the `run-tests` local skill: `.claude/skills/run-tests.md`

## Critical Rule

**NEVER use `extends SceneTree`** — this mode skips autoloads, breaking all tests that depend on GameManager, StageManager, etc. Always use `extends Node` with an associated `.tscn` file.

## Test Suites

| File | Focus |
|------|-------|
| `tests/test_game_manager.gd` | GameManager: lives, max_hp, active_character, save/load, complete_stage |
| `tests/test_stage_manager.gd` | StageManager: checkpoint save/restore, spawn_position, current_stage_id |
| `tests/test_character_base.gd` | CharacterBase: take_damage, die signal, invincibility, wall-jump |
| `tests/test_zael.gd` | Zael: shoot types, charge level, bullet instantiation |
| `tests/test_zara.gd` | Zara: weapon selection, combo counter, finisher activation |
| `tests/test_enemy_base.gd` | EnemyBase: contact damage, hit flash, death |
| `tests/test_boss_base.gd` | BossBase: phase transitions, attack timers, HP thresholds |
| `tests/test_boss_ai.gd` | Boss AI: attack patterns, weakness system |
| `tests/test_collectible.gd` | Collectible: heart, sub-tank, armor, ability pickup |
| `tests/test_stage_controller.gd` | StageController: spawn, checkpoint, die-respawn cycle |
| `tests/test_hud.gd` | HUD: HP display, lives update, ability indicator |
| `tests/test_pause_menu.gd` | PauseMenu: pause, resume, quit signals |
| `tests/test_stage_complete.gd` | StageComplete: routing, next stage unlock |
| `tests/test_touch_controls.gd` | TouchControls: button-to-action mapping |
| `tests/test_wall_jump.gd` | Wall-jump + wall-grab disable via `no_wall_grab` group |
| `tests/test_checkpoint_door.gd` | CheckpointDoor: trigger, save position |
| `tests/test_intro_boss.gd` | IntroBoss AI: Phase 00 specific patterns |

## Web Export Browser Testing

After running `web-export` skill and starting the local server (port 8080), use Chrome DevTools MCP to validate:
- Game loads and renders at 1920×1080
- Input actions respond (keyboard)
- No JS console errors

See `.claude/skills/chrome-devtools/SKILL.md` for browser testing patterns.

## Test Results Log

Append results to `.opencastle/logs/events.ndjson` using `observability-logging` skill.
