# Kawagael — Swap do Zael para robô verde PixelLab

**Data:** 2026-08-10
**Status:** Design (brainstorming)
**Escopo:** Substituir o Zael atual pelo personagem `bc1bd784-bffa-417e-905a-56e5aac35f67` do PixelLab (robô humanoide verde, "sleek combat robot"), mantendo 100% da mecânica de gameplay.

---

## Objetivo

Trocar por completo as sprites do personagem jogável Zael por um novo asset gerado no PixelLab, mantendo o pipeline `Kawagael extends Zael` já iniciado em `characters/ranged/kawagael/`. Todas as habilidades, controles, física, colisão e sistemas de jogo (habilidades de boss, save/load, HUD) continuam funcionando sem modificação.

## Não-objetivos

- Rebalanceamento de gameplay
- Mudanças em Zara ou nas armaduras
- Rework de shaders, VFX de tiros, ou HUD
- Portrait bust (fica pra outra iteração se necessário)
- Cobertura west separada — vamos usar `flip_h` sobre east

---

## Estado atual

**Zael hoje ([characters/ranged/zael.gd](characters/ranged/zael.gd)):**
- 13 animações em sprite sheets 68×68px, scale 2×2, `flip_h` para west
- Anims: idle 8f, run 6f, jump 4f, shoot_1/2/3 (compartilha sheet), dash 2f, wall_slide 2f, hurt 3f, death 6f, run_shoot 9f, jump_shoot 2f, dash_shoot 2f

**Scaffold Kawagael já existe** ([characters/ranged/kawagael/](characters/ranged/kawagael/)):
- `kawagael.gd` estende `Zael` e sobrescreve `_setup_sprite_frames()`
- Hoje só troca a sprite do run (versão placeholder de 5 frames); tudo o mais reusa Zael
- `.gitignore` do `_raw/` já configurado

**PixelLab (character `bc1bd784-...`):**
- 256×256px, view side, 8 rotations disponíveis (usaremos apenas east)
- 1 anim residual "stand tall" 9f east (na verdade um walk) — deixaremos órfã, não usaremos
- Orçamento: 561 gerações disponíveis

---

## Arquitetura

### Componentes

**`Kawagael` classe** ([characters/ranged/kawagael/kawagael.gd](characters/ranged/kawagael/kawagael.gd))
- Extends `Zael`
- Sobrescreve `_setup_sprite_frames()`: constrói `SpriteFrames` a partir de PNGs individuais em `characters/ranged/kawagael/anims/{anim_name}/f00.png…fNN.png`
- Sobrescreve `_update_animation()`: adiciona estados `run_start` / `run_stop` na FSM (novos)
- Se um diretório de anim não existir no disco, cai em fallback pra sheet do Zael — permite entrega incremental (mas o alvo desta implementação é ter todos os 15 diretórios preenchidos, sem fallback)

**`kawagael.tscn`** — praticamente idêntico ao `zael.tscn`, difere só em:
- `AnimatedSprite2D.scale = Vector2(0.55, 0.55)` (para bater tamanho visual do Zael)
- `AnimatedSprite2D.position.y` — ajustar em runtime para alinhar pés com colisão

**Loader helper** (`_add_anim_from_frames`) — método privado no `kawagael.gd`:
```gdscript
func _add_anim_from_frames(frames: SpriteFrames, name: String,
        dir: String, speed: float, loop: bool) -> void:
    frames.add_animation(name)
    frames.set_animation_loop(name, loop)
    frames.set_animation_speed(name, speed)
    var da := DirAccess.open(dir)
    if da == null:
        push_warning("kawagael: missing anim dir %s — check assets" % dir)
        return
    var files := da.get_files()
    files.sort()  # f00.png, f01.png, ...
    for f in files:
        if not f.ends_with(".png"): continue
        var tex := load(dir + f) as Texture2D
        if tex: frames.add_frame(name, tex)
```

### Máquina de estados de anim (mudanças vs. Zael)

Zael atual:
```
grounded + velocity.x != 0 → "run"
grounded + velocity.x == 0 → "idle"
```

