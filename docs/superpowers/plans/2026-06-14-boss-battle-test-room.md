# Sala de Teste de Batalha (ImgDebug › BATALHA) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar uma seção **BATALHA** ao `ImgDebug` que abre uma sala de treino, no tamanho real da sala do boss do Stage 00, onde o jogador escolhe um dos 11 bosses e luta com o Zael (boss e player com HP 99999 — treino).

**Architecture:** Tudo dentro de `ui/img_debug.gd`, seguindo o padrão já existente da seção MOVIMENTOS (`_MovView` + `_MovWorld`). Duas novas classes internas: `_BossBattleWorld` (Node2D — sala fechada + física + Zael + boss) e `_BossBattleView` (Control — tela de seleção em grade + `SubViewport` da sala). Lista de bosses num const top-level `_BOSS_BATTLE` (idiom igual a `_HITBOX_ENTITIES`). A tela de seleção é o hub: ESC/Enter dentro da sala voltam a ela; o botão "Sair" fecha a seção.

**Tech Stack:** Godot 4.6.2, GDScript. Todos os bosses extendem `BossBase`. Verificação por parse-check headless + um teste headless (`extends Node` + `.tscn`, convenção do projeto).

---

## File Structure

| Arquivo | Responsabilidade | Ação |
|---------|------------------|------|
| `ui/img_debug.gd` | Overlay de debug; ganha o const `_BOSS_BATTLE`, as classes internas `_BossBattleWorld`/`_BossBattleView`, e a fiação da seção BATALHA | Modificar |
| `tests/test_boss_battle.gd` | Teste headless: instancia `_BossBattleWorld`, itera `load_boss` sobre os 11 bosses, valida instância/estado | Criar |
| `tests/test_boss_battle.tscn` | Cena associada ao teste (`extends Node`) | Criar |

**Comando de parse-check** (usado em quase toda task):

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script ui/img_debug.gd
```
Saída esperada em sucesso: **nenhum erro de parse, exit code 0**. Em erro, imprime a linha do erro e retorna != 0.

---

## Task 1: Const `_BOSS_BATTLE` + classe interna `_BossBattleWorld`

**Files:**
- Modify: `ui/img_debug.gd` (adicionar const perto de `_HITBOX_ENTITIES` ~linha 25; anexar classe interna ao final do arquivo, após a linha 3292)

- [ ] **Step 1: Adicionar o const top-level `_BOSS_BATTLE`**

Logo após o fechamento do array `const _HITBOX_ENTITIES: Array = [ ... ]` (termina na linha 57 com `]`), inserir:

```gdscript
const _BOSS_BATTLE: Array = [
    {"name": "Ignarath",    "path": "res://characters/bosses/ignarath.tscn"},
    {"name": "Cryovex",     "path": "res://characters/bosses/cryovex.tscn"},
    {"name": "Voltrix",     "path": "res://characters/bosses/voltrix.tscn"},
    {"name": "Gravitus",    "path": "res://characters/bosses/gravitus.tscn"},
    {"name": "Galerix",     "path": "res://characters/bosses/galerix.tscn"},
    {"name": "Umbraex",     "path": "res://characters/bosses/umbraex.tscn"},
    {"name": "Luxar",       "path": "res://characters/bosses/luxar.tscn"},
    {"name": "Terragor",    "path": "res://characters/bosses/terragor.tscn"},
    {"name": "IntroBoss",   "path": "res://characters/bosses/intro_boss.tscn"},
    {"name": "Nullvex",     "path": "res://characters/bosses/nullvex.tscn"},
    {"name": "Nullvex True","path": "res://characters/bosses/nullvex_true.tscn"},
]
```

- [ ] **Step 2: Anexar a classe interna `_BossBattleWorld` ao final do arquivo**

Adicionar ao final de `ui/img_debug.gd` (após a última linha):

```gdscript

