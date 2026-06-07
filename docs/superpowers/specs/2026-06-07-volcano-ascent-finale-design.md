# Final em Ascensão de Vulcão (stage_01) — Design

**Data:** 2026-06-07
**Fase:** stage_01 (boss Ignarath, fogo)
**Branch:** feat/stagebot-z3

## Objetivo

Substituir o shaft de wall-kick e o Corridor2 por uma **ascensão de vulcão**: a partir da maré de lava, o player sobe duas escadas de piso+plataforma com lava subindo, alcança o cume e **cai dentro da cratera** para a arena do boss. Tudo dentro do orçamento de pulo do jogo (≤118px vertical, ~196px horizontal), portanto validável pelo StageBot.

## Motivação

- O shaft de wall-kick (`ShaftUpP1‑5`, gaps de 256px) é **inalcançável por pulo** (pulo máx ≈118px) e o bot não encadeia wall-kicks alternados (`climb_to` só faz parede única). Ver `reference_jump_height` e `reference_imgdebug_floor_platform_hole`.
- A ideia de "maré de lava" da zona 3 fica mantida e estendida verticalmente, com a lava como ameaça de ascensão.

## Fluxo (base → cume)

```
                         ╔═════════════════╗
   cume / cratera  →     ║  buraco ↓↓↓     ║  player cai DENTRO da cratera
                         ║ [arena do BOSS] ║  (câmara do vulcão, reusa boss atual)
                         ╚═════════════════╝
        z4 coupled ↑   escada piso+plataforma (lava ACOPLADA à altura, só-de-ida)
        patamar z4     plats horizontais + CHECKPOINT (respawn + cura)
        z3 chase   ↑   escada piso+plataforma (lava PERSEGUINDO, sobe contínua)
        maré           seção horizontal atual (mantida)
```

## Componentes

### 1. Maré horizontal (mantida)
Sem mudanças. `Z3Entry` (piso+plataforma+buraco), maré oscilante (`rising_lava` modo tide), passagens, refúgios, `Z3Exit`. A `Z3Exit` passa a ser a base da escada-chase (em vez de levar ao shaft).

### 2. Subida z3 — "chase" (lava perseguindo)
- **Escada** de peças piso+plataforma subindo up-and-right da base (~x15300, y2624) até o patamar z4 (~y1600). Cada degrau **≤118px vertical / ≤196px horizontal**.
- **Lava-chase**: uma `Area2D` instant-kill cuja superfície (`position.y`) sobe **contínua** num ritmo fixo (`rise_speed`, ~80px/s) assim que ativada, sem parar, até um teto (`cap_y` = piso do patamar z4). Mata no contato. Ativada por um gatilho (`Area2D`) na base da escada quando o player entra.
- **Sem volta**: a lava cobre a base; descer = morte.
- **Bot**: congela em `low_y` quando `DebugBoot.bot_enabled` (early-return no `_physics_process`), expondo a escada inteira → o bot valida pulando degrau a degrau. A pressão de tempo do chase NÃO é testada pelo bot (ele só prova que o caminho existe).

### 3. Patamar z4 + checkpoint
- Plats horizontais largos e seguros (~y1600), acima do `cap_y` da lava-chase — respiro entre as duas subidas. Reaproveita o estilo dos `Z4Plat` sobre lava.
- **Checkpoint** (`checkpoint.tscn`, índice 2) no patamar: salva respawn + cura (substitui a função do CP2 removido). Sem porta/corredor.

### 4. Subida z4 — "coupled" (lava acoplada)
- **Escada** de piso+plataforma continuando do patamar (~y1600) até o cume (~y400), mesmos limites de pulo.
- **Lava-coupled**: `Area2D` instant-kill cuja superfície acompanha a **altura máxima já alcançada** pelo player (fica logo abaixo do degrau mais alto atingido), só sobe (nunca desce) → caminho só-de-ida, sem pressão de tempo. Mata no contato.
- **Bot**: congela em `low_y` no modo bot.

### 5. Cume / cratera (buraco no fim) → boss
- A última peça da escada é **piso+plataforma+buraco**; o buraco é a **cratera** no cume (~x21000, y~400).
- O player **cai dentro da cratera** → uma abertura no teto da câmara do boss leva à arena.
- **Arena do boss reaproveitada**: `BossFloor`, `BossWallL/R`, `BossCeil`, `BossPlat1/2`, `Ignarath` (atuais, ~x19776–22592, y~480–1024). Abre-se um vão no `BossCeil` na coluna da cratera para a queda entrar. A entrada do boss passa a ser **por cima** (queda), não mais horizontal pelo corredor.

