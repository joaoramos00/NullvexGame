# tests/bot/stage_bot.gd — autopilot que atravessa a fase (Approach A)
extends Node

const TOL := 24.0
const JUMP_X_TOL := 48.0   # jump_to completa ao aterrissar perto do x-alvo (altura implícita pela plataforma)
const STUCK_EPS := 2.0
const STUCK_TIMEOUT := 4.0
const JUMP_HOLD := 0.12
const DASH_HOLD := 0.08

var _player: CharacterBody2D = null
var _path: Array = []
var _idx: int = 0
var _seg_time: float = 0.0
var _last_dist: float = INF
var _stuck_timer: float = 0.0
var _jump_hold: float = 0.0
var _dash_hold: float = 0.0
var _seg_jumped: bool = false   # leap one-shot por segmento (dash-jump)
var _node_cache: Dictionary = {}  # nós da cena (plataformas móveis) por nome
var _done: bool = false

func _ready() -> void:
	if _player == null:
		_player = _find_player()
	_path = _load_path()
	if _path.is_empty():
		print("BOT_STUCK:no_path@0,0")
		_done = true
		return
	# Debug ?zone=N: começa o caminho no marcador {"t":"zone","n":N} (calibração rápida
	# de uma zona, pareado com o spawn por zona da cena).
	if DebugBoot.zone > 0:
		for i in _path.size():
			var s: Dictionary = _path[i]
			if str(s.get("t", "")) == "zone" and int(s.get("n", -1)) == DebugBoot.zone:
				_idx = i
				break
	print("BOT_START")

func _find_player() -> CharacterBody2D:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] if nodes.size() > 0 else null

func _load_path() -> Array:
	var path := "res://tests/bot/paths/stage_%02d.gd" % StageManager.current_stage_id
	if not ResourceLoader.exists(path):
		return []
	var inst: Object = (load(path) as GDScript).new()
	return inst.path() if inst.has_method("path") else []

func _physics_process(delta: float) -> void:
	if _done or _player == null:
		return
	# Detecção de morte: queda/dano que mata o player desincroniza o caminho.
	if _player.is_dead:
		var dp := _player.global_position
		print("BOT_STUCK:died@%d,%d" % [int(dp.x), int(dp.y)])
		_done = true
		_release_all()
		return
	if _jump_hold > 0.0:
		_jump_hold -= delta
		if _jump_hold <= 0.0:
			Input.action_release("jump")
	if _dash_hold > 0.0:
		_dash_hold -= delta
		if _dash_hold <= 0.0:
			Input.action_release("dash")
	if _idx >= _path.size():
		_finish()
		return
	var seg: Dictionary = _path[_idx]
	var t := str(seg.get("t", ""))
	var complete := false
	match t:
		"walk_to":    complete = _do_walk_to(seg)
		"dash_to":    complete = _do_dash_to(seg)
		"jump_to":    complete = _do_jump_to(seg)
		"climb_to":   complete = _do_climb_to(seg)
		"drop":       complete = _do_drop(seg)
		"wait":       complete = _do_wait(seg, delta)
		"screenshot": complete = _do_screenshot(seg)
		"board":      complete = _do_board(seg)
		"zone":       complete = true   # marcador (no-op) p/ ?zone=N começar aqui
		_:            complete = true
	if not complete and (t == "walk_to" or t == "dash_to" or t == "jump_to" or t == "climb_to" or t == "board"):
		if _check_stuck(seg, delta):
			return
	if complete:
		_release_dirs()
		_advance()

func _advance() -> void:
	_idx += 1
	_seg_time = 0.0
	_stuck_timer = 0.0
	_last_dist = INF
	_seg_jumped = false

func _finish() -> void:
	_done = true
	_release_dirs()
	print("BOT_DONE")

# ── Segmentos ───────────────────────────────────────────────────────────────

func _do_walk_to(seg: Dictionary) -> bool:
	var tx := float(seg.get("x", _player.global_position.x))
	var dx := tx - _player.global_position.x
	# land=true: só completa POUSADO no x-alvo (não no ar). Essencial p/ descidas em que
	# o player cai de plataforma em plataforma — senão o walk_to completa no meio da queda
	# e os segmentos dessincronizam do pouso real.
	if absf(dx) < TOL and (not bool(seg.get("land", false)) or _player.is_on_floor()):
		return true
	_press_dir(signf(dx))
	# Hop sobre degraus pequenos ao esbarrar numa parede. no_hop desliga isso (ex.:
	# descida do shaft, onde encostar na parede da plataforma geraria pulo infinito).
	if not bool(seg.get("no_hop", false)) and _player.is_on_wall() and _player.is_on_floor():
		_tap_jump()
	return false

