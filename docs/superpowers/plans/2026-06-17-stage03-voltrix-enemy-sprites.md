# Stage 03 Voltrix Enemy Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, process, import, QC, and commit 9 Stage 03 Voltrix enemy sprite sheets plus 4 separate projectile/FX sheets.

**Architecture:** Each enemy or projectile is generated as its own raw sheet under `assets/generated/stage03_*`, then postprocessed with `generate2dsprite.py` into transparent sheets, frames, GIFs, and metadata. Runtime-ready PNGs are copied to `characters/enemies/stage_03/`, imported by Godot, and committed in small batches.

**Tech Stack:** Godot 4.6.2, PowerShell, built-in image generation through the `imagegen` skill/CLI fallback, `generate2dsprite.py` for deterministic chroma-key processing and QC metadata, Git.

---

## Source Context

- Spec: `docs/superpowers/specs/2026-06-17-stage03-voltrix-enemies-sprite-design.md`
- Boss: Voltrix, falcao trovao, elemento raio/energia
- Stage theme: central eletrica/tempestade
- Runtime output folder: `characters/enemies/stage_03/`
- Generated output prefix: `assets/generated/stage03_`
- Required final roster:
  - Ground/melee: `enemy_volt_guard`, `enemy_rail_runner`
  - Fly: `enemy_thunder_hawklet`, `enemy_storm_kite`, `enemy_arc_orbiter`, `enemy_static_interceptor`
  - Static/ranged: `enemy_tesla_coil`, `enemy_arc_turret`, `enemy_storm_relay`
  - Projectiles/FX: `arc_bolt`, `thunder_shot`, `tesla_pulse`, `storm_spark`

## Shared Rules

- Work from `D:\SnesGame\.worktrees\other-stages-enemies`.
- Keep every raw sheet on solid `#FF00FF` background.
- Use separate raw sheets for each enemy and projectile.
- Use `--shared-scale` and `--reject-edge-touch` for every processed sheet.
- Use `--component-mode largest` for enemy body sheets.
- Use `--component-mode largest` for compact projectiles unless visual QC shows detached spark components were incorrectly removed; then reprocess that projectile with `--component-mode all`.
- If processing reports edge-touch frames, inspect `raw-sheet.png`, strengthen containment in `prompt-used.txt`, regenerate, and reprocess.
- If Godot `--headless --import` exits nonzero but creates `.import` files, validate sidecars directly with `Get-Item`.

## Common Commands

Load the API key for CLI fallback:

```powershell
$line = Get-Content .env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
```

Generate with CLI fallback when built-in image generation cannot write to the worktree path:

```powershell
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file <prompt-file> --size <size> --quality medium --out <raw-output> --force
```

Process with `generate2dsprite.py`:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input <raw-sheet> --target <target> --mode <mode> --output-dir <output-dir> --rows <rows> --cols <cols> --label-prefix <label> --align <align> --shared-scale --component-mode largest --fit-scale <scale> --reject-edge-touch
```

Import runtime PNGs:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
```

Validate runtime sidecars:

```powershell
Get-Item characters/enemies/stage_03/*.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
```

---

### Task 1: Prompt Files

**Files:**
- Create: `assets/generated/stage03_enemy_volt_guard/shock/prompt-used.txt`
- Create: `assets/generated/stage03_enemy_rail_runner/charge/prompt-used.txt`
- Create: `assets/generated/stage03_enemy_thunder_hawklet/dive/prompt-used.txt`
- Create: `assets/generated/stage03_enemy_storm_kite/shoot/prompt-used.txt`
- Create: `assets/generated/stage03_enemy_arc_orbiter/hover_shoot/prompt-used.txt`
- Create: `assets/generated/stage03_enemy_static_interceptor/shoot/prompt-used.txt`
- Create: `assets/generated/stage03_enemy_tesla_coil/pulse/prompt-used.txt`
- Create: `assets/generated/stage03_enemy_arc_turret/shoot/prompt-used.txt`
- Create: `assets/generated/stage03_enemy_storm_relay/pulse/prompt-used.txt`
- Create: `assets/generated/stage03_arc_bolt/projectile/prompt-used.txt`
- Create: `assets/generated/stage03_thunder_shot/projectile/prompt-used.txt`
- Create: `assets/generated/stage03_tesla_pulse/projectile/prompt-used.txt`
- Create: `assets/generated/stage03_storm_spark/projectile/prompt-used.txt`

