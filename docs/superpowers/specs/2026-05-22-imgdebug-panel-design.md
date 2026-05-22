# ImgDebug Panel Design

## Goal

Adicionar um painel de debug de assets visuais na title screen, acessível pelo botão ImgDebug, que permite visualizar sprites animados dos personagens e os tiles dos tilesets do projeto.

## Architecture

O painel é uma cena/script separado (`ui/img_debug.gd` + `ui/img_debug.tscn`) instanciado dinamicamente pela title screen quando o botão ImgDebug é pressionado. Toda a lógica de navegação, animação e exibição fica encapsulada dentro desse script, sem acoplar nada à title screen além do instanciamento.

A title screen apenas instancia/destrói o painel — não sabe nada do conteúdo interno.

## Layout

```
┌─────────────────────────────────────────────────────┐
│  [ SPRITES ]  [ TILES ]                             │  ← seção principal
├─────────────────────────────────────────────────────┤
│  (modo SPRITES)                                     │
│  [ ZAEL ]  [ ZARA ]                                 │  ← seleção de personagem
│  [ Idle ] [ Run ] [ Jump ] [ Shot ]                 │  ← abas de animação
│                                                     │
│  ┌──────────┐   Zael Idle | frame 3/8 | 8 fps      │
│  │          │   ● animando                          │
│  │  preview │   ┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐┌──┐  │
│  │  136×136 │   │0 ││1 ││2*││3 ││4 ││5 ││6 ││7 │  │  ← strip clicável
│  │          │   └──┘└──┘└──┘└──┘└──┘└──┘└──┘└──┘  │
│  └──────────┘                                       │
├─────────────────────────────────────────────────────┤
│  (modo TILES)                                       │
│  Stage_00T  (4×4, 32px cada)                        │
│  ┌────┬────┬────┬────┐                              │
│  │0,0 │1,0 │2,0 │3,0 │                              │
│  ├────┼────┼────┼────┤                              │
│  │0,1 │1,1 │2,1 │3,1 │                              │
│  ├────┼────┼────┼────┤                              │
│  │0,2 │1,2 │2,2 │3,2 │                              │
│  ├────┼────┼────┼────┤                              │
│  │ —  │1,3 │2,3 │3,3 │  ← (0,3) transparente        │
│  └────┴────┴────┴────┘                              │
└─────────────────────────────────────────────────────┘
```

## Dados de Sprites

| Personagem | Animação | Arquivo | Frames | Frame size | FPS |
|---|---|---|---|---|---|
| Zael | Idle | ZaelIdle.png | 8 | 68×68 | 8 |
| Zael | Run | ZaelCorrendo.png | 6 | 68×68 | 10 |
| Zael | Jump | ZaelJump.png | 9 | 68×68 | 10 |
| Zael | Shot | ZaelAtirando.png | 9 | 68×68 | 10 |
| Zara | Walk | ZaraAndando.png | 5 | 68×68 | 8 |
| Zara | Run | ZaraCorrendo.png | 3 | 68×68 | 10 |

## Dados de Tilesets

| Tileset | Arquivo | Grid | Tile size |
|---|---|---|---|
| Stage_00T | stages/stage_00/Stage_00T.png | 4×4 | 32×32 |

Tile `(0,3)` tem alpha = 0 (transparente) — renderizado com borda tracejada e label `—`.

## Comportamento de Navegação

- **Seção** (SPRITES / TILES): botões toggle no topo. Estado inicial: SPRITES.
- **Personagem** (ZAEL / ZARA): visível apenas em modo SPRITES. Estado inicial: ZAEL.
- **Animação**: abas que mudam conforme o personagem selecionado. Estado inicial: primeira aba.
- Trocar personagem reseta a aba de animação para a primeira.
- Trocar animação reseta o frame para 0 e retoma animação automática.

## Comportamento do Preview de Sprites

- Frame grande: 136×136 px, `TEXTURE_FILTER_NEAREST`, mostra o frame atual via `AtlasTexture`.
- Animação automática via `_process(delta)` com acumulador de tempo baseado no FPS da animação.
- Strip de frames individuais: cada frame em miniatura 40×40 px. Frame atual destacado com borda colorida.
- Clicar num frame do strip pausa a animação naquele frame.
- Clicar no preview grande retoma a animação se pausada.

## Comportamento do Preview de Tiles

- Grid 4×4, cada célula 52×52 px, mostra `draw_texture_rect_region` com o tile recortado.
- Label `(col,row)` abaixo de cada célula.
- Tile `(0,3)` exibido com fundo transparente e label `—`.
- Clicar num tile destaca-o com borda e exibe as coordenadas no rodapé.

## Integração com Title Screen

- `title_screen.tscn`: adiciona `ImgDebugButton` ao VBox (estilo roxo, após Quit).
- `title_screen.gd`: conecta `pressed` do botão. Ao pressionar: se painel existe → `queue_free`; se não existe → instancia `ImgDebug` e adiciona como filho.
- O painel cobre a tela inteira (anchor full rect, z_index alto) com fundo semi-opaco.
- Botão **✕ Fechar** dentro do painel também destrói o nó.

## Arquivos

| Ação | Arquivo |
|---|---|
| Criar | `ui/img_debug.gd` |
| Criar | `ui/img_debug.tscn` |
| Modificar | `ui/title_screen.gd` |
| Modificar | `ui/title_screen.tscn` |

## Testes

- `tests/test_img_debug.gd` + `.tscn`: verificar que o nó instancia corretamente, que os dados de sprites/tiles estão presentes, que trocar personagem muda as abas, que trocar animação reseta o frame.
