extends BossBase

# Galerix boss — fox reploide (rework Aug 2026). 2-attack moveset:
#   PREP  -> windup compartilhado (crouches, wind swirls, tail flares)
#   SLASH -> ranged: encadeia do prep e spawna GalerixWindSlash (fx_wind_slash reusa)
#   DASH  -> close-range: pounce forward + damage no impact frame
#
# Todas as anims novas foram geradas em south-east (character `8bf45943-...`
# no PixelLab dashboard). Facing west via `scale.x = -1` — mirror do sprite
# south-east. Walk continua com legacy east/west sheets (não regenerado).

enum AnimState {
	INTRO, IDLE, WALK, PREP,
	ATTACK_SLASH, ATTACK_DASH,
	HURT, DEATH,
}

const _TEX_IDLE   := preload("res://characters/bosses/galerix/galerix_idle_south-east.png")
const _TEX_HURT   := preload("res://characters/bosses/galerix/galerix_hurt_south-east.png")
const _TEX_DEATH  := preload("res://characters/bosses/galerix/galerix_death_south-east.png")
const _TEX_PREP   := preload("res://characters/bosses/galerix/galerix_prep_south-east.png")
const _TEX_SLASH  := preload("res://characters/bosses/galerix/galerix_attack_slash_south-east.png")
const _TEX_DASH   := preload("res://characters/bosses/galerix/galerix_claw_dash_south-east.png")
const _TEX_ENTRY  := preload("res://characters/bosses/galerix/galerix_entry.png")
const _TEX_WALK_E := preload("res://characters/bosses/galerix/galerix_walk_east.png")
const _TEX_WALK_W := preload("res://characters/bosses/galerix/galerix_walk_west.png")

const _IDLE_FRAMES   := 9
const _HURT_FRAMES   := 7
const _DEATH_FRAMES  := 9
const _PREP_FRAMES   := 7
const _SLASH_FRAMES  := 9
const _DASH_FRAMES   := 7
const _ENTRY_FRAMES  := 6
const _WALK_FRAMES   := 8

const _ANIM_FPS  := 10.0
const _WALK_FPS  := 8.0
const _ENTRY_FPS := 8.0

const _WIND_SLASH_SCENE := preload("res://characters/bosses/galerix_wind_slash.gd")
const _SLASH_DAMAGE   := 5
const _DASH_DAMAGE    := 5
const _DASH_RANGE     := 220.0
const _MELEE_RANGE    := 260.0

var _anim_state: AnimState = AnimState.IDLE
var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _facing: float = -1.0

# Dash movement (patrol) — mesmo pattern do Galerix original
var _dash_dir: float = 1.0
var _dash_flip_timer: float = 1.8

@onready var _sprite: Sprite2D = $Sprite2D

func _draw() -> void:
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	draw_rect(Rect2(-24, -52, 48, 6), Color.BLACK)
	draw_rect(Rect2(-24, -52, 48.0 * pct, 6), Color.GREEN)

func _face_player() -> void:
	pass  # driven by _update_animation

func _physics_process(delta: float) -> void:
	super(delta)
	_update_animation(delta)

func _update_animation(delta: float) -> void:
	# 1) Transições passivas de estado
	var next_state: AnimState = _anim_state
	if state == State.INTRO:
		next_state = AnimState.INTRO
	elif state in [State.DYING, State.DEAD]:
		next_state = AnimState.DEATH
	elif _anim_state in [AnimState.INTRO, AnimState.IDLE, AnimState.WALK]:
		next_state = AnimState.WALK if absf(velocity.x) > 10.0 else AnimState.IDLE
	if next_state != _anim_state:
		_play(next_state)

	# 2) Facing (skip durante anims travadas)
	if not (_anim_state in [AnimState.PREP, AnimState.ATTACK_SLASH, AnimState.ATTACK_DASH, AnimState.HURT, AnimState.DEATH, AnimState.INTRO]):
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

	# 4) Modulate
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
				_anim_frame = frames - 1  # hold last (INTRO/DEATH/PREP/SLASH/DASH/HURT)
	_sprite.frame = _anim_frame

