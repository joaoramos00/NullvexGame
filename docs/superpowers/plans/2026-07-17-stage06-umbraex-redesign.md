# Stage 06 Umbraex Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework Stage 06 (Umbraex, tema sombra) do esqueleto atual pra uma fase completa com 4 zonas temáticas, roster de 9 inimigos com IA funcional, 2 mecânicas novas (plataforma fasing, portal de sombra) com dificuldade crescente, e sala do boss.

**Architecture:** `stages/stage_06/stage_06_scene.gd extends "res://stages/stage_scene.gd"` (mesmo padrão de stage_04/05), zonas construídas em código via o mesmo vocabulário de helpers já validado (`_floor_seg`/`_solid_block`/`_glass_wall`/`_fixed_plat`/`_setup_corridors`/`_make_corridor`/`_setup_zone_triggers`/`_spawn_zone_enemies`). Dois componentes novos: `phase_platform.gd` (toggle de colisão por tempo, mesma técnica de `crumbling_ledge.gd`) e `shadow_portal.gd` (par de `Area2D` reposicionando o corpo, sem precedente no código — desenhado do zero). 9 scripts de IA em `characters/enemies/stage_06/`, cada um clonando o template mais próximo já em produção nas stages 01-05.

**Tech Stack:** Godot 4.6.2 GDScript, headless parse-check, sprites/tileset já existentes (nenhum asset novo).

## Global Constraints

- Nomes de arquivo/script em snake_case; `class_name` em PascalCase.
- `CorridorSection` sempre 896×64 / zoom 2.0 — nunca variar a largura do corredor.
- Nenhuma cura em checkpoints/corredores (`heal_on_entry = false`).
- Teto por zona usa `_CEIL_FACE_GAP` (colisão 32px acima do nominal, visual intocado) e fallback cross-zone desde a primeira versão (não como fix posterior) — ver memórias `reference_ceiling_collision_gap`/`reference_ceiling_zone_boundary`.
- `sign()`/`clamp()`/`abs()` sempre tipados explicitamente com `: float` no build web.
- `phase_platform.gd` fica sempre SÓLIDA quando `DebugBoot.bot_enabled`; `shadow_portal.gd` continua funcionando normalmente sob `bot_enabled` (teleporte é reposicionamento discreto, não força contínua — não precisa de caso especial).
- Toda coordenada de piso/parede/sala da sala do boss deve ser múltiplo de 64px (skill `new-boss-room`).
- Após cada task: parse-check headless (`--headless --path . res://<cena>.tscn` com timeout, ou scene-load pra `.gd` isolado — `--check-only --script` dá falso-positivo em qualquer script que toque autoload, usar carregamento de cena real) antes de seguir pra próxima.
- **Verificação de geometria é responsabilidade de CADA task, não só do plano**: antes de finalizar qualquer zona, recalcular manualmente as coordenadas X/Y de piso/plataforma/portal a partir do código de verdade (não confiar só na prosa deste documento) e confirmar que a travessia é fisicamente possível (gaps de piso ≤196px de alcance horizontal / ≤118px de altura salvo quando cruzados por portal, que não tem esse limite). Esse é o padrão que revisões da Stage 05 (plano irmão) usaram pra achar e corrigir 4 bugs reais de geometria antes do merge — replicar o mesmo rigor aqui.

---

### Task 1: Projétil compartilhado shadow_projectile

**Files:**
- Create: `characters/enemies/stage_06/shadow_projectile.gd`
- Create: `characters/enemies/stage_06/shadow_projectile.tscn`

**Interfaces:**
- Produces: `ShadowProjectile.setup(velocity_value: Vector2, damage_value: int, source_value := "stage06_shadow", gravity_value := 0.0, variant_value := "shadow_bolt") -> void` — usado pelas Tasks 4-6.

- [ ] **Step 1: Criar o script do projétil**

`characters/enemies/stage_06/shadow_projectile.gd`:
```gdscript
extends Area2D
class_name ShadowProjectile

# Projétil de sombra compartilhado do roster do stage 06 (molde do wind_projectile).
const TEX := {
	"shadow_bolt": preload("res://characters/enemies/stage_06/shadow_bolt.png"),
	"void_shard": preload("res://characters/enemies/stage_06/void_shard.png"),
}

var projectile_velocity: Vector2 = Vector2(300.0, 0.0)
var damage: int = 6
var source_id: String = "stage06_shadow"
var variant: String = "shadow_bolt"
var _lifetime: float = 4.0
var _hit := false
var _anim_timer := 0.0
var _frame := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_enemy_shoot)

func setup(velocity_value: Vector2, damage_value: int, source_value := "stage06_shadow",
		gravity_value := 0.0, variant_value := "shadow_bolt") -> void:
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

- [ ] **Step 2: Criar a cena do projétil**

`characters/enemies/stage_06/shadow_projectile.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_06/shadow_projectile.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_06/shadow_bolt.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="Circ_1"]
radius = 10.0

[node name="ShadowProjectile" type="Area2D"]
collision_layer = 0
collision_mask = 2
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Circ_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 2
vframes = 2
frame = 0
```

- [ ] **Step 3: Parse-check headless**

Run: instanciar `shadow_projectile.tscn` numa cena temporária carregada via `--headless --path . res://<temp>.tscn` (mesma técnica das Tasks 1-5 do plano da Stage 05 — `--check-only --script` dá falso-positivo em `AudioLibrary`/`AudioManager`).
Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 4: Commit**

```bash
git add characters/enemies/stage_06/shadow_projectile.gd characters/enemies/stage_06/shadow_projectile.tscn
git commit -m "feat(stage06): projétil de sombra compartilhado do roster"
```

---

### Task 2: Componente `phase_platform.gd`

**Files:**
- Create: `stages/stage_06/phase_platform.gd`

**Interfaces:**
- Produces: `PhasePlatform` (`StaticBody2D`), `@export var solid_time: float`, `@export var phase_time: float`, `@export var phase_offset: float` — instanciado pelas Tasks 8-9 (Zonas 1/2).

- [ ] **Step 1: Criar o componente**

`stages/stage_06/phase_platform.gd`:
```gdscript
# Plataforma que alterna sólida/vazia num ciclo temporizado — mesma técnica
# de toggle de colisão de stages/stage_01/crumbling_ledge.gd (set_deferred
# "disabled" + skip_base_draw), só que disparada por tempo, não por contato.
# phase_offset dessincroniza múltiplas instâncias entre si (Zona 2).
extends StaticBody2D

@export var solid_time: float = 2.0
@export var phase_time: float = 1.0
@export var phase_offset: float = 0.0
@export var warn_time: float = 0.3   # flicker de aviso antes de fasear

var _cs: CollisionShape2D
var _timer: float = 0.0
var _solid: bool = true

func _ready() -> void:
	_cs = get_node_or_null("CollisionShape2D")
	if _cs == null:
		for c in get_children():
			if c is CollisionShape2D:
				_cs = c
				break
	assert(_cs != null, "PhasePlatform precisa de um CollisionShape2D filho")
	_timer = phase_offset
	if not DebugBoot.bot_enabled:
		_catch_up()

func _catch_up() -> void:
	# Aplica o avanço de phase_offset sem esperar o primeiro frame de física
	# (senão a plataforma pisca visualmente sólida por 1 frame antes de ajustar).
	while _timer >= (solid_time if _solid else phase_time):
		_timer -= (solid_time if _solid else phase_time)
		_solid = not _solid
	_apply_state()

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return   # bot: plataforma sempre sólida, valida o layout sem depender do timing
	_timer += delta
	var period: float = solid_time if _solid else phase_time
	if _timer >= period:
		_timer -= period
		_solid = not _solid
		_apply_state()
	elif _solid and (period - _timer) <= warn_time:
		visible = int(Time.get_ticks_msec() / 80) % 2 == 0
	else:
		visible = true

func _apply_state() -> void:
	if _cs:
		_cs.set_deferred("disabled", not _solid)
	visible = _solid
	if _solid:
		if has_meta("skip_base_draw"):
			remove_meta("skip_base_draw")
	else:
		set_meta("skip_base_draw", true)
```

