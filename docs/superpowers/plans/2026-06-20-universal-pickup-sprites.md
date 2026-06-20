# Universal Pickup Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate, process, import, QC, and commit 7 universal pickup/upgrade sprite sheets for use across all stages.

**Architecture:** Each pickup is generated as its own raw sheet under `assets/generated/pickups_*`, then postprocessed with `generate2dsprite.py` into transparent sheets, frames, GIFs, and metadata. Runtime-ready PNGs are copied to `characters/pickups/`, `.png.import` sidecars are created for Godot, and the work is committed in small batches.

**Tech Stack:** Godot 4.6.2, PowerShell, built-in image generation or CLI fallback through the `imagegen` skill, `generate2dsprite.py` for deterministic chroma-key processing and QC metadata, Git.

---

## Source Context

- Spec: `docs/superpowers/specs/2026-06-19-universal-pickup-sprites-design.md`
- Current runtime collectible: `stages/collectible.tscn` + `stages/collectible.gd`
- Current collectible visual: `_draw()` circles by type; this plan only creates sprite assets and does not replace runtime behavior
- Runtime output folder: `characters/pickups/`
- Generated output prefix: `assets/generated/pickups_`
- Required final roster:
  - `pickup_health_small`
  - `pickup_health_large`
  - `pickup_energy_small`
  - `pickup_energy_large`
  - `pickup_life_upgrade`
  - `pickup_1up`
  - `upgrade_capsule`

## Shared Rules

- Work from `D:\SnesGame\.worktrees\universal-pickups`.
- Keep every raw sheet on solid `#FF00FF` background.
- Use separate raw sheets for each pickup.
- Use `--target asset`, `--shared-scale`, and `--reject-edge-touch` for every processed sheet.
- Use `--component-mode largest` for compact pickup bodies.
- If processing reports edge-touch frames, inspect `raw-sheet.png`, strengthen containment in `prompt-used.txt`, regenerate, and reprocess.
- After every process step, reextract frame PNGs from `sheet-transparent.png` if any generated frame PNG contains visible `#FF00FF` pixels with alpha > 0.
- Do not commit `.png.import` files created inside `assets/generated`; only commit generated source PNG/GIF/metadata plus runtime `.png.import` files under `characters/pickups/`.

## Common Commands

Load the API key for CLI fallback:

```powershell
$line = Get-Content D:\SnesGame\.env | Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
$env:OPENAI_API_KEY = $line.Substring('OPENAI_API_KEY='.Length).Trim().Trim('"')
```

Generate with CLI fallback:

```powershell
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file <prompt-file> --size 1024x1024 --quality medium --out <raw-output> --force
```

Process with `generate2dsprite.py`:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input <raw-sheet> --target asset --mode animated --output-dir <output-dir> --rows <rows> --cols <cols> --label-prefix <label> --align center --shared-scale --component-mode largest --fit-scale <scale> --reject-edge-touch
```

Reextract clean frame PNGs from a transparent sheet:

```powershell
@'
from pathlib import Path
from PIL import Image
sheet_path = Path("<output-dir>/sheet-transparent.png")
prefix = "<label>"
rows = <rows>
cols = <cols>
sheet = Image.open(sheet_path).convert("RGBA")
cell_w = sheet.width // cols
cell_h = sheet.height // rows
assert cell_w == 128 and cell_h == 128, (sheet.size, rows, cols)
frame = 1
for r in range(rows):
    for c in range(cols):
        crop = sheet.crop((c * cell_w, r * cell_h, (c + 1) * cell_w, (r + 1) * cell_h))
        crop.save(sheet_path.parent / f"{prefix}-{frame}.png")
        frame += 1
'@ | python -
```

Verify frame PNGs have no visible magenta:

```powershell
@'
from pathlib import Path
from PIL import Image
paths = list(Path("assets/generated").glob("pickups_*/**/*.png"))
issues = []
for path in paths:
    if path.name.startswith("raw-sheet") or path.name == "sheet-transparent.png":
        continue
    img = Image.open(path).convert("RGBA")
    if img.size != (128, 128):
        issues.append(f"dim {path} {img.size}")
    magenta = sum(1 for r,g,b,a in img.getdata() if (r,g,b)==(255,0,255) and a>0)
    if magenta:
        issues.append(f"magenta {path} {magenta}")
