# Stage 06 Umbraex Enemy Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, process, import, QC, and commit 9 Stage 06 Umbraex enemy sprite sheets plus 4 separate projectile/FX sheets.

**Architecture:** Each enemy or projectile is generated as its own raw sheet under `assets/generated/stage06_*`, then postprocessed with `generate2dsprite.py` into transparent sheets, frames, GIFs, and metadata. Runtime-ready PNGs are copied to `characters/enemies/stage_06/`, import sidecars are created consistently with the existing Godot texture import pattern, and work is committed in small batches.

**Tech Stack:** Godot 4.6.2, PowerShell, built-in image generation or CLI fallback through the `imagegen` skill, `generate2dsprite.py` for deterministic chroma-key processing and QC metadata, Git.

---

## Source Context

- Spec: `docs/superpowers/specs/2026-06-19-stage06-umbraex-enemies-sprite-design.md`
- Boss: Umbraex, reploid sombrio com linguagem de morcego/chifres, teleporte e projeteis roxos em leque
- Stage theme: sombra, eclipse, penumbra, teleporte curto, emboscada e tecnologia que apaga luz
- Runtime output folder: `characters/enemies/stage_06/`
- Generated output prefix: `assets/generated/stage06_`
- Required final roster:
  - Ground/melee: `enemy_shadow_stalker`, `enemy_eclipse_duelist`, `enemy_night_pouncer`
  - Suspended/fly/hazard: `enemy_umbra_bat`, `enemy_void_orbiter`, `enemy_shadow_snare`, `enemy_phase_mine`
  - Static/ranged: `enemy_dark_lantern`, `enemy_eclipse_turret`
  - Projectiles/FX: `shadow_bolt`, `void_shard`, `snare_pulse`, `phase_slash`

## Shared Rules

- Work from `D:\SnesGame\.worktrees\stage06-enemies`.
- Keep every raw sheet on solid `#FF00FF` background.
- Use separate raw sheets for each enemy and projectile.
- Use `--shared-scale` and `--reject-edge-touch` for every processed sheet.
- Use `--component-mode largest` for enemy body sheets.
- Use `--component-mode largest` for compact projectiles unless visual QC shows detached shard/ring/slash components were incorrectly removed; then reprocess that projectile with `--component-mode all`.
- If processing reports edge-touch frames, inspect `raw-sheet.png`, strengthen containment in `prompt-used.txt`, regenerate, and reprocess.
- If Godot `--headless --import` creates only temporary `.import*.tmp` files, either rename validated temporary sidecars or create final `.png.import` sidecars using the standard texture template and MD5 of `res://characters/enemies/stage_06/<file>.png`.
- Do not commit `.png.import` files created inside `assets/generated`; only commit generated source PNG/GIF/metadata plus runtime `.png.import` files under `characters/enemies/stage_06/`.

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
$res = "res://characters/enemies/stage_06/$name.png"
$md5 = [System.Security.Cryptography.MD5]::Create()
$hash = (($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res)) | ForEach-Object { $_.ToString('x2') }) -join '')
$uid = "uid://stage06$name".Replace("_","").Substring(0, [Math]::Min(22, "uid://stage06$name".Replace("_","").Length))
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
"@ | Set-Content "characters/enemies/stage_06/$name.png.import" -Encoding UTF8
```

---

### Task 1: Prompt Files

**Files:**
- Create: `characters/enemies/stage_06/.gitkeep`
- Create one `prompt-used.txt` under each generated output directory listed below.

- [ ] **Step 1: Create output directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  characters/enemies/stage_06, `
  assets/generated/stage06_enemy_shadow_stalker/slash, `
  assets/generated/stage06_enemy_eclipse_duelist/slash, `
  assets/generated/stage06_enemy_night_pouncer/pounce, `
  assets/generated/stage06_enemy_umbra_bat/dive, `
  assets/generated/stage06_enemy_void_orbiter/shoot, `
  assets/generated/stage06_enemy_shadow_snare/grab, `
  assets/generated/stage06_enemy_phase_mine/pulse, `
  assets/generated/stage06_enemy_dark_lantern/pulse, `
  assets/generated/stage06_enemy_eclipse_turret/shoot, `
  assets/generated/stage06_shadow_bolt/projectile, `
  assets/generated/stage06_void_shard/projectile, `
  assets/generated/stage06_snare_pulse/projectile, `
  assets/generated/stage06_phase_slash/projectile
