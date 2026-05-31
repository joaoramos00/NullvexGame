# no_wall_grab — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Qualquer `StaticBody2D` no grupo `"no_wall_grab"` impede wall grab/jump e aplica gravidade plena ao player; o vidro do `CorridorSection` é automaticamente marcado.

**Architecture:** Helper `_touching_no_grab_wall()` em `character_base.gd` itera `get_slide_collision()` a cada frame e, se tocar parede do grupo, retorna `true`; `_update_wall_slide()` usa esse resultado como guarda. `corridor_section.gd` chama `add_to_group("no_wall_grab")` no `Glass_Lateral` StaticBody2D.

**Tech Stack:** GDScript / Godot 4.6.2

---

## Arquivos Modificados

| Arquivo | Mudança |
|---|---|
| `characters/base/character_base.gd` | Novo método `_touching_no_grab_wall()` + guarda em `_update_wall_slide()` |
| `stages/corridor_section.gd` | Uma linha em `_add_glass_lateral_collision()` |
| `tests/test_character_base.gd` | Novo teste para `_touching_no_grab_wall()` |

---

## Task 1: Helper _touching_no_grab_wall + guarda em _update_wall_slide

**Files:**
- Modify: `characters/base/character_base.gd:83-92`
- Test: `tests/test_character_base.gd`

- [ ] **Step 1: Adicionar o teste ao test_character_base.gd**

Abrir `tests/test_character_base.gd`. Adicionar chamada ao `run_tests()` e a função de teste:

```gdscript
func run_tests() -> void:
    test_initial_hp()
    test_take_damage_reduces_hp()
    test_damage_triggers_invincibility()
    test_invincibility_blocks_second_hit()
    test_death_signal_on_lethal_damage()
    test_is_dead_flag_set()
    test_no_grab_wall_returns_false_with_no_collisions()   # <-- novo
    print("=== All CharacterBase tests passed ===")

func test_no_grab_wall_returns_false_with_no_collisions() -> void:
    var cb := CharacterBase.new()
    add_child(cb)
    cb.max_hp = 100
    cb._ready()
    # Sem nenhum move_and_slide chamado, get_slide_collision_count() == 0
    # _touching_no_grab_wall() deve retornar false (nenhuma colisão).
    assert(cb._touching_no_grab_wall() == false, "_touching_no_grab_wall false sem colisões")
    cb.queue_free()
    print("PASS: test_no_grab_wall_returns_false_with_no_collisions")
```

- [ ] **Step 2: Rodar o teste — verificar que falha (método não existe)**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```

Esperado: erro de script — `_touching_no_grab_wall` não definido, ou `Invalid call`.

- [ ] **Step 3: Implementar _touching_no_grab_wall em character_base.gd**

Em `characters/base/character_base.gd`, adicionar o método logo após a linha 92 (após `_update_wall_slide`), **antes** de `_apply_gravity`:

```gdscript
func _touching_no_grab_wall() -> bool:
    for i in get_slide_collision_count():
        var col := get_slide_collision(i)
        var n := col.get_normal()
        if abs(n.x) > abs(n.y) and col.get_collider().is_in_group("no_wall_grab"):
            return true
    return false
```

- [ ] **Step 4: Adicionar a guarda em _update_wall_slide**

Substituir o bloco `_update_wall_slide` existente (linhas 83-92):

```gdscript
func _update_wall_slide() -> void:
    if _is_dashing or is_on_floor():
        _is_wall_sliding = false
        return
    var dir := Input.get_axis("move_left", "move_right")
    if is_on_wall() and dir != 0.0 and velocity.y >= 0.0:
        if _touching_no_grab_wall():
            _is_wall_sliding = false
            return
        _is_wall_sliding = true
        _wall_normal = get_wall_normal()
    else:
        _is_wall_sliding = false
```

- [ ] **Step 5: Rodar o teste — verificar que passa**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```

Esperado:
```
PASS: test_initial_hp
PASS: test_take_damage_reduces_hp
PASS: test_damage_triggers_invincibility
PASS: test_invincibility_blocks_second_hit
PASS: test_death_signal_on_lethal_damage
PASS: test_is_dead_flag_set
PASS: test_no_grab_wall_returns_false_with_no_collisions
=== All CharacterBase tests passed ===
```

- [ ] **Step 6: Commit**

```bash
git add characters/base/character_base.gd tests/test_character_base.gd
git commit -m "feat: no_wall_grab — helper + guarda em _update_wall_slide"
```

---

## Task 2: Marcar Glass_Lateral com o grupo no_wall_grab

**Files:**
- Modify: `stages/corridor_section.gd:100`

- [ ] **Step 1: Adicionar add_to_group no _add_glass_lateral_collision**

Em `stages/corridor_section.gd`, na função `_add_glass_lateral_collision()`, adicionar **uma linha** após `add_child(body)` (linha 100):

Estado atual (linhas 99-100):
```gdscript
    body.add_child(cs)
    add_child(body)
```

Novo estado:
```gdscript
    body.add_child(cs)
    add_child(body)
    body.add_to_group("no_wall_grab")
```

- [ ] **Step 2: Rodar os testes existentes — verificar que nada quebrou**

```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
```

Esperado: todos terminam sem erros.

- [ ] **Step 3: Commit**

```bash
git add stages/corridor_section.gd
git commit -m "feat: corridor_section glass marcado com grupo no_wall_grab"
```

---

## Task 3: Web export + verificação manual

- [ ] **Step 1: Exportar e publicar**

Rodar a skill `web-export` (`/web-export`).

- [ ] **Step 2: Verificar comportamento no browser**

No stage_00, jogar até o corredor (Corr1 ou Corr2) e testar:

| Ação | Comportamento esperado |
|---|---|
| Pular contra o vidro no ar | Player bate e cai — não agarra |
| Pressionar direção para o vidro no ar | Player bate e cai com gravidade plena — não desacelera |
| Tentar wall jump no vidro | Nada acontece — jump normal do chão apenas |
| Animação ao colidir com vidro | Pose de pulo/queda — sem wall-slide anim |
| Parede normal (chão, pilar) | Wall grab e wall jump funcionam normalmente |
