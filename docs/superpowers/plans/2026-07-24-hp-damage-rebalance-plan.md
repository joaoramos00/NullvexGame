# HP/Damage Rebalance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the game's HP/damage numbers (player, all common enemies in stages 00-08, all 8 elemental bosses, IntroBoss, Nullvex/Nullvex True) with the small, deliberate scale defined in `docs/superpowers/specs/2026-07-24-hp-damage-rebalance-design.md`.

**Architecture:** This is a pure data-value change across ~100 existing files — no new systems, no new node types. Every enemy/boss already exposes `max_hp` and `contact_damage` as either an `@export var` (set once) or a hardcoded assignment in `_init()`/`_ready()`. Boss ranged/melee attack damage is already a named constant per attack. The work is: edit those literals to match the spec, fix two pre-existing script/scene ambiguities (Ignarath and IntroBoss `max_hp`), add per-ability ammo caps to `GameManager`, and update the handful of existing tests that hardcode old values.

**Tech Stack:** Godot 4.6.2, GDScript. No new dependencies.

## Global Constraints

- **Every enemy and boss must have `contact_damage >= 1`** — never `0`, even for stationary turrets whose main threat is a projectile (spec: "Regra Geral").
- Five boss-attack items are **intentionally left unchanged** in this plan (per user decision, documented in the spec's "Itens Pendentes" section): Voltrix (contact + projectile), Galerix (contact + projectile), Luxar (contact + feixe), Nullvex (contact + tiro em leque), Nullvex True (contact + projétil fase1-2 + projétil de queda fase3). Only their `max_hp` changes in this plan — do not touch their attack damage constants.
- `enemy_ember_orbiter` is removed from Stage 01 entirely (spawn calls deleted), per user decision.
- Boss `max_hp` must come from a single source of truth. Two bosses (Ignarath, IntroBoss) currently have a script-side `_ready()` override that silently wins over the `.tscn`-stored value — both must be updated together so they agree.
- Zael's charge system has only **3** real levels today (not 4) — armor unlocks level 3, it does not add a level 4. Do not touch the armor-gating logic (`_charge_level()`'s `mini(level, 2)` cap) — that stays as-is. Only the 3 damage values change.

## Edit Convention for Common Enemies

Nearly every file under `characters/enemies/stage_0X/` follows one of two shapes. Confirmed by direct inspection of a sample from every stage before writing this plan — do not assume a third shape exists without checking the file first.

**Shape A — set twice (in both `_init()` and `_ready()`):**
```gdscript
func _init() -> void:
	max_hp = 10
	contact_damage = 8

func _ready() -> void:
	max_hp = 10
	contact_damage = 8
	super._ready()
```
Use `replace_all: true` in the Edit tool so both copies change together.

**Shape B — set once, followed by `current_hp = max_hp`:**
```gdscript
func _init() -> void:
	max_hp = 8
	contact_damage = 7
	current_hp = max_hp
```
A single (non-`replace_all`) edit is enough.

For every file listed in the tables below: open it, run `grep -n "max_hp\|contact_damage" <file>` to see which shape it is and confirm the current numbers match the table's "old" column, then edit both the `max_hp` and `contact_damage` lines to the "new" column values (`replace_all: true` if the grep showed the pair twice). If a file's current values don't match the table, stop and re-check against the spec before editing — do not silently proceed on a mismatch.

---

### Task 1: Player Core — HP, Zael/Zara base damage, ability ammo

**Files:**
- Modify: `autoloads/game_manager.gd:13-14` (BASE_HP, HEART_HP_BONUS)
- Modify: `autoloads/game_manager.gd:23` (ABILITY_MAX_AMMO)
- Modify: `autoloads/game_manager.gd:99-143` (unlock_ability, get_ability_ammo, use_ability_ammo, refill_ability_ammo)
- Modify: `characters/ranged/zael.gd:7` (BULLET_DAMAGE)
- Modify: `characters/melee/zara.gd:6` (COMBO_DAMAGE)
- Modify: `tests/test_game_manager.gd` (4 assertions)
- Test: `tests/test_game_manager.tscn` (existing, headless)

**Interfaces:**
- Produces: `GameManager.BASE_HP == 14`, `GameManager.HEART_HP_BONUS == 2`, `GameManager.ABILITY_MAX_AMMO` becomes a `Dictionary[String, int]` keyed by ability id instead of a flat `int`.
- Consumes: nothing new — these are existing autoload constants read by `character_base.gd`, `zael.gd`, `zara.gd`.

- [ ] **Step 1: Update player HP constants**

In `autoloads/game_manager.gd`:
```gdscript
const BASE_HP := 14
const HEART_HP_BONUS := 2
```
(was `const BASE_HP := 50` / `const HEART_HP_BONUS := 20`)

- [ ] **Step 2: Convert ABILITY_MAX_AMMO to a per-ability dictionary**

Replace:
```gdscript
const ABILITY_MAX_AMMO: int = 30
```
with:
```gdscript
const ABILITY_MAX_AMMO: Dictionary = {
	"ignarath": 8,
	"cryovex": 15,
	"voltrix": 8,
	"gravitus": 12,
	"galerix": 20,
	"umbraex": 10,
	"luxar": 20,
	"terragor": 8,
}
```

- [ ] **Step 3: Update the 3 functions that read ABILITY_MAX_AMMO as a flat int**

In `unlock_ability()`, replace:
```gdscript
		boss_ability_ammo[ability_id] = ABILITY_MAX_AMMO
```
with:
```gdscript
		boss_ability_ammo[ability_id] = ABILITY_MAX_AMMO.get(ability_id, 10)
```

In `get_ability_ammo()`, replace:
```gdscript
func get_ability_ammo(ability_id: String) -> int:
    return int(boss_ability_ammo.get(ability_id, ABILITY_MAX_AMMO))
```
with:
```gdscript
func get_ability_ammo(ability_id: String) -> int:
    return int(boss_ability_ammo.get(ability_id, ABILITY_MAX_AMMO.get(ability_id, 10)))
```

