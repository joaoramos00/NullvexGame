# Intro Boss Sprites — Stage 00 Design Spec

**Data:** 2026-05-31  
**Escopo:** Gerar sprites do IntroBoss via PixelLab MCP e integrá-los ao código do jogo.

---

## Visão Geral

O `intro_boss.gd` (Stage 00) usa atualmente o placeholder `boss_color` do BossBase — um retângulo escuro desenhado via `_draw()`. Este spec cobre a geração de 4 sprite sheets via PixelLab e a integração no código seguindo o padrão do `enemy_miniboss.gd`.

---

## 1. Identidade Visual — Commander Vex

**Conceito:** Soldado corrupto cibernético — comandante da vanguarda das forças de Nullvex.

**Visual:**
- Tamanho: 64×128px por frame (limite máximo do PixelLab: 128px)
- Armadura tática escura (cinza escuro / chumbo)
- Detalhes luminosos neon roxo-azul (juntas, visor, painéis de energia)
- Capacete com visor monocular brilhante (neon azul)
- Braço esquerdo humanoide; braço direito com canhão integrado (para ataque shoot)
- Estilo: HD pixel art, consistente com o miniboss do mesmo stage

**Paleta dominante:** `#1a1a2e` (base), `#7b2d8b` (roxo neon), `#00b4d8` (azul neon), `#e0e0e0` (detalhes metálicos)

---

## 2. Animações

| Animação | Frames | FPS | Sprite Sheet Dimensions | Arquivo destino |
|----------|--------|-----|------------------------|-----------------|
| `idle` | 4 | 6 | 256×128px | `characters/bosses/intro_boss/intro_boss_idle.png` |
| `walk` | 6 | 8 | 384×128px | `characters/bosses/intro_boss/intro_boss_walk.png` |
| `dash` | 6 | 12 | 384×128px | `characters/bosses/intro_boss/intro_boss_dash.png` |
| `shoot` | 6 | 12 | 384×128px | `characters/bosses/intro_boss/intro_boss_shoot.png` |

**Descrições por animação:**

- **idle:** Respiração leve ou pulso do visor. Boss parado, canhão baixo, levemente inclinado para frente.
- **walk:** Passos laterais pesados mas controlados. Mantém postura de combate.
- **dash:** Body lean agressivo para frente, propulsores nas botas/costas acesos (neon roxo), frames progridem de pré-impulso → pico de velocidade → desaceleração.
- **shoot:** Canhão se eleva, frame 3-4 mostra carregamento (brilho no cano), frame 5 disparo (flash branco no cano), frame 6 recuo.

---

## 3. Geração via PixelLab MCP

**Ferramenta:** `create_character` + `animate_character` (PixelLab MCP)

**Workflow:**
1. `create_character` — definir Commander Vex com descrição detalhada, dimensões 80×160, vista lateral (sidescroller)
2. `create_character_state` (idle) — gerar animação idle, 4 frames
3. `create_character_state` (walk) — gerar walk, 6 frames, referenciando o idle como base visual
4. `create_character_state` (dash) — gerar dash, 6 frames
5. `create_character_state` (shoot) — gerar shoot, 6 frames
6. Download de cada animação como PNG horizontal via script de download da skill `/pixellab`
7. Salvar em `characters/bosses/intro_boss/`

**Descrição para o PixelLab (prompt base):**
```
Cybernetic corrupted soldier commander, dark tactical armor (dark gray / charcoal),
neon purple-blue glowing joints and visor panel, single-eye monocular visor glowing blue,
left arm humanoid, right arm has integrated cannon barrel,
HD pixel art sidescroller boss character, 80x160 pixels per frame, facing left
```

---

## 4. Integração no Código

### 4.1 Estrutura de arquivos

```
characters/bosses/intro_boss/
  intro_boss_idle.png
  intro_boss_walk.png
  intro_boss_dash.png
  intro_boss_shoot.png
```

### 4.2 Alterações em `intro_boss.gd`

Seguindo o padrão do `enemy_miniboss.gd`:

```gdscript
const _TEX_IDLE  := preload("res://characters/bosses/intro_boss/intro_boss_idle.png")
const _TEX_WALK  := preload("res://characters/bosses/intro_boss/intro_boss_walk.png")
const _TEX_DASH  := preload("res://characters/bosses/intro_boss/intro_boss_dash.png")
const _TEX_SHOOT := preload("res://characters/bosses/intro_boss/intro_boss_shoot.png")

const _IDLE_FRAMES  := 4;  const _IDLE_FPS  := 6.0
const _WALK_FRAMES  := 6;  const _WALK_FPS  := 8.0
const _DASH_FRAMES  := 6;  const _DASH_FPS  := 12.0
const _SHOOT_FRAMES := 6;  const _SHOOT_FPS := 12.0
```

**Lógica de animação:**
- `idle` → state IDLE ou INTRO
- `walk` → state COMBAT, não dashando e não atirando (`_is_dashing == false`)
- `dash` → `_is_dashing == true` (frame 5 congelado durante voo, igual ao miniboss no STOMP)
- `shoot` → durante `_do_shoot()` (controlado por `_is_attacking`)

### 4.3 Alterações em `intro_boss.tscn`

- Adicionar `Sprite2D` como filho do root node com `texture_filter = NEAREST`
- Remover a dependência de `_draw()` do BossBase para o placeholder (sobrescrever com `func _draw(): pass`)

### 4.4 Remoção do placeholder

Em `intro_boss.gd`, sobrescrever `_draw()` com vazio para suprimir o retângulo colorido do BossBase.

---

## 5. Critérios de Aceite

- [ ] 4 PNGs gerados e salvos em `characters/bosses/intro_boss/`
- [ ] `intro_boss.gd` carrega e troca texturas corretamente por estado
- [ ] Retângulo placeholder não aparece mais em jogo
- [ ] Sprite faz flip horizontal conforme direção do boss
- [ ] Animação de dash congela no último frame durante o voo
- [ ] Boss exporta corretamente para web (tipos explícitos para sign()/abs())

---

## Fora de Escopo

- Novo comportamento de AI para o intro boss (mantém dash + shoot existentes)
- Hit flash e invincibility flicker (já implementados no BossBase)
- SFX (AudioLibrary já tem slots `sfx_boss_damage` e `sfx_boss_death`)
