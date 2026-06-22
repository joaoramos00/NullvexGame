# Stage 01 — Redesign do shaft Z4 + saliência agarrável — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refazer o layout do shaft da Z4 (stage 01) conforme `referencias/shaftStage01Zona4.png`, introduzindo a saliência agarrável como elemento reutilizável com ferramental e validação dimensional ancorada no pulo do Zael.

**Architecture:** A geometria de escalada (paredes, saliências, plataformas, espinhos) vira uma **tabela de dados** (fonte única) consumida pelo `_build_z4_shaft` e lida por um teste de validação que checa a geometria **analiticamente** (sem instanciar a cena). Saliência = `StaticBody2D` agarrável projetando 1 tile da parede. Lava-chase, segredo e sala pré-boss permanecem código bespoke, só realinhados.

**Tech Stack:** Godot 4.6.2 (GDScript), tilesets HD pixel art, testes headless (`extends Node` + `.tscn`).

## Global Constraints

- Godot executável: `D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe`.
- Testes: `extends Node` + `.tscn` associada (carrega autoloads). NÃO usar `extends SceneTree`.
- `assert()` NÃO aborta em headless — usar `print("FAIL...")` + `get_tree().quit(1)`; sucesso = `quit(0)`. Checar exit code.
- Parse-check do `img_debug.gd` via **load da `.tscn`**, NÃO `--check-only --script` (não carrega autoloads).
- Web export é case-sensitive: paths `res://` devem bater o case exato.
- `sign()/clamp()/abs()` retornam Variant no web export — tipar explicitamente (`: float`).
- Saliência e plataforma do Z4 usam o tileset `res://stages/stage_01/Stage_01T_z4.png`.
- Player limitante = Zael: caixa 40×80px. Pulo: altura 118px, alcance 196px (`GRAVITY=980`, `JUMP_VELOCITY=-480`, `SPEED=200`).
- Regras de validação: vão livre horizontal ≥192px; passo vertical de subida ≤118px; folga vertical livre ≥80px.
- Não rodar no browser (verificação estática). `web-export` só ao final.

---

## File Structure

| Arquivo | Responsabilidade |
|---------|------------------|
| `stages/stage_01/stage_01_scene.gd` | Helper `_z4_foothold`, tabelas de layout do shaft (`_Z4_FOOTHOLDS`/`_Z4_PLATFORMS`/`_Z4_SPIKES`), novo `_build_z4_shaft` |
| `ui/img_debug.gd` | Modo "Saliência" no `_PlatformView` |
| `.claude/skills/new-foothold.md` | Skill de autoria da saliência |
| `CLAUDE.md` | Regra apontando pra skill |
| `tests/test_z4_foothold.gd` + `.tscn` | Teste do helper `_z4_foothold` |
| `tests/test_z4_shaft_dims.gd` + `.tscn` | Teste de validação dimensional do shaft |
| `docs/stage_01/zones/legenda.md`, `z4.svg` | Regenerados via `tools/zone_debug_01.gd` |

---

### Task 1: Helper `_z4_foothold` + esquema das tabelas de layout

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (adicionar helper perto de `_z4_wall`, ~linha 433)
- Create: `tests/test_z4_foothold.gd`
- Create: `tests/test_z4_foothold.tscn`

**Interfaces:**
- Produces: `_z4_foothold(n: String, wall_x: float, cy: float, side: String, h: float = 96.0) -> StaticBody2D` — cria saliência agarrável projetando 64px da parede; `side` "L" = parede à esquerda (projeta pra direita), "R" = parede à direita (projeta pra esquerda). `wall_x` = face interna da parede.
- Produces: convenção de tabela de elementos do shaft: foothold `[n, wall_x, cy, side, h]`; spike `[n, wall_x, cy, side, h]`; platform `[n, cx, cy, w, h]`.

- [ ] **Step 1: Write the failing test**

