# ImgDebug Hitbox/Sprite Editor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Editar com o mouse (no ImgDebug/localhost) hitbox, sprite e offset de projétil dos inimigos — com criar/deletar hitboxes e por-frame — persistindo num JSON que o jogo lê, sem pedir à IA; e deixar a UI do ImgDebug mais limpa.

**Architecture:** Camada de dados `data/hitbox_overrides.json` lida por um autoload `HitboxData` e aplicada em runtime por `EnemyBase`; `serve_web.py` grava/serve o JSON vivo; o ImgDebug ganha dropdowns (UI limpa) e um editor por mouse que salva via POST.

**Tech Stack:** Godot 4.6.2 / GDScript; Python `http.server` (serve_web.py). Testes headless: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/<x>.tscn`.

**Spec:** `docs/superpowers/specs/2026-06-21-imgdebug-hitbox-editor-design.md`

## Global Constraints
- Id do inimigo = basename do `get_script().resource_path` sem extensão (ex.: `enemy_magma_grunt`).
- `data/hitbox_overrides.json` é a fonte de verdade dos valores tunáveis; `.tscn` é só default. Ausência de entrada = usa o `.tscn`.
- `kind`: `"rect"` (size `[w,h]`) ou `"capsule"` (size `[radius,height]`). `target`: `"body"` ou `"contact"`. `frames`: `"all"` ou `[ints]`.
- Sem mudança visual na migração (valores iguais aos atuais).
- Após cada PR: testes headless PASS + web export + reiniciar localhost (skill web-export).
- Tipar explicitamente retornos de `sign()/clamp()/abs()` como `: float` (web export trata como Variant).

---

# FASE A — UI limpa (dropdowns)  [PR 1]

### Task A1: Dropdowns de Tipo/Stage/Entidade

**Files:**
- Modify: `ui/img_debug.gd` (classe `_HitboxView`: `_build`, `_refresh_hierarchy_rows`, `_refresh_stage_row`, `_refresh_entity_row`, `_set_filter`, `_set_stage`; remover os botões empilhados)

**Interfaces:**
- Consumes: `ImgDebug._HITBOX_ENTITIES` (Array de dicts com `name`/`group`/`stage`), `_select_index(i)`, `_filter_group`, `_selected_stage`.
- Produces: seleção via `OptionButton` (mesma semântica de filtro/seleção).

- [ ] **Step 1: Substituir as 3 linhas de botões por um cabeçalho com 3 OptionButton**

Em `_build()`, trocar a criação de `_type_row`/`_stage_row`/`_entity_row` (linhas ~1385-1401) por uma única linha com dropdowns:
```gdscript
        var sel_row := HBoxContainer.new()
        sel_row.add_theme_constant_override("separation", 10)
        root.add_child(sel_row)

        _type_opt = OptionButton.new()
        for g in ["Todos", "Personagens", "Inimigos", "Bosses", "Projeteis"]:
            _type_opt.add_item(g)
        _type_opt.item_selected.connect(func(i): _set_filter(_type_opt.get_item_text(i)))
        sel_row.add_child(_make_label("Tipo:"))
        sel_row.add_child(_type_opt)

        _stage_opt = OptionButton.new()
        _stage_opt.item_selected.connect(func(i): _set_stage(_stage_opt.get_item_text(i)))
        sel_row.add_child(_make_label("Stage:"))
        sel_row.add_child(_stage_opt)

        _entity_opt = OptionButton.new()
        _entity_opt.item_selected.connect(func(_i): _select_index(int(_entity_opt.get_selected_metadata())))
        sel_row.add_child(_make_label("Entidade:"))
        sel_row.add_child(_entity_opt)
```
Declarar os membros (perto de `_type_row` etc.) e um helper de label:
```gdscript
    var _type_opt: OptionButton = null
    var _stage_opt: OptionButton = null
    var _entity_opt: OptionButton = null
```
```gdscript
    func _make_label(txt: String) -> Label:
        var l := Label.new()
        l.text = txt
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        return l
```
Remover as declarações/usos de `_type_row`, `_stage_row`, `_entity_row` (e seus `_clear_container`).

- [ ] **Step 2: Popular os dropdowns de stage/entidade conforme o filtro**

Reescrever `_refresh_hierarchy_rows`/`_refresh_stage_row`/`_refresh_entity_row` para preencher os OptionButton:
```gdscript
    func _refresh_hierarchy_rows() -> void:
        _refresh_stage_options()
        _refresh_entity_options()

    func _refresh_stage_options() -> void:
        if _stage_opt == null:
            return
        _stage_opt.clear()
        var stages := ["Todos"]
        for e in ImgDebug._HITBOX_ENTITIES:
            if _filter_group != "Todos" and String(e.group) != _filter_group:
                continue
            var st := String(e.get("stage", ""))
            if st != "" and not stages.has(st):
                stages.append(st)
        for s in stages:
            _stage_opt.add_item(s)
        # mantém seleção atual se possível
        for i in _stage_opt.item_count:
            if _stage_opt.get_item_text(i) == _selected_stage:
                _stage_opt.select(i)
                return
        _selected_stage = "Todos"
        _stage_opt.select(0)

    func _refresh_entity_options() -> void:
        if _entity_opt == null:
            return
        _entity_opt.clear()
        for i in ImgDebug._HITBOX_ENTITIES.size():
            var e: Dictionary = ImgDebug._HITBOX_ENTITIES[i]
            if _filter_group != "Todos" and String(e.group) != _filter_group:
                continue
            if _selected_stage != "Todos" and String(e.get("stage", "")) != _selected_stage:
                continue
            var idx := _entity_opt.item_count
            _entity_opt.add_item(String(e.name))
            _entity_opt.set_item_metadata(idx, i)
        if _entity_opt.item_count > 0:
            _entity_opt.select(0)
            _select_index(int(_entity_opt.get_selected_metadata()))
