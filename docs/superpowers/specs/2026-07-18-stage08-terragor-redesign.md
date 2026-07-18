# Stage 08 — Terragor (Terra) — Redesign

## Contexto

Stage 08 hoje só tem o esqueleto básico dos Plans 11+13: tileset de 4 zonas
(`stages/stage_08/Stage_08T_z1-z4.png` + `stage_08_glass.png`), `stage_08.tscn`
simples sem zonas (piso reto + poucas plataformas + 4 grunts genéricos + 1
flyer genérico). Já existem, prontos pra reaproveitar:

- Roster completo de 9 inimigos com sprites gerados (sem script de IA ainda):
  `enemy_terra_grunt`, `enemy_mossback_brute`, `enemy_drill_mole`,
  `enemy_gem_wasp`, `enemy_stone_glider`, `enemy_ore_orbiter`,
  `enemy_root_snare`, `enemy_boulder_turret`, `enemy_fossil_totem` + FX
  `stone_shot`/`ore_shard`/`root_bind`/`quake_wave` (ver
  `docs/superpowers/plans/2026-06-19-stage08-terragor-enemy-sprites.md`).
- Boss `characters/bosses/terragor.tscn`/`terragor.gd` já implementado
  (fraqueza: habilidade do Cryovex; ganha habilidade pro Voltrix). Fase 2
  hoje só reduz `attack_interval_p2` — sem ataque novo.
- `_DROP_TABLE` em `characters/enemies/enemy_base.gd` já classifica os 9
  inimigos por arquétipo de loot (grunt×2/heavy/orbiter/flyer×2/turret/
  trap×2). Nenhum tem tier elite/miniboss ainda.
- Componentes genéricos já prontos pra reaproveitar direto (sem clonar):
  `res://stages/stage_01/crumbling_ledge.gd` (saliência que desmorona e
  respawna, já reusado cross-stage por stage_02) e
  `res://stages/stage_04/crusher.gd` (bloco que cicla espera→queda→pausa→
  subida, dano na queda).

Este spec cobre o rework completo do LAYOUT + IA dos inimigos + mecânica
nova de parede quebrável (sem gate de habilidade, já que Stage 08 é
acessível em qualquer ordem pelo stage select) + uma mecânica real de fase 2
pro boss, no mesmo nível de profundidade dos reworks já completos de
stage_01 a stage_07.

## Objetivo

Transformar Stage 08 numa fase completa: 4 zonas temáticas de mina/terra
instável, roster de 9 inimigos com IA funcional, sala do boss Terragor, e a
combinação de 3 mecânicas de desmoronamento (piso instável, queda de rocha,
parede de entulho quebrável) com dificuldade crescente, terminando num boss
com fase 2 real.

## Estrutura por zona

- **Z1 — Piso instável.** Combate terrestre (`enemy_terra_grunt`,
  `enemy_mossback_brute`, `enemy_drill_mole`) + saliências que desmoronam sob
  o pé (`crumbling_ledge.gd`, reuso direto via preload cross-stage, mesmo
  padrão já usado por stage_02). Checkpoint 1 no fim.
- **Z2 — Desabamentos.** Blocos de rocha em ciclo espera→queda→pausa→subida
  bloqueando/ameaçando o caminho (`crusher.gd`, reuso direto via preload
  cross-stage, reflavorizado visualmente como bloco de rocha — mesmo
  componente de stage_04, sem mudança de código). Ameaça aérea:
  `enemy_gem_wasp`, `enemy_stone_glider`. Armadura de Zara (Pernas) num
  desvio guardado por um crusher.
- **Z3 — Túnel de mineração.** Parede de entulho quebrável por ataque comum
  do jogador (componente NOVO, **sem gate de habilidade** — diferente da
  parede secreta de stage_01 que exige Galerix, porque aqui a parede bloqueia
  o caminho PRINCIPAL e Stage 08 pode ser a primeira fase jogada). Perigo
  suspenso/trap: `enemy_root_snare` (armadilha estacionária que prende o
  jogador brevemente ao se aproximar), `enemy_fossil_totem` (estático,
  dispara em intervalos), `enemy_ore_orbiter`. Extra de Zael (Cannon) +
  coração + sub-tank num desvio atrás da parede quebrável. Checkpoint 2 no
  fim.
- **Z4 — Corredor final.** `enemy_boulder_turret` fixo cobrindo o caminho +
  portão levando à sala do boss Terragor.

## Mecânica nova (técnico)

