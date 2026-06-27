# ImgDebug — Editor de Hitbox/Sprite por Mouse + Camada de Dados

**Data:** 2026-06-21
**Objetivo:** Permitir ajustar com o mouse (no ImgDebug, no navegador/localhost) o hitbox, a posição/scale do sprite e o offset do projétil de cada inimigo — incluindo criar/deletar hitboxes e edição por-frame — e que essas edições **persistam e afetem o jogo** sem precisar pedir à IA. Também deixar a UI do ImgDebug mais limpa (a seleção hoje empilha linhas de botões e come o espaço, principalmente na aba Hitbox).

**Restrição-chave:** o build web (navegador) não grava nos `.tscn` do projeto. A persistência usa um **arquivo JSON** gravado pelo `serve_web.py` (servidor local) e lido pelo jogo em runtime.

## Decisões fixadas
- **Id do inimigo** = basename do script (ex.: `enemy_magma_grunt`). Sem editar cada inimigo individualmente.
- **Escopo inicial de dados:** migrar só o roster de fogo do stage 01 pro JSON. Sem override no JSON → o inimigo usa o `.tscn` como hoje.
- **Fonte de verdade** dos valores tunáveis (hitbox/sprite/offset de projétil) passa a ser o JSON; o `.tscn` vira só o default inicial.

---

## Fases

O projeto é entregue em 3 fases, cada uma com valor próprio.

### Fase A — Limpeza da UI do ImgDebug
Trocar as linhas de botões empilhadas (tipo / stage / entidade / frame / projétil) por **dropdowns compactos** (`OptionButton`) em **uma linha**: `Tipo ▾  Stage ▾  Entidade ▾` + stepper de frame (`◀ Frame N ▶`) + a toolbar existente (Sprite/Labels/Regua). Resultado: muito mais espaço vertical pro viewport.

- Modificar: `ui/img_debug.gd` (classe `_HitboxView._build` e os `_refresh_*_row`).
- Comportamento preservado: filtros por tipo/stage, seleção de entidade, troca de frame, e o estado por-frame (`apply_frame_hitbox`).
- Mesmas entidades do catálogo `_HITBOX_ENTITIES`.

### Fase B — Camada de dados (jogo lê de JSON)

**Arquivo:** `data/hitbox_overrides.json` (commitado). Schema por id de inimigo:
```json
{
  "enemy_magma_grunt": {
    "sprite":     { "pos": [0, 0], "scale": [0.7, 0.7] },
    "projectile": { "offset": [0, 0] },
    "shapes": [
      { "target": "body",    "kind": "rect", "pos": [0, 0], "size": [40, 80], "frames": "all" },
      { "target": "contact", "kind": "rect", "pos": [0, 0], "size": [40, 80], "frames": "all" }
    ]
  }
}
```
- `kind`: `"rect"` (size `[w,h]`) ou `"capsule"` (size `[radius, height]`).
- `target`: `"body"` (CollisionShape2D do corpo, layer 4 — hurtbox) ou `"contact"` (ContactZone, dano por contato).
- `frames`: `"all"` ou lista de índices 0-based; permite hitbox por-frame e múltiplos shapes por alvo.
- `projectile.offset`/`sprite` são opcionais (ausência = usa o do `.tscn`/código).

**Autoload `HitboxData`** (`autoloads/hitbox_data.gd`):
- `_ready()`: carrega o JSON (ver "Carregamento" abaixo) num `Dictionary`.
- `func has(id: String) -> bool`
- `func apply(enemy: Node, id: String) -> void`: aplica sprite (pos/scale) e reconstrói os `CollisionShape2D` de `body` e `ContactZone` a partir de `shapes` (apenas os com `frames=="all"` ou contendo o frame 0, inicialmente); guarda o mapa por-frame no inimigo para `apply_frame_hitbox`.
- `func proj_offset(id: String, direction: float) -> Vector2`: offset do projétil (x espelha por `direction`); `Vector2.INF`/sentinela se ausente (chamador usa o default).
- `func frame_shapes(id: String, frame: int) -> Array`: shapes ativos no frame (para a lógica por-frame).
- `func reload() -> void`: relê o JSON (usado pelo editor após salvar).

**Aplicação nos inimigos:**
- `EnemyBase._ready()` chama `HitboxData.apply(self, _hitbox_id())` ao final. `_hitbox_id()` = basename do `get_script().resource_path`. Voadores (`EnemyFlyer`) herdam via `super._ready()`.
- A lógica por-frame do `ash_hopper` é **generalizada** para `EnemyBase`: se o id tem shapes por-frame, `EnemyBase` aplica o shape do frame corrente a cada mudança de `_anim_frame` (substitui o `apply_frame_hitbox` específico do ash_hopper, que passa a ser data-driven). Mantém ancoragem pelos pés via `pos` dos shapes.
- Os 5 atiradores (`ember_orbiter`, `cinder_flyer`, `heat_mortar`, `magma_turret`, `lava_serpent`) leem o offset via `HitboxData.proj_offset(id, _direction)` no `_fire`/`_fire_bolt`, com fallback ao valor atual se ausente.

