# Zona 4 do Stage 01 — Shaft de Wall-Jump (MMX2) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir a subida diagonal da zona 4 (escada-chase + escada-coupled + cratera) por um shaft vertical de wall-jump com lava única perseguindo, câmara → corredor → arena do boss reconstruída (porta lateral), e uma rota secreta de revisita (galerix) com sub-tank.

**Architecture:** Tudo em `stages/stage_01/stage_01_scene.gd` (geometria via helpers + tabelas de coordenadas) + 3 scripts de mecânica (`rising_lava.gd` aceleração, `crumbling_ledge.gd` novo, `cracked_wall.gd` flag de lado). A sala do boss é recriada no molde de `_draw_boss_room` do stage 00 (porta na parede esquerda), só trocando o tileset (`_ROOM_TILE`). Testes são scripts headless que instanciam a cena e checam invariantes de geometria (padrão `tests/test_z3_geom`), mais validação por bot e web export.

**Tech Stack:** Godot 4.6.2 / GDScript. Rodar testes: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/<x>.tscn`.

**Spec:** `docs/superpowers/specs/2026-06-15-stage01-zone4-walljump-shaft-design.md`

---

## Sistema de coordenadas (design inicial — tunável no playtest)

Mantidos: `Z4Base` (x16160–16480, topo 2624) e `Z4ChaseStep0–3` (terminam em x17184, superfície y2208).

**Shaft (interior, centrado em x≈17520; paredes de 64px por fora):**

| Seg | y_top | y_bot | x_l | x_r | largura | extras |
|-----|-------|-------|-----|-----|---------|--------|
| 1 | 1900 | 2208 | 17424 | 17616 | 192 | ease-in; **parede #1** na base (face esq.) |
| 2 | 1580 | 1900 | 17440 | 17600 | 160 | saliência de respiro (dir.) |
| 3 | 1260 | 1580 | 17424 | 17616 | 192 | espinhos (faces alternadas, `no_wall_grab`) |
| 4 | 940  | 1260 | 17408 | 17632 | 224 | **saliência que desmorona** (centro) |
| 5 | 620  | 940  | 17424 | 17616 | 192 | espinhos + **flyer** + saliência |
| 6 | 360  | 620  | 17456 | 17584 | 128 | estreito; saída no topo → câmara pré-chefe |

**Lava única** (`rising_lava` chase): x17400–17640, `low_y=2360`, `cap_y=480`, `rise_speed=80`, `accel_y=975`, `accel_speed=150`, altura 1700. Disparada por `Z4ChaseTrigger`.

**Câmara pré-chefe:** piso `StaticBody2D` topo y360, x17440–18200 (com vão x17456–17584 = saída do seg6). Seca.

**Corredor:** `CorridorSection`, floor topo y376 (floor_center (18530,408), size (660,64)), ceil (18530,208)/(660,64), wall_l (18200,308)/(64,264), wall_r (18860,308)/(64,264), porta + checkpoint index 2.

**Arena do boss (reconstruída):** `BossWallL` x18900 (porta na parede esq.), `BossWallR` x21716, `BossFloor` topo y440, teto y-160 → interior ~2816×600. Ignarath em (~20300, 360).

**Rota secreta (galerix):**
- Passagem secreta: interior x16980–17360, da base (y2208) até a câmara do coletável.
- **Parede #1:** seção `cracked_wall` na face esquerda do seg1 (x17360–17424, y2080–2208), quebra pelo lado do shaft (direita).
- **Elevador:** `vertical_platform` `up_only`, largura 192, base y2180, `move_distance≈1760` → topo y~420; encaixa no buraco do piso da câmara do coletável.
- **Câmara do coletável:** piso topo y360, x16800–17380; **buraco** x17000–17200 (encaixe do elevador); contém 1 `Collectible` SUBTANK.
- **Parede #2:** `cracked_wall` x17380–17440 (entre coletável e pré-chefe), **quebra só pelo lado esquerdo** (coletável).

---

## FASE 1 — Mecânicas isoladas

### Task 1: Aceleração da lava-chase em `rising_lava.gd`

**Files:**
- Modify: `stages/stage_01/rising_lava.gd`
- Test: `tests/test_rising_lava_accel.gd` + `.tscn`

- [ ] **Step 1: Escrever o teste que falha**

`tests/test_rising_lava_accel.gd`:
```gdscript
extends Node

func _ready() -> void:
	var lava = preload("res://stages/stage_01/rising_lava.gd").new()
	lava.mode = "chase"
	lava.low_y = 2000.0
	lava.rise_speed = 80.0
	lava.cap_y = 400.0
	lava.accel_y = 1000.0      # acima disso (y < 1000) acelera
	lava.accel_speed = 150.0
	lava.position = Vector2(0, 2000.0)
	lava.activate()
	# longe do topo (y=2000 > accel_y) → velocidade normal
	var y0 = lava.position.y
	lava._tick(1.0)
	var slow = y0 - lava.position.y
	# pula pra perto do topo (y=900 < accel_y) → acelerada
	lava.position.y = 900.0
	var y1 = lava.position.y
	lava._tick(1.0)
	var fast = y1 - lava.position.y
	print("slow=", slow, " fast=", fast)
	if abs(slow - 80.0) > 0.5 or abs(fast - 150.0) > 0.5:
		print("FAIL: aceleração da lava errada"); get_tree().quit(1); return
	print("PASS: lava acelera no terço final")
	get_tree().quit(0)
