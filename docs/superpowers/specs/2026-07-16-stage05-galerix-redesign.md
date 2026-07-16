# Stage 05 — Galerix (Vento) — Redesign

## Contexto

Stage 05 hoje só tem o esqueleto básico dos Plans 11+13 (`stages/stage_05/stage_05.tscn`,
196 linhas): plataformas retangulares simples, 2 checkpoints, colectáveis soltos,
sem zonas, sem paredes/teto compostos, sem inimigos temáticos posicionados. Já
existem, prontos pra reaproveitar:

- Tileset de 4 zonas: `stages/stage_05/Stage_05T_z1.png` … `z4.png` +
  `stage_05_glass.png`.
- Roster completo de 9 inimigos com sprites gerados (sem script de IA ainda):
  `characters/enemies/stage_05/enemy_gale_runner.png`, `enemy_claw_glider.png`,
  `enemy_airfoil_lancer.png`, `enemy_sky_harrier.png`, `enemy_turbine_wisp.png`,
  `enemy_feather_swarm.png`, `enemy_gale_grappler.png`, `enemy_gale_turret.png`,
  `enemy_updraft_fan.png` + projéteis `gale_bolt.png`, `wind_slash.png`,
  `feather_dart.png`, `updraft_pulse.png` (ver
  `docs/superpowers/plans/2026-06-18-stage05-galerix-enemy-sprites.md`).
- Boss `characters/bosses/galerix.tscn`/`galerix.gd` já implementado (fraqueza:
  habilidade do Gravitus).

Este spec cobre o rework completo do LAYOUT + IA dos inimigos + mecânicas de
vento, no mesmo nível de profundidade dos reworks já feitos em stage_01
(shaft Z4 + roster de fogo), stage_02 (Cryovex), stage_03 (Voltrix) e stage_04
(Gravitus).

## Objetivo

Transformar Stage 05 numa fase completa com identidade própria: 4 zonas
temáticas de vento, roster de 9 inimigos com IA funcional posicionados no
mapa, sala do boss Galerix, e 3 mecânicas de vento (corrente horizontal,
updraft vertical, plataforma deslizante) distribuídas pelas zonas.

## Estrutura por zona

- **Z1 — Entrada / corrente de vento horizontal.** Piso aberto com trechos de
  corrente de ar constante empurrando o jogador (a favor ou contra o avanço,
  variando por trecho) — obriga a cronometrar pulos contra o empurrão.
  Inimigos terrestres: `enemy_gale_runner` (corredor), `enemy_claw_glider`
  (melee agachado), `enemy_airfoil_lancer` (lancer). Checkpoint 1 no fim.
- **Z2 — Coluna de updraft vertical.** Shaft vertical com câmaras de vento
  ascendente que erguem o jogador — alcança alturas impossíveis só com pulo,
  papel equivalente ao shaft de wall-jump do stage_01, mas por corrente de ar.
  Inimigos aéreos: `enemy_sky_harrier` (mergulho), `enemy_turbine_wisp`
  (atirador). `enemy_updraft_fan` decora/ameaça as bordas da coluna.
  Armadura de Zael (Braços) num desvio lateral do shaft.
- **Z3 — Plataformas deslizantes sobre abismo.** Plataformas soltas que
  deslizam horizontalmente quando pisadas, sobre um abismo — exige timing de
  pulo em vez de posição estática. Perigo: `enemy_feather_swarm` (enxame
  orbital) e `enemy_gale_grappler` (agarra e empurra pro abismo). Extra de
  Zara (Garras) e o coração num desvio. Checkpoint 2 no fim.
- **Z4 — Corredor final + sala do boss.** Corredor com `enemy_gale_turret`
  fixas cobrindo o caminho, termina na sala do Galerix.

## Mecânicas de vento (técnico)

- **Corrente horizontal (Z1):** reaproveitar `stages/stage_02/blizzard_zone.gd`
  como está (`Area2D`, `@export var force: Vector2`, aplica
  `body.apply_stage_wind(force * delta)` em quem estiver dentro via
  `CharacterBase.apply_stage_wind`, já existente). Instanciar com `force`
  apontando na direção de cada trecho.