- [ ] **Step 1: Create output directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  assets/generated/stage03_enemy_volt_guard/shock, `
  assets/generated/stage03_enemy_rail_runner/charge, `
  assets/generated/stage03_enemy_thunder_hawklet/dive, `
  assets/generated/stage03_enemy_storm_kite/shoot, `
  assets/generated/stage03_enemy_arc_orbiter/hover_shoot, `
  assets/generated/stage03_enemy_static_interceptor/shoot, `
  assets/generated/stage03_enemy_tesla_coil/pulse, `
  assets/generated/stage03_enemy_arc_turret/shoot, `
  assets/generated/stage03_enemy_storm_relay/pulse, `
  assets/generated/stage03_arc_bolt/projectile, `
  assets/generated/stage03_thunder_shot/projectile, `
  assets/generated/stage03_tesla_pulse/projectile, `
  assets/generated/stage03_storm_spark/projectile
```

Expected: all directories exist.

- [ ] **Step 2: Write `enemy_volt_guard` prompt**

Write this exact text to `assets/generated/stage03_enemy_volt_guard/shock/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_volt_guard, a compact electric-stage reploid security guard from the power-plant domain of Voltrix, a thunder hawk boss. It is a ground melee troop, not a bird. Visual design: gray metal armor, black-and-yellow warning plates, blue electric visor, small antenna fins on helmet, short shock baton or conductive claw held close to the body, visible electric joints, athletic but compact Mega Man X inspired silhouette with original IP identity. Motion: ready stance, weight shift, baton/claw charges, short shock lunge pose, recoil, return-ready loop pose. Keep electric sparks compact and attached to baton/claw only. Same identity, same scale, centered body, stable feet/bottom anchor in each cell. Full body inside central 65% safe area, no baton, antenna, limb, spark, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 3: Write `enemy_rail_runner` prompt**

Write this exact text to `assets/generated/stage03_enemy_rail_runner/charge/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_rail_runner, a low fast ground robot from Voltrix's electric power plant, built like a maintenance rail cart turned combat hazard. Visual design: flattened armored body, magnetic skate rails or roller treads, front wedge with abstract mechanical beak shape, exposed cables, bright yellow-blue electric core, black-and-yellow hazard stripes, gray metal casing. Motion read left-to-right: idle on rail, core warms, magnetic skates spark, body leans forward, short dash burst, full charge pose, brake sparks, recoil, return idle. Keep sparks compact and attached to wheels/skates. Same identity, same scale, centered body, stable bottom anchor in each cell. Full body inside central 65% safe area, no sparks, wheels, wedge, cable, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 4: Write `enemy_thunder_hawklet` prompt**

Write this exact text to `assets/generated/stage03_enemy_thunder_hawklet/dive/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_thunder_hawklet, a small robotic thunder hawk drone serving Voltrix, much smaller than the boss and clearly a common enemy. Visual design: compact bird-of-prey silhouette, short metallic beak, folded mechanical wings with rigid metal feather plates, small energized talons, electric yellow highlights, blue arc core, dark gray joints, black-and-yellow plating. Motion read left-to-right: hover perch pose, wings open, electric talons charge, nose dips, dive start, fast dive attack pose, pull-up pose, stabilize hover, return hover. Keep wing tips, talons, beak, and sparks inside the cell. Same identity, same scale, centered subject in each cell. Full subject inside central 65% safe area, no wing, talon, beak, spark, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 5: Write `enemy_storm_kite` prompt**