```
`tests/test_rising_lava_accel.tscn`:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/test_rising_lava_accel.gd" id="1"]
[node name="T" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_rising_lava_accel.tscn`
Expected: FAIL (accel_y/accel_speed não existem ou sem efeito) — exit 1.

- [ ] **Step 3: Implementar**

Em `rising_lava.gd`, adicionar exports e usar no chase:
```gdscript
@export var accel_y: float = -100000.0   # chase: abaixo deste y (mais alto) usa accel_speed; default = nunca
@export var accel_speed: float = 0.0
```
Trocar `_tick_chase`:
```gdscript
func _tick_chase(delta: float) -> void:
	if not _active:
		return
	var spd: float = accel_speed if (accel_speed > 0.0 and position.y < accel_y) else rise_speed
	position.y = move_toward(position.y, cap_y, spd * delta)
```

- [ ] **Step 4: Rodar e ver passar**

Run: idem Step 2. Expected: `PASS: lava acelera no terço final`, exit 0.

- [ ] **Step 5: Commit**
```bash
git add stages/stage_01/rising_lava.gd tests/test_rising_lava_accel.gd tests/test_rising_lava_accel.tscn
git commit -m "feat(stage01): lava-chase acelera no terço final (accel_y/accel_speed)"
```

---

### Task 2: `crumbling_ledge.gd` (saliência que desmorona)

**Files:**
- Create: `stages/stage_01/crumbling_ledge.gd`
- Test: `tests/test_crumbling_ledge.gd` + `.tscn`

- [ ] **Step 1: Escrever o teste que falha**

`tests/test_crumbling_ledge.gd`:
```gdscript
extends Node

func _ready() -> void:
	var ledge = preload("res://stages/stage_01/crumbling_ledge.gd").new()
	ledge.crumble_delay = 0.5
	ledge.respawn_delay = 1.0
	var cs := CollisionShape2D.new()
	cs.shape = RectangleShape2D.new()
	ledge.add_child(cs)
	add_child(ledge)
	await get_tree().process_frame
	# começa sólida
	if cs.disabled:
		print("FAIL: começa desabilitada"); get_tree().quit(1); return
	# simula player pousando → inicia crumble
	ledge.touched()
	ledge._tick(0.6)   # passa do crumble_delay
	if not cs.disabled:
		print("FAIL: não desmoronou após delay"); get_tree().quit(1); return
	ledge._tick(1.1)   # passa do respawn_delay
	if cs.disabled:
		print("FAIL: não respawnou"); get_tree().quit(1); return
	print("PASS: crumbling ledge")
	get_tree().quit(0)
```
`.tscn` análogo aos outros (node "T" + script).

- [ ] **Step 2: Rodar e ver falhar** — script não existe → exit 1.

- [ ] **Step 3: Implementar**

`stages/stage_01/crumbling_ledge.gd`:
```gdscript
# Saliência que desmorona ~crumble_delay após o player pousar, e respawna depois.
extends StaticBody2D

@export var crumble_delay: float = 0.5
@export var respawn_delay: float = 1.2

var _cs: CollisionShape2D
var _state: String = "solid"   # solid | crumbling | gone
var _timer: float = 0.0

func _ready() -> void:
	_cs = get_node_or_null("CollisionShape2D")
	if _cs == null:
		for c in get_children():
			if c is CollisionShape2D:
				_cs = c
				break

func touched() -> void:
	if _state == "solid":
		_state = "crumbling"
		_timer = 0.0

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return   # bot: saliência fica sólida (valida o caminho)
	_tick(delta)

func _tick(delta: float) -> void:
	if _state == "crumbling":
		_timer += delta
		if _timer >= crumble_delay:
			if _cs: _cs.set_deferred("disabled", true)
			_state = "gone"
			_timer = 0.0
	elif _state == "gone":
		_timer += delta
		if _timer >= respawn_delay:
			if _cs: _cs.set_deferred("disabled", false)
			_state = "solid"
			_timer = 0.0
```
Nota: o `touched()` é chamado por um `Area2D` filho no topo (detector de pouso) — criado na geometria (Task 6). O detector conecta `body_entered` → `touched()`.

- [ ] **Step 4: Rodar e ver passar** — `PASS: crumbling ledge`, exit 0.

- [ ] **Step 5: Commit**
```bash
git add stages/stage_01/crumbling_ledge.gd tests/test_crumbling_ledge.gd tests/test_crumbling_ledge.tscn
git commit -m "feat(stage01): crumbling_ledge — saliência que desmorona e respawna"
```

