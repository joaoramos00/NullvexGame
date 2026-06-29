# Stage 07 Luxar Enemy Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, process, import, QC, and commit 9 Stage 07 Luxar enemy sprite sheets plus 4 separate projectile/FX sheets.

**Architecture:** Each enemy or projectile is generated as its own raw sheet under `assets/generated/stage07_*`, then postprocessed with `generate2dsprite.py` into transparent sheets, frames, GIFs, and metadata. Runtime-ready PNGs are copied to `characters/enemies/stage_07/`, import sidecars are created consistently with the existing Godot texture import pattern, and work is committed in small batches.

**Tech Stack:** Godot 4.6.2, PowerShell, built-in image generation or CLI fallback through the `imagegen` skill, `generate2dsprite.py` for deterministic chroma-key processing and QC metadata, Git.

---

## Source Context

- Spec: `docs/superpowers/specs/2026-06-19-stage07-luxar-enemies-sprite-design.md`
- Boss: Luxar, solar lion reploid with white mane, gold rays, blue/gold armor, horizontal light beams
- Stage theme: light, reflection, crystal temple, celestial clearing, optical mechanisms
- Runtime output folder: `characters/enemies/stage_07/`
- Generated output prefix: `assets/generated/stage07_`
- Required final roster:
  - Ground/melee: `enemy_solar_guard`, `enemy_mirror_ram`, `enemy_lion_cub_runner`
  - Suspended/fly/hazard: `enemy_glasswing_drone`, `enemy_prism_orbiter`, `enemy_mirror_moth`, `enemy_sun_grabber`
  - Static/ranged: `enemy_radiant_pylon`, `enemy_beam_turret`
  - Projectiles/FX: `light_bolt`, `prism_shard`, `flash_pulse`, `solar_slash`

## Shared Rules

- Work from `D:\SnesGame\.worktrees\stage07-enemies`.
- Keep every raw sheet on solid `#FF00FF` background.
- Use separate raw sheets for each enemy and projectile.
- Use `--shared-scale` and `--reject-edge-touch` for every processed sheet.
- Use `--component-mode largest` for enemy body sheets.
- Use `--component-mode largest` for compact projectiles unless visual QC shows detached shard/ring/slash components were incorrectly removed; then reprocess that projectile with `--component-mode all`.
- Stage 07 visuals must look like light/reflection/temple optics, not Stage 03 electricity or Stage 02 ice.
- If processing reports edge-touch frames, inspect `raw-sheet.png`, strengthen containment in `prompt-used.txt`, regenerate, and reprocess.
- Do not commit `.png.import` files created inside `assets/generated`; only commit generated source PNG/GIF/metadata plus runtime `.png.import` files under `characters/enemies/stage_07/`.

## Common Commands

Load the API key for CLI fallback:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
```

Generate with CLI fallback:

```powershell
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file <prompt-file> --size <size> --quality medium --out <raw-output> --force
```

Process with `generate2dsprite.py`:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input <raw-sheet> --target <target> --mode <mode> --output-dir <output-dir> --rows <rows> --cols <cols> --label-prefix <label> --align <align> --shared-scale --component-mode largest --fit-scale <scale> --reject-edge-touch
```

Create runtime `.png.import` sidecars after copying PNGs:

```powershell
$files = @('<asset_name_1>', '<asset_name_2>')
foreach ($name in $files) {
  $res = "res://characters/enemies/stage_07/$name.png"
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $hash = (($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res)) | ForEach-Object { $_.ToString('x2') }) -join '')
  $uid = "uid://s07" + ($name.Replace("_",""))
  if ($uid.Length -gt 28) { $uid = $uid.Substring(0, 28) }
  $content = @"
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
"@
  Set-Content -LiteralPath "characters/enemies/stage_07/$name.png.import" -Value $content -Encoding UTF8
}
```

---

### Task 1: Prompt Files

