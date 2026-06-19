# Stage 08 Terragor Enemy Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, process, import, QC, and commit 9 Stage 08 Terragor enemy sprite sheets plus 4 separate projectile/FX sheets.

**Architecture:** Each enemy or projectile is generated as its own raw sheet under `assets/generated/stage08_*`, then postprocessed with `generate2dsprite.py` into transparent sheets, frames, GIFs, and metadata. Runtime-ready PNGs are copied to `characters/enemies/stage_08/`, import sidecars are created consistently with the existing Godot texture import pattern, and work is committed in small batches.

**Tech Stack:** Godot 4.6.2, PowerShell, built-in image generation or CLI fallback through the `imagegen` skill, `generate2dsprite.py` for deterministic chroma-key processing and QC metadata, Git.

---

## Source Context

- Spec: `docs/superpowers/specs/2026-06-19-stage08-terragor-enemy-sprites-design.md`
- Boss: Terragor, gorila de pedra com punhos grandes, placas rochosas, espinhos de pedra e ataques de rocha/terra
- Stage theme: caverna, terra, rocha, musgo, raizes, fosseis, veios minerais e ruinas organicas
- Runtime output folder: `characters/enemies/stage_08/`
- Generated output prefix: `assets/generated/stage08_`
- Required final roster:
  - Ground/melee: `enemy_terra_grunt`, `enemy_mossback_brute`, `enemy_drill_mole`
  - Fly/suspended: `enemy_gem_wasp`, `enemy_stone_glider`, `enemy_ore_orbiter`
  - Static/ranged/traps: `enemy_root_snare`, `enemy_boulder_turret`, `enemy_fossil_totem`
  - Projectiles/FX: `stone_shot`, `ore_shard`, `root_bind`, `quake_wave`

## Shared Rules

- Work from `D:\SnesGame\.worktrees\stage08-enemies`.
- Keep every raw sheet on solid `#FF00FF` background.
- Use separate raw sheets for each enemy and projectile.
- Use `--shared-scale` and `--reject-edge-touch` for every processed sheet.
- Use `--component-mode largest` for enemy body sheets.
- Use `--component-mode all` for `root_bind` and `quake_wave` if the effect has multiple intentional connected components; otherwise start with `largest`.
- If processing reports edge-touch frames, inspect `raw-sheet.png`, strengthen containment in `prompt-used.txt`, regenerate, and reprocess.
- If Godot `--headless --import` creates only temporary `.import*.tmp` files, create final `.png.import` sidecars using the standard texture template and MD5 of `res://characters/enemies/stage_08/<file>.png`.
- Do not commit `.png.import` files created inside `assets/generated`; only commit generated source PNG/GIF/metadata plus runtime `.png.import` files under `characters/enemies/stage_08/`.

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

Create a Godot texture import sidecar manually when Godot safe-save fails:

```powershell
$name = "<asset_name>"
$res = "res://characters/enemies/stage_08/$name.png"
$md5 = [System.Security.Cryptography.MD5]::Create()
$hash = (($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res)) | ForEach-Object { $_.ToString('x2') }) -join '')
$uidSource = "uid://stage08$name".Replace("_","")
$uid = $uidSource.Substring(0, [Math]::Min(22, $uidSource.Length))
@"
[remap]

importer="texture"
type="CompressedTexture2D"
uid="$uid"
path="res://.godot/imported/$name.png-$hash.ctex"
metadata={
"vram_texture": false
}

[deps]

source_file="$res"
dest_files=["res://.godot/imported/$name.png-$hash.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"@ | Set-Content "characters/enemies/stage_08/$name.png.import" -Encoding UTF8
```

---

### Task 1: Prompt Files

**Files:**
- Create: `characters/enemies/stage_08/.gitkeep`
- Create one `prompt-used.txt` under each generated output directory listed below.