Write this exact text to `assets/generated/stage03_enemy_storm_kite/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_storm_kite, a high-flying electric glider drone from Voltrix's storm power plant. Visual design: thin kite-like wing body, abstract bird head with subtle metal beak, wide but compact folding wing panels, stabilizer fins, yellow lightning trim, blue charged emitter underneath, gray metal frame, black hazard striping. Motion: steady high hover, wing panels flex, underside emitter charges, downward/diagonal shoot pose with compact attached muzzle glow only, recoil tilt, return hover. Do not include detached projectile in the body sheet. Same identity, same scale, centered subject in every cell. Full body inside central 65% safe area, no wing panel, fin, glow, or spark crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 6: Write `enemy_arc_orbiter` prompt**

Write this exact text to `assets/generated/stage03_enemy_arc_orbiter/hover_shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_arc_orbiter, a floating high-voltage orbiter machine from Voltrix's power plant. Visual design: bright yellow-blue electric core, circular gray metal shell, segmented ring of small coil modules orbiting around it, black-and-yellow hazard marks, tiny antenna prongs, arcs between ring segments. Motion: hover idle, ring rotates, core brightens, emitter port opens, shoot pose with compact attached glow only, return hover. Do not include detached projectile in the body sheet. Same identity, same scale, centered circular silhouette in every cell. Full subject inside central 60% safe area with clear magenta margin, no ring segment, antenna, arc, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 7: Write `enemy_static_interceptor` prompt**

Write this exact text to `assets/generated/stage03_enemy_static_interceptor/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_static_interceptor, an angular military electric patrol drone from Voltrix's security force. Visual design: compact armored drone body, front blue visor/emitter, small side stabilizer wings, antenna fins, gray metal armor, black-and-yellow warning plates, yellow charged joints. It is tactical and machine-like, not an animal. Motion: hover patrol, slight tilt, emitter charges, shoot pose with compact attached muzzle glow only, recoil tilt, return hover. Do not include detached projectile in the body sheet. Same identity, same scale, centered body in each cell. Full subject inside central 65% safe area, no wing, antenna, muzzle glow, or spark crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 8: Write static enemy prompts**

Write these exact prompts:

`assets/generated/stage03_enemy_tesla_coil/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_tesla_coil, a stationary Tesla coil defense unit from Voltrix's electric power plant. Visual design: heavy industrial base, vertical coil tower, round conductor cap, yellow-blue electric core, ceramic insulators, gray metal bolts, black-and-yellow hazard stripes. Motion: idle dark coil, base lights up, coil begins to glow, top conductor charges, compact discharge pulse attached to the coil, cooldown. Do not include long beam or detached projectile in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full turret inside central 65% safe area, no electric arc, cap, base, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage03_enemy_arc_turret/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: enemy_arc_turret, a fixed electric arc cannon installed in Voltrix's power plant. Visual design: low angular turret body, gray armored shell, black-and-yellow plates, front blue emitter lens that subtly suggests a mechanical beak, small antenna prongs, yellow capacitors on the side. Motion: idle, emitter charges, shoot pose with compact attached muzzle glow only, cooldown. Do not include detached projectile in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full turret inside central 65% safe area, no muzzle glow, antenna, or side capacitor crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage03_enemy_storm_relay/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_storm_relay, a stationary storm relay hazard from Voltrix's electric power plant. Visual design: industrial relay tower, thick base with bolts, ceramic insulators, forked lightning rod, exposed cables, yellow-blue charge core, gray metal panels, black-and-yellow warning plates, small sparks orbiting close to the rod. Motion read left-to-right: idle, cable lights blink, core charges, rod vibrates, stronger charge, compact pulse discharge attached to rod, afterglow, cooldown, return idle. Do not include detached projectile or wide lightning in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full subject inside central 65% safe area, no rod, cable, spark, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 9: Write projectile prompts**

