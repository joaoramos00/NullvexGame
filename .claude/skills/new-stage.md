# Skill: new-stage

Use quando o usuário pedir para criar uma nova fase.

## Informações a Coletar

1. **stage_id** — int (próximo disponível após 11, ou novo)
2. **nome descritivo** — ex: `volcano`, `ice_cave`
3. **boss** — nome do boss (deve existir em `characters/bosses/`)
4. **estilo** — `simple` (usa stage_scene.gd) | `complex` (GD customizado com zonas/doors)
5. **platform_color** — Color das plataformas
6. **tema visual** — descrição do cenário para gerar `_draw()` (apenas para `complex`)

## Arquivos a Criar

**Simple:**
- `stages/stage_<id>/stage_<id>.tscn`
- `tests/test_stage_<id>.gd`
- `tests/test_stage_<id>.tscn`

**Complex:**
- `stages/stage_<id>/stage_<id>.tscn`
- `stages/stage_<id>/stage_<id>_scene.gd`
- `tests/test_stage_<id>.gd`
- `tests/test_stage_<id>.tscn`

---

## Template Simple

Baseado em `stages/stage_01/stage_01.tscn`. Adaptar `<id>`, `<NomePascal>`, `<BossNomePascal>`, `uid://boss_<nome>`, `platform_color`, posições.

