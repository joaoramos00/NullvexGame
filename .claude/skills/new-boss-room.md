# Skill: new-boss-room

Use quando o usuário pedir para criar (ou corrigir) a sala/arena de um boss ou
miniboss — o destino de um corredor de transição (`CorridorSection`, ver skill
`new-corridor`).

## Regra de ouro: tudo em múltiplos de 64px

**Todo** floor/ceil/parede da sala — largura E altura — deve ser múltiplo de
64px (o tamanho do tile). Isso vale tanto pra sala quanto pro corredor que leva
até ela.

Por quê: o piso/teto/parede é desenhado em blocos de 64px (`ceili(size/64)`
colunas/linhas). Se a medida não fecha exata, a última coluna/linha vira um
tile cortado (uma fatia fina em vez de um tile inteiro) — ou, no caso de um
renderizador por grid como `_draw_boss_room` (`round((bottom-top)/ts)`), a
grade desenhada fica alguns pixels desalinhada da colisão real (chão/teto
parecem "flutuar" fora do lugar). Os dois sintomas já aconteceram no shaft Z4
do stage 01 (corredor 660×64/64×264 fora da grade + sala do boss com 300px de
altura interior, arredondada pra 448 no desenho) e foram corrigidos calculando
tudo em múltiplos de 64 — ver `stages/stage_01/stage_01_scene.gd::_build_z4_top`
e a constante `_BOSS_CEIL_TOP` como exemplo do "antes/depois".

**Continuidade com o corredor:** a superfície do piso (e do teto, se houver)
deve ser a MESMA coordenada Y do fim do corredor até o começo da sala — sem
degrau nem vão. Se a sala for mais funda que o corredor (arena maior pra
combate), o degrau deve ser coberto por um bloco de soleira (ver
`BossThreshold` no stage 01), nunca deixado como buraco/vão aberto.

## Dois padrões de entrada

### A — Sala selada (RECOMENDADO; stage_00, `MiniBoss_*`)

Paredes de altura cheia (chão até teto); a esquerda (ou a que dá pro corredor)
começa com a colisão **desabilitada**; ativa quando o player entra (sela a
sala, ele não foge); desativa de novo quando o boss morre (libera a saída).

- Construção: `StaticBody2D` simples (autoral no `.tscn` OU via `_z2_static`),
  **sem meta nenhuma** — cai no renderizador padrão de `stage_scene.gd::_draw()`
  (mode "lava", pega o tileset da zona automaticamente). Não precisa de
  `_draw_*` bespoke.
- Toggle: `wall.get_node("CollisionShape2D").set_deferred("disabled", true/false)`
  — **nunca** `queue_free()` numa parede visual (remove os tiles; ver skill
  `new-corridor`, seção "Paredes Visuais Adjacentes").
- Largura da sala = largura do corredor de entrada (stage_00: ambos 896px) —
  dá uma leitura visual contínua, sem "sala genérica" desconectada do resto.

### B — Porta permanentemente aberta + trigger de aggro (stage_01, Ignarath)

A parede da entrada tem um vão fixo (o boss não te tranca dentro); o boss
agrota quando um `Area2D` de trigger detecta o player entrando pela porta.
Use quando o design quer que o player possa recuar/sair da luta.

- A colisão da parede já nasce cortada — só cobre a faixa ACIMA do vão (mesmo
  padrão do `CorridorSection._add_wall_above_door`): `wall_h = door_lo - wall_top`.
- **Isso exige um renderizador bespoke** (`_draw_boss_room` no stage 01): o
  grid genérico do `stage_scene.gd` não sabe desenhar um "buraco" numa parede,
  então a sala inteira (piso+teto+2 paredes) ganha `skip_base_draw` e um
  `_draw_*` próprio que pula as células da faixa do vão. Só vale a pena esse
  código extra quando o padrão A (parede que sela) não serve ao design.
- `BossRoomTrigger`: `Area2D` cobrindo o interior, `collision_mask = 2`,
  conectado a `boss.call("aggro")` no `body_entered`. `auto_aggro = false` no
  boss (ver `reference-boss-room-aggro` na memória do projeto).

## Informações a Coletar

1. **stage_id**, **room_id** (ex: `Boss`, `MiniBoss`)
2. **Padrão de entrada**: A (selada) ou B (porta aberta + trigger)?
3. **corridor_width** — largura do corredor que leva até a sala (múltiplo de 64)
4. **room_width** — largura da sala (múltiplo de 64; pode ser maior que o
   corredor pra dar espaço de combate, mas precisa ser múltiplo de 64 também)
