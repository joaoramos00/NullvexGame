# Final em Ascensão de Vulcão (stage_01) — Design

**Data:** 2026-06-07
**Fase:** stage_01 (boss Ignarath, fogo)
**Branch:** feat/stagebot-z3

## Objetivo

Substituir o shaft de wall-kick e o Corridor2 por uma **ascensão de vulcão na zona 4**. A **zona 3 fica intacta** (maré + peças piso+plataforma+buraco, já validada pelo bot). A zona 4 vira a subida: o player sobe por uma escada com lava perseguindo (chase), passa por um patamar de respiro, sobe outra escada com lava acoplada (coupled), chega ao topo (checkpoint), e **cai dentro da cratera** para a arena do boss. Tudo dentro do orçamento de pulo (≤118px vertical, ~196px horizontal) → validável pelo StageBot.

## Motivação

- O shaft de wall-kick (`ShaftUpP1‑5`, gaps de 256px) é **inalcançável por pulo** (pulo máx ≈118px) e o bot não encadeia wall-kicks (`climb_to` só faz parede única). Ver `reference_jump_height` e `reference_imgdebug_floor_platform_hole`.
- Reaproveita as peças piso+plataforma(+buraco) e a ideia de lava como ameaça, agora na vertical.

## Fluxo (base → cume)

```
                         ╔═════════════════╗
   cratera (buraco) →    ║  buraco ↓↓↓     ║  player cai DENTRO da cratera
                         ║ [arena do BOSS] ║  (câmara do vulcão, reusa boss atual)
                         ╚═════════════════╝
        topo + ⚑ CHECKPOINT  (respawn + cura, logo antes do boss)
        z4 coupled ↑   escada piso+plataforma (lava ACOPLADA à altura, só-de-ida)
        patamar (meio) plats horizontais de respiro (SEM checkpoint; teto da lava-chase)
        z4 chase   ↑   escada piso+plataforma (lava PERSEGUINDO, sobe contínua)
        base z4        após a saída da zona 3
        ───────────────────────────────────────────────
        ZONA 3 (intacta): maré horizontal + piso+plataforma+buraco  ⚑ CP1 (já existe)
```

## Componentes

### 0. Zona 3 (intacta)
Sem mudanças. Maré oscilante, passagens, refúgios, `Z3Entry`/`Z3Exit` (piso+plataforma+buraco), bot já valida. A `Z3Exit` continua sendo a saída da zona 3; logo após ela começa a base da zona 4.

### 1. Base da zona 4
Pequeno piso de transição após a `Z3Exit` (~x16200, y2624), onde começa a escada-chase. (CP1, na zona 3, é o respawn caso morra antes do topo.)

### 2. Subida z4 — "chase" (lava perseguindo)
- **Escada** de peças piso+plataforma subindo up-and-right da base (~y2624) até o patamar do meio (~y1550). Cada degrau **≤118px vertical / ≤196px horizontal**.
- **Lava-chase**: `Area2D` instant-kill cuja superfície (`position.y`) sobe **contínua** num ritmo fixo (`rise_speed`, ~80px/s) assim que ativada (gatilho na base), sem parar, até um teto (`cap_y` = piso do patamar do meio). Mata no contato.
- **Sem volta**: a lava cobre a base; descer = morte.
- **Bot**: congela em `low_y` quando `DebugBoot.bot_enabled` → o bot valida a escada pulando degrau a degrau. A pressão de tempo NÃO é testada pelo bot.

### 3. Patamar do meio (respiro, SEM checkpoint)
Plats horizontais largos e seguros (~y1550), acima do `cap_y` da lava-chase — respiro entre as duas subidas. Não salva progresso (o único checkpoint da subida é no topo).

### 4. Subida z4 — "coupled" (lava acoplada)
- **Escada** de piso+plataforma do patamar (~y1550) até o topo (~y500), mesmos limites de pulo.
- **Lava-coupled**: `Area2D` instant-kill cuja superfície acompanha a **altura máxima já alcançada** pelo player (fica logo abaixo do degrau mais alto atingido), só sobe → só-de-ida, sem pressão de tempo. Mata no contato.
- **Bot**: congela em `low_y` no modo bot.

### 5. Topo + checkpoint (antes do boss)
- Patamar seguro no topo (~y500) com **Checkpoint** (`checkpoint.tscn`, índice 2): salva respawn + cura, **logo antes do boss**. Morrer pro boss → respawn no topo. Morrer na subida (abaixo do topo) → respawn no CP1 (início da zona 3).

