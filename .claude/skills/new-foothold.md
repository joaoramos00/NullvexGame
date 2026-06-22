# Skill: new-foothold

Use quando o usuário pedir uma "saliência para escalar" / foothold agarrável num shaft.

## O que é

Uma saliência agarrável = `StaticBody2D` agarrável (SEM `no_wall_grab`) que se
projeta 1 tile (64px) pra dentro do shaft a partir de uma parede. Mecânica =
wall-grab/wall-jump padrão do MMX; só a FORMA (ressalto curto) muda. Serve de
ponto de apoio/respiro entre paredes lisas ou longas.

## Como criar (stage 01)

Helper em `stages/stage_01/stage_01_scene.gd`:

    _z4_foothold(nome, wall_x, cy, side, h)

- `wall_x`: face interna da parede de onde projeta.
- `side`: "L" (parede à esquerda → projeta pra direita) ou "R" (parede à direita → projeta pra esquerda).
- `h`: altura (≤ 1 tile de respiro; apoio curto, não plataforma).

## Tiles

Tileset da zona (stage 01 Z4: `Stage_01T_z4.png`). O ressalto é tilado pelo
marching-squares de `_fp_tile`: faces parede-esq `(1,0)` / parede-dir `(3,2)`;
cantos convexos do bump `(0,0)`/`(1,3)`/`(0,2)`/`(3,3)`; preenchimento `(2,1)`.

## Calibrar

Abra o imgdebug, aba "Plataformas", modo **"Saliência"**. Ajuste Cols/Rows
(largura/altura do ressalto) e "Espelhar" (lado). Confira as coords de tile do
bump antes de posicionar no stage.

## Regras de validação (dimensionadas ao pulo do Zael)

- Vão livre horizontal ≥ 192px (descontando saliências/espinhos opostos).
- Passo vertical de subida entre apoios ≤ 118px.
- Folga vertical livre ≥ 80px acima de qualquer apoio.
