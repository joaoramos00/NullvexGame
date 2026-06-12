# ImgDebug Projectile Line Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a projectile row and release-frame projectile preview to the existing ImgDebug hitbox frame view.

**Architecture:** Extend `ImgDebug._HitboxView` with a projectile metadata row and a small overlay draw path. Keep all behavior inside the existing hitbox view so current type, stage, entity, and frame selectors remain the source of navigation.

**Tech Stack:** Godot 4.6 GDScript, existing `tests/test_img_debug.gd`, existing Stage 02 enemy scenes/scripts.

---

### Task 1: Tests

**Files:**
- Modify: `tests/test_img_debug.gd`

- [x] Add tests that select each Stage 02 ranged enemy and assert the projectile row exists.
- [x] Assert projectile visibility only on the approved release frame.
- [x] Assert Cryo Bomber projectile preview is marked as parabolic.
- [x] Run `test_img_debug` and confirm the new tests fail before implementation.

### Task 2: ImgDebug Projectile Row

**Files:**
- Modify: `ui/img_debug.gd`

- [x] Add projectile metadata for Ice Archer, Frost Turret, Cryo Bomber, and Glacier Shield.
- [x] Build a `Projetil` row inside `_HitboxView`.
- [x] Refresh the row when entity or frame changes.
- [x] Add an overlay draw path that shows the projectile only on the release frame.

### Task 3: Verification and Export

**Files:**
- Modify: `export/web/index.html`
- Modify: `export/web/index.pck`

- [x] Run `test_img_debug`.
- [x] Run `test_stage02_enemies`.
- [x] Export Web.
- [x] Verify localhost responds.
- [x] Commit the code and export changes.
