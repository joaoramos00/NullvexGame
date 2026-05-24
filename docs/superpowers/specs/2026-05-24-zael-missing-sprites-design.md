# Design — Sprites Faltantes do Zael

**Data:** 2026-05-24
**Escopo:** Gerar 5 animações faltantes do Zael via script Python (PIL) e conectar no código GDScript

---

## 1. Contexto

O Zael possui 4 animações funcionais: `idle` (8f), `run` (6f), `jump` (4f), `shoot_1/2/3`.  
Comparando com a referência do Mega Man X, faltam: dash, wall_slide, hurt, death e run_shoot.  
Todas as animações serão geradas programaticamente a partir dos sprites existentes usando PIL (Python).

---

## 2. Sprites a Gerar

### Frame size: 68×68px (igual ao padrão existente)

| Arquivo de saída       | Frames | Largura total | Fonte principal              |
|------------------------|--------|---------------|------------------------------|
| `ZaelDash.png`         | 2      | 136×68        | ZaelCorrendo.png frames 2-3  |
| `ZaelWallSlide.png`    | 2      | 136×68        | ZaelJump_new.png frame 2 + ZaelIdle.png frame 0 |
| `ZaelHurt.png`         | 3      | 204×68        | ZaelIdle.png frame 0         |
| `ZaelDeath.png`        | 6      | 408×68        | ZaelJump_new.png frames 2-3  |
| `ZaelRunShoot.png`     | 6      | 408×68        | ZaelCorrendo.png (todos) + ZaelAtirando.png frame 4 |

Todos salvos em `res://characters/ranged/`.

---

## 3. Técnicas por Animação

### 3.1 ZaelDash — 2 frames

Pose de dash: corpo inclinado para frente, cabeça abaixada.

- **Frame 0 (entrada):** ZaelCorrendo frame 2 — leve estiramento horizontal (scale_x=1.05), translação Y+3px para simular agachamento
- **Frame 1 (dash pleno):** ZaelCorrendo frame 3 — estiramento maior (scale_x=1.10), translação Y+5px, adicionar rastro de 3px de pixels semi-transparentes atrás do sprite (alpha=0.3)

### 3.2 ZaelWallSlide — 2 frames

Pose de deslizamento na parede: corpo voltado para a parede, braço estendido.

- **Frame 0:** ZaelJump_new frame 2 (aéreo) — rotação CW 15°, flip horizontal
- **Frame 1:** ZaelIdle frame 0 — rotação CW 20°, translação X+4px (encostado na parede), flip horizontal

### 3.3 ZaelHurt — 3 frames

Sequência de impacto e recuo.

- **Frame 0 (impacto):** ZaelIdle frame 0 — sobreposição de camada branca com alpha=0.85 (flash)
- **Frame 1 (recuo):** ZaelIdle frame 0 — translação X-6px, Y-4px; sobreposição branca alpha=0.4
- **Frame 2 (recuperação):** ZaelIdle frame 0 — translação X-3px, Y-2px; sobreposição branca alpha=0.15

### 3.4 ZaelDeath — 6 frames

Sequência de morte: hurt → dissolução → dispersão.

- **Frame 0:** igual ao ZaelHurt frame 0 (flash branco total)
- **Frame 1:** ZaelJump_new frame 2 — tint vermelho alpha=0.5, translação Y-4px
- **Frame 2:** ZaelJump_new frame 3 — checkerboard removal 25% dos pixels (pixels pares removidos)
- **Frame 3:** ZaelJump_new frame 3 — checkerboard removal 50% dos pixels
- **Frame 4:** ZaelJump_new frame 3 — checkerboard removal 75% + partículas dispersas (8 pixels coloridos ao redor, raio 20px)
- **Frame 5:** canvas vazio 68×68 com partículas apenas (raio 30px, alpha=0.5)

### 3.5 ZaelRunShoot — 6 frames

Corrida com braço em posição de tiro. Compositing do braço atirador sobre cada frame de corrida.

- **Base:** ZaelCorrendo frames 0-5
- **Overlay:** Região do braço direito extraída de ZaelAtirando frame 4 (bounding box aproximada: x=34, y=20, w=30, h=20)
- **Operação:** Para cada frame de corrida, sobrepor o braço atirador em posição fixa (x=36, y=22) usando `Image.paste()` com máscara alpha

---

## 4. Script Python

Um único script `scripts/generate_zael_sprites.py` que:
1. Carrega todas as texturas fonte com `PIL.Image.open()`
2. Gera cada animação conforme as técnicas acima
3. Salva os PNGs em `characters/ranged/`

Dependência: `Pillow` (`pip install Pillow`)

---

## 5. Integração no Código GDScript

### 5.1 `_setup_sprite_frames()` em `zael.gd`

Adicionar carregamento dos 5 novos sprite sheets após os existentes:

```
dash_tex      → ZaelDash.png        (2 frames, loop=false, speed=12)
wall_tex      → ZaelWallSlide.png   (2 frames, loop=true,  speed=6)
hurt_tex      → ZaelHurt.png        (3 frames, loop=false, speed=15)
death_tex     → ZaelDeath.png       (6 frames, loop=false, speed=10)
run_shoot_tex → ZaelRunShoot.png    (6 frames, loop=true,  speed=10)
```

### 5.2 `_update_animation()` em `zael.gd`

Prioridade de animações (de maior para menor):

```
1. is_dead           → "death"
2. _is_hurt          → "hurt"
3. _is_shooting + correndo → "run_shoot"
4. _is_shooting      → "shoot_1/2/3" (comportamento atual)
5. _is_dashing       → "dash"
6. _is_wall_sliding  → "wall_slide"
7. não está no chão  → "jump"
8. velocity.x != 0   → "run"
9. else              → "idle"
```

### 5.3 `character_base.gd`

- Adicionar flag `_is_hurt: bool` com timer (duração 0.3s) disparado no `take_damage()`
- Conectar `animation_finished` da animação `"death"` ao `_on_death_anim_finished()` para emitir o sinal `died` somente após a animação completar

---

## 6. Fora do Escopo

- Sprites da Zara (tratados separadamente)
- Animações de habilidade especial (Spread, Laser, etc.)
- Edição manual de pixels — o script gera o resultado final
