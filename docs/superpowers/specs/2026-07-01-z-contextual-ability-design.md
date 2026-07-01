# Z Contextual Ability — Design Spec
_2026-07-01_

## Objetivo

Tornar Z o botão de ação primária: dispara Buster quando nenhuma habilidade de boss está ativa, ou ativa a habilidade selecionada quando uma está equipada. Extensível para qualquer número de habilidades futuras.

## Comportamento

| Estado | Z pressionado |
|---|---|
| `selected_boss_ability == ""` | Tiro Buster (comportamento atual) |
| Qualquer habilidade selecionada | `_use_special_ability()` — dispara o dispatch existente |

K (antes mapeada em `special`) é removida — a ação `special` fica sem binding.

## Mudanças

### `project.godot`
Remove o event K da ação `special`. A ação permanece registrada (não quebra código que referencie `"special"`) mas sem tecla mapeada.

### `zael.gd` — `_handle_shooting()`
Intercepta `attack` antes da lógica de carga quando há habilidade selecionada:

```gdscript
func _handle_shooting(delta: float) -> void:
    if is_dead:
        return
    if GameManager.selected_boss_ability != "" \
            and Input.is_action_just_pressed("attack"):
        _use_special_ability()
        return
    # fluxo normal de carga/tiro Buster...
```

`_use_special_ability()` já faz o dispatch por `bid` — adicionar habilidades futuras só exige um novo `elif` lá.

## Sem mudanças em
- `_fire_walk()`
- `_use_special_ability()`
- `_update_animation()` / animações
- `GameManager`
