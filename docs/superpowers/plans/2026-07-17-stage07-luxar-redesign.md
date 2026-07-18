# Stage 07 Luxar Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework Stage 07 (Luxar, tema luz) do esqueleto atual pra uma fase completa com 4 zonas temáticas, roster de 9 inimigos com IA funcional, 3 mecânicas novas (feixe de luz multi-segmento, interruptor de toggle permanente, zona de visão limitada) com dificuldade crescente, e sala do boss.

**Architecture:** `stages/stage_07/stage_07_scene.gd extends "res://stages/stage_scene.gd"` (mesmo padrão de stage_05/06), zonas construídas em código via o vocabulário de helpers já validado. Três componentes novos: `light_beam.gd` (hazard de feixe contínuo definido por lista de pontos — um feixe reto tem 2 pontos, um "espelhado" tem 3+, mesmo código cobre os dois), `light_switch.gd` (interruptor de toggle PERMANENTE, sem timer, que chama `set_active()` num `light_beam` OU alterna a colisão de um portão StaticBody2D diretamente) e `vision_limit_zone.gd` (escurecimento de tela via `CanvasModulate` + `PointLight2D` seguindo o jogador). 9 scripts de IA em `characters/enemies/stage_07/`, cada um clonando o template mais próximo já em produção nas stages 01-06.

**Tech Stack:** Godot 4.6.2 GDScript, headless parse-check, sprites/tileset já existentes (nenhum asset novo).

## Global Constraints

- Nomes de arquivo/script em snake_case; `class_name` em PascalCase.
- `CorridorSection` sempre 896×64 / zoom 2.0 — nunca variar a largura do corredor.
- Nenhuma cura em checkpoints/corredores (`heal_on_entry = false`).
- Teto por zona usa `_CEIL_FACE_GAP` (colisão 32px acima do nominal, visual intocado) e fallback cross-zone desde a primeira versão. O `draw_texture_rect_region` do desenho visual do teto usa `Rect2(x, y, ts, ts)` — **sem** subtrair `sts` (bug já cometido e corrigido na Stage 05, não repetir).
- `sign()`/`clamp()`/`abs()` sempre tipados explicitamente com `: float` no build web.
- **Colectáveis sempre via `Collectible.Type.XXX` (enum), nunca `.set("collectible_type", "string")`** — esse padrão falha silenciosamente e vira `Type.HEART` (bug real já corrigido nas Stages 05/06, ver memória `reference_collectible_type_enum`). Usar o campo companheiro certo por tipo: `armor_piece`/`ability_id`/`subtank_index`/`stage_id`.
- **`_build_boss_arena()` DEVE setar `arena_left`/`arena_right`/`arena_floor` no boss**, além de posição e `auto_aggro` — omitir isso deixa o boss nos defaults de `boss_base.gd` (arena_right=1820), o que pode quebrar completamente a luta pra bosses com lógica dependente da arena (bug crítico encontrado na revisão final da Stage 06, ver memória `project_stage06_rework`).
- `light_beam`/`light_switch`/`vision_limit_zone` ficam neutros/sem-efeito quando `DebugBoot.bot_enabled`: feixe sem dano (monitoring off), zona de visão sem escurecer a tela.
- Toda coordenada de piso/parede/sala da sala do boss deve ser múltiplo de 64px (skill `new-boss-room`).
- Após cada task: parse-check headless (scene-load real, não `--check-only --script`, que dá falso-positivo em qualquer script tocando autoload) antes de seguir pra próxima.
- **Verificação de geometria é responsabilidade de CADA task**: antes de finalizar qualquer zona, recalcular manualmente as coordenadas X/Y de piso/plataforma/feixe/interruptor a partir do código de verdade e confirmar que a travessia é fisicamente possível (gaps de piso ≤196px de alcance horizontal / ≤118px de altura). As revisões das Stages 05/06 acharam e corrigiram bugs reais de geometria/wiring assim repetidamente — replicar o mesmo rigor aqui, inclusive na revisão final de branch inteiro ao final deste plano.

---

### Task 1: Projétil compartilhado light_projectile

**Files:**
- Create: `characters/enemies/stage_07/light_projectile.gd`
- Create: `characters/enemies/stage_07/light_projectile.tscn`

**Interfaces:**
- Produces: `LightProjectile.setup(velocity_value: Vector2, damage_value: int, source_value := "stage07_light", gravity_value := 0.0, variant_value := "light_bolt") -> void` — usado pelas Tasks 6-7.

- [ ] **Step 1: Criar o script do projétil**

`characters/enemies/stage_07/light_projectile.gd`:
```gdscript
extends Area2D
class_name LightProjectile

# Projétil de luz compartilhado do roster do stage 07 (molde do shadow_projectile).
const TEX := {
	"light_bolt": preload("res://characters/enemies/stage_07/light_bolt.png"),
	"prism_shard": preload("res://characters/enemies/stage_07/prism_shard.png"),
}

var projectile_velocity: Vector2 = Vector2(300.0, 0.0)
var damage: int = 6
var source_id: String = "stage07_light"
var variant: String = "light_bolt"
var _lifetime: float = 4.0
var _hit := false
var _anim_timer := 0.0
var _frame := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_enemy_shoot)

func setup(velocity_value: Vector2, damage_value: int, source_value := "stage07_light",
		gravity_value := 0.0, variant_value := "light_bolt") -> void:
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

`characters/enemies/stage_07/light_projectile.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_07/light_projectile.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_07/light_bolt.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="Circ_1"]
radius = 10.0

[node name="LightProjectile" type="Area2D"]
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

Instanciar `light_projectile.tscn` numa cena temporária carregada via headless real (não `--check-only --script`). Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 4: Commit**

```bash
git add characters/enemies/stage_07/light_projectile.gd characters/enemies/stage_07/light_projectile.tscn
git commit -m "feat(stage07): projétil de luz compartilhado do roster"
```

---

### Task 2: Componente `light_beam.gd`

**Files:**
- Create: `stages/stage_07/light_beam.gd`

**Interfaces:**
- Produces: `LightBeam` (`Node2D`), `@export var points: Array[Vector2]`, `@export var active: bool`, `@export var damage: int`, método `set_active(value: bool) -> void` — instanciado pelas Tasks 9-10 (Zonas 1/2), controlado pela Task 3 (`light_switch.gd`).

- [ ] **Step 1: Criar o componente**

