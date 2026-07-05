# Coyote Time de Parede — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wall jump continua disponível por 0.15s após soltar do wall slide, permitindo a sequência natural de travessia parede→parede (direção-alvo primeiro, pulo depois).

**Architecture:** Timer `_wall_coyote_timer` no `CharacterBase`, armado apenas no ramo de `_update_wall_slide` em que o slide termina por soltar/perder contato. Helper `_can_wall_jump()` centraliza a decisão (slide ativo OU coyote no ar) e substitui os checks diretos de `_is_wall_sliding` na base e no Zael.

**Tech Stack:** Godot 4.6.2, GDScript. Testes headless via cenas `.tscn` (`extends Node`, NUNCA `extends SceneTree`).

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-05-wall-jump-coyote-design.md`
- `WALL_COYOTE_TIME := 0.15` (valor exato da spec)
- Branch de trabalho: `feat/wall-coyote` (já criada, contém a spec)
- Godot: `D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe`, rodar a partir de `D:\SnesGame`
- Web export: tipos de `sign()/clamp()/abs()` devem ser explícitos (`: float`) — não usados aqui, mas vale para qualquer ajuste
- Não curar player, não mexer em slide/climb existente (subir parede única deve ficar idêntico)

---

### Task 1: Timer + helper `_can_wall_jump()` no CharacterBase

**Files:**
- Modify: `characters/base/character_base.gd`
- Test: `tests/test_wall_jump.gd` (cena `tests/test_wall_jump.tscn` já existe e aponta pra ele)

**Interfaces:**
- Consumes: `_is_wall_sliding`, `_wall_normal`, `_apply_wall_jump()`, `_update_wall_slide()`, `_tick_timers()` (já existentes na base)
- Produces: `const WALL_COYOTE_TIME := 0.15`, `var _wall_coyote_timer: float`, `func _can_wall_jump() -> bool` — Task 2 usa `_can_wall_jump()` no Zael

- [ ] **Step 1: Escrever os testes que falham**

Em `tests/test_wall_jump.gd`, adicionar a chamada no `_ready()`:

```gdscript
	test_wall_slide_flag_set_when_on_wall()
	test_wall_jump_velocity_applied()
	test_dash_wall_jump()
	test_wall_coyote()
	test_no_wall_slide_on_floor()
```

E a função nova no fim do arquivo:

```gdscript
func test_wall_coyote() -> void:
	var char_scene := load("res://characters/ranged/zael.tscn") as PackedScene
	var c := char_scene.instantiate()
	add_child(c)
	_assert(c.WALL_COYOTE_TIME == 0.15, "WALL_COYOTE_TIME == 0.15")
	# Coyote ativo no ar (sem chão na cena → is_on_floor() == false)
	c._is_wall_sliding = false
	c._wall_coyote_timer = 0.1
	_assert(c._can_wall_jump(), "_can_wall_jump: true com coyote ativo no ar")
	# Sem slide e sem coyote
	c._wall_coyote_timer = 0.0
	_assert(not c._can_wall_jump(), "_can_wall_jump: false sem slide e sem coyote")
	# Em wall slide
	c._is_wall_sliding = true
	_assert(c._can_wall_jump(), "_can_wall_jump: true em wall slide")
	# _apply_wall_jump zera o coyote
	c._wall_normal = Vector2(1.0, 0.0)
	c._wall_coyote_timer = 0.15
	c._apply_wall_jump()
	_assert(c._wall_coyote_timer == 0.0, "_apply_wall_jump zera o coyote de parede")
	c.queue_free()
```

- [ ] **Step 2: Rodar e confirmar que falha**

```bash
cd /d/SnesGame && "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_wall_jump.tscn 2>&1 | tail -25
```

Esperado: SCRIPT ERROR (constante `WALL_COYOTE_TIME` inexistente) ou FAILs do teste novo. Os 17 asserts antigos devem continuar PASS.

- [ ] **Step 3: Implementar na base**

Em `characters/base/character_base.gd`, quatro edições:

(a) Constante — logo após `const WALL_GRAB_MAX_RISE := 160.0 ...`:

```gdscript
const WALL_COYOTE_TIME := 0.15  # janela pós-soltar da parede em que o wall jump ainda vale (travessia)
```

(b) Variável — logo após `var _wall_jump_dash_speed: float = 0.0 ...`:

```gdscript
var _wall_coyote_timer: float = 0.0
```

(c) Tick e reset no chão — em `_tick_timers`, o bloco

```gdscript
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
		_wall_jump_dash_speed = 0.0
	elif _coyote_timer > 0.0:
		_coyote_timer -= delta
```

vira:

```gdscript
	if _wall_coyote_timer > 0.0:
		_wall_coyote_timer -= delta
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
		_wall_jump_dash_speed = 0.0
		_wall_coyote_timer = 0.0
	elif _coyote_timer > 0.0:
		_coyote_timer -= delta
```

(d) Armar SÓ no ramo "soltou/perdeu contato" — em `_update_wall_slide`, o `else` final

```gdscript
	else:
		_is_wall_sliding = false
```

vira:

```gdscript
	else:
		if _was_wall_sliding:
			_wall_coyote_timer = WALL_COYOTE_TIME  # soltou sem pular → janela de travessia
		_is_wall_sliding = false
