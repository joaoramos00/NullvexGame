# Stage 08 Terragor Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework Stage 08 (Terragor, tema terra/mina) do esqueleto atual pra uma fase completa com 4 zonas temáticas de desmoronamento crescente, roster de 9 inimigos com IA funcional, 1 mecânica nova de terreno (parede de entulho quebrável, sem gate de habilidade), reaproveitamento de 2 componentes genéricos já existentes (`crumbling_ledge.gd`, `crusher.gd`), sala do boss Terragor com arena bounds corretos desde o início, e uma mecânica real de fase 2 pro boss (onda de tremor, hoje só muda o intervalo de ataque).

**Architecture:** `stages/stage_08/stage_08_scene.gd extends "res://stages/stage_scene.gd"` (mesmo padrão de stage_05/06/07), zonas construídas em código via o vocabulário de helpers já validado. Um componente novo de terreno: `rubble_wall.gd` (parede que quebra em N hits de qualquer ataque do jogador — **sem checagem de habilidade**, diferente de `cracked_wall.gd` da stage_01, porque Stage 08 é acessível em qualquer ordem pelo stage select e não pode travar o caminho principal atrás de uma habilidade de outro boss). Dois componentes genéricos JÁ EXISTENTES reaproveitados via preload cross-stage sem clonar código: `res://stages/stage_01/crumbling_ledge.gd` (saliência que desmorona) e `res://stages/stage_04/crusher.gd` (bloco que esmaga em ciclo). Um componente novo pro boss: `quake_wave.gd` (onda de choque horizontal, usada só em fase 2 de Terragor). 9 scripts de IA em `characters/enemies/stage_08/`, cada um clonando o template mais próximo já em produção nas stages 01-07.

**Tech Stack:** Godot 4.6.2 GDScript, headless parse-check, sprites/tileset já existentes (nenhum asset novo).

## Global Constraints

- Nomes de arquivo/script em snake_case; `class_name` em PascalCase.
- `CorridorSection` sempre 896×64 / zoom 2.0 — nunca variar a largura do corredor.
- Nenhuma cura em checkpoints/corredores (`heal_on_entry = false`).
- Teto por zona usa `_CEIL_FACE_GAP` (colisão 32px acima do nominal, visual intocado) e fallback cross-zone desde a primeira versão. O `draw_texture_rect_region` do desenho visual do teto usa `Rect2(x, y, ts, ts)` — **sem** subtrair `sts` (bug já cometido e corrigido na Stage 05, não repetir).
- `sign()`/`clamp()`/`abs()` sempre tipados explicitamente com `: float` no build web.
- **Colectáveis sempre via `Collectible.Type.XXX` (enum), nunca `.set("collectible_type", "string")`** — esse padrão falha silenciosamente e vira `Type.HEART` (bug real já corrigido nas Stages 05/06, ver memória `reference_collectible_type_enum`). Usar o campo companheiro certo por tipo: `armor_piece`/`ability_id`/`subtank_index`/`stage_id`.
- **`_build_boss_arena()` DEVE setar `arena_left`/`arena_right`/`arena_floor` no boss**, além de posição e `auto_aggro` — omitir isso deixa o boss nos defaults de `boss_base.gd` (arena_right=1820), o que pode quebrar completamente a luta pra bosses com lógica dependente da arena (bug crítico encontrado na revisão final da Stage 06, ver memória `project_stage06_rework`).
- **`rubble_wall.gd` fica neutro sob `DebugBoot.bot_enabled`**: `queue_free()` no `_ready()` (mesmo padrão de `stage_02/ice_gate.gd` — bot não ataca de forma confiável pra quebrar a parede, então ela simplesmente não existe nesse modo, garantindo que a travessia automática valide o resto da fase). `crumbling_ledge.gd` e `crusher.gd` já são neutros/previsíveis sob bot por herança (código já shipped, não precisa de caso especial adicional).
- Toda coordenada de piso/parede/sala da sala do boss deve ser múltiplo de 64px (skill `new-boss-room`).
- Após cada task: parse-check headless (scene-load real, não `--check-only --script`, que dá falso-positivo em qualquer script tocando autoload) antes de seguir pra próxima.
- **Verificação de geometria é responsabilidade de CADA task**: antes de finalizar qualquer zona, recalcular manualmente as coordenadas X/Y de piso/plataforma/crusher/parede a partir do código de verdade e confirmar que a travessia é fisicamente possível (gaps de piso ≤196px de alcance horizontal / ≤118px de altura, exceto onde um hazard exige timing deliberado). As revisões das Stages 05/06/07 acharam e corrigiram bugs reais de geometria/wiring assim repetidamente — replicar o mesmo rigor aqui, inclusive na revisão final de branch inteiro ao final deste plano.
- **Todos os números de posição abaixo são ponto de partida, não verdade absoluta**: cada task deve reconferir contra o código REAL já escrito pelas tasks anteriores no mesmo arquivo (não confiar cegamente nos exemplos deste plano) — mesmo padrão que pegou bugs reais nas Stages 05/06/07 (piso de uma zona invadindo território da próxima, polaridade de interruptor invertida, etc.).

---

### Task 1: Projétil compartilhado `stone_bolt.gd`

**Files:**
- Create: `characters/enemies/stage_08/stone_bolt.gd`
- Create: `characters/enemies/stage_08/stone_bolt.tscn`

**Interfaces:**
- Produces: `StoneBolt.setup(velocity_value: Vector2, damage_value: int, source_value := "stage08_stone", gravity_value := 0.0, variant_value := "stone_shot") -> void` — usado pelas Tasks 5-6.

- [ ] **Step 1: Criar o script do projétil**

Clone estrutural de `characters/enemies/stage_07/light_projectile.gd` (ler o arquivo real antes de escrever — este é só um ponto de partida), trocando os nomes de classe/variantes:

`characters/enemies/stage_08/stone_bolt.gd`:
```gdscript
extends Area2D
class_name StoneBolt

# Projétil compartilhado do roster do stage 08 (molde do light_projectile).
const TEX := {
	"stone_shot": preload("res://characters/enemies/stage_08/stone_shot.png"),
	"ore_shard": preload("res://characters/enemies/stage_08/ore_shard.png"),
}

var projectile_velocity: Vector2 = Vector2(300.0, 0.0)
var damage: int = 6
var source_id: String = "stage08_stone"
var variant: String = "stone_shot"
var gravity: float = 0.0
var _lifetime: float = 4.0
var _hit := false
var _anim_timer := 0.0
var _frame := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_enemy_shoot)

func setup(velocity_value: Vector2, damage_value: int, source_value := "stage08_stone",
		gravity_value := 0.0, variant_value := "stone_shot") -> void:
	projectile_velocity = velocity_value
	damage = damage_value
	source_id = source_value
	gravity = gravity_value
	variant = variant_value
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null and TEX.has(variant):
		spr.texture = TEX[variant]
		spr.hframes = 2
		spr.vframes = 2
		spr.frame = 0

func _physics_process(delta: float) -> void:
	if _hit:
		return
	projectile_velocity.y += gravity * delta
	global_position += projectile_velocity * delta
	rotation = projectile_velocity.angle()
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		_anim_timer += delta
		if _anim_timer >= 1.0 / 12.0:
			_anim_timer -= 1.0 / 12.0
			_frame = (_frame + 1) % 4
			spr.frame = _frame
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	queue_free()
```

**Antes de commitar:** confirmar que `stone_shot.png`/`ore_shard.png` existem em `characters/enemies/stage_08/` com layout de sprite-sheet compatível (2×2 hframes/vframes, 4 frames de animação) — se o layout real for diferente, ajustar `hframes`/`vframes`/módulo de `_frame` de acordo, não copiar cegamente do template de luz.

- [ ] **Step 2: Criar a cena do projétil**