Write these exact prompts:

`assets/generated/stage03_arc_bolt/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: arc_bolt, a compact horizontal electric bolt projectile fired by Voltrix stage enemies, travel direction left-to-right. Visual design: bright yellow lightning body with small blue-white core, jagged but contained shape, tiny sparks close to the bolt. Motion: stable bolt, brighter pulse, slightly stretched travel pulse, loop return. Same projectile identity and size in every frame, centered, compact glow. Projectile and glow stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage03_thunder_shot/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: thunder_shot, a concentrated military electric shot fired by enemy_static_interceptor, travel direction left-to-right. Visual design: compact blue-yellow plasma pellet with tiny metal-hot core, short contained electric tail, more precise and machine-like than a natural lightning bolt. Motion: stable shot, charge brightens, short tail stretch, loop return. Same projectile identity and size in every frame, centered, compact glow. Projectile and tail stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage03_tesla_pulse/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: tesla_pulse, a compact Tesla coil discharge pulse for enemy_tesla_coil. Visual design: short vertical/circular yellow-blue electric burst, bright blue-white center, small contained radial sparks, no long beam. Motion: small pulse, bright expansion, peak discharge, loop fade. Same effect identity and size in every frame, centered, compact glow. Pulse and sparks stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage03_storm_spark/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile/FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: storm_spark, an irregular compact storm spark emitted by enemy_storm_relay and enemy_storm_kite. Visual design: jagged yellow electric spark with blue-white center, uneven storm shape, tiny close sparks, chaotic but contained. Motion: spark flicker, brighter fork, compact burst, loop return. Same effect identity and size in every frame, centered, compact glow. Spark and glow stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 10: Commit prompt files**

Run:

```powershell
git add assets/generated/stage03_enemy_volt_guard assets/generated/stage03_enemy_rail_runner assets/generated/stage03_enemy_thunder_hawklet assets/generated/stage03_enemy_storm_kite assets/generated/stage03_enemy_arc_orbiter assets/generated/stage03_enemy_static_interceptor assets/generated/stage03_enemy_tesla_coil assets/generated/stage03_enemy_arc_turret assets/generated/stage03_enemy_storm_relay assets/generated/stage03_arc_bolt assets/generated/stage03_thunder_shot assets/generated/stage03_tesla_pulse assets/generated/stage03_storm_spark
git commit -m "docs: add stage 03 voltrix sprite prompts"
```

Expected: commit includes only prompt files and empty directories are not tracked.

---

### Task 2: Ground Enemy Sprites

**Files:**
- Create generated assets under `assets/generated/stage03_enemy_volt_guard/shock/`
- Create generated assets under `assets/generated/stage03_enemy_rail_runner/charge/`
- Create: `characters/enemies/stage_03/enemy_volt_guard.png`
- Create: `characters/enemies/stage_03/enemy_rail_runner.png`
- Create: `characters/enemies/stage_03/enemy_volt_guard.png.import`
- Create: `characters/enemies/stage_03/enemy_rail_runner.png.import`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content .env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_enemy_volt_guard\shock\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage03_enemy_volt_guard\shock\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_enemy_rail_runner\charge\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage03_enemy_rail_runner\charge\raw-sheet.png --force
```

