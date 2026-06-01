# Stage 01 · Ignarath — Design Spec

**Data:** 2026-06-01
**Status:** Aprovado

---

## Objetivo

Redesenhar o Stage 01 (Ignarath — Fogo) com layout elaborado em dois níveis, câmaras secretas com collectibles gateados por habilidades/exploração, e progressão temática do exterior vulcânico até a câmara de lava do boss.

---

## 1. Fluxo Geral

```
Z1 (alto) → shaft↓ → Z2 (baixo) → Corredor 1 + CP1 → Z3 (baixo→sobe) → shaft↑ → Z4 (alto) → Corredor 2 + CP2 + cura → Boss Ignarath
```

O stage opera em **dois níveis verticais**:
- **Nível alto** (y≈35–128 em game units): Z1, Z4, Corredor 2, Boss Room
- **Nível baixo / subterrâneo** (y≈160–262): Z2, Corredor 1, Z3

A transição entre níveis é feita por **shafts verticais** com plataformas em zigzag:
- **Shaft de descida** — extremidade direita de Z1 / início de Z2 (o player entra no Z2 descendo)
- **Shaft de subida** — extremidade direita de Z3 / início de Z4

---

## 2. Zonas

### Z1 · Exterior Vulcânico (nível alto)

**Tileset:** `Stage_01T_z1.png` — basalto vulcânico, veias de magma

| Elemento | Detalhe |
|----------|---------|
| Plataformas | 4 plataformas em escada ascendente (esquerda → direita → cima) |
| Inimigos | 3 grunts (em plataformas), 1 flyer (patrol no teto) |
| Hazards | Nenhum — zona de aquecimento |
| Collectibles | Nenhum |
| Saída | Shaft vertical descendente na extremidade direita → início de Z2 |

**Player spawn:** extremidade esquerda do chão.

---

### Shaft de Descida (Z1 → Z2)

- Posicionado rente ao início de Z2 (a boca do shaft é a entrada do subterrâneo)
- Paredes de pedra vulcânica dos dois lados
- **4 plataformas em zigzag** para controlar a velocidade de descida
- Sem inimigos, sem hazards — transição de zona

---

### Z2 · Túnel de Magma (nível baixo)

**Tileset:** `Stage_01T_z2.png` — lava tube, paredes de rocha com fissuras laranja

| Elemento | Detalhe |
|----------|---------|
| Plataformas | 7 plataformas esparsas sobre fossas de lava |
| Fossas de lava | 5 fossas no chão (dano contínuo ao tocar) |
| Inimigos | 3 grunts (nas plataformas), 2 flyers (patrol no teto) |
| Teto | Baixo — sensação de túnel apertado |
| Saída | Corredor 1 na extremidade direita |

**Câmara Secreta — Capacete Zael:**
- **Localização:** parede esquerda do Z2, logo ao entrar pelo shaft (visível assim que o player chega)
- **Acesso:** usar a habilidade do **Galerix (vento)** na parede rachada para destruí-la
- **Câmara:** sala lateral com piso único, capacete no centro
- **Sinalização:** a parede tem textura de rachadura distinta; o **Helmet do Zael** (se já equipado) pulsa ao passar perto
- **Retorno:** a câmara tem saída — o player não fica preso

> A mesma habilidade que é a fraqueza do Ignarath abre o segredo do seu stage — incentiva seguir a cadeia de fraquezas antes de revisitar.

---

### Corredor 1 (Z2 → Z3)

**Tileset:** `stage_01_glass.png` — obsidiana polida, paredes escuras

| Elemento | Detalhe |
|----------|---------|
| Tipo | `CorridorSection` horizontal |
| Conteúdo | **Checkpoint 1** (CP1) |
| Cura | Não |
| Sinalização | `checkpoint_triggered` ao atravessar |

---

### Z3 · Forja Industrial (nível baixo → ascendente)

**Tileset:** `Stage_01T_z3.png` — tijolos de fornalha, painéis metálicos, calor extremo

| Elemento | Detalhe |
|----------|---------|
| Plataformas | 5 plataformas em escada ascendente + 1 plataforma móvel (↔) perto do topo |
| Gêiseres | 3 gêiseres temporizados no chão — disparam em intervalos regulares (≈2.5 s ligado, 1.5 s desligado) |
| Inimigos | 3 grunts (nas plataformas), 1 flyer (patrol no meio) |
| Saída | Shaft vertical ascendente na extremidade direita → início de Z4 |

