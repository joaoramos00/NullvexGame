# Skills, Agents e Contexto do Jogo — Design Spec

> **For agentic workers:** Use superpowers:writing-plans to create an implementation plan from this spec.

**Goal:** Criar 5 skills locais (`/new-enemy`, `/new-boss`, `/new-stage`, `/run-tests`, `/web-export`) e um arquivo `GAME_CONTEXT.md` que dão a Claude contexto profundo do projeto e capacidade de gerar boilerplate completo para novos inimigos, bosses e stages.

**Architecture:** Skill files em `.claude/skills/` registrados em `settings.json`; `GAME_CONTEXT.md` na raiz referenciado no `CLAUDE.md`; cada skill contém templates de código inline para `.gd`, `.tscn` e arquivos de teste.

**Tech Stack:** GDScript 4 / Godot 4.6.2, Markdown, JSON (settings.json)

---

## 1. GAME_CONTEXT.md

Arquivo na raiz do projeto. Referenciado no `CLAUDE.md` para ser lido sempre que Claude precisar de contexto do jogo.

### 1.1 Seções obrigatórias

**Visão Geral**
- Engine, resolução, estilo
- Personagens jogáveis (Zael ranged, Zara melee)
- Estrutura de fases (00 → 01-08 → 09-11)

**Collision Layers**
```
Layer 1 "world"         → valor 1  — terrain/StaticBody2D
Layer 2 "player"        → valor 2  — CharacterBase
Layer 3 "enemy"         → valor 4  — EnemyBase / BossBase
Layer 4 "player_attack" → valor 8  — ZaelBullet / ZaraHitbox
```

**Tabela de Bosses**
| stage_id | boss_id    | weakness_id | ability_id | boss_color                   |
|----------|------------|-------------|------------|------------------------------|
| 1        | ignarath   | galerix     | ignarath   | Color(0.9, 0.3, 0.0)        |
| 2        | cryovex    | ignarath    | cryovex    | Color(0.3, 0.7, 1.0)        |
| 3        | voltrix    | terragor    | voltrix    | Color(1.0, 0.9, 0.0)        |
| 4        | gravitus   | luxar       | gravitus   | Color(0.5, 0.0, 0.8)        |
| 5        | galerix    | gravitus    | galerix    | Color(0.4, 0.9, 0.4)        |
| 6        | umbraex    | voltrix     | umbraex    | Color(0.2, 0.0, 0.3)        |
| 7        | luxar      | umbraex     | luxar      | Color(1.0, 1.0, 0.6)        |
| 8        | terragor   | cryovex     | terragor   | Color(0.5, 0.3, 0.1)        |
| 0        | intro_boss | —           | —          | (custom, não segue o padrão) |

**Autoloads e suas APIs**
- `GameManager` — `reset()`, `set_active_character(c)`, `active_character`, `max_hp`, `lives`, `complete_stage(id)`, `unlock_ability(id)`, `has_save()`, `save_game()`, `load_game()`
- `StageManager` — `current_stage_id`, `spawn_position`, `save_checkpoint(pos, idx)`, `get_respawn_position()`
- `AudioManager` — `play_bgm(stream)`, `play_sfx(stream)`, `play_bgm(null)` e `play_sfx(null)` são no-ops seguros
- `AudioLibrary` — `bgm_intro`, `get_stage_bgm(id)`, `sfx_enemy_death`, `sfx_boss_damage`, `sfx_boss_death`, `sfx_jump`, `sfx_shoot`, `sfx_collectible`

**Padrão EnemyBase**
- Herda: `CharacterBody2D`
- Collision: `layer=4 (enemy)`, `mask=1 (world)`
- ContactZone Area2D: `layer=0`, `mask=2 (player)` → dispara `_on_contact`
- `take_damage(amount: int, _source: String = "")` — interface pública
- `_draw()` — desenha o sprite via código; usar `draw_rect` centrado no origin
- Capsule: `radius=20, height=40` (total 80px) como referência de tamanho