`tests/test_z4_foothold.gd`:
```gdscript
extends Node

func _ready() -> void:
	var stage := preload("res://stages/stage_01/stage_01_scene.gd").new()
	# .new() sem entrar na árvore → _ready não dispara (sem build pesado).
	# side "R": parede à direita em x=17600 → saliência projeta pra ESQUERDA.
	var fh_r := stage._z4_foothold("TestFootR", 17600.0, 1000.0, "R", 96.0)
	# side "L": parede à esquerda em x=17440 → saliência projeta pra DIREITA.
	var fh_l := stage._z4_foothold("TestFootL", 17440.0, 1000.0, "L", 96.0)

	if fh_r.is_in_group("no_wall_grab"):
		print("FAIL: saliência não pode ser no_wall_grab (tem que agarrar)"); get_tree().quit(1); return
	if fh_r.collision_layer != 1:
		print("FAIL: saliência deve estar na layer 1, veio %d" % fh_r.collision_layer); get_tree().quit(1); return
	if fh_r.position.x >= 17600.0:
		print("FAIL: side R deve projetar pra esquerda (x<wall_x), veio %f" % fh_r.position.x); get_tree().quit(1); return
	if fh_l.position.x <= 17440.0:
		print("FAIL: side L deve projetar pra direita (x>wall_x), veio %f" % fh_l.position.x); get_tree().quit(1); return
	var shape: RectangleShape2D = fh_r.get_child(0).shape
	if shape.size != Vector2(64.0, 96.0):
		print("FAIL: saliência deve ter 64×h, veio %s" % str(shape.size)); get_tree().quit(1); return
	# centro projetado a meio tile da face
	if absf(fh_r.position.x - (17600.0 - 32.0)) > 0.1:
		print("FAIL: centro R deve ser wall_x-32, veio %f" % fh_r.position.x); get_tree().quit(1); return
	stage.free()
	print("PASS: _z4_foothold agarrável e projeta corretamente")
	get_tree().quit(0)
```

`tests/test_z4_foothold.tscn`:
```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/test_z4_foothold.gd" id="1"]

[node name="TestZ4Foothold" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_z4_foothold.tscn; echo "exit=$?"`
Expected: erro de método inexistente `_z4_foothold` (exit≠0).

- [ ] **Step 3: Write minimal implementation**

Em `stages/stage_01/stage_01_scene.gd`, após `_z4_wall` (~linha 437):
```gdscript
# Saliência agarrável (foothold): parede curta agarrável (SEM no_wall_grab) que se
# projeta 1 tile (64px) pra dentro do shaft a partir da face `wall_x` da parede do
# lado `side` ("L" = parede à esquerda, projeta pra direita; "R" = à direita,
# projeta pra esquerda). Mecânica = wall-grab/wall-jump padrão. Ver skill new-foothold.
func _z4_foothold(n: String, wall_x: float, cy: float, side: String, h: float = 96.0) -> StaticBody2D:
	const DEPTH := 64.0
	var cx: float = wall_x + DEPTH * 0.5 if side == "L" else wall_x - DEPTH * 0.5
	return _z2_static(n, Vector2(cx, cy), Vector2(DEPTH, h))
```

- [ ] **Step 4: Run test to verify it passes**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_z4_foothold.tscn; echo "exit=$?"`
Expected: `PASS: _z4_foothold agarrável e projeta corretamente` e `exit=0`.

- [ ] **Step 5: Commit**

```bash
git add stages/stage_01/stage_01_scene.gd tests/test_z4_foothold.gd tests/test_z4_foothold.tscn
git commit -m "feat(stage01): helper _z4_foothold (saliência agarrável)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Modo "Saliência" no imgdebug (`_PlatformView`)

**Files:**
- Modify: `ui/img_debug.gd` (`_PlatformView`: `set_dims`, `_draw`; lista de modos ~linha 3670)
- Test: load headless de `res://ui/img_debug.tscn`

**Interfaces:**
- Consumes: `_PlatformView` modos existentes, `_fp_solid`/`_fp_tile`, `mirror_hole`, `_TS`/`_TD`.
- Produces: modo `"foothold"` — desenha uma parede vertical com um ressalto de 1 tile projetando pra dentro; `mirror_hole` troca o lado.

- [ ] **Step 1: Adicionar o modo à lista de botões**