`stages/stage_<id>/stage_<id>.tscn`:
```
[gd_scene format=3 uid="uid://stage_<id>"]

[ext_resource type="Script" path="res://stages/stage_scene.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://stage_controller" path="res://stages/stage_controller.tscn" id="2_sc"]
[ext_resource type="PackedScene" uid="uid://checkpoint" path="res://stages/checkpoint.tscn" id="3_cp"]
[ext_resource type="PackedScene" uid="uid://collectible" path="res://stages/collectible.tscn" id="4_col"]
[ext_resource type="PackedScene" uid="uid://hud" path="res://ui/hud.tscn" id="5_hud"]
[ext_resource type="PackedScene" uid="uid://pause_menu" path="res://ui/pause_menu.tscn" id="6_pause"]
[ext_resource type="PackedScene" uid="uid://game_over" path="res://ui/game_over.tscn" id="7_gameover"]
[ext_resource type="PackedScene" uid="uid://stage_complete" path="res://ui/stage_complete.tscn" id="8_scom"]
[ext_resource type="PackedScene" uid="uid://<boss_nome>" path="res://characters/bosses/<boss_nome>.tscn" id="9_boss"]
[ext_resource type="PackedScene" uid="uid://enemy_base" path="res://characters/enemies/enemy_base.tscn" id="10_grunt"]
[ext_resource type="PackedScene" uid="uid://enemy_flyer" path="res://characters/enemies/enemy_flyer.tscn" id="11_flyer"]

[sub_resource type="RectangleShape2D" id="FloorA"]
size = Vector2(800, 40)

[sub_resource type="RectangleShape2D" id="FloorB"]
size = Vector2(600, 40)

[sub_resource type="RectangleShape2D" id="FloorPre"]
size = Vector2(500, 40)

[sub_resource type="RectangleShape2D" id="FloorBoss"]
size = Vector2(1200, 40)

[sub_resource type="RectangleShape2D" id="P1"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="P2"]
size = Vector2(180, 20)

[sub_resource type="RectangleShape2D" id="P3"]
size = Vector2(200, 20)

[sub_resource type="RectangleShape2D" id="P4"]
size = Vector2(220, 20)

[node name="Stage<Id>" type="Node2D"]
platform_color = <platform_color>
script = ExtResource("1_script")

[node name="PlayerSpawn" type="Node2D" parent="."]
position = Vector2(200, 760)

[node name="StageController" parent="." instance=ExtResource("2_sc")]

[node name="Checkpoint1" parent="." instance=ExtResource("3_cp")]
position = Vector2(2000, 850)
checkpoint_index = 1

[node name="Checkpoint2" parent="." instance=ExtResource("3_cp")]
position = Vector2(3500, 850)
checkpoint_index = 2

[node name="FloorA" type="StaticBody2D" parent="."]
position = Vector2(400, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorA"]
shape = SubResource("FloorA")

[node name="FloorB" type="StaticBody2D" parent="."]
position = Vector2(1900, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorB"]
shape = SubResource("FloorB")

[node name="FloorPre" type="StaticBody2D" parent="."]
position = Vector2(3500, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorPre"]
shape = SubResource("FloorPre")

[node name="FloorBoss" type="StaticBody2D" parent="."]
position = Vector2(4700, 920)
[node name="CollisionShape2D" type="CollisionShape2D" parent="FloorBoss"]
shape = SubResource("FloorBoss")

[node name="Plat1" type="StaticBody2D" parent="."]
position = Vector2(850, 820)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat1"]
shape = SubResource("P1")

[node name="Plat2" type="StaticBody2D" parent="."]
position = Vector2(1100, 760)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat2"]
shape = SubResource("P2")

[node name="Plat3" type="StaticBody2D" parent="."]
position = Vector2(1350, 700)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat3"]
shape = SubResource("P3")

[node name="Plat4" type="StaticBody2D" parent="."]
position = Vector2(1650, 640)
[node name="CollisionShape2D" type="CollisionShape2D" parent="Plat4"]
shape = SubResource("P4")

[node name="<BossNomePascal>" parent="." instance=ExtResource("9_boss")]
position = Vector2(4600, 760)
arena_left = 4100.0
arena_right = 5100.0
arena_floor = 900.0

[node name="Grunt1" parent="." instance=ExtResource("10_grunt")]
position = Vector2(850, 790)

[node name="Grunt2" parent="." instance=ExtResource("10_grunt")]
position = Vector2(1350, 670)

[node name="Grunt3" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2600, 670)

[node name="Grunt4" parent="." instance=ExtResource("10_grunt")]
position = Vector2(2900, 730)

[node name="Flyer1" parent="." instance=ExtResource("11_flyer")]
position = Vector2(1700, 600)

[node name="Heart" parent="." instance=ExtResource("4_col")]
position = Vector2(1350, 660)
stage_id = <id>

[node name="HUD" parent="." instance=ExtResource("5_hud")]
[node name="PauseMenu" parent="." instance=ExtResource("6_pause")]
[node name="GameOver" parent="." instance=ExtResource("7_gameover")]
[node name="StageComplete" parent="." instance=ExtResource("8_scom")]

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_top = 0
limit_bottom = 1080
limit_right = 5300
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

---

## Template Complex

Para stage complexo, usar `stage_00_scene.gd` e `stage_00.tscn` como referência direta:
- Ler `stages/stage_00/stage_00_scene.gd` e `stages/stage_00/stage_00.tscn`
- Adaptar: id, nome, posições de zonas, cores do `_draw_background()`, boss
- Para corredores de transição entre zonas: usar `CorridorSection` (`stages/corridor_section.gd`) — ver skill `new-corridor`
- Para paredes lisas (vidro, gelo, metal polido) onde o player não deve agarrar: `body.add_to_group("no_wall_grab")` — bloqueia fisicamente mas desativa wall grab/jump e cap de queda; ver grupo `no_wall_grab` em CLAUDE.md

Estrutura mínima do GD customizado:
```gdscript
extends Node2D

const ZAEL_SCENE   := preload("res://characters/ranged/zael.tscn")
const ZARA_SCENE   := preload("res://characters/melee/zara.tscn")
const _GRUNT_SCENE := preload("res://characters/enemies/enemy_base.tscn")
const _FLYER_SCENE := preload("res://characters/enemies/enemy_flyer.tscn")
const _BOSS_SCENE  := preload("res://characters/bosses/<boss_nome>.tscn")
const _DOOR_SCENE  := preload("res://stages/checkpoint_door.tscn")

