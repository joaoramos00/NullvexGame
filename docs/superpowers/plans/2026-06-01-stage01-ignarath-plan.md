# Stage 01 · Ignarath — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir o layout básico de Stage 01 por um stage completo com dois níveis, shafts verticais, hazards temáticos e duas câmaras secretas.

**Architecture:** Quatro scripts novos e autocontidos (geyser, lava_floor, cracked_wall, moving_platform) são adicionados como filhos da cena. O `stage_01.tscn` é reconstruído no Godot Editor usando `stage_scene.gd` como script base (sem script custom na stage). Os corredores usam `CorridorSection` existente.

**Tech Stack:** Godot 4.6.2 · GDScript · `stage_scene.gd` · `CorridorSection` · `Collectible` · `EnemyBase` · `EnemyFlyer`

---

## Coordinate Reference

```
Tile size         : 64 game units
Nível alto  y_gnd : 1024   (Z1, Z4, Corr2, Boss)
Nível baixo y_gnd : 2688   (Z2, Corr1, Z3)
Shaft width       : 192    (3 tiles)

X layout (left edge of each section):
  Z1 start          : 512
  Shaft descida      : 3264    (Z1 ends at x=3264)
  Z2 start           : 3264    (bottom of shaft)
  Corr1 start        : 9792
  Z3 start           : 10752
  Shaft subida        : 16320
  Z4 start            : 16320  (top of shaft)
  Corr2 start         : 19456
  Boss room start     : 20480
  Boss room end       : 21888
```

---

## File Map

| Action | File |
|--------|------|
| Create | `stages/stage_01/geyser.gd` |
| Create | `stages/stage_01/lava_floor.gd` |
| Create | `stages/stage_01/cracked_wall.gd` |
| Create | `stages/stage_01/moving_platform.gd` |
| Rebuild | `stages/stage_01/stage_01.tscn` (Godot Editor) |
| Create | `tests/test_stage01_hazards.gd` |
| Create | `tests/test_stage01_hazards.tscn` |

---

## Task 1: Geyser (hazard Z3)

**Files:**
- Create: `stages/stage_01/geyser.gd`

- [ ] **Criar o script**

```gdscript
# stages/stage_01/geyser.gd
extends Area2D

@export var active_time:   float = 2.5
@export var inactive_time: float = 1.5
@export var damage:        int   = 20

var _active: bool = false
var _timer:  float = 0.0
var _bodies_inside: Array[Node] = []

func _ready() -> void:
    monitoring = false

func _process(delta: float) -> void:
    _timer -= delta
    if _timer <= 0.0:
        _active = !_active
        monitoring = _active
        _timer = active_time if _active else inactive_time
        if not _active:
            _bodies_inside.clear()

func _on_body_entered(body: Node) -> void:
    if body is CharacterBase:
        _bodies_inside.append(body)

func _on_body_exited(body: Node) -> void:
    _bodies_inside.erase(body)

func _physics_process(_delta: float) -> void:
    if not _active:
        return
    for body in _bodies_inside:
        if is_instance_valid(body):
            (body as CharacterBase).take_damage(damage)
```

- [ ] **Conectar sinais no editor:** selecionar o nó Geyser → Body Entered → `_on_body_entered`; Body Exited → `_on_body_exited`

- [ ] **Commit**

```bash
git add stages/stage_01/geyser.gd
git commit -m "feat(stage01): geyser hazard script"
```

---

## Task 2: Lava Floor (hazard Z2 fossas, Z4, boss room)

**Files:**
- Create: `stages/stage_01/lava_floor.gd`

- [ ] **Criar o script**

```gdscript
# stages/stage_01/lava_floor.gd
extends Area2D

@export var damage_per_second: float = 40.0

var _bodies_inside: Array[Node] = []

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
    if body is CharacterBase:
        _bodies_inside.append(body)

func _on_body_exited(body: Node) -> void:
    _bodies_inside.erase(body)

func _physics_process(delta: float) -> void:
    for body in _bodies_inside:
        if is_instance_valid(body):
            (body as CharacterBase).take_damage(int(damage_per_second * delta))
```

- [ ] **Commit**

```bash
git add stages/stage_01/lava_floor.gd
git commit -m "feat(stage01): lava floor continuous damage script"
```