`characters/enemies/stage_08/stone_bolt.tscn` (mesma estrutura de `light_projectile.tscn`: `Area2D` raiz, `collision_layer=0`/`collision_mask=2`, `CollisionShape2D` com `CircleShape2D` radius≈10, `Sprite2D` filho com a textura `stone_shot.png`).

- [ ] **Step 3: Parse-check headless**

Instanciar `stone_bolt.tscn` numa cena temporária carregada via headless real (não `--check-only --script`). Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 4: Commit**

```bash
git add characters/enemies/stage_08/stone_bolt.gd characters/enemies/stage_08/stone_bolt.tscn
git commit -m "feat(stage08): projétil compartilhado stone_bolt do roster"
```

---

### Task 2: Componente `rubble_wall.gd`

**Files:**
- Create: `stages/stage_08/rubble_wall.gd`

**Interfaces:**
- Produces: `RubbleWall` (`StaticBody2D`), `@export var hits_required: int`, `signal wall_destroyed` — instanciado pela Task 9 (Zona 3) via um helper `_rubble_wall()` em `stage_08_scene.gd` (construído em código, sem `.tscn` próprio — mesmo padrão de `light_gate`/`light_beam` da stage_07, que também não têm `.tscn`).

- [ ] **Step 1: Criar o componente**

Ler `stages/stage_01/cracked_wall.gd` primeiro (estrutura de referência: tint visual + `HitDetector` Area2D filho + contagem de hits), mas **remover completamente a checagem de habilidade** — este componente quebra com qualquer ataque do jogador, sempre, sem depender de `GameManager.boss_abilities_unlocked`:

`stages/stage_08/rubble_wall.gd`:
```gdscript
# Parede de entulho que bloqueia o caminho principal da Zona 3 até levar
# hits_required golpes de qualquer ataque do jogador. Diferente de
# cracked_wall.gd (stage_01, que exige a habilidade do Galerix pra abrir um
# SEGREDO opcional): esta parede está no caminho OBRIGATÓRIO, e Stage 08
# pode ser a primeira fase jogada (stage select em qualquer ordem) — travar
# atrás de uma habilidade de outro boss deixaria a fase impossível de
# terminar em certas ordens de jogo. Por isso quebra com qualquer hit, sem
# checagem de habilidade.
extends StaticBody2D

signal wall_destroyed

@export var hits_required: int = 3

var _hits: int = 0

const _TINT := Color(0.55, 0.4, 0.25, 0.45)

func _draw() -> void:
	for c in get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			var sz: Vector2 = ((c as CollisionShape2D).shape as RectangleShape2D).size
			var pos: Vector2 = (c as Node2D).position
			draw_rect(Rect2(pos - sz * 0.5, sz), _TINT)

func _ready() -> void:
	add_to_group("rubble_wall")
	if DebugBoot.bot_enabled:
		# Bot não ataca de forma confiável pra quebrar a parede em N hits —
		# mesmo raciocínio de stage_02/ice_gate.gd: abre pra validar o resto
		# da travessia automaticamente.
		call_deferred("queue_free")
		return
	queue_redraw()
	var detector := get_node_or_null("HitDetector") as Area2D
	if detector != null:
		detector.area_entered.connect(_on_hit)

func _on_hit(_area: Area2D) -> void:
	if is_queued_for_deletion():
		return
	_hits += 1
	if _hits >= hits_required:
		wall_destroyed.emit()
		queue_free()
```

**Antes de commitar:** confirmar a camada de colisão real dos hitboxes de ataque do jogador (grep por `collision_layer = 8` ou equivalente nos scripts de ataque de `characters/base/` ou `characters/zael`/`characters/zara` — a Task 9 vai precisar disso pro `HitDetector.collision_mask` do muro, e o memo de Stage 05 já documentou um bug real de camada errada nesse tipo de componente, "layer-8 bug" — não adivinhar, ler o valor real).

- [ ] **Step 2: Parse-check headless**

Scene-load real de uma cena temporária instanciando o script num `StaticBody2D` com um `HitDetector` filho, timeout, grep por erros.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_08/rubble_wall.gd
git commit -m "feat(stage08): componente de parede de entulho quebrável (sem gate de habilidade)"
```

---

### Task 3: Componente `quake_wave.gd` + integração de fase 2 no boss Terragor

**Files:**
- Create: `characters/bosses/quake_wave.gd`
- Create: `characters/bosses/quake_wave.tscn`
- Modify: `characters/bosses/terragor.gd`

**Interfaces:**
- Produces: `QuakeWave` (`Area2D`), `@export var direction: float`, `@export var speed: float`, `@export var damage: int` — spawnado só por `terragor.gd` em fase 2.
- Consumes: nenhuma interface de outras tasks deste plano (Terragor já existe e é independente do resto da fase).

- [ ] **Step 1: Ler `characters/bosses/terragor.gd` e `characters/bosses/boss_base.gd` por completo antes de escrever**

Confirmar a assinatura real de `_do_attack()`, `_enter_phase_2()`, `_spawn_projectile()`, e os campos `phase`/`attack_interval_p2` — o código abaixo é um PONTO DE PARTIDA baseado na versão lida durante o brainstorm desta spec; se o arquivo real divergir, adaptar em vez de sobrescrever cegamente.

- [ ] **Step 2: Criar o componente `quake_wave.gd`**

```gdscript
# characters/bosses/quake_wave.gd
# Onda de choque horizontal: nasce na posição de Terragor e se desloca pro
# lado indicado (uma instância por direção — a fase 2 spawna 2, uma pra
# cada lado) até percorrer max_distance, então some. Dano por contato
# (uma vez por corpo, via _hit_bodies).
extends Area2D
class_name QuakeWave

const TEX := preload("res://characters/enemies/stage_08/quake_wave.png")

@export var speed: float = 260.0
@export var damage: int = 12
@export var max_distance: float = 900.0

var direction: float = 1.0

var _origin_x: float = 0.0
var _hit_bodies: Dictionary = {}

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_origin_x = global_position.x
	body_entered.connect(_on_body_entered)
	if _sprite != null:
		_sprite.texture = TEX
		_sprite.flip_h = direction < 0.0

func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta
	if absf(global_position.x - _origin_x) >= max_distance:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit_bodies.has(body):
		return
	if body.has_method("take_damage"):
		_hit_bodies[body] = true
		body.take_damage(damage)
```

- [ ] **Step 3: Criar `characters/bosses/quake_wave.tscn`**

`Area2D` raiz (`collision_layer=0`, `collision_mask=2`), `CollisionShape2D` filho com `RectangleShape2D` (ex.: `size = Vector2(56.0, 64.0)` — ajustar depois de olhar o sprite `quake_wave.png` real), `Sprite2D` filho.

- [ ] **Step 4: Modificar `terragor.gd` — fase 2 real**

Adicionar um contador de ataques de fase 2 e alternar entre a rajada de rochas já existente e um pulso de tremor (2 `QuakeWave`, uma pra cada lado). Não mudar `_do_combat()` nem a lógica de movimento — só `_do_attack()`/`_enter_phase_2()`:

```gdscript
const _QUAKE_SCENE := preload("res://characters/bosses/quake_wave.tscn")

var _phase2_attack_count: int = 0

func _do_attack() -> void:
	_is_attacking = true
	velocity.x = 0.0
	await get_tree().create_timer(0.4).timeout
	if is_dead:
		_is_attacking = false
		return
	if phase == 2 and _phase2_attack_count % 2 == 1:
		_do_quake_attack()
	else:
		_do_rock_attack()
	if phase == 2:
		_phase2_attack_count += 1
	_is_attacking = false

func _do_rock_attack() -> void:
	var count := 4 if phase == 2 else 2
	for i in count:
		var dir := 1.0 if i % 2 == 0 else -1.0
		var vy := -100.0 if phase == 2 and i >= 2 else 0.0
		_spawn_projectile(
			global_position, Vector2(dir * 180.0, vy),
			15, "terragor", Color(0.5, 0.35, 0.1)
		)