5. **floor_top** — Y da superfície do piso da sala (pode ser diferente do
   piso do corredor; se for, cobrir o degrau com uma soleira)
6. **interior_height** — múltiplo de 64 (stage_00 usa 384 = 6 tiles pro
   MiniBoss; arenas de boss maior podem precisar de mais, ex. 320-448)
7. **tileset** — reaproveitar o mesmo do corredor/zona adjacente

## Geometria (padrão A — sala selada, valores de exemplo do stage_00)

| Nó | Posição (center) | Tamanho | Função |
|----|-------------------|---------|--------|
| `<Room>_Floor` | (cx, floor_top+32) | largura × 64 | Chão |
| `<Room>_Ceil`  | (cx, floor_top−interior_height−32) | largura × 64 | Teto |
| `<Room>_LWall` | (x_entrada, cy) | 64 × (interior_height+128) | Parede de entrada (toggle) |
| `<Room>_RWall` | (x_saída, cy) | 64 × (interior_height+128) | Parede de saída (toggle) |

`cy = floor_top − interior_height/2`. Altura da parede = `interior_height + 2×64`
(cobre o piso e o teto inteiros, não só o vão — mesma regra usada no
`_z2_static("BossWallR", ...)` do stage 01, onde `h = floor_top − ceil_top + 64`).

## O que Gerar

### Padrão A (selada) — código em `stages/<stage_id>/<stage_id>_scene.gd`

```gdscript
func _build_<room>_room() -> void:
	_z2_static("<Room>_Floor", Vector2(cx, floor_top + 32.0), Vector2(width, 64.0))
	_z2_static("<Room>_Ceil",  Vector2(cx, ceil_bottom - 32.0), Vector2(width, 64.0))
	var lwall := _z2_static("<Room>_LWall", Vector2(entry_x, cy), Vector2(64.0, wall_h))
	lwall.get_node("CollisionShape2D").disabled = true   # abre até o player entrar
	_z2_static("<Room>_RWall", Vector2(exit_x, cy), Vector2(64.0, wall_h))

func _seal_<room>_room() -> void:
	get_node("<Room>_LWall/CollisionShape2D").set_deferred("disabled", false)

func _open_<room>_exit() -> void:
	get_node("<Room>_RWall/CollisionShape2D").set_deferred("disabled", true)
```

Conectar `_seal_<room>_room` ao trigger de entrada (mesmo padrão de
`docs/stage_00/corredor.md`, seção "Trigger de Entrada") e `_open_<room>_exit`
ao sinal de derrota do boss.

### Padrão B (porta aberta) — ver `_build_z4_boss` + `_draw_boss_room` +
`_setup_boss_room_trigger` em `stages/stage_01/stage_01_scene.gd` como
referência completa (constantes `_BOSS_L/_BOSS_R/_BOSS_FLOOR_TOP/_BOSS_CEIL_TOP/
_BOSS_DOOR_LO/_BOSS_DOOR_HI`, todas usadas pra derivar geometria e grid —
mudar UMA delas já propaga certo pro resto, desde que a diferença
`_BOSS_FLOOR_TOP − _BOSS_CEIL_TOP` continue múltiplo de 64).

## Checklist Pós-Criação

- [ ] Largura da sala múltiplo de 64px
- [ ] Altura interior (piso ao teto) múltiplo de 64px
- [ ] Superfície do piso na mesma cota Y do corredor de entrada (ou degrau
      coberto por soleira, nunca vão aberto)
- [ ] Teto contínuo desde o corredor até a sala — nenhum trecho de piso sem
      teto acima ("céu aberto")
- [ ] Padrão A: paredes com `skip_base_draw` ausente (renderizador padrão);
      toggle via `disabled`, nunca `queue_free()`
- [ ] Padrão B: `skip_base_draw` nas 4 peças + `_draw_*` bespoke pulando a
      faixa do vão da porta; trigger de aggro com `auto_aggro=false` no boss
- [ ] Testado: câmera enquadra a sala inteira sem mostrar geometria externa;
      grade visual bate com a colisão real (sem sliver de tile na borda)

## Documentação de Referência

- Corredor: skill `new-corridor`, `docs/corredor_template.md`,
  `docs/stage_00/corredor.md` (padrão A completo — MiniBoss)
- Padrão B completo: `stages/stage_01/stage_01_scene.gd` (`_build_z4_boss`,
  `_draw_boss_room`, `_setup_boss_room_trigger`)
- Componente de corredor: `stages/corridor_section.gd`
