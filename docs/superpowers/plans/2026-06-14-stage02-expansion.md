# Expansão do Stage 2 (Cryovex) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dobrar o comprimento do Stage 2 (~14k → ~24k) esticando as 4 zonas ~2x, com plataforma baseada no chão (piso+abismo, sem flutuantes), abismo recuperável em Z1–Z3 e mortal+glass na Z4, perigo de gelo por zona, mais inimigos — e corrigir o desalinhamento dos corredores com o piso.

**Architecture:** Geometria procedural em `stages/stage_02/stage_02_scene.gd` (padrão do `stage_01_scene.gd`): builders `_build_zone1..4()` removem os blocos antigos do `.tscn` e montam o terreno (helpers de piso/elevação/poço/abismo-glass). Um `const FLOOR_Y := 800.0` único define a superfície de piso de TODAS as zonas E dos corredores (corrige o desalinhamento de 88px). Constantes de layout recalculadas deslocam corredores/miniboss/boss pra direita.

**Tech Stack:** Godot 4.6.2, GDScript 2D. CorridorSection, tilesets por zona, kill plane por fase.

---

## Contexto de geometria (verificado)

- **Superfície de piso das zonas = y 800** (blocos `BlockWide` 900×360 centro y=980 → topo 800; `PlayerSpawn` y=760 → pés em 800).
- **Corredores hoje têm piso em y 888** (`floor_center.y=920`, size 64 → topo 888) → **88px ABAIXO das zonas = o desalinhamento**. Corrigir alinhando o piso do corredor a FLOOR_Y.
- `_draw_static_terrain` desenha qualquer `StaticBody2D` filho do Node2D usando o tileset por **prefixo do nome** (`Z1`/`Z2`/`Z3`/`Z4` → `_texture_for_node`). Então segmentos nomeados `Z1_*`..`Z4_*` desenham com o tileset certo automaticamente.
- Perigos existentes (Area2D + scripts): `StageIceFloor` (ice_floor.gd, hoje 14500×640 cobrindo a fase toda), `Z2_Spikes` (ice_spikes.gd), `Z3_Blizzard` (blizzard_zone.gd, force (180,0)). Gates: `Z2_IgnarathGate`, `Z4_LuxarGate` (ice_gate.gd). Colectáveis: SubTank, ArmorZaraHelmet, Heart, SpreadZael.
- Pulo do jogo: máx ~118px de altura / ~196px de alcance horizontal (memória `reference_jump_height`). Elevações ≤64px (1 tile) são saltáveis; poços recuperáveis ≤96px de profundidade dão pra sair pulando.

## Layout-alvo (x), deslocado e dobrado

| Elemento | Faixa X nova |
|----------|--------------|
| Z1 | 180 – 5600 |
| Z2 | 5600 – 10600 |
| CP1 (corr) | 10600 – 11400 |
| MiniBoss (MB02) | 11500 – 12300 |
| CP2 (corr) | 12400 – 13200 |
| Z3 | 13200 – 18000 |
| Z4 | 18000 – 23600 |
| CP3 (corr) | 23600 – 24400 |
| Boss entry | 24550 |
| Camera `limit_right` | 25000 |

---

## File Structure

| Arquivo | Responsabilidade | Ação |
|---------|------------------|------|
| `stages/stage_02/stage_02_scene.gd` | Builders de zona, helpers de terreno, layout, alinhamento de corredor, inimigos, triggers | Modificar |
| `stages/stage_02/stage_02.tscn` | Remover blocos antigos; reposicionar markers/gates/colectáveis/hazards/boss-entry/câmera | Modificar |

