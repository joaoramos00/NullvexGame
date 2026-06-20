# Stage 01 — Roster de Fogo: Gameplay Design

**Data:** 2026-06-20
**Escopo:** comportamento em jogo e posicionamento dos 9 inimigos comuns de fogo do `stage_01` (a arte já existe)
**Relacionado:** spec de sprites `docs/superpowers/specs/2026-06-17-stage01-fire-enemies-sprite-design.md` (visual); este doc cobre só gameplay.

## Objetivo

Os 9 sprites de inimigos de fogo do `stage_01` (+ 4 projéteis) já estão gerados em `characters/enemies/stage_01/` e `characters/ranged/stage_01/`, mas não têm script/cena nem estão posicionados. Este design define o comportamento distinto de cada inimigo, o projétil compartilhado, e o posicionamento na fase (densidade pesada, focada em dificuldade).

A arquitetura reaproveita o padrão já provado do `stage_02` (roster de gelo): `EnemyBase` (terrestres), `EnemyFlyer` (voadores), e um projétil de inimigo simples. Boss, layout e hazards do `stage_01` ficam intactos.

## Arquitetura

- Cada inimigo: `characters/enemies/stage_01/<nome>.gd` + `.tscn`, no molde do `stage_02`:
  - `CharacterBody2D`, `collision_layer = 4`, `collision_mask = 1`.
  - `CollisionShape2D` (cápsula) + `Sprite2D` (sheet com `hframes`/`vframes` = grade real do sheet) + `ContactZone` (Area2D, layer 0 / mask 2) para dano de contato.
  - Script `extends EnemyBase` (ou `EnemyFlyer`), define `max_hp` e `contact_damage` em `_init()`/`_ready()`, anima via `_advance_sprite_frame_loop(delta, frames, fps)` / `_set_sprite_frame()`.
- Comportamentos que não são patrulha simples **sobrescrevem `_physics_process` sem chamar `super`** (turret fixa, serpente, mortar), usando os helpers de animação/invencibilidade de `EnemyBase`.
- **Projétil compartilhado** `characters/ranged/stage_01/fire_projectile.gd` + `.tscn`:
  - `extends Area2D`, no molde de `enemy_ice_projectile.gd`, com `setup(velocity, damage, source, gravity, variant)`.
  - Diferença: usa `Sprite2D` com a textura real do projétil (não `_draw()` procedural). `variant` seleciona a textura (`fire_bolt`/`fire_glob`/`fire_spit`/`heat_mortar_shell`) e o shape de colisão.
  - `gravity > 0` dá o arco parabólico do `heat_mortar`.
- As grades (`hframes`/`vframes`) e contagem de frames de cada sheet são lidas dos artefatos em `assets/generated/stage01_<enemy>/<action>/` na implementação.

## Os 9 inimigos

Frame inicial sempre `idle` (frame 0), exceto a serpente (começa submersa). Stats são alvo inicial, tunáveis no playtest.

### Melee (`EnemyBase`)
1. **`enemy_magma_grunt`** — patrulha simples, pressão de linha de frente. `super._physics_process` (patrulha default). `max_hp 10`, `contact_damage 8`.
2. **`enemy_molten_ram`** — investida: patrulha lenta; ao detectar o player à frente dentro de alcance, entra em arrancada curta acelerada (charge) e recua/cooldown. Mais tanky, contato forte. `max_hp 22`, `contact_damage 14`.
3. **`enemy_ash_hopper`** — coelho-robô: pulos ritmados (timer de salto com impulso vertical+horizontal), rápido e evasivo, hp baixo. `max_hp 7`, `contact_damage 7`.

### Fly (`EnemyFlyer`)
4. **`enemy_ember_orbiter`** — hover (bob) + dispara `fire_bolt` em rajada curta quando o player está em alcance; pouco deslocamento. `max_hp 8`, `contact_damage 6`. Projétil: `fire_bolt`.
5. **`enemy_flame_skimmer`** — mergulho e recuo: usa direto o ciclo hover→windup→dive→retreat do `EnemyFlyer` (parâmetros mais agressivos). `max_hp 9`, `contact_damage 10`.
6. **`enemy_cinder_flyer`** — patrulha aérea de assédio: hover patrulhando com drop/tiro leve ocasional. `max_hp 8`, `contact_damage 7`.

### Ranged (`EnemyBase` + timer de tiro)
7. **`enemy_heat_mortar`** — tiro **parabólico** (`heat_mortar_shell` com `gravity > 0`): preparar→disparar (release no frame de antecipação)→recuperar. Fixo no chão, vira para o player. `max_hp 14`, `contact_damage 9`, intervalo ~1.8s.
8. **`enemy_magma_turret`** — estacionária, **não vira**, dispara `fire_glob` horizontal em loop quando o player cruza a linha de tiro. Sem deslocamento, tanky. `max_hp 18`, `contact_damage 9`, intervalo ~1.4s.
9. **`enemy_lava_serpent`** — ciclo de máquina de estados (ver abaixo). Projétil: `fire_spit`.

