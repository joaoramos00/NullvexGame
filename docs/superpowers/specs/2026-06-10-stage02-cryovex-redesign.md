# Stage 02 · Cryovex — Redesign Ambicioso

**Data:** 2026-06-10  
**Status:** Aguardando revisão do usuário

---

## Objetivo

Refazer o `stage_02` do zero como stage complexo de gelo, com quatro zonas temáticas, três corredores/checkpoints usando `CorridorSection`, miniboss próprio, inimigos abundantes, hazards de gelo e ramificações grandes para coletáveis e revisita.

O redesign usa os tiles já existentes em `stages/stage_02/`:

| Zona/Recurso | Arquivo | Uso |
|---|---|---|
| Z1 | `Stage_02T_z1.png` | Tundra congelada |
| Z2 | `Stage_02T_z2.png` | Caverna de gelo |
| Z3 | `Stage_02T_z3.png` | Glaciar profundo |
| Z4 | `Stage_02T_z4.png` | Câmara cristalina |
| Corredores | `stage_02_glass.png` | Vidro/gelo liso para `CorridorSection` |

---

## 1. Fluxo Geral

```
Z1 Tundra -> Z2 Caverna -> CP1 -> MB02 -> CP2 -> Z3 Glaciar -> Z4 Cristal -> CP3 -> futura arena Cryovex
```

### Checkpoints e corredores

Todos os corredores/checkpoints usam o adapter existente `CorridorSection` (`stages/corridor_section.gd`), com `glass_tex = stage_02_glass.png`.

| Corredor | Posição no fluxo | Conteúdo |
|---|---|---|
| CP1 | Depois de Z2 | Checkpoint, sem cura obrigatória |
| CP2 | Depois do MB02 | Checkpoint, recuperação pós-miniboss |
| CP3 | Depois de Z4 | Checkpoint pré-boss + cura |

`CP3` prepara a entrada para a arena do Cryovex, mas esta spec **não implementa Cryovex nem exige alterações no boss**. A arena/entrada pode existir como espaço/porta de integração futura.

---

## 2. Regras de Terreno

O Stage 02 não deve usar plataformas finas soltas no ar. O terreno deve parecer e funcionar como massa sólida:

- Chão e patamares são desenhados pelo topo do tileset, com corpo/fill para baixo.
- Degraus, saliências e pontes devem ter espessura visual e colisão coerente.
- Blocos retangulares altos são permitidos, desde que tenham corpo até embaixo.
- Heightfields/terreno contínuo são preferidos para trechos longos com degraus, cavernas e fendas.
- Fendas/abismos são interrupções reais da massa de gelo/rocha, com laterais visíveis.
- Paredes lisas de gelo/vidro devem entrar no grupo `"no_wall_grab"` quando o player não deve agarrar.

Essa regra vale para rota principal, câmaras laterais, zonas de coletáveis e entradas de corredores.

---

## 3. Zonas

### Z1 · Tundra Congelada

**Tileset:** `Stage_02T_z1.png`

Zona de entrada ampla, com chão escorregadio desde o começo e combate denso em terreno escalonado. O objetivo é ensinar o comportamento de gelo sem punir demais.

| Elemento | Detalhe |
|---|---|
| Terreno | Chão contínuo com degraus altos, fendas pequenas e alcovas |
| Hazard base | Chão escorregadio |
| Inimigos | Muitos grunts de gelo e flyers em camadas |
| Coletável | `SubTank`, escondido em rota curta de fácil acesso |
| Saída | Entrada para Z2 por caverna descendente |

O `SubTank` não exige habilidade específica. Deve ficar escondido, mas acessível para jogador atento na primeira visita.

### Z2 · Caverna de Gelo

**Tileset:** `Stage_02T_z2.png`

Caverna mais fechada, com teto baixo, paredes lisas e cristais/estacas de gelo com dano. A zona aumenta a pressão com emboscadas e menor espaço para corrigir derrapagens.

| Elemento | Detalhe |
|---|---|
| Terreno | Túneis, degraus escavados, colunas e fendas verticais |
| Hazard base | Chão escorregadio |
| Hazard principal | Estacas/cristais de gelo com dano |
| Inimigos | Grunts em corredores, flyers em câmaras altas |
| Coletável | Capacete da Zara, gateado por Ignarath |
| Saída | `CP1` via `CorridorSection` |

O **Capacete da Zara** fica atrás de gelo espesso/rachado que só abre com o poder do **Ignarath**. O gate deve ser sinalizado visualmente por gelo queimável/derretível.

### MB02 · Guardião Glacial

Sala selada entre `CP1` e `CP2`. O miniboss é próprio do Stage 02 e deve ter sprite novo gerado via `generate2dsprite` após aprovação da spec e do plano.

| Elemento | Detalhe |
|---|---|
| Entrada | Após `CP1` |
| Saída | `CP2`, aberto após derrota |
| Arena | Chão escorregadio e paredes de gelo liso |
| Função | Ponto de virada da fase; teste de controle no gelo |
| Implementação | Script próprio ou derivado de `EnemyBase`, conforme plano |

O MB02 deve controlar espaço com ataques de gelo, mas não deve substituir o boss Cryovex.

### Z3 · Glaciar Profundo

**Tileset:** `Stage_02T_z3.png`

Zona longa e parcialmente vertical, com fendas maiores e nevasca lateral. O layout exige saltos com tração reduzida e leitura do vento.

| Elemento | Detalhe |
|---|---|
| Terreno | Grandes blocos de glaciar, fendas profundas, shafts com massa lateral |
| Hazard base | Chão escorregadio |
| Hazard principal | Nevasca lateral empurrando o player |
| Inimigos | Abundantes, posicionados para pressionar saltos e retomadas |
| Coletável | `Heart`, gateado por mobilidade/salto longo |
| Saída | Z4 |