Kawagael (novo):
```
idle ─[dir pressed]→ run_start ─[anim finished + still moving]→ run
                              ─[dir released before finish]→ idle
run ─[dir released]→ run_stop ─[anim finished]→ idle
run ─[dir pressed again mid-stop]→ run_start
run  + attack held → run_shoot
run_shoot + attack released → run
```

Novas vars de estado em `Kawagael`:
- `_run_phase: String` — um de `"idle"`, `"starting"`, `"cycle"`, `"stopping"`, `"shooting"`

Todos os outros estados (dash, jump, wall_slide, hurt, death, shoot 1/2/3) delegam pra lógica do Zael sem mudança.

### Convenção de layout no disco

```
characters/ranged/kawagael/
├── kawagael.gd            # existente, será reescrito
├── kawagael.tscn          # existente, ajuste de scale
├── .gitignore             # existente (_raw/)
├── _raw/                  # (gitignored) downloads brutos do PixelLab
│   ├── rotations/         # {south,east,north,west}.png full-res
│   └── animations/        # {anim}/east/{0..N}.png
├── rotations/
│   └── kawagael_east.png  # (opcional) rotation base curada
└── anims/
    ├── idle/f00.png … f07.png       # 8 frames
    ├── run_start/f00.png … f02.png  # 3 frames
    ├── run/f00.png … f04.png        # 5 frames
    ├── run_stop/f00.png … f02.png   # 3 frames
    ├── jump/f00.png … f03.png       # 4 frames
    ├── shoot_1/f00.png              # 1 frame
    ├── shoot_2/f00.png … f01.png    # 2 frames
    ├── shoot_3/f00.png … f02.png    # 3 frames
    ├── dash/f00.png … f01.png       # 2 frames
    ├── wall_slide/f00.png … f01.png # 2 frames
    ├── hurt/f00.png … f02.png       # 3 frames
    ├── death/f00.png … f05.png      # 6 frames
    ├── run_shoot/f00.png … f05.png  # 6 frames
    ├── jump_shoot/f00.png … f01.png # 2 frames
    └── dash_shoot/f00.png … f01.png # 2 frames
```

Todos os PNGs east-facing, sem sheet stitching. Cada frame é um `Texture2D` completo (256×256), passado direto pra `SpriteFrames.add_frame(name, tex)` — sem `AtlasTexture`, sem regiões manuais.

---

## Lista de animações a gerar (15 total)

Todas east-only (west sai por `_sprite.flip_h`). Prompts base parametrizados no character do PixelLab; description de cada anim substitui só o `action_description`.

| # | Anim | Frames | Loop | Speed (fps) | `action_description` para PixelLab |
|---|---|---|---|---|---|
| 1 | idle | 8 | ✓ | 8 | "sleek combat robot standing idle, subtle chest breathing, slight arm sway, weapons lowered" |
| 2 | run_start | 3 | – | 10 | "sleek combat robot transitioning from idle stance to running, leaning weight forward, first stride pushing off" |
| 3 | run | 5 | ✓ | 10 | "sleek combat robot running cycle, alternating leg strides at full pace, arms swinging naturally, weapons lowered" |
| 4 | run_stop | 3 | – | 10 | "sleek combat robot decelerating from run to a full stop, planting foot forward, weight settling back to idle" |
| 5 | jump | 4 | – | 10 | "sleek combat robot jumping: squat wind-up, takeoff push, airborne peak with legs tucked, landing crouch" |
| 6 | shoot_1 | 1 | – | 10 | "sleek combat robot firing single shot, one arm extended forward with gun, other arm braced" |
| 7 | shoot_2 | 2 | – | 10 | "sleek combat robot firing charged shot, arm extended with visible recoil kickback" |
| 8 | shoot_3 | 3 | – | 10 | "sleek combat robot firing max-charge shot, both arms brace forward with full recoil, energy discharge" |
| 9 | dash | 2 | – | 12 | "sleek combat robot ground dash, body leaning forward, one leg sliding, thrust burst behind" |
| 10 | wall_slide | 2 | ✓ | 6 | "sleek combat robot clinging to wall, sliding down slowly, facing away from wall" |
| 11 | hurt | 3 | – | 15 | "sleek combat robot taking damage, knocked back with head snap, arms flinching" |
| 12 | death | 6 | – | 10 | "sleek combat robot destroyed, falling backward, sparks and pieces breaking off, collapsing to ground" |
| 13 | run_shoot | 6 | ✓ | 10 | "sleek combat robot running cycle with arm ALWAYS extended forward holding gun ready to shoot, legs alternating strides, weapon locked in aim" |
| 14 | jump_shoot | 2 | ✓ | 10 | "sleek combat robot airborne, mid-jump, arm extended forward holding gun in aim" |
| 15 | dash_shoot | 2 | ✓ | 12 | "sleek combat robot dashing forward with arm extended holding gun, weapon locked in aim during dash" |

