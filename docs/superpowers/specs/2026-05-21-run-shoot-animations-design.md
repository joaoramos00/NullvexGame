# Run & Shoot Animations Design

**Date:** 2026-05-21
**Scope:** New running sprites for Zael and Zara; Zael shoot animation with visible charge levels.

---

## Goals

- Replace walk animation with a distinct running animation for both characters
- Add 3-frame shoot animation for Zael that visually reflects charge level in real time
- No changes to physics, combat systems, or other characters

---

## Sprite Generation (Pixel Lab API)

### ZaelCorrendo.png
- **Dimensions:** 340×68 px (5 frames × 68×68)
- **Style:** HD pixel art, side-scrolling platformer character
- **Description:** Zael running — body leaning forward, legs in dynamic running cycle, blue armour with white accents, right-facing (will be flipped for left)

### ZaraCorrendo.png
- **Dimensions:** 340×68 px (5 frames × 68×68)
- **Style:** HD pixel art, same style as ZaelCorrendo
- **Description:** Zara running — body leaning forward, hair flowing back, red armour, sword in hand, right-facing

### ZaelAtirando.png
- **Dimensions:** 204×68 px (3 frames × 68×68)
- **Style:** HD pixel art
- **Frame 0 (level 1):** Zael aiming, faint blue glow at weapon tip — normal shot
- **Frame 1 (level 2):** Medium glow, energy aura around arm — mid charge
- **Frame 2 (level 3):** Full-body intense glow/aura — full charge

---

## Technical Changes

### `characters/ranged/zael.gd`

**Constants removed:** `_FIGHT_FRAME_W`, `_FIGHT_FRAME_H`, `_FIGHT_ROW` (no longer needed)

**`_setup_sprite_frames`:**
- `"walk"` animation renamed to `"run"`, loads 5 frames from `ZaelCorrendo.png` at 8fps
- `"idle"` and `"jump"` remain on `ZaelAndando.png` frame 2 (unchanged)
- `"shoot"` animation: 3 frames from `ZaelAtirando.png` (68×68 each), 8fps, loop=false

**`_update_animation`:**
- `_sprite.play("walk")` → `_sprite.play("run")`
- Added charging branch (before run/idle checks):
  ```gdscript
  elif _is_charging:
      var level := get_charge_level(_charge_timer)
      _sprite.play("shoot")
      _sprite.set_frame_and_progress(level - 1, 0.0)
      _sprite.stop()
  ```

**`_fire(level)`:**
- `_sprite.play("shoot")` + `_sprite.set_frame_and_progress(level - 1, 0.0)` (no stop — lets animation play through as a flash)

### `characters/melee/zara.gd`

**`_setup_sprite_frames`:**
- `"walk"` renamed to `"run"`, loads 5 frames from `ZaraCorrendo.png` at 8fps
- `"idle"`, `"jump"`, `"attack"` remain on `ZaraAndando.png` (unchanged)

**`_update_animation`:**
- `_sprite.play("walk")` → `_sprite.play("run")`

### `ui/character_select.gd`

- Preview textures load from `ZaelCorrendo.png` and `ZaraCorrendo.png` instead of `ZaelAndando.png`/`ZaraAndando.png`
- Frame count stays 5, constants `_FRAME_W=68`, `_FRAME_H=68`, `_ROW_RIGHT=0` unchanged

---

## Behaviour Summary

| State | Zael | Zara |
|-------|------|------|
| Idle | ZaelAndando frame 2 | ZaraAndando frame 2 |
| Running | ZaelCorrendo 5-frame cycle | ZaraCorrendo 5-frame cycle |
| Jumping | ZaelAndando frame 2 | ZaraAndando frame 2 |
| Charging (hold attack) | ZaelAtirando frozen at level frame | — |
| Shoot fired | ZaelAtirando plays from level frame | — |
| Attack | — | ZaraAndando frame 0 |

---

## Out of Scope

- New idle or jump sprites
- Zara shoot/charge animation
- Changes to ZaelLutando.png (file kept but no longer used by shoot animation)
- Animation blending or transitions