New-Item -ItemType File -Force characters/enemies/stage_06/.gitkeep
```

- [ ] **Step 2: Write ground enemy prompts**

`assets/generated/stage06_enemy_shadow_stalker/slash/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_shadow_stalker, a low crouched shadow assassin reploid from Umbraex's Stage 06 eclipse domain. Visual design: compact ground soldier, black and dark purple armor plates, violet visor, small horn-like helmet fins, claw gauntlets kept close to the body, subtle attached shadow smoke, Mega Man X inspired silhouette with original IP identity. Motion: low ready stance, creeping step, claws charge violet, short close slash pose with no detached slash arc, recoil, return crouch. It must be a ground troop, not a full bat and not a heavy unit. Same identity, same scale, centered body, stable feet/bottom anchor in every cell. Full body inside central 60% safe area with clear magenta margin around claws, helmet fins, smoke, and feet. No limb, claw, horn, smoke, glow, or armor crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage06_enemy_eclipse_duelist/slash/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_eclipse_duelist, an elegant dark reploid duelist guarding Umbraex's shadow stage. Visual design: slim upright assassin, black graphite armor, deep violet chest core, small eclipse halo motif on one shoulder, short dark blade or tonfa kept close to body, narrow horned visor, lilac highlights, no gold or bright sunlight. Motion: poised stance, blade lifts, core darkens, short close melee slash with no detached arc, recoil step, return guard. Same identity, same scale, centered body, stable feet/bottom anchor in every cell. Full body and weapon inside central 60% safe area, no blade tip, halo, glow, or smoke crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage06_enemy_night_pouncer/pounce/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_night_pouncer, a compact robotic nocturnal pouncer from Umbraex's shadow domain. Visual design: crouched mechanical predator, black purple armor, strong spring legs, small folded bat-like wing panels, short horn ears, violet eyes and chest core, compact attached shadow smoke. Motion read left-to-right: crouch idle, coils legs, wing panels twitch, core glows, short pounce pose, compact landing impact with attached smoke only, recoil crouch, reset, return idle. It must suggest robotic nocturnal fauna, not a natural animal and not a boss. Same identity, same scale, centered body, stable bottom anchor in grounded frames. Full body inside central 60% safe area, no wing, horn, foot, smoke, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 3: Write suspended/flying enemy prompts**

