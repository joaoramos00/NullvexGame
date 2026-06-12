# Stage 00 — Inimigos: Design Spec

**Data:** 2026-05-26
**Fase:** Stage 00 (intro)
**Tema visual da fase:** cidade destruída ao entardecer, estética dark/industrial

---

## Decisões de Contexto

- Todos os inimigos pertencem à **mesma facção robótica** do grunt (coesão visual)
- MiniBoss usa **`EnemyBase`** (sem HP bar — decisão de simplicidade)
- Boss usa **`BossBase`** existente (HP bar, intro animada, `boss_defeated`)
- `shockwave_effect.tscn` — Area2D temporário compartilhado entre MiniBoss e Boss

---

## 5.1.1 — Fly

### Visual
Drone robótico sem pernas, levita por propulsores anti-grav. Mesma facção do grunt mas **paleta cinza metálico/teal** com detalhes luminosos e olho-sensor vermelho. Sprite 68×68px.

### PixelLab Prompt
> "Pixel art robot drone enemy, side view, 68×68px frame, gray metallic body with teal glowing accents, small hovering robot, no legs, anti-gravity thrusters underneath, compact round chassis, single red eye sensor, HD pixel art style, dark background"

### Comportamento — 3 estados

| Estado | Descrição |
|--------|-----------|
| **HOVER** | Flutua ~200px acima do player, rastreia o X do player com suavidade. Aguarda timer de ataque (2–3s). |
| **DIVE** | Voa em direção ao player em alta velocidade. Termina ao atingir distância mínima ou colidir. |
| **RETREAT** | Recua rapidamente para a altura de patrulha. Ao chegar, volta para HOVER e reinicia o timer. |

Dano por contato durante DIVE via `ContactZone` existente. Sem projéteis.

### Técnico
- Arquivo: `characters/enemies/enemy_flyer.gd` — **reescrito** com enum `State {HOVER, DIVE, RETREAT}`
- Referência ao player via `get_tree().get_nodes_in_group("player")`
- Remove `patrol_range` — posicionamento dinâmico em relação ao player
- `_draw()` atual substituído por `AnimatedSprite2D` com sprite novo

---

## 5.1.2 — MiniBoss

### Visual
Versão blindada e aumentada do grunt. Paleta **laranja/vermelho** idêntica, mas com ombreiras maiores, punhos/manoplas reforçados e postura mais pesada. Sprite 68×68px escalado para ~3× no .tscn para atingir 2× Zael na tela.

### PixelLab Prompt
> "Pixel art heavy robot soldier enemy, side view, 68×68px sprite, orange and dark red heavy armor, large reinforced gauntlets, wide shoulder pads, compact helmet with visor, stocky threatening stance, same faction as grunt soldier, HD pixel art style, dark background"

### Stats
| Propriedade | Valor |
|-------------|-------|
| HP | 18 |
| contact_damage | 3 |
| shockwave_damage | 3 |

### Comportamento — 4 estados

| Estado | Descrição |
|--------|-----------|
| **PATROL** | Anda devagar (~50) em direção ao player. |
| **CHARGE** | Ao entrar em ~300px do player: corre a ~220 por 0.5s direto na direção. Dano por contato. |
| **STOMP** | Após charge ou a cada 4s: salta levemente e cai pesado. Gera shockwave 150px para cada lado. Player precisa pular. |
| **RECOVER** | 0.6s de pausa após stomp antes de voltar ao PATROL. |

**Sequência:** CHARGE → STOMP → RECOVER → PATROL → CHARGE → …

### Técnico
- Arquivo: `characters/enemies/enemy_miniboss.gd` — extends `EnemyBase`
- `.tscn`: `characters/enemies/enemy_miniboss.tscn`
- Shockwave: instancia `shockwave_effect.tscn` no chão; auto-destruído após 0.4s
- Aparece **uma única vez** em stage_00 (spawn fixo no código de `stage_00_scene.gd`)

---

## 5.1.3 — Boss (redesenhado)

### Visual
Comandante humanóide robótico, **~3× Zael**. Armadura pesada laranja/vermelho escuro, ombreiras largas com detalhes metálicos, elmo com visor iluminado, **canhão integrado no braço direito**. Mais alto e imponente que o MiniBoss.

### PixelLab Prompt
> "Pixel art robot commander boss, side view, 68×68px sprite sheet, tall humanoid robot, heavy orange and dark red armor, wide shoulder pads, full helmet with glowing visor, right arm replaced by arm cannon, imposing stance, military leader aesthetic, HD pixel art style, dark background"

### Stats
| Propriedade | Valor |
|-------------|-------|
| HP | 30 |
| contact_damage | 5 |
| projectile_damage | 3 |
| shockwave_damage | 5 |

### Comportamento — estados

| Estado | Fase | Descrição |
|--------|------|-----------|
| **WALK** | 1+2 | Aproxima-se do player (~60). |
| **DASH** | 1+2 | Corre horizontalmente (~280) na direção do player por 0.5s. Dano por contato. |
| **SLAM** | 2 | Logo após o dash: salta e cai pesado. Shockwave 200px para cada lado. |
| **SHOOT** | 1+2 | Para, mira no player. Fase 1: 1 projétil. Fase 2: 2 projéteis em leque leve. |
| **RECOVER** | 1+2 | 0.5s de pausa após cada ataque. |

**Sequência fase 1:** WALK → DASH → RECOVER → SHOOT → RECOVER → repete.

**Sequência fase 2 (<50% HP):** WALK → DASH → SLAM → RECOVER → SHOOT (2 proj.) → RECOVER → repete. Intervalos 30% menores.

### Técnico
- Arquivo: `characters/bosses/intro_boss.gd` — **reescrito** com novo state machine
- Mantém `extends BossBase` (HP bar, intro, `boss_defeated`, fraqueza)
- Shockwave compartilhado via `shockwave_effect.tscn`
- `boss_id = "intro_boss"`, `stage_id = 0`, `max_hp = 30`

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `characters/enemies/enemy_flyer.gd` | Reescrever com HOVER/DIVE/RETREAT |
| `characters/enemies/enemy_flyer.tscn` | Atualizar sprite |
| `characters/enemies/enemy_miniboss.gd` | Criar — extends EnemyBase |
| `characters/enemies/enemy_miniboss.tscn` | Criar |
| `characters/bosses/intro_boss.gd` | Reescrever — novo state machine |
| `effects/shockwave_effect.tscn` | Criar — Area2D temporário compartilhado |
| `stages/stage_00/stage_00_scene.gd` | Adicionar spawn do MiniBoss |
