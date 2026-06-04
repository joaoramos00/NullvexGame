# StageBot — Validador Automático de Fase — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Um bot in-engine que atravessa uma fase via `Input.action_press` e marca pontos de screenshot, com um runner Playwright que fotografa o build web e emite PASS/FAIL.

**Architecture:** O papel de **dirigir** é GDScript dentro do jogo (funciona no web, diferente do CDP); o de **observar/fotografar** é Playwright. Um autoload `DebugBoot` lê params de URL e boota direto numa fase com flags. As fases removem combatentes em modo `no_enemies`. O `StageBot` consome um caminho por fase (lista de segmentos de alto nível) e imprime marcadores no console que o runner Playwright escuta.

**Tech Stack:** Godot 4.6.2 / GDScript (motor + bot), Node.js + Playwright (runner). Testes headless no padrão do projeto (`extends Node` + `.tscn`).

**Spec:** `docs/superpowers/specs/2026-06-03-stage-validation-bot-design.md`

---

## File Structure

| Arquivo | Responsabilidade |
|---|---|
| `tests/bot/debug_boot.gd` | Autoload: lê params de URL/cmdline, boota a fase, expõe flags `bot_enabled`/`no_enemies`/`stage_id`. |
| `tests/bot/stage_bot.gd` | Autopilot: executa o caminho da fase via `Input`, imprime marcadores de console, detecta travamento. |
| `tests/bot/paths/stage_00.gd` | Dados do caminho da fase 00 (segmentos). |
| `tests/bot/paths/stage_01.gd` | Dados do caminho da fase 01. |
| `tests/bot/run_stage_bot.mjs` | Runner Playwright: abre URL, escuta console, fotografa, grava PASS/FAIL. |
| `tests/bot/package.json` | Dependência Playwright pro runner. |
| `tests/test_debug_boot.gd` + `.tscn` | Testa `DebugBoot.parse_params`. |
| `tests/test_no_enemies.gd` + `.tscn` | Testa remoção de combatentes na stage_01. |
| `tests/test_stage_bot.gd` + `.tscn` | Testa lógica de segmentos/travamento do StageBot. |
| `stages/stage_scene.gd` (modificar) | Remove combatentes + anexa bot quando flags ligadas (fases 01-08). |
| `stages/stage_00/stage_00_scene.gd` (modificar) | Gate dos triggers de miniboss/boss + anexa bot. |
| `project.godot` (modificar) | Registrar autoload `DebugBoot`. |
| `.gitignore` (modificar) | Ignorar `tests/bot/shots/` e `tests/bot/results/`. |

Convenção de chamada de testes (igual ao resto do projeto):
```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/<nome>.tscn
```

---

## Task 1: DebugBoot — parsing de parâmetros (autoload)

**Files:**
- Create: `tests/bot/debug_boot.gd`
- Create: `tests/test_debug_boot.gd`
- Create: `tests/test_debug_boot.tscn`
- Modify: `project.godot` (seção `[autoload]`)

- [ ] **Step 1: Write the failing test**

`tests/test_debug_boot.gd`:
```gdscript
# tests/test_debug_boot.gd
extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	_test_empty()
	_test_basic()
	_test_leading_question_mark()
	_test_flag_without_value()
	_print_results()
	get_tree().quit()

func _assert(cond: bool, msg: String) -> void:
	if cond: _passed += 1; print("  PASS: " + msg)
	else:    _failed += 1; print("  FAIL: " + msg)

func _test_empty() -> void:
	var d := preload("res://tests/bot/debug_boot.gd").parse_params("")
	_assert(d.is_empty(), "query vazia → dict vazio")

func _test_basic() -> void:
	var d := preload("res://tests/bot/debug_boot.gd").parse_params("stage=00&bot=1&noenemies=1")
	_assert(d.get("stage") == "00", "stage parseado")
	_assert(d.get("bot") == "1", "bot parseado")
	_assert(d.get("noenemies") == "1", "noenemies parseado")

func _test_leading_question_mark() -> void:
	var d := preload("res://tests/bot/debug_boot.gd").parse_params("?stage=01")
	_assert(d.get("stage") == "01", "remove '?' inicial")

func _test_flag_without_value() -> void:
	var d := preload("res://tests/bot/debug_boot.gd").parse_params("bot")
	_assert(d.has("bot") and d.get("bot") == "", "chave sem valor vira string vazia")

func _print_results() -> void:
	print("\n=== %d passed, %d failed ===" % [_passed, _failed])
```

