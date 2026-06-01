# Intro Boss AI — Commander Vex Design Spec

**Data:** 2026-05-31  
**Escopo:** Redesenhar a IA do `intro_boss.gd` para um padrão de 3 ataques com fase 2 distinta, substituindo a alternância mecânica dash/shoot atual.

---

## Visão Geral

O Commander Vex (Stage 00) é o primeiro boss do jogo — serve como tutorial de mecânicas de boss. O design prioriza padrões legíveis e ensináveis. O player aprende o ciclo após 2 rotações completas, mas precisa reagir a cada ataque individualmente.

O boss existente já tem sprites (idle, walk, dash, shoot) e o sistema de animação wired. Este spec cobre apenas a camada de IA/comportamento — sem novos assets.

---

## 1. Ciclo de Ataques (Fase 1)

**Rotação fixa:** dash → shoot → burst → (repete)

| Idx | Ataque | Descrição |
|-----|--------|-----------|
| 0 | **Dash** | Avança em direção ao player a 320px/s por 0.45s |
| 1 | **Shoot** | 1 projétil apontado direto ao player, 260px/s, dano 8 |
| 2 | **Burst** | 3 projéteis em leque de 30° (−15°, 0°, +15°), 240px/s, dano 6 cada |

**Entre ataques:** boss anda lentamente em direção ao player (60px/s). Para quando dentro de 80px.

**Attack interval (fase 1):** 2.2s

---

## 2. Fase 2 — Modo Frenesi (< 50% HP = < 14 HP)

### Trigger
- BossBase detecta HP ≤ 50% e chama `_enter_phase_2()`
- Boss pausa 0.5s (white flash via `_hit_flash_timer = 0.5`) enquanto rage é ativada

### Visual
- Sprite modulate base vira `Color(1.3, 0.6, 1.3)` — tint roxo-avermelhado persistente
- Flash branco de 0.5s ao entrar na fase

### Parâmetros aumentados

| Parâmetro | Fase 1 | Fase 2 |
|-----------|--------|--------|
| Attack interval | 2.2s | 1.0s |
| Dash speed | 320px/s | 420px/s |
| Walk speed | 60px/s | 100px/s |
| Projectile speed (shoot/burst) | 260/240px/s | 340/320px/s |
| Burst count | 3 projéteis | 5 projéteis |
| Burst spread | 30° total (15° cada lado) | 50° total (12.5° cada lado) |

### Rotação em Fase 2
Mantém a mesma sequência dash → shoot → burst, mas com os parâmetros escalados acima.

---

## 3. Burst Attack — Detalhe

Reusa a animação `_TEX_SHOOT` (mesmo sprite sheet). O boss para, a animação toca normalmente, e múltiplos projéteis são spawned ao final do windup (frame ~4 de 6).

```
base_dir = normalize(player.pos - boss.pos)
for i in count:               # count = 3 (p1) ou 5 (p2)
    angle = -half_spread + step * i
    dir = base_dir.rotated(angle)
    spawn_projectile(dir * speed, damage=6, color=purple)
```

**Cor dos projéteis burst:** `Color(0.5, 0.1, 0.8)` — roxo (diferente do shoot vermelho `Color(0.7, 0.1, 0.2)`)

---

## 4. Mudanças em `intro_boss.gd`

### Constantes novas / modificadas

```gdscript
const DASH_SPEED_P1    := 320.0
const DASH_SPEED_P2    := 420.0
const DASH_DURATION    := 0.45      # inalterado
const WALK_SPEED_P1    := 60.0
const WALK_SPEED_P2    := 100.0
const SHOOT_SPEED_P1   := 260.0
const SHOOT_SPEED_P2   := 340.0
const BURST_SPEED_P1   := 240.0
const BURST_SPEED_P2   := 320.0
const BURST_COUNT_P1   := 3
const BURST_COUNT_P2   := 5
const BURST_SPREAD_P1  := 30.0   # graus totais
const BURST_SPREAD_P2  := 50.0   # graus totais
const SHOOT_DAMAGE     := 8
const BURST_DAMAGE     := 6
const RAGE_FLASH_DURATION := 0.5
```

### Variáveis novas

```gdscript
var _phase2_rage: bool = false   # controla tint persistente
```

### `_attack_phase` — 3 estados

```gdscript
func _do_attack() -> void:
    match _attack_phase:
        0: _do_dash()
        1: _do_shoot()
        2: _do_burst()
    _attack_phase = (_attack_phase + 1) % 3
```

### `_enter_phase_2()`

```gdscript
func _enter_phase_2() -> void:
    attack_interval_p2 = 1.0
    _phase2_rage = true
    _hit_flash_timer = RAGE_FLASH_DURATION
    _is_attacking = true   # pausa attack timer durante o flash
    _resume_after_rage()

func _resume_after_rage() -> void:
    await get_tree().create_timer(RAGE_FLASH_DURATION).timeout
    _is_attacking = false
```

### `_do_combat` — walk speed phase-aware

```gdscript
var walk_spd := WALK_SPEED_P2 if phase >= 2 else WALK_SPEED_P1
```

### `_update_animation` — tint base em fase 2

```gdscript
# Modulate priority: hit flash > invincibility > rage tint > normal
if _hit_flash_timer > 0.0:
    _sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
elif _invincible:
    _sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
elif _phase2_rage:
    _sprite.modulate = Color(1.3, 0.6, 1.3, 1.0)
else:
    _sprite.modulate = Color.WHITE
```

---

## 5. Parâmetros do Boss

```gdscript
max_hp             = 28
attack_interval_p1 = 2.2
attack_interval_p2 = 1.0
phase2_threshold   = 0.5   # 50% HP = 14 HP
```

---

## 6. Critérios de Aceite

- [ ] Boss cicla dash → shoot → burst corretamente
- [ ] Burst dispara 3 projéteis roxos em leque de 30° (fase 1)
- [ ] Ao entrar em fase 2: flash branco de 0.5s, depois tint roxo persistente
- [ ] Burst dispara 5 projéteis em leque de 50° (fase 2)
- [ ] Velocidades de dash/walk/projéteis escaladas corretamente em fase 2
- [ ] `_draw()` permanece vazio (sem regressão do placeholder)
- [ ] Animações continuam corretas: dash congela no último frame, shoot toca ao atirar/burst

---

## Fora de Escopo

- Novos sprites para fase 2 (reusa os 4 existentes)
- Mudanças na arena ou colisões
- Novos efeitos de partícula (usa os existentes do BossBase)
- Mudanças no miniboss
