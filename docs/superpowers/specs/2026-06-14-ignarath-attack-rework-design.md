# Spec — Ajustes no Boss Ignarath (Stage 01)

**Data:** 2026-06-14
**Arquivos afetados:** `characters/bosses/ignarath.gd`, `characters/bosses/ignarath.tscn`, novo `characters/bosses/ignarath/fire_beam.gd`, `characters/bosses/ignarath/fire_wave.gd` (reuso), remover `characters/bosses/ignarath/fire_patch.gd` (+ web export ao final)

## Objetivo

Quatro ajustes no Ignarath, mantendo a regra de invulnerabilidade já existente
(blindado durante os ataques; a fraqueza do Galerix fura o escudo, dá dano 2× e
interrompe a ação via `_attack_gen`/`_break_action`).

## Decisões (do brainstorm)

### #1 — Tamanho e posição
- `scale = Vector2(0.8, 0.8)` no `_ready` (era `1.0`). Escala o nó inteiro (sprite + capsule).
- **Subir 32px = offset do `Sprite2D` pra cima** (corrige o boss "afundado" no chão).
  A colisão/pés ficam no lugar. Como o `Sprite2D` é filho do nó escalado (0.8), o
  offset em coords locais é `-32 / 0.8 = -40` pra resultar em ~32px de mundo. Definir
  `Sprite2D.position = Vector2(0, -40)` no `ignarath.tscn`.

### #2 — Firebreath = beam que varre (estilo Godzilla)
Substitui o firebreath atual (onda alta que viaja). Novo `fire_beam.gd`:
- Feixe que sai da **boca** do Ignarath e vai até o **chão** (`arena_floor`).
- Começa **vertical (0° em relação à vertical)** e **varre pra fora** em direção ao
  player (ângulo abrindo até `max_angle`), o ponto de contato no chão **avançando**
  em direção ao player.
- A **linha inteira do beam machuca**: checagem distância-ponto-a-segmento por frame
  contra a posição do player; se `< half_width`, `player.take_damage(FIRE_DAMAGE, "ignarath")`
  (os i-frames do player espaçam os hits).
- **Sprite estático** no frame de firebreath durante a varredura (não cicla animação).
- Origem (boca): `boss.global_position + Vector2(_facing * MOUTH_DX, MOUTH_DY)`.
  Valores tunáveis (defaults: `MOUTH_DX = 24`, `MOUTH_DY = -40`, já considerando scale 0.8).
- Params (consts em `ignarath.gd`, tunáveis):
  - `BEAM_SWEEP_TIME_P1 = 1.0`, `BEAM_SWEEP_TIME_P2 = 0.7`
  - `BEAM_MAX_ANGLE = 70.0` (graus a partir da vertical)
  - `BEAM_HALF_WIDTH = 20.0`
  - dano = `FIRE_DAMAGE` (12)
- Boss **invulnerável durante toda a varredura** (`_invuln = true` no início, `false` no fim).
- **Fraqueza fura e interrompe**: `_break_action()` deve também remover/`queue_free` o
  beam ativo. `_do_firebreath` guarda referência ao beam; ao detectar `gen != _attack_gen`,
  o beam é liberado.
- `fire_beam.gd` não usa colisão física (Area2D) — é `Node2D` com `_draw` + checagem
  manual, recebendo `player`, `origin`, `facing`, `floor_y`, params, e se autodestrói
  ao terminar a varredura (`_t >= sweep_time + 0.15`).

### #3 — Claw = ataque à distância + fogo rasteiro que viaja
- Remove a exigência `CLAW_MIN_RANGE` (a garra **sempre** executa, em qualquer distância).
- No instante do golpe:
  - **Corpo-a-corpo**: se `distance <= CLAW_RANGE` (130px), `player.take_damage(CLAW_DAMAGE)` (18).
  - **Fogo rasteiro**: lança uma onda **baixa** (`fire_wave.gd` com `wave_h ≈ 56`) que
    viaja pelo chão na direção `_facing` até bater na parede (`despawn_x` = parede oposta).
    Baixa o bastante pra ser **pulada** (não força wall-jump).
- Mantém a janela de invulnerabilidade no instante do golpe (`CLAW_INVULN_WINDOW`).
- Remove `fire_patch.gd` (poça estática) — substituído pela onda rasteira.
- Constantes da onda rasteira da garra: `CLAW_WAVE_H = 56`, `CLAW_WAVE_W = 90`,
  `CLAW_WAVE_SPEED_P1 = 300`, `CLAW_WAVE_SPEED_P2 = 400`, dano = `FIRE_DAMAGE` (12).

### #4 — Bloco vermelho no teste de batalha
- Override `func _draw() -> void: pass` em `ignarath.gd` → remove o retângulo
  placeholder + barra de HP do `BossBase._draw`. Fica só o `Sprite2D`; o HP do boss
  é exibido pelo HUD (`connect_to_boss`).

## Componentes

| Arquivo | Mudança |
|---------|---------|
| `characters/bosses/ignarath/fire_beam.gd` | **Novo** — beam que varre (firebreath) |
| `characters/bosses/ignarath/fire_wave.gd` | Reaproveitado pela garra (altura baixa) — sem mudança de código necessária |
| `characters/bosses/ignarath/fire_patch.gd` | **Removido** |
| `characters/bosses/ignarath.gd` | `_ready` scale 0.8; `_draw` vazio; `_do_firebreath` → beam; `_do_claw` ranged + onda baixa; `_break_action` libera o beam; remove `_spawn_fire_patch`; remove preload `_FIRE_PATCH`; ajusta consts |
| `characters/bosses/ignarath.tscn` | `Sprite2D.position = (0, -40)` |

## Mantido (não muda)
- Regra de invulnerabilidade + fraqueza (Galerix) furando o escudo e interrompendo
  a ação (`_attack_gen` / `_break_action` / `take_damage`).
- Aggro ao entrar na sala, fases (p1/p2), movimento de perseguição.

## Validação
- `test_boss_battle` (instancia os 11 bosses em COMBAT) deve continuar EXIT=0.
- Load headless de `stage_01` e `img_debug` sem `SCRIPT ERROR` (ignorar avisos de
  áudio e o miniboss já corrigido).
- Checks de runtime: firebreath spawna o beam e varre; garra lança a onda baixa e
  dá corpo-a-corpo quando perto; fraqueza interrompe e remove o beam; `_draw` não
  desenha o bloco vermelho.
- **Web export** ao final + reiniciar localhost (convenção do projeto).
