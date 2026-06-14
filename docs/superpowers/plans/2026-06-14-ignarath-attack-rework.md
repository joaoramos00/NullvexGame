# Rework de Ataques do Ignarath — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajustar o boss Ignarath (Stage 01): reduzir 20% + subir o sprite, firebreath vira um beam que varre da vertical pra fora (Godzilla), garra vira ataque à distância com fogo rasteiro que viaja até a parede, e remover o bloco vermelho placeholder.

**Architecture:** Tudo em `characters/bosses/ignarath.gd` + `ignarath.tscn`, mais um novo `characters/bosses/ignarath/fire_beam.gd` (firebreath) e a remoção de `fire_patch.gd`. Reaproveita `fire_wave.gd` (parametrizado por altura) para o fogo rasteiro da garra. A regra de invulnerabilidade/fraqueza (`_invuln`, `_attack_gen`, `_break_action`, `take_damage`) é mantida e estendida (o beam é liberado ao interromper).

**Tech Stack:** Godot 4.6.2, GDScript. Bosses extends `BossBase`.

---

## File Structure

| Arquivo | Responsabilidade | Ação |
|---------|------------------|------|
| `characters/bosses/ignarath.gd` | Lógica do boss (ataques, consts, anim, dano) | Modificar |
| `characters/bosses/ignarath.tscn` | Offset do `Sprite2D` | Modificar |
| `characters/bosses/ignarath/fire_beam.gd` | Firebreath: beam que varre da vertical pra fora | Criar |
| `characters/bosses/ignarath/fire_wave.gd` | Fogo rasteiro da garra (reuso, parametrizado) | Sem mudança |
| `characters/bosses/ignarath/fire_patch.gd` | Poça estática antiga | Remover |

**Comandos de verificação** (usados em quase toda task), a partir de `D:\SnesGame`:

Load do Stage 01 (compila ignarath + dependências; sem autoload-falso-positivo):
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . --quit-after 20 res://stages/stage_01/stage_01.tscn 2>&1 | grep -iE "SCRIPT ERROR|Parse Error|Compile Error|ignarath|fire_beam|fire_wave|fire_patch" | grep -ivE "bgm_|\.mp3"
```
Sucesso = nenhuma linha (vazio). Avisos de áudio são pré-existentes.

Teste dos bosses:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_boss_battle.tscn 2>&1 | grep -E "ALL BATTLE|FAIL"; echo "EXIT=${PIPESTATUS[0]}"
```
Sucesso = `ALL BATTLE TESTS PASSED` e `EXIT=0`.

---

## Task 1: Tamanho/posição (#1) + remover bloco vermelho (#4)

**Files:**
- Modify: `characters/bosses/ignarath.gd` (`_ready`, novo `_draw`)
- Modify: `characters/bosses/ignarath.tscn` (offset do Sprite2D)

- [ ] **Step 1: Escala 0.8 no `_ready`**

Em `characters/bosses/ignarath.gd`, trocar:
```gdscript
	super()
	scale = Vector2(1.0, 1.0)
```
por:
```gdscript
	super()
	scale = Vector2(0.8, 0.8)   # 80% do tamanho (sprite + colisão)
```

- [ ] **Step 2: Override `_draw()` vazio (remove o bloco vermelho do BossBase)**

Em `characters/bosses/ignarath.gd`, logo após a função `_ready()` (antes de `_physics_process`), inserir:
```gdscript

# Remove o placeholder vermelho + barra de HP do BossBase._draw (o boss usa o
# Sprite2D; o HP é mostrado pelo HUD via connect_to_boss).
func _draw() -> void:
	pass
```

- [ ] **Step 3: Offset do Sprite2D no `.tscn`**

Em `characters/bosses/ignarath.tscn`, trocar:
```
[node name="Sprite2D" type="Sprite2D" parent="."]
```
por:
```
[node name="Sprite2D" type="Sprite2D" parent="."]
position = Vector2(0, -40)
```
(−40 em coords locais; com `scale` 0.8 resulta em ~32px de mundo pra cima.)

- [ ] **Step 4: Verificar load + teste**

Rodar o load do Stage 01 e o teste dos bosses (comandos no topo). Esperado: load sem erro; `ALL BATTLE TESTS PASSED`, `EXIT=0`.

- [ ] **Step 5: Commit**