func _do_quake_attack() -> void:
	for dir in [1.0, -1.0]:
		var wave: QuakeWave = _QUAKE_SCENE.instantiate()
		wave.global_position = global_position + Vector2(0.0, -20.0)
		wave.direction = dir
		get_parent().add_child(wave)

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.2
	_phase2_attack_count = 0
```

**Nota:** isso preserva 100% do comportamento de fase 1 (só `_do_rock_attack()` roda, `_phase2_attack_count` sempre 0 antes da transição) e faz fase 2 alternar rajada-de-rocha / pulso-de-tremor a cada ataque, em vez de só encurtar o intervalo (comportamento antigo, já identificado como "sem mudança de padrão real" no spec). Confirmar que `_spawn_projectile` ainda existe com essa assinatura em `boss_base.gd` antes de reusar.

- [ ] **Step 5: Parse-check headless**

Scene-load real de `characters/bosses/terragor.tscn` isolada (ou de uma cena de teste que a instancie), timeout, grep por erros. Também instanciar `quake_wave.tscn` isoladamente.

- [ ] **Step 6: Commit**

```bash
git add characters/bosses/quake_wave.gd characters/bosses/quake_wave.tscn characters/bosses/terragor.gd
git commit -m "feat(stage08): onda de tremor (quake_wave) + fase 2 real do Terragor"
```

---

### Task 4: Inimigos terrestres/melee (terra_grunt, mossback_brute, drill_mole)

**Files:**
- Create: `characters/enemies/stage_08/enemy_terra_grunt.gd` / `.tscn`
- Create: `characters/enemies/stage_08/enemy_mossback_brute.gd` / `.tscn`
- Create: `characters/enemies/stage_08/enemy_drill_mole.gd` / `.tscn`

**Interfaces:**
- Produces: as 3 `PackedScene`s, consumidas pela Task 7 (`_TERRAGOR_ROSTER`/roster dict de `stage_08_scene.gd`).

Para cada inimigo: ler o template mais próximo listado abaixo POR COMPLETO (`.gd` e `.tscn`) antes de clonar, e adaptar sprite/hitbox/stats — não inventar uma estrutura nova, `EnemyBase` já resolve movimento/dano/morte/drop.

| Inimigo | Base | Molde (ler primeiro) | max_hp | contact_damage | Padrão |
|---|---|---|---|---|---|
| `enemy_terra_grunt` | `EnemyBase` | `characters/enemies/stage_07/enemy_lion_cub_runner.gd` | 8 | 6 | patrulha + investida curta |
| `enemy_mossback_brute` | `EnemyBase` | `characters/enemies/stage_07/enemy_mirror_ram.gd` | 22 | 12 | pesado, investida lenta longa |
| `enemy_drill_mole` | `EnemyBase` | `characters/enemies/stage_07/enemy_solar_guard.gd` | 10 | 8 | melee, lunge curto |

- [ ] **Step 1: `enemy_terra_grunt`** — clonar `enemy_lion_cub_runner.gd`/`.tscn`, textura `enemy_terra_grunt.png`, `max_hp=8`, `contact_damage=6`, mesmo padrão de patrulha+dash.

- [ ] **Step 2: `enemy_mossback_brute`** — clonar `enemy_mirror_ram.gd`/`.tscn`, textura `enemy_mossback_brute.png`, `max_hp=22`, `contact_damage=12`, mesmo padrão de charge pesado.

- [ ] **Step 3: `enemy_drill_mole`** — clonar `enemy_solar_guard.gd`/`.tscn`, textura `enemy_drill_mole.png`, `max_hp=10`, `contact_damage=8`, mesmo padrão de lunge curto.

- [ ] **Step 4: Parse-check headless dos 3**

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_08/enemy_terra_grunt.* characters/enemies/stage_08/enemy_mossback_brute.* characters/enemies/stage_08/enemy_drill_mole.*
git commit -m "feat(stage08): inimigos terrestres/melee (terra_grunt, mossback_brute, drill_mole)"
```

---

### Task 5: Inimigos voadores/suspensos (gem_wasp, stone_glider, ore_orbiter)

**Files:**
- Create: `characters/enemies/stage_08/enemy_gem_wasp.gd` / `.tscn`
- Create: `characters/enemies/stage_08/enemy_stone_glider.gd` / `.tscn`
- Create: `characters/enemies/stage_08/enemy_ore_orbiter.gd` / `.tscn`

**Interfaces:**
- Produces: as 3 `PackedScene`s, consumidas pela Task 7. `enemy_stone_glider` usa `StoneBolt.setup(..., variant_value="stone_shot")` (Task 1).

| Inimigo | Base | Molde (ler primeiro) | max_hp | contact_damage | Padrão |
|---|---|---|---|---|---|
| `enemy_gem_wasp` | `enemy_flyer.gd` | `characters/enemies/stage_07/enemy_glasswing_drone.gd` | 6 | 6 | mergulhador aéreo |
| `enemy_stone_glider` | `enemy_flyer.gd` | `characters/enemies/stage_07/enemy_prism_orbiter.gd` | 8 | 5 | hover-atirador, dispara `stone_shot` |
| `enemy_ore_orbiter` | `enemy_flyer.gd` | `characters/enemies/stage_07/enemy_sun_grabber.gd` | 12 | 8 | suspenso, perseguidor lento |

- [ ] **Step 1: `enemy_gem_wasp`** — clonar `enemy_glasswing_drone.gd`/`.tscn`, textura `enemy_gem_wasp.png`, `max_hp=6`, `contact_damage=6`, mesmo padrão de mergulho.

- [ ] **Step 2: `enemy_stone_glider`** — clonar `enemy_prism_orbiter.gd`/`.tscn`, textura `enemy_stone_glider.png`, `max_hp=8`, `contact_damage=5`; trocar o projétil de `LightProjectile`/`variant="light_bolt"` pra `StoneBolt`/`variant="stone_shot"` (Task 1) — confirmar que a chamada `setup()` bate com a assinatura real de `stone_bolt.gd`.

- [ ] **Step 3: `enemy_ore_orbiter`** — clonar `enemy_sun_grabber.gd`/`.tscn`, textura `enemy_ore_orbiter.png`, `max_hp=12`, `contact_damage=8`, mesmo padrão suspenso/perseguidor lento.

- [ ] **Step 4: Parse-check headless dos 3**

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_08/enemy_gem_wasp.* characters/enemies/stage_08/enemy_stone_glider.* characters/enemies/stage_08/enemy_ore_orbiter.*
git commit -m "feat(stage08): inimigos voadores/suspensos (gem_wasp, stone_glider, ore_orbiter)"
```

---

### Task 6: Inimigos estáticos/traps (root_snare, boulder_turret, fossil_totem)

**Files:**
- Create: `characters/enemies/stage_08/enemy_root_snare.gd` / `.tscn`
- Create: `characters/enemies/stage_08/enemy_boulder_turret.gd` / `.tscn`
- Create: `characters/enemies/stage_08/enemy_fossil_totem.gd` / `.tscn`

**Interfaces:**
- Produces: as 3 `PackedScene`s, consumidas pela Task 7. `enemy_boulder_turret`/`enemy_fossil_totem` usam `StoneBolt.setup()` (Task 1).

| Inimigo | Base | Molde (ler primeiro) | max_hp | contact_damage | Padrão |
|---|---|---|---|---|---|
| `enemy_root_snare` | `EnemyBase` | `characters/enemies/stage_06/enemy_dark_lantern.gd` | 14 | 10 | estático, aura/trap de curto alcance (`root_bind`, dano por Area2D quando o jogador se aproxima, sem projétil) |
| `enemy_boulder_turret` | `EnemyBase` | `characters/enemies/stage_07/enemy_beam_turret.gd` | 12 | — | canhão fixo, dispara `stone_shot` |
| `enemy_fossil_totem` | `EnemyBase` | `characters/enemies/stage_06/enemy_eclipse_turret.gd` | 16 | — | estático, dispara `ore_shard` em intervalos |

- [ ] **Step 1: `enemy_root_snare`** — clonar `enemy_dark_lantern.gd`/`.tscn` (padrão de aura estática — ler a implementação real, `_DROP_TABLE` já classifica como `"trap"`), textura `enemy_root_snare.png`, `max_hp=14`, `contact_damage=10`. Sem projétil próprio — dano por Area2D de curto alcance quando o jogador entra no raio (usar o FX `root_bind.png` só como referência visual/tint, sem exigir animação nova se o padrão do lantern já resolver via aura simples).

- [ ] **Step 2: `enemy_boulder_turret`** — clonar `enemy_beam_turret.gd`/`.tscn`, textura `enemy_boulder_turret.png`, `max_hp=12`; trocar `LightProjectile`/`"light_bolt"` por `StoneBolt`/`"stone_shot"`.

- [ ] **Step 3: `enemy_fossil_totem`** — clonar `enemy_eclipse_turret.gd`/`.tscn`, textura `enemy_fossil_totem.png`, `max_hp=16`; trocar o projétil da stage_06 por `StoneBolt`/`"ore_shard"`.

- [ ] **Step 4: Parse-check headless dos 3**

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_08/enemy_root_snare.* characters/enemies/stage_08/enemy_boulder_turret.* characters/enemies/stage_08/enemy_fossil_totem.*
git commit -m "feat(stage08): inimigos estáticos/traps (root_snare, boulder_turret, fossil_totem)"
```

