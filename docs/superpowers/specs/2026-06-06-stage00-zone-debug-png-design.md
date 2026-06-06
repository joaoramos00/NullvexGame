# Spec — Gerador de PNG de debug por zona (Fase 00)

**Data:** 2026-06-06
**Objetivo:** Facilitar o debug das zonas da fase 00 gerando, por área, uma imagem
rotulada onde cada elemento e inimigo recebe um ID curto (`plat001`, `grunt001`…)
que mapeia de volta ao nó real. Acompanha uma legenda `ID → nó real → rect`.

## Problema

A fase 00 é grande (~7 áreas, x de 0 a ~18000) e mistura elementos do `.tscn`
com elementos criados em código (`Z3_Wall`, `Z3MovingPlat`, portas, inimigos).
Hoje, para falar de um elemento específico durante o debug, é preciso caçar o nó
no `.tscn`/código. Um mapa visual rotulado por área torna isso imediato:
"sobe `plat003` 2 tiles" vira uma referência sem ambiguidade.

## Escopo

- **7 PNGs** (um por área), em **dois modos selecionáveis** (real e esquemático).
- Cobre apenas a **fase 00**.
- Inclui paredes, tetos e pisos (todos rotulados) — debug de colisão é o uso.

Fora de escopo: outras fases, edição dos nós, UI interativa.

## Áreas (esquerda → direita)

```
Z1 (entrada) → Corr1 → MiniBoss → Corr2 → Z2 → Z3 (corredor+gauntlet) → Boss
```

Atribuição de área **por prefixo do nome** (os nomes já codificam a área):

| Área | Regra de nome |
|---|---|
| `Z1` | contém `Z1` |
| `Corr1` | começa com `Corr1` |
| `MiniBoss` | contém `MiniBoss` |
| `Corr2` | começa com `Corr2` |
| `Z2` | contém `Z2` |
| `Z3` | contém `Z3` ou `CorrZ3` |
| `Boss` | contém `Boss` ou nome == `GoalZone` |

**Ordem de avaliação obrigatória** (substrings colidem): `Z1` → `Corr1` →
`MiniBoss` → `Corr2` → `Z3` → `Z2` → `Boss`. Crítico: testar `MiniBoss` **antes**
de `Boss` (pois `"MiniBoss"` contém `"Boss"`).

Elementos sem prefixo de área (`PlayerSpawn`, `LBoundary`, portas de checkpoint,
inimigos spawnados, zone triggers) são atribuídos pela **posição X do centro**,
caindo na faixa X da área cujos membros (passo acima) cobrem aquele X.

## Taxonomia de tipos (prefixo do ID)

Classificação por palavra-chave no nome e/ou classe do nó:

| Tipo | Prefixo | Regra |
|---|---|---|
| Piso/chão | `floor` | nome contém `Floor` |
| Plataforma flutuante | `plat` | contém `Plat` (e não `SubPlat`/`Moving`) |
| Sub-plataforma | `sub` | contém `SubPlat` |
| Plataforma móvel | `movp` | `AnimatableBody2D` ou contém `Moving` |
| Degrau | `step` | contém `Step` |
| Bloco | `block` | contém `Block` |
| Parede | `wall` | contém `Wall`, `LWall`, `RWall` ou `Div` |
| Teto | `ceil` | contém `Ceil` |
| Cobertura | `cover` | contém `Cover` |
| Vidro (sem grab) | `glass` | contém `Glass` |
| Porta de checkpoint | `door` | classe `CheckpointDoor` / cena de porta |
| Trigger de zona | `zone` | `Area2D` de zona |
| Zona de objetivo | `goal` | nome == `GoalZone` |
| Limite de fase | `bound` | contém `Boundary` |
| Spawn do player | `spawn` | nome == `PlayerSpawn` |
| Grunt (terrestre) | `grunt` | classe `EnemyBase` |
| Flyer (voador) | `flyer` | classe `EnemyFlyer` |
| Miniboss | `mboss` | cena do miniboss |
| Boss | `boss` | `intro_boss` |

**Ordem de avaliação obrigatória** (substrings colidem): classe de inimigo →
`movp` (`AnimatableBody2D`/`Moving`) → `sub` (`SubPlat`) → `plat` (`Plat`) → demais.
Crítico: `movp` e `sub` **antes** de `plat` (pois `"Z3MovingPlat"` e `"SubPlat"`
contêm `"Plat"`).

**Nota:** peças de corredor (`Corr1_Floor`, `CorrZ3_Entry_Ceil`…) classificam pelo
papel estrutural (`floor`/`ceil`/`wall`), não num tipo "corr" — mais útil pro debug.

## IDs

- Numeração **por tipo, global na fase**, ordenada por `(x, y)` ascendente.
- Formato `prefixo` + 3 dígitos: `plat001`, `plat002`, … `grunt001`, …
- Estável e único: `plat003` é sempre o mesmo nó (enquanto o layout não muda).
- Cada PNG de área mostra apenas os IDs dos elementos daquela área (números podem
  não começar em 001 numa área — é esperado, pois a numeração é global por tipo).

