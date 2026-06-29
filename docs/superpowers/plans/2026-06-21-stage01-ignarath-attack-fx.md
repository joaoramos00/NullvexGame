# Stage 01 Ignarath Attack FX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate modular sprite sheets for Ignarath's fire beam and claw fire wave attacks.

**Architecture:** Each visual attack is built from modular pieces so runtime can stretch or repeat the body segment to arbitrary length. Raw sheets are generated under `assets/generated/stage01_ignarath_*`, processed with `generate2dsprite.py`, then runtime PNG sheets are copied into `characters/bosses/ignarath/`.

**Tech Stack:** Godot 4.6.2, GDScript, built-in image generation, `generate2dsprite.py`.

---

## Asset Contract

Create these runtime sheets:

- `characters/bosses/ignarath/fire_beam_origin.png` - large muzzle/origin ball at the mouth.
- `characters/bosses/ignarath/fire_beam_body.png` - repeatable energy body segment.
- `characters/bosses/ignarath/fire_beam_end.png` - rounded beam tip.
- `characters/bosses/ignarath/fire_wave_start.png` - trailing start of ground fire.
- `characters/bosses/ignarath/fire_wave_body.png` - repeatable low flame body.
- `characters/bosses/ignarath/fire_wave_end.png` - advancing low flame front.

All six raw sheets use 2 rows by 2 columns, 4 frames, solid `#FF00FF` background, and safe containment. Runtime integration is a separate task after visual QC.

### Task 1: Generate Raw Sheets

**Files:**
- Create: `assets/generated/stage01_ignarath_fire_beam_origin/loop/prompt-used.txt`
- Create: `assets/generated/stage01_ignarath_fire_beam_body/loop/prompt-used.txt`
- Create: `assets/generated/stage01_ignarath_fire_beam_end/loop/prompt-used.txt`
- Create: `assets/generated/stage01_ignarath_fire_wave_start/loop/prompt-used.txt`
- Create: `assets/generated/stage01_ignarath_fire_wave_body/loop/prompt-used.txt`
- Create: `assets/generated/stage01_ignarath_fire_wave_end/loop/prompt-used.txt`

- [ ] **Step 1: Generate each raw sheet with built-in image generation**

Use each `prompt-used.txt` to produce `raw-sheet.png` in the same directory.

Expected: six 2x2 raw sheets with solid magenta background.

### Task 2: Process Sheets

**Files:**
- Create: `assets/generated/stage01_ignarath_*/loop/sheet-transparent.png`
- Create: `assets/generated/stage01_ignarath_*/loop/animation.gif`
- Create: `assets/generated/stage01_ignarath_*/loop/pipeline-meta.json`

- [ ] **Step 1: Process all generated sheets**

Run:

```powershell
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_ignarath_fire_beam_origin/loop/raw-sheet.png --target asset --mode fx --output-dir assets/generated/stage01_ignarath_fire_beam_origin/loop --rows 2 --cols 2 --label-prefix fire_beam_origin --align center --shared-scale --component-mode all --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_ignarath_fire_beam_body/loop/raw-sheet.png --target asset --mode fx --output-dir assets/generated/stage01_ignarath_fire_beam_body/loop --rows 2 --cols 2 --label-prefix fire_beam_body --align center --shared-scale --component-mode all --fit-scale 0.86 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_ignarath_fire_beam_end/loop/raw-sheet.png --target asset --mode fx --output-dir assets/generated/stage01_ignarath_fire_beam_end/loop --rows 2 --cols 2 --label-prefix fire_beam_end --align center --shared-scale --component-mode all --fit-scale 0.78 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_ignarath_fire_wave_start/loop/raw-sheet.png --target asset --mode fx --output-dir assets/generated/stage01_ignarath_fire_wave_start/loop --rows 2 --cols 2 --label-prefix fire_wave_start --align bottom --shared-scale --component-mode all --fit-scale 0.82 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_ignarath_fire_wave_body/loop/raw-sheet.png --target asset --mode fx --output-dir assets/generated/stage01_ignarath_fire_wave_body/loop --rows 2 --cols 2 --label-prefix fire_wave_body --align bottom --shared-scale --component-mode all --fit-scale 0.86 --reject-edge-touch
python C:/Users/Usuário/.codex/skills/generate2dsprite/scripts/generate2dsprite.py process --input assets/generated/stage01_ignarath_fire_wave_end/loop/raw-sheet.png --target asset --mode fx --output-dir assets/generated/stage01_ignarath_fire_wave_end/loop --rows 2 --cols 2 --label-prefix fire_wave_end --align bottom --shared-scale --component-mode all --fit-scale 0.82 --reject-edge-touch
```