**Comando de verificação de carga** (quase toda task):
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit-after 8 res://stages/stage_02/stage_02.tscn 2>&1 | grep -iE "SCRIPT ERROR|Parse Error|Compile Error" | grep -ivE "bgm_|\.mp3"
```
Sucesso = nenhuma linha (vazio).

> Nota de execução: as coordenadas das zonas abaixo são valores iniciais. Após cada zona, **verifique transponibilidade** (debug `?zone=N` ou o StageBot) e ajuste vãos/alturas pra respeitar ~118px/196px. Não invente plataformas flutuantes — só piso, elevações ≤64px e poços.

---

## Task 1: Constante FLOOR_Y + alinhamento dos corredores + layout deslocado

**Files:** Modify `stages/stage_02/stage_02_scene.gd`

- [ ] **Step 1: Adicionar FLOOR_Y e recalcular as constantes de layout**

Trocar o bloco de constantes de layout (linhas ~41-48):
```gdscript
const _CP1_ENTRY_X := 5400.0
const _CP1_EXIT_X := 6200.0
const _MB_LEFT := 6300.0
const _MB_RIGHT := 7100.0
const _CP2_ENTRY_X := 7200.0
const _CP2_EXIT_X := 8000.0
const _CP3_ENTRY_X := 13200.0
const _CP3_EXIT_X := 14000.0
```
por:
```gdscript
# Superfície de piso única (zonas E corredores) — corrige o desalinhamento de 88px.
const FLOOR_Y := 800.0          # topo do piso (player origin fica ~40px acima)
const _CORR_INTERIOR := 192.0   # vão interno do corredor (piso↔teto)

const _CP1_ENTRY_X := 10600.0
const _CP1_EXIT_X := 11400.0
const _MB_LEFT := 11500.0
const _MB_RIGHT := 12300.0
const _CP2_ENTRY_X := 12400.0
const _CP2_EXIT_X := 13200.0
const _CP3_ENTRY_X := 23600.0
const _CP3_EXIT_X := 24400.0
const _BOSS_ENTRY_X := 24550.0
```

- [ ] **Step 2: Alinhar `_make_corridor` ao piso (FLOOR_Y)**

Em `_make_corridor`, trocar os blocos de geometria (linhas ~138-145) que usavam y=920/728/824:
```gdscript
	corr.floor_center = Vector2(entry_x + width * 0.5, 920.0)
	corr.floor_size = Vector2(width, 64.0)
	corr.ceil_center = Vector2(entry_x + width * 0.5, 728.0)
	corr.ceil_size = Vector2(width, 64.0)
	corr.wall_l_center = Vector2(entry_x, 824.0)
	corr.wall_l_size = Vector2(64.0, 256.0)
	corr.wall_r_center = Vector2(exit_x, 824.0)
	corr.wall_r_size = Vector2(64.0, 256.0)
```
por (piso do corredor = FLOOR_Y; teto sobe pra manter o vão; paredes/câmera centradas no meio do vão):
```gdscript
	var floor_cy := FLOOR_Y + 32.0                      # topo do piso = FLOOR_Y (800) → centro 832
	var ceil_cy := FLOOR_Y - _CORR_INTERIOR - 32.0      # fundo do teto = FLOOR_Y - 192 → centro
	var mid_y := (floor_cy + ceil_cy) * 0.5
	corr.floor_center = Vector2(entry_x + width * 0.5, floor_cy)
	corr.floor_size = Vector2(width, 64.0)
	corr.ceil_center = Vector2(entry_x + width * 0.5, ceil_cy)
	corr.ceil_size = Vector2(width, 64.0)
	corr.wall_l_center = Vector2(entry_x, mid_y)
	corr.wall_l_size = Vector2(64.0, _CORR_INTERIOR + 64.0)
	corr.wall_r_center = Vector2(exit_x, mid_y)
	corr.wall_r_size = Vector2(64.0, _CORR_INTERIOR + 64.0)
```
E na mesma função trocar `corr.cam_center = Vector2(entry_x + width * 0.5, 824.0)` por:
```gdscript
	corr.cam_center = Vector2(entry_x + width * 0.5, mid_y)
```
(O `glass_lateral_x`/`glass_fill_x`/`glass_fill_cols` continuam iguais.)

- [ ] **Step 3: Verificar carga + alinhamento**

Rodar o comando de carga (topo). Esperado: sem erro. (O alinhamento visual confere na verificação final no navegador.)

- [ ] **Step 4: Commit**

```bash
git add stages/stage_02/stage_02_scene.gd
git commit -m "feat(stage02): FLOOR_Y único + alinhar corredores ao piso + layout deslocado

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Helpers de terreno procedural

**Files:** Modify `stages/stage_02/stage_02_scene.gd`

- [ ] **Step 1: Adicionar os helpers de terreno (no fim do arquivo)**