---

### Task 7: Scaffold `stage_08_scene.gd` + Zona 1 (piso instável)

**Files:**
- Modify: `stages/stage_08/stage_08.tscn` (trocar script raiz, remover geometria antiga, manter `Terragor` com `visible=false` reposicionado)
- Create: `stages/stage_08/stage_08_scene.gd`

**Interfaces:**
- Produces: helpers de terreno (`_floor_seg`, `_solid_block`, `_fixed_plat`, `_setup_corridors`, `_make_corridor`, `_setup_zone_triggers`, `_spawn_zone_enemies`, `_crumble_ledge`), constantes de zona (`FLOOR_Y`, `_CP1_ENTRY_X`/`_CP1_EXIT_X`/`_CP2_ENTRY_X`/`_CP2_EXIT_X`/`_BOSS_L`/`_BOSS_R`), `_build_zone1()` — consumidos pelas Tasks 8-11.
- Consumes: as 9 `PackedScene`s das Tasks 4-6, `res://stages/stage_01/crumbling_ledge.gd` (reuso direto, sem clonar).

- [ ] **Step 1: Reescrever `stage_08.tscn`**

Ler o arquivo atual por completo primeiro. Trocar `script = ExtResource("1_script")` de `stages/stage_scene.gd` pra `stages/stage_08/stage_08_scene.gd` (novo `ext_resource`). Manter `StageController`/`Camera2D`/`HUD`/`PauseMenu`/`GameOver`/`StageComplete`/`Terragor` (setar `visible=false`, reposicionar depois em código igual ao padrão de Luxar na stage_07). Remover TODOS os `StaticBody2D` de piso/plataforma antigos (`FloorStart`, `CaveFloorA/B`, `FloorReturn`, `FloorBoss`, `CaveWallLeft/Right`, `DescentPlat1/2`, `CaveMidPlat1/2`, `AscentPlat1/2`, `PreBossPlat1/2`), os `Checkpoint1/2` antigos (recriados via `CorridorSection` em código), os collectibles antigos (`Heart`, `SubTank`, `ArmorZaraLegs`, `CannonZael` — recriados em código com coordenadas novas) e os inimigos genéricos (`Grunt1-4`, `Flyer1` — substituídos pelo roster novo). Ajustar `PlayerSpawn` pra `Vector2(200, 760)` e `Camera2D.limit_right`/`limit_bottom` pro tamanho real da fase reconstruída (calcular depois que `_BOSS_R` estiver definido — ver Step 2).

- [ ] **Step 2: Criar `stage_08_scene.gd` — scaffold + helpers + Zona 1**

