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
# Rajada de fogo (onda que viaja em linha reta). Alta demais pra pular do chão
# (pulo ~118px) → força o player a wall-jump na parede.
const WAVE_HEIGHT          := 150.0
const WAVE_WIDTH           := 90.0
const WAVE_SPEED_P1        := 300.0
const WAVE_SPEED_P2        := 430.0
const FIRE_WINDUP_P1       := 0.5    # telegraph antes de cuspir (tempo de ir pra parede)
const FIRE_WINDUP_P2       := 0.35
const CLAW_DAMAGE          := 18
const CLAW_RANGE           := 130.0
const CLAW_MIN_RANGE       := 130.0  # só ataca se player estiver perto
const RAGE_FLASH_DURATION  := 0.6
const _FIRE_WAVE := preload("res://characters/bosses/ignarath/fire_wave.gd")

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

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	stage_id           = 1
	ability_id         = "ignarath"
	max_hp             = 180
	boss_color         = Color(0.8, 0.2, 0.0, 1)
	attack_interval_p1 = 2.5
	attack_interval_p2 = 1.6
	super()
	scale = Vector2(1.0, 1.0)

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
	_is_attacking = true
	_is_attacking_anim = true
	velocity.x = 0.0
	_facing = -1.0 if player.global_position.x < global_position.x else 1.0
	_start_attack_anim(_TEX_FIREBREATH, _FIREBREATH_FRAMES, _FIREBREATH_FPS)

	# Telegraph: brilho de "inspirar" antes de cuspir — dá tempo de correr pra parede.
	var windup := FIRE_WINDUP_P2 if phase >= 2 else FIRE_WINDUP_P1
	_telegraph_timer = windup
	await get_tree().create_timer(windup).timeout
	if is_dead or player == null:
		_telegraph_timer = 0.0
		_end_attack_anim()
		return
	_telegraph_timer = 0.0

	# Cospe a onda de fogo: viaja reto da boca até a parede oposta.
	_spawn_fire_wave()

	await get_tree().create_timer(0.4).timeout
	_end_attack_anim()

func _spawn_fire_wave() -> void:
	var wave: Area2D = _FIRE_WAVE.new()
	wave.set("dir", _facing)
	wave.set("speed", WAVE_SPEED_P2 if phase >= 2 else WAVE_SPEED_P1)
	wave.set("damage", FIRE_DAMAGE)
	wave.set("source_id", "ignarath")
	wave.set("wave_w", WAVE_WIDTH)
	wave.set("wave_h", WAVE_HEIGHT)
	wave.set("despawn_x", (arena_right + 120.0) if _facing > 0.0 else (arena_left - 120.0))
	wave.global_position = Vector2(global_position.x + _facing * 50.0, arena_floor - WAVE_HEIGHT * 0.5)
	get_parent().add_child(wave)

func _do_claw() -> void:
	if player == null:
		return
	# Só executa garra se o player estiver perto
	if global_position.distance_to(player.global_position) > CLAW_MIN_RANGE:
		_is_attacking = false
		return
	_is_attacking = true
	_is_attacking_anim = true
	velocity.x = 0.0
	_facing = -1.0 if player.global_position.x < global_position.x else 1.0
	_start_attack_anim(_TEX_CLAW, _CLAW_FRAMES, _CLAW_FPS)

	# Dano no meio da animação
	var hit_delay := float(_CLAW_FRAMES) / _CLAW_FPS * 0.5
	await get_tree().create_timer(hit_delay).timeout
	if not is_dead and player != null:
		if global_position.distance_to(player.global_position) < CLAW_RANGE:
			player.take_damage(CLAW_DAMAGE)

	await get_tree().create_timer(float(_CLAW_FRAMES) / _CLAW_FPS * 0.5).timeout
	_end_attack_anim()

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

# ── Phase 2 ───────────────────────────────────────────────────────────────────
func _enter_phase_2() -> void:
	_hit_flash_timer = RAGE_FLASH_DURATION
	_is_attacking    = true
	await get_tree().create_timer(RAGE_FLASH_DURATION).timeout
	if not is_dead:
		_is_attacking = false

# ── Take damage override ──────────────────────────────────────────────────────
func take_damage(amount: int, source_id: String = "") -> void:
	super.take_damage(amount, source_id)

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

	# Modulate
	if _hit_flash_timer > 0.0:
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
