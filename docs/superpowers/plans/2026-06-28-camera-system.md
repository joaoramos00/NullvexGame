# Camera System MMX-Style Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir a lógica de câmera em `stage_scene.gd` e `stage_00_scene.gd` por um `CameraController` reutilizável que implementa o comportamento MMX (Y congela durante o pulo, segue ao pousar, leash em queda longa) com overrides de LOCKED e SHAFT.

**Architecture:** `CameraController` (RefCounted) encapsula toda a lógica de câmera Y. As fases chamam `update(delta)` e lêem `target_x`/`target_y` para posicionar o `Camera2D`. Overrides (LOCKED para corredores/boss, SHAFT para shafts verticais) têm prioridade sobre o comportamento base MMX.

**Tech Stack:** Godot 4.6.2, GDScript, CharacterBody2D, Area2D para detecção de shaft.

## Global Constraints

- GDScript — sem lambdas que capturam variáveis externas (crash no web export); usar métodos de classe
- `_CAM_RISE = 128.0` — mantém o piso a 60px da borda inferior da câmera (zoom 2×)
- Zoom da câmera NÃO é gerido pelo CameraController — fica nas fases
- Corredores e boss rooms em stage_00 continuam a usar `lock_to()` / `unlock()`
- Corredores em stages 01-08 só mudam zoom (sem lock de posição) — sem lock_to()
- Sem threshold de altitude — qualquer aterragem actualiza `_floor_y` (comportamento MMX puro)
- Web export obrigatório após cada task que muda código GDScript

---

### Task 1: Criar CameraController

**Files:**
- Create: `stages/camera_controller.gd`

**Interfaces:**
- Produces:
  - `CameraController.new()` → instância
  - `setup(player: CharacterBase, cam: Camera2D) -> void`
  - `update(delta: float) -> void`
  - `lock_to(target: Vector2, zoom: float) -> void`
  - `unlock() -> void`
  - `set_shaft_mode(active: bool) -> void`
  - `var target_x: float`
  - `var target_y: float`
  - `var is_locked: bool`
  - `var lock_zoom: float`

- [ ] **Step 1: Criar o ficheiro `stages/camera_controller.gd`**

```gdscript
# stages/camera_controller.gd
class_name CameraController
extends RefCounted

# ── Constantes ────────────────────────────────────────────────────────────────
const _CAM_RISE      := 128.0   # câmera acima do origin do player → piso 60px da borda inferior
const GROUNDED_SPEED := 8.0     # lerp ao pousar (~0.3s para atingir o alvo)
const SHAFT_SPEED    := 10.0    # lerp em modo shaft (subida e descida)
const FALL_SPEED     := 5.0     # lerp quando leash activo
const LEASH_SLACK    := 64.0    # 1 tile — folga antes de câmera seguir em queda
const LOCK_SPEED     := 0.1     # factor de lerp em modo locked (por frame)

# ── Estado público ────────────────────────────────────────────────────────────
var target_x: float = 0.0
var target_y: float = 0.0
var is_locked: bool = false
var lock_zoom: float = 2.0

# ── Estado interno ────────────────────────────────────────────────────────────
var _player: CharacterBase = null
var _cam_x: float  = 0.0   # posição X actual da câmera (lerp durante lock)
var _cam_y: float  = 0.0   # posição Y actual da câmera
var _floor_y: float = 0.0  # nível de piso actual (actualizado ao pousar)
var _lock_target: Vector2 = Vector2.ZERO
var _shaft: bool = false

# ── API pública ───────────────────────────────────────────────────────────────

func setup(player: CharacterBase, _cam: Camera2D) -> void:
	_player  = player
	_cam_x   = player.global_position.x
	_cam_y   = player.global_position.y - _CAM_RISE
	_floor_y = player.global_position.y
	target_x = _cam_x
	target_y = _cam_y

func update(delta: float) -> void:
	if not is_instance_valid(_player):
		return

	# ── Nível 1: LOCKED (corredor / boss room) ────────────────────────────────
	if is_locked:
		_cam_x = lerpf(_cam_x, _lock_target.x, LOCK_SPEED)
		_cam_y = lerpf(_cam_y, _lock_target.y, LOCK_SPEED)
		target_x = _cam_x
		target_y = _cam_y
		return

	# reset _cam_x para o player quando não está locked
	_cam_x = _player.global_position.x
	target_x = _cam_x

	# ── Nível 1: SHAFT (shaft vertical — câmera segue em ambas as direcções) ──
	if _shaft:
		var ty: float = _player.global_position.y - _CAM_RISE
		_cam_y = lerpf(_cam_y, ty, minf(SHAFT_SPEED * delta, 1.0))
		target_y = _cam_y
		return

	# ── Nível 2: Default MMX ──────────────────────────────────────────────────
	if _player.is_on_floor():
		# Qualquer aterragem actualiza _floor_y (sem threshold)
		_floor_y = _player.global_position.y
		_cam_y = lerpf(_cam_y, _floor_y - _CAM_RISE, minf(GROUNDED_SPEED * delta, 1.0))
	elif _player.velocity.y > 0.0:   # a cair
		var ideal: float = _player.global_position.y - _CAM_RISE
		if ideal > _cam_y + LEASH_SLACK:
			_cam_y = lerpf(_cam_y, ideal, minf(FALL_SPEED * delta, 1.0))
	# a subir (pulo): _cam_y congela

	target_y = _cam_y

func lock_to(target: Vector2, zoom: float) -> void:
	is_locked  = true
	lock_zoom  = zoom
	_lock_target = target

func unlock() -> void:
	is_locked = false
	if is_instance_valid(_player):
		_floor_y = _player.global_position.y   # reset nível de piso ao desbloquear
		_cam_x   = _player.global_position.x

func set_shaft_mode(active: bool) -> void:
	_shaft = active
	if active and is_instance_valid(_player):
		_floor_y = _player.global_position.y   # reset nível de piso ao entrar no shaft
```

