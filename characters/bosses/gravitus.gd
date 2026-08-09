extends BossBase

# Gravitus reconstruído a partir de novo character PixelLab (urso mecânico
# bípede com módulo de mísseis nas costas). Ciclo de caminhada alterna entre
# Walk1/Walk2 (mesmo padrão do Terragor). Combate: Preparo compartilhado
# (agachar, garras cravadas) antes de Gravity Slam e Missile Barrage — o
# agachamento também expõe os lançadores nas costas —, e Singularity Punch
# tem seu próprio wind-up dedicado. Missile Barrage usa GravitusMissile
# (fly + explosion, arte PixelLab dedicada); Slam/Punch ainda usam dano por
# proximidade (sem FX próprio ainda).
const _TEX_IDLE_W := preload("res://characters/bosses/gravitus/gravitus_west.png")
const _TEX_IDLE_E := preload("res://characters/bosses/gravitus/gravitus_east.png")
const _TEX_IDLE_NEW_E := preload("res://characters/bosses/gravitus/gravitus_idle_east.png")
const _TEX_DEATH_NEW_E := preload("res://characters/bosses/gravitus/gravitus_death_east.png")
const _TEX_WALK1_W := preload("res://characters/bosses/gravitus/gravitus_walk1_west.png")
const _TEX_WALK1_E := preload("res://characters/bosses/gravitus/gravitus_walk1_east.png")
const _TEX_WALK2_W := preload("res://characters/bosses/gravitus/gravitus_walk2_west.png")
const _TEX_WALK2_E := preload("res://characters/bosses/gravitus/gravitus_walk2_east.png")
const _TEX_ENTRY_W := preload("res://characters/bosses/gravitus/gravitus_entry_west.png")
const _TEX_ENTRY_E := preload("res://characters/bosses/gravitus/gravitus_entry_east.png")
const _TEX_PREPARO_W := preload("res://characters/bosses/gravitus/gravitus_preparo_west.png")
const _TEX_PREPARO_E := preload("res://characters/bosses/gravitus/gravitus_preparo_east.png")
const _TEX_SLAM_W := preload("res://characters/bosses/gravitus/gravitus_slam_west.png")
const _TEX_SLAM_E := preload("res://characters/bosses/gravitus/gravitus_slam_east.png")
const _TEX_MISSILE_W := preload("res://characters/bosses/gravitus/gravitus_missile_west.png")
const _TEX_MISSILE_E := preload("res://characters/bosses/gravitus/gravitus_missile_east.png")
const _TEX_SINGPUNCH_PREP_W := preload("res://characters/bosses/gravitus/gravitus_singpunch_prep_west.png")
const _TEX_SINGPUNCH_PREP_E := preload("res://characters/bosses/gravitus/gravitus_singpunch_prep_east.png")
const _TEX_SINGPUNCH_W := preload("res://characters/bosses/gravitus/gravitus_singpunch_west.png")
const _TEX_SINGPUNCH_E := preload("res://characters/bosses/gravitus/gravitus_singpunch_east.png")
const _TEX_TAKEHIT_W := preload("res://characters/bosses/gravitus/gravitus_takehit_west.png")
const _TEX_TAKEHIT_E := preload("res://characters/bosses/gravitus/gravitus_takehit_east.png")

const _MISSILE_SCENE := preload("res://characters/bosses/gravitus_missile.tscn")
const _SINGULARITY_FX_SCENE := preload("res://characters/bosses/gravitus_singularity_fx.tscn")
const _FIST_OFFSET := Vector2(60.0, -20.0)
const _SATELLITE_SCENE := preload("res://characters/bosses/gravitus_satellite.tscn")

const _WALK_FRAMES  := 7
const _WALK_FPS     := 8.0
const _ENTRY_FRAMES := 9
const _ENTRY_FPS    := 8.0
const _PREPARO_FRAMES := 9
const _PREPARO_FPS    := 10.0
const _SLAM_FRAMES := 9
const _SLAM_FPS    := 14.0
const _MISSILE_FRAMES := 9
const _MISSILE_FPS    := 14.0
const _SINGPUNCH_PREP_FRAMES := 9
const _SINGPUNCH_PREP_FPS    := 10.0
const _SINGPUNCH_FRAMES := 9
const _SINGPUNCH_FPS    := 16.0
const _TAKEHIT_FRAMES := 9
const _TAKEHIT_FPS    := 14.0
const _IDLE_NEW_FRAMES  := 9
const _IDLE_NEW_FPS     := 10.0
const _DEATH_NEW_FRAMES := 9
const _DEATH_NEW_FPS    := 10.0

