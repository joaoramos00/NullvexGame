# Stage 07 — Luxar (Luz) — Redesign

## Contexto

Stage 07 hoje só tem o esqueleto básico dos Plans 11+13: tileset de 4 zonas
(`stages/stage_07/Stage_07T_z1-z4.png` + `stage_07_glass.png`), `stage_07.tscn`
simples sem zonas. Já existem, prontos pra reaproveitar:

- Roster completo de 9 inimigos com sprites gerados (sem script de IA ainda):
  `enemy_lion_cub_runner`, `enemy_solar_guard`, `enemy_mirror_ram`,
  `enemy_glasswing_drone`, `enemy_prism_orbiter`, `enemy_mirror_moth`,
  `enemy_sun_grabber`, `enemy_radiant_pylon`, `enemy_beam_turret` + projéteis
  `light_bolt`/`prism_shard`/`flash_pulse`/`solar_slash` (ver
  `docs/superpowers/plans/2026-06-19-stage07-luxar-enemy-sprites.md`).
- Boss `characters/bosses/luxar.tscn`/`luxar.gd` já implementado (fraqueza:
  habilidade do Umbraex).
- `_DROP_TABLE` em `characters/enemies/enemy_base.gd` já classifica os 9
  inimigos por arquétipo de loot (grunt×2/heavy/turret×2/flyer×2/orbiter/
  elite).

Este spec cobre o rework completo do LAYOUT + IA dos inimigos + três
mecânicas novas de luz/reflexo, no mesmo nível de profundidade dos reworks
já completos de stage_01 a stage_06.

## Objetivo

Transformar Stage 07 numa fase completa: 4 zonas temáticas de luz/templo de
cristal, roster de 9 inimigos com IA funcional, sala do boss Luxar, e 3
mecânicas novas (feixes de luz contínuos, interruptores de toggle permanente,
zona de visão limitada) com dificuldade crescente.

## Estrutura por zona

- **Z1 — Introdução aos feixes.** Combate terrestre (`enemy_lion_cub_runner`,
  `enemy_solar_guard`, `enemy_mirror_ram`) + feixes de luz retos e fixos
  (dano por contato, exigem timing/posicionamento pra desviar). Checkpoint 1
  no fim.
- **Z2 — Feixes espelhados + interruptores.** Feixes com 1-2 dobras (pontos
  de espelho fixos definidos em tempo de design, não rotacionáveis pelo
  jogador) bloqueando o caminho; interruptores (ou destruir
  `enemy_radiant_pylon`) desligam um feixe específico permanentemente,
  abrindo a rota. Ameaça aérea: `enemy_glasswing_drone`, `enemy_prism_orbiter`.
  Armadura de Zael (Pernas) num desvio guardado por um feixe.
- **Z3 — Zona de luz ofuscante + portões.** Trecho com visão reduzida
  (escurecimento ao redor do jogador, só uma área próxima iluminada);
  interruptores ativam plataformas/portões permanentemente sólidos (mesma
  técnica de toggle de colisão já usada em `crumbling_ledge.gd`, sem timer).
  Perigo suspenso: `enemy_mirror_moth`, `enemy_sun_grabber`. Extra de Zara
  (Machado de Guerra) + coração num desvio. Checkpoint 2 no fim.
- **Z4 — Corredor final.** `enemy_beam_turret` fixas cobrindo o caminho +
  portão de luz final levando à sala do boss Luxar.

## Mecânicas novas (técnico)

- **Feixe de luz (Z1/Z2/Z4) — componente NOVO:** `light_beam.gd` (`Area2D`
  ou nó com múltiplas `CollisionShape2D`), definido por uma lista de pontos
  (`Array[Vector2]`) formando um polilinha — um feixe reto tem 2 pontos
  (emissor→receptor), um feixe "espelhado" tem 3+ pontos (emissor→ponto de
  espelho→receptor). Mesmo código cobre os dois casos. Dano por contato
  contínuo enquanto ativo (`@export var active: bool`); pode ser desligado
  permanentemente via `set_active(false)` chamado por um `light_switch`.
- **Interruptor (Z2/Z3) — componente NOVO:** `light_switch.gd` (`Area2D` ou
  vínculo ao sinal `died` de um inimigo específico como `enemy_radiant_pylon`)
  — ao ser ativado, chama `set_active(false)` num `light_beam` vinculado OU
  `set_deferred("disabled", false)` numa `CollisionShape2D` de plataforma/
  portão vinculado, permanentemente (sem timer, ao contrário de
  `phase_platform.gd` da Stage 06). Reaproveita a técnica de toggle já
  validada em `crumbling_ledge.gd`.
- **Zona de visão limitada (Z3) — componente NOVO:** `vision_limit_zone.gd`
  — `Area2D` que, ao ser tocada pelo jogador, ativa um escurecimento da tela
  (`CanvasModulate` escurecido + `PointLight2D` seguindo o jogador revelando
  uma área ao redor) enquanto o jogador estiver dentro; desativa ao sair.
  Sistema visual novo, sem precedente direto no código — usar a abordagem
  mais simples que funcione (CanvasModulate global escurecido + luz pontual
  no player) em vez de um sistema de iluminação completo por tile.
