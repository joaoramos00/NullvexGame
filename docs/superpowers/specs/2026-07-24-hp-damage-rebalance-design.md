# Rebalanceamento de HP e Dano — Design Spec

**Data:** 2026-07-24
**Status:** Aprovado para plano de implementação (com itens pendentes documentados)

## Contexto e Motivação

O jogo usa hoje uma escala de números grande e pouco consistente: player com HP base 50 (até ~210 com corações), inimigos comuns variando de 6 a 24 HP, bosses fixos em 200 HP, dano de tiro do Zael carregado chegando a 25. Os números foram herdados incrementalmente durante o desenvolvimento de cada fase, sem uma régua compartilhada.

Esta revisão substitui essa escala por uma régua pequena e deliberada — HP e dano de uma única dígito na maior parte dos casos — para que cada ataque e cada inimigo tenham peso legível e comparável entre si e entre fases.

## Regra Geral

**Todo inimigo tem no mínimo 1 de dano de contato**, mesmo inimigos estacionários/torretas cujo padrão anterior era `contact_damage = 0`. O perigo desses inimigos continua vindo majoritariamente do projétil, mas o contato nunca é gratuito.

## Player

| Item | Valor |
|---|---|
| HP inicial | 14 |
| HP máximo | 30 |
| Incremento por coração | +2 (8 corações nas fases 01-08, tabela de colectáveis existente) |
| Zael — nível de carga 1 (sem carga) | 1 |
| Zael — nível de carga 2 | 2 |
| Zael — nível de carga 3 (carga total) | 3 |
| Zael — nível de carga 4 (só com armadura de braço) | 5 |
| Zara — golpe 1 do combo | 1 |
| Zara — golpe 2 do combo | 1 |
| Zara — finisher | 3 |

Os valores de carga/combo se aplicam de forma compartilhada a todos os 5 tipos de tiro do Zael e todas as 5 armas da Zara (o código atual já usa um array de dano único indexado por nível de carga / força do golpe, reaproveitado por todos os tipos — a diferenciação entre tipos é visual/de padrão de disparo, não de dano base).

### Habilidades de Boss (Zael)

Sistema de munição por habilidade já existe (`GameManager.boss_ability_ammo`), mas hoje usa um teto único (`ABILITY_MAX_AMMO = 30`) para todas. Nesta revisão cada habilidade ganha seu próprio teto de munição.

| Boss | Habilidade | Status | Dano | Munição máxima |
|---|---|---|---|---|
| Ignarath | `fire_wave` | implementada | 3 | 8 |
| Cryovex | `ice_arrow` | implementada | 2 | 15 |
| Voltrix | *(não implementada — feature incompleta)* | — | 6 | 8 |
| Gravitus | *(não implementada — feature incompleta)* | — | 3 | 12 |
| Galerix | `wind_gust` | implementada | 1 | 20 |
| Umbraex | `shadow_kunai` | implementada | 3 | 10 |
| Luxar | *(não implementada — feature incompleta)* | — | 1 | 20 |
| Terragor | `stone_shard` | implementada | 4 | 8 |

As habilidades de Voltrix, Gravitus e Luxar não têm script/mecânica implementada no Zael hoje (feature incompleta, não é um número de balanceamento). Os valores acima já ficam definidos para quando a feature for construída. Zara não usa o sistema de habilidades de boss atualmente — fora de escopo desta revisão.

## Mudanças de Escopo (além de números)

- **Remover `enemy_ember_orbiter` da fase 01** — instâncias devem ser retiradas de `stage_01.tscn` durante a implementação.
- **Padronizar `max_hp` de cada boss num único valor** — hoje vários bosses têm valores divergentes entre o `@export` default no script (ex. `ignarath.gd` define `180` em `_ready()`) e o valor salvo na `.tscn` (ex. `ignarath.tscn` tem `200`), porque a atribuição em `_ready()` roda depois da carga da cena e sobrescreve o valor exportado. A implementação deve eliminar essa ambiguidade (recomendado: remover a atribuição redundante em `_ready()` e manter só o valor na `.tscn`, ou vice-versa).
- **IntroBoss** tem a mesma ambiguidade (`120` no script vs `28` na cena, com o teste `test_intro_boss.gd` esperando `28`) — resolver e atualizar o teste durante a implementação.

## Inimigos Comuns e Bosses por Fase

### Fase 00 — Intro