### 6. Cratera (buraco no fim) → boss
- Última peça **piso+plataforma+buraco** no topo; o buraco é a **cratera** (~x21000, y~450).
- O player **cai dentro** → vão no teto da câmara do boss leva à arena.
- **Arena do boss reaproveitada**: `BossFloor`, `BossWallL/R`, `BossCeil`, `BossPlat1/2`, `Ignarath` (atuais, ~x19776–22592, y~480–1024). Abre-se um vão no `BossCeil` na coluna da cratera. Entrada do boss passa a ser **por cima** (queda).

### 7. Lava de fundo (estética de vulcão)
Lava de fundo preenche visualmente as paredes do vulcão sob as escadas (textura `stage_01_lava_v2.png` + shader de fluxo).

## Remoções

- `ShaftUpWallL`, `ShaftUpWallR`, `ShaftUpP1`–`ShaftUpP5` (shaft wall-kick).
- `Corridor2` (CP2 — corredor/porta/checkpoint horizontal).
- O caminho horizontal antigo da zona 4 que levava ao Corridor2.

## Mecânica de lava — implementação

Estender `rising_lava.gd` com `@export var mode: String` (`"tide"` | `"chase"` | `"coupled"`):
- `tide`: comportamento atual (oscila low↔high).
- `chase`: inativa até `activate()` (gatilho na base da z4); depois `position.y` faz `move_toward(cap_y, rise_speed*delta)`; para em `cap_y`.
- `coupled`: a cada frame `target = player.global_position.y + offset`; `position.y = min(position.y, target)` (só sobe).
- Todas instant-kill em `body_entered` (CharacterBase→`kill()`) e todas com `if DebugBoot.bot_enabled: return` no `_physics_process` (ficam em `low_y`).

## Construção (stage_01_scene.gd)

Padrão `_build_zone2`/`_build_zone3`:
- Zona 3: sem mudança.
- Novo `_build_zone4()`: base + escada-chase + lava-chase + gatilho + patamar do meio + escada-coupled + lava-coupled + topo + checkpoint + cratera.
- `_ready()`: remove (`queue_free`) os nós do shaft e do `Corridor2`; abre o vão no `BossCeil`.
- Reuso de `_z3_floor_platform(...)` (com `hole` p/ a cratera) em todos os degraus.
- `_zone_spawn()`: pontos de debug para base z4, patamar do meio, topo, cratera.

## Validação pelo bot (StageBot)

`tests/bot/paths/stage_01.gd`, após a maré (zona 3, já calibrada):
1. Base z4 → escada-chase: `jump_to` por degrau (lava congelada baixa).
2. Patamar do meio: `walk_to` + screenshot.
3. Escada-coupled: `jump_to` por degrau.
4. Topo (checkpoint): `walk_to` + screenshot.
5. Cratera: `walk_to` até a borda, `drop` para dentro → screenshot do boss.

Sucesso: `BOT_DONE` sem `BOT_STUCK` nem morte, lava congelada. Calibração iterativa via logs `BOT_*`.

## Coordenadas (aproximadas — ajuste fino na implementação)

- Zona 3 (intacta): maré y2624; `Z3Exit` até ~x16392.
- Base z4: ~x16200, y2624.
- Escada-chase: x≈16200→18200, y2624→1550 (~10 degraus de ~107px↑ / ~200px→).
- Patamar do meio: x≈18200–19200, y≈1550.
- Escada-coupled: x≈19200→20900, y1550→550 (~10 degraus).
- Topo + checkpoint: x≈20900–21100, y≈500.
- Cratera: x≈21000, y≈450 (acima do `BossCeil` y448).
- Arena boss: reusa x19776–22592, y480–1024.

Tile = 64 game units; `_SRC_TS = 32`. Degraus tile-alinhados.

## Casos de borda / riscos

- **Lava-chase mal calibrada**: `rise_speed` via `@export` p/ tuning; bot não cobre timing → teste manual.
- **Respawn**: morrer no topo/boss → checkpoint do topo (cura). Morrer na subida → CP1 (início da zona 3). É punitivo de propósito (a subida é um trecho só de ida).
- **Vão no `BossCeil`**: garantir que a queda da cratera entra na arena sem prender o player.
- **Câmera**: subida vertical; conferir enquadramento (zoom bot 1.3 / jogo 2.2).

## Testes

- `run-tests` (headless) continua passando (load das cenas).
- StageBot: `?stage=01&bot=1&noenemies=1&zone=N` por trecho; alvo final `BOT_DONE`.
- Conferência visual via screenshots (base, cada escada, patamar, topo/checkpoint, queda no boss).
