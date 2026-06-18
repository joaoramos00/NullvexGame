# Stage 05 Galerix Enemy Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, process, import, QC, and commit 9 Stage 05 Galerix enemy sprite sheets plus 4 separate projectile/FX sheets.

**Architecture:** Each enemy or projectile is generated as its own raw sheet under `assets/generated/stage05_*`, then postprocessed with `generate2dsprite.py` into transparent sheets, frames, GIFs, and metadata. Runtime-ready PNGs are copied to `characters/enemies/stage_05/`, imported by Godot, and committed in small batches.

**Tech Stack:** Godot 4.6.2, PowerShell, built-in image generation or CLI fallback through the `imagegen` skill, `generate2dsprite.py` for deterministic chroma-key processing and QC metadata, Git.

---

## Source Context

- Spec: `docs/superpowers/specs/2026-06-18-stage05-galerix-enemies-sprite-design.md`
- Boss: Galerix, reploid aviario/raptor de vento
- Stage theme: plataformas aereas, vento, turbinas e correntes de ar
- Runtime output folder: `characters/enemies/stage_05/`
- Generated output prefix: `assets/generated/stage05_`
- Required final roster:
  - Ground/melee: `enemy_gale_runner`, `enemy_claw_glider`, `enemy_airfoil_lancer`
  - Suspended/fly/hazard: `enemy_sky_harrier`, `enemy_turbine_wisp`, `enemy_feather_swarm`, `enemy_gale_grappler`
  - Static/ranged: `enemy_gale_turret`, `enemy_updraft_fan`
  - Projectiles/FX: `gale_bolt`, `wind_slash`, `feather_dart`, `updraft_pulse`

## Shared Rules

- Work from `D:\SnesGame\.worktrees\stage05-enemies`.
- Keep every raw sheet on solid `#FF00FF` background.
- Use separate raw sheets for each enemy and projectile.
- Use `--shared-scale` and `--reject-edge-touch` for every processed sheet.
- Use `--component-mode largest` for enemy body sheets.
- Use `--component-mode largest` for compact projectiles unless visual QC shows detached feather/trail/pulse components were incorrectly removed; then reprocess that projectile with `--component-mode all`.
- If processing reports edge-touch frames, inspect `raw-sheet.png`, strengthen containment in `prompt-used.txt`, regenerate, and reprocess.
- If Godot `--headless --import` exits nonzero but creates `.import` files, validate sidecars directly with `Get-Item`.
- Do not commit `.png.import` files created inside `assets/generated`; only commit generated source PNG/GIF/metadata plus runtime `.png.import` files under `characters/enemies/stage_05/`.

## Common Commands