print("issues", len(issues))
for issue in issues:
    print(issue)
'@ | python -
```

---

### Task 1: Prompt Files

**Files:**
- Create: `characters/pickups/.gitkeep`
- Create one `prompt-used.txt` under each generated output directory listed below.

- [ ] **Step 1: Create output directories**

Run:

```powershell
New-Item -ItemType Directory -Force `
  characters/pickups, `
  assets/generated/pickups_pickup_health_small/pulse, `
  assets/generated/pickups_pickup_health_large/pulse, `
  assets/generated/pickups_pickup_energy_small/pulse, `
  assets/generated/pickups_pickup_energy_large/pulse, `
  assets/generated/pickups_pickup_life_upgrade/charge, `
  assets/generated/pickups_pickup_1up/shine, `
  assets/generated/pickups_upgrade_capsule/open
New-Item -ItemType File -Force characters/pickups/.gitkeep
```

- [ ] **Step 2: Write prompt files**

`assets/generated/pickups_pickup_health_small/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game pickup sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: pickup_health_small, a small universal health recovery capsule for a Mega Man X inspired platformer with original IP identity. Visual design: compact mechanical capsule, red medical core with small green life indicator, white highlight, dark graphite outline, tiny metal end caps, readable as HP recovery, not stage themed, not organic, not an enemy. Motion: idle, soft inner pulse, small rim shine, return idle. Same item identity and same scale in every frame, centered. Full pickup and glow inside central 60% safe area with generous magenta margin. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/pickups_pickup_health_large/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game pickup sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: pickup_health_large, a large universal health recovery capsule for a Mega Man X inspired platformer with original IP identity. Visual design: robust mechanical capsule in the same family as pickup_health_small, larger body, red medical core, green life indicator band, white highlight, dark graphite outline, thicker metal end caps, clearly more valuable than the small health pickup, not stage themed, not organic. Motion: idle, stronger inner pulse, bright rim shine, return idle. Same item identity and same scale in every frame, centered. Full pickup and glow inside central 60% safe area with generous magenta margin. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/pickups_pickup_energy_small/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game pickup sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: pickup_energy_small, a small universal weapon energy capsule for a Mega Man X inspired platformer with original IP identity. Visual design: compact mechanical energy cartridge, cyan blue core with white inner glow, dark graphite outline, small silver end caps, slight circuit stripe, readable as weapon energy not health, not stage themed, not lightning hazard, not an enemy. Motion: idle, compact cyan pulse, tiny internal flicker, return idle. Same item identity and same scale in every frame, centered. Full pickup and glow inside central 60% safe area with generous magenta margin. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/pickups_pickup_energy_large/pulse/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game pickup sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: pickup_energy_large, a large universal weapon energy capsule for a Mega Man X inspired platformer with original IP identity. Visual design: robust mechanical energy cartridge in the same family as pickup_energy_small, larger body, intense cyan blue core, white inner glow, dark graphite outline, thicker silver end caps, circuit stripe, clearly more valuable than the small energy pickup, readable as weapon energy not health. Motion: idle, stronger cyan pulse, compact internal flicker, return idle. Same item identity and same scale in every frame, centered. Full pickup and glow inside central 60% safe area with generous magenta margin. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/pickups_pickup_life_upgrade/charge/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game pickup sprite sheet, exactly 3 rows by 3 columns, 9 equal cells. Subject: pickup_life_upgrade, a permanent max-life upgrade item shaped as a robotic battery, for a Mega Man X inspired platformer with original IP identity. Visual design: vertical mechanical battery cell, reinforced dark metal shell, visible circuit traces, red-green life charge core, small white shine, rare upgrade silhouette, not a heart, not a simple health capsule, not a SubTank, not stage themed. Motion read left-to-right: idle battery, charge rises, circuits light, core brightens, central shine, charge peak, small glow pulse, cooldown, return idle. Same item identity and same scale in every frame, centered. Full battery and glow inside central 60% safe area with generous magenta margin. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