- [ ] **Step 1: Create output directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  characters/enemies/stage_08, `
  assets/generated/stage08_enemy_terra_grunt/attack, `
  assets/generated/stage08_enemy_mossback_brute/quake, `
  assets/generated/stage08_enemy_drill_mole/burrow, `
  assets/generated/stage08_enemy_gem_wasp/shoot, `
  assets/generated/stage08_enemy_stone_glider/glide, `
  assets/generated/stage08_enemy_ore_orbiter/shoot, `
  assets/generated/stage08_enemy_root_snare/grab, `
  assets/generated/stage08_enemy_boulder_turret/shoot, `
  assets/generated/stage08_enemy_fossil_totem/pulse, `
  assets/generated/stage08_stone_shot/projectile, `
  assets/generated/stage08_ore_shard/projectile, `
  assets/generated/stage08_root_bind/projectile, `
  assets/generated/stage08_quake_wave/projectile
New-Item -ItemType File -Force characters/enemies/stage_08/.gitkeep
```

- [ ] **Step 2: Write the 13 prompt files**

Create these exact prompt files:

`assets/generated/stage08_enemy_terra_grunt/attack/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_terra_grunt, a basic ground soldier from Terragor's Stage 08 earth cave domain. Visual design: compact reploid troop with stone armor plates, oxidized buried metal joints, small moss-green visor, rocky shoulders, short integrated heavy arm club kept close to the body, earth brown gray and moss palette, Mega Man X inspired silhouette with original IP identity. Motion: idle guard, heavy step, arm club lifts, short close-range strike with no detached shockwave, recoil, return guard. It must be a common cave ground troop, not a mini Terragor, not a pure golem, and not a fire enemy. Same identity, same scale, centered body, stable feet/bottom anchor in every cell. Full body inside central 60% safe area with clear magenta margin around club, shoulders, feet, dust, and helmet. No limb, club, rock plate, moss, dust, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_enemy_mossback_brute/quake/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_mossback_brute, a heavy walking earth robot from Terragor's cave stage. Visual design: wide mechanical body, layered stone armor, moss-covered back and shoulders, thick hydraulic legs, big blunt forearms, dark brown gray rock plates, muted green moss details, amber mineral cracks, Mega Man X inspired enemy. Motion read left-to-right: heavy idle, one slow step, both arms lift, body compresses, ground-slam pose with attached dust only, recoil, moss shakes, reset stance, return idle. Do not include a wide quake wave in the body sheet. Same identity, same scale, centered body, stable feet/bottom anchor in every grounded frame. Full body inside central 60% safe area, no arm, moss clump, dust, rock plate, or foot crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_enemy_drill_mole/burrow/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_drill_mole, a robotic mole digger enemy from Terragor's underground Stage 08. Visual design: low compact mechanical mole body, large front drill cone, small claw feet, stone back plates, dirt-brown armor, gray metal chassis, moss green sensor eye, small attached dirt chunks only. Motion read left-to-right: low idle, drill spins, crouch into ground, half-buried pose, emerge forward, drill charge pose, short dash pose, recoil, return idle. It must suggest robotic subterranean fauna, not a natural animal and not a boss. Same identity, same scale, centered body, stable bottom anchor in grounded frames. Full body inside central 60% safe area, no drill tip, claw, dirt chunk, rock plate, or dust crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_enemy_gem_wasp/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_gem_wasp, a small flying mineral wasp robot from Terragor's Stage 08 cave. Visual design: compact insectoid drone, thin amber mineral wings, oxidized metal thorax, crystal amber stinger, moss green eye slit, small stone armor plates, earthy brown gray green palette, not electric and not ice. Motion read left-to-right: hover idle, wings up, wings down, abdomen aims, amber stinger charges, shoot pose with compact attached muzzle glint only, recoil hover, wing beat stabilize, return hover. Do not include detached projectile in the body sheet. Same identity, same scale, centered body in every cell. Full subject inside central 60% safe area, no wing tip, stinger, glint, antenna, or leg crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_enemy_stone_glider/glide/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_stone_glider, a cave glider machine from Terragor's earth stage. Visual design: flat mechanical body, thin fossil-stone wing plates, short mineral tail, small green sensor, gray brown rock material, oxidized metal ribs, subtle amber vein highlights, no teal wind effects and no ice crystal. Motion: glide idle, left wing dips, right wing dips, shallow dive pose, pull-up pose, return glide. Keep wings compact and body centered. Same identity, same scale in every cell. Full subject inside central 60% safe area, no wing tip, tail, fossil plate, glow, or sensor crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_enemy_ore_orbiter/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_ore_orbiter, a floating mineral core machine from Terragor's cave stage. Visual design: amber ore core in a compact stone-metal shell, small rock chunks held by short mechanical struts or clamps, moss green sensor, brown gray stone plates, no purple gravity effects, no orbital cosmic rings, no blue ice crystals. Motion: hover idle, clamps shift, ore core glows amber, shoot pose with compact attached stone muzzle chip only, recoil tilt, return hover. Do not include detached projectile in the body sheet. Same identity, same scale, centered body in every cell. Full subject inside central 60% safe area, no rock chunk, clamp, glow, dust, or shell crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_enemy_root_snare/grab/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_root_snare, a semi-buried mechanical root trap from Terragor's Stage 08. Visual design: fixed ground base of stone and oxidized metal, segmented root-metal tendrils, moss green core, brown roots, gray buried clamps, ancient organic machine look. Motion read left-to-right: dormant buried base, core wakes, short roots unfold, roots spread low, grab-ready pose, compact close grip pose, recoil open, roots retract, return dormant. Do not show the player, do not include a long tether, and do not include a wide area effect in the body sheet. Same identity, same scale, stable base/bottom anchor in every cell. Full subject inside central 60% safe area, no root, clamp, core glow, dirt, or moss crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_enemy_boulder_turret/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: enemy_boulder_turret, a fixed stone cannon installed in Terragor's Stage 08 cave platforms. Visual design: squat low turret, carved stone casing, oxidized buried metal barrel, moss in seams, brown gray rock body, small amber chamber, mechanical base clamps, no soldier legs. Motion: idle, barrel raises, shoot pose with compact attached stone muzzle dust only, cooldown. Do not include detached projectile or wide blast in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full turret inside central 60% safe area, no barrel, muzzle dust, clamp, moss, or rock chip crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_enemy_fossil_totem/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_fossil_totem, a fixed ancient organic ruin totem from Terragor's earth stage. Visual design: vertical carved stone column, embedded fossil bones and shell impressions, moss patches, dark green core, brown gray crumbled stone, subtle amber mineral veins, old subterranean machine altar, not a clean sci-fi turret. Motion: idle dim core, fossil plates shift, moss-green core charges, compact attached ground pulse glow, recoil crumble dust, return idle. Do not include a wide quake wave in the body sheet. Same identity, same scale, stable base/bottom anchor in every cell. Full totem inside central 60% safe area, no fossil piece, dust, core glow, moss, or stone edge crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_stone_shot/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: stone_shot, a compact rock projectile fired by Stage 08 Terragor enemies, travel direction left-to-right. Visual design: small rough brown gray stone chunk, tiny close dust trail, physical impact mass, no fire, no ice, no purple gravity glow. Motion: stone angle one, slight spin, travel stretch with dust, loop return. Same projectile identity and size in every frame, centered, compact trail. Stone and dust stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_ore_shard/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: ore_shard, a compact amber mineral shard fired by enemy_gem_wasp in Stage 08, travel direction left-to-right. Visual design: jagged amber ore crystal with earthy brown edge, small warm mineral glint, tiny close trail, not blue ice and not fire. Motion: shard angle one, spinning glint, slight travel stretch, loop return. Same projectile identity and size in every frame, centered, compact trail. Shard and trail stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_root_bind/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: root_bind, a compact mechanical root bind effect used by enemy_root_snare. Visual design: brown segmented root-metal tendrils closing into a small snare loop, moss-green core glow, tiny dirt bits, organic machine texture, no shadow magic and no electricity. Motion: roots appear low, tendrils curl inward, compact closed snare, loop fade. Same effect identity and size in every frame, centered, compact. Roots and dirt stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage08_quake_wave/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: quake_wave, a low horizontal seismic ground wave used by Terragor Stage 08 enemies, travel direction left-to-right. Visual design: short jagged ground ripple, brown dust, small gray rock chips, low earth shock ridge, no fire, no wind, no purple gravity distortion. Motion: ground bulge starts, rock ridge rises, compact wave peak, dust settles. Same effect identity and size in every frame, centered and low. Wave, dust, and chips stay fully inside central 65% safe area with extra side margin. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 3: Commit prompt files**

Run:

```powershell
git add characters/enemies/stage_08/.gitkeep assets/generated/stage08_*/**/prompt-used.txt
git commit -m "docs: add stage 08 terragor sprite prompts"
```

Expected: commit records only `.gitkeep` and 13 `prompt-used.txt` files.

---

### Task 2: Ground Enemy Sprite Sheets

**Files:**
- Create/modify: `assets/generated/stage08_enemy_terra_grunt/attack/`
- Create/modify: `assets/generated/stage08_enemy_mossback_brute/quake/`
- Create/modify: `assets/generated/stage08_enemy_drill_mole/burrow/`
- Create: `characters/enemies/stage_08/enemy_terra_grunt.png`
- Create: `characters/enemies/stage_08/enemy_mossback_brute.png`
- Create: `characters/enemies/stage_08/enemy_drill_mole.png`

- [ ] **Step 1: Generate raw sheets**

Run one command per prompt:

```powershell
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_enemy_terra_grunt/attack/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_enemy_terra_grunt/attack/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_enemy_mossback_brute/quake/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_enemy_mossback_brute/quake/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_enemy_drill_mole/burrow/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_enemy_drill_mole/burrow/raw-sheet.png --force
```

Expected: each directory contains `raw-sheet.png`.

- [ ] **Step 2: Process sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_enemy_terra_grunt/attack/raw-sheet.png --target enemy --mode animated --output-dir assets/generated/stage08_enemy_terra_grunt/attack --rows 2 --cols 3 --label-prefix enemy_terra_grunt --align bottom --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_enemy_mossback_brute/quake/raw-sheet.png --target enemy --mode animated --output-dir assets/generated/stage08_enemy_mossback_brute/quake --rows 3 --cols 3 --label-prefix enemy_mossback_brute --align bottom --shared-scale --component-mode largest --fit-scale 0.84 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_enemy_drill_mole/burrow/raw-sheet.png --target enemy --mode animated --output-dir assets/generated/stage08_enemy_drill_mole/burrow --rows 3 --cols 3 --label-prefix enemy_drill_mole --align bottom --shared-scale --component-mode largest --fit-scale 0.86 --reject-edge-touch
```

