extends BossBase
class_name Ignarath

# ── Textures ─────────────────────────────────────────────────────────────────
const _TEX_ENTER     := preload("res://characters/bosses/ignarath/ignarath_enter.png")
const _TEX_WALKING   := preload("res://characters/bosses/ignarath/ignarath_walking.png")
const _TEX_FIREBREATH := preload("res://characters/bosses/ignarath/ignarath_firebreath.png")
const _TEX_CLAW      := preload("res://characters/bosses/ignarath/ignarath_claw.png")
const _TEX_TAKINGHIT := preload("res://characters/bosses/ignarath/ignarath_takinghit.png")

const _ENTER_FRAMES      := 9;  const _ENTER_FPS      := 8.0
const _WALKING_FRAMES    := 9;  const _WALKING_FPS    := 10.0
const _FIREBREATH_FRAMES := 9;  const _FIREBREATH_FPS := 10.0
const _CLAW_FRAMES       := 9;  const _CLAW_FPS       := 12.0
const _TAKINGHIT_FRAMES  := 9;  const _TAKINGHIT_FPS  := 12.0

# ── Combat constants ──────────────────────────────────────────────────────────
const WALK_SPEED_P1        := 80.0
const WALK_SPEED_P2        := 130.0
const FIRE_DAMAGE          := 12
# Firebreath = beam que sai da boca e varre da vertical pra fora (estilo Godzilla).
const BEAM_SWEEP_TIME_P1   := 1.0
const BEAM_SWEEP_TIME_P2   := 0.7
const BEAM_MAX_ANGLE       := 90.0   # graus a partir da vertical (começa horizontal)
const BEAM_HALF_WIDTH      := 20.0
const MOUTH_DX             := 38.5   # offset da boca (a partir da origem do boss)
const MOUTH_DY             := -15.0
const FIREBREATH_STATIC_FRAME := 8   # frame 9 (1-idx): sprite travado durante a varredura
const FIRE_WINDUP_P1       := 0.5    # telegraph antes de cuspir (tempo de ir pra parede)
const FIRE_WINDUP_P2       := 0.35
const CLAW_DAMAGE          := 18
const CLAW_RANGE           := 130.0    # alcance do corpo-a-corpo (se o player estiver colado)
const CLAW_INVULN_WINDOW   := 0.25     # janela de INVULNERABILIDADE no instante do golpe
# Fogo rasteiro da garra: onda BAIXA que viaja até a parede (dá pra pular por cima).
const CLAW_WAVE_H          := 56.0
const CLAW_WAVE_W          := 90.0
const CLAW_WAVE_SPEED_P1   := 300.0
const CLAW_WAVE_SPEED_P2   := 400.0
const CLAW_WAVE_DAMAGE     := 12
const RAGE_FLASH_DURATION  := 0.6
const _FIRE_WAVE  := preload("res://characters/bosses/ignarath/fire_wave.gd")
const _FIRE_BEAM  := preload("res://characters/bosses/ignarath/fire_beam.gd")
const _TEX_CLAW_SLASH    := preload("res://characters/bosses/ignarath/fx_claw_slash.png")
const _CLAW_SLASH_FRAMES := 7
const _CLAW_SLASH_FPS    := 14.0

# ── State ─────────────────────────────────────────────────────────────────────
var _attack_phase   : int   = 0   # 0=firebreath 1=claw
var _anim_frame     : int   = 0
var _anim_timer     : float = 0.0
var _facing         : float = -1.0  # -1=left  1=right; west sprites → flip when right
var _is_entering    : bool  = false
var _is_attacking_anim : bool = false
var _attack_anim_tex : Texture2D = null
var _attack_anim_frames : int = 0
var _attack_anim_fps    : float = 0.0
var _telegraph_timer    : float = 0.0   # brilho de aviso (windup) antes de cuspir
var _invuln         : bool  = false # INVULNERÁVEL nas janelas (firebreath inteiro / golpe da garra)
var _block_flash_timer  : float = 0.0   # flash cinza ao bloquear dano (invulnerável)
var _attack_gen     : int   = 0     # token p/ cancelar a coroutine de ataque ao ser interrompido
var _static_anim    : bool  = false # trava o frame do sprite (varredura do firebreath)
var _active_beam    : Node  = null  # beam do firebreath em andamento (liberado ao interromper)

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	stage_id           = 1
	ability_id         = "ignarath"
	max_hp             = 180
	boss_color         = Color(0.8, 0.2, 0.0, 1)
	attack_interval_p1 = 2.5
	attack_interval_p2 = 1.6
	super()
	scale = Vector2(0.8, 0.8)
	_sprite.texture = _TEX_WALKING
	_sprite.hframes = _WALKING_FRAMES
	_sprite.vframes = 1
	_sprite.frame   = 0

# Remove o placeholder vermelho + barra de HP do BossBase._draw (o boss usa o
# Sprite2D; o HP é mostrado pelo HUD via connect_to_boss).
func _draw() -> void:
	pass

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_dead:
		_update_animation(delta)

