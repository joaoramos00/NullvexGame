# Touch Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar controles touch overlay (◀ ▶ Pulo Ataque Pausa) que aparecem apenas no browser, sem alterar nenhum código de gameplay.

**Architecture:** Uma cena `ui/touch_controls.tscn` (CanvasLayer layer=10) cujos botões são criados inteiramente em código em `_ready()`. Cada `TouchScreenButton` tem `action` configurada para disparar o InputMap action existente — o restante do jogo continua lendo `Input.is_action_pressed()` normalmente. Visibilidade controlada por `OS.get_name() == "Web"`. Instanciada nos três scripts de cena base.

**Tech Stack:** Godot 4.6.2 GDScript, TouchScreenButton (Node2D), CanvasLayer, ImageTexture

---

## Arquivos

| Arquivo | Operação |
|---------|----------|
| `ui/touch_controls.gd` | **CRIAR** — lógica de visibilidade + criação dos botões |
| `ui/touch_controls.tscn` | **CRIAR** — CanvasLayer com script; nenhum filho (criados em código) |
| `tests/test_touch_controls.gd` | **CRIAR** — testa ocultamento fora do Web |
| `tests/test_touch_controls.tscn` | **CRIAR** — cena de teste |
| `stages/stage_scene.gd` | **MODIFICAR** — preload + add_child |
| `stages/stage_00/stage_00_scene.gd` | **MODIFICAR** — preload + add_child |
| `stages/stage_09/stage_09_scene.gd` | **MODIFICAR** — preload + add_child |

---

## Task 1: Criar `ui/touch_controls.gd` e `ui/touch_controls.tscn`

**Files:**
- Create: `ui/touch_controls.gd`
- Create: `ui/touch_controls.tscn`

- [ ] **Step 1: Criar `ui/touch_controls.gd`**

```gdscript
extends CanvasLayer

# [action, offset_x_from_left, offset_x_from_right, offset_y_from_bottom, w, h, color]
# Posições calculadas em _ready() relativas ao tamanho do viewport

func _ready() -> void:
	if OS.get_name() != "Web":
		visible = false
		return
	layer = 10
	modulate = Color(1.0, 1.0, 1.0, 0.65)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_add_button("move_left",  Vector2(10,           vp.y - 62), 52, 52, Color(0.9, 0.27, 0.38))
	_add_button("move_right", Vector2(68,           vp.y - 62), 52, 52, Color(0.9, 0.27, 0.38))
	_add_button("jump",       Vector2(vp.x - 120,  vp.y - 62), 52, 52, Color(0.15, 0.68, 0.38))
	_add_button("attack",     Vector2(vp.x - 62,   vp.y - 62), 52, 52, Color(0.29, 0.56, 0.85))
	_add_button("pause",      Vector2(vp.x - 46,   8),         36, 28, Color(0.31, 0.31, 0.39))

func _add_button(action: String, pos: Vector2, w: int, h: int, color: Color) -> void:
	var btn := TouchScreenButton.new()
	btn.action = action
	btn.passby_press = true
	btn.position = pos
	btn.texture_normal = _make_tex(color, w, h)
	btn.texture_pressed = _make_tex(color.lightened(0.35), w, h)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, h)
	btn.shape = shape
	btn.shape_centered = false
	add_child(btn)

static func _make_tex(color: Color, w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
```

- [ ] **Step 2: Criar `ui/touch_controls.tscn`**

```
[gd_scene format=3 uid="uid://touch_controls"]

[ext_resource type="Script" path="res://ui/touch_controls.gd" id="1_script"]

[node name="TouchControls" type="CanvasLayer"]
layer = 10
script = ExtResource("1_script")
```

---

## Task 2: Escrever e rodar o teste

**Files:**
- Create: `tests/test_touch_controls.gd`
- Create: `tests/test_touch_controls.tscn`

- [ ] **Step 1: Criar `tests/test_touch_controls.gd`**

```gdscript
extends Node

func _ready() -> void:
	var scene := preload("res://ui/touch_controls.tscn")
	var tc: CanvasLayer = scene.instantiate()
	add_child(tc)
	# Fora do Web (headless), deve estar oculto
	assert(not tc.visible, "FAIL: TouchControls deveria estar oculto fora do Web")
	print("PASS: touch_controls oculto em plataforma nao-Web")
	tc.queue_free()
	get_tree().quit()
```

- [ ] **Step 2: Criar `tests/test_touch_controls.tscn`**

```
[gd_scene format=3 uid="uid://test_touch_controls"]

[ext_resource type="Script" path="res://tests/test_touch_controls.gd" id="1_script"]

[node name="TestTouchControls" type="Node"]
script = ExtResource("1_script")
```