Expected: each command succeeds and writes `sheet-transparent.png`, frames, GIF, and `pipeline-meta.json` with no rejected edge-touch frames.

- [ ] **Step 3: Copy runtime PNGs**

Run:

```powershell
Copy-Item assets/generated/stage08_enemy_terra_grunt/attack/sheet-transparent.png characters/enemies/stage_08/enemy_terra_grunt.png -Force
Copy-Item assets/generated/stage08_enemy_mossback_brute/quake/sheet-transparent.png characters/enemies/stage_08/enemy_mossback_brute.png -Force
Copy-Item assets/generated/stage08_enemy_drill_mole/burrow/sheet-transparent.png characters/enemies/stage_08/enemy_drill_mole.png -Force
```

- [ ] **Step 4: QC visual output**

Open or inspect:

```powershell
Get-Item assets/generated/stage08_enemy_terra_grunt/attack/animation.gif, assets/generated/stage08_enemy_mossback_brute/quake/animation.gif, assets/generated/stage08_enemy_drill_mole/burrow/animation.gif
```

Expected: `enemy_terra_grunt` reads as common stone soldier, `enemy_mossback_brute` reads as heavy walker with no wide quake wave in body sheet, and `enemy_drill_mole` reads as robotic mole/drill with no cropped drill tip.

