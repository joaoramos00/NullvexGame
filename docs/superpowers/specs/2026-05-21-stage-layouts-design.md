# Stage Layouts Design — Stages 01-08

**Date:** 2026-05-21
**Scope:** Redesign layouts of stages 01-08 with thematic platforming and colored platforms.

---

## Goals

- Each stage has a distinct platforming gimmick tied to its boss's element
- Layouts include horizontal and vertical sections
- Platforms are colored per stage via `stage_scene.gd`'s `_draw()`
- No changes to gameplay systems (physics, collisions, enemies, boss AI)

---

## Technical Changes

### `stage_scene.gd`
Add `@export var platform_color: Color = Color(0.35, 0.35, 0.35)` and use it in `_draw()` instead of the hardcoded gray. Each stage's `.tscn` sets this value.

### Floor structure
Each stage replaces the single floor `StaticBody2D` with multiple floor segments to create gaps and pits. Walls (tall narrow `StaticBody2D`) are used for vertical shaft sections.

### Stage dimensions
- Total width: ~5300px (camera limit right = 5300)
- Floor y: 560 (top surface at y=540)
- Player spawn: x=200, y=400
- Boss arena: x≈4100–5100

---

## Stage Designs

### Stage 01 — Ignarath (Fogo)
**Color:** `Color(0.9, 0.3, 0.1)` — orange-red

**Gimmick:** Ascending volcano path. Platforms climb progressively from y=460 to y=220 (peak), then descend to boss. Floor has 2 gaps forcing platform use.

**Floor segments:**
- Start: 800×40 at x=400
- Mid: 600×40 at x=1900
- Pre-boss: 500×40 at x=3500
- Boss arena: 1200×40 at x=4700

**Platforms (ascending then descending):**
- x=850, y=460 — 200×20
- x=1100, y=400 — 180×20
- x=1350, y=340 — 200×20
- x=1650, y=280 — 220×20
- x=1950, y=220 — 200×20 ← peak
- x=2300, y=280 — 200×20
- x=2600, y=340 — 220×20
- x=2900, y=400 — 200×20
- x=3200, y=460 — 250×20
- x=3700, y=380 — 200×20 (pre-boss approach)

**Enemies:** 3 grunts on ascending platforms, 1 grunt on descent, 2 flyers flanking the peak.

---

### Stage 02 — Cryovex (Gelo)
**Color:** `Color(0.4, 0.8, 1.0)` — ice blue

**Gimmick:** Full floor (no gaps), but platforms are long (300–400px) and spaced very far apart horizontally (400–500px). Few platforms, long jumps — evokes sliding ice floes.

**Floor:** Single segment 5400×40 at x=2700.

**Platforms (sparse, widely spaced):**
- x=700, y=400 — 350×20
- x=1450, y=320 — 300×20
- x=2200, y=400 — 400×20
- x=3100, y=300 — 350×20
- x=3900, y=380 — 300×20

**Enemies:** 2 grunts at platform edges, 2 flyers over the wide gaps, 2 grunts on floor.

---

### Stage 03 — Voltrix (Raio)
**Color:** `Color(1.0, 0.9, 0.1)` — electric yellow

**Gimmick:** Starts horizontal, then enters a vertical lightning shaft (walls + zigzag platforms climbing 400px), then descends back to floor level.

**Floor segments:**
- Start: 1000×40 at x=500
- Post-shaft: 800×40 at x=2400
- Boss arena: 1200×40 at x=4700

**Shaft (x=1100–1600):**
- Left wall: 40×500 at x=1100, y=300
- Right wall: 40×500 at x=1600, y=300
- Shaft platforms (zigzag, 140×20):
  - x=1150, y=460 (left side)
  - x=1450, y=380 (right side)
  - x=1150, y=300 (left side)
  - x=1450, y=220 (right side) ← top

**Post-shaft platforms:**
- x=1700, y=300 — 200×20 (exit ledge)
- x=2000, y=380 — 200×20
- x=2300, y=460 — 200×20

**Enemies:** 2 grunts pre-shaft, 2 flyers inside shaft, 2 grunts post-shaft.

---

### Stage 04 — Gravitus (Gravidade)
**Color:** `Color(0.5, 0.2, 0.8)` — deep purple

**Gimmick:** Section with platforms near both floor (y=480) and ceiling (y=120), connected by narrow vertical corridors. Player must climb to ceiling-level paths and navigate back down.

**Floor segments:**
- Start: 800×40 at x=400
- Mid floor: 600×40 at x=2200
- Boss arena: 1200×40 at x=4700

**Ceiling:** StaticBody2D 5300×40 at y=60 (invisible ceiling for platforms to sit against).

**Floor-level platforms:**
- x=900, y=480 — 200×20
- x=1150, y=480 — 200×20

**Transition platforms (climbing):**
- x=1050, y=380 — 160×20
- x=1050, y=260 — 160×20
- x=1050, y=140 — 160×20 (ceiling level)

**Ceiling-level platforms:**
- x=1300, y=140 — 300×20
- x=1700, y=140 — 300×20
- x=2100, y=140 — 200×20

**Descent platforms:**
- x=2300, y=260 — 160×20
- x=2300, y=380 — 160×20
- x=2300, y=480 — 160×20

**Pre-boss platforms:**
- x=2700, y=400 — 250×20
- x=3100, y=340 — 200×20
- x=3500, y=400 — 250×20

**Enemies:** 2 grunts on floor, 2 flyers at ceiling level, 2 grunts on descent.

---

### Stage 05 — Galerix (Vento)
**Color:** `Color(0.2, 0.8, 0.5)` — wind green