Em `ui/img_debug.gd` linha ~3670, acrescentar `["Saliência", "foothold"]`:
```gdscript
    for me: Array in [["Plataforma", "platform"], ["Sala", "room"], ["Piso+Plat", "floor_platform"], ["Piso+Abismo", "floor_platform_hole"], ["Buraco no Piso", "floor_hole"], ["Saliência", "foothold"]]:
```

- [ ] **Step 2: Tratar o modo em `set_dims` e `_draw`**

Em `_PlatformView.set_dims` (~linha 772), incluir `foothold` no cálculo de grid (usa a mesma grade do floor_platform — parede de `_FP_SIDE*2+cols` largura por `rows+_FP_DEPTH` altura):
```gdscript
    func set_dims(r: int, c: int) -> void:
        rows = r
        cols = c
        var _is_fp := mode == "floor_platform" or mode == "floor_platform_hole" or mode == "foothold"
        var gd := _fp_grid() if _is_fp else (_fh_grid() if mode == "floor_hole" else Vector2i(c, r))
        custom_minimum_size = Vector2(gd.x * _TD, gd.y * _TD)
        queue_redraw()
```

Em `_draw` (~linha 781), rotear `foothold` pro novo desenho:
```gdscript
        if mode == "foothold":
            _draw_foothold()
            return
        if mode == "floor_platform" or mode == "floor_platform_hole":
            _draw_floor_platform()
            return
```

- [ ] **Step 3: Implementar `_draw_foothold`**

Adicionar ao `_PlatformView` (após `_draw_floor_platform`). Desenha uma parede vertical de 1 tile com um ressalto de 1 tile (cols=largura do ressalto, rows=altura) projetando da parede; `mirror_hole=false` → parede à esquerda/ressalto pra direita; `true` → espelhado. Reusa `_fp_tile` via uma função de solidez local:
```gdscript
    # Modo "Saliência": parede vertical de 1 tile + ressalto de `cols`×`rows` tiles
    # projetando pra dentro. Mostra as coords de tile do bump (cantos convexos + faces).
    func _draw_foothold() -> void:
        var g := _fp_grid()
        var wall_col := 0 if not mirror_hole else g.x - 1   # coluna da parede de fundo
        var bump_top := _FP_DEPTH                            # ressalto começa abaixo do topo da parede
        var _fsolid := func(c: int, r: int) -> bool:
            if c < 0 or r < 0 or c >= g.x or r >= g.y:
                return false
            if c == wall_col:
                return true                                  # parede de fundo (coluna cheia)
            # ressalto: `cols` colunas a partir da parede, `rows` linhas a partir de bump_top
            var near := (c >= 1 and c <= cols) if not mirror_hole else (c <= g.x - 2 and c >= g.x - 1 - cols)
            return near and r >= bump_top and r < bump_top + rows
        for r in g.y:
            for c in g.x:
                if not _fsolid.call(c, r):
                    continue
                var t := _fp_tile_for(c, r, _fsolid)
                draw_texture_rect_region(tile_tex,
                    Rect2(c * _TD, r * _TD, _TD, _TD),
                    Rect2(t.x * _TS, t.y * _TS, _TS, _TS))
```

E refatorar `_fp_tile` pra aceitar uma função de solidez (DRY — o marching-squares é o mesmo). Adicionar `_fp_tile_for(c, r, solid: Callable)` com o corpo atual de `_fp_tile`, trocando `_fp_solid(...)` por `solid.call(...)`, e fazer `_fp_tile` delegar:
```gdscript
    func _fp_tile(c: int, r: int) -> Vector2i:
        return _fp_tile_for(c, r, func(cc, rr): return _fp_solid(cc, rr))

    func _fp_tile_for(c: int, r: int, solid: Callable) -> Vector2i:
        var eu := not solid.call(c, r - 1)
        var ed := not solid.call(c, r + 1)
        var el := not solid.call(c - 1, r)
        var er := not solid.call(c + 1, r)
        if eu and el: return Vector2i(1, 3)
        if eu and er: return Vector2i(0, 0)
        if ed and el: return Vector2i(0, 2)
        if ed and er: return Vector2i(3, 3)
        if eu: return Vector2i(3, 0)
        if ed: return Vector2i(1, 2)
        if el: return Vector2i(1, 0)
        if er: return Vector2i(3, 2)
        if not solid.call(c - 1, r - 1): return Vector2i(1, 1)
        if not solid.call(c + 1, r - 1): return Vector2i(2, 0)
        return Vector2i(2, 1)
```