# Posições por zona (adaptar ao layout)
const ZONE1_GRUNTS := [Vector2(400, 520), Vector2(700, 520)]
const ZONE1_FLYERS := [Vector2(550, 380)]
const ZONE2_GRUNTS := [Vector2(3500, 204), Vector2(3900, 204)]
const ZONE2_FLYERS := [Vector2(3700, 160)]
const ZONE3_GRUNTS := [Vector2(6100, 520), Vector2(6800, 460)]
const ZONE3_FLYERS := [Vector2(6600, 400)]

const BOSS_SPAWN   := Vector2(9100, 400)
const CP1_ENTRY_X  := 2900.0
const CP1_EXIT_X   := 3200.0
const CP2_ENTRY_X  := 8000.0
const CP2_EXIT_X   := 8300.0

# Copiar _ready, _process, _unhandled_input, _spawn_player, _setup_doors,
# _on_cp1_entry_opened, _on_cp2_entry_opened, _on_boss_door_opened, _spawn_boss,
# _setup_zone_triggers, _make_zone_trigger, zone entered/exited callbacks,
# _spawn_zone_enemies, _get_zone_array, _respawn_zone, _clear_zone_enemies
# de stage_00_scene.gd e adaptar boss_id e posições.
#
# Adaptar _draw_background() com as cores e tema do novo stage.
```

---

## Template de Teste

`tests/test_stage_<id>.gd`:
```gdscript
extends Node

func _ready() -> void:
    test_scene_loads()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_scene_loads() -> void:
    var scene := load("res://stages/stage_<id>/stage_<id>.tscn")
    assert(scene != null, "tscn deve existir")
    print("PASS: scene_loads")
```

`tests/test_stage_<id>.tscn`:
```
[gd_scene format=3]

[ext_resource type="Script" path="res://tests/test_stage_<id>.gd" id="1_script"]

[node name="TestStage<Id>" type="Node"]
script = ExtResource("1_script")
```

## Pós-Criação

1. Rodar: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_<id>.tscn`
2. Verificar `ALL TESTS PASSED`
3. Commitar: `git add stages/stage_<id>/ tests/test_stage_<id>.* && git commit -m "feat: nova fase stage_<id> (<nome>)"`

---

## Sistema de Tiles — Alinhamento de Bordas (Stage Complexo)

> Referência obrigatória ao implementar `_draw_platform_tiles()` ou qualquer tileset próprio num stage complexo.

### Tileset: `Stage_00T.png`

Grade **4×4** de tiles de **32×32 px** fonte, renderizados a **64×64 game units** (`_SRC_TS = 32`, `_TS = 64`).
Câmera zoom 2.2× → 1 game unit = 2.2 screen px; 1 src px = 4.4 screen px.

```
Col →  0          1          2          3
Row 0: BOT+LEFT   BOT+RIGHT  TOP+LEFT†  TOP
Row 1: LEFT*      RIGHT*     FILL       RIGHT†
Row 2: TOP+RIGHT† BOTTOM     TOP+RIGHT  LEFT†
Row 3: –          BOT+RIGHT† –          TOP+LEFT†
```
`†` = tiles de corredor/quarto (`_draw_room_tiles`), não usados em plataformas.

### Conteúdo sólido por tile (análise de pixel — canal alpha médio por quadrante)

| Tile (x,y) | Label | TL | TR | BL | BR | Sólido em |
|---|---|---|---|---|---|---|
| (3,0) | TOP | 0 | 0 | 254 | 254 | metade inferior |
| (1,3) | BOT+RIGHT | 0 | 0 | 0 | 222 | quadrante inf-dir |
| (0,0) | BOT+LEFT | 0 | 0 | 221 | 0 | quadrante inf-esq |
| (1,0) | RIGHT (parede esq) | 0 | 213 | 0 | 213 | metade direita |
| (3,2) | LEFT (parede dir) | 214 | 0 | 214 | 0 | metade esquerda |
| (2,1) | FILL | 255 | 255 | 255 | 255 | tudo |
| (1,2) | BOTTOM | 220 | 220 | 0 | 0 | metade superior |
| (3,3) | TOP+LEFT (canto inf-dir) | 175 | 0 | 0 | 0 | quadrante sup-esq |
| (0,2) | TOP+RIGHT (canto inf-esq) | 0 | 175 | 0 | 0 | quadrante sup-dir |