func _play(new_state: AnimState) -> void:
	if _anim_state == new_state:
		return
	_anim_state = new_state
	_anim_frame = 0
	_anim_timer = 0.0
	if new_state == AnimState.WALK:
		return  # walk texture handled in _update_animation (directional)
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
		AnimState.ATTACK_SLASH: return _TEX_SLASH
		AnimState.ATTACK_DASH:  return _TEX_DASH
		AnimState.HURT:         return _TEX_HURT
		AnimState.DEATH:        return _TEX_DEATH
		_:                      return _TEX_IDLE

func _frames_for(s: AnimState) -> int:
	match s:
		AnimState.INTRO:        return _ENTRY_FRAMES
		AnimState.IDLE:         return _IDLE_FRAMES
		AnimState.WALK:         return _WALK_FRAMES
		AnimState.PREP:         return _PREP_FRAMES
		AnimState.ATTACK_SLASH: return _SLASH_FRAMES
		AnimState.ATTACK_DASH:  return _DASH_FRAMES
		AnimState.HURT:         return _HURT_FRAMES
		AnimState.DEATH:        return _DEATH_FRAMES
		_:                      return 1

# Patrol dash mantido do Galerix original — corre pra frente e vira, mudando
# de sentido a cada 1.8s ou ao bater na borda da arena.
func _do_combat(delta: float) -> void:
	if _is_attacking:
		velocity.x = 0.0
		return
	_dash_flip_timer -= delta
	if _dash_flip_timer <= 0.0:
		_dash_dir *= -1.0
		_dash_flip_timer = 1.8
	if global_position.x <= arena_left + 60.0:
		_dash_dir = 1.0
		_dash_flip_timer = 1.8
	elif global_position.x >= arena_right - 60.0:
		_dash_dir = -1.0
		_dash_flip_timer = 1.8
	velocity.x = _dash_dir * 220.0
	_clamp_to_arena()

func _do_attack() -> void:
	_is_attacking = true
	if player == null or is_dead:
		_is_attacking = false
		return

	# Prep phase — windup compartilhado
	_play(AnimState.PREP)
	await get_tree().create_timer(float(_PREP_FRAMES) / _ANIM_FPS).timeout
	if is_dead:
		_is_attacking = false
		return

	var dist := global_position.distance_to(player.global_position)
	if dist < _MELEE_RANGE:
		await _do_attack_dash()
	else:
		await _do_attack_slash()

	if not is_dead:
		_play(AnimState.IDLE)
	_is_attacking = false

func _do_attack_slash() -> void:
	_play(AnimState.ATTACK_SLASH)
	# Spawn wind slash no frame 3 (~pico do swing)
	await get_tree().create_timer(3.0 / _ANIM_FPS).timeout
	if is_dead:
		return
	if player != null:
		var dir: float = sign(player.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0
		_spawn_wind_slash(dir)
	await get_tree().create_timer(float(_SLASH_FRAMES - 3) / _ANIM_FPS).timeout

func _do_attack_dash() -> void:
	_play(AnimState.ATTACK_DASH)
	# Impact frame 3 (pico do pounce) — dano se player no alcance
	await get_tree().create_timer(3.0 / _ANIM_FPS).timeout
	if is_dead:
		return
	if player != null and global_position.distance_to(player.global_position) < _DASH_RANGE:
		player.take_damage(_DASH_DAMAGE, "galerix")
	await get_tree().create_timer(float(_DASH_FRAMES - 3) / _ANIM_FPS).timeout

func _spawn_wind_slash(dir: float) -> void:
	var slash: Area2D = _WIND_SLASH_SCENE.new()
	slash.set("dir", dir)
	slash.set("damage", _SLASH_DAMAGE)
	slash.set("source_id", "galerix")
	slash.global_position = global_position + Vector2(dir * 40.0, -20.0)
	get_parent().add_child(slash)

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.0