**Files:**
- Create: `characters/enemies/stage_07/.gitkeep`
- Create one `prompt-used.txt` under each generated output directory listed below.

- [ ] **Step 1: Create output directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  characters/enemies/stage_07, `
  assets/generated/stage07_enemy_solar_guard/shield, `
  assets/generated/stage07_enemy_mirror_ram/charge, `
  assets/generated/stage07_enemy_lion_cub_runner/pounce, `
  assets/generated/stage07_enemy_glasswing_drone/dive, `
  assets/generated/stage07_enemy_prism_orbiter/shoot, `
  assets/generated/stage07_enemy_mirror_moth/flash, `
  assets/generated/stage07_enemy_sun_grabber/grab, `
  assets/generated/stage07_enemy_radiant_pylon/pulse, `
  assets/generated/stage07_enemy_beam_turret/shoot, `
  assets/generated/stage07_light_bolt/projectile, `
  assets/generated/stage07_prism_shard/projectile, `
  assets/generated/stage07_flash_pulse/projectile, `
  assets/generated/stage07_solar_slash/projectile
New-Item -ItemType File -Force characters/enemies/stage_07/.gitkeep
```

- [ ] **Step 2: Write ground enemy prompts**

`assets/generated/stage07_enemy_solar_guard/shield/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_solar_guard, a compact temple sentinel reploid from Luxar's Stage 07 light domain. Visual design: upright ground guard, white and gold armor plates, blue crystal visor, circular shield-lens mounted on one arm, short spear or baton kept close to body, small solar crest, Mega Man X inspired silhouette with original IP identity. Motion: ready stance, step forward, shield-lens brightens, short shield bash or spear jab with compact attached light only, recoil, return guard. It must be a common guard, not a mini Luxar and not an electric knight. Same identity, same scale, centered body, stable feet/bottom anchor in every cell. Full body and weapon inside central 60% safe area with clear magenta margin around crest, shield, spear, glow, and feet. No limb, spear, shield, crest, glow, or armor crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage07_enemy_mirror_ram/charge/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_mirror_ram, a heavy walking quadruped mirror ram robot from Luxar's Stage 07 light temple. Visual design: robust four-legged mechanical ram, white stone-like armor, gold trim, mirrored silver plates, blue lens core, thick front horn-lenses, heavy piston legs, solar temple plating, not a natural animal and not a boss. Motion read left-to-right: heavy idle, slow walk step, lowers head, horn-lenses charge bright gold light, short reflective charge pose, compact impact pose with attached light flash only, brakes, recoils backward, returns heavy idle. It must feel heavy and predictable, not fast like a cub runner. Same identity, same scale, centered body, stable bottom anchor in grounded frames. Full body inside central 60% safe area, no horn, leg, mirror plate, flash, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage07_enemy_lion_cub_runner/pounce/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_lion_cub_runner, a small fast robotic solar lion cub enemy from Luxar's Stage 07 light domain. Visual design: low compact mechanical feline, small gold-white mane plates, blue eye visor, spring paws, short tail fin, bright but contained solar chest core, clearly much smaller and less regal than Luxar. Motion read left-to-right: crouched ready, paws tense, mane plates flare, short run step, pounce forward pose, compact landing with attached spark only, recoil crouch, reset, return ready. It must read as a small common robot cub, not a full lion boss and not a heavy ram. Same identity, same scale, centered body, stable bottom anchor in grounded frames. Full body inside central 60% safe area, no mane plate, paw, tail, spark, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 3: Write suspended/flying enemy prompts**

`assets/generated/stage07_enemy_glasswing_drone/dive/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_glasswing_drone, a compact stained-glass wing patrol drone from Luxar's Stage 07 crystal light temple. Visual design: small mechanical drone body, translucent blue-white glass wings, gold frame struts, white armor core, blue lens eye, tiny solar crest, no feathers and no electric hazard stripes. Motion read left-to-right: hover patrol, glass wings tilt, lens brightens, dive windup, short dive pose, attack pass, pull up, stabilize hover, return patrol. Keep dive motion compact inside each cell and do not include detached projectile. Same identity, same scale, centered body. Full subject inside central 60% safe area, no wing tip, crest, tail, shine, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage07_enemy_prism_orbiter/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_prism_orbiter, a small floating optical refraction core machine from Luxar's Stage 07 light temple. Visual design: central blue-white lens core, gold segmented shell, tiny compact prism satellites kept close to body, white stone armor tabs, radiant but readable outline, not an ice wisp and not an electric orbiter. Motion: hover idle, prism satellites rotate, lens focuses, shoot pose with compact attached muzzle glow only, recoil tilt, return hover. Do not include detached projectile in the body sheet. Same identity, same scale, centered body in every cell. Full subject inside central 60% safe area, no prism, shell segment, lens glow, or emitter crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage07_enemy_mirror_moth/flash/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_mirror_moth, a small mechanical mirror moth hazard from Luxar's Stage 07 light temple. Visual design: compact insect-like drone, mirrored silver and pale gold wings, blue glass panels, tiny mechanical body, white armor cap, lens eye, no natural fur and no butterfly softness. Motion read left-to-right: hover idle, mirror wings open, panels angle outward, lens charges, compact frontal flash pose, peak flash attached to body only, recoil, wings close, return hover. Do not include a wide screen flash or detached projectile in the body sheet. Same identity, same scale, centered body in every cell. Full subject inside central 60% safe area, no wing, antenna, flash, glow, or shard crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage07_enemy_sun_grabber/grab/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_sun_grabber, a suspended light-trap grabber from Luxar's Stage 07 crystal temple. Visual design: compact floating solar core, white-gold shell, two or three short lens-claw arms kept close, blue crystal suction center, small halo fragments, mechanical clamps. Motion read left-to-right: dormant hover, lens claws open, core focuses, light arms curl inward, grab-ready pose, compact capture pose with attached golden ring only, recoil, claws close, return dormant. Do not show the player, do not include a long tether, and do not include a wide area effect in the body sheet. Same identity, same scale, centered body in every cell. Full subject inside central 60% safe area, no claw, arm, ring, halo, glow, or prism crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 4: Write static enemy prompts**