**Câmara Secreta — Coração:**
- **Localização:** buraco entre duas plataformas no trecho médio de Z3
- **Acesso:** o buraco parece uma fossa mortal, mas tem um **piso escondido** abaixo (câmara subterrânea abaixo do nível baixo)
- **Câmara:** sala compacta com coração no centro
- **Saída lateral:** passagem para o chão do Z3 à frente do buraco (o player não perde progresso)
- **Sinalização:** nenhuma visual — pura exploração

---

### Shaft de Subida (Z3 → Z4)

- Espelho do shaft de descida
- **5 plataformas em zigzag** para a subida
- Sem inimigos, sem hazards

---

### Z4 · Câmara de Lava (nível alto)

**Tileset:** `Stage_01T_z4.png` — câmara submersa em pedra vulcânica, teto de rocha derretida

| Elemento | Detalhe |
|----------|---------|
| Plataformas | 3 plataformas fixas sobre lava + 1 plataforma móvel (↔) |
| Lava | Chão coberto de lava (dano contínuo) — sem chão sólido acessível |
| Inimigos | 2 grunts (nas plataformas), 1 flyer |
| Hazards | Lava no chão (obrigatório navegar por plataformas) |
| Atmosfera | Zona de tensão antes do boss — sem collectibles, sem cura aqui |
| Saída | Corredor 2 na extremidade direita |

---

### Corredor 2 (Z4 → Boss)

**Tileset:** `stage_01_glass.png` — obsidiana polida

| Elemento | Detalhe |
|----------|---------|
| Tipo | `CorridorSection` horizontal |
| Conteúdo | **Checkpoint 2** (CP2) + **cura** (pequena recuperação de HP) |
| Sinalização | `checkpoint_triggered` + `player_healed` |

---

### Boss Room — Ignarath

- Sem alterações no design desta spec
- Boss room existente com Ignarath AI atual (fase 1: tiro único; fase 2: fan de 3 projéteis)
- Chão de lava no boss room (dano contínuo), 2 andares de plataformas
- **Entrada:** porta abre ao entrar; Ignarath realiza animação de entry_south ao iniciar o combate

---

## 3. Collectibles

| Item | Zona | Acesso |
|------|------|--------|
| 🪖 Capacete Zael | Z2 — câmara atrás da parede rachada | Habilidade do **Galerix** (vento) |
| ❤ Coração (+1 HP máximo) | Z3 — câmara abaixo do buraco | Cair no buraco certo (exploração) |

---

## 4. Inimigos por Zona

| Zona | Grunts | Flyers | Total |
|------|--------|--------|-------|
| Z1 | 3 | 1 | 4 |
| Z2 | 3 | 2 | 5 |
| Z3 | 3 | 1 | 4 |
| Z4 | 2 | 1 | 3 |
| **Total** | **11** | **5** | **16** |

---

## 5. Hazards Resumo

| Hazard | Zona | Comportamento |
|--------|------|---------------|
| Fossas de lava | Z2 (5x) | Dano contínuo ao tocar |
| Gêiseres temporizados | Z3 (3x) | Ciclo ≈2.5 s ativo / 1.5 s parado; hitbox de fogo ativo |
| Lava no chão | Z4 + Boss Room | Dano contínuo; sem piso sólido acessível |

---

## 6. Notas de Implementação

- **CorridorSection** já existe em `stages/corridor_section.gd` — usar para os dois corredores com `glass_tex = stage_01_glass.png`
- **Shaft vertical:** implementar como `StaticBody2D` com paredes laterais e série de plataformas internas; não há componente dedicado — criar inline na cena
- **Parede rachada:** `StaticBody2D` com grupo próprio; script verifica se player tem a habilidade `galerix` no `GameManager` para destruí-la (`queue_free`)
- **Câmara coração:** piso oculto abaixo do buraco — `StaticBody2D` posicionado abaixo do `_zone_min` do Z3; câmara com saída lateral em `StaticBody2D` sólido
- **Gêiseres:** `Area2D` com `CollisionShape2D` que alterna habilitado/desabilitado via `Timer`; aplica dano via `body_entered`
- **Lava no chão:** `Area2D` cobrindo o chão de Z4 e boss room; dano contínuo via `_process` enquanto player está dentro
- **Tilesets por zona:** `stage_scene.gd` já suporta `_zone_tilesets` com 4 zonas — os 4 arquivos `Stage_01T_z1-z4.png` já existem
