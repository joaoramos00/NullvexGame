# Design — Kawagael (reskin do Zael) — Iteração 1: Corrida

**Data:** 2026-06-08
**Status:** Aprovado (design) — aguardando spec review
**Personagem-fonte PixelLab:** `bc1bd784-bffa-417e-905a-56e5aac35f67` (robô esmeralda, 256×256, 8 direções, side view)

## Visão Geral

Kawagael é um **reskin do Zael**: reusa 100% da mecânica existente (5 tipos de tiro,
sistema de carga, dash, dash-jump, wall-jump, etc.) e troca apenas as sprites e o nome.
O Zael permanece **intacto e jogável** durante todo o desenvolvimento — nenhum asset do
Zael é deletado ou modificado.

A construção é **incremental, um estado de animação por vez**. Esta iteração entrega
apenas o ciclo de **corrida (8 frames)**. Demais estados (idle, jump, shoot, dash, etc.)
ficam para iterações futuras e, enquanto não gerados, herdam as texturas do Zael via
fallback — de modo que Kawagael é jogável desde o dia 1.

### Por que "states por pose" e não animação

O `animate_character` do PixelLab (tanto custom quanto templates embutidos) não produz
troca de pernas em side-view: o skeleton interpola a partir de uma única pose-base e
mantém a perna de trás estática (testado pelo usuário). A correção é **autorar cada frame
como um `create_character_state` independente**, com a pose descrita explicitamente —
incluindo os dois *contacts* (perna direita à frente e perna esquerda à frente), o que
força o cruzamento real das pernas.

## Estrutura de Arquivos

Nada do Zael é tocado. Tudo novo fica isolado:

```
characters/ranged/kawagael/
  KawagaelRun.png          # spritesheet 8 frames × (68×68) = 544×68, gerado
  kawagael.gd              # extends Zael
  kawagael.tscn            # instancia character_base + kawagael.gd
tools/
  build_kawagael_run.py    # pós-processamento: trim / align / downscale / stitch
tests/
  test_kawagael.gd
  test_kawagael.tscn       # preview headless + assert de frames
docs/superpowers/specs/
  2026-06-08-kawagael-reskin-run-design.md   # este documento
```

## Pipeline de Geração

### Etapa (a) — Geração dos states (MCP, in-session)

8 chamadas `create_character_state` a partir de `bc1bd784…`, uma por pose. Parâmetros
comuns:
- `use_color_palette_from_reference=true` (trava a paleta da fonte → sem deriva de cor)
- `seed` controlada por frame (regeneração reproduzível de um frame isolado)

Poses (todas em corrida voltada para **east**, perfil direito):

| # | Fase do ciclo | edit_description (resumo) |
|---|---------------|---------------------------|
| 0 | contact R     | perna direita estendida à frente e plantada, esquerda empurrada atrás, braço esquerdo à frente, braço direito atrás |
| 1 | down/recoil R | peso baixando sobre a perna direita dobrada, perna esquerda começando a subir atrás |
| 2 | passing       | pernas passando sob o corpo, joelho esquerdo erguido à frente, torso ereto |
| 3 | high          | perna esquerda avançando no ar à frente, perna direita estendida empurrando atrás |
| 4 | contact L     | perna **esquerda** estendida à frente e plantada, direita atrás, braço direito à frente (cruzamento) |
| 5 | down/recoil L | peso baixando sobre a perna esquerda dobrada, perna direita começando a subir atrás |
| 6 | passing       | pernas passando sob o corpo, joelho direito erguido à frente |
| 7 | high          | perna direita avançando no ar à frente, perna esquerda estendida empurrando atrás |

Cada state gera 8 rotações; apenas a rotação **east** é usada.

### Etapa (b) — Download (REST)

`tools/pixellab_download.py character <state_id> characters/ranged/kawagael/_raw/` baixa
as rotações de cada state. Usa-se apenas o arquivo `*_east.png` (256×256) de cada um.
Os `_raw/` ficam fora do spritesheet final (artefatos intermediários).

### Etapa (c) — Pós-processamento (`build_kawagael_run.py`)

Para cada um dos 8 PNGs east, em ordem de frame:
1. **Trim** — recorta o bounding box dos pixels opacos.
2. **Align de pés** — alinha o pixel opaco mais baixo (pés) a uma **linha de chão fixa**
   comum a todos os frames → trava o bob vertical (corrida não "flutua").
3. **Centralização horizontal** — centraliza pelo centro do bounding box.
4. **Downscale** — escala uniforme para caber numa caixa de 68×68 preservando aspecto
   (LANCZOS — mantém o look "HD pixel art" do projeto).
5. **Stitch** — cola os 8 frames lado a lado → `KawagaelRun.png` (544×68, RGBA).

## Integração no Godot

`characters/ranged/kawagael/kawagael.gd`:

```gdscript
extends Zael
class_name Kawagael
```

Sobrescreve **apenas** `_setup_sprite_frames()`. A implementação monta um mapa
`estado → textura` que usa a textura do Kawagael onde já existe (nesta iteração: `run` →
`KawagaelRun.png`) e **cai de volta na textura correspondente do Zael** para todos os
estados ainda não gerados (idle, jump, shoot_*, dash, wall_slide, hurt, death, run_shoot,
jump_shoot, dash_shoot). A montagem de `SpriteFrames` (regiões `AtlasTexture` 68×68,
loops, speeds) é idêntica à do Zael.

Consequências:
- Mesmo `flip_h` (sprites gerados east = virados à direita; Zael já usa essa convenção).
- Mesma cápsula de colisão, mesmo offset/scale do `AnimatedSprite2D` (drop-in 68×68).
- Kawagael totalmente jogável desde já; cada iteração futura substitui um fallback.

`kawagael.tscn` espelha `zael.tscn` (instancia `character_base.tscn`, script
`kawagael.gd`, mesma `CapsuleShape2D` e `AnimatedSprite2D`).

Durante o desenvolvimento o personagem ativo do jogo continua sendo o Zael; o Kawagael é
validado pela cena de teste. A troca do personagem ativo / entrada no stage select fica
fora desta iteração.

## Erros & Validação

- **Pré-cheque de créditos** via `GET /v2/balance` antes das 8 gerações.
- **Poll com timeout** por state (reusa o padrão de polling do `pixellab_download.py`).
- **Regeneração isolada** — se um frame sair com pose ruim ou jitter de detalhe, regenera
  somente aquele state (novo seed), sem refazer os outros 7.
- **Validação headless** — `tests/test_kawagael.tscn` carrega `kawagael.gd`, confirma que
  a animação `run` tem 8 frames e que o restante cai no fallback do Zael sem erro.
- **Validação visual** — inspeção do `KawagaelRun.png` (e GIF de preview opcional) antes
  de aceitar; conferir alinhamento de pés e ausência de bob.

## Fora de Escopo (iterações futuras)

- Estados: idle, jump, shoot_1/2/3, dash, wall_slide, hurt, death, run_shoot, jump_shoot,
  dash_shoot.
- Troca do personagem ativo (Kawagael substituindo o Zael no fluxo de jogo).
- Entrada no stage select / sistema de save.
- Versão da Zara, se aplicável.