Expected: both `raw-sheet.png` files exist.

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_enemy_volt_guard/shock/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage03_enemy_volt_guard/shock --rows 2 --cols 3 --label-prefix shock --align feet --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_enemy_rail_runner/charge/raw-sheet.png --target creature --mode charge --output-dir assets/generated/stage03_enemy_rail_runner/charge --rows 3 --cols 3 --label-prefix charge --align bottom --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
```

Expected: both commands exit 0 and create `sheet-transparent.png`, frame PNGs, `animation.gif`, and `pipeline-meta.json`.

- [ ] **Step 3: Visual QC**

Open:

```powershell
assets/generated/stage03_enemy_volt_guard/shock/sheet-transparent.png
assets/generated/stage03_enemy_rail_runner/charge/sheet-transparent.png
```

Pass criteria:
- `enemy_volt_guard` reads as compact electric ground guard, not bird, not turret.
- `enemy_rail_runner` reads as low rail/magnetic dash hazard.
- No frame visibly touches cell edges.
- Body scale stays stable.

- [ ] **Step 4: Copy runtime PNGs**

Run:

```powershell
New-Item -ItemType Directory -Force characters/enemies/stage_03
Copy-Item assets/generated/stage03_enemy_volt_guard/shock/sheet-transparent.png characters/enemies/stage_03/enemy_volt_guard.png -Force
Copy-Item assets/generated/stage03_enemy_rail_runner/charge/sheet-transparent.png characters/enemies/stage_03/enemy_rail_runner.png -Force
```

Expected: runtime PNGs exist.

- [ ] **Step 5: Import with Godot**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_03/enemy_volt_guard.png.import, characters/enemies/stage_03/enemy_rail_runner.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
```

Expected: both `.png.import` sidecars exist.

- [ ] **Step 6: Commit ground sprites**

Run:

```powershell
git add assets/generated/stage03_enemy_volt_guard assets/generated/stage03_enemy_rail_runner characters/enemies/stage_03/enemy_volt_guard.png characters/enemies/stage_03/enemy_rail_runner.png characters/enemies/stage_03/enemy_volt_guard.png.import characters/enemies/stage_03/enemy_rail_runner.png.import
git commit -m "feat: add stage 03 ground enemy sprites"
```

---

### Task 3: Flying Enemy Sprites

**Files:**
- Create generated assets for `enemy_thunder_hawklet`, `enemy_storm_kite`, `enemy_arc_orbiter`, `enemy_static_interceptor`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_03/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content .env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_enemy_thunder_hawklet\dive\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage03_enemy_thunder_hawklet\dive\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_enemy_storm_kite\shoot\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage03_enemy_storm_kite\shoot\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_enemy_arc_orbiter\hover_shoot\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage03_enemy_arc_orbiter\hover_shoot\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_enemy_static_interceptor\shoot\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage03_enemy_static_interceptor\shoot\raw-sheet.png --force
```

Expected: four `raw-sheet.png` files exist.

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_enemy_thunder_hawklet/dive/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage03_enemy_thunder_hawklet/dive --rows 3 --cols 3 --label-prefix dive --align center --shared-scale --component-mode largest --fit-scale 0.86 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_enemy_storm_kite/shoot/raw-sheet.png --target creature --mode shoot --output-dir assets/generated/stage03_enemy_storm_kite/shoot --rows 2 --cols 3 --label-prefix shoot --align center --shared-scale --component-mode largest --fit-scale 0.86 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_enemy_arc_orbiter/hover_shoot/raw-sheet.png --target creature --mode shoot --output-dir assets/generated/stage03_enemy_arc_orbiter/hover_shoot --rows 2 --cols 3 --label-prefix hover-shoot --align center --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_enemy_static_interceptor/shoot/raw-sheet.png --target creature --mode shoot --output-dir assets/generated/stage03_enemy_static_interceptor/shoot --rows 2 --cols 3 --label-prefix shoot --align center --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
```

Expected: all commands exit 0, `edge_touch_frames` is empty for each `pipeline-meta.json`.

- [ ] **Step 3: Visual QC**

Open:

```powershell
assets/generated/stage03_enemy_thunder_hawklet/dive/sheet-transparent.png
assets/generated/stage03_enemy_storm_kite/shoot/sheet-transparent.png
assets/generated/stage03_enemy_arc_orbiter/hover_shoot/sheet-transparent.png
assets/generated/stage03_enemy_static_interceptor/shoot/sheet-transparent.png
```

