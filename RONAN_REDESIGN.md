# Ronan — Redesign visual do 3º personagem (rodar em sessão LOCAL)

> **Nome definido:** o novo personagem se chama **Ronan** — não é "Kawagael
> Ronin" nem uma variação do nome Kawagael. Onde este documento cita
> "Kawagael" sozinho, é o personagem atual (robô verde) já existente em
> `characters/ranged/kawagael/`, mantido como referência/prior art.

> **Por que esse arquivo existe:** esta sessão começou no Claude Code na nuvem
> (claude.ai/code), que roda num container remoto sem acesso ao MCP do
> PixelLab nem ao `.env` com `PIXELLAB_API_KEY` — esses só existem na sua
> máquina. Este documento junta tudo que foi decidido pra você (ou uma nova
> sessão do Claude Code rodando localmente) executar sem precisar repetir a
> conversa. Basta abrir uma sessão local e dizer: **"segue o plano em
> RONAN_REDESIGN.md"**.

## Contexto

O Kawagael é o 3º personagem jogável (atalho `K`), hoje um "sleek combat
robot" verde gerado a partir do character PixelLab `bc1bd784-bffa-417e-905a-56e5aac35f67`
(ver `docs/superpowers/specs/2026-08-10-kawagael-pixellab-swap-design.md`).
Ele reusa 100% do kit de gameplay do Zael (5 tipos de tiro, carga, dash,
wall-jump) — só a aparência muda.

Este documento propõe um **redesign visual completo** (novo character
PixelLab, não um ajuste do atual): **Ronan**, um gunslinger esguio e
elegante com tema "ronin", decidido como a direção escolhida entre 5
opções (Heavy Vanguard, Ronin/Ronan, Corsair, Wraith, Aurora).

**Não-objetivo:** mudar código de gameplay. O loader (`_add_anim_from_frames`)
e a FSM já existentes em `characters/ranged/kawagael/kawagael.gd` continuam
valendo — só as pastas de sprite seriam usadas/substituídas ao final,
depois de aprovado visualmente (ver Passo 5 sobre virar classe própria ou
substituir o Kawagael atual).

## Conceito — Ronan

- **Silhueta:** humanoide esguio (mais magro que o Kawagael verde atual),
  postura ereta de gunslinger, não um "mecha bruto".
- **Cabeça:** capacete liso com uma crista/leque tipo penacho nas costas da
  cabeça (referência samurai, sem exagerar — ainda robótico).
- **Arma:** canhão embutido numa **braçadeira no antebraço** (não o braço
  inteiro virando canhão) — o resto do braço fica livre/articulado, reforça
  leitura de "arma acoplada" em vez de "braço-arma".
- **Detalhe de movimento:** uma tira de pano/lenço simulado preso no ombro
  ou cintura, que reage no `run`/`dash` pra dar dinamismo extra (opcional —
  só incluir se o PixelLab conseguir manter consistência entre frames).
- **Paleta:** índigo/azul-petróleo escuro como cor base do chassi + dourado
  metálico nos detalhes/juntas + um brilho ciano suave no "olho"/visor e no
  cano do canhão.
- **Tom geral:** mais ágil e refinado que o Kawagael atual, contrasta com o
  visual "tosco" dos inimigos e dá uma identidade própria dentro do elenco
  (Zael = herói clássico, Zara = melee, Ronan = atirador elegante).

## Pré-requisitos (checar antes de começar)

1. `claude mcp list` deve mostrar `pixellab: https://api.pixellab.ai/mcp (HTTP) - ✔ Connected`.
   Se não aparecer, o MCP foi configurado mas a sessão local precisa reiniciar.
2. Carregar a API key na sessão (ver `.claude/skills/pixellab.md`):
   ```powershell
   $env:PIXELLAB_API_KEY = (Get-Content .env | Select-String "PIXELLAB_API_KEY").ToString().Split("=")[1]
   ```
3. Checar créditos: chamar `mcp__pixellab__get_balance` e confirmar saldo
   suficiente (a geração completa de um personagem com ~15 animações e
   curadoria de frames consome uma faixa parecida com o que o Kawagael verde
   já consumiu — ver `characters/ranged/kawagael/_raw/job_ids.json` do
   personagem atual como referência de volume).
4. Ler `docs/superpowers/specs/2026-08-10-kawagael-pixellab-swap-design.md`
   antes de começar — o pipeline técnico (loader, FSM, diretórios) é o mesmo,
   só o character-source muda.

## Passo 1 — Gerar o character base no PixelLab

Usar `mcp__pixellab__create_character`:

```json
{
  "name": "Ronan",
  "description": "Sleek humanoid combat robot, samurai-inspired gunslinger silhouette, slim build, upright posture. Deep indigo/petrol-blue chassis plating with warm gold metallic trim on joints and edges. Smooth featureless helmet with a small fan-shaped crest/fin on the back of the head, single soft cyan glowing visor slit. Forearm-mounted cannon gauntlet on the right arm (not a full arm-cannon) — the cannon is a compact attachment over the forearm, hand and fingers still visible/articulated. Left arm free and unarmed. A thin cloth sash or scarf hangs from one shoulder for movement flair. HD pixel art style, side view, dark background, clean single-color outline.",
  "size": 256,
  "view": "side",
  "n_directions": 8,
  "mode": "standard",
  "outline": "single color outline",
  "shading": "basic shading",
  "detail": "high detail",
  "proportions": "{\"type\": \"preset\", \"name\": \"heroic\"}"
}
```