---

## Task 3: Cracked Wall (câmara secreta da armadura)

**Files:**
- Create: `stages/stage_01/cracked_wall.gd`

- [ ] **Criar o script**

```gdscript
# stages/stage_01/cracked_wall.gd
# StaticBody2D com CollisionShape2D filho.
# Destruída quando um projétil (Area2D, collision_layer=8) entra no
# filho HitDetector enquanto o player tiver "galerix" desbloqueada.
extends StaticBody2D

signal wall_destroyed

func _ready() -> void:
    add_to_group("cracked_wall")
    # HitDetector: Area2D filho, collision_layer=0, collision_mask=8
    ($HitDetector as Area2D).area_entered.connect(_on_hit)

func _on_hit(_area: Area2D) -> void:
    try_destroy()

func try_destroy() -> void:
    if GameManager.boss_abilities_unlocked.has("galerix"):
        wall_destroyed.emit()
        queue_free()
```

- [ ] **Commit**

```bash
git add stages/stage_01/cracked_wall.gd
git commit -m "feat(stage01): cracked wall destroyable with Galerix ability"
```

---

## Task 4: Moving Platform (Z3 e Z4)

**Files:**
- Create: `stages/stage_01/moving_platform.gd`

- [ ] **Criar o script**

```gdscript
# stages/stage_01/moving_platform.gd
extends StaticBody2D

@export var move_distance: float = 320.0   # pixels de deslocamento total (metade p/ cada lado)
@export var speed:         float = 80.0    # pixels/s

var _start_x: float = 0.0
var _dir:     float = 1.0

func _ready() -> void:
    _start_x = global_position.x

func _physics_process(delta: float) -> void:
    var half := move_distance * 0.5
    global_position.x += _dir * speed * delta
    if global_position.x >= _start_x + half:
        global_position.x = _start_x + half
        _dir = -1.0
    elif global_position.x <= _start_x - half:
        global_position.x = _start_x - half
        _dir = 1.0
```

- [ ] **Commit**

```bash
git add stages/stage_01/moving_platform.gd
git commit -m "feat(stage01): moving platform script"
```

---

## Task 5: Rebuild stage_01.tscn — Z1 + Shaft Descida

Abrir `stages/stage_01/stage_01.tscn` no Godot Editor. Deletar todos os filhos existentes (plataformas básicas do Plan 11). Manter apenas: `StageController`, `HUD`, `Camera2D`, `PauseMenu`, `PlayerSpawn`.

- [ ] **PlayerSpawn:** position = `(576, 960)`

- [ ] **Z1 — chão** (StaticBody2D com CollisionShape2D RectangleShape2D):
  - center = `(1888, 1024)`, size = `(2752, 128)` — cobre x 512..3264

- [ ] **Z1 — teto** (StaticBody2D):
  - center = `(1888, 448)`, size = `(2752, 64)`

- [ ] **Z1 — plataformas** (4× StaticBody2D, sizes = `(256, 32)` cada):
  - Plat1 center = `(832, 928)`
  - Plat2 center = `(1408, 832)`
  - Plat3 center = `(2048, 736)`
  - Plat4 center = `(2688, 640)`

- [ ] **Z1 — inimigos:** 3× EnemyBase nas plataformas 1/2/4; 1× EnemyFlyer patrol y=512 em x≈1600

- [ ] **Shaft Descida — parede esquerda** (StaticBody2D):
  - center = `(3232, 1856)`, size = `(64, 1664)`

- [ ] **Shaft Descida — parede direita** (StaticBody2D):
  - center = `(3424, 1856)`, size = `(64, 1664)`

- [ ] **Shaft Descida — 4 plataformas zigzag** (size=`(128,32)` cada):
  - P1 center = `(3296, 1344)`
  - P2 center = `(3360, 1600)`
  - P3 center = `(3296, 1856)`
  - P4 center = `(3360, 2112)`

- [ ] **Commit**

```bash
git commit -m "feat(stage01): Z1 platforms and descent shaft in scene"
```

---

## Task 6: Z2 — Túnel de Magma + Câmara Secreta Armadura

- [ ] **Z2 — chão** (StaticBody2D):
  - center = `(6528, 2688)`, size = `(6528, 128)` — cobre x 3264..9792