```gdscript
# stages/stage_08/stage_08_scene.gd — Terragor (terra)
# Rebuild completo no molde dos stages 02-07: estende a base stage_scene.gd,
# zonas construídas em código, 2 corredores com checkpoint e arena de boss.
# Identidade de terra/mina:
#   Z1 piso instável   — saliências que desmoronam (crumbling_ledge.gd, reuso direto)
#   Z2 desabamentos    — blocos que esmagam em ciclo (crusher.gd, reuso direto)
#   Z3 túnel de mina    — parede de entulho quebrável por ataque (rubble_wall.gd, NOVO)
#   Z4 corredor final   — canhões de pedra até a sala do Terragor
extends "res://stages/stage_scene.gd"

const _CRUMBLE := preload("res://stages/stage_01/crumbling_ledge.gd")   # script genérico
const _CRUSHER := preload("res://stages/stage_04/crusher.gd")           # script genérico
const _RUBBLE := preload("res://stages/stage_08/rubble_wall.gd")
const _TERRAGOR_ROSTER := {
	"grunt":   preload("res://characters/enemies/stage_08/enemy_terra_grunt.tscn"),
	"brute":   preload("res://characters/enemies/stage_08/enemy_mossback_brute.tscn"),
	"mole":    preload("res://characters/enemies/stage_08/enemy_drill_mole.tscn"),
	"wasp":    preload("res://characters/enemies/stage_08/enemy_gem_wasp.tscn"),
	"glider":  preload("res://characters/enemies/stage_08/enemy_stone_glider.tscn"),
	"orbiter": preload("res://characters/enemies/stage_08/enemy_ore_orbiter.tscn"),
	"snare":   preload("res://characters/enemies/stage_08/enemy_root_snare.tscn"),
	"turret":  preload("res://characters/enemies/stage_08/enemy_boulder_turret.tscn"),
	"totem":   preload("res://characters/enemies/stage_08/enemy_fossil_totem.tscn"),
}

const FLOOR_Y := 800.0
const _CORR_INTERIOR := 192.0

const _CP1_ENTRY_X := 3200.0
const _CP1_EXIT_X := 4096.0
const _CP2_ENTRY_X := 10496.0
const _CP2_EXIT_X := 11392.0
const _BOSS_L := 12544.0
const _BOSS_R := 13952.0

# Roster de terra por zona: kind (chave de _TERRAGOR_ROSTER) → posições.
const Z1_ENEMIES := {
	"grunt": [Vector2(500.0, 760.0), Vector2(2900.0, 760.0)],
	"brute": [Vector2(1100.0, 760.0)],
	"mole":  [Vector2(2400.0, 760.0)],
}
const Z2_ENEMIES := {
	"wasp":   [Vector2(4700.0, 500.0), Vector2(6800.0, 450.0)],
	"glider": [Vector2(5600.0, 600.0)],
}
const Z3_ENEMIES := {
	"snare":   [Vector2(9200.0, 760.0)],
	"totem":   [Vector2(9800.0, 760.0)],
	"orbiter": [Vector2(10200.0, 650.0)],
}
const Z4_ENEMIES := {
	"turret": [Vector2(11700.0, 736.0), Vector2(12200.0, 736.0)],
}

var _door_tex: Texture2D = null
var _zone1_enemies: Array[Node] = []
var _zone2_enemies: Array[Node] = []
var _zone3_enemies: Array[Node] = []
var _zone4_enemies: Array[Node] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if StageManager.current_stage_id < 0:
		StageManager.current_stage_id = 8
	super._ready()
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_setup_corridors()
	_build_zone1()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _zone_tile_path(zone: String) -> String:
	var z := zone.to_lower()
	if z == "boss":
		z = "z4"
	return "res://stages/stage_08/Stage_08T_%s.png" % z

# ── Corredores (checkpoints) ─────────────────────────────────────────────────

func _setup_corridors() -> void:
	_make_corridor("CP1", _CP1_ENTRY_X, _CP1_EXIT_X, "z1", FLOOR_Y, 1)
	_make_corridor("CP2", _CP2_ENTRY_X, _CP2_EXIT_X, "z3", FLOOR_Y, 2)

func _make_corridor(name_prefix: String, entry_x: float, exit_x: float, zone: String, floor_y: float, checkpoint_index: int) -> CorridorSection:
	var width := exit_x - entry_x
	var corr := CorridorSection.new()
	corr.name = name_prefix
	corr.tileset = _cached_override_tex(_zone_tile_path(zone))
	corr.door_tex = _door_tex
	var floor_cy := floor_y + 32.0
	var ceil_cy := floor_y - _CORR_INTERIOR - 32.0
	var mid_y := (floor_cy + ceil_cy) * 0.5
	corr.floor_center = Vector2(entry_x + width * 0.5, floor_cy)
	corr.floor_size = Vector2(width, 64.0)
	corr.ceil_center = Vector2(entry_x + width * 0.5, ceil_cy)
	corr.ceil_size = Vector2(width, 64.0)
	corr.wall_l_center = Vector2(entry_x, mid_y)
	corr.wall_l_size = Vector2(64.0, _CORR_INTERIOR + 64.0)
	corr.wall_r_center = Vector2(exit_x, mid_y)
	corr.wall_r_size = Vector2(64.0, _CORR_INTERIOR + 64.0)
	corr.entry_x = entry_x
	corr.exit_x = exit_x
	corr.save_checkpoint = true
	corr.heal_on_entry = false
	corr.checkpoint_index = checkpoint_index
	corr.checkpoint_respawn_x = exit_x + 128.0
	corr.cam_center = Vector2(entry_x + width * 0.5, mid_y)
	corr.cam_zoom = 2.0
	add_child(corr)
	corr.setup(_player)
	return corr

# ── Spawn de inimigos por zona ───────────────────────────────────────────────

func _setup_zone_triggers() -> void:
	_make_zone_trigger("Z2Trigger", Rect2(_CP1_EXIT_X, 300.0, _CP2_ENTRY_X - _CP1_EXIT_X, 900.0), 2)
	_make_zone_trigger("Z3Trigger", Rect2(7296.0, 300.0, _CP2_ENTRY_X - 7296.0, 900.0), 3)
	_make_zone_trigger("Z4Trigger", Rect2(_CP2_EXIT_X, 300.0, _BOSS_L - _CP2_EXIT_X, 900.0), 4)

func _make_zone_trigger(node_name: String, rect: Rect2, zone: int) -> void:
	var area := Area2D.new()
	area.name = node_name
	area.collision_layer = 0
	area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	area.add_child(cs)
	area.position = rect.position + rect.size * 0.5
	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			_spawn_zone_enemies(zone))
	add_child(area)

func _spawn_zone_enemies(zone: int) -> void:
	if DebugBoot.no_enemies:
		return
	var target: Array[Node]
	var table: Dictionary
	match zone:
		1: target = _zone1_enemies; table = Z1_ENEMIES
		2: target = _zone2_enemies; table = Z2_ENEMIES
		3: target = _zone3_enemies; table = Z3_ENEMIES
		4: target = _zone4_enemies; table = Z4_ENEMIES
		_: return
	if not target.is_empty():
		return
	for kind: String in table:
		var scene: PackedScene = _TERRAGOR_ROSTER[kind]
		for pos in table[kind]:
			var e := scene.instantiate()
			(e as Node2D).global_position = pos
			add_child(e)
			target.append(e)

# ── Helpers de terreno (mesmo vocabulário dos stages 02-07) ──────────────────

func _floor_seg(zone: String, x0: float, x1: float, surface_y: float, dr: int = 3) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = "%s_Floor_%d" % [zone, int(x0)]
	b.collision_layer = 1
	b.collision_mask = 0
	var w := x1 - x0
	var h := dr * float(_TS)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	cs.shape = shape
	cs.position = Vector2(x0 + w * 0.5, surface_y + h * 0.5)
	b.add_child(cs)
	b.set_meta("lava_override", _zone_tile_path(zone))
	add_child(b)
	return b

func _solid_block(zone: String, n: String, cx: float, cy: float, w: float, h: float) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = n
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = Vector2(cx, cy)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	b.add_child(cs)
	b.set_meta("lava_override", _zone_tile_path(zone))
	add_child(b)
	return b

func _fixed_plat(n: String, zone: String, cx: float, top_y: float, w: float = 128.0) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = n
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = Vector2(cx, top_y + 16.0)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, 32.0)
	cs.shape = sh
	b.add_child(cs)
	b.set_meta("platform_override", _zone_tile_path(zone))
	add_child(b)
	return b

# Saliência que desmorona (script genérico de stage_01, reuso cross-stage —
# mesmo padrão de stage_02::_ice_crumble). LandDetector Area2D chama
# touched() quando o player pousa em cima.
func _crumble_ledge(n: String, zone: String, cx: float, top_y: float, w: float = 160.0) -> void:
	var body := StaticBody2D.new()
	body.name = n
	body.set_script(_CRUMBLE)
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2(cx, top_y + 16.0)
	body.set_meta("platform_override", _zone_tile_path(zone))
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, 32.0)
	cs.shape = sh
	body.add_child(cs)
	var det := Area2D.new()
	det.name = "LandDetector"
	det.collision_layer = 0
	det.collision_mask = 2
	var dcs := CollisionShape2D.new()
	var dsh := RectangleShape2D.new()
	dsh.size = Vector2(w, 16.0)
	dcs.shape = dsh
	dcs.position = Vector2(0.0, -24.0)
	det.add_child(dcs)
	det.body_entered.connect(func(b2: Node) -> void:
		if b2 is CharacterBase:
			body.call("touched"))
	body.add_child(det)
	add_child(body)

# ── Zona 1 — Piso instável ────────────────────────────────────────────────────
# Pequeno abismo (1600→2080, 480px) atravessado por 3 saliências que
# desmoronam ~0.5s após o pouso e respawnam em 1.2s (crumbling_ledge.gd) —
# flush com o piso normal (top_y=FLOOR_Y, mesma superfície de _floor_seg).
# Sem piso embaixo do abismo: kill plane por-fase cobre a queda (herdado,
# sem código novo, ver reference_kill_plane na memória do projeto).

func _build_zone1() -> void:
	_floor_seg("z1", 0.0, 1600.0, FLOOR_Y)
	_crumble_ledge("Z1_Crumble1", "z1", 1680.0, FLOOR_Y, 160.0)
	_crumble_ledge("Z1_Crumble2", "z1", 1840.0, FLOOR_Y, 160.0)
	_crumble_ledge("Z1_Crumble3", "z1", 2000.0, FLOOR_Y, 160.0)
	_floor_seg("z1", 2080.0, _CP1_ENTRY_X, FLOOR_Y)
```

**Antes de commitar:**
1. Ler `stages/stage_04/crusher.gd` de novo pra confirmar que `set("wait_time", ...)` é o único parâmetro exposto — a Task 8 vai precisar disso.
2. Recalcular a largura real do abismo (1600→2080 = 480px) contra os 3 `_crumble_ledge` de 160px cada (1600-1760, 1760-1920, 1920-2080) — confirmar que cobrem o vão inteiro sem gap e sem overlap.
3. Confirmar que `_TS`/`_SRC_TS` (usados por `_floor_seg`) existem em `stages/stage_scene.gd` com os mesmos nomes usados nos stages 02-07 — não assumir, ler o arquivo base.
4. Ajustar `Camera2D.limit_right` no `.tscn` (Step 1) pro valor real de `_BOSS_R + margem` já que agora ambos os arquivos existem.

- [ ] **Step 3: Parse-check headless**

Scene-load real de `stages/stage_08/stage_08.tscn`, timeout, grep por erros.

