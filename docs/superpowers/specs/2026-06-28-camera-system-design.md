# Camera System Design — MMX-Style Vertical Camera

**Data:** 2026-06-28
**Scope:** `stage_scene.gd`, `stage_00_scene.gd`, novo `stages/camera_controller.gd`, shafts em `.tscn`

---

## Contexto

O sistema de câmera actual (`_cam_y` com threshold de 256px) não se comporta de forma consistente: plataformas pequenas da Z1 não movem a câmera (correcto), mas a subida gradual da Z2/Z3 pode falhar dependendo de como os degraus estão espaçados. O objectivo é substituí-lo por um comportamento próximo do Mega Man X original — previsível, responsivo e extensível para shafts e zonas especiais.

---

## Arquitectura: Dois Níveis de Override

```
┌─────────────────────────────────────────┐
│             CameraController            │
│                                         │
│  Nível 1 — Override                     │
│  ┌──────────┬──────────┬─────────────┐  │
│  │ LOCKED   │  SHAFT   │  (futuro)   │  │
│  └──────────┴──────────┴─────────────┘  │
│       ↓ se nenhum override activo       │
│  Nível 2 — Default MMX                  │
│  ┌──────────┬──────────┬─────────────┐  │
│  │ GROUNDED │ JUMPING  │ FALL_LEASH  │  │
│  └──────────┴──────────┴─────────────┘  │
└─────────────────────────────────────────┘
```

Um `CameraController` (`RefCounted`) encapsula toda a lógica. As fases chamam `update(delta)` e lêem `target_x`/`target_y` para posicionar o `Camera2D`. Nenhuma lógica de câmera permanece em `_process` das fases.

---

## Nível 1 — Overrides

### LOCKED (corredores + boss rooms)
Activado por `lock_to(target: Vector2, zoom: float)`, desactivado por `unlock()`.
A câmera lerpa suavemente para `target` enquanto activo. Ao desactivar, retoma o Nível 2 a partir da posição actual — sem salto.

As fases chamam `_cam.lock_to()` no signal `camera_lock_requested` do `CorridorSection` (já existente). Os boss rooms usam o mesmo mecanismo.

### SHAFT (shafts verticais)
Activado por `set_shaft_mode(true/false)` a partir de uma `Area2D` no `.tscn` da fase.

Enquanto activo: câmera segue `player.y - _CAM_RISE` continuamente com lerp rápido em **ambas as direcções** (subida e descida). É o único modo onde o pulo move a câmera verticalmente — necessário para shafts de wall-jump como o Z4 da stage_01.

**Detecção:** `Area2D` com shape que cobre a extensão do shaft, signals `body_entered` / `body_exited` filtrados pelo grupo `"player"`. A fase conecta os signals a `_cam.set_shaft_mode()`. O `CameraController` não sabe onde o shaft está — é uma decisão de design da fase.

### Prioridade
`LOCKED > SHAFT > Default MMX`

Se o shaft tiver um corredor na saída, o LOCKED toma precedência automaticamente.

---

## Nível 2 — Default MMX

Avaliado em cascata quando nenhum override está activo.

### GROUNDED (`is_on_floor() == true`)
Ao aterrar, regista `_floor_y = player.global_position.y`.
Câmera lerpa para `_floor_y - _CAM_RISE`:

```gdscript
_cam_y = lerpf(_cam_y, _floor_y - _CAM_RISE, 8.0 * delta)
```

Velocidade ~8/s → atinge o alvo em ~0.3s. **Não há threshold** — qualquer aterragem actualiza `_floor_y`. Plataformas pequenas da Z1 (88–192px) actualizam `_floor_y` mas como o player pousa e salta rapidamente, o movimento da câmera é imperceptível (~15–25px em 0.3s).

### JUMPING (`velocity.y ≤ 0`, no ar)
`_cam_y` congela completamente. Nenhuma actualização.

### FALL_LEASH (`velocity.y > 0`, no ar)
A câmera só segue se o player sair da janela inferior da câmera:

```gdscript
const LEASH_SLACK := 64.0   # 1 tile
var ideal_y := player.global_position.y - _CAM_RISE
if ideal_y > _cam_y + LEASH_SLACK:
    _cam_y = lerpf(_cam_y, ideal_y, FALL_SPEED * delta)
```

`LEASH_SLACK = 64px` — se a posição ideal da câmera estiver mais de 1 tile abaixo da posição actual, a câmera começa a seguir. Quedas curtas (salto para plataforma mais baixa) não movem a câmera; quedas longas (Z2→Z1, ~500px) movem.

---

## Interface Pública do CameraController

```gdscript
class_name CameraController extends RefCounted

func setup(player: CharacterBase, cam: Camera2D, viewport: Viewport) -> void
func update(delta: float) -> void

func lock_to(target: Vector2, zoom: float) -> void
func unlock() -> void
func set_shaft_mode(active: bool) -> void

var target_x: float   # sempre player.global_position.x
var target_y: float   # Y calculado pelo controller
```

---

## Constantes

| Constante | Valor | Descrição |
|-----------|-------|-----------|
| `_CAM_RISE` | 128px | câmera acima do origin do player → piso a 60px da borda inferior |
| `GROUNDED_SPEED` | 8.0/s | velocidade de lerp ao pousar |
| `SHAFT_SPEED` | 10.0/s | velocidade de lerp em modo shaft |
| `FALL_SPEED` | 5.0/s | velocidade de lerp quando leash activo |
| `LEASH_SLACK` | 64px | folga antes de câmera seguir em queda |
| `LOCK_SPEED` | 0.1 (factor) | velocidade de lerp em modo locked (já existente) |

---

## Ficheiros a Criar / Modificar

| Ficheiro | Acção |
|---------|-------|
| `stages/camera_controller.gd` | **Criar** — toda a lógica de câmera |
| `stages/stage_scene.gd` | **Modificar** — substituir `_process` camera logic + remover `_cam_y`, `_cam_floor_y` |
| `stages/stage_00/stage_00_scene.gd` | **Modificar** — idem + substituir bloco `_camera_locked` por `_cam.lock_to()` / `_cam.unlock()` |
| `stages/stage_01/stage_01.tscn` | **Modificar** — adicionar `Area2D` na entrada/saída do shaft Z4 |

---

## O Que NÃO Muda

- `CorridorSection` continua a emitir `camera_lock_requested` — as fases chamam `_cam.lock_to()` nesse signal
- Boss rooms continuam a usar o mesmo mecanismo de lock
- `_cam_visible_rect` continua a ser calculado após o update (para o backdrop do `_draw`)
- Zoom da câmera continua a ser gerido pelas fases (não pelo controller)