`assets/generated/stage06_enemy_umbra_bat/dive/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_umbra_bat, a compact mechanical bat patrol drone from Umbraex's Stage 06 shadow stage. Visual design: batlike robotic silhouette, angular black wings, violet core, small horned head, segmented gray joints, lilac edge glow, no natural fur and no full Umbraex body copy. Motion read left-to-right: hover patrol, wings tilt, core brightens, dive windup, short dive pose, attack pass, pull up, stabilize hover, return patrol. Keep dive motion compact inside each cell and do not include detached projectile. Same identity, same scale, centered body. Full subject inside central 60% safe area, no wing tip, horn, tail, smoke, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage06_enemy_void_orbiter/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_void_orbiter, a small floating shadow core machine from Umbraex's eclipse stage. Visual design: dark violet spherical core, black segmented shell, tiny compact shard satellites kept close to the body, single violet eye or emitter, smoke wisps attached close, not a gravity mine and not a bright electric drone. Motion: hover idle, shell segments rotate, core darkens, shoot pose with compact attached muzzle shadow only, recoil tilt, return hover. Do not include detached projectile in the body sheet. Same identity, same scale, centered body in every cell. Full subject inside central 60% safe area, no shard, smoke, glow, or emitter crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage06_enemy_shadow_snare/grab/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: enemy_shadow_snare, a suspended shadow trap that slows or restrains players in Umbraex's stage. Visual design: compact hovering eclipse core, black violet shell, two or three short claw hooks or ribbon-like shadow arms kept close, violet suction center, small bat-ear antennae, dark mechanical clamps. Motion read left-to-right: dormant hover, hooks open, core charges, shadow ribbons curl inward, grab-ready pose, compact capture pose with attached shadow ring only, recoil, hooks close, return dormant. Do not show the player, do not include a long tether, and do not include a wide area effect in the body sheet. Same identity, same scale, centered body in every cell. Full subject inside central 60% safe area, no hook, ribbon, ring, glow, or smoke crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage06_enemy_phase_mine/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_phase_mine, a compact shadow phase mine from Umbraex's eclipse stage. Visual design: small black segmented mine, violet core, crescent eclipse markings, faint attached transparency echo, tiny warning lights, not a heavy gravity mine. Motion: almost invisible phase state, solidifies, core charges, compact pulse glow attached to the mine, armed state, cooldown fade. Same identity, same scale, centered body in every cell. Full subject inside central 60% safe area, no halo, glow, segment, or phase echo crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 4: Write static enemy prompts**

`assets/generated/stage06_enemy_dark_lantern/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 3 columns, 6 equal cells. Subject: enemy_dark_lantern, a fixed black lantern pedestal that emits shadow pulses in Umbraex's stage. Visual design: low pedestal tower, black graphite casing, violet inverted flame or dark core inside a cage, crescent eclipse trim, small bat-like side fins, cold gray base clamps. Motion: idle dim core, cage shutters open, flame darkens, compact attached pulse glow, recoil dim, return idle. Do not include wide area effect or detached projectile in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full lantern inside central 60% safe area, no flame, fin, cage, glow, or base crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage06_enemy_eclipse_turret/shoot/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game enemy sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: enemy_eclipse_turret, a low fixed shadow cannon installed on Umbraex's dark platforms. Visual design: squat angular turret body, black and dark purple armor panels, violet circular shadow emitter, dark base clamps, crescent eclipse plate near the barrel, no bright gold and no electric coils. Motion: idle, internal emitter spins, shoot pose with compact attached muzzle shadow only, cooldown. Do not include detached projectile or wide blast in the body sheet. Same identity, same scale, stable base on bottom anchor in every cell. Full turret inside central 60% safe area, no muzzle shadow, barrel, crescent plate, or base clamp crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 5: Write projectile prompts**