- [ ] **Step 4: Commit**

```bash
git add stages/stage_08/stage_08.tscn stages/stage_08/stage_08_scene.gd
git commit -m "feat(stage08): scaffold do script + zona 1 (piso instável)"
```

---

### Task 8: Zona 2 — Desabamentos (crushers)

**Files:**
- Modify: `stages/stage_08/stage_08_scene.gd` (adicionar `_build_zone2()` + chamada em `_ready()`)

**Interfaces:**
- Consumes: `_floor_seg`, `_fixed_plat`, `_CRUSHER` (Task 7).
- Produces: `_build_zone2()`, consumida pela Task 11 (integração final).

- [ ] **Step 1: Ler o estado atual de `_build_zone1()` e confirmar `_CP1_EXIT_X` antes de escrever**

- [ ] **Step 2: Adicionar `_build_zone2()`**

```gdscript
# ── Zona 2 — Desabamentos ─────────────────────────────────────────────────────
# Piso contínuo com 2 crushers (crusher.gd, script genérico de stage_04)
# embutidos no teto da zona (surface FLOOR_Y-500=300, centro de repouso a
# 348 = 300+48, metade da altura 96) descendo travel=404 até a base tocar o
# piso (348+404=752, borda inferior do bloco 96/2=48 abaixo → 800 = FLOOR_Y).
# Timing escalonado (wait_time 1.2/0.9) igual ao padrão de stage_04.
func _build_zone2() -> void:
	_floor_seg("z2", _CP1_EXIT_X, 4700.0, FLOOR_Y)
	var c1: AnimatableBody2D = _CRUSHER.new()
	c1.name = "Z2_Crusher1"
	c1.set("wait_time", 1.2)
	c1.collision_layer = 1
	c1.collision_mask = 0
	c1.position = Vector2(5000.0, 348.0)
	var cs1 := CollisionShape2D.new()
	var sh1 := RectangleShape2D.new()
	sh1.size = Vector2(128.0, 96.0)
	cs1.shape = sh1
	c1.add_child(cs1)
	add_child(c1)
	_floor_seg("z2", 4700.0, 6000.0, FLOOR_Y)
	var c2: AnimatableBody2D = _CRUSHER.new()
	c2.name = "Z2_Crusher2"
	c2.set("wait_time", 0.9)
	c2.collision_layer = 1
	c2.collision_mask = 0
	c2.position = Vector2(6200.0, 348.0)
	var cs2 := CollisionShape2D.new()
	var sh2 := RectangleShape2D.new()
	sh2.size = Vector2(128.0, 96.0)
	cs2.shape = sh2
	c2.add_child(cs2)
	add_child(c2)
	_floor_seg("z2", 6000.0, 7296.0, FLOOR_Y)
	# Armadura de Zara (Pernas, cf. tabela do CLAUDE.md p/ Fase 08) num desvio
	# elevado logo após o segundo crusher — mesma altura/offset usados nas
	# stages 06/07 (FLOOR_Y-98 = 98px acima do piso, dentro do alcance de
	# pulo de ~117.5px; colecionável 40px acima do topo da plataforma).
	_fixed_plat("Z2_ArmorLedge", "z2", 6600.0, FLOOR_Y - 98.0, 160.0)
	var armor := preload("res://stages/collectible.tscn").instantiate()
	armor.set("collectible_type", Collectible.Type.ARMOR_ZARA)
	armor.set("armor_piece", "legs")
	armor.global_position = Vector2(6600.0, FLOOR_Y - 138.0)
	add_child(armor)
```

**Antes de commitar:**
1. Recalcular a posição de repouso/travel dos crushers a partir das constantes REAIS (`FLOOR_Y`, `_TS`) já escritas em `stage_08_scene.gd`, não copiar cegamente `348.0`/`404.0` deste plano — o comentário acima mostra a conta, refazer com os valores reais do arquivo.
2. Confirmar que o piso sob cada crusher realmente existe (não é um buraco) — a `_hurt` Area2D de `crusher.gd` só causa dano durante a fase de queda; o jogador pode ficar parado sobre o piso normal esperando o ciclo, então o piso embaixo do crusher deve ser sólido (`_floor_seg` cobrindo toda a Zona 2, sem gap sob os crushers).
3. Confirmar que a Zona 2 termina exatamente em `7296.0` sem overlap com a Zona 3 (Task 9, que começa o piso em `7296.0`) — mesma classe de bug de piso invadindo território da próxima zona já visto nas Stages 06/07.
4. Adicionar a chamada `_build_zone2()` em `_ready()`, logo após `_build_zone1()`.

- [ ] **Step 3: Parse-check headless**

- [ ] **Step 4: Commit**

```bash
git add stages/stage_08/stage_08_scene.gd
git commit -m "feat(stage08): zona 2 (desabamentos + armadura)"
```

---

### Task 9: Zona 3 — Túnel de mineração (parede quebrável)

**Files:**
- Modify: `stages/stage_08/stage_08_scene.gd` (adicionar `_build_zone3()` + chamada em `_ready()`)

**Interfaces:**
- Consumes: `_floor_seg`, `_fixed_plat`, `_RUBBLE` (Task 7/2).
- Produces: `_build_zone3()`, consumida pela Task 11.

- [ ] **Step 1: Ler o estado atual de `_build_zone2()` antes de escrever** — confirmar o valor real onde o piso da Zona 2 termina.

- [ ] **Step 2: Adicionar um helper `_rubble_wall()` + `_build_zone3()`**

```gdscript
# Parede de entulho (rubble_wall.gd, Task 2): bloco sólido no caminho
# principal, largura 64/altura 192 (> pulo máx. ~117.5px, flush com o piso),
# quebra em hits_required hits de qualquer ataque do jogador. HitDetector
# usa a camada real dos hitboxes de ataque do jogador (confirmar o valor —
# ver nota na Task 2, "layer-8 bug" já documentado na memória do projeto).
func _rubble_wall(n: String, zone: String, cx: float, top_y: float, hits: int = 3) -> RubbleWall:
	var b: RubbleWall = _RUBBLE.new()
	b.name = n
	b.hits_required = hits
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = Vector2(cx, top_y)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(64.0, 192.0)
	cs.shape = sh
	b.add_child(cs)
	var det := Area2D.new()
	det.name = "HitDetector"
	det.collision_layer = 0
	det.collision_mask = 8   # CONFIRMAR: mesma camada usada por cracked_wall.gd (stage_01) pros hitboxes de ataque
	var dcs := CollisionShape2D.new()
	dcs.shape = sh
	det.add_child(dcs)
	b.add_child(det)
	b.set_meta("lava_override", _zone_tile_path(zone))
	add_child(b)
	return b

# ── Zona 3 — Túnel de mineração ───────────────────────────────────────────────
# Parede de entulho bloqueando o caminho principal em x≈8700 — quebra em 3
# hits de qualquer ataque. Extra de Zael (Cannon) + coração + sub-tank num
# desvio logo depois, guardados atrás da parede (só acessíveis depois de
# quebrá-la).
func _build_zone3() -> void:
	_floor_seg("z3", 7296.0, 8700.0, FLOOR_Y)
	_rubble_wall("Z3_RubbleWall", "z3", 8700.0, FLOOR_Y - 96.0, 3)
	_floor_seg("z3", 8700.0, _CP2_ENTRY_X, FLOOR_Y)
	_fixed_plat("Z3_ExtraLedge", "z3", 8900.0, FLOOR_Y - 98.0, 200.0)
	var cannon := preload("res://stages/collectible.tscn").instantiate()
	cannon.set("collectible_type", Collectible.Type.SHOT_ZAEL)
	cannon.set("ability_id", "cannon")
	cannon.global_position = Vector2(8850.0, FLOOR_Y - 138.0)
	add_child(cannon)
	var heart := preload("res://stages/collectible.tscn").instantiate()
	heart.set("collectible_type", Collectible.Type.HEART)
	heart.set("stage_id", 8)
	heart.global_position = Vector2(8900.0, FLOOR_Y - 138.0)
	add_child(heart)
	var subtank := preload("res://stages/collectible.tscn").instantiate()
	subtank.set("collectible_type", Collectible.Type.SUBTANK)
	subtank.set("subtank_index", 4)
	subtank.global_position = Vector2(8950.0, FLOOR_Y - 138.0)
	add_child(subtank)
```