**Padrão BossBase**
- Herda: `CharacterBody2D`
- @exports obrigatórios: `boss_id`, `weakness_id`, `ability_id`, `stage_id`, `max_hp`, `boss_color`
- @exports opcionais: `arena_left/right/floor`, `attack_interval_p1/p2`, `phase2_threshold`
- Sobrescrever: `_do_combat(delta)`, `_do_attack()`, `_enter_phase_2()`
- `_spawn_projectile(pos, vel, dmg, src, col)` disponível na base
- `_face_player()`, `_clamp_to_arena()` disponíveis na base

**Padrão Stage Simples (stages 01–08)**
- Usa `stage_scene.gd` como script (sem GD customizado)
- Plataformas como `StaticBody2D` + `RectangleShape2D` na cena
- Boss instanciado com `arena_left/right/floor` definidos
- 2 Checkpoints (`checkpoint_index = 1` e `2`)
- PlayerSpawn, StageController, HUD, PauseMenu, GameOver, StageComplete, Camera2D

**Padrão Stage Complexo (stage_00)**
- GD customizado extends `Node2D` (não `stage_scene.gd`)
- Zonas de inimigos com respawn (Array de posições por zona)
- Portas de checkpoint (`checkpoint_door.tscn`) com `CP_ENTRY_X` / `CP_EXIT_X`
- Boss room isolado com `Boss_LWall` (collision disabled até boss door abrir)
- `_draw()` com background + plataformas via tileset (`_draw_platform_tiles`)
- Camera2D com `limit_left/top/bottom/right` definidos

**Padrão de Testes**
```gdscript
extends Node
func _ready() -> void:
    test_X()
    print("ALL TESTS PASSED")
    get_tree().quit(0)
func test_X() -> void:
    # arrange / act / assert
    print("PASS: X")
```
- Arquivo `.gd` + `.tscn` associada (`extends Node`, NÃO `SceneTree`)
- Rodar: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_X.tscn`

---

## 2. Skill: `/new-enemy`

**Arquivo:** `.claude/skills/new-enemy.md`

**Quando usar:** Usuário pede para criar um novo tipo de inimigo.

**Informações a coletar do usuário:**
1. Nome em snake_case (ex: `enemy_jumper`)
2. Cor (ex: `Color(0.8, 0.2, 0.2)`)
3. Comportamento: `ground_patrol` | `flyer` | `jumper` | `shooter`

**Arquivos gerados:**
- `characters/enemies/<nome>.gd`
- `characters/enemies/<nome>.tscn`
- `tests/test_<nome>.gd`
- `tests/test_<nome>.tscn`

**Template `.gd` por comportamento:**

*ground_patrol* — igual ao `EnemyBase`, sobrescreve `_draw()` com nova cor. Nenhum override de `_physics_process`.

*flyer* — igual ao `EnemyFlyer`: sem gravidade, sem detecção de borda, patrulha horizontal com `patrol_range`.

*jumper* — herda `EnemyBase`, adiciona lógica de salto periódico: `_jump_timer` que dispara `velocity.y = -JUMP_SPEED` quando no chão.

*shooter* — herda `EnemyBase`, adiciona `_shoot_timer` que instancia `_PROJECTILE_SCENE` (reusar `boss_projectile.tscn`) na direção do player.

**Template `.tscn`:** Herdar de `enemy_base.tscn`, sobrescrever script.

**Template de teste:** Testa `initial_hp`, `take_damage`, `invincibility`, `death`.

---

## 3. Skill: `/new-boss`

**Arquivo:** `.claude/skills/new-boss.md`

**Quando usar:** Usuário pede para criar um novo boss.

**Informações a coletar:**
1. Nome em snake_case (ex: `pyrovex`)
2. `boss_id` (string, geralmente = nome)
3. `weakness_id` (ability_id de outro boss)
4. `ability_id` (string que será desbloqueada ao derrotar)
5. `stage_id` (int, 1–11 ou novo)
6. `boss_color` (Color GDScript)
7. Padrão de ataque fase 1 (livre, Claude sugere baseado no tema)
8. Diferença na fase 2 (mais projéteis, velocidade, novo padrão)

**Arquivos gerados:**
- `characters/bosses/<nome>.gd`
- `characters/bosses/<nome>.tscn`
- `tests/test_<nome>.gd`
- `tests/test_<nome>.tscn`

**Template `.gd`:**
```gdscript
extends BossBase

func _do_combat(delta: float) -> void:
    # movimento em direção ao player com clamp
    _face_player()
    _clamp_to_arena()

