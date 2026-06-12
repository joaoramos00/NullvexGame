# ImgDebug Projectile Line Design

## Goal

Add a projectile row to the existing `ImgDebug` hitbox frame view so ranged Stage 02 enemies show their projectile on the correct release frame.

## Approved Behavior

- Keep the existing frame row and frame selection behavior.
- Add a `Projetil` row to the hitbox view.
- The row is visible for Stage 02 ranged enemies that fire projectiles.
- The projectile preview is shown only when the currently selected frame is the enemy's release frame.
- On non-release frames, the row still shows which frame fires, but no projectile is drawn in the preview.
- Cryo Bomber shows a parabolic preview for its ice ball.

## Release Frames

- Ice Archer: frame 5, zero-based index `4`.
- Frost Turret: frame 4, zero-based index `3`.
- Cryo Bomber: frame 4, zero-based index `3`, parabolic trajectory.
- Glacier Shield: frame 3, zero-based index `2`.

## Implementation Notes

- Use the existing `ImgDebug._HitboxView` frame selection path.
- Do not create a separate frame navigation flow.
- Do not change gameplay projectile timing unless tests reveal the debug view and gameplay must share the same source of truth.
- Draw the projectile overlay in the hitbox preview using simple shapes matching the existing projectile variants.