`stages/stage_07/light_beam.gd`:
```gdscript
# Feixe de luz contínuo definido por uma lista de pontos (polilinha, em
# coordenadas LOCAIS ao nó — o primeiro ponto normalmente é (0,0) e os
# demais relativos a ele). Um feixe reto tem 2 pontos; um feixe "espelhado"
# tem 3+ (dobra num ponto de espelho fixo definido em tempo de design) — o
# mesmo código cobre os dois casos, cada segmento consecutivo vira uma
# Area2D retangular rotacionada. Dano por contato com cooldown por corpo
# (evita dano repetido a cada frame). set_active(false) desliga o feixe
# permanentemente (chamado por light_switch.gd) — sem timer, ao contrário
# de stages/stage_06/phase_platform.gd.
extends Node2D
class_name LightBeam

@export var points: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(400.0, 0.0)]
@export var active: bool = true
@export var damage: int = 10
@export var beam_width: float = 12.0
@export var beam_color: Color = Color(1.0, 0.95, 0.6, 0.85)

const HIT_COOLDOWN := 0.4

var _segments: Array[Area2D] = []
var _cooldowns: Dictionary = {}

func _ready() -> void:
	_build_segments()
	_apply_active()
	queue_redraw()

func _build_segments() -> void:
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var seg_len := a.distance_to(b)
		if seg_len <= 0.0:
			continue
		var mid := (a + b) * 0.5
		var angle := (b - a).angle()
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		area.position = mid
		area.rotation = angle
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(seg_len, beam_width)
		cs.shape = sh
		area.add_child(cs)
		add_child(area)
		area.body_entered.connect(_on_body_entered)
		_segments.append(area)

func set_active(value: bool) -> void:
	active = value
	_apply_active()
	queue_redraw()

func _apply_active() -> void:
	var on: bool = active and not DebugBoot.bot_enabled
	for seg in _segments:
		seg.monitoring = on
		seg.monitorable = on

func _on_body_entered(body: Node) -> void:
	if not active or DebugBoot.bot_enabled:
		return
	if _cooldowns.has(body):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, "light_beam")
	_cooldowns[body] = HIT_COOLDOWN

func _physics_process(delta: float) -> void:
	if _cooldowns.is_empty():
		return
	for b in _cooldowns.keys().duplicate():
		_cooldowns[b] -= delta
		if _cooldowns[b] <= 0.0:
			_cooldowns.erase(b)

func _draw() -> void:
	if not active:
		return
	for i in points.size() - 1:
		draw_line(points[i], points[i + 1], beam_color, beam_width * 0.5)
```

- [ ] **Step 2: Parse-check headless**

Instanciar em cena temporária com `points = [Vector2(0,0), Vector2(300,0), Vector2(300,-200)]` (feixe de 2 segmentos, simula o caso "espelhado"), confirmar sem `SCRIPT ERROR`/`Parse Error` e que 2 `Area2D` filhas foram criadas.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_07/light_beam.gd
git commit -m "feat(stage07): componente de feixe de luz multi-segmento"
```

---

### Task 3: Componente `light_switch.gd`

**Files:**
- Create: `stages/stage_07/light_switch.gd`

**Interfaces:**
- Consumes: `LightBeam.set_active(value: bool)` (Task 2).
- Produces: `LightSwitch` (`Area2D`), `@export var target_path: NodePath`, `@export var target_active_value: bool` — instanciado pelas Tasks 9-10 (Zonas 2/3).

- [ ] **Step 1: Criar o componente**

`stages/stage_07/light_switch.gd`:
```gdscript
# Interruptor de toggle PERMANENTE (sem timer, ao contrário de
# phase_platform.gd) — ao ser tocado pelo player uma vez, aplica
# target_active_value no nó apontado por target_path e nunca mais reage.
# Funciona com dois tipos de alvo:
#   - um nó com método set_active(bool) (ex: light_beam.gd) — chama direto.
#   - um StaticBody2D "portão" sem set_active — alterna a CollisionShape2D
#     filha (disabled) e a meta skip_base_draw diretamente, mesma técnica
#     de stages/stage_01/crumbling_ledge.gd.
extends Area2D
class_name LightSwitch

@export var target_path: NodePath
@export var target_active_value: bool = true

var _triggered: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered or DebugBoot.bot_enabled:
		return
	if not body.is_in_group("player"):
		return
	_triggered = true
	_apply()

func _apply() -> void:
	var target := get_node_or_null(target_path)
	if target == null:
		return
	if target.has_method("set_active"):
		target.call("set_active", target_active_value)
		return
	var cs: CollisionShape2D = null
	for c in target.get_children():
		if c is CollisionShape2D:
			cs = c
			break
	if cs:
		cs.set_deferred("disabled", not target_active_value)
	if target_active_value:
		if target.has_meta("skip_base_draw"):
			target.remove_meta("skip_base_draw")
	else:
		target.set_meta("skip_base_draw", true)
```

- [ ] **Step 2: Parse-check headless**

Instanciar em cena temporária junto de um `StaticBody2D` alvo (com `CollisionShape2D` filha, `disabled=true` inicial) e um corpo com grupo `"player"` — simular `body_entered` chamando `_on_body_entered` diretamente e confirmar que `cs.disabled` vira `false`. Confirmar sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_07/light_switch.gd
git commit -m "feat(stage07): componente de interruptor de toggle permanente"
```

---

### Task 4: Componente `vision_limit_zone.gd`

**Files:**
- Create: `stages/stage_07/vision_limit_zone.gd`

**Interfaces:**
- Produces: `VisionLimitZone` (`Area2D`), `@export var dark_color: Color`, `@export var light_radius: float` — instanciado pela Task 10 (Zona 3).

- [ ] **Step 1: Criar o componente**

`stages/stage_07/vision_limit_zone.gd`:
```gdscript
# Zona de visão limitada: ao entrar, escurece a tela inteira via
# CanvasModulate e acende uma PointLight2D (textura de gradiente radial)
# grudada no player, revelando só uma área ao redor dele. Ao sair, desfaz.
# Sistema visual novo — deliberadamente simples (sem motor de iluminação
# por tile), só CanvasModulate + 1 luz pontual seguindo o player.
extends Area2D
class_name VisionLimitZone

@export var dark_color: Color = Color(0.03, 0.03, 0.08, 0.92)
@export var light_radius: float = 220.0
@export var light_energy: float = 1.4

var _canvas_mod: CanvasModulate = null
var _point_light: PointLight2D = null
var _player: Node2D = null
var _active := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if DebugBoot.bot_enabled:
		return
	if not body.is_in_group("player"):
		return
	_player = body as Node2D
	_activate()

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_deactivate()
		_player = null

func _activate() -> void:
	if _active:
		return
	_active = true
	_canvas_mod = CanvasModulate.new()
	_canvas_mod.color = dark_color
	get_tree().current_scene.add_child(_canvas_mod)
	_point_light = PointLight2D.new()
	_point_light.energy = light_energy
	_point_light.texture = _radial_gradient_texture()
	_point_light.texture_scale = light_radius / 256.0
	if _player:
		_player.add_child(_point_light)

func _deactivate() -> void:
	_active = false
	if is_instance_valid(_canvas_mod):
		_canvas_mod.queue_free()
	if is_instance_valid(_point_light):
		_point_light.queue_free()
	_canvas_mod = null
	_point_light = null

func _radial_gradient_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex
```

- [ ] **Step 2: Parse-check headless**

Instanciar em cena temporária, confirmar sem `SCRIPT ERROR`/`Parse Error`. Simular `_on_body_entered` com um corpo fictício no grupo `"player"` e confirmar que `_canvas_mod`/`_point_light` são criados; simular `_on_body_exited` e confirmar que são liberados (`is_instance_valid` volta `false` depois de um frame, ou verificar via `queue_free` chamado).