`assets/generated/stage06_shadow_bolt/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: shadow_bolt, a compact horizontal shadow projectile fired by Stage 06 Umbraex enemies, travel direction left-to-right. Visual design: bright violet core, black purple compressed edge, tiny close smoky trail, dense and compact, no lightning and no green wind. Motion: stable bolt, darker pulse, slightly stretched travel pulse, loop return. Same projectile identity and size in every frame, centered, compact glow. Projectile and glow stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage06_void_shard/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game projectile sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: void_shard, a compact dark physical-energy shard thrown by Umbraex stage enemies, travel direction left-to-right. Visual design: black violet crystalline shard, lilac edge glint, tiny close shadow trail, physical jagged object not a rock and not an energy ball. Motion: shard angle one, spinning glint, slight travel stretch, loop return. Same projectile identity and size in every frame, centered, compact trail. Shard and trail stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage06_snare_pulse/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: snare_pulse, a compact circular shadow snare pulse from enemy_shadow_snare or enemy_dark_lantern. Visual design: violet black ring, small inward hook marks, subtle chain-like shadow segments, compact glow, no explosion fire, no lightning, no gravity debris. Motion: small ring appears, ring tightens inward, peak compact snare ring, loop fade. Same effect identity and size in every frame, centered, compact glow. Ring and hook marks stay fully inside central 60% safe area. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/stage06_phase_slash/projectile/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game FX sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: phase_slash, a short curved cutting arc of dark shadow from Umbraex stage melee enemies. Visual design: compact crescent slash, violet inner blade, black purple trailing edge, thin attached smoke streaks, sharp and compact, no electric sparks and no wind gust. Motion: small slash arc, brighter sweep, peak compact crescent, shorter return crescent. Same effect identity and size in every frame, centered, compact glow. No frame may be blank, tiny, only residue, or only detached streaks. Slash and trail stay fully inside central 55% safe area with wide magenta margin. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 6: Commit prompt files**

Run:

```powershell
git add characters/enemies/stage_06/.gitkeep assets/generated/stage06_enemy_shadow_stalker assets/generated/stage06_enemy_eclipse_duelist assets/generated/stage06_enemy_night_pouncer assets/generated/stage06_enemy_umbra_bat assets/generated/stage06_enemy_void_orbiter assets/generated/stage06_enemy_shadow_snare assets/generated/stage06_enemy_phase_mine assets/generated/stage06_enemy_dark_lantern assets/generated/stage06_enemy_eclipse_turret assets/generated/stage06_shadow_bolt assets/generated/stage06_void_shard assets/generated/stage06_snare_pulse assets/generated/stage06_phase_slash
git commit -m "docs: add stage 06 umbraex sprite prompts"
```

---

### Task 2: Ground Enemy Sprites

**Files:**
- Create generated assets for `enemy_shadow_stalker`, `enemy_eclipse_duelist`, `enemy_night_pouncer`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_06/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_enemy_shadow_stalker\slash\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage06_enemy_shadow_stalker\slash\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_enemy_eclipse_duelist\slash\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage06_enemy_eclipse_duelist\slash\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_enemy_night_pouncer\pounce\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage06_enemy_night_pouncer\pounce\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_enemy_shadow_stalker/slash/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage06_enemy_shadow_stalker/slash --rows 2 --cols 3 --label-prefix slash --align bottom --shared-scale --component-mode largest --fit-scale 0.82 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_enemy_eclipse_duelist/slash/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage06_enemy_eclipse_duelist/slash --rows 2 --cols 3 --label-prefix slash --align bottom --shared-scale --component-mode largest --fit-scale 0.82 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_enemy_night_pouncer/pounce/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage06_enemy_night_pouncer/pounce --rows 3 --cols 3 --label-prefix pounce --align bottom --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
```

- [ ] **Step 3: Validate metadata**

Run:

```powershell
Get-ChildItem assets/generated/stage06_enemy_shadow_stalker/slash, assets/generated/stage06_enemy_eclipse_duelist/slash, assets/generated/stage06_enemy_night_pouncer/pounce -Filter pipeline-meta.json -Recurse | ForEach-Object {
  $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
  [pscustomobject]@{Path=$_.FullName.Replace((Resolve-Path .).Path + '\',''); Rows=$json.rows; Cols=$json.cols; Frames=$json.frames.Count; EdgeTouch=$json.edge_touch_frames.Count; SharedScale=$json.shared_scale}
}
```

Expected: every row has `EdgeTouch=0` and `SharedScale=True`.

- [ ] **Step 4: Visual QC**

Open:

```powershell
assets/generated/stage06_enemy_shadow_stalker/slash/sheet-transparent.png
assets/generated/stage06_enemy_eclipse_duelist/slash/sheet-transparent.png
assets/generated/stage06_enemy_night_pouncer/pounce/sheet-transparent.png
```

Pass criteria:
- `shadow_stalker` reads as a low ground assassin, not a full bat and not heavy.
- `eclipse_duelist` reads as a dark melee duelist, not Stage 07 light and not electric.
- `night_pouncer` reads as compact nocturnal pouncer with stable scale and no natural-animal look.