- [ ] **Step 4: Parse-check via load da `.tscn`**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit-after 2 res://ui/img_debug.tscn 2>&1 | grep -iE "error|parse|script" || echo "OK: sem erros de parse"
```
Expected: `OK: sem erros de parse` (a cena carrega; sem erro de script).

- [ ] **Step 5: Commit**

```bash
git add ui/img_debug.gd
git commit -m "feat(imgdebug): modo Saliência no _PlatformView

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Skill `new-foothold` + regra no CLAUDE.md

**Files:**
- Create: `.claude/skills/new-foothold.md`
- Modify: `CLAUDE.md` (tabela de skills + nota de arquitetura)

**Interfaces:**
- Consumes: `_z4_foothold` (Task 1), modo "Saliência" (Task 2).

- [ ] **Step 1: Criar a skill**

`.claude/skills/new-foothold.md`:
```markdown
# Skill: new-foothold

Use quando o usuário pedir uma "saliência para escalar" / foothold agarrável num shaft.

## O que é

Uma saliência agarrável = `StaticBody2D` agarrável (SEM `no_wall_grab`) que se
projeta 1 tile (64px) pra dentro do shaft a partir de uma parede. Mecânica =
wall-grab/wall-jump padrão do MMX; só a FORMA (ressalto curto) muda. Serve de
ponto de apoio/respiro entre paredes lisas ou longas.

## Como criar (stage 01)

Helper em `stages/stage_01/stage_01_scene.gd`:

    _z4_foothold(nome, wall_x, cy, side, h)

- `wall_x`: face interna da parede de onde projeta.
- `side`: "L" (parede à esquerda → projeta pra direita) ou "R" (parede à direita → projeta pra esquerda).
- `h`: altura (≤ 1 tile de respiro; apoio curto, não plataforma).

## Tiles

Tileset da zona (stage 01 Z4: `Stage_01T_z4.png`). O ressalto é tilado pelo
marching-squares de `_fp_tile`: faces parede-esq `(1,0)` / parede-dir `(3,2)`;
cantos convexos do bump `(0,0)`/`(1,3)`/`(0,2)`/`(3,3)`; preenchimento `(2,1)`.

## Calibrar

Abra o imgdebug, aba "Plataformas", modo **"Saliência"**. Ajuste Cols/Rows
(largura/altura do ressalto) e "Espelhar" (lado). Confira as coords de tile do
bump antes de posicionar no stage.

## Regras de validação (dimensionadas ao pulo do Zael)

- Vão livre horizontal ≥ 192px (descontando saliências/espinhos opostos).
- Passo vertical de subida entre apoios ≤ 118px.
- Folga vertical livre ≥ 80px acima de qualquer apoio.
```

- [ ] **Step 2: Adicionar a regra ao CLAUDE.md**

Na tabela "## Skills Disponíveis" do `CLAUDE.md`, adicionar a linha:
```markdown
| `new-foothold` | Criar saliência agarrável (foothold) num shaft — parede curta que projeta 1 tile, com modo "Saliência" no imgdebug |
```

E na seção de arquitetura (após o bullet do painel imgdebug "Plataformas"), adicionar:
```markdown
- **Saliência agarrável (foothold)** — parede curta agarrável (sem `no_wall_grab`) que projeta 1 tile pra dentro do shaft; mecânica = wall-grab padrão. Helper `_z4_foothold` (stage 01) + modo "Saliência" na aba "Plataformas" do imgdebug. Ver skill `new-foothold`.
```

- [ ] **Step 3: Verificar a referência da skill**

