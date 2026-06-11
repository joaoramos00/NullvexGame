# ImgDebug Hitboxes Design

## Goal

Add a new `Hitboxes` section to `ImgDebug` for static inspection of scene collision shapes. The section helps validate whether character, enemy, boss, miniboss, and projectile hitboxes line up with their sprites without running movement physics.

## Scope

- Add `Hitboxes` as a top-level section beside existing `Sprites`, `Tiles`, and `Movimentos` panels.
- Show one entity at a time in a static preview with a floor/reference line.
- Include scenes that expose `CollisionShape2D`, covering characters, common enemies, stage 02 enemies, minibosses, bosses, and projectiles.
- Draw the sprite or animated sprite if the scene has one.
- Draw collision overlays for the main shape and nested shape groups such as `ContactZone`, `BodyHurtbox`, `PunchZone`, and `Head`.
- Show readable shape metadata: node path, shape type, position, and relevant dimensions.
- Keep all button/control text web-safe ASCII to avoid browser fallback glyph boxes.

## Out Of Scope

- Editing hitbox values from the UI.
- Simulating movement, attacks, physics, or projectile travel.
- Replacing the existing `Movimentos` screen.
- Adding new sprites or changing gameplay collision values as part of this feature.

## UI Design

The section uses the existing `ImgDebug` layout style. It has a compact toolbar with previous/next controls, a group filter, and toggles for sprite visibility and shape labels. The main preview area displays the selected scene centered over a ground/reference line.

The metadata panel lists the selected entity name, scene path, and detected shapes. Each shape entry uses the same color as its overlay:

- Main `CollisionShape2D`: yellow.
- `ContactZone`: cyan.
- Hurtbox/body-specific groups: magenta or orange.
- Other collision shapes: white.

## Data Model

Create a small catalog entry per inspectable scene:

- Display name.
- Scene path.
- Group: `Personagens`, `Inimigos`, `Bosses`, or `Projeteis`.

The runtime inspector instantiates the selected scene in a `SubViewport`, finds supported sprite nodes, collects `CollisionShape2D` descendants, and draws overlays from the actual shape resources. Unsupported shapes should still appear in metadata with a clear unsupported marker rather than breaking the panel.

## Testing

Add tests in `tests/test_img_debug.gd` to verify:

- The `Hitboxes` section is registered in the `ImgDebug` UI.
- The hitbox catalog contains loadable scenes and each listed scene has at least one `CollisionShape2D`.
- The panel can instantiate and inspect at least one character, one enemy, one boss, and one projectile.
- Button/control text remains web-safe.

## Acceptance Criteria

- Opening `ImgDebug` shows a `Hitboxes` section at the same level as the existing debug sections.
- The user can cycle through entities and filter by group.
- The selected entity renders with sprite and collision overlays.
- Metadata updates when the entity changes.
- Existing `ImgDebug` tests still pass.