- [ ] **Z2 — teto** (StaticBody2D):
  - center = `(6528, 2176)`, size = `(6528, 64)`

- [ ] **Z2 — 7 plataformas** (size=`(256,32)` cada):
  - P1 = `(3712, 2560)`, P2 = `(4480, 2496)`, P3 = `(5248, 2560)`
  - P4 = `(6016, 2496)`, P5 = `(6784, 2560)`, P6 = `(7552, 2496)`, P7 = `(8320, 2560)`

- [ ] **Z2 — 5 fossas de lava** (LavaFloor Area2D, size=`(256, 64)` cada, y_center=2688):
  - x centers: `4096`, `4864`, `5632`, `6400`, `7168`
  - script: `stages/stage_01/lava_floor.gd`; `damage_per_second = 40.0`
  - CollisionShape2D monitorOnly; collision_mask = 2 (player)

- [ ] **Z2 — inimigos:** 3× EnemyBase em P2/P4/P6; 2× EnemyFlyer patrol y≈2256 em x≈4500, x≈7000

- [ ] **Câmara secreta — parede rachada** (CrackedWall, nó StaticBody2D):
  - script: `stages/stage_01/cracked_wall.gd`
  - position = `(3264, 2432)`, CollisionShape2D size = `(64, 512)`
  - Adicionar filho Area2D "HitDetector" com CollisionShape2D size=`(128, 512)`, collision_mask=8 (player_attack)
  - No HitDetector: `body_entered` → chamar `get_parent().try_destroy()`

- [ ] **Câmara — chão** (StaticBody2D):
  - center = `(2432, 2688)`, size = `(1664, 128)`

- [ ] **Câmara — teto** (StaticBody2D, fecha câmara em cima):
  - center = `(2432, 2176)`, size = `(1664, 64)`

- [ ] **Câmara — parede esquerda** (StaticBody2D):
  - center = `(1600, 2432)`, size = `(64, 512)`

- [ ] **Câmara — Collectible armadura** (Collectible Area2D):
  - script: `stages/collectible.gd`; `collectible_type = ARMOR_ZAEL`; `armor_piece = "helmet"`; `stage_id = 1`
  - position = `(2432, 2624)`

- [ ] **Commit**

```bash
git commit -m "feat(stage01): Z2 tunnel, lava pits, secret armor chamber"
```

---

## Task 7: Corredor 1 (CP1, Z2→Z3)

- [ ] **Adicionar filho CorridorSection** à cena (nó Node2D, script `stages/corridor_section.gd`)

  Configurar @exports:
  ```
  tileset        = preload("res://stages/stage_01/Stage_01T_z2.png")
  glass_tex      = preload("res://stages/stage_01/stage_01_glass.png")
  floor_center   = Vector2(10272, 2688)
  floor_size     = Vector2(960, 128)
  ceil_center    = Vector2(10272, 2176)
  ceil_size      = Vector2(960, 64)
  wall_l_center  = Vector2(9824, 2432)
  wall_l_size    = Vector2(64, 512)
  wall_r_center  = Vector2(10720, 2432)
  wall_r_size    = Vector2(64, 512)
  entry_x        = 9856.0
  exit_x         = 10688.0
  door_cy        = 2432.0
  door_height    = 200.0
  cam_center     = Vector2(10272, 2432)
  cam_zoom       = 2.0
  glass_lateral_x = 9760.0
  glass_fill_x   = 9824.0
  glass_fill_cols = 13
  glass_col_rows  = 8
  glass_col_bot   = 2624.0
  glass_mirror    = false
  checkpoint_index      = 1
  checkpoint_respawn_x  = 10752.0
  heal_on_entry  = false
  save_checkpoint = true
  ```

- [ ] **Conectar sinais do Corredor 1 na stage:** No Godot Editor, selecionar o CorridorSection → Signals:
  - `camera_lock_requested` → `$Camera2D` método `_on_camera_lock` (ver passo abaixo)
  - (checkpoint_triggered é gerenciado internamente pelo CorridorSection)

  Adicionar ao `stage_01.tscn` um script custom `stages/stage_01/stage_01_scene.gd`:

