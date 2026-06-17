# Stage 01 Fire Enemy Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate and integrate production sprite sheets for the 9 Stage 01 fire enemies and their 4 fire projectiles.

**Architecture:** Generate one raw sheet per enemy or projectile with built-in `image_gen`, then postprocess each sheet with `generate2dsprite.py` for transparent runtime textures, frame PNGs, GIF previews, and QC metadata. Keep generated artifacts under `assets/generated/stage01_<asset>/<action>/` and copy accepted transparent sheets into `characters/enemies/stage_01/` or `characters/ranged/stage_01/`.

**Tech Stack:** built-in `image_gen`, `generate2dsprite.py`, Godot 4.6.2 texture import, HD pixel-art-inspired side-view sprites, solid `#FF00FF` chroma background.

---

## File Structure

- `docs/superpowers/specs/2026-06-17-stage01-fire-enemies-sprite-design.md`: source of truth for roster, visual families, grid flexibility, and acceptance criteria.
- `assets/generated/stage01_enemy_magma_grunt/idle/`: raw and processed sheet for the A-family melee grunt.
- `assets/generated/stage01_enemy_molten_ram/charge/`: raw and processed sheet for the C-family melee ram.
- `assets/generated/stage01_enemy_ash_hopper/hop/`: raw and processed sheet for the B-family rabbit robot hopper.
- `assets/generated/stage01_enemy_ember_orbiter/hover_shoot/`: raw and processed sheet for the B-family shooting orbiter.
- `assets/generated/stage01_enemy_flame_skimmer/dive/`: raw and processed sheet for the C-family fly skimmer.
- `assets/generated/stage01_enemy_cinder_flyer/hover/`: raw and processed sheet for the A-family flyer.
- `assets/generated/stage01_enemy_heat_mortar/shoot/`: raw and processed sheet for the A-family mortar enemy.
- `assets/generated/stage01_enemy_magma_turret/shoot/`: raw and processed sheet for the C-family turret.
- `assets/generated/stage01_enemy_lava_serpent/emerge_spit/`: raw and processed sheet for the B-family lava serpent.
- `assets/generated/stage01_fire_bolt/projectile/`: raw and processed projectile for `enemy_ember_orbiter`.
- `assets/generated/stage01_fire_glob/projectile/`: raw and processed projectile for `enemy_magma_turret`.
- `assets/generated/stage01_fire_spit/projectile/`: raw and processed projectile for `enemy_lava_serpent`.
- `assets/generated/stage01_heat_mortar_shell/projectile/`: raw and processed projectile for `enemy_heat_mortar`.
- `characters/enemies/stage_01/*.png`: final enemy runtime sheets.
- `characters/ranged/stage_01/*.png`: final projectile runtime sheets.

---

### Task 1: Prepare Output Folders And Prompt Files

**Files:**
- Create: `assets/generated/stage01_enemy_magma_grunt/idle/prompt-used.txt`
- Create: `assets/generated/stage01_enemy_molten_ram/charge/prompt-used.txt`
- Create: `assets/generated/stage01_enemy_ash_hopper/hop/prompt-used.txt`
- Create: `assets/generated/stage01_enemy_ember_orbiter/hover_shoot/prompt-used.txt`
- Create: `assets/generated/stage01_enemy_flame_skimmer/dive/prompt-used.txt`
- Create: `assets/generated/stage01_enemy_cinder_flyer/hover/prompt-used.txt`
- Create: `assets/generated/stage01_enemy_heat_mortar/shoot/prompt-used.txt`
- Create: `assets/generated/stage01_enemy_magma_turret/shoot/prompt-used.txt`
- Create: `assets/generated/stage01_enemy_lava_serpent/emerge_spit/prompt-used.txt`
- Create: `assets/generated/stage01_fire_bolt/projectile/prompt-used.txt`
- Create: `assets/generated/stage01_fire_glob/projectile/prompt-used.txt`
- Create: `assets/generated/stage01_fire_spit/projectile/prompt-used.txt`
- Create: `assets/generated/stage01_heat_mortar_shell/projectile/prompt-used.txt`

