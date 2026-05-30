# Stage 00 — Pós-Corredor MB: Pilares com Saliências

**Data:** 2026-05-30  
**Contexto:** Redesign da área entre a saída do CorrMB (x=8222) e o início elevado da Zona 2 (Floor_Z2A top y=456).

---

## Problema

Os nós `Step_Up1/2/3` e `Pilar/Plat_PilarTop` existentes são inacessíveis:

- `JUMP_VELOCITY = -480`, `GRAVITY = 980` → pulo máximo ≈ **118px**
- Chão real (top face de `Floor_Pilar`): **y=1088** (não y=1024 como parecia)
- Step_Up1 top = y=864 → 224px acima do chão — inalcançável
- Step_Up2/3 ainda mais altos, mesma X — subida vertical impossível

---

## Física de Referência

```
JUMP_VELOCITY = -480 px/s
GRAVITY       = 980  px/s²
Max jump height = 480² / (2 × 980) ≈ 118px
Step seguro    = 96px  (margem de 22px)
```

---

## Solução

3 pilares estilo "construção com sacada" (120px de gap entre cada), cada pilar com uma **saliência baixa** (Ledge) e um **topo principal** (Shaft). Cada salto sobe exatamente **96px**.

---

## Layout (x=8222→9422, ~1200px horizontal)

```
y=456  ──────────────────────────────[Floor_Z2A]
y=512                          [Shaft_C topo]──┐
y=608                    [Ledge_C topo]  │Pilar│
y=704          [Shaft_B topo]──┐   │    │  C  │
y=800    [Ledge_B topo] │Pilar │   │    │     │
y=896  [Shaft_A topo]──┐│  B  │   │    │     │
y=992  [Ledge_A top] │ ││     │   │    │     │
y=1088─[CorrMB saída]──┘└─────┘gap└────┘gap──┘
       8222 8350 8542  8662 8790 8982 9102 9230 9422
        ◄─Ledge_A─►
             ◄─Shaft_A──►
                    ◄120►
                          ◄─Ledge_B─►
                                ◄─Shaft_B──►
                                       ◄120►
                                             ◄Ledge_C►
                                                  ◄─Shaft_C──►
```

**Caminho de subida** (6 saltos × 96px + salto final 56px):

| Passo | De | Para | Delta Y |
|---|---|---|---|
| 1 | Chão y=1088 | Ledge_A y=992 | 96px |
| 2 | Ledge_A y=992 | Shaft_A y=896 | 96px |
| 3 | Shaft_A y=896 | Ledge_B y=800 | 96px (+ 120px gap) |
| 4 | Ledge_B y=800 | Shaft_B y=704 | 96px (mesma borda) |
| 5 | Shaft_B y=704 | Ledge_C y=608 | 96px (+ 120px gap) |
| 6 | Ledge_C y=608 | Shaft_C y=512 | 96px (mesma borda) |
| 7 | Shaft_C y=512 | Floor_Z2A y=456 | 56px ✓ |

---

## Nós a Criar no .tscn

Cada "pilar" é dois StaticBody2D adjacentes que formam um L (sacada + coluna).

| Nó | Position (center) | Size | Top face y | X span |
|---|---|---|---|---|
| `Ledge_A` | (8286, 1072) | 128 × 160 | 992 | 8222→8350 |
| `Pilar_A` | (8446, 1024) | 192 × 256 | 896 | 8350→8542 |
| `Ledge_B` | (8726, 976)  | 128 × 352 | 800 | 8662→8790 |
| `Pilar_B` | (8886, 928)  | 192 × 448 | 704 | 8790→8982 |
| `Ledge_C` | (9166, 880)  | 128 × 544 | 608 | 9102→9230 |
| `Pilar_C` | (9326, 832)  | 192 × 640 | 512 | 9230→9422 |

**Verificação:** bottom de todos os nós = top_face + size.y = 1088+32=1152 (dentro do `Floor_Pilar`). ✓

---

## Nós a Remover do .tscn

- `Step_Up1`, `Step_Up2`, `Step_Up3`
- `Pilar`, `Plat_PilarTop`

(Total: 5 nós removidos, 6 adicionados)

---

## Gaps e Jumpability

**Gap A→B (x=8542→8662, 120px):**
- Player pula de Shaft_A topo (y=896) para Ledge_B topo (y=800)
- Ao cruzar x=8662 (t≈0.60s, dist=120px) o jogador está ~112px acima → pés em y=784 < 800 ✓
- Aterra em Ledge_B (x=8662→8790) sem problema

**Gap B→C (x=8982→9102, 120px):**
- Mesmo padrão: pula de Shaft_B (y=704) para Ledge_C (y=608) ✓

**Subida Ledge→Shaft (sem gap, borda comum):**
- Ledge_A right edge = Pilar_A left edge = x=8350
- Player sobe 96px na borda interna: pulo "corner jump" simples ✓

---

## Renderização

Os novos nós são `StaticBody2D` sem prefixo especial → `_draw_platforms()` os renderiza automaticamente via `_draw_platform_tiles()`. **Nenhuma mudança de código** necessária no drawing.

---

## Compatibilidade com Resto da Stage

- `Floor_Pilar` (9022, 1120, 1600×64) — chão abaixo dos pilares, **mantido**
- `Floor_Z2A` (8422, 488, 2000×64) — topo y=456; Pilar_C topo y=512 está 56px abaixo ✓
- Inimigos de Zona 2 em y≈392–800 — acessíveis após subida pelos pilares ✓
- Nenhuma mudança em código GDScript necessária
