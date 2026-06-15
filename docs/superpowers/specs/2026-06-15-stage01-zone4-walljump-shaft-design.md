# Design — Zona 4 do Stage 01: shaft de wall-jump estilo MMX2

**Data:** 2026-06-15
**Status:** aprovado (brainstorming), pendente de plano de implementação
**Arquivo principal:** `stages/stage_01/stage_01_scene.gd` (`_build_zone4`, `_relocate_and_gap_boss`, `_draw_boss_room`, `_setup_boss_room_trigger`)

## Objetivo

Remodelar o topo da zona 4 (antes do boss Ignarath) substituindo a subida diagonal em dois trechos (escada-chase + escada-coupled) por um **shaft vertical de wall-jump** com **lava única que sobe perseguindo** (estilo Flame Stag, Mega Man X2). Resolve de vez o problema original ("lava na frente do buraco impedindo a descida") e unifica as duas lavas (`Z4ChaseLava` + `Z4CoupLava`) numa só.

A entrada do boss deixa de ser pela **cratera no teto** (queda) e passa a ser por uma **câmara → corredor → porta na parede lateral** da arena (padrão do stage 00).

## O que é removido

De `_build_zone4` / cena:
- `Z4ChaseStep4`–`Z4ChaseStep9` (mantém `Z4ChaseStep0`–`3`).
- `Z4MidA`, `Z4MidB` (patamar do meio).
- `Z4CoupStep0`–`Z4CoupStep12` (escada-coupled).
- `Z4CoupLava` (lava-coupled).
- `Z4Top` e a **cratera** (vão no teto do boss).
- **A arena do boss inteira** (`BossFloor`, `BossWallL/R`, `BossCeil*`, `BossLava`, `BossRoomTrigger`) e a lógica de `_relocate_and_gap_boss`/cratera — será **recriada do zero** (ver "Topo: câmara → corredor → boss").

## O que é mantido

- `Z4Base` (x16160–16480, topo 2624) e `Z4ChaseStep0`–`3` (escada-chase, x16480→17312, topo 2520→2208). A perseguição começa aqui.
- `Z4ChaseTrigger` (gatilho na base) — passa a ativar a lava única do shaft.

## Geometria nova

### Shaft de wall-jump (rota normal)

Shaft vertical logo após o `step003` (~x17300–17556 interior, paredes de 64px de cada lado), subindo de **y≈2208** até a câmara pré-chefe em **y≈360** (~1850px). Dividido em **6 segmentos** de ~300px. Largura **tunável** (o wall-jump cruza ~256px com folga; 224 é o teto seguro, 128 o rápido):

| Seg | Faixa Y (aprox) | Largura | Elementos |
|-----|------------------|---------|-----------|
| 1 | 2208 → 1900 | 192 | twin-wall, ease-in; **parede #1** (segredo) na base |
| 2 | 1900 → 1580 | 160 | estreito (pulos rápidos) + saliência de respiro curta |
| 3 | 1580 → 1260 | 192 | espinhos alternados nas faces (grupo `no_wall_grab` + dano) |
| 4 | 1260 → 940 | 224 | largo + **saliência que desmorona** (timed) |
| 5 | 940 → 620 | 192 | espinhos + **1 flyer** + saliência |
| 6 | 620 → 360 | 128 | estreito; **lava acelera** — clímax → saída na câmara pré-chefe |

Elementos:
- **Espinhos em faces de parede:** trechos onde a parede entra no grupo `no_wall_grab` (sem wall-grab/slide ali) + hitbox de dano. Força mirar o wall-jump nas faces limpas.
- **Saliências de respiro:** pequenas `StaticBody2D` laterais pra pousar ~1s. A lava continua subindo (sem descanso real).
- **Flyer:** 1× `EnemyFlyer` no seg 5 (e opcionalmente seg 6).

### Lava única

Substitui `Z4ChaseLava` + `Z4CoupLava` por **uma** lava (modo `chase`, `rising_lava.gd`):
- Cobre toda a largura do shaft.
- Disparada por `Z4ChaseTrigger` na base.
- Sobe a velocidade normal (`rise_speed`), **acelera no terço final** (a partir de ~y900) — ver "Mecânicas novas".
- `cap_y` **abaixo da câmara pré-chefe** (~y480) → topo sempre seco.

### Topo: câmara → corredor → boss

- **Câmara pré-chefe** (seca, respiro) recebe a saída do shaft pela direita (~y360).
- **Corredor do boss:** `CorridorSection` (padrão stage 00) com **porta do boss + checkpoint + trava de câmera**.
- **Arena do boss reconstruída do zero:** a arena atual do stage 01 é **deletada** (nós `BossFloor`, `BossWallL/R`, `BossCeil*`, `BossLava`, `BossRoomTrigger`, e a lógica de `_relocate_and_gap_boss`/cratera) e **recriada no molde da sala do boss do stage 00** — câmara de rocha com **porta na parede esquerda**, desenhada pelo mesmo padrão de `_draw_boss_room` (grid unificado, cantos côncavos, abertura da porta na parede), **mudando apenas o tileset** (usar o tileset de rocha/vulcão do stage 01 em vez do `_ROOM_TILE` do stage 00). Ignarath é re-spawnado dentro dela. Sem cratera no teto.