O **Heart** exige movimento além de `dash + jump` normal. O gate aceita qualquer solução de mobilidade equivalente, desde que permita um salto mais longo que o kit base.

### Z4 · Câmara Cristalina

**Tileset:** `Stage_02T_z4.png`

Zona final com cristais, paredes lisas, fendas e inimigos em camadas. A dificuldade vem de combinar gelo escorregadio, abismos e combate antes do checkpoint pré-boss.

| Elemento | Detalhe |
|---|---|
| Terreno | Cristais maciços, pontes grossas, fendas e câmaras laterais |
| Hazard base | Chão escorregadio |
| Hazard principal | Paredes lisas/abismos/cristais de controle espacial |
| Inimigos | Alta densidade, com encontros em vários níveis |
| Coletável | `SpreadZael`, gateado por Luxar |
| Saída | `CP3` pré-boss |

O **Spread do Zael** fica em rota aberta pelo poder do **Luxar**, usando ativação/reflexo de cristais ou uma barreira cristalina responsiva à luz.

---

## 4. Coletáveis

| Item | Zona | Gate/Acesso |
|---|---|---|
| `SubTank` | Z1 | Escondido, fácil acesso, sem poder externo |
| `ArmorZaraHelmet` | Z2 | Poder do Ignarath derrete/abre gelo espesso |
| `Heart` | Z3 | Mobilidade/salto longo maior que dash+jump |
| `SpreadZael` | Z4 | Poder do Luxar ativa/abre cristais |

A rota principal da fase deve continuar vencível sem coletar esses itens e sem poderes externos.

---

## 5. Hazards

### Chão escorregadio

Comportamento base do Stage 02. Pode aparecer em todas as zonas, preferencialmente nas superfícies marcadas como gelo polido.

O implementation plan deve decidir se isso será um script/área de superfície escorregadia ou uma extensão controlada no movimento do player. A solução precisa ser local ao stage e testável.

### Estacas/cristais de gelo

Hazard de dano simples em Z2 e opcionalmente em rotas laterais. Deve aplicar dano ao player ao tocar, com collision/mask compatível com player.

### Nevasca lateral

Hazard ambiental de Z3. Empurra o player horizontalmente em trechos definidos, principalmente durante saltos sobre fendas ou em shafts.

### Paredes lisas

Usar grupo `"no_wall_grab"` em superfícies onde wall grab/wall jump devem ser bloqueados. Isso vale para vidro dos corredores e paredes de gelo polido.

---

## 6. Inimigos e Sprites

O Stage 02 deve ter inimigos abundantes em todas as zonas. O plano de implementação deve criar novos inimigos de gelo conforme necessário e gerar seus sprites usando a skill `generate2dsprite`.

Escopo mínimo recomendado:

| Inimigo | Função | Sprite |
|---|---|---|
| Grunt de gelo | Patrulha terrestre em terreno escorregadio | Novo sprite via `generate2dsprite` |
| Flyer de gelo | Pressão aérea em fendas/câmaras | Novo sprite via `generate2dsprite` |
| MB02 | Miniboss do stage | Novo sprite via `generate2dsprite` |

Scripts podem derivar de `EnemyBase`/`EnemyFlyer` quando o comportamento for próximo. O MB02 deve ter comportamento próprio ou adaptação explícita de miniboss existente.

---

## 7. Arquitetura e Arquivos

### Arquivos principais

| Arquivo | Ação |
|---|---|
| `stages/stage_02/stage_02.tscn` | Recriar como cena complexa |
| `stages/stage_02/stage_02_scene.gd` | Novo script customizado do stage |
| `tests/test_stage_02.gd` | Expandir/criar teste de load e estrutura |
| `tests/test_stage_02.tscn` | Cena de teste |

### Padrões obrigatórios

- Spawn de player segue `stage_00_scene.gd`: escolhe Zael/Zara por `GameManager.active_character`.
- `StageController.setup(_player)` e HUD conectam ao player spawnado.
- Câmera suporta lock temporário em corredores, miniboss e futura arena.
- Corredores são instâncias de `CorridorSection`, não implementação paralela.
- Portas devem usar o comportamento já encapsulado por `CorridorSection`.
- Não criar nem alterar Cryovex nesta etapa.

---

## 8. Testes e Validação

### Testes automatizados mínimos

- Cena `res://stages/stage_02/stage_02.tscn` carrega.
- Existem nós/instâncias ou setup equivalente para `CP1`, `CP2`, `CP3`.
- Existem marcadores/zonas para Z1, Z2, MB02, Z3, Z4 e entrada futura do boss.
- Coletáveis obrigatórios existem e têm propriedades corretas:
  - `Heart.stage_id = 2`
  - `SubTank.collectible_type = 1`
  - `ArmorZaraHelmet.collectible_type = 3`, `armor_piece = "helmet"`
  - `SpreadZael.collectible_type = 4`, `ability_id = "spread"`

### Validação manual/bot

- Jogar rota principal sem poderes externos.
- Testar respawn em CP1, CP2 e CP3.
- Confirmar que paredes `"no_wall_grab"` não permitem wall slide/wall jump.
- Confirmar que terreno tem corpo visual para baixo e não parece plataforma fina solta.
- Confirmar que gates opcionais não bloqueiam a rota principal.

---

## Fora de Escopo

- Criar ou alterar Cryovex.
- Gerar sprites imediatamente durante brainstorming.
- Mudar o sistema global de progressão/save.
- Recriar tilesets do Stage 02, pois os assets já existem.
- Implementar uma solução genérica para todos os stages; o foco é Stage 02.