- [ ] **Step 1: Create output directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  assets/generated/stage01_enemy_magma_grunt/idle, `
  assets/generated/stage01_enemy_molten_ram/charge, `
  assets/generated/stage01_enemy_ash_hopper/hop, `
  assets/generated/stage01_enemy_ember_orbiter/hover_shoot, `
  assets/generated/stage01_enemy_flame_skimmer/dive, `
  assets/generated/stage01_enemy_cinder_flyer/hover, `
  assets/generated/stage01_enemy_heat_mortar/shoot, `
  assets/generated/stage01_enemy_magma_turret/shoot, `
  assets/generated/stage01_enemy_lava_serpent/emerge_spit, `
  assets/generated/stage01_fire_bolt/projectile, `
  assets/generated/stage01_fire_glob/projectile, `
  assets/generated/stage01_fire_spit/projectile, `
  assets/generated/stage01_heat_mortar_shell/projectile, `
  characters/enemies/stage_01, `
  characters/ranged/stage_01
```

Expected: all directories exist.

- [ ] **Step 2: Write prompt files**

Create each `prompt-used.txt` with the exact prompt blocks below. These are the prompts to pass to built-in `image_gen`.

`assets/generated/stage01_enemy_magma_grunt/idle/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: enemy_magma_grunt, a compact fire-stage armored reploid troop from the volcanic domain of a lion reploid boss, short legs, heavy gauntlets, orange-red magma armor plates, dark mechanical joints, glowing heat core on the chest, small thermal crest or claw-shaped armor cuts, aggressive idle stance for a Mega Man X inspired platformer with original IP identity. Motion: frame 1 ready stance, frame 2 slight weight shift, frame 3 fists tighten and heat core brightens, frame 4 return-ready loop pose. Do not make it a small lion; it is a guard soldier that shares the lion boss domain language. Keep the same enemy identity, same bounding box, same pixel scale, centered body, stable feet/bottom anchor in every cell. Full body inside the central 65% safe area, no limbs, armor, glow, sparks, or detached effects crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_enemy_molten_ram/charge/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_molten_ram, a fire-stage industrial lava machine built for ramming in the arena foundry of a lion reploid boss, low-to-medium heavy body, reinforced glowing molten head or chest like a battering ram, foundry plates, pistons, dark steel legs, furnace vents, orange lava seams, front plating that subtly suggests a metal jaw or blunt mane-like heat fins without becoming an animal. Motion read left-to-right: idle crouch, heat buildup, piston compression, forward lean, short burst charge, impact pose, recoil, heavy recovery, return to idle. Keep it as a common enemy, not a boss. Same identity, same scale, centered body, stable bottom anchor in every cell. Full body inside central 65% safe area, no fire trails or wide effects crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_enemy_ash_hopper/hop/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_ash_hopper, a small agile ash-and-ember rabbit robot enemy living in the volcanic territory of a lion reploid boss, mechanical short rabbit ears or antenna ears, segmented rear legs with springs and pistons, wide hopping feet, small hot core in the torso, dark red metal shell with ember orange highlights, tiny claw-cut plates that match the stage's guard language. Motion: crouch, compressed legs, takeoff, airborne hop, landing, ready stance. It must read clearly as a robot rabbit, not a soldier and not a lion. Same identity, same scale, centered body, stable feet/bottom anchor when grounded, airborne frame still centered. Full body inside central 65% safe area, no detached dust or sparks outside the silhouette. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_enemy_ember_orbiter/hover_shoot/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_ember_orbiter, a small fire drone with a glowing ember core and segmented mechanical ring orbiting around it, compact floating enemy from the lion reploid boss domain, dark metal shell pieces, orange-red core, clean circular silhouette, ring segments arranged like an abstract mechanical mane without forming a lion face. Motion: hover idle, ring rotates, core charges, small muzzle or core port opens, shoot pose with compact attached glow only, return to hover. Do not include the detached projectile in this body sheet. Same identity, same scale, centered body in each cell. Full subject inside central 60% safe area with magenta margin on all sides, no ring segment or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_enemy_flame_skimmer/dive/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_flame_skimmer, an industrial lava flying machine for fast dive attacks in the hunting territory of a lion reploid boss, elongated aerodynamic body, furnace vent, turbine intake, red-black metal carapace, orange heated exhaust, claw-like nose fins, sharp predatory readable silhouette. Motion read left-to-right: hover approach, nose dips, turbine flare, dive start, fast dive pose, low attack pass, pull up, stabilizing hover, return pose. Keep effects compact and attached. Same identity, same scale, centered in each cell. Full body inside central 65% safe area, no exhaust flame or wing tip crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_enemy_cinder_flyer/hover/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: enemy_cinder_flyer, a military fire-stage armored patrol drone from a lion reploid boss guard force, compact reploid troop language, hard armor panels with claw-cut shapes, small mechanical wings or side thrusters, front visor, glowing heat core, red-orange armor over dark joints. Motion: steady hover, slight tilt, thruster pulse, return hover. Do not make it an animal; it is a guard drone that shares the boss domain armor language. Same identity, same bounding box, same scale, centered body. Full subject inside central 65% safe area, no thruster plume or wing tip crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_enemy_heat_mortar/shoot/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_heat_mortar, a compact armored reploid fire troop with a shoulder/back mounted mortar cannon, heavy support unit from a lion reploid boss guard force, military silhouette, visor, heat vents, red-black armor, glowing orange barrel, small thermal crest or claw-shaped armor marks. It must not look like an archer. Motion: ready stance, brace feet, mortar angles upward, barrel heats, firing recoil upward, recovery. Do not include detached mortar shell in the body sheet. Same identity, same scale, centered body, stable feet/bottom anchor in each cell. Full body and mortar inside central 65% safe area, no muzzle flash crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_enemy_magma_turret/shoot/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: enemy_magma_turret, a stationary furnace turret from the lion reploid boss foundry, squat square defensive body, front cannon mouth that subtly suggests a metal jaw, glowing molten core, foundry plates, dark bolts and vents, industrial lava machine family. Motion: idle, core heats up, cannon opens and fires compact attached muzzle glow only, cooldown. Do not include detached projectile in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full turret inside central 65% safe area, no muzzle glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_enemy_lava_serpent/emerge_spit/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 4 rows by 4 columns, 16 equal cells. Subject: enemy_lava_serpent, a mechanical lava serpent or eel emerging from a lava pool in the volcanic territory of a lion reploid boss, segmented rigid armor, glowing heat core segments, metal jaw or fire-spit launcher mouth, red-black plates with molten orange seams, predatory mechanical details that fit the boss domain without copying lion anatomy. Action sequence read left-to-right across rows: mostly submerged, head starts emerging, neck rises, body segments rise, visible threat pose, charge heat in mouth, stronger charge, spit pose with compact attached mouth glow only, recoil, lowering, segments descend, head descends, mostly submerged, bubbling mechanical outline, return to hidden state, loop-ready submerged pose. Do not include detached projectile in the body sheet. Same identity, same scale, centered in each cell, lava base stays compact and inside the cell. Full subject inside central 70% safe area, no tail, jaw, glow, splash, or lava crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_fire_bolt/projectile/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: fire_bolt, a small fast ember bolt fired by enemy_ember_orbiter, compact orange-red energy dart with tiny metal-hot core, travel direction left-to-right. Motion: stable bolt, brighter pulse, slightly stretched travel pulse, loop return. Same projectile identity and size in every frame, centered, compact glow. Projectile and glow stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_fire_glob/projectile/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: fire_glob, a heavy molten glob fired by enemy_magma_turret, round orange lava mass with darker crust shards, slow heavy projectile, travel direction left-to-right. Motion: glob pulse, crust opens, molten center brightens, loop return. Same projectile identity and size in every frame, centered, compact glow. Projectile and glow stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_fire_spit/projectile/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: fire_spit, a narrow serpent fire spit projectile, hot orange flame capsule with a small molten core and short contained tail, travel direction left-to-right. Motion: flame capsule, hotter pulse, tail flicker, loop return. Same projectile identity and size in every frame, centered, compact glow and tail. Projectile and tail stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage01_heat_mortar_shell/projectile/prompt-used.txt`

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: heat_mortar_shell, a small arcing mortar shell for enemy_heat_mortar, dark metal shell casing with glowing orange vents and small contained heat trail, designed to fly in a parabola. Motion: shell stable, heat vents brighten, slight spin, loop return. Same projectile identity and size in every frame, centered, compact trail. Projectile and trail stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 3: Commit prompt files**