**Custo estimado:** 15 jobs × ~15-30 gens = 225-450 gens. Cabe no orçamento restante (561).

---

## Pipeline de geração

### Passo 1 — Baixar rotations (uma vez)
```powershell
python tools/pixellab_download.py character bc1bd784-bffa-417e-905a-56e5aac35f67 characters/ranged/kawagael/_raw/rotations/
```
(Se o `tools/pixellab_download.py` não bater com essa árvore por conta do formato, adapto num shim.)

Curar: copiar `_raw/rotations/east.png` → `rotations/kawagael_east.png` para consulta rápida.

### Passo 2 — Submeter animações
Para cada anim da tabela acima, chamar `mcp__pixellab__animate_character`:
```json
{
  "character_id": "bc1bd784-bffa-417e-905a-56e5aac35f67",
  "action_description": "<da tabela>",
  "directions": ["east"],
  "frame_count": <frames - 1>,
  "mode": "v3"
}
```

**Nota:** `frame_count: N` produz `N+1` frames (inclui frame de fechamento). Então para `run_start` de 3 frames, passamos `frame_count: 2`.

Guardar array `{anim_name → background_job_id}`.

### Passo 3 — Baixar frames
Loop de `python tools/pixellab_download.py animation <job_id> characters/ranged/kawagael/_raw/animations/ --direction east --action <anim_name>` (ou script adaptado). Cada job produz `_raw/animations/{anim}/east/0.png … N.png`.

### Passo 4 — Curar
Mover PNGs de `_raw/animations/{anim}/east/` para `anims/{anim}/f{00..NN}.png` com renomeação zero-padded. Script `tools/kawagael_curate.py` (ou equivalente PowerShell) idempotente.

### Passo 5 — Preview + aprovação
Antes de rodar no jogo, gerar HTML de preview (semelhante ao já feito para o idle candidate) com todas as 15 anims tocando lado-a-lado. Se algo estiver ruim, marcar pra regenerar.

---

## Implementação de código

### `kawagael.gd` — reescrita
- `_setup_sprite_frames()`: constrói `SpriteFrames` iterando pela tabela de 15 anims, chamando `_add_anim_from_frames()`
- `_add_anim_from_frames()`: helper que carrega PNGs de um diretório
- `_update_animation()`: sobrescreve. Delega ao `super._update_animation()` para tudo exceto o bloco run — para run, roda FSM `_run_phase`
- `_on_animation_finished()`: sobrescreve. Adiciona handling de `run_start` → `run` e `run_stop` → `idle`

### `kawagael.tscn` — ajustes
- `AnimatedSprite2D.scale`: `Vector2(0.55, 0.55)`
- `AnimatedSprite2D.position`: `Vector2(0, 35)` (mesmo do Zael por enquanto — calibrar visualmente)

### Wiring em `stages/stage_scene.gd`
Localizar onde `Zael` é instanciado (via `preload("res://characters/ranged/zael.tscn").instantiate()`) e trocar por `preload("res://characters/ranged/kawagael/kawagael.tscn").instantiate()`. Como `Kawagael extends Zael`, `is Zael` continua verdadeiro, `class_name` bate para checagens externas.

**Impacto:** todo lugar do código que faz `is Zael`, `player as Zael`, ou lê `zael_selected_shot` continua correto — o GameManager não precisa saber que o Kawagael existe.

---

## Testes