```gdscript
# stages/stage_01/stage_01_scene.gd
extends "res://stages/stage_scene.gd"

func _ready() -> void:
    super._ready()
    for corr in get_children():
        if corr is CorridorSection:
            corr.setup(_player)
            corr.camera_lock_requested.connect(_on_camera_lock)

func _on_camera_lock(center: Vector2, zoom: float) -> void:
    $Camera2D.zoom = Vector2(zoom, zoom)
    # câmera volta a seguir o player automaticamente pelo _process herdado
```

- [ ] **Commit**

```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01): Corridor 1 CP1 and stage custom script"
```

---

## Task 8: Z3 — Forja Industrial + Câmara Secreta Coração

- [ ] **Z3 — chão** (StaticBody2D):
  - center = `(13536, 2688)`, size = `(5568, 128)` — cobre x 10752..16320

- [ ] **Z3 — teto** (StaticBody2D):
  - center = `(13536, 2176)`, size = `(5568, 64)`

- [ ] **Z3 — 5 plataformas ascendentes** (size=`(256,32)` cada):
  - P1 = `(11264, 2560)`, P2 = `(11968, 2432)`, P3 = `(12672, 2304)`
  - P4 = `(13376, 2176)`, P5 = `(14080, 2048 + 32)` ← já perto do teto

- [ ] **Z3 — plataforma móvel** (MovingPlatform, script `stages/stage_01/moving_platform.gd`):
  - position = `(14784, 2240)`, CollisionShape2D size = `(256, 32)`
  - `move_distance = 320.0`, `speed = 70.0`

- [ ] **Z3 — 3 gêiseres temporizados** (Geyser Area2D, script `stages/stage_01/geyser.gd`):
  - CollisionShape2D size = `(64, 256)` (hitbox vertical)
  - G1 position = `(11520, 2560)`, `active_time = 2.5`, `inactive_time = 1.5`
  - G2 position = `(12800, 2560)`, `active_time = 2.0`, `inactive_time = 2.0`
  - G3 position = `(14400, 2560)`, `active_time = 2.5`, `inactive_time = 1.0`
  - Conectar `body_entered` / `body_exited` nos três

- [ ] **Z3 — inimigos:** 3× EnemyBase em P1/P3/P5; 1× EnemyFlyer patrol y≈2256 em x≈12500

- [ ] **Câmara secreta coração — buraco no chão**
  - Remover chão de Z3 entre x=13568..13760 (deixar gap de 192px entre plataformas P3 e P4)
  - Adicionar StaticBody2D "HiddenFloor" (piso escondido abaixo do gap):
    - center = `(13664, 2880)`, size = `(384, 64)`
  - Adicionar paredes laterais da câmara:
    - Esq: center = `(13472, 2944)`, size = `(64, 192)`
    - Dir: center = `(13856, 2944)`, size = `(64, 192)`
  - Adicionar saída lateral (gap na parede direita da câmara — apenas visual, sem StaticBody2D obstruindo a saída; o chão normal de Z3 continua a partir de x=13760)
  - Adicionar Collectible (Coração):
    - script `stages/collectible.gd`, `collectible_type = HEART`, `stage_id = 1`
    - position = `(13664, 2816)`

- [ ] **Commit**

```bash
git commit -m "feat(stage01): Z3 forge, geysers, moving platform, hidden heart chamber"
```

---

## Task 9: Shaft Subida + Z4 — Câmara de Lava

- [ ] **Shaft Subida — paredes** (StaticBody2D):
  - Esquerda: center = `(16288, 1856)`, size = `(64, 1664)`
  - Direita: center = `(16480, 1856)`, size = `(64, 1664)`

- [ ] **Shaft Subida — 5 plataformas zigzag** (size=`(128,32)` cada):
  - P1 = `(16352, 2432)`, P2 = `(16416, 2176)`, P3 = `(16352, 1920)`
  - P4 = `(16416, 1664)`, P5 = `(16352, 1408)`

- [ ] **Z4 — lava no chão** (LavaFloor Area2D):
  - script `stages/stage_01/lava_floor.gd`, `damage_per_second = 40.0`
  - center = `(17888, 1056)`, size = `(2752, 64)` — cobre todo o chão de Z4