- [ ] **Step 5: Commit ground enemies**

Run:

```powershell
git add assets/generated/stage08_enemy_terra_grunt assets/generated/stage08_enemy_mossback_brute assets/generated/stage08_enemy_drill_mole characters/enemies/stage_08/enemy_terra_grunt.png characters/enemies/stage_08/enemy_mossback_brute.png characters/enemies/stage_08/enemy_drill_mole.png
git commit -m "feat: add stage 08 ground enemy sprites"
```

---

### Task 3: Fly And Suspended Enemy Sprite Sheets

**Files:**
- Create/modify: `assets/generated/stage08_enemy_gem_wasp/shoot/`
- Create/modify: `assets/generated/stage08_enemy_stone_glider/glide/`
- Create/modify: `assets/generated/stage08_enemy_ore_orbiter/shoot/`
- Create: `characters/enemies/stage_08/enemy_gem_wasp.png`
- Create: `characters/enemies/stage_08/enemy_stone_glider.png`
- Create: `characters/enemies/stage_08/enemy_ore_orbiter.png`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_enemy_gem_wasp/shoot/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_enemy_gem_wasp/shoot/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_enemy_stone_glider/glide/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_enemy_stone_glider/glide/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_enemy_ore_orbiter/shoot/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_enemy_ore_orbiter/shoot/raw-sheet.png --force
```

- [ ] **Step 2: Process sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_enemy_gem_wasp/shoot/raw-sheet.png --target enemy --mode animated --output-dir assets/generated/stage08_enemy_gem_wasp/shoot --rows 3 --cols 3 --label-prefix enemy_gem_wasp --align center --shared-scale --component-mode largest --fit-scale 0.84 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_enemy_stone_glider/glide/raw-sheet.png --target enemy --mode animated --output-dir assets/generated/stage08_enemy_stone_glider/glide --rows 2 --cols 3 --label-prefix enemy_stone_glider --align center --shared-scale --component-mode largest --fit-scale 0.82 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_enemy_ore_orbiter/shoot/raw-sheet.png --target enemy --mode animated --output-dir assets/generated/stage08_enemy_ore_orbiter/shoot --rows 2 --cols 3 --label-prefix enemy_ore_orbiter --align center --shared-scale --component-mode largest --fit-scale 0.86 --reject-edge-touch
```

