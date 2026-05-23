# Skills Locais e GAME_CONTEXT — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar `GAME_CONTEXT.md` com referência completa do jogo e 5 skills locais em `.claude/skills/` para scaffolding de inimigos, bosses, stages, execução de testes e export web.

**Architecture:** Skills são arquivos `.md` em `.claude/skills/` com templates de código inline. `GAME_CONTEXT.md` na raiz é referenciado no `CLAUDE.md`. Nenhuma dependência externa — apenas markdown e edições em JSON/md existentes.

**Tech Stack:** Markdown, GDScript 4, Godot 4.6.2, JSON

---

## Arquivos Criados/Modificados

| Arquivo | Ação |
|---------|------|
| `GAME_CONTEXT.md` | Criar |
| `.claude/skills/new-enemy.md` | Criar |
| `.claude/skills/new-boss.md` | Criar |
| `.claude/skills/new-stage.md` | Criar |
| `.claude/skills/run-tests.md` | Criar |
| `.claude/skills/web-export.md` | Criar |
| `CLAUDE.md` | Modificar — adicionar seção Skills e link GAME_CONTEXT |
| `.claude/settings.json` | Modificar — registrar skills |

---

### Task 1: GAME_CONTEXT.md

**Files:**
- Create: `GAME_CONTEXT.md`

- [ ] **Step 1: Criar GAME_CONTEXT.md na raiz do projeto**

```markdown
# NullvexGame — Contexto do Jogo

Referência completa para Claude. Leia este arquivo antes de criar ou modificar qualquer parte do jogo.

---

## Visão Geral

- **Engine:** Godot 4.6.2 (GDScript)
- **Resolução:** 1920×1080
- **Godot exe:** `D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe`
- **Gênero:** Plataforma/ação 2D — Mega Man X4 como referência
- **Personagens:** Zael (ranged, tiro carregável) e Zara (melee, combo)
- **Fases:** 00 (intro) → 01-08 (stage select) → 09-11 (finais)
- **Bosses:** 8 elementais + Nullvex (10/11) + IntroBoss (00)

---

## Collision Layers (project.godot)

| Layer | Nome | Valor | Usado por |
|-------|------|-------|-----------|
| 1 | world | 1 | StaticBody2D (terreno) |
| 2 | player | 2 | CharacterBase |
| 3 | enemy | 4 | EnemyBase, BossBase |
| 4 | player_attack | 8 | ZaelBullet, hitboxes de Zara |

**Referência rápida:**
- Inimigo: `collision_layer=4, collision_mask=1`
- Player: `collision_layer=2, collision_mask=1`
- Bala do player: `collision_layer=8, collision_mask=5` (world + enemy)
- ContactZone do inimigo (detecta player): `collision_layer=0, collision_mask=2`

---

## Autoloads — APIs Completas

### GameManager
```gdscript
GameManager.active_character          # "zael" ou "zara"
GameManager.max_hp                    # int — HP máximo atual
GameManager.lives                     # int — vidas restantes
GameManager.reset()                   # reseta para estado inicial
GameManager.set_active_character(c)   # "zael" | "zara"
GameManager.complete_stage(id: int)   # marca fase como completa
GameManager.unlock_ability(id: String)
GameManager.has_save() -> bool
GameManager.save_game()
GameManager.load_game()
```

### StageManager
```gdscript
StageManager.current_stage_id         # int (-1 = nenhuma)
StageManager.spawn_position           # Vector2
StageManager.save_checkpoint(pos: Vector2, idx: int)
StageManager.get_respawn_position() -> Vector2
StageManager.load_stage(id: int)
```

### AudioManager
```gdscript
AudioManager.play_bgm(stream)   # null = silêncio (safe)
AudioManager.play_sfx(stream)   # null = no-op (safe)
```

### AudioLibrary (streams, atribuir no editor)
```gdscript
AudioLibrary.bgm_intro
AudioLibrary.get_stage_bgm(id: int) -> AudioStream
AudioLibrary.sfx_enemy_death
AudioLibrary.sfx_boss_damage
AudioLibrary.sfx_boss_death
AudioLibrary.sfx_jump
AudioLibrary.sfx_shoot
AudioLibrary.sfx_collectible
```

---

## Tabela de Bosses

| stage_id | boss_id | weakness_id | ability_id | boss_color |
|----------|---------|-------------|------------|------------|
| 1 | ignarath | galerix | ignarath | Color(0.9, 0.3, 0.0) |
| 2 | cryovex | ignarath | cryovex | Color(0.3, 0.7, 1.0) |
| 3 | voltrix | terragor | voltrix | Color(1.0, 0.9, 0.0) |
| 4 | gravitus | luxar | gravitus | Color(0.5, 0.0, 0.8) |
| 5 | galerix | gravitus | galerix | Color(0.4, 0.9, 0.4) |
| 6 | umbraex | voltrix | umbraex | Color(0.2, 0.0, 0.3) |
| 7 | luxar | umbraex | luxar | Color(1.0, 1.0, 0.6) |
| 8 | terragor | cryovex | terragor | Color(0.5, 0.3, 0.1) |

Cadeia de fraquezas: `Gravitus→Galerix→Ignarath→Cryovex→Terragor→Voltrix→Umbraex→Luxar→Gravitus`

---

## EnemyBase — Padrão de Código

**Arquivo base:** `characters/enemies/enemy_base.gd` + `enemy_base.tscn`

```gdscript
# Estrutura mínima de um novo inimigo
extends EnemyBase
class_name EnemyXxx

