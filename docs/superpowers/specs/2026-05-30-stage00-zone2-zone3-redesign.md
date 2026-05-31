# Stage 00 — Redesign Zona 2 e Zona 3

**Data:** 2026-05-30  
**Escopo:** Redesign completo de Zona 2 (x 8222–12922) e Zona 3 (x 12922–16492) do Stage 00.  
**Arquivos afetados:** `stages/stage_00/stage_00.tscn`, `stages/stage_00/stage_00_scene.gd`

---

## Visão Geral

A Zona 2 e Zona 3 originais eram planas e sem identidade. O redesign dá a cada zona um caráter distinto:

- **Zona 2 — "A Escalada":** ascensão vertical agressiva do chão (y=1088) até y=280, ~808u de altitude ganha.
- **Zona 3 — "Interior Elevado":** interior fechado com teto (y=80) que o player percorre em altura antes de entrar na sala do boss.
- **Corr3:** redesenhado para estar elevado (piso y=280, teto y=80) em vez de no chão.
- **Boss_LWall:** dividido em dois segmentos para abrir passagem ao Corr3 elevado. Player entra na arena e cai ~808u até o chão.

Nenhuma outra área do Stage 00 (Zona 1, Corr1, Sala do MiniBoss, Corr2, Sala do Boss) é alterada.

---

## Zona 2 — "A Escalada" (x 8222–12922)

Comprimento total: ~4700u. O player sobe progressivamente em 5 seções sem retornar ao chão.

### Seção 1 — Entrada (x 8222–8700, ~480u)

Trecho de reorientação após o Corr2.

| Nó | Posição (center) | Tamanho | Tipo |
|----|-----------------|---------|------|
| `Floor_Z2_Entry` | (8461, 1120) | 478 × 64 | Chão plano |

**Inimigos:** 2 grunts em (8360, 1042) e (8540, 1042).

---

### Seção 2 — Degraus de Subida (x 8700–9620, ~920u)

Três blocos maciços escalonados. Os gaps entre eles são abismos — cair significa voltar para a Seção 1.

| Nó | Posição (center) | Tamanho | y topo |
|----|-----------------|---------|--------|
| `Step_Z2_1` | (8860, 968) | 320 × 240 | 848 |
| `Step_Z2_2` | (9160, 872) | 320 × 432 | 656 |
| `Step_Z2_3` | (9460, 776) | 320 × 624 | 464 |

**Inimigos:** 1 grunt em (9090, 610). 2 flyers em (8860, 780) e (9160, 590).

---

### Seção 3 — Plataformas Flutuantes (x 9700–10884, ~1184u)

Três plataformas estreitas sem chão abaixo. Exige posicionamento preciso; queda é fatal (sem chão de recuperação).

| Nó | x (left–right) | y topo | Largura |
|----|----------------|--------|---------|
| `Plat_Z2_Float_A` | 9700–10084 | 360 | 384 |
| `Plat_Z2_Float_B` | 10100–10484 | 296 | 384 |
| `Plat_Z2_Float_C` | 10500–10884 | 360 | 384 |

**Inimigos:** 3 grunts (um por plataforma). 2 flyers nos gaps em (9950, 290) e (10350, 290).

---

### Seção 4 — Patamar Alto (x 10900–12200, ~1300u)

Área de combate no topo da escalada. Piso principal em y=280 com sub-plataformas e cover.

| Nó | Posição (center) | Tamanho | y topo |
|----|-----------------|---------|--------|
| `Floor_Z2_Peak` | (11550, 312) | 1300 × 64 | 280 |
| `SubPlat_Z2_1` | (11260, 248) | 320 × 64 | 216 |
| `SubPlat_Z2_2` | (11860, 248) | 320 × 64 | 216 |
| `Cover_Z2` | (11496, 280) | 192 × 128 | 216 |

**Inimigos:** 4 grunts em (10960, 234), (11160, 170), (11460, 170), (11760, 170). 2 flyers em (11340, 140) e (11940, 140).

---

### Seção 5 — Transição para Zona 3 (x 12200–12922, ~722u)

Patamar continuado em y=280. Player entra na Zona 3 mantendo altitude.

| Nó | Posição (center) | Tamanho |
|----|-----------------|---------|
| `Floor_Z2_Trans` | (12561, 312) | 722 × 64 |

**Inimigos:** nenhum (buffer de transição).

---

### Totais Zona 2

| Tipo | Quantidade | vs. Original |
|------|-----------|--------------|
| Grunt | 10 | +5 |
| Flyer | 6 | +4 |

**Constantes a atualizar em `stage_00_scene.gd`:** `ZONE2_GRUNTS`, `ZONE2_FLYERS`.

---

## Zona 3 — "Interior Elevado" (x 12922–16492)

Comprimento total: ~3570u. Player percorre o interior em altitude constante (piso y=280, teto y=80, clearance 200u — igual ao Corr1 existente).

### Seção 1 — Entrada (x 12922–13400, ~478u)

Primeiro contato com o teto. Parede esquerda veda o interior.

| Nó | Posição (center) | Tamanho |
|----|-----------------|---------|
| `Floor_Z3_Entry` | (13161, 312) | 478 × 64 |
| `Ceil_Z3_Entry` | (13161, 112) | 478 × 64 |
| `Wall_Z3_Entry_L` | (12890, 212) | 64 × 264 |

**Inimigos:** 2 grunts em (13080, 234) e (13260, 234).

