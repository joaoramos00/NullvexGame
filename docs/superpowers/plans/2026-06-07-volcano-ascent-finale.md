# Final em Ascensão de Vulcão (stage_01) — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transformar o fim da stage_01 numa ascensão de vulcão na zona 4 (escada-chase → patamar → escada-coupled → topo+checkpoint → cratera → boss), mantendo a zona 3 intacta e removendo o shaft de wall-kick e o Corridor2.

**Architecture:** Tudo construído em runtime no `stage_01_scene.gd` (padrão `_build_zone2/_build_zone3`), reaproveitando `_z3_static_floor` (degraus/patamares) e `_z3_floor_platform` (cratera com buraco). A lava ganha modos (`tide`/`chase`/`coupled`) no `rising_lava.gd`, todos congelando embaixo no modo bot. Validação por StageBot (lava congelada → valida pulos) com calibração iterativa via logs `BOT_*`.

**Tech Stack:** Godot 4.6.2, GDScript. Export web + localhost:8080 + Playwright MCP para validação visual/bot. Godot exe: `D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe`.

**Constantes de física (não mudar):** `SPEED=200`, `JUMP_VELOCITY=-480`, `GRAVITY=980` → pulo máx ≈118px↑ / ~196px→. Todo degrau deve respeitar isso. Tile=64 game units, `_SRC_TS=32`.

---

## Estrutura de arquivos

- **Modificar** `stages/stage_01/rising_lava.gd` — adicionar modos `tide`/`chase`/`coupled`.
- **Modificar** `stages/stage_01/stage_01_scene.gd` — remover nós do shaft/Corridor2, abrir vão no BossCeil, novo `_build_zone4()`, novos `_zone_spawn` de debug.
- **Modificar** `tests/bot/paths/stage_01.gd` — segmentos do bot para a zona 4 (substituem os stubs de zona 4/boss).
- **Criar** `tests/test_rising_lava.gd` + `tests/test_rising_lava.tscn` — teste headless da lógica de modos da lava.

Convenção dos testes (CLAUDE.md): `extends Node` + `.tscn` associada; rodar com `--headless ... res://tests/<x>.tscn`. NÃO usar `extends SceneTree`.

---

### Task 1: Modos da lava (`rising_lava.gd`)

**Files:**
- Modify: `stages/stage_01/rising_lava.gd`
- Create: `tests/test_rising_lava.gd`
- Create: `tests/test_rising_lava.tscn`

- [ ] **Step 1: Escrever o teste headless que falha**

Criar `tests/test_rising_lava.gd`:

```gdscript
extends Node
# Testa a lógica de modos da rising_lava sem física/_player real.

const RisingLava := preload("res://stages/stage_01/rising_lava.gd")

func _ready() -> void:
	test_chase_rises_to_cap()
	test_coupled_only_rises()
	print("ALL TESTS PASSED")
	get_tree().quit(0)

func test_chase_rises_to_cap() -> void:
	var l := Area2D.new()
	l.set_script(RisingLava)
	add_child(l)
	l.mode = "chase"
	l.low_y = 2000.0
	l.cap_y = 1500.0
	l.rise_speed = 100.0
	l.position.y = 2000.0
	l.activate()
	# 10s a 100px/s sobe 1000px, mas para no cap (1500).
	for i in 700:
		l._tick(1.0 / 60.0)
	assert(absf(l.position.y - 1500.0) < 1.0, "chase deve parar em cap_y")
	print("PASS: chase_rises_to_cap")

func test_coupled_only_rises() -> void:
	var l := Area2D.new()
	l.set_script(RisingLava)
	add_child(l)
	l.mode = "coupled"
	l.coupled_offset = 200.0
	l.position.y = 2000.0
	# player a 1700 → alvo 1900 (sobe de 2000→1900).
	l._set_coupled_target(1700.0)
	l._tick(1.0)
	assert(l.position.y <= 1901.0, "coupled deve subir até player+offset")
	# player desce p/ 1850 → alvo 2050; NÃO desce (fica em 1900).
	l._set_coupled_target(1850.0)
	l._tick(1.0)
	assert(absf(l.position.y - 1900.0) < 1.0, "coupled nunca desce")
	print("PASS: coupled_only_rises")
```

Criar `tests/test_rising_lava.tscn`:

```
[gd_scene format=3]

[ext_resource type="Script" path="res://tests/test_rising_lava.gd" id="1_script"]

[node name="TestRisingLava" type="Node"]
script = ExtResource("1_script")
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_rising_lava.tscn`
Expected: FALHA (script `rising_lava.gd` não tem `mode`/`cap_y`/`activate`/`_tick`/`_set_coupled_target`).

- [ ] **Step 3: Reescrever `rising_lava.gd` com modos**

Substituir TODO o conteúdo de `stages/stage_01/rising_lava.gd` por:

```gdscript
# stages/stage_01/rising_lava.gd
# Lava instant-kill com 3 modos:
#   tide    — oscila low_y ↔ high_y (maré da zona 3).
#   chase   — após activate(), sobe contínua (rise_speed) até cap_y; não para.
#   coupled — acompanha a altura máxima do player (player.y+coupled_offset); só sobe.
# Em TODOS os modos: instant-kill no contato e CONGELA em low_y no modo bot.
extends Area2D

@export var mode: String = "tide"        # "tide" | "chase" | "coupled"
@export var low_y:  float = 2720.0        # superfície em repouso / congelada (bot)
@export var high_y: float = 2500.0        # tide: pico
@export var speed:  float = 70.0          # tide: px/s
@export var pause_time: float = 1.2       # tide: pausa nos extremos
@export var rise_speed: float = 80.0      # chase: px/s subindo
@export var cap_y: float = 1500.0         # chase: teto (para de subir)
@export var coupled_offset: float = 220.0 # coupled: distância abaixo do player

var _going_up: bool = true
var _pause: float = 0.0
var _active: bool = false                 # chase: ligada?
var _coupled_target: float = 0.0
var _player: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	position.y = low_y
	if mode == "coupled":
		_coupled_target = low_y

func set_player(p: Node2D) -> void:
	_player = p

func activate() -> void:
	_active = true

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		(body as CharacterBase).kill()

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return                            # bot: lava parada embaixo (valida o caminho)
	if mode == "coupled" and is_instance_valid(_player):
		_set_coupled_target(_player.global_position.y)
	_tick(delta)

# Lógica pura (testável headless), separada do _physics_process.
func _tick(delta: float) -> void:
	match mode:
		"tide":   _tick_tide(delta)
		"chase":  _tick_chase(delta)
		"coupled": _tick_coupled(delta)

func _tick_tide(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		return
	var tgt := high_y if _going_up else low_y
	position.y = move_toward(position.y, tgt, speed * delta)
	if absf(position.y - tgt) < 0.5:
		_going_up = not _going_up
		_pause = pause_time

func _tick_chase(delta: float) -> void:
	if not _active:
		return
	position.y = move_toward(position.y, cap_y, rise_speed * delta)

func _set_coupled_target(player_y: float) -> void:
	_coupled_target = player_y + coupled_offset

func _tick_coupled(_delta: float) -> void:
	# só sobe (y menor = mais alto): nunca aumenta position.y.
	position.y = minf(position.y, _coupled_target)
```

- [ ] **Step 4: Rodar e ver passar**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_rising_lava.tscn`
Expected: `ALL TESTS PASSED`.

- [ ] **Step 5: Confirmar que a maré (zona 3) ainda funciona (modo tide é o default)**

A zona 3 usa `_z3_rising_lava` que cria a Area2D com o script e seta `low_y`/`high_y`. Como `mode` default é `"tide"`, o comportamento é o mesmo de antes. Verificar em `stage_01_scene.gd` que `_z3_rising_lava` NÃO seta `mode` (ou seta `"tide"`).

- [ ] **Step 6: Commit**

```bash
git add stages/stage_01/rising_lava.gd tests/test_rising_lava.gd tests/test_rising_lava.tscn
git commit -m "feat(stage01): modos tide/chase/coupled na rising_lava + teste headless"
```

---

### Task 2: Remover shaft + Corridor2 e abrir vão no teto do boss

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd:14-33` (função `_ready`)

- [ ] **Step 1: Adicionar remoção dos nós no `_ready()`**

Em `stage_01_scene.gd`, dentro de `_ready()` (depois de `super._ready()` e antes de `_build_zone2()`), adicionar:

