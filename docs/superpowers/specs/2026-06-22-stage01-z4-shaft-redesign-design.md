# Stage 01 — Redesign do shaft (Zona 4) + saliência agarrável

**Data:** 2026-06-22
**Fase:** Stage 01 (Ignarath), Zona 4 (shaft de wall-jump)
**Referência visual:** `referencias/shaftStage01Zona4.png`

## Objetivo

Refazer o layout do shaft da Z4 conforme a imagem de referência, introduzindo a
**saliência agarrável** (foothold) como elemento de level design reutilizável, com
ferramental de autoria (skill + visualizador no imgdebug) e regras de validação
dimensionadas à física de pulo do Zael.

## Legenda de cores (referência)

| Cor | Hex | Significado |
|-----|-----|-------------|
| Azul-claro | `7FC9FF` | Passagem secreta (coluna esquerda, altura cheia) |
| Laranja | `FF6A00` | Entrada/parede quebrável da passagem secreta |
| Rosa | `FF006E` | Geometria **existente** (base/entrada — preservar) |
| Vermelho | `FF0000` | Espinhos (instant-kill) |
| Amarelo | `FFD800` | Plataformas (estáticas, andáveis) |
| Verde | `4CFF00` | Saliência para escalar (foothold agarrável) |
| Marrom | `7F3F3F` | Parede comum (agarrável) |
| Indigo | `4800FF` | Sala pré-boss (já existe; realinhar) |

## Decisões de design (confirmadas)

1. **Saliência agarrável = parede agarrável isolada.** Mecânica idêntica ao
   wall-grab/wall-jump padrão do MMX (gruda, escorrega a `WALL_SLIDE_SPEED`,
   wall-jump). NÃO há input novo. O que muda é a **forma**: um ressalto curto que
   se projeta ~1 tile (64px) pra dentro do shaft a partir de uma parede, lendo como
   ponto de apoio. Parede comum (marrom) e saliência (verde) são **mecanicamente
   iguais** (ambas agarráveis); a saliência só se projeta do plano da parede.
2. **Lava-chase mantida.** A lava sobe perseguindo o player (`Z4ShaftLava` +
   `Z4ChaseTrigger`); o novo layout de saliências/plataformas é o caminho por cima
   dela. Só realinhar `cap_y`/coluna ao novo envelope.
3. **Sala pré-boss mantida.** Já existe e liga ao corredor do boss; apenas
   realinhar ao novo topo do shaft.
4. **Passagem secreta** (ver fluxo abaixo) guarda o coletável Dual Blades.
5. **Layout autorado por abordagem híbrida:** paredes do shaft, lava-chase,
   segredo e boss permanecem código bespoke (são lógica, não só geometria); as
   **saliências + plataformas + espinhos** vêm de uma tabela local dentro de
   `_build_z4_shaft`, iterada por helpers.

## Fluxo da passagem secreta

Coluna azul-clara à esquerda, altura cheia, paralela ao shaft de escalada.

1. **Parede quebrável inferior** (`FF6A00` de baixo): quebra pelo lado **de fora**
   (lado do shaft; detector externo), requer habilidade de Galerix → dá acesso
   PARA DENTRO da passagem.
2. **Dentro:** plataforma/elevador (`Z4SecretElevator`) que **só ativa quando o
   player sobe nela** → leva ao topo. O coletável **Dual Blades** fica dentro.
3. **Parede quebrável superior** (`FF6A00` de cima): quebra **só pelo lado de
   dentro** → sai no topo do shaft, perto da sala pré-boss.
4. Segredo **totalmente selado**: sem vão/buraco alternativo; só as duas paredes
   quebráveis dão acesso (regra existente do projeto).

## Saliência agarrável — ferramental

### Helper de build
`_z4_foothold(nome, x_parede, y, lado, altura)` em `stage_01_scene.gd`:
- Cria `StaticBody2D` agarrável (**sem** `no_wall_grab`), projetando-se 64px pra
  dentro do shaft a partir da parede no `lado` ("L"/"R").
- `altura` ≤ 1 tile de respiro (regra de design — apoio curto, não plataforma).

### Modo "Saliência" no imgdebug (aba "Plataformas")
Novo modo no `_PlatformView` (`ui/img_debug.gd`):
- Desenha uma parede vertical com um ressalto projetando 1 tile, via
  marching-squares (reusa `_fp_solid`/`_fp_tile`).
- Mostra as coords de tile do bump pra parede esquerda e direita.
- Botão **"Espelhar"** troca o lado do ressalto.
- Entra na lista de modos junto de `platform`/`room`/`floor_platform`/
  `floor_platform_hole`/`floor_hole`.

### Skill formal
`.claude/skills/new-foothold/SKILL.md`: quando usar, helper a chamar, quais coords
de tile, regra de altura (≤1 tile), e dica de calibrar no modo "Saliência" do
imgdebug. Regra curta no `CLAUDE.md` (seções imgdebug + arquitetura) apontando
pra skill.