`assets/generated/stage07_enemy_radiant_pylon/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_radiant_pylon, a fixed radiant temple pylon that emits compact light pulses in Luxar's Stage 07. Visual design: low pedestal tower, white marble-like casing, gold trim, blue-white crystal or lens at the top, small halo ring fragments, clean angular base clamps, no ice frost and no electric coil. Motion: idle dim lens, shutters open, crystal brightens, compact attached pulse glow, recoil dim, return idle. Do not include wide area effect or detached projectile in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full pylon inside central 60% safe area, no crystal, halo, glow, trim, or base crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage07_enemy_beam_turret/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: enemy_beam_turret, a low fixed solar lens turret installed on Luxar's bright temple platforms. Visual design: squat angular turret body, white and gold armor panels, blue circular lens emitter, gold base clamps, small sunray crest near the barrel, no electric coils and no ice crystals. Motion: idle, internal lens focuses, shoot pose with compact attached muzzle light only, cooldown. Do not include detached projectile or wide beam in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full turret inside central 60% safe area, no muzzle light, barrel, crest, or base clamp crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 5: Write projectile prompts**

`assets/generated/stage07_light_bolt/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: light_bolt, a compact horizontal light projectile fired by Stage 07 Luxar enemies, travel direction left-to-right. Visual design: bright warm white core, gold compressed edge, tiny close blue-white glint trail, dense and compact, no lightning branches and no ice shard texture. Motion: stable bolt, brighter lens pulse, slightly stretched travel pulse, loop return. Same projectile identity and size in every frame, centered, compact glow. Projectile and glow stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage07_prism_shard/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: prism_shard, a compact sacred glass shard thrown by Luxar stage enemies, travel direction left-to-right. Visual design: pale gold and blue-white crystalline glass shard, sharp reflective facets, tiny close rainbow-white glint trail, physical glass object not an ice shard and not a rock. Motion: shard angle one, spinning glint, slight travel stretch, loop return. Same projectile identity and size in every frame, centered, compact trail. Shard and trail stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage07_flash_pulse/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: flash_pulse, a compact circular lens flash pulse from enemy_mirror_moth, enemy_sun_grabber, or enemy_radiant_pylon. Visual design: warm white and gold circular flash ring, small blue lens glints, subtle sunray notches, compact glow, no lightning, no explosion fire, no ice mist. Motion: small ring appears, ring brightens inward, peak compact lens flash, smaller complete return ring. Same effect identity and size in every frame, centered, compact glow. Every frame must contain a complete centered ring or starburst with visible gold outlines; no frame may be blank, faded into magenta, partial, off-center, tiny, or only residue. Pulse and glints stay fully inside central 55% safe area with strong contrast against the #FF00FF background. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage07_solar_slash/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: solar_slash, a short curved cutting arc of warm light from Luxar stage melee enemies. Visual design: compact crescent slash, white inner blade, gold trailing edge, tiny blue lens glints, sharp and compact, no electric sparks and no wind gust. Motion: small slash arc, brighter sweep, peak compact crescent, shorter return crescent. Same effect identity and size in every frame, centered, compact glow. No frame may be blank, tiny, only residue, or only detached streaks. Slash and trail stay fully inside central 55% safe area with wide magenta margin. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 6: Validate and commit prompt files**

