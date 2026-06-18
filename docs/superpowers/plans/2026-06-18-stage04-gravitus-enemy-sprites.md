# Stage 04 Gravitus Enemy Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, process, import, QC, and commit 9 Stage 04 Gravitus enemy sprite sheets plus 4 separate projectile/FX sheets.

**Architecture:** Each enemy or projectile is generated as its own raw sheet under `assets/generated/stage04_*`, then postprocessed with `generate2dsprite.py` into transparent sheets, frames, GIFs, and metadata. Runtime-ready PNGs are copied to `characters/enemies/stage_04/`, imported by Godot, and committed in small batches.

**Tech Stack:** Godot 4.6.2, PowerShell, built-in image generation or CLI fallback through the `imagegen` skill, `generate2dsprite.py` for deterministic chroma-key processing and QC metadata, Git.

---

## Source Context

- Spec: `docs/superpowers/specs/2026-06-18-stage04-gravitus-enemies-sprite-design.md`
- Boss: Gravitus, urso gravitacional, elemento gravidade
- Stage theme: estacao espacial/antigravidade
- Runtime output folder: `characters/enemies/stage_04/`
- Generated output prefix: `assets/generated/stage04_`
- Required final roster:
  - Ground/melee: `enemy_grav_guard`, `enemy_mass_brute`, `enemy_orbit_mauler`
  - Suspended/fly/hazard: `enemy_void_drone`, `enemy_gravity_mine`, `enemy_debris_orbiter`
  - Static/ranged: `enemy_singularity_turret`, `enemy_grav_well`, `enemy_crush_pylon`
  - Projectiles/FX: `gravity_bolt`, `mass_pulse`, `orbit_shard`, `crush_wave`

## Shared Rules