Run:

```powershell
git add assets/generated/stage01_enemy_magma_grunt assets/generated/stage01_enemy_molten_ram assets/generated/stage01_enemy_ash_hopper assets/generated/stage01_enemy_ember_orbiter assets/generated/stage01_enemy_flame_skimmer assets/generated/stage01_enemy_cinder_flyer assets/generated/stage01_enemy_heat_mortar assets/generated/stage01_enemy_magma_turret assets/generated/stage01_enemy_lava_serpent assets/generated/stage01_fire_bolt assets/generated/stage01_fire_glob assets/generated/stage01_fire_spit assets/generated/stage01_heat_mortar_shell
git commit -m "docs: add stage 01 fire sprite prompts"
```

---

### Task 2: Generate And Process Melee Enemy Sheets

**Files:**
- Create: `assets/generated/stage01_enemy_magma_grunt/idle/raw-sheet.png`
- Create: `assets/generated/stage01_enemy_magma_grunt/idle/sheet-transparent.png`
- Create: `assets/generated/stage01_enemy_molten_ram/charge/raw-sheet.png`
- Create: `assets/generated/stage01_enemy_molten_ram/charge/sheet-transparent.png`
- Create: `assets/generated/stage01_enemy_ash_hopper/hop/raw-sheet.png`
- Create: `assets/generated/stage01_enemy_ash_hopper/hop/sheet-transparent.png`
- Create: `characters/enemies/stage_01/enemy_magma_grunt.png`
- Create: `characters/enemies/stage_01/enemy_molten_ram.png`
- Create: `characters/enemies/stage_01/enemy_ash_hopper.png`