Run:

```powershell
Get-ChildItem assets/generated -Recurse -Filter prompt-used.txt | Where-Object { $_.FullName -match 'stage07_' } | Measure-Object
git add characters/enemies/stage_07/.gitkeep assets/generated/stage07_enemy_solar_guard assets/generated/stage07_enemy_mirror_ram assets/generated/stage07_enemy_lion_cub_runner assets/generated/stage07_enemy_glasswing_drone assets/generated/stage07_enemy_prism_orbiter assets/generated/stage07_enemy_mirror_moth assets/generated/stage07_enemy_sun_grabber assets/generated/stage07_enemy_radiant_pylon assets/generated/stage07_enemy_beam_turret assets/generated/stage07_light_bolt assets/generated/stage07_prism_shard assets/generated/stage07_flash_pulse assets/generated/stage07_solar_slash
git commit -m "docs: add stage 07 luxar sprite prompts"
```

Expected: prompt count is 13.

---

### Task 2: Ground Enemy Sprites

**Files:**
- Create generated assets for `enemy_solar_guard`, `enemy_mirror_ram`, `enemy_lion_cub_runner`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_07/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_enemy_solar_guard\shield\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage07_enemy_solar_guard\shield\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_enemy_mirror_ram\charge\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage07_enemy_mirror_ram\charge\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_enemy_lion_cub_runner\pounce\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage07_enemy_lion_cub_runner\pounce\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_enemy_solar_guard/shield/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage07_enemy_solar_guard/shield --rows 2 --cols 3 --label-prefix shield --align bottom --shared-scale --component-mode largest --fit-scale 0.82 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_enemy_mirror_ram/charge/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage07_enemy_mirror_ram/charge --rows 3 --cols 3 --label-prefix charge --align bottom --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_enemy_lion_cub_runner/pounce/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage07_enemy_lion_cub_runner/pounce --rows 3 --cols 3 --label-prefix pounce --align bottom --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
```

- [ ] **Step 3: Validate metadata**

Run:

```powershell
Get-ChildItem assets/generated/stage07_enemy_solar_guard/shield, assets/generated/stage07_enemy_mirror_ram/charge, assets/generated/stage07_enemy_lion_cub_runner/pounce -Filter pipeline-meta.json -Recurse | ForEach-Object {
  $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
  [pscustomobject]@{Path=$_.FullName.Replace((Resolve-Path .).Path + '\',''); Rows=$json.rows; Cols=$json.cols; Frames=$json.frames.Count; EdgeTouch=$json.edge_touch_frames.Count; SharedScale=$json.shared_scale}
}
```

Expected: every row has `EdgeTouch=0` and `SharedScale=True`.

- [ ] **Step 4: Visual QC**

Pass criteria:
- `solar_guard` reads as a common white/gold temple guard with shield-lens.
- `mirror_ram` reads as a heavy walking quadruped ram, not a fast cub and not Luxar.
- `lion_cub_runner` reads as small fast mechanical cub, not a heavy ram.
- No sheet has white glow that erases the body silhouette.

- [ ] **Step 5: Copy runtime PNGs, create imports, and commit**

Run:

```powershell
Copy-Item assets/generated/stage07_enemy_solar_guard/shield/sheet-transparent.png characters/enemies/stage_07/enemy_solar_guard.png -Force
Copy-Item assets/generated/stage07_enemy_mirror_ram/charge/sheet-transparent.png characters/enemies/stage_07/enemy_mirror_ram.png -Force
Copy-Item assets/generated/stage07_enemy_lion_cub_runner/pounce/sheet-transparent.png characters/enemies/stage_07/enemy_lion_cub_runner.png -Force
$files = 'enemy_solar_guard','enemy_mirror_ram','enemy_lion_cub_runner'
foreach ($name in $files) {
  $res = "res://characters/enemies/stage_07/$name.png"
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $hash = (($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res)) | ForEach-Object { $_.ToString('x2') }) -join '')
  $uid = "uid://s07" + ($name.Replace("_",""))
  if ($uid.Length -gt 28) { $uid = $uid.Substring(0, 28) }
  $content = @"
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
"@
  Set-Content -LiteralPath "characters/enemies/stage_07/$name.png.import" -Value $content -Encoding UTF8
}
$generated = Get-ChildItem assets/generated/stage07_enemy_solar_guard, assets/generated/stage07_enemy_mirror_ram, assets/generated/stage07_enemy_lion_cub_runner -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_07/enemy_solar_guard.png characters/enemies/stage_07/enemy_solar_guard.png.import characters/enemies/stage_07/enemy_mirror_ram.png characters/enemies/stage_07/enemy_mirror_ram.png.import characters/enemies/stage_07/enemy_lion_cub_runner.png characters/enemies/stage_07/enemy_lion_cub_runner.png.import
git commit -m "feat: add stage 07 ground enemy sprites"
```

---

### Task 3: Suspended Enemy Sprites

**Files:**
- Create generated assets for `enemy_glasswing_drone`, `enemy_prism_orbiter`, `enemy_mirror_moth`, `enemy_sun_grabber`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_07/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_enemy_glasswing_drone\dive\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage07_enemy_glasswing_drone\dive\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_enemy_prism_orbiter\shoot\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage07_enemy_prism_orbiter\shoot\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_enemy_mirror_moth\flash\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage07_enemy_mirror_moth\flash\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_enemy_sun_grabber\grab\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage07_enemy_sun_grabber\grab\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_enemy_glasswing_drone/dive/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage07_enemy_glasswing_drone/dive --rows 3 --cols 3 --label-prefix dive --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_enemy_prism_orbiter/shoot/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage07_enemy_prism_orbiter/shoot --rows 2 --cols 3 --label-prefix shoot --align center --shared-scale --component-mode largest --fit-scale 0.82 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_enemy_mirror_moth/flash/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage07_enemy_mirror_moth/flash --rows 3 --cols 3 --label-prefix flash --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_enemy_sun_grabber/grab/raw-sheet.png --target asset --mode attack --output-dir assets/generated/stage07_enemy_sun_grabber/grab --rows 3 --cols 3 --label-prefix grab --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
```