### Por que há gap entre tile e física

Nenhum tile de borda ocupa a largura/altura **completa** de 64 game units.
O conteúdo sólido está sempre em **metade** (ou 1 quadrante) do tile.
Sem correção, a física cobre X pixels onde não há pixel visível.

#### Eixo Y (superfície superior)
O tile `TOP (3,0)` tem sólido apenas na **metade inferior** da sua área de 64 units.
Sem shift, o topo da física ficaria invisível pelos 32 units superiores do tile.

**Correção:** `dy = rect.position.y + row * ts - src_ts`
O shift de `-src_ts (-32)` sobe o tile inteiro 32 units, fazendo o sólido inferior coincidir com a face física superior. Aplica a **todas as linhas** — garante continuidade vertical sem gaps entre tiles adjacentes.

#### Eixo X (bordas laterais)
Os tiles de borda (`(1,0)`, `(3,2)`, cantos) têm sólido em apenas **metade** da largura.
Sem correção, há 32 game units de gap entre borda física e início do visual.

**Correção para `col == 0` (borda física esquerda):**
```gdscript
dx -= src_ts  # move tile 32 units à esquerda
# A metade sólida direita do tile agora coincide com a borda física esquerda.
# Preenche gap de 32 units com metade esquerda do tile de fill correto:
draw_texture_rect_region(_TILESET,
    Rect2(rect.position.x + ts / 2.0, dy, ts / 2.0, dh),
    Rect2(fill.x * src_ts, fill.y * src_ts, src_ts / 2, src_ts))
```

**Correção para `col == cols - 1` (borda física direita):**
```gdscript
dx += src_ts  # move tile 32 units à direita
# A metade sólida esquerda do tile agora coincide com a borda física direita.
# O clamp natural de dw = minf(ts, ...) exibe apenas os 32 units sólidos.
# Preenche gap de 32 units com metade direita do tile de fill correto:
draw_texture_rect_region(_TILESET,
    Rect2(rect.position.x + (cols - 1) * ts, dy, ts / 2.0, dh),
    Rect2(fill.x * src_ts + src_ts / 2, fill.y * src_ts, src_ts / 2, src_ts))
```

**Escala do gap fill:** `16 src px → 32 game units = 2× por pixel` — idêntica à escala das tiles normais (`32 src px → 64 game units`). Garantia de que o pixel art não aparece nem menor nem maior que o resto.

### Implementação canônica

Copiar estas duas funções de `stages/stage_00/stage_00_scene.gd` para qualquer stage complexo com tileset próprio:

```gdscript
func _draw_platform_tiles(rect: Rect2) -> void:
    var ts     := _TS
    var src_ts := _SRC_TS
    var cols := ceili(rect.size.x / ts)
    var rows := ceili(rect.size.y / ts)
    for row in rows:
        for col in cols:
            var tile := _tile_at(col, cols, row, rows)
            var dx := rect.position.x + col * ts
            var dy := rect.position.y + row * ts - src_ts  # alinha face sólida com física
            var dh := minf(ts, rect.position.y + rect.size.y - dy)
            if cols > 1:
                var fill := _gap_fill_tile(row, rows)
                if col == 0:
                    dx -= src_ts
                    draw_texture_rect_region(_TILESET,
                        Rect2(rect.position.x + ts / 2.0, dy, ts / 2.0, dh),
                        Rect2(fill.x * src_ts, fill.y * src_ts, src_ts / 2, src_ts))
                elif col == cols - 1:
                    dx += src_ts
                    draw_texture_rect_region(_TILESET,
                        Rect2(rect.position.x + (cols - 1) * ts, dy, ts / 2.0, dh),
                        Rect2(fill.x * src_ts + src_ts / 2, fill.y * src_ts, src_ts / 2, src_ts))
            var dw := minf(ts, rect.position.x + rect.size.x - dx)
            var src := Rect2(tile.x * src_ts, tile.y * src_ts, src_ts * dw / ts, src_ts * dh / ts)
            draw_texture_rect_region(_TILESET, Rect2(dx, dy, dw, dh), src)

func _gap_fill_tile(row: int, rows: int) -> Vector2i:
    if row == 0:        return Vector2i(3, 0)  # TOP  — linha visual superior
    if row == rows - 1: return Vector2i(1, 2)  # BOTTOM — linha visual inferior
    return Vector2i(2, 1)                       # FILL — interior
```

