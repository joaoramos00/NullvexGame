extends BossBase

# Luxar boss — solar bull warrior with a 4-attack moveset:
#   PREP        -> windup compartilhado antes de beam/burst
#   BEAM        -> ranged: encadeia do prep e spawna LuxarSolarOrb
#   BURST       -> close-range: radial AoE dourada
#   SKY (phase 2 only) -> crouch → rise → call, chove 3-5 LuxarSkyBeam
#
# Todas as anims novas foram geradas em south-east (character `dd669b9b-...` no
# PixelLab dashboard). Facing west é feito via `scale.x = -1` — mirror simples
# do sprite south-east. Walk continua usando os sheets legacy east/west
# (não foram regenerados nesta rodada).

enum AnimState {
	INTRO, IDLE, WALK, PREP,
	ATTACK_BEAM, ATTACK_BURST,
	SKY_CROUCH, SKY_RISE, SKY_CALL,
	HURT, DEATH,
}

const _TEX_IDLE       := preload("res://characters/bosses/luxar/luxar_idle_south-east.png")
const _TEX_HURT       := preload("res://characters/bosses/luxar/luxar_hurt_south-east.png")
const _TEX_DEATH      := preload("res://characters/bosses/luxar/luxar_death_south-east.png")
const _TEX_PREP       := preload("res://characters/bosses/luxar/luxar_prep_attack_south-east.png")
const _TEX_BEAM       := preload("res://characters/bosses/luxar/luxar_attack_beam_south-east.png")
const _TEX_BURST      := preload("res://characters/bosses/luxar/luxar_attack_burst_south-east.png")
const _TEX_SKY_CROUCH := preload("res://characters/bosses/luxar/luxar_sky_crouch_south-east.png")
const _TEX_SKY_RISE   := preload("res://characters/bosses/luxar/luxar_sky_rise_south-east.png")
const _TEX_SKY_CALL   := preload("res://characters/bosses/luxar/luxar_sky_call_south-east.png")
const _TEX_ENTRY      := preload("res://characters/bosses/luxar/luxar_entry.png")
const _TEX_WALK_E     := preload("res://characters/bosses/luxar/luxar_walk_east.png")
const _TEX_WALK_W     := preload("res://characters/bosses/luxar/luxar_walk_west.png")

const _IDLE_FRAMES       := 9
const _HURT_FRAMES       := 7
const _DEATH_FRAMES      := 9
const _PREP_FRAMES       := 7
const _BEAM_FRAMES       := 9
const _BURST_FRAMES      := 7
const _SKY_CROUCH_FRAMES := 9
const _SKY_RISE_FRAMES   := 7
const _SKY_CALL_FRAMES   := 7
const _ENTRY_FRAMES      := 6
const _WALK_FRAMES       := 8

const _ANIM_FPS  := 10.0
const _WALK_FPS  := 8.0
const _ENTRY_FPS := 8.0

const _SOLAR_ORB_SCENE := preload("res://characters/bosses/luxar_solar_orb.tscn")
const _SKY_BEAM_SCENE  := preload("res://characters/bosses/luxar_sky_beam.tscn")
const _BEAM_DAMAGE   := 6
const _BURST_DAMAGE  := 4
const _BURST_RADIUS  := 180.0
const _MELEE_RANGE   := 220.0
const _ORB_SPEED     := 500.0
# Sky attack: quantos beams chovem e onde
const _SKY_BEAM_COUNT_P2 := 4     # phase 2: 4 beams
const _SKY_BEAM_INTERVAL := 0.18  # segundos entre spawns
const _SKY_BEAM_SPREAD   := 380.0 # raio horizontal a partir do player pra escolher x aleatório
const _SKY_ATTACK_CHANCE := 0.4   # phase 2: 40% de chance de sky em vez de beam/burst

var _anim_state: AnimState = AnimState.IDLE
var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _facing: float = -1.0
var _last_close_was_burst: bool = false

@onready var _sprite: Sprite2D = $Sprite2D

func _draw() -> void:
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	draw_rect(Rect2(-24, -52, 48, 6), Color.BLACK)
	draw_rect(Rect2(-24, -52, 48.0 * pct, 6), Color.GREEN)

func _face_player() -> void:
	pass  # facing is driven by _update_animation

func _ready() -> void:
	super._ready()
	gravity_scale = 0.0

func _physics_process(delta: float) -> void:
	super(delta)
	_update_animation(delta)