### Rota secreta (atalho + sub-tank)

Layout (vista de lado): câmara do coletável fica **em cima, à esquerda** da câmara pré-chefe; o elevador sobe da base até ela.

Sequência:
1. **Parede #1** — `cracked_wall` na **base do seg 1**, quebra **pelo lado do shaft**. Abre a **passagem secreta**.
2. **Elevador** — `vertical_platform.gd` em modo `up_only`, sobe da base da passagem até a **câmara do coletável** e **encaixa num buraco** no chão dela (a plataforma ancora no vão).
3. **Câmara do coletável** — contém **só um sub-tank**.
4. **Parede #2** — `cracked_wall` que separa a câmara do coletável da câmara pré-chefe; quebra **só pelo lado de dentro** (do coletável). Não é quebrável pelo lado da câmara pré-chefe (impede acesso reverso/cheese).
5. Sai na **câmara pré-chefe** → corredor → boss.

**Requisito pra quebrar (paredes #1 e #2): habilidade `galerix`** (comportamento atual do `cracked_wall.gd`, sem mudança). Como o player não tem galerix na 1ª vez no stage 01, o segredo é um **atalho de revisita/backtracking** — só acessível depois de derrotar o boss que dá galerix. Quem volta pega o sub-tank **e** pula o shaft + lava.

## Mecânicas novas (precisam de código)

1. **Saliência que desmorona** (timed platform): `StaticBody2D` que desativa a colisão ~0.5s após o player pousar e some (respawn ao sair da tela / reentrar na zona). Novo script pequeno (ex.: `crumbling_ledge.gd`).
2. **Parede quebrável por um lado só:** flag em `cracked_wall.gd` (ex.: `break_side`) — o `HitDetector` (Area2D) cobre só o lado permitido, então projétil do lado proibido não registra. Mantém o requisito de `galerix` existente.
3. **Aceleração da lava no terço final:** no modo `chase` do `rising_lava.gd`, aumentar `rise_speed` quando `position.y < accel_y` (novo `@export accel_y`, `accel_speed`). Mantém compatibilidade (default = sem aceleração).

## Reaproveitamento

- `rising_lava.gd` (modo chase, + aceleração), `vertical_platform.gd` (`up_only`), `cracked_wall.gd` (+ flags), `CorridorSection`, `EnemyFlyer`, sub-tank collectible, grupo `no_wall_grab`, `_z3_static_floor`/`_z2_static` helpers, `_draw_boss_room` (porta lateral no molde do stage 00), `spikes.png`.

## Câmera

O shaft é alto e estreito → a câmera precisa acompanhar a subida sem cortar as paredes. Usar o seguimento padrão do player (já existe). Verificar zoom na vertical durante o plano.

## Testes

- **Geometria headless** (padrão dos fixes recentes): script que instancia `stage_01`, dump dos rects do shaft/segmentos/paredes/elevador/lava/câmaras, e asserts: (a) largura de cada segmento dentro do alcance do wall-jump; (b) lava `cap_y` abaixo da câmara pré-chefe; (c) elevador `up_only` sobe e ancora no buraco; (d) parede #2 não quebrável pelo lado pré-chefe; (e) câmara pré-chefe seca.
- **Bot path** (`?stage=1&bot=1`): revalidar que o bot completa a fase (lavas congelam no modo bot — o shaft precisa ser percorrível com as plataformas/saliências paradas). Ajustar `_zone_spawn` (zonas 7/8 hoje apontam pro layout antigo) pros novos pontos.
- **SVG de debug:** regenerar `tools/zone_debug_01.tscn` pra inspecionar o novo layout da Z4.
- **Regra:** após qualquer mudança de código, web export + reiniciar localhost (preferência do projeto).

## Riscos / pontos de atenção

- **Reconstruir a arena do boss do zero** (molde stage 00, tileset do stage 01) toca `_relocate_and_gap_boss`, `_draw_boss_room`, `_setup_boss_room_trigger`, `BossRoomTrigger`, re-spawn do Ignarath e câmera. É a parte de maior risco — mas reusa o padrão já validado do stage 00.
- **Largura do wall-jump** é estimada (alcance ~256). Calibrar no playtest; o bot valida só o caminho (lavas paradas), não a dificuldade.
- **Sem checkpoint no meio do shaft** — decisão fechada (não reavaliar). Morrer no shaft volta pro `step0`; o checkpoint fica no corredor (topo).
- Escopo grande → o plano de implementação deve **fasear** (1: shaft + lava única; 2: arena do boss reconstruída + corredor; 3: rota secreta; 4: mecânicas novas e polimento).