```gdscript
	# Final em vulcão: fora o shaft de wall-kick e o Corridor2 (substituídos pela
	# ascensão da zona 4). Abre um vão no teto do boss p/ a queda da cratera entrar.
	for n in ["ShaftUpWallL", "ShaftUpWallR", "ShaftUpP1", "ShaftUpP2", "ShaftUpP3",
			"ShaftUpP4", "ShaftUpP5", "Corridor2",
			"Z4Floor", "Z4Ceil", "Z4Lava", "Z4Plat1", "Z4Plat2", "Z4Plat3",
			"Z4MovingPlat", "Z4Grunt1", "Z4Grunt2", "Z4Flyer1"]:
		var node := get_node_or_null(n)
		if node:
			node.queue_free()
	_open_boss_ceiling_gap()
```

E adicionar o método (perto dos outros helpers da cena):

```gdscript
# Abre um vão no teto da câmara do boss (BossCeil) na coluna da cratera, p/ a queda
# da cratera entrar. Substitui o BossCeil único por 2 segmentos com um vão no meio-dir.
func _open_boss_ceiling_gap() -> void:
	var ceil_node := get_node_or_null("BossCeil")
	if ceil_node == null:
		return
	# BossCeil atual: centro (21184, 448), tamanho (2816, 64) → x19776–22592.
	var gap_cx := 21000.0   # coluna da cratera
	var gap_w := 256.0
	var left_x := 19776.0
	var right_x := 22592.0
	var top := 416.0
	var h := 64.0
	ceil_node.queue_free()
	# segmento esquerdo: left_x → (gap_cx - gap_w/2)
	var lw := (gap_cx - gap_w * 0.5) - left_x
	var lb := _z2_static("BossCeilL", Vector2(left_x + lw * 0.5, top + h * 0.5), Vector2(lw, h))
	lb.set_meta("tileset_override", _Z2_FLOOR_TILE)
	# segmento direito: (gap_cx + gap_w/2) → right_x
	var rw := right_x - (gap_cx + gap_w * 0.5)
	var rb := _z2_static("BossCeilR", Vector2((gap_cx + gap_w * 0.5) + rw * 0.5, top + h * 0.5), Vector2(rw, h))
	rb.set_meta("tileset_override", _Z2_FLOOR_TILE)
```

- [ ] **Step 2: Exportar e checar que não há erro de script**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" export/web/index.html`
Expected: `[ DONE ] savepack` sem erros de parse.

- [ ] **Step 3: Verificar via teste headless que a cena carrega**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn`
Expected: `All StageManager tests passed` (sem erro de carregamento de stage_01).

- [ ] **Step 4: Commit**

```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01): remove shaft wall-kick + Corridor2; abre vão no teto do boss"
```

---

### Task 3: Escada-chase (lava perseguindo) — geometria + lava + gatilho

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (novo `_build_zone4`, chamado no `_ready`)

- [ ] **Step 1: Chamar `_build_zone4()` no `_ready()`**

Logo após `_build_zone3()`:

```gdscript
	_build_zone4()
```

- [ ] **Step 2: Helpers de escada + lava de modo**

Adicionar em `stage_01_scene.gd`:

```gdscript
const _RISING_LAVA_MODE := preload("res://stages/stage_01/rising_lava.gd")

# Cria uma lava de modo (chase/coupled). low_y = superfície inicial/congelada.
func _z4_lava(n: String, mode: String, center_x: float, low_y: float, width: float,
		height: float) -> Area2D:
	var a := Area2D.new()
	a.name = n
	a.set_script(_RISING_LAVA_MODE)
	a.collision_layer = 0
	a.collision_mask = 2
	a.set("mode", mode)
	a.set("low_y", low_y)
	a.position = Vector2(center_x, low_y)
	var cs := _z2_shape(Vector2(width, height))
	cs.position = Vector2(0, height * 0.5)   # topo da hitbox no y do nó (= superfície)
	a.add_child(cs)
	add_child(a)
	return a

# Escada ascendente de plataformas-degrau (slabs com cara de chão). Cada degrau sobe
# `dy` (≤118) e anda `dx` (≤196) em relação ao anterior. Retorna o topo do último.
func _z4_stair(prefix: String, x0: float, top0: float, dx: float, dy: float,
		count: int, step_w: float = 256.0) -> Vector2:
	var x := x0
	var top := top0
	for i in count:
		_z3_static_floor("%s%d" % [prefix, i], Vector2(x + step_w * 0.5, top + 64.0),
			Vector2(step_w, 128.0))   # topo em `top`
		x += dx
		top -= dy
	return Vector2(x, top + dy)   # posição do último degrau criado