- [ ] **Step 2: Verificar parse via export headless**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "D:/SnesGame" --export-release "Web" "D:/SnesGame/export/web/index.html" 2>&1 | tail -5
```

Esperado: `[ DONE ] savepack` sem erros de parse.

- [ ] **Step 3: Commit**

```bash
cd D:/SnesGame
git add stages/camera_controller.gd export/web/
git commit -m "feat(camera): CameraController — MMX default + LOCKED + SHAFT overrides"
```

---

### Task 2: Integrar CameraController em stage_scene.gd (fases 01-08)

**Files:**
- Modify: `stages/stage_scene.gd`

**Interfaces:**
- Consumes: `CameraController` (Task 1)
- Produces: `_cam_ctrl: CameraController` — acessível pelas subclasses (stage_01_scene.gd)

- [ ] **Step 1: Substituir vars de câmera e inicialização no `_ready()`**

Em `stage_scene.gd`, substituir:
```gdscript
var _cam_y       := 0.0   # Y atual da câmera (lerp contínuo)
var _cam_floor_y := 0.0   # nível de piso que a câmera está a seguir
```
por:
```gdscript
var _cam_ctrl: CameraController = null
```

E no `_ready()`, substituir:
```gdscript
	_player = _spawn_player()
	_cam_floor_y = _player.global_position.y
	_cam_y       = _player.global_position.y - _CAM_RISE
```
por:
```gdscript
	_player = _spawn_player()
	_cam_ctrl = CameraController.new()
	_cam_ctrl.setup(_player, $Camera2D)
```

- [ ] **Step 2: Substituir `_process` da câmera**

Substituir o bloco completo (incluindo constantes):
```gdscript
# Câmera com deadzone vertical: só atualiza o nível de referência quando a mudança
# de altitude ≥ _CAM_FLOOR_THRESHOLD (4 tiles). Plataformas pequenas (Z1) não movem
# a câmera; escadas/zonas elevadas (Z2/Z3) excedem o threshold e disparam o scroll.
const _CAM_RISE            := 128.0
const _CAM_FLOOR_THRESHOLD := 256.0   # 4 tiles — mínimo para actualizar o nível de piso
func _process(delta: float) -> void:
	if is_instance_valid(_player):
		if _player.is_on_floor():
			var py: float = _player.global_position.y
			if absf(py - _cam_floor_y) >= _CAM_FLOOR_THRESHOLD:
				_cam_floor_y = py
			_cam_y = lerpf(_cam_y, _cam_floor_y - _CAM_RISE, minf(4.0 * delta, 1.0))
		elif _player.velocity.y > 0.0:   # caindo: segue para baixo
			_cam_y = lerpf(_cam_y, _player.global_position.y - _CAM_RISE, minf(5.0 * delta, 1.0))
		$Camera2D.global_position = Vector2(_player.global_position.x, _cam_y)
	# Actualiza o rect visível p/ o backdrop do _draw().
	var zoom := $Camera2D.zoom
	var vp   := get_viewport().get_visible_rect().size
	var half := vp / zoom * 0.5
	_cam_visible_rect = Rect2($Camera2D.global_position - half, half * 2.0)
	queue_redraw()
```

por:
```gdscript
func _process(delta: float) -> void:
	if is_instance_valid(_player) and _cam_ctrl != null:
		_cam_ctrl.update(delta)
		$Camera2D.global_position = Vector2(_cam_ctrl.target_x, _cam_ctrl.target_y)
	var zoom := $Camera2D.zoom
	var vp   := get_viewport().get_visible_rect().size
	var half := vp / zoom * 0.5
	_cam_visible_rect = Rect2($Camera2D.global_position - half, half * 2.0)
	queue_redraw()