func _update_animation(delta: float) -> void:
	# 1) Decide se precisamos trocar de _anim_state (transições passivas)
	var next_state: AnimState = _anim_state
	if state == State.INTRO:
		next_state = AnimState.INTRO
	elif state in [State.DYING, State.DEAD]:
		next_state = AnimState.DEATH
	elif _anim_state in [AnimState.INTRO, AnimState.IDLE, AnimState.WALK]:
		# Ataques (PREP/BEAM/BURST/HURT) são drivados por _do_attack via await;
		# aqui só oscilamos entre INTRO -> IDLE/WALK e IDLE <-> WALK.
		next_state = AnimState.WALK if absf(velocity.x) > 10.0 else AnimState.IDLE
	if next_state != _anim_state:
		_play(next_state)

	# 2) Facing (skip durante anims travadas por await pra não flipar mid-ataque)
	if not (_anim_state in [AnimState.PREP, AnimState.ATTACK_BEAM, AnimState.ATTACK_BURST, AnimState.SKY_CROUCH, AnimState.SKY_RISE, AnimState.SKY_CALL, AnimState.HURT, AnimState.DEATH, AnimState.INTRO]):
		if player != null:
			var dx := player.global_position.x - global_position.x
			if dx > 20.0:
				_facing = 1.0
			elif dx < -20.0:
				_facing = -1.0

	# 3) Texture selection (WALK é direcional; resto é south-east + mirror)
	if _anim_state == AnimState.WALK:
		var walk_tex: Texture2D = _TEX_WALK_E if _facing > 0.0 else _TEX_WALK_W
		if _sprite.texture != walk_tex:
			_sprite.texture = walk_tex
			_sprite.hframes = _WALK_FRAMES
			_anim_frame = 0
			_anim_timer = 0.0
		_sprite.scale.x = absf(_sprite.scale.x)
	else:
		_sprite.scale.x = absf(_sprite.scale.x) * (1.0 if _facing > 0.0 else -1.0)

	# 4) Modulate (hit flash + invincibility flicker)
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var a := 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, a)
	else:
		_sprite.modulate = Color.WHITE

	# 5) Frame stepping
	var frames := _frames_for(_anim_state)
	var fps: float = _WALK_FPS if _anim_state == AnimState.WALK else (_ENTRY_FPS if _anim_state == AnimState.INTRO else _ANIM_FPS)
	_anim_timer += delta
	if _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		_anim_frame += 1
		if _anim_frame >= frames:
			if _anim_state in [AnimState.IDLE, AnimState.WALK]:
				_anim_frame = 0  # loop
			else:
				_anim_frame = frames - 1  # segura último frame (INTRO/DEATH/PREP/BEAM/BURST/HURT)
	_sprite.frame = _anim_frame

func _play(new_state: AnimState) -> void:
	if _anim_state == new_state:
		return
	_anim_state = new_state
	_anim_frame = 0
	_anim_timer = 0.0
	# WALK tem swap direcional na _update_animation; aqui só seta textures fixas.
	if new_state == AnimState.WALK:
		return
	var tex := _texture_for(new_state)
	var frames := _frames_for(new_state)
	if tex != null:
		_sprite.texture = tex
		_sprite.hframes = frames
		_sprite.frame = 0

func _texture_for(s: AnimState) -> Texture2D:
	match s:
		AnimState.INTRO:        return _TEX_ENTRY
		AnimState.IDLE:         return _TEX_IDLE
		AnimState.PREP:         return _TEX_PREP
		AnimState.ATTACK_BEAM:  return _TEX_BEAM
		AnimState.ATTACK_BURST: return _TEX_BURST
		AnimState.SKY_CROUCH:   return _TEX_SKY_CROUCH
		AnimState.SKY_RISE:     return _TEX_SKY_RISE
		AnimState.SKY_CALL:     return _TEX_SKY_CALL
		AnimState.HURT:         return _TEX_HURT
		AnimState.DEATH:        return _TEX_DEATH
		_:                      return _TEX_IDLE

func _frames_for(s: AnimState) -> int:
	match s:
		AnimState.INTRO:        return _ENTRY_FRAMES
		AnimState.IDLE:         return _IDLE_FRAMES
		AnimState.WALK:         return _WALK_FRAMES
		AnimState.PREP:         return _PREP_FRAMES
		AnimState.ATTACK_BEAM:  return _BEAM_FRAMES
		AnimState.ATTACK_BURST: return _BURST_FRAMES
		AnimState.SKY_CROUCH:   return _SKY_CROUCH_FRAMES
		AnimState.SKY_RISE:     return _SKY_RISE_FRAMES
		AnimState.SKY_CALL:     return _SKY_CALL_FRAMES
		AnimState.HURT:         return _HURT_FRAMES
		AnimState.DEATH:        return _DEATH_FRAMES
		_:                      return 1

func _do_combat(_delta: float) -> void:
	if _is_attacking or player == null:
		return
	var dx := player.global_position.x - global_position.x
	var target_y := player.global_position.y - 100.0
	var dy := target_y - global_position.y
	velocity.x = sign(dx) * 100.0 if abs(dx) > 200.0 else 0.0
	velocity.y = sign(dy) * 80.0 if abs(dy) > 30.0 else 0.0
	_clamp_to_arena()