Pass criteria:
- `thunder_hawklet` reads as small robotic hawk, not boss-scale Voltrix.
- `storm_kite` reads as high glider with subtle bird language.
- `arc_orbiter` reads as circular high-voltage machine.
- `static_interceptor` reads as tactical patrol drone, not animal.

- [ ] **Step 4: Copy runtime PNGs**

Run:

```powershell
Copy-Item assets/generated/stage03_enemy_thunder_hawklet/dive/sheet-transparent.png characters/enemies/stage_03/enemy_thunder_hawklet.png -Force
Copy-Item assets/generated/stage03_enemy_storm_kite/shoot/sheet-transparent.png characters/enemies/stage_03/enemy_storm_kite.png -Force
Copy-Item assets/generated/stage03_enemy_arc_orbiter/hover_shoot/sheet-transparent.png characters/enemies/stage_03/enemy_arc_orbiter.png -Force
Copy-Item assets/generated/stage03_enemy_static_interceptor/shoot/sheet-transparent.png characters/enemies/stage_03/enemy_static_interceptor.png -Force
```

- [ ] **Step 5: Import with Godot**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_03/enemy_thunder_hawklet.png.import, characters/enemies/stage_03/enemy_storm_kite.png.import, characters/enemies/stage_03/enemy_arc_orbiter.png.import, characters/enemies/stage_03/enemy_static_interceptor.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
```

Expected: four `.png.import` sidecars exist.

- [ ] **Step 6: Commit flying sprites**

Run:

```powershell
git add assets/generated/stage03_enemy_thunder_hawklet assets/generated/stage03_enemy_storm_kite assets/generated/stage03_enemy_arc_orbiter assets/generated/stage03_enemy_static_interceptor characters/enemies/stage_03/enemy_thunder_hawklet.png characters/enemies/stage_03/enemy_storm_kite.png characters/enemies/stage_03/enemy_arc_orbiter.png characters/enemies/stage_03/enemy_static_interceptor.png characters/enemies/stage_03/enemy_thunder_hawklet.png.import characters/enemies/stage_03/enemy_storm_kite.png.import characters/enemies/stage_03/enemy_arc_orbiter.png.import characters/enemies/stage_03/enemy_static_interceptor.png.import
git commit -m "feat: add stage 03 flying enemy sprites"
```

---

### Task 4: Static Enemy Sprites

**Files:**
- Create generated assets for `enemy_tesla_coil`, `enemy_arc_turret`, `enemy_storm_relay`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_03/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content .env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_enemy_tesla_coil\pulse\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage03_enemy_tesla_coil\pulse\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_enemy_arc_turret\shoot\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage03_enemy_arc_turret\shoot\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_enemy_storm_relay\pulse\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage03_enemy_storm_relay\pulse\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_enemy_tesla_coil/pulse/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage03_enemy_tesla_coil/pulse --rows 2 --cols 3 --label-prefix pulse --align bottom --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_enemy_arc_turret/shoot/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage03_enemy_arc_turret/shoot --rows 2 --cols 2 --label-prefix shoot --align bottom --shared-scale --component-mode largest --fit-scale 0.90 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_enemy_storm_relay/pulse/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage03_enemy_storm_relay/pulse --rows 3 --cols 3 --label-prefix pulse --align bottom --shared-scale --component-mode largest --fit-scale 0.86 --reject-edge-touch
```

Expected: all processed sheets pass edge-touch QC.

- [ ] **Step 3: Visual QC**

Open:

```powershell
assets/generated/stage03_enemy_tesla_coil/pulse/sheet-transparent.png
assets/generated/stage03_enemy_arc_turret/shoot/sheet-transparent.png
assets/generated/stage03_enemy_storm_relay/pulse/sheet-transparent.png
```

Pass criteria:
- `tesla_coil` reads as vertical fixed Tesla tower.
- `arc_turret` reads as low directional electric cannon.
- `storm_relay` reads as relay/hazard infrastructure, not another turret.