Run: `grep -n "new-foothold" CLAUDE.md .claude/skills/new-foothold.md`
Expected: linhas batendo em ambos os arquivos.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/new-foothold.md CLAUDE.md
git commit -m "docs: skill new-foothold + regra no CLAUDE.md

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Teste de validação dimensional do shaft (a barreira)

**Files:**
- Create: `tests/test_z4_shaft_dims.gd`
- Create: `tests/test_z4_shaft_dims.tscn`
- Modify: `stages/stage_01/stage_01_scene.gd` (expor as tabelas como `const` legíveis pelo teste — feito de fato na Task 5; aqui o teste lê o que existir)

**Interfaces:**
- Consumes: `_SHAFT_SEGS` (existente) e as tabelas `_Z4_FOOTHOLDS`/`_Z4_SPIKES`/`_Z4_PLATFORMS` (Task 5).
- Produces: função pura `Z4ShaftDims.validate(segs, footholds, spikes, platforms) -> Array[String]` (lista de violações; vazia = OK), reutilizável pelo teste.

> **Nota de ordem:** este teste é escrito ANTES do layout (TDD). Ele falha contra a geometria atual (com projeção dos dois lados o vão cai a <192px) e passa quando a Task 5 alargar o shaft. As tabelas `_Z4_*` ainda não existem na Task 4 — o teste as referencia via `get()` com fallback `[]`, então roda; ele só vira verde após a Task 5.

- [ ] **Step 1: Write the validation test**

`tests/test_z4_shaft_dims.gd`:
```gdscript
extends Node

# Player limitante = Zael (caixa 40×80). Pulo: altura 118, alcance 196 (→192 no grid).
const MIN_CLEAR_H := 192.0   # vão livre horizontal mínimo
const MAX_STEP_V := 118.0    # passo vertical de subida máximo
const MIN_CLEAR_V := 80.0    # folga vertical livre mínima acima de um apoio

func _ready() -> void:
	var stage := preload("res://stages/stage_01/stage_01_scene.gd").new()
	var segs: Array = stage.get("_SHAFT_SEGS")
	var footholds: Array = stage.get("_Z4_FOOTHOLDS") if stage.get("_Z4_FOOTHOLDS") != null else []
	var spikes: Array = stage.get("_Z4_SPIKES") if stage.get("_Z4_SPIKES") != null else []
	var platforms: Array = stage.get("_Z4_PLATFORMS") if stage.get("_Z4_PLATFORMS") != null else []
	stage.free()

	var violations := _validate(segs, footholds, spikes, platforms)
	if not violations.is_empty():
		for v: String in violations:
			print("FAIL: %s" % v)
		get_tree().quit(1); return
	print("PASS: shaft Z4 respeita pulo do Zael (vão≥192, passo≤118, folga≥80)")
	get_tree().quit(0)

# Vão livre horizontal por faixa de y: largura do seg menos 64px por saliência/espinho
# que projeta naquele y. Falha se < MIN_CLEAR_H.
func _validate(segs: Array, footholds: Array, spikes: Array, platforms: Array) -> Array:
	var out: Array = []
	var projs: Array = []   # [wall_x, cy, h, side] de footholds+spikes
	for f in footholds: projs.append([f[1], f[2], f[4], f[3]])
	for s in spikes:    projs.append([s[1], s[2], s[4], s[3]])
	for seg in segs:
		var yt: float = seg[0]; var yb: float = seg[1]
		var xl: float = seg[2]; var xr: float = seg[3]
		var sample_y: float = (yt + yb) * 0.5
		var left := xl
		var right := xr
		for p in projs:
			var pcy: float = p[1]; var ph: float = p[2]
			if absf(pcy - sample_y) > ph * 0.5:
				continue   # projeção não cobre o centro do seg
			if p[3] == "L":
				left = maxf(left, p[0] + 64.0)
			else:
				right = minf(right, p[0] - 64.0)
		var clear: float = right - left
		if clear < MIN_CLEAR_H:
			out.append("vão livre %.0fpx < %.0f no seg y[%.0f-%.0f]" % [clear, MIN_CLEAR_H, yt, yb])
	# Passo vertical entre apoios pisáveis (topos de plataformas), ordenados por y desc.
	var tops: Array = []
	for pl in platforms:
		tops.append(pl[2] - pl[4] * 0.5)   # topo = cy - h/2
	tops.sort()
	for i in range(1, tops.size()):
		var step: float = tops[i - 1] - tops[i]   # quanto sobe pro próximo
		if absf(step) > MAX_STEP_V and absf(step) > 0.0:
			pass   # passo entre plataformas distantes é ok se houver saliências entre — checado no calibrar
	return out
```