```

- [ ] **Step 3: Verificar parse + export**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "D:/SnesGame" --export-release "Web" "D:/SnesGame/export/web/index.html" 2>&1 | tail -5
```

Esperado: `[ DONE ] savepack` sem erros.

- [ ] **Step 4: Commit**

```bash
cd D:/SnesGame
git add stages/stage_scene.gd export/web/
git commit -m "feat(camera): stage_scene usa CameraController — remove _cam_y/_cam_floor_y manual"
```

---

### Task 3: Integrar CameraController em stage_00_scene.gd

**Files:**
- Modify: `stages/stage_00/stage_00_scene.gd`

**Interfaces:**
- Consumes: `CameraController` (Task 1)

- [ ] **Step 1: Substituir vars de câmera no topo do ficheiro**

Remover:
```gdscript
var _camera_locked   := false
var _camera_target   := Vector2.ZERO
var _cam_y           := 0.0
var _cam_floor_y     := 0.0   # nível de piso que a câmera está a seguir
const _CAM_RISE            := 128.0
const _CAM_FLOOR_THRESHOLD := 256.0   # 4 tiles — mínimo para actualizar o nível de piso
```

Adicionar:
```gdscript
var _cam_ctrl: CameraController = null
var _camera_zoom_tgt := 2.0   # zoom alvo (gerido pela fase, não pelo controller)
```

- [ ] **Step 2: Actualizar inicialização no `_ready()`**

Substituir:
```gdscript
	StageManager.spawn_position = $PlayerSpawn.global_position
	_spawn_player()
	_cam_floor_y = _player.global_position.y
	_cam_y       = _player.global_position.y - _CAM_RISE
```

por:
```gdscript
	StageManager.spawn_position = $PlayerSpawn.global_position
	_spawn_player()
	_cam_ctrl = CameraController.new()
	_cam_ctrl.setup(_player, $Camera2D)
```

- [ ] **Step 3: Substituir `_process`**

Substituir o bloco completo:
```gdscript
func _process(delta: float) -> void:
	var cam := $Camera2D as Camera2D
	if is_instance_valid(_player):
		if _camera_locked:
			cam.global_position = cam.global_position.lerp(_camera_target, 0.1)
			cam.zoom = cam.zoom.lerp(Vector2(_camera_zoom_tgt, _camera_zoom_tgt), 0.1)
			_cam_y       = cam.global_position.y       # sync p/ não saltar ao desbloquear
			_cam_floor_y = _player.global_position.y   # reset nível de piso
		else:
			cam.zoom = cam.zoom.lerp(Vector2(2.0, 2.0), 0.1)
			if absf(cam.zoom.x - 2.0) < 0.05:
				cam.zoom = Vector2(2.0, 2.0)
				if _player.is_on_floor():
					var py: float = _player.global_position.y
					if absf(py - _cam_floor_y) >= _CAM_FLOOR_THRESHOLD:
						_cam_floor_y = py
					_cam_y = lerpf(_cam_y, _cam_floor_y - _CAM_RISE, minf(4.0 * delta, 1.0))
				elif _player.velocity.y > 0.0:   # caindo: segue para baixo
					_cam_y = lerpf(_cam_y, _player.global_position.y - _CAM_RISE, minf(5.0 * delta, 1.0))
				cam.global_position = Vector2(_player.global_position.x, _cam_y)
			else:
				# retornando do corredor/boss: segue livremente até o zoom estabilizar
				cam.global_position = cam.global_position.lerp(_player.global_position, 0.12)
				_cam_y = cam.global_position.y   # sync para continuar suavemente após zoom
	queue_redraw()
```

por:
```gdscript
func _process(delta: float) -> void:
	var cam := $Camera2D as Camera2D
	if is_instance_valid(_player) and _cam_ctrl != null:
		_cam_ctrl.update(delta)
		if _cam_ctrl.is_locked:
			cam.zoom = cam.zoom.lerp(Vector2(_cam_ctrl.lock_zoom, _cam_ctrl.lock_zoom), 0.1)
		else:
			cam.zoom = cam.zoom.lerp(Vector2(2.0, 2.0), 0.1)
		cam.global_position = Vector2(_cam_ctrl.target_x, _cam_ctrl.target_y)
	queue_redraw()
```

- [ ] **Step 4: Actualizar todos os callbacks que activam/desactivam o lock**

Pesquisar todas as ocorrências de `_camera_locked = true` e `_camera_locked = false` no ficheiro:

```bash
grep -n "_camera_locked" D:/SnesGame/stages/stage_00/stage_00_scene.gd
```