- [ ] **Step 1: Generate the three raw melee sheets with built-in `image_gen`**

Use built-in `image_gen` once for each melee prompt file from Task 1. Save the returned PNGs as:

```text
assets/generated/stage01_enemy_magma_grunt/idle/raw-sheet.png
assets/generated/stage01_enemy_molten_ram/charge/raw-sheet.png
assets/generated/stage01_enemy_ash_hopper/hop/raw-sheet.png
```

Expected: three raw PNG files with solid `#FF00FF` backgrounds.

- [ ] **Step 2: Process melee sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_enemy_magma_grunt/idle/raw-sheet.png --target creature --mode idle --output-dir assets/generated/stage01_enemy_magma_grunt/idle --rows 2 --cols 2 --label-prefix idle --align feet --shared-scale --component-mode largest --fit-scale 0.90 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_enemy_molten_ram/charge/raw-sheet.png --target creature --mode charge --output-dir assets/generated/stage01_enemy_molten_ram/charge --rows 3 --cols 3 --label-prefix charge --align feet --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_enemy_ash_hopper/hop/raw-sheet.png --target creature --mode jump --output-dir assets/generated/stage01_enemy_ash_hopper/hop --rows 2 --cols 3 --label-prefix hop --align feet --shared-scale --component-mode largest --fit-scale 0.90 --reject-edge-touch
```

Expected: each folder has `sheet-transparent.png`, frame PNGs, `animation.gif`, and `pipeline-meta.json` with `"edge_touch_frames": []`.

- [ ] **Step 3: Copy accepted melee sheets to runtime paths**

Run:

```powershell
Copy-Item assets/generated/stage01_enemy_magma_grunt/idle/sheet-transparent.png characters/enemies/stage_01/enemy_magma_grunt.png -Force
Copy-Item assets/generated/stage01_enemy_molten_ram/charge/sheet-transparent.png characters/enemies/stage_01/enemy_molten_ram.png -Force
Copy-Item assets/generated/stage01_enemy_ash_hopper/hop/sheet-transparent.png characters/enemies/stage_01/enemy_ash_hopper.png -Force
```

- [ ] **Step 4: Import melee textures in Godot**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit
```