### Mapeamento projétil ↔ inimigo
| Projétil | Inimigo | Movimento |
|----------|---------|-----------|
| `fire_bolt` | `enemy_ember_orbiter` | reto, rápido |
| `fire_glob` | `enemy_magma_turret` | reto, horizontal |
| `heat_mortar_shell` | `enemy_heat_mortar` | parabólico (gravity) |
| `fire_spit` | `enemy_lava_serpent` | reto/levemente arqueado |

## Serpente de lava (especial)

Script próprio `enemy_lava_serpent.gd` com máquina de estados:

`SUBMERGED → EMERGING → EXPOSED → SPIT → SUBMERGING → (SUBMERGED)`

- **SUBMERGED:** invisível/escondida no poço, **invulnerável** (`take_damage` no-op), sem ContactZone ativa; timer até emergir.
- **EMERGING:** sobe do poço (anim de emergência), começa a ficar vulnerável ao expor.
- **EXPOSED:** janela visível, vulnerável, ContactZone ativa.
- **SPIT:** cospe `fire_spit` em direção ao player (1 ou rajada curta).
- **SUBMERGING:** desce e volta a SUBMERGED.
- Posicionada **sobre poços de lava** (Z2 Rio de Lava, Z3 maré). A âncora vertical (y do poço) é setada por instância no posicionamento.
- A serpente é fixa em X (não anda); o desafio é o timing da janela exposta durante a travessia.

## Posicionamento (densidade pesada, dificuldade)

Substitui as placements genéricas antigas (Z1 `Grunt2/3`, `Flyer1`; as de Z2/Z3/Z4 já são removidas em runtime pelo `_ready`). Os inimigos do roster de fogo são spawnados via script nas zonas reconstruídas (`_build_zone2/3/4`) e via `.tscn`/script na Z1.

| Zona | Inimigos | Subtotal |
|------|----------|----------|
| **Z1 — início** | magma_grunt ×4, ash_hopper ×3, cinder_flyer ×3 | 10 |
| **Z2 — Rio de Lava** | molten_ram ×3, magma_turret ×3, ember_orbiter ×3, lava_serpent ×2 | 11 |
| **Z3 — maré** | heat_mortar ×3, flame_skimmer ×3, ash_hopper ×3, lava_serpent ×2 | 11 |
| **Z4 — shaft** | cinder_flyer ×3, ember_orbiter ×3, magma_grunt ×3, flame_skimmer ×2 | 11 |

Total ~43. Todos os 9 tipos presentes; cada tipo ≥2.

**Mira em dificuldade (sem regra de justiça):**
- Voadores podem assediar em pulos obrigatórios e sobre vãos de lava.
- Ranged/turrets posicionados para cobrir landings e forçar timing sob fogo.
- Serpentes podem emergir em pontos de travessia da lava (Z2/Z3) como hazard real durante o pulo.
- Únicos limites técnicos: não spawnar inimigo dentro de parede/colisão; não deixar inimigo terrestre flutuando sobre abismo/kill-plane.

Posições exatas calibradas na implementação (SVG de zona + bot + playtest).

## Entrega faseada (PR por trio)

1. **PR 1 — trio melee:** `magma_grunt`, `molten_ram`, `ash_hopper` (scripts + cenas + test).
2. **PR 2 — trio fly:** `ember_orbiter`, `flame_skimmer`, `cinder_flyer`.
3. **PR 3 — trio ranged:** `heat_mortar`, `magma_turret`, `lava_serpent` + `fire_projectile` compartilhado + 4 projéteis.
4. **PR 4 — wiring:** posicionamento dos ~43 inimigos no `stage_01`, ajuste do bot path, web export.

Cada PR: branch própria → testes headless PASS → PR → merge (fluxo do projeto).

## Testes & validação

- `tests/test_stage01_fire_enemies.gd` (+ `.tscn`): instancia cada cena de inimigo, confirma load sem erro e frame inicial `idle`/0 antes de qualquer timer avançar (serpente: estado submerso inicial). Estendido a cada trio.
- Testes de fase existentes (`test_no_enemies`, `test_stage01_hazards`) seguem passando após o wiring.
- Smoke do bot do `stage_01` (boot + travessia sem crash) e web export ao final do PR 4.

## Fora de escopo

- Miniboss para `stage_01`.
- Qualquer mudança no Ignarath, na sala do boss ou no fluxo de checkpoint.
- Mudança no layout/hazards da fase além do posicionamento de inimigos.
- Regeração/alteração de arte (sprites já existem).