- [ ] **Step 3: Copy runtime PNGs**

Run:

```powershell
Copy-Item assets/generated/stage08_enemy_gem_wasp/shoot/sheet-transparent.png characters/enemies/stage_08/enemy_gem_wasp.png -Force
Copy-Item assets/generated/stage08_enemy_stone_glider/glide/sheet-transparent.png characters/enemies/stage_08/enemy_stone_glider.png -Force
Copy-Item assets/generated/stage08_enemy_ore_orbiter/shoot/sheet-transparent.png characters/enemies/stage_08/enemy_ore_orbiter.png -Force
```

- [ ] **Step 4: QC visual output**

Inspect the three GIFs:

```powershell
Get-Item assets/generated/stage08_enemy_gem_wasp/shoot/animation.gif, assets/generated/stage08_enemy_stone_glider/glide/animation.gif, assets/generated/stage08_enemy_ore_orbiter/shoot/animation.gif
```

Expected: wasp reads as mineral insect, glider reads as fossil/stone cave flyer, and orbiter reads as mineral machinery without purple gravity language.

- [ ] **Step 5: Commit fly/suspended enemies**

Run:

```powershell
git add assets/generated/stage08_enemy_gem_wasp assets/generated/stage08_enemy_stone_glider assets/generated/stage08_enemy_ore_orbiter characters/enemies/stage_08/enemy_gem_wasp.png characters/enemies/stage_08/enemy_stone_glider.png characters/enemies/stage_08/enemy_ore_orbiter.png
git commit -m "feat: add stage 08 suspended enemy sprites"
```

---

### Task 4: Static, Ranged, And Trap Sprite Sheets

