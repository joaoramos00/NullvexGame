# Z Contextual Ability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Z dispara Buster quando nenhuma habilidade está ativa, ou ativa a habilidade selecionada do boss quando uma está equipada.

**Architecture:** Interceptar `attack` (Z) em `_handle_shooting()` antes da lógica de carga: se `GameManager.selected_boss_ability != ""`, redirecionar para `_use_special_ability()` que já faz dispatch por bid. Remover binding K da ação `special` no project.godot.

**Tech Stack:** GDScript 4, Godot 4, InputMap via project.godot

## Global Constraints

- `_use_special_ability()` não muda — novos poderes futuros adicionam `elif` lá
- Ação `special` permanece registrada no InputMap (sem binding) — não remove a ação
- Nenhuma mudança em animações, `_fire_walk()`, `GameManager`

---

### Task 1: Z contextual — remover K e interceptar attack

**Files:**
- Modify: `project.godot` linhas 64-68 (bloco `special={}`)
- Modify: `characters/ranged/zael.gd` função `_handle_shooting()` (linhas 308-325)

**Interfaces:**
- Consumes: `GameManager.selected_boss_ability: String` (vazio = sem habilidade)
- Consumes: `_use_special_ability()` — dispatch existente por bid
- Produces: Z contextual funcionando; K sem efeito

- [ ] **Step 1: Remover binding K da ação `special` em project.godot**

Substituir o bloco (linhas 64-68):
```
special={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":75,"key_label":0,"unicode":107,"location":0,"echo":false,"script":null)
]
}
```
Por:
```
special={
"deadzone": 0.5,
"events": []
}
```

- [ ] **Step 2: Modificar `_handle_shooting()` em `characters/ranged/zael.gd`**

Substituir a função inteira (linhas 308-325):
```gdscript
func _handle_shooting(delta: float) -> void:
    if is_dead:
        return
    if GameManager.selected_boss_ability != "" \
            and Input.is_action_just_pressed("attack"):
        _use_special_ability()
        return
    if Input.is_action_just_pressed("attack"):
        _is_charging = true
        _last_charge_level = 1
    if _is_charging:
        _charge_timer += delta
        var lvl := _charge_level()
        if lvl > _last_charge_level:
            _last_charge_level = lvl
            AudioManager.play_sfx(AudioLibrary.sfx_charge_ready)
    if Input.is_action_just_released("attack") and _is_charging:
        _fire(_charge_level())
        _is_charging = false
        _charge_timer = 0.0
```

Nota: a linha `if Input.is_action_just_pressed("special"):` foi removida — K não tem binding, e Z agora despacha via `attack` quando há habilidade ativa.

- [ ] **Step 3: Testar manualmente — sem habilidade selecionada**

Rodar o jogo (cena de teste ou stage). Sem habilidade equipada:
- Pressionar Z → Zael atira Buster (nível 1)
- Segurar Z → carrega (nível 2/3 com tempo)
- Soltar Z carregado → disparo de carga
- Pressionar K → nada acontece

- [ ] **Step 4: Testar manualmente — Fire Walk ativo**

No pause menu, selecionar a habilidade Ignarath (Fire Walk). Voltar ao jogo:
- Pressionar Z → Fire Walk dispara (4 ondas de fogo), usa 1 ammo
- Z não carrega nem atira Buster
- Pressionar K → nada acontece

- [ ] **Step 5: Commit**

```bash
git add project.godot characters/ranged/zael.gd
git commit -m "feat(input): Z contextual — buster ou habilidade ativa; remove K"
```