---

### Task 3: `cracked_wall.gd` — quebrar só por um lado

**Files:**
- Modify: `stages/stage_01/cracked_wall.gd`
- Test: `tests/test_cracked_wall_side.gd` + `.tscn`

- [ ] **Step 1: Escrever o teste que falha**

`tests/test_cracked_wall_side.gd`:
```gdscript
extends Node

func _ready() -> void:
	GameManager.boss_abilities_unlocked = ["galerix"]
	var wall = preload("res://stages/stage_01/cracked_wall.gd").new()
	wall.break_side = "left"   # só quebra por um detector do lado esquerdo
	# Detector do lado errado não deve destruir
	var ok_right := wall.can_break_from("right")
	var ok_left := wall.can_break_from("left")
	if ok_right or not ok_left:
		print("FAIL: break_side não respeitado (left=%s right=%s)" % [ok_left, ok_right]); get_tree().quit(1); return
	print("PASS: cracked_wall break_side")
	get_tree().quit(0)
```

- [ ] **Step 2: Rodar e ver falhar** — `break_side`/`can_break_from` não existem → exit 1.

- [ ] **Step 3: Implementar**

Em `cracked_wall.gd`, adicionar:
```gdscript
@export var break_side: String = ""   # "" = qualquer lado; "left"/"right" = só esse detector

func can_break_from(side: String) -> bool:
	if not GameManager.boss_abilities_unlocked.has("galerix"):
		return false
	return break_side == "" or break_side == side
```
E no `_on_hit`, identificar o detector pelo nome do filho. Trocar a conexão do `_ready` pra passar o lado:
```gdscript
func _ready() -> void:
	add_to_group("cracked_wall")
	for child in get_children():
		if child is Area2D and String(child.name).begins_with("HitDetector"):
			var side := "left" if String(child.name).ends_with("L") else ("right" if String(child.name).ends_with("R") else "")
			(child as Area2D).area_entered.connect(func(_a): _on_hit_side(side))

func _on_hit_side(side: String) -> void:
	if can_break_from(side):
		wall_destroyed.emit()
		queue_free()
```
Manter `try_destroy()` antiga? Remover se nada mais a usa (grep `try_destroy` antes; se houver uso, manter delegando a `can_break_from("")`). A parede #1 usa `HitDetector` (sem sufixo → qualquer lado, com galerix). A parede #2 usa `HitDetectorL` (break_side="left").

- [ ] **Step 4: Rodar e ver passar** — `PASS`, exit 0.

- [ ] **Step 5: Commit**
```bash
git add stages/stage_01/cracked_wall.gd tests/test_cracked_wall_side.gd tests/test_cracked_wall_side.tscn
git commit -m "feat(stage01): cracked_wall quebrável por um lado só (break_side)"
```

---

## FASE 2 — Reconstrução da geometria da zona 4

### Task 4: Limpar a zona 4 antiga e a arena do boss

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (`_ready`, `_build_zone4`, `_relocate_and_gap_boss`, remover `_CRATER_CX` se não usado)

- [ ] **Step 1: Remover nós antigos**

No bloco de `_ready` que remove nós (linhas ~30–37), substituir a lista de remoção pra incluir também a arena antiga e remover a chamada `_relocate_and_gap_boss()`:
```gdscript
	for n in ["ShaftUpP1","ShaftUpP2","ShaftUpP3","ShaftUpP4","ShaftUpP5","Corridor2",
		"BossFloor","BossWallL","BossWallR","BossCeil","BossLava","Ignarath"]:
		var nd := get_node_or_null(n)
		if nd: nd.queue_free()
```
Remover a linha `_relocate_and_gap_boss()` e a função inteira `_relocate_and_gap_boss()` (será substituída pela arena nova em Task 8). Remover o `const _CRATER_CX`.

- [ ] **Step 2: Esvaziar `_build_zone4` (manter só base + step0-3 + trigger)**

Reescrever `_build_zone4()` deixando só:
```gdscript
func _build_zone4() -> void:
	_z3_static_floor("Z4Base", Vector2(16320, 2688), Vector2(320, 128))
	_z4_stair("Z4ChaseStep", 16480.0, 2520.0, 192.0, 104.0, 4, 128.0)   # step0..3
	_build_z4_shaft()       # Task 5
	_build_z4_top()         # Task 7
	_build_z4_boss()        # Task 8
	_build_z4_secret()      # Task 9
```
Criar stubs vazios de `_build_z4_shaft/_top/_boss/_secret` por enquanto (`func _build_z4_shaft() -> void: pass` etc.) pra cena carregar.

- [ ] **Step 3: Verificar que a cena carrega headless**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://stages/stage_01/stage_01.tscn --quit-after 3 2>&1 | grep -iE "SCRIPT ERROR|Parse Error" || echo NO-ERRORS`
Expected: `NO-ERRORS`.