func _draw() -> void:
    var c := Color.WHITE if _hit_flash_timer > 0.0 else Color(R, G, B)
    draw_rect(Rect2(-20, -40, 40, 80), c)  # tamanho padrão grunt
```

**Cenas herdadas de enemy_base.tscn:**
- `CollisionShape2D` — CapsuleShape2D(radius=20, height=40), layer=4, mask=1
- `ContactZone` — Area2D(layer=0, mask=2) → `_on_contact` → `body.take_damage(contact_damage)`

**Variáveis disponíveis (não redeclare):**
`max_hp`, `contact_damage`, `current_hp`, `is_dead`, `_direction`, `_invincible`,
`_invincibility_timer`, `_hit_flash_timer`, `GRAVITY`, `PATROL_SPEED`,
`INVINCIBILITY_DURATION`, `HIT_FLASH_DURATION`

**Métodos disponíveis (pode sobrescrever):**
`_physics_process(delta)`, `_draw()`, `_has_floor_ahead() -> bool`, `take_damage(amount, _source="")`

---

## BossBase — Padrão de Código

**Arquivo base:** `characters/bosses/boss_base.gd` + `boss_base.tscn`
- `boss_base.tscn`: CapsuleShape2D(radius=24, height=80), layer=4, mask=1

**@exports obrigatórios (definir no .tscn):**
```gdscript
@export var boss_id: String = ""
@export var weakness_id: String = ""
@export var ability_id: String = ""
@export var stage_id: int = -1
@export var max_hp: int = 200
@export var boss_color: Color = Color.DARK_RED
```

**@exports opcionais (com defaults razoáveis):**
```gdscript
@export var arena_left: float = 100.0
@export var arena_right: float = 1820.0
@export var arena_floor: float = 500.0
@export var attack_interval_p1: float = 2.5
@export var attack_interval_p2: float = 1.5
@export var phase2_threshold: float = 0.5
@export var intro_duration: float = 1.0
@export var death_duration: float = 1.5
```

**Métodos para sobrescrever:**
```gdscript
func _do_combat(delta: float) -> void:   # movimento durante combate
func _do_attack() -> void:               # executa um ataque
func _enter_phase_2() -> void:           # transição para fase 2
```

**Métodos utilitários disponíveis:**
```gdscript
_face_player()       # scale.x aponta para player
_clamp_to_arena()    # limita posição entre arena_left e arena_right
_spawn_projectile(pos, vel, dmg, src, col)  # instancia boss_projectile.tscn
```

**Variáveis disponíveis:**
`current_hp`, `state` (IDLE/INTRO/COMBAT/DYING/DEAD), `phase` (1 ou 2),
`player` (referência ao CharacterBase), `_is_attacking`, `_attack_timer`

---

## Stage Simples (stages 01–08) — Padrão

**Script:** usa `stage_scene.gd` — não cria GD customizado.

**Nós obrigatórios na cena:**
```
StageRoot (Node2D, script=stage_scene.gd, platform_color=Color(...))
├── PlayerSpawn (Node2D, position=Vector2(200, Y))
├── StageController (instance stage_controller.tscn)
├── Checkpoint1 (instance checkpoint.tscn, position=..., checkpoint_index=1)
├── Checkpoint2 (instance checkpoint.tscn, position=..., checkpoint_index=2)
├── <BossName> (instance boss.tscn, arena_left=..., arena_right=..., arena_floor=...)
├── <plataformas> (StaticBody2D + CollisionShape2D + RectangleShape2D)
├── <inimigos> (instance enemy_base.tscn ou enemy_flyer.tscn)
├── <colectáveis> (instance collectible.tscn com propriedades)
├── HUD (instance hud.tscn)
├── PauseMenu (instance pause_menu.tscn)
├── GameOver (instance game_over.tscn)
├── StageComplete (instance stage_complete.tscn)
└── Camera2D (limit_left=0, limit_top=0, limit_bottom=1080, limit_right=<total_width>)
```

**Caminhos de recursos:**
```
res://stages/stage_controller.tscn
res://stages/checkpoint.tscn
res://stages/collectible.tscn
res://ui/hud.tscn
res://ui/pause_menu.tscn
res://ui/game_over.tscn
res://ui/stage_complete.tscn
```

---

## Stage Complexo (stage_00) — Padrão

**Script:** GD customizado `extends Node2D` (NÃO usa stage_scene.gd).

**Estrutura chave:**
- Constantes de posição: `ZONE1_GRUNTS`, `ZONE1_FLYERS`, `ZONE2_GRUNTS`... (Arrays de Vector2)
- Constantes de portas: `CP1_ENTRY_X`, `CP1_EXIT_X`, `CP2_ENTRY_X`, `CP2_EXIT_X`
- Boss room selado: `Boss_LWall` com collision disabled até boss door abrir
- Zone triggers (Area2D invisible) detectam player → respawn inimigos da zona
- `_draw()` com background temático + `_draw_platform_tiles()` com tileset

**Nós obrigatórios no .tscn além das plataformas:**
```
Boss_LWall (StaticBody2D, collision disabled no _ready())
Boss_RWall (StaticBody2D)
Boss_Floor (StaticBody2D)
Boss_Ceil (StaticBody2D)
GoalZone (Area2D, collision_layer=0, mask=2)
Camera2D (limit_left=0, limit_top=<topo>, limit_bottom=<base>, limit_right=<fim>)
```

---

## Padrão de Testes

```gdscript
extends Node