- [ ] **Step 4: Copy runtime PNGs**

Run:

```powershell
Copy-Item assets/generated/stage03_enemy_tesla_coil/pulse/sheet-transparent.png characters/enemies/stage_03/enemy_tesla_coil.png -Force
Copy-Item assets/generated/stage03_enemy_arc_turret/shoot/sheet-transparent.png characters/enemies/stage_03/enemy_arc_turret.png -Force
Copy-Item assets/generated/stage03_enemy_storm_relay/pulse/sheet-transparent.png characters/enemies/stage_03/enemy_storm_relay.png -Force
```

- [ ] **Step 5: Import with Godot**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_03/enemy_tesla_coil.png.import, characters/enemies/stage_03/enemy_arc_turret.png.import, characters/enemies/stage_03/enemy_storm_relay.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
```

Expected: three `.png.import` sidecars exist.

- [ ] **Step 6: Commit static sprites**

Run:

```powershell
git add assets/generated/stage03_enemy_tesla_coil assets/generated/stage03_enemy_arc_turret assets/generated/stage03_enemy_storm_relay characters/enemies/stage_03/enemy_tesla_coil.png characters/enemies/stage_03/enemy_arc_turret.png characters/enemies/stage_03/enemy_storm_relay.png characters/enemies/stage_03/enemy_tesla_coil.png.import characters/enemies/stage_03/enemy_arc_turret.png.import characters/enemies/stage_03/enemy_storm_relay.png.import
git commit -m "feat: add stage 03 static enemy sprites"
```

---

### Task 5: Projectile And FX Sprites

**Files:**
- Create generated assets for `arc_bolt`, `thunder_shot`, `tesla_pulse`, `storm_spark`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_03/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content .env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_arc_bolt\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage03_arc_bolt\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_thunder_shot\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage03_thunder_shot\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_tesla_pulse\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage03_tesla_pulse\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage03_storm_spark\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage03_storm_spark\projectile\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_arc_bolt/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage03_arc_bolt/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.80 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_thunder_shot/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage03_thunder_shot/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.80 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_tesla_pulse/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage03_tesla_pulse/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.80 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage03_storm_spark/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage03_storm_spark/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.80 --reject-edge-touch
```

Expected: all processed sheets pass edge-touch QC.

- [ ] **Step 3: Visual QC**

Open:

```powershell
assets/generated/stage03_arc_bolt/projectile/sheet-transparent.png
assets/generated/stage03_thunder_shot/projectile/sheet-transparent.png
assets/generated/stage03_tesla_pulse/projectile/sheet-transparent.png
assets/generated/stage03_storm_spark/projectile/sheet-transparent.png
```

Pass criteria:
- `arc_bolt` reads as jagged horizontal bolt.
- `thunder_shot` reads as concentrated machine projectile.
- `tesla_pulse` reads as compact discharge pulse, not long beam.
- `storm_spark` reads as irregular storm spark and differs from `arc_bolt`.

- [ ] **Step 4: Copy runtime PNGs**

Run:

```powershell
Copy-Item assets/generated/stage03_arc_bolt/projectile/sheet-transparent.png characters/enemies/stage_03/arc_bolt.png -Force
Copy-Item assets/generated/stage03_thunder_shot/projectile/sheet-transparent.png characters/enemies/stage_03/thunder_shot.png -Force
Copy-Item assets/generated/stage03_tesla_pulse/projectile/sheet-transparent.png characters/enemies/stage_03/tesla_pulse.png -Force
Copy-Item assets/generated/stage03_storm_spark/projectile/sheet-transparent.png characters/enemies/stage_03/storm_spark.png -Force
```

