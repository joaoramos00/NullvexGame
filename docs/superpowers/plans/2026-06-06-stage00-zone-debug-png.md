# Plano — Gerador de PNG de debug por zona (Fase 00)

**Data:** 2026-06-06
**Spec:** `docs/superpowers/specs/2026-06-06-stage00-zone-debug-png-design.md`
**Branch:** `feat/kawagael-reskin` (trabalho de debug-tooling, sem conflito com o reskin)

> **Status 2026-06-12 — IMPLEMENTADO, com pivot para SVG headless.**
> Fase 1 (`ZoneClassifier` + testes) entregue. Fase 2 entregue, mas o render por GPU
> (`SubViewport`/PNG) **reiniciava a máquina** (Radeon 520, viewport 4096px) — trocado
> por emissão de **SVG vetorial headless** (zero GPU). `tools/zone_debug.gd` instancia
> a `stage_00` só para coletar geometria viva e escreve um `.svg` por área + legenda.
> Rodar: `Godot --headless --path . res://tools/zone_debug.tscn -- --area=all`.
> A descrição de Fase 2 abaixo (SubViewport/modos real+esquemático/PNG) é o plano
> original; a entrega real é SVG headless.

## Objetivo

Gerar, por área da fase 00, um PNG rotulado onde cada elemento/inimigo recebe um ID
curto (`plat001`, `grunt001`…) que mapeia de volta ao nó real, em dois modos (real e
esquemático), mais uma legenda `ID → nó → rect`. Uso: tornar o debug de zonas
inequívoco ("sobe `plat003` 2 tiles").

## APIs confirmadas (não assumir — já verificado)

| Item | Fato |
|---|---|
| Cena da fase | `res://stages/stage_00/stage_00.tscn` |
| `EnemyBase` | `class_name EnemyBase` (`characters/enemies/enemy_base.gd`) |
| `EnemyFlyer` | **SEM `class_name`** (`characters/enemies/enemy_flyer.gd`) → classificar por path do script |
| `EnemyMiniBoss` | `class_name EnemyMiniBoss` (`characters/enemies/enemy_miniboss.gd`) |
| `IntroBoss` | `class_name IntroBoss` (`characters/bosses/intro_boss.gd`) |
| `CheckpointDoor` | `class_name CheckpointDoor` (`stages/checkpoint_door.gd`) |
| Spawn de inimigos | gated por `DebugBoot.no_enemies` (autoload `tests/bot/debug_boot.gd`); o gerador força `no_enemies = false` |
| Render | exige GPU → roda em janela, **não** `--headless` |

`enemy_flyer.gd` estende `EnemyBase`, então `is EnemyBase` casa para ambos; desempatar
flyer pelo `get_script().resource_path.ends_with("enemy_flyer.gd")`.

## Arquitetura (do spec)

1. `tools/zone_classifier.gd` — `class_name ZoneClassifier`, pura/testável (sem GPU).
2. `tools/zone_debug.gd` + `tools/zone_debug.tscn` — gerador em janela (instancia
   stage_00 num SubViewport, varre a árvore viva, renderiza, salva PNGs + legenda).
3. `tests/test_zone_debug.gd` — testa o classifier headless com fixtures.

---

## Fase 1 — `ZoneClassifier` (TDD, sem GPU)

### Tarefa 1.1 — Esqueleto + tipos

`tools/zone_classifier.gd`:

```gdscript
class_name ZoneClassifier
extends RefCounted

# Registro de entrada (resolvido pelo chamador):
#   { name: String, kind: String, rect: Rect2 }
# kind ∈ {"boss","mboss","grunt","flyer","door","goal","zone","spawn",
#         "movp","area","static", ...}  (tag já resolvida pelo zone_debug)
# Saída: { id, type, area, name, rect }
```

Constantes de ordem (substrings colidem — ordem importa):

```gdscript
const AREA_ORDER := ["Z1", "Corr1", "MiniBoss", "Corr2", "Z3", "Z2", "Boss"]
```

### Tarefa 1.2 — `classify_type(name, kind) -> String` (escrever teste primeiro)

Ordem obrigatória (do spec): classe de inimigo → `movp` → `sub` → `plat` → demais.