func _do_attack() -> void:
	_is_attacking = true
	if player == null or is_dead:
		_is_attacking = false
		return

	# Phase 2 pode disparar sky_attack em vez do beam/burst tradicional.
	# Sky é caro (~2.3s de anim + 4 beams chovendo), então mantém baixa freq.
	if phase >= 2 and randf() < _SKY_ATTACK_CHANCE:
		await _do_sky_attack()
		if not is_dead:
			_play(AnimState.IDLE)
		_is_attacking = false
		return

	# Prep phase — windup comum a beam/burst
	_play(AnimState.PREP)
	await get_tree().create_timer(float(_PREP_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		_is_attacking = false
		return

	var dist := global_position.distance_to(player.global_position)
	var do_burst := dist < _MELEE_RANGE
	# Fase 2 alterna beam/burst no close-range pra variar
	if do_burst and phase >= 2:
		_last_close_was_burst = not _last_close_was_burst
		do_burst = _last_close_was_burst

	if do_burst:
		await _do_attack_burst()
	else:
		await _do_attack_beam()

	if not is_dead:
		_play(AnimState.IDLE)
	_is_attacking = false

func _do_attack_beam() -> void:
	_play(AnimState.ATTACK_BEAM)
	# Spawn do orb no frame 3 (~pico da pose de disparo)
	await get_tree().create_timer(3.0 / _ANIM_FPS).timeout
	if is_dead:
		return
	if player != null:
		var dir: float = sign(player.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0
		_spawn_solar_orb(global_position, Vector2(dir * _ORB_SPEED, 0.0))
	# Espera terminar de tocar a anim
	await get_tree().create_timer(float(_BEAM_FRAMES - 3) / _ANIM_FPS).timeout

func _do_attack_burst() -> void:
	_play(AnimState.ATTACK_BURST)
	# Dano radial no frame 3 (pico do burst)
	await get_tree().create_timer(3.0 / _ANIM_FPS).timeout
	if is_dead:
		return
	if player != null and global_position.distance_to(player.global_position) < _BURST_RADIUS:
		player.take_damage(_BURST_DAMAGE, "luxar")
	await get_tree().create_timer(float(_BURST_FRAMES - 3) / _ANIM_FPS).timeout

func _spawn_solar_orb(pos: Vector2, vel: Vector2) -> void:
	var orb: LuxarSolarOrb = _SOLAR_ORB_SCENE.instantiate()
	orb.global_position = pos
	orb.projectile_velocity = vel
	orb.damage = _BEAM_DAMAGE
	orb.source_id = "luxar"
	get_parent().add_child(orb)

# Sky attack (phase 2): crouch → rise → call, e durante o call chove N beams
# em posições x aleatórias ao redor do player. Cada LuxarSkyBeam é
# self-contained (anim + janela de dano + queue_free).
func _do_sky_attack() -> void:
	_play(AnimState.SKY_CROUCH)
	await get_tree().create_timer(float(_SKY_CROUCH_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		return
	_play(AnimState.SKY_RISE)
	await get_tree().create_timer(float(_SKY_RISE_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		return
	_play(AnimState.SKY_CALL)
	# Beams começam a chover no frame 2 do call (quando os braços já estão em cima).
	await get_tree().create_timer(2.0 / _ANIM_FPS).timeout
	if is_dead:
		return
	for i in _SKY_BEAM_COUNT_P2:
		_spawn_sky_beam(_pick_beam_target_x())
		if i < _SKY_BEAM_COUNT_P2 - 1:
			await get_tree().create_timer(_SKY_BEAM_INTERVAL).timeout
			if is_dead:
				return
	# Segura no frame final do call por mais um pouco antes de voltar pro idle.
	await get_tree().create_timer(float(_SKY_CALL_FRAMES - 2) / _ANIM_FPS).timeout

func _pick_beam_target_x() -> float:
	# Escolhe um X aleatório dentro do spread ao redor do player, clampado à arena.
	if player == null:
		return global_position.x
	var base_x := player.global_position.x
	var offset := randf_range(-_SKY_BEAM_SPREAD, _SKY_BEAM_SPREAD)
	return clampf(base_x + offset, arena_left, arena_right)

func _spawn_sky_beam(target_x: float) -> void:
	var beam: LuxarSkyBeam = _SKY_BEAM_SCENE.instantiate()
	# Y do chão da arena — beam nasce sobre o chão pra parecer atingindo o solo.
	beam.global_position = Vector2(target_x, arena_floor - 32.0)
	get_parent().add_child(beam)

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.0
