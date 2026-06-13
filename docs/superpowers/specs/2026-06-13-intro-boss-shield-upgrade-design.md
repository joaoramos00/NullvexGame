# IntroBoss — Shield Upgrade Design

**Data:** 2026-06-13  
**Escopo:** `characters/bosses/intro_boss.gd`, `characters/bosses/boss_base.gd`, `characters/ranged/zael_bullet.gd`

---

## Objetivo

Tornar o IntroBoss (boss da Stage 00) mais desafiador com três mudanças: escala visual maior, HP rebalanceado e uma mecânica de shield reativo que deflecte projéteis para cima.

---

## 1. Tamanho

`scale = Vector2(1.3, 1.3)` aplicado no nó raiz do IntroBoss. O Sprite2D, CollisionShape2D e tudo mais escala automaticamente com o pai.

---

## 2. HP Rebalanceado

| Parâmetro | Antes | Depois |
|-----------|-------|--------|
| `max_hp` | 28 | 80 |
| Dano L1 (5) | 17,8% | 6,25% |
| Dano L2 (12) | 42,8% | **15%** ✓ |
| Dano L3 (25) | 89,3% | 31,25% |
| Fase 2 threshold | 50% = 14 HP | 50% = 40 HP |

---

## 3. Shield Reativo

### 3.1 Registro de balas

`zael_bullet.gd` — adicionar no `_ready()`:
```gdscript
add_to_group("player_bullet")
```

Isso permite ao boss localizar projéteis via `get_tree().get_nodes_in_group("player_bullet")`.

### 3.2 Constantes (intro_boss.gd)

```gdscript
const SHIELD_RANGE       := 220.0   # px — raio de detecção
const SHIELD_TIME_WINDOW := 0.35    # s  — impacto iminente
const SHIELD_DURATION    := 0.6     # s  — duração do shield ativo
const SHIELD_COOLDOWN    := 4.0     # s  — recarga após uso
```

### 3.3 Variáveis de estado

```gdscript
var _is_shielding    : bool  = false
var _shield_timer    : float = 0.0
var _shield_cooldown : float = 0.0
```

### 3.4 Lógica de detecção (chamada em `_do_combat` a cada frame)

```
para cada nó em grupo "player_bullet":
    se distância ao boss < SHIELD_RANGE:
        bullet_speed = magnitude da velocidade da bala
        time_to_impact = distância / bullet_speed
        se time_to_impact < SHIELD_TIME_WINDOW
           AND _shield_cooldown == 0
           AND NOT _is_shielding
           AND NOT _is_dashing
           AND NOT _is_shooting:
            → ativar shield
            break
```

### 3.5 Ativação do shield

- `_is_shielding = true`
- `_is_attacking = true` (impede ataque normal enquanto ativo)
- `velocity.x = 0.0` (boss para)
- `_invincible = true` (sem dano durante shield)
- `_shield_timer = SHIELD_DURATION`

### 3.6 Deflexão de bala

Qualquer bala do grupo `"player_bullet"` que entre no `_check_shield_deflect()`:

```
bullet.velocity.y = -abs(bullet.velocity.length())
bullet.velocity.x  mantido
```

Isso força a bala para cima com magnitude total da velocidade original. A bala **não é destruída** — continua ativa e pode acertar inimigos normais no cenário. `source_id` inalterado.

### 3.7 Desativação

```
_shield_timer -= delta
quando <= 0:
    _is_shielding    = false
    _is_attacking    = false
    _invincible      = false
    _shield_cooldown = SHIELD_COOLDOWN
```

`_shield_cooldown` decrementa a cada frame normalmente junto com os outros timers.

### 3.8 Visual

Enquanto `_is_shielding`:
- `_sprite.modulate = Color(0.4, 0.8, 2.0, 1.0)` (azul-ciano brilhante)
- `_draw()` desenha anel ao redor do boss: `draw_arc(Vector2.ZERO, 52.0, 0, TAU, 32, Color(0.4, 0.8, 2.0, 0.6), 4.0)`

Ao desativar: modulate volta ao normal.

---

## Arquivos Modificados

| Arquivo | Mudança |
|---------|---------|
| `characters/bosses/intro_boss.gd` | `scale`, `max_hp`, constantes/vars de shield, lógica de detecção e deflexão, visual |
| `characters/ranged/zael_bullet.gd` | `add_to_group("player_bullet")` no `_ready()` |

`boss_base.gd` **não é modificado** — toda lógica fica no IntroBoss específico.
