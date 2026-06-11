# Stage 02 Enemy Action Sprites Design

## Goal

Replace the temporary procedural sprite motion for common Stage 02 enemies with generated animation sheets that communicate each enemy action clearly in-game and in ImgDebug. The miniboss and boss are out of scope.

## Scope

Included enemies:

- Ice Grunt
- Ice Flyer
- Ice Archer
- Frost Turret
- Cryo Bomber
- Glacier Shield
- Ice Wisp

Excluded enemies:

- Ice MiniBoss
- Cryovex or any boss

## Asset Plan

The generated sprites will match the existing side-view ice-stage enemy style, using transparent processed sheets from raw magenta-background generations.

Action sheets:

- Ice Grunt: running loop. This replaces the current walk-style loop with a more aggressive running cycle.
- Ice Flyer: keep the current hover sheet and current behavior. No new generation is required for this pass unless integration reveals the current sheet cannot support the expected hover.
- Ice Archer: shot cycle only. The archer stays planted, draws the bow, releases the arrow, and returns to ready stance.
- Frost Turret: shot cycle only. The turret stays fixed, charges or opens, fires, then settles back.
- Cryo Bomber: shot cycle only. The bomber stays planted, winds up, throws/lobs the ice bomb, then recovers.
- Glacier Shield: shield-lowering cycle. The shield drops or shifts down while the eyes glow, then returns to guarded stance.
- Ice Wisp: hover loop only. The wisp floats with a readable looping motion.

Default sheet shape is a compact multi-row grid, not a raw single-row strip. Four-frame actions use `2x2`; six-frame actions use `2x3` if the action needs more anticipation/recovery. Final runtime strips may be assembled deterministically after QC if Godot scene setup benefits from row-based frame indexing.

## Runtime Behavior

The scenes will use real `Sprite2D` frame animation instead of the temporary `_animate_sprite_motion()` transform offsets for the generated-sheet enemies.

The runtime should support:

- Looping movement animation for Ice Grunt running and Ice Wisp hover.
- Existing Ice Flyer hover behavior unchanged.
- Shot-state animation for Ice Archer, Frost Turret, and Cryo Bomber.
- A frame event for shot enemies so the projectile is spawned at the release frame, not at an arbitrary timer boundary.
- A shield action state for Glacier Shield where the shield-lowering animation and eye glow are visible.

The existing enemy AI timing can remain timer-driven, but projectile creation should be synchronized to the animation frame once a shot action starts.

## Integration

Generated and processed assets should live under `assets/generated/stage02_<enemy>/<action>/` for provenance and QC output. Runtime-ready sheets should be copied or referenced from `characters/enemies/stage_02/` using clear names such as:

- `enemy_ice_grunt_running.png`
- `enemy_ice_archer_shot.png`
- `enemy_frost_turret_shot.png`
- `enemy_cryo_bomber_shot.png`
- `enemy_glacier_shield_guard.png`
- `enemy_ice_wisp_hover.png`

Scene files should set `hframes` and `vframes` to match each accepted sheet. Scripts should expose or centralize animation frame counts and release-frame indexes so tests can assert the behavior.

## ImgDebug

ImgDebug Movimentos should show the same action cycles used in the stage. Shot enemies should be easy to validate by selecting the enemy, enabling movement/action, and seeing the shot cycle play with projectile spawn at the release moment.

The debug view does not need a separate animation browser for these enemies in this pass; it only needs to display the integrated runtime behavior accurately.

## Testing

Tests should cover:

- Each included new sheet is loadable and has the expected frame grid.
- Ice Grunt and Ice Wisp advance animation frames during their loop.
- Archer, Turret, and Bomber enter a shot state and spawn exactly one projectile at the configured release frame.
- Glacier Shield advances through the shield-lowering/eye-glow animation.
- Ice Flyer remains loadable and retains its current hover behavior.
- Stage 02 still spawns the expected enemy mix.
- ImgDebug still lists all Stage 02 enemies and can instantiate the updated scenes.

Manual verification should include Web export and a Playwright pass through ImgDebug Movimentos for at least Ice Archer, Frost Turret, Cryo Bomber, Glacier Shield, Ice Grunt, and Ice Wisp.

## Non-Goals

- No new miniboss or boss sprites.
- No new enemy types.
- No Stage 02 layout changes.
- No projectile redesign beyond syncing existing projectile spawn to shot animation frames.