- [ ] **Step 5: Copy runtime PNGs, create imports, and commit**

Run:

```powershell
Copy-Item assets/generated/stage06_enemy_shadow_stalker/slash/sheet-transparent.png characters/enemies/stage_06/enemy_shadow_stalker.png -Force
Copy-Item assets/generated/stage06_enemy_eclipse_duelist/slash/sheet-transparent.png characters/enemies/stage_06/enemy_eclipse_duelist.png -Force
Copy-Item assets/generated/stage06_enemy_night_pouncer/pounce/sheet-transparent.png characters/enemies/stage_06/enemy_night_pouncer.png -Force
$files = 'enemy_shadow_stalker','enemy_eclipse_duelist','enemy_night_pouncer'
foreach ($name in $files) {
  $res = "res://characters/enemies/stage_06/$name.png"
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $hash = (($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res)) | ForEach-Object { $_.ToString('x2') }) -join '')
  $uid = "uid://s06" + ($name.Replace("_",""))
  if ($uid.Length -gt 28) { $uid = $uid.Substring(0, 28) }
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
"@ | Set-Content "characters/enemies/stage_06/$name.png.import" -Encoding UTF8
}
$generated = Get-ChildItem assets/generated/stage06_enemy_shadow_stalker, assets/generated/stage06_enemy_eclipse_duelist, assets/generated/stage06_enemy_night_pouncer -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_06/enemy_shadow_stalker.png characters/enemies/stage_06/enemy_shadow_stalker.png.import characters/enemies/stage_06/enemy_eclipse_duelist.png characters/enemies/stage_06/enemy_eclipse_duelist.png.import characters/enemies/stage_06/enemy_night_pouncer.png characters/enemies/stage_06/enemy_night_pouncer.png.import
git commit -m "feat: add stage 06 ground enemy sprites"
```

---

### Task 3: Suspended Enemy Sprites