```bash
git add characters/bosses/ignarath.gd characters/bosses/ignarath.tscn
git commit -m "feat: Ignarath 80% do tamanho + sprite +32px; remove bloco vermelho (_draw vazio)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Firebreath = beam que varre (#2)

**Files:**
- Create: `characters/bosses/ignarath/fire_beam.gd`
- Modify: `characters/bosses/ignarath.gd` (consts, vars, `_do_firebreath`, novo `_spawn_fire_beam`, remove `_spawn_fire_wave`, `_break_action`, `_update_animation`)

- [ ] **Step 1: Criar `characters/bosses/ignarath/fire_beam.gd`**

```gdscript
extends Node2D
# Firebreath do Ignarath: feixe que sai da BOCA até o CHÃO e VARRE da vertical
# (90°) pra FORA em direção ao player (o contato no chão avança). A linha inteira
# machuca (distância ponto-a-segmento por frame). Autodestrói ao fim da varredura.

var player: CharacterBase = null
var origin: Vector2 = Vector2.ZERO      # boca, em coords de mundo
var facing: float = 1.0                  # +1 direita, -1 esquerda
var floor_y: float = 0.0
var sweep_time: float = 1.0
var max_angle_deg: float = 70.0          # ângulo final a partir da vertical
var half_width: float = 20.0
var damage: int = 12
var source_id: String = "ignarath"
var _t: float = 0.0
var _end: Vector2 = Vector2.ZERO

func _ready() -> void:
	z_index = 3
	position = Vector2.ZERO               # desenho em coords de mundo
	var depth: float = maxf(8.0, floor_y - origin.y)
	_end = origin + Vector2(0.0, depth)   # começa vertical
	queue_redraw()

func _physics_process(delta: float) -> void:
	_t += delta
	var prog: float = clampf(_t / sweep_time, 0.0, 1.0)
	var ang: float = deg_to_rad(max_angle_deg * prog)   # 0 (vertical) → max (pra fora)
	var depth: float = maxf(8.0, floor_y - origin.y)
	_end = origin + Vector2(facing * depth * tan(ang), depth)
	if is_instance_valid(player) and not player.is_dead:
		if _point_seg_dist(player.global_position, origin, _end) < half_width + 24.0:
			player.take_damage(damage, source_id)
	queue_redraw()
	if _t >= sweep_time + 0.15:
		queue_free()

func _draw() -> void:
	var fl: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 30.0)
	draw_line(origin, _end, Color(1.0, 0.35 + 0.25 * fl, 0.05, 0.9), half_width * 2.0)
	draw_line(origin, _end, Color(1.0, 0.85, 0.3, 0.95), half_width)   # núcleo claro

func _point_seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var denom: float = ab.length_squared()
	var t: float = 0.0
	if denom > 0.0:
		t = clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)
