# Voltrix Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Voltrix's sprite with the PixelLab winged/hover character (`a40e732b-e933-4026-bea6-7ef964f2c977`), switch its movement to hover (like Luxar), and build a 4-attack moveset from scratch.

**Architecture:** Two independent halves — an asset pipeline (download the character's existing south-only rotation + hover-loop animation, generate 3 new south-only animations via PixelLab, clean out the old humanoid sprite files) and a code rewrite of `characters/bosses/voltrix.gd` (hover movement + south-only sprite with horizontal flip + 4 named attacks), followed by a `.tscn` data change. The asset pipeline has no automated test (visual generation isn't unit-testable) — verification there is "does the downloaded PNG look right," confirmed by viewing the file. The code half is verified by the existing `test_character_base.tscn`/`test_boss_base.tscn` suite plus a manual playtest.

**Tech Stack:** Godot 4.6.2 GDScript, PixelLab v2 API (`tools/pixellab_download.py`, `tools/download_from_character.py`).

## Global Constraints

- Voltrix stays the **Raio (lightning)** elemental boss for all game logic (weakness chain, ability unlock) — only the sprite and moveset change.
- Only the **south** rotation/direction is used for every sprite in this rework — no west/east pair like the other 8 bosses.
- HP stays **40** (already set, not touched by this plan).
- `contact_damage = 2` (new, was unset/defaulting to `BossBase`'s generic 15).
- Damage per named attack: `thunder_bolt` = 3, `talon_dive` = 4, `static_pulse` = 2, `storm_barrage` = 3 (phase 2 only).
- The animations for `talon_dive`, `static_pulse`, and `storm_barrage`'s preparation poses are **out of scope** — the user builds those later. This plan only generates: entry, a generic preparation animation, and `thunder_bolt`'s attack animation (all south-only).
- Every enemy/boss in this codebase must have `contact_damage >= 1` (project-wide rule from the HP/damage rebalance) — already satisfied by `contact_damage = 2`.

---

### Task 1: Clean Old Assets + Download New Character's Base Pose and Hover Loop

**Files:**
- Delete: every file in `characters/bosses/voltrix/` (old humanoid sprite set — 15 PNGs + 15 `.import` sidecars, listed below)
- Create: `characters/bosses/voltrix/voltrix_south.png` (idle base pose)
- Create: `characters/bosses/voltrix/voltrix_hover1_south_f00.png` through `_f08.png` (9 frames)
- Create: `characters/bosses/voltrix/voltrix_hover2_south_f00.png` through `_f08.png` (9 frames)
- Create: `tools/download_voltrix_hover.py` (one-off download script for this task)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the 3 PNG sets above, which Task 3 loads by exact filename.

- [ ] **Step 1: Delete the old Voltrix sprite files**

The current folder holds the OLD humanoid design (pre-dates this rework, confirmed via file timestamps — 2026-06-01). Delete all of it:

```bash
rm -f characters/bosses/voltrix/voltrix_east.png characters/bosses/voltrix/voltrix_east.png.import \
      characters/bosses/voltrix/voltrix_entry.png characters/bosses/voltrix/voltrix_entry.png.import \
      characters/bosses/voltrix/voltrix_entry_south_f00.png characters/bosses/voltrix/voltrix_entry_south_f00.png.import \
      characters/bosses/voltrix/voltrix_entry_south_f01.png characters/bosses/voltrix/voltrix_entry_south_f01.png.import \
      characters/bosses/voltrix/voltrix_entry_south_f02.png characters/bosses/voltrix/voltrix_entry_south_f02.png.import \
      characters/bosses/voltrix/voltrix_entry_south_f03.png characters/bosses/voltrix/voltrix_entry_south_f03.png.import \
      characters/bosses/voltrix/voltrix_entry_south_f04.png characters/bosses/voltrix/voltrix_entry_south_f04.png.import \
      characters/bosses/voltrix/voltrix_entry_south_f05.png characters/bosses/voltrix/voltrix_entry_south_f05.png.import \
      characters/bosses/voltrix/voltrix_north-east.png characters/bosses/voltrix/voltrix_north-east.png.import \
      characters/bosses/voltrix/voltrix_north-west.png characters/bosses/voltrix/voltrix_north-west.png.import \
      characters/bosses/voltrix/voltrix_north.png characters/bosses/voltrix/voltrix_north.png.import \
      characters/bosses/voltrix/voltrix_south-east.png characters/bosses/voltrix/voltrix_south-east.png.import \
      characters/bosses/voltrix/voltrix_south-west.png characters/bosses/voltrix/voltrix_south-west.png.import \
      characters/bosses/voltrix/voltrix_south.png characters/bosses/voltrix/voltrix_south.png.import \
      characters/bosses/voltrix/voltrix_walk_east.png characters/bosses/voltrix/voltrix_walk_east.png.import \
      characters/bosses/voltrix/voltrix_walk_east_f00.png characters/bosses/voltrix/voltrix_walk_east_f00.png.import \
      characters/bosses/voltrix/voltrix_walk_east_f01.png characters/bosses/voltrix/voltrix_walk_east_f01.png.import \
      characters/bosses/voltrix/voltrix_walk_east_f02.png characters/bosses/voltrix/voltrix_walk_east_f02.png.import \
      characters/bosses/voltrix/voltrix_walk_east_f03.png characters/bosses/voltrix/voltrix_walk_east_f03.png.import \
      characters/bosses/voltrix/voltrix_walk_east_f04.png characters/bosses/voltrix/voltrix_walk_east_f04.png.import \
      characters/bosses/voltrix/voltrix_walk_east_f05.png characters/bosses/voltrix/voltrix_walk_east_f05.png.import \
      characters/bosses/voltrix/voltrix_walk_east_f06.png characters/bosses/voltrix/voltrix_walk_east_f06.png.import \
      characters/bosses/voltrix/voltrix_walk_east_f07.png characters/bosses/voltrix/voltrix_walk_east_f07.png.import \
      characters/bosses/voltrix/voltrix_walk_west.png characters/bosses/voltrix/voltrix_walk_west.png.import \
      characters/bosses/voltrix/voltrix_walk_west_f00.png characters/bosses/voltrix/voltrix_walk_west_f00.png.import \
      characters/bosses/voltrix/voltrix_walk_west_f01.png characters/bosses/voltrix/voltrix_walk_west_f01.png.import \
      characters/bosses/voltrix/voltrix_walk_west_f02.png characters/bosses/voltrix/voltrix_walk_west_f02.png.import \
      characters/bosses/voltrix/voltrix_walk_west_f03.png characters/bosses/voltrix/voltrix_walk_west_f03.png.import \
      characters/bosses/voltrix/voltrix_walk_west_f04.png characters/bosses/voltrix/voltrix_walk_west_f04.png.import \
      characters/bosses/voltrix/voltrix_walk_west_f05.png characters/bosses/voltrix/voltrix_walk_west_f05.png.import \
      characters/bosses/voltrix/voltrix_walk_west_f06.png characters/bosses/voltrix/voltrix_walk_west_f06.png.import \
      characters/bosses/voltrix/voltrix_walk_west_f07.png characters/bosses/voltrix/voltrix_walk_west_f07.png.import \
      characters/bosses/voltrix/voltrix_west.png characters/bosses/voltrix/voltrix_west.png.import
```

- [ ] **Step 2: Verify the folder is empty**

Run: `ls characters/bosses/voltrix/`
Expected: empty output (or "No such file or directory" if the folder itself got removed — recreate it with `mkdir -p characters/bosses/voltrix` if so).

- [ ] **Step 3: Write the one-off download script**

Create `tools/download_voltrix_hover.py`:

```python
#!/usr/bin/env python3
"""One-off downloader: Voltrix's new character base pose + existing hover-loop animations.

Fetches the south rotation (idle pose) and the two already-generated "Flutuar1"/"Flutuar2"
animation groups (9 frames each, south direction) directly by URL. These predate this script —
they were generated in an earlier PixelLab session, not by animate_character here.
"""
from pathlib import Path
import urllib.request

DEST = Path("characters/bosses/voltrix")
DEST.mkdir(parents=True, exist_ok=True)

ROTATION_SOUTH_URL = "https://backblaze.pixellab.ai/file/pixellab-characters/a9da7a16-f3eb-4cf3-9cd5-75a1df14979e/a40e732b-e933-4026-bea6-7ef964f2c977/rotations/south.png"

HOVER1_FRAME_URLS = [
    f"https://backblaze.pixellab.ai/file/pixellab-characters/a9da7a16-f3eb-4cf3-9cd5-75a1df14979e/a40e732b-e933-4026-bea6-7ef964f2c977/animations/b563441e-abc1-4387-9e6d-4d3f2a44135e/south/{i}.png"
    for i in range(9)
]
HOVER2_FRAME_URLS = [
    f"https://backblaze.pixellab.ai/file/pixellab-characters/a9da7a16-f3eb-4cf3-9cd5-75a1df14979e/a40e732b-e933-4026-bea6-7ef964f2c977/animations/1180ac10-8d05-49a8-b879-63b1e29a6d30/south/{i}.png"
    for i in range(9)
]


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "voltrix-downloader/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def main() -> None:
    print("Downloading base pose (south)...")
    (DEST / "voltrix_south.png").write_bytes(fetch(ROTATION_SOUTH_URL))
    print("  Saved voltrix_south.png")

    for i, url in enumerate(HOVER1_FRAME_URLS):
        data = fetch(url)
        (DEST / f"voltrix_hover1_south_f{i:02d}.png").write_bytes(data)
        print(f"  Saved voltrix_hover1_south_f{i:02d}.png")

    for i, url in enumerate(HOVER2_FRAME_URLS):
        data = fetch(url)
        (DEST / f"voltrix_hover2_south_f{i:02d}.png").write_bytes(data)
        print(f"  Saved voltrix_hover2_south_f{i:02d}.png")

    print("Done.")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run the download script**

Run: `python tools/download_voltrix_hover.py`
Expected: 19 "Saved ..." lines (1 base pose + 9 hover1 + 9 hover2), no errors. If any URL returns an HTTP error (backblaze links can expire), re-fetch the current URLs with `mcp__pixellab__get_character(character_id="a40e732b-e933-4026-bea6-7ef964f2c977")` and update the URLs in the script before retrying — the `?t=...` query parameter is a timestamp token that can go stale.

- [ ] **Step 5: Verify the downloaded base pose visually**

Use the Read tool on `characters/bosses/voltrix/voltrix_south.png` and confirm it shows the winged green/gold robot (matching the character analyzed during brainstorming) — not a blank/corrupt image.

- [ ] **Step 6: Commit**

```bash
git add characters/bosses/voltrix/ tools/download_voltrix_hover.py
git commit -m "feat(voltrix): remove old sprite set, add new character base pose + hover loop"
```

---

### Task 2: Generate the 3 New Animations (Entry, Preparation, Thunder Bolt)

**Files:**
- Modify: `tools/pixellab_download.py:158` (extend `--action` choices)
- Create: `characters/bosses/voltrix/voltrix_entrada_south_f00.png` through last frame (+ `.gif`)
- Create: `characters/bosses/voltrix/voltrix_preparacao_south_f00.png` through last frame (+ `.gif`)
- Create: `characters/bosses/voltrix/voltrix_thunderbolt_south_f00.png` through last frame (+ `.gif`)

**Interfaces:**
- Consumes: `a40e732b-e933-4026-bea6-7ef964f2c977` (character_id, same as Task 1).
- Produces: 3 new south-only frame sets that Task 3 loads by exact filename prefix (`voltrix_entrada_south`, `voltrix_preparacao_south`, `voltrix_thunderbolt_south`).

- [ ] **Step 1: Extend the download script's allowed action names**

In `tools/pixellab_download.py`, find this line (around line 158):
```python
    p_anim.add_argument("--action", required=True, choices=["walk", "idle", "attack", "death", "hit", "dash", "shoot"])
```
Replace with:
```python
    p_anim.add_argument("--action", required=True, choices=["walk", "idle", "attack", "death", "hit", "dash", "shoot", "entrada", "preparacao", "thunderbolt"])
```

- [ ] **Step 2: Generate the entry animation**

Call the `mcp__pixellab__animate_character` tool (or the raw `POST /v2/animate-character` endpoint per the pixellab skill) with:
```json
{
  "character_id": "a40e732b-e933-4026-bea6-7ef964f2c977",
  "action_description": "boss entrance, flying in from off-screen and landing in a hovering combat stance, dramatic entry",
  "directions": ["south"],
  "frame_count": 8,
  "mode": "v3"
}
```
Record the `background_job_ids[0]` value (call it `ENTRY_JOB_ID`).

- [ ] **Step 3: Download the entry animation**

Run: `python tools/pixellab_download.py animation ENTRY_JOB_ID characters/bosses/voltrix/ --direction south --action entrada`
(Replace `ENTRY_JOB_ID` with the actual id from Step 2. This polls automatically, ~2-3 min.)
Expected: frame PNGs saved as `voltrix_entrada_south_f00.png` … and a `voltrix_entrada_south.gif` preview.

- [ ] **Step 4: Generate the preparation animation**

Call `mcp__pixellab__animate_character` with:
```json
{
  "character_id": "a40e732b-e933-4026-bea6-7ef964f2c977",
  "action_description": "charging up electric energy before an attack, wings spreading, body glowing with building charge, windup pose",
  "directions": ["south"],
  "frame_count": 8,
  "mode": "v3"
}
```
Record `background_job_ids[0]` (call it `PREP_JOB_ID`).

- [ ] **Step 5: Download the preparation animation**

Run: `python tools/pixellab_download.py animation PREP_JOB_ID characters/bosses/voltrix/ --direction south --action preparacao`
Expected: `voltrix_preparacao_south_f00.png` … + `.gif`.

- [ ] **Step 6: Generate the thunder_bolt attack animation**

Call `mcp__pixellab__animate_character` with:
```json
{
  "character_id": "a40e732b-e933-4026-bea6-7ef964f2c977",
  "action_description": "firing a quick bolt of lightning straight ahead from an outstretched claw, no windup, instant discharge",
  "directions": ["south"],
  "frame_count": 6,
  "mode": "v3"
}
```
Record `background_job_ids[0]` (call it `BOLT_JOB_ID`).

- [ ] **Step 7: Download the thunder_bolt animation**

Run: `python tools/pixellab_download.py animation BOLT_JOB_ID characters/bosses/voltrix/ --direction south --action thunderbolt`
Expected: `voltrix_thunderbolt_south_f00.png` … + `.gif`.

- [ ] **Step 8: Verify all 3 GIFs visually**

Use the Read tool on `voltrix_entrada_south.gif`, `voltrix_preparacao_south.gif`, `voltrix_thunderbolt_south.gif` and confirm each plays a sensible loop matching its description (entry = flying in and landing; preparation = charging/glowing; thunder_bolt = quick discharge with no windup).

- [ ] **Step 9: Commit**

```bash
git add characters/bosses/voltrix/ tools/pixellab_download.py
git commit -m "feat(voltrix): generate entry, preparation, and thunder_bolt animations"
```

---

### Task 3: Rewrite voltrix.gd — Hover Movement + South-Only Sprite

**Files:**
- Modify: `characters/bosses/voltrix.gd` (complete rewrite)
- Test: `tests/test_boss_base.tscn`, `tests/test_character_base.tscn` (existing, headless)

**Interfaces:**
- Consumes: frame counts from Task 1/2's downloads (hover1 = 9 frames, hover2 = 9 frames, entrada = 8 frames requested, preparacao = 8 frames requested, thunderbolt = 6 frames requested — confirm actual counts by listing the downloaded files before hardcoding `_HOVER1_FRAMES` etc., since PixelLab sometimes returns one more frame than requested per the pixellab skill's notes).
- Produces: `_facing: float` (existing pattern, reused), `AnimState` enum consumed by Task 4's attack functions to trigger `preparacao`/`thunderbolt` playback.

- [ ] **Step 1: Count actual downloaded frames**

Run: `ls characters/bosses/voltrix/voltrix_hover1_south_f*.png | wc -l && ls characters/bosses/voltrix/voltrix_hover2_south_f*.png | wc -l && ls characters/bosses/voltrix/voltrix_entrada_south_f*.png | wc -l && ls characters/bosses/voltrix/voltrix_preparacao_south_f*.png | wc -l && ls characters/bosses/voltrix/voltrix_thunderbolt_south_f*.png | wc -l`
Record each count — use these exact numbers in Step 2's constants (do not assume the requested `frame_count` matches the delivered count).

- [ ] **Step 2: Rewrite characters/bosses/voltrix.gd**

Replace the entire file with (substituting `<HOVER1_N>`, `<HOVER2_N>`, `<ENTRADA_N>`, `<PREPARACAO_N>`, `<THUNDERBOLT_N>` with the counts from Step 1):

```gdscript
extends BossBase

enum AnimState { HOVER1, HOVER2, ENTRADA, PREPARACAO, THUNDERBOLT }

const _HOVER1_FRAMES      := <HOVER1_N>
const _HOVER2_FRAMES      := <HOVER2_N>
const _ENTRADA_FRAMES     := <ENTRADA_N>
const _PREPARACAO_FRAMES  := <PREPARACAO_N>
const _THUNDERBOLT_FRAMES := <THUNDERBOLT_N>
const _ANIM_FPS := 10.0

# Cada anim eh uma sequencia de sprites individuais (nao um spritesheet horizontal
# como os outros bosses) -- carregamos os frames num Array e trocamos a textura
# do Sprite2D a cada tick, em vez de usar hframes/frame.
var _hover1_frames: Array[Texture2D] = []
var _hover2_frames: Array[Texture2D] = []
var _entrada_frames: Array[Texture2D] = []
var _preparacao_frames: Array[Texture2D] = []
var _thunderbolt_frames: Array[Texture2D] = []

var _anim_state: AnimState = AnimState.HOVER1
var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _facing: float = -1.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	super._ready()
	gravity_scale = 0.0
	_load_frame_arrays()

func _load_frame_arrays() -> void:
	for i in _HOVER1_FRAMES:
		_hover1_frames.append(load("res://characters/bosses/voltrix/voltrix_hover1_south_f%02d.png" % i))
	for i in _HOVER2_FRAMES:
		_hover2_frames.append(load("res://characters/bosses/voltrix/voltrix_hover2_south_f%02d.png" % i))
	for i in _ENTRADA_FRAMES:
		_entrada_frames.append(load("res://characters/bosses/voltrix/voltrix_entrada_south_f%02d.png" % i))
	for i in _PREPARACAO_FRAMES:
		_preparacao_frames.append(load("res://characters/bosses/voltrix/voltrix_preparacao_south_f%02d.png" % i))
	for i in _THUNDERBOLT_FRAMES:
		_thunderbolt_frames.append(load("res://characters/bosses/voltrix/voltrix_thunderbolt_south_f%02d.png" % i))

func _draw() -> void:
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	draw_rect(Rect2(-24, -52, 48, 6), Color.BLACK)
	draw_rect(Rect2(-24, -52, 48.0 * pct, 6), Color.GREEN)

func _face_player() -> void:
	pass

func _physics_process(delta: float) -> void:
	super(delta)
	_update_animation(delta)

func _current_frame_array() -> Array[Texture2D]:
	match _anim_state:
		AnimState.HOVER2:      return _hover2_frames
		AnimState.ENTRADA:     return _entrada_frames
		AnimState.PREPARACAO:  return _preparacao_frames
		AnimState.THUNDERBOLT: return _thunderbolt_frames
		_:                     return _hover1_frames

func _update_animation(delta: float) -> void:
	if state == State.INTRO:
		_play_state(AnimState.ENTRADA)
	elif state in [State.DYING, State.DEAD]:
		return
	elif _anim_state == AnimState.ENTRADA:
		# Intro acabou (state saiu de INTRO) mas a entrada ainda nao foi trocada
		# de volta -- acontece uma vez, na primeira _update_animation em COMBAT.
		_play_state(AnimState.HOVER1)
	elif _anim_state in [AnimState.PREPARACAO, AnimState.THUNDERBOLT]:
		pass  # ataque em andamento, deixa terminar (ver _play_state)
	else:
		# Sem asas/pernas de andar -- so alterna HOVER1<->HOVER2 (loop continuo),
		# nunca ha "parado" vs "andando" como nos outros bosses.
		if velocity.x >  10.0: _facing =  1.0
		elif velocity.x < -10.0: _facing = -1.0
	_sprite.scale.x = absf(_sprite.scale.x) * (1.0 if _facing > 0.0 else -1.0)
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var a := 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, a)
	else:
		_sprite.modulate = Color.WHITE
	var frames := _current_frame_array()
	if frames.is_empty():
		return
	_anim_timer += delta
	if _anim_timer >= 1.0 / _ANIM_FPS:
		_anim_timer -= 1.0 / _ANIM_FPS
		_anim_frame += 1
		if _anim_frame >= frames.size():
			if _anim_state in [AnimState.ENTRADA, AnimState.PREPARACAO, AnimState.THUNDERBOLT]:
				_anim_frame = frames.size() - 1  # segura no ultimo frame, quem chamou decide quando voltar pro hover
			else:
				_anim_frame = 0
				_anim_state = AnimState.HOVER2 if _anim_state == AnimState.HOVER1 else AnimState.HOVER1
				frames = _current_frame_array()
	_sprite.texture = frames[_anim_frame]