`tests/test_debug_boot.tscn`:
```
[gd_scene format=3 uid="uid://test_debug_boot"]

[ext_resource type="Script" path="res://tests/test_debug_boot.gd" id="1_script"]

[node name="TestDebugBoot" type="Node"]
script = ExtResource("1_script")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_debug_boot.tscn`
Expected: FAIL — `debug_boot.gd` não existe (erro de preload).

- [ ] **Step 3: Write minimal implementation**

`tests/bot/debug_boot.gd`:
```gdscript
# tests/bot/debug_boot.gd — autoload "DebugBoot"
extends Node

var bot_enabled: bool = false
var no_enemies:  bool = false
var stage_id:    int  = -1
var active_char: String = "zael"
var _booted: bool = false

static func parse_params(query: String) -> Dictionary:
	var out := {}
	var q := query.lstrip("?")
	if q == "":
		return out
	for pair in q.split("&", false):
		var kv := pair.split("=", true, 1)
		var key: String = kv[0]
		var val: String = kv[1] if kv.size() > 1 else ""
		if key != "":
			out[key] = val
	return out

func _ready() -> void:
	var params := parse_params(_get_query_string())
	if not params.has("stage"):
		return  # inerte — jogo inicia normal pelo título
	stage_id    = int(params.get("stage", "-1"))
	bot_enabled = params.get("bot", "0") == "1"
	no_enemies  = params.get("noenemies", "0") == "1"
	active_char = params.get("char", "zael")
	call_deferred("_boot")

func _get_query_string() -> String:
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("window.location.search", true))
	var parts := PackedStringArray()
	for arg in OS.get_cmdline_user_args():
		parts.append(arg.lstrip("-"))
	return "&".join(parts)

func _boot() -> void:
	pass  # preenchido na Task 2
```

Registrar o autoload — em `project.godot`, dentro de `[autoload]`, após a linha `AudioLibrary=...`:
```
DebugBoot="*res://tests/bot/debug_boot.gd"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_debug_boot.tscn`
Expected: PASS — `5 passed, 0 failed` (ou mais conforme asserts).

- [ ] **Step 5: Commit**

```bash
git add tests/bot/debug_boot.gd tests/test_debug_boot.gd tests/test_debug_boot.tscn project.godot
git commit -m "feat(bot): DebugBoot autoload + parsing de params de URL"
```

---

## Task 2: DebugBoot — boot direto na fase

**Files:**
- Modify: `tests/bot/debug_boot.gd` (função `_boot`)

Sem teste headless dedicado (troca de cena é validada na integração da Task 9). Implementação direta.

- [ ] **Step 1: Implementar `_boot`**

Substituir `func _boot() -> void: pass` por:
```gdscript
func _boot() -> void:
	if _booted or stage_id < 0:
		return
	_booted = true
	GameManager.reset()
	GameManager.set_active_character(active_char)
	StageManager.current_stage_id = stage_id
	var path := "res://stages/stage_%02d/stage_%02d.tscn" % [stage_id, stage_id]
	if not ResourceLoader.exists(path):
		push_error("DebugBoot: cena inexistente %s" % path)
		return
	get_tree().change_scene_to_file(path)
```

A fase, no seu `_ready`, é quem anexa o `StageBot` (Tasks 4 e 6) — assim o player já existe quando o bot sobe.

- [ ] **Step 2: Verificar que o projeto ainda abre normal (sem params)**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit-after 30`
Expected: abre e fecha sem erro de `DebugBoot` (autoload inerte sem `stage`). Pode haver logs normais do jogo.

- [ ] **Step 3: Commit**

```bash
git add tests/bot/debug_boot.gd
git commit -m "feat(bot): DebugBoot boota direto na fase via change_scene"
```

---

## Task 3: Remoção de combatentes nas fases 01-08

**Files:**
- Modify: `stages/stage_scene.gd` (função `_ready`)
- Create: `tests/test_no_enemies.gd`
- Create: `tests/test_no_enemies.tscn`

- [ ] **Step 1: Write the failing test**

`tests/test_no_enemies.gd`:
```gdscript
# tests/test_no_enemies.gd
extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	await _test_enemies_removed()
	await _test_enemies_present_by_default()
	_print_results()
	get_tree().quit()

