# Enemy Fly — HOVER/DIVE/RETREAT Design

**Data:** 2026-05-26  
**Arquivo alvo:** `characters/enemies/enemy_flyer.gd` + `characters/enemies/enemy_flyer.tscn`

---

## Objetivo

Atualizar o inimigo Fly para ter comportamento em 3 estados (HOVER/DIVE/RETREAT) e usar o sprite `enemies/fly_bot.png`.

---

## State Machine

```
HOVER ──(player entra em detect_radius)──► DIVE
DIVE  ──(max_dive_time esgotado)──────────► RETREAT
RETREAT ──(voltou ao spawn_y)─────────────► HOVER
```

### HOVER
- Patrulha horizontalmente entre `_start_x ± patrol_range`
- Bobbing vertical leve: `velocity.y = sin(_bob_time * bob_speed) * bob_amplitude`
- Inverte direção ao bater em parede (`is_on_wall()`)
- A cada frame: verifica distância ao player via `get_tree().get_first_node_in_group("player")`
- Se `distance <= detect_radius` → entra em DIVE

### DIVE
- No início do estado: captura `_dive_dir = (player.global_position - global_position).normalized()`
- Mantém `velocity = _dive_dir * dive_speed` durante todo o estado
- Decrementa `_dive_timer`; quando `_dive_timer <= 0` → RETREAT

### RETREAT
- Move verticalmente para cima: `velocity = Vector2(0.0, -retreat_speed)`
- Quando `global_position.y <= _spawn_y` → fixa Y em `_spawn_y`, entra em HOVER

---

## Parâmetros

| Parâmetro | Tipo | Padrão | Descrição |
|---|---|---|---|
| `patrol_range` | float | 150.0 | Distância máxima de patrulha a partir de `_start_x` |
| `detect_radius` | float | 200.0 | Raio de detecção do player para iniciar DIVE |
| `dive_speed` | float | 280.0 | Velocidade durante o mergulho |
| `retreat_speed` | float | 150.0 | Velocidade de subida no RETREAT |
| `bob_amplitude` | float | 6.0 | Amplitude do bobbing vertical (px) |
| `bob_speed` | float | 2.0 | Velocidade angular do bobbing (rad/s) |
| `max_dive_time` | float | 1.2 | Duração máxima do mergulho (s) |

---

## Sprite

- Nó `Sprite2D` adicionado ao `enemy_flyer.tscn` com texture `res://enemies/fly_bot.png`
- `_sprite.flip_h` baseado no sinal de `velocity.x` (flip quando movendo para esquerda)
- Flicker de invencibilidade: `_sprite.modulate.a` alterna entre 0.35 e 1.0 durante `_invincible`

---

## Arquivos Modificados

| Arquivo | Mudança |
|---|---|
| `characters/enemies/enemy_flyer.tscn` | Adiciona nó `Sprite2D` com `fly_bot.png` |
| `characters/enemies/enemy_flyer.gd` | Substitui lógica por state machine HOVER/DIVE/RETREAT |

---

## Notas de Implementação

- `enemy_flyer.gd` já sobrescreve `_physics_process` sem chamar `super()` — manter esse padrão
- `_invincibility_timer` e `_invincible` são gerenciados manualmente (não dependem do super)
- Player buscado via grupo "player" — sem referência direta para manter desacoplamento
- `_spawn_y` salvo em `_ready()` para uso no RETREAT