- [ ] **Step 2: Parse-check headless**

Run: instanciar em cena temporária, confirmar sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_06/phase_platform.gd
git commit -m "feat(stage06): componente de plataforma fasing"
```

---

### Task 3: Componente `shadow_portal.gd`

**Files:**
- Create: `stages/stage_06/shadow_portal.gd`

**Interfaces:**
- Produces: `ShadowPortal` (`Area2D`), método `link_partner(other: Node2D) -> void` — instanciado em pares pelas Tasks 9-10 (Zonas 3/4) via um helper `_shadow_portal_pair` que a Task 9 adiciona em `stage_06_scene.gd`.

- [ ] **Step 1: Criar o componente**

`stages/stage_06/shadow_portal.gd`:
```gdscript
# Portal de sombra: par de Area2D que reposiciona o corpo que entrar numa
# delas pra posição da outra, preservando velocity (CharacterBody2D.velocity
# não é tocado, só global_position muda). Cooldown por corpo em AMBOS os
# portais evita re-teleporte imediato quando as duas áreas ficam próximas
# (o corpo chega na saída já sobrepondo a área dela).
extends Area2D
class_name ShadowPortal

@export var reentry_cooldown: float = 0.3

var _partner: ShadowPortal = null
var _cooldown: Dictionary = {}   # Node -> float (tempo restante)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func link_partner(other: Node2D) -> void:
	_partner = other as ShadowPortal

func mark_cooldown(body: Node) -> void:
	_cooldown[body] = reentry_cooldown

func _on_body_entered(body: Node) -> void:
	if _partner == null:
		return
	if _cooldown.has(body):
		return
	if not (body is Node2D):
		return
	(body as Node2D).global_position = _partner.global_position
	mark_cooldown(body)
	_partner.mark_cooldown(body)

func _physics_process(delta: float) -> void:
	if _cooldown.is_empty():
		return
	for b in _cooldown.keys().duplicate():
		_cooldown[b] -= delta
		if _cooldown[b] <= 0.0:
			_cooldown.erase(b)
```

- [ ] **Step 2: Parse-check headless**

Run: instanciar em cena temporária, confirmar sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_06/shadow_portal.gd
git commit -m "feat(stage06): componente de portal de sombra"
```

---

### Task 4: Inimigos terrestres/melee (shadow_stalker, eclipse_duelist, night_pouncer)

**Files:**
- Create: `characters/enemies/stage_06/enemy_shadow_stalker.gd` + `.tscn`
- Create: `characters/enemies/stage_06/enemy_eclipse_duelist.gd` + `.tscn`
- Create: `characters/enemies/stage_06/enemy_night_pouncer.gd` + `.tscn`

**Interfaces:**
- Produces: 3 `PackedScene` prontas pra `preload()` na Task 7.

- [ ] **Step 1: `enemy_shadow_stalker` — melee agachado com investida curta (molde `enemy_claw_glider`, Stage 05)**

`characters/enemies/stage_06/enemy_shadow_stalker.gd`:
```gdscript
extends EnemyBase
class_name EnemyShadowStalker

# Assassino agachado: investida de garra curta e rápida quando o player está perto.
const FRAMES := 6
const FPS := 9.0
const DETECT_X := 160.0
const DETECT_Y := 50.0
const LUNGE_SPEED := 280.0
const LUNGE_TIME := 0.35
const LUNGE_COOLDOWN := 1.2

var _lunge_timer := 0.0
var _cooldown := 0.4

func _init() -> void:
	max_hp = 10
	contact_damage = 9

func _ready() -> void:
	max_hp = 10
	contact_damage = 9
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _lunge_timer > 0.0:
		_lunge_timer -= delta
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = LUNGE_SPEED * _direction
		move_and_slide()
		if is_on_wall():
			_lunge_timer = 0.0
		if _lunge_timer <= 0.0:
			_cooldown = LUNGE_COOLDOWN
		_advance_sprite_frame_loop(delta, FRAMES, FPS * 1.8)
		_sprite.flip_h = (_direction < 0)
		return
	super._physics_process(delta)
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null:
		var off: Vector2 = p.global_position - global_position
		if absf(off.x) <= DETECT_X and absf(off.y) <= DETECT_Y:
			_direction = signf(off.x)
			_lunge_timer = LUNGE_TIME
```

`characters/enemies/stage_06/enemy_shadow_stalker.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_06/enemy_shadow_stalker.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_06/enemy_shadow_stalker.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 20.0
height = 64.0

[node name="EnemyShadowStalker" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 2
frame = 0
scale = Vector2(0.75, 0.75)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 2: `enemy_eclipse_duelist` — duelista pesado com investida (molde `enemy_mass_brute`, Stage 04, HP maior — arquétipo "elite")**

`characters/enemies/stage_06/enemy_eclipse_duelist.gd`:
```gdscript
extends EnemyBase
class_name EnemyEclipseDuelist

# Duelista de elite: patrulha; ao ver o player no mesmo nível, dispara uma
# investida de lâmina até bater em parede ou esgotar o tempo. HP alto (elite).
const FRAMES := 6
const FPS := 10.0
const DETECT_X := 340.0
const DETECT_Y := 70.0
const CHARGE_SPEED := 260.0
const CHARGE_TIME := 1.1
const CHARGE_COOLDOWN := 1.6

var _charge_timer := 0.0
var _cooldown := 0.6

func _init() -> void:
	max_hp = 24
	contact_damage = 13

func _ready() -> void:
	max_hp = 24
	contact_damage = 13
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _charge_timer > 0.0:
		_charge_timer -= delta
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = CHARGE_SPEED * _direction
		move_and_slide()
		if is_on_wall():
			_charge_timer = 0.0
		if _charge_timer <= 0.0:
			_cooldown = CHARGE_COOLDOWN
		_advance_sprite_frame_loop(delta, FRAMES, FPS * 1.6)
		_sprite.flip_h = (_direction < 0)
		return
	super._physics_process(delta)
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null:
		var off: Vector2 = p.global_position - global_position
		if absf(off.x) <= DETECT_X and absf(off.y) <= DETECT_Y:
			_direction = signf(off.x)
			_charge_timer = CHARGE_TIME
```

`characters/enemies/stage_06/enemy_eclipse_duelist.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_06/enemy_eclipse_duelist.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_06/enemy_eclipse_duelist.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 20.0
height = 72.0