### Mapeamento `_tile_at` — convenção de eixos

`is_left = col == cols - 1` (última coluna = borda **visual direita**)
`is_right = col == 0` (primeira coluna = borda **visual esquerda**)
`is_top = row == rows - 1` (última linha = borda **visual inferior**)
`is_bottom = row == 0` (primeira linha = borda **visual superior**)

Os nomes estão **invertidos** em relação ao espaço visual — não alterar sem rever toda a tabela de tiles.

### Formas compostas (marching-squares / heightfield)

Para formas que **não** são um retângulo simples — ex.: piso reto + plataforma
elevada + piso reto (modo "Piso+Plat" do ImgDebug), terreno com degraus, etc. —
não dá para usar `_tile_at` direto. Trate como um **heightfield** (cada coluna tem
um topo sólido) e escolha o tile por célula a partir das **faces expostas**
(vizinho daquele lado é vazio). Esta tabela é empírica e respeita os eixos
invertidos do tileset (validada visualmente — a primeira versão saiu com paredes
e junções espelhadas justamente por ignorar a inversão):

| Faces expostas (screen-space) | Tile | Nome |
|---|---|---|
| só topo | `(3,0)` | TOP (superfície) |
| só base | `(1,2)` | BOTTOM |
| só esquerda | `(1,0)` | parede **esquerda** visual |
| só direita | `(3,2)` | parede **direita** visual |
| topo + esquerda | `(1,3)` | canto sup-esq |
| topo + direita | `(0,0)` | canto sup-dir |
| base + esquerda | `(0,2)` | canto inf-esq |
| base + direita | `(3,3)` | canto inf-dir |
| nenhuma, diagonal sup-esq vazia | `(1,1)` | côncavo (entalhe sup-esq) |
| nenhuma, diagonal sup-dir vazia | `(2,0)` | côncavo (entalhe sup-dir) |
| nenhuma (interior) | `(2,1)` | FILL |

**Armadilha confirmada:** parede esquerda usa `(1,0)` e direita usa `(3,2)` —
ao contrário do que os nomes "Lateral esquerda/direita" sugerem. O mesmo
espelhamento vale para as junções côncavas. Sempre derivar do `_tile_at`/`_room_at`
(que são visualmente confirmados), nunca do raciocínio de máscara "natural".
Implementação de referência: `_fp_tile()` em `ui/img_debug.gd`.

### Checklist ao criar plataformas

- [ ] `_TS = 64`, `_SRC_TS = 32` — nunca misturar as duas escalas
- [ ] Usar `_draw_platform_tiles` para **qualquer** `StaticBody2D` retangular (chão, plataforma, pilar)
- [ ] Usar `_draw_room_tiles` apenas para peças de corredor/sala (`_Ceil`, `_Floor`, `_Wall_L/R`)
- [ ] Testar visualmente com câmera zoom 2.2× — gap de 32 game units = ~70 px na tela
- [ ] Plataforma de **1 linha** e **múltiplas linhas** cobrem casos diferentes; ambas são tratadas pelo mesmo código
- [ ] A borda **inferior** da última linha pode ter até 32 game units de gap com o fundo da física (não visível ao jogador; aceitável para plataformas no chão)
