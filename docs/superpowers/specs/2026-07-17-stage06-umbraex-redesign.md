# Stage 06 — Umbraex (Sombra) — Redesign

## Contexto

Stage 06 hoje só tem o esqueleto básico dos Plans 11+13: tileset de 4 zonas
(`stages/stage_06/Stage_06T_z1-z4.png` + `stage_06_glass.png`), `stage_06.tscn`
simples sem zonas. Já existem, prontos pra reaproveitar:

- Roster completo de 9 inimigos com sprites gerados (sem script de IA ainda):
  `enemy_shadow_stalker`, `enemy_eclipse_duelist`, `enemy_night_pouncer`,
  `enemy_umbra_bat`, `enemy_void_orbiter`, `enemy_shadow_snare`,
  `enemy_phase_mine`, `enemy_dark_lantern`, `enemy_eclipse_turret` +
  projéteis `shadow_bolt`/`void_shard`/`snare_pulse`/`phase_slash` (ver
  `docs/superpowers/plans/2026-06-19-stage06-umbraex-enemy-sprites.md`).
- Boss `characters/bosses/umbraex.tscn`/`umbraex.gd` já implementado
  (fraqueza: habilidade do Voltrix).
- `_DROP_TABLE` em `characters/enemies/enemy_base.gd` já classifica os 9
  inimigos por arquétipo de loot (grunt/elite/hopper/flyer/orbiter/trap×3/
  turret) — usado só pra pool de drop, não define a classe de movimento.

Este spec cobre o rework completo do LAYOUT + IA dos inimigos + duas
mecânicas novas de sombra/eclipse, no mesmo nível de profundidade dos
reworks já completos de stage_01 a stage_05.

## Objetivo

Transformar Stage 06 numa fase completa: 4 zonas temáticas de sombra/eclipse,
roster de 9 inimigos com IA funcional, sala do boss Umbraex, e 2 mecânicas
novas (plataformas fasing, portais de sombra) com dificuldade crescente.

## Estrutura por zona

- **Z1 — Introdução às plataformas fasing.** Combate terrestre
  (`enemy_shadow_stalker`, `enemy_night_pouncer`, `enemy_eclipse_duelist`) +
  primeiras plataformas que alternam sólido/vazio num ciclo simples e
  previsível (mesmo período pra todas, fácil de decorar). Checkpoint 1 no
  fim.
- **Z2 — Fasing avançado + emboscada.** Múltiplas plataformas fora de
  sincronia (períodos/fases diferentes — exige ler o padrão, não só decorar
  um timing único). Ameaça aérea: `enemy_umbra_bat`, `enemy_void_orbiter`.
  `enemy_dark_lantern` como hazard estático guardando a Armadura de Zara
  (Braços) num desvio.
- **Z3 — Portais de sombra.** Pares de portais cruzando abismos largos
  demais pra pular. `enemy_shadow_snare` (suspenso, agarra) e
  `enemy_phase_mine` (hazard quase invisível) posicionados perto dos
  portais, punindo quem hesita na travessia. Extra de Zael (Laser) +
  coração + sub-tank num desvio. Checkpoint 2 no fim.
- **Z4 — Corredor final.** `enemy_eclipse_turret` fixas cobrindo o caminho +
  sequência final de portal levando à sala do boss Umbraex.

## Mecânicas novas (técnico)

- **Plataforma fasing (Z1/Z2) — componente NOVO:** `phase_platform.gd`
  (`StaticBody2D`), alterna `CollisionShape2D.disabled` num ciclo
  temporizado (`@export var solid_time`/`@export var phase_time`, opcional
  `@export var phase_offset` pra dessincronizar múltiplas instâncias na Z2).
  Mesma técnica de toggle já validada em `crumbling_ledge.gd` (stage_01) e
  nas portas de sala de boss (`set_deferred("disabled", ...)`), só que
  disparada por tempo em vez de contato. Visual: opacidade/`modulate.a`
  reduzida durante a fase vazia, pra dar leitura clara do estado.
- **Portal de sombra (Z3/Z4) — componente NOVO:** `shadow_portal.gd` (par de
  `Area2D`, entrada + saída). Ao entrar na área de entrada, reposiciona o
  corpo pra saída (`global_position = exit.global_position`), preservando
  `velocity`. Cooldown breve (`@export var reentry_cooldown`, ex. 0.3s) após
  teleportar pra não re-disparar imediatamente ao sair da área de saída (se
  as duas áreas estiverem próximas).