func _do_dash_to(seg: Dictionary) -> bool:
	# Avança com dash (burst de 720 px/s, gravidade off) — cobre chão rápido e
	# atravessa vãos curtos dando dash na beirada. Completa ao parar perto do x.
	var tx := float(seg.get("x", _player.global_position.x))
	var dx := tx - _player.global_position.x
	if _player.is_on_floor() and absf(dx) < TOL:
		return true
	_press_dir(signf(dx))
	if _player.is_on_floor():
		_tap_dash()
		# leap=true: dash-jump uma vez p/ cruzar vãos largos. Sem jump_x, dispara assim
		# que o dash pega velocidade (>400). Com jump_x, espera chegar na beirada (p/
		# fossos largos, o lançamento precisa ser no fim da pista pra alcançar o outro lado).
		if bool(seg.get("leap", false)) and not _seg_jumped and absf(_player.velocity.x) > 300.0:
			var jx: Variant = seg.get("jump_x", null)
			var ready: bool = (jx == null and absf(_player.velocity.x) > 400.0) \
				or (jx != null and _player.global_position.x >= float(jx))
			if ready:
				_tap_jump()
				_seg_jumped = true
	return false

func _do_jump_to(seg: Dictionary) -> bool:
	# Pula proativamente rumo a uma plataforma à frente. Completa ao aterrissar
	# perto do x-alvo (a altura é implícita — qual plataforma está naquele x).
	var tx := float(seg.get("x", _player.global_position.x))
	if _player.is_on_floor() and absf(tx - _player.global_position.x) < JUMP_X_TOL:
		return true
	# max_y: ao sair de uma plataforma móvel rumo a uma estática, só pula quando o player
	# está alto o suficiente (móvel perto do apex). Enquanto baixo, espera (não anda p/
	# não cair da móvel estreita).
	var my_v: Variant = seg.get("max_y", null)
	if _player.is_on_floor() and my_v != null and _player.global_position.y > float(my_v):
		_release_dirs()
		return false
	# No ar e já perto do x-alvo: cai RETO (sem ficar trocando de lado / oscilando ao
	# cruzar o alvo). Evita o "trocando de lado" na queda em poços.
	if not _player.is_on_floor() and absf(tx - _player.global_position.x) < 40.0:
		_release_dirs()
	else:
		_press_dir(signf(tx - _player.global_position.x))
	var jx: Variant = seg.get("jump_x", null)
	if jx == null:
		if _player.is_on_floor():
			_tap_jump()   # sem jump_x: hop repetido rumo ao alvo (comportamento antigo)
	else:
		# jump_x: corre até a beirada e lança UMA vez. NÃO exige on_floor — o coyote time
		# (0.12s) do personagem cobre o caso de já ter saído da plataforma 1-2 frames antes.
		# Sem isso, em alta velocidade o player atravessa a janela de 1 frame na beirada e
		# cai no vão SEM pular (bug Plat3→MovPlat3).
		var fwd := signf(tx - _player.global_position.x)
		var past: bool = (fwd >= 0.0 and _player.global_position.x >= float(jx)) \
			or (fwd < 0.0 and _player.global_position.x <= float(jx))
		if past and not _seg_jumped:
			_tap_jump()
			_seg_jumped = true
	return false

func _stage_node(n: String) -> Node2D:
	if not _node_cache.has(n):
		_node_cache[n] = get_parent().get_node_or_null(n)
	return _node_cache[n] as Node2D

func _do_board(seg: Dictionary) -> bool:
	# Embarca numa plataforma móvel: corre até PERTO da beirada, PARA e espera a
	# plataforma chegar numa altura alcançável (topo perto/abaixo dos pés), e só então
	# avança+pula. Sem isso o player corre pra fora da plataforma e cai no lava.
	var plat := _stage_node(str(seg.get("plat", "")))
	if plat == null:
		return true  # sem plataforma — pula o segmento
	var px := plat.global_position.x
	var py := plat.global_position.y
	var dx := px - _player.global_position.x
	# Completa ao estar em pé sobre a plataforma (perto em x, acima do centro dela).
	if _player.is_on_floor() and absf(dx) < 100.0 and _player.global_position.y < py - 8.0:
		return true
	var plat_top := py - 16.0          # ShapeShaftPlat tem 32 de altura
	var feet := _player.global_position.y + 44.0
	var catchable := plat_top >= feet - 28.0 and plat_top <= feet + 110.0
	# from_x: x onde esperar (beirada da plataforma atual). Sem ele, usa 180px do alvo.
	var fx_v: Variant = seg.get("from_x", null)
	var wait_x: float = float(fx_v) if fx_v != null else (px - signf(dx) * 180.0)
	var at_edge: bool = absf(_player.global_position.x - wait_x) < 24.0 \
		or (signf(dx) > 0.0 and _player.global_position.x >= wait_x) \
		or (signf(dx) < 0.0 and _player.global_position.x <= wait_x)
	if not _player.is_on_floor():
		_press_dir(signf(dx))          # no ar: segue rumo à plataforma
	elif not at_edge:
		_press_dir(signf(dx))          # ainda longe: corre até a pista (wait_x)
	elif catchable:
		# plataforma na altura certa: corre da pista e pula COM IMPULSO (parado o hop
		# é fraco e cai no gap). from_x deve dar ~80px de pista antes da beirada real.
		_press_dir(signf(dx))
		if absf(_player.velocity.x) > 180.0:
			_tap_jump()
	else:
		_release_dirs()                # na pista, plataforma fora de alcance: espera
	return false