- **Updraft vertical (Z2):** reaproveitar `stages/stage_04/lift_zone.gd` como
  está (câmara de empuxo pra cima, mesmo mecanismo `apply_stage_wind`, com
  traços visuais ascendentes já desenhados em `_draw()`).
- **Plataforma deslizante (Z3) — componente NOVO:** `sliding_platform.gd`
  (`AnimatableBody2D`, técnica de acumulador de posição — ver memória
  `reference_moving_platform_carry`). Detecta o player em cima (via `Area2D`
  filha ou `get_colliding_bodies` do corpo), acelera numa direção fixa até
  sair da plataforma / bater num limite, carregando o player junto (nunca ler
  `position` de volta pra decidir deslocamento — usar acumulador). Reseta pra
  posição inicial após um tempo sem ninguém em cima. Fica PARADA quando
  `DebugBoot.bot_enabled` (mesmo padrão de `lift_zone.gd`/`crumbling_ledge.gd`)
  pra não quebrar a validação automática do StageBot.

## Roster — mapeamento pra scripts

Cada inimigo ganha um script em `characters/enemies/stage_05/`, seguindo o
padrão de base já usado (`EnemyBase` pra grunts/estáticos, `EnemyFlyer` pra
voadores) — mesmo processo das skills `new-enemy`/`new-boss`:

| Sprite | Papel | Base |
|---|---|---|
| `enemy_gale_runner` | corredor terrestre | EnemyBase (grunt) |
| `enemy_claw_glider` | melee agachado terrestre | EnemyBase |
| `enemy_airfoil_lancer` | lancer terrestre | EnemyBase |
| `enemy_sky_harrier` | mergulho aéreo | EnemyFlyer |
| `enemy_turbine_wisp` | atirador aéreo (`gale_bolt`) | EnemyFlyer |
| `enemy_feather_swarm` | enxame orbital (hazard) | EnemyFlyer |
| `enemy_gale_grappler` | captura/empurra pro abismo | EnemyFlyer |
| `enemy_gale_turret` | canhão fixo (`gale_bolt`) | estático (EnemyBase parado) |
| `enemy_updraft_fan` | fonte visual/hazard do updraft | estático |

Projéteis já com arte pronta: `gale_bolt` (turret/wisp), `wind_slash`
(claw_glider/airfoil_lancer melee FX), `feather_dart` (feather_swarm),
`updraft_pulse` (updraft_fan/gale_grappler FX).

## Sala do boss

Segue o padrão porta-aberta+trigger do stage_01 (skill `new-boss-room`):
arena horizontal aberta (espaço pro voo/dash do Galerix), aggro por `Area2D`
de entrada na arena — não por distância (mesmo motivo do stage_01: evita
acordar o boss cedo se o jogador cair/entrar antes da hora).

## Colectáveis e checkpoints

Tabela do CLAUDE.md pra Stage 05: Armadura Zael = Braços; Armadura Zara = —;
Extra Zael = —; Extra Zara = Garras; Coração = ✓; Sub-Tank = — (fases ímpares
não têm sub-tank). Checkpoints: fim de Z1 e fim de Z3 (2 no total, padrão de
todas as fases).

## Casos extremos / validação

- **Kill plane:** confirmar que `kill_y` da fase (calculado por-fase em
  `stage_scene.gd`, `reference_kill_plane`) cobre os trechos de Z1/Z3 onde o
  vento pode empurrar o jogador pro vazio.
- **StageBot:** `apply_stage_wind` já é compatível com o bot (usado em
  stage_02/04 com bot ativo); `sliding_platform.gd` novo precisa da mesma
  checagem `DebugBoot.bot_enabled` que `lift_zone`/`crumbling_ledge` já usam.
- **imgdebug:** se algum layout de piso/parede/teto novo (ex: bordas do shaft
  de updraft) não bater com um modo existente, seguir a skill
  `new-imgdebug-tile-mode` (e `imgdebug-render-parity` pro preenchimento de
  borda) antes de hardcodar tile-a-tile no stage.

## Fora de escopo

- Stages 06/07/08 — cada um recebe seu próprio spec/plano depois que Stage 05
  estiver completo e validado.
- Novos assets de PixelLab além do já gerado, a menos que o design de alguma
  zona específica exija (autonomia concedida pelo usuário para usar PixelLab
  se necessário durante a implementação).
