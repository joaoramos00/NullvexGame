extends BossBase

const _TEX_IDLE_W := preload("res://characters/bosses/umbraex/umbraex_west.png")
const _TEX_IDLE_E := preload("res://characters/bosses/umbraex/umbraex_east.png")
const _TEX_WALK_W := preload("res://characters/bosses/umbraex/umbraex_walk_west.png")
const _TEX_WALK_E := preload("res://characters/bosses/umbraex/umbraex_walk_east.png")
const _TEX_DISAPEAR_W := preload("res://characters/bosses/umbraex/umbraex_disapear_west.png")
const _TEX_DISAPEAR_E := preload("res://characters/bosses/umbraex/umbraex_disapear_east.png")
const _TEX_PUNCH_W := preload("res://characters/bosses/umbraex/umbraex_punch_west.png")
const _TEX_PUNCH_E := preload("res://characters/bosses/umbraex/umbraex_punch_east.png")
const _TEX_THROWSHURIKEN_W := preload("res://characters/bosses/umbraex/umbraex_throwshuriken_west.png")
const _TEX_THROWSHURIKEN_E := preload("res://characters/bosses/umbraex/umbraex_throwshuriken_east.png")

const _WALK_FRAMES  := 9
const _WALK_FPS     := 8.0
# Disapear é usado nos dois sentidos: para a frente (corpo -> fumaça) ao
# sumir, de trás pra frente (fumaça -> corpo) ao aparecer — inclusive na
# entrada da sala (INTRO), sem precisar de uma animação de entrada separada.
const _DISAPEAR_FRAMES := 9
const _DISAPEAR_FPS    := 12.0
const _PUNCH_FRAMES := 9
const _PUNCH_FPS    := 12.0
const _THROWSHURIKEN_FRAMES := 9
const _THROWSHURIKEN_FPS    := 14.0

const _TELEPORT_OFFSET := 120.0
const _PUNCH_DAMAGE := 16
const _SHURIKEN_DAMAGE := 8
const _SHURIKEN_UP_ANGLE := -0.6    # rad, ~34° pra cima
const _SHURIKEN_DOWN_ANGLE := 0.6   # rad, ~34° pra baixo

const _KUNAI_DAMAGE := 10

const _SHURIKEN_SCENE := preload("res://characters/bosses/shuriken_projectile.tscn")
const _KUNAI_SCENE := preload("res://characters/bosses/kunai_projectile.tscn")
const _VOID_ORB_SCENE := preload("res://characters/bosses/void_orb_projectile.tscn")

enum AttackAnim { NONE, VANISH, APPEAR, PUNCH, THROWSHURIKEN }

var _anim_timer : float = 0.0
var _anim_frame : int   = 0
var _facing     : float = -1.0
var _attack_anim: int = AttackAnim.NONE

@onready var _sprite: Sprite2D = $Sprite2D

func _draw() -> void:
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	draw_rect(Rect2(-24, -52, 48, 6), Color.BLACK)
	draw_rect(Rect2(-24, -52, 48.0 * pct, 6), Color.GREEN)

func _face_player() -> void:
	pass

func _physics_process(delta: float) -> void:
	super(delta)
	_update_animation(delta)

func _update_animation(delta: float) -> void:
	if state == State.INTRO:
		# Aparece: Disapear de trás pra frente (fumaça -> corpo sólido).
		var tex := _TEX_DISAPEAR_E if _facing > 0.0 else _TEX_DISAPEAR_W
		if _sprite.texture != tex:
			_sprite.texture = tex
			_sprite.hframes = _DISAPEAR_FRAMES
		_anim_timer += delta
		if _anim_timer >= 1.0 / _DISAPEAR_FPS:
			_anim_timer -= 1.0 / _DISAPEAR_FPS
			_anim_frame = mini(_anim_frame + 1, _DISAPEAR_FRAMES - 1)
		_sprite.frame    = _DISAPEAR_FRAMES - 1 - _anim_frame
		_sprite.modulate = Color.WHITE
		return
	if state in [State.DYING, State.DEAD]:
		return
	if   velocity.x >  10.0: _facing =  1.0
	elif velocity.x < -10.0: _facing = -1.0

	match _attack_anim:
		AttackAnim.VANISH:
			var tex := _TEX_DISAPEAR_E if _facing > 0.0 else _TEX_DISAPEAR_W
			_apply_anim(tex, _DISAPEAR_FRAMES, _DISAPEAR_FPS, delta)
			return
		AttackAnim.APPEAR:
			var tex := _TEX_DISAPEAR_E if _facing > 0.0 else _TEX_DISAPEAR_W
			_apply_anim_reverse(tex, _DISAPEAR_FRAMES, _DISAPEAR_FPS, delta)
			return
		AttackAnim.PUNCH:
			var tex := _TEX_PUNCH_E if _facing > 0.0 else _TEX_PUNCH_W
			_apply_anim(tex, _PUNCH_FRAMES, _PUNCH_FPS, delta)
			return
		AttackAnim.THROWSHURIKEN:
			var tex := _TEX_THROWSHURIKEN_E if _facing > 0.0 else _TEX_THROWSHURIKEN_W
			_apply_anim(tex, _THROWSHURIKEN_FRAMES, _THROWSHURIKEN_FPS, delta)
			return

	if absf(velocity.x) > 10.0:
		var tex := _TEX_WALK_E if _facing > 0.0 else _TEX_WALK_W
		_apply_anim(tex, _WALK_FRAMES, _WALK_FPS, delta)
	else:
		var tex := _TEX_IDLE_E if _facing > 0.0 else _TEX_IDLE_W
		if _sprite.texture != tex:
			_sprite.texture = tex
			_sprite.hframes = 1
			_anim_frame = 0; _anim_timer = 0.0
		_apply_modulate()
		_sprite.frame = 0

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