const _MELEE_RANGE  := 150.0
const _SLAM_RANGE   := 160.0
const _PUNCH_RANGE  := 110.0
const _SLAM_DAMAGE  := 3
const _PUNCH_DAMAGE := 4
const _MISSILE_DAMAGE := 2
const _MISSILE_COUNT  := 3

enum AttackAnim { NONE, PREPARO, SLAM, MISSILE, SINGPUNCH_PREP, SINGPUNCH }

var _anim_timer : float = 0.0
var _anim_frame : int   = 0
var _facing     : float = -1.0
# Ciclo de caminhada alterna entre os dois loops gerados (Walk1 -> Walk2 ->
# Walk1 -> ...), trocando de textura sempre que um loop completa uma volta.
var _walk_variant : int = 0
var _attack_anim: int = AttackAnim.NONE
var _takehit_timer: float = 0.0
var _dying_anim_done: bool = false

@onready var _sprite: Sprite2D = $Sprite2D

func _draw() -> void:
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	draw_rect(Rect2(-24, -52, 48, 6), Color.BLACK)
	draw_rect(Rect2(-24, -52, 48.0 * pct, 6), Color.GREEN)

func _face_player() -> void:
	pass

func _physics_process(delta: float) -> void:
	super(delta)
	if _takehit_timer > 0.0:
		_takehit_timer = maxf(0.0, _takehit_timer - delta)
	_update_animation(delta)

func take_damage(amount: int, source_id: String = "") -> void:
	super.take_damage(amount, source_id)
	if not is_dead and state == State.COMBAT:
		_takehit_timer = _TAKEHIT_FRAMES / _TAKEHIT_FPS
		_anim_frame = 0
		_anim_timer = 0.0

func _update_animation(delta: float) -> void:
	# DEATH override — ganha prioridade sobre tudo (inclusive INTRO).
	if state in [State.DYING, State.DEAD]:
		_apply_new_anim_east(_TEX_DEATH_NEW_E, _DEATH_NEW_FRAMES, _DEATH_NEW_FPS, delta, true)
		return
	if state == State.INTRO:
		var tex := _TEX_ENTRY_E if _facing > 0.0 else _TEX_ENTRY_W
		if _sprite.texture != tex:
			_sprite.texture = tex
			_sprite.hframes = _ENTRY_FRAMES
			_sprite.flip_h = false
		_anim_timer += delta
		if _anim_timer >= 1.0 / _ENTRY_FPS:
			_anim_timer -= 1.0 / _ENTRY_FPS
			_anim_frame = mini(_anim_frame + 1, _ENTRY_FRAMES - 1)
		_sprite.frame    = _anim_frame
		_sprite.modulate = Color.WHITE
		return
	if   velocity.x >  10.0: _facing =  1.0
	elif velocity.x < -10.0: _facing = -1.0

	# Prioridade: reação a dano > ataque em andamento > locomoção normal.
	if _takehit_timer > 0.0:
		var tex := _TEX_TAKEHIT_E if _facing > 0.0 else _TEX_TAKEHIT_W
		_apply_anim(tex, _TAKEHIT_FRAMES, _TAKEHIT_FPS, delta)
		return

	match _attack_anim:
		AttackAnim.PREPARO:
			var tex := _TEX_PREPARO_E if _facing > 0.0 else _TEX_PREPARO_W
			_apply_anim(tex, _PREPARO_FRAMES, _PREPARO_FPS, delta)
			return
		AttackAnim.SLAM:
			var tex := _TEX_SLAM_E if _facing > 0.0 else _TEX_SLAM_W
			_apply_anim(tex, _SLAM_FRAMES, _SLAM_FPS, delta)
			return
		AttackAnim.MISSILE:
			var tex := _TEX_MISSILE_E if _facing > 0.0 else _TEX_MISSILE_W
			_apply_anim(tex, _MISSILE_FRAMES, _MISSILE_FPS, delta)
			return
		AttackAnim.SINGPUNCH_PREP:
			var tex := _TEX_SINGPUNCH_PREP_E if _facing > 0.0 else _TEX_SINGPUNCH_PREP_W
			_apply_anim(tex, _SINGPUNCH_PREP_FRAMES, _SINGPUNCH_PREP_FPS, delta)
			return
		AttackAnim.SINGPUNCH:
			var tex := _TEX_SINGPUNCH_E if _facing > 0.0 else _TEX_SINGPUNCH_W
			_apply_anim(tex, _SINGPUNCH_FRAMES, _SINGPUNCH_FPS, delta)
			return

	if absf(velocity.x) > 10.0:
		_update_walk_animation(delta)
	else:
		_walk_variant = 0   # próxima vez que andar, começa sempre pelo Walk1
		# IDLE novo animado (substitui o static frame antigo). East + flip_h.
		_apply_new_anim_east(_TEX_IDLE_NEW_E, _IDLE_NEW_FRAMES, _IDLE_NEW_FPS, delta, false)