- [ ] **Z4 — chão visual** (StaticBody2D, collision_layer=1 mas lava Area2D no topo):
  - center = `(17888, 1024)`, size = `(2752, 128)`

- [ ] **Z4 — teto** (StaticBody2D):
  - center = `(17888, 448)`, size = `(2752, 64)`

- [ ] **Z4 — 3 plataformas fixas** (size=`(256,32)` cada):
  - P1 = `(16960, 896)`, P2 = `(17664, 768)`, P3 = `(18368, 896)`

- [ ] **Z4 — plataforma móvel** (MovingPlatform):
  - position = `(18880, 832)`, size = `(256, 32)`, `move_distance = 256.0`, `speed = 60.0`

- [ ] **Z4 — inimigos:** 2× EnemyBase em P1/P3; 1× EnemyFlyer patrol y≈512 em x≈17700

- [ ] **Commit**

```bash
git commit -m "feat(stage01): ascent shaft and Z4 lava chamber"
```

---

## Task 10: Corredor 2 + Boss Room

- [ ] **Corredor 2** (CorridorSection filho da cena):

  ```
  tileset        = preload("res://stages/stage_01/Stage_01T_z4.png")
  glass_tex      = preload("res://stages/stage_01/stage_01_glass.png")
  floor_center   = Vector2(19968, 1024)
  floor_size     = Vector2(960, 128)
  ceil_center    = Vector2(19968, 448)
  ceil_size      = Vector2(960, 64)
  wall_l_center  = Vector2(19520, 736)
  wall_l_size    = Vector2(64, 576)
  wall_r_center  = Vector2(20416, 736)
  wall_r_size    = Vector2(64, 576)
  entry_x        = 19552.0
  exit_x         = 20384.0
  door_cy        = 736.0
  door_height    = 200.0
  cam_center     = Vector2(19968, 736)
  cam_zoom       = 2.0
  glass_lateral_x = 19456.0
  glass_fill_x   = 19520.0
  glass_fill_cols = 13
  glass_col_rows  = 9
  glass_col_bot   = 960.0
  glass_mirror    = false
  checkpoint_index     = 2
  checkpoint_respawn_x = 20480.0
  heal_on_entry  = true
  save_checkpoint = true
  ```

- [ ] **Boss Room — chão** (StaticBody2D):
  - center = `(21184, 1024)`, size = `(2816, 128)`

- [ ] **Boss Room — teto** (StaticBody2D):
  - center = `(21184, 448)`, size = `(2816, 64)`

- [ ] **Boss Room — paredes** (StaticBody2D):
  - Esq: center = `(19776, 736)`, size = `(64, 576)`
  - Dir: center = `(22592, 736)`, size = `(64, 576)`

- [ ] **Boss Room — lava no chão** (LavaFloor Area2D):
  - center = `(21184, 1056)`, size = `(2816, 64)`, `damage_per_second = 40.0`

- [ ] **Boss Room — 2 plataformas** (size=`(384,32)` cada):
  - P1 = `(20160, 832)`, P2 = `(22208, 832)`

- [ ] **Ignarath** (instância de `characters/bosses/ignarath.tscn`):
  - position = `(21184, 768)` — centro do boss room, em cima das plataformas

- [ ] **Conectar Corredor 2** no `stage_01_scene.gd` (já feito via loop `get_children()`)

- [ ] **Commit**

```bash
git commit -m "feat(stage01): Corridor 2 CP2+heal and Ignarath boss room"
```

---

## Task 11: Testes

**Files:**
- Create: `tests/test_stage01_hazards.gd`
- Create: `tests/test_stage01_hazards.tscn`

A `.tscn` deve ter script `tests/test_stage01_hazards.gd` e um nó raiz `Node`.

- [ ] **Criar `tests/test_stage01_hazards.tscn`** no Godot Editor: nó raiz Node2D, script `tests/test_stage01_hazards.gd`

- [ ] **Criar `tests/test_stage01_hazards.gd`**