Expected: command exits `0` and `.import` files are created for the three runtime PNGs.

- [ ] **Step 5: Commit melee sprites**

Run:

```powershell
git add assets/generated/stage01_enemy_magma_grunt assets/generated/stage01_enemy_molten_ram assets/generated/stage01_enemy_ash_hopper characters/enemies/stage_01/enemy_magma_grunt.png characters/enemies/stage_01/enemy_molten_ram.png characters/enemies/stage_01/enemy_ash_hopper.png characters/enemies/stage_01/enemy_magma_grunt.png.import characters/enemies/stage_01/enemy_molten_ram.png.import characters/enemies/stage_01/enemy_ash_hopper.png.import
git commit -m "feat: add stage 01 melee enemy sprites"
```

---

### Task 3: Generate And Process Fly Enemy Sheets

**Files:**
- Create: `assets/generated/stage01_enemy_ember_orbiter/hover_shoot/raw-sheet.png`
- Create: `assets/generated/stage01_enemy_ember_orbiter/hover_shoot/sheet-transparent.png`
- Create: `assets/generated/stage01_enemy_flame_skimmer/dive/raw-sheet.png`
- Create: `assets/generated/stage01_enemy_flame_skimmer/dive/sheet-transparent.png`
- Create: `assets/generated/stage01_enemy_cinder_flyer/hover/raw-sheet.png`
- Create: `assets/generated/stage01_enemy_cinder_flyer/hover/sheet-transparent.png`
- Create: `characters/enemies/stage_01/enemy_ember_orbiter.png`
- Create: `characters/enemies/stage_01/enemy_flame_skimmer.png`
- Create: `characters/enemies/stage_01/enemy_cinder_flyer.png`

- [ ] **Step 1: Generate the three raw fly sheets with built-in `image_gen`**

Use built-in `image_gen` once for each fly prompt file from Task 1. Save the returned PNGs as:

```text
assets/generated/stage01_enemy_ember_orbiter/hover_shoot/raw-sheet.png
assets/generated/stage01_enemy_flame_skimmer/dive/raw-sheet.png
assets/generated/stage01_enemy_cinder_flyer/hover/raw-sheet.png
```

- [ ] **Step 2: Process fly sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_enemy_ember_orbiter/hover_shoot/raw-sheet.png --target creature --mode shoot --output-dir assets/generated/stage01_enemy_ember_orbiter/hover_shoot --rows 2 --cols 3 --label-prefix hover-shoot --align center --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_enemy_flame_skimmer/dive/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage01_enemy_flame_skimmer/dive --rows 3 --cols 3 --label-prefix dive --align center --shared-scale --component-mode largest --fit-scale 0.86 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_enemy_cinder_flyer/hover/raw-sheet.png --target creature --mode hover --output-dir assets/generated/stage01_enemy_cinder_flyer/hover --rows 2 --cols 2 --label-prefix hover --align center --shared-scale --component-mode largest --fit-scale 0.90 --reject-edge-touch
```

Expected: each folder has `sheet-transparent.png`, frame PNGs, `animation.gif`, and `pipeline-meta.json` with `"edge_touch_frames": []`.

- [ ] **Step 3: Copy accepted fly sheets to runtime paths**

Run:

```powershell
Copy-Item assets/generated/stage01_enemy_ember_orbiter/hover_shoot/sheet-transparent.png characters/enemies/stage_01/enemy_ember_orbiter.png -Force
Copy-Item assets/generated/stage01_enemy_flame_skimmer/dive/sheet-transparent.png characters/enemies/stage_01/enemy_flame_skimmer.png -Force
Copy-Item assets/generated/stage01_enemy_cinder_flyer/hover/sheet-transparent.png characters/enemies/stage_01/enemy_cinder_flyer.png -Force
```

- [ ] **Step 4: Import fly textures in Godot**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit
```

