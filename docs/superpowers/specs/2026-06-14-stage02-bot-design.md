# Spec — Bot (StageBot) do Stage 2

**Data:** 2026-06-14
**Arquivos afetados:** `tests/bot/paths/stage_02.gd` (novo), `stages/stage_02/stage_02_scene.gd`, `stages/stage_02/ice_floor.gd`

## Objetivo

Criar o autopilot (StageBot) que atravessa o Stage 2 expandido, para validar a
travessia/plataforma da fase automaticamente — como já existe para os Stages 00 e 01.
Durante a execução do bot, **desligar o piso escorregadio** (StageIceFloor), porque o
modelo de movimento do bot não lida com derrapagem.

## Decisões (do brainstorm)

| Tema | Decisão |
|------|---------|
| Derrapante no bot | **Desligar na fase inteira** quando `bot=1` (não só na zona 1) |
| Amarração | Ao `DebugBoot.bot_enabled` (flag `bot=1`), **independente** de `noenemies` |
| Jogo normal | Derrapante **continua ligado** (jogador humano enfrenta o gelo) |
| Miniboss no bot | Rodar com `noenemies=1`; o CP2 (gate pós-miniboss) **auto-abre** no modo bot/no_enemies pra o bot não travar |
| Comando de validação | `?stage=2&bot=1&noenemies=1` (headless) |

## Sistema de bot (existente, reusado)

- `DebugBoot` (autoload): parseia `?stage=2&bot=1&noenemies=1`, dá boot da cena com
  `bot_enabled`/`no_enemies`.
- `StageBot` (`tests/bot/stage_bot.gd`): carrega `res://tests/bot/paths/stage_%02d.gd`
  (RefCounted com `func path() -> Array`) e segue os segmentos via input simulado.
- Segmentos suportados: `walk_to`/`dash_to`/`jump_to` (com `jump_x`, `no_hop`, `leap`),
  `climb_to`, `board`, `wait`, `zone` (marcador p/ `?zone=N`), `screenshot`.
- Cada fase chama `_maybe_spawn_bot()` no `_ready` (quando `bot_enabled`) pra instanciar o bot.

## Geometria do Stage 2 (referência p/ o path; FLOOR_Y=800)

- **Z1 (escorregadio):** piso 0–1400, degrau 1400–1900 (topo 736), poço recuperável
  1900–3000 (vão 2300–2560, fundo catch em 896), poço 3000–4200 (vão 3450–3650),
  degrau 4200–4700, piso 4700–5600.
- **Z2 (espinhos):** piso 5600–6600, poço 6600–7800 (vão 7050–7300), degrau 7800–8300,
  piso 8300–9400 (campo de espinhos ~8850), poço 9400–10600 (vão 9850–10100).
- **CP1 corredor:** 10600–11400. **MiniBoss:** 11500–12300. **CP2 corredor:** 12400–13200.
- **Z3 (nevasca):** piso 13200–14400, poço 14400–15600 (vão 14900–15150), degrau
  15600–16100, poço 16100–17300 (vão 16550–16800), piso 17300–18000.
- **Z4 (abismos mortais):** piso 18000–19000, abismo 19000–20200 (vão 19180–19360),
  piso 20200–20900, abismo 20900–22200 (vão 21080–21260), piso 22200–22900, abismo
  22900–23600 (vão 23080–23260), piso 23600–24400.
- **CP3 corredor:** 23600–24400. **Boss entry:** 24550.

Pulo: máx ~118px / alcance ~196px. Poços recuperáveis (vãos >196) → cair e pular pra
sair (fundo 96px abaixo, saltável). Abismos Z4 (vãos 180 ≤196) → `jump_to` preciso
(cair = morte via kill plane).

## Componentes

### `stages/stage_02/ice_floor.gd`
- Em `_on_body_entered`: **não** chamar `set_stage_ice(true)` se `DebugBoot.bot_enabled`.
  Assim o bot roda com atrito normal. (`_on_body_exited` continua chamando
  `set_stage_ice(false)` — idempotente; ou também guardar por bot.)

### `stages/stage_02/stage_02_scene.gd`
- `_maybe_spawn_bot()` (chamado no fim do `_ready`): se `DebugBoot.bot_enabled`,
  instancia `preload("res://tests/bot/stage_bot.gd").new()` (name `StageBot`) e
  `add_child`.
- `_apply_debug_zone_spawn()` (chamado no `_ready` após `_spawn_player`): se
  `DebugBoot.zone > 0`, reposiciona o player no início da zona via `_zone_spawn(zone)`
  e atualiza `StageManager.spawn_position`.
- `_zone_spawn(zone)`: retorna o x/y inicial de cada zona (1: ~(200,720), 2: ~(5700,720),
  3: ~(13300,720), 4: ~(18100,720)), e zonas de debug do miniboss/corredores conforme útil.
- **CP2 auto-abre no bot/no_enemies:** o `_make_corridor("CP2", ...)` usa `manual=true`.
  Trocar pra `manual = not (DebugBoot.bot_enabled or DebugBoot.no_enemies)` (ou, se o
  miniboss não spawnar, abrir o CP2 no `_ready`). Garante que o bot passa sem lutar.

### `tests/bot/paths/stage_02.gd` (novo)
- `extends RefCounted`, `func path() -> Array` retornando os segmentos da travessia
  Z1→Z2→CP1→MiniBoss→CP2→Z3→Z4→CP3→boss, com `zone` markers (1–4) e `screenshot`s.
- Pisos retos = `walk_to`; poços recuperáveis = `walk_to` (no_hop) pra cair + `jump_to`
  pra sair; abismos Z4 = `jump_to` com `jump_x` na beirada.
- Valores iniciais a **calibrar** rodando o bot.

## Validação
- `"D:/Godot.../Godot.exe" --headless --path . res://stages/stage_02/stage_02.tscn -- stage=2 bot=1 noenemies=1` (ou via web), e conferir:
  - O bot **chega ao fim** (perto do boss entry) sem imprimir `BOT_STUCK`.
  - O bot **não morre** nos abismos da Z4 (kill plane).
  - **Sem derrapagem** no modo bot (movimento estável).
  - Screenshots por trecho confirmam o caminho.
- Iterar nos waypoints até a travessia completa.
- **Web export** ao final + reiniciar localhost (convenção do projeto).

## Mantido (não muda)
- Geometria/inimigos/hazards da fase (Stage 2 expandido), miniboss, boss, checkpoints.
- `DebugBoot` e `StageBot` (reusados, sem alteração de código).