In `refill_ability_ammo()`, replace:
```gdscript
func refill_ability_ammo(ability_id: String) -> void:
    boss_ability_ammo[ability_id] = ABILITY_MAX_AMMO
```
with:
```gdscript
func refill_ability_ammo(ability_id: String) -> void:
    boss_ability_ammo[ability_id] = ABILITY_MAX_AMMO.get(ability_id, 10)
```

(The `10` fallback only matters for the two fake ability ids `test_game_manager.gd` uses to test the generic unlock mechanism — `"fire_ball"` and `"ice_shot"` — which aren't real `ABILITY_ORDER` entries. It has no effect on real gameplay.)

- [ ] **Step 4: Update Zael and Zara base damage arrays**

In `characters/ranged/zael.gd:7`, replace:
```gdscript
const BULLET_DAMAGE := [0, 5, 12, 25]
```
with:
```gdscript
const BULLET_DAMAGE := [0, 1, 2, 3]
```

In `characters/melee/zara.gd:6`, replace:
```gdscript
const COMBO_DAMAGE := [0, 8, 12, 20]
```
with:
```gdscript
const COMBO_DAMAGE := [0, 1, 1, 3]
```

- [ ] **Step 5: Update test_game_manager.gd assertions**

In `tests/test_game_manager.gd`, apply these 4 edits (`replace_all: false` — each is a distinct line/context):

Line 21: `assert(GameManager.max_hp == 50, "max_hp should start at 50")` → `assert(GameManager.max_hp == 14, "max_hp should start at 14")`

Line 32: `assert(GameManager.max_hp == 70, "heart adds 20 to max_hp")` → `assert(GameManager.max_hp == 16, "heart adds 2 to max_hp")`

Line 39: `assert(GameManager.max_hp == 70, "duplicate heart must not stack")` → `assert(GameManager.max_hp == 16, "duplicate heart must not stack")`

Line 93: `assert(GameManager.max_hp == 70, "max_hp restored from heart")` → `assert(GameManager.max_hp == 16, "max_hp restored from heart")`

- [ ] **Step 6: Run the test**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn`
Expected: last line `=== All GameManager tests passed ===`, exit code 0.

- [ ] **Step 7: Run the character base test (reads GameManager.max_hp on _ready)**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0. (This test sets `cb.max_hp` directly on its own instances, so it's unaffected by the `BASE_HP` change — confirm it still passes rather than assuming.)

- [ ] **Step 8: Commit**

```bash
git add autoloads/game_manager.gd characters/ranged/zael.gd characters/melee/zara.gd tests/test_game_manager.gd
git commit -m "feat: rebalance player HP, base damage, and per-ability ammo caps"
```

---

### Task 2: Boss Ability Projectiles (Zael)

**Files:**
- Modify: `characters/ranged/player_fire_wave.gd:16`
- Modify: `characters/ranged/player_ice_arrow.gd:17`
- Modify: `characters/ranged/player_wind_gust.gd:14`
- Modify: `characters/ranged/player_shadow_kunai.gd:17`
- Modify: `characters/ranged/player_stone_shard.gd:19`

**Interfaces:**
- Consumes: nothing new.
- Produces: nothing new — these are leaf projectile scripts, no other task depends on their exact damage value.

- [ ] **Step 1: Edit each ability's damage default**

| File | Old | New |
|---|---|---|
| `characters/ranged/player_fire_wave.gd:16` | `var damage: int = 8` | `var damage: int = 3` |
| `characters/ranged/player_ice_arrow.gd:17` | `var damage: int = 8` | `var damage: int = 2` |
| `characters/ranged/player_wind_gust.gd:14` | `var damage: int = 8` | `var damage: int = 1` |
| `characters/ranged/player_shadow_kunai.gd:17` | `var damage: int = 10` | `var damage: int = 3` |
| `characters/ranged/player_stone_shard.gd:19` | `var damage: int = 8` | `var damage: int = 4` |

- [ ] **Step 2: Verify with grep**

Run: `grep -n "var damage" characters/ranged/player_fire_wave.gd characters/ranged/player_ice_arrow.gd characters/ranged/player_wind_gust.gd characters/ranged/player_shadow_kunai.gd characters/ranged/player_stone_shard.gd`
Expected output shows `3`, `2`, `1`, `3`, `4` respectively.

- [ ] **Step 3: Commit**

```bash
git add characters/ranged/player_fire_wave.gd characters/ranged/player_ice_arrow.gd characters/ranged/player_wind_gust.gd characters/ranged/player_shadow_kunai.gd characters/ranged/player_stone_shard.gd
git commit -m "feat: rebalance boss-ability projectile damage"
```

---

### Task 3: Stage 00 (Intro) — generic grunt/flyer, MB00, IntroBoss

**Files:**
- Modify: `characters/enemies/enemy_base.gd:122-123`
- Modify: `characters/enemies/enemy_miniboss.gd:69-70`
- Modify: `characters/bosses/intro_boss.gd:34-35,62`
- Modify: `characters/bosses/intro_boss.tscn:12`
- Modify: `tests/test_intro_boss.gd:27`
- Test: `tests/test_intro_boss.tscn`, `tests/test_character_base.tscn` (existing, headless)

**Interfaces:**
- Consumes: nothing new.
- Produces: `EnemyBase` default `max_hp`/`contact_damage` used as the fallback by every enemy that doesn't override them (only Stage 00's generic grunt/flyer rely on the default — every themed enemy in stages 01-08 already overrides both in its own script).

- [ ] **Step 1: Lower the generic EnemyBase/EnemyFlyer default**

In `characters/enemies/enemy_base.gd`, replace:
```gdscript
@export var max_hp:         int = 8
@export var contact_damage: int = 8
```
with:
```gdscript
@export var max_hp:         int = 2
@export var contact_damage: int = 1
```
(`enemy_flyer.gd` extends `enemy_base.gd` without overriding either value, so Stage 00's flyer inherits this too.)

- [ ] **Step 2: Update MB00 (generic miniboss)**

In `characters/enemies/enemy_miniboss.gd`, replace:
```gdscript
	max_hp         = 36
	contact_damage = 3
```
with:
```gdscript
	max_hp         = 15
	contact_damage = 2
```

- [ ] **Step 3: Update IntroBoss attack constants and fix the max_hp ambiguity**

In `characters/bosses/intro_boss.gd`, replace:
```gdscript
const SHOOT_DAMAGE        := 8
const BURST_DAMAGE        := 6
```
with:
```gdscript
const SHOOT_DAMAGE        := 2
const BURST_DAMAGE        := 3
```

In the same file's `_ready()`, replace:
```gdscript
	max_hp             = 120
```
with:
```gdscript
	max_hp             = 20
```

- [ ] **Step 4: Sync the .tscn value and add contact_damage**

In `characters/bosses/intro_boss.tscn`, replace:
```
max_hp = 28
boss_color = Color(0.5, 0.0, 0.1, 1)
```
with:
```
max_hp = 20
boss_color = Color(0.5, 0.0, 0.1, 1)
contact_damage = 1
```
(The script's `_ready()` still wins for `max_hp` at runtime since it overrides after scene load — this edit keeps the stored scene value from lying about it. `contact_damage` is **not** touched by `_ready()`, so this is what actually takes effect at runtime for contact damage.)

- [ ] **Step 5: Update the stale test assertion**

In `tests/test_intro_boss.gd:27`, replace:
```gdscript
	_assert(boss.max_hp == 28, "max_hp == 28")
```
with:
```gdscript
	_assert(boss.max_hp == 20, "max_hp == 20")
```

- [ ] **Step 6: Run tests**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_intro_boss.tscn`
Expected: exit code 0, no assertion failures.

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0.

- [ ] **Step 7: Commit**

```bash
git add characters/enemies/enemy_base.gd characters/enemies/enemy_miniboss.gd characters/bosses/intro_boss.gd characters/bosses/intro_boss.tscn tests/test_intro_boss.gd
git commit -m "feat: rebalance stage 00 generic enemies, MB00, and IntroBoss"
```

---

### Task 4: Stage 01 (Ignarath) — 8 enemies (ember_orbiter removed), boss

**Files:**
- Modify: `characters/enemies/stage_01/enemy_magma_grunt.gd`
- Modify: `characters/enemies/stage_01/enemy_molten_ram.gd`
- Modify: `characters/enemies/stage_01/enemy_ash_hopper.gd`
- Modify: `characters/enemies/stage_01/enemy_flame_skimmer.gd`
- Modify: `characters/enemies/stage_01/enemy_cinder_flyer.gd`
- Modify: `characters/enemies/stage_01/enemy_heat_mortar.gd`
- Modify: `characters/enemies/stage_01/enemy_magma_turret.gd`
- Modify: `characters/enemies/stage_01/enemy_lava_serpent.gd`
- Modify: `stages/stage_01/stage_01_scene.gd` (remove 4 `enemy_ember_orbiter` spawn calls + its dict entry)
- Modify: `characters/bosses/ignarath.gd:20,31,39,69`
- Modify: `characters/bosses/ignarath.tscn:16-17`

**Interfaces:**
- Consumes: nothing new.
- Produces: nothing consumed by later tasks (each stage is independent).

- [ ] **Step 1: Edit the 8 common enemies**

Full worked example — `characters/enemies/stage_01/enemy_magma_grunt.gd` (Shape A, appears twice):
```gdscript
func _init() -> void:
	max_hp = 3
	contact_damage = 1

func _ready() -> void:
	max_hp = 3
	contact_damage = 1
	super._ready()
```
(was `max_hp = 10` / `contact_damage = 8`, both places — use `replace_all: true`)

Remaining 7 files (verify shape via `grep -n "max_hp\|contact_damage" <file>` first, per the Edit Convention above):

| File | Old HP | New HP | Old Dmg | New Dmg |
|---|---|---|---|---|
| `enemy_molten_ram.gd` | 22 | 15 | 14 | 3 |
| `enemy_ash_hopper.gd` | 7 | 2 | 7 | 1 |
| `enemy_flame_skimmer.gd` | 9 | 2 | 10 | 1 |
| `enemy_cinder_flyer.gd` | 8 | 2 | 7 | 1 |
| `enemy_heat_mortar.gd` | 14 | 4 | 9 | 1 |
| `enemy_magma_turret.gd` | 18 | 4 | 9 | 1 |
| `enemy_lava_serpent.gd` | 14 | 2 | 11 | 2 |

- [ ] **Step 2: Remove enemy_ember_orbiter from the stage**

In `stages/stage_01/stage_01_scene.gd`, delete these 3 lines (Z2 orbiters):
```gdscript
	_spawn_fire("orbiter", "F_Z2Orb1", Vector2(5000, 2380))
	_spawn_fire("orbiter", "F_Z2Orb2", Vector2(6300, 2380))
	_spawn_fire("orbiter", "F_Z2Orb3", Vector2(7900, 2380))
```

Delete this 1 line (Z4 orbiter):
```gdscript
	_spawn_fire("orbiter", "F_Z4Orb1",  Vector2(17648, 1044))   # entre WallPlat2 e WallPlat3
```

Delete the now-unused dict entry:
```gdscript
	"orbiter": preload("res://characters/enemies/stage_01/enemy_ember_orbiter.tscn"),
```
(from the `_FIRE` dictionary near the top of the file)

- [ ] **Step 3: Verify no orbiter references remain**

Run: `grep -n "orbiter" stages/stage_01/stage_01_scene.gd`
Expected: no output (empty).

- [ ] **Step 4: Update Ignarath boss**

In `characters/bosses/ignarath.gd`, apply these 4 edits:

Line 20: `const FIRE_DAMAGE          := 12` → `const FIRE_DAMAGE          := 4`
Line 31: `const CLAW_DAMAGE          := 18` → `const CLAW_DAMAGE          := 5`
Line 39: `const CLAW_WAVE_DAMAGE     := 12` → `const CLAW_WAVE_DAMAGE     := 2`
Line 69 (inside `_ready()`): `	max_hp             = 180` → `	max_hp             = 40`

In `characters/bosses/ignarath.tscn`, replace:
```
max_hp = 200
boss_color = Color(0.9, 0.3, 0.0, 1)
```
with:
```
max_hp = 40
boss_color = Color(0.9, 0.3, 0.0, 1)
contact_damage = 1
```
(Script `_ready()` still wins for `max_hp` at runtime — this keeps the stored value from lying. `contact_damage` isn't touched by `_ready()`, so the `.tscn` value is what actually applies.)

- [ ] **Step 5: Verify**

Run: `grep -n "max_hp\|contact_damage\|FIRE_DAMAGE\|CLAW_DAMAGE\|CLAW_WAVE_DAMAGE" characters/bosses/ignarath.gd characters/bosses/ignarath.tscn`
Expected: `max_hp = 40` (both files), `contact_damage = 1`, `FIRE_DAMAGE := 4`, `CLAW_DAMAGE := 5`, `CLAW_WAVE_DAMAGE := 2`.

- [ ] **Step 6: Run tests**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0.

- [ ] **Step 7: Commit**

```bash
git add characters/enemies/stage_01/ stages/stage_01/stage_01_scene.gd characters/bosses/ignarath.gd characters/bosses/ignarath.tscn
git commit -m "feat: rebalance stage 01 enemies and Ignarath, remove ember_orbiter"
```

---

### Task 5: Stage 02 (Cryovex) — 7 enemies, MB02, boss

**Files:**
- Modify: `characters/enemies/stage_02/enemy_ice_grunt.gd`
- Modify: `characters/enemies/stage_02/enemy_ice_flyer.gd`
- Modify: `characters/enemies/stage_02/enemy_cryo_bomber.gd`
- Modify: `characters/enemies/stage_02/enemy_frost_turret.gd`
- Modify: `characters/enemies/stage_02/enemy_glacier_shield.gd`
- Modify: `characters/enemies/stage_02/enemy_ice_archer.gd`
- Modify: `characters/enemies/stage_02/enemy_ice_wisp.gd`
- Modify: `characters/enemies/stage_02/enemy_ice_miniboss.gd`
- Modify: `characters/bosses/cryovex.gd:40,45,55`
- Modify: `characters/bosses/cryovex.tscn:12-13`

- [ ] **Step 1: Edit the 7 common enemies + MB02**

Verify shape via `grep -n "max_hp\|contact_damage" <file>` first (per Edit Convention).

| File | Old HP | New HP | Old Dmg | New Dmg |
|---|---|---|---|---|
| `enemy_ice_grunt.gd` | 10 | 3 | 8 | 1 |
| `enemy_ice_flyer.gd` | 9 | 2 | 7 | 1 |
| `enemy_cryo_bomber.gd` | 16 | 3 | 9 | 3 |
| `enemy_frost_turret.gd` | 14 | 4 | 6 | 1 |
| `enemy_glacier_shield.gd` | 18 | 2 | 10 | 2 |
| `enemy_ice_archer.gd` | 12 | 2 | 7 | 1 |
| `enemy_ice_wisp.gd` | 8 | 1 | 6 | 1 |
| `enemy_ice_miniboss.gd` (MB02, Shape A) | 44 | 15 | 8 | 3 |

- [ ] **Step 2: Update Cryovex boss**

In `characters/bosses/cryovex.gd`, apply these 3 edits:

Line 40: `const _ICE_ORB_DAMAGE  := 14` → `const _ICE_ORB_DAMAGE  := 4`
Line 45: `const _ICE_TOOTH_DAMAGE    := 6` → `const _ICE_TOOTH_DAMAGE    := 3`
Line 55: `const _BITE_DAMAGE := 16` → `const _BITE_DAMAGE := 3`

In `characters/bosses/cryovex.tscn`, replace:
```
max_hp = 200
boss_color = Color(0.3, 0.7, 1.0, 1)
```
with:
```
max_hp = 40
boss_color = Color(0.3, 0.7, 1.0, 1)
contact_damage = 2
```
(Cryovex has no script-side `_ready()` override — the `.tscn` value is the only source of truth here, no ambiguity to fix.)

- [ ] **Step 3: Verify**

Run: `grep -n "max_hp\|contact_damage\|_ICE_ORB_DAMAGE\|_ICE_TOOTH_DAMAGE\|_BITE_DAMAGE" characters/bosses/cryovex.gd characters/bosses/cryovex.tscn`
Expected: `max_hp = 40`, `contact_damage = 2`, `_ICE_ORB_DAMAGE := 4`, `_ICE_TOOTH_DAMAGE := 3`, `_BITE_DAMAGE := 3`.

- [ ] **Step 4: Run test**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_02/ characters/bosses/cryovex.gd characters/bosses/cryovex.tscn
git commit -m "feat: rebalance stage 02 enemies and Cryovex"
```

---

### Task 6: Stage 03 (Voltrix) — 9 enemies, boss HP only

**Files:**
- Modify: `characters/enemies/stage_03/enemy_volt_guard.gd`
- Modify: `characters/enemies/stage_03/enemy_rail_runner.gd`
- Modify: `characters/enemies/stage_03/enemy_thunder_hawklet.gd`
- Modify: `characters/enemies/stage_03/enemy_storm_kite.gd`
- Modify: `characters/enemies/stage_03/enemy_arc_orbiter.gd`
- Modify: `characters/enemies/stage_03/enemy_static_interceptor.gd`
- Modify: `characters/enemies/stage_03/enemy_tesla_coil.gd`
- Modify: `characters/enemies/stage_03/enemy_arc_turret.gd`
- Modify: `characters/enemies/stage_03/enemy_storm_relay.gd`
- Modify: `characters/bosses/voltrix.tscn:12`

**Do not touch** `characters/bosses/voltrix.gd` — its attack damage (contact + projectile, currently hardcoded `18` inline in `_do_attack()`) is one of the 5 pending items. Only `max_hp` changes for this boss.

- [ ] **Step 1: Edit the 9 common enemies**

Verify shape via `grep -n "max_hp\|contact_damage" <file>` first.

| File | Old HP | New HP | Old Dmg | New Dmg |
|---|---|---|---|---|
| `enemy_volt_guard.gd` | 12 | 3 | 8 | 1 |
| `enemy_rail_runner.gd` | 10 | 3 | 10 | 2 |
| `enemy_thunder_hawklet.gd` | 7 | 1 | 9 | 1 |
| `enemy_storm_kite.gd` | 8 | 1 | 7 | 1 |
| `enemy_arc_orbiter.gd` | 8 | 2 | 6 | 1 |
| `enemy_static_interceptor.gd` | 9 | 2 | 8 | 1 |
| `enemy_tesla_coil.gd` | 16 | 4 | 9 | 3 |
| `enemy_arc_turret.gd` | 18 | 5 | 9 | 1 |
| `enemy_storm_relay.gd` | 10 | 3 | 6 | 2 |

- [ ] **Step 2: Update Voltrix HP only**

In `characters/bosses/voltrix.tscn:12`, replace:
```
max_hp = 200
```
with:
```
max_hp = 40
```

- [ ] **Step 3: Verify**

Run: `grep -n "max_hp" characters/bosses/voltrix.tscn`
Expected: `max_hp = 40`.

Run: `grep -c "18" characters/bosses/voltrix.gd` — confirm this is unchanged from before this task (the attack damage `18` and `contact_damage` default of `15` from `boss_base.gd` must still be untouched).

- [ ] **Step 4: Run test**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_03/ characters/bosses/voltrix.tscn
git commit -m "feat: rebalance stage 03 enemies, Voltrix HP only (attacks pending)"
```

---

### Task 7: Stage 04 (Gravitus) — 9 enemies, boss (incl. new satellite attack)

**Files:**
- Modify: `characters/enemies/stage_04/enemy_grav_guard.gd`
- Modify: `characters/enemies/stage_04/enemy_mass_brute.gd`
- Modify: `characters/enemies/stage_04/enemy_orbit_mauler.gd`
- Modify: `characters/enemies/stage_04/enemy_void_drone.gd`
- Modify: `characters/enemies/stage_04/enemy_gravity_mine.gd`
- Modify: `characters/enemies/stage_04/enemy_debris_orbiter.gd`
- Modify: `characters/enemies/stage_04/enemy_singularity_turret.gd`
- Modify: `characters/enemies/stage_04/enemy_grav_well.gd`
- Modify: `characters/enemies/stage_04/enemy_crush_pylon.gd`
- Modify: `characters/bosses/gravitus.gd:57-59`
- Modify: `characters/bosses/gravitus_satellite.gd:33`
- Modify: `characters/bosses/gravitus.tscn:12-13`

**Note:** Gravitus is mid-rework on the current branch (uncommitted new files for laser/satellite/singularity FX — see `git status`). `gravitus_satellite.gd` already exists on disk; edit it in place like any other file.

- [ ] **Step 1: Edit the 9 common enemies**

Verify shape via `grep -n "max_hp\|contact_damage" <file>` first.

| File | Old HP | New HP | Old Dmg | New Dmg |
|---|---|---|---|---|
| `enemy_grav_guard.gd` | 12 | 3 | 8 | 1 |
| `enemy_mass_brute.gd` | 20 | 6 | 12 | 3 |
| `enemy_orbit_mauler.gd` | 9 | 3 | 11 | 2 |
| `enemy_void_drone.gd` | 7 | 2 | 9 | 1 |
| `enemy_gravity_mine.gd` | 6 | 1 | 12 | 5 |
| `enemy_debris_orbiter.gd` | 8 | 2 | 6 | 1 |
| `enemy_singularity_turret.gd` | 18 | 4 | 9 | 1 |
| `enemy_grav_well.gd` | 14 | 4 | 10 | 1 |
| `enemy_crush_pylon.gd` | 16 | 5 | 9 | 2 |

- [ ] **Step 2: Update Gravitus boss**

In `characters/bosses/gravitus.gd`, apply these 3 edits:

Line 57: `const _SLAM_DAMAGE  := 14` → `const _SLAM_DAMAGE  := 3`
Line 58: `const _PUNCH_DAMAGE := 16` → `const _PUNCH_DAMAGE := 4`
Line 59: `const _MISSILE_DAMAGE := 8` → `const _MISSILE_DAMAGE := 2`

In `characters/bosses/gravitus_satellite.gd:33`, replace:
```gdscript
const _STRIKE_DAMAGE := 18
```
with:
```gdscript
const _STRIKE_DAMAGE := 1
```

In `characters/bosses/gravitus.tscn`, replace:
```
max_hp = 200
boss_color = Color(0.5, 0.0, 0.8, 1)
```
with:
```
max_hp = 40
boss_color = Color(0.5, 0.0, 0.8, 1)
contact_damage = 3
```

- [ ] **Step 3: Verify**

Run: `grep -n "max_hp\|contact_damage\|_SLAM_DAMAGE\|_PUNCH_DAMAGE\|_MISSILE_DAMAGE" characters/bosses/gravitus.gd characters/bosses/gravitus.tscn`
Expected: `max_hp = 40`, `contact_damage = 3`, `_SLAM_DAMAGE := 3`, `_PUNCH_DAMAGE := 4`, `_MISSILE_DAMAGE := 2`.

Run: `grep -n "_STRIKE_DAMAGE" characters/bosses/gravitus_satellite.gd`
Expected: `_STRIKE_DAMAGE := 1`.

- [ ] **Step 4: Run test**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_04/ characters/bosses/gravitus.gd characters/bosses/gravitus_satellite.gd characters/bosses/gravitus.tscn
git commit -m "feat: rebalance stage 04 enemies and Gravitus"
```

---

### Task 8: Stage 05 (Galerix) — 9 enemies, boss HP only

**Files:**
- Modify: `characters/enemies/stage_05/enemy_gale_runner.gd`
- Modify: `characters/enemies/stage_05/enemy_claw_glider.gd`
- Modify: `characters/enemies/stage_05/enemy_airfoil_lancer.gd`
- Modify: `characters/enemies/stage_05/enemy_sky_harrier.gd`
- Modify: `characters/enemies/stage_05/enemy_turbine_wisp.gd`
- Modify: `characters/enemies/stage_05/enemy_feather_swarm.gd`
- Modify: `characters/enemies/stage_05/enemy_gale_grappler.gd`
- Modify: `characters/enemies/stage_05/enemy_gale_turret.gd`
- Modify: `characters/enemies/stage_05/enemy_updraft_fan.gd`
- Modify: `characters/bosses/galerix.tscn:12`

**Do not touch** `characters/bosses/galerix.gd` — its attack damage (contact + projectile, currently hardcoded `10` inline in `_do_attack()`) is one of the 5 pending items. Only `max_hp` changes.

- [ ] **Step 1: Edit the 9 common enemies**

Verify shape via `grep -n "max_hp\|contact_damage" <file>` first.

| File | Old HP | New HP | Old Dmg | New Dmg |
|---|---|---|---|---|
| `enemy_gale_runner.gd` | 9 | 3 | 6 | 1 |
| `enemy_claw_glider.gd` | 10 | 3 | 9 | 2 |
| `enemy_airfoil_lancer.gd` | 11 | 3 | 6 | 1 |
| `enemy_sky_harrier.gd` | 8 | 2 | 9 | 1 |
| `enemy_turbine_wisp.gd` | 7 | 2 | 5 | 1 |
| `enemy_feather_swarm.gd` | 6 | 2 | 6 | 1 |
| `enemy_gale_grappler.gd` | 16 | 4 | 13 | 3 |
| `enemy_gale_turret.gd` | 15 | 4 | 8 | 1 |
| `enemy_updraft_fan.gd` | 13 | 4 | 6 | 1 |

- [ ] **Step 2: Update Galerix HP only**

In `characters/bosses/galerix.tscn:12`, replace:
```
max_hp = 200
```
with:
```
max_hp = 40
```

- [ ] **Step 3: Verify**

Run: `grep -n "max_hp" characters/bosses/galerix.tscn`
Expected: `max_hp = 40`.

- [ ] **Step 4: Run test**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_05/ characters/bosses/galerix.tscn
git commit -m "feat: rebalance stage 05 enemies, Galerix HP only (attacks pending)"
```

---

### Task 9: Stage 06 (Umbraex) — 9 enemies, boss

**Files:**
- Modify: `characters/enemies/stage_06/enemy_shadow_stalker.gd`
- Modify: `characters/enemies/stage_06/enemy_eclipse_duelist.gd`
- Modify: `characters/enemies/stage_06/enemy_night_pouncer.gd`
- Modify: `characters/enemies/stage_06/enemy_umbra_bat.gd`
- Modify: `characters/enemies/stage_06/enemy_void_orbiter.gd`
- Modify: `characters/enemies/stage_06/enemy_shadow_snare.gd`
- Modify: `characters/enemies/stage_06/enemy_phase_mine.gd`
- Modify: `characters/enemies/stage_06/enemy_dark_lantern.gd`
- Modify: `characters/enemies/stage_06/enemy_eclipse_turret.gd`
- Modify: `characters/bosses/umbraex.gd:27-32`
- Modify: `characters/bosses/umbraex.tscn:12-13`

- [ ] **Step 1: Edit the 9 common enemies**

Verify shape via `grep -n "max_hp\|contact_damage" <file>` first.

| File | Old HP | New HP | Old Dmg | New Dmg |
|---|---|---|---|---|
| `enemy_shadow_stalker.gd` | 10 | 3 | 9 | 1 |
| `enemy_eclipse_duelist.gd` | 24 | 3 | 13 | 4 |
| `enemy_night_pouncer.gd` | 8 | 2 | 8 | 1 |
| `enemy_umbra_bat.gd` | 8 | 2 | 9 | 1 |
| `enemy_void_orbiter.gd` | 7 | 2 | 5 | 1 |
| `enemy_shadow_snare.gd` | 16 | 3 | 13 | 2 |
| `enemy_phase_mine.gd` | 6 | 1 | 12 | 3 |
| `enemy_dark_lantern.gd` | 14 | 4 | 10 | 1 |
| `enemy_eclipse_turret.gd` | 15 | 5 | 8 | 1 |

- [ ] **Step 2: Update Umbraex boss**

In `characters/bosses/umbraex.gd`, apply these 3 edits:

Line 27: `const _PUNCH_DAMAGE := 16` → `const _PUNCH_DAMAGE := 3`
Line 28: `const _SHURIKEN_DAMAGE := 8` → `const _SHURIKEN_DAMAGE := 3`
Line 32: `const _KUNAI_DAMAGE := 10` → `const _KUNAI_DAMAGE := 4`

In `characters/bosses/umbraex.tscn`, replace:
```
max_hp = 200
boss_color = Color(0.2, 0.0, 0.3, 1)
```
with:
```
max_hp = 40
boss_color = Color(0.2, 0.0, 0.3, 1)
contact_damage = 3
```

- [ ] **Step 3: Verify**

Run: `grep -n "max_hp\|contact_damage\|_PUNCH_DAMAGE\|_SHURIKEN_DAMAGE\|_KUNAI_DAMAGE" characters/bosses/umbraex.gd characters/bosses/umbraex.tscn`
Expected: `max_hp = 40`, `contact_damage = 3`, `_PUNCH_DAMAGE := 3`, `_SHURIKEN_DAMAGE := 3`, `_KUNAI_DAMAGE := 4`.

- [ ] **Step 4: Run test**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_06/ characters/bosses/umbraex.gd characters/bosses/umbraex.tscn
git commit -m "feat: rebalance stage 06 enemies and Umbraex"
```

---

### Task 10: Stage 07 (Luxar) — 9 enemies, boss HP only

**Files:**
- Modify: `characters/enemies/stage_07/enemy_solar_guard.gd`
- Modify: `characters/enemies/stage_07/enemy_mirror_ram.gd`
- Modify: `characters/enemies/stage_07/enemy_lion_cub_runner.gd`
- Modify: `characters/enemies/stage_07/enemy_glasswing_drone.gd`
- Modify: `characters/enemies/stage_07/enemy_prism_orbiter.gd`
- Modify: `characters/enemies/stage_07/enemy_mirror_moth.gd`
- Modify: `characters/enemies/stage_07/enemy_sun_grabber.gd`
- Modify: `characters/enemies/stage_07/enemy_radiant_pylon.gd`
- Modify: `characters/enemies/stage_07/enemy_beam_turret.gd`
- Modify: `characters/bosses/luxar.tscn:12`

**Do not touch** `characters/bosses/luxar.gd` — its attack damage (contact + feixe, currently hardcoded `20` inline in `_do_attack()`) is one of the 5 pending items. Only `max_hp` changes. (Luxar's existing `_ready()` only sets `gravity_scale = 0.0` — it does not touch `max_hp`, so there is no script/scene ambiguity to fix here.)

- [ ] **Step 1: Edit the 9 common enemies**

Verify shape via `grep -n "max_hp\|contact_damage" <file>` first.

| File | Old HP | New HP | Old Dmg | New Dmg |
|---|---|---|---|---|
| `enemy_solar_guard.gd` | 10 | 3 | 8 | 1 |
| `enemy_mirror_ram.gd` | 22 | 6 | 12 | 3 |
| `enemy_lion_cub_runner.gd` | 8 | 2 | 6 | 1 |
| `enemy_glasswing_drone.gd` | 8 | 2 | 8 | 1 |
| `enemy_prism_orbiter.gd` | 7 | 2 | 5 | 1 |
| `enemy_mirror_moth.gd` | 6 | 1 | 6 | 1 |
| `enemy_sun_grabber.gd` | 20 | 4 | 14 | 3 |
| `enemy_radiant_pylon.gd` | 12 | 4 | 6 | 1 |
| `enemy_beam_turret.gd` | 15 | 4 | 8 | 1 |

- [ ] **Step 2: Update Luxar HP only**

In `characters/bosses/luxar.tscn:12`, replace:
```
max_hp = 200
```
with:
```
max_hp = 40
```

- [ ] **Step 3: Verify**

Run: `grep -n "max_hp" characters/bosses/luxar.tscn`
Expected: `max_hp = 40`.

- [ ] **Step 4: Run test**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_07/ characters/bosses/luxar.tscn
git commit -m "feat: rebalance stage 07 enemies, Luxar HP only (attacks pending)"
```

---

### Task 11: Stage 08 (Terragor) — 9 enemies, boss (incl. quake_wave + stone_shatter)

**Files:**
- Modify: `characters/enemies/stage_08/enemy_terra_grunt.gd`
- Modify: `characters/enemies/stage_08/enemy_mossback_brute.gd`
- Modify: `characters/enemies/stage_08/enemy_drill_mole.gd`
- Modify: `characters/enemies/stage_08/enemy_gem_wasp.gd`
- Modify: `characters/enemies/stage_08/enemy_stone_glider.gd`
- Modify: `characters/enemies/stage_08/enemy_ore_orbiter.gd`
- Modify: `characters/enemies/stage_08/enemy_root_snare.gd`
- Modify: `characters/enemies/stage_08/enemy_boulder_turret.gd`
- Modify: `characters/enemies/stage_08/enemy_fossil_totem.gd`
- Modify: `characters/bosses/terragor.gd:47,49`
- Modify: `characters/bosses/quake_wave.gd:18`
- Modify: `characters/bosses/rolling_boulder.gd:21,108`
- Modify: `characters/bosses/terragor.tscn:12-13`

- [ ] **Step 1: Edit the 7 common enemies (excluding the 2 turrets, handled next)**

Verify shape via `grep -n "max_hp\|contact_damage" <file>` first.

| File | Old HP | New HP | Old Dmg | New Dmg |
|---|---|---|---|---|
| `enemy_terra_grunt.gd` | 8 | 3 | 6 | 1 |
| `enemy_mossback_brute.gd` | 22 | 6 | 12 | 3 |
| `enemy_drill_mole.gd` | 10 | 3 | 8 | 1 |
| `enemy_gem_wasp.gd` | 6 | 2 | 6 | 1 |
| `enemy_stone_glider.gd` | 8 | 2 | 5 | 1 |
| `enemy_ore_orbiter.gd` | 12 | 3 | 8 | 2 |
| `enemy_root_snare.gd` | 14 | 4 | 10 | 2 |

- [ ] **Step 2: Edit the 2 turrets (HP + contact_damage + projectile BOLT_DAMAGE)**

`enemy_boulder_turret.gd` — 3 edits:
- `max_hp = 12` → `max_hp = 4` (appears twice, `replace_all: true`)
- `contact_damage = 0` → `contact_damage = 1` (appears twice, `replace_all: true`)
- `const BOLT_DAMAGE := 7` → `const BOLT_DAMAGE := 1`

`enemy_fossil_totem.gd` — 3 edits:
- `max_hp = 16` → `max_hp = 5` (appears twice, `replace_all: true`)
- `contact_damage = 0` → `contact_damage = 1` (appears twice, `replace_all: true`)
- `const BOLT_DAMAGE := 7` → `const BOLT_DAMAGE := 2`

- [ ] **Step 3: Update Terragor's named attack constants**

In `characters/bosses/terragor.gd`, apply 2 edits:

Line 47: `const _BOULDER_DAMAGE    := 18` → `const _BOULDER_DAMAGE    := 4`
Line 49: `const _BREATH_DAMAGE     := 7` → `const _BREATH_DAMAGE     := 3`

- [ ] **Step 4: Update the quake_wave shockwave damage (used only by Terragor's ground smash)**

In `characters/bosses/quake_wave.gd:18`, replace:
```gdscript
@export var damage: int = 12
```
with:
```gdscript
@export var damage: int = 3
```

- [ ] **Step 5: Update the rolling boulder + fragment damage (used only by Terragor's stone_shatter)**

In `characters/bosses/rolling_boulder.gd`, apply 2 edits:

Line 21: `var damage: int = 16` → `var damage: int = 4`
Line 108: `frag.damage = 6` → `frag.damage = 2`

(`_do_throw_legal()` in `terragor.gd` explicitly sets `boulder.damage = _BOULDER_DAMAGE` after instantiating, so this default of `4` only takes effect for `_do_stone_shatter()`, which doesn't override it — both paths end up dealing `4`, matching the spec.)

- [ ] **Step 6: Update Terragor HP and contact damage**

In `characters/bosses/terragor.tscn`, replace:
```
max_hp = 200
boss_color = Color(0.5, 0.3, 0.1, 1)
```
with:
```
max_hp = 40
boss_color = Color(0.5, 0.3, 0.1, 1)
contact_damage = 2
```

- [ ] **Step 7: Verify**

Run: `grep -n "max_hp\|contact_damage\|BOLT_DAMAGE" characters/enemies/stage_08/enemy_boulder_turret.gd characters/enemies/stage_08/enemy_fossil_totem.gd`
Expected: boulder_turret shows `max_hp = 4` (x2), `contact_damage = 1` (x2), `BOLT_DAMAGE := 1`; fossil_totem shows `max_hp = 5` (x2), `contact_damage = 1` (x2), `BOLT_DAMAGE := 2`.

Run: `grep -n "_BOULDER_DAMAGE\|_BREATH_DAMAGE\|max_hp\|contact_damage" characters/bosses/terragor.gd characters/bosses/terragor.tscn`
Expected: `_BOULDER_DAMAGE := 4`, `_BREATH_DAMAGE := 3`, `max_hp = 40`, `contact_damage = 2`.

Run: `grep -n "damage" characters/bosses/quake_wave.gd characters/bosses/rolling_boulder.gd`
Expected: `quake_wave.gd` shows `damage: int = 3`; `rolling_boulder.gd` shows `damage: int = 4` and `frag.damage = 2`.

- [ ] **Step 8: Run test**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0.

- [ ] **Step 9: Commit**

```bash
git add characters/enemies/stage_08/ characters/bosses/terragor.gd characters/bosses/terragor.tscn characters/bosses/quake_wave.gd characters/bosses/rolling_boulder.gd
git commit -m "feat: rebalance stage 08 enemies and Terragor (incl. quake_wave, stone_shatter)"
```

---

### Task 12: Stage 09 (Gauntlet) — no code change, verification only

**Files:** none modified.

- [ ] **Step 1: Confirm no gauntlet-specific override exists**

Run: `grep -rn "max_hp\|contact_damage" stages/stage_09/ 2>/dev/null`
Expected: no per-boss HP/damage override in the gauntlet stage script (it should just instance the same boss scenes already edited in Tasks 4-11 in sequence). If an override IS found, stop and flag it — the spec says the gauntlet uses identical values to each boss's home stage, so any such override would need to be removed, which is out of scope for this plan as written and should be confirmed with the user first.

- [ ] **Step 2: No commit needed** (verification-only task, skip if step 1 found nothing to change)

---

### Task 13: Nullvex + Nullvex True — HP only

**Files:**
- Modify: `characters/bosses/nullvex.tscn:12`
- Modify: `characters/bosses/nullvex_true.tscn:12`

**Do not touch** `characters/bosses/nullvex.gd` or `characters/bosses/nullvex_true.gd` — their attack damage (contact + projectiles) are 2 of the 5 pending items. Only `max_hp` changes for both.

- [ ] **Step 1: Update Nullvex HP**

In `characters/bosses/nullvex.tscn:12`, replace:
```
max_hp = 400
```
with:
```
max_hp = 40
```

- [ ] **Step 2: Update Nullvex True HP**

In `characters/bosses/nullvex_true.tscn:12`, replace:
```
max_hp = 600
```
with:
```
max_hp = 70
```

- [ ] **Step 3: Verify**

Run: `grep -n "max_hp" characters/bosses/nullvex.tscn characters/bosses/nullvex_true.tscn`
Expected: `nullvex.tscn` shows `max_hp = 40`; `nullvex_true.tscn` shows `max_hp = 70`.

- [ ] **Step 4: Run test**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add characters/bosses/nullvex.tscn characters/bosses/nullvex_true.tscn
git commit -m "feat: rebalance Nullvex and Nullvex True HP (attacks pending)"
```

---

### Task 14: Full Regression Pass

**Files:** none modified (verification only, fixes only if regressions found).

- [ ] **Step 1: Run every existing headless test**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_boss_base.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_intro_boss.tscn
```
Expected: every one exits 0 with its corresponding "all tests passed" line.

- [ ] **Step 2: Grep-audit for any remaining 0 contact_damage**

Run: `grep -rn "contact_damage = 0" characters/enemies/ characters/bosses/`
Expected: no output. If any file still shows `0`, it was missed in an earlier task — go back and fix it (Global Constraint: minimum contact damage is 1).

- [ ] **Step 3: Grep-audit for any remaining old boss max_hp = 200/400/600/28/120/180**

Run: `grep -rn "max_hp = 200\|max_hp = 400\|max_hp = 600\|max_hp = 28\b\|max_hp             = 120\|max_hp             = 180" characters/bosses/`
Expected: no output.

- [ ] **Step 4: If all checks pass, this plan is complete.** No further commit needed for this task — Steps 1-3 are pure verification.

---

## Deferred Work (not part of this plan)

Per the spec's "Itens Pendentes" section, these 5 attack-damage decisions were deferred by the user and are **not implemented by this plan**:

1. Voltrix — contact + projectile damage
2. Galerix — contact + projectile damage
3. Luxar — contact + feixe damage
4. Nullvex — contact + tiro em leque damage
5. Nullvex True — contact + projétil fase1-2 + projétil de queda fase3 damage

When the user is ready to close these, a small follow-up plan (or direct edits, given the small size) can apply them the same way Tasks 4/5/7/9/11 handled their bosses' attack constants.