- [ ] **Step 4: Commit**
```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "refactor(stage01 z4): remove escada coupled/cratera/arena antiga; stubs do shaft"
```

---

### Task 5: Construir o shaft + lava única

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd`
- Test: `tests/test_z4_shaft.gd` + `.tscn`

- [ ] **Step 1: Helper de parede + build do shaft**

```gdscript
const _SHAFT_SEGS := [
	# y_top, y_bot, x_l, x_r
	[1900.0, 2208.0, 17424.0, 17616.0],
	[1580.0, 1900.0, 17440.0, 17600.0],
	[1260.0, 1580.0, 17424.0, 17616.0],
	[ 940.0, 1260.0, 17408.0, 17632.0],
	[ 620.0,  940.0, 17424.0, 17616.0],
	[ 360.0,  620.0, 17456.0, 17584.0],
]

func _z4_wall(n: String, cx: float, cy: float, w: float, h: float, no_grab := false) -> StaticBody2D:
	var b := _z2_static(n, Vector2(cx, cy), Vector2(w, h))
	if no_grab:
		b.add_to_group("no_wall_grab")
	return b

func _build_z4_shaft() -> void:
	for i in _SHAFT_SEGS.size():
		var s = _SHAFT_SEGS[i]
		var yt: float = s[0]; var yb: float = s[1]; var xl: float = s[2]; var xr: float = s[3]
		var h: float = yb - yt
		var cy: float = (yt + yb) * 0.5
		_z4_wall("Z4ShaftWL%d" % i, xl - 32.0, cy, 64.0, h)   # parede esquerda
		_z4_wall("Z4ShaftWR%d" % i, xr + 32.0, cy, 64.0, h)   # parede direita
	# lava única (chase) cobrindo o shaft
	var lava := _z4_lava("Z4ShaftLava", "chase", 17520.0, 2360.0, 240.0, 1700.0)
	lava.set("rise_speed", 80.0)
	lava.set("cap_y", 480.0)
	lava.set("accel_y", 975.0)
	lava.set("accel_speed", 150.0)
	var trig := get_node_or_null("Z4ChaseTrigger")
	# (Z4ChaseTrigger já existe? se não, criar igual ao antigo) — ver nota abaixo.
	if trig == null:
		trig = Area2D.new(); trig.name = "Z4ChaseTrigger"
		trig.collision_layer = 0; trig.collision_mask = 2
		trig.position = Vector2(16480, 2560); trig.add_child(_z2_shape(Vector2(64, 256)))
		add_child(trig)
	trig.body_entered.connect(func(b): if b is CharacterBase: lava.call("activate"))