```gdscript
# ── Helpers de terreno procedural (piso baseado no chão; sem flutuantes) ──────
# Segmento de piso sólido: topo em surface_y, profundidade dr tiles. zone = "Z1".."Z4".
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
	add_child(b)
	return b

# Parede de vidro lisa (no_wall_grab) — face vertical de um abismo mortal (Z4).
func _glass_wall(x_center: float, top_y: float, height: float) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = "Z4_Glass_%d" % int(x_center)
	b.collision_layer = 1
	b.collision_mask = 0
	b.add_to_group("no_wall_grab")
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64.0, height)
	cs.shape = shape
	cs.position = Vector2(x_center, top_y + height * 0.5)
	b.add_child(cs)
	add_child(b)
	return b

# POÇO RECUPERÁVEL (Z1–Z3): piso à esquerda, vão, piso à direita, e um piso de
# fundo (catch) ~`depth` abaixo cobrindo o vão → cai e volta pulando (depth ≤ ~96).
func _recoverable_pit(zone: String, left_x: float, right_x: float, gap_x0: float, gap_x1: float, depth: float = 96.0) -> void:
	_floor_seg(zone, left_x, gap_x0, FLOOR_Y)
	_floor_seg(zone, gap_x1, right_x, FLOOR_Y)
	_floor_seg(zone, gap_x0, gap_x1, FLOOR_Y + depth)   # fundo do poço (catch)

# ABISMO MORTAL (Z4): piso à esquerda, vão ABERTO (sem fundo → morte), piso à
# direita, com VIDRO nas faces internas. O kill plane (abaixo) mata na queda.
func _deadly_pit(left_x: float, right_x: float, gap_x0: float, gap_x1: float) -> void:
	_floor_seg("Z4", left_x, gap_x0, FLOOR_Y)
	_floor_seg("Z4", gap_x1, right_x, FLOOR_Y)
	_glass_wall(gap_x0 + 32.0, FLOOR_Y, 320.0)   # face de vidro à esquerda do vão
	_glass_wall(gap_x1 - 32.0, FLOOR_Y, 320.0)   # face de vidro à direita do vão

# Degrau elevado saltável (≤64px) sobre o piso base — seção de chão mais alta.
func _step_up(zone: String, x0: float, x1: float, rise: float = 64.0) -> void:
	_floor_seg(zone, x0, x1, FLOOR_Y - rise)
```

- [ ] **Step 2: Fazer o vidro desenhar com a textura glass (não o tileset da zona)**

Em `_texture_for_node`, adicionar antes do `return _tileset_z1` final:
```gdscript
	if node.name.begins_with("Z4_Glass"):
		return _glass_tex
```
(Os nós `Z4_Glass_*` passam a desenhar com `_glass_tex`; os `Z*_Floor_*` desenham com o tileset da zona pelo prefixo.)

- [ ] **Step 3: Verificar carga**

Rodar o comando de carga. Esperado: sem erro (helpers ainda não chamados, mas o arquivo compila).

- [ ] **Step 4: Commit**

```bash
git add stages/stage_02/stage_02_scene.gd
git commit -m "feat(stage02): helpers de terreno (piso, poço recuperável, abismo glass, degrau)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Build Zone 1 (escorregadio, dobrada) + remover blocos antigos

**Files:** Modify `stages/stage_02/stage_02_scene.gd`, `stages/stage_02/stage_02.tscn`

- [ ] **Step 1: Remover os blocos antigos da Z1 no `.tscn`**

Remover os nós `Z1_BlockA`, `Z1_BlockB`, `Z1_BlockC` (e seus `CollisionShape2D` filhos) de `stage_02.tscn` (linhas ~79-95).

- [ ] **Step 2: Adicionar `_build_zone1()` e chamá-lo no `_ready`**

No `_ready`, após `_setup_corridors()` e antes de `_setup_zone_triggers()`, inserir:
```gdscript
	_build_zone1()
	_build_zone2()
	_build_zone3()
	_build_zone4()