| Inimigo | HP | Dano |
|---|---|---|
| Grunt/Flyer genérico (`enemy_base`/`enemy_flyer`, sem variante temática) | 2 | 1 |
| MB00 (miniboss, `enemy_miniboss.gd`) | 15 | 2 |
| **IntroBoss** | **20** | contato 1 / `shoot` 2 / `burst` 3 |

### Fase 01 — Ignarath (Fogo)

| Inimigo | HP | Dano |
|---|---|---|
| `enemy_magma_grunt` | 3 | 1 |
| `enemy_molten_ram` | 15 | 3 |
| `enemy_ash_hopper` | 2 | 1 |
| `enemy_ember_orbiter` | *(removido da fase)* | — |
| `enemy_flame_skimmer` | 2 | 1 |
| `enemy_cinder_flyer` | 2 | 1 |
| `enemy_heat_mortar` | 4 | 1 |
| `enemy_magma_turret` | 4 | 1 |
| `enemy_lava_serpent` | 2 | 2 |
| **Ignarath** | **40** | contato 1 / `firebreath` (à distância) 4 / `claw` (corpo-a-corpo) 5 / `claw_wave` (onda rasteira) 2 |

### Fase 02 — Cryovex (Gelo)

| Inimigo | HP | Dano |
|---|---|---|
| `enemy_ice_grunt` | 3 | 1 |
| `enemy_ice_flyer` | 2 | 1 |
| `enemy_cryo_bomber` | 3 | 3 |
| `enemy_frost_turret` | 4 | 1 |
| `enemy_glacier_shield` | 2 | 2 |
| `enemy_ice_archer` | 2 | 1 |
| `enemy_ice_wisp` | 1 | 1 |
| `enemy_ice_miniboss` (MB02) | 15 | 3 |
| **Cryovex** | **40** | contato 2 / `bite` (corpo-a-corpo) 3 / `ice_orb` (à distância) 4 / `ice_tooth` (groundburst) 3 |

### Fase 03 — Voltrix (Raio)

| Inimigo | HP | Dano |
|---|---|---|
| `enemy_volt_guard` | 3 | 1 |
| `enemy_rail_runner` | 3 | 2 |
| `enemy_thunder_hawklet` | 1 | 1 |
| `enemy_storm_kite` | 1 | 1 |
| `enemy_arc_orbiter` | 2 | 1 |
| `enemy_static_interceptor` | 2 | 1 |
| `enemy_tesla_coil` | 4 | 3 |
| `enemy_arc_turret` | 5 | 1 |
| `enemy_storm_relay` | 3 | 2 |
| **Voltrix** | **40** | **PENDENTE** — contato/projétil de raio (hoje 15/18) |

### Fase 04 — Gravitus (Gravidade)

| Inimigo | HP | Dano |
|---|---|---|
| `enemy_grav_guard` | 3 | 1 |
| `enemy_mass_brute` | 6 | 3 |
| `enemy_orbit_mauler` | 3 | 2 |
| `enemy_void_drone` | 2 | 1 |
| `enemy_gravity_mine` | 1 | 5 |
| `enemy_debris_orbiter` | 2 | 1 |
| `enemy_singularity_turret` | 4 | 1 |
| `enemy_grav_well` | 4 | 1 |
| `enemy_crush_pylon` | 5 | 2 |
| **Gravitus** | **40** | contato 3 / `slam` 3 / `punch` 4 / `missile` 2 / `satellite_strike` 1 |

Nota: Gravitus está em rework ativo no branch atual (arquivos novos de laser/satélite/singularidade ainda não commitados — ver `git status`). Os valores acima já cobrem o `satellite_strike` novo.

### Fase 05 — Galerix (Vento)

| Inimigo | HP | Dano |
|---|---|---|
| `enemy_gale_runner` | 3 | 1 |
| `enemy_claw_glider` | 3 | 2 |
| `enemy_airfoil_lancer` | 3 | 1 |
| `enemy_sky_harrier` | 2 | 1 |
| `enemy_turbine_wisp` | 2 | 1 |
| `enemy_feather_swarm` | 2 | 1 |
| `enemy_gale_grappler` | 4 | 3 |
| `enemy_gale_turret` | 4 | 1 |
| `enemy_updraft_fan` | 4 | 1 |
| **Galerix** | **40** | **PENDENTE** — contato/projétil (hoje 15/10) |

### Fase 06 — Umbraex (Sombra)