- [ ] **Step 3: Validate metadata**

Run:

```powershell
Get-ChildItem assets/generated/stage07_enemy_glasswing_drone/dive, assets/generated/stage07_enemy_prism_orbiter/shoot, assets/generated/stage07_enemy_mirror_moth/flash, assets/generated/stage07_enemy_sun_grabber/grab -Filter pipeline-meta.json -Recurse | ForEach-Object {
  $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
  [pscustomobject]@{Path=$_.FullName.Replace((Resolve-Path .).Path + '\',''); Rows=$json.rows; Cols=$json.cols; Frames=$json.frames.Count; EdgeTouch=$json.edge_touch_frames.Count; SharedScale=$json.shared_scale}
}
```

Expected: every row has `EdgeTouch=0` and `SharedScale=True`.

- [ ] **Step 4: Visual QC**

Pass criteria:
- `glasswing_drone` reads as stained-glass drone, not electric bird.
- `prism_orbiter` reads as optical lens shooter, not ice wisp or electric orbiter.
- `mirror_moth` reads as mirror/flash hazard, not natural insect.
- `sun_grabber` reads as compact suspended grabber/trap with no player shown.

- [ ] **Step 5: Copy runtime PNGs, create imports, and commit**

Run:

```powershell
Copy-Item assets/generated/stage07_enemy_glasswing_drone/dive/sheet-transparent.png characters/enemies/stage_07/enemy_glasswing_drone.png -Force
Copy-Item assets/generated/stage07_enemy_prism_orbiter/shoot/sheet-transparent.png characters/enemies/stage_07/enemy_prism_orbiter.png -Force
Copy-Item assets/generated/stage07_enemy_mirror_moth/flash/sheet-transparent.png characters/enemies/stage_07/enemy_mirror_moth.png -Force
Copy-Item assets/generated/stage07_enemy_sun_grabber/grab/sheet-transparent.png characters/enemies/stage_07/enemy_sun_grabber.png -Force
$files = 'enemy_glasswing_drone','enemy_prism_orbiter','enemy_mirror_moth','enemy_sun_grabber'
foreach ($name in $files) {
  $res = "res://characters/enemies/stage_07/$name.png"
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $hash = (($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res)) | ForEach-Object { $_.ToString('x2') }) -join '')
  $uid = "uid://s07" + ($name.Replace("_",""))
  if ($uid.Length -gt 28) { $uid = $uid.Substring(0, 28) }
  $content = @"
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
"@
  Set-Content -LiteralPath "characters/enemies/stage_07/$name.png.import" -Value $content -Encoding UTF8
}
$generated = Get-ChildItem assets/generated/stage07_enemy_glasswing_drone, assets/generated/stage07_enemy_prism_orbiter, assets/generated/stage07_enemy_mirror_moth, assets/generated/stage07_enemy_sun_grabber -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_07/enemy_glasswing_drone.png characters/enemies/stage_07/enemy_glasswing_drone.png.import characters/enemies/stage_07/enemy_prism_orbiter.png characters/enemies/stage_07/enemy_prism_orbiter.png.import characters/enemies/stage_07/enemy_mirror_moth.png characters/enemies/stage_07/enemy_mirror_moth.png.import characters/enemies/stage_07/enemy_sun_grabber.png characters/enemies/stage_07/enemy_sun_grabber.png.import
git commit -m "feat: add stage 07 suspended enemy sprites"
```