Expected: all commands exit 0 and no frame touches cell edges.

### Task 3: Copy Runtime Sheets

**Files:**
- Create: `characters/bosses/ignarath/fire_beam_origin.png`
- Create: `characters/bosses/ignarath/fire_beam_body.png`
- Create: `characters/bosses/ignarath/fire_beam_end.png`
- Create: `characters/bosses/ignarath/fire_wave_start.png`
- Create: `characters/bosses/ignarath/fire_wave_body.png`
- Create: `characters/bosses/ignarath/fire_wave_end.png`

- [ ] **Step 1: Copy processed sheets to runtime paths**

Run:

```powershell
Copy-Item assets/generated/stage01_ignarath_fire_beam_origin/loop/sheet-transparent.png characters/bosses/ignarath/fire_beam_origin.png -Force
Copy-Item assets/generated/stage01_ignarath_fire_beam_body/loop/sheet-transparent.png characters/bosses/ignarath/fire_beam_body.png -Force
Copy-Item assets/generated/stage01_ignarath_fire_beam_end/loop/sheet-transparent.png characters/bosses/ignarath/fire_beam_end.png -Force
Copy-Item assets/generated/stage01_ignarath_fire_wave_start/loop/sheet-transparent.png characters/bosses/ignarath/fire_wave_start.png -Force
Copy-Item assets/generated/stage01_ignarath_fire_wave_body/loop/sheet-transparent.png characters/bosses/ignarath/fire_wave_body.png -Force
Copy-Item assets/generated/stage01_ignarath_fire_wave_end/loop/sheet-transparent.png characters/bosses/ignarath/fire_wave_end.png -Force
```

Expected: six runtime PNGs exist.

### Task 4: Verify And Commit

**Files:**
- Verify: `assets/generated/stage01_ignarath_*/loop/pipeline-meta.json`
- Verify: `characters/bosses/ignarath/fire_*png`

- [ ] **Step 1: Check generated files**

Run:

```powershell
Get-Item assets/generated/stage01_ignarath_*/loop/animation.gif
Get-Item characters/bosses/ignarath/fire_beam_origin.png, characters/bosses/ignarath/fire_beam_body.png, characters/bosses/ignarath/fire_beam_end.png, characters/bosses/ignarath/fire_wave_start.png, characters/bosses/ignarath/fire_wave_body.png, characters/bosses/ignarath/fire_wave_end.png
Get-ChildItem assets/generated -Recurse -Filter pipeline-meta.json | Where-Object { $_.FullName -like '*stage01_ignarath_fire_*' } | Select-String -Pattern '"edge_touch_frames": \[[^\]]+\]'
```

Expected: GIFs and runtime PNGs exist; edge-touch check prints no matches.

- [ ] **Step 2: Commit generated assets**

Run:

```powershell
git add docs/superpowers/plans/2026-06-21-stage01-ignarath-attack-fx.md assets/generated/stage01_ignarath_fire_beam_origin assets/generated/stage01_ignarath_fire_beam_body assets/generated/stage01_ignarath_fire_beam_end assets/generated/stage01_ignarath_fire_wave_start assets/generated/stage01_ignarath_fire_wave_body assets/generated/stage01_ignarath_fire_wave_end characters/bosses/ignarath/fire_beam_origin.png characters/bosses/ignarath/fire_beam_body.png characters/bosses/ignarath/fire_beam_end.png characters/bosses/ignarath/fire_wave_start.png characters/bosses/ignarath/fire_wave_body.png characters/bosses/ignarath/fire_wave_end.png
git commit -m "feat(stage01): add modular Ignarath attack FX sprites"
```

Expected: commit contains only the plan, generated FX assets, and runtime FX PNGs.