- **Parede de entulho quebrável (Z3) — componente NOVO:**
  `rubble_wall.gd` (`StaticBody2D`, clone estrutural de
  `stages/stage_01/cracked_wall.gd` mas **sem `can_break_from`/checagem de
  habilidade** — quebra em N hits de qualquer ataque do jogador, via um
  `HitDetector` (`Area2D`, `collision_mask` = camada dos hitboxes de ataque
  do jogador) contando golpes e emitindo `wall_destroyed` + `queue_free()` ao
  chegar no limite. Tint visual translúcido sobre o tile da zona, igual ao
  padrão de `cracked_wall.gd`, pra sinalizar visualmente que é quebrável.
  Neutro sob `DebugBoot.bot_enabled`: `queue_free()` direto no `_ready()`
  quando o bot está ativo (mesmo padrão do `ice_gate.gd` da stage_02 — bot
  não tem a mecânica de combate necessária pra quebrar de forma confiável,
  então a parede simplesmente não existe nesse modo, garantindo que a
  travessia automática valide o resto da fase).

## Mecânica de fase 2 do boss (técnico)

- **Terragor ganha um ataque de tremor em fase 2** — `_enter_phase_2()`
  passa a dar spawn periódico de uma onda de choque (`quake_wave.gd`,
  componente NOVO, `Area2D` que nasce na posição do boss e se desloca ao
  longo do piso pros dois lados a uma velocidade fixa, dano por contato,
  `queue_free()` ao sair do alcance máximo ou ao sair da arena) intercalada
  com os projéteis de rocha já existentes — em vez de só encurtar o
  intervalo de ataque (comportamento atual, que a spec de stage_06/stage_07
  já identificou como "sem mudança de padrão real"). Usa a arte `quake_wave`
  já gerada pro roster de inimigos desta fase.

## Roster — mapeamento pra scripts

Cada inimigo ganha um script em `characters/enemies/stage_08/`, seguindo o
padrão de base já usado (`EnemyBase` pra grunts/estáticos/melee/traps,
`res://characters/enemies/enemy_flyer.gd` pra voadores/suspensos):

| Sprite | Papel | Base | Molde mais próximo (stage 01-07) |
|---|---|---|---|
| `enemy_terra_grunt` | corredor terrestre básico | EnemyBase | `enemy_lion_cub_runner` (Stage 07, patrol) |
| `enemy_mossback_brute` | terrestre pesado, investida lenta | EnemyBase | `enemy_mirror_ram` (Stage 07, charge, HP alto) |
| `enemy_drill_mole` | melee terrestre (bash/jab curto) | EnemyBase | `enemy_solar_guard` (Stage 07, lunge curto) |
| `enemy_gem_wasp` | mergulhador aéreo | enemy_flyer.gd | `enemy_glasswing_drone` (Stage 07) |
| `enemy_stone_glider` | hover-atirador aéreo | enemy_flyer.gd | `enemy_prism_orbiter` (Stage 07, atira `stone_shot`) |
| `enemy_ore_orbiter` | suspenso, perseguidor lento | enemy_flyer.gd | `enemy_sun_grabber` (Stage 07) |
| `enemy_root_snare` | estático, trap que prende o jogador ao se aproximar | EnemyBase | `enemy_dark_lantern` (Stage 06, aura) |
| `enemy_boulder_turret` | canhão fixo (`stone_shot`) | EnemyBase | `enemy_beam_turret` (Stage 07) |
| `enemy_fossil_totem` | estático, dispara em intervalos | EnemyBase | `enemy_eclipse_turret` (Stage 06) |

Projétil compartilhado `stone_bolt.gd` (clone de `light_projectile.gd`) cobre
`stone_shot`/`ore_shard`. `root_bind` é FX puramente visual do ataque de
`root_snare` (sem projétil próprio — dano por Area2D de curto alcance).

## Sala do boss

Padrão porta-aberta+trigger (padrão B, skill `new-boss-room`), mesmo usado
em stage_01/05/06/07: arena horizontal aberta, aggro por `Area2D` de
entrada. **Atenção**: aplicar desde o início `arena_left`/`arena_right`/
`arena_floor` no `_build_boss_arena()` (bug encontrado na revisão final da
Stage 06, repetido desde então em toda stage nova — ver memória
`project_stage06_rework`). Terragor é um walker terrestre (não voa), então
`arena_floor` também é relevante aqui (diferente de Luxar, que voa) — a
`.tscn` já tem `arena_floor=900.0` mas isso precisa ser recalculado contra
as coordenadas REAIS da sala reconstruída, não copiado do valor antigo.

## Colectáveis e checkpoints

Tabela do CLAUDE.md pra Stage 08: Armadura Zael = —; Armadura Zara = Pernas;
Extra Zael = Cannon; Extra Zara = —; Coração = ✓; Sub-Tank = ✓ (fases pares
têm sub-tank). Checkpoints: fim de Z1 e fim de Z3 (2 no total, padrão de
todas as fases). **Usar `Collectible.Type.XXX` (enum) desde o início, nunca
String** — ver memória `reference_collectible_type_enum`.

## Casos extremos / validação

- **Kill plane:** herdado por-fase, sem código novo necessário.
- **StageBot:** `crumbling_ledge.gd` e `crusher.gd` já são neutros/previsíveis
  sob `bot_enabled` (comportamento herdado, confirmado nos códigos-fonte
  citados acima). `rubble_wall.gd` (novo) precisa da mesma neutralidade —
  `queue_free()` no `_ready()` quando `bot_enabled` (padrão `ice_gate.gd`).
  `quake_wave.gd` (novo, spawnado só pelo boss em fase 2) não precisa de
  caso especial de bot — mesmo padrão dos projéteis de boss existentes, que
  já não interferem na validação de travessia do bot (a luta de boss não é
  parte do percurso validado pelo StageBot).
- **Ceiling:** teto por zona segue o padrão já estabelecido desde o início
  (constantes `_CEIL_FACE_GAP`-equivalente + fallback cross-zone), incluindo
  o offset de desenho visual **correto desde a primeira versão** (`Rect2(x,
  y, ts, ts)`, sem subtrair `sts`) — ver memória
  `reference_ceiling_collision_gap`.
- **Boss arena bounds:** ver seção "Sala do boss" acima.
- **imgdebug:** qualquer composição de tile nova que não bata com um modo
  existente segue a skill `new-imgdebug-tile-mode`.

## Fora de escopo

- Stage 09-11 (fases finais) — já implementadas (Plan 12), não fazem parte
  deste rework.
- Sistema de destruição de terreno em massa (só a parede quebrável definida
  acima; sem mineração livre pelo jogador).