```

- [ ] **Step 2: Ajustar constantes em `ignarath.gd`**

Trocar o bloco (linhas ~21-26):
```gdscript
# Rajada de fogo (onda que viaja em linha reta). Alta demais pra pular do chão
# (pulo ~118px) → força o player a wall-jump na parede.
const WAVE_HEIGHT          := 150.0
const WAVE_WIDTH           := 90.0
const WAVE_SPEED_P1        := 300.0
const WAVE_SPEED_P2        := 430.0
```
por:
```gdscript
# Firebreath = beam que sai da boca e varre da vertical pra fora (estilo Godzilla).
const BEAM_SWEEP_TIME_P1   := 1.0
const BEAM_SWEEP_TIME_P2   := 0.7
const BEAM_MAX_ANGLE       := 70.0   # graus a partir da vertical
const BEAM_HALF_WIDTH      := 20.0
const MOUTH_DX             := 24.0   # offset da boca (a partir da origem do boss)
const MOUTH_DY             := -40.0
const FIREBREATH_STATIC_FRAME := 4   # frame "cuspindo" travado durante a varredura
```

E trocar a linha do preload do patch (linha ~41):
```gdscript
const _FIRE_PATCH := preload("res://characters/bosses/ignarath/fire_patch.gd")
```
por:
```gdscript
const _FIRE_BEAM := preload("res://characters/bosses/ignarath/fire_beam.gd")
```
(Mantém `const _FIRE_WAVE := preload(...)` — usado pela garra na Task 3.)

- [ ] **Step 3: Adicionar vars de estado do beam**

Trocar (linha ~56):
```gdscript
var _attack_gen     : int   = 0     # token p/ cancelar a coroutine de ataque ao ser interrompido
```
por:
```gdscript
var _attack_gen     : int   = 0     # token p/ cancelar a coroutine de ataque ao ser interrompido
var _static_anim    : bool  = false # trava o frame do sprite (varredura do firebreath)
var _active_beam    : Node  = null  # beam do firebreath em andamento (liberado ao interromper)
```

- [ ] **Step 4: Reescrever `_do_firebreath` e trocar `_spawn_fire_wave` por `_spawn_fire_beam`**

Trocar todo o bloco de `func _do_firebreath()` até o fim de `func _spawn_fire_wave()` (linhas ~112-154) por:
```gdscript
func _do_firebreath() -> void:
	if player == null:
		return
	_attack_gen += 1
	var gen := _attack_gen
	_is_attacking = true
	_is_attacking_anim = true
	_invuln = true   # INVULNERÁVEL durante TODO o firebreath (exceto fraqueza)
	velocity.x = 0.0
	_facing = -1.0 if player.global_position.x < global_position.x else 1.0
	_start_attack_anim(_TEX_FIREBREATH, _FIREBREATH_FRAMES, _FIREBREATH_FPS)

	# Telegraph: brilho de "inspirar" antes de varrer.
	var windup := FIRE_WINDUP_P2 if phase >= 2 else FIRE_WINDUP_P1
	_telegraph_timer = windup
	await get_tree().create_timer(windup).timeout
	if gen != _attack_gen:
		return   # interrompido pela fraqueza (já limpo por _break_action)
	if is_dead or player == null:
		_telegraph_timer = 0.0
		_end_attack_anim()
		return
	_telegraph_timer = 0.0

	# Sprite estático no frame de "cuspindo" + beam que varre.
	_static_anim = true
	_anim_frame = FIREBREATH_STATIC_FRAME
	var sweep := BEAM_SWEEP_TIME_P2 if phase >= 2 else BEAM_SWEEP_TIME_P1
	_spawn_fire_beam(sweep)

	await get_tree().create_timer(sweep).timeout
	if gen != _attack_gen:
		return
	_static_anim = false
	_end_attack_anim()

func _spawn_fire_beam(sweep_time: float) -> void:
	var beam: Node2D = _FIRE_BEAM.new()
	beam.set("player", player)
	beam.set("origin", global_position + Vector2(_facing * MOUTH_DX, MOUTH_DY))
	beam.set("facing", _facing)
	beam.set("floor_y", arena_floor)
	beam.set("sweep_time", sweep_time)
	beam.set("max_angle_deg", BEAM_MAX_ANGLE)
	beam.set("half_width", BEAM_HALF_WIDTH)
	beam.set("damage", FIRE_DAMAGE)
	beam.set("source_id", "ignarath")
	get_parent().add_child(beam)
	_active_beam = beam
```

- [ ] **Step 5: `_break_action` libera o beam + limpa `_static_anim`**

Trocar a função `_break_action` (linhas ~245-255) por:
```gdscript
func _break_action() -> void:
	if is_dead:
		return
	_attack_gen += 1            # invalida a coroutine de ataque em andamento
	_invuln = false
	_is_attacking = false
	_is_attacking_anim = false
	_attack_anim_tex = null
	_telegraph_timer = 0.0
	_static_anim = false
	if is_instance_valid(_active_beam):
		_active_beam.queue_free()
	_active_beam = null
	velocity.x = 0.0
	_attack_timer = 1.0        # recuo: janela de punição antes do próximo ataque
```

- [ ] **Step 6: `_update_animation` respeita `_static_anim`**

Trocar o bloco final de avanço de frame (linhas ~317-321):
```gdscript
	_anim_timer += delta
	if _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		_anim_frame  = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame
```
por:
```gdscript
	if not _static_anim:
		_anim_timer += delta
		if _anim_timer >= 1.0 / fps:
			_anim_timer -= 1.0 / fps
			_anim_frame  = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame
```

- [ ] **Step 7: Verificar load + teste**

Rodar load do Stage 01 + teste dos bosses (comandos no topo). Esperado: sem erro; `EXIT=0`.

- [ ] **Step 8: Runtime check do beam (firebreath spawna o beam e varre; fraqueza interrompe e remove)**

Criar `tests/_tmp_beam.gd`:
```gdscript
extends Node
func _ready() -> void:
	var w := ImgDebug._BossBattleWorld.new()
	w.tile_tex = load("res://stages/stage_00/Stage_00T.png")
	add_child(w)
	await get_tree().process_frame
	w.load_boss(0)  # Ignarath
	await get_tree().process_frame
	var b = w._boss
	b.attack_interval_p1 = 0.3
	b._attack_phase = 0
	b._attack_timer = 0.1
	var ok := true
	# espera o beam aparecer
	var saw_beam := false
	var t := 0.0
	while t < 2.5 and not saw_beam:
		await get_tree().process_frame
		t += get_process_delta_time()
		for c in w.get_children():
			if c is Node2D and c.get_script() != null and String(c.get_script().resource_path).ends_with("fire_beam.gd"):
				saw_beam = true
	ok = saw_beam and ok
	print("saw_beam=", saw_beam)
	# fraqueza durante o blindado interrompe (remove o beam e para o ataque)
	if b._invuln:
		b.take_damage(50, "galerix")
		await get_tree().process_frame
		await get_tree().process_frame
		var beam_left := false
		for c in w.get_children():
			if c is Node2D and c.get_script() != null and String(c.get_script().resource_path).ends_with("fire_beam.gd") and not c.is_queued_for_deletion():
				beam_left = true
		print("apos_fraqueza atacando=", b._is_attacking, " beam_left=", beam_left)
		ok = (not b._is_attacking) and (not beam_left) and ok
	if ok: print("BEAM_OK"); get_tree().quit(0)
	else: printerr("BEAM_FAIL"); get_tree().quit(1)