func _ready() -> void:
    test_caso_1()
    test_caso_2()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_caso_1() -> void:
    var obj = _spawn()
    assert(obj.propriedade == esperado, "mensagem de erro")
    obj.queue_free()
    print("PASS: caso_1")

func _spawn() -> TipoBase:
    var scene := load("res://path/to/scene.tscn")
    var inst: TipoBase = scene.instantiate()
    add_child(inst)
    return inst
```

**.tscn de teste:**
```
[gd_scene format=3]
[ext_resource type="Script" path="res://tests/test_xxx.gd" id="1"]
[node name="TestXxx" type="Node"]
script = ExtResource("1")
```

**Rodar teste individual:**
```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_xxx.tscn
```

**Saída esperada:** última linha deve ser `ALL TESTS PASSED` e exit code 0.

---

## Convenções de Nomenclatura

| Tipo | Exemplo GD | Exemplo TSCN | Pasta |
|------|-----------|-------------|-------|
| Inimigo | `enemy_jumper.gd` | `enemy_jumper.tscn` | `characters/enemies/` |
| Boss | `pyrovex.gd` | `pyrovex.tscn` | `characters/bosses/` |
| Stage simples | — | `stage_12.tscn` | `stages/stage_12/` |
| Stage complexo | `stage_12_scene.gd` | `stage_12.tscn` | `stages/stage_12/` |
| Teste | `test_enemy_jumper.gd` | `test_enemy_jumper.tscn` | `tests/` |

**UIDs:** Sempre declarar `uid="uid://<nome>"` no cabeçalho do .tscn.

---

## Erros Comuns

- `take_damage` do enemy aceita `(amount: int, _source: String = "")` — passar 2 args é OK
- `body_entered` em Area2D não dispara para overlaps pré-existentes ao spawn → usar `get_overlapping_bodies()` como fallback
- `params.exclude` em PhysicsRayQueryParameters2D exige `Array[RID]` tipado — não passar Array genérico
- Testes usam `extends Node`, NÃO `extends SceneTree` — SceneTree não carrega autoloads
- Export web: caminho correto é `export/web/index.html`, não `.godot/exported/`
```

- [ ] **Step 2: Verificar seções**

Ler `GAME_CONTEXT.md` e confirmar que contém: "Collision Layers", "Tabela de Bosses", "EnemyBase", "BossBase", "Stage Simples", "Stage Complexo", "Padrão de Testes", "Convenções".

- [ ] **Step 3: Commit**

```bash
git add GAME_CONTEXT.md
git commit -m "docs: GAME_CONTEXT.md com referência completa do jogo"
```

---

### Task 2: Skill new-enemy

**Files:**
- Create: `.claude/skills/new-enemy.md`

- [ ] **Step 1: Criar pasta .claude/skills/ se não existir**

```bash
mkdir -p .claude/skills
```

- [ ] **Step 2: Criar .claude/skills/new-enemy.md**

```markdown
# Skill: new-enemy

Use quando o usuário pedir para criar um novo tipo de inimigo.

## Informações a Coletar

Pergunte ao usuário (uma por vez se não fornecidas):
1. **nome** — snake_case, ex: `enemy_jumper`
2. **cor** — Color GDScript, ex: `Color(0.8, 0.2, 0.2)`
3. **comportamento** — escolha: `ground_patrol` | `flyer` | `jumper` | `shooter`

## Arquivos a Criar

Substituir `<nome>` pelo nome informado (ex: `enemy_jumper`):

1. `characters/enemies/<nome>.gd`
2. `characters/enemies/<nome>.tscn`
3. `tests/test_<nome>.gd`
4. `tests/test_<nome>.tscn`

## Templates por Comportamento

### ground_patrol

`characters/enemies/<nome>.gd`:
```gdscript
extends EnemyBase
class_name <NomePascal>

func _draw() -> void:
    var c := Color.WHITE if _hit_flash_timer > 0.0 else <cor>
    draw_rect(Rect2(-20, -40, 40, 80), c)
