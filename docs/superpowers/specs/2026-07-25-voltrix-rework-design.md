# Voltrix Rework — Design Spec

**Data:** 2026-07-25
**Status:** Aprovado para plano de implementação

## Contexto e Motivação

O Voltrix (3º boss, tema Raio/elétrico) hoje é o boss mais simples do roster: sprite de humanoide andando no chão, um único ataque (teleporta perto do player e derruba um projétil vertical, dano hardcoded em 18). Seu HP já foi fixado em 40 numa revisão de balanceamento anterior (`docs/superpowers/specs/2026-07-24-hp-damage-rebalance-design.md`), mas o dano de contato e do ataque ficaram como item pendente naquela revisão.

Esta revisão substitui o sprite do Voltrix por um personagem já gerado no PixelLab (robô alado, hover, verde/dourado) e constrói um moveset completo de 4 ataques do zero, seguindo o mesmo padrão dos bosses já reconstruídos (Ignarath, Cryovex, Gravitus, Terragor).

## Identidade

Voltrix continua sendo o boss do elemento **Raio** para todos os efeitos de jogo (fraqueza contra Terragor, habilidade elétrica desbloqueada ao derrotá-lo, posição na cadeia de fraquezas). A troca de sprite não muda isso — os ataques continuam tematicamente elétricos (raio, choque, tempestade) mesmo que o personagem não tenha bobinas visíveis enrolando o corpo. O dourado do personagem e os detalhes verde-neon já comunicam "choque" o suficiente; não colocar raios literais ao redor do corpo mantém a animação mais simples.

## Asset Visual

- **Personagem PixelLab:** `a40e732b-e933-4026-bea6-7ef964f2c977` (existe um estado irmão `c65718bb-d61e-4f44-bdd0-7f6c4f8eea28` no mesmo grupo, variação de pose — não usado nesta revisão).
- **Direção:** apenas **south** — é a que ficou boa pro jogo (diferente dos outros bosses, que usam west/east lado-a-lado).
- **Idle/hover:** já existe — grupo de animação `Flutuar1` seguido de `Flutuar2`, ambos direção south, 9 frames, formando um loop de flutuação.
- **A gerar nesta revisão (south apenas):**
  - Animação de entrada (intro do boss)
  - Animação de preparação genérica (telegraph/windup compartilhado, no padrão do "GatherEnergy" do Cryovex)
  - Animação do ataque `thunder_bolt` (o único dos 4 que dispara direto, sem preparação própria)
- **Fora de escopo desta revisão:** as animações de preparação específicas de `talon_dive`, `static_pulse` e `storm_barrage` — o usuário vai montá-las depois, escolhendo manualmente o frame inicial de cada uma no PixelLab.

## Movimento

Flutuante, no mesmo padrão do Luxar (`characters/bosses/luxar.gd`): `gravity_scale = 0.0` setado em `_ready()`, movimento livre em X e Y perseguindo o player a uma distância-alvo (não gruda nele, mantém uma distância de combate).

## HP

**40** (já fixado na revisão anterior, `characters/bosses/voltrix.tscn`). Não muda nesta revisão.

## Moveset (4 ataques nomeados)

| Ataque | Tipo | Dano | Preparação | Descrição |
|---|---|---|---|---|
| Contato | corpo-a-corpo passivo | 2 | — | Toque genérico do corpo (`contact_damage`, já existe via `BossBase`) |
| `thunder_bolt` | à distância | 3 | Não | Dispara um raio horizontal rápido na direção do player — substitui o ataque antigo de "cair do teto", já que agora o boss voa livre e não precisa mais se posicionar acima do player |
| `talon_dive` | corpo-a-corpo (investida) | 4 | Sim (usuário monta depois) | Mergulha em disparada contra o player usando asas + propulsores |
| `static_pulse` | área curta ao redor do corpo | 2 | Sim (usuário monta depois) | Descarga elétrica em área quando o boss está próximo do player |
| `storm_barrage` | à distância, leque | 3 | Sim (usuário monta depois) | Só na fase 2 — dispara múltiplos raios em leque, tempestade elétrica intensificada (expande `thunder_bolt`, no mesmo padrão de como o Luxar aumenta de 2 para 3 feixes na fase 2) |

Todo inimigo/boss tem `contact_damage >= 1` — regra já estabelecida na revisão anterior, respeitada aqui (2).

## Arquitetura de Código

Segue o padrão exato dos outros bosses reconstruídos: `characters/bosses/voltrix.gd` extends `BossBase`, com:
- `_ready()` override chamando `super._ready()` e setando `gravity_scale = 0.0`
- `_do_combat(delta)` — movimento hover livre em X/Y perseguindo o player a uma distância-alvo, no padrão do `luxar.gd::_do_combat`
- `_do_attack()` — escolhe o ataque por distância até o player, no padrão do Cryovex (`_DASH_RANGE` decide entre bite/IcyBlast): se o player está longe, usa `thunder_bolt` (fase 1) ou `storm_barrage` (fase 2, substituindo o `thunder_bolt`); se está perto, alterna entre `talon_dive` e `static_pulse`
- 4 funções privadas, uma por ataque nomeado (`_do_thunder_bolt()`, `_do_talon_dive()`, `_do_static_pulse()`, `_do_storm_barrage()`), cada uma tocando sua animação e aplicando dano via `_spawn_projectile()` (ataques à distância) ou `player.take_damage()` direto (ataques de contato/investida, no padrão do `_SLAM_DAMAGE`/`_PUNCH_DAMAGE` do Gravitus)
- Constantes de dano nomeadas no topo do arquivo (`_THUNDER_BOLT_DAMAGE := 3`, `_TALON_DIVE_DAMAGE := 4`, `_STATIC_PULSE_DAMAGE := 2`, `_STORM_BARRAGE_DAMAGE := 3`), seguindo a convenção dos outros bosses
- `contact_damage = 2` setado em `voltrix.tscn` (não em `_ready()` do script, já que Voltrix não tem outros overrides de `_ready()` que criem ambiguidade — `.tscn` continua a única fonte de verdade, como já é hoje)

Como só existe direção **south**, o boss não vai ter west/east distintos como os outros — a implementação precisa decidir como lidar com "virar" pro lado do player (ex: `scale.x` flip do sprite south, já que não há sprite lateral dedicado). Isso é uma diferença estrutural real em relação a todos os outros 8 bosses e deve ser resolvido explicitamente no plano de implementação.

## Fora de Escopo

- Animações de preparação de `talon_dive`, `static_pulse`, `storm_barrage` — usuário monta depois.
- Qualquer redesign de `contact_damage`/HP dos outros 4 bosses ainda pendentes da revisão anterior (Galerix, Luxar, Nullvex, Nullvex True) — não fazem parte desta revisão.
- Reskin do estado irmão `c65718bb-d61e-4f44-bdd0-7f6c4f8eea28` — não usado.