# Helper pras anims novas (east + flip_h). hold_last=true segura no ultimo
# frame apos completar uma volta (usado pra death).
func _apply_new_anim_east(tex: Texture2D, frames: int, fps: float, delta: float, hold_last: bool) -> void:
	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = frames
		_anim_frame = 0
		_anim_timer = 0.0
		if hold_last:
			_dying_anim_done = false
	_sprite.flip_h = _facing < 0.0
	_apply_modulate()
	if hold_last and _dying_anim_done:
		_sprite.frame = frames - 1
		return
	_anim_timer += delta
	if frames > 1 and _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		if hold_last:
			_anim_frame += 1
			if _anim_frame >= frames:
				_anim_frame = frames - 1
				_dying_anim_done = true
		else:
			_anim_frame = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame

func _apply_anim(tex: Texture2D, frames: int, fps: float, delta: float) -> void:
	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = frames
	_apply_modulate()
	_anim_timer += delta
	if frames > 1 and _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		_anim_frame = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame

func _update_walk_animation(delta: float) -> void:
	var tex_e := _TEX_WALK1_E if _walk_variant == 0 else _TEX_WALK2_E
	var tex_w := _TEX_WALK1_W if _walk_variant == 0 else _TEX_WALK2_W
	var tex   := tex_e if _facing > 0.0 else tex_w
	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = _WALK_FRAMES
	_apply_modulate()
	_anim_timer += delta
	if _anim_timer >= 1.0 / _WALK_FPS:
		_anim_timer -= 1.0 / _WALK_FPS
		_anim_frame += 1
		if _anim_frame >= _WALK_FRAMES:
			_anim_frame = 0
			_walk_variant = 1 - _walk_variant
	_sprite.frame = _anim_frame

func _apply_modulate() -> void:
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var a := 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, a)
	else:
		_sprite.modulate = Color.WHITE

func _do_combat(delta: float) -> void:
	if player == null:
		return
	var dx := player.global_position.x - global_position.x
	if abs(dx) > 100.0:
		velocity.x = sign(dx) * 70.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	_clamp_to_arena()

func _do_attack() -> void:
	_is_attacking = true
	velocity.x = 0.0
	if player == null:
		_is_attacking = false
		return
	var dx := player.global_position.x - global_position.x
	if abs(dx) <= _MELEE_RANGE:
		if randf() < 0.5:
			await _do_gravity_slam()
		else:
			await _do_singularity_punch()
	else:
		if randf() < 0.5:
			await _do_missile_barrage()
		else:
			await _do_satellite_strike()
	_attack_anim = AttackAnim.NONE
	_is_attacking = false

# Preparo compartilhado (agachar, cravar garras) -> soco no chão em área.
func _do_gravity_slam() -> void:
	_attack_anim = AttackAnim.PREPARO
	_anim_frame = 0; _anim_timer = 0.0
	await get_tree().create_timer(_PREPARO_FRAMES / _PREPARO_FPS).timeout
	if is_dead:
		return
	_attack_anim = AttackAnim.SLAM
	_anim_frame = 0; _anim_timer = 0.0
	var total := _SLAM_FRAMES / _SLAM_FPS
	await get_tree().create_timer(total * 0.6).timeout
	if is_dead:
		return
	if player != null and global_position.distance_to(player.global_position) <= _SLAM_RANGE:
		player.take_damage(_SLAM_DAMAGE, "gravitus")
	await get_tree().create_timer(total * 0.4).timeout