**Migração:** popular `data/hitbox_overrides.json` com os valores atuais do roster de fogo do stage 01 (grunt, ram, hopper, orbiter, skimmer, cinder, mortar, turret, serpent) — exatamente os que estão hoje nos `.tscn`/código, para não mudar nada visualmente.

**Carregamento (localhost vs Pages):**
- `HitboxData._ready()`: em web, tenta `fetch` HTTP de `/hitbox_overrides.json` (servido vivo pelo `serve_web.py`); se falhar (ex.: Pages), cai para o arquivo assado `res://data/hitbox_overrides.json`. Em desktop, lê `res://`.
- Assim, no localhost o jogo e o editor refletem edições sem re-export; no Pages usa o arquivo commitado/assado.
- O `_PROJECTILE_DEFS` do ImgDebug passa a derivar do `HitboxData` (offset/variant) em vez de constantes duplicadas, mantendo o preview coerente com o jogo.

### Fase C — Editor por mouse + salvar

**Editor no `_HitboxView` (aba Hitbox):**
- Alças de manipulação desenhadas no overlay sobre o shape selecionado:
  - **Mover** hitbox (arrastar o corpo do shape).
  - **Redimensionar** (alças nas bordas/cantos): rect = largura/altura; capsule = radius/height.
  - **Mover/escalar** o sprite (arrastar o sprite; alça de canto p/ scale).
  - **Arrastar** o ponto de spawn do projétil (atualiza `projectile.offset`).
- **Seleção de shape:** clicar num shape o seleciona (vários shapes por inimigo).
- **CRUD:** botões **"+ Hitbox"** (adiciona um rect default ao alvo atual) e **"Deletar"** (remove o shape selecionado).
- **Por-frame:** as edições valem para o frame atual se o shape for por-frame; um toggle "Este frame / Todos" decide se a edição afeta só o frame selecionado ou `frames:"all"`.
- **Snap:** arraste em passos de 1 game-px (a régua já mede em game-px 1:1; ver `feedback_imgdebug_ruler_gamepx`).
- **Salvar:** botão "Salvar" serializa o estado do inimigo atual e faz `POST /save-hitbox` pro `serve_web.py`; em seguida `HitboxData.reload()` + re-aplica no preview.

**`serve_web.py`:**
- `do_POST` em `/save-hitbox`: recebe JSON `{ "id": ..., "data": {...} }`, faz merge no `data/hitbox_overrides.json` do projeto (não em `export/web/`), grava formatado.
- `do_GET` de `/hitbox_overrides.json`: serve o arquivo-fonte do projeto (não o assado), para o jogo/editor lerem a versão viva.
- Mantém os headers COOP/COEP existentes.

---

## Estrutura de arquivos

- Create: `autoloads/hitbox_data.gd` (+ registrar em `project.godot` autoloads)
- Create: `data/hitbox_overrides.json`
- Modify: `serve_web.py` (GET/POST do JSON)
- Modify: `characters/enemies/enemy_base.gd` (apply no `_ready`, por-frame data-driven, `_hitbox_id`)
- Modify: `characters/enemies/stage_01/enemy_ash_hopper.gd` (remover lógica por-frame específica; passa a ler do data)
- Modify: os 5 atiradores do stage 01 (`_fire`/`_fire_bolt` leem `HitboxData.proj_offset`)
- Modify: `ui/img_debug.gd` (UI dropdowns; editor de mouse; CRUD; salvar; `_PROJECTILE_DEFS` via HitboxData)
- Tests: `tests/test_hitbox_data.gd` (+ `.tscn`)

## Testes & validação
- `tests/test_hitbox_data`: carrega um JSON de fixture, valida `apply` (sprite/shapes), `proj_offset` (espelho por direção), `frame_shapes` (por-frame), e fallback quando id ausente.
- `test_stage01_fire_enemies` e `test_no_enemies` seguem passando após a migração (comportamento idêntico ao atual).
- Carga headless do `img_debug.tscn` sem erros após a UI nova e o editor.
- Validação manual no localhost: arrastar → salvar → recarregar mostra a mudança; re-export "assa".

## Fora de escopo
- Editar inimigos fora do roster de fogo do stage 01 (a infra é genérica; só não migramos os dados ainda).
- Editar bosses/personagens jogáveis pelo mouse.
- Desfazer/refazer (undo) no editor.
- Gravar de volta nos `.tscn` (a fonte de verdade passa a ser o JSON).
