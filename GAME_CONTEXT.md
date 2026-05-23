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
AudioManager.play_bgm(stream, fade_in: float = 0.5)  # null = silêncio (safe); fade_in em segundos
AudioManager.stop_bgm(fade_out: float = 0.5)          # fade out e para a música
AudioManager.play_sfx(stream)                          # null = no-op (safe)
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
    var c := Color.WHITE if _hit_flash_timer > 0.0 else Color(0.8, 0.4, 0.1)  # substituir pela cor do inimigo
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
@export var player: CharacterBase = null  # atribuir via stage script ou inspector
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
| Boss | `ignarath.gd` | `ignarath.tscn` | `characters/bosses/` |
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