func _do_attack() -> void:
    _is_attacking = true
    # lógica de ataque fase 1
    _is_attacking = false

func _enter_phase_2() -> void:
    attack_interval_p2 = <valor menor>
    # mudança de comportamento fase 2
```

**Template `.tscn`:** Herdar de `boss_base.tscn`, sobrescrever script e definir todos os @exports.

**Template de teste:** Testa `initial_hp`, `take_damage`, `weakness_multiplier`, `phase_transition`, `defeat`.

---

## 4. Skill: `/new-stage`

**Arquivo:** `.claude/skills/new-stage.md`

**Quando usar:** Usuário pede para criar uma nova fase.

**Informações a coletar:**
1. `stage_id` (int)
2. Nome descritivo (ex: `volcano`, `ice_cave`)
3. Boss para essa fase (deve existir em `characters/bosses/`)
4. Estilo: `simple` (usa `stage_scene.gd`) | `complex` (GD customizado com zonas)
5. Tema visual (paleta de cores, tipo de cenário — Claude gera `_draw()`)
6. `platform_color` (Color para as plataformas)

**Arquivos gerados:**
- `stages/stage_<id>/stage_<id>.tscn`
- `stages/stage_<id>/stage_<id>_scene.gd` (apenas se `complex`)
- `tests/test_stage_<id>.gd` + `.tscn`

**Template simple:** Baseado em `stage_01.tscn` — plataformas estáticas, boss instanciado com arena, 2 checkpoints, 4 grunts + 1 flyer, 1 heart collectible, câmera com limites.

**Template complex:** Baseado em `stage_00_scene.gd` + `stage_00.tscn` — 3 zonas, respawn de inimigos, portas de checkpoint, boss room isolado, `_draw()` com background temático.

---

## 5. Skill: `/run-tests`

**Arquivo:** `.claude/skills/run-tests.md`

**Quando usar:** Usuário quer rodar testes.

**Comportamento:**
- Sem argumento: roda todos os 19 arquivos de teste em sequência
- Com argumento (ex: `/run-tests enemy_base`): roda só `tests/test_enemy_base.tscn`
- Para cada teste: executa o comando headless, lê saída, extrai linhas `PASS:` e detecta erros
- Reporta: tabela de resultados com ✅/❌ por teste, tempo total

**Comando base:**
```
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_<nome>.tscn
```

**Saída esperada:** `ALL TESTS PASSED` → ✅; qualquer `assert` falhando → ❌ com mensagem.

---

## 6. Skill: `/web-export`

**Arquivo:** `.claude/skills/web-export.md`

**Quando usar:** Usuário quer exportar e publicar o build web.

**Passos:**
1. Rodar: `"D:/Godot_v4.6.2-stable_win64/..." --headless --path . --export-release "Web" export/web/index.html`
2. Verificar se `export/web/index.html` existe
3. `git add export/web/`
4. `git commit -m "chore: web export"`
5. `git push`

**Mensagem de commit:** usar descrição do que mudou se o usuário fornecer, senão `"chore: web export"`.

---

## 7. Atualização do CLAUDE.md

Adicionar seção **Skills Disponíveis** com tabela de skills + trigger, e linha `## Contexto do Jogo` apontando para `GAME_CONTEXT.md`.

---

## 8. Registro em settings.json

Skills locais precisam ser registradas em `.claude/settings.json` para aparecer como slash commands. Adicionar entrada `"skills"` com os 5 skills mapeados para seus arquivos `.md`.

```json
"skills": {
  "new-enemy":   ".claude/skills/new-enemy.md",
  "new-boss":    ".claude/skills/new-boss.md",
  "new-stage":   ".claude/skills/new-stage.md",
  "run-tests":   ".claude/skills/run-tests.md",
  "web-export":  ".claude/skills/web-export.md"
}
```

---

## Ordem de implementação

1. `GAME_CONTEXT.md` — base para todas as outras
2. `.claude/skills/new-enemy.md`
3. `.claude/skills/new-boss.md`
4. `.claude/skills/new-stage.md`
5. `.claude/skills/run-tests.md`
6. `.claude/skills/web-export.md`
7. Atualizar `CLAUDE.md`
8. Registrar em `settings.json`