`assets/generated/pickups_pickup_1up/shine/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game pickup sprite sheet, exactly 2 rows by 2 columns, 4 equal cells. Subject: pickup_1up, a universal extra life pickup for a Mega Man X inspired platformer with original IP identity. Visual design: rare robotic life emblem, compact circular or helmet-like mechanical core, green and blue-white glow with a small gold trim, optional large readable 1UP symbol integrated as a bold emblem, silhouette must still read as a rare extra life even if text is not read, not a character head portrait, not stage themed. Motion: idle, rare shine sweep, bright pulse, return idle. Same item identity and same scale in every frame, centered. Full emblem and glow inside central 60% safe area with generous magenta margin. Background must be 100% solid flat #FF00FF, no gradients, no small text, no labels, no UI, no borders between cells.
```

`assets/generated/pickups_upgrade_capsule/open/prompt-used.txt`:

```text
Create a side-view HD pixel-art-inspired 2D game upgrade capsule sprite sheet, exactly 4 rows by 4 columns, 16 equal cells. Subject: upgrade_capsule, a universal technology upgrade capsule for a Mega Man X inspired platformer with original IP identity. Visual design: vertical upgrade pod with heavy dark metal base, glass energy chamber, neutral blue-white core, subtle green circuitry, clean sci-fi silhouette, larger and more important than common pickups, not stage themed, not a boss capsule, not a character. Motion read left-to-right: closed idle, core flicker, rim lights turn on, glass brightens, side locks release, front panel opens slightly, chamber opens halfway, energy rises, capsule fully open, strong vertical glow, upgrade pulse, shine sweep, glow settles, panel begins closing, closed bright idle, return to idle. Same capsule identity and same scale in every frame, centered with stable base. Full capsule and glow inside central 65% safe area with generous magenta margin; no panel, light beam, base, or glow crossing cell edges. Background must be 100% solid flat #FF00FF, no gradients, no text, no labels, no UI, no borders between cells.
```

- [ ] **Step 3: Commit prompt files**

Run:

```powershell
git add characters/pickups/.gitkeep assets/generated/pickups_*/**/prompt-used.txt
git commit -m "docs: add universal pickup sprite prompts"
```

Expected: commit records only `.gitkeep` and 7 prompt files.

---

### Task 2: Common Recovery Pickups

**Files:**
- Create/modify: `assets/generated/pickups_pickup_health_small/pulse/`
- Create/modify: `assets/generated/pickups_pickup_health_large/pulse/`
- Create/modify: `assets/generated/pickups_pickup_energy_small/pulse/`
- Create/modify: `assets/generated/pickups_pickup_energy_large/pulse/`
- Create: `characters/pickups/pickup_health_small.png`
- Create: `characters/pickups/pickup_health_large.png`
- Create: `characters/pickups/pickup_energy_small.png`
- Create: `characters/pickups/pickup_energy_large.png`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/pickups_pickup_health_small/pulse/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/pickups_pickup_health_small/pulse/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/pickups_pickup_health_large/pulse/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/pickups_pickup_health_large/pulse/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/pickups_pickup_energy_small/pulse/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/pickups_pickup_energy_small/pulse/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/pickups_pickup_energy_large/pulse/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/pickups_pickup_energy_large/pulse/raw-sheet.png --force
```

- [ ] **Step 2: Process sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/pickups_pickup_health_small/pulse/raw-sheet.png --target asset --mode animated --output-dir assets/generated/pickups_pickup_health_small/pulse --rows 2 --cols 2 --label-prefix pickup_health_small --align center --shared-scale --component-mode largest --fit-scale 0.72 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/pickups_pickup_health_large/pulse/raw-sheet.png --target asset --mode animated --output-dir assets/generated/pickups_pickup_health_large/pulse --rows 2 --cols 2 --label-prefix pickup_health_large --align center --shared-scale --component-mode largest --fit-scale 0.80 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/pickups_pickup_energy_small/pulse/raw-sheet.png --target asset --mode animated --output-dir assets/generated/pickups_pickup_energy_small/pulse --rows 2 --cols 2 --label-prefix pickup_energy_small --align center --shared-scale --component-mode largest --fit-scale 0.72 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/pickups_pickup_energy_large/pulse/raw-sheet.png --target asset --mode animated --output-dir assets/generated/pickups_pickup_energy_large/pulse --rows 2 --cols 2 --label-prefix pickup_energy_large --align center --shared-scale --component-mode largest --fit-scale 0.80 --reject-edge-touch
```

