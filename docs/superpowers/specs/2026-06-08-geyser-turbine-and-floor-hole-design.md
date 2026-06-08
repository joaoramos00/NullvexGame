# Gêiser → Turbina + Buraco no Piso (imgdebug/memórias) — Design

**Data:** 2026-06-08
**Fase:** stage_01 zona 2 (gêiseres) + ferramenta imgdebug + memórias

## Objetivo

Quatro itens, após o "buraco no piso" (corte real do chão) do gêiser ficar pronto:
A. Trocar o vulcão por uma **turbina cilíndrica** (gira em loop, solta vapor) via PixelLab.
B. Adicionar um modo **"Buraco no Piso"** na aba Plataformas do imgdebug.
C. Renomear o modo atual **"Piso+Buraco" → "Piso+Abismo"** (label) + memória.
D. **Memórias**: técnica do corte de piso + padrão do gêiser animado.

## A. Turbina cilíndrica (substitui o vulcão)

Mantém as 4 fases do gêiser e o corte de piso (`floor_holes`). Muda só os sprites e o aviso:
- **DORMENTE:** turbina girando devagar (loop normal), sem dano.
- **AVISO:** turbina **acelera** (`speed_scale` maior na AnimatedSprite), sem dano. (Substitui a fumaça.)
- **SUBIDA:** jato de **vapor** cresce do zero (clip de baixo p/ cima, como hoje), dano.
- **ATIVO:** jato de vapor em loop, dano.

PixelLab (sidescroller):
- Objeto turbina cilíndrica (128) → `animate_object` rotação em loop.
- Objeto jato de vapor (160) → `animate_object` billowing loop. (Subida = clip no motor.)

Integração: `geyser.gd` troca os 4 frames-sets: `_volcano` (smoke) → turbina (spin), `_jet`/`_rise` (lava) → vapor. A turbina fica dentro do "Buraco no Piso" já existente. Assets nomeados `geyser_turbine_*.png` e `geyser_steam_*.png` (path minúsculo = web-safe). Os assets antigos (geyser_smoke_*, geyser_jet_*) podem ser removidos.

## B. Modo "Buraco no Piso" no imgdebug

Novo botão na aba Plataformas (`ui/img_debug.gd`, `_PlatformView`): renderiza uma faixa de piso com um corte 2×2 (poço) usando os mesmos tiles do jogo: col esq topo (0,0)/baixo (2,0), col dir topo (1,3)/baixo (1,1). Para visualizar/calibrar o poço (tiles semi-transparentes precisam do piso cortado atrás).

## C. Rename "Piso+Buraco" → "Piso+Abismo"

O modo `floor_platform_hole` (piso + plataforma + abismo/penhasco) passa a exibir o **label "Piso+Abismo"** no imgdebug. Nome interno do modo (`floor_platform_hole`) e a meta `mirror_hole` ficam — só o texto do botão muda, p/ não quebrar. A memória `reference_imgdebug_floor_platform_hole` é atualizada para a terminologia "abismo".

## D. Memórias

1. **Nova — corte de piso (buraco):** `_draw_lava_tiles(rect, tex, holes)` + `_pit_tile_at` no `stage_scene`; meta `floor_holes` (PackedFloat32Array de x-mundo) na ledge; tiles do poço esq (0,0)/(2,0) e dir (1,3)/(1,1) são **semi-transparentes** (corner pieces) → exige o piso cortado atrás, senão o chão vaza.
2. **Nova — gêiser animado:** 4 fases (dormente/aviso/subida/ativo) via `AnimatedSprite2D` montado com `SpriteFrames` em runtime; subida = `Sprite2D` com `region_rect` revelando de baixo p/ cima; workflow PixelLab (objeto → `animate_object` v3 → baixar frames → recortar por bbox-união → importar).
3. **Atualizar** `reference_imgdebug_floor_platform_hole` → terminologia "Piso+Abismo".

## Validação

- imgdebug: abrir a aba Plataformas, clicar "Buraco no Piso" e "Piso+Abismo", conferir render.
- Jogo: turbina girando no buraco, acelera no aviso, solta vapor (subida + loop); bot da zona 2 revalidado.
- `test_stage01_hazards` continua passando (ajustar nomes se preciso).
