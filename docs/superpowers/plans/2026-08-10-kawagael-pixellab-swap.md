# Kawagael — Swap do Zael para robô verde PixelLab — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trocar todas as sprites do Zael pelo personagem PixelLab `bc1bd784-bffa-417e-905a-56e5aac35f67` (robô humanoide verde "sleek combat robot"), mantendo 100% da mecânica de jogo via `Kawagael extends Zael`.

**Architecture:** `Kawagael` estende `Zael` sobrescrevendo `_setup_sprite_frames()` (novo loader lê PNGs individuais de `characters/ranged/kawagael/anims/{name}/fNN.png`, sem sheet stitching) e `_update_animation()` (adiciona FSM `_run_phase` com transições `idle → run_start → run → run_stop → idle`, e `run ↔ run_shoot` conforme input de tiro). `stage_scene.gd` troca 1 `preload` de Zael para Kawagael — todo o resto do jogo (habilidades, HUD, save/load, `is Zael` checks) continua funcionando.

**Tech Stack:** Godot 4.6.2 (GDScript), PixelLab MCP (`mcp__pixellab__*` tools), PowerShell (download/curate scripts em Windows).

## Global Constraints

- Godot version: **4.6.2** (`D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe`)
- Todas as animações são **east-only** — west sai por `_sprite.flip_h = not facing_right` (já é o comportamento do Zael base)
- Cada frame é um `Texture2D` completo 256×256px passado direto pra `SpriteFrames.add_frame()` — **não usar `AtlasTexture` nem regiões manuais**
- Assets brutos em `characters/ranged/kawagael/_raw/` ficam **gitignored** (o `.gitignore` já existe)
- `Kawagael extends Zael` — **não modificar `zael.gd` nem `character_base.gd`** durante este plano
- Chave de API PixelLab lida via `.env` (não commitar) — MCP tools já autenticadas por sessão
- Tests headless: `Start-Process -Wait` (memory: `godot-cli-windows-quirk` — `--headless` sozinho detacha silenciosamente)
- Commits pequenos, um por task quando faz sentido; mensagens em português com prefixo convencional (`feat(kawagael):`, `test(kawagael):`, `chore(kawagael):`)

---

### Task 1: Baseline check + estrutura de diretórios

**Files:**
- Create: `characters/ranged/kawagael/anims/.gitkeep`
- Create: `characters/ranged/kawagael/rotations/.gitkeep`
- Modify: `characters/ranged/kawagael/.gitignore` (garantir que `_raw/` está ignorado)

**Interfaces:**
- Produces: layout `characters/ranged/kawagael/{anims,rotations,_raw}/` pronto para receber assets

- [ ] **Step 1: Confirmar que estamos no worktree correto**

```bash
pwd
git branch --show-current
```

Expected: `.claude/worktrees/zael-pixellab-swap` on branch `worktree-zael-pixellab-swap`.

- [ ] **Step 2: Rodar suite de baseline (3 test scenes core)**

```powershell
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_game_manager.tscn"
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_stage_manager.tscn"
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_character_base.tscn"
```

Expected: cada uma imprime "=== All ... tests passed ===" no final. Se algo falhar, PARAR e reportar antes de continuar.

- [ ] **Step 3: Criar diretórios de destino com .gitkeep**

```powershell
New-Item -ItemType Directory -Force -Path characters/ranged/kawagael/anims | Out-Null
New-Item -ItemType Directory -Force -Path characters/ranged/kawagael/rotations | Out-Null
New-Item -ItemType File -Force -Path characters/ranged/kawagael/anims/.gitkeep | Out-Null
New-Item -ItemType File -Force -Path characters/ranged/kawagael/rotations/.gitkeep | Out-Null
```

- [ ] **Step 4: Verificar `.gitignore` do kawagael**

Ler `characters/ranged/kawagael/.gitignore` — deve conter `_raw/`. Se não tiver, adicionar. Deve haver:
```
_raw/
```

- [ ] **Step 5: Commit**

```bash
git add characters/ranged/kawagael/anims/.gitkeep characters/ranged/kawagael/rotations/.gitkeep characters/ranged/kawagael/.gitignore
git commit -m "chore(kawagael): scaffold anims/ e rotations/ pra receber assets PixelLab"
```

---

### Task 2: Submeter os 15 jobs de animação no PixelLab

**Files:**
- Create: `characters/ranged/kawagael/_raw/job_ids.json` (mapa `{anim_name: job_id}`)

**Interfaces:**
- Consumes: character existente `bc1bd784-bffa-417e-905a-56e5aac35f67` no PixelLab
- Produces: 15 background jobs em execução no PixelLab, IDs salvos em `_raw/job_ids.json`

**⚠️ CHECKPOINT:** Esta task consome ~225-450 gerações da conta PixelLab. Antes de submeter, confirmar com o usuário via `AskUserQuestion` que pode prosseguir.

- [ ] **Step 1: Checkpoint com usuário**

Perguntar: "Vou submeter 15 jobs de animação no PixelLab agora (~225-450 gerações). Prossigo?"

- [ ] **Step 2: Confirmar créditos disponíveis**

Chamar `mcp__pixellab__get_balance`. Verificar que `generations_remaining >= 450` (margem de segurança). Se menor, avisar usuário antes de continuar.

- [ ] **Step 3: Submeter os 15 jobs de animação**

Chamar `mcp__pixellab__animate_character` uma vez por anim. Ordem e parâmetros:

| # | anim_name | frame_count | action_description |
|---|---|---|---|
| 1 | idle | 7 | "sleek combat robot standing idle, subtle chest breathing, slight arm sway, weapons lowered" |
| 2 | run_start | 2 | "sleek combat robot transitioning from idle stance to running, leaning weight forward, first stride pushing off" |
| 3 | run | 4 | "sleek combat robot running cycle, alternating leg strides at full pace, arms swinging naturally, weapons lowered" |
| 4 | run_stop | 2 | "sleek combat robot decelerating from run to a full stop, planting foot forward, weight settling back to idle" |
| 5 | jump | 3 | "sleek combat robot jumping: squat wind-up, takeoff push, airborne peak with legs tucked, landing crouch" |
| 6 | shoot_1 | 0 | "sleek combat robot firing single shot, one arm extended forward with gun, other arm braced" |
| 7 | shoot_2 | 1 | "sleek combat robot firing charged shot, arm extended with visible recoil kickback" |
| 8 | shoot_3 | 2 | "sleek combat robot firing max-charge shot, both arms brace forward with full recoil, energy discharge" |
| 9 | dash | 1 | "sleek combat robot ground dash, body leaning forward, one leg sliding, thrust burst behind" |
| 10 | wall_slide | 1 | "sleek combat robot clinging to wall, sliding down slowly, facing away from wall" |
| 11 | hurt | 2 | "sleek combat robot taking damage, knocked back with head snap, arms flinching" |
| 12 | death | 5 | "sleek combat robot destroyed, falling backward, sparks and pieces breaking off, collapsing to ground" |
| 13 | run_shoot | 5 | "sleek combat robot running cycle with arm ALWAYS extended forward holding gun ready to shoot, legs alternating strides, weapon locked in aim" |
| 14 | jump_shoot | 1 | "sleek combat robot airborne, mid-jump, arm extended forward holding gun in aim" |
| 15 | dash_shoot | 1 | "sleek combat robot dashing forward with arm extended holding gun, weapon locked in aim during dash" |

**Nota importante:** `frame_count: N` produz `N+1` frames. As colunas acima já subtraem 1 dos targets do spec (idle=8 frames → frame_count=7, etc.).

Para cada, `directions: ["east"]`, `mode: "v3"`, `character_id: "bc1bd784-bffa-417e-905a-56e5aac35f67"`.

Guardar cada `job_id` retornado no array `background_job_ids[0]`.

- [ ] **Step 4: Salvar mapa anim→job_id**

Escrever `characters/ranged/kawagael/_raw/job_ids.json` com formato:
```json
{
  "idle": "<job_id>",
  "run_start": "<job_id>",
  "run": "<job_id>",
  ... (15 entries total)
}
```

- [ ] **Step 5: Commit (só o mapa, sem os frames ainda)**

```bash
git add characters/ranged/kawagael/_raw/job_ids.json
git commit -m "chore(kawagael): submete 15 jobs de anim no PixelLab (job_ids.json)"
```

**Nota:** normalmente `_raw/` está gitignored, mas o `job_ids.json` é minúsculo e útil pra retomar em caso de falha — commitamos essa exceção. O `.gitignore` precisa ser ajustado ou usamos `git add -f`.

Ajuste alternativo: adicionar `!_raw/job_ids.json` no `.gitignore`.

---

### Task 3: Test infrastructure — smoke test do Kawagael

**Files:**
- Create: `tests/test_kawagael.tscn`
- Create: `tests/test_kawagael.gd`

**Interfaces:**
- Consumes: `characters/ranged/kawagael/kawagael.tscn` (existente)
- Produces: test scene que valida Kawagael instancia, herda Zael, e tem SpriteFrames com anims esperadas

- [ ] **Step 1: Criar test_kawagael.tscn (mínimo)**

Ver estrutura de `tests/test_game_manager.tscn` como referência. Criar:

```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/test_kawagael.gd" id="1"]
[node name="TestKawagael" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Escrever teste inicial (falhando ou verde conforme estado)**

`tests/test_kawagael.gd`:

```gdscript
extends Node

const EXPECTED_ANIMS := [
    "idle", "run_start", "run", "run_stop", "jump",
    "shoot_1", "shoot_2", "shoot_3", "dash", "wall_slide",
    "hurt", "death", "run_shoot", "jump_shoot", "dash_shoot",
]
const EXPECTED_FRAMES := {
    "idle": 8, "run_start": 3, "run": 5, "run_stop": 3, "jump": 4,
    "shoot_1": 1, "shoot_2": 2, "shoot_3": 3, "dash": 2, "wall_slide": 2,
    "hurt": 3, "death": 6, "run_shoot": 6, "jump_shoot": 2, "dash_shoot": 2,
}

func _ready() -> void:
    test_kawagael_instantiates()
    test_kawagael_is_zael_subclass()
    test_kawagael_has_all_animations()
    test_kawagael_frame_counts()
    print("=== All Kawagael tests passed ===")
    get_tree().quit()

func test_kawagael_instantiates() -> void:
    var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
    assert(scene != null, "kawagael.tscn missing")
    var kawa := scene.instantiate()
    assert(kawa != null, "instantiate() failed")
    kawa.free()
    print("PASS: test_kawagael_instantiates")

func test_kawagael_is_zael_subclass() -> void:
    var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
    var kawa := scene.instantiate()
    add_child(kawa)  # required for _ready() to fire
    await get_tree().process_frame
    assert(kawa is Zael, "Kawagael must inherit Zael (needed for is-checks across the code)")
    kawa.queue_free()
    print("PASS: test_kawagael_is_zael_subclass")

func test_kawagael_has_all_animations() -> void:
    var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
    var kawa := scene.instantiate()
    add_child(kawa)
    await get_tree().process_frame
    var sprite: AnimatedSprite2D = kawa.get_node("AnimatedSprite2D")
    var got := sprite.sprite_frames.get_animation_names()
    for anim in EXPECTED_ANIMS:
        assert(anim in got, "missing animation: %s (got %s)" % [anim, got])
    kawa.queue_free()
    print("PASS: test_kawagael_has_all_animations")