```
Não sobrescreve `_physics_process` — usa o da base (patrol + ledge detection + gravity).

---

### flyer

`characters/enemies/<nome>.gd`:
```gdscript
extends EnemyBase
class_name <NomePascal>

@export var patrol_range: float = 150.0

var _start_x: float = 0.0

func _ready() -> void:
    super._ready()
    _start_x = global_position.x

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    if _invincibility_timer > 0.0:
        _invincibility_timer -= delta
        if _invincibility_timer <= 0.0:
            _invincible = false
    velocity.x = PATROL_SPEED * _direction
    velocity.y = 0.0
    move_and_slide()
    if abs(global_position.x - _start_x) >= patrol_range:
        _direction = -_direction

func _draw() -> void:
    var c := Color.WHITE if _hit_flash_timer > 0.0 else <cor>
    draw_rect(Rect2(-20, -28, 40, 56), c)
```

---

### jumper

`characters/enemies/<nome>.gd`:
```gdscript
extends EnemyBase
class_name <NomePascal>

const JUMP_SPEED := 500.0
const JUMP_INTERVAL := 2.0

var _jump_timer: float = JUMP_INTERVAL

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if is_dead:
        return
    _jump_timer -= delta
    if _jump_timer <= 0.0 and is_on_floor():
        velocity.y = -JUMP_SPEED
        _jump_timer = JUMP_INTERVAL

func _draw() -> void:
    var c := Color.WHITE if _hit_flash_timer > 0.0 else <cor>
    draw_rect(Rect2(-20, -40, 40, 80), c)
```

---

### shooter

`characters/enemies/<nome>.gd`:
```gdscript
extends EnemyBase
class_name <NomePascal>

const _PROJECTILE_SCENE := preload("res://characters/bosses/boss_projectile.tscn")
const SHOOT_INTERVAL := 2.5
const SHOOT_SPEED := 250.0
const SHOOT_DAMAGE := 10

var _shoot_timer: float = SHOOT_INTERVAL

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if is_dead:
        return
    _shoot_timer -= delta
    if _shoot_timer <= 0.0:
        _shoot_timer = SHOOT_INTERVAL
        _fire()

func _fire() -> void:
    if _PROJECTILE_SCENE == null:
        return
    var p = _PROJECTILE_SCENE.instantiate()
    p.global_position = global_position
    p.projectile_velocity = Vector2(_direction * SHOOT_SPEED, 0.0)
    p.damage = SHOOT_DAMAGE
    p.source_id = ""
    p.color = <cor>
    get_parent().add_child(p)

func _draw() -> void:
    var c := Color.WHITE if _hit_flash_timer > 0.0 else <cor>
    draw_rect(Rect2(-20, -40, 40, 80), c)
```

---

## Template .tscn

`characters/enemies/<nome>.tscn`:
```
[gd_scene format=3 uid="uid://<nome>"]

[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="1_base"]
[ext_resource type="Script" path="res://characters/enemies/<nome>.gd" id="2_script"]

[node name="<NomePascal>" instance=ExtResource("1_base")]
script = ExtResource("2_script")
```

Para **flyer**, adicionar `patrol_range = 150.0` após `script = ...`.

---

## Template de Teste

`tests/test_<nome>.gd`:
```gdscript
extends Node

func _ready() -> void:
    test_initial_hp()
    test_take_damage()
    test_invincibility()
    test_death()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_initial_hp() -> void:
    var e = _spawn()
    assert(e.current_hp == e.max_hp)
    assert(not e.is_dead)
    e.queue_free()
    print("PASS: initial_hp")

func test_take_damage() -> void:
    var e = _spawn()
    e.take_damage(2)
    assert(e.current_hp == e.max_hp - 2)
    e.queue_free()
    print("PASS: take_damage")

func test_invincibility() -> void:
    var e = _spawn()
    e.take_damage(1)
    e.take_damage(1)  # bloqueado por invencibilidade
    assert(e.current_hp == e.max_hp - 1)
    e.queue_free()
    print("PASS: invincibility")

func test_death() -> void:
    var e = _spawn()
    var died_flag := [false]
    e.died.connect(func(): died_flag[0] = true)
    e.take_damage(e.max_hp)
    assert(e.is_dead)
    assert(died_flag[0])
    print("PASS: death")

func _spawn():
    var scene := load("res://characters/enemies/<nome>.tscn")
    var inst = scene.instantiate()
    add_child(inst)
    return inst
```

`tests/test_<nome>.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://tests/test_<nome>.gd" id="1_script"]

[node name="Test<NomePascal>" type="Node"]
script = ExtResource("1_script")
```

## Pós-Criação

Após criar os 4 arquivos:
1. Rodar: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_<nome>.tscn`
2. Verificar saída contém `ALL TESTS PASSED`
3. Commitar: `git add characters/enemies/<nome>.* tests/test_<nome>.* && git commit -m "feat: novo inimigo <nome>"`
```

- [ ] **Step 3: Verificar arquivo criado**

Ler `.claude/skills/new-enemy.md` e confirmar que contém os 4 templates de comportamento e os templates de .tscn e teste.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/new-enemy.md
git commit -m "feat: skill /new-enemy com templates ground_patrol/flyer/jumper/shooter"
```

