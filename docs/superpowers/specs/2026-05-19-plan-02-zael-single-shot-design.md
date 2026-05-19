# Design — Plan 02: Zael Single Shot
**Data:** 2026-05-19
**Escopo:** Zael com Single Shot (3 níveis de carga) + ajuste de input map

---

## 1. Contexto

Plan 01 entregou `CharacterBase` com movimento, pulo duplo, dash e HP. Plan 02 cria o personagem `Zael` que estende `CharacterBase` e adiciona o sistema de tiro Single com carga hold-and-release. Os outros 4 tipos de tiro (Spread, Rapid, Laser, Cannon) ficam para plano futuro.

---

## 2. Input Map (alterações)

| Ação | Tecla nova | Tecla anterior |
|------|-----------|----------------|
| move_left | Seta esquerda | A |
| move_right | Seta direita | D |
| jump | Space | Z |
| attack | Z | J |
| dash | X | X (sem mudança) |

`special`, `ability_prev`, `ability_next`, `pause` permanecem iguais.

---

## 3. Arquitetura

### Arquivos novos

| Arquivo | Tipo | Responsabilidade |
|---------|------|-----------------|
| `characters/ranged/zael.gd` | Script | Estende CharacterBase; gerencia estado de carga e disparo |
| `characters/ranged/zael.tscn` | Cena | Instancia CharacterBase + adiciona Marker2D para spawn do projétil |
| `characters/ranged/zael_bullet.gd` | Script | Movimento do projétil, colisão, auto-destruição |
| `characters/ranged/zael_bullet.tscn` | Cena | Area2D + CollisionShape2D (CircleShape2D) + Sprite2D |

### Arquivos modificados

| Arquivo | Alteração |
|---------|-----------|
| `project.godot` | Input map com novas teclas |
| `scenes/test_level.tscn` | Substitui instância de CharacterBase por Zael |
| `scenes/test_level.gd` | Atualiza tipo da referência de CharacterBase para Zael |

---

## 4. Zael (`zael.gd`)

Estende `CharacterBase`. Adiciona apenas o sistema de tiro — todo o movimento, pulo, dash e HP vêm da base.

### Estado interno

```
_charge_timer: float = 0.0   # tempo que Z está pressionado
_is_charging: bool = false    # Z está segurado
```

### Constantes de carga

| Constante | Valor |
|-----------|-------|
| CHARGE_L2_THRESHOLD | 0.4s |
| CHARGE_L3_THRESHOLD | 1.2s |

### Lógica por frame (`_physics_process`)

1. Chama `super._physics_process(delta)` para manter todo o movimento da base
2. Chama `_handle_shooting(delta)`

### `_handle_shooting(delta)`

```
Se "attack" acabou de ser pressionado:
    _is_charging = true

Se _is_charging:
    _charge_timer += delta

Se "attack" foi solto E _is_charging:
    nível = _get_charge_level()
    _fire(nível)
    _is_charging = false
    _charge_timer = 0.0
```

### `_get_charge_level() → int`

```
se _charge_timer >= CHARGE_L3_THRESHOLD → retorna 3
se _charge_timer >= CHARGE_L2_THRESHOLD → retorna 2
retorna 1
```

### `_fire(level: int)`

- Instancia `zael_bullet.tscn`
- Define `bullet.damage` e `bullet.scale` conforme a tabela abaixo
- Define `bullet.direction` = `1.0` se `facing_right`, `-1.0` caso contrário
- Adiciona o bullet como filho do nó pai do Zael (não do Zael, para não herdar transform)
- Posiciona o bullet no `Marker2D` (`$BulletSpawn.global_position`)

### Tabela de níveis

| Nível | Threshold | Damage | Scale |
|-------|-----------|--------|-------|
| L1 | < 0.4s | 5 | (1.0, 1.0) |
| L2 | 0.4s – 1.2s | 12 | (1.6, 1.6) |
| L3 | > 1.2s | 25 | (2.5, 2.5) |

---

## 5. Cena do Zael (`zael.tscn`)

Usa **herança de cena** do Godot 4: `zael.tscn` herda de `character_base.tscn`. O script do nó raiz é substituído por `zael.gd` (que `extends CharacterBase`). Todos os nós filhos da base (CollisionShape2D, Sprite2D, AnimationPlayer) são herdados automaticamente. Adiciona:

- `Marker2D` nomeado `BulletSpawn`, posicionado em `(20, -10)` local (ponta do canhão, altura do peito)

Visual placeholder: mantém o `_draw()` herdado da CharacterBase (retângulo ciano).

---

## 6. Projétil (`zael_bullet.gd` + `zael_bullet.tscn`)

### Estrutura da cena

```
ZaelBullet (Area2D)
├── CollisionShape2D (CircleShape2D, radius: 6)
├── Sprite2D
└── Timer (wait_time: 3.0, autostart: true, one_shot: true)
```

### Propriedades exportadas

```
var damage: int = 5
var direction: float = 1.0  # 1.0 = direita, -1.0 = esquerda
const SPEED := 500.0
```

### `_ready()`

- Conecta `body_entered` → `_on_body_entered`
- Conecta `Timer.timeout` → `queue_free`

### `_physics_process(delta)`

```
global_position.x += direction * SPEED * delta
```

### `_on_body_entered(body)`

```
queue_free()
```

### Visual placeholder

`_draw()` no script: `draw_circle(Vector2.ZERO, 6, Color.YELLOW)`. A escala do nó (definida pelo Zael ao instanciar) faz o círculo crescer para L2 e L3.

### Collision layers

- Bullet: layer 3, mask: layer 1 (cenário) — quando inimigos existirem (Plan 04), adicionar mask: layer 2

---

## 7. Test Level

`test_level.tscn` substitui a instância `CharacterBase` por `Zael`. O script `test_level.gd` atualiza a type hint da variável `character` de `CharacterBase` para `Zael`.

Nenhuma outra mudança no test level.

---

## 8. O que este plano NÃO cobre

- Outros 4 tipos de tiro (Spread, Rapid, Laser, Cannon) — plano futuro
- Efeito visual/sonoro de carga (sem assets ainda)
- Integração com armadura de braços — Plan 06
- Colisão com inimigos/hurtboxes — Plan 04
- HUD de charge indicator — Plan 08