---

### Task 4: Static Enemy Sprites

**Files:**
- Create generated assets for `enemy_radiant_pylon`, `enemy_beam_turret`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_07/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_enemy_radiant_pylon\pulse\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage07_enemy_radiant_pylon\pulse\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_enemy_beam_turret\shoot\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage07_enemy_beam_turret\shoot\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_enemy_radiant_pylon/pulse/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage07_enemy_radiant_pylon/pulse --rows 2 --cols 3 --label-prefix pulse --align bottom --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_enemy_beam_turret/shoot/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage07_enemy_beam_turret/shoot --rows 2 --cols 2 --label-prefix shoot --align bottom --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
```

- [ ] **Step 3: Visual QC**

Pass criteria:
- `radiant_pylon` reads as fixed radiant temple pylon, not ice crystal.
- `beam_turret` reads as low solar lens turret, not electric coil cannon.

- [ ] **Step 4: Copy runtime PNGs, create imports, and commit**

Run:

```powershell
Copy-Item assets/generated/stage07_enemy_radiant_pylon/pulse/sheet-transparent.png characters/enemies/stage_07/enemy_radiant_pylon.png -Force
Copy-Item assets/generated/stage07_enemy_beam_turret/shoot/sheet-transparent.png characters/enemies/stage_07/enemy_beam_turret.png -Force
$files = 'enemy_radiant_pylon','enemy_beam_turret'
foreach ($name in $files) {
  $res = "res://characters/enemies/stage_07/$name.png"
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $hash = (($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res)) | ForEach-Object { $_.ToString('x2') }) -join '')
  $uid = "uid://s07" + ($name.Replace("_",""))
  if ($uid.Length -gt 28) { $uid = $uid.Substring(0, 28) }
  $content = @"
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
"@
  Set-Content -LiteralPath "characters/enemies/stage_07/$name.png.import" -Value $content -Encoding UTF8
}
$generated = Get-ChildItem assets/generated/stage07_enemy_radiant_pylon, assets/generated/stage07_enemy_beam_turret -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_07/enemy_radiant_pylon.png characters/enemies/stage_07/enemy_radiant_pylon.png.import characters/enemies/stage_07/enemy_beam_turret.png characters/enemies/stage_07/enemy_beam_turret.png.import
git commit -m "feat: add stage 07 static enemy sprites"
```

---

### Task 5: Projectile And FX Sprites

**Files:**
- Create generated assets for `light_bolt`, `prism_shard`, `flash_pulse`, `solar_slash`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_07/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_light_bolt\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage07_light_bolt\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_prism_shard\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage07_prism_shard\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_flash_pulse\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage07_flash_pulse\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage07_solar_slash\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage07_solar_slash\projectile\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_light_bolt/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage07_light_bolt/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_prism_shard/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage07_prism_shard/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_flash_pulse/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage07_flash_pulse/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage07_solar_slash/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage07_solar_slash/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
```

