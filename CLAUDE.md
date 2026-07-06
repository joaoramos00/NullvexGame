# NullvexGame — CLAUDE.md

## Visão Geral

Jogo de plataforma e ação 2D inspirado em Mega Man X4. IP original. Dois personagens jogáveis (Zael e Zara), 12 fases, 8 bosses elementais com cadeia de fraquezas lógica, e vilão final Nullvex.

**Engine:** Godot 4.6.2 (GDScript)
**Resolução:** 1920×1080 nativo
**Estilo Visual:** HD Pixel Art
**Godot executável:** `D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe`

## APIs Externas

| Serviço | Variável | Arquivo |
|---------|----------|---------|
| PixelLab (geração de sprites/tilesets) | `PIXELLAB_API_KEY` | `.env` (não commitado) |

Carregar a chave antes de chamar a API:
```bash
# PowerShell
$env:PIXELLAB_API_KEY = (Get-Content .env | Select-String "PIXELLAB_API_KEY").ToString().Split("=")[1]

# Bash
export PIXELLAB_API_KEY=$(grep PIXELLAB_API_KEY .env | cut -d= -f2)
```

Endpoint tileset sidescroller: `POST https://api.pixellab.ai/v2/tilesets-sidescroller`  
Endpoint imagem genérica: `POST https://api.pixellab.ai/v1/generate-image`

---

## Como Rodar Testes

```bash
# A partir de D:\SnesGame
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```

**Importante:** Testes usam `extends Node` + `.tscn` associada. NÃO usar `extends SceneTree` — esse modo não carrega autoloads do projeto.

---

## Estado Atual

### Planos Completos

| Plano | Conteúdo |
|-------|----------|
| Plan 01 ✅ | Fundação — project.godot, autoloads, CharacterBase, test_level |
| Plan 02 ✅ | Zael — 5 tipos de tiro (Single/Spread/Rapid/Laser/Cannon), sistema de carga |
| Plan 03 ✅ | Zara — 5 armas, sistema de combo (2 golpes + finisher) |
| Plan 04 ✅ | Sistema de combate — Hitbox/Hurtbox, EnemyBase, inimigos base |
| Plan 05 ✅ | Sistema de fases — StageController, Checkpoint, vidas, respawn |
| Plan 06 ✅ | Colectáveis — corações, sub-tanks, armaduras, armas/tiros |
| Plan 07 ✅ | Bosses — BossBase + 8 bosses elementais com fraquezas |
| Plan 08 ✅ | UI/Menus — HUD, PauseMenu, GameOver, StageSelect, TitleScreen |
| Plan 09 ✅ | Save/Load final + fluxo completo de jogo |
| Plan 10 ✅ | Boss AI — fase, attack timer, BossProjectile, gravity_scale, 8 scripts únicos |
| Plan 11 ✅ | Stage Scenes — stage_scene.gd + 8 cenas (stages 01-08) com plataformas e colectáveis |
| Plan 12 ✅ | Fases Finais — Stage 00 (intro+GoalZone), Stage 09 (gauntlet 8 bosses+walls), Stages 10-11 (Nullvex + NullvexTrue 3 fases), stage_complete routing |
| Plan 13 ✅ | Inimigos nas fases — EnemyBase (grunt) + EnemyFlyer em stages 01-08 (4 grunts + 1 flyer por fase) |
| Plan 14 ✅ | Polimento — contact damage (ContactZone Area2D), hit flash (branco 0.1s), death_effect.tscn (círculo expansivo), flicker de invencibilidade do player |
| Plan 15 ✅ | Audio — AudioLibrary autoload (null streams), play_bgm nas 3 cenas base, play_sfx em jump/shoot/attack/damage/death/collectible |

### Planos Pendentes

Nenhum plano pendente. Desenvolvimento principal concluído.

---

## Arquitetura