---

### Task 3: Skill new-boss

**Files:**
- Create: `.claude/skills/new-boss.md`

- [ ] **Step 1: Criar .claude/skills/new-boss.md**

```markdown
# Skill: new-boss

Use quando o usuário pedir para criar um novo boss elemental.

## Informações a Coletar

Pergunte ao usuário (uma por vez se não fornecidas):
1. **nome** — snake_case, ex: `pyrovex`
2. **boss_id** — string identificadora (geralmente = nome)
3. **weakness_id** — ability_id do boss que o derrota (ver tabela em GAME_CONTEXT.md)
4. **ability_id** — string desbloqueada ao derrotá-lo (geralmente = nome)
5. **stage_id** — int (1–11, ou novo número acima de 11)
6. **boss_color** — Color GDScript, ex: `Color(0.9, 0.3, 0.0)`
7. **tema do ataque fase 1** — descrição livre (ex: "dispara 3 projéteis em leque")
8. **diferença fase 2** — (ex: "intervalo menor e 5 projéteis")

## Arquivos a Criar

1. `characters/bosses/<nome>.gd`
2. `characters/bosses/<nome>.tscn`
3. `tests/test_<nome>.gd`
4. `tests/test_<nome>.tscn`

## Template .gd

`characters/bosses/<nome>.gd`:
```gdscript
extends BossBase

func _do_combat(delta: float) -> void:
    if player == null:
        return
    var dx := player.global_position.x - global_position.x
    if abs(dx) > 120.0:
        velocity.x = sign(dx) * 80.0
    else:
        velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
    _face_player()
    _clamp_to_arena()

func _do_attack() -> void:
    _is_attacking = true
    velocity.x = 0.0
    await get_tree().create_timer(0.3).timeout
    if is_dead or player == null:
        _is_attacking = false
        return
    var dir := sign(player.global_position.x - global_position.x)
    if dir == 0.0:
        dir = 1.0
    # FASE 1: <descrição do ataque fase 1>
    var shots := 1
    if phase >= 2:
        shots = 3  # <ajuste fase 2>
    for i in shots:
        var angle := 0.0
        if shots > 1:
            angle = (i - shots / 2.0) * 0.25
        var vel := Vector2(dir * 300.0, 0.0).rotated(angle)
        _spawn_projectile(global_position, vel, 15, "<boss_id>", <boss_color>)
    _is_attacking = false

func _enter_phase_2() -> void:
    attack_interval_p2 = 1.2
    # <ajuste adicional fase 2 se necessário>
```

Ajustar `_do_attack()` conforme o tema informado pelo usuário.

## Template .tscn

`characters/bosses/<nome>.tscn`:
```
[gd_scene format=3 uid="uid://<nome>"]

[ext_resource type="PackedScene" uid="uid://boss_base" path="res://characters/bosses/boss_base.tscn" id="1_base"]
[ext_resource type="Script" path="res://characters/bosses/<nome>.gd" id="2_script"]

[node name="<NomePascal>" instance=ExtResource("1_base")]
script = ExtResource("2_script")
boss_id = "<boss_id>"
weakness_id = "<weakness_id>"
ability_id = "<ability_id>"
stage_id = <stage_id>
max_hp = 200
boss_color = <boss_color>
arena_left = 100.0
arena_right = 1820.0
arena_floor = 500.0
```

## Template de Teste

`tests/test_<nome>.gd`:
```gdscript
extends Node

func _ready() -> void:
    test_initial_hp()
    test_take_damage()
    test_weakness_multiplier()
    test_no_damage_when_idle()
    test_phase_transition()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_initial_hp() -> void:
    var b = _spawn()
    assert(b.current_hp == b.max_hp)
    assert(not b.is_dead)
    b.queue_free()
    print("PASS: initial_hp")

func test_take_damage() -> void:
    var b = _spawn()
    b.state = b.State.COMBAT
    b.take_damage(20)
    assert(b.current_hp == b.max_hp - 20)
    b.queue_free()
    print("PASS: take_damage")

func test_weakness_multiplier() -> void:
    var b = _spawn()
    b.state = b.State.COMBAT
    b.take_damage(10, b.weakness_id)
    # dano dobrado: 20
    assert(b.current_hp == b.max_hp - 20)
    b.queue_free()
    print("PASS: weakness_multiplier")

func test_no_damage_when_idle() -> void:
    var b = _spawn()
    # state == IDLE por padrão — dano ignorado
    b.take_damage(50)
    assert(b.current_hp == b.max_hp)
    b.queue_free()
    print("PASS: no_damage_when_idle")