**Antes de commitar:**
1. Confirmar em `characters/enemies/enemy_base.gd`/`characters/base/character_base.gd` (ou onde os hitboxes de ataque do jogador são definidos) a camada real usada — `collision_mask = 8` acima é um placeholder herdado de `cracked_wall.gd`, CONFIRMAR antes de commitar, não assumir.
2. Confirmar `subtank_index` real ainda não usado por outra fase (grep `subtank_index` em todos os `stages/*/*.tscn`/`*.gd` — os índices 0-3 já foram usados pelas stages pares anteriores per CLAUDE.md, `4` é só um placeholder deste plano).
3. Recalcular se `Z3_RubbleWall` (top_y=FLOOR_Y-96=704, altura 192 → spans y=[608,800]) realmente bloqueia toda a largura navegável (sem gap lateral, sem squeeze-under) e se as 3 collectibles em `Z3_ExtraLedge` (200px de largura) cabem sem overlap.
4. Confirmar que a Zona 3 termina exatamente em `_CP2_ENTRY_X` sem gap/overlap com o corredor CP2 (Task 7, `_setup_corridors`).
5. Adicionar a chamada `_build_zone3()` em `_ready()`, logo após `_build_zone2()`.

- [ ] **Step 3: Parse-check headless**

- [ ] **Step 4: Commit**

```bash
git add stages/stage_08/stage_08_scene.gd
git commit -m "feat(stage08): zona 3 (túnel de mineração + parede quebrável + colectáveis)"
```

---

### Task 10: Zona 4 + sala do boss

**Files:**
- Modify: `stages/stage_08/stage_08_scene.gd` (adicionar `_build_zone4()`, `_build_boss_arena()` + chamadas em `_ready()`)

**Interfaces:**
- Consumes: `_floor_seg`, `_solid_block` (Task 7), nó `Terragor` já presente na `.tscn` (Task 7 Step 1).
- Produces: `_build_zone4()`, `_build_boss_arena()`, consumidos pela Task 11.

- [ ] **Step 1: Adicionar `_build_zone4()` e `_build_boss_arena()`**

Em `_ready()`:
```gdscript
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_boss_arena()
	_setup_zone_triggers()
```

```gdscript
# ── Zona 4 — Corredor final com canhões de pedra ──────────────────────────────

func _build_zone4() -> void:
	_floor_seg("z4", _CP2_EXIT_X, _BOSS_L, FLOOR_Y)

# ── Sala do boss (Terragor) ────────────────────────────────────────────────────
# Padrão B (porta aberta + trigger, skill new-boss-room): arena aberta,
# aggro por Area2D de entrada — não por distância. Terragor é walker
# terrestre (gravity padrão, não voa) — arena_floor não é lido por
# _clamp_to_arena() (só clampa X, ver boss_base.gd), mas é setado por
# convenção do projeto mesmo assim (Global Constraints).

func _build_boss_arena() -> void:
	_floor_seg("boss", _BOSS_L, _BOSS_R, FLOOR_Y)
	_solid_block("boss", "Boss_WallR", _BOSS_R + 32.0, FLOOR_Y - 256.0, 64.0, 512.0)
	_solid_block("boss", "Boss_WallL_Top", _BOSS_L + 32.0, FLOOR_Y - 448.0, 64.0, 256.0)
	var terragor := get_node_or_null("Terragor")
	if terragor:
		terragor.visible = true
		terragor.global_position = Vector2((_BOSS_L + _BOSS_R) * 0.5, FLOOR_Y - 64.0)
		terragor.set("auto_aggro", false)
		terragor.set("arena_left", _BOSS_L + 64.0)
		terragor.set("arena_right", _BOSS_R - 64.0)
		terragor.set("arena_floor", FLOOR_Y)
		var trig := Area2D.new()
		trig.name = "BossRoomTrigger"
		trig.collision_layer = 0
		trig.collision_mask = 2
		trig.position = Vector2((_BOSS_L + _BOSS_R) * 0.5, FLOOR_Y - 150.0)
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(_BOSS_R - _BOSS_L - 200.0, 300.0)
		cs.shape = sh
		trig.add_child(cs)
		add_child(trig)
		trig.body_entered.connect(func(b: Node) -> void:
			if b is CharacterBase:
				terragor.call("aggro"))
		if terragor.has_signal("boss_defeated"):
			terragor.connect("boss_defeated", _on_boss_defeated)

func _on_boss_defeated(_ability_id: String) -> void:
	GameManager.save_game()
```

**Antes de commitar**: (a) ler `stages/stage_scene.gd::_ready()` pra confirmar se a conexão genérica de HUD/boss (`$HUD.connect_to_boss`) ainda existe pra qualquer `BossBase` presente na árvore antes desta função rodar — se sim, NÃO duplicar a chamada aqui (mesmo caso já resolvido nas Stages 06/07); (b) recalcular os valores de `arena_left`/`arena_right`/`arena_floor` contra as constantes REAIS do arquivo e confirmar que `terragor.global_position` cai dentro do intervalo `[arena_left, arena_right]`; (c) confirmar `Boss_WallR`/`Boss_WallL_Top`/largura da sala múltiplos de 64px (`_BOSS_R - _BOSS_L = 13952-12544 = 1408 = 22×64`, recalcular com os valores reais).

- [ ] **Step 2: Parse-check headless**

- [ ] **Step 3: Commit**

```bash
git add stages/stage_08/stage_08_scene.gd
git commit -m "feat(stage08): zona 4 + sala do boss Terragor (com arena bounds)"
```

---

### Task 11: Teto por zona + integração final

**Files:**
- Modify: `stages/stage_08/stage_08_scene.gd` (adicionar `_CEIL08_SEGS`, `_build_zone_ceilings08()`, `_ceil08_surface_at()`, `_draw_zone_ceilings08()`, `_draw()`, chamada em `_ready()`)

**Interfaces:**
- Consumes: todas as zonas das Tasks 7-10.
- Produces: fase jogável completa, testada headless + testes de regressão.

- [ ] **Step 1: Adicionar sistema de teto (FACE_GAP + fallback cross-zone + offset visual correto desde o início)**

Em `_ready()`, como ÚLTIMA chamada de construção:
```gdscript
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_boss_arena()
	_build_zone_ceilings08()
	_setup_zone_triggers()
```

Como a fase inteira fica numa única elevação (`FLOOR_Y = 800.0`), o teto é uma faixa reta por zona. A entrada `"Z2"` cobre `[_CP1_EXIT_X, _CP2_ENTRY_X]`, que abrange fisicamente a Zona 2 (Task 8) + Zona 3 (Task 9) inteiras — mesmo padrão já usado nas Stages 06/07 (sem entrada `"Z3"` própria):