func _assert(cond: bool, msg: String) -> void:
	if cond: _passed += 1; print("  PASS: " + msg)
	else:    _failed += 1; print("  FAIL: " + msg)

func _count_combatants(scene: Node) -> int:
	var n := 0
	for c in scene.get_children():
		if c is EnemyBase or c is BossBase:
			n += 1
	return n

func _test_enemies_removed() -> void:
	DebugBoot.no_enemies = true
	StageManager.current_stage_id = 1
	var scene: Node = preload("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert(_count_combatants(scene) == 0, "no_enemies remove EnemyBase/BossBase da stage_01")
	scene.queue_free()
	await get_tree().process_frame

func _test_enemies_present_by_default() -> void:
	DebugBoot.no_enemies = false
	StageManager.current_stage_id = 1
	var scene: Node = preload("res://stages/stage_01/stage_01.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	_assert(_count_combatants(scene) > 0, "sem flag, inimigos permanecem")
	scene.queue_free()
	await get_tree().process_frame

func _print_results() -> void:
	print("\n=== %d passed, %d failed ===" % [_passed, _failed])
```

`tests/test_no_enemies.tscn`:
```
[gd_scene format=3 uid="uid://test_no_enemies"]

[ext_resource type="Script" path="res://tests/test_no_enemies.gd" id="1_script"]

[node name="TestNoEnemies" type="Node"]
script = ExtResource("1_script")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_no_enemies.tscn`
Expected: FAIL no primeiro assert — combatentes ainda presentes (remoção não implementada).

- [ ] **Step 3: Write minimal implementation**

Em `stages/stage_scene.gd`, substituir o laço de bosses no `_ready` (atualmente):
```gdscript
	for child in get_children():
		if child is BossBase:
			child.player = _player
```
por:
```gdscript
	for child in get_children():
		if DebugBoot.no_enemies and (child is EnemyBase or child is BossBase):
			child.queue_free()
			continue
		if child is BossBase:
			child.player = _player
	_maybe_spawn_bot()
```

E adicionar, ao final do arquivo `stages/stage_scene.gd`:
```gdscript
func _maybe_spawn_bot() -> void:
	if not DebugBoot.bot_enabled:
		return
	var bot := preload("res://tests/bot/stage_bot.gd").new()
	bot.name = "StageBot"
	add_child(bot)
```

> Nota: `tests/bot/stage_bot.gd` ainda não existe nesta task. Criar um stub vazio agora pra o preload não quebrar:
`tests/bot/stage_bot.gd`:
```gdscript
# tests/bot/stage_bot.gd — implementado na Task 5
extends Node
```

- [ ] **Step 4: Run test to verify it passes**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_no_enemies.tscn`
Expected: PASS — `2 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add stages/stage_scene.gd tests/bot/stage_bot.gd tests/test_no_enemies.gd tests/test_no_enemies.tscn
git commit -m "feat(bot): remove combatentes em no_enemies + hook do bot (fases 01-08)"
```

---

## Task 4: Remoção de miniboss/boss + bot na stage_00

**Files:**
- Modify: `stages/stage_00/stage_00_scene.gd`

stage_00 não usa `stage_scene.gd` como base e spawna boss/miniboss por trigger. Validação na integração (Task 9).

- [ ] **Step 1: Gate dos triggers e anexo do bot**

Em `stages/stage_00/stage_00_scene.gd`, na função `_ready`, localizar a chamada `_setup_miniboss_trigger()` e envolvê-la:
```gdscript
	if not DebugBoot.no_enemies:
		_setup_miniboss_trigger()
	_maybe_spawn_bot()
```
(Se `_setup_miniboss_trigger()` estiver no fim do `_ready`, manter a ordem; só adicionar a guarda e a chamada do bot.)

No início de `func _spawn_boss() -> void:`, adicionar early-return:
```gdscript
func _spawn_boss() -> void:
	if DebugBoot.no_enemies:
		return
	if _boss_spawned:
		return
	...
```

Adicionar ao final de `stages/stage_00/stage_00_scene.gd`:
```gdscript
func _maybe_spawn_bot() -> void:
	if not DebugBoot.bot_enabled:
		return
	var bot := preload("res://tests/bot/stage_bot.gd").new()
	bot.name = "StageBot"
	add_child(bot)
```

- [ ] **Step 2: Verificar que a stage_00 ainda carrega sem flags**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://stages/stage_00/stage_00.tscn --quit-after 60`
Expected: carrega sem erro (DebugBoot.no_enemies/bot_enabled = false por default → comportamento normal).

- [ ] **Step 3: Commit**

```bash
git add stages/stage_00/stage_00_scene.gd
git commit -m "feat(bot): gate miniboss/boss em no_enemies + hook do bot (stage_00)"
```

---

## Task 5: StageBot — núcleo, walk_to, screenshot, travamento

**Files:**
- Modify: `tests/bot/stage_bot.gd` (substituir o stub)
- Create: `tests/test_stage_bot.gd`
- Create: `tests/test_stage_bot.tscn`

- [ ] **Step 1: Write the failing test**

`tests/test_stage_bot.gd`:
```gdscript
# tests/test_stage_bot.gd
extends Node

var _passed := 0
var _failed := 0

func _ready() -> void:
	_test_walk_to_completion()
	_test_screenshot_completes()
	_test_dist_to_goal()
	_print_results()
	get_tree().quit()

func _assert(cond: bool, msg: String) -> void:
	if cond: _passed += 1; print("  PASS: " + msg)
	else:    _failed += 1; print("  FAIL: " + msg)

func _make_bot_with_player() -> Node:
	var bot: Node = preload("res://tests/bot/stage_bot.gd").new()
	var p := CharacterBody2D.new()
	p.add_to_group("player")
	add_child(p)
	bot._player = p
	add_child(bot)
	return bot

func _test_walk_to_completion() -> void:
	var bot := _make_bot_with_player()
	bot._player.global_position = Vector2(100, 0)
	var done_far: bool = bot._do_walk_to({"x": 1000.0})
	_assert(not done_far, "walk_to incompleto quando longe do alvo")
	bot._player.global_position = Vector2(1000, 0)
	var done_near: bool = bot._do_walk_to({"x": 1000.0})
	_assert(done_near, "walk_to completo ao chegar no alvo (dentro da TOL)")
	bot._player.queue_free(); bot.queue_free()

func _test_screenshot_completes() -> void:
	var bot := _make_bot_with_player()
	StageManager.current_stage_id = 7
	var done: bool = bot._do_screenshot({"label": "teste"})
	_assert(done, "screenshot completa imediatamente (imprime BOT_SHOT:07:teste acima)")
	bot._player.queue_free(); bot.queue_free()

func _test_dist_to_goal() -> void:
	var bot := _make_bot_with_player()
	bot._player.global_position = Vector2(300, 50)
	var d: float = bot._dist_to_goal({"t": "walk_to", "x": 800.0})
	_assert(absf(d - 500.0) < 0.5, "_dist_to_goal de walk_to = |alvo - x|")
	bot._player.queue_free(); bot.queue_free()

func _print_results() -> void:
	print("\n=== %d passed, %d failed ===" % [_passed, _failed])
```

`tests/test_stage_bot.tscn`:
```
[gd_scene format=3 uid="uid://test_stage_bot"]

[ext_resource type="Script" path="res://tests/test_stage_bot.gd" id="1_script"]

[node name="TestStageBot" type="Node"]
script = ExtResource("1_script")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_bot.tscn`
Expected: FAIL — métodos `_do_walk_to`/`_do_screenshot`/`_dist_to_goal` não existem (stub vazio).

- [ ] **Step 3: Write minimal implementation**

Substituir todo o `tests/bot/stage_bot.gd` por:
```gdscript
# tests/bot/stage_bot.gd — autopilot que atravessa a fase (Approach A)
extends Node

const TOL := 24.0
const STUCK_EPS := 2.0
const STUCK_TIMEOUT := 4.0
const JUMP_HOLD := 0.12

var _player: CharacterBody2D = null
var _path: Array = []
var _idx: int = 0
var _seg_time: float = 0.0
var _last_dist: float = INF
var _stuck_timer: float = 0.0
var _jump_hold: float = 0.0
var _done: bool = false

func _ready() -> void:
	if _player == null:
		_player = _find_player()
	_path = _load_path()
	if _path.is_empty():
		print("BOT_STUCK:no_path@0,0")
		_done = true
		return
	print("BOT_START")

func _find_player() -> CharacterBody2D:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] if nodes.size() > 0 else null

func _load_path() -> Array:
	var path := "res://tests/bot/paths/stage_%02d.gd" % StageManager.current_stage_id
	if not ResourceLoader.exists(path):
		return []
	var inst: Object = (load(path) as GDScript).new()
	return inst.path() if inst.has_method("path") else []

func _physics_process(delta: float) -> void:
	if _done or _player == null:
		return
	if _jump_hold > 0.0:
		_jump_hold -= delta
		if _jump_hold <= 0.0:
			Input.action_release("jump")
	if _idx >= _path.size():
		_finish()
		return
	var seg: Dictionary = _path[_idx]
	var t := str(seg.get("t", ""))
	var complete := false
	match t:
		"walk_to":    complete = _do_walk_to(seg)
		"climb_to":   complete = _do_climb_to(seg)
		"drop":       complete = _do_drop(seg)
		"wait":       complete = _do_wait(seg, delta)
		"screenshot": complete = _do_screenshot(seg)
		_:            complete = true
	if t == "walk_to" or t == "climb_to":
		if _check_stuck(seg, delta):
			return
	if complete:
		_release_dirs()
		_advance()

func _advance() -> void:
	_idx += 1
	_seg_time = 0.0
	_stuck_timer = 0.0
	_last_dist = INF

func _finish() -> void:
	_done = true
	_release_dirs()
	print("BOT_DONE")

# ── Segmentos ───────────────────────────────────────────────────────────────

func _do_walk_to(seg: Dictionary) -> bool:
	var tx := float(seg.get("x", _player.global_position.x))
	var dx := tx - _player.global_position.x
	if absf(dx) < TOL:
		return true
	_press_dir(signf(dx))
	if _player.is_on_wall() and _player.is_on_floor():
		_tap_jump()
	return false

func _do_climb_to(seg: Dictionary) -> bool:
	var ty := float(seg.get("y", _player.global_position.y))
	if _player.global_position.y <= ty:
		return true
	var dir := -1.0 if str(seg.get("side", "left")) == "left" else 1.0
	_press_dir(dir)
	if _player.is_on_wall():
		_tap_jump()
	return false

func _do_drop(seg: Dictionary) -> bool:
	_press_dir(float(seg.get("dir", 1.0)))
	return (not _player.is_on_floor()) and _player.velocity.y > 0.0

func _do_wait(seg: Dictionary, delta: float) -> bool:
	_seg_time += delta
	return _seg_time >= float(seg.get("seconds", 0.5))

func _do_screenshot(seg: Dictionary) -> bool:
	print("BOT_SHOT:%02d:%s" % [StageManager.current_stage_id, str(seg.get("label", "shot"))])
	return true

# ── Travamento ──────────────────────────────────────────────────────────────

func _check_stuck(seg: Dictionary, delta: float) -> bool:
	var d := _dist_to_goal(seg)
	if d < _last_dist - STUCK_EPS:
		_last_dist = d
		_stuck_timer = 0.0
	else:
		_stuck_timer += delta
		if _stuck_timer >= STUCK_TIMEOUT:
			var p := _player.global_position
			print("BOT_STUCK:%s@%d,%d" % [str(seg.get("label", seg.get("t", "?"))), int(p.x), int(p.y)])
			_done = true
			_release_dirs()
			return true
	return false

func _dist_to_goal(seg: Dictionary) -> float:
	var p := _player.global_position
	match str(seg.get("t", "")):
		"walk_to":  return absf(float(seg.get("x", p.x)) - p.x)
		"climb_to": return absf(p.y - float(seg.get("y", p.y)))
		_:          return 0.0

# ── Input ─────────────────────────────────────────────────────────────────────

func _press_dir(dir: float) -> void:
	if dir < 0.0:
		Input.action_press("move_left")
		Input.action_release("move_right")
	elif dir > 0.0:
		Input.action_press("move_right")
		Input.action_release("move_left")

func _release_dirs() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")

func _tap_jump() -> void:
	if _jump_hold <= 0.0 and not Input.is_action_pressed("jump"):
		Input.action_press("jump")
		_jump_hold = JUMP_HOLD
```

- [ ] **Step 4: Run test to verify it passes**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_bot.tscn`
Expected: PASS — `3 passed, 0 failed`, e uma linha `BOT_SHOT:07:teste` no output.

- [ ] **Step 5: Commit**

```bash
git add tests/bot/stage_bot.gd tests/test_stage_bot.gd tests/test_stage_bot.tscn
git commit -m "feat(bot): StageBot núcleo (walk_to/climb_to/drop/wait/screenshot + travamento)"
```

---

## Task 6: Caminho da stage_00

**Files:**
- Create: `tests/bot/paths/stage_00.gd`

- [ ] **Step 1: Criar o caminho (rascunho a calibrar na Task 9)**

`tests/bot/paths/stage_00.gd`:
```gdscript
# tests/bot/paths/stage_00.gd — segmentos do caminho da fase 00
extends RefCounted

func path() -> Array:
	return [
		{"t": "screenshot", "label": "00_spawn"},
		{"t": "walk_to", "x": 3000.0},
		{"t": "screenshot", "label": "01_corredor1"},
		{"t": "walk_to", "x": 6470.0},   # sala do miniboss (vazia em no_enemies)
		{"t": "screenshot", "label": "02_sala_miniboss"},
		{"t": "walk_to", "x": 8222.0},   # corredor 2
		{"t": "screenshot", "label": "03_corredor2"},
		{"t": "walk_to", "x": 17000.0},  # sala do boss (boss removido)
		{"t": "screenshot", "label": "04_sala_boss"},
	]
```

> As coordenadas x são um primeiro chute baseado na geometria do `stage_00_scene.gd` (miniboss trigger ~6470, arena do boss ~17202). Serão ajustadas na calibração da Task 9 observando onde o bot trava.

- [ ] **Step 2: Verificar que o caminho carrega (sintaxe)**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_bot.tscn`
Expected: ainda PASS (`3 passed`) — confirma que o projeto compila com o novo arquivo.

- [ ] **Step 3: Commit**

```bash
git add tests/bot/paths/stage_00.gd
git commit -m "feat(bot): caminho inicial da stage_00 (a calibrar)"
```

---

## Task 7: Runner Playwright

**Files:**
- Create: `tests/bot/package.json`
- Create: `tests/bot/run_stage_bot.mjs`

- [ ] **Step 1: Criar package.json**

`tests/bot/package.json`:
```json
{
  "name": "stagebot-runner",
  "private": true,
  "type": "module",
  "scripts": {
    "bot": "node run_stage_bot.mjs"
  },
  "dependencies": {
    "playwright": "^1.48.0"
  }
}
```

- [ ] **Step 2: Instalar dependências**

Run (PowerShell, a partir de `tests/bot/`):
```
cd tests/bot; npm install; npx playwright install chromium
```
Expected: instala `playwright` e o browser Chromium sem erro.

- [ ] **Step 3: Escrever o runner**

`tests/bot/run_stage_bot.mjs`:
```javascript
// tests/bot/run_stage_bot.mjs
// Uso: node run_stage_bot.mjs <stageId>   (ex.: node run_stage_bot.mjs 00)
import { chromium } from "playwright";
import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const stage = (process.argv[2] ?? "00").padStart(2, "0");
const BASE = "http://localhost:8080";
const URL = `${BASE}/?stage=${stage}&bot=1&noenemies=1`;
const BOOT_TIMEOUT = 30_000;
const RUN_TIMEOUT = 180_000;

const shotsDir = resolve(__dirname, "shots", stage);
const resultsDir = resolve(__dirname, "results");
await mkdir(shotsDir, { recursive: true });
await mkdir(resultsDir, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });

const result = { status: "FAIL", stage, segments_completed: 0, shots: [], stuck: null, duration_ms: 0 };
const started = Date.now();

let resolveRun;
const runDone = new Promise((r) => (resolveRun = r));
let bootSeen = false;
let bootTimer = setTimeout(() => { if (!bootSeen) { result.error = "boot timeout"; resolveRun(); } }, BOOT_TIMEOUT);
const runTimer = setTimeout(() => { result.error = "run timeout"; resolveRun(); }, RUN_TIMEOUT);

async function snap(label, suffix = "") {
  const file = resolve(shotsDir, `${label}${suffix}.png`);
  const canvas = page.locator("canvas").first();
  await canvas.screenshot({ path: file });
  result.shots.push(file);
}

page.on("console", async (msg) => {
  const text = msg.text();
  if (text.startsWith("BOT_START")) {
    bootSeen = true; clearTimeout(bootTimer);
  } else if (text.startsWith("BOT_SHOT:")) {
    const label = text.split(":").slice(2).join(":").trim();
    await snap(label);
    result.segments_completed++;
  } else if (text.startsWith("BOT_STUCK:")) {
    const body = text.slice("BOT_STUCK:".length).trim();
    const [label, pos] = body.split("@");
    const [x, y] = (pos ?? "0,0").split(",").map(Number);
    result.stuck = { label, x, y };
    await snap(label, "_STUCK");
    resolveRun();
  } else if (text.startsWith("BOT_DONE")) {
    result.status = "PASS";
    resolveRun();
  }
});

await page.goto(URL, { waitUntil: "load" });
await runDone;

clearTimeout(runTimer);
result.duration_ms = Date.now() - started;
await browser.close();
await writeFile(resolve(resultsDir, `${stage}.json`), JSON.stringify(result, null, 2));

console.log(`\n[StageBot] stage ${stage}: ${result.status}` +
  (result.stuck ? ` (travou em ${result.stuck.label} @ ${result.stuck.x},${result.stuck.y})` : "") +
  ` — ${result.shots.length} prints, ${result.duration_ms}ms`);
process.exit(result.status === "PASS" ? 0 : 1);
```

- [ ] **Step 4: Commit**

```bash
git add tests/bot/package.json tests/bot/run_stage_bot.mjs
git commit -m "feat(bot): runner Playwright (screenshots + PASS/FAIL)"
```

---

## Task 8: Gitignore dos artefatos

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Adicionar entradas**

Acrescentar ao final de `.gitignore`:
```
# StageBot — artefatos de saída (regerados a cada run)
tests/bot/shots/
tests/bot/results/
tests/bot/node_modules/
```

- [ ] **Step 2: Verificar**

Run: `git status --porcelain tests/bot/`
Expected: `shots/`, `results/` e `node_modules/` NÃO aparecem como untracked.

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore(bot): gitignore dos artefatos do StageBot"
```

---

## Task 9: Integração + calibração na stage_00 (aceitação do framework)

**Files:**
- Modify: `tests/bot/paths/stage_00.gd` (ajuste fino dos x conforme travamentos)

Pré-requisito: build web atualizado e servidor no ar. Seguir a skill `web-export` (export + `serve_web.py` na 8080).

- [ ] **Step 1: Exportar web e subir o servidor**

Run:
```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" "export/web/index.html"
```
Depois subir o servidor na 8080 (bloco PowerShell da skill `web-export`). Confirmar `200` em `http://localhost:8080`.

- [ ] **Step 2: Rodar o bot na stage_00**

Run (a partir de `tests/bot/`):
```
node run_stage_bot.mjs 00
```
Expected (objetivo): `[StageBot] stage 00: PASS — 5 prints, …`.

- [ ] **Step 3: Calibrar se travar**

Se sair `FAIL (travou em <label> @ x,y)`:
1. Abrir `tests/bot/results/00.json` e o print `..._STUCK.png` em `tests/bot/shots/00/`.
2. Ajustar o segmento problemático em `tests/bot/paths/stage_00.gd`: corrigir o `x`, ou inserir `climb_to`/`drop`/`wait` onde o terreno exige (ex.: subir plataformas antes de seguir).
3. Reexportar (se mudou só o `.gd` de caminho, ele está no PCK → reexportar web), reiniciar servidor, rodar de novo.
4. Repetir até `PASS` com os 5 prints coerentes (spawn, corredores, salas).

- [ ] **Step 4: Conferir a galeria**

Abrir os PNGs em `tests/bot/shots/00/` e confirmar visualmente: spawn, corredor 1, sala do miniboss (vazia), corredor 2, sala do boss (vazia). Sem lava branca / tiles faltando.

- [ ] **Step 5: Commit**

```bash
git add tests/bot/paths/stage_00.gd
git commit -m "test(bot): stage_00 calibrada — bot atravessa e gera galeria (PASS)"
```

---

## Task 10: Caminho da stage_01

**Files:**
- Create: `tests/bot/paths/stage_01.gd`

- [ ] **Step 1: Escrever o caminho da stage_01**

Basear nas zonas conhecidas (do `stage_01.tscn`): Z1 → shaft (descida) → Z2 + ponte → Corridor1 (porta) → Z3 → ShaftUp (wall-jumps) → Z4 → Corridor2 → sala do boss.

`tests/bot/paths/stage_01.gd`:
```gdscript
# tests/bot/paths/stage_01.gd — segmentos do caminho da fase 01
extends RefCounted

func path() -> Array:
	return [
		{"t": "screenshot", "label": "00_spawn"},
		{"t": "walk_to", "x": 4000.0},           # Z1
		{"t": "screenshot", "label": "01_z1"},
		{"t": "drop", "dir": 1.0},               # entra na descida do shaft
		{"t": "walk_to", "x": 9680.0},           # fundo / início da Z2 (ponte)
		{"t": "screenshot", "label": "02_z2_ponte"},
		{"t": "walk_to", "x": 10688.0},          # entra no Corridor1 (porta faz auto-walk)
		{"t": "wait", "seconds": 2.0},           # deixa o corredor levar o player
		{"t": "screenshot", "label": "03_corredor1"},
		{"t": "walk_to", "x": 16256.0},          # base do ShaftUp
		{"t": "climb_to", "y": 1408.0, "side": "left"},  # sobe o shaft com wall-jump
		{"t": "screenshot", "label": "04_shaftup"},
		{"t": "walk_to", "x": 19552.0},          # Z4 → Corridor2
		{"t": "wait", "seconds": 2.0},
		{"t": "screenshot", "label": "05_corredor2"},
		{"t": "walk_to", "x": 21000.0},          # sala do boss (boss removido)
		{"t": "screenshot", "label": "06_sala_boss"},
	]
```

> Coordenadas derivadas do `stage_01.tscn` (ShaftUp em x~16256, Corridor1 entry 9856/exit 10688, Corridor2 entry 19552). Calibrar na próxima etapa.

- [ ] **Step 2: Reexportar, subir servidor, rodar**

Run (após export web + servidor 8080, a partir de `tests/bot/`):
```
node run_stage_bot.mjs 01
```
Expected (objetivo): `[StageBot] stage 01: PASS — 7 prints, …`.

- [ ] **Step 3: Calibrar até PASS**

Mesmo loop da Task 9 Step 3, focando nos trechos difíceis da stage_01: a descida do shaft (`drop` + `walk_to`), o `climb_to` do ShaftUp (ajustar `y`/`side`, ou trocar por uma sequência de `climb_to` por degrau se um único não subir), e os `wait` dos corredores (porta + auto-walk). Conferir os PNGs.

- [ ] **Step 4: Commit**

```bash
git add tests/bot/paths/stage_01.gd
git commit -m "test(bot): stage_01 calibrada — bot atravessa e gera galeria (PASS)"
```

---

## Self-Review

**Cobertura do spec:**
- Boot direto por URL → Tasks 1-2. ✅
- Flag `no_enemies` (grunts/flyers/miniboss/boss) → Tasks 3-4. ✅
- StageBot Approach A (walk_to/climb_to/drop/wait/screenshot) → Task 5. ✅
- Marcadores de console (BOT_START/SHOT/STUCK/DONE) → Task 5. ✅
- Detecção de travamento (4s) → Task 5. ✅
- Caminhos por fase (stage_00 primeiro, depois stage_01) → Tasks 6, 10. ✅
- Runner Playwright (screenshots + PASS/FAIL + results.json) → Task 7. ✅
- Layout de arquivos + gitignore → Tasks 1-8. ✅
- Validar framework na stage_00 antes da 01 → Task 9 antes da 10. ✅

**Consistência de tipos/nomes:**
- `parse_params` (static) usado igual no teste e no `_get_query_string`/`_ready`. ✅
- `DebugBoot.bot_enabled`/`no_enemies`/`stage_id`/`active_char` consistentes entre debug_boot, stage_scene, stage_00_scene, stage_bot. ✅
- `_maybe_spawn_bot` definido nas duas cenas (01-08 e 00). ✅
- Marcadores `BOT_SHOT:%02d:%s` no bot batem com o parse `text.split(":").slice(2)` no runner. ✅
- `_do_walk_to`/`_do_screenshot`/`_dist_to_goal` testados existem com a mesma assinatura no stage_bot. ✅

**Riscos conhecidos (resolvidos por calibração, não por código):**
- `climb_to` com um único alvo pode não subir shafts longos → a Task 10 Step 3 prevê quebrar em degraus.
- Coordenadas x dos caminhos são chutes iniciais → Tasks 9/10 calibram observando travamentos.