func test_phase_transition() -> void:
    var b = _spawn()
    b.state = b.State.COMBAT
    b.take_damage(int(b.max_hp * 0.6))  # cai abaixo de 50%
    assert(b.phase == 2)
    b.queue_free()
    print("PASS: phase_transition")

func _spawn():
    var scene := load("res://characters/bosses/<nome>.tscn")
    var inst = scene.instantiate()
    add_child(inst)
    return inst
```

`tests/test_<nome>.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://tests/test_<nome>.gd" id="1_script"]

[node name="Test<NomePascal>" type="Node"]
script = ExtResource("1_script")
```

## Pós-Criação

1. Rodar: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_<nome>.tscn`
2. Verificar `ALL TESTS PASSED`
3. Commitar: `git add characters/bosses/<nome>.* tests/test_<nome>.* && git commit -m "feat: novo boss <nome>"`
```

- [ ] **Step 2: Verificar arquivo**

Ler `.claude/skills/new-boss.md` e confirmar presença de: template .gd com `_do_attack`/`_enter_phase_2`, template .tscn com todos os @exports, template de teste com 5 casos.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/new-boss.md
git commit -m "feat: skill /new-boss com templates completos"
```

---

### Task 4: Skill new-stage

**Files:**
- Create: `.claude/skills/new-stage.md`

- [ ] **Step 1: Criar .claude/skills/new-stage.md**

```markdown
# Skill: new-stage

Use quando o usuário pedir para criar uma nova fase.

## Informações a Coletar

1. **stage_id** — int (próximo disponível após 11, ou novo)
2. **nome descritivo** — ex: `volcano`, `ice_cave`
3. **boss** — nome do boss (deve existir em `characters/bosses/`)
4. **estilo** — `simple` (usa stage_scene.gd) | `complex` (GD customizado com zonas/doors)
5. **platform_color** — Color das plataformas
6. **tema visual** — descrição do cenário para gerar `_draw()` (apenas para `complex`)

## Arquivos a Criar

**Simple:**
- `stages/stage_<id>/stage_<id>.tscn`
- `tests/test_stage_<id>.gd`
- `tests/test_stage_<id>.tscn`

**Complex:**
- `stages/stage_<id>/stage_<id>.tscn`
- `stages/stage_<id>/stage_<id>_scene.gd`
- `tests/test_stage_<id>.gd`
- `tests/test_stage_<id>.tscn`

---

## Template Simple

Baseado em `stages/stage_01/stage_01.tscn`. Adaptar `<id>`, `<NomePascal>`, `<BossNomePascal>`, `uid://boss_<nome>`, `platform_color`, posições.

`stages/stage_<id>/stage_<id>.tscn`:
```
[gd_scene format=3 uid="uid://stage_<id>"]

[ext_resource type="Script" path="res://stages/stage_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://checkpoint" path="res://stages/checkpoint.tscn" id="3_cp"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="4_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://<boss_nome>" path="res://characters/bosses/<boss_nome>.tscn" id="9_boss"]
[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="10_grunt"]
[ext_resource type="PackedScene" uid="uid://enemy_flyer" path="res://characters/enemies/enemy_flyer.tscn" id="11_flyer"]

[sub_resource type="RectangleShape2D" id="FloorA"]
size = Vector2(800, 40)

[sub_resource type="RectangleShape2D" id="FloorB"]
size = Vector2(600, 40)

[sub_resource type="RectangleShape2D" id="FloorPre"]
size = Vector2(500, 40)

[sub_resource type="RectangleShape2D" id="FloorBoss"]
size = Vector2(1200, 40)

[sub_resource type="RectangleShape2D" id="P1"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="P2"]
size = Vector2(180, 20)

[sub_resource type="RectangleShape2D" id="P3"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="P4"]
size = Vector2(220, 20)

[node name="Stage<Id>" type="Node2D"]
platform_color = <platform_color>
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 760)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Checkpoint1" parent="." instance=ExtResource("3_cp")]
position = Vector2(2000, 850)
checkpoint_index = 1

[node name="Checkpoint2" parent="." instance=ExtResource("3_cp")]
position = Vector2(3500, 850)
checkpoint_index = 2

[node name="FloorA" type="StaticBody2D" parent="."]
position = Vector2(400, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorA"]
shape = SubResource("FloorA")

[node name="FloorB" type="StaticBody2D" parent="."]
position = Vector2(1900, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorB"]
shape = SubResource("FloorB")

[node name="FloorPre" type="StaticBody2D" parent="."]
position = Vector2(3500, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorPre"]
shape = SubResource("FloorPre")

[node name="FloorBoss" type="StaticBody2D" parent="."]
position = Vector2(4700, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorBoss"]
shape = SubResource("FloorBoss")

[node name="Plat1" type="StaticBody2D" parent="."]
position = Vector2(850, 820)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat1"]
shape = SubResource("P1")

[node name="Plat2" type="StaticBody2D" parent="."]
position = Vector2(1100, 760)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat2"]
shape = SubResource("P2")

[node name="Plat3" type="StaticBody2D" parent="."]
position = Vector2(1350, 700)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat3"]
shape = SubResource("P3")

[node name="Plat4" type="StaticBody2D" parent="."]
position = Vector2(1650, 640)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat4"]
shape = SubResource("P4")

[node name="<BossNomePascal>" parent="." instance=ExtResource("9_boss")]
position = Vector2(4600, 760)
arena_left = 4100.0
arena_right = 5100.0
arena_floor = 900.0

[node name="Grunt1" parent="." instance=ExtResource("10_grunt")]
position = Vector2(850, 790)

[node name="Grunt2" parent="." instance=ExtResource("10_grunt")]
position = Vector2(1350, 670)

[node name="Grunt3" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2600, 670)

[node name="Grunt4" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2900, 730)

[node name="Flyer1" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1700, 600)

[node name="Heart" parent="." instance=ExtResource("4_col")]
position = Vector2(1350, 660)
stage_id = <id>

[node name="HUD" parent="." instance=ExtResource("5_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]
[node name="GameOver" parent="." instance=ExtResource("7_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_top = 0
limit_bottom = 1080
limit_right = 5300
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

---

## Template Complex

Para stage complexo, usar `stage_00_scene.gd` e `stage_00.tscn` como referência direta:
- Ler `stages/stage_00/stage_00_scene.gd` e `stages/stage_00/stage_00.tscn`
- Adaptar: id, nome, posições de zonas, cores do `_draw_background()`, boss

Estrutura mínima do GD customizado:
```gdscript
extends Node2D