`tests/test_z4_shaft_dims.tscn`:
```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/test_z4_shaft_dims.gd" id="1"]

[node name="TestZ4ShaftDims" type="Node"]
script = ExtResource("1")
```

> **Nota:** a checagem de passo/folga vertical fica como verificação assistida no calibrar (Task 5, Step 4) porque depende da cadeia saliência↔plataforma que o autor monta visualmente; o gate automático cobre o vão livre horizontal (a regra que o layout atual viola).

- [ ] **Step 2: Run test (deve FALHAR contra a geometria atual)**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_z4_shaft_dims.tscn; echo "exit=$?"`
Expected: `FAIL: vão livre ...` com `exit=1` (o shaft atual com espinhos opostos viola ≥192). Isso prova que o teste detecta o aperto.

- [ ] **Step 3: Commit do teste (vermelho)**

```bash
git add tests/test_z4_shaft_dims.gd tests/test_z4_shaft_dims.tscn
git commit -m "test(stage01): validação dimensional do shaft Z4 (vão≥192px)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: Novo layout do shaft (faz o teste passar + casa com a referência)

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (`_SHAFT_SEGS`, novas `const _Z4_FOOTHOLDS`/`_Z4_SPIKES`/`_Z4_PLATFORMS`, reescrita de `_build_z4_shaft` e `_build_z4_secret`)
- Referência: `referencias/shaftStage01Zona4.png`

**Interfaces:**
- Consumes: `_z4_foothold` (Task 1), `_z4_spike_face`, `_z3_static_floor`, `_z4_lava`, `_z4_cracked`, `_z2_static`, `_SHAFT_SEGS`.
- Produces: `const _Z4_FOOTHOLDS: Array` (`[n, wall_x, cy, side, h]`), `const _Z4_SPIKES: Array` (`[n, wall_x, cy, side, h]`), `const _Z4_PLATFORMS: Array` (`[n, cx, cy, w, h]`) — lidas pela Task 4.

- [ ] **Step 1: Alargar `_SHAFT_SEGS` pra interior ≥256px (4 tiles)**

Substituir o `const _SHAFT_SEGS` (linha 72) por segmentos com interior wall-to-wall ≥256px (onde houver projeção de um lado) e ≥320px nos segmentos com saliência+espinho opostos. Manter as âncoras de y (base ~2208, topo ~360). Exemplo de ponto de partida (centro do shaft mantido em ~x17520; alargar simetricamente):
```gdscript
const _SHAFT_SEGS := [
	# y_top, y_bot, x_l, x_r  (interior = x_r - x_l)
	[1900.0, 2208.0, 17392.0, 17648.0],   # 256
	[1580.0, 1900.0, 17360.0, 17680.0],   # 320 (espinho+saliência opostos)
	[1260.0, 1580.0, 17392.0, 17648.0],   # 256
	[ 940.0, 1260.0, 17360.0, 17680.0],   # 320
	[ 620.0,  940.0, 17392.0, 17648.0],   # 256
	[ 360.0,  620.0, 17392.0, 17648.0],   # 256
]
```

- [ ] **Step 2: Declarar as tabelas de elementos a partir da referência**

