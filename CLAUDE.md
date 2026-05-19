# NullvexGame — CLAUDE.md

## Visão Geral

Jogo de plataforma e ação 2D inspirado em Mega Man X4. IP original. Dois personagens jogáveis (Zael e Zara), 12 fases, 8 bosses elementais com cadeia de fraquezas lógica, e vilão final Nullvex.

**Engine:** Godot 4.6.2 (GDScript)
**Resolução:** 1920×1080 nativo
**Estilo Visual:** HD Pixel Art
**Godot executável:** `D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe`

---

## Como Rodar Testes

```bash
# A partir de C:\Users\Usuário\SnesGame
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_stage_manager.tscn
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```

**Importante:** Testes usam `extends Node` + `.tscn` associada. NÃO usar `extends SceneTree` — esse modo não carrega autoloads do projeto.

---

## Estado Atual

### Plano 01 — Fundação ✅ (completo)

| Arquivo | Descrição |
|---------|-----------|
| `project.godot` | Config do projeto: 1080p, pixel filter, input map, autoloads |
| `autoloads/game_manager.gd` | Estado persistente, unlocks, save/load JSON |
| `autoloads/stage_manager.gd` | Fase atual, checkpoints, spawn |
| `autoloads/audio_manager.gd` | BGM com fade, pool de 8 SFX players |
| `characters/base/character_base.gd` | Movimento, pulo duplo, dash, HP, dano, invencibilidade |
| `characters/base/character_base.tscn` | Cena base com CollisionShape2D + Sprite2D |
| `scenes/test_level.tscn` | Cena de teste manual de movimento |

### Planos Pendentes

| Plano | Conteúdo |
|-------|----------|
| **Plan 02** ← próximo | Zael — 5 tipos de tiro, sistema de carga |
| Plan 03 | Zara — 5 armas, sistema de combo (2 golpes + finisher) |
| Plan 04 | Sistema de combate — Hitbox/Hurtbox, inimigos base |
| Plan 05 | Sistema de fases — carregamento, checkpoints, vidas, StageController |
| Plan 06 | Colectáveis — corações, sub-tanks, armaduras, armas/tiros |
| Plan 07 | Bosses — base, 8 bosses com fraquezas, Nullvex |
| Plan 08 | UI/Menus — HUD, pausa, stage select, title screen |
| Plan 09 | Save/Load final + fluxo completo de jogo |

---

## Arquitetura

- **Autoloads** comunicam exclusivamente via sinais — sem chamadas diretas entre sistemas
- **GameManager** — estado persistente (lives, max_hp, unlocks, armaduras, save/load)
- **StageManager** — fase atual, checkpoints, posição de spawn
- **AudioManager** — BGM fade, pool SFX
- **CharacterBase** — HP in-game (inicia com `GameManager.max_hp`), morre emitindo `died`
- Um **StageController** (Plan 05) vai conectar `CharacterBase.died` ao `GameManager.lose_life()`

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