- [ ] **Step 3: Commit**

```bash
git add stages/stage_07/vision_limit_zone.gd
git commit -m "feat(stage07): componente de zona de visão limitada"
```

---

### Task 5: Inimigos terrestres/melee (lion_cub_runner, solar_guard, mirror_ram)

**Files:**
- Create: `characters/enemies/stage_07/enemy_lion_cub_runner.gd` + `.tscn`
- Create: `characters/enemies/stage_07/enemy_solar_guard.gd` + `.tscn`
- Create: `characters/enemies/stage_07/enemy_mirror_ram.gd` + `.tscn`

**Interfaces:**
- Produces: 3 `PackedScene` prontas pra Task 8.

- [ ] **Step 1: `enemy_lion_cub_runner` — corredor rápido com arrancada (molde `enemy_gale_runner`, Stage 05)**

`characters/enemies/stage_07/enemy_lion_cub_runner.gd`:
```gdscript
extends EnemyBase
class_name EnemyLionCubRunner

# Cria robótica veloz: patrulha normal; ao ver o player no mesmo nível,
# dispara uma arrancada rápida até bater em parede ou esgotar o tempo.
const FRAMES := 9
const FPS := 11.0
const DETECT_X := 300.0
const DETECT_Y := 60.0
const DASH_SPEED := 230.0
const DASH_TIME := 0.65
const DASH_COOLDOWN := 1.3

var _dash_timer := 0.0
var _cooldown := 0.5

func _init() -> void:
	max_hp = 8
	contact_damage = 6

func _ready() -> void:
	max_hp = 8
	contact_damage = 6
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _dash_timer > 0.0:
		_dash_timer -= delta
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = DASH_SPEED * _direction
		move_and_slide()
		if is_on_wall():
			_dash_timer = 0.0
		if _dash_timer <= 0.0:
			_cooldown = DASH_COOLDOWN
		_advance_sprite_frame_loop(delta, FRAMES, FPS * 1.5)
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
			_dash_timer = DASH_TIME
```

`characters/enemies/stage_07/enemy_lion_cub_runner.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_07/enemy_lion_cub_runner.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_07/enemy_lion_cub_runner.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 18.0
height = 60.0

[node name="EnemyLionCubRunner" type="CharacterBody2D"]
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

- [ ] **Step 2: `enemy_solar_guard` — melee terrestre com bash curto (molde `enemy_shadow_stalker`, Stage 06)**

`characters/enemies/stage_07/enemy_solar_guard.gd`:
```gdscript
extends EnemyBase
class_name EnemySolarGuard

# Guarda do templo: bash/investida curta e rápida quando o player está perto.
const FRAMES := 6
const FPS := 9.0
const DETECT_X := 160.0
const DETECT_Y := 50.0
const LUNGE_SPEED := 260.0
const LUNGE_TIME := 0.32
const LUNGE_COOLDOWN := 1.2

var _lunge_timer := 0.0
var _cooldown := 0.4

func _init() -> void:
	max_hp = 10
	contact_damage = 8

func _ready() -> void:
	max_hp = 10
	contact_damage = 8
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

`characters/enemies/stage_07/enemy_solar_guard.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_07/enemy_solar_guard.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_07/enemy_solar_guard.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 20.0
height = 68.0

[node name="EnemySolarGuard" type="CharacterBody2D"]
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
scale = Vector2(0.76, 0.76)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 3: `enemy_mirror_ram` — terrestre pesado com investida (molde `enemy_eclipse_duelist`, Stage 06 — arquétipo "heavy")**

`characters/enemies/stage_07/enemy_mirror_ram.gd`:
```gdscript
extends EnemyBase
class_name EnemyMirrorRam

# Carneiro-espelho pesado: patrulha lenta; investida longa e previsível
# quando vê o player no mesmo nível. HP alto (arquétipo "heavy").
const FRAMES := 9
const FPS := 8.0
const DETECT_X := 340.0
const DETECT_Y := 70.0
const CHARGE_SPEED := 240.0
const CHARGE_TIME := 1.2
const CHARGE_COOLDOWN := 1.8

var _charge_timer := 0.0
var _cooldown := 0.6

func _init() -> void:
	max_hp = 22
	contact_damage = 12

func _ready() -> void:
	max_hp = 22
	contact_damage = 12
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

`characters/enemies/stage_07/enemy_mirror_ram.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_07/enemy_mirror_ram.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_07/enemy_mirror_ram.png" id="2_tex"]

[sub_resource type="CapsuleShape2D" id="Cap_1"]
radius = 22.0
height = 76.0

[node name="EnemyMirrorRam" type="CharacterBody2D"]
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
scale = Vector2(0.8, 0.8)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 4: Parse-check headless dos 3 scripts**

Carregar cada `.tscn` numa cena temporária headless. Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 5: Commit**

```bash
git add characters/enemies/stage_07/enemy_lion_cub_runner.* characters/enemies/stage_07/enemy_solar_guard.* characters/enemies/stage_07/enemy_mirror_ram.*
git commit -m "feat(stage07): inimigos terrestres/melee (lion_cub_runner, solar_guard, mirror_ram)"
```

---

### Task 6: Inimigos voadores/suspensos (glasswing_drone, prism_orbiter, mirror_moth, sun_grabber)

**Files:**
- Create: `characters/enemies/stage_07/enemy_glasswing_drone.gd` + `.tscn`
- Create: `characters/enemies/stage_07/enemy_prism_orbiter.gd` + `.tscn`
- Create: `characters/enemies/stage_07/enemy_mirror_moth.gd` + `.tscn`
- Create: `characters/enemies/stage_07/enemy_sun_grabber.gd` + `.tscn`

**Interfaces:**
- Consumes: `LightProjectile.setup(...)` (Task 1), `res://characters/enemies/enemy_flyer.gd`.
- Produces: 4 `PackedScene` prontas pra Task 8.

- [ ] **Step 1: `enemy_glasswing_drone` — mergulhador padrão (molde `enemy_umbra_bat`, Stage 06)**

`characters/enemies/stage_07/enemy_glasswing_drone.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyGlasswingDrone

# Drone-vidro patrulheiro: mergulhador padrão, dive rápido quando detecta o player.
func _ready() -> void:
	super._ready()
	max_hp = 8
	contact_damage = 8
	current_hp = max_hp
	detect_radius = 260.0
	dive_speed = 370.0
	retreat_speed = 190.0
	patrol_range = 200.0
	bob_amplitude = 10.0
```

`characters/enemies/stage_07/enemy_glasswing_drone.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_07/enemy_glasswing_drone.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_07/enemy_glasswing_drone.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(70.0, 60.0)

[node name="EnemyGlasswingDrone" type="CharacterBody2D"]
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

- [ ] **Step 2: `enemy_prism_orbiter` — hover-atirador (molde `enemy_void_orbiter`, Stage 06)**

`characters/enemies/stage_07/enemy_prism_orbiter.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyPrismOrbiter

# Núcleo prismático flutuante: hover puro (sem mergulho) + tiro de light_bolt.
const _PROJ := preload("res://characters/enemies/stage_07/light_projectile.tscn")
const SHOOT_INTERVAL := 1.6
const SHOOT_RANGE := 420.0
const BOLT_SPEED := 310.0
const BOLT_DAMAGE := 6

var _shoot_timer := 0.6

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
	var proj := _PROJ.instantiate() as LightProjectile
	proj.setup(dir * BOLT_SPEED, BOLT_DAMAGE, "prism_orbiter", 0.0, "light_bolt")
	get_parent().add_child(proj)
	proj.global_position = global_position
```

`characters/enemies/stage_07/enemy_prism_orbiter.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_07/enemy_prism_orbiter.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_07/enemy_prism_orbiter.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="Cap_1"]
radius = 26.0

[node name="EnemyPrismOrbiter" type="CharacterBody2D"]
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

- [ ] **Step 3: `enemy_mirror_moth` — hover-atirador (molde `enemy_feather_swarm`, Stage 05)**

`characters/enemies/stage_07/enemy_mirror_moth.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemyMirrorMoth

# Mariposa-espelho: hover puro + arremesso de prism_shard.
const _PROJ := preload("res://characters/enemies/stage_07/light_projectile.tscn")
const SHOOT_INTERVAL := 1.5
const SHOOT_RANGE := 380.0
const SHARD_SPEED := 280.0
const SHARD_DAMAGE := 5

var _shoot_timer := 0.5

func _ready() -> void:
	super._ready()
	max_hp = 6
	contact_damage = 6
	current_hp = max_hp
	dive_speed = 0.0
	detect_radius = 0.0
	patrol_range = 90.0
	bob_amplitude = 12.0
	bob_speed = 3.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p != null and global_position.distance_to(p.global_position) <= SHOOT_RANGE:
			_shoot_timer = SHOOT_INTERVAL
			_fire_shard(p)

func _fire_shard(target: Node2D) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var proj := _PROJ.instantiate() as LightProjectile
	proj.setup(dir * SHARD_SPEED, SHARD_DAMAGE, "mirror_moth", 0.0, "prism_shard")
	get_parent().add_child(proj)
	proj.global_position = global_position
```

`characters/enemies/stage_07/enemy_mirror_moth.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_07/enemy_mirror_moth.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_07/enemy_mirror_moth.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="Cap_1"]
radius = 24.0

[node name="EnemyMirrorMoth" type="CharacterBody2D"]
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

- [ ] **Step 4: `enemy_sun_grabber` — suspenso perseguidor lento (molde `enemy_shadow_snare`, Stage 06 — arquétipo "elite")**

`characters/enemies/stage_07/enemy_sun_grabber.gd`:
```gdscript
extends "res://characters/enemies/enemy_flyer.gd"
class_name EnemySunGrabber

# Coletor solar suspenso: flutua e avança devagar até o player quando
# detecta — contato pesado, HP alto (arquétipo "elite").
func _ready() -> void:
	super._ready()
	max_hp = 20
	contact_damage = 14
	current_hp = max_hp
	detect_radius = 320.0
	dive_speed = 130.0
	retreat_speed = 70.0
	patrol_range = 70.0
	bob_amplitude = 14.0
```

`characters/enemies/stage_07/enemy_sun_grabber.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_07/enemy_sun_grabber.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_07/enemy_sun_grabber.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(78.0, 72.0)

[node name="EnemySunGrabber" type="CharacterBody2D"]
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
scale = Vector2(0.74, 0.74)