# ── Sala de teste de batalha (seção BATALHA) ─────────────────────────────────
# Caixa fechada nas dimensões reais da sala do boss do Stage 00 (15×8 tiles de
# 64px; interior 832×384). Espelha o padrão de _MovWorld. Treino: player e boss
# com HP 99999. tile_tex deve ser setado ANTES do add_child (usado em _draw).
class _BossBattleWorld extends Node2D:
    const _TS      := 64.0
    const _SRC     := 32.0
    const _COLS    := 15
    const _ROWS    := 8
    const _FLOOR_Y := 448.0   # superfície do chão (topo) — coords locais
    const _WALL_L  := 64.0     # face interna parede esquerda
    const _WALL_R  := 896.0    # face interna parede direita
    const _MARGIN  := 80.0     # margem lateral da arena do boss

    var tile_tex: Texture2D = null
    var _player: CharacterBase = null
    var _boss: Node2D = null

    func _ready() -> void:
        texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        GameManager.zael_selected_shot = "single"
        _build_room()
        _spawn_player()
        var cam := Camera2D.new()
        cam.global_position = Vector2(480.0, 256.0)  # centro da sala
        cam.zoom = Vector2(1.0, 1.0)                 # sala 960px preenche o SubViewport
        add_child(cam)

    func _build_room() -> void:
        _add_wall(Vector2(480.0, 480.0), Vector2(960.0, 64.0))  # chão
        _add_wall(Vector2(480.0, 32.0),  Vector2(960.0, 64.0))  # teto
        _add_wall(Vector2(32.0, 256.0),  Vector2(64.0, 512.0))  # parede esq
        _add_wall(Vector2(928.0, 256.0), Vector2(64.0, 512.0))  # parede dir

    func _add_wall(center: Vector2, size: Vector2) -> void:
        var body := StaticBody2D.new()
        body.collision_layer = 1
        body.collision_mask = 0
        var cs := CollisionShape2D.new()
        var shape := RectangleShape2D.new()
        shape.size = size
        cs.shape = shape
        cs.position = center
        body.add_child(cs)
        add_child(body)

    func _spawn_player() -> void:
        if is_instance_valid(_player):
            _player.queue_free()
        var scene := load("res://characters/ranged/zael.tscn") as PackedScene
        if scene == null:
            return
        _player = scene.instantiate() as CharacterBase
        _player.add_to_group("player")
        add_child(_player)
        _player.global_position = Vector2(220.0, _FLOOR_Y - 90.0)
        _player.max_hp = 99999
        _player.current_hp = 99999
        _player.died.connect(func(): call_deferred("_spawn_player"))
        if is_instance_valid(_boss):
            (_boss as BossBase).player = _player

    func load_boss(idx: int) -> void:
        if is_instance_valid(_boss):
            _boss.queue_free()
            _boss = null
        if idx < 0 or idx >= ImgDebug._BOSS_BATTLE.size():
            return
        var scene := load(ImgDebug._BOSS_BATTLE[idx].path) as PackedScene
        if scene == null:
            return
        var boss := scene.instantiate() as BossBase
        add_child(boss)
        boss.global_position = Vector2(680.0, _FLOOR_Y - 120.0)
        boss.player      = _player
        boss.arena_left  = _WALL_L + _MARGIN
        boss.arena_right = _WALL_R - _MARGIN
        boss.arena_floor = _FLOOR_Y
        boss.max_hp      = 99999
        boss.current_hp  = 99999
        boss.state       = BossBase.State.COMBAT
        _boss = boss

    func _draw() -> void:
        if tile_tex == null:
            return
        # Fundo escuro (igual ao boss room background do stage)
        draw_rect(Rect2(0.0, 0.0, _COLS * _TS, _ROWS * _TS), Color(0.05, 0.05, 0.12))
        # Caixa fechada — mapeamento canônico de _draw_boss_room (sem abertura de porta)
        var ts := _TS
        var src := _SRC
        for row in _ROWS:
            for col in _COLS:
                var is_l := col == 0
                var is_r := col == _COLS - 1
                var is_t := row == 0
                var is_b := row == _ROWS - 1
                if not (is_l or is_r or is_t or is_b):
                    continue
                var tile: Vector2i
                var tx := 0.0
                var ty := 0.0
                if   is_t and is_l: tile = Vector2i(3, 1); tx =  src; ty =  src
                elif is_t and is_r: tile = Vector2i(2, 2); tx = -src; ty =  src
                elif is_b and is_l: tile = Vector2i(2, 0); tx =  src; ty = -src
                elif is_b and is_r: tile = Vector2i(1, 1); tx = -src; ty = -src
                elif is_t:          tile = Vector2i(1, 2);            ty =  src
                elif is_b:          tile = Vector2i(3, 0);            ty = -src
                elif is_l:          tile = Vector2i(3, 2); tx =  src
                else:               tile = Vector2i(1, 0); tx = -src
                var dx := col * ts + tx
                var dy := row * ts + ty
                draw_texture_rect_region(tile_tex,
                    Rect2(dx, dy, ts, ts),
                    Rect2(tile.x * src, tile.y * src, src, src))
```

- [ ] **Step 3: Rodar parse-check**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script ui/img_debug.gd
```
Expected: exit code 0, sem erros de parse.

- [ ] **Step 4: Commit**