Load the API key for CLI fallback:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
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
Get-Item characters/enemies/stage_05/*.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
```

---

### Task 1: Prompt Files

**Files:**
- Create: `characters/enemies/stage_05/.gitkeep`
- Create one `prompt-used.txt` under each generated output directory listed below.

- [ ] **Step 1: Create output directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  characters/enemies/stage_05, `
  assets/generated/stage05_enemy_gale_runner/dash, `
  assets/generated/stage05_enemy_claw_glider/slash, `
  assets/generated/stage05_enemy_airfoil_lancer/lunge, `
  assets/generated/stage05_enemy_sky_harrier/dive, `
  assets/generated/stage05_enemy_turbine_wisp/shoot, `
  assets/generated/stage05_enemy_feather_swarm/orbit, `
  assets/generated/stage05_enemy_gale_grappler/grab, `
  assets/generated/stage05_enemy_gale_turret/shoot, `
  assets/generated/stage05_enemy_updraft_fan/pulse, `
  assets/generated/stage05_gale_bolt/projectile, `
  assets/generated/stage05_wind_slash/projectile, `
  assets/generated/stage05_feather_dart/projectile, `
  assets/generated/stage05_updraft_pulse/projectile
New-Item -ItemType File -Force characters/enemies/stage_05/.gitkeep
```

- [ ] **Step 2: Write ground enemy prompts**

`assets/generated/stage05_enemy_gale_runner/dash/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_gale_runner, a light aerodynamic reploid ground runner from Galerix's wind platform stage. Visual design: slim armored guard, green and teal plates, white-cyan wind core, dark mechanical joints, small ankle turbines, swept helmet crest like a metallic feather, Mega Man X inspired silhouette with original IP identity. Motion: ready stance, lean forward, ankle turbines spin, short dash pose with compact attached wind streak only, brake recoil, return-ready loop pose. It must be a light ground troop, not a bird and not a heavy unit. Same identity, same scale, centered body, stable feet/bottom anchor in every cell. Full body inside central 60% safe area with clear magenta margin around feet and turbines, no limb, turbine, glow, wind streak, or armor crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage05_enemy_claw_glider/slash/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_claw_glider, a low agile wind-stage robot with short folding winglets and metal claws, built for close-range slashes on Galerix's aerial platforms. Visual design: compact crouched body, green teal armor, white-cyan core, black joints, two short wing panels folded close to the back, sharp but small claw gauntlets, subtle raptor/feather language without copying Galerix. Motion: crouch, winglets open slightly, claws charge, short close slash pose with no detached slash arc, recoil, return crouch. Same identity, same scale, centered body, stable bottom anchor in grounded frames. Full subject inside central 60% safe area, no winglet, claw, glow, or wind streak crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage05_enemy_airfoil_lancer/lunge/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_airfoil_lancer, a light wind-stage lancer guard with an aerodynamic short lance and airfoil armor, from Galerix's platform domain. Visual design: narrow reploid soldier, green and teal wing-shaped shoulder plates, white-cyan visor and chest core, compact lance shaped like an aircraft fin, small back stabilizer fins, dark mechanical legs. Motion read left-to-right: idle, brace, lance lowers, wind core brightens, short lunge, compact impact pose, recoil, reset stance, return idle. Keep lance close enough that the body remains large and readable. Same identity, same scale, centered body, stable feet/bottom anchor in every grounded cell. Full body and lance inside central 60% safe area, no lance tip, fin, glow, or wind crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 3: Write suspended/flying enemy prompts**

`assets/generated/stage05_enemy_sky_harrier/dive/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_sky_harrier, a compact mechanical raptor patrol drone from Galerix's wind stage. Visual design: birdlike but robotic silhouette, swept metal wings, pointed visor or beak-like nose, green teal armor, white-cyan turbine core, dark joints, feather-like wing panels. Motion read left-to-right: hover patrol, wings tilt, core spins, dive windup, short dive pose, attack pass, pull up, stabilize hover, return patrol. Keep dive motion compact inside each cell and do not include detached projectile. Same identity, same scale, centered body. Full subject inside central 60% safe area, no wing tip, beak, tail fin, wind streak, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage05_enemy_turbine_wisp/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_turbine_wisp, a small floating wind core machine with orbiting turbine blades from Galerix's aerial platform stage. Visual design: white-cyan glowing core, green teal rotor shell, black mechanical clamps, three compact orbiting fan blades close to the body, no lightning and no bird body. Motion: hover idle, rotor turns, core brightens, shoot pose with compact attached muzzle swirl only, recoil tilt, return hover. Do not include detached projectile in the body sheet. Same identity, same scale, centered body in every cell. Full subject inside central 60% safe area, no rotor blade, muzzle swirl, glow, or distortion crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage05_enemy_feather_swarm/orbit/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_feather_swarm, a compact hazard made of metallic feather darts orbiting a small wind core in Galerix's stage. Visual design: central white-cyan core, green teal metal feathers, dark tiny hinges, circular feather orbit, raptor-tech language, not a natural bird flock. Motion read left-to-right: slow orbit, feathers rotate, core pulses, orbit widens slightly but stays compact, charge peak, release pose with attached glow only, recoil, orbit stabilizes, return idle. Same identity, same scale, centered circular silhouette. Full subject inside central 60% safe area, no feather, arc, glow, or wind distortion crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage05_enemy_gale_grappler/grab/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_gale_grappler, a suspended wind capture drone that grabs players and throws them toward pits in Galerix's aerial platform stage. Visual design: compact hovering core shaped like a small vertical tornado engine, green teal armor shell, white-cyan suction core, two short claw anchors or hook arms kept close to the body, small rotor fins, dark mechanical joints. Motion read left-to-right: idle hover, claws open, suction core charges, rotor pulls inward, grab-ready pose, compact capture pose with attached wind spiral only, recoil, claws close, return hover. Do not show the player, do not include a long tether, and do not include a wide throw effect in the body sheet. Same identity, same scale, centered body in every cell. Full subject inside central 60% safe area, no claw, rotor, spiral, glow, or wind trail crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 4: Write static enemy prompts**

`assets/generated/stage05_enemy_gale_turret/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: enemy_gale_turret, a fixed wind cannon installed on Galerix's aerial platforms. Visual design: low angular turret body, green teal armor panels, white-cyan circular wind emitter, dark base clamps, small internal fan visible in the barrel, subtle feather-shaped side plates. Motion: idle, internal fan spins, shoot pose with compact attached muzzle swirl only, cooldown. Do not include detached projectile or wide gust in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full turret inside central 60% safe area, no muzzle swirl, barrel, antenna, or base clamp crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage05_enemy_updraft_fan/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_updraft_fan, a fixed vertical updraft fan hazard from Galerix's wind platform stage. Visual design: compact industrial fan tower, green teal casing, white-cyan turbine core, visible vertical fan blades behind a grille, dark base, small arrow-like air vents pointing upward. Motion: idle, fan starts, blades accelerate, core brightens, compact vertical air pulse attached to the fan, cooldown. Do not include a wide lift column or detached projectile in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full fan inside central 60% safe area, no blade, vent, glow, pulse, or casing crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 5: Write projectile prompts**

`assets/generated/stage05_gale_bolt/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: gale_bolt, a compact horizontal wind projectile fired by Stage 05 Galerix enemies, travel direction left-to-right. Visual design: bright white-cyan core, teal green compressed edge, tiny wind spiral lines close to the bolt, dense and compact, no lightning. Motion: stable bolt, brighter pulse, slightly stretched travel pulse, loop return. Same projectile identity and size in every frame, centered, compact glow. Projectile and glow stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage05_wind_slash/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: wind_slash, a short curved cutting arc of compressed air from Galerix stage melee enemies. Visual design: crescent white-cyan blade, teal green trailing edge, thin air streaks, sharp and compact, no electric sparks. Motion: small slash arc, brighter sweep, peak compact crescent, loop fade. Same effect identity and size in every frame, centered, compact glow. Slash and trail stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage05_feather_dart/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: feather_dart, a compact physical metallic feather dart hurled by wind, travel direction left-to-right. Visual design: green teal metal feather blade, white-cyan glint, dark hinge detail, tiny close wind trail, physical object not energy bolt. Motion: feather angle one, spinning glint, slight travel stretch, loop return. Same projectile identity and size in every frame, centered, compact trail. Feather and trail stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage05_updraft_pulse/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: updraft_pulse, a compact vertical wind lift pulse from enemy_updraft_fan or enemy_gale_grappler. Visual design: vertical white-cyan swirl core, teal green curved air bands, subtle upward arrow-like flow, no explosion fire and no lightning. Motion: small swirl, ring lifts upward, peak compact updraft, loop fade. Same effect identity and size in every frame, centered, compact glow. Pulse and bands stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 6: Commit prompt files**

Run:

```powershell
git add characters/enemies/stage_05/.gitkeep assets/generated/stage05_enemy_gale_runner assets/generated/stage05_enemy_claw_glider assets/generated/stage05_enemy_airfoil_lancer assets/generated/stage05_enemy_sky_harrier assets/generated/stage05_enemy_turbine_wisp assets/generated/stage05_enemy_feather_swarm assets/generated/stage05_enemy_gale_grappler assets/generated/stage05_enemy_gale_turret assets/generated/stage05_enemy_updraft_fan assets/generated/stage05_gale_bolt assets/generated/stage05_wind_slash assets/generated/stage05_feather_dart assets/generated/stage05_updraft_pulse
git commit -m "docs: add stage 05 galerix sprite prompts"
```

---

### Task 2: Ground Enemy Sprites

**Files:**
- Create generated assets for `enemy_gale_runner`, `enemy_claw_glider`, `enemy_airfoil_lancer`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_05/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_enemy_gale_runner\dash\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage05_enemy_gale_runner\dash\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_enemy_claw_glider\slash\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage05_enemy_claw_glider\slash\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_enemy_airfoil_lancer\lunge\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage05_enemy_airfoil_lancer\lunge\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_enemy_gale_runner/dash/raw-sheet.png --target creature --mode run --output-dir assets/generated/stage05_enemy_gale_runner/dash --rows 2 --cols 3 --label-prefix dash --align bottom --shared-scale --component-mode largest --fit-scale 0.82 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_enemy_claw_glider/slash/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage05_enemy_claw_glider/slash --rows 2 --cols 3 --label-prefix slash --align bottom --shared-scale --component-mode largest --fit-scale 0.82 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_enemy_airfoil_lancer/lunge/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage05_enemy_airfoil_lancer/lunge --rows 3 --cols 3 --label-prefix lunge --align bottom --shared-scale --component-mode largest --fit-scale 0.80 --reject-edge-touch
```

Expected: all `pipeline-meta.json` files have `edge_touch_frames=[]` and `shared_scale=true`.

- [ ] **Step 3: Visual QC**

Open:

```powershell
assets/generated/stage05_enemy_gale_runner/dash/sheet-transparent.png
assets/generated/stage05_enemy_claw_glider/slash/sheet-transparent.png
assets/generated/stage05_enemy_airfoil_lancer/lunge/sheet-transparent.png
```

Pass criteria:
- `gale_runner` reads as a light ground dash troop, not a bird and not heavy.
- `claw_glider` reads as low claw/winglet melee unit.
- `airfoil_lancer` reads as light lancer with compact lance, not oversized or cropped.

- [ ] **Step 4: Copy runtime PNGs, import, and commit**

Run:

```powershell
Copy-Item assets/generated/stage05_enemy_gale_runner/dash/sheet-transparent.png characters/enemies/stage_05/enemy_gale_runner.png -Force
Copy-Item assets/generated/stage05_enemy_claw_glider/slash/sheet-transparent.png characters/enemies/stage_05/enemy_claw_glider.png -Force
Copy-Item assets/generated/stage05_enemy_airfoil_lancer/lunge/sheet-transparent.png characters/enemies/stage_05/enemy_airfoil_lancer.png -Force
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_05/enemy_gale_runner.png.import, characters/enemies/stage_05/enemy_claw_glider.png.import, characters/enemies/stage_05/enemy_airfoil_lancer.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
$generated = Get-ChildItem assets/generated/stage05_enemy_gale_runner, assets/generated/stage05_enemy_claw_glider, assets/generated/stage05_enemy_airfoil_lancer -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_05/enemy_gale_runner.png characters/enemies/stage_05/enemy_gale_runner.png.import characters/enemies/stage_05/enemy_claw_glider.png characters/enemies/stage_05/enemy_claw_glider.png.import characters/enemies/stage_05/enemy_airfoil_lancer.png characters/enemies/stage_05/enemy_airfoil_lancer.png.import
git commit -m "feat: add stage 05 ground enemy sprites"
```

---

### Task 3: Suspended Enemy Sprites

**Files:**
- Create generated assets for `enemy_sky_harrier`, `enemy_turbine_wisp`, `enemy_feather_swarm`, `enemy_gale_grappler`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_05/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_enemy_sky_harrier\dive\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage05_enemy_sky_harrier\dive\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_enemy_turbine_wisp\shoot\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage05_enemy_turbine_wisp\shoot\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_enemy_feather_swarm\orbit\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage05_enemy_feather_swarm\orbit\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_enemy_gale_grappler\grab\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage05_enemy_gale_grappler\grab\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_enemy_sky_harrier/dive/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage05_enemy_sky_harrier/dive --rows 3 --cols 3 --label-prefix dive --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_enemy_turbine_wisp/shoot/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage05_enemy_turbine_wisp/shoot --rows 2 --cols 3 --label-prefix shoot --align center --shared-scale --component-mode largest --fit-scale 0.82 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_enemy_feather_swarm/orbit/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage05_enemy_feather_swarm/orbit --rows 3 --cols 3 --label-prefix orbit --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_enemy_gale_grappler/grab/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage05_enemy_gale_grappler/grab --rows 3 --cols 3 --label-prefix grab --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
```

- [ ] **Step 3: Visual QC**

Pass criteria:
- `sky_harrier` reads as mechanical raptor patrol/dive enemy.
- `turbine_wisp` reads as small wind-core shooter, not electric.
- `feather_swarm` reads as compact metallic feather hazard.
- `gale_grappler` reads as capture drone with close claws/core, not a generic shooter.

- [ ] **Step 4: Copy runtime PNGs, import, and commit**

Run:

```powershell
Copy-Item assets/generated/stage05_enemy_sky_harrier/dive/sheet-transparent.png characters/enemies/stage_05/enemy_sky_harrier.png -Force
Copy-Item assets/generated/stage05_enemy_turbine_wisp/shoot/sheet-transparent.png characters/enemies/stage_05/enemy_turbine_wisp.png -Force
Copy-Item assets/generated/stage05_enemy_feather_swarm/orbit/sheet-transparent.png characters/enemies/stage_05/enemy_feather_swarm.png -Force
Copy-Item assets/generated/stage05_enemy_gale_grappler/grab/sheet-transparent.png characters/enemies/stage_05/enemy_gale_grappler.png -Force
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_05/enemy_sky_harrier.png.import, characters/enemies/stage_05/enemy_turbine_wisp.png.import, characters/enemies/stage_05/enemy_feather_swarm.png.import, characters/enemies/stage_05/enemy_gale_grappler.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
$generated = Get-ChildItem assets/generated/stage05_enemy_sky_harrier, assets/generated/stage05_enemy_turbine_wisp, assets/generated/stage05_enemy_feather_swarm, assets/generated/stage05_enemy_gale_grappler -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_05/enemy_sky_harrier.png characters/enemies/stage_05/enemy_sky_harrier.png.import characters/enemies/stage_05/enemy_turbine_wisp.png characters/enemies/stage_05/enemy_turbine_wisp.png.import characters/enemies/stage_05/enemy_feather_swarm.png characters/enemies/stage_05/enemy_feather_swarm.png.import characters/enemies/stage_05/enemy_gale_grappler.png characters/enemies/stage_05/enemy_gale_grappler.png.import
git commit -m "feat: add stage 05 suspended enemy sprites"
```

---

### Task 4: Static Enemy Sprites

**Files:**
- Create generated assets for `enemy_gale_turret`, `enemy_updraft_fan`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_05/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_enemy_gale_turret\shoot\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage05_enemy_gale_turret\shoot\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_enemy_updraft_fan\pulse\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage05_enemy_updraft_fan\pulse\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_enemy_gale_turret/shoot/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage05_enemy_gale_turret/shoot --rows 2 --cols 2 --label-prefix shoot --align bottom --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_enemy_updraft_fan/pulse/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage05_enemy_updraft_fan/pulse --rows 2 --cols 3 --label-prefix pulse --align bottom --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
```

- [ ] **Step 3: Visual QC**

Pass criteria:
- `gale_turret` reads as low directional wind cannon.
- `updraft_fan` reads as vertical fan/lift hazard, not a turret.

- [ ] **Step 4: Copy runtime PNGs, import, and commit**

Run:

```powershell
Copy-Item assets/generated/stage05_enemy_gale_turret/shoot/sheet-transparent.png characters/enemies/stage_05/enemy_gale_turret.png -Force
Copy-Item assets/generated/stage05_enemy_updraft_fan/pulse/sheet-transparent.png characters/enemies/stage_05/enemy_updraft_fan.png -Force
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_05/enemy_gale_turret.png.import, characters/enemies/stage_05/enemy_updraft_fan.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
$generated = Get-ChildItem assets/generated/stage05_enemy_gale_turret, assets/generated/stage05_enemy_updraft_fan -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_05/enemy_gale_turret.png characters/enemies/stage_05/enemy_gale_turret.png.import characters/enemies/stage_05/enemy_updraft_fan.png characters/enemies/stage_05/enemy_updraft_fan.png.import
git commit -m "feat: add stage 05 static enemy sprites"
```

---

### Task 5: Projectile And FX Sprites

**Files:**
- Create generated assets for `gale_bolt`, `wind_slash`, `feather_dart`, `updraft_pulse`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_05/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_gale_bolt\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage05_gale_bolt\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_wind_slash\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage05_wind_slash\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_feather_dart\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage05_feather_dart\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage05_updraft_pulse\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage05_updraft_pulse\projectile\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_gale_bolt/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage05_gale_bolt/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_wind_slash/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage05_wind_slash/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_feather_dart/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage05_feather_dart/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage05_updraft_pulse/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage05_updraft_pulse/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
```

- [ ] **Step 3: Visual QC**

Pass criteria:
- `gale_bolt` reads as compact horizontal wind shot.
- `wind_slash` reads as curved cutting air blade.
- `feather_dart` reads as physical metallic feather, not energy.
- `updraft_pulse` reads as vertical lift/turbulence pulse distinct from `gale_bolt`.

- [ ] **Step 4: Copy runtime PNGs, import, and commit**

Run:

```powershell
Copy-Item assets/generated/stage05_gale_bolt/projectile/sheet-transparent.png characters/enemies/stage_05/gale_bolt.png -Force
Copy-Item assets/generated/stage05_wind_slash/projectile/sheet-transparent.png characters/enemies/stage_05/wind_slash.png -Force
Copy-Item assets/generated/stage05_feather_dart/projectile/sheet-transparent.png characters/enemies/stage_05/feather_dart.png -Force
Copy-Item assets/generated/stage05_updraft_pulse/projectile/sheet-transparent.png characters/enemies/stage_05/updraft_pulse.png -Force
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_05/gale_bolt.png.import, characters/enemies/stage_05/wind_slash.png.import, characters/enemies/stage_05/feather_dart.png.import, characters/enemies/stage_05/updraft_pulse.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
$generated = Get-ChildItem assets/generated/stage05_gale_bolt, assets/generated/stage05_wind_slash, assets/generated/stage05_feather_dart, assets/generated/stage05_updraft_pulse -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_05/gale_bolt.png characters/enemies/stage_05/gale_bolt.png.import characters/enemies/stage_05/wind_slash.png characters/enemies/stage_05/wind_slash.png.import characters/enemies/stage_05/feather_dart.png characters/enemies/stage_05/feather_dart.png.import characters/enemies/stage_05/updraft_pulse.png characters/enemies/stage_05/updraft_pulse.png.import
git commit -m "feat: add stage 05 enemy projectile sprites"
```

---

### Task 6: Final QC

**Files:**
- Verify all files created by Tasks 1-5.

- [ ] **Step 1: Validate runtime outputs**

Run:

```powershell
$files = @(
  'enemy_gale_runner',
  'enemy_claw_glider',
  'enemy_airfoil_lancer',
  'enemy_sky_harrier',
  'enemy_turbine_wisp',
  'enemy_feather_swarm',
  'enemy_gale_grappler',
  'enemy_gale_turret',
  'enemy_updraft_fan',
  'gale_bolt',
  'wind_slash',
  'feather_dart',
  'updraft_pulse'
)
foreach ($name in $files) {
  $png = "characters/enemies/stage_05/$name.png"
  $imp = "$png.import"
  [pscustomobject]@{Name=$name; Png=(Test-Path $png); Import=(Test-Path $imp)}
}
```

Expected: all rows show `Png=True` and `Import=True`.

- [ ] **Step 2: Validate metadata edge-touch**

Run:

```powershell
$metas = Get-ChildItem assets/generated -Recurse -Filter pipeline-meta.json | Where-Object { $_.FullName -match 'stage05_' }
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

- [ ] **Step 3: Validate runtime PNG border alpha**

Run:

```powershell
Add-Type -AssemblyName System.Drawing
$files = @('enemy_gale_runner','enemy_claw_glider','enemy_airfoil_lancer','enemy_sky_harrier','enemy_turbine_wisp','enemy_feather_swarm','enemy_gale_grappler','enemy_gale_turret','enemy_updraft_fan','gale_bolt','wind_slash','feather_dart','updraft_pulse')
foreach ($name in $files) {
  $path = (Resolve-Path "characters/enemies/stage_05/$name.png").Path
  $bmp = [System.Drawing.Bitmap]::new($path)
  $edge = 0
  for ($x=0; $x -lt $bmp.Width; $x++) {
    if ($bmp.GetPixel($x,0).A -gt 0) { $edge++ }
    if ($bmp.GetPixel($x,$bmp.Height-1).A -gt 0) { $edge++ }
  }
  for ($y=0; $y -lt $bmp.Height; $y++) {
    if ($bmp.GetPixel(0,$y).A -gt 0) { $edge++ }
    if ($bmp.GetPixel($bmp.Width-1,$y).A -gt 0) { $edge++ }
  }
  [pscustomobject]@{Name=$name; Width=$bmp.Width; Height=$bmp.Height; EdgeAlphaPixels=$edge}
  $bmp.Dispose()
}
```

Expected: every row has `EdgeAlphaPixels=0`.

- [ ] **Step 4: Review git status and recent commits**

Run:

```powershell
git status --short -- assets/generated/stage05_* characters/enemies/stage_05 docs/superpowers
git log --oneline -8
```

Expected: no uncommitted Stage 05 sprite files remain except untracked `.png.import` files under `assets/generated`, which must not be committed. Recent commits include spec, plan, prompts, and sprite batches.

- [ ] **Step 5: Final visual checklist**

Inspect final runtime sheets:

```powershell
characters/enemies/stage_05/enemy_gale_runner.png
characters/enemies/stage_05/enemy_claw_glider.png
characters/enemies/stage_05/enemy_airfoil_lancer.png
characters/enemies/stage_05/enemy_sky_harrier.png
characters/enemies/stage_05/enemy_turbine_wisp.png
characters/enemies/stage_05/enemy_feather_swarm.png
characters/enemies/stage_05/enemy_gale_grappler.png
characters/enemies/stage_05/enemy_gale_turret.png
characters/enemies/stage_05/enemy_updraft_fan.png
characters/enemies/stage_05/gale_bolt.png
characters/enemies/stage_05/wind_slash.png
characters/enemies/stage_05/feather_dart.png
characters/enemies/stage_05/updraft_pulse.png
```

Pass criteria:
- Galerix/vento/raptor theme is visible across the set.
- The set feels like aerial wind platforms, not Stage 03 electricity or Stage 04 gravity.
- Ground enemies feel light and fast.
- Suspended enemies clearly communicate patrol, shooter, swarm, and capture roles.
- Static enemies clearly communicate wind cannon and updraft fan.
- The four projectiles are distinct.
- No body sheet relies on wide detached FX.