- **Todos os três** ficam num estado neutro/sem-efeito quando
  `DebugBoot.bot_enabled`: `light_beam` fica sempre com dano desabilitado
  (não interfere na validação do bot); `light_switch` não é necessário
  (o bot não precisa interagir, já que os feixes não fazem dano nesse modo);
  `vision_limit_zone` não escurece a tela (mesmo padrão de "efeito visual
  puro, sem gameplay" — o bot não depende de visão).

## Roster — mapeamento pra scripts

Cada inimigo ganha um script em `characters/enemies/stage_07/`, seguindo o
padrão de base já usado (`EnemyBase` pra grunts/estáticos/melee,
`res://characters/enemies/enemy_flyer.gd` pra voadores/suspensos):

| Sprite | Papel | Base | Molde mais próximo (stage 01-06) |
|---|---|---|---|
| `enemy_lion_cub_runner` | corredor terrestre rápido | EnemyBase | `enemy_gale_runner` (Stage 05, patrol+dash) |
| `enemy_solar_guard` | melee terrestre (bash/jab curto) | EnemyBase | `enemy_shadow_stalker` (Stage 06, lunge curto) |
| `enemy_mirror_ram` | terrestre pesado, investida lenta | EnemyBase | `enemy_eclipse_duelist` (Stage 06, charge, HP alto) |
| `enemy_glasswing_drone` | mergulhador aéreo | enemy_flyer.gd | `enemy_umbra_bat` (Stage 06) |
| `enemy_prism_orbiter` | hover-atirador aéreo | enemy_flyer.gd | `enemy_void_orbiter` (Stage 06) |
| `enemy_mirror_moth` | hover-atirador aéreo (flash) | enemy_flyer.gd | `enemy_feather_swarm` (Stage 05) |
| `enemy_sun_grabber` | suspenso, perseguidor lento | enemy_flyer.gd | `enemy_shadow_snare` (Stage 06) |
| `enemy_radiant_pylon` | estático, hazard/gatilho de interruptor | EnemyBase | `enemy_dark_lantern` (Stage 06, aura) |
| `enemy_beam_turret` | canhão fixo (`light_bolt`) | EnemyBase | `enemy_eclipse_turret` (Stage 06) |

Projéteis já com arte pronta: `light_bolt` (turret/orbiter), `prism_shard`
(ranged físico opcional), `flash_pulse` (moth/sun_grabber FX), `solar_slash`
(melee FX). Um `light_projectile.gd` compartilhado (clone de
`shadow_projectile.gd`) cobre `light_bolt`/`prism_shard`.

## Sala do boss

Padrão porta-aberta+trigger (padrão B, skill `new-boss-room`), mesmo usado
em stage_01/05/06: arena horizontal aberta, aggro por `Area2D` de entrada.
**Atenção**: aplicar desde o início o fix de `arena_left`/`arena_right`/
`arena_floor` descoberto na revisão final da Stage 06 (o boss precisa desses
3 valores setados em `_build_boss_arena()`, senão usa os defaults de
`boss_base.gd` e pode sair da sala/se comportar errado) — ver memória
`project_stage06_rework`.

## Colectáveis e checkpoints

Tabela do CLAUDE.md pra Stage 07: Armadura Zael = Pernas; Armadura Zara = —;
Extra Zael = —; Extra Zara = Machado de Guerra; Coração = ✓; Sub-Tank = —
(fases ímpares não têm sub-tank). Checkpoints: fim de Z1 e fim de Z3 (2 no
total, padrão de todas as fases). **Usar `Collectible.Type.XXX` (enum) desde
o início, nunca String** — ver memória `reference_collectible_type_enum`.

## Casos extremos / validação

- **Kill plane:** herdado por-fase, sem código novo necessário — confirmar
  que cobre os trechos onde os feixes/zona de visão limitada possam empurrar
  o jogador pra perto de bordas.
- **StageBot:** os 3 componentes novos ficam neutros/sem-efeito sob
  `bot_enabled` (ver seção de mecânicas acima) — sem caso especial adicional
  esperado além disso.
- **Ceiling:** teto por zona segue o padrão já estabelecido desde o início
  (constantes `_CEIL_FACE_GAP`-equivalente + fallback cross-zone), incluindo
  o offset de desenho visual **correto desde a primeira versão** (`Rect2(x,
  y, ts, ts)`, sem subtrair `sts`) — ver memória `reference_ceiling_collision_gap`.
- **Boss arena bounds:** ver seção "Sala do boss" acima — aplicar
  `arena_left`/`arena_right`/`arena_floor` desde o início, não como fix
  posterior.
- **imgdebug:** qualquer composição de tile nova que não bata com um modo
  existente segue a skill `new-imgdebug-tile-mode`.

## Fora de escopo

- Stage 08 — recebe seu próprio spec/plano depois.
- Sistema de iluminação por tile completo (luzes dinâmicas em toda a fase,
  sombras projetadas) — a `vision_limit_zone` é deliberadamente simples
  (CanvasModulate + luz pontual no player), não um motor de iluminação.