- [ ] **Step 3: Rodar o teste e verificar PASS**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_touch_controls.tscn
```

Saída esperada:
```
PASS: touch_controls oculto em plataforma nao-Web
```

- [ ] **Step 4: Commit**

```bash
git add ui/touch_controls.gd ui/touch_controls.tscn tests/test_touch_controls.gd tests/test_touch_controls.tscn
git commit -m "feat: touch controls overlay para mobile browser"
```

---

## Task 3: Integrar em `stages/stage_scene.gd`

**Files:**
- Modify: `stages/stage_scene.gd`

- [ ] **Step 1: Adicionar preload e instância no `_ready()` de `stage_scene.gd`**

Adicionar após a linha `const ZARA_SCENE := preload(...)`:
```gdscript
const _TOUCH_SCENE := preload("res://ui/touch_controls.tscn")
```

Adicionar como **última linha** do `_ready()`, antes de `queue_redraw()`:
```gdscript
	add_child(_TOUCH_SCENE.instantiate())
```

O `_ready()` final fica:
```gdscript
func _ready() -> void:
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")
	_player = _spawn_player()
	for child in get_children():
		if child is BossBase:
			child.player = _player
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)
	StageManager.spawn_position = $PlayerSpawn.global_position
	AudioManager.play_bgm(AudioLibrary.get_stage_bgm(StageManager.current_stage_id))
	add_child(_TOUCH_SCENE.instantiate())
	queue_redraw()
```

- [ ] **Step 2: Rodar teste existente para garantir que stage_scene não quebrou**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_controller.tscn
```

Saída esperada: sem erros / PASS.

---

## Task 4: Integrar em `stage_00_scene.gd` e `stage_09_scene.gd`

**Files:**
- Modify: `stages/stage_00/stage_00_scene.gd`
- Modify: `stages/stage_09/stage_09_scene.gd`

- [ ] **Step 1: Adicionar preload e instância em `stage_00_scene.gd`**

Adicionar após `const ZARA_SCENE := preload(...)`:
```gdscript
const _TOUCH_SCENE := preload("res://ui/touch_controls.tscn")
```

Adicionar como penúltima linha do `_ready()` (antes de `queue_redraw()`):
```gdscript
	add_child(_TOUCH_SCENE.instantiate())
```

O `_ready()` final fica:
```gdscript
func _ready() -> void:
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")
	_player = _spawn_player()
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)
	StageManager.spawn_position = $PlayerSpawn.global_position
	$GoalZone.body_entered.connect(_on_goal_entered)
	AudioManager.play_bgm(AudioLibrary.bgm_intro)
	add_child(_TOUCH_SCENE.instantiate())
	queue_redraw()
```

- [ ] **Step 2: Adicionar preload e instância em `stage_09_scene.gd`**

Adicionar após `const ZARA_SCENE := preload(...)`:
```gdscript
const _TOUCH_SCENE := preload("res://ui/touch_controls.tscn")
```

Adicionar como penúltima linha do `_ready()` (antes de `queue_redraw()`):
```gdscript
	add_child(_TOUCH_SCENE.instantiate())
```

O `_ready()` final fica:
```gdscript
func _ready() -> void:
	if StageManager.current_stage_id < 0:
		GameManager.reset()
		GameManager.set_active_character("zael")
	_player = _spawn_player()
	$StageController.setup(_player)
	$HUD.connect_to_player(_player)
	StageManager.spawn_position = $PlayerSpawn.global_position
	_collect_nodes()
	_setup_bosses()
	AudioManager.play_bgm(AudioLibrary.bgm_gauntlet)
	add_child(_TOUCH_SCENE.instantiate())
	queue_redraw()
```

- [ ] **Step 3: Commit final**

```bash
git add stages/stage_scene.gd stages/stage_00/stage_00_scene.gd stages/stage_09/stage_09_scene.gd
git commit -m "feat: instanciar touch_controls nas cenas de fase"
```

---

## Self-Review

**Spec coverage:**
- ✅ 5 botões (move_left, move_right, jump, attack, pause)
- ✅ Overlay semitransparente (modulate 0.65)
- ✅ Visível apenas em Web (`OS.get_name() == "Web"`)
- ✅ layer = 10 (acima do HUD em layer 5)
- ✅ Integrado em stage_scene.gd, stage_00_scene.gd, stage_09_scene.gd
- ✅ Zero alterações em código de personagem/gameplay
- ✅ passby_press = true para deslizar o dedo
- ✅ shape_centered = false para alinhar shape com textura

**Placeholders:** nenhum.

**Type consistency:** `_make_tex` retorna `ImageTexture` em Task 1 e é usado apenas em Task 1 — consistente.