```bash
git add ui/img_debug.gd
git commit -m "feat: _BossBattleWorld — sala fechada real-size + Zael + load_boss

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Classe interna `_BossBattleView` (tela de seleção + SubViewport)

**Files:**
- Modify: `ui/img_debug.gd` (anexar classe interna ao final, após `_BossBattleWorld`)

- [ ] **Step 1: Anexar a classe `_BossBattleView`**

Adicionar ao final de `ui/img_debug.gd`, depois da classe `_BossBattleWorld`:

```gdscript

# ── View da seção BATALHA: tela de seleção (hub) + SubViewport da sala ────────
class _BossBattleView extends Control:
    signal exit_requested

    var _grid_box: VBoxContainer = null
    var _svc: SubViewportContainer = null
    var _world: ImgDebug._BossBattleWorld = null
    var _in_battle := false

    func _ready() -> void:
        set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        _build_selection()
        show_selection()

    func _build_selection() -> void:
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 12)
        add_child(box)
        _grid_box = box

        var title := Label.new()
        title.text = "Escolha o boss  (ESC/Enter na sala = voltar aqui)"
        title.add_theme_font_size_override("font_size", 26)
        title.add_theme_color_override("font_color", Color(0.85, 0.8, 1.0))
        box.add_child(title)

        var grid := GridContainer.new()
        grid.columns = 4
        grid.add_theme_constant_override("h_separation", 8)
        grid.add_theme_constant_override("v_separation", 8)
        box.add_child(grid)
        for i in ImgDebug._BOSS_BATTLE.size():
            var btn := Button.new()
            btn.text = ImgDebug._BOSS_BATTLE[i].name
            btn.add_theme_font_size_override("font_size", 24)
            btn.custom_minimum_size = Vector2(240.0, 56.0)
            btn.pressed.connect(_enter_battle.bind(i))
            grid.add_child(btn)

        var exit_btn := Button.new()
        exit_btn.text = "Sair"
        exit_btn.add_theme_font_size_override("font_size", 24)
        exit_btn.custom_minimum_size = Vector2(160.0, 48.0)
        exit_btn.pressed.connect(func(): exit_requested.emit())
        box.add_child(exit_btn)

    func _ensure_world() -> void:
        if _svc != null:
            return
        _svc = SubViewportContainer.new()
        _svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        _svc.stretch = true
        add_child(_svc)
        var svp := SubViewport.new()
        svp.size = Vector2i(960, 540)
        svp.handle_input_locally = false
        _svc.add_child(svp)
        var w := ImgDebug._BossBattleWorld.new()
        w.tile_tex = load("res://stages/stage_00/Stage_00T.png") as Texture2D
        svp.add_child(w)
        _world = w

    func _enter_battle(idx: int) -> void:
        _ensure_world()
        _world.load_boss(idx)
        _grid_box.visible = false
        _svc.visible = true
        _in_battle = true

    func show_selection() -> void:
        _in_battle = false
        if _svc != null:
            _svc.visible = false
        if _grid_box != null:
            _grid_box.visible = true

    func _unhandled_key_input(event: InputEvent) -> void:
        if not _in_battle:
            return
        if event is InputEventKey and event.pressed and not event.echo:
            var kc: int = (event as InputEventKey).keycode
            if kc == KEY_ESCAPE or kc == KEY_ENTER or kc == KEY_KP_ENTER:
                show_selection()
                get_viewport().set_input_as_handled()
```

- [ ] **Step 2: Rodar parse-check**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script ui/img_debug.gd
```
Expected: exit code 0, sem erros de parse.

- [ ] **Step 3: Commit**

```bash
git add ui/img_debug.gd
git commit -m "feat: _BossBattleView — tela de seleção (hub) + SubViewport ESC/Enter

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Fiação da seção BATALHA no ImgDebug

**Files:**
- Modify: `ui/img_debug.gd` — vars de seção (~linha 2176), `_build_ui` (botão ~2396 e box ~2463), `_show_section` (~2217)

- [ ] **Step 1: Declarar as variáveis-membro da seção**

Localizar o bloco (linhas ~2176-2180):
```gdscript
var _sprites_box: VBoxContainer
var _tiles_box: VBoxContainer
var _moves_box: VBoxContainer
var _hitboxes_box: VBoxContainer
var _hitbox_view: _HitboxView
```
Inserir logo depois de `var _hitboxes_box: VBoxContainer`:
```gdscript
var _battle_box: VBoxContainer
var _battle_view: _BossBattleView
```

- [ ] **Step 2: Adicionar o botão BATALHA na section_row**

Localizar em `_build_ui` (linhas ~2391-2396):
```gdscript
    var hitbox_btn := Button.new()
    hitbox_btn.text = "HITBOXES"
    hitbox_btn.add_theme_font_size_override("font_size", 28)
    hitbox_btn.pressed.connect(_show_section.bind("HITBOXES"))
    section_row.add_child(hitbox_btn)
    _section_btns["HITBOXES"] = hitbox_btn