```
Nota: `_z4_lava` já existe no arquivo (reusar). `Z4ChaseTrigger` era criado no `_build_zone4` antigo — como foi esvaziado em Task 4, recriá-lo aqui (código acima).

- [ ] **Step 2: Teste de invariantes de geometria**

`tests/test_z4_shaft.gd`:
```gdscript
extends Node
const WALLJUMP_MAX := 256.0   # largura máx. cruzável (alcance do wall-jump)
func _ready() -> void:
	var s = load("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(s)
	for i in 4: await get_tree().physics_frame
	var fail := false
	# largura de cada segmento <= alcance do wall-jump
	for i in 6:
		var wl = s.get_node_or_null("Z4ShaftWL%d" % i)
		var wr = s.get_node_or_null("Z4ShaftWR%d" % i)
		if wl == null or wr == null:
			print("FAIL: faltou parede do seg %d" % i); fail = true; continue
		var inner := wr.position.x - wl.position.x - 64.0
		if inner > WALLJUMP_MAX + 0.5:
			print("FAIL: seg %d largura %.0f > %.0f" % [i, inner, WALLJUMP_MAX]); fail = true
	# lava cap acima da câmara (cap_y < 620 do seg6_bot e suficientemente acima do topo)
	var lava = s.get_node_or_null("Z4ShaftLava")
	if lava == null or float(lava.get("cap_y")) > 520.0:
		print("FAIL: lava cap_y nao protege o topo"); fail = true
	if fail: get_tree().quit(1)
	else: print("PASS: shaft geometry"); get_tree().quit(0)
```

- [ ] **Step 3: Rodar fail→pass**

Run: `... res://tests/test_z4_shaft.tscn`. Implementar até `PASS: shaft geometry`, exit 0.

- [ ] **Step 4: Commit**
```bash
git add stages/stage_01/stage_01_scene.gd tests/test_z4_shaft.gd tests/test_z4_shaft.tscn
git commit -m "feat(stage01 z4): shaft de wall-jump (6 segmentos) + lava única chase"
```

---

### Task 6: Espinhos, saliências de respiro, saliência que desmorona, flyer

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (dentro de `_build_z4_shaft`, no fim)

- [ ] **Step 1: Implementar elementos**

Adicionar ao fim de `_build_z4_shaft()`:
```gdscript
	# Espinhos (no_wall_grab + dano) em faces de parede — seg3 (face dir.) e seg5 (face esq.)
	_z4_spike_face("Z4SpikeR3", _SHAFT_SEGS[2][3] + 32.0, 1420.0, 64.0, 200.0)  # parede dir seg3
	_z4_spike_face("Z4SpikeL5", _SHAFT_SEGS[4][2] - 32.0, 780.0, 64.0, 200.0)   # parede esq seg5
	# Saliências de respiro (StaticBody2D normal, pequenas)
	_z3_static_floor("Z4Ledge2", Vector2(_SHAFT_SEGS[1][3] - 64.0, 1640.0), Vector2(128.0, 32.0))
	_z3_static_floor("Z4Ledge5", Vector2(_SHAFT_SEGS[4][2] + 64.0, 700.0),  Vector2(128.0, 32.0))
	# Saliência que desmorona — seg4 (centro)
	_z4_crumble("Z4Crumble4", Vector2(17520.0, 1100.0), Vector2(160.0, 32.0))
	# Flyer no seg5
	var flyer := preload("res://characters/enemies/enemy_flyer.gd").new()  # ajustar path real do EnemyFlyer
	flyer.name = "Z4Flyer1"
	flyer.position = Vector2(17520.0, 760.0)
	add_child(flyer)
```
Helpers:
```gdscript
func _z4_spike_face(n: String, cx: float, cy: float, w: float, h: float) -> void:
	# parede no_grab + Area2D de dano sobreposta
	var wall := _z4_wall(n, cx, cy, w, h, true)
	var hurt := Area2D.new(); hurt.name = n + "Hurt"
	hurt.collision_layer = 0; hurt.collision_mask = 2
	hurt.add_child(_z2_shape(Vector2(w, h)))
	hurt.position = Vector2(cx, cy)
	hurt.body_entered.connect(func(b): if b is CharacterBase: (b as CharacterBase).take_damage(1))
	add_child(hurt)

func _z4_crumble(n: String, center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = n
	body.set_script(preload("res://stages/stage_01/crumbling_ledge.gd"))
	body.collision_layer = 1; body.collision_mask = 0
	body.position = center
	body.add_child(_z2_shape(size))
	# detector de pouso no topo
	var det := Area2D.new(); det.name = "LandDetector"
	det.collision_layer = 0; det.collision_mask = 2
	var ds := _z2_shape(Vector2(size.x, 16.0)); ds.position = Vector2(0, -size.y * 0.5 - 8.0)
	det.add_child(ds)
	det.body_entered.connect(func(b): if b is CharacterBase: body.call("touched"))
	body.add_child(det)
	add_child(body)
```
Nota de implementação: confirmar o path real do `EnemyFlyer` (grep `enemy_flyer.gd`) e a assinatura de `take_damage` em `CharacterBase` (grep). Ajustar se diferente.

- [ ] **Step 2: Verificar carga headless** (sem SCRIPT ERROR), como Task 4 Step 3.

- [ ] **Step 3: Commit**
```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01 z4): espinhos no_grab, saliências de respiro, crumbling, flyer"
```

---

## FASE 3 — Topo, corredor e arena do boss

### Task 7: Câmara pré-chefe + corredor (CorridorSection)

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (`_build_z4_top`, vars de corredor, `_on_camera_lock`)

- [ ] **Step 1: Implementar `_build_z4_top`**

```gdscript
var _corr_boss: CorridorSection = null

func _build_z4_top() -> void:
	# Câmara pré-chefe: piso seco com vão (saída do seg6) em x17456–17584
	_z3_static_floor("Z4PreL", Vector2(17420.0, 392.0), Vector2(40.0, 128.0))   # piso à esq do vão (parede #2 fica aqui)
	_z3_static_floor("Z4PreR", Vector2(17892.0, 392.0), Vector2(616.0, 128.0))  # piso à dir do vão → até o corredor
	# Corredor do boss (porta + checkpoint + trava câmera)
	_corr_boss = CorridorSection.new()
	_corr_boss.tileset        = _ROOM_TILE
	_corr_boss.floor_center   = Vector2(18530, 408)
	_corr_boss.floor_size     = Vector2(660, 64)
	_corr_boss.ceil_center    = Vector2(18530, 208)
	_corr_boss.ceil_size      = Vector2(660, 64)
	_corr_boss.wall_l_center  = Vector2(18200, 308)
	_corr_boss.wall_l_size    = Vector2(64, 264)
	_corr_boss.wall_r_center  = Vector2(18860, 308)
	_corr_boss.wall_r_size    = Vector2(64, 264)
	_corr_boss.entry_x        = 18260.0
	_corr_boss.exit_x         = 18800.0
	_corr_boss.save_checkpoint = true
	_corr_boss.checkpoint_index = 2
	_corr_boss.checkpoint_respawn_x = 18300.0
	_corr_boss.heal_on_entry  = false
	_corr_boss.exit_retriggerable = true
	_corr_boss.cam_center     = Vector2(18530, 308)
	_corr_boss.cam_zoom       = 2.0
	_corr_boss.camera_lock_requested.connect(_on_camera_lock)
	add_child(_corr_boss)
	_corr_boss.setup(_player)
```
Conferir no código a assinatura/props exatas do `CorridorSection` (comparar com o uso de `_corr3` no stage 00). Setar `door_tex` se o `CorridorSection` exigir (senão a porta fica invisível — ver memória de calibração do corredor). Usar uma textura de porta existente do projeto.

- [ ] **Step 2: Verificar carga headless** (sem erro) + um teste de invariante simples: a câmara pré-chefe está seca (lava `cap_y` 480 > piso 360). Já coberto pelo `test_z4_shaft`; estender pra checar `Z4PreR` existe.

- [ ] **Step 3: Commit**
```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01 z4): câmara pré-chefe + corredor do boss (CorridorSection)"
```

---

### Task 8: Arena do boss reconstruída (molde stage 00, porta lateral)

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (`_build_z4_boss`, `_draw_boss_room`, `_setup_boss_room_trigger`)

- [ ] **Step 1: Construir os corpos da arena nova**

```gdscript
const _BOSS_L := 18900.0
const _BOSS_R := 21716.0
const _BOSS_FLOOR_TOP := 440.0
const _BOSS_CEIL_TOP := -160.0
const _BOSS_DOOR_LO := 240.0   # vão da porta na parede esq (y)
const _BOSS_DOOR_HI := 440.0

func _build_z4_boss() -> void:
	var h := _BOSS_FLOOR_TOP - _BOSS_CEIL_TOP + 64.0
	var cy := (_BOSS_CEIL_TOP + _BOSS_FLOOR_TOP) * 0.5
	_z2_static("BossWallL", Vector2(_BOSS_L, cy), Vector2(64, h)).set_meta("skip_base_draw", true)
	_z2_static("BossWallR", Vector2(_BOSS_R, cy), Vector2(64, h)).set_meta("skip_base_draw", true)
	_z2_static("BossFloor", Vector2((_BOSS_L+_BOSS_R)*0.5, _BOSS_FLOOR_TOP + 32.0), Vector2(_BOSS_R-_BOSS_L, 64)).set_meta("skip_base_draw", true)
	_z2_static("BossCeil",  Vector2((_BOSS_L+_BOSS_R)*0.5, _BOSS_CEIL_TOP - 32.0), Vector2(_BOSS_R-_BOSS_L, 64)).set_meta("skip_base_draw", true)
	# Ignarath
	var ign := preload("res://characters/bosses/ignarath/ignarath.tscn").instantiate()  # conferir path real
	ign.name = "Ignarath"
	ign.position = Vector2((_BOSS_L+_BOSS_R)*0.5, _BOSS_FLOOR_TOP - 80.0)
	ign.set("arena_left", _BOSS_L + 64.0)
	ign.set("arena_right", _BOSS_R - 64.0)
	ign.set("auto_aggro", false)
	add_child(ign)
	_setup_boss_room_trigger()
```
Conferir o path real do Ignarath (grep `ignarath` `.tscn`) e os nomes das props (`arena_left/right`, `auto_aggro`) — já usados no `_setup_boss_room_trigger` atual.

- [ ] **Step 2: Trocar a abertura no `_draw_boss_room` — teto → parede esquerda**

Reescrever `_draw_boss_room` pra abrir a porta na PAREDE ESQUERDA (igual stage 00), no vão `_BOSS_DOOR_LO.._BOSS_DOOR_HI`, em vez do gap no teto. Base (copiar do stage 00 `_draw_boss_room`, trocando `_TILESET`→`_ROOM_TILE`):
```gdscript
func _draw_boss_room() -> void:
	var lwall := get_node_or_null("BossWallL") as Node2D
	var rwall := get_node_or_null("BossWallR") as Node2D
	var ceil_n := get_node_or_null("BossCeil") as Node2D
	var floor_n := get_node_or_null("BossFloor") as Node2D
	if not (lwall and rwall and ceil_n and floor_n): return
	var ts := _TS; var src_ts := _SRC_TS
	var left := lwall.position.x - ts * 0.5
	var right := rwall.position.x + ts * 0.5
	var top := ceil_n.position.y - ts * 0.5
	var bottom := floor_n.position.y + ts * 0.5
	var cols := int(round((right - left) / ts))
	var rows := int(round((bottom - top) / ts))
	var door_lo := int(ceil((_BOSS_DOOR_LO - top) / ts))
	var door_hi := int(floor((_BOSS_DOOR_HI - top) / ts)) - 1
	for row in rows:
		for col in cols:
			var is_l := col == 0; var is_r := col == cols - 1
			var is_t := row == 0; var is_b := row == rows - 1
			if not (is_l or is_r or is_t or is_b): continue
			if is_l and not is_t and not is_b and row >= door_lo and row <= door_hi:
				continue   # abertura da porta na parede esquerda
			var door_to_floor := door_hi >= rows - 2
			var bl_is_floor := is_b and is_l and door_to_floor
			var tile: Vector2i; var tx := 0; var ty := 0
			if   is_t and is_l: tile = Vector2i(3,1); tx = src_ts; ty = src_ts
			elif is_t and is_r: tile = Vector2i(2,2); tx = -src_ts; ty = src_ts
			elif bl_is_floor:   tile = Vector2i(3,0); ty = -src_ts
			elif is_b and is_l: tile = Vector2i(2,0); tx = src_ts; ty = -src_ts
			elif is_b and is_r: tile = Vector2i(1,1); tx = -src_ts; ty = -src_ts
			elif is_t:          tile = Vector2i(1,2); ty = src_ts
			elif is_b:          tile = Vector2i(3,0); ty = -src_ts
			elif is_l:          tile = Vector2i(3,2); tx = src_ts
			else:               tile = Vector2i(1,0); tx = -src_ts
			var dx := left + col * ts + tx
			var dy := top + row * ts + ty
			draw_texture_rect_region(_ROOM_TILE, Rect2(dx, dy, ts, ts),
				Rect2(tile.x * src_ts, tile.y * src_ts, src_ts, src_ts))
```

- [ ] **Step 3: Verificar carga headless + bot smoke**

Run cena headless (sem erro). Depois `?stage=1&bot=1` (web ou editor) numa fase seguinte — o bot deve alcançar a arena. (Validação completa do bot em Task 10.)

- [ ] **Step 4: Commit**
```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01 z4): arena do boss reconstruída (molde stage00, porta lateral, tileset rocha)"
```

---

## FASE 4 — Rota secreta + finalização

### Task 9: Rota secreta (parede #1, elevador, câmara do coletável, parede #2)

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (`_build_z4_secret`)
- Test: `tests/test_z4_secret.gd` + `.tscn`

- [ ] **Step 1: Implementar `_build_z4_secret`**

```gdscript
func _build_z4_secret() -> void:
	# Passagem secreta (paredes), interior x16980–17360, da base até a câmara do coletável (y~360)
	_z2_static("Z4SecretWL", Vector2(16948.0, 1284.0), Vector2(64.0, 1848.0))   # parede esq da passagem
	# (a parede direita da passagem é a parede esquerda do shaft seg1-? ; cobrir o trecho com a parede #1 quebrável)
	# Parede #1 — cracked_wall na face esq do seg1 (x17360–17424), quebra pelo lado do shaft (direita)
	_z4_cracked("Z4Crack1", Vector2(17392.0, 2144.0), Vector2(64.0, 128.0), "", "R")   # break_side "" (qualquer, c/ galerix); detector à direita
	# Elevador (up_only) na passagem
	var elev := preload("res://stages/stage_01/vertical_platform.gd").new()
	elev.name = "Z4SecretElevator"
	elev.up_only = true
	elev.move_distance = 1760.0
	elev.speed = 90.0
	elev.position = Vector2(17170.0, 2180.0)
	var ecs := _z2_shape(Vector2(192.0, 32.0)); elev.add_child(ecs)
	elev.collision_layer = 1; elev.collision_mask = 0
	add_child(elev)
	# Câmara do coletável: piso topo y360, x16800–17380, com BURACO x17000–17200 (encaixe do elevador)
	_z3_static_floor("Z4CollectFloorL", Vector2(16900.0, 392.0), Vector2(200.0, 128.0))  # 16800–17000
	_z3_static_floor("Z4CollectFloorR", Vector2(17290.0, 392.0), Vector2(180.0, 128.0))  # 17200–17380
	_z2_static("Z4CollectCeil", Vector2(17090.0, 232.0), Vector2(580.0, 64.0))
	# Sub-tank
	var col := preload("res://stages/collectible.tscn").instantiate()
	col.set("collectible_type", 1)   # Collectible.Type.SUBTANK
	col.set("stage_id", 1)
	col.set("subtank_index", 0)      # conferir índice livre p/ stage 01
	col.position = Vector2(16900.0, 320.0)
	add_child(col)
	# Parede #2 — entre coletável (esq) e câmara pré-chefe (dir): x17380–17440, quebra SÓ pela esquerda
	_z4_cracked("Z4Crack2", Vector2(17410.0, 392.0), Vector2(60.0, 128.0), "left", "L")
```
Helper:
```gdscript
func _z4_cracked(n: String, center: Vector2, size: Vector2, break_side: String, det_side: String) -> void:
	var w := preload("res://stages/stage_01/cracked_wall.gd").new()
	w.name = n
	w.set("break_side", break_side)
	w.collision_layer = 1; w.collision_mask = 0
	w.position = center
	w.add_child(_z2_shape(size))
	var det := Area2D.new(); det.name = "HitDetector" + det_side
	det.collision_layer = 0; det.collision_mask = 8   # projéteis
	var dx := (size.x * 0.5 + 16.0) * (1.0 if det_side == "R" else -1.0)
	var d := _z2_shape(Vector2(32.0, size.y)); d.position = Vector2(dx, 0)
	det.add_child(d)
	w.add_child(det)
	add_child(w)
```

- [ ] **Step 2: Teste de invariantes do segredo**

`tests/test_z4_secret.gd`:
```gdscript
extends Node
func _ready() -> void:
	var s = load("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(s)
	for i in 4: await get_tree().physics_frame
	var fail := false
	for nm in ["Z4SecretElevator","Z4Crack1","Z4Crack2","Z4CollectFloorL","Z4CollectFloorR"]:
		if s.get_node_or_null(nm) == null:
			print("FAIL: faltou ", nm); fail = true
	var c2 = s.get_node_or_null("Z4Crack2")
	if c2 and c2.get("break_side") != "left":
		print("FAIL: parede #2 deveria quebrar só pela esquerda"); fail = true
	# elevador up_only sobe (após alguns frames a y diminui ou está no topo)
	if fail: get_tree().quit(1)
	else: print("PASS: secret geometry"); get_tree().quit(0)
```

- [ ] **Step 3: Rodar fail→pass**, exit 0.

- [ ] **Step 4: Commit**
```bash
git add stages/stage_01/stage_01_scene.gd tests/test_z4_secret.gd tests/test_z4_secret.tscn
git commit -m "feat(stage01 z4): rota secreta — parede#1, elevador, câmara do sub-tank, parede#2 (galerix)"
```

---

### Task 10: Debug spawns, SVG de zona, bot, web export

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (`_zone_spawn`)
- Modify (regen): `docs/stage_01/zones/*` via `tools/zone_debug_01.tscn`

- [ ] **Step 1: Atualizar `_zone_spawn`**

Trocar os pontos antigos da z4 (zonas 7/8) pros novos:
```gdscript
		7: return Vector2(17520, 1100)   # DEBUG: meio do shaft (seg4)
		8: return Vector2(17520, 420)    # DEBUG: topo do shaft / câmara pré-chefe
		9: return Vector2(17100, 2150)   # DEBUG: base da passagem secreta (com galerix)
```

- [ ] **Step 2: Rodar todos os testes headless da z4**

```bash
for t in test_rising_lava_accel test_crumbling_ledge test_cracked_wall_side test_z4_shaft test_z4_secret; do
  "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/$t.tscn 2>&1 | grep -E "PASS|FAIL"
done
```
Expected: todos `PASS`.

- [ ] **Step 3: Validação do bot**

`"D:/Godot_v4.6.2-stable_win64/...exe" --headless --path . res://stages/stage_01/stage_01.tscn -- stage=1 bot=1 noenemies=1` (ou pela URL web). Conferir log `BOT_DONE` / chegada na arena. Ajustar saliências/larguras se o bot travar (lavas/crumble/elevador ficam parados no modo bot).

- [ ] **Step 4: Regenerar SVG de debug da zona 4**

```bash
"D:/Godot_v4.6.2-stable_win64/...exe" --headless --path . res://tools/zone_debug_01.tscn -- --area=z4
```
Abrir `docs/stage_01/zones/z4.svg` e conferir o layout do shaft/segredo.

- [ ] **Step 5: Web export + reiniciar localhost** (preferência do projeto — ver skill `web-export`).

- [ ] **Step 6: Commit**
```bash
git add stages/stage_01/stage_01_scene.gd docs/stage_01/zones/ export/web/index.html export/web/index.pck
git commit -m "feat(stage01 z4): debug spawns + SVG regen + web export do shaft de wall-jump"
```

---

## Self-review (cobertura do spec)

- Shaft 6 segmentos + larguras variáveis → Task 5 (tabela `_SHAFT_SEGS`).
- Lava única chase + aceleração no terço final → Task 1 + Task 5.
- Espinhos (no_grab+dano), saliências de respiro, crumbling, flyer → Task 2 + Task 6.
- Câmara pré-chefe + corredor (porta/checkpoint/câmera) → Task 7.
- Arena do boss reconstruída (molde stage00, porta lateral, tileset rocha) → Task 4 (remoção) + Task 8.
- Rota secreta (parede#1, elevador up_only, câmara sub-tank, parede#2 só-esquerda, galerix) → Task 3 + Task 9.
- Remoção da escada coupled/cratera/arena antiga → Task 4.
- Debug spawns + SVG + bot + web export → Task 10.

**Pontos a confirmar na implementação (grep antes de codar):** path real do `EnemyFlyer` e do `Ignarath` (`.tscn`), assinatura de `CharacterBase.take_damage`, props exatas do `CorridorSection` (comparar com `_corr3` do stage00), `subtank_index` livre pro stage 01, e se `door_tex` é obrigatório no `CorridorSection`.