```
Ajustar `_set_filter`/`_set_stage` para apenas setar o estado e chamar os refresh acima (sem reconstruir botões):
```gdscript
    func _set_filter(group_name: String) -> void:
        _filter_group = group_name
        _selected_stage = "Todos"
        _refresh_stage_options()
        _refresh_entity_options()

    func _set_stage(stage_name: String) -> void:
        _selected_stage = stage_name
        _refresh_entity_options()
```

- [ ] **Step 3: Verificar carga headless**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://ui/img_debug.tscn --quit-after 5 2>&1 | grep -iE "SCRIPT ERROR|Parse Error" || echo NO-ERRORS`
Expected: `NO-ERRORS`.

- [ ] **Step 4: Commit**
```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): seleção por dropdowns (Tipo/Stage/Entidade) — UI mais limpa"
```

---

### Task A2: Frame como stepper compacto

**Files:**
- Modify: `ui/img_debug.gd` (`_refresh_frame_row` → stepper)

**Interfaces:**
- Consumes: `_frame_count`, `_selected_frame`, `_select_frame(i)`.

- [ ] **Step 1: Trocar a linha de botões de frame por `◀ Frame N/T ▶`**

Reescrever `_refresh_frame_row`:
```gdscript
    func _refresh_frame_row() -> void:
        _clear_container(_frame_row)
        if _frame_count <= 1:
            _frame_row.visible = false
            return
        _frame_row.visible = true
        _frame_row.add_child(_make_button("◀", func(): _select_frame(wrapi(_selected_frame - 1, 0, _frame_count))))
        _frame_lbl = _make_label("Frame %d/%d" % [_selected_frame + 1, _frame_count])
        _frame_row.add_child(_frame_lbl)
        _frame_row.add_child(_make_button("▶", func(): _select_frame(wrapi(_selected_frame + 1, 0, _frame_count))))
```
Declarar `var _frame_lbl: Label = null`. (`_frame_row` HBox já existe.)

- [ ] **Step 2: Verificar carga headless** (como A1 Step 3). Expected `NO-ERRORS`.

- [ ] **Step 3: Commit + PR 1 (web export + push + merge)**
```bash
git checkout -b feat/imgdebug-ui-clean
git add ui/img_debug.gd
git commit -m "feat(imgdebug): frame como stepper compacto"
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" "export/web/index.html"
git add -f export/web/
git commit -m "chore: web export — imgdebug UI limpa"
git push -u origin feat/imgdebug-ui-clean
gh pr create --base master --title "ImgDebug: UI de seleção mais limpa (dropdowns + stepper)" --body "Fase A do editor de hitbox."
gh pr merge --merge
```

---

# FASE B — Camada de dados  [PR 2]

### Task B1: Autoload `HitboxData` + fixture + teste

**Files:**
- Create: `autoloads/hitbox_data.gd`
- Modify: `project.godot` (`[autoload]`)
- Create: `data/hitbox_overrides.json` (inicialmente `{}`)
- Test: `tests/test_hitbox_data.gd` + `.tscn`

**Interfaces:**
- Produces: autoload `HitboxData` com:
  - `func has(id: String) -> bool`
  - `func entry(id: String) -> Dictionary` (vazio se ausente)
  - `func proj_offset(id: String, direction: float) -> Vector2` (retorna `Vector2.INF` se ausente)
  - `func frame_shapes(id: String, frame: int) -> Array` (shapes do alvo body+contact ativos no frame)
  - `func reload() -> void`
  - `signal reloaded`

- [ ] **Step 1: Escrever o teste que falha**