- **Autoloads** comunicam exclusivamente via sinais — sem chamadas diretas entre sistemas
- **GameManager** — estado persistente (lives, max_hp, unlocks, armaduras, save/load)
- **StageManager** — fase atual, checkpoints, posição de spawn
- **AudioManager** — BGM fade, pool SFX; `play_bgm(null)` and `play_sfx(null)` are safe no-ops
- **AudioLibrary** — all audio stream slots (`@export var bgm_*/sfx_*`); assign real files in editor
- **CharacterBase** — HP in-game (inicia com `GameManager.max_hp`), morre emitindo `died`
- **StageController** conecta `CharacterBase.died` ao `GameManager.lose_life()` via property setter (suporta spawn dinâmico)
- **stage_scene.gd** — script base compartilhado pelas 8 cenas de fase; spawna Zael ou Zara conforme `GameManager.active_character`; desenha terreno automaticamente via `_draw()`
- **CorridorSection** (`stages/corridor_section.gd`) — Node2D reutilizável para corredores de transição entre zonas; troque `tileset` e `glass_tex` por @export; emite sinais `camera_lock_requested`, `checkpoint_triggered`, `player_healed`, `player_traversed` para a stage conectar
- **Grupo `"no_wall_grab"`** — qualquer `StaticBody2D` nesse grupo se torna parede lisa: bloqueia o player (colisão normal), mas desativa wall grab, wall jump e cap de queda (gravidade plena). O `character_base.gd` detecta via `get_slide_collision()` a cada frame. Para ativar: `body.add_to_group("no_wall_grab")`. O `CorridorSection` já aplica isso ao vidro lateral automaticamente.
- **Painel imgdebug — aba "Plataformas"** (`ui/img_debug.gd`, classe `_PlatformView`): visualizadores de layout via marching-squares (`_fp_tile`). Modos: `platform`, `room` (sala vista por dentro), `floor_platform` (piso + plataforma elevada + piso), e **`floor_platform_hole`** = botão **"Piso+Buraco"** (piso + plataforma elevada + **abismo** de um lado). O botão **"Espelhar"** alterna `mirror_hole` (false = buraco à direita, true = à esquerda). O penhasco sai automático do `_fp_tile` ao vazar as colunas do lado do buraco em `_fp_solid` (helper `_fp_hole_dir()` → +1/-1/0). Para pedir: "modo Piso+Buraco" / "layout piso+plataforma+buraco".
- **Saliência agarrável (foothold)** — parede curta agarrável (sem `no_wall_grab`) que projeta 1 tile pra dentro do shaft; mecânica = wall-grab padrão. Helper `_z4_foothold` (stage 01) + modo "Saliência" na aba "Plataformas" do imgdebug. Ver skill `new-foothold`.

---

## Design dos Personagens

### Zael (Ranged)
- 5 tipos de tiro selecionáveis no stage select
- Single (padrão, 3 cargas), Spread (bidirecional), Rapid (8 direções c/ armadura), Laser (perfura 1), Cannon (alto dano, curto alcance, carregável)
- Com armadura de braço: +1 nível de carga para Single/Spread/Laser/Cannon; Rapid → 8 direções

### Zara (Melee)
- 5 armas selecionáveis no stage select
- Espada (padrão), Dual Blades, Glaive, Garras, Machado de Guerra
- Combo fixo: 2 golpes + finisher
- Com armadura de braço: segurar ataque carrega golpe em área

### Armaduras (4 peças cada)
- **Zael:** Capacete (detecta itens), Torso (−50% dano), Braços (+carga), Pernas (andar no ar)
- **Zara:** Capacete (parry → teleporta atrás do inimigo), Torso (−50% dano), Braços (carga área), Pernas (dash longo + diagonal ↑)
- Armadura completa Zael: Nova Buster (tiro atravessa todos)
- Armadura completa Zara: Fúria Limitless (fúria permanente)

---

## Estrutura de Fases

```
Fase 00 — Intro (obrigatória)
Fases 01-08 — Stage Select (qualquer ordem)
Fases 09-11 — Estágios Finais (desbloqueados após completar as 8)
```

- 2 checkpoints por fase (meio + antes do boss)
- Sistema de vidas: 3 iniciais, game over recarrega início da fase