const ZAEL_SCENE   := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE   := preload("res://characters/melee/zara.tscn")
const _GRUNT_SCENE := preload("res://characters/enemies/enemy_base.tscn")
const _FLYER_SCENE := preload("res://characters/enemies/enemy_flyer.tscn")
const _BOSS_SCENE  := preload("res://characters/bosses/<boss_nome>.tscn")
const _DOOR_SCENE  := preload("res://stages/checkpoint_door.tscn")

# Posições por zona (adaptar ao layout)
const ZONE1_GRUNTS := [Vector2(400, 520), Vector2(700, 520)]
const ZONE1_FLYERS := [Vector2(550, 380)]
const ZONE2_GRUNTS := [Vector2(3500, 204), Vector2(3900, 204)]
const ZONE2_FLYERS := [Vector2(3700, 160)]
const ZONE3_GRUNTS := [Vector2(6100, 520), Vector2(6800, 460)]
const ZONE3_FLYERS := [Vector2(6600, 400)]

const BOSS_SPAWN   := Vector2(9100, 400)
const CP1_ENTRY_X  := 2900.0
const CP1_EXIT_X   := 3200.0
const CP2_ENTRY_X  := 8000.0
const CP2_EXIT_X   := 8300.0

# Copiar _ready, _process, _unhandled_input, _spawn_player, _setup_doors,
# _on_cp1_entry_opened, _on_cp2_entry_opened, _on_boss_door_opened, _spawn_boss,
# _setup_zone_triggers, _make_zone_trigger, zone entered/exited callbacks,
# _spawn_zone_enemies, _get_zone_array, _respawn_zone, _clear_zone_enemies
# de stage_00_scene.gd e adaptar boss_id e posições.
#
# Adaptar _draw_background() com as cores e tema do novo stage.
```

---

## Template de Teste

`tests/test_stage_<id>.gd`:
```gdscript
extends Node

func _ready() -> void:
    test_scene_loads()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_scene_loads() -> void:
    var scene := load("res://stages/stage_<id>/stage_<id>.tscn")
    assert(scene != null, "tscn deve existir")
    print("PASS: scene_loads")
```

`tests/test_stage_<id>.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://tests/test_stage_<id>.gd" id="1_script"]

[node name="TestStage<Id>" type="Node"]
script = ExtResource("1_script")
```

## Pós-Criação

1. Rodar: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_<id>.tscn`
2. Verificar `ALL TESTS PASSED`
3. Commitar: `git add stages/stage_<id>/ tests/test_stage_<id>.* && git commit -m "feat: nova fase stage_<id> (<nome>)"`
```

- [ ] **Step 2: Verificar arquivo**

Ler `.claude/skills/new-stage.md` e confirmar presença de template simple e complex com campos substituíveis.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/new-stage.md
git commit -m "feat: skill /new-stage com templates simple e complex"
```

---

### Task 5: Skill run-tests

**Files:**
- Create: `.claude/skills/run-tests.md`

- [ ] **Step 1: Criar .claude/skills/run-tests.md**

```markdown
# Skill: run-tests

Use quando o usuário quiser rodar os testes do projeto.

## Comportamento

**Sem argumento** — roda todos os testes listados abaixo em sequência.
**Com argumento** (ex: `run-tests enemy_base`) — roda só `tests/test_<argumento>.tscn`.

## Comando Base

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_<nome>.tscn 2>&1
```

## Lista Completa de Testes