```
Criar `tests/_tmp_beam.tscn`:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/_tmp_beam.gd" id="1"]
[node name="TmpBeam" type="Node"]
script = ExtResource("1")
```
Rodar:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/_tmp_beam.tscn 2>&1 | grep -iE "BEAM_OK|BEAM_FAIL|saw_beam|apos_fraqueza" | grep -ivE "bgm_|\.mp3"; echo "EXIT=${PIPESTATUS[0]}"
rm -f tests/_tmp_beam.gd tests/_tmp_beam.tscn tests/_tmp_beam.gd.uid
```
Esperado: `BEAM_OK`, `EXIT=0`. Se falhar, investigar (não relaxar o teste). Apagar os arquivos temporários ao final (já no comando).

- [ ] **Step 9: Commit**

```bash
git add characters/bosses/ignarath/fire_beam.gd characters/bosses/ignarath.gd
git commit -m "feat: firebreath do Ignarath vira beam que varre da vertical pra fora

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Claw = ranged + fogo rasteiro que viaja (#3)

**Files:**
- Modify: `characters/bosses/ignarath.gd` (consts, `_do_claw`, troca `_spawn_fire_patch` por `_spawn_claw_wave`)
- Remove: `characters/bosses/ignarath/fire_patch.gd`

- [ ] **Step 1: Ajustar constantes da garra**

Trocar o bloco (linhas ~29-38):
```gdscript
const CLAW_DAMAGE          := 18
const CLAW_RANGE           := 130.0
const CLAW_MIN_RANGE       := 130.0  # só ataca se player estiver perto
const CLAW_INVULN_WINDOW     := 0.25   # janela de INVULNERABILIDADE no instante do golpe
# Rastro de fogo da garra: arco no chão à frente (negação de área curta).
const CLAW_FIRE_DAMAGE     := 10
const CLAW_FIRE_W          := 180.0
const CLAW_FIRE_H          := 44.0
const CLAW_FIRE_LIFE_P1    := 1.1
const CLAW_FIRE_LIFE_P2    := 1.5
```
por:
```gdscript
const CLAW_DAMAGE          := 18
const CLAW_RANGE           := 130.0    # alcance do corpo-a-corpo (se o player estiver colado)
const CLAW_INVULN_WINDOW   := 0.25     # janela de INVULNERABILIDADE no instante do golpe
# Fogo rasteiro da garra: onda BAIXA que viaja até a parede (dá pra pular por cima).
const CLAW_WAVE_H          := 56.0
const CLAW_WAVE_W          := 90.0
const CLAW_WAVE_SPEED_P1   := 300.0
const CLAW_WAVE_SPEED_P2   := 400.0
```

- [ ] **Step 2: Reescrever `_do_claw` e trocar `_spawn_fire_patch` por `_spawn_claw_wave`**

Trocar todo o bloco de `func _do_claw()` até o fim de `func _spawn_fire_patch()` (linhas ~156-207) por:
```gdscript
func _do_claw() -> void:
	if player == null:
		return
	# Garra é ataque à distância: sempre executa (sem exigir proximidade).
	_attack_gen += 1
	var gen := _attack_gen
	_is_attacking = true
	_is_attacking_anim = true
	velocity.x = 0.0
	_facing = -1.0 if player.global_position.x < global_position.x else 1.0
	_start_attack_anim(_TEX_CLAW, _CLAW_FRAMES, _CLAW_FPS)

	# Telegraph: ergue a garra brilhando durante o windup (até o golpe).
	var hit_delay := float(_CLAW_FRAMES) / _CLAW_FPS * 0.5
	_telegraph_timer = hit_delay
	await get_tree().create_timer(hit_delay).timeout
	if gen != _attack_gen:
		return   # interrompido pela fraqueza
	_telegraph_timer = 0.0
	if not is_dead and player != null:
		_invuln = true   # INVULNERÁVEL no instante do golpe (exceto fraqueza)
		# Corpo-a-corpo só se o player estiver colado
		if global_position.distance_to(player.global_position) < CLAW_RANGE:
			player.take_damage(CLAW_DAMAGE)
		# Lança a onda de fogo rasteira: viaja pelo chão até bater na parede.
		_spawn_claw_wave()

	await get_tree().create_timer(CLAW_INVULN_WINDOW).timeout
	if gen != _attack_gen:
		return
	_invuln = false
	var rest := float(_CLAW_FRAMES) / _CLAW_FPS * 0.5 - CLAW_INVULN_WINDOW
	if rest > 0.0:
		await get_tree().create_timer(rest).timeout
		if gen != _attack_gen:
			return
	_end_attack_anim()

func _spawn_claw_wave() -> void:
	var wave: Area2D = _FIRE_WAVE.new()
	wave.set("dir", _facing)
	wave.set("speed", CLAW_WAVE_SPEED_P2 if phase >= 2 else CLAW_WAVE_SPEED_P1)
	wave.set("damage", FIRE_DAMAGE)
	wave.set("source_id", "ignarath")
	wave.set("wave_w", CLAW_WAVE_W)
	wave.set("wave_h", CLAW_WAVE_H)
	wave.set("despawn_x", (arena_right + 120.0) if _facing > 0.0 else (arena_left - 120.0))
	wave.global_position = Vector2(global_position.x + _facing * 50.0, arena_floor - CLAW_WAVE_H * 0.5)
	get_parent().add_child(wave)
```

- [ ] **Step 3: Remover o `fire_patch.gd`**

```bash
git rm characters/bosses/ignarath/fire_patch.gd
```
(Se houver um `fire_patch.gd.uid`, remover também: `git rm characters/bosses/ignarath/fire_patch.gd.uid`.)

- [ ] **Step 4: Verificar load + teste**

Rodar load do Stage 01 + teste dos bosses. Esperado: sem erro (nenhuma referência a `fire_patch`); `EXIT=0`.

- [ ] **Step 5: Runtime check da garra (ranged: lança a onda mesmo de longe; corpo-a-corpo de perto)**

Criar `tests/_tmp_claw2.gd`:
```gdscript
extends Node
func _ready() -> void:
	var w := ImgDebug._BossBattleWorld.new()
	w.tile_tex = load("res://stages/stage_00/Stage_00T.png")
	add_child(w)
	await get_tree().process_frame
	w.load_boss(0)
	await get_tree().process_frame
	var b = w._boss
	var p = w._player
	# player LONGE do boss (garra deve mesmo assim lançar a onda)
	p.global_position = b.global_position + Vector2(600, 0)
	b.attack_interval_p1 = 0.3
	b._attack_phase = 1   # próxima = claw
	b._attack_timer = 0.1
	var saw_wave := false
	var t := 0.0
	while t < 2.5 and not saw_wave:
		await get_tree().process_frame
		t += get_process_delta_time()
		p.global_position = b.global_position + Vector2(600, 0)
		for c in w.get_children():
			if c is Area2D and c.get_script() != null and String(c.get_script().resource_path).ends_with("fire_wave.gd"):
				saw_wave = true
	print("saw_wave_long=", saw_wave)
	if saw_wave: print("CLAW2_OK"); get_tree().quit(0)
	else: printerr("CLAW2_FAIL"); get_tree().quit(1)
```
Criar `tests/_tmp_claw2.tscn`:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://tests/_tmp_claw2.gd" id="1"]
[node name="TmpClaw2" type="Node"]
script = ExtResource("1")
```
Rodar:
```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/_tmp_claw2.tscn 2>&1 | grep -iE "CLAW2_OK|CLAW2_FAIL|saw_wave_long" | grep -ivE "bgm_|\.mp3"; echo "EXIT=${PIPESTATUS[0]}"
rm -f tests/_tmp_claw2.gd tests/_tmp_claw2.tscn tests/_tmp_claw2.gd.uid
```
Esperado: `CLAW2_OK`, `EXIT=0`.

- [ ] **Step 6: Commit**

```bash
git add characters/bosses/ignarath.gd
git commit -m "feat: garra do Ignarath vira ranged + onda de fogo baixa até a parede; remove fire_patch

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Verificação final + web export

**Files:** nenhum código novo (build/deploy).

- [ ] **Step 1: Teste dos bosses + regressão**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_boss_battle.tscn 2>&1 | grep -E "ALL BATTLE|FAIL"; echo "EXIT=${PIPESTATUS[0]}"
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path . res://tests/test_game_manager.tscn 2>&1 | grep -E "All GameManager|FAIL"; echo "EXIT=${PIPESTATUS[0]}"
```
Esperado: ambos `EXIT=0`.

- [ ] **Step 2: Web export**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "D:\SnesGame" --export-release "Web" "D:\SnesGame\export\web\index.html" 2>&1 | grep -iE "^\[ DONE \]" | tail -1
```
Verificar PCK atualizado:
```bash
powershell -Command "(Get-Item 'D:\SnesGame\export\web\index.pck').LastWriteTime"
```

- [ ] **Step 3: Commit do export + reiniciar localhost**

```bash
git add -f export/web/index.html export/web/index.pck
git commit -m "chore: web export — rework de ataques do Ignarath

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push origin master
```
Reiniciar o servidor (port 8080):
```bash
powershell -Command "$pids = (netstat -ano | findstr ':8080' | ForEach-Object { ($_ -split '\s+')[-1] } | Sort-Object -Unique); foreach ($p in $pids) { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue }; Start-Process python -ArgumentList 'D:\SnesGame\serve_web.py' -WindowStyle Hidden; Start-Sleep 2; (Invoke-WebRequest http://localhost:8080 -UseBasicParsing).StatusCode"
```
Esperado: `200`.

---

## Self-Review

**1. Spec coverage:**
- #1 tamanho/posição → Task 1 (scale 0.8 + Sprite2D offset). ✓
- #2 firebreath beam → Task 2 (fire_beam.gd + _do_firebreath + sprite estático + invuln + interrupção). ✓
- #3 claw ranged + fogo rasteiro → Task 3 (remove proximidade, _spawn_claw_wave baixo, mantém corpo-a-corpo, remove fire_patch). ✓
- #4 bloco vermelho → Task 1 (`_draw` vazio). ✓
- Mantido invuln/fraqueza → Task 2 estende `_break_action` (libera beam); `take_damage` inalterado. ✓
- Web export → Task 4. ✓

**2. Placeholder scan:** Sem TBD/TODO; todo passo tem código/comando concretos. ✓

**3. Type consistency:**
- `_FIRE_BEAM`/`_FIRE_WAVE` preloads batem com os usos (`_spawn_fire_beam`/`_spawn_claw_wave`). ✓
- `fire_beam.gd` vars (`player`, `origin`, `facing`, `floor_y`, `sweep_time`, `max_angle_deg`, `half_width`, `damage`, `source_id`) batem com os `.set(...)` em `_spawn_fire_beam`. ✓
- `fire_wave.gd` vars (`dir`, `speed`, `damage`, `source_id`, `wave_w`, `wave_h`, `despawn_x`) batem com `_spawn_claw_wave`. ✓
- Consts removidas (`WAVE_*`, `CLAW_MIN_RANGE`, `CLAW_FIRE_*`) não são mais referenciadas após as Tasks 2/3. `_spawn_fire_wave`/`_spawn_fire_patch` removidos junto com seus únicos chamadores. ✓
- `_static_anim`/`_active_beam` declarados na Task 2 (Step 3) antes do uso. ✓