### Novos
`tests/test_kawagael.tscn` + `tests/test_kawagael.gd`:
- Instancia `Kawagael`
- Verifica `_sprite.sprite_frames.get_animation_names()` inclui todas as 15 anims esperadas
- Verifica frame count de cada uma (5 frames em `run`, 8 em `idle`, etc.)
- Verifica loop flags corretas
- Verifica que `Kawagael is Zael` retorna true (garantia de compatibilidade)

### Regressão
Rodar após:
- `tests/test_character_base.tscn` — base não muda, deve continuar verde
- `tests/test_game_manager.tscn` — active_character logic não muda
- Qualquer teste que instancia Zael diretamente (grep para confirmar zero regressões)

### Verificação visual
Via `run` skill, abrir stage_01 com Kawagael ativo. Screenshots em: idle parado, run (após run_start), run_stop (soltar direcional), jump peak, dash, wall_slide, hurt, death, shoot_3 carregado.

---

## Riscos & mitigações

| Risco | Mitigação |
|---|---|
| Anim gerada fica ruim (personagem se desmontando, quebrando design) | Preview antes de curar; regenerar com `action_description` mais restritiva. Cada anim isolada = fácil de re-fazer. |
| Scale 0.55 fica desproporcional (muito grande/pequeno vs. inimigos) | Calibrar em runtime via browser preview. Ajustar `scale` é 1 linha de edit no .tscn. |
| PNGs com padding/canvas diferentes por anim (PixelLab é inconsistente) | Loader do Kawagael centraliza sprite — usa `position` do AnimatedSprite2D pra corrigir por-anim se necessário. Provavelmente todas as anims do mesmo character saem no mesmo canvas 256×256. |
| FSM run_start/run_stop introduz bug (fica travado num estado) | Testar transições no test_kawagael + verificação visual. Fallback: se `_run_phase` fica em estado inválido por > 0.5s + player não está em ação especial, força reset pra idle. |
| Tools/pixellab_download.py não bate com layout `anims/{anim}/fNN.png` | Adaptar via shim curto (`tools/kawagael_curate.py` ou PowerShell inline) — não bloqueia geração. |
| Anims run_shoot/jump_shoot/dash_shoot com arm-extended saem mal (PixelLab confunde "braço estendido" ao longo do ciclo) | Prompt força "arm ALWAYS extended, weapon locked in aim" — se falhar, iteração de prompt. Pior caso, fallback pra Zael nessas 3 anims. |

---

## Ordem de execução (para o plan)

1. **Downloads iniciais** — rotations do PixelLab, criação da árvore `_raw/`
2. **Submissão dos 15 jobs de animação** — em paralelo (o PixelLab é async)
3. **Aguardar completar** — poll via `get_character` até todas prontas (~10-30 min)
4. **Baixar frames** — script adaptado, salva em `_raw/animations/{anim}/east/`
5. **Preview HTML** — artifact com todas as 15 anims tocando; user aprova ou marca reruns
6. **Curar** — mover pra `anims/{anim}/fNN.png`
7. **Reescrever kawagael.gd + tscn** — loader + FSM run_start/run_stop, scale ajustado
8. **Trocar wiring em stage_scene.gd** — 1 preload substituído
9. **Testes** — novos + regressão
10. **Verificação visual** — browser preview do stage_01
11. **Commit + PR** — feature/kawagael-swap-zael

---

## Definição de "pronto"

- [ ] 15 anims curadas em `characters/ranged/kawagael/anims/`
- [ ] `kawagael.gd` reescrito com loader + FSM
- [ ] `kawagael.tscn` com scale correto
- [ ] `stage_scene.gd` instancia Kawagael no lugar de Zael
- [ ] `test_kawagael.tscn` verde (15 anims, frame counts, loop flags corretos)
- [ ] Testes de regressão (`test_character_base`, `test_game_manager`) verdes
- [ ] Playthrough visual do stage_01 sem glitches: idle, run_start/run/run_stop, jump, dash, wall_slide, hurt, death, shoot_1/2/3, run_shoot, jump_shoot, dash_shoot
- [ ] `active_character == "zael"` continua funcionando (drop-in)