- Work from `D:\SnesGame\.worktrees\stage04-enemies`.
- Keep every raw sheet on solid `#FF00FF` background.
- Use separate raw sheets for each enemy and projectile.
- Use `--shared-scale` and `--reject-edge-touch` for every processed sheet.
- Use `--component-mode largest` for enemy body sheets.
- Use `--component-mode largest` for compact projectiles unless visual QC shows detached shard/spark components were incorrectly removed; then reprocess that projectile with `--component-mode all`.
- If processing reports edge-touch frames, inspect `raw-sheet.png`, strengthen containment in `prompt-used.txt`, regenerate, and reprocess.
- If Godot `--headless --import` exits nonzero but creates `.import` files, validate sidecars directly with `Get-Item`.
- Do not commit `.png.import` files created inside `assets/generated`; only commit generated source PNG/GIF/metadata plus runtime `.png.import` files under `characters/enemies/stage_04/`.

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
Get-Item characters/enemies/stage_04/*.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
```

---

### Task 1: Prompt Files

**Files:**
- Create: `characters/enemies/stage_04/.gitkeep`
- Create: `assets/generated/stage04_enemy_grav_guard/shock/prompt-used.txt`
- Create: `assets/generated/stage04_enemy_mass_brute/charge/prompt-used.txt`
- Create: `assets/generated/stage04_enemy_orbit_mauler/swing/prompt-used.txt`
- Create: `assets/generated/stage04_enemy_void_drone/shoot/prompt-used.txt`
- Create: `assets/generated/stage04_enemy_gravity_mine/pulse/prompt-used.txt`
- Create: `assets/generated/stage04_enemy_debris_orbiter/orbit/prompt-used.txt`
- Create: `assets/generated/stage04_enemy_singularity_turret/shoot/prompt-used.txt`
- Create: `assets/generated/stage04_enemy_grav_well/pulse/prompt-used.txt`
- Create: `assets/generated/stage04_enemy_crush_pylon/pulse/prompt-used.txt`
- Create: `assets/generated/stage04_gravity_bolt/projectile/prompt-used.txt`
- Create: `assets/generated/stage04_mass_pulse/projectile/prompt-used.txt`
- Create: `assets/generated/stage04_orbit_shard/projectile/prompt-used.txt`
- Create: `assets/generated/stage04_crush_wave/projectile/prompt-used.txt`

- [ ] **Step 1: Create output directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  characters/enemies/stage_04, `
  assets/generated/stage04_enemy_grav_guard/shock, `
  assets/generated/stage04_enemy_mass_brute/charge, `
  assets/generated/stage04_enemy_orbit_mauler/swing, `
  assets/generated/stage04_enemy_void_drone/shoot, `
  assets/generated/stage04_enemy_gravity_mine/pulse, `
  assets/generated/stage04_enemy_debris_orbiter/orbit, `
  assets/generated/stage04_enemy_singularity_turret/shoot, `
  assets/generated/stage04_enemy_grav_well/pulse, `
  assets/generated/stage04_enemy_crush_pylon/pulse, `
  assets/generated/stage04_gravity_bolt/projectile, `
  assets/generated/stage04_mass_pulse/projectile, `
  assets/generated/stage04_orbit_shard/projectile, `
  assets/generated/stage04_crush_wave/projectile
New-Item -ItemType File -Force characters/enemies/stage_04/.gitkeep
```

- [ ] **Step 2: Write ground enemy prompts**

Write these exact prompts.

`assets/generated/stage04_enemy_grav_guard/shock/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_grav_guard, a compact heavy orbital reploid guard from Gravitus's anti-gravity space station. It is a ground melee troop, not a bear. Visual design: dark purple and black dense armor, burgundy plates, white-lavender gravity core in the chest, broad shoulders, heavy boots, short dense fists or gravity gauntlets, small orbital emitters on the arms, Mega Man X inspired silhouette with original IP identity. Motion: ready stance, weight shift, gravity core brightens, short heavy punch or impact pose, recoil, return-ready loop pose. Keep gravity glow compact and attached to fists/core only. Same identity, same scale, centered body, stable feet/bottom anchor in each cell. Full body inside central 65% safe area, no limb, armor, glow, debris, or distortion crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage04_enemy_mass_brute/charge/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_mass_brute, a low heavy quadruped robot inspired by a gravity bear, a common enemy from Gravitus's anti-gravity station, much smaller than the boss. Visual design: dense black-purple armor, broad shoulder plates, magnetic paws, compact bear-like mechanical head without organic fur, burgundy joint plates, white gravity core in the torso, heavy reinforced back. Motion read left-to-right: idle crouch, core warms, paws magnetize, body compresses, forward lean, short heavy charge pose, impact brace, recoil, return idle. Keep dust/debris compact and attached near paws. Same identity, same scale, centered body, stable bottom anchor in every grounded cell. Full body inside central 65% safe area, no paw, shoulder, glow, or debris crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage04_enemy_orbit_mauler/swing/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_orbit_mauler, a slow ground gravity guard with two compact debris weights orbiting close to its body in Gravitus's space station. Visual design: stocky armored reploid body, dark purple and black armor, burgundy plates, white-lavender gravity core, two small metal debris spheres orbiting on short gravity arcs near the shoulders, heavy feet. Motion read left-to-right: idle, debris starts orbiting, core charges, orbit speeds up, debris swings forward, compact strike pose, recoil, orbit slows, return idle. Keep both debris weights close to the body and inside each cell. Same identity, same scale, centered body, stable bottom anchor in every cell. Full subject inside central 65% safe area, no debris sphere, arc, arm, glow, or distortion crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 3: Write suspended/flying enemy prompts**

`assets/generated/stage04_enemy_void_drone/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_void_drone, a floating orbital security drone from Gravitus's anti-gravity space station. Visual design: compact triangular-circular drone body, dark purple and black metal shell, burgundy armor tabs, white gravity core, small close-orbiting fragments, front emitter lens, no wings or lightning. Motion: hover patrol, slight tilt, core brightens, shoot pose with compact attached muzzle glow only, recoil tilt, return hover. Do not include detached projectile in the body sheet. Same identity, same scale, centered body in every cell. Full subject inside central 65% safe area, no fragment, antenna, muzzle glow, or distortion crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage04_enemy_gravity_mine/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_gravity_mine, a suspended anti-gravity mine hazard from Gravitus's space station. Visual design: dark segmented spherical shell, black-purple armor, burgundy clamps, bright white-lavender gravity core, short compact orbital rings, small warning lights. Motion: dormant hover, shell segments wake, core charges, compact pulse glow expands attached to mine, armed state, cooldown. Do not include wide area effect or detached projectile in the body sheet. Same identity, same scale, centered body in every cell. Full subject inside central 60% safe area with clear magenta margin, no ring, segment, glow, or distortion crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage04_enemy_debris_orbiter/orbit/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_debris_orbiter, a compact gravity anomaly machine made of mechanical debris fragments orbiting a white-lavender unstable core. Visual design: central dark purple gravity core housing, black metal fragments, burgundy broken plates, small debris chunks orbiting close in a circular pattern, space-station machinery not natural rock. Motion read left-to-right: slow orbit, fragments rotate, core pulses, orbit widens slightly but stays compact, charge peak, release pose with attached glow only, recoil, orbit stabilizes, return idle. Same identity, same scale, centered circular silhouette. Full subject inside central 60% safe area, no fragment, arc, glow, or distortion crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 4: Write static enemy prompts**

`assets/generated/stage04_enemy_singularity_turret/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: enemy_singularity_turret, a fixed gravity cannon installed in Gravitus's anti-gravity space station. Visual design: low angular turret body, dark purple and black armored shell, burgundy capacitor plates, front circular white-lavender singularity emitter, heavy base clamps, small gravity rings around the muzzle. Motion: idle, emitter charges, shoot pose with compact attached muzzle glow only, cooldown. Do not include detached projectile in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full turret inside central 65% safe area, no muzzle glow, ring, antenna, or capacitor crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage04_enemy_grav_well/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_grav_well, a stationary gravity well generator from Gravitus's space station. Visual design: industrial base, central dark singularity chamber, white-lavender gravity core, short rotating orbital rings, black-purple panels, burgundy braces, small close debris bits held by gravity. Motion read left-to-right: idle, rings wake, chamber darkens, core brightens, rings rotate faster, compact pulse attached to generator, afterglow, cooldown, return idle. Do not include wide pull field or detached projectile in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full subject inside central 65% safe area, no ring, debris, glow, or distortion crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage04_enemy_crush_pylon/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_crush_pylon, a fixed gravity compression pylon hazard from Gravitus's anti-gravity station. Visual design: vertical compact pylon tower, dense black-purple metal, burgundy segment plates, stacked white-lavender gravity lenses, heavy base, short compression rings attached close to the tower. Motion: idle dark pylon, lower lens lights, middle lens charges, top lens charges, compact compression discharge attached to the pylon, cooldown. Do not include detached wave or wide beam in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full pylon inside central 65% safe area, no ring, glow, antenna, or distortion crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 5: Write projectile prompts**

`assets/generated/stage04_gravity_bolt/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: gravity_bolt, a compact horizontal gravity projectile fired by Stage 04 Gravitus enemies, travel direction left-to-right. Visual design: bright white-lavender core, dark purple compressed edge, small gravity distortion rings close to the bolt, dense and compact. Motion: stable bolt, brighter pulse, slightly stretched travel pulse, loop return. Same projectile identity and size in every frame, centered, compact glow. Projectile and glow stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage04_mass_pulse/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: mass_pulse, a compact radial gravity pulse emitted by enemy_grav_well or enemy_gravity_mine. Visual design: circular white-lavender center, dark purple compression rim, subtle concentric rings, no explosion fire or lightning. Motion: small dense pulse, ring expansion, peak compact field, loop fade. Same effect identity and size in every frame, centered, compact glow. Pulse and rings stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage04_orbit_shard/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: orbit_shard, a compact physical debris shard hurled by a gravity field, travel direction left-to-right. Visual design: dark metal shard with purple highlights, burgundy edge plates, tiny white-lavender gravity trail close behind it, spinning physical object not energy bolt. Motion: shard angle one, spinning glint, slight stretch/travel pose, loop return. Same projectile identity and size in every frame, centered, compact trail. Shard and trail stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage04_crush_wave/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: crush_wave, a short dense gravity compression wave from enemy_crush_pylon or enemy_mass_brute. Visual design: flattened horizontal white-lavender pressure band, dark purple edges, compact stacked compression lines, heavier and flatter than mass_pulse. Motion: narrow pressure line, denser band, peak compression ripple, loop fade. Same effect identity and size in every frame, centered, compact glow. Wave and glow stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 6: Commit prompt files**

Run:

```powershell
git add characters/enemies/stage_04/.gitkeep assets/generated/stage04_enemy_grav_guard assets/generated/stage04_enemy_mass_brute assets/generated/stage04_enemy_orbit_mauler assets/generated/stage04_enemy_void_drone assets/generated/stage04_enemy_gravity_mine assets/generated/stage04_enemy_debris_orbiter assets/generated/stage04_enemy_singularity_turret assets/generated/stage04_enemy_grav_well assets/generated/stage04_enemy_crush_pylon assets/generated/stage04_gravity_bolt assets/generated/stage04_mass_pulse assets/generated/stage04_orbit_shard assets/generated/stage04_crush_wave
git commit -m "docs: add stage 04 gravitus sprite prompts"
```

---

### Task 2: Ground Enemy Sprites

**Files:**
- Create generated assets for `enemy_grav_guard`, `enemy_mass_brute`, `enemy_orbit_mauler`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_04/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_enemy_grav_guard\shock\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage04_enemy_grav_guard\shock\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_enemy_mass_brute\charge\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage04_enemy_mass_brute\charge\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_enemy_orbit_mauler\swing\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage04_enemy_orbit_mauler\swing\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_enemy_grav_guard/shock/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage04_enemy_grav_guard/shock --rows 2 --cols 3 --label-prefix shock --align bottom --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_enemy_mass_brute/charge/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage04_enemy_mass_brute/charge --rows 3 --cols 3 --label-prefix charge --align bottom --shared-scale --component-mode largest --fit-scale 0.86 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_enemy_orbit_mauler/swing/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage04_enemy_orbit_mauler/swing --rows 3 --cols 3 --label-prefix swing --align bottom --shared-scale --component-mode largest --fit-scale 0.86 --reject-edge-touch
```

Expected: all `pipeline-meta.json` files have `edge_touch_frames=[]` and `shared_scale=true`.

- [ ] **Step 3: Visual QC**

Open:

```powershell
assets/generated/stage04_enemy_grav_guard/shock/sheet-transparent.png
assets/generated/stage04_enemy_mass_brute/charge/sheet-transparent.png
assets/generated/stage04_enemy_orbit_mauler/swing/sheet-transparent.png
```

Pass criteria:
- `grav_guard` reads as heavy ground reploid guard, not a bear.
- `mass_brute` reads as compact bear-inspired quadruped common enemy.
- `orbit_mauler` reads as ground unit with compact orbiting debris.

- [ ] **Step 4: Copy runtime PNGs**

Run:

```powershell
Copy-Item assets/generated/stage04_enemy_grav_guard/shock/sheet-transparent.png characters/enemies/stage_04/enemy_grav_guard.png -Force
Copy-Item assets/generated/stage04_enemy_mass_brute/charge/sheet-transparent.png characters/enemies/stage_04/enemy_mass_brute.png -Force
Copy-Item assets/generated/stage04_enemy_orbit_mauler/swing/sheet-transparent.png characters/enemies/stage_04/enemy_orbit_mauler.png -Force
```

- [ ] **Step 5: Import with Godot**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_04/enemy_grav_guard.png.import, characters/enemies/stage_04/enemy_mass_brute.png.import, characters/enemies/stage_04/enemy_orbit_mauler.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
```

- [ ] **Step 6: Commit ground sprites**

Run:

```powershell
$generated = Get-ChildItem assets/generated/stage04_enemy_grav_guard, assets/generated/stage04_enemy_mass_brute, assets/generated/stage04_enemy_orbit_mauler -Recurse -File | Where-Object { $_.Name -notlike '*.import' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_04/enemy_grav_guard.png characters/enemies/stage_04/enemy_grav_guard.png.import characters/enemies/stage_04/enemy_mass_brute.png characters/enemies/stage_04/enemy_mass_brute.png.import characters/enemies/stage_04/enemy_orbit_mauler.png characters/enemies/stage_04/enemy_orbit_mauler.png.import
git commit -m "feat: add stage 04 ground enemy sprites"
```

---

### Task 3: Suspended Enemy Sprites

**Files:**
- Create generated assets for `enemy_void_drone`, `enemy_gravity_mine`, `enemy_debris_orbiter`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_04/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_enemy_void_drone\shoot\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage04_enemy_void_drone\shoot\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_enemy_gravity_mine\pulse\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage04_enemy_gravity_mine\pulse\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_enemy_debris_orbiter\orbit\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage04_enemy_debris_orbiter\orbit\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_enemy_void_drone/shoot/raw-sheet.png --target creature --mode shoot --output-dir assets/generated/stage04_enemy_void_drone/shoot --rows 2 --cols 3 --label-prefix shoot --align center --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_enemy_gravity_mine/pulse/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage04_enemy_gravity_mine/pulse --rows 2 --cols 3 --label-prefix pulse --align center --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_enemy_debris_orbiter/orbit/raw-sheet.png --target creature --mode shoot --output-dir assets/generated/stage04_enemy_debris_orbiter/orbit --rows 3 --cols 3 --label-prefix orbit --align center --shared-scale --component-mode largest --fit-scale 0.86 --reject-edge-touch
```

- [ ] **Step 3: Visual QC**

Pass criteria:
- `void_drone` reads as floating orbital security drone.
- `gravity_mine` reads as suspended hazard/mine, not a shooter drone.
- `debris_orbiter` reads as mechanical debris anomaly with compact orbit.

- [ ] **Step 4: Copy runtime PNGs, import, and commit**

Run:

```powershell
Copy-Item assets/generated/stage04_enemy_void_drone/shoot/sheet-transparent.png characters/enemies/stage_04/enemy_void_drone.png -Force
Copy-Item assets/generated/stage04_enemy_gravity_mine/pulse/sheet-transparent.png characters/enemies/stage_04/enemy_gravity_mine.png -Force
Copy-Item assets/generated/stage04_enemy_debris_orbiter/orbit/sheet-transparent.png characters/enemies/stage_04/enemy_debris_orbiter.png -Force
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_04/enemy_void_drone.png.import, characters/enemies/stage_04/enemy_gravity_mine.png.import, characters/enemies/stage_04/enemy_debris_orbiter.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
$generated = Get-ChildItem assets/generated/stage04_enemy_void_drone, assets/generated/stage04_enemy_gravity_mine, assets/generated/stage04_enemy_debris_orbiter -Recurse -File | Where-Object { $_.Name -notlike '*.import' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_04/enemy_void_drone.png characters/enemies/stage_04/enemy_void_drone.png.import characters/enemies/stage_04/enemy_gravity_mine.png characters/enemies/stage_04/enemy_gravity_mine.png.import characters/enemies/stage_04/enemy_debris_orbiter.png characters/enemies/stage_04/enemy_debris_orbiter.png.import
git commit -m "feat: add stage 04 suspended enemy sprites"
```

---

### Task 4: Static Enemy Sprites

**Files:**
- Create generated assets for `enemy_singularity_turret`, `enemy_grav_well`, `enemy_crush_pylon`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_04/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_enemy_singularity_turret\shoot\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage04_enemy_singularity_turret\shoot\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_enemy_grav_well\pulse\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage04_enemy_grav_well\pulse\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_enemy_crush_pylon\pulse\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage04_enemy_crush_pylon\pulse\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_enemy_singularity_turret/shoot/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage04_enemy_singularity_turret/shoot --rows 2 --cols 2 --label-prefix shoot --align bottom --shared-scale --component-mode largest --fit-scale 0.90 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_enemy_grav_well/pulse/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage04_enemy_grav_well/pulse --rows 3 --cols 3 --label-prefix pulse --align bottom --shared-scale --component-mode largest --fit-scale 0.86 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_enemy_crush_pylon/pulse/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage04_enemy_crush_pylon/pulse --rows 2 --cols 3 --label-prefix pulse --align bottom --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
```

- [ ] **Step 3: Visual QC**

Pass criteria:
- `singularity_turret` reads as low directional gravity cannon.
- `grav_well` reads as field generator, not turret.
- `crush_pylon` reads as compact vertical compression pylon/hazard.

- [ ] **Step 4: Copy runtime PNGs, import, and commit**

Run:

```powershell
Copy-Item assets/generated/stage04_enemy_singularity_turret/shoot/sheet-transparent.png characters/enemies/stage_04/enemy_singularity_turret.png -Force
Copy-Item assets/generated/stage04_enemy_grav_well/pulse/sheet-transparent.png characters/enemies/stage_04/enemy_grav_well.png -Force
Copy-Item assets/generated/stage04_enemy_crush_pylon/pulse/sheet-transparent.png characters/enemies/stage_04/enemy_crush_pylon.png -Force
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_04/enemy_singularity_turret.png.import, characters/enemies/stage_04/enemy_grav_well.png.import, characters/enemies/stage_04/enemy_crush_pylon.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
$generated = Get-ChildItem assets/generated/stage04_enemy_singularity_turret, assets/generated/stage04_enemy_grav_well, assets/generated/stage04_enemy_crush_pylon -Recurse -File | Where-Object { $_.Name -notlike '*.import' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_04/enemy_singularity_turret.png characters/enemies/stage_04/enemy_singularity_turret.png.import characters/enemies/stage_04/enemy_grav_well.png characters/enemies/stage_04/enemy_grav_well.png.import characters/enemies/stage_04/enemy_crush_pylon.png characters/enemies/stage_04/enemy_crush_pylon.png.import
git commit -m "feat: add stage 04 static enemy sprites"
```

---

### Task 5: Projectile And FX Sprites

**Files:**
- Create generated assets for `gravity_bolt`, `mass_pulse`, `orbit_shard`, `crush_wave`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_04/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_gravity_bolt\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage04_gravity_bolt\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_mass_pulse\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage04_mass_pulse\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_orbit_shard\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage04_orbit_shard\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage04_crush_wave\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage04_crush_wave\projectile\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_gravity_bolt/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage04_gravity_bolt/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.80 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_mass_pulse/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage04_mass_pulse/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.80 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_orbit_shard/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage04_orbit_shard/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.80 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage04_crush_wave/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage04_crush_wave/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.80 --reject-edge-touch
```

- [ ] **Step 3: Visual QC**

Pass criteria:
- `gravity_bolt` reads as compact horizontal gravity shot.
- `mass_pulse` reads as radial pulse.
- `orbit_shard` reads as physical spinning debris, not energy.
- `crush_wave` reads as flattened compression wave, distinct from `mass_pulse`.

- [ ] **Step 4: Copy runtime PNGs, import, and commit**

Run:

```powershell
Copy-Item assets/generated/stage04_gravity_bolt/projectile/sheet-transparent.png characters/enemies/stage_04/gravity_bolt.png -Force
Copy-Item assets/generated/stage04_mass_pulse/projectile/sheet-transparent.png characters/enemies/stage_04/mass_pulse.png -Force
Copy-Item assets/generated/stage04_orbit_shard/projectile/sheet-transparent.png characters/enemies/stage_04/orbit_shard.png -Force
Copy-Item assets/generated/stage04_crush_wave/projectile/sheet-transparent.png characters/enemies/stage_04/crush_wave.png -Force
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
Get-Item characters/enemies/stage_04/gravity_bolt.png.import, characters/enemies/stage_04/mass_pulse.png.import, characters/enemies/stage_04/orbit_shard.png.import, characters/enemies/stage_04/crush_wave.png.import -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime
$generated = Get-ChildItem assets/generated/stage04_gravity_bolt, assets/generated/stage04_mass_pulse, assets/generated/stage04_orbit_shard, assets/generated/stage04_crush_wave -Recurse -File | Where-Object { $_.Name -notlike '*.import' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_04/gravity_bolt.png characters/enemies/stage_04/gravity_bolt.png.import characters/enemies/stage_04/mass_pulse.png characters/enemies/stage_04/mass_pulse.png.import characters/enemies/stage_04/orbit_shard.png characters/enemies/stage_04/orbit_shard.png.import characters/enemies/stage_04/crush_wave.png characters/enemies/stage_04/crush_wave.png.import
git commit -m "feat: add stage 04 enemy projectile sprites"
```

---

### Task 6: Final QC

**Files:**
- Verify all files created by Tasks 1-5.

- [ ] **Step 1: Validate runtime outputs**

Run:

```powershell
$files = @(
  'enemy_grav_guard',
  'enemy_mass_brute',
  'enemy_orbit_mauler',
  'enemy_void_drone',
  'enemy_gravity_mine',
  'enemy_debris_orbiter',
  'enemy_singularity_turret',
  'enemy_grav_well',
  'enemy_crush_pylon',
  'gravity_bolt',
  'mass_pulse',
  'orbit_shard',
  'crush_wave'
)
foreach ($name in $files) {
  $png = "characters/enemies/stage_04/$name.png"
  $imp = "$png.import"
  [pscustomobject]@{Name=$name; Png=(Test-Path $png); Import=(Test-Path $imp)}
}
```

Expected: all rows show `Png=True` and `Import=True`.

- [ ] **Step 2: Validate metadata edge-touch**

Run:

```powershell
$metas = Get-ChildItem assets/generated -Recurse -Filter pipeline-meta.json | Where-Object { $_.FullName -match 'stage04_' }
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
$files = @('enemy_grav_guard','enemy_mass_brute','enemy_orbit_mauler','enemy_void_drone','enemy_gravity_mine','enemy_debris_orbiter','enemy_singularity_turret','enemy_grav_well','enemy_crush_pylon','gravity_bolt','mass_pulse','orbit_shard','crush_wave')
foreach ($name in $files) {
  $path = (Resolve-Path "characters/enemies/stage_04/$name.png").Path
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
git status --short -- assets/generated/stage04_* characters/enemies/stage_04 docs/superpowers
git log --oneline -8
```

Expected: no uncommitted Stage 04 sprite files remain. Recent commits include spec, plan, prompts, and sprite batches.

- [ ] **Step 5: Final visual checklist**

Inspect final runtime sheets:

```powershell
characters/enemies/stage_04/enemy_grav_guard.png
characters/enemies/stage_04/enemy_mass_brute.png
characters/enemies/stage_04/enemy_orbit_mauler.png
characters/enemies/stage_04/enemy_void_drone.png
characters/enemies/stage_04/enemy_gravity_mine.png
characters/enemies/stage_04/enemy_debris_orbiter.png
characters/enemies/stage_04/enemy_singularity_turret.png
characters/enemies/stage_04/enemy_grav_well.png
characters/enemies/stage_04/enemy_crush_pylon.png
characters/enemies/stage_04/gravity_bolt.png
characters/enemies/stage_04/mass_pulse.png
characters/enemies/stage_04/orbit_shard.png
characters/enemies/stage_04/crush_wave.png
```

Pass criteria:
- Gravitus/urso gravitacional theme is visible across the set.
- The set feels like anti-gravity/space station, not Stage 03 electricity or Stage 06 shadow.
- Ground enemies feel heavier than Stage 03 flyers.
- Static/hazard enemies clearly communicate gravity control.
- The four projectiles are distinct.
- No body sheet relies on wide detached FX.