## Arquitetura

Duas unidades isoladas:

### 1. `tools/zone_classifier.gd` — classe pura (testável sem GPU)

`class_name ZoneClassifier`. Entrada: lista de registros
`{ name: String, kind: String, rect: Rect2 }` (kind = nome de classe/tag já
resolvido pelo chamador). Saída: lista de
`{ id, type, area, name, rect }` + bbox por área.

- Sem dependência de cena/render → testável com fixtures.
- Funções: `classify_type(name, kind)`, `classify_area(name, center, area_extents)`,
  `assign_ids(records)`, `area_bboxes(records)`.

### 2. `tools/zone_debug.tscn` + `zone_debug.gd` — gerador (cena com janela)

Roda como cena **normal** (NÃO `--headless` — headless usa driver de render dummy
e `get_image()` volta em branco). Fluxo:

1. Instancia a cena real `stage_00` num `SubViewport`, `await` 2 frames para o
   `_ready` rodar e os inimigos/elementos de código spawnarem.
2. Varre a árvore viva → coleta `{name, kind, rect}` de cada
   `StaticBody2D`/`AnimatableBody2D`/`Area2D` (rect via `CollisionShape2D` +
   `RectangleShape2D`) e de cada inimigo (rect via collision shape ou AABB do sprite).
3. Passa pro `ZoneClassifier`.
4. Para cada área × modo:
   - Posiciona `Camera2D` no centro do bbox da área (+ padding **96px**), zoom para
     caber; tamanho do viewport = tamanho do bbox em game units, lado maior limitado
     a **4096px** (escala uniforme se exceder).
   - **modo real:** renderiza a `stage_00` (tiles reais da fase) + overlay de
     caixas/rótulos por cima.
   - **modo esquemático:** fundo escuro + caixa preenchida por tipo (cor por tipo) +
     rótulo + coordenada; sem a arte da fase.
   - `viewport.get_texture().get_image().save_png("docs/stage_00/zones/<area>_<modo>.png")`.
5. Gera a legenda e `quit()`.

**Overlay de rótulo:** contorno do rect na cor do tipo + texto do ID próximo ao
canto superior-esquerdo do rect, com fundo semi-opaco para legibilidade
(`ThemeDB.fallback_font`).

**Cores por tipo:** paleta fixa no `zone_debug.gd` (ex.: floor=cinza, plat=verde,
wall=azul, enemy=vermelho, door=amarelo, goal=magenta…). Documentada numa legenda
de cores no topo de cada PNG esquemático.

### 3. Legenda — `docs/stage_00/zones/legenda.md`

Tabela agrupada por área:

```
## Z1
| ID | nó real | tipo | rect (x, y, w, h) |
|----|---------|------|-------------------|
| plat001 | Plat_Z1A | plat | (…, …, …, …) |
```

## Invocação

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --path . \
  res://tools/zone_debug.tscn -- --mode=both --area=all
```

Args via `OS.get_cmdline_user_args()`:
- `--mode=real|schematic|both` (default `both`)
- `--area=all|z1|corr1|miniboss|corr2|z2|z3|boss` (default `all`)

Permite rodar só um modo/área conforme a necessidade.

## Saídas

```
docs/stage_00/zones/
  z1_real.png        z1_schem.png
  corr1_real.png     corr1_schem.png
  miniboss_real.png  miniboss_schem.png
  corr2_real.png     corr2_schem.png
  z2_real.png        z2_schem.png
  z3_real.png        z3_schem.png
  boss_real.png      boss_schem.png
  legenda.md
```

## Testes

`tests/test_zone_debug.gd` (headless, sem GPU) — testa o `ZoneClassifier` com
fixtures espelhando nós reais da fase 00:

- `Plat_Z1A` → type `plat`, area `Z1`.
- `Corr1_Wall_L` → type `wall`, area `Corr1`.
- `Z3MovingPlat` → type `movp`, area `Z3`.
- `GoalZone` → type `goal`, area `Boss`.
- Inimigo `EnemyBase` em X dentro de Z1 → type `grunt`, area `Z1` (via posição).
- IDs únicos e sequenciais por tipo, ordenados por (x, y).

Os PNGs em si são verificados visualmente pelo usuário.

## Tratamento de erros

- Nó sem `CollisionShape2D`/`RectangleShape2D` válido → ignorado (com aviso no log).
- Área sem membros → PNG não gerado (aviso no log), não quebra o batch.
- Falha de `save_png` (path) → erro visível; cria `docs/stage_00/zones/` se faltar.

## Riscos / decisões

- **Render exige GPU:** roda em janela, não headless. Aceitável (a janela abre,
  renderiza e fecha sozinha).
- **`DebugBoot.no_enemies`:** o gerador força inimigos ligados para capturá-los.
- **Áreas muito largas (Z3 ~3570px):** PNG largo; o cap de 4096px no lado maior
  evita arquivos gigantes.