`tests/test_hitbox_data.gd`:
```gdscript
extends Node

func _ready() -> void:
	var fail := false
	# injeta dados direto (sem depender do arquivo)
	HitboxData._data = {
		"enemy_x": {
			"sprite": {"pos": [0, -10], "scale": [1.0, 1.0]},
			"projectile": {"offset": [30, -20]},
			"shapes": [
				{"target": "body", "kind": "rect", "pos": [0, 0], "size": [40, 80], "frames": "all"},
				{"target": "body", "kind": "rect", "pos": [0, 5], "size": [50, 30], "frames": [1, 2]},
			],
		}
	}
	if not HitboxData.has("enemy_x") or HitboxData.has("enemy_none"):
		print("FAIL: has()"); fail = true
	var off := HitboxData.proj_offset("enemy_x", -1.0)
	if off != Vector2(-30, -20):
		print("FAIL: proj_offset espelho (", off, ")"); fail = true
	if HitboxData.proj_offset("enemy_none", 1.0) != Vector2.INF:
		print("FAIL: proj_offset ausente devia ser INF"); fail = true
	# frame 0: só o "all"; frame 1: "all" + o [1,2]
	if HitboxData.frame_shapes("enemy_x", 0).size() != 1:
		print("FAIL: frame_shapes(0)"); fail = true
	if HitboxData.frame_shapes("enemy_x", 1).size() != 2:
		print("FAIL: frame_shapes(1)"); fail = true
	if fail: get_tree().quit(1)
	else: print("PASS: hitbox_data"); get_tree().quit(0)
```
`.tscn` padrão (node "T" + script).

- [ ] **Step 2: Rodar e ver falhar** — autoload não existe → erro/exit 1.

- [ ] **Step 3: Implementar o autoload**

`autoloads/hitbox_data.gd`:
```gdscript
extends Node

signal reloaded

const _PATH := "res://data/hitbox_overrides.json"

var _data: Dictionary = {}

func _ready() -> void:
	_load_baked()

func _load_baked() -> void:
	if not FileAccess.file_exists(_PATH):
		_data = {}
		return
	var f := FileAccess.open(_PATH, FileAccess.READ)
	if f == null:
		_data = {}
		return
	var parsed = JSON.parse_string(f.get_as_text())
	_data = parsed if parsed is Dictionary else {}

func reload() -> void:
	_load_baked()
	reloaded.emit()

func set_data(d: Dictionary) -> void:
	_data = d
	reloaded.emit()

func has(id: String) -> bool:
	return _data.has(id)

func entry(id: String) -> Dictionary:
	return _data.get(id, {})

func proj_offset(id: String, direction: float) -> Vector2:
	var e := entry(id)
	if not e.has("projectile"):
		return Vector2.INF
	var o = e["projectile"].get("offset", null)
	if not (o is Array) or o.size() < 2:
		return Vector2.INF
	return Vector2(float(o[0]) * (1.0 if direction >= 0.0 else -1.0), float(o[1]))

func frame_shapes(id: String, frame: int) -> Array:
	var out: Array = []
	var e := entry(id)
	for s in e.get("shapes", []):
		var fr = s.get("frames", "all")
		if fr == "all" or (fr is Array and fr.has(frame)):
			out.append(s)
	return out
```
Registrar em `project.godot` no bloco `[autoload]` (após `DebugBoot`):
```
HitboxData="*res://autoloads/hitbox_data.gd"
```
Criar `data/hitbox_overrides.json` com `{}`.

- [ ] **Step 4: Rodar e ver passar** — `PASS: hitbox_data`, exit 0.

- [ ] **Step 5: Commit**
```bash
git add autoloads/hitbox_data.gd project.godot data/hitbox_overrides.json tests/test_hitbox_data.gd tests/test_hitbox_data.tscn
git commit -m "feat: autoload HitboxData + data/hitbox_overrides.json (camada de dados)"
```

---

### Task B2: `EnemyBase` aplica overrides (sprite + shapes + por-frame)

**Files:**
- Modify: `characters/enemies/enemy_base.gd`
- Modify: `characters/enemies/stage_01/enemy_ash_hopper.gd` (remove lógica por-frame específica)

**Interfaces:**
- Consumes: `HitboxData.entry(id)`, `HitboxData.frame_shapes(id, frame)`.
- Produces: `EnemyBase._hitbox_id() -> String`; aplicação automática no `_ready`; por-frame automático no `_physics_process` quando há shapes por-frame.

- [ ] **Step 1: Implementar id + apply no `_ready`**