```
Inserir imediatamente depois desse bloco:
```gdscript
    var battle_btn := Button.new()
    battle_btn.text = "BATALHA"
    battle_btn.add_theme_font_size_override("font_size", 28)
    battle_btn.pressed.connect(_show_section.bind("BATALHA"))
    section_row.add_child(battle_btn)
    _section_btns["BATALHA"] = battle_btn
```

- [ ] **Step 3: Criar a box e a view da seção**

Localizar o final de `_build_ui` (linhas ~2461-2468):
```gdscript
    _hitboxes_box = VBoxContainer.new()
    _hitboxes_box.add_theme_constant_override("separation", 8)
    main.add_child(_hitboxes_box)
    _hitbox_view = _HitboxView.new()
    _hitbox_view.custom_minimum_size = Vector2(0.0, 520.0)
    _hitbox_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _hitbox_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _hitboxes_box.add_child(_hitbox_view)
```
Inserir imediatamente depois (ainda dentro de `_build_ui`, antes do `func _build_moves_box`):
```gdscript

    # BATALHA BOX
    _battle_box = VBoxContainer.new()
    _battle_box.add_theme_constant_override("separation", 8)
    _battle_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main.add_child(_battle_box)
    _battle_view = _BossBattleView.new()
    _battle_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _battle_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _battle_view.custom_minimum_size = Vector2(0.0, 560.0)
    _battle_view.exit_requested.connect(func(): _show_section("SPRITES"))
    _battle_box.add_child(_battle_view)
```

- [ ] **Step 4: Atualizar `_show_section`**

Localizar (linhas ~2217-2224):
```gdscript
func _show_section(section: String) -> void:
    _section = section
    _sprites_box.visible = (section == "SPRITES")
    _tiles_box.visible   = (section == "TILES")
    _moves_box.visible   = (section == "MOVIMENTOS")
    _hitboxes_box.visible = (section == "HITBOXES")
    for s in _section_btns:
        _section_btns[s].modulate = Color(1, 1, 0) if s == section else Color(0.6, 0.6, 0.6)
```
Substituir por:
```gdscript
func _show_section(section: String) -> void:
    _section = section
    _sprites_box.visible = (section == "SPRITES")
    _tiles_box.visible   = (section == "TILES")
    _moves_box.visible   = (section == "MOVIMENTOS")
    _hitboxes_box.visible = (section == "HITBOXES")
    _battle_box.visible  = (section == "BATALHA")
    if section == "BATALHA" and _battle_view != null:
        _battle_view.show_selection()  # sempre entra pelo hub de seleção
    for s in _section_btns:
        _section_btns[s].modulate = Color(1, 1, 0) if s == section else Color(0.6, 0.6, 0.6)
```

- [ ] **Step 5: Rodar parse-check**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script ui/img_debug.gd
```
Expected: exit code 0, sem erros de parse.

- [ ] **Step 6: Commit**

```bash
git add ui/img_debug.gd
git commit -m "feat: fiar seção BATALHA no ImgDebug (botão/box/show_section)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Teste headless — instanciar todos os bosses na sala

**Files:**
- Create: `tests/test_boss_battle.gd`
- Create: `tests/test_boss_battle.tscn`

- [ ] **Step 1: Escrever o teste (espera FALHAR antes da implementação? Não — implementação já existe nas Tasks 1-3; este teste valida)**

Criar `tests/test_boss_battle.gd`:
```gdscript
# tests/test_boss_battle.gd
# Valida a sala de batalha do ImgDebug: instancia _BossBattleWorld e percorre
# todos os bosses de _BOSS_BATTLE via load_boss, conferindo instância/estado.
# assert() NÃO aborta em headless — usamos _check + quit(code).
extends Node

func _ready() -> void:
    var ok := true
    var world := ImgDebug._BossBattleWorld.new()
    world.tile_tex = load("res://stages/stage_00/Stage_00T.png") as Texture2D
    add_child(world)
    await get_tree().process_frame
    ok = _check(is_instance_valid(world._player), "player Zael spawnado") and ok

    for i in ImgDebug._BOSS_BATTLE.size():
        var boss_name: String = ImgDebug._BOSS_BATTLE[i].name
        world.load_boss(i)
        await get_tree().process_frame
        var b = world._boss
        ok = _check(is_instance_valid(b), "boss %d instanciado (%s)" % [i, boss_name]) and ok
        if is_instance_valid(b):
            ok = _check(b is BossBase, "boss %d é BossBase (%s)" % [i, boss_name]) and ok
            ok = _check(b.state == BossBase.State.COMBAT, "boss %d em COMBAT (%s)" % [i, boss_name]) and ok
            ok = _check(b.player == world._player, "boss %d tem player (%s)" % [i, boss_name]) and ok

    if ok:
        print("ALL BATTLE TESTS PASSED")
        get_tree().quit(0)
    else:
        printerr("BATTLE TESTS FAILED")
        get_tree().quit(1)

