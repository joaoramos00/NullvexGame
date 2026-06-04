# StageBot — Validador Automático de Fase

**Data:** 2026-06-03
**Status:** Design aprovado (aguardando revisão do spec)

## Problema

Validar uma fase de ponta a ponta hoje é manual: abrir o jogo, jogar a fase inteira, e olhar à mão se a geometria deixa passar e se o visual (tilesets, lava, corredores, portas) está certo. É lento e propenso a esquecer trechos — e os piores bugs (ex.: lava branca) só aparecem no **build web** (WebGL2), não no Godot nativo.

## Objetivo

Um bot que **atravessa a fase automaticamente** (provando que dá pra completar) **e tira screenshots nos pontos-chave** do **build web real**, pra inspeção visual. Resultado: galeria de PNGs + veredito PASS/FAIL com o ponto onde travou, se travar.

Escopo de entrega:
1. Framework reutilizável (motor + runner) que não muda ao adicionar fases.
2. Caminho da **stage_00** autorado primeiro (fase conhecida-boa → valida o próprio framework).
3. Caminho da **stage_01** em seguida.
4. As outras 10 fases ganham suporte depois só criando um arquivo de caminho — sem tocar no motor.

## Restrição técnica central

O player se move lendo o singleton `Input` do Godot (`Input.get_axis(...)`, `Input.is_action_just_pressed(...)`). **Eventos de tecla sintéticos via Playwright/CDP NÃO movem o player** (confirmado em sessão anterior; só `ui_accept`/Enter de menu funciona).

**Solução:** dividir os papéis.
- **Dirigir** = código GDScript dentro do jogo, chamando `Input.action_press/release(...)`. Isso funciona no build web (é o `Input` do próprio Godot, não CDP).
- **Observar/fotografar** = Playwright tira screenshots do canvas. Playwright faz só o que sabe fazer no Godot web: ver.

## Arquitetura

```
Playwright (run_stage_bot.mjs)          Godot (build web em localhost:8080)
─────────────────────────────           ──────────────────────────────────
abre ?stage=00&bot=1&noenemies=1  ──►   debug_boot (autoload) lê params
escuta console do canvas                 ├─ seta GameManager/StageManager
                                         ├─ carrega cena da fase direto
                                         └─ liga flags bot_enabled/no_enemies
                                                      │
                                         fase remove inimigos (no_enemies)
                                                      │
                                         StageBot dirige player por segmentos
                                                      │
  ◄── console: BOT_SHOT:00:corridor1 ──  segmento screenshot imprime marcador
  tira screenshot → shots/00/...png
                                                      │
  ◄── console: BOT_DONE ───────────────  bot chega ao fim
  grava results/00.json (PASS)
```

### Componentes

#### 1. `debug_boot.gd` — autoload de boot direto
Registrado como autoload no `project.godot`. No `_ready`:
- Lê os params de URL (web: via `JavaScriptBridge.eval("window.location.search")`; desktop: via `OS.get_cmdline_args()`).
- Params: `stage` (id da fase), `bot` (liga o StageBot), `noenemies` (remove combatentes), `char` (opcional, `zael`/`zara`, default `zael`).
- Se `stage` presente: `GameManager.reset()`, `set_active_character(...)`, `StageManager.current_stage_id = N`, e troca a cena para `res://stages/stage_NN/stage_NN.tscn` — pulando título e stage select.
- Expõe flags globais lidas pelas fases e pelo bot: `DebugBoot.bot_enabled`, `DebugBoot.no_enemies`, `DebugBoot.stage_id`.

Sem params de bot, o autoload é inerte — o jogo inicia normal pelo título.

#### 2. Flag `no_enemies` — remoção de combatentes
Remove **todos** os combatentes: grunts, flyers, **miniboss e boss** (`enemy_flyer`/`enemy_miniboss` estendem `EnemyBase`; bosses são `BossBase`).

- **Fases 01-08** (base `stage_scene.gd`): em `_ready()`, se `DebugBoot.no_enemies`, iterar filhos e `queue_free()` em tudo que for `is EnemyBase or is BossBase`. Fazer isso **antes** do laço que liga `child.player = _player`, pra não referenciar nó liberado.
- **stage_00** (`stage_00_scene.gd`): boss e miniboss são spawnados por trigger. Se `no_enemies`: **não** chamar `_setup_miniboss_trigger()` e tornar `_spawn_boss()` no-op (early return). Nada é instanciado.

Com o boss fora, o bot encerra o percurso ao **chegar à sala do boss / goal zone** (último segmento), sem luta.

#### 3. `stage_bot.gd` — o autopilot (Approach A)
`Node` adicionado à fase pelo `debug_boot` quando `bot_enabled`. Guarda referência ao `_player` (busca pelo grupo `"player"`). Consome um caminho = `Array` de segmentos (dicionários). Tipos:

| Segmento | Campos | Comportamento |
|---|---|---|
| `walk_to` | `x` | segura `move_left`/`move_right` rumo a x; auto-`jump` quando `is_on_wall()` sem progresso, ou ao detectar beirada antes de um gap rumo ao alvo. Completo quando `abs(player.x - x) < TOL` (TOL=24). |
| `climb_to` | `y`, `side` | loop de wall-jump: pressiona contra a parede (`side`), `jump`, alterna; completo quando `player.y <= y`. |
| `drop` | (—) | anda pra fora da beirada mais próxima na direção do progresso; completo quando começa a cair (`velocity.y > 0` e não `is_on_floor`) ou passa de um `y` alvo. |
| `wait` | `seconds` | ocioso. |
| `screenshot` | `label` | imprime `BOT_SHOT:<stage>:<label>`, espera 1 frame. |