```gdscript
# ── Teto por zona ─────────────────────────────────────────────────────────────
# A entrada "Z2" cobre [_CP1_EXIT_X, _CP2_ENTRY_X], que abrange o piso real
# da Zona 2 (Task 8) + Zona 3 (Task 9) inteiras — mesmo padrão de stage_06/07
# (sem entrada "Z3" própria). CONFIRMAR contra os _floor_seg reais escritos
# nas Tasks 8/9 antes de commitar — se houver gap/overlap, adicionar uma
# entrada "Z3" própria em vez de confiar só no fallback cross-zone.
const _CEIL08_SEGS := {
	"Z1":   [[0.0, _CP1_ENTRY_X, FLOOR_Y - 500.0]],
	"Z2":   [[_CP1_EXIT_X, _CP2_ENTRY_X, FLOOR_Y - 500.0]],
	"Z4":   [[_CP2_EXIT_X, _BOSS_L, FLOOR_Y - 500.0]],
	"Boss": [[_BOSS_L, _BOSS_R, FLOOR_Y - 448.0 - 256.0]],
}
const _CEIL08_TEX := { "Z1": "z1", "Z2": "z2", "Z4": "z4", "Boss": "z4" }
const _CEIL08_TOP := 128.0
const _CEIL08_FACE_GAP := 32.0

func _build_zone_ceilings08() -> void:
	for zk: String in _CEIL08_SEGS:
		var body := StaticBody2D.new()
		body.name = "%sCeilSegs" % zk
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		for s: Array in _CEIL08_SEGS[zk]:
			var cs := CollisionShape2D.new()
			var sh := SegmentShape2D.new()
			sh.a = Vector2(s[0], (s[2] as float) - _CEIL08_FACE_GAP)
			sh.b = Vector2(s[1], (s[2] as float) - _CEIL08_FACE_GAP)
			cs.shape = sh
			body.add_child(cs)

func _ceil08_surface_at(zk: String, wx: float) -> float:
	for s: Array in _CEIL08_SEGS[zk]:
		if wx >= (s[0] as float) and wx < (s[1] as float):
			return s[2]
	for zk2: String in _CEIL08_SEGS:
		if zk2 == zk:
			continue
		for s: Array in _CEIL08_SEGS[zk2]:
			if wx >= (s[0] as float) and wx < (s[1] as float):
				return s[2]
	return -1.0

func _ceil08_solid(zk: String, wx: float, y: float) -> bool:
	var yb := _ceil08_surface_at(zk, wx)
	return yb > 0.0 and y < yb

func _draw() -> void:
	super._draw()
	_draw_zone_ceilings08()

func _draw_zone_ceilings08() -> void:
	var ts := float(_TS)
	var sts := float(_SRC_TS)
	for zk: String in _CEIL08_SEGS:
		var segs: Array = _CEIL08_SEGS[zk]
		var tex := _cached_override_tex(_zone_tile_path(_CEIL08_TEX[zk] as String))
		if tex == null:
			continue
		var x0f: float = segs[0][0]
		var x1f: float = segs[segs.size() - 1][1]
		var x := x0f
		while x < x1f:
			var yb := _ceil08_surface_at(zk, x)
			var y := _CEIL08_TOP
			while y < yb:
				var ed := not _ceil08_solid(zk, x, y + ts)
				var el := not _ceil08_solid(zk, x - ts, y)
				var er := not _ceil08_solid(zk, x + ts, y)
				var tile: Vector2i
				if   ed and el: tile = Vector2i(0, 2)
				elif ed and er: tile = Vector2i(3, 3)
				elif ed:        tile = Vector2i(1, 2)
				elif el:        tile = Vector2i(1, 0)
				elif er:        tile = Vector2i(3, 2)
				elif not _ceil08_solid(zk, x - ts, y + ts): tile = Vector2i(2, 2)
				elif not _ceil08_solid(zk, x + ts, y + ts): tile = Vector2i(3, 1)
				else:           tile = Vector2i(2, 1)
				draw_texture_rect_region(tex, Rect2(x, y, ts, ts),
					Rect2(float(tile.x) * sts, float(tile.y) * sts, sts, sts))
				y += ts
			x += ts
```

**Nota**: verificar se o teto da Zona 2 (y=300 de superfície, colisão a 268) não colide com o ponto de repouso dos crushers da Task 8 (centro y=348, topo do bloco em repouso = 348-48=300) — 32px de folga esperados, recalcular contra os números reais escritos na Task 8, não os deste plano.

- [ ] **Step 2: Parse-check headless do script**

Scene-load real, grep por erros.

- [ ] **Step 3: Parse-check headless da cena completa**

`timeout 30 "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://stages/stage_08/stage_08.tscn`, grep por `script error|parse error` (case-insensitive) no log. Expected: nenhuma ocorrência.

- [ ] **Step 4: Rodar os testes automatizados existentes**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```
`test_game_manager`/`test_stage_manager` devem passar limpos. `test_character_base` pode reportar as mesmas 3 asserções pré-existentes já confirmadas como não-relacionadas (`current_hp equals max_hp on ready`, `hp is 70 after 30 damage`, `second hit blocked during invincibility`) — confirmar via `git diff --stat <branch-base>..HEAD -- characters/base/character_base.gd autoloads/game_manager.gd` mostrando vazio.

- [ ] **Step 5: Traçar a travessia ponta a ponta uma última vez**

Reler o arquivo final e confirmar, com os números REAIS: Z1 piso instável+desmoronamento → corredor CP1 → Z2 crushers → armadura → Z3 parede quebrável+traps → extra+coração+subtank → corredor CP2 → Z4 corredor → sala do boss. Confirmar que `Z3_RubbleWall` realmente bloqueia o caminho até quebrar (sem desvio lateral) e que os 3 collectibles atrás dela ficam genuinamente inacessíveis antes de quebrá-la (não há rota alternativa nem pulo que contorne). Esse é o mesmo tipo de checagem que a revisão final de branch inteiro das Stages 05/06/07 fez e que pegou bugs reais de wiring cross-task.

- [ ] **Step 6: Export web (não commitar — o deploy agora builda no CI)**

**NÃO rodar `--export-release` nem commitar `export/web/*`** — o `.github/workflows/deploy.yml` builda o jogo automaticamente a cada push na master. Rodar só o parse-check/scene-load local (Steps 2-4) como verificação; o deploy real acontece sozinho depois do merge.

- [ ] **Step 7: Commit final**

```bash
git add stages/stage_08/stage_08_scene.gd
git commit -m "feat(stage08): teto por zona + integração final"
```

---

## Self-Review

**1. Cobertura do spec:** Z1 piso instável (Task 7) ✓, Z2 desabamentos+armadura (Task 8) ✓, Z3 parede quebrável+extra+coração+subtank (Task 9) ✓, Z4+boss com arena bounds (Task 10) ✓, roster de 9 (Tasks 4-6) ✓, 2 checkpoints (Task 7) ✓, teto com FACE_GAP/fallback/offset-visual-correto desde o início (Task 11) ✓, colectáveis via enum desde o início (Tasks 8-9) ✓, fase 2 real do boss (Task 3) ✓, componente novo neutro sob bot (Task 2) ✓.

**2. Placeholders:** nenhum "TBD"/"implementar depois". Cada task de zona tem instrução explícita de reconferir a aritmética contra o código de verdade escrito, não contra os números de exemplo do plano — mesmo padrão que funcionou nas Stages 05/06/07 pra pegar bugs reais antes do merge. A camada de colisão do `HitDetector` da parede quebrável (Task 9) é explicitamente marcada como "CONFIRMAR" — não um placeholder esquecido, uma instrução deliberada de verificação.

**3. Consistência de tipos:** `StoneBolt.setup()` (Task 1) usado identicamente pelas Tasks 5 (`stone_glider`) e 6 (`boulder_turret`, `fossil_totem`). `_TERRAGOR_ROSTER` (Task 7) referencia exatamente os nomes de arquivo `.tscn` criados nas Tasks 4-6. `RubbleWall.hits_required`/`wall_destroyed` (Task 2) batendo entre definição e uso na Task 9. `QuakeWave.direction`/`speed`/`damage` (Task 3) batendo entre definição e uso em `terragor.gd`. `crumbling_ledge.gd`/`crusher.gd` (reuso cross-stage, Task 7) instanciados com a mesma assinatura já validada nos stages 01/02/04.

---

**Plan complete and saved to `docs/superpowers/plans/2026-07-18-stage08-terragor-redesign.md`.**

Seguindo direto pra execução via subagent-driven-development, conforme pedido — sem pausa pra escolha de abordagem.