```

- [ ] **Step 3: Construir a base + escada-chase + lava-chase + gatilho no `_build_zone4()`**

```gdscript
func _build_zone4() -> void:
	# Base: pequeno piso de transição após a Z3Exit (topo 2624).
	_z3_static_floor("Z4Base", Vector2(16320, 2688), Vector2(320, 128))  # x16160–16480

	# Escada-chase: 10 degraus subindo (dy=104 ≤118, dx=192 ≤196) de y2624 → ~1584.
	_z4_stair("Z4ChaseStep", 16480.0, 2520.0, 192.0, 104.0, 10)  # topo0 2520 (1º acima da base)

	# Lava-chase: sobe contínua da base até o teto (cap_y = piso do patamar do meio).
	var chase := _z4_lava("Z4ChaseLava", "chase", 17400.0, 2820.0, 3600.0, 1200.0)
	chase.set("rise_speed", 80.0)
	chase.set("cap_y", 1640.0)   # logo abaixo do patamar do meio (topo 1584)

	# Gatilho: ativa a lava-chase quando o player entra na base da subida.
	var trig := Area2D.new()
	trig.name = "Z4ChaseTrigger"
	trig.collision_layer = 0
	trig.collision_mask = 2
	trig.position = Vector2(16480, 2560)
	var tcs := _z2_shape(Vector2(64, 256))
	trig.add_child(tcs)
	add_child(trig)
	trig.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBase:
			chase.call("activate"))
```

- [ ] **Step 4: Spawn de debug da base da z4**

Em `_zone_spawn(zone)`, ajustar o caso `4`:

```gdscript
		4: return Vector2(16320, 2480)   # base da z4 (escada-chase)
```

- [ ] **Step 5: Exportar e ver a escada-chase (visual)**

Run export (Task 2 Step 2). Abrir `http://localhost:8080/?stage=01&bot=1&noenemies=1&zone=4&v=NN`, esperar ~6s, screenshot. Conferir: base + escada subindo + (lava congelada baixa no bot). Sem erro no console (só o aviso de orientação).

- [ ] **Step 6: Commit**

```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01): zona 4 base + escada-chase + lava perseguindo + gatilho"
```

---

### Task 4: Patamar do meio (respiro)

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (`_build_zone4`)

- [ ] **Step 1: Adicionar o patamar ao fim de `_build_zone4()`**

Após a escada-chase:

```gdscript
	# Patamar do meio (respiro, topo 1584, acima do cap_y 1640 da lava-chase).
	_z3_static_floor("Z4MidA", Vector2(18560, 1648), Vector2(640, 128))  # x18240–18880
	_z3_static_floor("Z4MidB", Vector2(19200, 1648), Vector2(640, 128))  # x18880–19520
```

- [ ] **Step 2: Spawn de debug do patamar**

Em `_zone_spawn`, adicionar (reusar um número livre, ex. 7):

```gdscript
		7: return Vector2(18560, 1500)   # DEBUG: patamar do meio da z4
```

- [ ] **Step 3: Exportar e conferir o patamar**

Export + `?stage=01&bot=1&noenemies=1&zone=7&v=NN` + screenshot. Conferir patamar largo seguro acima da lava.

- [ ] **Step 4: Commit**

```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01): patamar de respiro entre as duas subidas da z4"
```

---

### Task 5: Escada-coupled (lava acoplada)

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (`_build_zone4`)

- [ ] **Step 1: Adicionar escada-coupled + lava-coupled**

Após o patamar. IMPORTANTE: a lava-coupled NÃO pode cobrir a coluna da cratera
(x~21000), senão o player bate nela ao cair. Ela termina em ~x20600; a cratera fica
à direita disso (Task 6/7).

```gdscript
	# Escada-coupled: 10 degraus de y1584 → ~544 (dy=104, dx=96). Último ~x20384, topo 544.
	_z4_stair("Z4CoupStep", 19520.0, 1480.0, 96.0, 104.0, 10)

	# Lava-coupled: acompanha a altura do player; só sobe; congela no bot. X LIMITADA
	# ao trecho da escada (x18800–20600), longe da cratera (21000).
	var coup := _z4_lava("Z4CoupLava", "coupled", 19700.0, 1820.0, 1800.0, 1400.0)
	coup.set("coupled_offset", 240.0)
	if is_instance_valid(_player):
		coup.call("set_player", _player)
```