```
(As funções das zonas 2–4 são adicionadas nas tasks seguintes; criar `_build_zone1` agora e stubs vazios `func _build_zone2()->void: pass` etc. pra compilar — serão preenchidos depois.)

Adicionar (fim do arquivo):
```gdscript
# Z1 — gelo escorregadio. Piso base contínuo com poços recuperáveis e degraus.
func _build_zone1() -> void:
	# Piso de entrada (spawn) reto até 1400
	_floor_seg("Z1", 0.0, 1400.0, FLOOR_Y)
	_step_up("Z1", 1400.0, 1900.0)                       # degrau saltável
	_recoverable_pit("Z1", 1900.0, 3000.0, 2300.0, 2560.0)   # poço (vão 260 ≤ 196? não: ver nota)
	_recoverable_pit("Z1", 3000.0, 4200.0, 3450.0, 3650.0)
	_step_up("Z1", 4200.0, 4700.0)
	_floor_seg("Z1", 4700.0, 5600.0, FLOOR_Y)            # piso até a entrada do CP1 (10600) — ver Z2
```
> Nota de tuning: o vão recuperável pode ser maior que 196px porque NÃO precisa ser pulado limpo (cair é recuperável). Mas se quiser que dê pra pular por cima, mantenha gap ≤ 196. Ajustar na verificação.

- [ ] **Step 3: Estender o `StageIceFloor` (escorregadio) e movê-lo pra cobrir Z1–toda a fase**

No `.tscn`, o `StageIceFloor` (Area2D) tem shape `StageIceShape` 14500×640 em (7250,760). Atualizar pra cobrir o novo comprimento: trocar a sub_resource `StageIceShape` `size = Vector2(14500, 640)` por `size = Vector2(25000, 640)` e o nó `StageIceFloor` `position = Vector2(7250, 760)` por `position = Vector2(12500, 760)` (centro do novo comprimento ~25k).

- [ ] **Step 4: Verificar carga**

Rodar comando de carga. Esperado: sem erro. Opcional: `?zone=1` debug pra ver a Z1.

- [ ] **Step 5: Commit**

```bash
git add stages/stage_02/stage_02_scene.gd stages/stage_02/stage_02.tscn
git commit -m "feat(stage02): Zone 1 dobrada (escorregadio, piso+poços recuperáveis)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Build Zone 2 (espinhos, dobrada)

**Files:** Modify `stages/stage_02/stage_02_scene.gd`, `stages/stage_02/stage_02.tscn`

- [ ] **Step 1: Remover blocos antigos Z2** (`Z2_BlockA/B/C`) do `.tscn` (linhas ~97-113).

- [ ] **Step 2: Substituir o stub `_build_zone2` por:**
```gdscript
# Z2 — espinhos de gelo. Piso com campos de espinhos e poços recuperáveis.
func _build_zone2() -> void:
	_floor_seg("Z2", 5600.0, 6600.0, FLOOR_Y)
	_recoverable_pit("Z2", 6600.0, 7800.0, 7050.0, 7300.0)
	_step_up("Z2", 7800.0, 8300.0)
	_floor_seg("Z2", 8300.0, 9400.0, FLOOR_Y)            # campo de espinhos aqui (Area2D)
	_recoverable_pit("Z2", 9400.0, 10600.0, 9850.0, 10100.0)
```

- [ ] **Step 3: Reposicionar/ampliar `Z2_Spikes` no `.tscn`**

`Z2_Spikes` (Area2D, `HazardMedium` 480×96) está em (4100,760). Mover pro novo campo da Z2: `position = Vector2(8850, 768)` (sobre o piso 8300–9400, topo dos espinhos rente a FLOOR_Y=800). Se quiser mais campos, duplicar o nó com posições adicionais (ex.: (6100,768)).

- [ ] **Step 4: Verificar carga + commit**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit-after 8 res://stages/stage_02/stage_02.tscn 2>&1 | grep -iE "SCRIPT ERROR|Parse Error|Compile Error" | grep -ivE "bgm_|\.mp3"
git add stages/stage_02/stage_02_scene.gd stages/stage_02/stage_02.tscn
git commit -m "feat(stage02): Zone 2 dobrada (espinhos + poços)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Build Zone 3 (nevasca, dobrada)

**Files:** Modify `stages/stage_02/stage_02_scene.gd`, `stages/stage_02/stage_02.tscn`

- [ ] **Step 1: Remover blocos antigos Z3** (`Z3_BlockA/B/C`) do `.tscn` (linhas ~121-137).