```
kind=="boss"  → "boss"
kind=="mboss" → "mboss"
kind=="flyer" → "flyer"
kind=="grunt" → "grunt"
kind=="door"  → "door"
kind=="goal" / name=="GoalZone" → "goal"
kind=="spawn" / name=="PlayerSpawn" → "spawn"
name contém "Boundary" → "bound"
kind=="movp" / name contém "Moving" / kind=="animatable" → "movp"
name contém "SubPlat" → "sub"
name contém "Plat"    → "plat"
name contém "Step"    → "step"
name contém "Block"   → "block"
name contém "Glass"   → "glass"
name contém "Cover"   → "cover"
name contém "Ceil"    → "ceil"
name contém ("Wall" | "LWall" | "RWall" | "Div") → "wall"
name contém "Floor"   → "floor"
kind=="zone" / Area2D de zona → "zone"
fallback → "misc"
```

Testes: `Z3MovingPlat`→`movp`, `SubPlat_Z3_A`→`sub`, `Plat_Z1A`→`plat`,
`Floor_Z1A`→`floor`, `Corr1_Wall_L`→`wall`, `Glass_Z3_Ceil`→`glass`,
`Block_Z1A`→`block`, `Step_Z2_1`→`step`, `Div_Z3_X`→`wall`, `GoalZone`→`goal`.

### Tarefa 1.3 — `classify_area(name, center, area_extents) -> String`

Primeiro por prefixo do nome, na `AREA_ORDER` (MiniBoss antes de Boss):

```
contém "Z1" → Z1
começa "Corr1" → Corr1
contém "MiniBoss" → MiniBoss
começa "Corr2" → Corr2
contém "Z3" ou "CorrZ3" → Z3
contém "Z2" → Z2
contém "Boss" ou name=="GoalZone" → Boss
```

Sem match por nome (`PlayerSpawn`, `LBoundary`, inimigos spawnados, portas) →
por `center.x` caindo na faixa X da área (`area_extents`: `{area: [min_x, max_x]}`
computado pelos membros já atribuídos por nome).

Testes: `Plat_Z1A`→Z1, `Corr1_Wall_L`→Corr1, `MiniBoss_Floor`→MiniBoss (não Boss!),
`Boss_Floor`→Boss, `GoalZone`→Boss, `CorrZ3_Entry_Ceil`→Z3, inimigo sem prefixo em
X∈Z1 → Z1.

### Tarefa 1.4 — `area_extents(records) -> Dictionary` e `assign_ids(records)`

- `area_extents`: varre só os registros com área-por-nome resolvida, acumula
  min/max X por área. (Duas passadas em `classify`: nome primeiro, X depois.)
- `assign_ids`: agrupa por `type`, ordena cada grupo por `(rect.position.x,
  rect.position.y)` asc, numera `prefixo%03d` global na fase (não por área).

Testes: IDs únicos; `plat001` é o plat de menor (x,y); dois plats → `plat001/plat002`;
ordenação estável.

### Tarefa 1.5 — `classify(records) -> { items, area_bboxes }`

Orquestra: type → extents → area → ids; computa bbox por área (`Rect2` que engloba
todos os membros da área). Retorna `items` (lista final) + `area_bboxes`.

**Gate:** `tests/test_zone_debug.gd` headless verde com todas as fixtures do spec.

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_zone_debug.tscn
```

(Criar `tests/test_zone_debug.tscn` associando `test_zone_debug.gd`, padrão do projeto:
`extends Node` + `.tscn`, `quit(0)` no fim.)

---

## Fase 2 — Gerador `zone_debug.gd` (GPU, janela)

### Tarefa 2.1 — Boot + carregamento da fase

`tools/zone_debug.tscn` (Node raiz + script) + `tools/zone_debug.gd`:

```gdscript
extends Node
func _ready() -> void:
    DebugBoot.no_enemies = false   # força inimigos pra capturá-los
    var args := _parse_args()      # OS.get_cmdline_user_args(): --mode, --area
    var sub := SubViewport.new()
    sub.size = Vector2i(4096, 4096)   # placeholder; reconfig por área
    add_child(sub)
    var stage := preload("res://stages/stage_00/stage_00.tscn").instantiate()
    sub.add_child(stage)
    await get_tree().process_frame
    await get_tree().process_frame   # _ready + spawns de código rodam
    ...
