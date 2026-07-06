# Skill: new-corridor

Use quando o usuário pedir para adicionar um corredor de transição a um stage complexo existente.

## Regra de ouro: todo corredor tem o MESMO tamanho e zoom do Corr1 do stage_00

**Não é "múltiplo de 64px genérico" — é o valor exato do stage_00, sempre:**

```
floor_size / ceil_size = Vector2(896, 64)   # 14 tiles
wall_l_size / wall_r_size = Vector2(64, 256)
interior height = 128px (2 tiles)
cam_zoom = 2.0
```

Isso vale pra QUALQUER corredor em QUALQUER stage. O que muda de um corredor
pro outro é só: `tileset`, posição (`floor_center`/`ceil_center`/`wall_*_center`,
`entry_x`/`exit_x`, `cam_center`) e — se a área disponível for menor que 896px —
**redistribuir o espaço adjacente** (encurtar a zona/plataforma que vem antes ou
depois) até 896px caber, nunca encolher o corredor em si. Ver
`stages/stage_01/stage_01_scene.gd::_build_z4_top` — o corredor pré-boss (`_corr_boss`)
foi corrigido de 660×64 (arbitrário) pra 896×64 exatamente por essa regra;
o espaço foi aberto encurtando `Z4PreR` de 704 pra 448, não encolhendo o corredor.

**Só stage_00 e stage_01 estão prontos hoje** — não mexer nos corredores de
stage_02/03/04 (ainda em WIP) só porque eles também desviam da regra; isso é
trabalho futuro, não deste fix.

## Informações a Coletar

Pergunte ao usuário (uma por vez se não fornecidas):

1. **stage_id** — ex: `stage_00`
2. **corridor_id** — ex: `Corr1`, `Corr2`
3. **tileset** — caminho do tileset (ex: `res://stages/stage_00/Stage_00T.png`) — **único campo que muda a "identidade visual" do corredor**
4. **glass_tex** — tileset do teto de glass (ex: `res://stage_00_glass.png`; `null` se não houver)
5. **entry_x / exit_x** — X absoluto das duas portas no mundo (a distância entre elas não precisa ser 896 — a porta fica em qualquer ponto dentro do corredor, ver padrão de offset abaixo)
6. **glass_mirror** — `false` para corredor normal (lateral à esquerda); `true` para corredor espelho (lateral à direita, ex: saída de sala de boss)
7. **cam_center** — centro da câmera enquanto o player traversa (X = centro do corredor; Y = centro vertical do interior)

**Offset padrão das portas dentro do corredor de 896px** (mesma proporção do
Corr1): `entry_x = wall_l_center.x + 32`; `exit_x = wall_r_center.x` (a porta de
saída fica exatamente na parede direita).

8. **checkpoint_index** — índice do checkpoint (1 ou 2); `save_checkpoint = false` para corredores sem checkpoint (ex: saída de miniboss)
9. **checkpoint_respawn_x** — X de respawn após o checkpoint (geralmente `exit_x + 128`)

## Geometria do Glass (se glass_tex != null)

### Modo Normal (`glass_mirror = false`) — lateral à ESQUERDA (entry side)

```
glass_lateral_x = entry_x - 54   # lateral estende ~64px antes do entry
glass_fill_x    = entry_x + 10   # fills começam logo após o lateral
glass_fill_cols = (exit_x - glass_fill_x) / 64  # cobre até a exit
```

Padrão CP1:
- lateral tile (1,0) em x=5480 (64px antes do entry x=5534)
- 14 fills (2,1) em x=5544 → 6440
- Largura total: 960px (14 tiles corredor + 1 tile lateral estendido)

### Modo Espelho (`glass_mirror = true`) — lateral à DIREITA (exit side)

```
glass_fill_x    = entry_x          # fills começam no entry
glass_fill_cols = (exit_x - entry_x) / 64   # 14 fills para 896px
glass_lateral_x = exit_x           # lateral (3,2) estende 64px DEPOIS do exit
```

Padrão CorrMB (espelho exato do CP1):
- 14 fills (2,1) em x=7326 → 8222 (= largura 896px do corredor)
- lateral tile **(3,2)** em x=8222 → 8286 (64px após o exit)