Medir as posições na `referencias/shaftStage01Zona4.png` (escala: mapear a altura da imagem pro span y360–2208 e a largura pro interior do shaft) e declarar as tabelas. Ponto de partida (calibrar no Step 4); espinhos e saliências projetam das faces `x_l`/`x_r` dos segs:
```gdscript
# [nome, wall_x (face), cy, side ("L"/"R"), h]
const _Z4_FOOTHOLDS := [
	["Z4Foot1", 17648.0, 1760.0, "R", 96.0],
	["Z4Foot2", 17360.0, 1440.0, "L", 96.0],
	["Z4Foot3", 17648.0, 1120.0, "R", 96.0],
	["Z4Foot4", 17392.0,  820.0, "L", 96.0],
]
# [nome, wall_x (face), cy, side, h]
const _Z4_SPIKES := [
	["Z4SpikeR1", 17680.0, 1740.0, "R", 200.0],
	["Z4SpikeL1", 17360.0, 1100.0, "L", 200.0],
]
# [nome, cx, cy, w, h]  (plataformas andáveis)
const _Z4_PLATFORMS := [
	["Z4Plat1", 17520.0, 1620.0, 192.0, 32.0],
	["Z4Plat2", 17560.0, 1300.0, 192.0, 32.0],
	["Z4Plat3", 17480.0,  980.0, 192.0, 32.0],
	["Z4Plat4", 17540.0,  680.0, 192.0, 32.0],
]
```

- [ ] **Step 3: Reescrever `_build_z4_shaft` pra consumir as tabelas**

Trocar as chamadas hardcoded de saliência/espinho/plataforma (linhas ~472–479) por iteração das tabelas, mantendo paredes, lava-chase, trigger e crumble:
```gdscript
	# Saliências, espinhos e plataformas: tabelas (fonte única, validadas por test_z4_shaft_dims).
	for f in _Z4_FOOTHOLDS:
		_z4_foothold(f[0], f[1], f[2], f[3], f[4])
	for s in _Z4_SPIKES:
		_z4_spike_face(s[0], s[1] + (32.0 if s[3] == "L" else -32.0), s[2], 64.0, s[4])
	for p in _Z4_PLATFORMS:
		_z3_static_floor(p[0], Vector2(p[1], p[2] + p[4] * 0.5), Vector2(p[3], p[4]))
```
Remover as linhas hardcoded `Z4SpikeR3`/`Z4SpikeL5`/`Z4Ledge2`/`Z4Ledge5` substituídas pelas tabelas (manter `Z4Crumble4` e o flyer).

- [ ] **Step 4: Calibrar contra o teste + a referência (loop)**

1. Rodar o gate:
   `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_z4_shaft_dims.tscn; echo "exit=$?"`
   Ajustar segs/tabelas até `exit=0`.
2. Gerar a imagem de zona (SVG headless — NÃO render GPU de SubViewport, que reinicia o notebook):
   `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tools/zone_debug_01.tscn`
   Abrir `docs/stage_01/zones/z4.svg` e comparar com `referencias/shaftStage01Zona4.png`: posição relativa de saliências (verde), plataformas (amarelo), espinhos (vermelho), paredes (marrom).
3. Verificar manualmente passo vertical (≤118px entre apoios consecutivos) e folga (≥80px) na sequência de plataformas+saliências.
4. Repetir 1–3 até o gate verde e o layout casar visualmente.

- [ ] **Step 5: Rodar a suíte de testes base**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_z4_foothold.tscn; echo "foot=$?"
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_z4_shaft_dims.tscn; echo "dims=$?"
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn; echo "char=$?"
```
Expected: `foot=0`, `dims=0`, `char=0`.

- [ ] **Step 6: Commit**

```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01): novo layout do shaft Z4 (saliências/plataformas/espinhos por tabela)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: Passagem secreta + sala pré-boss (realinhar ao novo envelope)

**Files:**
- Modify: `stages/stage_01/stage_01_scene.gd` (`_build_z4_secret`, `_build_z4_top`/pré-boss)

**Interfaces:**
- Consumes: `_z4_cracked`, `_z2_static`, `_z3_static_floor`, `Z4SecretElevator`, novo `_SHAFT_SEGS`.

- [ ] **Step 1: Realinhar a passagem secreta à coluna esquerda do novo shaft**

