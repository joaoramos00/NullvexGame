# IntroBoss Shield Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aumentar o IntroBoss em 30% (scale 1.3), rebalancear HP para 80 e implementar shield reativo que deflecte qualquer bala do Zael para cima com arco de gravidade.

**Architecture:** Toda lógica nova fica em `intro_boss.gd` — sem tocar `boss_base.gd`. O `ZaelBullet` ganha um modo "deflectido" com física própria (velocidade 2D + gravidade). O boss encontra balas via grupo `"player_bullet"` e chama `deflect_upward()` no contato enquanto shielding.

**Tech Stack:** GDScript 4, Godot 4.6.2, extends BossBase / extends Area2D

---

## Arquivos

| Arquivo | Mudança |
|---------|---------|
| `characters/ranged/zael_bullet.gd` | grupo player_bullet, modo deflectido |
| `characters/bosses/intro_boss.gd` | scale, HP, shield logic, visual |

---

### Task 1: ZaelBullet — grupo + modo deflectido

**Files:**
- Modify: `characters/ranged/zael_bullet.gd`

- [ ] **Step 1: Adicionar ao grupo e declarar variáveis de deflexão**

Em `zael_bullet.gd`, após a linha `var _hit: bool = false`, adicionar:

```gdscript
var _deflected: bool = false
var _deflect_velocity: Vector2 = Vector2.ZERO
```

Em `_ready()`, adicionar como primeira linha:

```gdscript
add_to_group("player_bullet")
```

- [ ] **Step 2: Adicionar o método `deflect_upward()`**

Adicionar antes de `_on_area_entered`:

```gdscript
func deflect_upward() -> void:
	_deflected = true
	source_id = "deflected"
	_deflect_velocity = Vector2(direction * SPEED, -SPEED)
```

Isso mantém a direção horizontal e dispara a bala para cima com velocidade total.

- [ ] **Step 3: Modificar `_physics_process` para tratar o modo deflectido**

Substituir o início do método:

```gdscript
func _physics_process(delta: float) -> void:
	if _hit:
		return
	if _deflected:
		_deflect_velocity.y += 980.0 * delta
		global_position += _deflect_velocity * delta
		# Ainda pode acertar inimigos/player enquanto deflectida
		for area in get_overlapping_areas():
			_on_area_entered(area)
			return
		for body in get_overlapping_bodies():
			_on_body_entered(body)
			return
		return
	global_position.x += direction * SPEED * delta
	# Checa áreas primeiro (hurtboxes têm prioridade sobre paredes)
	for area in get_overlapping_areas():
		_on_area_entered(area)
		return
	for body in get_overlapping_bodies():
		_on_body_entered(body)
		return
```

- [ ] **Step 4: Commit**

```bash
git add characters/ranged/zael_bullet.gd
git commit -m "feat: ZaelBullet grupo player_bullet + modo deflectido com gravidade"
```

---

### Task 2: IntroBoss — escala e HP

**Files:**
- Modify: `characters/bosses/intro_boss.gd`

- [ ] **Step 1: Aplicar scale e novo max_hp em `_ready()`**

Em `intro_boss.gd`, alterar `_ready()`:

```gdscript
func _ready() -> void:
	stage_id           = 0
	ability_id         = ""
	max_hp             = 80
	boss_color         = Color(0.5, 0.0, 0.1, 1)
	attack_interval_p1 = 2.2
	attack_interval_p2 = 1.0
	super()
	scale = Vector2(1.3, 1.3)
```

`scale` deve vir após `super()` para não ser sobrescrito.

- [ ] **Step 2: Commit**

```bash
git add characters/bosses/intro_boss.gd
git commit -m "feat: IntroBoss scale 1.3 e max_hp 80"
```

---

### Task 3: IntroBoss — constantes e variáveis do shield

**Files:**
- Modify: `characters/bosses/intro_boss.gd`

- [ ] **Step 1: Adicionar constantes de shield**

Após as constantes existentes (linha após `RAGE_FLASH_DURATION`), adicionar:

```gdscript
const SHIELD_RANGE        := 220.0  # px — raio de detecção de bala
const SHIELD_TIME_WINDOW  := 0.35   # s  — tempo de impacto para activar
const SHIELD_DURATION     := 0.6    # s  — duração do shield activo
const SHIELD_COOLDOWN     := 4.0    # s  — recarga após uso
const SHIELD_CONTACT_DIST := 52.0   # px — distância de contacto para deflectir
```

- [ ] **Step 2: Declarar variáveis de estado do shield**

Após as variáveis de estado existentes (`_phase2_rage`, `_is_entering`), adicionar:

```gdscript
var _is_shielding    : bool  = false
var _shield_timer    : float = 0.0
var _shield_cooldown : float = 0.0
```

- [ ] **Step 3: Commit**

```bash
git add characters/bosses/intro_boss.gd
git commit -m "feat: IntroBoss constantes e vars do shield"
```

---

### Task 4: IntroBoss — lógica do shield em `_do_combat`

**Files:**
- Modify: `characters/bosses/intro_boss.gd`

- [ ] **Step 1: Adicionar método `_scan_for_shield()`**

Adicionar antes de `_do_dash()`:

```gdscript
func _scan_for_shield() -> void:
	if _shield_cooldown > 0.0 or _is_shielding or _is_dashing or _is_shooting:
		return
	for node in get_tree().get_nodes_in_group("player_bullet"):
		if not node is ZaelBullet:
			continue
		if node._hit or node._deflected:
			continue
		var to_boss: Vector2 = global_position - node.global_position
		# Bala deve estar a mover-se em direcção ao boss (X)
		if sign(node.direction) != sign(to_boss.x):
			continue
		# Boss deve estar na linha de tiro (tolerância vertical)
		if absf(to_boss.y) > 64.0:
			continue
		var horiz_dist := absf(to_boss.x)
		var time_to_impact := horiz_dist / ZaelBullet.SPEED
		if time_to_impact < SHIELD_TIME_WINDOW:
			_activate_shield()
			return
```

- [ ] **Step 2: Adicionar método `_activate_shield()`**

```gdscript
func _activate_shield() -> void:
	_is_shielding = true
	_is_attacking = true
	_shield_timer = SHIELD_DURATION
	velocity.x = 0.0
```

- [ ] **Step 3: Adicionar método `_check_deflect()`**

```gdscript
func _check_deflect() -> void:
	for node in get_tree().get_nodes_in_group("player_bullet"):
		if not node is ZaelBullet:
			continue
		if node._hit or node._deflected:
			continue
		if global_position.distance_to(node.global_position) < SHIELD_CONTACT_DIST:
			node.deflect_upward()
```

- [ ] **Step 4: Modificar `_do_combat()` para integrar shield**

Substituir o método inteiro:

```gdscript
func _do_combat(delta: float) -> void:
	# Timers
	if _shield_cooldown > 0.0:
		_shield_cooldown = maxf(0.0, _shield_cooldown - delta)
	if _is_shielding:
		_check_deflect()
		_shield_timer -= delta
		if _shield_timer <= 0.0:
			_is_shielding = false
			_is_attacking = false
			_shield_cooldown = SHIELD_COOLDOWN
		_clamp_to_arena()
		return  # boss parado durante shield
	if _is_shooting:
		_shoot_anim_timer = maxf(0.0, _shoot_anim_timer - delta)
		if _shoot_anim_timer <= 0.0:
			_is_shooting = false
			_is_attacking = false
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
			velocity.x = 0.0
	else:
		if player != null:
			var dx: float = player.global_position.x - global_position.x
			var walk_spd := WALK_SPEED_P2 if phase >= 2 else WALK_SPEED_P1
			if absf(dx) > 80.0:
				velocity.x = sign(dx) * walk_spd
			else:
				velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
		else:
			velocity.x = 0.0
	_scan_for_shield()
	_clamp_to_arena()
```

- [ ] **Step 5: Commit**

```bash
git add characters/bosses/intro_boss.gd
git commit -m "feat: IntroBoss shield reativo — detecção, activação e deflexão de balas"
```

---

### Task 5: IntroBoss — override take_damage + visual do shield