func test_kawagael_frame_counts() -> void:
    var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
    var kawa := scene.instantiate()
    add_child(kawa)
    await get_tree().process_frame
    var sprite: AnimatedSprite2D = kawa.get_node("AnimatedSprite2D")
    for anim in EXPECTED_ANIMS:
        var got := sprite.sprite_frames.get_frame_count(anim)
        var want: int = EXPECTED_FRAMES[anim]
        assert(got == want, "anim %s: expected %d frames, got %d" % [anim, want, got])
    kawa.queue_free()
    print("PASS: test_kawagael_frame_counts")
```

- [ ] **Step 3: Rodar teste — esperado FALHAR**

```powershell
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_kawagael.tscn"
```

Expected: FAIL. Motivos possíveis:
- `test_kawagael_has_all_animations` falha porque hoje o Kawagael só tem anims herdadas do Zael no atalho — vai faltar `run_start`, `run_stop`
- Frame counts também vão bater errado (Zael tem run=6, esperamos run=5)

Isto documenta o gap: as tasks seguintes vão fazer o teste passar.

- [ ] **Step 4: Commit**

```bash
git add tests/test_kawagael.tscn tests/test_kawagael.gd
git commit -m "test(kawagael): smoke test — instantia, herda Zael, tem 15 anims"
```

---

### Task 4: Loader de PNGs individuais (`_add_anim_from_frames`)

**Files:**
- Modify: `characters/ranged/kawagael/kawagael.gd`
- Create: `tests/test_kawagael_loader.tscn`
- Create: `tests/test_kawagael_loader.gd`
- Create (fixtures): `tests/fixtures/kawagael/anims/testrun/f00.png`, `f01.png`, `f02.png` (PNGs 8×8 lisos, gerados via Godot)

**Interfaces:**
- Produces: método `Kawagael._add_anim_from_frames(frames, name, dir, speed, loop) -> void` — carrega todos os `*.png` de `dir` (ordenados por nome) como frames de `name` em `frames`. Se `dir` não existir, `push_warning` e retorna vazio.

- [ ] **Step 1: Gerar PNG fixtures via Godot script**

Não precisamos criar PNGs à mão. O test setup pode gerar. Criar script util `tests/fixtures/kawagael/gen_fixtures.gd`:

```gdscript
@tool
extends EditorScript
# Uso: rodar via EditorScript pra gerar fixtures 1 vez.

func _run() -> void:
    var dir := "res://tests/fixtures/kawagael/anims/testrun/"
    DirAccess.make_dir_recursive_absolute(dir)
    for i in 3:
        var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
        img.fill(Color(float(i)/2.0, 1.0-float(i)/2.0, 0.5, 1.0))
        img.save_png(dir + "f%02d.png" % i)
    print("Fixtures generated at %s" % dir)
```

**Alternativa mais simples:** gerar os PNGs no runtime do próprio teste, dentro de `user://tests/fixtures/`. Isso é mais autocontido — não precisa de um passo manual do editor. Vamos com essa alternativa. Ver Step 4.

- [ ] **Step 2: Criar test_kawagael_loader.tscn**

```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/test_kawagael_loader.gd" id="1"]
[node name="TestKawagaelLoader" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 3: Escrever teste do loader**

`tests/test_kawagael_loader.gd`:

```gdscript
extends Node

const _FIXTURE_DIR := "user://test_kawa_fixtures/anims/testrun/"

func _ready() -> void:
    _setup_fixtures()
    test_loader_reads_all_frames_ordered()
    test_loader_handles_missing_dir()
    test_loader_respects_loop_and_speed()
    print("=== All Kawagael loader tests passed ===")
    get_tree().quit()

func _setup_fixtures() -> void:
    DirAccess.make_dir_recursive_absolute(_FIXTURE_DIR)
    for i in 3:
        var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
        img.fill(Color(float(i)/2.0, 1.0-float(i)/2.0, 0.5, 1.0))
        img.save_png(_FIXTURE_DIR + "f%02d.png" % i)

func test_loader_reads_all_frames_ordered() -> void:
    var kawa: Kawagael = _new_kawagael()
    var frames := SpriteFrames.new()
    kawa._add_anim_from_frames(frames, "testrun", _FIXTURE_DIR, 10.0, true)
    assert(frames.get_frame_count("testrun") == 3, "expected 3 frames")
    kawa.queue_free()
    print("PASS: test_loader_reads_all_frames_ordered")

func test_loader_handles_missing_dir() -> void:
    var kawa: Kawagael = _new_kawagael()
    var frames := SpriteFrames.new()
    kawa._add_anim_from_frames(frames, "ghost", "user://nonexistent/xyz/", 10.0, true)
    assert(frames.get_frame_count("ghost") == 0, "missing dir should yield 0 frames")
    kawa.queue_free()
    print("PASS: test_loader_handles_missing_dir")

func test_loader_respects_loop_and_speed() -> void:
    var kawa: Kawagael = _new_kawagael()
    var frames := SpriteFrames.new()
    kawa._add_anim_from_frames(frames, "testrun", _FIXTURE_DIR, 12.5, false)
    assert(frames.get_animation_loop("testrun") == false, "loop flag wrong")
    assert(is_equal_approx(frames.get_animation_speed("testrun"), 12.5), "speed wrong")
    kawa.queue_free()
    print("PASS: test_loader_respects_loop_and_speed")