---

### Seção 2 — Salas Fechadas (x 13400–15200, ~1800u)

Teto e piso contínuos. Três divisórias criam quatro salas com sub-plataformas internas.

**Estrutura contínua:**

| Nó | Posição (center) | Tamanho |
|----|-----------------|---------|
| `Ceil_Z3_Rooms` | (14300, 112) | 1800 × 64 |
| `Floor_Z3_Rooms` | (14300, 312) | 1800 × 64 |

**Divisórias e passagens (abertura y=160–220, 60u):**

| Nó | x center | Tamanho topo | Tamanho base | Passagem |
|----|----------|-------------|-------------|---------|
| `Div_Z3_1` topo | (13832, 121) | 64 × 82 | — | P1 |
| `Div_Z3_1` base | (13832, 282) | 64 × 124 | — | P1 |
| `Div_Z3_2` topo | (14432, 121) | 64 × 82 | — | P2 |
| `Div_Z3_2` base | (14432, 282) | 64 × 124 | — | P2 |
| `Div_Z3_3` topo | (15032, 121) | 64 × 82 | — | P3 |
| `Div_Z3_3` base | (15032, 282) | 64 × 124 | — | P3 |

**Sub-plataformas por sala:**

| Sala | x (left–right) | y topo | Inimigos |
|------|----------------|--------|----------|
| Sala A (x 13400–13800) | 13480–13720 | 196 | 1 grunt + 1 flyer |
| Sala B (x 13864–14400) | 13960–14280 | 180 | 2 grunts + 1 flyer |
| Sala C (x 14464–15000) | 14560–14880 | 196 | 2 grunts |
| Sala D (x 15064–15200) | 15064–15184 | 180 | — |

---

### Seção 3 — Continuação para Corr3 (x 15200–16492, ~1292u)

Interior continua elevado até a entrada do Corr3.

| Nó | Posição (center) | Tamanho |
|----|-----------------|---------|
| `Floor_Z3_Cont` | (15846, 312) | 1292 × 64 |
| `Ceil_Z3_Cont` | (15846, 112) | 1292 × 64 |

**Inimigos:** 2 grunts em (15340, 234) e (15800, 234).

---

### Totais Zona 3

| Tipo | Quantidade | vs. Original |
|------|-----------|--------------|
| Grunt | 9 | +5 |
| Flyer | 2 | 0 |

**Constantes a atualizar:** `ZONE3_GRUNTS`, `ZONE3_FLYERS`.

---

## Corr3 — Redesenhado Elevado (x 16492–17152)

O Corr3 era no chão (piso y=1088). Agora acompanha a Zona 3 em altitude.

| Nó | Posição (center) | Tamanho | Antes |
|----|-----------------|---------|-------|
| `Corr2_Floor` | (16822, 312) | 660 × 64 | y=1120 |
| `Corr2_Ceil` | (16822, 112) | 660 × 64 | y=832 |
| `Corr2_Wall_L` | (16492, 212) | 64 × 264 | y center=960, h=384 |
| `Corr2_Wall_R` | (17152, 212) | 64 × 264 | y center=960, h=384 |

> Os nós mantêm os nomes `Corr2_*` existentes no `.tscn`; apenas as posições e tamanhos mudam.

---

## Boss_LWall — Dividido em Dois Segmentos

A abertura y=80–344 (264u) permite a passagem do Corr3 elevado para a sala do boss.

| Nó | Posição (center) | Tamanho | Substitui |
|----|-----------------|---------|-----------|
| `Boss_LWall_Top` | (17124, -20) | 64 × 200 | `Boss_LWall` (remove) |
| `Boss_LWall_Bot` | (17124, 752) | 64 × 816 | `Boss_LWall` (remove) |

O código em `stage_00_scene.gd` que referencia `Boss_LWall` precisará buscar ambos os nós para habilitar/desabilitar a colisão.

**Efeito dramático:** player sai do Corr3 elevado (y≈280) e cai ~808u até o chão da arena (y=1088) antes de enfrentar o boss.

---

## Nós Removidos do `.tscn`

Os seguintes 16 nós das zonas originais são deletados:

```
# Zona 2 original (12 nós)
Floor_Pilar, Floor_Z2A, Block_Z2A, Plat_Z2B, Plat_Z2C, Plat_Desc1
Ledge_A, Ledge_B, Ledge_C, Pilar_A, Pilar_B, Pilar_C

# Zona 3 original (4 nós)
Floor_Z3Start, Plat_Z3A, Floor_Z3B, Floor_Z3C
```

---

## Resumo de Mudanças por Arquivo

### `stages/stage_00/stage_00.tscn`
- Remover 12 nós das zonas originais (listados acima)
- Adicionar ~25 novos StaticBody2D com CollisionShape2D
- Atualizar posições de `Corr2_Floor`, `Corr2_Ceil`, `Corr2_Wall_L`, `Corr2_Wall_R`
- Substituir `Boss_LWall` por `Boss_LWall_Top` + `Boss_LWall_Bot`

### `stages/stage_00/stage_00_scene.gd`
- Atualizar `ZONE2_GRUNTS` e `ZONE2_FLYERS` com as novas posições
- Atualizar `ZONE3_GRUNTS` e `ZONE3_FLYERS` com as novas posições
- Atualizar referência de `Boss_LWall` → buscar `Boss_LWall_Top` e `Boss_LWall_Bot`