[node name="EnemyEclipseDuelist" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 2
frame = 0
scale = Vector2(0.78, 0.78)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: `enemy_night_pouncer` — pulador terrestre (molde `enemy_ash_hopper`, Stage 01)**

`characters/enemies/stage_06/enemy_night_pouncer.gd`:
```gdscript
extends EnemyBase
class_name EnemyNightPouncer

# Predador que salta em arco periodicamente, vira nas bordas/paredes.
const FRAMES := 9
const FPS := 10.0
const HOP_INTERVAL := 0.9
const HOP_VY := -460.0
const HOP_VX := 150.0

var _hop_timer := 0.6

func _init() -> void:
	max_hp = 8
	contact_damage = 8

func _ready() -> void:
	max_hp = 8
	contact_damage = 8
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor():
		if not _has_floor_ahead():
			_direction = -_direction
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			_hop_timer = HOP_INTERVAL
			velocity.y = HOP_VY
			velocity.x = HOP_VX * _direction
		else:
			velocity.x = 0.0
	move_and_slide()
	if is_on_wall():
		_direction = -_direction
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if (_invincible and int(Time.get_ticks_msec() / 80) % 2 == 0) else 1.0
	_advance_sprite_frame_loop(delta, FRAMES, FPS)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
```

`characters/enemies/stage_06/enemy_night_pouncer.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_06/enemy_night_pouncer.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_06/enemy_night_pouncer.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 18.0
height = 60.0

[node name="EnemyNightPouncer" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 3
frame = 0
scale = Vector2(0.72, 0.72)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 4: Parse-check headless dos 3 scripts**

Run: carregar cada `.tscn` numa cena temporária headless. Expected: sem `SCRIPT ERROR`/`Parse Error` em nenhum dos 3.

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_06/enemy_shadow_stalker.* characters/enemies/stage_06/enemy_eclipse_duelist.* characters/enemies/stage_06/enemy_night_pouncer.*
git commit -m "feat(stage06): inimigos terrestres/melee (shadow_stalker, eclipse_duelist, night_pouncer)"
```

---

### Task 5: Inimigos voadores/suspensos (umbra_bat, void_orbiter, shadow_snare)

**Files:**
- Create: `characters/enemies/stage_06/enemy_umbra_bat.gd` + `.tscn`
- Create: `characters/enemies/stage_06/enemy_void_orbiter.gd` + `.tscn`
- Create: `characters/enemies/stage_06/enemy_shadow_snare.gd` + `.tscn`

**Interfaces:**
- Consumes: `ShadowProjectile.setup(...)` (Task 1), `res://characters/enemies/enemy_flyer.gd`.
- Produces: 3 `PackedScene` prontas pra Task 7.

- [ ] **Step 1: `enemy_umbra_bat` — mergulhador padrão (molde `enemy_sky_harrier`, Stage 05)**

`characters/enemies/stage_06/enemy_umbra_bat.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyUmbraBat

# Morcego patrulheiro: mergulhador padrão, dive rápido quando detecta o player.
func _ready() -> void:
	super._ready()
	max_hp = 8
	contact_damage = 9
	current_hp = max_hp
	detect_radius = 260.0
	dive_speed = 380.0
	retreat_speed = 190.0
	patrol_range = 200.0
	bob_amplitude = 10.0
```

`characters/enemies/stage_06/enemy_umbra_bat.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_06/enemy_umbra_bat.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_06/enemy_umbra_bat.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(70.0, 60.0)

[node name="EnemyUmbraBat" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 3
frame = 0
scale = Vector2(0.7, 0.7)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 2: `enemy_void_orbiter` — hover-atirador (molde `enemy_turbine_wisp`, Stage 05)**

`characters/enemies/stage_06/enemy_void_orbiter.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyVoidOrbiter

# Núcleo de sombra flutuante: hover puro (sem mergulho) + tiro de shadow_bolt.
const _PROJ := preload("res://characters/enemies/stage_06/shadow_projectile.tscn")
const SHOOT_INTERVAL := 1.7
const SHOOT_RANGE := 420.0
const BOLT_SPEED := 300.0
const BOLT_DAMAGE := 6

var _shoot_timer := 0.7

func _ready() -> void:
	super._ready()
	max_hp = 7
	contact_damage = 5
	current_hp = max_hp
	dive_speed = 0.0
	detect_radius = 0.0
	patrol_range = 110.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p != null and global_position.distance_to(p.global_position) <= SHOOT_RANGE:
			_shoot_timer = SHOOT_INTERVAL
			_fire_bolt(p)

func _fire_bolt(target: Node2D) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var proj := _PROJ.instantiate() as ShadowProjectile
	proj.setup(dir * BOLT_SPEED, BOLT_DAMAGE, "void_orbiter", 0.0, "shadow_bolt")
	get_parent().add_child(proj)
	proj.global_position = global_position
```

`characters/enemies/stage_06/enemy_void_orbiter.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_06/enemy_void_orbiter.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_06/enemy_void_orbiter.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="Cap_1"]
radius = 26.0