- [ ] **Step 2: Spawn de debug do topo da escada-coupled**

```gdscript
		8: return Vector2(20900, 600)   # DEBUG: topo da escada-coupled
```

- [ ] **Step 3: Exportar e conferir a escada-coupled**

Export + `?stage=01&bot=1&noenemies=1&zone=8&v=NN` + screenshot. Conferir a escada subindo do patamar até o topo (~y544).

- [ ] **Step 4: Commit**

```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01): escada-coupled + lava acoplada à altura do player"
```

---

### Task 6: Topo + checkpoint + cura

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (`_build_zone4`)

- [ ] **Step 1: Adicionar topo, checkpoint e cura**

Após a escada-coupled:

```gdscript
	# Topo: patamar seguro que vai do fim da escada (~x20384) até a borda da cratera
	# (x21000). Acima da lava-coupled (que termina em 20600). Checkpoint + cura.
	_z3_static_floor("Z4Top", Vector2(20692, 608), Vector2(616, 128))   # x20384–21000, topo 544

	var cp := preload("res://stages/checkpoint.tscn").instantiate()
	cp.name = "Z4Checkpoint"
	cp.position = Vector2(20600, 480)
	cp.set("checkpoint_index", 2)
	add_child(cp)

	# Cura ao chegar no topo (o nó Checkpoint só salva; a cura era do corredor).
	var heal := Area2D.new()
	heal.name = "Z4TopHeal"
	heal.collision_layer = 0
	heal.collision_mask = 2
	heal.position = Vector2(20692, 480)
	var hcs := _z2_shape(Vector2(616, 160))
	heal.add_child(hcs)
	add_child(heal)
	var healed := [false]
	heal.body_entered.connect(func(b: Node) -> void:
		if not healed[0] and b is CharacterBase:
			healed[0] = true
			(b as CharacterBase).heal((b as CharacterBase).max_hp))
```

(Obs.: `[false]` num Array contorna a captura por valor de lambda em GDScript — ver `reference_gdscript_lambda_capture`.)

- [ ] **Step 2: Exportar e conferir o topo + checkpoint**

Export + `?stage=01&bot=1&noenemies=1&zone=8&v=NN` (spawn no topo da coupled, perto do topo) + screenshot. Conferir patamar do topo.

- [ ] **Step 3: Commit**

```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01): topo da z4 com checkpoint (índice 2) + cura"
```

---

### Task 7: Cratera (buraco no fim) + conexão com a arena do boss

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (`_build_zone4`)

A cratera é a **borda direita do `Z4Top`** (x21000): o chão acaba ali e abaixo está o vão
do `BossCeil` (gap em 21000±128, Task 2) → a queda entra na arena. Não há peça/colisão
nova — é o vão. A lava-coupled (termina em x20600) não alcança a cratera, então a queda
é segura.

- [ ] **Step 1: Lip visual da cratera (opcional, estético)**

Para a borda da cratera "ler" como boca de vulcão, desenhar um pequeno lip de lava à
direita do `Z4Top`, sem colisão (só visual), sobre o vão:

```gdscript
	# Lip visual da cratera (sem colisão): borda de lava na boca, sobre o vão do BossCeil.
	var lip := Sprite2D.new()
	lip.name = "Z4CraterLip"
	var lip_tex: Texture2D = load("res://stages/stage_01/lava_top.png")
	if lip_tex:
		lip.texture = lip_tex
		lip.centered = false
		lip.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		lip.region_enabled = true
		lip.region_rect = Rect2(0, 0, 128, 32)   # ~256px no mundo (scale 2)
		lip.scale = Vector2(2, 2)
		lip.position = Vector2(21000, 528)
		lip.material = ShaderMaterial.new()
		(lip.material as ShaderMaterial).shader = _LAVA_SHADER
		add_child(lip)
```

- [ ] **Step 2: Garantir alinhamento cratera ↔ vão do BossCeil ↔ arena**

`Z4Top` termina em x21000; o vão do `BossCeil` é 21000±128 (20872–21128, Task 2); a
`BossFloor` (y960) está embaixo. Andar até 21000 e cair = atravessa o vão e pousa na
arena. Se o vão e a borda não baterem, ajustar `gap_cx`/`gap_w` (Task 2) p/ alinhar com
x21000.

- [ ] **Step 3: Exportar e conferir a queda na arena**