Em `characters/enemies/enemy_base.gd`, trocar `_ready` e adicionar helpers:
```gdscript
var _hb_per_frame: bool = false
var _hb_last_frame: int = -1

func _ready() -> void:
	current_hp = max_hp
	$ContactZone.body_entered.connect(_on_contact)
	_apply_hitbox_data()

func _hitbox_id() -> String:
	var scr := get_script()
	if scr == null:
		return ""
	return scr.resource_path.get_file().get_basename()

func _apply_hitbox_data() -> void:
	var id := _hitbox_id()
	if not HitboxData.has(id):
		return
	var e := HitboxData.entry(id)
	# sprite
	if e.has("sprite") and is_instance_valid(_sprite):
		var sp = e["sprite"]
		if sp.has("pos"): _sprite.position = Vector2(sp["pos"][0], sp["pos"][1])
		if sp.has("scale"): _sprite.scale = Vector2(sp["scale"][0], sp["scale"][1])
	# shapes: por-frame? aplica o frame 0; senão aplica os "all"
	_hb_per_frame = false
	for s in e.get("shapes", []):
		if s.get("frames", "all") != "all":
			_hb_per_frame = true
			break
	_apply_hitbox_frame(0)

func _apply_hitbox_frame(frame: int) -> void:
	var id := _hitbox_id()
	var shapes := HitboxData.frame_shapes(id, frame)
	if shapes.is_empty():
		return
	_rebuild_shapes("body", shapes)
	_rebuild_shapes("contact", shapes)
	_hb_last_frame = frame

func _rebuild_shapes(target: String, shapes: Array) -> void:
	var host: Node = self if target == "body" else get_node_or_null("ContactZone")
	if host == null:
		return
	for c in host.get_children():
		if c is CollisionShape2D:
			c.queue_free()
	for s in shapes:
		if String(s.get("target", "")) != target:
			continue
		var cs := CollisionShape2D.new()
		cs.position = Vector2(s["pos"][0], s["pos"][1])
		if String(s.get("kind", "rect")) == "capsule":
			var cap := CapsuleShape2D.new()
			cap.radius = float(s["size"][0]); cap.height = float(s["size"][1])
			cs.shape = cap
		else:
			var r := RectangleShape2D.new()
			r.size = Vector2(s["size"][0], s["size"][1])
			cs.shape = r
		host.add_child(cs)
```
Nota: `_rebuild_shapes` recria os `CollisionShape2D` do alvo. Como roda no `_ready` antes do primeiro frame, é seguro.

- [ ] **Step 2: Por-frame no `_physics_process` (genérico)**

`EnemyBase` não controla `_anim_frame` de todos os subtipos uniformemente, então exponha um hook que os subtipos já chamam via `_advance_sprite_frame_loop`. Adicionar ao fim de `_advance_sprite_frame_loop`:
```gdscript
func _advance_sprite_frame_loop(delta: float, frame_count: int, fps: float) -> int:
	_animate_sprite_frames(delta, frame_count, fps)
	var fr: int = _sprite.frame if is_instance_valid(_sprite) else 0
	if _hb_per_frame and fr != _hb_last_frame:
		_apply_hitbox_frame(fr)
	return fr
```

- [ ] **Step 3: Migrar o `ash_hopper` p/ data-driven**

Em `characters/enemies/stage_01/enemy_ash_hopper.gd`, **remover** `_FRAME_BOX`, `_FOOT_Y`, `_body_cs`, `_contact_cs`, `_last_box_frame`, `apply_frame_hitbox` e a chamada `apply_frame_hitbox(_anim_frame)`/`apply_frame_hitbox(0)`. O `_physics_process` mantém só o gameplay (gravidade/hop/flip) + `_advance_sprite_frame_loop(delta, FRAMES, FPS)` (o por-frame agora vem do `HitboxData`). O `_ready` fica:
```gdscript
func _ready() -> void:
	max_hp = 7
	contact_damage = 7
	super._ready()
```
(Os dados por-frame do ash_hopper entram no JSON na Task B4.)

- [ ] **Step 4: Verificar carga headless de um inimigo + ash_hopper**

Run (cada um deve dar NO-ERRORS):
```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://characters/enemies/stage_01/enemy_ash_hopper.tscn --quit-after 2 2>&1 | grep -iE "SCRIPT ERROR|Parse Error" || echo NO-ERRORS
```

- [ ] **Step 5: Commit**
```bash
git add characters/enemies/enemy_base.gd characters/enemies/stage_01/enemy_ash_hopper.gd
git commit -m "feat(enemies): EnemyBase aplica overrides do HitboxData (sprite/shapes/por-frame); ash_hopper data-driven"
```

---

### Task B3: Atiradores leem offset do projétil do HitboxData

**Files:**
- Modify: `characters/enemies/stage_01/enemy_ember_orbiter.gd`, `enemy_cinder_flyer.gd`, `enemy_heat_mortar.gd`, `enemy_magma_turret.gd`, `enemy_lava_serpent.gd`

**Interfaces:**
- Consumes: `HitboxData.proj_offset(id, direction)`.

- [ ] **Step 1: Helper de offset com fallback**