# Wind-up dedicado (energia comprimindo na garra) -> soco único de curto alcance.
func _do_singularity_punch() -> void:
	_attack_anim = AttackAnim.SINGPUNCH_PREP
	_anim_frame = 0; _anim_timer = 0.0
	_spawn_singularity_fx("shrink")
	await get_tree().create_timer(_SINGPUNCH_PREP_FRAMES / _SINGPUNCH_PREP_FPS).timeout
	if is_dead:
		return
	_attack_anim = AttackAnim.SINGPUNCH
	_anim_frame = 0; _anim_timer = 0.0
	var total := _SINGPUNCH_FRAMES / _SINGPUNCH_FPS
	await get_tree().create_timer(total * 0.6).timeout
	if is_dead:
		return
	_spawn_singularity_fx("explode")
	if player != null and global_position.distance_to(player.global_position) <= _PUNCH_RANGE:
		player.take_damage(_PUNCH_DAMAGE, "gravitus")
	await get_tree().create_timer(total * 0.4).timeout

func _spawn_singularity_fx(mode: String) -> void:
	var fx: GravitusSingularityFX = _SINGULARITY_FX_SCENE.instantiate()
	fx.mode = mode
	fx.global_position = global_position + Vector2(_FIST_OFFSET.x * _facing, _FIST_OFFSET.y)
	get_parent().add_child(fx)

# Mesmo preparo (agachar expõe os lançadores nas costas) -> saraivada de
# mísseis com arte dedicada (GravitusMissile).
func _do_missile_barrage() -> void:
	_attack_anim = AttackAnim.PREPARO
	_anim_frame = 0; _anim_timer = 0.0
	await get_tree().create_timer(_PREPARO_FRAMES / _PREPARO_FPS).timeout
	if is_dead:
		return
	_attack_anim = AttackAnim.MISSILE
	_anim_frame = 0; _anim_timer = 0.0
	var total := _MISSILE_FRAMES / _MISSILE_FPS
	await get_tree().create_timer(total * 0.4).timeout
	if is_dead:
		return
	if player != null:
		var dir: float = sign(player.global_position.x - global_position.x)
		if dir == 0.0:
			dir = _facing
		for i in _MISSILE_COUNT:
			var vy := (float(i) - float(_MISSILE_COUNT - 1) * 0.5) * 40.0
			var m: GravitusMissile = _MISSILE_SCENE.instantiate()
			m.global_position = global_position
			m.velocity = Vector2(dir * 260.0, vy)
			m.damage = _MISSILE_DAMAGE
			m.source_id = "gravitus"
			get_parent().add_child(m)
	await get_tree().create_timer(total * 0.6).timeout

# Mesmo preparo/pose do Missile Barrage (agachar expõe os lançadores) ->
# lança o satélite orbital, que age de forma autônoma (voa pro canto, dispara
# 3 lasers, se autodestrói) sem travar o Gravitus no meio do combate.
func _do_satellite_strike() -> void:
	_attack_anim = AttackAnim.PREPARO
	_anim_frame = 0; _anim_timer = 0.0
	await get_tree().create_timer(_PREPARO_FRAMES / _PREPARO_FPS).timeout
	if is_dead:
		return
	_attack_anim = AttackAnim.MISSILE
	_anim_frame = 0; _anim_timer = 0.0
	var total := _MISSILE_FRAMES / _MISSILE_FPS
	await get_tree().create_timer(total * 0.4).timeout
	if is_dead:
		return
	_spawn_satellite()
	await get_tree().create_timer(total * 0.6).timeout

func _spawn_satellite() -> void:
	var sat: GravitusSatellite = _SATELLITE_SCENE.instantiate()
	sat.global_position = global_position
	sat.player = player
	sat.arena_left = arena_left
	sat.arena_right = arena_right
	sat.arena_top = arena_top
	sat.arena_floor = arena_floor
	sat.source_id = "gravitus"
	get_parent().add_child(sat)

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.3