func _new_kawagael() -> Kawagael:
    var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
    var k: Kawagael = scene.instantiate()
    add_child(k)
    return k
```

- [ ] **Step 4: Rodar teste — esperado FALHAR (método não existe)**

```powershell
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_kawagael_loader.tscn"
```

Expected: FAIL com "invalid call: `_add_anim_from_frames` is not a valid method" ou similar.

- [ ] **Step 5: Implementar `_add_anim_from_frames` em kawagael.gd**

Editar `characters/ranged/kawagael/kawagael.gd`. Adicionar o método logo antes de `_setup_sprite_frames()`:

```gdscript
func _add_anim_from_frames(frames: SpriteFrames, anim_name: String,
        dir: String, speed: float, loop: bool) -> void:
    frames.add_animation(anim_name)
    frames.set_animation_loop(anim_name, loop)
    frames.set_animation_speed(anim_name, speed)
    var da := DirAccess.open(dir)
    if da == null:
        push_warning("kawagael: missing anim dir %s" % dir)
        return
    var files := []
    for f in da.get_files():
        if f.ends_with(".png"):
            files.append(f)
    files.sort()  # f00.png, f01.png, ..., fNN.png ordenam alfabeticamente
    for f in files:
        var tex := load(dir + f) as Texture2D
        if tex:
            frames.add_frame(anim_name, tex)
