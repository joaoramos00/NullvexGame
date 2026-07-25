extends BossBase

enum AnimState { HOVER1, HOVER2, ENTRADA, PREPARACAO, THUNDERBOLT, STATIC_PULSE, DIVE_CROUCH, DIVE_LUNGE }

const _HOVER1_FRAMES      := 9
const _HOVER2_FRAMES      := 9
const _ENTRADA_FRAMES     := 9
const _PREPARACAO_FRAMES  := 9
const _THUNDERBOLT_FRAMES := 7
const _STATIC_PULSE_FRAMES := 9
const _DIVE_CROUCH_FRAMES  := 9
const _DIVE_LUNGE_FRAMES   := 9
const _ANIM_FPS := 10.0
const _DIVE_TILT_DEG := 25.0

const _THUNDER_BOLT_DAMAGE   := 3
const _TALON_DIVE_DAMAGE     := 4
const _STATIC_PULSE_DAMAGE   := 2
const _STORM_BARRAGE_DAMAGE  := 3
const _MELEE_RANGE           := 200.0

const _THUNDER_ORB_SCENE := preload("res://characters/bosses/voltrix_thunder_orb.tscn")
const _STATIC_PULSE_FX_SCENE := preload("res://characters/bosses/voltrix_static_pulse_fx.tscn")
const _TALON_IMPACT_FX_SCENE := preload("res://characters/bosses/voltrix_talon_impact_fx.tscn")

# Cada anim eh uma sequencia de sprites individuais (nao um spritesheet horizontal
# como os outros bosses) -- carregamos os frames num Array e trocamos a textura
# do Sprite2D a cada tick, em vez de usar hframes/frame.
var _hover1_frames: Array[Texture2D] = []
var _hover2_frames: Array[Texture2D] = []
var _entrada_frames: Array[Texture2D] = []
var _preparacao_frames: Array[Texture2D] = []
var _thunderbolt_frames: Array[Texture2D] = []
var _static_pulse_frames: Array[Texture2D] = []
var _dive_crouch_frames: Array[Texture2D] = []
var _dive_lunge_frames: Array[Texture2D] = []

var _anim_state: AnimState = AnimState.HOVER1
var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _facing: float = -1.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	super._ready()
	gravity_scale = 0.0
	_load_frame_arrays()

func _load_frame_arrays() -> void:
	for i in _HOVER1_FRAMES:
		_hover1_frames.append(load("res://characters/bosses/voltrix/voltrix_hover1_south_f%02d.png" % i))
	for i in _HOVER2_FRAMES:
		_hover2_frames.append(load("res://characters/bosses/voltrix/voltrix_hover2_south_f%02d.png" % i))
	for i in _ENTRADA_FRAMES:
		_entrada_frames.append(load("res://characters/bosses/voltrix/voltrix_entrada_south_f%02d.png" % i))
	for i in _PREPARACAO_FRAMES:
		_preparacao_frames.append(load("res://characters/bosses/voltrix/voltrix_preparacao_south_f%02d.png" % i))
	for i in _THUNDERBOLT_FRAMES:
		_thunderbolt_frames.append(load("res://characters/bosses/voltrix/voltrix_thunderbolt_south_f%02d.png" % i))
	for i in _STATIC_PULSE_FRAMES:
		_static_pulse_frames.append(load("res://characters/bosses/voltrix/voltrix_static_pulse_south_f%02d.png" % i))
	for i in _DIVE_CROUCH_FRAMES:
		_dive_crouch_frames.append(load("res://characters/bosses/voltrix/voltrix_dive_crouch_south_f%02d.png" % i))
	for i in _DIVE_LUNGE_FRAMES:
		_dive_lunge_frames.append(load("res://characters/bosses/voltrix/voltrix_dive_lunge_south_f%02d.png" % i))

func _draw() -> void:
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	draw_rect(Rect2(-24, -52, 48, 6), Color.BLACK)
	draw_rect(Rect2(-24, -52, 48.0 * pct, 6), Color.GREEN)

func _face_player() -> void:
	pass

func _physics_process(delta: float) -> void:
	super(delta)
	_update_animation(delta)

func _current_frame_array() -> Array[Texture2D]:
	match _anim_state:
		AnimState.HOVER2:       return _hover2_frames
		AnimState.ENTRADA:      return _entrada_frames
		AnimState.PREPARACAO:   return _preparacao_frames
		AnimState.THUNDERBOLT:  return _thunderbolt_frames
		AnimState.STATIC_PULSE: return _static_pulse_frames
		AnimState.DIVE_CROUCH:  return _dive_crouch_frames
		AnimState.DIVE_LUNGE:   return _dive_lunge_frames
		_:                      return _hover1_frames