# Mesma lógica de _apply_anim, mas percorre os frames de trás pra frente —
# usado pra reaproveitar o Disapear como "aparecer" (fumaça -> corpo sólido).
func _apply_anim_reverse(tex: Texture2D, frames: int, fps: float, delta: float) -> void:
	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = frames
	_apply_modulate()
	_anim_timer += delta
	if frames > 1 and _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		_anim_frame = (_anim_frame + 1) % frames
	_sprite.frame = frames - 1 - _anim_frame

func _apply_modulate() -> void:
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var a := 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, a)
	else:
		_sprite.modulate = Color.WHITE

func _do_combat(_delta: float) -> void:
	velocity.x = 0.0

func _do_attack() -> void:
	_is_attacking = true
	velocity.x = 0.0
	if player == null:
		_is_attacking = false
		return
	# Some na posição atual.
	_attack_anim = AttackAnim.VANISH
	_anim_frame = 0; _anim_timer = 0.0
	await get_tree().create_timer(_DISAPEAR_FRAMES / _DISAPEAR_FPS).timeout
	if is_dead:
		_attack_anim = AttackAnim.NONE
		_is_attacking = false
		return
	# Reposiciona perto do player (mesmo cálculo do teleporte antigo).
	var behind := -_TELEPORT_OFFSET if player.facing_right else _TELEPORT_OFFSET
	var tx: float = clamp(
		player.global_position.x + behind,
		arena_left + 60.0, arena_right - 60.0
	)
	global_position = Vector2(tx, player.global_position.y)
	var dir: float = sign(player.global_position.x - global_position.x)
	if dir != 0.0:
		_facing = dir
	queue_redraw()
	# Aparece na nova posição.
	_attack_anim = AttackAnim.APPEAR
	_anim_frame = 0; _anim_timer = 0.0
	await get_tree().create_timer(_DISAPEAR_FRAMES / _DISAPEAR_FPS).timeout
	if is_dead:
		_attack_anim = AttackAnim.NONE
		_is_attacking = false
		return
	var roll := randf()
	if roll < 0.34:
		await _do_punch()
	elif roll < 0.67:
		await _do_throw_shuriken()
	else:
		await _do_throw_kunai()
	_attack_anim = AttackAnim.NONE
	_is_attacking = false

# Canhão de sombra: braço se transforma numa arma e dispara um orbe de vazio
# comprimido que puxa o player pra perto durante o voo — difícil de desviar.
func _do_punch() -> void:
	_attack_anim = AttackAnim.PUNCH
	_anim_frame = 0; _anim_timer = 0.0
	var total := _PUNCH_FRAMES / _PUNCH_FPS
	await get_tree().create_timer(total * 0.7).timeout
	if is_dead:
		return
	if player != null:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2(_facing, 0.0)
		var orb: VoidOrbProjectile = _VOID_ORB_SCENE.instantiate()
		orb.global_position = global_position
		orb.velocity = dir * 180.0
		orb.damage = _PUNCH_DAMAGE
		orb.source_id = "umbraex"
		orb.target = player
		get_parent().add_child(orb)
	await get_tree().create_timer(total * 0.3).timeout

# Dois shurikens em curva (um pra cima, um pra baixo) que vão se corrigindo
# em direção ao player durante o voo — meio teleguiado, não perseguição perfeita.
func _do_throw_shuriken() -> void:
	_attack_anim = AttackAnim.THROWSHURIKEN
	_anim_frame = 0; _anim_timer = 0.0
	var total := _THROWSHURIKEN_FRAMES / _THROWSHURIKEN_FPS
	await get_tree().create_timer(total * 0.75).timeout
	if is_dead:
		return
	if player != null:
		var dir: float = sign(player.global_position.x - global_position.x)
		if dir == 0.0:
			dir = _facing
		_spawn_shuriken(dir, _SHURIKEN_UP_ANGLE)
		_spawn_shuriken(dir, _SHURIKEN_DOWN_ANGLE)
	await get_tree().create_timer(total * 0.25).timeout

func _spawn_shuriken(dir: float, angle_offset: float) -> void:
	var s: ShurikenProjectile = _SHURIKEN_SCENE.instantiate()
	s.global_position = global_position
	s.velocity = Vector2(dir, 0.0).rotated(angle_offset)
	s.damage = _SHURIKEN_DAMAGE
	s.source_id = "umbraex"
	s.target = player
	get_parent().add_child(s)

# Kunai reta, sem curva — reaproveita a mesma animação de arremesso.
func _do_throw_kunai() -> void:
	_attack_anim = AttackAnim.THROWSHURIKEN
	_anim_frame = 0; _anim_timer = 0.0
	var total := _THROWSHURIKEN_FRAMES / _THROWSHURIKEN_FPS
	await get_tree().create_timer(total * 0.75).timeout
	if is_dead:
		return
	if player != null:
		var k: KunaiProjectile = _KUNAI_SCENE.instantiate()
		k.global_position = global_position
		k.velocity = player.global_position - global_position
		k.damage = _KUNAI_DAMAGE
		k.source_id = "umbraex"
		get_parent().add_child(k)
	await get_tree().create_timer(total * 0.25).timeout

func _enter_phase_2() -> void:
	attack_interval_p2 = 0.9