- [ ] **Step 3: Visual QC**

Pass criteria:
- `light_bolt` reads as compact horizontal light shot and not electric lightning.
- `prism_shard` reads as sacred glass shard and not an ice shard.
- `flash_pulse` reads as complete lens flash in all frames; no frame can be blank, partial, off-center, or only residue.
- `solar_slash` reads as compact warm light crescent and not wind/electricity.

- [ ] **Step 4: Copy runtime PNGs, create imports, and commit**

Run:

```powershell
Copy-Item assets/generated/stage07_light_bolt/projectile/sheet-transparent.png characters/enemies/stage_07/light_bolt.png -Force
Copy-Item assets/generated/stage07_prism_shard/projectile/sheet-transparent.png characters/enemies/stage_07/prism_shard.png -Force
Copy-Item assets/generated/stage07_flash_pulse/projectile/sheet-transparent.png characters/enemies/stage_07/flash_pulse.png -Force
Copy-Item assets/generated/stage07_solar_slash/projectile/sheet-transparent.png characters/enemies/stage_07/solar_slash.png -Force
$files = 'light_bolt','prism_shard','flash_pulse','solar_slash'
foreach ($name in $files) {
  $res = "res://characters/enemies/stage_07/$name.png"
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $hash = (($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res)) | ForEach-Object { $_.ToString('x2') }) -join '')
  $uid = "uid://s07" + ($name.Replace("_",""))
  if ($uid.Length -gt 28) { $uid = $uid.Substring(0, 28) }
  $content = @"
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
"@
  Set-Content -LiteralPath "characters/enemies/stage_07/$name.png.import" -Value $content -Encoding UTF8
}
$generated = Get-ChildItem assets/generated/stage07_light_bolt, assets/generated/stage07_prism_shard, assets/generated/stage07_flash_pulse, assets/generated/stage07_solar_slash -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_07/light_bolt.png characters/enemies/stage_07/light_bolt.png.import characters/enemies/stage_07/prism_shard.png characters/enemies/stage_07/prism_shard.png.import characters/enemies/stage_07/flash_pulse.png characters/enemies/stage_07/flash_pulse.png.import characters/enemies/stage_07/solar_slash.png characters/enemies/stage_07/solar_slash.png.import
git commit -m "feat: add stage 07 enemy projectile sprites"
```