**Files:**
- Modify: `characters/bosses/intro_boss.gd`

- [ ] **Step 1: Override `take_damage()` para bloquear dano durante shield**

Adicionar após `_do_burst()`:

```gdscript
func take_damage(amount: int, source_id: String = "") -> void:
	if _is_shielding:
		return
	super.take_damage(amount, source_id)
```

- [ ] **Step 2: Adicionar visual do shield em `_draw()`**

Substituir o método `_draw()` actual (`pass`):

```gdscript
func _draw() -> void:
	if _is_shielding:
		draw_arc(Vector2.ZERO, 52.0, 0.0, TAU, 32, Color(0.4, 0.8, 2.0, 0.7), 4.0)
```

- [ ] **Step 3: Adicionar modulate do shield em `_update_animation()`**

No bloco de modulate em `_update_animation()`, após a verificação de `_phase2_rage`, adicionar o caso de shield ANTES do bloco existente. Localizar:

```gdscript
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var alpha: float = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	elif _phase2_rage:
		_sprite.modulate = Color(1.3, 0.6, 1.3, 1.0)
	else:
		_sprite.modulate = Color.WHITE
```

Substituir por:

```gdscript
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _is_shielding:
		_sprite.modulate = Color(0.4, 0.8, 2.0, 1.0)
	elif _invincible:
		var alpha: float = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	elif _phase2_rage:
		_sprite.modulate = Color(1.3, 0.6, 1.3, 1.0)
	else:
		_sprite.modulate = Color.WHITE
```

O shield tem prioridade visual sobre o flicker de invincibilidade, mas o `elif _invincible` é mantido para o flicker pós-dano normal continuar funcionando.

- [ ] **Step 4: Garantir queue_redraw() a cada frame enquanto shielding**

Em `_do_combat()`, dentro do bloco `if _is_shielding:`, após `_check_deflect()`, adicionar:

```gdscript
		queue_redraw()
```

- [ ] **Step 5: Commit**

```bash
git add characters/bosses/intro_boss.gd
git commit -m "feat: IntroBoss shield — bloqueio de dano, anel azul-ciano, modulate"
```

---

### Task 6: Web export e verificação

**Files:** nenhum

- [ ] **Step 1: Exportar e publicar**

```bash
"D:/Godot_v4.6.2-stable_win64/Godot_v4.6.2-stable_win64.exe" --headless --path "C:\Users\Usuário\SnesGame" --export-release "Web" "C:\Users\Usuário\SnesGame\export\web\index.html" 2>&1
```

- [ ] **Step 2: Verificar PCK atualizado**

```powershell
powershell -Command "Get-Item 'C:\Users\Usuário\SnesGame\export\web\index.pck' | Select-Object LastWriteTime, Length"
```

`LastWriteTime` deve ser recente (dentro do último minuto).

- [ ] **Step 3: Commit e push do export**

```bash
git add -f export/web/
git commit -m "chore: web export — intro boss shield upgrade"
git push
```

- [ ] **Step 4: Reiniciar servidor local**

```powershell
powershell -Command "
  \$pids = (netstat -ano | findstr ':8080' | ForEach-Object { (\$_ -split '\s+')[-1] } | Sort-Object -Unique);
  foreach (\$p in \$pids) { Stop-Process -Id \$p -Force -ErrorAction SilentlyContinue };
  Start-Process python -ArgumentList 'C:\Users\Usuário\SnesGame\serve_web.py' -WindowStyle Hidden;
  Start-Sleep 2;
  (Invoke-WebRequest http://localhost:8080 -UseBasicParsing).StatusCode
"
```

Deve retornar `200`.

- [ ] **Step 5: Verificação manual em http://localhost:8080**

Checar:
1. Boss visivelmente maior (30%)
2. HP bar cheia com 80 HP — tiro L2 retira ~15%
3. Shield activa ao atirar na direção do boss — boss fica azul-ciano, anel aparece
4. Bala defletida sobe e arco com gravidade (cai depois)
5. Boss não recebe dano durante shield
6. Após shield: cooldown de ~4s antes de activar de novo