- **`phase_platform` fica sempre SÓLIDA quando `DebugBoot.bot_enabled`**
  (mesmo padrão de `lift_zone.gd`/`sliding_platform.gd`) — o ciclo de
  fase só roda em jogo normal, o bot valida o layout como se fosse piso
  fixo.
- **`shadow_portal` continua funcionando normalmente mesmo com
  `bot_enabled`** — ao contrário de forças contínuas (vento/updraft), um
  teleporte é um reposicionamento discreto e determinístico que não conflita
  com o pathing do bot; não precisa de caso especial.

## Roster — mapeamento pra scripts

Cada inimigo ganha um script em `characters/enemies/stage_06/`, seguindo o
padrão de base já usado (`EnemyBase` pra grunts/estáticos/melee,
`res://characters/enemies/enemy_flyer.gd` pra voadores/suspensos) — mesmo
processo das Tasks 3-5 do rework da Stage 05:

| Sprite | Papel | Base | Molde mais próximo (stage 01-05) |
|---|---|---|---|
| `enemy_shadow_stalker` | corredor/melee terrestre agachado | EnemyBase | `enemy_claw_glider` (Stage 05) |
| `enemy_eclipse_duelist` | duelista melee terrestre (elite) | EnemyBase | `enemy_mass_brute`-style charge, HP maior |
| `enemy_night_pouncer` | pulador terrestre | EnemyBase | padrão `jumper` (skill `new-enemy`) |
| `enemy_umbra_bat` | mergulhador aéreo | enemy_flyer.gd | `enemy_sky_harrier` (Stage 05) |
| `enemy_void_orbiter` | hover-atirador aéreo (`shadow_bolt`) | enemy_flyer.gd | `enemy_turbine_wisp` (Stage 05) |
| `enemy_shadow_snare` | suspenso, agarra/atira `snare_pulse` | enemy_flyer.gd | `enemy_gale_grappler`/`enemy_feather_swarm` (Stage 05) |
| `enemy_phase_mine` | hazard quase-invisível, pulsa dano por contato | EnemyBase (estático) | `enemy_gravity_mine` (Stage 04) |
| `enemy_dark_lantern` | estático, emite pulso (`snare_pulse` ou hazard de área) | EnemyBase (estático) | `enemy_grav_well` (Stage 04, aura) |
| `enemy_eclipse_turret` | canhão fixo (`shadow_bolt`) | EnemyBase (estático) | `enemy_gale_turret` (Stage 05) |

Projéteis já com arte pronta: `shadow_bolt` (turret/orbiter), `void_shard`
(duelist/stalker ranged opcional), `snare_pulse` (snare/lantern FX),
`phase_slash` (melee FX). Um `shadow_projectile.gd` compartilhado (clone de
`wind_projectile.gd`) cobre `shadow_bolt`/`void_shard`.

## Sala do boss

Segue o padrão porta-aberta+trigger (padrão B, skill `new-boss-room`) — mesmo
usado em stage_01 e stage_05: arena horizontal aberta, aggro por `Area2D` de
entrada, não por distância. Última peça do corredor final termina num portal
de sombra que deposita o jogador na entrada da arena (reforça o tema).

## Colectáveis e checkpoints

Tabela do CLAUDE.md pra Stage 06: Armadura Zael = —; Armadura Zara = Braços;
Extra Zael = Laser; Extra Zara = —; Coração = ✓; Sub-Tank = ✓ (fases pares
têm sub-tank). Checkpoints: fim de Z1 e fim de Z3 (2 no total, padrão de
todas as fases).

## Casos extremos / validação

- **Kill plane:** cobrir os abismos cruzados por portal em Z3/Z4 — cair sem
  usar o portal deve levar à morte por queda, não deixar o jogador preso.
- **StageBot:** `phase_platform` sólida fixa sob `bot_enabled` (mesmo padrão
  de `sliding_platform`/`lift_zone`); `shadow_portal` continua ativo (ver
  seção de mecânicas acima) — nenhum caso especial adicional esperado.
- **Ceiling:** teto por zona segue o padrão já estabelecido em stage_01-05
  desde o início (constantes `_CEIL_FACE_GAP`-equivalente + fallback
  cross-zone), não como fix posterior.
- **imgdebug:** qualquer composição de tile nova que não bata com um modo
  existente segue a skill `new-imgdebug-tile-mode` (+ `imgdebug-render-parity`
  pro preenchimento de borda).

## Fora de escopo

- Stages 07/08 — cada um recebe seu próprio spec/plano depois.
- Zonas de escuridão/visibilidade limitada (luz apagada) — mecânica citada
  no tema mas não escolhida como gimmick central; pode ser revisitada em
  polimento futuro se o usuário pedir.