**Files:**
- Create generated assets for `enemy_umbra_bat`, `enemy_void_orbiter`, `enemy_shadow_snare`, `enemy_phase_mine`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_06/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_enemy_umbra_bat\dive\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage06_enemy_umbra_bat\dive\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_enemy_void_orbiter\shoot\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage06_enemy_void_orbiter\shoot\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_enemy_shadow_snare\grab\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage06_enemy_shadow_snare\grab\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_enemy_phase_mine\pulse\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage06_enemy_phase_mine\pulse\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_enemy_umbra_bat/dive/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage06_enemy_umbra_bat/dive --rows 3 --cols 3 --label-prefix dive --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_enemy_void_orbiter/shoot/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage06_enemy_void_orbiter/shoot --rows 2 --cols 3 --label-prefix shoot --align center --shared-scale --component-mode largest --fit-scale 0.82 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_enemy_shadow_snare/grab/raw-sheet.png --target creature --mode attack --output-dir assets/generated/stage06_enemy_shadow_snare/grab --rows 3 --cols 3 --label-prefix grab --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_enemy_phase_mine/pulse/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage06_enemy_phase_mine/pulse --rows 2 --cols 3 --label-prefix pulse --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
```

- [ ] **Step 3: Validate metadata**

Run:

```powershell
Get-ChildItem assets/generated/stage06_enemy_umbra_bat/dive, assets/generated/stage06_enemy_void_orbiter/shoot, assets/generated/stage06_enemy_shadow_snare/grab, assets/generated/stage06_enemy_phase_mine/pulse -Filter pipeline-meta.json -Recurse | ForEach-Object {
  $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
  [pscustomobject]@{Path=$_.FullName.Replace((Resolve-Path .).Path + '\',''); Rows=$json.rows; Cols=$json.cols; Frames=$json.frames.Count; EdgeTouch=$json.edge_touch_frames.Count; SharedScale=$json.shared_scale}
}
```

Expected: every row has `EdgeTouch=0` and `SharedScale=True`.

- [ ] **Step 4: Visual QC**

Pass criteria:
- `umbra_bat` reads as mechanical bat patrol/dive enemy, not a mini Umbraex.
- `void_orbiter` reads as shadow core shooter, not a Stage 04 gravity mine.
- `shadow_snare` reads as capture/slow trap with close hooks/ribbons and no player shown.
- `phase_mine` reads as phasing shadow mine, not a heavy gravity mine.

- [ ] **Step 5: Copy runtime PNGs, create imports, and commit**

Run:

```powershell
Copy-Item assets/generated/stage06_enemy_umbra_bat/dive/sheet-transparent.png characters/enemies/stage_06/enemy_umbra_bat.png -Force
Copy-Item assets/generated/stage06_enemy_void_orbiter/shoot/sheet-transparent.png characters/enemies/stage_06/enemy_void_orbiter.png -Force
Copy-Item assets/generated/stage06_enemy_shadow_snare/grab/sheet-transparent.png characters/enemies/stage_06/enemy_shadow_snare.png -Force
Copy-Item assets/generated/stage06_enemy_phase_mine/pulse/sheet-transparent.png characters/enemies/stage_06/enemy_phase_mine.png -Force
$files = 'enemy_umbra_bat','enemy_void_orbiter','enemy_shadow_snare','enemy_phase_mine'
foreach ($name in $files) {
  $res = "res://characters/enemies/stage_06/$name.png"
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $hash = (($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res)) | ForEach-Object { $_.ToString('x2') }) -join '')
  $uid = "uid://s06" + ($name.Replace("_",""))
  if ($uid.Length -gt 28) { $uid = $uid.Substring(0, 28) }
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
"@ | Set-Content "characters/enemies/stage_06/$name.png.import" -Encoding UTF8
}
$generated = Get-ChildItem assets/generated/stage06_enemy_umbra_bat, assets/generated/stage06_enemy_void_orbiter, assets/generated/stage06_enemy_shadow_snare, assets/generated/stage06_enemy_phase_mine -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_06/enemy_umbra_bat.png characters/enemies/stage_06/enemy_umbra_bat.png.import characters/enemies/stage_06/enemy_void_orbiter.png characters/enemies/stage_06/enemy_void_orbiter.png.import characters/enemies/stage_06/enemy_shadow_snare.png characters/enemies/stage_06/enemy_shadow_snare.png.import characters/enemies/stage_06/enemy_phase_mine.png characters/enemies/stage_06/enemy_phase_mine.png.import
git commit -m "feat: add stage 06 suspended enemy sprites"
```

---

### Task 4: Static Enemy Sprites

**Files:**
- Create generated assets for `enemy_dark_lantern`, `enemy_eclipse_turret`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_06/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_enemy_dark_lantern\pulse\prompt-used.txt --size 1536x1024 --quality medium --out assets\generated\stage06_enemy_dark_lantern\pulse\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_enemy_eclipse_turret\shoot\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage06_enemy_eclipse_turret\shoot\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_enemy_dark_lantern/pulse/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage06_enemy_dark_lantern/pulse --rows 2 --cols 3 --label-prefix pulse --align bottom --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_enemy_eclipse_turret/shoot/raw-sheet.png --target asset --mode shoot --output-dir assets/generated/stage06_enemy_eclipse_turret/shoot --rows 2 --cols 2 --label-prefix shoot --align bottom --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
```

- [ ] **Step 3: Visual QC**

Pass criteria:
- `dark_lantern` reads as fixed black lantern/pulse hazard, not a projectile creature.
- `eclipse_turret` reads as low shadow cannon, not a soldier and not a gravity device.

- [ ] **Step 4: Copy runtime PNGs, create imports, and commit**

Run:

```powershell
Copy-Item assets/generated/stage06_enemy_dark_lantern/pulse/sheet-transparent.png characters/enemies/stage_06/enemy_dark_lantern.png -Force
Copy-Item assets/generated/stage06_enemy_eclipse_turret/shoot/sheet-transparent.png characters/enemies/stage_06/enemy_eclipse_turret.png -Force
$files = 'enemy_dark_lantern','enemy_eclipse_turret'
foreach ($name in $files) {
  $res = "res://characters/enemies/stage_06/$name.png"
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $hash = (($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res)) | ForEach-Object { $_.ToString('x2') }) -join '')
  $uid = "uid://s06" + ($name.Replace("_",""))
  if ($uid.Length -gt 28) { $uid = $uid.Substring(0, 28) }
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
"@ | Set-Content "characters/enemies/stage_06/$name.png.import" -Encoding UTF8
}
$generated = Get-ChildItem assets/generated/stage06_enemy_dark_lantern, assets/generated/stage06_enemy_eclipse_turret -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_06/enemy_dark_lantern.png characters/enemies/stage_06/enemy_dark_lantern.png.import characters/enemies/stage_06/enemy_eclipse_turret.png characters/enemies/stage_06/enemy_eclipse_turret.png.import
git commit -m "feat: add stage 06 static enemy sprites"
```

---

### Task 5: Projectile And FX Sprites

**Files:**
- Create generated assets for `shadow_bolt`, `void_shard`, `snare_pulse`, `phase_slash`
- Create runtime PNG and `.import` sidecars in `characters/enemies/stage_06/`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_shadow_bolt\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage06_shadow_bolt\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_void_shard\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage06_void_shard\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_snare_pulse\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage06_snare_pulse\projectile\raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets\generated\stage06_phase_slash\projectile\prompt-used.txt --size 1024x1024 --quality medium --out assets\generated\stage06_phase_slash\projectile\raw-sheet.png --force
```

- [ ] **Step 2: Process raw sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_shadow_bolt/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage06_shadow_bolt/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_void_shard/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage06_void_shard/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_snare_pulse/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage06_snare_pulse/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage06_phase_slash/projectile/raw-sheet.png --target asset --mode projectile --output-dir assets/generated/stage06_phase_slash/projectile --rows 2 --cols 2 --label-prefix projectile --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
```

- [ ] **Step 3: Visual QC**

Pass criteria:
- `shadow_bolt` reads as compact horizontal shadow shot.
- `void_shard` reads as physical dark shard, not a stone or generic orb.
- `snare_pulse` reads as compact capture ring distinct from `shadow_bolt`.
- `phase_slash` reads as dark crescent slash and every frame has a visible complete slash.

- [ ] **Step 4: Copy runtime PNGs, create imports, and commit**

Run:

```powershell
Copy-Item assets/generated/stage06_shadow_bolt/projectile/sheet-transparent.png characters/enemies/stage_06/shadow_bolt.png -Force
Copy-Item assets/generated/stage06_void_shard/projectile/sheet-transparent.png characters/enemies/stage_06/void_shard.png -Force
Copy-Item assets/generated/stage06_snare_pulse/projectile/sheet-transparent.png characters/enemies/stage_06/snare_pulse.png -Force
Copy-Item assets/generated/stage06_phase_slash/projectile/sheet-transparent.png characters/enemies/stage_06/phase_slash.png -Force
$files = 'shadow_bolt','void_shard','snare_pulse','phase_slash'
foreach ($name in $files) {
  $res = "res://characters/enemies/stage_06/$name.png"
  $md5 = [System.Security.Cryptography.MD5]::Create()
  $hash = (($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res)) | ForEach-Object { $_.ToString('x2') }) -join '')
  $uid = "uid://s06" + ($name.Replace("_",""))
  if ($uid.Length -gt 28) { $uid = $uid.Substring(0, 28) }
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
"@ | Set-Content "characters/enemies/stage_06/$name.png.import" -Encoding UTF8
}
$generated = Get-ChildItem assets/generated/stage06_shadow_bolt, assets/generated/stage06_void_shard, assets/generated/stage06_snare_pulse, assets/generated/stage06_phase_slash -Recurse -File | Where-Object { $_.Name -notmatch '\.import($|\.)|\.tmp$' } | ForEach-Object { $_.FullName }
git add -- $generated characters/enemies/stage_06/shadow_bolt.png characters/enemies/stage_06/shadow_bolt.png.import characters/enemies/stage_06/void_shard.png characters/enemies/stage_06/void_shard.png.import characters/enemies/stage_06/snare_pulse.png characters/enemies/stage_06/snare_pulse.png.import characters/enemies/stage_06/phase_slash.png characters/enemies/stage_06/phase_slash.png.import
git commit -m "feat: add stage 06 enemy projectile sprites"
```