Em cada atirador, no ponto onde calcula `proj.global_position = global_position + Vector2(...)`, trocar pelo padrão:
```gdscript
	var ov := HitboxData.proj_offset(_hitbox_id(), _direction)
	var off := ov if ov != Vector2.INF else Vector2(<DEFAULT_X>, <DEFAULT_Y>)
	proj.global_position = global_position + off
```
Valores `<DEFAULT_X/Y>` = os atuais de cada um:
- `enemy_ember_orbiter._fire_bolt`: default `Vector2(10.0, 40.0)` (hoje fixo; sem `_direction` → usar `proj_offset(id, 1.0)`)
- `enemy_cinder_flyer._fire_bolt`: default `Vector2(10.0, 40.0)` (`proj_offset(id, 1.0)`)
- `enemy_heat_mortar._fire`: default `Vector2(_direction * 17.0, -40.0)`
- `enemy_magma_turret._fire`: default `Vector2(_direction * 38.0, -5.0)`
- `enemy_lava_serpent._fire`: default `Vector2(0.0, -20.0)` (`proj_offset(id, 1.0)`)

Para os que hoje usam offset fixo sem direção (orbiter/cinder/serpent), chamar `HitboxData.proj_offset(_hitbox_id(), 1.0)` (direção +1 = não espelha).

- [ ] **Step 2: Verificar carga headless** dos 5 (NO-ERRORS) + `tests/test_stage01_fire_enemies` PASS.

- [ ] **Step 3: Commit**
```bash
git add characters/enemies/stage_01/enemy_ember_orbiter.gd characters/enemies/stage_01/enemy_cinder_flyer.gd characters/enemies/stage_01/enemy_heat_mortar.gd characters/enemies/stage_01/enemy_magma_turret.gd characters/enemies/stage_01/enemy_lava_serpent.gd
git commit -m "feat(stage01): atiradores leem offset do projétil do HitboxData (fallback ao atual)"
```

---

### Task B4: Migrar valores atuais do roster de fogo p/ o JSON

**Files:**
- Modify: `data/hitbox_overrides.json`
- Test: `tests/test_stage01_fire_enemies.tscn` (deve seguir PASS)

- [ ] **Step 1: Preencher o JSON com os valores hoje nos `.tscn`/código**

Escrever `data/hitbox_overrides.json` com uma entrada por inimigo refletindo os valores atuais. Conferir cada `.tscn` antes de escrever (os números abaixo são os atuais do plano; validar com `git show`/leitura):
```json
{
  "enemy_magma_grunt": { "sprite": {"scale":[0.7,0.7]}, "shapes": [
    {"target":"body","kind":"rect","pos":[0,0],"size":[40,80],"frames":"all"},
    {"target":"contact","kind":"rect","pos":[0,0],"size":[40,80],"frames":"all"}] },
  "enemy_molten_ram": { "sprite": {"pos":[0,-20],"scale":[1.0,1.0]}, "shapes": [
    {"target":"body","kind":"rect","pos":[0,-20],"size":[96,96],"frames":"all"},
    {"target":"contact","kind":"rect","pos":[0,-20],"size":[96,96],"frames":"all"}] },
  "enemy_ash_hopper": { "sprite": {"scale":[0.6,0.6]}, "shapes": [
    {"target":"body","kind":"rect","pos":[0,15],"size":[52,30],"frames":[0,1,4]},
    {"target":"body","kind":"rect","pos":[0,0],"size":[52,60],"frames":[2,3,5]},
    {"target":"contact","kind":"rect","pos":[0,15],"size":[52,30],"frames":[0,1,4]},
    {"target":"contact","kind":"rect","pos":[0,0],"size":[52,60],"frames":[2,3,5]}] },
  "enemy_ember_orbiter": { "sprite": {"scale":[0.65,0.65]}, "projectile": {"offset":[10,40]}, "shapes": [
    {"target":"body","kind":"rect","pos":[0,0],"size":[36,56],"frames":"all"},
    {"target":"contact","kind":"rect","pos":[0,0],"size":[36,56],"frames":"all"}] },
  "enemy_flame_skimmer": { "sprite": {"scale":[0.7,0.7]}, "shapes": [
    {"target":"body","kind":"rect","pos":[0,0],"size":[88,35],"frames":"all"},
    {"target":"contact","kind":"rect","pos":[0,0],"size":[88,35],"frames":"all"}] },
  "enemy_cinder_flyer": { "sprite": {"scale":[0.65,0.65]}, "projectile": {"offset":[10,40]}, "shapes": [
    {"target":"body","kind":"rect","pos":[0,0],"size":[72,66],"frames":"all"},
    {"target":"contact","kind":"rect","pos":[0,0],"size":[72,66],"frames":"all"}] },
  "enemy_heat_mortar": { "sprite": {"scale":[0.7,0.7]}, "projectile": {"offset":[17,-40]}, "shapes": [
    {"target":"body","kind":"capsule","pos":[0,0],"size":[32,76],"frames":"all"},
    {"target":"contact","kind":"capsule","pos":[0,0],"size":[32,76],"frames":"all"}] },
  "enemy_magma_turret": { "sprite": {"scale":[0.7,0.7]}, "projectile": {"offset":[38,-5]}, "shapes": [
    {"target":"body","kind":"capsule","pos":[-5,0],"size":[29,72],"frames":"all"},
    {"target":"contact","kind":"capsule","pos":[-5,0],"size":[29,72],"frames":"all"}] },
  "enemy_lava_serpent": { "sprite": {"scale":[1.2,1.2]}, "projectile": {"offset":[0,-20]}, "shapes": [
    {"target":"body","kind":"capsule","pos":[0,0],"size":[38,110],"frames":"all"},
    {"target":"contact","kind":"capsule","pos":[0,0],"size":[38,110],"frames":"all"}] }
}
```
Nota: confirmar `magma_turret` capsule com `pos[-5,0]` (o offset que dá +10px à esquerda) e `ash_hopper` frames (1,2,5 = 30 alt; 3,4,6 = 60 alt → índices 0,1,4 e 2,3,5).