**IMPORTANTE:** No modo espelho, usar tile `(3,2)` diretamente — NUNCA flipar `(1,0)`.
O flip `Rect2(64, 0, -32, 32)` produz visualmente o tile `(1,1)` (Inner-TL), não `(3,2)` (LEFT face).
O `CorridorSection._draw_glass()` já usa `right_lat_src = Rect2(3*_SRC, 2*_SRC, _SRC, _SRC)` no branch `glass_mirror`. ✓

### cam_zoom

Sempre `2.0` (regra de ouro no topo do arquivo) — largura sempre 896px, então o
zoom nunca muda de corredor pra corredor. Não existe "corredor menor com zoom
maior"; se o espaço disponível é menor que 896px, encurta a geometria
adjacente (ver regra de ouro), não o corredor.

## Deslocamento de Geometria Adjacente

Ao criar um corredor espelho (saída de sala), se a geometria da zona seguinte estiver muito próxima do exit_x, é necessário deslocar **todos** os nós da zona seguinte.

**Regra do deslocamento:**
```
shift_needed = exit_x - min(left_edge de todos os elementos da zona)
```

**ATENÇÃO:** Calcular o `left_edge` de CADA elemento individualmente (`center_x - size_x/2`), não apenas do primeiro elemento da zona. Elementos com left_edge menor que o Floor/Pilar de referência precisam de shift maior. Ignorar isso causa overlap de plataformas com o corredor.

Após o deslocamento, verificar que todos os elementos que terminam em `left_edge < camera_right_edge` foram considerados (camera_right_edge = cam_center_x + 1920/(2*zoom)).

## Paredes Visuais Adjacentes

Ao abrir uma sala para criar a entrada do corredor (ex: desabilitar MiniBoss_RWall):
- **SEMPRE desabilitar collision**, não usar `queue_free()`
- `queue_free()` remove os tiles visuais da parede — o corredor fica sem a parede de entrada visual
- `node.get_node("CollisionShape2D").set_deferred("disabled", true)` preserva os tiles
- O `_draw_platforms()` desenha nós `MiniBoss_*` mesmo com collision disabled (exceção explícita no código)

## Documentação de Referência

- Template: `docs/corredor_template.md`
- Exemplo completo (Stage 00 Corr1): `docs/stage_00/corredor.md`
- Componente: `stages/corridor_section.gd`

---

## O que Gerar

### 1. Código a adicionar em `stages/<stage_id>/<stage_id>_scene.gd`

**Variável de instância:**
```gdscript
var _corr<n>: CorridorSection = null
```

**Em `_ready()`**, após `_setup_doors()`:
```gdscript
_setup_corr<n>_section()
```

**Função de setup — corredor normal (entry side):**
```gdscript
func _setup_corr<n>_section() -> void:
	_corr<n>                          = CorridorSection.new()
	_corr<n>.tileset                  = _TILESET
	_corr<n>.glass_tex                = _GLASS_TEX   # ou null
	_corr<n>.door_tex                 = _DOOR_TEX
	_corr<n>.floor_center             = Vector2(<cx>, 1120.0)
	_corr<n>.floor_size               = Vector2(<width>, 64.0)
	_corr<n>.ceil_center              = Vector2(<cx>, 928.0)   # remover se sem teto
	_corr<n>.ceil_size                = Vector2(<width>, 64.0) # ou Vector2.ZERO
	_corr<n>.entry_x                  = <entry_x>
	_corr<n>.exit_x                   = <exit_x>
	_corr<n>.cam_center               = Vector2(<cx>, 1024.0)
	_corr<n>.cam_zoom                 = 2.0
	_corr<n>.checkpoint_index         = <idx>
	_corr<n>.checkpoint_respawn_x     = <exit_x + 128>
	# Glass (omitir bloco se glass_tex = null)
	_corr<n>.glass_lateral_x          = <entry_x - 54>
	_corr<n>.glass_fill_x             = <entry_x + 10>
	_corr<n>.glass_fill_cols          = <cols>
	_corr<n>.camera_lock_requested.connect(_on_corr<n>_cam_lock)
	_corr<n>.player_traversed.connect(_on_corr<n>_traversed)
	add_child(_corr<n>)
	_corr<n>.setup(_player)
```