func _check(cond: bool, msg: String) -> bool:
    if cond:
        print("  PASS: ", msg)
    else:
        printerr("  FAIL: ", msg)
    return cond
```

- [ ] **Step 2: Criar a cena associada**

Criar `tests/test_boss_battle.tscn`:
```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/test_boss_battle.gd" id="1_test"]

[node name="TestBossBattle" type="Node"]
script = ExtResource("1_test")
```

- [ ] **Step 3: Rodar o teste e conferir exit code**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_boss_battle.tscn; echo "EXIT=$?"
```
Expected: imprime `PASS:` para cada checagem, depois `ALL BATTLE TESTS PASSED` e `EXIT=0`.

Se algum boss falhar ao instanciar (erro de script de boss), o teste imprime `FAIL:` com o nome e retorna `EXIT=1` — investigar esse boss antes de prosseguir.

- [ ] **Step 4: Commit**

```bash
git add tests/test_boss_battle.gd tests/test_boss_battle.tscn
git commit -m "test: sala de batalha — instancia os 11 bosses em COMBAT

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Web export + verificação final

**Files:** nenhum arquivo de código novo (build/deploy).

- [ ] **Step 1: Parse-check final do arquivo inteiro**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --check-only --script ui/img_debug.gd; echo "EXIT=$?"
```
Expected: `EXIT=0`.

- [ ] **Step 2: Rodar a suíte headless existente (regressão rápida)**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn; echo "EXIT=$?"
```
Expected: `EXIT=0` (a seção BATALHA não altera GameManager fora do escopo da sala).

- [ ] **Step 3: Web export**

Usar a skill `web-export` (convenção do projeto: sempre exportar web e reiniciar o localhost após qualquer mudança de código). Seguir o fluxo da skill: exportar o build web e reiniciar o servidor local na porta 8080.

- [ ] **Step 4: Commit do build web (se a skill gerar artefatos versionados)**

```bash
git add -A
git commit -m "chore: web export — seção BATALHA (sala de teste de boss)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review

**1. Spec coverage:**
- Modo treino (HP 99999 boss + player) → Task 1 (`load_boss` e `_spawn_player` setam 99999). ✓
- Roster: 11 bosses → Task 1 const `_BOSS_BATTLE`; grade na Task 2. ✓
- Player só Zael Single → Task 1 (`zael.tscn`, `zael_selected_shot="single"`). ✓
- Seleção em grade → Task 2 (`GridContainer`). ✓
- Sala tamanho real (15×8, interior 832×384, chão y=280→local 448, zoom) → Task 1 (`_build_room`/`_draw`/câmera). ✓
- ESC/Enter voltam à seleção → Task 2 (`_unhandled_key_input`). ✓
- Entrada pela tela de seleção → Task 3 (`_show_section` chama `show_selection`). ✓
- Botão "Sair" volta ao ImgDebug → Task 2 (`exit_requested`) + Task 3 (conecta a `_show_section("SPRITES")`). ✓
- Caixa fechada sem porta → Task 1 (`_draw` sem lógica de door). ✓
- Escopo: só `ui/img_debug.gd` + tests → Tasks 1-4. ✓
- Web export final → Task 5. ✓

**2. Placeholder scan:** Sem TBD/TODO; todo passo tem código ou comando concreto. ✓

**3. Type consistency:**
- `show_selection()` (pública) usada na Task 2 (def), Task 3 (chamada). Consistente — não foi nomeada `_show_selection` em lugar nenhum. ✓
- `_BOSS_BATTLE` (dicionários com `.name`/`.path`) usado igual em World (`.path`) e View (`.name`). ✓
- `_BossBattleWorld` / `_BossBattleView` nomes batem entre definição e referência (`ImgDebug._BossBattleWorld`). ✓
- `BossBase.State.COMBAT`, `arena_left/right/floor`, `max_hp`, `current_hp`, `player`, `state` conferem com `boss_base.gd`. ✓
- `_player.max_hp/current_hp/died/add_to_group` conferem com `character_base.gd`. ✓
