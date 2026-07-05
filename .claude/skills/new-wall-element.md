# Skill: new-wall-element

Use quando o usuário pedir um elemento preso à parede de um shaft: plataforma
saindo da parede, obstáculo/bloco que bloqueia a passagem, espinhos na face da
parede ou espinhos embaixo de uma plataforma.

## Tipos (preview no imgdebug → aba "Plataformas" → grupo "Parede")

| Botão | mode interno | O que é |
|-------|--------------|---------|
| Parede+Plat | `wall_platform` | plataforma pisável saindo da parede, vão livre acima/abaixo |
| Parede+Obstáculo | `wall_obstacle` | bloco que bloqueia a passagem (contorno de colisão amarelo) |
| Espinhos Parede | `wall_plat_spikes` | plat + espinhos na face LATERAL da parede, abaixo dela |
| Espinhos Plat | `wall_plat_spikes_under` | plat + espinhos pendurados na base da plataforma |

Cols×Rows dimensionam o elemento; "Espelhar" move a parede pra direita.
Calibrar SEMPRE no imgdebug antes de posicionar no stage.

## Tiles (tabela fixa em `_wall_tile_at` — NÃO usar marching-squares genérico)

- Parede = 2 colunas: miolo `(2,1)` + face (`(3,2)` parede esq / `(1,0)` parede dir).
- Junção parede↔elemento vira canto côncavo: esq topo `(2,0)` / base `(3,1)`;
  dir topo `(1,1)` / base `(2,2)`.
- Elemento: topo interior `(3,0)`, canto externo topo `(0,0)` esq / `(1,3)` dir;
  base interior `(1,2)`, canto externo base `(3,3)` esq / `(0,2)` dir;
  linhas do meio: fill `(2,1)` + face externa `(3,2)`/`(1,0)`.
- Cada lado tem peças próprias — **nunca flipar** um tile do outro lado.
- **No JOGO — espessura:** a plataforma tem 2 fileiras de arte (A: topo (3,0) +
  cantos (0,0)/(1,3); B: base (1,2) + cantos (3,3)/(0,2)) ⇒ rocha visível de
  64px ⇒ **colisão de 64px** ([top, top+64]). Tudo num GRID GLOBAL de 64px:
  topos de elemento ≡ 32 (mod 64), células da face ancoradas em ≡ 0 (mod 64) —
  a junção cai em células exatas, sem seams.
- **No JOGO:** desenhar a parede com COLUNA DE FACE a cavalo da linha de colisão
  (célula de 64px centrada na face; metade rocha dentro do corpo, metade
  transparente dentro do shaft) — a rocha visível fica exata na colisão e a
  junção pode SUBSTITUIR o tile de face na linha do topo/base do elemento,
  aplicando esta tabela literalmente. Células de junção centradas nas
  superfícies (a linha de rocha fica no MEIO da célula, como a crosta (3,0)).
  NUNCA desenhar junção sobre parede de fill sólido — fica invisível (não dá
  pra recortar fill já desenhado). Ver `_draw_z4_shaft_walls` +
  `_z4_draw_wall_junction` no stage 01.

## Espinhos

- Textura: `res://stages/stage_01/spikes.png` (32×32 = 1 cluster por tile, tips pra CIMA).
- Na face da parede: rotação ±PI/2 via transform (cf. `_z4_spike_face` no stage 01);
  +90° = tips pra direita (parede esq), −90° = tips pra esquerda (parede dir).
- Sob a plataforma: rotação PI com origem no canto inf-dir da tira.
- **NUNCA usar Rect2 com tamanho negativo** (dst ou src) — no web export o quad
  aparece duplicado/espelhado. Sempre rects positivos + `draw_set_transform`.
- Offsets pelas partes transparentes dos tiles: base do espinho 3/4 de tile pra
  DENTRO da coluna de face; sob plataforma, base 3/4 de tile ACIMA da borda da
  grade; recuo de meio tile no canto externo; largura da tira em tiles INTEIROS
  (nunca deixar cluster cortado — a folga fica do lado da parede).
- No jogo: colisão = parede `no_wall_grab` + Area2D instant_kill (`lava_floor`)
  alinhada às pontas + visual com `skip_base_draw` (ver `_z4_spike_face`).

## Regras de validação (dimensionadas ao pulo do Zael)

- Vão livre horizontal ≥ 192px; com espinho oposto, ≥ 240px.
- Passo vertical de subida entre apoios ≤ 118px.
- Folga vertical livre ≥ 80px acima de qualquer apoio pisável.