- [ ] **Step 5: Import with Godot**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_03/arc_bolt.png.import, characters/enemies/stage_03/thunder_shot.png.import, characters/enemies/stage_03/tesla_pulse.png.import, characters/enemies/stage_03/storm_spark.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
```

Expected: four `.png.import` sidecars exist.

- [ ] **Step 6: Commit projectile sprites**

Run:

```powershell
git add assets/generated/stage03_arc_bolt assets/generated/stage03_thunder_shot assets/generated/stage03_tesla_pulse assets/generated/stage03_storm_spark characters/enemies/stage_03/arc_bolt.png characters/enemies/stage_03/thunder_shot.png characters/enemies/stage_03/tesla_pulse.png characters/enemies/stage_03/storm_spark.png characters/enemies/stage_03/arc_bolt.png.import characters/enemies/stage_03/thunder_shot.png.import characters/enemies/stage_03/tesla_pulse.png.import characters/enemies/stage_03/storm_spark.png.import
git commit -m "feat: add stage 03 enemy projectile sprites"
```

---

### Task 6: Final QC

**Files:**
- Verify all files created by Tasks 1-5

- [ ] **Step 1: Validate runtime outputs**

Run:

```powershell
$files = @(
  'enemy_volt_guard',
  'enemy_rail_runner',
  'enemy_thunder_hawklet',
  'enemy_storm_kite',
  'enemy_arc_orbiter',
  'enemy_static_interceptor',
  'enemy_tesla_coil',
  'enemy_arc_turret',
  'enemy_storm_relay',
  'arc_bolt',
  'thunder_shot',
  'tesla_pulse',
  'storm_spark'
)
foreach ($name in $files) {
  $png = "characters/enemies/stage_03/$name.png"
  $imp = "$png.import"
  [pscustomobject]@{Name=$name; Png=(Test-Path $png); Import=(Test-Path $imp)}
}
```

Expected: all rows show `Png=True` and `Import=True`.

- [ ] **Step 2: Validate metadata edge-touch**

Run:

```powershell
$metas = Get-ChildItem assets/generated -Recurse -Filter pipeline-meta.json | Where-Object { $_.FullName -match 'stage03_' }
foreach ($m in $metas) {
  $json = Get-Content $m.FullName -Raw | ConvertFrom-Json
  [pscustomobject]@{
    Path=$m.FullName.Replace((Resolve-Path .).Path + '\','')
    Rows=$json.rows
    Cols=$json.cols
    Frames=$json.frames.Count
    EdgeTouch=$json.edge_touch_frames.Count
    SharedScale=$json.shared_scale
  }
}
```

Expected: every row has `EdgeTouch=0` and `SharedScale=True`.

- [ ] **Step 3: Review git status**

Run:

```powershell
git status --short assets/generated characters/enemies/stage_03 docs/superpowers
git log --oneline -8
```

Expected: no uncommitted Stage 03 sprite files remain. Recent commits include prompt/spec and sprite batches.

- [ ] **Step 4: Final visual checklist**

Inspect final runtime sheets:

```powershell
characters/enemies/stage_03/enemy_volt_guard.png
characters/enemies/stage_03/enemy_rail_runner.png
characters/enemies/stage_03/enemy_thunder_hawklet.png
characters/enemies/stage_03/enemy_storm_kite.png
characters/enemies/stage_03/enemy_arc_orbiter.png
characters/enemies/stage_03/enemy_static_interceptor.png
characters/enemies/stage_03/enemy_tesla_coil.png
characters/enemies/stage_03/enemy_arc_turret.png
characters/enemies/stage_03/enemy_storm_relay.png
characters/enemies/stage_03/arc_bolt.png
characters/enemies/stage_03/thunder_shot.png
characters/enemies/stage_03/tesla_pulse.png
characters/enemies/stage_03/storm_spark.png
```

Pass criteria:
- Voltrix/falcao trovao theme is visible across the set.
- Flying/static presence is stronger than ground presence.
- The four projectiles are distinct.
- No output reads as fire/ice/shadow/light stage.
- No body sheet relies on wide detached FX.