- [ ] **Step 2: Rodar testes** — `test_stage01_fire_enemies` PASS (carrega cenas; shapes agora vêm do JSON). Se algum frame inicial != 0 falhar, revisar.

- [ ] **Step 3: Commit**
```bash
git add data/hitbox_overrides.json
git commit -m "feat(stage01): migra hitbox/sprite/projétil do roster de fogo p/ o JSON (sem mudança visual)"
```

---

### Task B5: Leitura "viva" no localhost (HTTP) + reaplicar

**Files:**
- Modify: `autoloads/hitbox_data.gd` (fetch HTTP no web)
- Modify: `characters/enemies/enemy_base.gd` (reaplicar ao `HitboxData.reloaded`)

**Interfaces:**
- Consumes: `HitboxData.reloaded` (signal).

- [ ] **Step 1: Buscar o JSON vivo no web via HTTPRequest**

Em `hitbox_data.gd`, no `_ready`, após `_load_baked()`, em web tentar o arquivo vivo servido pelo `serve_web.py`:
```gdscript
func _ready() -> void:
	_load_baked()
	if OS.has_feature("web"):
		var req := HTTPRequest.new()
		add_child(req)
		req.request_completed.connect(_on_live_fetch)
		req.request("/hitbox_overrides.json")

func _on_live_fetch(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if code != 200:
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Dictionary:
		_data = parsed
		reloaded.emit()
```

- [ ] **Step 2: Inimigos reaplicam quando o data carrega/atualiza**

Em `EnemyBase._ready`, conectar:
```gdscript
	HitboxData.reloaded.connect(_apply_hitbox_data)
```
(`_apply_hitbox_data` é idempotente — reconstrói shapes.)

- [ ] **Step 3: Verificar carga headless** (NO-ERRORS) + `test_stage01_fire_enemies` PASS + `test_hitbox_data` PASS.

- [ ] **Step 4: Commit + PR 2 (web export + push + merge)**
```bash
git checkout -b feat/imgdebug-data-layer
git add autoloads/hitbox_data.gd characters/enemies/enemy_base.gd
git commit -m "feat: HitboxData busca JSON vivo no localhost + inimigos reaplicam"
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" "export/web/index.html"
git add -f export/web/
git commit -m "chore: web export — camada de dados de hitbox"
git push -u origin feat/imgdebug-data-layer
gh pr create --base master --title "ImgDebug: camada de dados (HitboxData + JSON)" --body "Fase B do editor de hitbox."
gh pr merge --merge
```

---

# FASE C — Editor por mouse + salvar  [PR 3]

> A aba Hitbox (`_HitboxView`) ganha um modo edição. O estado editado é um `Dictionary` espelhando a entrada do `HitboxData` para o inimigo atual; ao salvar, faz POST e recarrega.

### Task C1: `serve_web.py` grava/serve o JSON

**Files:**
- Modify: `serve_web.py`

**Interfaces:**
- Produces: `GET /hitbox_overrides.json` (lê `data/hitbox_overrides.json` do projeto); `POST /save-hitbox` body `{id, data}` → merge e grava.

- [ ] **Step 1: Adicionar GET/POST do JSON**

Em `serve_web.py`, ampliar o Handler:
```python
import json

PROJECT_DIR = os.path.dirname(__file__)
HITBOX_JSON = os.path.join(PROJECT_DIR, "data", "hitbox_overrides.json")

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self):
        if self.path.split("?")[0] == "/hitbox_overrides.json":
            try:
                with open(HITBOX_JSON, "rb") as f:
                    body = f.read()
            except OSError:
                body = b"{}"
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()

    def do_POST(self):
        if self.path.split("?")[0] != "/save-hitbox":
            self.send_response(404); self.end_headers(); return
        length = int(self.headers.get("Content-Length", 0))
        payload = json.loads(self.rfile.read(length).decode("utf-8"))
        try:
            with open(HITBOX_JSON, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (OSError, ValueError):
            data = {}
        data[payload["id"]] = payload["data"]
        os.makedirs(os.path.dirname(HITBOX_JSON), exist_ok=True)
        with open(HITBOX_JSON, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        self.send_response(200); self.end_headers(); self.wfile.write(b"ok")

    def log_message(self, format, *args):
        pass
```