func _do_climb_to(seg: Dictionary) -> bool:
	var ty := float(seg.get("y", _player.global_position.y))
	# Completa só ao POUSAR em cima (não no pico do pulo) — segura a direção contra
	# a parede o tempo todo, que carrega o player por cima da borda quando a parede acaba.
	if _player.is_on_floor() and _player.global_position.y <= ty:
		return true
	var dir := -1.0 if str(seg.get("side", "left")) == "left" else 1.0
	_press_dir(dir)
	# leap=true: pula do chão pra alcançar uma plataforma flutuante num vão e dá
	# wall-jump na face dela (parede fina). Sem leap: só wall-jump em parede adjacente.
	var leap := bool(seg.get("leap", false))
	if _player.is_on_wall() or (leap and _player.is_on_floor()):
		_tap_jump()
	return false

func _do_drop(seg: Dictionary) -> bool:
	_press_dir(float(seg.get("dir", 1.0)))
	return (not _player.is_on_floor()) and _player.velocity.y > 0.0

func _do_wait(seg: Dictionary, delta: float) -> bool:
	_seg_time += delta
	return _seg_time >= float(seg.get("seconds", 0.5))

func _do_screenshot(seg: Dictionary) -> bool:
	print("BOT_SHOT:%02d:%s" % [StageManager.current_stage_id, str(seg.get("label", "shot"))])
	return true

# ── Travamento ──────────────────────────────────────────────────────────────

func _check_stuck(seg: Dictionary, delta: float) -> bool:
	var d := _dist_to_goal(seg)
	if d < _last_dist - STUCK_EPS:
		_last_dist = d
		_stuck_timer = 0.0
	else:
		_stuck_timer += delta
		# patience: segmentos que esperam um gatilho (ex.: porta do boss que abre por
		# proximidade e leva alguns segundos) toleram mais tempo parado antes de desistir.
		if _stuck_timer >= float(seg.get("patience", STUCK_TIMEOUT)):
			var p := _player.global_position
			print("BOT_STUCK:%s@%d,%d" % [str(seg.get("label", seg.get("t", "?"))), int(p.x), int(p.y)])
			_done = true
			_release_dirs()
			return true
	return false

func _dist_to_goal(seg: Dictionary) -> float:
	var p := _player.global_position
	match str(seg.get("t", "")):
		"walk_to":  return absf(float(seg.get("x", p.x)) - p.x)
		"dash_to":  return absf(float(seg.get("x", p.x)) - p.x)
		"jump_to":  return absf(float(seg.get("x", p.x)) - p.x)
		"climb_to": return absf(p.y - float(seg.get("y", p.y)))
		"board":
			var plat := _stage_node(str(seg.get("plat", "")))
			return absf(plat.global_position.x - p.x) if plat else 0.0
		_:          return 0.0

# ── Input ─────────────────────────────────────────────────────────────────────

func _press_dir(dir: float) -> void:
	if dir < 0.0:
		Input.action_press("move_left")
		Input.action_release("move_right")
	elif dir > 0.0:
		Input.action_press("move_right")
		Input.action_release("move_left")

func _release_dirs() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")

func _release_all() -> void:
	_release_dirs()
	Input.action_release("jump")
	Input.action_release("dash")

func _tap_jump() -> void:
	if _jump_hold <= 0.0 and not Input.is_action_pressed("jump"):
		Input.action_press("jump")
		_jump_hold = JUMP_HOLD

func _tap_dash() -> void:
	if _dash_hold <= 0.0 and not Input.is_action_pressed("dash"):
		Input.action_press("dash")
		_dash_hold = DASH_HOLD