**Files:**
- Create/modify: `assets/generated/stage08_enemy_root_snare/grab/`
- Create/modify: `assets/generated/stage08_enemy_boulder_turret/shoot/`
- Create/modify: `assets/generated/stage08_enemy_fossil_totem/pulse/`
- Create: `characters/enemies/stage_08/enemy_root_snare.png`
- Create: `characters/enemies/stage_08/enemy_boulder_turret.png`
- Create: `characters/enemies/stage_08/enemy_fossil_totem.png`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_enemy_root_snare/grab/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_enemy_root_snare/grab/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_enemy_boulder_turret/shoot/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_enemy_boulder_turret/shoot/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_enemy_fossil_totem/pulse/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_enemy_fossil_totem/pulse/raw-sheet.png --force
```

- [ ] **Step 2: Process sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_enemy_root_snare/grab/raw-sheet.png --target enemy --mode animated --output-dir assets/generated/stage08_enemy_root_snare/grab --rows 3 --cols 3 --label-prefix enemy_root_snare --align bottom --shared-scale --component-mode largest --fit-scale 0.84 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_enemy_boulder_turret/shoot/raw-sheet.png --target enemy --mode animated --output-dir assets/generated/stage08_enemy_boulder_turret/shoot --rows 2 --cols 2 --label-prefix enemy_boulder_turret --align bottom --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_enemy_fossil_totem/pulse/raw-sheet.png --target enemy --mode animated --output-dir assets/generated/stage08_enemy_fossil_totem/pulse --rows 2 --cols 3 --label-prefix enemy_fossil_totem --align bottom --shared-scale --component-mode largest --fit-scale 0.86 --reject-edge-touch
```

- [ ] **Step 3: Copy runtime PNGs**

Run:

```powershell
Copy-Item assets/generated/stage08_enemy_root_snare/grab/sheet-transparent.png characters/enemies/stage_08/enemy_root_snare.png -Force
Copy-Item assets/generated/stage08_enemy_boulder_turret/shoot/sheet-transparent.png characters/enemies/stage_08/enemy_boulder_turret.png -Force
Copy-Item assets/generated/stage08_enemy_fossil_totem/pulse/sheet-transparent.png characters/enemies/stage_08/enemy_fossil_totem.png -Force
```

- [ ] **Step 4: QC visual output**

Inspect the three GIFs:

```powershell
Get-Item assets/generated/stage08_enemy_root_snare/grab/animation.gif, assets/generated/stage08_enemy_boulder_turret/shoot/animation.gif, assets/generated/stage08_enemy_fossil_totem/pulse/animation.gif
```

Expected: root snare communicates ground trap without player/tether, turret reads as fixed stone cannon, and fossil totem reads as old organic ruin pylon with no wide quake effect in body sheet.

- [ ] **Step 5: Commit static/ranged/trap enemies**

Run:

```powershell
git add assets/generated/stage08_enemy_root_snare assets/generated/stage08_enemy_boulder_turret assets/generated/stage08_enemy_fossil_totem characters/enemies/stage_08/enemy_root_snare.png characters/enemies/stage_08/enemy_boulder_turret.png characters/enemies/stage_08/enemy_fossil_totem.png
git commit -m "feat: add stage 08 static enemy sprites"
```

---

### Task 5: Projectile And FX Sprite Sheets

**Files:**
- Create/modify: `assets/generated/stage08_stone_shot/projectile/`
- Create/modify: `assets/generated/stage08_ore_shard/projectile/`
- Create/modify: `assets/generated/stage08_root_bind/projectile/`
- Create/modify: `assets/generated/stage08_quake_wave/projectile/`
- Create: `characters/enemies/stage_08/stone_shot.png`
- Create: `characters/enemies/stage_08/ore_shard.png`
- Create: `characters/enemies/stage_08/root_bind.png`
- Create: `characters/enemies/stage_08/quake_wave.png`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_stone_shot/projectile/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_stone_shot/projectile/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_ore_shard/projectile/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_ore_shard/projectile/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_root_bind/projectile/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_root_bind/projectile/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/stage08_quake_wave/projectile/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/stage08_quake_wave/projectile/raw-sheet.png --force
```

- [ ] **Step 2: Process projectile and FX sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_stone_shot/projectile/raw-sheet.png --target projectile --mode animated --output-dir assets/generated/stage08_stone_shot/projectile --rows 2 --cols 2 --label-prefix stone_shot --align center --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_ore_shard/projectile/raw-sheet.png --target projectile --mode animated --output-dir assets/generated/stage08_ore_shard/projectile --rows 2 --cols 2 --label-prefix ore_shard --align center --shared-scale --component-mode largest --fit-scale 0.88 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_root_bind/projectile/raw-sheet.png --target fx --mode animated --output-dir assets/generated/stage08_root_bind/projectile --rows 2 --cols 2 --label-prefix root_bind --align center --shared-scale --component-mode all --fit-scale 0.82 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage08_quake_wave/projectile/raw-sheet.png --target fx --mode animated --output-dir assets/generated/stage08_quake_wave/projectile --rows 2 --cols 2 --label-prefix quake_wave --align bottom --shared-scale --component-mode all --fit-scale 0.80 --reject-edge-touch
```