### Colectáveis por Fase (01-08)
| Fase | Boss | Armadura Zael | Armadura Zara | Extra Zael | Extra Zara | Coração | Sub-Tank |
|------|------|--------------|--------------|------------|------------|---------|---------|
| 01 | Ignarath | Capacete | — | — | Dual Blades | ✓ | — |
| 02 | Cryovex | — | Capacete | Spread | — | ✓ | ✓ |
| 03 | Voltrix | Torso | — | — | Glaive | ✓ | — |
| 04 | Gravitus | — | Torso | Rapid | — | ✓ | ✓ |
| 05 | Galerix | Braços | — | — | Garras | ✓ | — |
| 06 | Umbraex | — | Braços | Laser | — | ✓ | ✓ |
| 07 | Luxar | Pernas | — | — | Machado | ✓ | — |
| 08 | Terragor | — | Pernas | Cannon | — | ✓ | ✓ |

---

## Bosses

| # | Boss | Tema | Fraqueza |
|---|------|------|---------|
| 1 | Ignarath | Fogo | Habilidade de Galerix |
| 2 | Cryovex | Gelo | Habilidade de Ignarath |
| 3 | Voltrix | Raio | Habilidade de Terragor |
| 4 | Gravitus | Gravidade | Habilidade de Luxar |
| 5 | Galerix | Vento | Habilidade de Gravitus |
| 6 | Umbraex | Sombra | Habilidade de Voltrix |
| 7 | Luxar | Luz | Habilidade de Umbraex |
| 8 | Terragor | Terra | Habilidade de Cryovex |

Cadeia: `Gravitus→Galerix→Ignarath→Cryovex→Terragor→Voltrix→Umbraex→Luxar→Gravitus`

### Fases Finais
- **Fase 09:** Gauntlet — todos os 8 bosses em sequência, sem regenerar HP
- **Fase 10:** Nullvex — Forma Humanoide (vulnerável a habilidades específicas em momentos pontuais)
- **Fase 11:** Nullvex — Forma Verdadeira (2 sub-fases, ataques intensificam no último terço)

---

## Save/Load

- **Auto-save:** ao completar fase (derrotar boss) ou sair pelo menu de pausa
- **1 save compartilhado** entre Zael e Zara
- **Compartilhado:** fases completas, corações, sub-tanks, vidas, HP máximo
- **Separado:** armaduras, habilidades de boss, armas (Zara), tipos de tiro (Zael)
- Derrotar boss uma vez → ambos recebem a habilidade

---

## Documentação Completa

- **Design spec:** `docs/superpowers/specs/2026-05-19-megaman-inspired-game-design.md`
- **Plano 01:** `docs/superpowers/plans/2026-05-19-plan-01-foundation.md`
- **Template corredor:** `docs/corredor_template.md`
- **Corredor Stage 00 (Corr1):** `docs/stage_00/corredor.md`

---

## Contexto Completo do Jogo

Ver `GAME_CONTEXT.md` na raiz — contém collision layers, tabela de bosses, APIs de autoloads, padrões de código e convenções.

---

## Skills Disponíveis

Skills locais em `.claude/skills/`. Invocar dizendo "use a skill X" ou `/X`.

| Skill | Quando Usar |
|-------|-------------|
| `new-enemy` | Criar novo tipo de inimigo (ground/flyer/jumper/shooter) |
| `new-boss` | Criar novo boss elemental com AI e fraqueza |
| `new-stage` | Criar nova fase (simple ou complex com zonas) |
| `new-corridor` | Adicionar corredor de transição a um stage complexo usando `CorridorSection` |
| `new-boss-room` | Criar/corrigir a sala/arena de um boss ou miniboss (destino de um corredor) — regra de múltiplos de 64px, padrão selado (stage_00) vs porta aberta+trigger (stage_01) |
| `new-foothold` | Criar saliência agarrável (foothold) num shaft — parede curta que projeta 1 tile, com modo "Saliência" no imgdebug |
| `new-wall-element` | Elemento preso à parede de shaft: plataforma, obstáculo ou espinhos (na face da parede / sob a plataforma) — grupo "Parede" no imgdebug |
| `run-tests` | Rodar testes headless do Godot, reportar PASS/FAIL |
| `web-export` | Exportar build web e publicar no GitHub Pages |
| `pixellab` | Gerar sprites de inimigos/bosses e tilesets via PixelLab API |

---

## Input Map

| Ação | Teclado |
|------|---------|
| move_left | A |
| move_right | D |
| jump | Z |
| dash | X |
| attack | J |
| special | K |
| ability_prev | Q |
| ability_next | E |
| pause | Escape |
