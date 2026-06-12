# Kawagael Reskin — Iteração 1 (Corrida) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gerar o ciclo de corrida (8 frames) do Kawagael via PixelLab character states e integrá-lo como reskin jogável do Zael, sem tocar em nenhum asset do Zael.

**Architecture:** `create_character_state` (MCP) autora cada um dos 8 frames como pose independente → download da rotação `east` → script Python recorta/alinha pés/downscale para 68×68 e monta o spritesheet → `kawagael.gd extends Zael` carrega `KawagaelRun.png` na animação `run` e cai de volta nas texturas do Zael para os demais estados (ainda não gerados).

**Tech Stack:** Godot 4.6.2 (GDScript), Python 3 + Pillow, PixelLab MCP/REST.

**Spec:** `docs/superpowers/specs/2026-06-08-kawagael-reskin-run-design.md`
**Personagem-fonte PixelLab:** `bc1bd784-bffa-417e-905a-56e5aac35f67`

---

## Estrutura de Arquivos

| Arquivo | Responsabilidade |
|---------|------------------|
| `characters/ranged/kawagael/` (dir) | Tudo do Kawagael, isolado |
| `characters/ranged/kawagael/_raw/fN/` | PNGs east crus baixados (intermediário) |
| `characters/ranged/kawagael/KawagaelRun.png` | Spritesheet final 544×68 |
| `tools/build_kawagael_run.py` | Pós-processamento: trim/align/downscale/stitch (funções puras + CLI) |
| `tools/test_build_kawagael_run.py` | Teste do build com inputs sintéticos (sem pytest) |
| `characters/ranged/kawagael/kawagael.gd` | `extends Zael`, override de `_setup_sprite_frames()` |
| `characters/ranged/kawagael/kawagael.tscn` | Espelha `zael.tscn` |
| `tests/test_kawagael.gd` / `.tscn` | Validação headless (8 frames no `run` + fallbacks) |

---

## Task 1: Scaffold do diretório + .gitignore dos intermediários

**Files:**
- Create: `characters/ranged/kawagael/.gitignore`

- [ ] **Step 1: Criar a pasta e ignorar os PNGs crus**

```bash
mkdir -p characters/ranged/kawagael/_raw
printf '_raw/\n' > characters/ranged/kawagael/.gitignore
```

- [ ] **Step 2: Commit**

```bash
git add characters/ranged/kawagael/.gitignore
git commit -m "chore(kawagael): scaffold do diretório de sprites"
```

---

## Task 2: Script de build (TDD com inputs sintéticos)

O build expõe funções puras (`trim`, `build_sheet`) testáveis sem chamar o PixelLab.
Regra de alinhamento: **uma única escala global** (calculada a partir do maior frame
recortado) mantém o robô do mesmo tamanho em todos os frames; cada frame é colado com o
**fundo dos pés numa linha fixa** → sem bob vertical.

**Files:**
- Create: `tools/build_kawagael_run.py`
- Test: `tools/test_build_kawagael_run.py`

- [ ] **Step 1: Escrever o teste que falha**

Create `tools/test_build_kawagael_run.py`:

```python
"""Teste do build_kawagael_run com frames sintéticos (sem dependência de PixelLab)."""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from PIL import Image
from build_kawagael_run import build_sheet, FRAME, GROUND_PAD


def _synthetic(width: int, height: int) -> Image.Image:
    """Canvas 256x256 com um retângulo opaco; a fileira de baixo do retângulo = 'pés'."""
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    x0 = (256 - width) // 2
    y1 = 200
    y0 = y1 - height
    for y in range(y0, y1):
        for x in range(x0, x0 + width):
            img.putpixel((x, y), (0, 200, 120, 255))
    return img


def _lowest_opaque_y(cell: Image.Image) -> int:
    px = cell.load()
    w, h = cell.size
    for y in range(h - 1, -1, -1):
        for x in range(w):
            if px[x, y][3] > 0:
                return y
    return -1


def main() -> None:
    # 8 frames com alturas/larguras variadas (simula poses diferentes)
    frames = [
        _synthetic(60, 150), _synthetic(70, 120), _synthetic(80, 160),
        _synthetic(65, 140), _synthetic(60, 150), _synthetic(70, 120),
        _synthetic(80, 160), _synthetic(65, 140),
    ]
    sheet = build_sheet(frames)

    assert sheet.size == (FRAME * 8, FRAME), f"tamanho errado: {sheet.size}"

    expected_y = FRAME - GROUND_PAD - 1
    for i in range(8):
        cell = sheet.crop((i * FRAME, 0, (i + 1) * FRAME, FRAME))
        low = _lowest_opaque_y(cell)
        assert low == expected_y, f"frame {i}: pés em y={low}, esperado {expected_y}"
        bbox = cell.getbbox()
        assert bbox is not None, f"frame {i} vazio"

    print("TEST_BUILD_KAWAGAEL: PASS")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `python tools/test_build_kawagael_run.py`
Expected: FAIL com `ModuleNotFoundError: No module named 'build_kawagael_run'`

- [ ] **Step 3: Implementar o build mínimo**

Create `tools/build_kawagael_run.py`:

```python
#!/usr/bin/env python3
"""Monta KawagaelRun.png a partir das rotações east dos 8 character states.

Pipeline por frame: trim do bbox opaco -> escala global única (mesmo tamanho em
todos os frames) -> alinhamento dos pés a uma linha fixa -> stitch horizontal.

Uso:
  python tools/build_kawagael_run.py
Lê:  characters/ranged/kawagael/_raw/f*/f*_east.png  (ordenado f0..f7)
Grava: characters/ranged/kawagael/KawagaelRun.png
"""
from pathlib import Path

