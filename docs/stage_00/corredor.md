# Stage 00 — Corredor 1 (Corr1)

> Instância de `docs/corredor_template.md`  
> Componente reutilizável: `stages/corridor_section.gd`

---

## Metadados

```yaml
corridor_id:   Corr1
stage:         stage_00
zona_origem:   Zona 1
zona_destino:  Sala do MiniBoss
tileset:       stages/stage_00/Stage_00T.png
glass_tileset: stage_00_glass.png
```

---

## Uso do CorridorSection

Para reutilizar em outra stage, instancie `CorridorSection`, ajuste os `@export` e conecte os sinais:

```gdscript
var corr := CorridorSection.new()
corr.tileset           = preload("res://stages/stage_XX/Stage_XXT.png")
corr.glass_tex         = preload("res://stage_XX_glass.png")  # null se não houver glass
corr.entry_x           = 5566.0
corr.exit_x            = 6430.0
corr.cam_center        = Vector2(5982, 1024)
corr.cam_zoom          = 2.0
corr.checkpoint_index  = 1
add_child(corr)
corr.setup(_player)

corr.camera_lock_requested.connect(_on_camera_lock)
corr.checkpoint_triggered.connect(StageManager.save_checkpoint)
corr.player_healed.connect(func(): _player.heal(_player.max_hp))
corr.player_traversed.connect(_on_corr1_traversed)
```

---

## Geometria

| Nó | Posição (center) | Tamanho | Função |
|----|-----------------|---------|--------|
| `Corr1_Floor`  | (5982, 1120) | 896 × 64  | Chão |
| `Corr1_Ceil`   | (5982, 928)  | 896 × 64  | **Desabilitado** — substituído pelo glass |
| `Corr1_Wall_L` | (5534, 1024) | 64 × 256  | Parede esquerda (colisão desabilitada) |
| `Corr1_Wall_R` | (6430, 1024) | 64 × 256  | Parede direita (colisão desabilitada) |

**Extensão horizontal:** x = 5534 → 6430 (896 px, 14 tiles de 64 px)  
**Altura interior:** y = 960 → 1088 (128 px)

### Observações de geometria
- `Corr1_Ceil` desabilitado em `_ready()` — o glass visual substitui o teto físico.
- As paredes L/R têm colisão desabilitada; as portas de checkpoint fazem a barreira.
- `MiniBoss_LWall` renderizada desde o início com `skip_bottom_corner = true` para face interna contínua acima da porta.

---

## Portas de Checkpoint

| Constante | X | Função |
|-----------|---|--------|
| `CP1_ENTRY_X` | 5566 | Entrada (vindo da Zona 1) |
| `CP1_EXIT_X`  | 6430 | Saída (indo para a Sala do MiniBoss) |

### Porta de Entrada — Sequência
1. Porta abre, player travado (`door_locked = true`)
2. Checkpoint salvo com respawn em x = 6558; HP restaurado ao máximo
3. Player caminha automaticamente até x = 5662
4. Porta fecha; câmera trava em `_CORR1_CAM_CENTER = (5982, 1024)`, zoom 2×

### Porta de Saída — Sequência
1. Porta abre, player caminha até x = 6526
2. `door_walk_speed` zerado, porta fecha
3. Sinal `player_traversed` emitido → trigger do MiniBoss assume o controle

---

## Câmera

```
_CORR1_CAM_CENTER = Vector2(5982.0, 1024.0)
_CORR1_CAM_ZOOM   = 2.0
```

Largura visível = 1920 / 2 = 960 px — cobre o corredor de 896 px inteiro com folga.

---

## Teto de Glass

Tileset: `stage_00_glass.png` (4 × 4 tiles de 32 px)

| Elemento | X inicial | Tile  | Colunas |
|----------|-----------|-------|---------|
| Lateral  | 5480      | (1,0) | 1 |
| Fill     | 5544      | (2,1) | 14 → x = 6440 |

**Altura:** 33 tiles × 64 px = 2112 px, de y = −1152 até y = 960

### Colisão do Glass (`Glass_Lateral` — StaticBody2D)

```
center_x = 5544
width    = 128 px  (x = 5480 → 5608)
height   = 2048 px (y = −1280 → 768)
layer    = 1
```

---

## Destino — Sala do MiniBoss

### Trigger de Entrada

```
position = (6470, 1024)
size     = 80 × 256
mask     = 2 (player)
```

### Sequência ao entrar no trigger
1. MiniBoss instanciado (deferred) em x = 7000
2. Aguarda player chegar a x = 6490
3. `MiniBoss_LWall` colisão ativada — sala selada
4. Câmera: `_MINIBOSS_CAM_CENTER = (6878, 896)`, zoom 2×

### Geometria da Sala do MiniBoss

| Nó | Posição (center) | Tamanho |
|----|-----------------|---------|
| `MiniBoss_Floor` | (6878, 1120) | 896 × 64  |
| `MiniBoss_Ceil`  | (6878, 672)  | 896 × 64  |
| `MiniBoss_LWall` | (6430, 896)  | 64 × 512  |
| `MiniBoss_RWall` | (7326, 896)  | 64 × 512  |

### Após derrota do MiniBoss
1. `MiniBoss_RWall` colisão desabilitada — saída liberada
2. Câmera desbloqueia quando player passa x = 7358

---

## Fluxo Completo

```
Zona 1
  → Porta CP1_ENTRY (x=5566) — checkpoint salvo, HP cheio, câmera fixa 2×
    → Corredor Corr1 — teto de glass, câmera estática
      → Porta CP1_EXIT (x=6430) — player atravessa automaticamente
        → Trigger MiniBoss (x=6470) — sala sela, câmera muda
          → Sala do MiniBoss
            → MiniBoss derrotado — RWall abre, câmera livre
              → Zona 2 (após x=7358)
```

---

## Arquivos Relevantes

| Arquivo | Conteúdo |
|---------|----------|
| `stages/corridor_section.gd` | **Componente reutilizável** — toda a lógica de corredor |
| `stages/stage_00/stage_00_scene.gd` | Lógica específica do Stage 00 (usa o componente) |
| `stages/stage_00/stage_00.tscn` | Nós de geometria Corr1_* e MiniBoss_* |
| `stages/checkpoint_door.gd` | Comportamento das portas (shared) |
| `stage_00_glass.png` | Tileset do teto de glass |
| `characters/enemies/enemy_miniboss.gd` | IA do MiniBoss (PATROL/CHARGE/STOMP/RECOVER) |