- [ ] **Step 2: Substituir o stub `_build_zone3` por:**
```gdscript
# Z3 — nevasca que empurra. Piso com poços recuperáveis sob vento lateral.
func _build_zone3() -> void:
	_floor_seg("Z3", 13200.0, 14400.0, FLOOR_Y)
	_recoverable_pit("Z3", 14400.0, 15600.0, 14900.0, 15150.0)
	_step_up("Z3", 15600.0, 16100.0)
	_recoverable_pit("Z3", 16100.0, 17300.0, 16550.0, 16800.0)
	_floor_seg("Z3", 17300.0, 18000.0, FLOOR_Y)
```

- [ ] **Step 3: Reposicionar/ampliar `Z3_Blizzard` no `.tscn`**

`Z3_Blizzard` (Area2D, `HazardWide` 760×96, force (180,0)) está em (9000,620). Mover pro meio da Z3 sobre os poços: `position = Vector2(15600, 600)`. Pode ampliar a shape (ex.: 2400×200) ou duplicar pra cobrir mais da zona — vento atrapalha os pulos sobre os poços.

- [ ] **Step 4: Verificar carga + commit**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit-after 8 res://stages/stage_02/stage_02.tscn 2>&1 | grep -iE "SCRIPT ERROR|Parse Error|Compile Error" | grep -ivE "bgm_|\.mp3"
git add stages/stage_02/stage_02_scene.gd stages/stage_02/stage_02.tscn
git commit -m "feat(stage02): Zone 3 dobrada (nevasca + poços)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: Build Zone 4 (abismos mortais + glass, dobrada)

**Files:** Modify `stages/stage_02/stage_02_scene.gd`, `stages/stage_02/stage_02.tscn`

- [ ] **Step 1: Remover blocos antigos Z4** (`Z4_BlockA/B/C`) do `.tscn` (linhas ~139-155).

- [ ] **Step 2: Substituir o stub `_build_zone4` por:**
```gdscript
# Z4 — abismos MORTAIS (sem fundo → kill plane) com vidro nas laterais.
# Travessia por pulos precisos entre seções de piso (vãos ≤ 196px de alcance).
func _build_zone4() -> void:
	_floor_seg("Z4", 18000.0, 19000.0, FLOOR_Y)
	_deadly_pit(19000.0, 20200.0, 19180.0, 19360.0)   # vão 180 ≤ 196 (saltável)
	_floor_seg("Z4", 20200.0, 20900.0, FLOOR_Y)
	_deadly_pit(20900.0, 22200.0, 21080.0, 21260.0)
	_floor_seg("Z4", 22200.0, 22900.0, FLOOR_Y)
	_deadly_pit(22900.0, 23600.0, 23080.0, 23260.0)
	_floor_seg("Z4", 23600.0, 24400.0, FLOOR_Y)        # piso até o CP3
```
> Importante: os vãos mortais DEVEM ser ≤ ~196px (alcance do pulo) pra serem transponíveis. Verificar com `?zone=4`/bot.

- [ ] **Step 3: Garantir kill plane abaixo dos abismos**

O kill plane do Stage 2 é por-fase (calculado do piso mais baixo + 600 OU `CharacterBase.KILL_Y`). Os poços de fundo dos `_recoverable_pit` (FLOOR_Y+96 ≈ 896) e o piso base (depth 3 tiles → fundo ~992) definem o "piso mais baixo". O `_deadly_pit` não tem fundo, então a queda passa do piso base → precisa morrer. Confirmar no `_ready` que existe lógica de kill plane; se o Stage 2 não aplica kill plane próprio, adicionar no `_ready` após `_spawn_player`:
```gdscript
	_player.kill_y = FLOOR_Y + 700.0   # ~1500: abaixo de todo piso, mata na queda dos abismos Z4
```
(Conferir se `_player` já tem `kill_y`; é o mesmo campo usado em `stage_scene.gd`.)

- [ ] **Step 4: Verificar carga + commit**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit-after 8 res://stages/stage_02/stage_02.tscn 2>&1 | grep -iE "SCRIPT ERROR|Parse Error|Compile Error" | grep -ivE "bgm_|\.mp3"
git add stages/stage_02/stage_02_scene.gd stages/stage_02/stage_02.tscn
git commit -m "feat(stage02): Zone 4 dobrada (abismos mortais + glass lateral)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 7: Inimigos, triggers, markers, gates, colectáveis, câmera

