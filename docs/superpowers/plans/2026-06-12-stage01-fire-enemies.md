# Stage 01 Fire Enemies Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fire-stage common enemy roster for `stage_01` with 9 new enemy definitions split across ground, flyer, and ranged roles, including a lava-serpent ranged enemy that submerges and spits fire.

**Architecture:** Keep the stage layout and boss content intact, but replace the current generic stage 01 combatants with a dedicated fire roster built on the existing `EnemyBase` and `EnemyFlyer` patterns. Sprite assets come from `generate2dsprite`, while ranged attacks use a small shared projectile implementation so each enemy can own its attack timing without duplicating motion/hit logic.

**Tech Stack:** Godot 4, GDScript, existing `EnemyBase` / `EnemyFlyer`, `generate2dsprite`, Godot headless tests.

---

## Roster

The new fire roster has 9 enemy definitions:

Ground:
- `enemy_magma_grunt`
- `enemy_cinder_brute`
- `enemy_ash_hopper`

Flyers:
- `enemy_ember_wisp`
- `enemy_flame_skimmer`
- `enemy_cinder_flyer`

Ranged:
- `enemy_fire_archer`
- `enemy_magma_turret`
- `enemy_lava_serpent`

Sprite rule for every enemy: the first frame/sprite is always `idle`.

Ranged attack rule:
- `enemy_fire_archer`: standing shot / recover loop
- `enemy_magma_turret`: stationary shot loop, no turning
- `enemy_lava_serpent`: submerge -> emerge -> static -> spit fire -> submerge

---

### Task 1: Generate the fire enemy art

**Files:**
- Create: `characters/enemies/stage_01/enemy_magma_grunt.png`
- Create: `characters/enemies/stage_01/enemy_cinder_brute.png`
- Create: `characters/enemies/stage_01/enemy_ash_hopper.png`
- Create: `characters/enemies/stage_01/enemy_ember_wisp.png`
- Create: `characters/enemies/stage_01/enemy_flame_skimmer.png`
- Create: `characters/enemies/stage_01/enemy_cinder_flyer.png`
- Create: `characters/enemies/stage_01/enemy_fire_archer.png`
- Create: `characters/enemies/stage_01/enemy_magma_turret.png`
- Create: `characters/enemies/stage_01/enemy_lava_serpent.png`
- Create: `characters/ranged/stage_01/fire_bolt.png`
- Create: `characters/ranged/stage_01/fire_glob.png`
- Create: `characters/ranged/stage_01/fire_spit.png`

- [ ] **Step 1: Run `generate2dsprite` for the 9 enemies**

Generate transparent PNG sheets with a consistent fire palette and readable silhouettes. Keep `idle` as the first frame in every sheet, and give the lava serpent a clear submerged/emerge/spit sequence.

- [ ] **Step 2: Run `generate2dsprite` for the ranged projectiles**

Generate the three projectile sheets so the archer, turret, and serpent can each read distinctly in motion.

- [ ] **Step 3: Verify the imported textures load in Godot**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\Usuário\SnesGame" --quit
```
Expected: project opens without import errors, and the new PNGs appear under the `characters/enemies/stage_01` and `characters/ranged/stage_01` folders.

- [ ] **Step 4: Commit the generated art**

```bash
git add characters/enemies/stage_01 characters/ranged/stage_01
git commit -m "feat: add stage 01 fire enemy art"
```

---

### Task 2: Implement the 9 enemy definitions

**Files:**
- Create: `characters/enemies/stage_01/enemy_magma_grunt.gd`
- Create: `characters/enemies/stage_01/enemy_magma_grunt.tscn`
- Create: `characters/enemies/stage_01/enemy_cinder_brute.gd`
- Create: `characters/enemies/stage_01/enemy_cinder_brute.tscn`
- Create: `characters/enemies/stage_01/enemy_ash_hopper.gd`
- Create: `characters/enemies/stage_01/enemy_ash_hopper.tscn`
- Create: `characters/enemies/stage_01/enemy_ember_wisp.gd`
- Create: `characters/enemies/stage_01/enemy_ember_wisp.tscn`
- Create: `characters/enemies/stage_01/enemy_flame_skimmer.gd`
- Create: `characters/enemies/stage_01/enemy_flame_skimmer.tscn`
- Create: `characters/enemies/stage_01/enemy_cinder_flyer.gd`
- Create: `characters/enemies/stage_01/enemy_cinder_flyer.tscn`
- Create: `characters/enemies/stage_01/enemy_fire_archer.gd`
- Create: `characters/enemies/stage_01/enemy_fire_archer.tscn`
- Create: `characters/enemies/stage_01/enemy_magma_turret.gd`
- Create: `characters/enemies/stage_01/enemy_magma_turret.tscn`
- Create: `characters/enemies/stage_01/enemy_lava_serpent.gd`
- Create: `characters/enemies/stage_01/enemy_lava_serpent.tscn`
- Create: `characters/ranged/stage_01/fire_bolt.gd`
- Create: `characters/ranged/stage_01/fire_bolt.tscn`
- Create: `characters/ranged/stage_01/fire_glob.gd`
- Create: `characters/ranged/stage_01/fire_glob.tscn`
- Create: `characters/ranged/stage_01/fire_spit.gd`
- Create: `characters/ranged/stage_01/fire_spit.tscn`
- Test: `tests/test_stage01_fire_enemies.gd`
- Test: `tests/test_stage01_fire_enemies.tscn`

- [ ] **Step 1: Write the enemy scenes against the existing base classes**

Ground enemies use `EnemyBase`; flyers use `EnemyFlyer`; ranged enemies use a small shared projectile scene or a projectile helper that mirrors the existing `boss_projectile` / `zael_bullet` pattern.

- [ ] **Step 2: Implement the movement and attack loops**

Keep the ground enemies distinct:
- `enemy_magma_grunt`: simple patrol pressure
- `enemy_cinder_brute`: slow heavy advance with a stronger contact hit
- `enemy_ash_hopper`: hop timing to break up floor rhythm

Keep the flyers distinct:
- `enemy_ember_wisp`: hover and short burst attack
- `enemy_flame_skimmer`: dive and retreat loop
- `enemy_cinder_flyer`: hover with a fire drop / harassment loop

Keep the ranged enemies distinct:
- `enemy_fire_archer`: stationary shot and recover
- `enemy_magma_turret`: fixed position, no turning
- `enemy_lava_serpent`: lava submerge cycle with a single visible spit window

- [ ] **Step 3: Write a focused test scene**

The test scene should instantiate each new enemy scene, verify the node loads, and confirm the sprite starts on `idle`/frame zero before any attack timer advances.

- [ ] **Step 4: Run the new test suite**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\Usuário\SnesGame" res://tests/test_stage01_fire_enemies.tscn
```
Expected: `ALL TESTS PASSED`