Guardar o `character_id` retornado. Só vamos usar a rotação `east` (mesmo
padrão do Kawagael atual — `west` é `flip_h` em runtime).

**Gerar 2-3 variações da descrição** (ex.: variar intensidade do dourado,
com/sem sash, tamanho do canhão) antes de comprometer com uma — mesmo
processo de "escolher entre candidatos" usado pra efeitos visuais
(`pixellab-effect`). Baixar as rotações de cada candidato pra
`assets/generated/ronan/candidates/<n>/` antes de decidir.

## Passo 2 — Aprovar o candidato e baixar sprite base

```powershell
python tools/pixellab_download.py character <character_id> assets/generated/ronan/
```

## Passo 3 — Animações (mesmas 15 do Kawagael atual, pra drop-in direto)

Reusar exatamente os nomes de estado que `kawagael.gd` já espera em
`characters/ranged/kawagael/anims/<nome>/` (ou `characters/ranged/ronan/anims/<nome>/`
se virar classe própria — ver Passo 5):

| Estado | Frames aprox. | Descrição de ação sugerida |
|---|---|---|
| `idle` | 8f loop | "idle stance, cannon-arm relaxed at side, subtle breathing sway, sash moving gently" |
| `run` | 6-8f loop | "running cycle, sash trailing behind with movement, upright agile stride" |
| `run_start` | 2-3f | "transition from idle into running stride" |
| `run_stop` | 2-3f | "transition from running back to idle stance" |
| `jump` | 4f | "jumping up, knees tucked, sash flowing upward" |
| `jump_shoot` | 2f | "firing forearm cannon while airborne" |
| `dash` | 2f | "quick horizontal dash pose, low crouch, cannon arm forward" |
| `dash_shoot` | 2f | "firing cannon mid-dash" |
| `shoot_1` / `shoot_2` / `shoot_3` | compartilhado | "aiming and firing forearm cannon, charge levels 1-3, muzzle flash growing" |
| `run_shoot` | 9f | "running while firing forearm cannon, arm extended forward" |
| `wall_slide` | 2f | "sliding down a wall, free hand and feet braced against surface" |
| `hurt` | 3f | "recoiling from a hit, defensive flinch" |
| `death` | 6f | "powering down and collapsing, visor light fading out" |

Submeter via `mcp__pixellab__animate_character` (`mode: "v3"`, direção
`east` apenas) e baixar com `tools/pixellab_download.py animation ...`
pra `assets/generated/ronan/<estado>/`.

## Passo 4 — Curadoria

Mesmo processo do Kawagael atual: recortar/alinhar pés, downscale pra
68×68px, remover fundo, exportar `f00.png…fNN.png` por estado. Usar
`tools/kawagael_curate.ps1` como referência de script (adaptar nomes de
pasta pra "ronan") ou o helper Python equivalente já usado no swap original.

## Passo 5 — Integração (sem mudar código)

1. Decidir a estrutura final antes de copiar os frames curados (ver
   "Decisão em aberto" abaixo):
   - **Substituir** o Kawagael atual: copiar os frames por cima de
     `characters/ranged/kawagael/anims/<estado>/`, sem mudar nome de
     classe/arquivo.
   - **Personagem novo separado**: criar `characters/ranged/ronan/ronan.gd`
     (cópia de `kawagael.gd`, extends `Zael`, ajustando `class_name` e o
     diretório base de `anims/`) + `ronan.tscn`, e adicionar o 4º slot em
     `stage_scene.gd`/seleção de personagem (mesmo padrão usado quando o
     Kawagael foi adicionado como 3º personagem).
2. Reajustar `AnimatedSprite2D.scale` e `position.y` na `.tscn` se a nova
   arte tiver proporções/pés em posição diferente da atual.
3. Rodar a suite de testes correspondente (`test_kawagael*` ou os
   equivalentes `test_ronan*` se virar classe própria) — skill `run-tests`.
4. Fazer o smoke playthrough visual (a mesma Task 11 pendente registrada em
   `STATUS.md`): idle/run/jump/dash/hurt/shoot/wall_slide/death num stage
   real, via skill `run`.

## Decisão em aberto

- **Substituir** o Kawagael verde atual pelo Ronan ou **manter os dois**
  como personagens/skins separados (Kawagael + Ronan)? Isso muda se o
  Passo 5.1 sobrescreve `characters/ranged/kawagael/anims/` ou cria uma
  pasta/classe nova em `characters/ranged/ronan/`. Decidir antes de rodar a
  curadoria final — o candidate staging em `assets/generated/ronan/` não
  compromete nada, pode gerar e comparar sem decidir isso ainda.
