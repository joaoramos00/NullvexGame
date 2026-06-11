# ImgDebug Hitboxes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a static `Hitboxes` section to `ImgDebug` for inspecting sprites and collision shapes from characters, enemies, bosses, and projectiles.

**Architecture:** Extend the existing monolithic `ui/img_debug.gd` pattern with one focused nested view class, `_HitboxView`, plus a small `_HITBOX_ENTITIES` catalog. The view instantiates a selected scene in a `SubViewport`, collects `CollisionShape2D` descendants, draws shape overlays, and emits metadata labels.

**Tech Stack:** Godot 4.6 GDScript, existing `ImgDebug` scene, existing headless Godot test runner.

---

### Task 1: Catalog And Section Tests

**Files:**
- Modify: `tests/test_img_debug.gd`
- Modify: `ui/img_debug.gd`

- [ ] **Step 1: Write failing tests**

Add these calls in `_ready()` after `test_platform_tab_shows_panel()`:

```gdscript
test_hitbox_section_exists()
test_hitbox_catalog_loads_collision_scenes()
```

Add these tests:

```gdscript
func test_hitbox_section_exists() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    assert(panel._section_btns.has("HITBOXES"), "ImgDebug deve ter seção HITBOXES")
    panel._show_section("HITBOXES")
    assert(panel._hitboxes_box != null, "HITBOXES deve ter container")
    assert(panel._hitboxes_box.visible, "HITBOXES deve ficar visível ao selecionar")
    panel.queue_free()
    print("PASS: hitbox_section_exists")

func test_hitbox_catalog_loads_collision_scenes() -> void:
    assert(ImgDebug._HITBOX_ENTITIES.size() >= 8, "catálogo de hitboxes deve cobrir várias entidades")
    var groups := {}
    for entry in ImgDebug._HITBOX_ENTITIES:
        assert(entry.has("name"), "entrada hitbox deve ter name")
        assert(entry.has("path"), "entrada hitbox deve ter path")
        assert(entry.has("group"), "entrada hitbox deve ter group")
        groups[entry.group] = true
        var scene := load(entry.path) as PackedScene
        assert(scene != null, "cena hitbox deve carregar: " + entry.path)
        var inst := scene.instantiate()
        assert(_has_collision_shape(inst), "cena hitbox deve ter CollisionShape2D: " + entry.path)
        inst.queue_free()
    for group_name in ["Personagens", "Inimigos", "Bosses", "Projeteis"]:
        assert(groups.has(group_name), "catálogo hitbox deve incluir grupo " + group_name)
    print("PASS: hitbox_catalog_loads_collision_scenes")

func _has_collision_shape(node: Node) -> bool:
    if node is CollisionShape2D:
        return true
    for child in node.get_children():
        if _has_collision_shape(child):
            return true
    return false
```

- [ ] **Step 2: Run RED**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --disable-crash-handler --log-file test-logs/test_img_debug_hitboxes_red.log --path . res://tests/test_img_debug.tscn
```

Expected: fails because `_HITBOX_ENTITIES` and `_hitboxes_box` do not exist.

- [ ] **Step 3: Add minimal catalog and section container**

Add `_HITBOX_ENTITIES`, `_hitboxes_box`, create the `HITBOXES` section button, include it in `_show_section()`, and instantiate an empty `VBoxContainer`.

- [ ] **Step 4: Run GREEN**

Run the same command with `test_img_debug_hitboxes_catalog_green.log`.

Expected: `ALL TESTS PASSED`.

- [ ] **Step 5: Commit**

```powershell
git add ui/img_debug.gd tests/test_img_debug.gd
git commit -m "feat: add imgdebug hitbox catalog"
```

### Task 2: Hitbox Inspector View

**Files:**
- Modify: `tests/test_img_debug.gd`
- Modify: `ui/img_debug.gd`

- [ ] **Step 1: Write failing tests**

Add:

```gdscript
test_hitbox_view_inspects_representative_entities()
```

Test code:

```gdscript
func test_hitbox_view_inspects_representative_entities() -> void:
    var view := ImgDebug._HitboxView.new()
    add_child(view)
    for group_name in ["Personagens", "Inimigos", "Bosses", "Projeteis"]:
        var idx := view._find_first_group(group_name)
        assert(idx >= 0, "HitboxView deve encontrar grupo " + group_name)
        view._select_index(idx)
        assert(view._current_instance != null, "HitboxView deve instanciar " + group_name)
        assert(view._shape_infos.size() > 0, "HitboxView deve coletar shapes de " + group_name)
        assert(view._meta_label.text.contains(group_name), "metadata deve indicar grupo " + group_name)
    view.queue_free()
    print("PASS: hitbox_view_inspects_representative_entities")