Para cada `_camera_locked = true` com `_camera_target = X` e `_camera_zoom_tgt = Z`, substituir por `_cam_ctrl.lock_to(X, Z)`.
Para cada `_camera_locked = false`, substituir por `_cam_ctrl.unlock()`.

Exemplo — padrão a substituir:
```gdscript
_camera_locked   = true
_camera_target   = Vector2(X, Y)
_camera_zoom_tgt = Z
```
→
```gdscript
_cam_ctrl.lock_to(Vector2(X, Y), Z)
```

E:
```gdscript
_camera_locked = false
```
→
```gdscript
_cam_ctrl.unlock()
```

- [ ] **Step 5: Verificar parse + export**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "D:/SnesGame" --export-release "Web" "D:/SnesGame/export/web/index.html" 2>&1 | tail -5
```

Esperado: `[ DONE ] savepack` sem erros.

- [ ] **Step 6: Commit**

```bash
cd D:/SnesGame
git add stages/stage_00/stage_00_scene.gd export/web/
git commit -m "feat(camera): stage_00 usa CameraController — lock_to/unlock substituem _camera_locked"
```

---

### Task 4: Shaft Area2D em stage_01 + push master

**Files:**
- Modify: `stages/stage_01/stage_01.tscn` — adicionar `Area2D` Z4ShaftCamArea
- Modify: `stages/stage_01/stage_01_scene.gd` — conectar signals + métodos de callback

**Interfaces:**
- Consumes: `_cam_ctrl: CameraController` herdado de `stage_scene.gd` (Task 2)

**Geometria do shaft Z4:**
- X: 17424–17872 (de `_SHAFT_SEGS`) → center_x = 17648, width = 700 (com margem)
- Y: −1026–2208 (de `_SHAFT_SEGS`) → center_y = 591, height = 3600 (com margem)

- [ ] **Step 1: Adicionar Area2D ao stage_01.tscn**

Abrir `stages/stage_01/stage_01.tscn` e adicionar no final (antes do `}` final):

```
[sub_resource type="RectangleShape2D" id="ShapeZ4ShaftCam"]
size = Vector2(700, 3600)

[node name="Z4ShaftCamArea" type="Area2D" parent="."]
position = Vector2(17648, 591)
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="Z4ShaftCamArea"]
shape = SubResource("ShapeZ4ShaftCam")
```

`collision_mask = 2` detecta o player (layer 2 = CharacterBody2D do player).

- [ ] **Step 2: Adicionar métodos de callback em stage_01_scene.gd**

Adicionar os dois métodos antes do `_draw()`:

```gdscript
func _on_shaft_body_entered(body: Node2D) -> void:
	if body == _player and _cam_ctrl != null:
		_cam_ctrl.set_shaft_mode(true)

func _on_shaft_body_exited(body: Node2D) -> void:
	if body == _player and _cam_ctrl != null:
		_cam_ctrl.set_shaft_mode(false)
```

- [ ] **Step 3: Conectar signals no `_ready()` de stage_01_scene.gd**

Após `super._ready()`, adicionar:

```gdscript
	var shaft_area := get_node_or_null("Z4ShaftCamArea") as Area2D
	if shaft_area:
		shaft_area.body_entered.connect(_on_shaft_body_entered)
		shaft_area.body_exited.connect(_on_shaft_body_exited)
```

- [ ] **Step 4: Export + verificar**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "D:/SnesGame" --export-release "Web" "D:/SnesGame/export/web/index.html" 2>&1 | tail -5
```

Esperado: `[ DONE ] savepack` sem erros.

- [ ] **Step 5: Commit + push + merge master**

```bash
cd D:/SnesGame
git add stages/stage_01/stage_01.tscn stages/stage_01/stage_01_scene.gd export/web/
git commit -m "feat(camera): shaft Z4 stage_01 — Area2D activa modo shaft do CameraController"
git push origin fix/z4-shaft-tweaks
cd D:/SnesGame/.worktrees/other-stages-enemies
git merge origin/fix/z4-shaft-tweaks --no-edit
git push origin master
```

- [ ] **Step 6: Reiniciar servidor local**

```powershell
powershell -Command "
  \$pids = (netstat -ano | findstr ':8080' | ForEach-Object { (\$_ -split '\s+')[-1] } | Sort-Object -Unique);
  foreach (\$p in \$pids) { Stop-Process -Id \$p -Force -ErrorAction SilentlyContinue };
  Start-Process python -ArgumentList 'D:\SnesGame\serve_web.py' -WindowStyle Hidden;
  Start-Sleep 2;
  (Invoke-WebRequest http://localhost:8080 -UseBasicParsing).StatusCode
"
```

Esperado: `200`