## Qual tile

- **Paredes comuns, saliências e plataformas Z4** → `stages/stage_01/Stage_01T_z4.png`
  (atlas 4×4, escolhido automaticamente por `_get_zone_tileset` na faixa de x do Z4).
  Saliência tilada por `_fp_tile`: faces parede-esq `(1,0)` / parede-dir `(3,2)`;
  cantos convexos do bump `(0,0)`/`(1,3)`/`(0,2)`/`(3,3)`; preenchimento `(2,1)`.
- **Espinhos** → `stages/stage_01/spikes.png` (helper `_z4_spike_face`, existente).
- **Lava-chase** → `stages/stage_01/Stage_01_lava_v2.png` (inalterado).

## Validação dimensional (ancorada no pulo do Zael)

Player limitante = **Zael**: cápsula `radius=20`/`height=80` → caixa **40×80px**
(Zara é 20×28, mais estreita, não-limitante). Constantes de `character_base.gd`:
`GRAVITY=980`, `JUMP_VELOCITY=-480`, `SPEED=200`.

Envelope de pulo derivado:
- **Altura do pulo** = `480² / (2·980)` = **118px**
- **Alcance horizontal** (arco completo, mesma altura) = `200 · (2·480/980)` = **196px**

Regras (todas dimensionadas ao pulo, não a chute):
1. **Passagem livre horizontal ≥ 192px** (3 tiles — os 196px de alcance do pulo
   arredondados ao grid de 64px; folga de 4px), já descontando saliências/espinhos.
   Daí: interior wall-to-wall **≥256px (4 tiles)** onde só um lado projeta (256−64=192);
   **≥320px (5 tiles)** onde saliência e espinho se opõem (320−128=192).
   (O shaft atual tem 192–240px wall-to-wall, então com projeção dos dois lados a
   passagem cai a ~64–128px — abaixo do alvo, daí o aperto.)
2. **Passo vertical de subida entre apoios ≤ 118px** (altura do pulo) — nunca
   exigir mais que um pulo pra alcançar o próximo apoio.
3. **Folga vertical livre ≥ 80px** acima de qualquer superfície pisável (cabe a
   altura do Zael).

### Teste de validação
Teste headless que varre o shaft por faixa de y e **falha** (exit code 1) se:
vão livre horizontal `< 192px`, passo vertical de subida `> 118px`, ou folga
vertical `< 80px`. Segue o padrão `_check + quit(1)` (assert não aborta em
headless). Verificação **estática** — sem rodar no browser.

## Layout do shaft (estrutura)

Âncoras preservadas: base conecta em `Z4ShaftEntry`/escada-chase embaixo
(~y2208); topo conecta na sala pré-boss → corredor do boss (~y360). Blocos rosa
(`Existente`) = base/entrada atuais preservadas.

Regiões (da imagem):
- **Coluna esquerda (altura cheia):** passagem secreta + elevador + Dual Blades +
  2 paredes quebráveis.
- **Miolo (escalada):** saliências (verde), plataformas (amarelo), espinhos
  (vermelho), tilados no `Stage_01T_z4.png`.
- **Lado direito:** escada de paredes comuns (marrom) descendo, agarráveis.
- **Topo:** sala pré-boss (indigo) → porta do boss.
- **Fundo:** lava-chase subindo sob todo o miolo.

Tabela local em `_build_z4_shaft` (`[x_coluna, y, w/altura, tipo, lado]`),
iterada pelos helpers `_z4_platform` / `_z4_foothold` / `_z4_spike_face`.
Coordenadas/larguras derivadas proporcionalmente da imagem e **calibradas no
render de zona do imgdebug**, respeitando as 3 regras de validação acima.

## Arquivos tocados

| Arquivo | Mudança |
|---------|---------|
| `stages/stage_01/stage_01_scene.gd` | Novo layout do shaft + helper `_z4_foothold` + tabela de elementos |
| `ui/img_debug.gd` | Modo "Saliência" no `_PlatformView` |
| `.claude/skills/new-foothold/SKILL.md` | Skill nova |
| `CLAUDE.md` | Regra apontando pra skill (imgdebug + arquitetura) |
| `docs/stage_01/zones/legenda.md` + `z4.svg` | Regenerar via `tools/zone_debug_01.gd` |
| `tests/` | Teste headless de validação dimensional do shaft |

## Testes

- `run-tests` headless (game_manager / stage_manager / character_base).
- Parse-check do `img_debug.gd` via **load da `.tscn`** (NÃO `--check-only --script`,
  que não carrega autoloads).
- Teste de validação dimensional do shaft (regras 1–3).
- Verificação estática (sem Playwright/browser).
- `web-export` ao final.

## Fora de escopo (YAGNI)

- Mecânica nova de input (mantle/escada) — confirmado que saliência = wall-grab.
- Mudar lava-chase, sala pré-boss ou geometria de base/entrada além do realinhamento.
- Refatorar o estilo bespoke do resto do `stage_01_scene.gd`.