```

- [ ] **Step 6: Rodar teste — esperado PASSAR**

```powershell
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_kawagael_loader.tscn"
```

Expected: PASS `=== All Kawagael loader tests passed ===`.

- [ ] **Step 7: Commit**

```bash
git add characters/ranged/kawagael/kawagael.gd tests/test_kawagael_loader.tscn tests/test_kawagael_loader.gd
git commit -m "feat(kawagael): loader _add_anim_from_frames para PNGs individuais + testes"
```

---

### Task 5: FSM `_run_phase` (run_start → run → run_stop)

**Files:**
- Modify: `characters/ranged/kawagael/kawagael.gd`
- Create: `tests/test_kawagael_fsm.tscn`
- Create: `tests/test_kawagael_fsm.gd`

**Interfaces:**
- Consumes: `Kawagael._add_anim_from_frames` (Task 4)
- Produces:
  - Nova var `Kawagael._run_phase: String` — valores: `"idle"`, `"starting"`, `"cycle"`, `"stopping"`
  - Override de `_update_animation()` que gerencia essas transições
  - Override de `_on_animation_finished()` que trata fim de `run_start` e `run_stop`

- [ ] **Step 1: Criar test_kawagael_fsm.tscn**

```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/test_kawagael_fsm.gd" id="1"]
[node name="TestKawagaelFSM" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Escrever teste da FSM**

`tests/test_kawagael_fsm.gd`:

```gdscript
extends Node

# Testa apenas as transições da FSM de run. Não depende de assets — instancia
# Kawagael e drive o _run_phase manualmente, verificando o estado que
# _update_animation resolveria.

func _ready() -> void:
    test_initial_phase_is_idle()
    test_starts_running_when_moving_from_idle()
    test_starting_becomes_cycle_after_anim_finish()
    test_moving_to_stop_when_dir_released_from_cycle()
    test_stopping_becomes_idle_after_anim_finish()
    test_dir_repress_during_stopping_restarts()
    print("=== All Kawagael FSM tests passed ===")
    get_tree().quit()

func _new_kawagael() -> Kawagael:
    var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
    var k: Kawagael = scene.instantiate()
    add_child(k)
    return k

func test_initial_phase_is_idle() -> void:
    var k := _new_kawagael()
    assert(k._run_phase == "idle", "initial phase must be idle, got %s" % k._run_phase)
    k.queue_free()
    print("PASS: test_initial_phase_is_idle")

func test_starts_running_when_moving_from_idle() -> void:
    var k := _new_kawagael()
    # Simular: no chão, x != 0, não morto, não hurt, não dashing, não jumping
    k.velocity.x = 100.0
    # Chamamos a lógica de update. Note que precisamos que o teste seja
    # tolerante ao fato de _update_animation ser chamado dentro de _physics_process
    # que exige um mundo físico. Para isolar, expomos um helper:
    k._advance_run_fsm_for_testing(true, true)  # is_on_floor=true, moving=true
    assert(k._run_phase == "starting", "expected starting, got %s" % k._run_phase)
    k.queue_free()
    print("PASS: test_starts_running_when_moving_from_idle")

func test_starting_becomes_cycle_after_anim_finish() -> void:
    var k := _new_kawagael()
    k._run_phase = "starting"
    # Simular _on_animation_finished com anim atual == "run_start"
    k._notify_run_start_finished()
    assert(k._run_phase == "cycle", "expected cycle, got %s" % k._run_phase)
    k.queue_free()
    print("PASS: test_starting_becomes_cycle_after_anim_finish")

func test_moving_to_stop_when_dir_released_from_cycle() -> void:
    var k := _new_kawagael()
    k._run_phase = "cycle"
    k.velocity.x = 0.0
    k._advance_run_fsm_for_testing(true, false)  # on floor, not moving
    assert(k._run_phase == "stopping", "expected stopping, got %s" % k._run_phase)
    k.queue_free()
    print("PASS: test_moving_to_stop_when_dir_released_from_cycle")

func test_stopping_becomes_idle_after_anim_finish() -> void:
    var k := _new_kawagael()
    k._run_phase = "stopping"
    k._notify_run_stop_finished()
    assert(k._run_phase == "idle", "expected idle, got %s" % k._run_phase)
    k.queue_free()
    print("PASS: test_stopping_becomes_idle_after_anim_finish")

func test_dir_repress_during_stopping_restarts() -> void:
    var k := _new_kawagael()
    k._run_phase = "stopping"
    k.velocity.x = 100.0
    k._advance_run_fsm_for_testing(true, true)  # on floor, moving again
    assert(k._run_phase == "starting", "expected starting, got %s" % k._run_phase)
    k.queue_free()
    print("PASS: test_dir_repress_during_stopping_restarts")
```

- [ ] **Step 3: Rodar teste — esperado FALHAR**

```powershell
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_kawagael_fsm.tscn"
```

Expected: FAIL — `_run_phase` não existe, helpers `_advance_run_fsm_for_testing` / `_notify_run_start_finished` não existem.

- [ ] **Step 4: Adicionar FSM no kawagael.gd**

Editar `characters/ranged/kawagael/kawagael.gd`. Adicionar após a declaração de classe:

```gdscript
var _run_phase: String = "idle"

# Chamado no _on_animation_finished — se anim que acabou foi run_start,
# transiciona pra cycle.
func _notify_run_start_finished() -> void:
    if _run_phase == "starting":
        _run_phase = "cycle"

# Chamado no _on_animation_finished — se anim que acabou foi run_stop,
# transiciona pra idle.
func _notify_run_stop_finished() -> void:
    if _run_phase == "stopping":
        _run_phase = "idle"

# Testing helper — replica só a parte da lógica que a FSM olha do estado
# real do personagem. Produção usa is_on_floor() e velocity.x.
func _advance_run_fsm_for_testing(on_floor: bool, moving: bool) -> void:
    _advance_run_fsm(on_floor, moving)

func _advance_run_fsm(on_floor: bool, moving: bool) -> void:
    if not on_floor:
        return  # transições no ar são de outra classe de estado
    match _run_phase:
        "idle":
            if moving:
                _run_phase = "starting"
        "starting":
            pass  # espera _notify_run_start_finished
        "cycle":
            if not moving:
                _run_phase = "stopping"
        "stopping":
            if moving:
                _run_phase = "starting"
```

- [ ] **Step 5: Rodar teste — esperado PASSAR**

```powershell
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_kawagael_fsm.tscn"
```

Expected: PASS.

- [ ] **Step 6: Override `_update_animation` e `_on_animation_finished` para chamar a FSM**

Ainda em `kawagael.gd`. Adicionar (ou substituir se já existirem em versões antigas):

```gdscript
func _on_animation_finished() -> void:
    # Delegate primeiro pro comportamento do Zael (shoot/hurt/death).
    super._on_animation_finished()
    # Adiciona nossos handlers de FSM de run.
    match _sprite.animation:
        "run_start":
            _notify_run_start_finished()
        "run_stop":
            _notify_run_stop_finished()

func _update_animation() -> void:
    # Estados terminais / de exceção — comportamento herdado do Zael:
    if is_dead or _is_hurt or _jump_squat_timer >= 0.0 or _is_dashing \
            or not is_on_floor() or _is_shooting:
        # Zael cobre esses cenários; delegamos.
        # Além disso, resetamos a FSM de run pra "idle" — quando voltarmos
        # ao chão sem input, o próximo tick reinicia normal.
        if not is_on_floor() or _is_shooting or _is_dashing:
            _run_phase = "idle"
        super._update_animation()
        return

    # A partir daqui: no chão, sem hurt/death, sem jump squat, sem dashing,
    # sem shooting. Só FSM de run.
    if not _is_shooting and not is_dead and not _is_hurt:
        _sprite.flip_h = not facing_right

    var moving := velocity.x != 0.0
    _advance_run_fsm(true, moving)

    match _run_phase:
        "starting":
            if _sprite.animation != "run_start":
                _sprite.play("run_start")
        "cycle":
            if _sprite.animation != "run":
                _sprite.play("run")
        "stopping":
            if _sprite.animation != "run_stop":
                _sprite.play("run_stop")
        "idle":
            if _sprite.animation != "idle":
                _sprite.play("idle")
```

- [ ] **Step 7: Rodar teste completo da FSM novamente**

```powershell
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_kawagael_fsm.tscn"
```

Expected: PASS todas as 6.

- [ ] **Step 8: Commit**

```bash
git add characters/ranged/kawagael/kawagael.gd tests/test_kawagael_fsm.tscn tests/test_kawagael_fsm.gd
git commit -m "feat(kawagael): FSM _run_phase (idle → starting → cycle → stopping) + testes"
```

---

### Task 6: Baixar rotations e frames PixelLab

**Files:**
- Create: `characters/ranged/kawagael/_raw/rotations/{south,east,north,west}.png`
- Create: `characters/ranged/kawagael/_raw/animations/{anim}/east/0.png … N.png` (para cada uma das 15 anims)

**Interfaces:**
- Consumes: `characters/ranged/kawagael/_raw/job_ids.json` (Task 2)
- Produces: todos os PNGs brutos baixados em `_raw/`

- [ ] **Step 1: Aguardar/verificar que todos os 15 jobs estão prontos**

Chamar `mcp__pixellab__get_character` com o `character_id`. Verificar que o número de anims listadas no response é 16 (1 residual + 15 novas). Se algum job ainda estiver processando, reportar quais e aguardar (típico: 5-15 min pra tudo terminar).

Retry pattern: chamar `get_character` a cada 60s até tudo completo, com timeout de 30min.

- [ ] **Step 2: Baixar rotations via tools/pixellab_download.py**

```powershell
$env:PIXELLAB_API_KEY = (Get-Content .env | Select-String "PIXELLAB_API_KEY").ToString().Split("=")[1]
python tools/pixellab_download.py character bc1bd784-bffa-417e-905a-56e5aac35f67 characters/ranged/kawagael/_raw/rotations/
```

Se `python` não estiver no PATH, tentar `py` ou usar PowerShell + `Invoke-WebRequest` diretamente nas URLs de rotation retornadas pelo `get_character`.

Alternativa PowerShell inline (não depende de Python) — chamar `mcp__pixellab__get_character` primeiro pra pegar URLs frescas (elas têm `?t=<expiry>`), depois:
```powershell
# Preencher $rotations com as 4 URLs retornadas por get_character no bloco "rotations:"
$rotations = @{
  south = "<paste URL from mcp response>"
  east  = "<paste URL from mcp response>"
  north = "<paste URL from mcp response>"
  west  = "<paste URL from mcp response>"
}
New-Item -ItemType Directory -Force -Path characters/ranged/kawagael/_raw/rotations | Out-Null
foreach ($k in $rotations.Keys) {
  Invoke-WebRequest -Uri $rotations[$k] -OutFile "characters/ranged/kawagael/_raw/rotations/$k.png" -UseBasicParsing
  "downloaded $k.png ($([Math]::Round((Get-Item "characters/ranged/kawagael/_raw/rotations/$k.png").Length/1024)) KB)"
}
```

- [ ] **Step 3: Baixar frames de cada animação (loop)**

Ler `_raw/job_ids.json`. Para cada `(anim_name, job_id)`:

```powershell
python tools/pixellab_download.py animation <job_id> characters/ranged/kawagael/_raw/animations/ --direction east --action <anim_name>
```

Ou, com PowerShell inline (sem Python): chamar `mcp__pixellab__get_character` — a resposta lista cada anim com uma linha `<direction>: url1, url2, ...` no bloco `animations`. Copiar as URLs pra hashtable local e baixar:

```powershell
# Popular via inspeção do resultado de get_character. Cada anim aponta pra suas
# URLs east (uma por frame). O grupo é identificado pelo action_description que
# você usou na Task 2 (idle, run_start, run, ...).
$animUrls = @{
  idle       = @("<url f0>", "<url f1>", ...)  # 8 URLs
  run_start  = @("<url f0>", "<url f1>", ...)  # 3 URLs
  # ... 13 outras
}
foreach ($name in $animUrls.Keys) {
  $dir = "characters/ranged/kawagael/_raw/animations/$name/east"
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  for ($i=0; $i -lt $animUrls[$name].Count; $i++) {
    Invoke-WebRequest -Uri $animUrls[$name][$i] -OutFile "$dir/$i.png" -UseBasicParsing
  }
  "$name -> $($animUrls[$name].Count) frames"
}
```

**Nota prática:** copiar 15×N URLs manualmente é chato. Se o `tools/pixellab_download.py` funcionar, prefere ele. Se não, escrever um `tools/kawagael_download.ps1` que faz o parse do texto retornado por `get_character` — mas isto é opcional e pode ser feito lazy.

- [ ] **Step 4: Verificar que todos os frames chegaram**

```powershell
foreach ($anim in @("idle","run_start","run","run_stop","jump","shoot_1","shoot_2","shoot_3","dash","wall_slide","hurt","death","run_shoot","jump_shoot","dash_shoot")) {
  $count = (Get-ChildItem "characters/ranged/kawagael/_raw/animations/$anim/east/*.png" -ErrorAction SilentlyContinue).Count
  "$anim -> $count frames"
}
```

Comparar contagem com a coluna "Frames" da tabela do spec. Se algum faltar, refazer download só daquela.

- [ ] **Step 5: NÃO commitar `_raw/` (está gitignored)**

Apenas verificar via `git status` que `_raw/rotations/` e `_raw/animations/` NÃO aparecem como untracked.

---

### Task 7: Curar assets — copiar de _raw/ para anims/ com nomes fNN.png

**Files:**
- Create: `characters/ranged/kawagael/anims/{anim}/f{00..NN}.png` para as 15 anims
- (Opcional) Create: `characters/ranged/kawagael/rotations/kawagael_east.png` (copy do `_raw/rotations/east.png`)

**Interfaces:**
- Consumes: `characters/ranged/kawagael/_raw/animations/{anim}/east/*.png` (Task 6)
- Produces: `characters/ranged/kawagael/anims/{anim}/f{00..NN}.png` (formato zero-padded esperado pelo loader da Task 4)

- [ ] **Step 1: Escrever helper de curagem (PowerShell)**

Criar `tools/kawagael_curate.ps1`:

```powershell
# Copia _raw/animations/{anim}/east/{i}.png -> anims/{anim}/f{ii}.png
$root = "characters/ranged/kawagael"
$anims = @("idle","run_start","run","run_stop","jump","shoot_1","shoot_2","shoot_3","dash","wall_slide","hurt","death","run_shoot","jump_shoot","dash_shoot")

foreach ($anim in $anims) {
  $srcDir = "$root/_raw/animations/$anim/east"
  $dstDir = "$root/anims/$anim"
  if (-not (Test-Path $srcDir)) {
    Write-Warning "missing source: $srcDir — skip"
    continue
  }
  New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
  $files = Get-ChildItem "$srcDir/*.png" | Sort-Object { [int]([IO.Path]::GetFileNameWithoutExtension($_.Name)) }
  for ($i=0; $i -lt $files.Count; $i++) {
    $dst = "$dstDir/f{0:D2}.png" -f $i
    Copy-Item -Force $files[$i].FullName $dst
  }
  Write-Host "  $anim -> $($files.Count) frames"
}
```

- [ ] **Step 2: Executar**

```powershell
./tools/kawagael_curate.ps1
```

Expected output: `idle -> 8 frames`, `run_start -> 3 frames`, etc.

- [ ] **Step 3: Verificar árvore final**

```powershell
Get-ChildItem characters/ranged/kawagael/anims -Recurse -File | Group-Object DirectoryName | Format-Table Name, Count
```

Cada anim dir deve ter o número esperado. Confirmar via comparação com `EXPECTED_FRAMES` do teste.

- [ ] **Step 4: (Opcional) Copiar east rotation curada**

```powershell
Copy-Item -Force characters/ranged/kawagael/_raw/rotations/east.png characters/ranged/kawagael/rotations/kawagael_east.png
```

- [ ] **Step 5: Commit dos assets curados**

```bash
git add characters/ranged/kawagael/anims/ characters/ranged/kawagael/rotations/ tools/kawagael_curate.ps1
git commit -m "chore(kawagael): assets curados — 15 anims east + rotation base"
```

---

### Task 8: Preview HTML das 15 anims + aprovação do usuário

**Files:**
- Create (scratchpad, não commitado): `scratchpad/kawagael_preview.html`

**Interfaces:**
- Consumes: `characters/ranged/kawagael/anims/*/f*.png` (Task 7)
- Produces: artifact HTML tocando as 15 anims em loop, base64-embedded

**⚠️ CHECKPOINT:** Após publicar o preview, aguardar aprovação do usuário. Se alguma anim estiver ruim, marcar para regenerar (voltar à Task 2 só para os anims marcados).

- [ ] **Step 1: Gerar HTML embed com todas as 15 anims**

Script PowerShell (semelhante ao já feito no brainstorming):
- Para cada anim, ler todos os `f*.png` em base64
- Montar HTML com 15 seções (uma por anim), cada uma com playback + strip de frames + FPS control
- Seguir mesmo estilo visual do preview do idle (paleta verde do robô, mono para dados)

Arquivo em `C:\Users\User\AppData\Local\Temp\claude\D--NullvexGame\...\scratchpad\kawagael_preview.html`.

- [ ] **Step 2: Publicar como Artifact**

Chamar tool `Artifact` com favicon 🤖, title "Kawagael — 15 anims preview".

- [ ] **Step 3: Aguardar veredicto do usuário**

Perguntar via `AskUserQuestion`: "Todas as 15 anims estão aprovadas? Se não, quais precisam ser regeneradas?"

- [ ] **Step 4: Regenerar anims marcadas (se houver)**

Se o usuário marcar N anims para regen:
1. Chamar `mcp__pixellab__delete_animation` para cada uma
2. Repetir Task 2 (submeter jobs) só para as N marcadas
3. Repetir Task 6 (download) só para as N
4. Repetir Task 7 (curar) só para as N
5. Republicar preview

Loop até aprovação total.

- [ ] **Step 5: (No commit — HTML é scratchpad)**

Não há commit aqui — o preview é ferramenta de aprovação, não asset do projeto.

---

### Task 9: Ajustar scale/position em kawagael.tscn + wire loader com todas as 15 anims

**Files:**
- Modify: `characters/ranged/kawagael/kawagael.tscn`
- Modify: `characters/ranged/kawagael/kawagael.gd`

**Interfaces:**
- Consumes: `_add_anim_from_frames` (Task 4), assets curados (Task 7)
- Produces: Kawagael funcional visualmente correto quando instanciado

- [ ] **Step 1: Reescrever `_setup_sprite_frames()` no kawagael.gd**

Substituir o método existente (que hoje ainda tem loads do Zael) por versão nova. Editar `characters/ranged/kawagael/kawagael.gd`:

```gdscript
const _ANIMS_DIR := "res://characters/ranged/kawagael/anims/"

# (anim_name, speed_fps, loop) — ordem/valores conforme spec
const _ANIM_SPECS := [
    ["idle",       8.0,  true],
    ["run_start", 10.0, false],
    ["run",       10.0,  true],
    ["run_stop",  10.0, false],
    ["jump",      10.0, false],
    ["shoot_1",   10.0, false],
    ["shoot_2",   10.0, false],
    ["shoot_3",   10.0, false],
    ["dash",      12.0, false],
    ["wall_slide", 6.0,  true],
    ["hurt",      15.0, false],
    ["death",     10.0, false],
    ["run_shoot", 10.0,  true],
    ["jump_shoot",10.0,  true],
    ["dash_shoot",12.0,  true],
]

func _setup_sprite_frames() -> void:
    var frames := SpriteFrames.new()
    for spec in _ANIM_SPECS:
        var anim_name: String = spec[0]
        var speed: float      = spec[1]
        var loop: bool        = spec[2]
        _add_anim_from_frames(frames, anim_name, _ANIMS_DIR + anim_name + "/", speed, loop)
    _sprite.sprite_frames = frames
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sprite.play("idle")
```

Remover a tabela `_add_anim` antiga e todos os `load(_ZAEL_DIR + ...)` — não usamos mais nada do Zael.

- [ ] **Step 2: Ajustar scale em kawagael.tscn**

Editar `characters/ranged/kawagael/kawagael.tscn`. Alterar a linha do `AnimatedSprite2D`:

```
[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
position = Vector2(0, 35)
scale = Vector2(0.55, 0.55)
```

(Trocar `scale = Vector2(2, 2)` por `scale = Vector2(0.55, 0.55)`.)

- [ ] **Step 3: Rodar test_kawagael.tscn (smoke test da Task 3) — esperado PASSAR**

```powershell
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_kawagael.tscn"
```

Expected: PASS todas as 4 assertions:
- `test_kawagael_instantiates`
- `test_kawagael_is_zael_subclass`
- `test_kawagael_has_all_animations` (agora acha as 15)
- `test_kawagael_frame_counts` (bate com EXPECTED_FRAMES)

Se falhar por frame count, ver mensagem — provavelmente uma anim veio com 1 frame a mais/menos do esperado. Duas resoluções:
1. Ajustar `EXPECTED_FRAMES` no teste pra bater com a realidade (se o PixelLab retornou o número real que a gente pediu, o teste é que está errado)
2. Curar (Task 7) — remover frames excedentes

- [ ] **Step 4: Commit**

```bash
git add characters/ranged/kawagael/kawagael.gd characters/ranged/kawagael/kawagael.tscn
git commit -m "feat(kawagael): loader completo (15 anims) + scale 0.55 no sprite"
```

---

### Task 10: Trocar Zael por Kawagael em stage_scene.gd

**Files:**
- Modify: `stages/stage_scene.gd` (ou o arquivo real que instancia Zael — a Task descobre)

**Interfaces:**
- Consumes: `characters/ranged/kawagael/kawagael.tscn` (Task 9)
- Produces: Kawagael renderizado em stages quando `active_character == "zael"`

- [ ] **Step 1: Localizar onde Zael é instanciado**

```bash
grep -rn "res://characters/ranged/zael.tscn\|preload.*zael\|Zael.new()" --include="*.gd"
```

Provavelmente `stages/stage_scene.gd` tem algo como:
```gdscript
const _ZAEL_SCENE := preload("res://characters/ranged/zael.tscn")
```

- [ ] **Step 2: Substituir por Kawagael**

Editar o preload:
```gdscript
const _ZAEL_SCENE := preload("res://characters/ranged/kawagael/kawagael.tscn")
```

Manter o nome da constante `_ZAEL_SCENE` — `Kawagael extends Zael`, então todos os `is Zael` continuam funcionando.

**Se houver outros locais** (test scenes específicas, cutscenes, etc.), listá-los e decidir caso a caso — a princípio queremos que TODOS os spawns de "zael" virem Kawagael.

- [ ] **Step 3: Rodar todos os testes de regressão**

```powershell
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_game_manager.tscn"
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_stage_manager.tscn"
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_character_base.tscn"
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_kawagael.tscn"
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_kawagael_loader.tscn"
Start-Process -Wait -NoNewWindow -FilePath "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" -ArgumentList "--headless","--path",".","res://tests/test_kawagael_fsm.tscn"
```

Expected: todos PASS.

- [ ] **Step 4: Commit**

```bash
git add stages/stage_scene.gd
git commit -m "feat(stages): instancia Kawagael no lugar de Zael (drop-in visual swap)"
```

---

### Task 11: Verificação visual + smoke playthrough

**Files:** (nenhum modificado — só verificação)

**Interfaces:**
- Consumes: tudo até Task 10

- [ ] **Step 1: Abrir o jogo via skill `run`**

Invocar `Skill run` — abre Godot no jogo. Navegar até um stage simples (ex: stage_01). Confirmar visualmente:
- Kawagael aparece no spawn point (não o Zael antigo)
- Idle: respiração/oscilação sutil
- Andando: `run_start` → `run` loop → `run_stop` ao soltar
- Pulando: `jump` toca (4 frames)
- Dash (X): sprite muda pro dash pose
- Tomar dano: `hurt` toca
- Atirar (Z): `shoot_1/2/3` conforme carga
- Correr atirando: `run_shoot` (braço estendido)
- Wall slide (agarrado numa parede no ar): `wall_slide`
- Morte: `death` play + game over

Se algo estiver visualmente errado (scale, posição, pé flutuando):
- Scale: ajustar `Vector2(0.55, 0.55)` em `kawagael.tscn` — provavelmente na faixa 0.45-0.65
- Posição Y: ajustar `position` do `AnimatedSprite2D`
- Recomitar como `chore(kawagael): calibra scale/position visual`

- [ ] **Step 2: Screenshot de referência**

Via `mcp__Claude_Browser__computer` `screenshot`, tirar imagem do Kawagael em idle + run + jump + shoot. Salvar no scratchpad.

- [ ] **Step 3: (Opcional) Enviar screenshots pro usuário**

Via `SendUserFile` com status normal e caption "Kawagael no stage_01 — visual final".

- [ ] **Step 4: Commit final (se houver ajustes de calibração)**

Se algum tune-up foi feito:
```bash
git add characters/ranged/kawagael/kawagael.tscn
git commit -m "chore(kawagael): calibra scale/position via playthrough visual"
```

---

## Definição de "pronto"

Todos os itens abaixo verificados:

- [ ] Task 1 (baseline + scaffold) — commit
- [ ] Task 2 (submissão de jobs PixelLab) — job_ids.json commitado
- [ ] Task 3 (test infrastructure) — commit
- [ ] Task 4 (loader `_add_anim_from_frames`) — commit
- [ ] Task 5 (FSM `_run_phase`) — commit
- [ ] Task 6 (download de rotations + frames) — `_raw/` populado (não commitado)
- [ ] Task 7 (curagem `_raw/` → `anims/`) — commit
- [ ] Task 8 (preview HTML + aprovação) — usuário aprovou as 15 anims
- [ ] Task 9 (loader completo + scale) — commit
- [ ] Task 10 (wire stage_scene.gd) — commit
- [ ] Task 11 (verificação visual + smoke playthrough) — screenshots aprovados
- [ ] Suite completa passando: `test_game_manager`, `test_stage_manager`, `test_character_base`, `test_kawagael`, `test_kawagael_loader`, `test_kawagael_fsm`
- [ ] `active_character == "zael"` funciona (drop-in — sem quebras em habilidades de boss, HUD, save/load)