**Files:** Modify `stages/stage_02/stage_02_scene.gd`, `stages/stage_02/stage_02.tscn`

- [ ] **Step 1: Expandir os arrays de inimigos por zona**

Trocar os arrays `Z1_*`..`Z4_*` (linhas ~23-39) por versões espalhadas no novo comprimento (mais entradas, y na superfície ~800; flyers/wisps acima). Valores iniciais (ajustar na verificação):
```gdscript
const Z1_GRUNTS := [Vector2(700, 760), Vector2(1500, 700), Vector2(2700, 760), Vector2(3700, 760), Vector2(4800, 760)]
const Z1_FLYERS := [Vector2(1100, 600), Vector2(2900, 560), Vector2(4400, 600)]
const Z1_ARCHERS := [Vector2(1700, 760), Vector2(5100, 760)]
const Z2_GRUNTS := [Vector2(5900, 760), Vector2(6900, 760), Vector2(8000, 700), Vector2(9000, 760), Vector2(10200, 760)]
const Z2_FLYERS := [Vector2(6300, 560), Vector2(8600, 540), Vector2(10000, 580)]
const Z2_ARCHERS := [Vector2(6100, 760), Vector2(10300, 760)]
const Z2_SHIELDS := [Vector2(8500, 760)]
const Z3_GRUNTS := [Vector2(13500, 760), Vector2(14600, 760), Vector2(15800, 700), Vector2(16900, 760), Vector2(17700, 760)]
const Z3_FLYERS := [Vector2(14000, 560), Vector2(16000, 520), Vector2(17400, 580)]
const Z3_TURRETS := [Vector2(13700, 740), Vector2(17200, 740)]
const Z3_WISPS := [Vector2(15200, 520), Vector2(16600, 540)]
const Z4_GRUNTS := [Vector2(18400, 760), Vector2(20500, 760), Vector2(22500, 760)]
const Z4_FLYERS := [Vector2(19600, 560), Vector2(21500, 520), Vector2(23200, 580)]
const Z4_TURRETS := [Vector2(18600, 740), Vector2(22600, 740)]
const Z4_BOMBERS := [Vector2(20400, 700), Vector2(23300, 760)]
const Z4_SHIELDS := [Vector2(20600, 760)]
const Z4_WISPS := [Vector2(19500, 520), Vector2(21400, 520)]
```

- [ ] **Step 2: Atualizar os zone triggers pras novas faixas X**

Em `_setup_zone_triggers`, trocar:
```gdscript
	_make_zone_trigger("Z2Trigger", Rect2(2800, 400, 2400, 800), 2)
	_make_zone_trigger("MB02Trigger", Rect2(_CP1_EXIT_X, 400, 900, 800), 5)
	_make_zone_trigger("Z3Trigger", Rect2(_CP2_EXIT_X, 300, 2600, 900), 3)
	_make_zone_trigger("Z4Trigger", Rect2(10400, 300, 2600, 900), 4)
```
por:
```gdscript
	_make_zone_trigger("Z2Trigger", Rect2(5600, 300, 4000, 900), 2)
	_make_zone_trigger("MB02Trigger", Rect2(_CP1_EXIT_X, 300, 900, 900), 5)
	_make_zone_trigger("Z3Trigger", Rect2(_CP2_EXIT_X, 300, 4000, 900), 3)
	_make_zone_trigger("Z4Trigger", Rect2(18000, 300, 4000, 900), 4)
```

- [ ] **Step 3: Reposicionar markers, gates, colectáveis e câmera no `.tscn`**

- Markers: `Z1Marker` (800,760), `Z2Marker` (7000,760), `MB02Marker` (11900,760), `Z3Marker` (15000,760), `Z4Marker` (20000,760), `BossEntryMarker` (24550,760).
- `MB02_Floor`: mover pra arena do miniboss novo — `position = Vector2(11900, 980)` (topo 800 = FLOOR_Y; arena 11500–12300).
- Gates: `Z2_IgnarathGate` → `position = Vector2(7400, 700)` (na Z2, sobre o piso). `Z4_LuxarGate` → `position = Vector2(21000, 700)` (na Z4).
- Colectáveis: `SubTank` (1500, 700), `ArmorZaraHelmet` (8600, 650), `Heart` (16000, 560), `SpreadZael` (21500, 560).
- `Camera2D`: `limit_right = 25000`.