[node name="EnemyVoidOrbiter" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 2
frame = 0
scale = Vector2(0.7, 0.7)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: `enemy_shadow_snare` — drone suspenso que persegue devagar (molde `enemy_gale_grappler`, Stage 05 — arquétipo "heavy"/suspenso)**

`characters/enemies/stage_06/enemy_shadow_snare.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyShadowSnare

# Armadilha suspensa: flutua e avança devagar até o player quando detecta —
# contato pesado, HP alto.
func _ready() -> void:
	super._ready()
	max_hp = 16
	contact_damage = 13
	current_hp = max_hp
	detect_radius = 320.0
	dive_speed = 130.0
	retreat_speed = 70.0
	patrol_range = 70.0
	bob_amplitude = 14.0
```

`characters/enemies/stage_06/enemy_shadow_snare.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_06/enemy_shadow_snare.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_06/enemy_shadow_snare.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(76.0, 70.0)

[node name="EnemyShadowSnare" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 3
frame = 0
scale = Vector2(0.72, 0.72)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 4: Parse-check headless dos 3 scripts**

Run: carregar cada `.tscn` numa cena temporária headless. Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_06/enemy_umbra_bat.* characters/enemies/stage_06/enemy_void_orbiter.* characters/enemies/stage_06/enemy_shadow_snare.*
git commit -m "feat(stage06): inimigos voadores/suspensos (umbra_bat, void_orbiter, shadow_snare)"
```

---

### Task 6: Inimigos estáticos (phase_mine, dark_lantern, eclipse_turret)

**Files:**
- Create: `characters/enemies/stage_06/enemy_phase_mine.gd` + `.tscn`
- Create: `characters/enemies/stage_06/enemy_dark_lantern.gd` + `.tscn`
- Create: `characters/enemies/stage_06/enemy_eclipse_turret.gd` + `.tscn`

**Interfaces:**
- Consumes: `ShadowProjectile.setup(...)` (Task 1).
- Produces: 3 `PackedScene` prontas pra Task 7/9.

- [ ] **Step 1: `enemy_phase_mine` — mina flutuante lenta (molde `enemy_gravity_mine`, Stage 04)**

`characters/enemies/stage_06/enemy_phase_mine.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyPhaseMine

# Mina quase-invisível: flutua parada, avança bem devagar até o player
# quando detecta — HP baixo, contato forte.
func _ready() -> void:
	super._ready()
	max_hp = 6
	contact_damage = 12
	current_hp = max_hp
	detect_radius = 340.0
	dive_speed = 150.0
	retreat_speed = 60.0
	patrol_range = 80.0
	bob_amplitude = 16.0
```

`characters/enemies/stage_06/enemy_phase_mine.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_06/enemy_phase_mine.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_06/enemy_phase_mine.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="Cap_1"]
radius = 22.0

[node name="EnemyPhaseMine" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 2
frame = 0
scale = Vector2(0.7, 0.7)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 2: `enemy_dark_lantern` — hazard estático com aura de puxão (molde `enemy_grav_well`, Stage 04)**

`characters/enemies/stage_06/enemy_dark_lantern.gd`:
```gdscript
extends EnemyBase
class_name EnemyDarkLantern

# Lanterna sombria fixa: enquanto viva, PUXA o player que entrar na aura
# (apply_stage_wind radial em direção à lanterna). Matar a lanterna desliga.
const FRAMES := 4
const FPS := 6.0
const AURA_RADIUS := 220.0
const PULL := 200.0

var _aura: Area2D = null
var _pulled: Array[Node] = []

func _init() -> void:
	max_hp = 14
	contact_damage = 10

func _ready() -> void:
	max_hp = 14
	contact_damage = 10
	super._ready()
	_aura = Area2D.new()
	_aura.collision_layer = 0
	_aura.collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = AURA_RADIUS
	cs.shape = sh
	_aura.add_child(cs)
	add_child(_aura)
	_aura.body_entered.connect(func(b: Node) -> void:
		if not _pulled.has(b):
			_pulled.append(b))
	_aura.body_exited.connect(func(b: Node) -> void:
		_pulled.erase(b))

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	move_and_slide()
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	if DebugBoot.bot_enabled:
		return
	for b in _pulled:
		if is_instance_valid(b) and b.has_method("apply_stage_wind"):
			var dir: Vector2 = global_position - (b as Node2D).global_position
			if dir.length() > 12.0:
				b.apply_stage_wind(dir.normalized() * PULL * delta)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
```

`characters/enemies/stage_06/enemy_dark_lantern.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_06/enemy_dark_lantern.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_06/enemy_dark_lantern.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(56.0, 88.0)

[node name="EnemyDarkLantern" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
vframes = 2
frame = 0
scale = Vector2(0.82, 0.82)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: `enemy_eclipse_turret` — canhão fixo (molde `enemy_gale_turret`, Stage 05)**

`characters/enemies/stage_06/enemy_eclipse_turret.gd`:
```gdscript
extends EnemyBase
class_name EnemyEclipseTurret

# Torre de sombra fixa: não vira; atira shadow_bolt quando o player entra na
# janela do lado configurado (face_dir).
const _PROJ := preload("res://characters/enemies/stage_06/shadow_projectile.tscn")
const FRAMES := 4
const FPS := 8.0
const SHOOT_RANGE := 520.0
const AIM_Y := 110.0
const SHOOT_INTERVAL := 1.4
const BOLT_SPEED := 320.0
const BOLT_DAMAGE := 7

@export var face_dir: float = -1.0

var _shoot_timer := 0.4

func _init() -> void:
	max_hp = 15
	contact_damage = 8

func _ready() -> void:
	max_hp = 15
	contact_damage = 8
	super._ready()
	_direction = face_dir
	_sprite.flip_h = _direction < 0.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	move_and_slide()
	_shoot_timer -= delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null and _shoot_timer <= 0.0:
		var off: Vector2 = p.global_position - global_position
		if absf(off.y) <= AIM_Y and absf(off.x) <= SHOOT_RANGE and signf(off.x) == _direction:
			_shoot_timer = SHOOT_INTERVAL
			_fire()
	_sprite.modulate.a = 0.35 if (_invincible and int(Time.get_ticks_msec() / 80) % 2 == 0) else 1.0
	_advance_sprite_frame_loop(delta, FRAMES, FPS)

func _fire() -> void:
	var proj := _PROJ.instantiate() as ShadowProjectile
	proj.setup(Vector2(_direction * BOLT_SPEED, 0.0), BOLT_DAMAGE, "eclipse_turret", 0.0, "shadow_bolt")
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(_direction * 36.0, -6.0)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
```

`characters/enemies/stage_06/enemy_eclipse_turret.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_06/enemy_eclipse_turret.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_06/enemy_eclipse_turret.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(60.0, 56.0)

[node name="EnemyEclipseTurret" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("Cap_1")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 2
vframes = 2
frame = 0
scale = Vector2(0.75, 0.75)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 4: Parse-check headless dos 3 scripts**

Run: carregar cada `.tscn` numa cena temporária headless. Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_06/enemy_phase_mine.* characters/enemies/stage_06/enemy_dark_lantern.* characters/enemies/stage_06/enemy_eclipse_turret.*
git commit -m "feat(stage06): inimigos estáticos (phase_mine, dark_lantern, eclipse_turret)"
```

---

### Task 7: Scaffold `stage_06_scene.gd` + Zona 1 (fasing simples)

**Files:**
- Create: `stages/stage_06/stage_06_scene.gd`
- Modify: `stages/stage_06/stage_06.tscn` (trocar script base, remover nós antigos)

**Interfaces:**
- Consumes: `phase_platform.gd` (Task 2), `shadow_portal.gd` (Task 3), os 9 `.tscn` de inimigo (Tasks 4-6).
- Produces: `Stage06` script base com `_zone_tile_path`, `_floor_seg`, `_solid_block`, `_glass_wall`, `_fixed_plat`, `_phase_plat`, `_shadow_portal_pair`, `_setup_corridors`/`_make_corridor`, `_setup_zone_triggers`/`_make_zone_trigger`, `_spawn_zone_enemies` — consumidos pelas Tasks 8-10.

- [ ] **Step 1: Ler o `.tscn` atual e reescrever**

Ler `stages/stage_06/stage_06.tscn` primeiro (`Read` tool) pra saber o nome exato do nó `Umbraex` (`uid://umbraex`) e confirmar a lista atual de ext_resources antes de editar — não assumir os mesmos nomes/uid usados no stage_05.tscn.

Substituir o conteúdo de `stages/stage_06/stage_06.tscn` seguindo exatamente o padrão de `stages/stage_05/stage_05.tscn` (já mergeado, ler como referência): trocar o `script` do nó raiz pra `res://stages/stage_06/stage_06_scene.gd`, manter `StageController`/`Camera2D`/`HUD`/`PauseMenu`/`GameOver`/`StageComplete`, adicionar um nó `Umbraex` (`instance=ExtResource("uid://umbraex")` — usar o uid real lido no passo anterior) com `visible = false`, remover qualquer plataforma/checkpoint/collectível hardcoded que já exista na cena atual.

- [ ] **Step 2: Criar o scaffold do script**

`stages/stage_06/stage_06_scene.gd`:
```gdscript
# stages/stage_06/stage_06_scene.gd — Umbraex (sombra)
# Rebuild completo no molde dos stages 02-05: estende a base stage_scene.gd,
# zonas construídas em código, 2 corredores com checkpoint e arena de boss.
# Identidade de sombra:
#   Z1 fasing simples     — plataformas alternando sólido/vazio, ciclo único
#   Z2 fasing dessincronizado + emboscada — múltiplas plataformas fora de fase
#   Z3 portais de sombra  — pares de portal cruzando abismos impossíveis de pular
#   Z4 corredor final     — canhões de sombra até a sala do Umbraex
extends "res://stages/stage_scene.gd"

const _PHASE := preload("res://stages/stage_06/phase_platform.gd")
const _PORTAL := preload("res://stages/stage_06/shadow_portal.gd")
const _UMBRA := {
	"stalker":  preload("res://characters/enemies/stage_06/enemy_shadow_stalker.tscn"),
	"duelist":  preload("res://characters/enemies/stage_06/enemy_eclipse_duelist.tscn"),
	"pouncer":  preload("res://characters/enemies/stage_06/enemy_night_pouncer.tscn"),
	"bat":      preload("res://characters/enemies/stage_06/enemy_umbra_bat.tscn"),
	"orbiter":  preload("res://characters/enemies/stage_06/enemy_void_orbiter.tscn"),
	"snare":    preload("res://characters/enemies/stage_06/enemy_shadow_snare.tscn"),
	"mine":     preload("res://characters/enemies/stage_06/enemy_phase_mine.tscn"),
	"lantern":  preload("res://characters/enemies/stage_06/enemy_dark_lantern.tscn"),
	"turret":   preload("res://characters/enemies/stage_06/enemy_eclipse_turret.tscn"),
}

const FLOOR_Y := 800.0
const _CORR_INTERIOR := 192.0

const _CP1_ENTRY_X := 3136.0
const _CP1_EXIT_X := 4032.0
const _CP2_ENTRY_X := 10432.0
const _CP2_EXIT_X := 11328.0
const _BOSS_L := 12672.0
const _BOSS_R := 14080.0

# Roster de sombra por zona: kind (chave de _UMBRA) → posições.
const Z1_ENEMIES := {
	"stalker": [Vector2(700.0, 760.0), Vector2(2100.0, 760.0)],
	"pouncer": [Vector2(1400.0, 760.0)],
	"duelist": [Vector2(2700.0, 760.0)],
}
const Z2_ENEMIES := {
	"bat":     [Vector2(4700.0, 500.0), Vector2(6200.0, 450.0)],
	"orbiter": [Vector2(5400.0, 600.0)],
	"lantern": [Vector2(6800.0, 760.0)],
}
const Z3_ENEMIES := {
	"snare": [Vector2(8600.0, 700.0)],
	"mine":  [Vector2(9400.0, 750.0), Vector2(10000.0, 750.0)],
}
const Z4_ENEMIES := {
	"turret": [Vector2(11600.0, 736.0), Vector2(12300.0, 736.0)],
}

var _door_tex: Texture2D = null
var _glass_tex: Texture2D = null
var _camera_locked := false
var _camera_target := Vector2.ZERO
var _camera_zoom_tgt := 2.0
var _zone1_enemies: Array[Node] = []
var _zone2_enemies: Array[Node] = []
var _zone3_enemies: Array[Node] = []
var _zone4_enemies: Array[Node] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if StageManager.current_stage_id < 0:
		StageManager.current_stage_id = 6
	super._ready()
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_glass_tex = load("res://stages/stage_06/stage_06_glass.png") as Texture2D
	_setup_corridors()
	_build_zone1()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _zone_tile_path(zone: String) -> String:
	var z := zone.to_lower()
	if z == "boss":
		z = "z4"
	return "res://stages/stage_06/Stage_06T_%s.png" % z

func _process(delta: float) -> void:
	var cam := $Camera2D as Camera2D
	if _camera_locked:
		cam.global_position = cam.global_position.lerp(_camera_target, 0.12)
		cam.zoom = cam.zoom.lerp(Vector2(_camera_zoom_tgt, _camera_zoom_tgt), 0.12)
		queue_redraw()
		return
	if not DebugBoot.bot_enabled:
		cam.zoom = cam.zoom.lerp(Vector2(2.0, 2.0), 0.12)
	super._process(delta)

# ── Corredores (checkpoints) ─────────────────────────────────────────────────

func _setup_corridors() -> void:
	_make_corridor("CP1", _CP1_ENTRY_X, _CP1_EXIT_X, "z1", FLOOR_Y, 1)
	_make_corridor("CP2", _CP2_ENTRY_X, _CP2_EXIT_X, "z3", FLOOR_Y, 2)

func _make_corridor(name_prefix: String, entry_x: float, exit_x: float, zone: String, floor_y: float, checkpoint_index: int) -> CorridorSection:
	var width := exit_x - entry_x
	var corr := CorridorSection.new()
	corr.name = name_prefix
	corr.tileset = _cached_override_tex(_zone_tile_path(zone))
	corr.glass_tex = _glass_tex
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
	corr.glass_lateral_x = entry_x - 64.0
	corr.glass_fill_x = entry_x
	corr.glass_fill_cols = int(width / 64.0)
	corr.camera_lock_requested.connect(_on_corridor_cam_lock)
	corr.player_traversed.connect(_on_corridor_traversed)
	add_child(corr)
	corr.setup(_player)
	return corr

func _on_corridor_cam_lock(center: Vector2, zoom: float) -> void:
	_camera_locked = true
	_camera_target = center
	_camera_zoom_tgt = zoom

func _on_corridor_traversed() -> void:
	_camera_locked = false

# ── Spawn de inimigos por zona ───────────────────────────────────────────────

func _setup_zone_triggers() -> void:
	_make_zone_trigger("Z2Trigger", Rect2(_CP1_EXIT_X, 300.0, 5600.0, 900.0), 2)
	_make_zone_trigger("Z3Trigger", Rect2(8000.0, 300.0, 3200.0, 900.0), 3)
	_make_zone_trigger("Z4Trigger", Rect2(_CP2_EXIT_X, 300.0, 2200.0, 900.0), 4)

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
		var scene: PackedScene = _UMBRA[kind]
		for pos in table[kind]:
			var e := scene.instantiate()
			(e as Node2D).global_position = pos
			add_child(e)
			target.append(e)

# ── Helpers de terreno (mesmo vocabulário dos stages 02-05) ──────────────────

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

func _glass_wall(x_center: float, top_y: float, height: float) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = "Z_Glass_%d" % int(x_center)
	b.collision_layer = 1
	b.collision_mask = 0
	b.add_to_group("no_wall_grab")
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64.0, height)
	cs.shape = shape
	cs.position = Vector2(x_center, top_y + height * 0.5)
	b.add_child(cs)
	b.set_meta("tileset_override", "res://stages/stage_06/stage_06_glass.png")
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

func _phase_plat(n: String, zone: String, cx: float, top_y: float, solid_t: float, phase_t: float, offset: float = 0.0, w: float = 128.0) -> void:
	var p: StaticBody2D = _PHASE.new()
	p.name = n
	p.set("solid_time", solid_t)
	p.set("phase_time", phase_t)
	p.set("phase_offset", offset)
	p.collision_layer = 1
	p.collision_mask = 0
	p.position = Vector2(cx, top_y + 16.0)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, 32.0)
	cs.shape = sh
	p.add_child(cs)
	p.set_meta("platform_override", _zone_tile_path(zone))
	add_child(p)

func _shadow_portal_pair(name_a: String, pos_a: Vector2, name_b: String, pos_b: Vector2, size: Vector2 = Vector2(64.0, 96.0)) -> void:
	var a: Area2D = _PORTAL.new()
	a.name = name_a
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = pos_a
	var cs_a := CollisionShape2D.new()
	var sh_a := RectangleShape2D.new()
	sh_a.size = size
	cs_a.shape = sh_a
	a.add_child(cs_a)
	add_child(a)

	var b: Area2D = _PORTAL.new()
	b.name = name_b
	b.collision_layer = 0
	b.collision_mask = 2
	b.position = pos_b
	var cs_b := CollisionShape2D.new()
	var sh_b := RectangleShape2D.new()
	sh_b.size = size
	cs_b.shape = sh_b
	b.add_child(cs_b)
	add_child(b)

	a.call("link_partner", b)
	b.call("link_partner", a)

# ── Zona 1 — Entrada / fasing simples ─────────────────────────────────────────

func _build_zone1() -> void:
	_floor_seg("z1", 0.0, 1400.0, FLOOR_Y)
	_phase_plat("Z1_Phase1", "z1", 1600.0, FLOOR_Y - 16.0, 2.0, 1.0)
	_phase_plat("Z1_Phase2", "z1", 1900.0, FLOOR_Y - 16.0, 2.0, 1.0)
	_floor_seg("z1", 2100.0, _CP1_ENTRY_X, FLOOR_Y)
```

- [ ] **Step 2: Parse-check headless (`.gd` isolado — `_build_zone2/3/4` ainda não existem, chamadas nas próximas tasks)**

Run: `--check-only --script` (aceitar o falso-positivo de autoload documentado) ou carregar `stage_06.tscn` inteira com timeout.
Expected: sem `SCRIPT ERROR`/`Parse Error` de sintaxe real.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_06/stage_06.tscn stages/stage_06/stage_06_scene.gd
git commit -m "feat(stage06): scaffold do script + zona 1 (fasing simples)"
```

---

### Task 8: Zona 2 — Fasing dessincronizado + emboscada

**Files:**
- Modify: `stages/stage_06/stage_06_scene.gd` (adicionar `_build_zone2()` + chamada em `_ready()`)

**Interfaces:**
- Consumes: `_phase_plat`, `_floor_seg`, `_fixed_plat` (Task 7).
- Produces: `_build_zone2()`, consumido pela Task 11.

- [ ] **Step 1: Adicionar `_build_zone2()`**

Em `_ready()`:
```gdscript
	_build_zone1()
	_build_zone2()
	_setup_zone_triggers()
```

Função nova. **Antes de finalizar, recalcular manualmente**: cada `_phase_plat` tem centro `cx` e largura `w=128` (padrão) — a distância de borda-a-borda entre plataformas/piso adjacentes deve ficar ≤196px (alcance de pulo, `reference_jump_height`), IGNORANDO se a plataforma está fasada ou não no pior caso (o jogador precisa conseguir pular pra cima dela mesmo se ela materializar um instante depois — ou o desenho da zona precisa garantir que o jogador só avança quando a próxima já está sólida, o que é o ponto do "ler o padrão" nesta zona: períodos de fase mais longos, offset dessincronizado, mas gaps sempre dentro do alcance):
```gdscript
# ── Zona 2 — Fasing dessincronizado + emboscada ──────────────────────────────
# 4 plataformas fora de sincronia (offsets diferentes) sobre um vão — o
# jogador precisa ler o padrão, não só decorar 1 timing. Períodos mais longos
# que a Z1 (mais tempo sólida, mais tempo vazia) pra dar tempo de observar.

func _build_zone2() -> void:
	_floor_seg("z2", _CP1_EXIT_X, 4500.0, FLOOR_Y)
	_phase_plat("Z2_Phase1", "z2", 4700.0, FLOOR_Y - 16.0, 2.4, 1.6, 0.0)
	_phase_plat("Z2_Phase2", "z2", 4980.0, FLOOR_Y - 16.0, 2.4, 1.6, 1.2)
	_phase_plat("Z2_Phase3", "z2", 5260.0, FLOOR_Y - 16.0, 2.4, 1.6, 2.4)
	_phase_plat("Z2_Phase4", "z2", 5540.0, FLOOR_Y - 16.0, 2.4, 1.6, 0.8)
	_floor_seg("z2", 5720.0, 7000.0, FLOOR_Y)
	# Armadura de Zara (Braços) num desvio elevado guardado pelo dark_lantern
	# (já posicionado em Z2_ENEMIES, x=6800).
	_fixed_plat("Z2_ArmorLedge", "z2", 6800.0, FLOOR_Y - 180.0, 160.0)
	var armor := preload("res://stages/collectible.tscn").instantiate()
	armor.set("collectible_type", "armor_zara_arms")
	armor.global_position = Vector2(6800.0, FLOOR_Y - 220.0)
	add_child(armor)
	_floor_seg("z2", 7000.0, _CP2_ENTRY_X, FLOOR_Y)
```

Recalcular gaps efetivamente usados (edge-a-edge, plataforma 128px de largura):
- Piso(≤4500) → Phase1(4700, span [4636,4764]): gap = 4636-4500 = 136px ✓
- Phase1→Phase2 (span [4916,5044]): gap = 4916-4764 = 152px ✓
- Phase2→Phase3 (span [5196,5324]): gap = 5196-5044 = 152px ✓
- Phase3→Phase4 (span [5476,5604]): gap = 5476-5324 = 152px ✓
- Phase4→Piso(5720): gap = 5720-5604 = 116px ✓

Todos ≤196px — confirmar essa aritmética contra os valores REAIS que ficaram no arquivo (se o passo anterior usou coordenadas diferentes das mostradas aqui, refazer a conta) antes de commitar.

- [ ] **Step 2: Parse-check headless**

Run: mesmo processo da Task 7 Step 2.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_06/stage_06_scene.gd
git commit -m "feat(stage06): zona 2 (fasing dessincronizado + armadura)"
```

---

### Task 9: Zona 3 — Portais de sombra

**Files:**
- Modify: `stages/stage_06/stage_06_scene.gd` (adicionar `_build_zone3()` + chamada em `_ready()`)

**Interfaces:**
- Consumes: `_shadow_portal_pair`, `_floor_seg`, `_fixed_plat` (Task 7).
- Produces: `_build_zone3()`, consumido pela Task 11.

- [ ] **Step 1: Adicionar `_build_zone3()`**

Em `_ready()`:
```gdscript
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_setup_zone_triggers()
```

Função nova:
```gdscript
# ── Zona 3 — Portais de sombra ────────────────────────────────────────────────
# 2 pares de portal cruzando abismos de 500px (bem além do alcance de pulo —
# só atravessável via portal). Piso corta de verdade entre os pares (sem
# ponte alternativa), reforçando que o portal é obrigatório.

func _build_zone3() -> void:
	_floor_seg("z3", _CP2_ENTRY_X - 2432.0, 8300.0, FLOOR_Y)   # 8000 até 8300
	_shadow_portal_pair("Z3_PortalA_In", Vector2(8260.0, FLOOR_Y - 48.0),
		"Z3_PortalA_Out", Vector2(8800.0, FLOOR_Y - 48.0))
	_floor_seg("z3", 8760.0, 9200.0, FLOOR_Y)
	_shadow_portal_pair("Z3_PortalB_In", Vector2(9160.0, FLOOR_Y - 48.0),
		"Z3_PortalB_Out", Vector2(9700.0, FLOOR_Y - 48.0))
	_floor_seg("z3", 9660.0, _CP2_ENTRY_X, FLOOR_Y)
	# Extra de Zael (Laser) + coração + sub-tank num desvio entre os portais.
	_fixed_plat("Z3_ExtraLedge", "z3", 8990.0, FLOOR_Y - 160.0, 160.0)
	var laser := preload("res://stages/collectible.tscn").instantiate()
	laser.set("collectible_type", "extra_zael_laser")
	laser.global_position = Vector2(8960.0, FLOOR_Y - 200.0)
	add_child(laser)
	var heart := preload("res://stages/collectible.tscn").instantiate()
	heart.set("collectible_type", "heart")
	heart.global_position = Vector2(9020.0, FLOOR_Y - 200.0)
	add_child(heart)
	var subtank := preload("res://stages/collectible.tscn").instantiate()
	subtank.set("collectible_type", "sub_tank")
	subtank.global_position = Vector2(8990.0, FLOOR_Y - 240.0)
	add_child(subtank)
```

**Antes de finalizar, verificar manualmente**: o piso corta entre `8300` e a posição do portal A de entrada (`8260`) — confirmar que o portal A de entrada (`Z3_PortalA_In`, centro x=8260, largura 64 → span [8228,8292]) fica sobre piso sólido (piso termina em 8300, então 8292<8300 ✓, a área do portal fica inteira sobre chão firme, não sobre o abismo). Mesma checagem pra `Z3_PortalA_Out` (centro 8800, span [8768,8832], contra o próximo segmento de piso que começa em 8760 — confirmar 8768>8760 ✓). Repetir pro par B. Se os números não baterem depois de escrever o código de verdade, ajustar as posições dos portais (não o piso) até eles ficarem sobre chão sólido dos dois lados — um portal cuja área de detecção paira sobre o abismo é inútil (o jogador cai antes de alcançá-la).

- [ ] **Step 2: Parse-check headless**

Run: mesmo processo da Task 7 Step 2.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_06/stage_06_scene.gd
git commit -m "feat(stage06): zona 3 (portais de sombra + colectáveis)"
```

---

### Task 10: Zona 4 + sala do boss

**Files:**
- Modify: `stages/stage_06/stage_06_scene.gd` (adicionar `_build_zone4()`, `_build_boss_arena()` + chamadas em `_ready()`)

**Interfaces:**
- Consumes: `_floor_seg`, `_solid_block` (Task 7), nó `Umbraex` já presente na `.tscn` (Task 7 Step 1).
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

Funções novas (padrão B — porta aberta + trigger, mesmo do stage_01/05):
```gdscript
# ── Zona 4 — Corredor final com canhões de sombra ────────────────────────────

func _build_zone4() -> void:
	_floor_seg("z4", _CP2_EXIT_X, _BOSS_L, FLOOR_Y)

# ── Sala do boss (Umbraex) ────────────────────────────────────────────────────
# Padrão B (porta aberta + trigger, skill new-boss-room): arena aberta,
# aggro por Area2D de entrada — não por distância.

func _build_boss_arena() -> void:
	_floor_seg("boss", _BOSS_L, _BOSS_R, FLOOR_Y)
	_solid_block("boss", "Boss_WallR", _BOSS_R + 32.0, FLOOR_Y - 256.0, 64.0, 512.0)
	_solid_block("boss", "Boss_WallL_Top", _BOSS_L + 32.0, FLOOR_Y - 448.0, 64.0, 256.0)
	var umbraex := get_node_or_null("Umbraex")
	if umbraex:
		umbraex.visible = true
		umbraex.global_position = Vector2((_BOSS_L + _BOSS_R) * 0.5, FLOOR_Y - 64.0)
		umbraex.set("auto_aggro", false)
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
				umbraex.call("aggro"))
		if umbraex.has_signal("boss_defeated"):
			umbraex.connect("boss_defeated", _on_boss_defeated)

func _on_boss_defeated(_ability_id: String) -> void:
	GameManager.save_game()
```

**Nota importante da Task 9 do plano da Stage 05**: NÃO chamar `$HUD.connect_to_boss(umbraex)` aqui — se `Umbraex` já é um nó filho pré-existente na `.tscn` (visível=false, ativado por este método), a base `stage_scene.gd::_ready()` já faz essa conexão genericamente pra qualquer `BossBase` presente na árvore ANTES desta função rodar (chamada depois de `super._ready()`). Confirmar isso lendo `stages/stage_scene.gd::_ready()` antes de escrever esse trecho — se o comportamento genérico não existir mais (arquivo pode ter mudado), então SIM adicionar `$HUD.connect_to_boss(umbraex)` aqui; documentar no relatório da task qual dos dois casos era verdade.

**Boss room 64px check**: `Boss_WallR` altura 512 (8×64) ✓, `Boss_WallL_Top` altura 256 (4×64) ✓, largura da sala `_BOSS_R - _BOSS_L = 1408` (22×64) ✓ — confirmar esses três números batem com os valores reais escritos no arquivo antes de commitar (mesma checagem que a Task 9 da Stage 05 precisou fazer).

- [ ] **Step 2: Parse-check headless**

Run: mesmo processo da Task 7 Step 2.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_06/stage_06_scene.gd
git commit -m "feat(stage06): zona 4 + sala do boss Umbraex"
```

---

### Task 11: Teto por zona + integração final

**Files:**
- Modify: `stages/stage_06/stage_06_scene.gd` (adicionar `_CEIL06_SEGS`, `_build_zone_ceilings06()`, `_ceil06_surface_at()`, `_draw_zone_ceilings06()`, `_draw()`, chamada em `_ready()`)

**Interfaces:**
- Consumes: todas as zonas das Tasks 7-10.
- Produces: fase jogável completa, testada headless + export web.

- [ ] **Step 1: Adicionar sistema de teto (FACE_GAP + fallback cross-zone desde o início)**

Em `_ready()`, como ÚLTIMA chamada de construção (antes de `_setup_zone_triggers`):
```gdscript
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_boss_arena()
	_build_zone_ceilings06()
	_setup_zone_triggers()
```

Como toda a fase fica numa ÚNICA elevação (`FLOOR_Y = 800.0`, sem shaft vertical — ao contrário da Stage 05), o teto pode ser uma faixa reta cobrindo cada zona com uma folga fixa acima do piso, sem degraus. Constantes e funções (mesmo padrão FACE_GAP/fallback cross-zone de stage_01-05):
```gdscript
# ── Teto por zona ─────────────────────────────────────────────────────────────
const _CEIL06_SEGS := {
	"Z1":   [[0.0, _CP1_ENTRY_X, FLOOR_Y - 500.0]],
	"Z2":   [[_CP1_EXIT_X, _CP2_ENTRY_X, FLOOR_Y - 500.0]],
	"Z4":   [[_CP2_EXIT_X, _BOSS_L, FLOOR_Y - 500.0]],
	"Boss": [[_BOSS_L, _BOSS_R, FLOOR_Y - 448.0 - 256.0]],
}
const _CEIL06_TEX := { "Z1": "z1", "Z2": "z2", "Z4": "z4", "Boss": "z4" }
const _CEIL06_TOP := 128.0
const _CEIL06_FACE_GAP := 32.0

func _build_zone_ceilings06() -> void:
	for zk: String in _CEIL06_SEGS:
		var body := StaticBody2D.new()
		body.name = "%sCeilSegs" % zk
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		for s: Array in _CEIL06_SEGS[zk]:
			var cs := CollisionShape2D.new()
			var sh := SegmentShape2D.new()
			sh.a = Vector2(s[0], (s[2] as float) - _CEIL06_FACE_GAP)
			sh.b = Vector2(s[1], (s[2] as float) - _CEIL06_FACE_GAP)
			cs.shape = sh
			body.add_child(cs)

func _ceil06_surface_at(zk: String, wx: float) -> float:
	for s: Array in _CEIL06_SEGS[zk]:
		if wx >= (s[0] as float) and wx < (s[1] as float):
			return s[2]
	for zk2: String in _CEIL06_SEGS:
		if zk2 == zk:
			continue
		for s: Array in _CEIL06_SEGS[zk2]:
			if wx >= (s[0] as float) and wx < (s[1] as float):
				return s[2]
	return -1.0

func _ceil06_solid(zk: String, wx: float, y: float) -> bool:
	var yb := _ceil06_surface_at(zk, wx)
	return yb > 0.0 and y < yb

func _draw() -> void:
	super._draw()
	_draw_zone_ceilings06()

func _draw_zone_ceilings06() -> void:
	var ts := float(_TS)
	var sts := float(_SRC_TS)
	for zk: String in _CEIL06_SEGS:
		var segs: Array = _CEIL06_SEGS[zk]
		var tex := _cached_override_tex(_zone_tile_path(_CEIL06_TEX[zk] as String))
		if tex == null:
			continue
		var x0f: float = segs[0][0]
		var x1f: float = segs[segs.size() - 1][1]
		var x := x0f
		while x < x1f:
			var yb := _ceil06_surface_at(zk, x)
			var y := _CEIL06_TOP
			while y < yb:
				var ed := not _ceil06_solid(zk, x, y + ts)
				var el := not _ceil06_solid(zk, x - ts, y)
				var er := not _ceil06_solid(zk, x + ts, y)
				var tile: Vector2i
				if   ed and el: tile = Vector2i(0, 2)
				elif ed and er: tile = Vector2i(3, 3)
				elif ed:        tile = Vector2i(1, 2)
				elif el:        tile = Vector2i(1, 0)
				elif er:        tile = Vector2i(3, 2)
				elif not _ceil06_solid(zk, x - ts, y + ts): tile = Vector2i(2, 2)
				elif not _ceil06_solid(zk, x + ts, y + ts): tile = Vector2i(3, 1)
				else:           tile = Vector2i(2, 1)
				draw_texture_rect_region(tex, Rect2(x, y, ts, ts),
					Rect2(float(tile.x) * sts, float(tile.y) * sts, sts, sts))
				y += ts
			x += ts
```

**Nota importante da Task 10 do plano da Stage 05**: o destino do `draw_texture_rect_region` é `Rect2(x, y, ts, ts)` — SEM subtrair `sts`/nenhum offset. Um offset `y - sts` aqui foi um bug real encontrado e corrigido na Stage 05 (visual do teto saía 32px alto demais); não introduzir de novo. `_CEIL06_SEGS` propositalmente NÃO tem entrada "Z3" — a Zona 3 (portais) já fica coberta pelas entradas Z2 (que vai até `_CP2_ENTRY_X`) e Z4/Boss por causa do fallback cross-zone, MAS confirmar isso é realmente verdade lendo os ranges reais no arquivo: se `_CP1_EXIT_X` até `_CP2_ENTRY_X` (a entrada "Z2") não cobre fisicamente toda a extensão de Z3 (`8000` a `10432` nas coordenadas do desenho acima), adicionar uma entrada "Z3" própria em vez de confiar só no fallback — o fallback existe pra fronteiras entre zonas vizinhas, não pra substituir cobertura de zona inteira.

- [ ] **Step 2: Parse-check headless do script**

Run: mesmo processo da Task 7 Step 2.

- [ ] **Step 3: Parse-check headless da cena completa**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://stages/stage_06/stage_06.tscn` com timeout de 30s, grep por `script error|parse error` (case-insensitive) no log.
Expected: nenhuma ocorrência.

- [ ] **Step 4: Rodar os testes automatizados existentes**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```
Expected: `test_game_manager` e `test_stage_manager` sem `SCRIPT ERROR`. `test_character_base` pode reportar 3 asserções pré-existentes já confirmadas como não-relacionadas a esse trabalho (`current_hp equals max_hp on ready`, `hp is 70 after 30 damage`, `second hit blocked during invincibility` — mesmas 3 falhas verificadas idênticas na master antes do rework da Stage 05, ver `.superpowers/sdd/progress.md` do plano irmão se ainda existir, ou reconfirmar com `git diff --stat <branch-base>..HEAD -- characters/base/character_base.gd autoloads/game_manager.gd` mostrando vazio).

- [ ] **Step 5: Traçar a travessia ponta a ponta uma última vez**

Reler o arquivo final e confirmar, com os números REAIS (não os deste documento): Z1 fasing → corredor CP1 → Z2 fasing dessincronizado → armadura → Z3 portal A → piso → portal B → corredor CP2 → Z4 corredor → sala do boss. Nenhum segmento de piso deveria terminar sem o próximo elemento (plataforma, portal ou piso) começando dentro do alcance de pulo (ou, no caso dos portais, sem a área de detecção do portal estar sobre chão sólido em ambos os lados). Esse é o mesmo tipo de checagem que a revisão final de branch inteiro da Stage 05 fez e que pegou um soft-lock que as revisões por-task não viram — fazer essa passada aqui, antes do export, é mais barato que descobrir depois.

- [ ] **Step 6: Export web**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --export-release "Web" "export/web/index.html"
```
Expected: `EXIT 0`, `export/web/index.pck` com timestamp atualizado.

- [ ] **Step 7: Commit final**

```bash
git add stages/stage_06/stage_06_scene.gd export/web/index.pck export/web/index.html
git commit -m "feat(stage06): teto por zona + integração final"
```

---

## Self-Review

**1. Cobertura do spec:** Z1 fasing simples (Task 7) ✓, Z2 fasing dessincronizado+armadura (Task 8) ✓, Z3 portais+extra+coração+subtank (Task 9) ✓, Z4+boss (Task 10) ✓, roster de 9 (Tasks 4-6) ✓, 2 checkpoints (Task 7) ✓, teto com FACE_GAP/fallback desde o início (Task 11) ✓, `phase_platform` sólida sob bot / `shadow_portal` ativo sob bot (Tasks 2-3) ✓, kill plane herdado da base — não precisa de código novo, só a validação da Task 11 Step 5.

**2. Placeholders:** nenhum "TBD"/"implementar depois". Toda task com aritmética de gap explicitada e instrução de reconferir contra o código de verdade — isso NÃO é um placeholder, é o mesmo processo de verificação obrigatório que a Stage 05 precisou (e que pegou bugs reais) documentado explicitamente pra cada task, em vez de assumir que os números de exemplo já saem certos de primeira.

**3. Consistência de tipos:** `ShadowProjectile.setup()` (Task 1) usado identicamente pelas Tasks 5 (`void_orbiter`) e 6 (`eclipse_turret`) com a mesma assinatura de `WindProjectile` (Stage 05). `_UMBRA` (Task 7) referencia exatamente os nomes de arquivo `.tscn` criados nas Tasks 4-6. `_phase_plat`/`PhasePlatform` (Task 2) com `solid_time`/`phase_time`/`phase_offset` batendo entre definição e uso nas Tasks 7-8. `_shadow_portal_pair`/`ShadowPortal.link_partner` (Task 3) batendo entre definição e uso na Task 9.

---

**Plan complete and saved to `docs/superpowers/plans/2026-07-17-stage06-umbraex-redesign.md`.**

Seguindo direto pra execução via subagent-driven-development, conforme pedido — sem pausa pra escolha de abordagem.