Export + `?stage=01&noenemies=1&zone=8&v=NN`; com teclado real (Playwright `keyboard.down('d')`) andar até a borda (x21000) e cair; screenshot da arena do boss. Confirmar pouso na `BossFloor`/`BossPlat` sem prender na borda nem bater em lava.
Se prender/morrer: ajustar `gap_w` (Task 2) e/ou a borda direita do `Z4Top` (Task 6).

- [ ] **Step 4: Commit**

```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01): cratera no cume liga a escada à arena do boss (queda)"
```

---

### Task 8: Caminho do bot — escada-chase + patamar

**Files:**
- Modify: `tests/bot/paths/stage_01.gd` (substituir os stubs de zona 4/boss)

- [ ] **Step 1: Substituir o bloco da zona 4 / boss**

Trocar os stubs:

```gdscript
		# ── Zona 4 ──
		{"t": "zone", "n": 4},
		{"t": "screenshot", "label": "07_z4_spawn"},
		# (a calibrar)

		# ── Boss ──
		{"t": "zone", "n": 5},
		{"t": "screenshot", "label": "09_boss"},
```

por (coordenadas iniciais; calibrar no Step 2 lendo `BOT_STUCK`):

```gdscript
		# ── Zona 4 "Ascensão do Vulcão": base → escada-chase → patamar → escada-coupled
		# → topo(checkpoint) → cratera → cai no boss. Lavas congelam baixo no bot. ──
		{"t": "zone", "n": 4},
		{"t": "screenshot", "label": "07_z4_base"},
		# Escada-chase: 10 degraus topo0 2520, dx192/dy104. Centro do degrau i ≈ x0+128+i*192.
		{"t": "jump_to", "x": 16608.0, "jump_x": 16480.0},   # base → degrau 0
		{"t": "jump_to", "x": 16800.0, "jump_x": 16700.0},   # → degrau 1
		{"t": "jump_to", "x": 16992.0, "jump_x": 16892.0},   # → degrau 2
		{"t": "jump_to", "x": 17184.0, "jump_x": 17084.0},   # → degrau 3
		{"t": "jump_to", "x": 17376.0, "jump_x": 17276.0},   # → degrau 4
		{"t": "screenshot", "label": "08_z4_chase_mid"},
		{"t": "jump_to", "x": 17568.0, "jump_x": 17468.0},   # → degrau 5
		{"t": "jump_to", "x": 17760.0, "jump_x": 17660.0},   # → degrau 6
		{"t": "jump_to", "x": 17952.0, "jump_x": 17852.0},   # → degrau 7
		{"t": "jump_to", "x": 18144.0, "jump_x": 18044.0},   # → degrau 8
		{"t": "jump_to", "x": 18336.0, "jump_x": 18236.0},   # → degrau 9 (último)
		{"t": "walk_to", "x": 18800.0},                       # patamar do meio
		{"t": "screenshot", "label": "09_z4_patamar"},
		# (escada-coupled + topo + cratera + boss adicionados na Task 9)
```

- [ ] **Step 2: Calibrar a escada-chase com o bot**

Export. Abrir `http://localhost:8080/?stage=01&bot=1&noenemies=1&zone=4&v=NN`, esperar ~14s, ler console (`browser_console_messages`). Esperado: `07_z4_base` → `08_z4_chase_mid` → `09_z4_patamar` sem `BOT_STUCK`.
Se `BOT_STUCK:jump_to@X,Y`: ajustar o `jump_x`/`x` do degrau correspondente (lembrar: pulo ≤118↑/≤196→). Repetir até passar o patamar.

- [ ] **Step 3: Commit**

```bash
git add tests/bot/paths/stage_01.gd
git commit -m "feat(bot): escada-chase da zona 4 calibrada até o patamar"
```

---

### Task 9: Caminho do bot — escada-coupled + cratera + boss (BOT_DONE)

**Files:**
- Modify: `tests/bot/paths/stage_01.gd`

- [ ] **Step 1: Acrescentar os segmentos finais**

Após o `screenshot 09_z4_patamar`, antes de fechar o array, adicionar:

```gdscript
		# Escada-coupled: 10 degraus topo0 1480, dx96/dy104. Centro i = 19648+i*96.
		{"t": "jump_to", "x": 19648.0, "jump_x": 19550.0},   # patamar → degrau 0
		{"t": "jump_to", "x": 19744.0, "jump_x": 19644.0},   # → degrau 1
		{"t": "jump_to", "x": 19840.0, "jump_x": 19740.0},   # → degrau 2
		{"t": "jump_to", "x": 19936.0, "jump_x": 19836.0},   # → degrau 3
		{"t": "jump_to", "x": 20032.0, "jump_x": 19932.0},   # → degrau 4
		{"t": "screenshot", "label": "10_z4_coup_mid"},
		{"t": "jump_to", "x": 20128.0, "jump_x": 20028.0},   # → degrau 5
		{"t": "jump_to", "x": 20224.0, "jump_x": 20124.0},   # → degrau 6
		{"t": "jump_to", "x": 20320.0, "jump_x": 20220.0},   # → degrau 7
		{"t": "jump_to", "x": 20416.0, "jump_x": 20316.0},   # → degrau 8
		{"t": "jump_to", "x": 20512.0, "jump_x": 20412.0},   # → degrau 9 (último)
		{"t": "walk_to", "x": 20700.0, "land": true},        # sobe no Z4Top (topo+checkpoint)
		{"t": "screenshot", "label": "11_z4_top"},
		{"t": "walk_to", "x": 21010.0},                       # anda até a borda da cratera (x21000)
		{"t": "drop", "dir": 1.0},                            # cai pela boca da cratera → arena
		{"t": "wait", "seconds": 1.5},
		{"t": "screenshot", "label": "12_boss"},
```

(Remover os antigos marcadores `{"t":"zone","n":5}` + `09_boss` se ainda existirem.)

- [ ] **Step 2: Calibrar coupled + cratera + boss**

Export. `?stage=01&bot=1&noenemies=1&zone=4&v=NN`, esperar ~30s, ler console. Alvo: sequência completa de screenshots até `12_boss` e `BOT_DONE`, sem `BOT_STUCK` nem morte.
Ajustar `jump_x`/`x` dos degraus que travarem; ajustar o `drop` se o player não cair na arena (pode precisar de `walk_to` mais à direita antes do drop, ou ajustar a cratera/vão).

- [ ] **Step 3: Rodar a fase inteira do início (regressão da z3)**

`?stage=01&bot=1&noenemies=1&zone=1&v=NN` (sem pular zona) — esperar ~60s, ler console. Confirmar que zonas 1→2→3→4→boss fluem e termina em `BOT_DONE`. (Se a z3 quebrou, revisar a conexão z3→z4 na base.)

- [ ] **Step 4: Commit**

```bash
git add tests/bot/paths/stage_01.gd
git commit -m "feat(bot): ascensão da zona 4 validada de ponta a ponta (BOT_DONE)"
```

---

### Task 10: Export final + verificação visual + lava em movimento

**Files:** nenhum (verificação)

- [ ] **Step 1: Verificar a lava em movimento (sem bot)**

`?stage=01&noenemies=1&zone=4&v=NN` (sem bot → lava ativa). Com teclado real, subir a escada-chase: confirmar visualmente que a lava-chase SOBE atrás do player (perseguição). Screenshot.

- [ ] **Step 2: Verificar a coupled (sem bot)**

`?stage=01&noenemies=1&zone=7&v=NN`, subir a escada-coupled: confirmar que a lava acompanha a altura e NÃO desce ao parar. Screenshot.

- [ ] **Step 3: Rodar os testes headless**

Run:
`"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_rising_lava.tscn`
`"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn`
Expected: ambos `ALL TESTS PASSED` / `All ... tests passed`.

- [ ] **Step 4: Export web final + restart localhost** (memória `feedback_web_export`)

Export release + reiniciar o servidor em 8080.

- [ ] **Step 5: Commit (se houver ajustes) e fim**

```bash
git add -A
git commit -m "chore(stage01): ajustes finais da ascensão do vulcão + verificação"
```

---

## Notas de execução

- **Calibração iterativa**: as coordenadas das escadas/bot são pontos de partida; o tuning real é via `BOT_STUCK`/screenshots, como nas zonas 1–3. Orçamento de pulo é a restrição dura (≤118↑/≤196→).
- **Limpeza**: apagar os PNGs de screenshot soltos da raiz após cada verificação (não commitar).
- **Lava no bot**: se algum degrau "sumir" sob lava no bot, conferir que a Area2D respectiva tem `low_y` baixo o suficiente e o early-return `DebugBoot.bot_enabled`.