Dirige só via `Input.action_press/release("move_left"|"move_right"|"jump")` — nunca seta `velocity`/`position` direto (assim a traversia prova a física real da fase).

**Marcadores de console** (contrato com o Playwright):
- `BOT_START` — bot pronto, começou o caminho.
- `BOT_SHOT:<stage>:<label>` — pedido de screenshot.
- `BOT_STUCK:<label>@<x>,<y>` — segmento sem progresso por `STUCK_TIMEOUT` (4s) → aborta.
- `BOT_DONE` — último segmento concluído com sucesso.

**Detecção de travamento:** cada segmento mede progresso (variação de posição rumo ao alvo). Se < `EPS` por 4s contínuos → `BOT_STUCK` e encerra (o Playwright fotografa o ponto travado).

#### 4. Caminhos por fase — `tests/bot/paths/stage_NN.gd`
Cada arquivo retorna a `Array` de segmentos, escrita à mão. Ex. (ilustrativo):
```gdscript
# tests/bot/paths/stage_00.gd
static func path() -> Array:
    return [
        {"t": "screenshot", "label": "00_spawn"},
        {"t": "walk_to", "x": 3000.0},
        {"t": "screenshot", "label": "01_corredor1"},
        {"t": "walk_to", "x": 6470.0},   # entra no trigger do miniboss (vazio em no_enemies)
        {"t": "screenshot", "label": "02_sala_miniboss"},
        {"t": "walk_to", "x": 8222.0},   # corredor 2
        {"t": "screenshot", "label": "03_corredor2"},
        {"t": "walk_to", "x": 17000.0},  # sala do boss (boss removido)
        {"t": "screenshot", "label": "04_sala_boss"},
    ]
```
`stage_bot.gd` resolve o arquivo por `DebugBoot.stage_id` (`load("res://tests/bot/paths/stage_%02d.gd")`). Adicionar uma fase = só criar o arquivo. Motor inalterado.

#### 5. `run_stage_bot.mjs` — runner Playwright (só observa)
Script Node com Playwright. Uso: `node tests/bot/run_stage_bot.mjs 00` (id da fase).
- Lança browser, abre `http://localhost:8080/?stage=00&bot=1&noenemies=1`.
- Escuta `page.on("console")`. Espera `BOT_START` (com timeout de boot).
- A cada `BOT_SHOT:<stage>:<label>` → `page.locator("canvas").screenshot()` → salva `tests/bot/shots/<stage>/<label>.png`.
- `BOT_DONE` → **PASS**. `BOT_STUCK` → fotografa o estado atual como `<label>_STUCK.png`, marca **FAIL**. Timeout global (ex. 120s) sem `BOT_DONE` → **FAIL**.
- Grava `tests/bot/results/<stage>.json`: `{ status, segments_completed, shots: [...], stuck: {label,x,y}|null, duration_ms }`.
- Exit code 0 (PASS) / 1 (FAIL) pra uso em script/CI futuramente.

Pré-requisito: servidor web já rodando em `localhost:8080` (skill `web-export` já cuida disso). O runner não sobe o servidor — assume que está no ar.

### Layout de arquivos
```
tests/bot/
├── stage_bot.gd            # autopilot (commitado)
├── debug_boot.gd           # autoload de boot (commitado; registrado no project.godot)
├── run_stage_bot.mjs       # runner Playwright (commitado)
├── paths/
│   ├── stage_00.gd         # caminho fase 00 (commitado)
│   └── stage_01.gd         # depois (commitado)
├── shots/                  # SAÍDA: PNGs (gitignored)
│   └── stage_00/<label>.png
└── results/                # SAÍDA: relatório (gitignored)
    └── stage_00.json
```
`.gitignore`: adicionar `tests/bot/shots/` e `tests/bot/results/`.

## Fluxo de dados
1. Playwright abre a URL com params.
2. `debug_boot` boota a fase direto + liga flags.
3. Fase remove inimigos (`no_enemies`).
4. `stage_bot` dirige o player pelos segmentos do caminho da fase.
5. Em cada `screenshot`, o bot imprime marcador; o Playwright fotografa o canvas.
6. `BOT_DONE` → Playwright grava PASS + galeria de PNGs. `BOT_STUCK`/timeout → FAIL + print do ponto travado.

## Tratamento de erros
- **Bot trava** → `BOT_STUCK:<label>@<pos>`, Playwright fotografa e marca FAIL com o local exato.
- **Boot não acontece** (sem `BOT_START` em N s) → FAIL "boot timeout" (provável erro nos params ou na cena).
- **Servidor fora do ar** → erro de conexão do Playwright, mensagem clara pedindo pra rodar o `web-export`/servidor.
- **Caminho inexistente** pra a fase → `stage_bot` imprime `BOT_STUCK:no_path` e encerra.

## Validação do próprio framework
Primeiro alvo é a **stage_00** (já funciona). Rodar o bot nela deve dar **PASS** com a galeria completa. Só depois autorar a **stage_01**. Isso separa "o framework funciona" de "a fase nova é válida".

## Fora de escopo (YAGNI)
- Pathfinding automático (Approach C).
- Lutar contra bosses / validar combate.
- Rodar em CI automaticamente (o design deixa exit codes prontos, mas a integração CI fica pra depois).
- Driver de menus (título/stage select) — substituído pelo boot direto.
- Comparação visual automática (diff de imagem) — a inspeção é humana, olhando os PNGs.