**Gimmick:** Large floor gap from x=700 to x=3200 (2500px) — player traverses only on floating platforms at various heights. Evokes crossing open sky on wind currents.

**Floor segments:**
- Start: 700×40 at x=350
- Landing: 500×40 at x=3450
- Boss arena: 1200×40 at x=4700

**Aerial platforms (various heights):**
- x=750, y=440 — 200×20
- x=1000, y=360 — 180×20
- x=1220, y=280 — 160×20
- x=1440, y=360 — 180×20
- x=1680, y=440 — 200×20
- x=1900, y=340 — 160×20
- x=2120, y=240 — 180×20
- x=2360, y=340 — 180×20
- x=2600, y=440 — 200×20
- x=2840, y=360 — 180×20
- x=3080, y=460 — 200×20

**Enemies:** 1 grunt at start, 3 flyers over the aerial section, 2 grunts at landing zone.

---

### Stage 06 — Umbraex (Sombra)
**Color:** `Color(0.25, 0.1, 0.4)` — dark purple

**Gimmick:** Narrow platforms (80px wide), many of them, demanding precision. Mid-section has a low ceiling corridor creating tight vertical space.

**Floor segments:**
- Start: 400×40 at x=200
- Gap bridge area: 600×40 at x=2000
- Boss arena: 1200×40 at x=4700

**Low ceiling corridor (x=1000–1800):**
- Ceiling slab: 800×40 at x=1400, y=240

**Platforms:**
- x=500, y=460 — 80×20
- x=680, y=400 — 80×20
- x=860, y=340 — 80×20
- x=1040, y=380 — 80×20 (corridor entry)
- x=1220, y=340 — 80×20
- x=1400, y=380 — 80×20
- x=1580, y=340 — 80×20
- x=1760, y=380 — 80×20 (corridor exit)
- x=2100, y=420 — 120×20
- x=2400, y=360 — 100×20
- x=2700, y=420 — 120×20
- x=3000, y=360 — 100×20
- x=3300, y=420 — 120×20
- x=3600, y=380 — 100×20

**Enemies:** 2 grunts pre-corridor, 2 flyers in corridor, 2 grunts post-corridor.

---

### Stage 07 — Luxar (Luz)
**Color:** `Color(1.0, 0.85, 0.2)` — gold

**Gimmick:** Continuous ascending spiral — platforms climb step by step from floor to y=100. Boss arena is elevated (large platform at y=200, no floor below).

**Floor segments:**
- Start: 600×40 at x=300
- (No floor after x=600 — player must use platforms all the way)

**Boss arena platform:** 1400×40 at x=4500, y=220 (elevated, no floor below).
Luxar node: `position.y = 180`, `arena_floor = 220` (top of elevated platform).

**Ascending platforms (tight, consistent step):**
- x=700, y=460 — 200×20
- x=950, y=400 — 200×20
- x=1200, y=340 — 200×20
- x=1450, y=280 — 200×20
- x=1700, y=220 — 200×20
- x=1950, y=160 — 200×20
- x=2200, y=100 — 200×20 ← peak
- x=2500, y=140 — 200×20
- x=2800, y=180 — 200×20
- x=3100, y=220 — 200×20
- x=3400, y=200 — 250×20
- x=3750, y=200 — 200×20 (approach to elevated boss)

**Enemies:** 2 grunts on lower platforms, 2 flyers near peak, 2 grunts on approach to boss.

---

### Stage 08 — Terragor (Terra)
**Color:** `Color(0.5, 0.35, 0.15)` — earth brown

**Gimmick:** Underground cave section — floor has 2 large gaps (pits), walls form cave tunnels. Player descends into cave then ascends back out.

**Floor segments:**
- Start: 700×40 at x=350
- Cave floor (lower): 800×40 at x=1600, y=700 (lower level)
- Cave floor 2: 600×40 at x=2700, y=700
- Surface return: 600×40 at x=3500
- Boss arena: 1200×40 at x=4700

**Cave walls:**
- Left descent wall: 40×200 at x=750, y=600
- Right descent wall: 40×200 at x=1250, y=600
- Left ascent wall: 40×200 at x=3050, y=600
- Right ascent wall: 40×200 at x=3450, y=600

**Cave platforms:**
- x=850, y=620 — 200×20 (descent)
- x=1050, y=680 — 180×20
- x=1300, y=660 — 200×20 (cave floor level)
- x=2000, y=640 — 220×20
- x=2300, y=680 — 200×20
- x=2600, y=640 — 200×20
- x=2900, y=600 — 180×20 (ascent)
- x=3100, y=540 — 180×20
- x=3300, y=480 — 200×20

**Pre-boss surface platforms:**
- x=3700, y=420 — 220×20
- x=3950, y=380 — 200×20

**Camera:** Set `Camera2D.limit_bottom = 750` in the .tscn (normal stages use default ~600).

**Enemies:** 1 grunt at start, 2 grunts in cave, 1 flyer in cave, 2 grunts on ascent.

---

## Collectible Positions

Collectibles keep their types from the original plan (see CLAUDE.md). Positions updated to fit new layouts — placed on platforms the player naturally passes through, not on the floor.

---

## Enemy Placement Principles

- Grunts: on solid platforms/floor, facing the player's path
- Flyers: above gaps or vertical sections where ground is unavailable
- Total per stage: 4 grunts + 1–2 flyers (same as current)

---

## Out of Scope

- Moving platforms
- Hazard tiles (spikes, lava)
- Background art changes
- Changes to boss arenas (positions preserved)
- Touch controls layout