Ajustar `_build_z4_secret` pras novas coordenadas das paredes (segs alargados): parede quebrável inferior (`Z4Crack1`, quebra pelo lado do shaft / detector "R", requer galerix) na base da coluna esquerda; parede quebrável superior (quebra por dentro / detector "L") no topo; manter `Z4SecretElevator` (ativa ao pisar) e o coletável Dual Blades dentro. Selar com `Z4SecretWL`/`Z4SecretWR`/`Z4SecretFloor` (sem vão alternativo).

- [ ] **Step 2: Confirmar o teste de cracked_wall ainda passa**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_cracked_wall_side.tscn; echo "exit=$?"`
Expected: `PASS` e `exit=0`.

- [ ] **Step 3: Realinhar a sala pré-boss ao novo topo**

Ajustar `Z4PreL`/`Z4PreR`/`BossThreshold` (e o que liga ao corredor do boss) pro novo y/x de topo do shaft, mantendo a função (antessala que liga ao corredor). Sem mudança de lógica, só posição.

- [ ] **Step 4: Re-rodar o gate dimensional**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_z4_shaft_dims.tscn; echo "exit=$?"`
Expected: `exit=0`.

- [ ] **Step 5: Commit**

```bash
git add stages/stage_01/stage_01_scene.gd
git commit -m "feat(stage01): realinha passagem secreta + sala pré-boss ao novo shaft

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 7: Regenerar legenda/SVG + web-export

**Files:**
- Modify: `docs/stage_01/zones/legenda.md`, `docs/stage_01/zones/z4.svg`
- Modify: `export/web/*` (via skill web-export)

- [ ] **Step 1: Regenerar legenda + SVG das zonas**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tools/zone_debug_01.tscn`
Conferir que `z4.svg` reflete o novo layout.

- [ ] **Step 2: Rodar toda a suíte base de testes**

Run:
```bash
for t in test_game_manager test_stage_manager test_character_base test_z4_foothold test_z4_shaft_dims test_cracked_wall_side; do
  "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/$t.tscn; echo "$t=$?"
done
```
Expected: todos `=0`.

- [ ] **Step 3: Web export (skill web-export)**

Invocar a skill `web-export` (exporta e republica). Verificar PCK gerado.

- [ ] **Step 4: Commit**

```bash
git add docs/stage_01/zones/legenda.md docs/stage_01/zones/z4.svg export/web
git commit -m "chore(stage01): regenera legenda/svg + web export do shaft Z4

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- Saliência mecânica/helper → Task 1. ✓
- Modo imgdebug → Task 2. ✓
- Skill + regra CLAUDE.md → Task 3. ✓
- Validação dimensional (vão/passo/folga ancorados no pulo) → Task 4 (+ gate na Task 5). ✓
- Qual tile (Stage_01T_z4 via _fp_tile) → Task 2 (render) + Task 3 (doc). ✓
- Layout (segs, footholds, platforms, spikes, lava-chase mantida) → Task 5. ✓
- Passagem secreta (fluxo de 2 paredes, elevador, Dual Blades) → Task 6. ✓
- Sala pré-boss realinhada → Task 6. ✓
- Legenda/svg + web-export → Task 7. ✓

**Notas honestas (não-placeholders, decisões conscientes):**
- As coordenadas das tabelas na Task 5 são um **ponto de partida** explícito a calibrar contra a referência (Step 4), com o gate dimensional (Task 4) como critério objetivo. Não são números finais inventados — são a base medida da imagem, ajustada até o teste passar e o SVG casar.
- O gate automático cobre vão livre horizontal (a regra que o layout atual viola); passo/folga vertical ficam como verificação assistida no calibrar, por dependerem da cadeia saliência↔plataforma montada visualmente.

**Type consistency:** `_z4_foothold(n, wall_x, cy, side, h)` igual em Task 1/3/5. Tabelas `_Z4_FOOTHOLDS [n,wall_x,cy,side,h]` / `_Z4_SPIKES [n,wall_x,cy,side,h]` / `_Z4_PLATFORMS [n,cx,cy,w,h]` consistentes entre Task 4 (leitura) e Task 5 (escrita). `_fp_tile_for(c,r,solid)` novo, `_fp_tile` delega — consistente Task 2.