- [ ] **Step 2: Testar manualmente** (servidor + curl)
```bash
python serve_web.py &  # ou via skill web-export
curl -s -X POST http://localhost:8080/save-hitbox -d '{"id":"enemy_test","data":{"sprite":{"scale":[1,1]}}}'
curl -s http://localhost:8080/hitbox_overrides.json | grep enemy_test && echo OK
```
Depois remover a entrada de teste do `data/hitbox_overrides.json`.

- [ ] **Step 3: Commit**
```bash
git add serve_web.py
git commit -m "feat(serve_web): GET/POST de data/hitbox_overrides.json p/ o editor"
```

---

### Task C2: Estado editável + alças de seleção/redimensão no overlay

**Files:**
- Modify: `ui/img_debug.gd` (`_HitboxView`: estado de edição, desenho de alças no `_HitboxOverlay`, hit-test, input)

**Interfaces:**
- Consumes: `HitboxData.entry(id)`, `_current_instance`, `_shape_overlay`.
- Produces: `_edit` Dictionary (cópia da entrada do inimigo atual), seleção de shape, manipulação por mouse.

- [ ] **Step 1: Carregar estado editável ao selecionar inimigo**

Em `_select_index`/após `_load_entity`, montar `_edit` a partir do `HitboxData.entry(id)` (ou derivar dos shapes atuais da instância se ausente). Declarar:
```gdscript
    var _edit: Dictionary = {}
    var _edit_id: String = ""
    var _sel_shape: int = -1   # índice em _edit["shapes"]
```
```gdscript
    func _load_edit_state() -> void:
        _edit_id = _entity_hitbox_id()
        _edit = HitboxData.entry(_edit_id).duplicate(true)
        if _edit.is_empty():
            _edit = {"shapes": []}
        _sel_shape = (_edit["shapes"].size() - 1) if _edit.get("shapes", []).size() > 0 else -1
```
`_entity_hitbox_id()` = basename do script da entidade atual (`_current_instance.get_script().resource_path`).

- [ ] **Step 2: Desenhar alças do shape selecionado no overlay**

No `_HitboxOverlay`, adicionar `var edit_shapes: Array = []` e `var sel_shape: int = -1` e desenhar, no `_draw`, retângulos de alça nos cantos/bordas do shape selecionado (8 alças) + contorno destacado. Ex.:
```gdscript
    func _draw_edit_handles() -> void:
        if sel_shape < 0 or sel_shape >= edit_shapes.size():
            return
        var s: Dictionary = edit_shapes[sel_shape]
        var c := ruler_origin + Vector2(s["pos"][0], s["pos"][1])
        var half := Vector2(s["size"][0], s["size"][1]) * 0.5
        var hs := 5.0
        for hx in [-1.0, 0.0, 1.0]:
            for hy in [-1.0, 0.0, 1.0]:
                if hx == 0.0 and hy == 0.0: continue
                var hp := c + Vector2(half.x * hx, half.y * hy)
                draw_rect(Rect2(hp - Vector2(hs, hs), Vector2(hs*2, hs*2)), Color(1,1,0,0.95))
```
Chamar em `_draw` quando em modo edição. Setar `edit_shapes`/`sel_shape`/`ruler_origin` a partir do `_HitboxView` a cada mudança (`queue_redraw`).

- [ ] **Step 3: Verificar carga headless** (NO-ERRORS).

- [ ] **Step 4: Commit**
```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): estado editável + alças do shape selecionado"
```

---

### Task C3: Arraste — mover/redimensionar hitbox, mover/escalar sprite, mover projétil

**Files:**
- Modify: `ui/img_debug.gd` (`_gui_input`/`_input` no viewport container; conversão tela→mundo via câmera; aplica no `_edit` e re-aplica na instância)

**Interfaces:**
- Consumes: `_edit`, `_sel_shape`, `_camera` (zoom/pos), `_current_instance`.
- Produces: edição ao vivo (instância reflete o `_edit` imediatamente).

- [ ] **Step 1: Conversão de coordenadas tela→mundo**

Helper no `_HitboxView`:
```gdscript
    func _screen_to_world(p: Vector2) -> Vector2:
        # p em px do viewport (900-ish); câmera centra _camera.global_position com zoom
        var vp := _viewport.size
        return _camera.global_position + (p - Vector2(vp) * 0.5) / _camera.zoom
```

- [ ] **Step 2: Máquina de arraste**

Capturar mouse no `SubViewportContainer` (via `gui_input`): em `MOUSE_BUTTON_LEFT` pressed, hit-test alças/shape/sprite/marcador de projétil → setar modo (`resize_<dir>`/`move_shape`/`move_sprite`/`scale_sprite`/`move_proj`); em motion, atualizar o `_edit` (em game-px, arredondado a inteiro) ancorando pelos pés quando redimensiona verticalmente; em release, encerrar. Após cada motion: `_apply_edit_to_instance()` + `_shape_overlay.queue_redraw()`.