### 6. Lava de fundo (estética de vulcão)
A lava de fundo (poça inferior) preenche visualmente as paredes do vulcão sob as escadas, reforçando o tema. Reusa a textura `stage_01_lava_v2.png` + shader de fluxo.

## Remoções

- `ShaftUpWallL`, `ShaftUpWallR`, `ShaftUpP1`–`ShaftUpP5` (shaft wall-kick).
- `Corridor2` (CP2 — corredor/porta/checkpoint horizontal).
- O caminho horizontal antigo da zona 4 que levava ao Corridor2.

## Mecânica de lava — implementação

Estender `rising_lava.gd` com um `@export var mode: String` (`"tide"` | `"chase"` | `"coupled"`), OU criar `chase_lava.gd` e `coupled_lava.gd`. Preferência: **modos no mesmo script** (menos duplicação), todos com o early-return de congelamento no bot.

- `tide`: comportamento atual (oscila low↔high).
- `chase`: inativa até `activate()`; depois `position.y` faz `move_toward(cap_y, rise_speed*delta)`; para ao chegar em `cap_y`.
- `coupled`: a cada frame, `target = player.global_position.y + offset`; `position.y = min(position.y, target)` (só sobe). Nunca desce.

Todas instant-kill em `body_entered` (CharacterBase → `kill()`), e todas com `if DebugBoot.bot_enabled: return` no `_physics_process` (ficam em `low_y`).

## Construção (stage_01_scene.gd)

Seguindo o padrão `_build_zone2`/`_build_zone3`:
- `_build_zone3()` estende a escada-chase a partir da `Z3Exit`.
- Novo `_build_zone4()` monta patamar + checkpoint + escada-coupled + cratera.
- `_ready()`: remove (`queue_free`) os nós do shaft e do `Corridor2`; abre o vão no `BossCeil`.
- Reuso de `_z3_floor_platform(...)` (com `hole` p/ a cratera) para todos os degraus.
- `_zone_spawn()`: pontos de debug para z3-climb, patamar z4, z4-coupled, cume.

## Validação pelo bot (StageBot)

`tests/bot/paths/stage_01.gd`, após a maré:
1. Escada-chase: `jump_to` por degrau (lava congelada baixa).
2. Patamar z4: `walk_to` + screenshot (checkpoint).
3. Escada-coupled: `jump_to` por degrau.
4. Cume: `walk_to` até a borda da cratera, `drop` para dentro → screenshot do boss.

Critério de sucesso: `BOT_DONE` sem `BOT_STUCK` nem morte, com a lava congelada. Calibração iterativa via logs `BOT_*` (como nas zonas 1–3).

## Coordenadas (aproximadas — ajuste fino na implementação)

- Maré: y2624 (atual).
- Escada-chase: x≈15300→17400, y2624→1600 (~10 degraus de ~104px↑ / ~210px→).
- Patamar z4 + checkpoint: x≈17400–18800, y≈1600.
- Escada-coupled: x≈18800→20900, y1600→500 (~10 degraus).
- Cratera: x≈21000, y≈450 (acima do `BossCeil` y448).
- Arena boss: reusa x19776–22592, y480–1024.

Tile = 64 game units; `_SRC_TS = 32`. Degraus tile-alinhados.

## Casos de borda / riscos

- **Lava-chase mal calibrada** (rápida/lenta demais): ritmo `rise_speed` exposto via `@export` para tuning. Bot não cobre timing — teste manual no fim.
- **Respawn**: morrer acima do checkpoint z4 → respawn no patamar (cura). Abaixo → CP1 (início da zona 3).
- **Vão no BossCeil**: garantir que a queda da cratera entra na arena sem prender o player na borda.
- **Câmera**: a subida é vertical; a câmera segue o player (zoom bot 1.3 / jogo 2.2) — conferir enquadramento.

## Testes

- `run-tests` (headless) continua passando (load das cenas).
- StageBot: `?stage=01&bot=1&noenemies=1&zone=N` por trecho; alvo final `BOT_DONE`.
- Conferência visual via screenshots (entrada de cada escada, patamar, cume, queda no boss).
