# Template — Corredor de Transição

> Copie este arquivo para `docs/<stage>/corr<N>.md`, preencha os campos marcados com `{{...}}` e remova esta instrução.
>
> **Implementação:** use `stages/corridor_section.gd` (Node2D reutilizável). Veja a seção **Uso do CorridorSection** em `docs/stage_00/corredor.md` para exemplo completo de instância e conexão de sinais.

---

## Metadados

```yaml
corridor_id:   {{CORR_ID}}          # ex: Corr1, Corr2
stage:         {{STAGE_ID}}          # ex: stage_00
zona_origem:   {{ZONE_FROM}}         # ex: Zona 1
zona_destino:  {{ZONE_TO}}           # ex: Sala do MiniBoss
tileset:       {{TILESET_PATH}}      # ex: stages/stage_00/Stage_00T.png
glass_tileset: {{GLASS_PATH}}        # ex: stage_00_glass.png  (null se não tiver)
```

---

## Geometria

| Nó | Posição (center) | Tamanho | Função |
|----|-----------------|---------|--------|
| `{{ID}}_Floor`  | ({{X}}, {{Y}}) | {{W}} × {{H}} | Chão |
| `{{ID}}_Ceil`   | ({{X}}, {{Y}}) | {{W}} × {{H}} | Teto (pode ser desabilitado) |
| `{{ID}}_Wall_L` | ({{X}}, {{Y}}) | {{W}} × {{H}} | Parede esquerda |
| `{{ID}}_Wall_R` | ({{X}}, {{Y}}) | {{W}} × {{H}} | Parede direita |

**Extensão horizontal:** x = {{X_START}} → {{X_END}} ({{WIDTH}} px, {{TILE_COUNT}} tiles de 64 px)  
**Altura interior:** y = {{Y_TOP}} → {{Y_BOT}} ({{HEIGHT}} px)

### Observações de geometria
> *(colisões desabilitadas, teto removido, peças especiais, etc.)*

---

## Portas de Checkpoint

| Constante | X | Função |
|-----------|---|--------|
| `{{ENTRY_CONST}}` | {{ENTRY_X}} | Entrada (vindo de {{ZONE_FROM}}) |
| `{{EXIT_CONST}}`  | {{EXIT_X}}  | Saída (indo para {{ZONE_TO}}) |

### Porta de Entrada — Sequência
1. Porta abre, player travado (`door_locked = true`)
2. {{CHECKPOINT_ACTION}} *(ex: checkpoint salvo, HP restaurado)*
3. Player caminha automaticamente até x = {{ENTRY_X + 96}}
4. Porta fecha; câmera trava em `{{CAM_CONST}} = ({{CAM_X}}, {{CAM_Y}})`, zoom {{CAM_ZOOM}}×

### Porta de Saída — Sequência
1. Porta abre, player caminha até x = {{EXIT_X + 96}}
2. Porta fecha
3. {{EXIT_ACTION}} *(ex: câmera segue próximo trigger, câmera livre)*

---

## Câmera

```
CAM_CENTER = Vector2({{CAM_X}}, {{CAM_Y}})
CAM_ZOOM   = {{CAM_ZOOM}}
```

> Largura visível = 1920 / zoom. Ajuste o zoom para que o corredor inteiro caiba na tela.

---

## Teto de Glass *(omita esta seção se não houver glass)*

Tileset: `{{GLASS_PATH}}`

| Elemento | X inicial | Tile | Colunas |
|----------|-----------|------|---------|
| Lateral  | {{LAT_X}} | (1,0) | 1 |
| Fill     | {{FILL_X_START}} | (2,1) | {{FILL_COLS}} → x = {{FILL_X_END}} |

**Altura:** {{COL_ROWS}} tiles × 64 px = {{COL_PX}} px, de y = {{COL_TOP}} até y = {{COL_BOT}}

### Colisão do Glass (`StaticBody2D`)

```
center_x = {{GLASS_COL_CX}}
width    = 128 px
height   = {{GLASS_COL_H}} px  (y = {{GLASS_COL_TOP}} → {{GLASS_COL_BOT}})
layer    = 1
```

---

## Destino — Sala / Próxima Zona

### Trigger de Entrada

```
position = ({{TRIGGER_X}}, {{TRIGGER_Y}})
size     = {{TRIGGER_W}} × {{TRIGGER_H}}
mask     = 2 (player)
```

### Sequência ao entrar no trigger
1. {{TRIGGER_ACTION_1}}
2. Aguarda player chegar a x = {{SEAL_X}}
3. {{SEAL_ACTION}} *(ex: LWall ativada, sala selada)*
4. Câmera: `{{DEST_CAM_CONST}} = ({{DEST_CAM_X}}, {{DEST_CAM_Y}})`, zoom {{DEST_CAM_ZOOM}}×

### Geometria da Sala de Destino

| Nó | Posição (center) | Tamanho |
|----|-----------------|---------|
| `{{DEST_ID}}_Floor` | ({{X}}, {{Y}}) | {{W}} × {{H}} |
| `{{DEST_ID}}_Ceil`  | ({{X}}, {{Y}}) | {{W}} × {{H}} |
| `{{DEST_ID}}_LWall` | ({{X}}, {{Y}}) | {{W}} × {{H}} |
| `{{DEST_ID}}_RWall` | ({{X}}, {{Y}}) | {{W}} × {{H}} |

### Após saída / derrota
1. {{POST_ACTION}} *(ex: RWall desativada, câmera livre)*
2. Câmera desbloqueia quando player passa x = {{UNLOCK_X}}

---

## Fluxo Completo

```
{{ZONE_FROM}}
  → Porta {{ENTRY_CONST}} (x={{ENTRY_X}}) — {{ENTRY_EFFECT}}
    → Corredor {{CORR_ID}} — {{CORR_DESCRIPTION}}
      → Porta {{EXIT_CONST}} (x={{EXIT_X}}) — {{EXIT_EFFECT}}
        → Trigger (x={{TRIGGER_X}}) — {{TRIGGER_EFFECT}}
          → {{ZONE_TO}}
            → {{DEST_RESOLUTION}} — {{POST_EFFECT}}
              → {{NEXT_ZONE}}
```

---

## Arquivos Relevantes

| Arquivo | Conteúdo |
|---------|----------|
| `stages/{{STAGE_ID}}/{{STAGE_ID}}_scene.gd` | Lógica de portas, glass, triggers, câmera |
| `stages/{{STAGE_ID}}/{{STAGE_ID}}.tscn` | Nós de geometria |
| `stages/checkpoint_door.gd` | Comportamento das portas (shared) |
| `{{GLASS_PATH}}` | Tileset do teto de glass |
| `{{ENEMY_SCRIPT}}` | Script do inimigo na sala de destino |
