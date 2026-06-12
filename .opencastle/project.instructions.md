```instructions
# Project Context

## Overview

**NullvexGame** is a 2D action-platformer inspired by Mega Man X4, built with Godot 4.6.2 (GDScript). Original IP with two playable characters — Zael (ranged, charge shots) and Zara (melee, combos) — 12 stages, 8 elemental bosses with a logical weakness chain, and final villain Nullvex.

**Status:** Main development complete (Plans 01–15 done). Current work: boss sprites via PixelLab, stage tilesets, visual polish.

## System Architecture

```
NullvexGame/
├── autoloads/              — GameManager, StageManager, AudioManager, AudioLibrary
├── characters/
│   ├── base/               — CharacterBase (HP, movement, wall-jump, dash, invincibility)
│   ├── ranged/             — Zael (5 shoot types, charge), ZaelBullet
│   ├── melee/              — Zara (5 weapons, combo: 2 hits + finisher)
│   ├── bosses/             — BossBase, 8 elemental bosses, NullvexTrue, IntroBoss
│   └── enemies/            — EnemyBase (grunt), EnemyFlyer, enemy_miniboss
├── stages/                 — StageController, Checkpoint, Collectible, stage_scene.gd, CorridorSection
│   ├── stage_00/           — Intro stage (zones, glass corridors, IntroBoss)
│   └── stage_01–11/        — Stage scenes (boss fight + collectibles)
├── ui/                     — HUD, PauseMenu, GameOver, StageSelect, TitleScreen, TouchControls
├── effects/                — death_effect.tscn (expanding circle)
├── tests/                  — Headless Godot test scenes (.gd + .tscn pairs)
├── docs/                   — Design specs, implementation plans, art brief, web artifacts
├── export/web/             — Active web export (deployed to GitHub Pages)
└── .github/workflows/      — deploy.yml: auto-deploys export/web on push to master
```

**Signal architecture:** Autoloads communicate exclusively via signals — no direct cross-system calls.

**Key pattern:** `StageController` connects `CharacterBase.died` to `GameManager.lose_life()` via property setter (supports dynamic spawn). `stage_scene.gd` is a shared base for all 8 stages; spawns Zael or Zara per `GameManager.active_character`; draws terrain via `_draw()`.

## Tech Stack

| Layer | Technology | Version | Notes |
|-------|-----------|---------|-------|
| Engine | Godot | 4.6.2 | GDScript only — no C# |
| Language | GDScript | 4.6.2 | Statically typed where possible |
| Resolution | 1920×1080 | — | HD Pixel Art style |
| CI/CD | GitHub Actions | — | `deploy.yml` — auto-deploys on push to `master` |
| Web Deploy | GitHub Pages | — | Artifact at `export/web/` |
| Sprite/Tileset Gen | PixelLab AI | v1/v2 | `PIXELLAB_API_KEY` in `.env` (gitignored) |
| Dev IDE | Godot Editor | 4.6.2 | `D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe` |

## Project Structure

| Path | Purpose |
|------|---------|
| `autoloads/` | Global singletons: GameManager, StageManager, AudioManager, AudioLibrary |
| `characters/base/character_base.gd` | Player base: HP, movement, wall-jump, dash, invincibility flicker |
| `characters/ranged/` | Zael: 5 shoot types (Single/Spread/Rapid/Laser/Cannon), charge system |
| `characters/melee/` | Zara: 5 weapons, 2-hit + finisher combo, combo system |
| `characters/bosses/boss_base.gd` | Boss base: phase management, attack timers, gravity_scale |
| `characters/enemies/enemy_base.gd` | Grunt: walk, hit flash, ContactZone damage |
| `characters/enemies/enemy_miniboss.gd` | Miniboss for Stage 00 |
| `stages/stage_scene.gd` | Shared base for stages 01–08 |
| `stages/stage_00/` | Intro stage: multi-zone with CorridorSection transitions |
| `stages/corridor_section.gd` | Reusable corridor Node2D; emits camera_lock, checkpoint, heal, traversal signals |
| `ui/hud.gd` | In-game HUD (HP bar, lives, ability indicator) |
| `tests/` | Headless test files — must use `extends Node` + `.tscn` |
| `docs/superpowers/` | Specs (`*-design.md`) and plans (`*-plan.md` or `*-plan-xx.md`) |
| `export/web/` | Web export output directory; deployed by CI |
| `.claude/skills/` | Project-local skills: new-enemy, new-boss, new-stage, web-export, pixellab, run-tests |

## Apps & Deployment

| App | Production URL | Dev Port |
|-----|---------------|----------|
| Web Export | https://joaoramos00.github.io/NullvexGame/ | localhost:8080 |

## Key Commands

```bash
# Run headless tests (PowerShell)
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn

# Start local web server (after export)
python -m http.server 8080 --directory export/web
# Kill server: Get-Process python | Stop-Process

# Load PixelLab API key before using PixelLab tools
$env:PIXELLAB_API_KEY = (Get-Content .env | Select-String "PIXELLAB_API_KEY").ToString().Split("=")[1]
```

## Environment Variables

| Variable | Purpose | File |
|----------|---------|------|
| `PIXELLAB_API_KEY` | PixelLab sprite/tileset generation | `.env` (gitignored) |

## Key Documentation

| Document | Description |
|----------|-------------|
| `CLAUDE.md` | Main project instructions, architecture, boss table, plans |
| `GAME_CONTEXT.md` | Full game context: collision layers, autoload APIs, boss weakness chain, code patterns |
| `docs/corredor_template.md` | Reusable corridor section template |
| `docs/stage_00/corredor.md` | Stage 00 corridor specification |
| `docs/art_brief.md` | Visual art direction and pixel art style guide |

## Domain Quick Reference

| Domain | Skill | Key Paths |
|--------|-------|-----------|
| Enemy creation | `new-enemy` | `characters/enemies/`, `characters/enemies/enemy_base.gd` |
| Boss creation | `new-boss` | `characters/bosses/`, `characters/bosses/boss_base.gd` |
| Stage creation | `new-stage` | `stages/`, `stages/stage_scene.gd` |
| Corridor sections | `new-corridor` | `stages/corridor_section.gd`, `docs/corredor_template.md` |
| Run tests | `run-tests` | `tests/`, Godot headless `--path .` |
| Web export + deploy | `web-export` | `export/web/`, `.github/workflows/deploy.yml` |
| Sprite generation | `pixellab` | `characters/`, `.env` (PIXELLAB_API_KEY) |

<!-- End of Project Context -->
```