```
test_game_manager
test_stage_manager
test_character_base
test_zael
test_zara
test_enemy_base
test_boss_base
test_boss_ai
test_wall_jump
test_checkpoint_door
test_collectible
test_hud
test_pause_menu
test_stage_complete
test_intro_boss
test_touch_controls
test_img_debug
```

## Interpretação da Saída

- `ALL TESTS PASSED` na saída → ✅ PASS
- Exit code ≠ 0 → ❌ FAIL
- Linha contendo `assert` ou `ERROR` → ❌ FAIL com detalhe

## Formato de Reporte

Após rodar todos (ou o selecionado), reportar:

```
Resultados dos Testes:
✅ test_game_manager
✅ test_stage_manager
❌ test_zael — assert falhou: linha 23
...
Total: X/Y passando
```

## Procedimento

1. Para cada teste (ou o informado), rodar o comando acima
2. Capturar saída completa
3. Verificar se contém "ALL TESTS PASSED"
4. Reportar tabela de resultados
5. Se algum falhou: mostrar a saída relevante do teste com falha
```

- [ ] **Step 2: Verificar funcionamento**

Rodar um teste real usando o comando da skill para confirmar que funciona:

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_enemy_base.tscn 2>&1
```

Saída esperada: deve conter `ALL TESTS PASSED`.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/run-tests.md
git commit -m "feat: skill /run-tests para execução headless dos testes"
```

---

### Task 6: Skill web-export

**Files:**
- Create: `.claude/skills/web-export.md`

- [ ] **Step 1: Criar .claude/skills/web-export.md**

```markdown
# Skill: web-export

Use quando o usuário quiser exportar e publicar o build web no GitHub Pages.

## Passos em Ordem

1. **Rodar export Godot:**
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" export/web/index.html 2>&1
```

2. **Verificar arquivo exportado:**
```bash
dir export/web/index.html
```
Se não existir → reportar erro e parar.

3. **Commitar o export:**
```bash
git add export/web/
git commit -m "chore: web export"
```
Se o usuário fornecer descrição do que mudou, usar: `"chore: web export — <descrição>"`

4. **Push:**
```bash
git push
```

## Observações

- O export preset "Web" já está configurado em `export_presets.cfg`
- O caminho `export/web/` é servido pelo GitHub Pages automaticamente
- Sempre usar `--export-release` (não `--export-debug`) para builds de produção
- O export pode levar 30–60 segundos; é normal
```

- [ ] **Step 2: Verificar funcionamento**

Rodar o export para confirmar que o caminho e preset estão corretos:

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" export/web/index.html 2>&1 | tail -3
```

Saída esperada: última linha contém `[ DONE ]`.

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/web-export.md
git commit -m "feat: skill /web-export para pipeline de publicação"
```

---

### Task 7: Atualizar CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Adicionar seção de Skills antes de "Input Map"**

Inserir o bloco abaixo antes da linha `## Input Map` no `CLAUDE.md`:

```markdown
---

## Contexto Completo do Jogo

Ver `GAME_CONTEXT.md` na raiz — contém collision layers, tabela de bosses, APIs de autoloads, padrões de código e convenções.

---

## Skills Disponíveis

Skills locais em `.claude/skills/`. Invocar dizendo "use a skill X" ou `/X`.

| Skill | Quando Usar |
|-------|-------------|
| `new-enemy` | Criar novo tipo de inimigo (ground/flyer/jumper/shooter) |
| `new-boss` | Criar novo boss elemental com AI e fraqueza |
| `new-stage` | Criar nova fase (simple ou complex com zonas) |
| `run-tests` | Rodar testes headless do Godot, reportar PASS/FAIL |
| `web-export` | Exportar build web e publicar no GitHub Pages |

```

- [ ] **Step 2: Verificar CLAUDE.md**

Ler `CLAUDE.md` e confirmar que a seção "Skills Disponíveis" foi inserida antes de "Input Map" e que o link para `GAME_CONTEXT.md` está presente.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: adiciona seção de skills e link GAME_CONTEXT no CLAUDE.md"
```

---

### Task 8: Registrar Skills em settings.json

**Files:**
- Modify: `.claude/settings.json`

- [ ] **Step 1: Atualizar .claude/settings.json**

Conteúdo completo do arquivo após a edição:

```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true
  },
  "skills": {
    "new-enemy":  ".claude/skills/new-enemy.md",
    "new-boss":   ".claude/skills/new-boss.md",
    "new-stage":  ".claude/skills/new-stage.md",
    "run-tests":  ".claude/skills/run-tests.md",
    "web-export": ".claude/skills/web-export.md"
  }
}
```

- [ ] **Step 2: Verificar JSON válido**

```bash
python -c "import json; json.load(open('.claude/settings.json')); print('JSON válido')"
```

Saída esperada: `JSON válido`

- [ ] **Step 3: Commit final**

```bash
git add .claude/settings.json
git commit -m "feat: registra skills locais em settings.json"
```
