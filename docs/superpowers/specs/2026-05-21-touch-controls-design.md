# Touch Controls — Design Spec
**Data:** 2026-05-21
**Projeto:** NullvexGame (Godot 4.6.2)

---

## Objetivo

Adicionar suporte a controles touch para jogar no navegador mobile. Os botões ficam sobrepostos ao jogo (overlay semitransparente), só aparecem quando rodando no browser, e não alteram nenhum código de gameplay existente.

---

## Escopo

**Incluído:**
- 5 botões touch: ←, →, Pulo, Ataque, Pausa
- Overlay sobre o jogo (CanvasLayer)
- Visível apenas em `OS.get_name() == "Web"`
- Integração automática em todas as fases via `stage_scene.gd`

**Excluído:**
- Dash, Especial, Ability Prev/Next (não mapeados no mobile)
- Telas de menu (title screen, character select, stage select) — controladas por mouse/toque nativo
- Configuração de layout pelo jogador

---

## Arquitetura

### Cena: `ui/touch_controls.tscn`

```
TouchControls (CanvasLayer, layer=10)
  └─ BtnLeft      (TouchScreenButton)
  └─ BtnRight     (TouchScreenButton)
  └─ BtnJump      (TouchScreenButton)
  └─ BtnAttack    (TouchScreenButton)
  └─ BtnPause     (TouchScreenButton)
```

**Script:** `ui/touch_controls.gd`
- Em `_ready()`: se `OS.get_name() != "Web"`, `visible = false` e retorna
- Sem lógica adicional — `TouchScreenButton` gerencia toque → InputAction internamente

### Propriedades de cada botão

| Nó | action | Posição (âncora) | Tamanho |
|----|--------|-----------------|---------|
| BtnLeft | move_left | Inferior-esquerdo, offset (10, -72) | 52×52 |
| BtnRight | move_right | Inferior-esquerdo, offset (68, -72) | 52×52 |
| BtnJump | jump | Inferior-direito, offset (-120, -72) | 52×52 |
| BtnAttack | attack | Inferior-direito, offset (-62, -72) | 52×52 |
| BtnPause | pause | Superior-direito, offset (-44, 8) | 36×28 |

**Aparência:**
- `modulate = Color(1, 1, 1, 0.65)`
- Textura: `TouchScreenButton` com `shape = RectangleShape2D` e `visibility_mode = ALWAYS` (visibilidade controlada pelo script)
- Cor por grupo: vermelho para movimento, verde para pulo, azul para ataque, cinza para pausa

### Integração em `stage_scene.gd`

```gdscript
const _TOUCH_SCENE := preload("res://ui/touch_controls.tscn")

func _ready() -> void:
    # ... código existente ...
    var touch := _TOUCH_SCENE.instantiate()
    add_child(touch)
```

A instância é adicionada no `_ready()` da cena base — cobre automaticamente stages 01–08. As cenas `stage_00_scene.gd` e `stage_09_scene.gd` também recebem a mesma linha.

---

## Fluxo de Input

```
Jogador toca botão → TouchScreenButton emite InputEventAction("attack")
→ Input singleton processa normalmente
→ zael.gd / zara.gd lê Input.is_action_just_pressed("attack")
→ comportamento idêntico ao teclado
```

Nenhum arquivo de personagem, boss ou stage é modificado além da adição da instância em `stage_scene.gd`.

---

## Casos de Borda

- **Jogar no PC com tela touch:** botões aparecem (detecção por `OS.get_name() == "Web"` — não afeta builds PC mesmo com touchscreen)
- **Morte/respawn:** `TouchControls` é filho da cena de fase, persiste durante respawn
- **Pausa:** `BtnPause` dispara `pause` action — `PauseMenu` já escuta essa action normalmente
- **Segurar botão:** `TouchScreenButton` suporta hold — `is_action_pressed` funciona para dash futuro se necessário

---

## Arquivos Afetados

| Arquivo | Mudança |
|---------|---------|
| `ui/touch_controls.tscn` | **NOVO** |
| `ui/touch_controls.gd` | **NOVO** |
| `stages/stage_scene.gd` | +3 linhas (preload + instantiate) |
| `stages/stage_00/stage_00_scene.gd` | +3 linhas |
| `stages/stage_09/stage_09_scene.gd` | +3 linhas |

---

## Critérios de Aceitação

- [ ] Botões aparecem no browser (web export)
- [ ] Botões **não** aparecem no build de PC
- [ ] ← e → movem o personagem
- [ ] Pulo faz o personagem pular (incluindo double jump segurando)
- [ ] Ataque dispara combo/tiro
- [ ] Pausa abre o PauseMenu
- [ ] Botões semitransparentes não bloqueiam visão de inimigos/plataformas