| Inimigo | HP | Dano |
|---|---|---|
| `enemy_shadow_stalker` | 3 | 1 |
| `enemy_eclipse_duelist` | 3 | 4 |
| `enemy_night_pouncer` | 2 | 1 |
| `enemy_umbra_bat` | 2 | 1 |
| `enemy_void_orbiter` | 2 | 1 |
| `enemy_shadow_snare` | 3 | 2 |
| `enemy_phase_mine` | 1 | 3 |
| `enemy_dark_lantern` | 4 | 1 |
| `enemy_eclipse_turret` | 5 | 1 |
| **Umbraex** | **40** | contato 3 / `punch` 3 / `shuriken` 3 / `kunai` 4 |

### Fase 07 — Luxar (Luz)

| Inimigo | HP | Dano |
|---|---|---|
| `enemy_solar_guard` | 3 | 1 |
| `enemy_mirror_ram` | 6 | 3 |
| `enemy_lion_cub_runner` | 2 | 1 |
| `enemy_glasswing_drone` | 2 | 1 |
| `enemy_prism_orbiter` | 2 | 1 |
| `enemy_mirror_moth` | 1 | 1 |
| `enemy_sun_grabber` | 4 | 3 |
| `enemy_radiant_pylon` | 4 | 1 |
| `enemy_beam_turret` | 4 | 1 |
| **Luxar** | **40** | **PENDENTE** — contato/feixe (hoje 15/20) |

### Fase 08 — Terragor (Terra)

| Inimigo | HP | Dano |
|---|---|---|
| `enemy_terra_grunt` | 3 | 1 |
| `enemy_mossback_brute` | 6 | 3 |
| `enemy_drill_mole` | 3 | 1 |
| `enemy_gem_wasp` | 2 | 1 |
| `enemy_stone_glider` | 2 | 1 |
| `enemy_ore_orbiter` | 3 | 2 |
| `enemy_root_snare` | 4 | 2 |
| `enemy_boulder_turret` | 4 | contato 1 / projétil (`stone_shot`) 1 |
| `enemy_fossil_totem` | 5 | contato 1 / projétil (`ore_shard`) 2 |
| **Terragor** | **40** | contato 2 / `boulder` (arremesso) 4 / `breath` (rajada de fragmentos) 3 / `quake_wave` (tremor do smash) 3 / `stone_shatter` — pedra rolando 4, estilhaço 2 |

### Fase 09 — Gauntlet

Os 8 bosses elementais aparecem em sequência com os mesmos valores de HP e dano definidos acima — **sem redução** para compensar a maratona sem cura. A dificuldade do gauntlet vem de enfrentar os 8 seguidos, não de números individuais diferentes.

### Fases 10-11 — Nullvex

| Boss | HP | Dano |
|---|---|---|
| **Nullvex** (fase 10, Forma Humanoide) | **40** | **PENDENTE** — contato/tiro em leque (hoje 15/20) |
| **Nullvex True** (fase 11, Forma Verdadeira) | **70** | **PENDENTE** — contato/projétil fase1-2/projétil de queda fase3 (hoje 15/25/20) |

## Itens Pendentes (decisão adiada pelo usuário)

Estes 5 itens ficam **intencionalmente em aberto** — não são lacunas do processo, o usuário optou por defini-los depois, antes do plano de implementação:

1. Voltrix — dano de contato e do projétil de raio
2. Galerix — dano de contato e do projétil
3. Luxar — dano de contato e do feixe horizontal
4. Nullvex — dano de contato e do tiro em leque
5. Nullvex True — dano de contato, projétil fase 1-2, projétil de queda fase 3

O plano de implementação deve tratar esses 5 bosses com os valores atuais (não alterados) até que o usuário feche os números, ou aguardar a decisão antes de implementar essas fases especificamente — a implementação das fases 01, 02, 04, 06, 08 e das fases 00/09/10/11 (parcial) pode prosseguir independentemente.

## Fora de Escopo

- Sub-tanks (mecânica de cura reservável) — não têm valor atrelado à escala de HP revisada, não avaliados nesta revisão.
- Os 4 tipos alternativos de tiro do Zael (Spread/Rapid/Laser/Cannon) e as 4 armas alternativas da Zara (Dual Blades/Glaive/Garras/Machado) além do tipo padrão — o código atual só implementa o tipo "single"/espada base de fato; os outros são seleção no stage select sem lógica de tiro própria ainda. A escala de dano definida (carga 1/2/3/5 e combo 1/1/3) já cobre esses tipos quando forem implementados, pela mesma razão descrita na seção Player.