---

### Task 6: Final QC

**Files:**
- Verify all files created by Tasks 1-5.

- [ ] **Step 1: Validate runtime outputs**

Run:

```powershell
$files = @(
  'enemy_shadow_stalker',
  'enemy_eclipse_duelist',
  'enemy_night_pouncer',
  'enemy_umbra_bat',
  'enemy_void_orbiter',
  'enemy_shadow_snare',
  'enemy_phase_mine',
  'enemy_dark_lantern',
  'enemy_eclipse_turret',
  'shadow_bolt',
  'void_shard',
  'snare_pulse',
  'phase_slash'
)
foreach ($name in $files) {
  $png = "characters/enemies/stage_06/$name.png"
  $imp = "$png.import"
  [pscustomobject]@{Name=$name; Png=(Test-Path $png); Import=(Test-Path $imp)}
}
```

Expected: all rows show `Png=True` and `Import=True`.

- [ ] **Step 2: Validate metadata edge-touch**

Run:

```powershell
$metas = Get-ChildItem assets/generated -Recurse -Filter pipeline-meta.json | Where-Object { $_.FullName -match 'stage06_' }
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
$files = @('enemy_shadow_stalker','enemy_eclipse_duelist','enemy_night_pouncer','enemy_umbra_bat','enemy_void_orbiter','enemy_shadow_snare','enemy_phase_mine','enemy_dark_lantern','enemy_eclipse_turret','shadow_bolt','void_shard','snare_pulse','phase_slash')
foreach ($name in $files) {
  $path = (Resolve-Path "characters/enemies/stage_06/$name.png").Path
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
git status --short -- assets/generated/stage06_* characters/enemies/stage_06 docs/superpowers
git log --oneline -8
```

Expected: no uncommitted Stage 06 sprite files remain except untracked `.png.import` files under `assets/generated`, which must not be committed. Recent commits include spec, plan, prompts, and sprite batches.

- [ ] **Step 5: Final visual checklist**

Inspect final runtime sheets:

```powershell
characters/enemies/stage_06/enemy_shadow_stalker.png
characters/enemies/stage_06/enemy_eclipse_duelist.png
characters/enemies/stage_06/enemy_night_pouncer.png
characters/enemies/stage_06/enemy_umbra_bat.png
characters/enemies/stage_06/enemy_void_orbiter.png
characters/enemies/stage_06/enemy_shadow_snare.png
characters/enemies/stage_06/enemy_phase_mine.png
characters/enemies/stage_06/enemy_dark_lantern.png
characters/enemies/stage_06/enemy_eclipse_turret.png
characters/enemies/stage_06/shadow_bolt.png
characters/enemies/stage_06/void_shard.png
characters/enemies/stage_06/snare_pulse.png
characters/enemies/stage_06/phase_slash.png
```

Pass criteria:
- Umbraex/sombra/morcego/chifres theme is visible across the set.
- The set feels like shadow, eclipse, teleporte and penumbra, not Stage 04 gravity or Stage 07 light.
- Ground enemies feel stealthy and fast.
- Suspended enemies clearly communicate patrol, shooter, snare, and phase mine roles.
- Static enemies clearly communicate dark lantern and eclipse turret.
- The four projectiles are distinct.
- No body sheet relies on wide detached FX.