# ── Intro ─────────────────────────────────────────────────────────────────────
func _run_intro() -> void:
	_is_entering = true
	_sprite.texture = _TEX_ENTER
	_sprite.hframes = _ENTER_FRAMES
	_sprite.flip_h  = false
	_anim_frame = 0
	_anim_timer = 0.0
	var duration := float(_ENTER_FRAMES) / _ENTER_FPS
	await get_tree().create_timer(duration).timeout
	_is_entering = false
	if state == State.INTRO:
		state = State.COMBAT
		boss_intro_ended.emit()

# ── Combat movement ───────────────────────────────────────────────────────────
func _do_combat(delta: float) -> void:
	if _is_attacking_anim or _is_attacking:
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		_clamp_to_arena()
		return
	if player != null:
		var dx := player.global_position.x - global_position.x
		var spd := WALK_SPEED_P2 if phase >= 2 else WALK_SPEED_P1
		if absf(dx) > 120.0:
			velocity.x = sign(dx) * spd
		else:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	_clamp_to_arena()

# ── Attacks ───────────────────────────────────────────────────────────────────
func _do_attack() -> void:
	match _attack_phase:
		0: _do_firebreath()
		1: _do_claw()
	_attack_phase = (_attack_phase + 1) % 2

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

	# Sprite travado no último frame + beam que varre imediatamente.
	_static_anim = true
	_anim_frame = FIREBREATH_STATIC_FRAME
	var sweep := BEAM_SWEEP_TIME_P2 if phase >= 2 else BEAM_SWEEP_TIME_P1
	_spawn_fire_beam(sweep)

	await get_tree().create_timer(sweep).timeout
	if gen != _attack_gen or is_dead:
		return
	_static_anim = false
	_end_attack_anim()

func _spawn_fire_beam(sweep_time: float) -> void:
	var beam: Node2D = _FIRE_BEAM.new()
	beam.set("player", player)
	var _mouth := HitboxData.proj_offset("ignarath", _facing)
	if _mouth == Vector2.INF:
		_mouth = Vector2(_facing * MOUTH_DX, MOUTH_DY) * scale.x
	beam.set("origin", global_position + _mouth)
	beam.set("facing", _facing)
	beam.set("floor_y", arena_floor)
	beam.set("sweep_time", sweep_time)
	beam.set("max_angle_deg", BEAM_MAX_ANGLE)
	beam.set("half_width", BEAM_HALF_WIDTH)
	beam.set("damage", FIRE_DAMAGE)
	beam.set("source_id", "ignarath")
	get_parent().add_child(beam)
	_active_beam = beam
	AudioManager.play_sfx(AudioLibrary.sfx_ignarath_fire)

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
	AudioManager.play_sfx(AudioLibrary.sfx_ignarath_clawwave)
	_spawn_claw_slash_fx()
	_run_claw_wave_sequence()

func _run_claw_wave_sequence() -> void:
	var speed := CLAW_WAVE_SPEED_P2 if phase >= 2 else CLAW_WAVE_SPEED_P1
	var gen   := _attack_gen
	# 4 ondas no chão
	for i in 4:
		if i > 0:
			await get_tree().create_timer(0.10).timeout
		if is_dead or gen != _attack_gen:
			return
		_do_floor_wave(speed)
	# 3 pares nas paredes (esq + dir simultâneos)
	await get_tree().create_timer(0.08).timeout
	for i in 3:
		if i > 0:
			await get_tree().create_timer(0.15).timeout
		if is_dead or gen != _attack_gen:
			return
		_do_wall_wave(arena_left  + CLAW_WAVE_H * 0.5, speed)
		_do_wall_wave(arena_right - CLAW_WAVE_H * 0.5, speed)

func _do_floor_wave(speed: float) -> void:
	var wave: Area2D = _FIRE_WAVE.new()
	wave.set("dir", _facing)
	wave.set("speed", speed)
	wave.set("damage", CLAW_WAVE_DAMAGE)
	wave.set("source_id", "ignarath")
	wave.set("wave_w", CLAW_WAVE_W)
	wave.set("wave_h", CLAW_WAVE_H)
	wave.set("despawn_x", (arena_right + 120.0) if _facing > 0.0 else (arena_left - 120.0))
	wave.global_position = Vector2(global_position.x + _facing * 50.0, arena_floor - CLAW_WAVE_H * 0.5)
	get_parent().add_child(wave)

func _do_wall_wave(wall_x: float, speed: float) -> void:
	var wave: Area2D = _FIRE_WAVE.new()
	wave.set("speed", speed)
	wave.set("damage", CLAW_WAVE_DAMAGE)
	wave.set("source_id", "ignarath")
	wave.set("wave_w", CLAW_WAVE_H)   # profundidade horizontal na parede
	wave.set("wave_h", CLAW_WAVE_H)
	wave.set("vertical", true)
	wave.global_position = Vector2(wall_x, arena_floor - CLAW_WAVE_H * 0.5)
	get_parent().add_child(wave)