```

`_parse_args` lê `--mode=real|schematic|both` (default both), `--area=all|z1|...`
(default all) de `OS.get_cmdline_user_args()`.

### Tarefa 2.2 — Varredura da árvore → registros `{name, kind, rect}`

Recursivo a partir do `stage`. Resolução de `kind` (ordem importa — flyer estende
EnemyBase):

```
n is IntroBoss → "boss"
n is EnemyMiniBoss → "mboss"
n is EnemyBase:
    n.get_script().resource_path.ends_with("enemy_flyer.gd") → "flyer"
    senão → "grunt"
n is CheckpointDoor → "door"
n.name == "GoalZone" → "goal"
n.name == "PlayerSpawn" → "spawn"
n is AnimatableBody2D → "movp"
n is Area2D → "zone"
n is StaticBody2D → "static"
```

`rect`: do primeiro `CollisionShape2D`+`RectangleShape2D` filho
(`global_position` do shape + `size`); inimigo sem rect de colisão → AABB do
sprite. Sem rect válido → ignora com `push_warning`.

### Tarefa 2.3 — Render por área × modo

Para cada área (filtrada por `--area`) e modo (filtrado por `--mode`):

- bbox da área (do classifier) + padding 96px.
- viewport.size = tamanho do bbox em game units; lado maior cap 4096 (escala
  uniforme se exceder).
- `Camera2D` no centro do bbox, zoom pra caber.
- **real:** mostra a `stage_00` (tiles reais) + overlay de caixas/rótulos.
- **schematic:** esconde a arte da fase (`stage.visible=false` ou viewport
  separado) + fundo escuro + caixa preenchida por cor-de-tipo + rótulo + coord.
- `await` 1 frame; `sub.get_texture().get_image().save_png(path)`.
- path: `docs/stage_00/zones/<area>_<modo>.png` (`_real` / `_schem`).

Overlay: nó `Control`/`Node2D` desenhando, por item da área, contorno do rect na
cor do tipo + ID em `ThemeDB.fallback_font` com fundo semi-opaco perto do
canto sup-esq.

Cores por tipo: dicionário fixo (`floor=cinza, plat=verde, sub=verde-claro,
movp=ciano, wall=azul, ceil=azul-escuro, step=oliva, block=marrom, glass=azul
translúcido, cover=cinza-azulado, door=amarelo, zone=laranja, goal=magenta,
bound=vermelho-escuro, spawn=branco, grunt=vermelho, flyer=rosa, mboss=roxo,
boss=vinho`).

### Tarefa 2.4 — Legenda + erros + quit

- `docs/stage_00/zones/legenda.md`: tabela por área `| ID | nó | tipo | rect |`.
- Cria `docs/stage_00/zones/` se faltar (`DirAccess.make_dir_recursive_absolute`).
- Área sem membros → pula com aviso, não quebra o batch.
- `save_png` falho → erro visível.
- `get_tree().quit(0)` no fim.

**Gate:** rodar e inspecionar visualmente:

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --path . res://tools/zone_debug.tscn -- --mode=both --area=all
```

---

## Ordem de execução

1. Fase 1 inteira (classifier + testes verdes) — é o núcleo arriscado, e é testável
   sem GPU.
2. Fase 2 (gerador) — depende do classifier pronto.
3. Validação visual dos PNGs pelo usuário.

## Notas de processo (constraints do projeto)

- **Não** rodar o jogo no browser/Playwright sem pedir — validação por análise
  estática + o gate de testes headless.
- Tooling de debug puro (sem mudança em código de jogo rodado no web build) → **não**
  exige web-export/restart do localhost. Se algum arquivo de `stages/`/autoload mudar,
  aí sim re-exportar.
- Tipar explicitamente retornos de `sign()/clamp()/abs()` como `: float` (Variant no
  web export) — caso apareçam no overlay/escala.
- Rebase com `master` antes de qualquer push; PR, nunca push direto em master.
- Log de observabilidade em `.opencastle/logs/` antes de encerrar a sessão.

## Critérios de aceite

- [ ] `tests/test_zone_debug.tscn` headless: PASS em todas as fixtures do spec.
- [ ] 7 áreas × 2 modos = até 14 PNGs em `docs/stage_00/zones/` + `legenda.md`.
- [ ] IDs únicos, por tipo, globais, ordenados por (x,y); legenda mapeia ID→nó→rect.
- [ ] `--mode` e `--area` filtram corretamente (rodar um modo/área isolado funciona).
- [ ] MiniBoss classifica como área `MiniBoss` (não `Boss`); `Z3MovingPlat`→`movp`.