```

- [ ] **Step 2: Run RED**

Expected: fails because `_HitboxView` does not exist.

- [ ] **Step 3: Implement `_HitboxView`**

Create a nested `Control` with:

- `_current_index`, `_current_instance`, `_shape_infos`.
- `_viewport`, `_world_root`, `_overlay`, `_meta_label`, `_name_label`.
- `_find_first_group(group_name)`.
- `_select_index(index)` to instantiate a scene and collect shapes.
- `_collect_shapes(root)` recursive traversal.
- `_shape_summary(shape)` for `RectangleShape2D`, `CapsuleShape2D`, `CircleShape2D`, and fallback.

- [ ] **Step 4: Run GREEN**

Run `tests/test_img_debug.tscn`; expected `ALL TESTS PASSED`.

- [ ] **Step 5: Commit**

```powershell
git add ui/img_debug.gd tests/test_img_debug.gd
git commit -m "feat: inspect hitboxes in imgdebug"
```

### Task 3: Controls, Drawing, And Export

**Files:**
- Modify: `tests/test_img_debug.gd`
- Modify: `ui/img_debug.gd`
- Modify via export: `export/web/index.html`, `export/web/index.js`, `export/web/index.pck`, `export/web/index.wasm`

- [ ] **Step 1: Write failing tests**

Extend `test_img_debug_buttons_use_web_safe_text()` by selecting `HITBOXES` before `_assert_buttons_without_fallback_symbols(panel)`. Add a direct structure assertion that the hitbox view has previous, next, filter, sprite toggle, and label toggle buttons with ASCII text.

- [ ] **Step 2: Run RED**

Expected: fails if controls are absent.

- [ ] **Step 3: Implement controls and overlay drawing**

Add toolbar buttons:

- `<` previous.
- `>` next.
- `Todos`, `Personagens`, `Inimigos`, `Bosses`, `Projeteis` filter buttons.
- `Sprite ON/OFF`.
- `Labels ON/OFF`.

Draw overlays in a `Control` child using `_draw()` for rectangles, circles, and capsules. Use the actual `CollisionShape2D.global_position` converted into viewport-local coordinates. Keep static preview centered with a ground line.

- [ ] **Step 4: Run tests**

Run:

```powershell
& "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --disable-crash-handler --log-file test-logs/test_img_debug_hitboxes_controls_green.log --path . res://tests/test_img_debug.tscn
```

Expected: `ALL TESTS PASSED`.

- [ ] **Step 5: Export Web and verify localhost**

Run:

```powershell
$godot = 'D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe'
$args = @('--headless', '--disable-crash-handler', '--log-file', 'test-logs/web_export_imgdebug_hitboxes.log', '--path', '.', '--export-debug', 'Web', 'export/web/index.html')
$p = Start-Process -FilePath $godot -ArgumentList $args -NoNewWindow -PassThru
if (-not $p.WaitForExit(120000)) { Stop-Process -Id $p.Id -Force; Write-Output "TIMEOUT_KILLED:$($p.Id)" } else { Write-Output "EXIT:$($p.ExitCode)" }
Invoke-WebRequest -Uri 'http://localhost:8000/web/index.html' -UseBasicParsing -TimeoutSec 5
```

Expected: export exits `0`, localhost returns HTTP `200`.

- [ ] **Step 6: Commit**

```powershell
git add ui/img_debug.gd tests/test_img_debug.gd export/web
git commit -m "feat: add imgdebug hitbox view"
```

## Self-Review

- Spec coverage: top-level section, broad catalog, sprite display, shape overlays, metadata, filters, and web-safe controls are covered.
- Placeholder scan: no TBD/TODO placeholders.
- Type consistency: all new names use `_HITBOX_ENTITIES`, `_hitboxes_box`, and `_HitboxView`.
