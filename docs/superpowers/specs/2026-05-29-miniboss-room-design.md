# Stage 00 — Sala do MiniBoss: Design Spec

**Data:** 2026-05-29  
**Contexto:** Sala pequena selada logo após a saída do corredor CP1 (X≈6430).

---

## Geometria da Sala

| Peça | Nó | Posição (center) | Tamanho |
|------|----|-----------------|---------|
| Chão | `MiniBoss_Floor` | (6750, 1120) | 640×64 |
| Teto | `MiniBoss_Ceil` | (6750, 800) | 640×64 |
| Parede direita (exit) | `MiniBoss_RWall` | (7070, 960) | 64×384 |

- **Parede esquerda (seal):** reutiliza `Corr1_Wall_R` (já existe, X=6430). Collision está desabilitada no `_ready()`; reabilita ao player entrar no trigger.
- **Dimensões internas:** 640×256px (10×4 tiles de 64px).
- **Floor face:** Y=1088 — mesmo nível do corredor e da Zona 2.
- **Ceil face:** Y=832.

---

## Trigger de Entrada

- `Area2D` criado dinamicamente em `stage_00_scene.gd`
- Posição: X=6470 (40px dentro da sala), Y=960 (centro)
- Tamanho: 80×256px
- `body_entered` com player → chama `_on_miniboss_room_entered()`

---

## Mecânica de Seal / Unseal

**Ao entrar:**
```
_on_miniboss_room_entered():
  Corr1_Wall_R.CollisionShape2D.disabled = false   # sela a entrada
  spawna MiniBoss se ainda não foi spawned
  desativa trigger (monitoring = false)
```

**Ao derrotar o MiniBoss:**
```
_on_miniboss_defeated():
  MiniBoss_RWall.CollisionShape2D.disabled = true  # libera saída
```

---

## MiniBoss

**Arquivo:** `characters/enemies/enemy_miniboss.gd` (extends `EnemyBase`)  
**Cena:** `characters/enemies/enemy_miniboss.tscn`  
**Spawn:** Vector2(6900, 1024) — lado direito da sala

### Stats
| Propriedade | Valor |
|-------------|-------|
| HP | 18 |
| contact_damage | 3 |
| shockwave_damage | 3 |

### State Machine

| Estado | Condição de entrada | Comportamento |
|--------|---------------------|---------------|
| `PATROL` | Inicial / após RECOVER | Anda devagar (~50px/s) em direção ao player |
| `CHARGE` | Player a ≤300px | Corre a ~220px/s por 0.5s na direção do player. Dano por contato. |
| `STOMP` | Após CHARGE ou a cada 4s | Salta levemente (+80px) e cai pesado. Ao tocar o chão: instancia `shockwave_effect.tscn` 150px para cada lado. |
| `RECOVER` | Após STOMP | Pausa de 0.6s. Volta para PATROL. |

**Sequência:** PATROL → CHARGE → STOMP → RECOVER → PATROL → …

---

## Shockwave Effect

**Arquivo:** `effects/shockwave_effect.tscn`  
**Tipo:** `Area2D` com `RectangleShape2D` (300×48px)  
- Instanciado no chão (Y=1088-24=1064) ao lado do MiniBoss
- `collision_layer=0`, `collision_mask=2` (player layer)
- `body_entered` → aplica `shockwave_damage` ao player (se não estiver no ar)
- Auto-destruído após 0.4s (`queue_free()`)

---

## Arquivos a Criar/Modificar

| Arquivo | Ação |
|---------|------|
| `stages/stage_00/stage_00.tscn` | Adicionar `MiniBoss_Floor`, `MiniBoss_Ceil`, `MiniBoss_RWall` |
| `stages/stage_00/stage_00_scene.gd` | Trigger de entrada, seal/unseal, spawn do MiniBoss |
| `characters/enemies/enemy_miniboss.gd` | Criar — state machine PATROL/CHARGE/STOMP/RECOVER |
| `characters/enemies/enemy_miniboss.tscn` | Criar — extends EnemyBase |
| `effects/shockwave_effect.tscn` | Criar — Area2D temporário |