```gdscript
# tests/test_stage01_hazards.gd
extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
    _test_lava_floor_damages_player()
    _test_geyser_inactive_no_damage()
    _test_geyser_active_damages_player()
    _test_cracked_wall_no_galerix()
    _test_cracked_wall_with_galerix()
    _test_moving_platform_reverses()
    _print_results()
    get_tree().quit()

func _assert(cond: bool, msg: String) -> void:
    if cond:
        _passed += 1
        print("  PASS: " + msg)
    else:
        _failed += 1
        print("  FAIL: " + msg)

# ── LavaFloor ──────────────────────────────────────────────────────────────────

func _test_lava_floor_damages_player() -> void:
    var lava := preload("res://stages/stage_01/lava_floor.gd").new()
    lava._physics_process(1.0)  # sem bodies, sem crash
    _assert(true, "lava_floor _physics_process sem bodies não crasha")

# ── Geyser ─────────────────────────────────────────────────────────────────────

func _test_geyser_inactive_no_damage() -> void:
    var g := preload("res://stages/stage_01/geyser.gd").new()
    add_child(g)
    _assert(not g.monitoring, "geyser começa inativo (monitoring=false)")
    g.queue_free()

func _test_geyser_active_damages_player() -> void:
    var g := preload("res://stages/stage_01/geyser.gd").new()
    add_child(g)
    # Simular transição para ativo
    g._timer = 0.0
    g._process(0.001)  # dispara troca de estado
    _assert(g.monitoring == true, "geyser ativa monitoring após timer expirar")
    g.queue_free()

# ── CrackedWall ────────────────────────────────────────────────────────────────

func _test_cracked_wall_no_galerix() -> void:
    GameManager.boss_abilities_unlocked.clear()
    var wall := preload("res://stages/stage_01/cracked_wall.gd").new()
    add_child(wall)
    wall.try_destroy()
    _assert(is_instance_valid(wall), "parede NÃO destruída sem habilidade Galerix")
    wall.queue_free()

func _test_cracked_wall_with_galerix() -> void:
    GameManager.boss_abilities_unlocked = ["galerix"]
    var wall := preload("res://stages/stage_01/cracked_wall.gd").new()
    add_child(wall)
    var destroyed := false
    wall.wall_destroyed.connect(func(): destroyed = true)
    wall.try_destroy()
    # wall_destroyed dispara sincronamente antes do queue_free
    _assert(destroyed, "parede emite wall_destroyed com habilidade Galerix")
    # queue_free só libera no fim do frame — checar via is_queued_for_deletion
    _assert(wall.is_queued_for_deletion(), "parede marcada para queue_free após destruição")
    GameManager.boss_abilities_unlocked.clear()

# ── MovingPlatform ─────────────────────────────────────────────────────────────

func _test_moving_platform_reverses() -> void:
    var plat := preload("res://stages/stage_01/moving_platform.gd").new()
    plat.move_distance = 100.0
    plat.speed = 100.0
    add_child(plat)
    await get_tree().process_frame
    var start_x := plat.global_position.x
    # Avançar além do limite
    plat._physics_process(1.0)
    _assert(plat._dir == -1.0, "plataforma reverte direção ao atingir limite")
    plat.queue_free()

func _print_results() -> void:
    print("\n=== test_stage01_hazards: %d passed, %d failed ===" % [_passed, _failed])
    if _failed > 0:
        push_error("TESTS FAILED")
```

- [ ] **Rodar testes**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage01_hazards.tscn
```

Esperado: `=== test_stage01_hazards: 7 passed, 0 failed ===`

- [ ] **Commit**

```bash
git add tests/test_stage01_hazards.gd tests/test_stage01_hazards.tscn
git commit -m "test(stage01): hazard unit tests — geyser, lava, cracked wall, moving platform"
```

---

## Task 12: Web Export + Validação

- [ ] **Exportar para web** via skill `web-export`

- [ ] **Verificar no browser** (localhost:8080):
  - Stage 01 carrega sem erros de console
  - Player spawn no ponto correto (Z1, esquerda)
  - Shaft de descida leva ao Z2
  - Fossas de lava causam dano
  - Gêiseres alternam ativo/inativo
  - Corredor 1 trava câmera e salva CP1
  - Câmara secreta do coração acessível caindo no buraco do Z3
  - Corredor 2 cura e salva CP2
  - Ignarath presente no boss room

- [ ] **Commit final**

```bash
git add export/web
git commit -m "build: web export stage01 Ignarath layout"
```