- [ ] **Step 3: Copy runtime PNGs**

Run:

```powershell
Copy-Item assets/generated/pickups_pickup_health_small/pulse/sheet-transparent.png characters/pickups/pickup_health_small.png -Force
Copy-Item assets/generated/pickups_pickup_health_large/pulse/sheet-transparent.png characters/pickups/pickup_health_large.png -Force
Copy-Item assets/generated/pickups_pickup_energy_small/pulse/sheet-transparent.png characters/pickups/pickup_energy_small.png -Force
Copy-Item assets/generated/pickups_pickup_energy_large/pulse/sheet-transparent.png characters/pickups/pickup_energy_large.png -Force
```

- [ ] **Step 4: QC**

Run:

```powershell
Get-Item assets/generated/pickups_pickup_health_small/pulse/animation.gif, assets/generated/pickups_pickup_health_large/pulse/animation.gif, assets/generated/pickups_pickup_energy_small/pulse/animation.gif, assets/generated/pickups_pickup_energy_large/pulse/animation.gif
Get-ChildItem assets/generated -Recurse -Filter pipeline-meta.json | Where-Object { $_.FullName -like '*pickups_pickup_*' } | Select-String -Pattern '"edge_touch_frames": \[[^\]]+\]'
```

Expected: four GIFs exist; no `edge_touch_frames` output. Visual check confirms health and energy are distinct and large versions read larger/more valuable.

- [ ] **Step 5: Commit common pickups**

Run:

```powershell
git add assets/generated/pickups_pickup_health_small assets/generated/pickups_pickup_health_large assets/generated/pickups_pickup_energy_small assets/generated/pickups_pickup_energy_large characters/pickups/pickup_health_small.png characters/pickups/pickup_health_large.png characters/pickups/pickup_energy_small.png characters/pickups/pickup_energy_large.png
git commit -m "feat: add universal recovery pickup sprites"
```

---

### Task 3: Special Pickup And Upgrade Sprites

**Files:**
- Create/modify: `assets/generated/pickups_pickup_life_upgrade/charge/`
- Create/modify: `assets/generated/pickups_pickup_1up/shine/`
- Create/modify: `assets/generated/pickups_upgrade_capsule/open/`
- Create: `characters/pickups/pickup_life_upgrade.png`
- Create: `characters/pickups/pickup_1up.png`
- Create: `characters/pickups/upgrade_capsule.png`

- [ ] **Step 1: Generate raw sheets**

Run:

```powershell
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/pickups_pickup_life_upgrade/charge/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/pickups_pickup_life_upgrade/charge/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/pickups_pickup_1up/shine/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/pickups_pickup_1up/shine/raw-sheet.png --force
python C:\Users\Usuário\.codex\skills\.system\imagegen\scripts\image_gen.py generate --prompt-file assets/generated/pickups_upgrade_capsule/open/prompt-used.txt --size 1024x1024 --quality medium --out assets/generated/pickups_upgrade_capsule/open/raw-sheet.png --force
```