```

(Os ramos de dash/chão e de parede `no_wall_grab` retornam antes e NÃO armam; o wall jump seta `_is_wall_sliding = false` fora desta função, então no frame seguinte `_was_wall_sliding` já é false e também não arma.)

(e) Helper + uso — adicionar antes de `_handle_jump`:

```gdscript
func _can_wall_jump() -> bool:
	# Slide ativo, ou acabou de soltar da parede (coyote) e está no ar.
	# No chão o timer é zerado em _tick_timers, então pulo de chão mantém prioridade.
	return _is_wall_sliding or (_wall_coyote_timer > 0.0 and not is_on_floor())
```

Em `_handle_jump`, trocar

```gdscript
	if _is_wall_sliding:
		_apply_wall_jump()
		return
```

por

```gdscript
	if _can_wall_jump():
		_apply_wall_jump()
		return
```

(f) Zerar ao disparar — em `_apply_wall_jump`, junto de `_is_wall_sliding = false`:

```gdscript
	_is_wall_sliding = false
	_wall_coyote_timer = 0.0
```

- [ ] **Step 4: Rodar e confirmar que passa**

```bash
cd /d/SnesGame && "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_wall_jump.tscn 2>&1 | tail -25
```

Esperado: `Wall Jump Tests: 22 passed, 0 failed`, exit 0.

- [ ] **Step 5: Regressão da base**

```bash
cd /d/SnesGame && "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_character_base.tscn 2>&1 | tail -6
```

Esperado: `=== All CharacterBase tests passed ===`, exit 0. (Há 1 FAIL pré-existente de invencibilidade que NÃO aborta — ignorar; qualquer FAIL novo é regressão.)

- [ ] **Step 6: Commit**

```bash
git add characters/base/character_base.gd tests/test_wall_jump.gd
git commit -m "feat(core): coyote time de parede — wall jump vale 0.15s após soltar do slide"
```

---

### Task 2: Zael usa `_can_wall_jump()`

**Files:**
- Modify: `characters/ranged/zael.gd:226` (função `_handle_jump`)

**Interfaces:**
- Consumes: `_can_wall_jump() -> bool` da Task 1 (herdado de CharacterBase)
- Produces: nada novo — Kawagael estende Zael e herda; Zara usa a base direto

- [ ] **Step 1: Trocar o check hardcoded**

Em `characters/ranged/zael.gd`, `_handle_jump`, trocar

```gdscript
    if Input.is_action_just_pressed("jump") and _is_wall_sliding:
        _dash_jump = false
        _apply_wall_jump()
        return
```

por

```gdscript
    if Input.is_action_just_pressed("jump") and _can_wall_jump():
        _dash_jump = false
        _apply_wall_jump()
        return
```

(Atenção: `zael.gd` usa indentação por ESPAÇOS, diferente da base que usa tabs — manter o estilo do arquivo.)

- [ ] **Step 2: Rodar os testes de wall jump (usam zael.tscn)**

```bash
cd /d/SnesGame && "D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_wall_jump.tscn 2>&1 | tail -25
```

Esperado: `Wall Jump Tests: 22 passed, 0 failed`, exit 0.

- [ ] **Step 3: Commit**

```bash
git add characters/ranged/zael.gd
git commit -m "feat(zael): wall jump prioritário usa _can_wall_jump (coyote de parede)"
```

---

### Task 3: Web export + PR

**Files:**
- Modify: `export/web/index.html`, `export/web/index.pck` (gerados pelo export)

**Interfaces:**
- Consumes: build da branch com Tasks 1-2 completas
- Produces: build web atualizado + PR mergeado em master

- [ ] **Step 1: Exportar web (release)**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "D:\SnesGame" --export-release "Web" "D:\SnesGame\export\web\index.html" 2>&1 | tail -3
```

Esperado: `[ DONE ] savepack` sem erros.

- [ ] **Step 2: Conferir PCK atualizado**

```powershell
powershell -Command "Get-Item 'D:\SnesGame\export\web\index.pck' | Select-Object LastWriteTime, Length"
```

Esperado: `LastWriteTime` = agora. Se não mudou, o export falhou — parar.

- [ ] **Step 3: Reiniciar servidor local (port 8080)**

```powershell
powershell -Command "
  \$pids = (netstat -ano | findstr ':8080' | ForEach-Object { (\$_ -split '\s+')[-1] } | Sort-Object -Unique);
  foreach (\$p in \$pids) { Stop-Process -Id \$p -Force -ErrorAction SilentlyContinue };
  Start-Process python -ArgumentList 'D:\SnesGame\serve_web.py' -WindowStyle Hidden;
  Start-Sleep 2;
  (Invoke-WebRequest http://localhost:8080 -UseBasicParsing).StatusCode
"
```

Esperado: `200`.

- [ ] **Step 4: Commit do export**

```bash
git add -f export/web/ && git commit -m "chore: web export — coyote time de parede"
```

- [ ] **Step 5: Rebase, push e PR**

```bash
git fetch origin master && git rebase origin/master
git push -u origin feat/wall-coyote
```

Corpo do PR em arquivo temporário (nunca `--body` inline), depois:

```bash
GH_PAGER=cat gh pr create --base master --title "feat(core): coyote time de parede — travessia parede→parede" --body-file <arquivo-temp>
```

Merge só com aprovação do usuário (validar o feel no shaft Z4 primeiro em `http://localhost:8080`).