- [ ] **Step 4: Verificar carga + commit**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit-after 8 res://stages/stage_02/stage_02.tscn 2>&1 | grep -iE "SCRIPT ERROR|Parse Error|Compile Error" | grep -ivE "bgm_|\.mp3"
git add stages/stage_02/stage_02_scene.gd stages/stage_02/stage_02.tscn
git commit -m "feat(stage02): inimigos/triggers/markers/gates/colectáveis no layout novo

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 8: Verificação de jogabilidade + web export

**Files:** nenhum código novo (verificação/build).

- [ ] **Step 1: Carga limpa + (se houver) testes**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit-after 30 res://stages/stage_02/stage_02.tscn 2>&1 | grep -iE "SCRIPT ERROR|Parse Error|Compile Error|null instance" | grep -ivE "bgm_|\.mp3"; echo "EXIT_CLEAN"
```
Esperado: sem erros.

- [ ] **Step 2: Verificação visual/jogável no navegador (localhost)**

Web export + servir + abrir, entrar no Stage 2 (via debug ou novo jogo) e conferir:
- Corredores **alinhados** com o piso das zonas (sem degrau de 88px).
- Poços Z1–Z3 são **recuperáveis** (cai e volta).
- Abismos Z4 **matam** (kill plane) e têm **vidro** lateral (sem wall-grab).
- Vãos transponíveis (~118/196px). Ajustar coordenadas que falharem e re-exportar.

(Se preferir headless: rodar com `?zone=N` e/ou o StageBot pra validar o caminho de cada zona.)

- [ ] **Step 3: Web export + push + restart localhost** (convenção do projeto)

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "D:\SnesGame" --export-release "Web" "D:\SnesGame\export\web\index.html" 2>&1 | grep -iE "^\[ DONE \]" | tail -1
git add -f export/web/index.html export/web/index.pck
git add stages/stage_02/
git commit -m "chore: web export — expansão do Stage 2

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push origin master
powershell -Command "$pids = (netstat -ano | findstr ':8080' | ForEach-Object { ($_ -split '\s+')[-1] } | Sort-Object -Unique); foreach ($p in $pids) { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue }; Start-Process python -ArgumentList 'D:\SnesGame\serve_web.py' -WindowStyle Hidden; Start-Sleep 2; (Invoke-WebRequest http://localhost:8080 -UseBasicParsing).StatusCode"
```
Esperado: export DONE, `200`.

---

## Self-Review

**1. Spec coverage:**
- Dobrar ~14k→~24k esticando 4 zonas → Tasks 3–6 (layout-alvo na Task 1). ✓
- Plataforma baseada no chão, sem flutuantes → helpers `_floor_seg`/`_step_up`/`_recoverable_pit`/`_deadly_pit` (Task 2), usados nas zonas. ✓
- Abismo recuperável Z1–Z3 → `_recoverable_pit` (Tasks 3–5). ✓
- Abismo mortal + glass Z4 → `_deadly_pit` + `_glass_wall` + kill plane (Tasks 2, 6). ✓
- Perigo de gelo por zona → StageIceFloor (T3), Z2_Spikes (T4), Z3_Blizzard (T5), abismos Z4 (T6). ✓
- Mais inimigos → Task 7. ✓
- Corredores via CorridorSection ALINHADOS ao piso → Task 1 (FLOOR_Y + `_make_corridor`). ✓
- Tudo deslocado pra direita → Task 1 constantes + Task 7 markers/câmera. ✓
- Web export → Task 8. ✓

**2. Placeholder scan:** Os stubs `_build_zone2/3/4` são criados na Task 3 e PREENCHIDOS nas Tasks 4–6 (não ficam vazios ao fim). Coordenadas são valores iniciais com passo de verificação/tuning explícito — não são "TODO". ✓

**3. Type consistency:** `_floor_seg`/`_glass_wall`/`_recoverable_pit`/`_deadly_pit`/`_step_up` definidos na Task 2 e usados igual nas Tasks 3–6. `FLOOR_Y`/`_CORR_INTERIOR`/`_BOSS_ENTRY_X` definidos na Task 1. Nomes `Z*_Floor_*`/`Z4_Glass_*` batem com `_texture_for_node`. ✓