- [ ] **Step 2: Process sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/pickups_pickup_life_upgrade/charge/raw-sheet.png --target asset --mode animated --output-dir assets/generated/pickups_pickup_life_upgrade/charge --rows 3 --cols 3 --label-prefix pickup_life_upgrade --align center --shared-scale --component-mode largest --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/pickups_pickup_1up/shine/raw-sheet.png --target asset --mode animated --output-dir assets/generated/pickups_pickup_1up/shine --rows 2 --cols 2 --label-prefix pickup_1up --align center --shared-scale --component-mode largest --fit-scale 0.76 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/pickups_upgrade_capsule/open/raw-sheet.png --target asset --mode animated --output-dir assets/generated/pickups_upgrade_capsule/open --rows 4 --cols 4 --label-prefix upgrade_capsule --align center --shared-scale --component-mode largest --fit-scale 0.84 --reject-edge-touch
```

- [ ] **Step 3: Copy runtime PNGs**

Run:

```powershell
Copy-Item assets/generated/pickups_pickup_life_upgrade/charge/sheet-transparent.png characters/pickups/pickup_life_upgrade.png -Force
Copy-Item assets/generated/pickups_pickup_1up/shine/sheet-transparent.png characters/pickups/pickup_1up.png -Force
Copy-Item assets/generated/pickups_upgrade_capsule/open/sheet-transparent.png characters/pickups/upgrade_capsule.png -Force
```

- [ ] **Step 4: QC**

Run:

```powershell
Get-Item assets/generated/pickups_pickup_life_upgrade/charge/animation.gif, assets/generated/pickups_pickup_1up/shine/animation.gif, assets/generated/pickups_upgrade_capsule/open/animation.gif
Get-ChildItem assets/generated -Recurse -Filter pipeline-meta.json | Where-Object { $_.FullName -like '*pickups_*' } | Select-String -Pattern '"edge_touch_frames": \[[^\]]+\]'
```

Expected: three GIFs exist; no `edge_touch_frames` output. Visual check confirms `pickup_life_upgrade` reads as robotic battery, `pickup_1up` reads as rare extra life, and `upgrade_capsule` reads as a larger 4x4 upgrade capsule.

- [ ] **Step 5: Commit special pickups**

Run:

```powershell
git add assets/generated/pickups_pickup_life_upgrade assets/generated/pickups_pickup_1up assets/generated/pickups_upgrade_capsule characters/pickups/pickup_life_upgrade.png characters/pickups/pickup_1up.png characters/pickups/upgrade_capsule.png
git commit -m "feat: add universal special pickup sprites"
```

---

### Task 4: Godot Imports And Final Verification

**Files:**
- Create: `characters/pickups/*.png.import`
- Verify: `assets/generated/pickups_*/**/pipeline-meta.json`

- [ ] **Step 1: Run Godot import**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --import --path .
```

Expected: Godot imports the 7 runtime PNGs and creates `.png.import` sidecars under `characters/pickups/`, or creates temporary sidecars that can be copied to final `.png.import` names after safe-save failures.

- [ ] **Step 2: If only temporary import files exist, copy them to final names**

Run:

```powershell
Get-ChildItem characters/pickups -Filter '*.png.import*.tmp' | ForEach-Object {
  $final = $_.FullName -replace '\.png\.import\d+\.tmp$','.png.import'
  Copy-Item -LiteralPath $_.FullName -Destination $final -Force
}
```

- [ ] **Step 3: Verify runtime files and imports exist**

Run:

```powershell
Get-Item characters/pickups/pickup_health_small.png, characters/pickups/pickup_health_large.png, characters/pickups/pickup_energy_small.png, characters/pickups/pickup_energy_large.png, characters/pickups/pickup_life_upgrade.png, characters/pickups/pickup_1up.png, characters/pickups/upgrade_capsule.png
Get-Item characters/pickups/pickup_health_small.png.import, characters/pickups/pickup_health_large.png.import, characters/pickups/pickup_energy_small.png.import, characters/pickups/pickup_energy_large.png.import, characters/pickups/pickup_life_upgrade.png.import, characters/pickups/pickup_1up.png.import, characters/pickups/upgrade_capsule.png.import
```

Expected: 7 PNGs and 7 `.png.import` files exist.

- [ ] **Step 4: Verify no generated edge-touch or magenta failures remain**

Run:

```powershell
Get-ChildItem assets/generated -Recurse -Filter pipeline-meta.json | Where-Object { $_.FullName -like '*pickups_*' } | Select-String -Pattern '"edge_touch_frames": \[[^\]]+\]'
```

Expected: no output.

Run the magenta checker from Common Commands.

Expected: `issues 0`.

- [ ] **Step 5: Verify git scope**

Run:

```powershell
git status --short
git diff --stat origin/master..HEAD
```

Expected: only pickup generated assets, runtime PNG/imports, and pickup spec/plan docs appear.

- [ ] **Step 6: Commit imports and final fixes**

Run:

```powershell
git add characters/pickups/*.png.import
git commit -m "chore: import universal pickup sprites"
```

Expected: commit records only `.png.import` files unless a prior QC fix was required.