Expected: command exits `0` and `.import` files are created for the three runtime PNGs.

- [ ] **Step 5: Commit fly sprites**

Run:

```powershell
git add assets/generated/stage01_enemy_ember_orbiter assets/generated/stage01_enemy_flame_skimmer assets/generated/stage01_enemy_cinder_flyer characters/enemies/stage_01/enemy_ember_orbiter.png characters/enemies/stage_01/enemy_flame_skimmer.png characters/enemies/stage_01/enemy_cinder_flyer.png characters/enemies/stage_01/enemy_ember_orbiter.png.import characters/enemies/stage_01/enemy_flame_skimmer.png.import characters/enemies/stage_01/enemy_cinder_flyer.png.import
git commit -m "feat: add stage 01 flying enemy sprites"
```

---

### Task 4: Generate And Process Ranged Enemy Sheets

**Files:**
- Create: `assets/generated/stage01_enemy_heat_mortar/shoot/raw-sheet.png`
- Create: `assets/generated/stage01_enemy_heat_mortar/shoot/sheet-transparent.png`
- Create: `assets/generated/stage01_enemy_magma_turret/shoot/raw-sheet.png`
- Create: `assets/generated/stage01_enemy_magma_turret/shoot/sheet-transparent.png`
- Create: `assets/generated/stage01_enemy_lava_serpent/emerge_spit/raw-sheet.png`
- Create: `assets/generated/stage01_enemy_lava_serpent/emerge_spit/sheet-transparent.png`
- Create: `characters/enemies/stage_01/enemy_heat_mortar.png`
- Create: `characters/enemies/stage_01/enemy_magma_turret.png`
- Create: `characters/enemies/stage_01/enemy_lava_serpent.png`

- [ ] **Step 1: Generate the three raw ranged sheets with built-in `image_gen`**

Use built-in `image_gen` once for each ranged prompt file from Task 1. Save the returned PNGs as:

```text
assets/generated/stage01_enemy_heat_mortar/shoot/raw-sheet.png
assets/generated/stage01_enemy_magma_turret/shoot/raw-sheet.png
assets/generated/stage01_enemy_lava_serpent/emerge_spit/raw-sheet.png
```

- [ ] **Step 2: Process ranged sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_enemy_heat_mortar/shoot/raw-sheet.png --target creature --mode shoot --output-dir assets/generated/stage01_enemy_heat_mortar/shoot --rows 2 --cols 3 --label-prefix shoot --align feet --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_enemy_magma_turret/shoot/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage01_enemy_magma_turret/shoot --rows 2 --cols 2 --label-prefix shoot --align bottom --shared-scale --component-mode largest --fit-scale 0.90 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_enemy_lava_serpent/emerge_spit/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage01_enemy_lava_serpent/emerge_spit --rows 4 --cols 4 --label-prefix emerge-spit --align bottom --shared-scale --component-mode largest --fit-scale 0.84 --reject-edge-touch
```

Expected: each folder has `sheet-transparent.png`, frame PNGs, `animation.gif`, and `pipeline-meta.json` with `"edge_touch_frames": []`.

- [ ] **Step 3: Copy accepted ranged sheets to runtime paths**

Run:

```powershell
Copy-Item assets/generated/stage01_enemy_heat_mortar/shoot/sheet-transparent.png characters/enemies/stage_01/enemy_heat_mortar.png -Force
Copy-Item assets/generated/stage01_enemy_magma_turret/shoot/sheet-transparent.png characters/enemies/stage_01/enemy_magma_turret.png -Force
Copy-Item assets/generated/stage01_enemy_lava_serpent/emerge_spit/sheet-transparent.png characters/enemies/stage_01/enemy_lava_serpent.png -Force
```

- [ ] **Step 4: Import ranged textures in Godot**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit
```

Expected: command exits `0` and `.import` files are created for the three runtime PNGs.

- [ ] **Step 5: Commit ranged sprites**

Run:

```powershell
git add assets/generated/stage01_enemy_heat_mortar assets/generated/stage01_enemy_magma_turret assets/generated/stage01_enemy_lava_serpent characters/enemies/stage_01/enemy_heat_mortar.png characters/enemies/stage_01/enemy_magma_turret.png characters/enemies/stage_01/enemy_lava_serpent.png characters/enemies/stage_01/enemy_heat_mortar.png.import characters/enemies/stage_01/enemy_magma_turret.png.import characters/enemies/stage_01/enemy_lava_serpent.png.import
git commit -m "feat: add stage 01 ranged enemy sprites"
```

---

### Task 5: Generate And Process Projectile Sheets

**Files:**
- Create: `assets/generated/stage01_fire_bolt/projectile/raw-sheet.png`
- Create: `assets/generated/stage01_fire_bolt/projectile/sheet-transparent.png`
- Create: `assets/generated/stage01_fire_glob/projectile/raw-sheet.png`
- Create: `assets/generated/stage01_fire_glob/projectile/sheet-transparent.png`
- Create: `assets/generated/stage01_fire_spit/projectile/raw-sheet.png`
- Create: `assets/generated/stage01_fire_spit/projectile/sheet-transparent.png`
- Create: `assets/generated/stage01_heat_mortar_shell/projectile/raw-sheet.png`
- Create: `assets/generated/stage01_heat_mortar_shell/projectile/sheet-transparent.png`
- Create: `characters/ranged/stage_01/fire_bolt.png`
- Create: `characters/ranged/stage_01/fire_glob.png`
- Create: `characters/ranged/stage_01/fire_spit.png`
- Create: `characters/ranged/stage_01/heat_mortar_shell.png`

- [ ] **Step 1: Generate the four raw projectile sheets with built-in `image_gen`**

Use built-in `image_gen` once for each projectile prompt file from Task 1. Save the returned PNGs as:

```text
assets/generated/stage01_fire_bolt/projectile/raw-sheet.png
assets/generated/stage01_fire_glob/projectile/raw-sheet.png
assets/generated/stage01_fire_spit/projectile/raw-sheet.png
assets/generated/stage01_heat_mortar_shell/projectile/raw-sheet.png
```

- [ ] **Step 2: Process projectile sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_fire_bolt/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage01_fire_bolt/projectile --rows 2 --cols 2 --label-prefix fire-bolt --align center --shared-scale --component-mode all --fit-scale 0.86 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_fire_glob/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage01_fire_glob/projectile --rows 2 --cols 2 --label-prefix fire-glob --align center --shared-scale --component-mode all --fit-scale 0.86 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_fire_spit/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage01_fire_spit/projectile --rows 2 --cols 2 --label-prefix fire-spit --align center --shared-scale --component-mode all --fit-scale 0.86 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_heat_mortar_shell/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage01_heat_mortar_shell/projectile --rows 2 --cols 2 --label-prefix heat-mortar-shell --align center --shared-scale --component-mode all --fit-scale 0.86 --reject-edge-touch
```

Expected: each folder has `sheet-transparent.png`, frame PNGs, `animation.gif`, and `pipeline-meta.json` with `"edge_touch_frames": []`.

- [ ] **Step 3: Copy accepted projectile sheets to runtime paths**

Run:

```powershell
Copy-Item assets/generated/stage01_fire_bolt/projectile/sheet-transparent.png characters/ranged/stage_01/fire_bolt.png -Force
Copy-Item assets/generated/stage01_fire_glob/projectile/sheet-transparent.png characters/ranged/stage_01/fire_glob.png -Force
Copy-Item assets/generated/stage01_fire_spit/projectile/sheet-transparent.png characters/ranged/stage_01/fire_spit.png -Force
Copy-Item assets/generated/stage01_heat_mortar_shell/projectile/sheet-transparent.png characters/ranged/stage_01/heat_mortar_shell.png -Force
```

- [ ] **Step 4: Import projectile textures in Godot**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit
```

Expected: command exits `0` and `.import` files are created for the four runtime PNGs.

- [ ] **Step 5: Commit projectile sprites**

Run:

```powershell
git add assets/generated/stage01_fire_bolt assets/generated/stage01_fire_glob assets/generated/stage01_fire_spit assets/generated/stage01_heat_mortar_shell characters/ranged/stage_01/fire_bolt.png characters/ranged/stage_01/fire_glob.png characters/ranged/stage_01/fire_spit.png characters/ranged/stage_01/heat_mortar_shell.png characters/ranged/stage_01/fire_bolt.png.import characters/ranged/stage_01/fire_glob.png.import characters/ranged/stage_01/fire_spit.png.import characters/ranged/stage_01/heat_mortar_shell.png.import
git commit -m "feat: add stage 01 fire projectile sprites"
```

---

### Task 6: QC And Import Verification

**Files:**
- Read: `assets/generated/stage01_*/**/pipeline-meta.json`
- Read: `assets/generated/stage01_*/**/animation.gif`
- Read: `characters/enemies/stage_01/*.png`
- Read: `characters/ranged/stage_01/*.png`

- [ ] **Step 1: Check QC metadata for edge contact**

Run:

```powershell
Get-ChildItem assets/generated/stage01_* -Recurse -Filter pipeline-meta.json |
  ForEach-Object {
    $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
    [PSCustomObject]@{
      File = $_.FullName
      EdgeTouchFrames = ($json.edge_touch_frames -join ',')
      Rows = $json.rows
      Cols = $json.cols
      SharedScale = $json.shared_scale
    }
  } | Format-Table -AutoSize
```

Expected: every `EdgeTouchFrames` cell is blank, row/column counts match the plan, and `SharedScale` is `True`.

- [ ] **Step 2: Visually inspect GIF previews**

Open or view these files:

```text
assets/generated/stage01_enemy_magma_grunt/idle/animation.gif
assets/generated/stage01_enemy_molten_ram/charge/animation.gif
assets/generated/stage01_enemy_ash_hopper/hop/animation.gif
assets/generated/stage01_enemy_ember_orbiter/hover_shoot/animation.gif
assets/generated/stage01_enemy_flame_skimmer/dive/animation.gif
assets/generated/stage01_enemy_cinder_flyer/hover/animation.gif
assets/generated/stage01_enemy_heat_mortar/shoot/animation.gif
assets/generated/stage01_enemy_magma_turret/shoot/animation.gif
assets/generated/stage01_enemy_lava_serpent/emerge_spit/animation.gif
assets/generated/stage01_fire_bolt/projectile/animation.gif
assets/generated/stage01_fire_glob/projectile/animation.gif
assets/generated/stage01_fire_spit/projectile/animation.gif
assets/generated/stage01_heat_mortar_shell/projectile/animation.gif
```

Expected:
- A-family enemies read as armored reploid troops.
- B-family enemies read as robotic fire creatures.
- C-family enemies read as industrial lava machines.
- All enemies feel like they belong to the volcanic domain of a lion reploid boss without becoming smaller copies of the boss.
- `enemy_ash_hopper` reads as a robot rabbit.
- `enemy_heat_mortar` does not read as an archer.
- `enemy_ember_orbiter` reads as a shooting orbital drone.
- Projectiles remain compact and loop cleanly.

- [ ] **Step 3: Run Godot import verification**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit
```

Expected: exit code `0`, no missing texture import errors.

- [ ] **Step 4: Commit QC-only fixes if any regeneration was required**

If any sprite was regenerated or reprocessed in this task, commit only the changed generated/runtime files:

```powershell
git add assets/generated/stage01_<changed_asset> characters/enemies/stage_01 characters/ranged/stage_01
git commit -m "fix: refine stage 01 fire sprite sheets"
```

---

## Self-Review

- Spec coverage: all 9 final enemies, all 4 projectiles, A/B/C distribution, coelho robô `enemy_ash_hopper`, non-archer `enemy_heat_mortar`, shooting `enemy_ember_orbiter`, and larger-grid allowance are covered.
- Placeholder scan: no unresolved planning markers remain.
- Type consistency: all paths use `stage01_<asset>/<action>` generated folders and runtime PNGs under `characters/enemies/stage_01` or `characters/ranged/stage_01`.