- [ ] **Step 3: Copy runtime PNGs**

Run:

```powershell
Copy-Item assets/generated/stage08_stone_shot/projectile/sheet-transparent.png characters/enemies/stage_08/stone_shot.png -Force
Copy-Item assets/generated/stage08_ore_shard/projectile/sheet-transparent.png characters/enemies/stage_08/ore_shard.png -Force
Copy-Item assets/generated/stage08_root_bind/projectile/sheet-transparent.png characters/enemies/stage_08/root_bind.png -Force
Copy-Item assets/generated/stage08_quake_wave/projectile/sheet-transparent.png characters/enemies/stage_08/quake_wave.png -Force
```

- [ ] **Step 4: QC projectile and FX output**

Inspect:

```powershell
Get-Item assets/generated/stage08_stone_shot/projectile/animation.gif, assets/generated/stage08_ore_shard/projectile/animation.gif, assets/generated/stage08_root_bind/projectile/animation.gif, assets/generated/stage08_quake_wave/projectile/animation.gif
```

Expected: `stone_shot` reads as physical rock, `ore_shard` reads as amber mineral not ice/fire, `root_bind` reads as compact root trap, and `quake_wave` reads as low ground wave with no edge cropping.

- [ ] **Step 5: Commit projectiles and FX**

Run:

```powershell
git add assets/generated/stage08_stone_shot assets/generated/stage08_ore_shard assets/generated/stage08_root_bind assets/generated/stage08_quake_wave characters/enemies/stage_08/stone_shot.png characters/enemies/stage_08/ore_shard.png characters/enemies/stage_08/root_bind.png characters/enemies/stage_08/quake_wave.png
git commit -m "feat: add stage 08 enemy projectile sprites"
```

---

### Task 6: Godot Imports And Final Verification

**Files:**
- Create: `characters/enemies/stage_08/*.png.import`
- Verify: `assets/generated/stage08_*/**/pipeline-meta.json`

- [ ] **Step 1: Run Godot import**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
```

Expected: Godot imports the 13 runtime PNGs and creates `.png.import` sidecars under `characters/enemies/stage_08/`, or creates temporary sidecars that can be replaced with the manual template from Common Commands.

- [ ] **Step 2: Verify runtime files exist**

Run:

```powershell
Get-Item characters/enemies/stage_08/enemy_terra_grunt.png, characters/enemies/stage_08/enemy_mossback_brute.png, characters/enemies/stage_08/enemy_drill_mole.png, characters/enemies/stage_08/enemy_gem_wasp.png, characters/enemies/stage_08/enemy_stone_glider.png, characters/enemies/stage_08/enemy_ore_orbiter.png, characters/enemies/stage_08/enemy_root_snare.png, characters/enemies/stage_08/enemy_boulder_turret.png, characters/enemies/stage_08/enemy_fossil_totem.png, characters/enemies/stage_08/stone_shot.png, characters/enemies/stage_08/ore_shard.png, characters/enemies/stage_08/root_bind.png, characters/enemies/stage_08/quake_wave.png
Get-Item characters/enemies/stage_08/*.png.import
```

Expected: 13 PNGs and 13 `.png.import` files are present.

- [ ] **Step 3: Verify no generated edge-touch failures remain**

Run:

```powershell
rg -n '"edge_touch_frames": \[[^]]+\]' assets/generated/stage08_*/**/pipeline-meta.json
```

Expected: no output. If there is output, regenerate or reprocess the affected sheet before committing.

- [ ] **Step 4: Verify git scope**

Run:

```powershell
git status --short
```

Expected: only Stage08 generated assets, Stage08 runtime PNG/imports, and this plan/spec work appear.

- [ ] **Step 5: Commit imports and verification fixes**

Run:

```powershell
git add characters/enemies/stage_08/*.png.import
git commit -m "chore: import stage 08 enemy sprites"
```

Expected: commit records only `.png.import` files unless a prior QC fix was required.

