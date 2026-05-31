# Design: Sistema no_wall_grab — Paredes Lisas

**Data:** 2026-05-31
**Contexto:** O vidro do `CorridorSection` (stage_00) era tratado como parede normal pelo CharacterBody2D — ativando wall slide (cap 60px/s) e wall jump. O comportamento correto é: sólido (bloqueia o player), mas sem agarre, sem wall jump, e com gravidade plena (o player cai direto na pose de pulo).

---

## Objetivo

Qualquer `StaticBody2D` do jogo pode optar por comportamento de "parede lisa" entrando no grupo `"no_wall_grab"`. O character detecta isso via slide collision e suprime o wall slide.

---

## Comportamento Esperado (parede no_wall_grab)

| Situação | Resultado |
|---|---|
| Player pressiona contra a parede no ar | Bloqueado (colisão sólida normal) |
| Wall grab | **Não ativa** — `_is_wall_sliding` fica `false` |
| Wall jump | **Não disponível** — depende de `_is_wall_sliding` |
| Velocidade de queda | Gravidade plena — sem cap de 60px/s |
| Animação | Pose de pulo/queda (não wall-slide) |

---

## Arquitetura

### Componentes alterados

| Arquivo | Mudança |
|---|---|
| `characters/base/character_base.gd` | Helper `_touching_no_grab_wall()` + guarda em `_update_wall_slide()` |
| `stages/corridor_section.gd` | `body.add_to_group("no_wall_grab")` no `Glass_Lateral` StaticBody2D |

**Nenhum nó extra. Nenhuma mudança de collision layer.**

---

## Implementação

### `character_base.gd` — helper de detecção

```gdscript
func _touching_no_grab_wall() -> bool:
    for i in get_slide_collision_count():
        var col := get_slide_collision(i)
        var n := col.get_normal()
        if abs(n.x) > abs(n.y) and col.get_collider().is_in_group("no_wall_grab"):
            return true
    return false
```

Filtra por `abs(n.x) > abs(n.y)` para distinguir colisão lateral (parede) de colisão vertical (chão/teto).

### `character_base.gd` — `_update_wall_slide()` com guarda

```gdscript
func _update_wall_slide() -> void:
    if _is_dashing or is_on_floor():
        _is_wall_sliding = false
        return
    var dir := Input.get_axis("move_left", "move_right")
    if is_on_wall() and dir != 0.0 and velocity.y >= 0.0:
        if _touching_no_grab_wall():   # <-- novo
            _is_wall_sliding = false
            return
        _is_wall_sliding = true
        _wall_normal = get_wall_normal()
    else:
        _is_wall_sliding = false
```

### `corridor_section.gd` — tag no Glass_Lateral

Em `_add_glass_lateral_collision()`, após `add_child(body)`:

```gdscript
body.add_to_group("no_wall_grab")
```

---

## Efeitos em Cadeia (sem mudanças extras)

- **`_apply_gravity()`** — cap `if _is_wall_sliding and velocity.y > WALL_SLIDE_SPEED` não aplica → gravidade plena automática.
- **`_handle_jump()`** (CharacterBase e Zael) — verificam `_is_wall_sliding` antes do wall jump → wall jump bloqueado automaticamente.
- **Animação** — `_is_wall_sliding = false` → pose de pulo/queda natural, sem wall-slide anim.

---

## Extensibilidade

Para qualquer futura superfície lisa no jogo (gelo, metal polido, etc.):

```gdscript
meu_static_body.add_to_group("no_wall_grab")
```

Nenhuma outra mudança necessária.

---

## Arquivos a Modificar

1. `characters/base/character_base.gd`
2. `stages/corridor_section.gd`