**Função de setup — corredor espelho (exit side, ex: saída de miniboss):**
```gdscript
func _setup_corr<n>_section() -> void:
	_corr<n>                          = CorridorSection.new()
	_corr<n>.tileset                  = _TILESET
	_corr<n>.glass_tex                = _GLASS_TEX
	_corr<n>.door_tex                 = _DOOR_TEX
	_corr<n>.glass_mirror             = true          # lateral à direita
	_corr<n>.floor_center             = Vector2(<entry_x + width/2>, 1120.0)
	_corr<n>.floor_size               = Vector2(<width>, 64.0)
	_corr<n>.ceil_size                = Vector2.ZERO  # teto geralmente ausente
	_corr<n>.entry_x                  = <entry_x>
	_corr<n>.exit_x                   = <exit_x>
	_corr<n>.entry_manual             = true          # abre após boss/miniboss
	_corr<n>.save_checkpoint          = false
	_corr<n>.heal_on_entry            = false
	_corr<n>.cam_center               = Vector2(<entry_x + width/2>, 1024.0)
	_corr<n>.cam_zoom                 = 2.0
	# Glass espelho: fills cobrem largura toda, lateral (3,2) 64px após exit
	_corr<n>.glass_fill_x             = <entry_x>
	_corr<n>.glass_fill_cols          = <width / 64>  # ex: 896/64 = 14
	_corr<n>.glass_lateral_x          = <exit_x>
	_corr<n>.camera_lock_requested.connect(_on_corr<n>_cam_lock)
	_corr<n>.player_traversed.connect(_on_corr<n>_traversed)
	add_child(_corr<n>)
	_corr<n>.setup(_player)
```

**Callbacks:**
```gdscript
func _on_corr<n>_cam_lock(center: Vector2, zoom: float) -> void:
	_camera_locked   = true
	_camera_target   = center
	_camera_zoom_tgt = zoom

func _on_corr<n>_traversed() -> void:
	_camera_locked = false  # ou lógica pós-corredor
```

**Abrir corredor após evento (ex: miniboss derrotado):**
```gdscript
func _on_<boss>_defeated() -> void:
	var wall := get_node_or_null("<WallNode>")
	if wall:
		wall.get_node("CollisionShape2D").set_deferred("disabled", true)  # NÃO queue_free!
		queue_redraw()
	if _corr<n> != null:
		_corr<n>.open_entry()
```

### 2. Documentação a criar

Criar `docs/<stage_id>/corr<n>.md` usando o template em `docs/corredor_template.md`.
Preencher todos os campos `{{...}}` com os valores coletados.

---

## Checklist Pós-Criação

- [ ] `CorridorSection` instanciada e adicionada ao stage
- [ ] Sinais conectados: `camera_lock_requested`, `player_traversed` (+ `checkpoint_triggered`, `player_healed` se save_checkpoint=true)
- [ ] `cam_zoom` adequado para a largura do corredor (tabela acima)
- [ ] Glass: modo normal usa (1,0) no entry; modo espelho usa (3,2) no exit via `glass_lateral_x = exit_x`
- [ ] Glass lateral tem `add_to_group("no_wall_grab")` — o `CorridorSection._add_glass_lateral_collision()` já faz isso automaticamente; confirmar se o corredor usa `glass_tex != null`
- [ ] Geometria adjacente não invade o corredor (verificar left_edges individuais)
- [ ] Paredes visuais: `set_deferred("disabled", true)` em vez de `queue_free()`
- [ ] Documento `docs/<stage_id>/corr<n>.md` criado
- [ ] Testado: player atravessa, câmera bloqueia/desbloqueia, visual fechado sem geometria externa visível; player NÃO agarra o vidro

## Paredes Lisas (no_wall_grab)

O vidro do corredor é automaticamente marcado com o grupo `"no_wall_grab"` pelo `CorridorSection`. Para criar outras paredes lisas (gelo, metal polido, etc.) em qualquer stage:

```gdscript
meu_static_body.add_to_group("no_wall_grab")
```

Efeito: o player é bloqueado pela colisão sólida, mas não ativa wall grab nem wall jump, e cai com gravidade plena (sem cap de 60px/s). Não requer nós extras nem mudança de collision layers.