func _spawn_claw_slash_fx() -> void:
	var sf := SpriteFrames.new()
	sf.add_animation("slash")
	sf.set_animation_loop("slash", false)
	sf.set_animation_speed("slash", _CLAW_SLASH_FPS)
	for i in _CLAW_SLASH_FRAMES:
		var at := AtlasTexture.new()
		at.atlas = _TEX_CLAW_SLASH
		at.region = Rect2(i * 128.0, 0.0, 128.0, 128.0)
		sf.add_frame("slash", at)
	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = sf
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index = 4
	sp.scale = Vector2(_facing, 1.0)
	sp.global_position = Vector2(global_position.x + _facing * 110.0, global_position.y - 60.0)
	sp.animation_finished.connect(sp.queue_free)
	get_parent().add_child(sp)
	sp.play("slash")

func _start_attack_anim(tex: Texture2D, frames: int, fps: float) -> void:
	_attack_anim_tex    = tex
	_attack_anim_frames = frames
	_attack_anim_fps    = fps
	_anim_frame = 0
	_anim_timer = 0.0

func _end_attack_anim() -> void:
	_is_attacking_anim = false
	_is_attacking      = false
	_attack_anim_tex   = null
	_invuln        = false

# ── Phase 2 ───────────────────────────────────────────────────────────────────
func _enter_phase_2() -> void:
	_hit_flash_timer = RAGE_FLASH_DURATION
	_is_attacking    = true
	await get_tree().create_timer(RAGE_FLASH_DURATION).timeout
	if not is_dead:
		_is_attacking = false

# ── Take damage override ──────────────────────────────────────────────────────
func take_damage(amount: int, source_id: String = "") -> void:
	# Durante o firebreath e o golpe da garra o Ignarath fica blindado: imune a dano
	# normal (flash cinza). MAS a fraqueza dele (galerix) fura o escudo, causa dano
	# (2× via BossBase) e INTERROMPE a ação que ele estiver executando.
	if _invuln:
		if source_id != "" and source_id == weakness_id:
			super.take_damage(amount, source_id)
			_break_action()
			return
		_block_flash_timer = 0.12
		return
	super.take_damage(amount, source_id)

# Interrompe o ataque em andamento (chamado quando a fraqueza fura o escudo).
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

func _die() -> void:
	if is_instance_valid(_active_beam):
		_active_beam.queue_free()
	_active_beam = null
	_static_anim = false
	super._die()

# ── Animation ─────────────────────────────────────────────────────────────────
func _update_animation(delta: float) -> void:
	if _is_entering:
		_sprite.modulate = Color.WHITE
		_anim_timer += delta
		if _anim_timer >= 1.0 / _ENTER_FPS:
			_anim_timer -= 1.0 / _ENTER_FPS
			_anim_frame = mini(_anim_frame + 1, _ENTER_FRAMES - 1)
		_sprite.frame = _anim_frame
		return

	# Facing: west sprites = natural left; flip_h when facing right
	if velocity.x > 10.0:
		_facing = 1.0
	elif velocity.x < -10.0:
		_facing = -1.0

	if _telegraph_timer > 0.0:
		_telegraph_timer = maxf(0.0, _telegraph_timer - delta)
	if _block_flash_timer > 0.0:
		_block_flash_timer = maxf(0.0, _block_flash_timer - delta)

	# Modulate
	if _block_flash_timer > 0.0:
		_sprite.modulate = Color(0.5, 0.5, 0.6, 1.0)   # bloqueado (invulnerável agora)
	elif _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _telegraph_timer > 0.0:
		# Brilho laranja pulsante de aviso (windup da rajada de fogo)
		var p: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 30.0)
		_sprite.modulate = Color(1.0 + 0.8 * p, 0.5 + 0.2 * p, 0.15, 1.0)
	elif _invincible:
		var a := 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, a)
	else:
		_sprite.modulate = Color.WHITE

	var tex    : Texture2D
	var frames : int
	var fps    : float

	if _is_attacking_anim and _attack_anim_tex != null:
		tex    = _attack_anim_tex
		frames = _attack_anim_frames
		fps    = _attack_anim_fps
	elif _is_attacking_anim and _attack_anim_tex == null and _anim_frame > 0:
		# takinghit
		tex = _TEX_TAKINGHIT; frames = _TAKINGHIT_FRAMES; fps = _TAKINGHIT_FPS
	elif absf(velocity.x) > 10.0:
		tex = _TEX_WALKING; frames = _WALKING_FRAMES; fps = _WALKING_FPS
	else:
		tex = _TEX_WALKING; frames = _WALKING_FRAMES; fps = 4.0  # slow idle

	_sprite.flip_h = _facing > 0.0
	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = frames
		_anim_frame     = 0
		_anim_timer     = 0.0

	if not _static_anim:
		_anim_timer += delta
		if _anim_timer >= 1.0 / fps:
			_anim_timer -= 1.0 / fps
			_anim_frame  = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame

# ── Hit reaction (visual only) ────────────────────────────────────────────────
func _play_takinghit() -> void:
	_sprite.texture = _TEX_TAKINGHIT
	_sprite.hframes = _TAKINGHIT_FRAMES
	_anim_frame = 0
	_anim_timer = 0.0