func _update_animation(delta: float) -> void:
	if state == State.INTRO:
		_play_state(AnimState.ENTRADA)
	elif state in [State.DYING, State.DEAD]:
		return
	elif _anim_state == AnimState.ENTRADA:
		# Intro acabou (state saiu de INTRO) mas a entrada ainda nao foi trocada
		# de volta -- acontece uma vez, na primeira _update_animation em COMBAT.
		_play_state(AnimState.HOVER1)
	elif _anim_state in [AnimState.PREPARACAO, AnimState.THUNDERBOLT, AnimState.STATIC_PULSE, AnimState.DIVE_CROUCH, AnimState.DIVE_LUNGE]:
		pass  # ataque em andamento, deixa terminar (ver _play_state)
	else:
		# Sem asas/pernas de andar -- so alterna HOVER1<->HOVER2 (loop continuo),
		# nunca ha "parado" vs "andando" como nos outros bosses.
		if velocity.x >  10.0: _facing =  1.0
		elif velocity.x < -10.0: _facing = -1.0
	_sprite.scale.x = absf(_sprite.scale.x) * (1.0 if _facing > 0.0 else -1.0)
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var a := 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, a)
	else:
		_sprite.modulate = Color.WHITE
	var frames := _current_frame_array()
	if frames.is_empty():
		return
	_anim_timer += delta
	if _anim_timer >= 1.0 / _ANIM_FPS:
		_anim_timer -= 1.0 / _ANIM_FPS
		_anim_frame += 1
		if _anim_frame >= frames.size():
			if _anim_state in [AnimState.ENTRADA, AnimState.PREPARACAO, AnimState.THUNDERBOLT, AnimState.STATIC_PULSE, AnimState.DIVE_CROUCH, AnimState.DIVE_LUNGE]:
				_anim_frame = frames.size() - 1  # segura no ultimo frame, quem chamou decide quando voltar pro hover
			else:
				_anim_frame = 0
				_anim_state = AnimState.HOVER2 if _anim_state == AnimState.HOVER1 else AnimState.HOVER1
				frames = _current_frame_array()
	_sprite.texture = frames[_anim_frame]

# Toca uma animacao nao-hover do inicio (chamado pelo intro e pelos ataques).
func _play_state(new_state: AnimState) -> void:
	if _anim_state == new_state:
		return
	_anim_state = new_state
	_anim_frame = 0
	_anim_timer = 0.0

func _do_combat(delta: float) -> void:
	if _is_attacking:
		return
	if player == null:
		return
	var dx := player.global_position.x - global_position.x
	var target_y := player.global_position.y - 120.0
	var dy := target_y - global_position.y
	velocity.x = sign(dx) * 90.0 if abs(dx) > 220.0 else 0.0
	velocity.y = sign(dy) * 70.0 if abs(dy) > 30.0 else 0.0
	_clamp_to_arena()

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.2

var _last_close_attack_was_dive: bool = false

func _do_attack() -> void:
	_is_attacking = true
	if player == null:
		_is_attacking = false
		return
	var dist := global_position.distance_to(player.global_position)
	if dist > _MELEE_RANGE:
		if phase >= 2:
			await _do_storm_barrage()
		else:
			await _do_thunder_bolt()
	else:
		_last_close_attack_was_dive = not _last_close_attack_was_dive
		if _last_close_attack_was_dive:
			await _do_talon_dive()
		else:
			await _do_static_pulse()
	_is_attacking = false

func _spawn_thunder_orb(pos: Vector2, vel: Vector2, dmg: int) -> void:
	var orb: VoltrixThunderOrb = _THUNDER_ORB_SCENE.instantiate()
	orb.global_position = pos
	orb.projectile_velocity = vel
	orb.damage = dmg
	orb.source_id = "voltrix"
	get_parent().add_child(orb)

func _do_thunder_bolt() -> void:
	_play_state(AnimState.THUNDERBOLT)
	await get_tree().create_timer(float(_THUNDERBOLT_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		return
	if player != null:
		var dir: float = sign(player.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0
		_spawn_thunder_orb(global_position, Vector2(dir * 620.0, 0.0), _THUNDER_BOLT_DAMAGE)
	_play_state(AnimState.HOVER1)

func _do_storm_barrage() -> void:
	_play_state(AnimState.THUNDERBOLT)
	await get_tree().create_timer(float(_THUNDERBOLT_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		return
	if player != null:
		var dir: float = sign(player.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0
		var spread := 0.3
		for i in 3:
			var angle: float = (float(i) - 1.0) * spread
			var vel := Vector2(dir * 620.0, 0.0).rotated(angle)
			_spawn_thunder_orb(global_position, vel, _STORM_BARRAGE_DAMAGE)
	_play_state(AnimState.HOVER1)

func _do_talon_dive() -> void:
	_play_state(AnimState.PREPARACAO)
	await get_tree().create_timer(float(_PREPARACAO_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		_sprite.rotation = 0.0
		return
	_play_state(AnimState.DIVE_CROUCH)
	await get_tree().create_timer(float(_DIVE_CROUCH_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		_sprite.rotation = 0.0
		return
	if player != null:
		var dir: float = sign(player.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0
		# Inclina o sprite na direcao do mergulho -- a arte ja mostra o corpo
		# esticado, a rotacao reforca o angulo diagonal da investida.
		_sprite.rotation = deg_to_rad(-_DIVE_TILT_DEG) if dir > 0.0 else deg_to_rad(_DIVE_TILT_DEG)
		_play_state(AnimState.DIVE_LUNGE)
		velocity = Vector2(dir * 500.0, (player.global_position.y - global_position.y) * 2.0)
		await get_tree().create_timer(float(_DIVE_LUNGE_FRAMES) / _ANIM_FPS).timeout
		if is_dead:
			_sprite.rotation = 0.0
			return
		if player != null and global_position.distance_to(player.global_position) < 60.0:
			player.take_damage(_TALON_DIVE_DAMAGE, "voltrix")
			var impact: Sprite2D = _TALON_IMPACT_FX_SCENE.instantiate()
			impact.global_position = player.global_position
			get_parent().add_child(impact)
		velocity = Vector2.ZERO
	_sprite.rotation = 0.0
	_play_state(AnimState.HOVER1)

func _do_static_pulse() -> void:
	_play_state(AnimState.STATIC_PULSE)
	await get_tree().create_timer(float(_STATIC_PULSE_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		return
	var pulse: Sprite2D = _STATIC_PULSE_FX_SCENE.instantiate()
	pulse.global_position = global_position
	get_parent().add_child(pulse)
	if player != null and global_position.distance_to(player.global_position) < 140.0:
		player.take_damage(_STATIC_PULSE_DAMAGE, "voltrix")
	_play_state(AnimState.HOVER1)