# Toca uma animacao nao-hover do inicio (chamado pelo intro e pelos ataques).
func _play_state(new_state: AnimState) -> void:
	if _anim_state == new_state:
		return
	_anim_state = new_state
	_anim_frame = 0
	_anim_timer = 0.0

func _do_combat(delta: float) -> void:
	if player == null:
		return
	var dx := player.global_position.x - global_position.x
	var target_y := player.global_position.y - 120.0
	var dy := target_y - global_position.y
	velocity.x = sign(dx) * 90.0 if abs(dx) > 220.0 else 0.0
	velocity.y = sign(dy) * 70.0 if abs(dy) > 30.0 else 0.0
	_clamp_to_arena()

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.2
```

- [ ] **Step 3: Verify the file parses**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/bosses/voltrix.gd`
Expected: no parse errors printed (this mode doesn't load autoloads, so any error about `GameManager`/`AudioManager` being undefined is unrelated noise to ignore — only look for GDScript syntax/type errors).

- [ ] **Step 4: Run the boss test suite**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_boss_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0. (This test suite exercises `BossBase` generically — it doesn't instantiate Voltrix specifically, so it verifies the shared contract still holds, not Voltrix's new code directly.)

- [ ] **Step 5: Commit**

```bash
git add characters/bosses/voltrix.gd
git commit -m "feat(voltrix): hover movement + south-only sprite animation system"
```

---

### Task 4: Implement the 4 Named Attacks

**Files:**
- Modify: `characters/bosses/voltrix.gd` (add attack functions to the file from Task 3)

**Interfaces:**
- Consumes: `AnimState` enum and `_play_state()` from Task 3.
- Produces: nothing consumed by later tasks (this is the last code task).

- [ ] **Step 1: Add damage constants and attack-selection logic**

In `characters/bosses/voltrix.gd`, add near the top (after the existing frame-count consts):

```gdscript
const _THUNDER_BOLT_DAMAGE   := 3
const _TALON_DIVE_DAMAGE     := 4
const _STATIC_PULSE_DAMAGE   := 2
const _STORM_BARRAGE_DAMAGE  := 3
const _MELEE_RANGE           := 200.0
```

Add `_do_attack()`, replacing any existing stub (there isn't one yet in this file since Task 3's rewrite didn't include it):

```gdscript
var _last_close_attack_was_dive: bool = false

func _do_attack() -> void:
	_is_attacking = true
	if player == null:
		_is_attacking = false
		return
	var dist := global_position.distance_to(player.global_position)
	if dist > _MELEE_RANGE:
		if phase >= 2:
			await _do_storm_barrage()
		else:
			await _do_thunder_bolt()
	else:
		_last_close_attack_was_dive = not _last_close_attack_was_dive
		if _last_close_attack_was_dive:
			await _do_talon_dive()
		else:
			await _do_static_pulse()
	_is_attacking = false
```

- [ ] **Step 2: Implement `_do_thunder_bolt()` (no preparation)**

```gdscript
func _do_thunder_bolt() -> void:
	_play_state(AnimState.THUNDERBOLT)
	await get_tree().create_timer(float(_THUNDERBOLT_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		return
	if player != null:
		var dir: float = sign(player.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0
		_spawn_projectile(
			global_position, Vector2(dir * 620.0, 0.0),
			_THUNDER_BOLT_DAMAGE, "voltrix", Color(1.0, 0.95, 0.0)
		)
	_play_state(AnimState.HOVER1)
```

- [ ] **Step 3: Implement `_do_storm_barrage()` (phase 2, expands thunder_bolt)**

```gdscript
func _do_storm_barrage() -> void:
	_play_state(AnimState.THUNDERBOLT)
	await get_tree().create_timer(float(_THUNDERBOLT_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		return
	if player != null:
		var dir: float = sign(player.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0
		var spread := 0.3
		for i in 3:
			var angle: float = (float(i) - 1.0) * spread
			var vel := Vector2(dir * 620.0, 0.0).rotated(angle)
			_spawn_projectile(global_position, vel, _STORM_BARRAGE_DAMAGE, "voltrix", Color(0.6, 0.9, 1.0))
	_play_state(AnimState.HOVER1)
```

- [ ] **Step 4: Implement `_do_talon_dive()` and `_do_static_pulse()` (with preparation — reuses PREPARACAO animation as a stand-in until the user's own prep animations are ready)**

```gdscript
func _do_talon_dive() -> void:
	_play_state(AnimState.PREPARACAO)
	await get_tree().create_timer(float(_PREPARACAO_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		return
	if player != null:
		var dir: float = sign(player.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0
		velocity = Vector2(dir * 500.0, (player.global_position.y - global_position.y) * 2.0)
		await get_tree().create_timer(0.35).timeout
		if is_dead:
			return
		if player != null and global_position.distance_to(player.global_position) < 60.0:
			player.take_damage(_TALON_DIVE_DAMAGE, "voltrix")
		velocity = Vector2.ZERO
	_play_state(AnimState.HOVER1)

func _do_static_pulse() -> void:
	_play_state(AnimState.PREPARACAO)
	await get_tree().create_timer(float(_PREPARACAO_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		return
	if player != null and global_position.distance_to(player.global_position) < 140.0:
		player.take_damage(_STATIC_PULSE_DAMAGE, "voltrix")
	_play_state(AnimState.HOVER1)
```

(Note: `_do_talon_dive` and `_do_static_pulse` both play `AnimState.PREPARACAO` since their own dedicated windup animations are the out-of-scope item the user builds later — see the spec's "Fora de Escopo" section. When those exist, swap in dedicated `AnimState` entries and textures the same way Task 3 wired `PREPARACAO`/`THUNDERBOLT`.)

- [ ] **Step 5: Verify the file parses and the test suite still passes**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script characters/bosses/voltrix.gd`
Expected: no syntax/type errors (ignore autoload-undefined noise, same as Task 3 Step 3).

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_boss_base.tscn`
Expected: `ALL TESTS PASSED`, exit code 0.

- [ ] **Step 6: Commit**

```bash
git add characters/bosses/voltrix.gd
git commit -m "feat(voltrix): implement 4-attack moveset (thunder_bolt, talon_dive, static_pulse, storm_barrage)"
```

---

### Task 5: Update voltrix.tscn (contact_damage) + Manual Verification

**Files:**
- Modify: `characters/bosses/voltrix.tscn:12-13`

**Interfaces:**
- Consumes: nothing new.
- Produces: nothing consumed by later tasks (final task).

- [ ] **Step 1: Add contact_damage to the scene**

In `characters/bosses/voltrix.tscn`, replace:
```
max_hp = 40
boss_color = Color(1.0, 0.9, 0.0, 1)
```
with:
```
max_hp = 40
boss_color = Color(1.0, 0.9, 0.0, 1)
contact_damage = 2
```

- [ ] **Step 2: Verify**

Run: `grep -n "max_hp\|contact_damage" characters/bosses/voltrix.tscn`
Expected: `max_hp = 40`, `contact_damage = 2`.

- [ ] **Step 3: Run the full existing regression suite**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_boss_base.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_intro_boss.tscn
```
Expected: all 5 green (matches the state from the prior HP/damage rebalance — nothing here should regress them, since this task only touches Voltrix-specific files).

- [ ] **Step 4: Manual playtest note**

This plan has no automated test for "does Voltrix look and play right in the actual level" — Godot scene/animation behavior at this level of visual polish needs a human or browser-driven look. After this task, open Stage 03 in the Godot editor (or via the `run` skill if available) and confirm: Voltrix hovers instead of standing on the floor, faces the player correctly (flips via `scale.x`), and each of the 4 attacks plays a distinct animation without crashing. Report back rather than assuming — this step cannot be verified from a headless test run.

- [ ] **Step 5: Commit**

```bash
git add characters/bosses/voltrix.tscn
git commit -m "feat(voltrix): set contact_damage=2"
```