---

### Task 6: Final QC

**Files:**
- Verify all files created by Tasks 1-5.

- [ ] **Step 1: Validate runtime outputs**

Run:

```powershell
$files = @(
  'enemy_solar_guard',
  'enemy_mirror_ram',
  'enemy_lion_cub_runner',
  'enemy_glasswing_drone',
  'enemy_prism_orbiter',
  'enemy_mirror_moth',
  'enemy_sun_grabber',
  'enemy_radiant_pylon',
  'enemy_beam_turret',
  'light_bolt',
  'prism_shard',
  'flash_pulse',
  'solar_slash'
)
foreach ($name in $files) {
  $png = "characters/enemies/stage_07/$name.png"
  $imp = "$png.import"
  [pscustomobject]@{Name=$name; Png=(Test-Path $png); Import=(Test-Path $imp)}
}
```

Expected: all rows show `Png=True` and `Import=True`.

- [ ] **Step 2: Validate metadata edge-touch**

Run:

```powershell
$metas = Get-ChildItem assets/generated -Recurse -Filter pipeline-meta.json | Where-Object { $_.FullName -match 'stage07_' }
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
$files = @('enemy_solar_guard','enemy_mirror_ram','enemy_lion_cub_runner','enemy_glasswing_drone','enemy_prism_orbiter','enemy_mirror_moth','enemy_sun_grabber','enemy_radiant_pylon','enemy_beam_turret','light_bolt','prism_shard','flash_pulse','solar_slash')
foreach ($name in $files) {
  $path = (Resolve-Path "characters/enemies/stage_07/$name.png").Path
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
git status --short -- assets/generated/stage07_* characters/enemies/stage_07 docs/superpowers
git log --oneline -8
```

Expected: no uncommitted Stage 07 sprite files remain except untracked `.png.import` files under `assets/generated`, which must not be committed. Recent commits include spec, plan, prompts, and sprite batches.

- [ ] **Step 5: Final visual checklist**

Inspect final runtime sheets:

```powershell
characters/enemies/stage_07/enemy_solar_guard.png
characters/enemies/stage_07/enemy_mirror_ram.png
characters/enemies/stage_07/enemy_lion_cub_runner.png
characters/enemies/stage_07/enemy_glasswing_drone.png
characters/enemies/stage_07/enemy_prism_orbiter.png
characters/enemies/stage_07/enemy_mirror_moth.png
characters/enemies/stage_07/enemy_sun_grabber.png
characters/enemies/stage_07/enemy_radiant_pylon.png
characters/enemies/stage_07/enemy_beam_turret.png
characters/enemies/stage_07/light_bolt.png
characters/enemies/stage_07/prism_shard.png
characters/enemies/stage_07/flash_pulse.png
characters/enemies/stage_07/solar_slash.png
```

Pass criteria:
- Luxar/light/solar-lion/optical-temple theme is visible across the set.
- The set feels like light, reflection, prism, temple and celestial gold, not Stage 03 electricity or Stage 02 ice.
- Ground enemies clearly communicate guard, heavy ram, and fast cub roles.
- Suspended enemies clearly communicate drone, shooter, flash hazard, and grabber roles.
- Static enemies clearly communicate radiant pylon and beam turret.
- The four projectiles are distinct.
- No body sheet relies on wide detached FX.