[node name="ContactZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="ContactZone"]
shape = SubResource("Cap_1")
```

- [ ] **Step 5: Parse-check headless dos 4 scripts**

Carregar cada `.tscn` numa cena temporária headless. Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 6: Commit**

```bash
git add characters/enemies/stage_07/enemy_glasswing_drone.* characters/enemies/stage_07/enemy_prism_orbiter.* characters/enemies/stage_07/enemy_mirror_moth.* characters/enemies/stage_07/enemy_sun_grabber.*
git commit -m "feat(stage07): inimigos voadores/suspensos (glasswing_drone, prism_orbiter, mirror_moth, sun_grabber)"
```

---

### Task 7: Inimigos estáticos (radiant_pylon, beam_turret)

**Files:**
- Create: `characters/enemies/stage_07/enemy_radiant_pylon.gd` + `.tscn`
- Create: `characters/enemies/stage_07/enemy_beam_turret.gd` + `.tscn`

**Interfaces:**
- Consumes: `LightProjectile.setup(...)` (Task 1).
- Produces: 2 `PackedScene` prontas pra Tasks 8/9.

- [ ] **Step 1: `enemy_radiant_pylon` — hazard estático com aura (molde `enemy_dark_lantern`, Stage 06)**

`characters/enemies/stage_07/enemy_radiant_pylon.gd`:
```gdscript
extends EnemyBase
class_name EnemyRadiantPylon

# Pilar radiante fixo: enquanto vivo, empurra pra CIMA quem entrar na coluna
# vertical acima dele (apply_stage_wind — mesmo espírito de um "elevador de
# luz"). Sua morte é usada em Z2 como gatilho alternativo pra desligar um
# light_beam vinculado (wiring feito na Task 9, não aqui).
const FRAMES := 4
const FPS := 6.0
const COLUMN_WIDTH := 90.0
const COLUMN_HEIGHT := 360.0
const PUSH := 220.0

var _column: Area2D = null
var _pushed: Array[Node] = []

func _init() -> void:
	max_hp = 12
	contact_damage = 6

func _ready() -> void:
	max_hp = 12
	contact_damage = 6
	super._ready()
	_column = Area2D.new()
	_column.collision_layer = 0
	_column.collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(COLUMN_WIDTH, COLUMN_HEIGHT)
	cs.shape = sh
	cs.position = Vector2(0.0, -COLUMN_HEIGHT * 0.5)
	_column.add_child(cs)
	add_child(_column)
	_column.body_entered.connect(func(b: Node) -> void:
		if not _pushed.has(b):
			_pushed.append(b))
	_column.body_exited.connect(func(b: Node) -> void:
		_pushed.erase(b))

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	velocity = Vector2.ZERO
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	if DebugBoot.bot_enabled:
		return
	for b in _pushed:
		if is_instance_valid(b) and b.has_method("apply_stage_wind"):
			b.apply_stage_wind(Vector2(0.0, -PUSH) * delta)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
```

`characters/enemies/stage_07/enemy_radiant_pylon.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_07/enemy_radiant_pylon.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_07/enemy_radiant_pylon.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(58.0, 90.0)

[node name="EnemyRadiantPylon" type="CharacterBody2D"]
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

- [ ] **Step 2: `enemy_beam_turret` — canhão fixo (molde `enemy_eclipse_turret`, Stage 06)**

`characters/enemies/stage_07/enemy_beam_turret.gd`:
```gdscript
extends EnemyBase
class_name EnemyBeamTurret

# Torre de luz fixa: não vira; atira light_bolt quando o player entra na
# janela do lado configurado (face_dir).
const _PROJ := preload("res://characters/enemies/stage_07/light_projectile.tscn")
const FRAMES := 4
const FPS := 8.0
const SHOOT_RANGE := 520.0
const AIM_Y := 110.0
const SHOOT_INTERVAL := 1.4
const BOLT_SPEED := 330.0
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
	var proj := _PROJ.instantiate() as LightProjectile
	proj.setup(Vector2(_direction * BOLT_SPEED, 0.0), BOLT_DAMAGE, "beam_turret", 0.0, "light_bolt")
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(_direction * 36.0, -6.0)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
```

`characters/enemies/stage_07/enemy_beam_turret.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemies/stage_07/enemy_beam_turret.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://characters/enemies/stage_07/enemy_beam_turret.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="Cap_1"]
size = Vector2(60.0, 56.0)

[node name="EnemyBeamTurret" type="CharacterBody2D"]
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

- [ ] **Step 3: Parse-check headless dos 2 scripts**

Carregar cada `.tscn` numa cena temporária headless. Expected: sem `SCRIPT ERROR`/`Parse Error`.

- [ ] **Step 4: Commit**

```bash
git add characters/enemies/stage_07/enemy_radiant_pylon.* characters/enemies/stage_07/enemy_beam_turret.*
git commit -m "feat(stage07): inimigos estáticos (radiant_pylon, beam_turret)"
```

---

### Task 8: Scaffold `stage_07_scene.gd` + Zona 1 (feixes retos)

**Files:**
- Create: `stages/stage_07/stage_07_scene.gd`
- Modify: `stages/stage_07/stage_07.tscn` (trocar script base, remover nós antigos)

**Interfaces:**
- Consumes: `light_beam.gd` (Task 2), `light_switch.gd` (Task 3), `vision_limit_zone.gd` (Task 4), os 9 `.tscn` de inimigo (Tasks 5-7).
- Produces: `Stage07` script base com `_zone_tile_path`, `_floor_seg`, `_solid_block`, `_glass_wall`, `_fixed_plat`, `_light_beam`, `_light_switch`, `_vision_zone`, `_setup_corridors`/`_make_corridor`, `_setup_zone_triggers`/`_make_zone_trigger`, `_spawn_zone_enemies` — consumidos pelas Tasks 9-11.

- [ ] **Step 1: Ler o `.tscn` atual e reescrever**

Ler `stages/stage_07/stage_07.tscn` primeiro (`Read` tool) pra saber o uid exato do nó `Luxar` e a lista atual de ext_resources — não assumir os mesmos nomes/uid usados no stage_06.tscn. Reescrever seguindo o padrão de `stages/stage_06/stage_06.tscn` (já mergeado, ler como referência): trocar o `script` do nó raiz pra `res://stages/stage_07/stage_07_scene.gd`, manter `StageController`/`Camera2D`/`HUD`/`PauseMenu`/`GameOver`/`StageComplete`, adicionar um nó `Luxar` (`instance=ExtResource("<uid real>")`) com `visible = false`, remover qualquer plataforma/checkpoint/collectível hardcoded existente.

- [ ] **Step 2: Criar o scaffold do script**

`stages/stage_07/stage_07_scene.gd`:
```gdscript
# stages/stage_07/stage_07_scene.gd — Luxar (luz)
# Rebuild completo no molde dos stages 02-06: estende a base stage_scene.gd,
# zonas construídas em código, 2 corredores com checkpoint e arena de boss.
# Identidade de luz:
#   Z1 feixes retos          — hazards de luz fixos, timing/posicionamento
#   Z2 feixes espelhados     — feixes com dobra + interruptores permanentes
#   Z3 visão limitada        — escurecimento de tela + portões por interruptor
#   Z4 corredor final        — canhões de luz até a sala do Luxar
extends "res://stages/stage_scene.gd"

const _BEAM := preload("res://stages/stage_07/light_beam.gd")
const _SWITCH := preload("res://stages/stage_07/light_switch.gd")
const _VISION := preload("res://stages/stage_07/vision_limit_zone.gd")
const _LUXAR_ROSTER := {
	"cub":     preload("res://characters/enemies/stage_07/enemy_lion_cub_runner.tscn"),
	"guard":   preload("res://characters/enemies/stage_07/enemy_solar_guard.tscn"),
	"ram":     preload("res://characters/enemies/stage_07/enemy_mirror_ram.tscn"),
	"drone":   preload("res://characters/enemies/stage_07/enemy_glasswing_drone.tscn"),
	"orbiter": preload("res://characters/enemies/stage_07/enemy_prism_orbiter.tscn"),
	"moth":    preload("res://characters/enemies/stage_07/enemy_mirror_moth.tscn"),
	"grabber": preload("res://characters/enemies/stage_07/enemy_sun_grabber.tscn"),
	"pylon":   preload("res://characters/enemies/stage_07/enemy_radiant_pylon.tscn"),
	"turret":  preload("res://characters/enemies/stage_07/enemy_beam_turret.tscn"),
}

const FLOOR_Y := 800.0
const _CORR_INTERIOR := 192.0

const _CP1_ENTRY_X := 3136.0
const _CP1_EXIT_X := 4032.0
const _CP2_ENTRY_X := 10432.0
const _CP2_EXIT_X := 11328.0
const _BOSS_L := 12672.0
const _BOSS_R := 14080.0

# Roster de luz por zona: kind (chave de _LUXAR_ROSTER) → posições.
const Z1_ENEMIES := {
	"cub":   [Vector2(700.0, 760.0), Vector2(2100.0, 760.0)],
	"guard": [Vector2(1400.0, 760.0)],
	"ram":   [Vector2(2700.0, 760.0)],
}
const Z2_ENEMIES := {
	"drone":   [Vector2(4700.0, 500.0), Vector2(6200.0, 450.0)],
	"orbiter": [Vector2(5400.0, 600.0)],
	"pylon":   [Vector2(6800.0, 760.0)],
}
const Z3_ENEMIES := {
	"grabber": [Vector2(8600.0, 700.0)],
	"moth":    [Vector2(9400.0, 650.0), Vector2(10000.0, 650.0)],
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
		StageManager.current_stage_id = 7
	super._ready()
	_door_tex = load("res://stages/door_pixellab.png") as Texture2D
	_glass_tex = load("res://stages/stage_07/stage_07_glass.png") as Texture2D
	_setup_corridors()
	_build_zone1()
	_setup_zone_triggers()
	_spawn_zone_enemies(1)
	queue_redraw()

func _zone_tile_path(zone: String) -> String:
	var z := zone.to_lower()
	if z == "boss":
		z = "z4"
	return "res://stages/stage_07/Stage_07T_%s.png" % z

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
		var scene: PackedScene = _LUXAR_ROSTER[kind]
		for pos in table[kind]:
			var e := scene.instantiate()
			(e as Node2D).global_position = pos
			add_child(e)
			target.append(e)

# ── Helpers de terreno (mesmo vocabulário dos stages 02-06) ──────────────────

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
	b.set_meta("tileset_override", "res://stages/stage_07/stage_07_glass.png")
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

# ── Helpers de luz ────────────────────────────────────────────────────────────

func _light_beam(n: String, pos: Vector2, local_points: Array, damage_val: int = 10) -> LightBeam:
	var beam: LightBeam = _BEAM.new()
	beam.name = n
	var pts: Array[Vector2] = []
	for p in local_points:
		pts.append(p as Vector2)
	beam.points = pts
	beam.damage = damage_val
	beam.position = pos
	add_child(beam)
	return beam

func _light_switch(n: String, pos: Vector2, size: Vector2, target: Node, target_active: bool) -> void:
	var sw: Area2D = _SWITCH.new()
	sw.name = n
	sw.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	sw.add_child(cs)
	add_child(sw)
	sw.set("target_path", sw.get_path_to(target))
	sw.set("target_active_value", target_active)

func _vision_zone(n: String, pos: Vector2, size: Vector2) -> void:
	var vz: Area2D = _VISION.new()
	vz.name = n
	vz.collision_layer = 0
	vz.collision_mask = 2
	vz.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	vz.add_child(cs)
	add_child(vz)

func _light_gate(n: String, zone: String, cx: float, top_y: float, w: float = 128.0, h: float = 192.0) -> StaticBody2D:
	# Portão que começa TRANCADO (invisível/sem colisão) até um light_switch
	# ligar. Mesma técnica de crumbling_ledge (skip_base_draw + disabled).
	var b := StaticBody2D.new()
	b.name = n
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = Vector2(cx, top_y)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(w, h)
	cs.shape = sh
	cs.disabled = true
	b.add_child(cs)
	b.set_meta("lava_override", _zone_tile_path(zone))
	b.set_meta("skip_base_draw", true)
	add_child(b)
	return b

# ── Zona 1 — Entrada / feixes retos ───────────────────────────────────────────

func _build_zone1() -> void:
	_floor_seg("z1", 0.0, _CP1_ENTRY_X, FLOOR_Y)
	# 2 feixes verticais fixos (chão até o teto nominal da zona), cruzando o
	# caminho — o jogador precisa cronometrar a passagem por baixo/entre eles.
	_light_beam("Z1_Beam1", Vector2(1100.0, FLOOR_Y - 260.0),
		[Vector2(0.0, -260.0), Vector2(0.0, 260.0)])
	_light_beam("Z1_Beam2", Vector2(2400.0, FLOOR_Y - 260.0),
		[Vector2(0.0, -260.0), Vector2(0.0, 260.0)])
```

- [ ] **Step 2: Parse-check headless (`.gd` isolado — `_build_zone2/3/4` ainda não existem)**

Scene-load real de `stage_07.tscn` com timeout, grep por `script error|parse error`. Expected: sem ocorrências.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_07/stage_07.tscn stages/stage_07/stage_07_scene.gd
git commit -m "feat(stage07): scaffold do script + zona 1 (feixes retos)"
```

---

### Task 9: Zona 2 — Feixes espelhados + interruptores

**Files:**
- Modify: `stages/stage_07/stage_07_scene.gd` (adicionar `_build_zone2()` + chamada em `_ready()`)

**Interfaces:**
- Consumes: `_light_beam`, `_light_switch`, `_floor_seg`, `_fixed_plat` (Task 8), `LightBeam.set_active` (Task 2).
- Produces: `_build_zone2()`, consumido pela Task 12.

- [ ] **Step 1: Adicionar `_build_zone2()`**

Em `_ready()`:
```gdscript
	_build_zone1()
	_build_zone2()
	_setup_zone_triggers()
```

Função nova. **Antes de finalizar, recalcular manualmente**: o feixe espelhado (`Z2_Beam1`) tem pontos locais `[(0,-260), (0,0), (300,-180)]` — 2 segmentos, um vertical (chão até o ponto de dobra) e um diagonal (dobra até o receptor). O interruptor `Z2_Switch1` fica posicionado sobre piso sólido, alcançável por pulo normal (gap ≤196px), e desliga `Z2_Beam1` via `_light_switch(..., beam1, false)`:
```gdscript
# ── Zona 2 — Feixes espelhados + interruptores ────────────────────────────────
# Feixe com 1 dobra bloqueando o caminho; um interruptor alcançável antes do
# feixe desliga ele permanentemente, abrindo a passagem. Ameaça aérea +
# armadura de Zael (Braços... Pernas, conferir tabela do CLAUDE.md) num
# desvio guardado pelo próprio feixe.

func _build_zone2() -> void:
	_floor_seg("z2", _CP1_EXIT_X, 4700.0, FLOOR_Y)
	var beam1 := _light_beam("Z2_Beam1", Vector2(5000.0, FLOOR_Y),
		[Vector2(0.0, -260.0), Vector2(0.0, 0.0), Vector2(260.0, -180.0)])
	_light_switch("Z2_Switch1", Vector2(4850.0, FLOOR_Y - 40.0), Vector2(64.0, 80.0), beam1, false)
	_floor_seg("z2", 4700.0, 7000.0, FLOOR_Y)
	# Armadura de Zael (Pernas) num desvio elevado atrás do feixe — só
	# alcançável depois de desligar Z2_Beam1 no interruptor.
	_fixed_plat("Z2_ArmorLedge", "z2", 5100.0, FLOOR_Y - 98.0, 160.0)
	var armor := preload("res://stages/collectible.tscn").instantiate()
	armor.set("collectible_type", Collectible.Type.ARMOR_ZAEL)
	armor.set("armor_piece", "legs")
	armor.global_position = Vector2(5100.0, FLOOR_Y - 138.0)
	add_child(armor)
	_floor_seg("z2", 7000.0, _CP2_ENTRY_X, FLOOR_Y)
```

Recalcular geometria efetiva a partir dos valores REAIS escritos no arquivo (não confiar nos números de exemplo acima sem reconferir): confirmar que o interruptor fica sobre piso sólido, que a plataforma da armadura (98px acima do piso) está dentro do alcance vertical de pulo (~118px), e que os segmentos do feixe não cobrem acidentalmente a área do interruptor ou da plataforma de aterrissagem.

- [ ] **Step 2: Parse-check headless**

Scene-load real com timeout, grep por erros.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_07/stage_07_scene.gd
git commit -m "feat(stage07): zona 2 (feixes espelhados + interruptor + armadura)"
```

---

### Task 10: Zona 3 — Visão limitada + portões

**Files:**
- Modify: `stages/stage_07/stage_07_scene.gd` (adicionar `_build_zone3()` + chamada em `_ready()`)

**Interfaces:**
- Consumes: `_vision_zone`, `_light_gate`, `_light_switch`, `_floor_seg`, `_fixed_plat` (Task 8).
- Produces: `_build_zone3()`, consumido pela Task 12.

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
# ── Zona 3 — Visão limitada + portões ─────────────────────────────────────────
# Trecho com CanvasModulate escurecido (vision_limit_zone) cobrindo boa parte
# da zona; um interruptor (fora da zona escura, visível) liga um portão
# permanentemente sólido logo depois, guardando o extra de Zara + coração.

func _build_zone3() -> void:
	_floor_seg("z3", 8000.0, _CP2_ENTRY_X, FLOOR_Y)
	_vision_zone("Z3_Dark", Vector2(9200.0, FLOOR_Y - 200.0), Vector2(2400.0, 700.0))
	var gate := _light_gate("Z3_Gate", "z3", 9700.0, FLOOR_Y - 96.0, 64.0, 192.0)
	_light_switch("Z3_Switch1", Vector2(9300.0, FLOOR_Y - 40.0), Vector2(64.0, 80.0), gate, true)
	# Extra de Zara (Machado de Guerra) + coração num desvio depois do portão.
	_fixed_plat("Z3_ExtraLedge", "z3", 9900.0, FLOOR_Y - 98.0, 160.0)
	var axe := preload("res://stages/collectible.tscn").instantiate()
	axe.set("collectible_type", Collectible.Type.WEAPON_ZARA)
	axe.set("ability_id", "war_axe")
	axe.global_position = Vector2(9900.0, FLOOR_Y - 138.0)
	add_child(axe)
	var heart := preload("res://stages/collectible.tscn").instantiate()
	heart.set("collectible_type", Collectible.Type.HEART)
	heart.set("stage_id", 7)
	heart.global_position = Vector2(9970.0, FLOOR_Y - 138.0)
	add_child(heart)
```

**Antes de finalizar, verificar manualmente**: `Z3_Gate` começa travado (`disabled=true`, `skip_base_draw=true`) e SÓ abre depois do interruptor ser tocado — confirmar que não há rota alternativa contornando o portão (senão ele vira decorativo, mesmo tipo de bug que a Zona 3 da Stage 06 teve com o piso cobrindo o abismo dos portais). Confirmar que `Z3_Switch1` está posicionado ANTES do `Z3_Gate` (x menor) e sobre piso sólido.

- [ ] **Step 2: Parse-check headless**

Scene-load real com timeout, grep por erros.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_07/stage_07_scene.gd
git commit -m "feat(stage07): zona 3 (visão limitada + portão + colectáveis)"
```

---

### Task 11: Zona 4 + sala do boss

**Files:**
- Modify: `stages/stage_07/stage_07_scene.gd` (adicionar `_build_zone4()`, `_build_boss_arena()` + chamadas em `_ready()`)

**Interfaces:**
- Consumes: `_floor_seg`, `_solid_block` (Task 8), nó `Luxar` já presente na `.tscn` (Task 8 Step 1).
- Produces: `_build_zone4()`, `_build_boss_arena()`, consumidos pela Task 12.

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

Funções novas (padrão B — porta aberta + trigger). **Crítico: setar `arena_left`/`arena_right`/`arena_floor` no boss** (bug encontrado na revisão final da Stage 06 — ver Global Constraints):
```gdscript
# ── Zona 4 — Corredor final com canhões de luz ────────────────────────────────

func _build_zone4() -> void:
	_floor_seg("z4", _CP2_EXIT_X, _BOSS_L, FLOOR_Y)

# ── Sala do boss (Luxar) ───────────────────────────────────────────────────────
# Padrão B (porta aberta + trigger, skill new-boss-room): arena aberta,
# aggro por Area2D de entrada — não por distância.

func _build_boss_arena() -> void:
	_floor_seg("boss", _BOSS_L, _BOSS_R, FLOOR_Y)
	_solid_block("boss", "Boss_WallR", _BOSS_R + 32.0, FLOOR_Y - 256.0, 64.0, 512.0)
	_solid_block("boss", "Boss_WallL_Top", _BOSS_L + 32.0, FLOOR_Y - 448.0, 64.0, 256.0)
	var luxar := get_node_or_null("Luxar")
	if luxar:
		luxar.visible = true
		luxar.global_position = Vector2((_BOSS_L + _BOSS_R) * 0.5, FLOOR_Y - 64.0)
		luxar.set("auto_aggro", false)
		luxar.set("arena_left", _BOSS_L + 64.0)
		luxar.set("arena_right", _BOSS_R - 64.0)
		luxar.set("arena_floor", FLOOR_Y)
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
				luxar.call("aggro"))
		if luxar.has_signal("boss_defeated"):
			luxar.connect("boss_defeated", _on_boss_defeated)

func _on_boss_defeated(_ability_id: String) -> void:
	GameManager.save_game()
```

**Antes de commitar**: (a) ler `stages/stage_scene.gd::_ready()` pra confirmar se a conexão genérica de HUD/boss (`$HUD.connect_to_boss`) ainda existe pra qualquer `BossBase` presente na árvore antes desta função rodar — se sim, NÃO duplicar a chamada aqui (mesmo caso já resolvido na Stage 06); (b) recalcular os valores de `arena_left`/`arena_right`/`arena_floor` contra as constantes REAIS do arquivo e confirmar que `luxar.global_position` cai dentro do intervalo `[arena_left, arena_right]`; (c) confirmar `Boss_WallR`/`Boss_WallL_Top`/largura da sala múltiplos de 64px.

- [ ] **Step 2: Parse-check headless**

Scene-load real com timeout, grep por erros.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_07/stage_07_scene.gd
git commit -m "feat(stage07): zona 4 + sala do boss Luxar (com arena bounds)"
```

---

### Task 12: Teto por zona + integração final

**Files:**
- Modify: `stages/stage_07/stage_07_scene.gd` (adicionar `_CEIL07_SEGS`, `_build_zone_ceilings07()`, `_ceil07_surface_at()`, `_draw_zone_ceilings07()`, `_draw()`, chamada em `_ready()`)

**Interfaces:**
- Consumes: todas as zonas das Tasks 8-11.
- Produces: fase jogável completa, testada headless + export web + testes de regressão.

- [ ] **Step 1: Adicionar sistema de teto (FACE_GAP + fallback cross-zone + offset visual correto desde o início)**

Em `_ready()`, como ÚLTIMA chamada de construção:
```gdscript
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_build_zone4()
	_build_boss_arena()
	_build_zone_ceilings07()
	_setup_zone_triggers()
```

Como a fase inteira fica numa única elevação (`FLOOR_Y = 800.0`), o teto é uma faixa reta por zona:
```gdscript
# ── Teto por zona ─────────────────────────────────────────────────────────────
const _CEIL07_SEGS := {
	"Z1":   [[0.0, _CP1_ENTRY_X, FLOOR_Y - 500.0]],
	"Z2":   [[_CP1_EXIT_X, _CP2_ENTRY_X, FLOOR_Y - 500.0]],
	"Z4":   [[_CP2_EXIT_X, _BOSS_L, FLOOR_Y - 500.0]],
	"Boss": [[_BOSS_L, _BOSS_R, FLOOR_Y - 448.0 - 256.0]],
}
const _CEIL07_TEX := { "Z1": "z1", "Z2": "z2", "Z4": "z4", "Boss": "z4" }
const _CEIL07_TOP := 128.0
const _CEIL07_FACE_GAP := 32.0

func _build_zone_ceilings07() -> void:
	for zk: String in _CEIL07_SEGS:
		var body := StaticBody2D.new()
		body.name = "%sCeilSegs" % zk
		body.collision_layer = 1
		body.collision_mask = 0
		add_child(body)
		for s: Array in _CEIL07_SEGS[zk]:
			var cs := CollisionShape2D.new()
			var sh := SegmentShape2D.new()
			sh.a = Vector2(s[0], (s[2] as float) - _CEIL07_FACE_GAP)
			sh.b = Vector2(s[1], (s[2] as float) - _CEIL07_FACE_GAP)
			cs.shape = sh
			body.add_child(cs)

func _ceil07_surface_at(zk: String, wx: float) -> float:
	for s: Array in _CEIL07_SEGS[zk]:
		if wx >= (s[0] as float) and wx < (s[1] as float):
			return s[2]
	for zk2: String in _CEIL07_SEGS:
		if zk2 == zk:
			continue
		for s: Array in _CEIL07_SEGS[zk2]:
			if wx >= (s[0] as float) and wx < (s[1] as float):
				return s[2]
	return -1.0

func _ceil07_solid(zk: String, wx: float, y: float) -> bool:
	var yb := _ceil07_surface_at(zk, wx)
	return yb > 0.0 and y < yb

func _draw() -> void:
	super._draw()
	_draw_zone_ceilings07()

func _draw_zone_ceilings07() -> void:
	var ts := float(_TS)
	var sts := float(_SRC_TS)
	for zk: String in _CEIL07_SEGS:
		var segs: Array = _CEIL07_SEGS[zk]
		var tex := _cached_override_tex(_zone_tile_path(_CEIL07_TEX[zk] as String))
		if tex == null:
			continue
		var x0f: float = segs[0][0]
		var x1f: float = segs[segs.size() - 1][1]
		var x := x0f
		while x < x1f:
			var yb := _ceil07_surface_at(zk, x)
			var y := _CEIL07_TOP
			while y < yb:
				var ed := not _ceil07_solid(zk, x, y + ts)
				var el := not _ceil07_solid(zk, x - ts, y)
				var er := not _ceil07_solid(zk, x + ts, y)
				var tile: Vector2i
				if   ed and el: tile = Vector2i(0, 2)
				elif ed and er: tile = Vector2i(3, 3)
				elif ed:        tile = Vector2i(1, 2)
				elif el:        tile = Vector2i(1, 0)
				elif er:        tile = Vector2i(3, 2)
				elif not _ceil07_solid(zk, x - ts, y + ts): tile = Vector2i(2, 2)
				elif not _ceil07_solid(zk, x + ts, y + ts): tile = Vector2i(3, 1)
				else:           tile = Vector2i(2, 1)
				draw_texture_rect_region(tex, Rect2(x, y, ts, ts),
					Rect2(float(tile.x) * sts, float(tile.y) * sts, sts, sts))
				y += ts
			x += ts
```

**Nota**: confirmar que a X-range da entrada "Z2" cobre toda a extensão real da Zona 3 (não existe entrada "Z3" própria, igual ao padrão da Stage 06) — se as coordenadas reais escritas nas Tasks 9/10 não baterem com essa suposição, adicionar uma entrada "Z3" própria em vez de confiar só no fallback cross-zone.

- [ ] **Step 2: Parse-check headless do script**

Scene-load real, grep por erros.

- [ ] **Step 3: Parse-check headless da cena completa**

`timeout 30 "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://stages/stage_07/stage_07.tscn`, grep por `script error|parse error` (case-insensitive) no log. Expected: nenhuma ocorrência.

- [ ] **Step 4: Rodar os testes automatizados existentes**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```
`test_game_manager`/`test_stage_manager` devem passar limpos. `test_character_base` pode reportar as mesmas 3 asserções pré-existentes já confirmadas como não-relacionadas (`current_hp equals max_hp on ready`, `hp is 70 after 30 damage`, `second hit blocked during invincibility`) — confirmar via `git diff --stat <branch-base>..HEAD -- characters/base/character_base.gd autoloads/game_manager.gd` mostrando vazio.

- [ ] **Step 5: Traçar a travessia ponta a ponta uma última vez**

Reler o arquivo final e confirmar, com os números REAIS: Z1 feixes → corredor CP1 → Z2 feixes espelhados+interruptor → armadura → Z3 visão limitada+portão → extra+coração → corredor CP2 → Z4 corredor → sala do boss. Confirmar que `Z2_Switch1` realmente desliga `Z2_Beam1` (não outro feixe por engano) e que `Z3_Switch1` realmente liga `Z3_Gate` (não fica travado pra sempre). Esse é o mesmo tipo de checagem que a revisão final de branch inteiro das Stages 05/06 fez e que pegou bugs reais de wiring cross-task.

- [ ] **Step 6: Export web (não commitar — o deploy agora builda no CI)**

**NÃO rodar `--export-release` nem commitar `export/web/*`** — desde a migração feita nesta sessão (`ci: build web export in CI instead of committing binaries to git`), o `.github/workflows/deploy.yml` builda o jogo automaticamente a cada push na master. Rodar só o parse-check/scene-load local (Steps 2-4) como verificação; o deploy real acontece sozinho depois do merge.

- [ ] **Step 7: Commit final**

```bash
git add stages/stage_07/stage_07_scene.gd
git commit -m "feat(stage07): teto por zona + integração final"
```

---

## Self-Review

**1. Cobertura do spec:** Z1 feixes retos (Task 8) ✓, Z2 feixes espelhados+interruptor+armadura (Task 9) ✓, Z3 visão limitada+portão+extra+coração (Task 10) ✓, Z4+boss com arena bounds (Task 11) ✓, roster de 9 (Tasks 5-7) ✓, 2 checkpoints (Task 8) ✓, teto com FACE_GAP/fallback/offset-visual-correto desde o início (Task 12) ✓, colectáveis via enum desde o início (Tasks 9-10) ✓, componentes neutros sob bot (Tasks 2-4) ✓.

**2. Placeholders:** nenhum "TBD"/"implementar depois". Cada task de zona tem instrução explícita de reconferir a aritmética contra o código de verdade escrito, não contra os números de exemplo do plano — mesmo padrão que funcionou nas Stages 05/06 pra pegar bugs reais antes do merge.

**3. Consistência de tipos:** `LightProjectile.setup()` (Task 1) usado identicamente pelas Tasks 6 (`prism_orbiter`, `mirror_moth`) e 7 (`beam_turret`). `_LUXAR_ROSTER` (Task 8) referencia exatamente os nomes de arquivo `.tscn` criados nas Tasks 5-7. `LightBeam.set_active`/`points`/`damage` (Task 2) batendo entre definição e uso nas Tasks 8-9. `LightSwitch.target_path`/`target_active_value` (Task 3) batendo entre definição e uso nas Tasks 9-10. `VisionLimitZone` (Task 4) instanciado via `_vision_zone` (Task 8) na Task 10 sem parâmetros extras não previstos.

---

**Plan complete and saved to `docs/superpowers/plans/2026-07-17-stage07-luxar-redesign.md`.**

Seguindo direto pra execução via subagent-driven-development, conforme pedido — sem pausa pra escolha de abordagem.