`_apply_edit_to_instance()` reusa a lógica de reconstrução (chama o mesmo `_rebuild_shapes`-equivalente, ou injeta `_edit` no `HitboxData` temporariamente e chama `_current_instance._apply_hitbox_data()`):
```gdscript
    func _apply_edit_to_instance() -> void:
        if _current_instance == null: return
        HitboxData._data[_edit_id] = _edit
        if _current_instance.has_method("_apply_hitbox_data"):
            _current_instance._apply_hitbox_data()
        _shape_overlay.edit_shapes = _edit.get("shapes", [])
        _shape_overlay.sel_shape = _sel_shape
        _shape_overlay.queue_redraw()
```
Nota de implementação: passos de 1 game-px; redimensão por alça move só a borda correspondente (ajusta `size` e `pos` para manter a borda oposta fixa). Sprite: arrastar muda `_edit["sprite"]["pos"]`; alça de canto muda `scale`. Projétil: arrastar o marcador muda `_edit["projectile"]["offset"]`.

- [ ] **Step 3: Verificar carga headless** (NO-ERRORS) + abrir manualmente no localhost p/ conferir arraste.

- [ ] **Step 4: Commit**
```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): arraste do mouse edita hitbox/sprite/projétil ao vivo"
```

---

### Task C4: CRUD de hitbox + toggle por-frame

**Files:**
- Modify: `ui/img_debug.gd`

- [ ] **Step 1: Botões + Hitbox / Deletar / alvo / por-frame**

Na toolbar do editor, adicionar:
- `"+ Hitbox"`: anexa a `_edit["shapes"]` um rect default `{"target": _edit_target, "kind":"rect","pos":[0,0],"size":[40,40],"frames": _frame_scope()}` e seleciona-o.
- `"Deletar"`: remove `_edit["shapes"][_sel_shape]`.
- Dropdown alvo (`body`/`contact`) p/ novos shapes.
- Toggle `"Este frame / Todos"`: define se a edição/criação usa `frames:[_selected_frame]` ou `"all"`.
```gdscript
    func _frame_scope() -> Variant:
        return [_selected_frame] if _edit_this_frame else "all"
```
Após qualquer mudança: `_apply_edit_to_instance()`.

- [ ] **Step 2: Verificar carga headless** (NO-ERRORS).

- [ ] **Step 3: Commit**
```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): criar/deletar hitbox + escopo por-frame no editor"
```

---

### Task C5: Salvar (POST) + recarregar

**Files:**
- Modify: `ui/img_debug.gd`

- [ ] **Step 1: Botão Salvar → POST + reload**
```gdscript
    func _on_save() -> void:
        var req := HTTPRequest.new()
        add_child(req)
        req.request_completed.connect(func(_r,_c,_h,_b): req.queue_free(); HitboxData.reload())
        var payload := JSON.stringify({"id": _edit_id, "data": _edit})
        req.request("/save-hitbox", PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, payload)
```
Adicionar botão `"Salvar"` na toolbar do editor chamando `_on_save`.

- [ ] **Step 2: Verificar carga headless** (NO-ERRORS).

- [ ] **Step 3: Validação manual (localhost)**: selecionar inimigo → arrastar → Salvar → conferir `data/hitbox_overrides.json` atualizado e o preview refletindo após reload.

- [ ] **Step 4: Commit + PR 3 (web export + push + merge)**
```bash
git checkout -b feat/imgdebug-mouse-editor
git add ui/img_debug.gd serve_web.py
git commit -m "feat(imgdebug): editor por mouse — salvar via serve_web + reload"
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --export-release "Web" "export/web/index.html"
git add -f export/web/
git commit -m "chore: web export — editor de hitbox por mouse"
git push -u origin feat/imgdebug-mouse-editor
gh pr create --base master --title "ImgDebug: editor de hitbox/sprite por mouse + salvar" --body "Fase C do editor de hitbox."
gh pr merge --merge
```

---

## Self-review (cobertura do spec)
- Fase A (UI dropdowns + frame stepper) → Tasks A1, A2.
- Fase B (JSON + HitboxData + apply + por-frame + projétil + migração + live) → B1–B5.
- Fase C (serve_web GET/POST + alças + arraste + CRUD/por-frame + salvar) → C1–C5.
- Id = basename do script → B2 `_hitbox_id`.
- Fonte de verdade = JSON → B2/B4 (shapes vêm do JSON; .tscn é default).
- Localhost live vs Pages baked → B1 (`_load_baked`) + B5 (HTTP fetch).
- Criar/deletar + por-frame por mouse → C4.

**Pontos a confirmar na implementação (ler antes de codar):** valores atuais exatos de cada `.tscn` do roster (confirmar antes de escrever B4); assinatura real de `_camera.zoom`/`_viewport.size` no `_HitboxView`; e se algum atirador usa `_direction` no offset (heat_mortar/turret sim; orbiter/cinder/serpent não).