- [ ] **Step 5: Commit the enemy implementation**

```bash
git add characters/enemies/stage_01 characters/ranged/stage_01 tests/test_stage01_fire_enemies.*
git commit -m "feat: add stage 01 fire enemies"
```

---

### Task 3: Wire the roster into Stage 01

**Files:**
- Modify: `stages/stage_01/stage_01.tscn`
- Modify: `stages/stage_01/stage_01_scene.gd`
- Modify: `tests/bot/paths/stage_01.gd`

- [ ] **Step 1: Remove the old generic enemy placements**

Replace the existing stage 01 grunt/flyer placements with instances of the 9 fire enemies so the stage reads as a fire roster instead of a generic placeholder mix.

- [ ] **Step 2: Place the new enemies across the existing zones**

Use the current stage geometry and hazards as-is. Spread the new roster across Z1, Z2, Z3, and Z4 so each zone has clear combat pressure without changing the boss room or adding a miniboss.

- [ ] **Step 3: Keep the current boss content untouched**

Do not alter Ignarath, the boss room layout, or checkpoint flow in this task. The scope is only the common enemy roster.

- [ ] **Step 4: Update the bot path if any new placement blocks traversal**

If the new enemies make the existing bot traversal brittle, adjust `tests/bot/paths/stage_01.gd` so the validation path still clears the stage cleanly and captures at least one screenshot of each enemy family in motion.

- [ ] **Step 5: Commit the stage wiring**

```bash
git add stages/stage_01/stage_01.tscn stages/stage_01/stage_01_scene.gd tests/bot/paths/stage_01.gd
git commit -m "feat: wire fire enemies into stage 01"
```

---

### Task 4: Validate the full stage

**Files:**
- Modify if needed: `tests/test_no_enemies.gd`
- Modify if needed: `tests/test_stage01_hazards.gd`

- [ ] **Step 1: Run the stage-level tests**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\Usuário\SnesGame" res://tests/test_no_enemies.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\Usuário\SnesGame" res://tests/test_stage01_hazards.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\Usuário\SnesGame" res://tests/test_stage01_fire_enemies.tscn
```
Expected: all three suites pass.

- [ ] **Step 2: Run the stage bot path**

Run the stage validation bot for `stage_01` and confirm the new roster does not break the traversal route or the corridor checkpoints.

- [ ] **Step 3: Export web and smoke-test the stage**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\Usuário\SnesGame" --export-release "Web" "C:\Users\Usuário\SnesGame\export\web\index.html"
powershell -Command "Get-Item 'C:\Users\Usuário\SnesGame\export\web\index.pck' | Select-Object LastWriteTime, Length"
```
Expected: `index.pck` has a recent `LastWriteTime`, and the browser build opens `stages/stage_01/stage_01.tscn` without missing textures or scene instantiation errors.

- [ ] **Step 4: Final commit**

Commit only after the test and export pass together.

---

## Out of Scope

- No miniboss for `stage_01`
- No new boss for `stage_01`
- No change to Ignarath AI
- No change to the stage 01 layout or hazards beyond enemy placement