from PIL import Image

FRAME = 68
GROUND_PAD = 2   # px do fundo da célula até a linha dos pés
TOP_PAD = 2      # respiro no topo
RAW_DIR = Path("characters/ranged/kawagael/_raw")
OUT = Path("characters/ranged/kawagael/KawagaelRun.png")


def trim(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    bbox = img.getbbox()
    return img.crop(bbox) if bbox else img


def build_sheet(images: list[Image.Image]) -> Image.Image:
    trimmed = [trim(im) for im in images]
    max_h = max(t.height for t in trimmed)
    max_w = max(t.width for t in trimmed)
    avail_h = FRAME - GROUND_PAD - TOP_PAD
    avail_w = FRAME
    scale = min(avail_h / max_h, avail_w / max_w)

    sheet = Image.new("RGBA", (FRAME * len(trimmed), FRAME), (0, 0, 0, 0))
    for i, t in enumerate(trimmed):
        nw = max(1, round(t.width * scale))
        nh = max(1, round(t.height * scale))
        scaled = t.resize((nw, nh), Image.LANCZOS)
        x = i * FRAME + (FRAME - nw) // 2
        y = FRAME - GROUND_PAD - nh   # fundo (pés) na linha fixa
        sheet.paste(scaled, (x, y), scaled)
    return sheet


def main() -> None:
    paths = sorted(RAW_DIR.glob("f*/f*_east.png"))
    if len(paths) != 8:
        raise SystemExit(f"Esperava 8 PNGs east em {RAW_DIR}, achei {len(paths)}: {paths}")
    images = [Image.open(p) for p in paths]
    sheet = build_sheet(images)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(f"Salvo: {OUT} ({sheet.size[0]}x{sheet.size[1]})")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `python tools/test_build_kawagael_run.py`
Expected: `TEST_BUILD_KAWAGAEL: PASS`

- [ ] **Step 5: Commit**

```bash
git add tools/build_kawagael_run.py tools/test_build_kawagael_run.py
git commit -m "feat(kawagael): script de build do spritesheet de corrida + teste"
```

---

## Task 3: Gerar os 8 character states (MCP, in-session)

Não há CLI — são 8 chamadas da ferramenta MCP `create_character_state` a partir de
`bc1bd784-bffa-417e-905a-56e5aac35f67`. Use `use_color_palette_from_reference=true` e a
`seed` indicada (regeneração isolada reproduzível). Cada chamada retorna um novo
`character_id`; **anote os 8 ids em ordem f0..f7**.

- [ ] **Step 1: Pré-cheque de créditos**

Run: `python -c "import urllib.request,json; k=open('.env').read().split('PIXELLAB_API_KEY=')[1].split()[0]; r=urllib.request.Request('https://api.pixellab.ai/v2/balance',headers={'Authorization':f'Bearer {k}'}); print(json.loads(urllib.request.urlopen(r).read()))"`
Expected: saldo suficiente para ~8 gerações (cada state = 1 geração). Se insuficiente, parar e avisar o usuário.

- [ ] **Step 2: Disparar os 8 states**

Para cada linha abaixo, chamar `create_character_state(character_id="bc1bd784-bffa-417e-905a-56e5aac35f67", edit_description=<texto>, use_color_palette_from_reference=true, seed=<seed>)`:

| Frame | seed | edit_description |
|-------|------|------------------|
| f0 | 1000 | `running to the right, side view, full body, right leg fully extended forward with foot planted on the ground, left leg pushed straight back behind the body, left arm swung forward, right arm swung back, torso leaning slightly forward` |
| f1 | 1001 | `running to the right, side view, full body, body weight pressing down on the bent right leg, right knee bent absorbing impact, left leg lifting off the ground behind, torso low` |
| f2 | 1002 | `running to the right, side view, full body, both legs passing underneath the body, left knee raised high in front bent ninety degrees, right leg pushing off the ground behind, arms mid-swing` |
| f3 | 1003 | `running to the right, side view, full body, left leg reaching forward through the air about to land, right leg fully extended pushing back behind, body at the highest point of the stride, right arm forward left arm back` |
| f4 | 1004 | `running to the right, side view, full body, left leg fully extended forward with foot planted on the ground, right leg pushed straight back behind the body, right arm swung forward, left arm swung back, torso leaning slightly forward` |
| f5 | 1005 | `running to the right, side view, full body, body weight pressing down on the bent left leg, left knee bent absorbing impact, right leg lifting off the ground behind, torso low` |
| f6 | 1006 | `running to the right, side view, full body, both legs passing underneath the body, right knee raised high in front bent ninety degrees, left leg pushing off the ground behind, arms mid-swing` |
| f7 | 1007 | `running to the right, side view, full body, right leg reaching forward through the air about to land, left leg fully extended pushing back behind, body at the highest point of the stride, left arm forward right arm back` |

- [ ] **Step 3: Registrar os ids**

Anotar os 8 `character_id` retornados (ordem f0..f7) num bloco temporário, ex:
```
f0=<id> f1=<id> ... f7=<id>
```
Estes ids são consumidos na Task 4. (Nada a commitar nesta task.)

---

## Task 4: Baixar as rotações east dos 8 states

**Files:** (gera intermediários em `_raw/`, fora do git)

- [ ] **Step 1: Baixar cada state na sua subpasta**

Para cada id da Task 3 (substitua `<f0_id>` … `<f7_id>`):

```bash
python tools/pixellab_download.py character <f0_id> characters/ranged/kawagael/_raw/f0
python tools/pixellab_download.py character <f1_id> characters/ranged/kawagael/_raw/f1
python tools/pixellab_download.py character <f2_id> characters/ranged/kawagael/_raw/f2
python tools/pixellab_download.py character <f3_id> characters/ranged/kawagael/_raw/f3
python tools/pixellab_download.py character <f4_id> characters/ranged/kawagael/_raw/f4
python tools/pixellab_download.py character <f5_id> characters/ranged/kawagael/_raw/f5
python tools/pixellab_download.py character <f6_id> characters/ranged/kawagael/_raw/f6
python tools/pixellab_download.py character <f7_id> characters/ranged/kawagael/_raw/f7
```

O script faz poll (~2–5 min por state) e salva `fN_east.png` (entre outras direções) em cada subpasta.

- [ ] **Step 2: Confirmar os 8 arquivos east**

Run: `python -c "from pathlib import Path; p=sorted(Path('characters/ranged/kawagael/_raw').glob('f*/f*_east.png')); print(len(p)); [print(x) for x in p]"`
Expected: `8` e os caminhos `f0/f0_east.png` … `f7/f7_east.png`.

---

## Task 5: Montar o spritesheet e validar visualmente

**Files:**
- Create: `characters/ranged/kawagael/KawagaelRun.png`

- [ ] **Step 1: Rodar o build**

Run: `python tools/build_kawagael_run.py`
Expected: `Salvo: characters/ranged/kawagael/KawagaelRun.png (544x68)`

- [ ] **Step 2: Gerar um GIF de preview p/ inspeção**

Run:
```bash
python -c "from PIL import Image; s=Image.open('characters/ranged/kawagael/KawagaelRun.png'); fr=[s.crop((i*68,0,(i+1)*68,68)) for i in range(8)]; fr[0].save('characters/ranged/kawagael/_raw/run_preview.gif',save_all=True,append_images=fr[1:],loop=0,duration=100,disposal=2); print('preview ok')"
```
Expected: `preview ok`. Inspecionar `_raw/run_preview.gif`: pés travados na mesma linha (sem bob), pernas cruzando (f0 perna direita à frente, f4 perna esquerda à frente), tamanho do robô constante.

- [ ] **Step 3: (Se algum frame estiver ruim) regenerar isolado**

Se um frame tiver pose ruim/jitter: rechamar `create_character_state` só daquele frame com nova `seed` (ex: +100), rebaixar para a subpasta `fN` correspondente (sobrescrevendo), e repetir Step 1–2. Não refazer os outros.

- [ ] **Step 4: Importar no Godot e commitar o sheet**

Run (gera o `.import` do Godot):
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit
```
Expected: editor importa `KawagaelRun.png`, criando `KawagaelRun.png.import`.

```bash
git add characters/ranged/kawagael/KawagaelRun.png characters/ranged/kawagael/KawagaelRun.png.import
git commit -m "feat(kawagael): spritesheet de corrida (8 frames) gerado via character states"
```

---

## Task 6: Script e cena do Kawagael (reskin)

`kawagael.gd extends Zael` e reimplementa só `_setup_sprite_frames()` (o do Zael tem
paths hardcoded inline). Usa `KawagaelRun.png` na `run` (8 frames) e as texturas do Zael
nos demais estados. Helper `_add_anim` evita repetição. `_FRAME_W`/`_FRAME_H`/`_sprite`
são herdados do Zael.

**Files:**
- Create: `characters/ranged/kawagael/kawagael.gd`
- Create: `characters/ranged/kawagael/kawagael.tscn`

- [ ] **Step 1: Criar `kawagael.gd`**

```gdscript
extends Zael
class_name Kawagael

const _ZAEL_DIR := "res://characters/ranged/"
const _KAWA_DIR := "res://characters/ranged/kawagael/"

func _add_anim(frames: SpriteFrames, anim: String, tex: Texture2D,
        start: int, count: int, speed: float, loop: bool) -> void:
    frames.add_animation(anim)
    frames.set_animation_loop(anim, loop)
    frames.set_animation_speed(anim, speed)
    for i in range(start, start + count):
        var at := AtlasTexture.new()
        at.atlas = tex
        at.filter_clip = true
        at.region = Rect2(i * _FRAME_W, 0, _FRAME_W, _FRAME_H)
        frames.add_frame(anim, at)

func _setup_sprite_frames() -> void:
    var idle_tex       := load(_ZAEL_DIR + "ZaelIdle.png")       as Texture2D
    var run_tex        := load(_KAWA_DIR + "KawagaelRun.png")    as Texture2D
    var jump_tex       := load(_ZAEL_DIR + "ZaelJump_new.png")   as Texture2D
    var shoot_tex      := load(_ZAEL_DIR + "ZaelAtirando.png")   as Texture2D
    var dash_tex       := load(_ZAEL_DIR + "ZaelDash.png")       as Texture2D
    var wall_tex       := load(_ZAEL_DIR + "ZaelWallSlide.png")  as Texture2D
    var hurt_tex       := load(_ZAEL_DIR + "ZaelHurt.png")       as Texture2D
    var death_tex      := load(_ZAEL_DIR + "ZaelDeath.png")      as Texture2D
    var run_shoot_tex  := load(_ZAEL_DIR + "ZaelRunShoot.png")   as Texture2D
    var jump_shoot_tex := load(_ZAEL_DIR + "ZaelJumpShoot.png")  as Texture2D
    var dash_shoot_tex := load(_ZAEL_DIR + "ZaelDashShoot.png")  as Texture2D

    var frames := SpriteFrames.new()
    _add_anim(frames, "idle",       idle_tex,       0, 8,  8.0, true)
    _add_anim(frames, "run",        run_tex,        0, 8, 10.0, true)
    _add_anim(frames, "jump",       jump_tex,       0, 4, 10.0, false)
    _add_anim(frames, "shoot_1",    shoot_tex,      4, 1, 10.0, false)
    _add_anim(frames, "shoot_2",    shoot_tex,      4, 2, 10.0, false)
    _add_anim(frames, "shoot_3",    shoot_tex,      4, 3, 10.0, false)
    _add_anim(frames, "dash",       dash_tex,       0, 2, 12.0, false)
    _add_anim(frames, "wall_slide", wall_tex,       0, 2,  6.0, true)
    _add_anim(frames, "hurt",       hurt_tex,       0, 3, 15.0, false)
    _add_anim(frames, "death",      death_tex,      0, 6, 10.0, false)
    _add_anim(frames, "run_shoot",  run_shoot_tex,  0, 9, 10.0, true)
    _add_anim(frames, "jump_shoot", jump_shoot_tex, 0, 2, 10.0, true)
    _add_anim(frames, "dash_shoot", dash_shoot_tex, 0, 2, 12.0, true)

    _sprite.sprite_frames = frames
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sprite.play("idle")
```

- [ ] **Step 2: Criar `kawagael.tscn` (espelha `zael.tscn`)**

```
[gd_scene load_steps=4 format=3 uid="uid://kawagael"]

[ext_resource type="PackedScene" uid="uid://character_base" path="res://characters/base/character_base.tscn" id="1_base"]
[ext_resource type="Script" path="res://characters/ranged/kawagael/kawagael.gd" id="2_kawa"]

[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_kawa"]
radius = 20.0
height = 80.0

[node name="Kawagael" instance=ExtResource("1_base")]
script = ExtResource("2_kawa")

[node name="CollisionShape2D" parent="."]
position = Vector2(0, 42)
shape = SubResource("CapsuleShape2D_kawa")

[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
position = Vector2(0, 35)
scale = Vector2(2, 2)
```

- [ ] **Step 3: Commit**

```bash
git add characters/ranged/kawagael/kawagael.gd characters/ranged/kawagael/kawagael.tscn
git commit -m "feat(kawagael): script e cena do reskin (run próprio + fallback Zael)"
```

---

## Task 7: Teste headless de validação

**Files:**
- Create: `tests/test_kawagael.gd`
- Create: `tests/test_kawagael.tscn`

- [ ] **Step 1: Criar `tests/test_kawagael.gd`**

```gdscript
extends Node

const _EXPECTED := [
    "idle", "run", "jump", "shoot_1", "shoot_2", "shoot_3",
    "dash", "wall_slide", "hurt", "death", "run_shoot", "jump_shoot", "dash_shoot",
]

func _ready() -> void:
    var scene := load("res://characters/ranged/kawagael/kawagael.tscn") as PackedScene
    var k := scene.instantiate()
    add_child(k)
    await get_tree().process_frame

    var sprite := k.get_node("AnimatedSprite2D") as AnimatedSprite2D
    var sf := sprite.sprite_frames
    var ok := true

    if sf.get_frame_count("run") != 8:
        push_error("run deveria ter 8 frames, tem %d" % sf.get_frame_count("run"))
        ok = false

    for anim in _EXPECTED:
        if not sf.has_animation(anim):
            push_error("faltando animação: " + anim)
            ok = false

    print("TEST_KAWAGAEL: ", "PASS" if ok else "FAIL")
    get_tree().quit(0 if ok else 1)
```

- [ ] **Step 2: Criar `tests/test_kawagael.tscn`**

```
[gd_scene load_steps=2 format=3 uid="uid://testkawagael"]

[ext_resource type="Script" path="res://tests/test_kawagael.gd" id="1"]

[node name="TestKawagael" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 3: Rodar o teste headless**

Run: `"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_kawagael.tscn`
Expected: saída contém `TEST_KAWAGAEL: PASS` e exit code 0.

- [ ] **Step 4: Commit**

```bash
git add tests/test_kawagael.gd tests/test_kawagael.tscn
git commit -m "test(kawagael): validação headless dos frames de animação"
```

---

## Task 8: Atualizar documentação de estado

**Files:**
- Modify: memória `project_nullvex.md` (índice) — registrar progresso do Kawagael

- [ ] **Step 1: Anotar o progresso**

Atualizar a memória de projeto indicando: "Kawagael (reskin Zael) — iteração 1: corrida (8 frames) gerada via character states e integrada; demais estados herdam Zael por fallback. Próximo: idle/jump/shoot."

- [ ] **Step 2: Rodar a suíte de testes base p/ garantir que nada quebrou**

Run:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn
```
Expected: PASS (o Zael e a base seguem intactos).

---

## Self-Review (preenchido pelo autor do plano)

- **Cobertura do spec:** estrutura de arquivos (Task 1,6), pipeline gerar/baixar/montar (Tasks 3,4,5), integração com fallback (Task 6), erros/validação — créditos (T3.1), poll (T4, via downloader), regeneração isolada (T5.3), validação headless + visual (T5.2, T7). Tudo coberto.
- **Placeholders:** os únicos `<...>` são os `character_id` que só existem em runtime (Task 3 produz, Task 4 consome) — inevitável e explicitado.
- **Consistência de tipos:** `build_sheet`/`trim`/`FRAME`/`GROUND_PAD` idênticos entre script e teste; `_add_anim` com a mesma assinatura em todas as chamadas; contagem da `run` = 8 consistente entre build (8 frames), `_add_anim("run",...,0,8,...)` e o assert do teste.
```
