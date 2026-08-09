extends BossBase

const _QUAKE_SCENE := preload("res://characters/bosses/quake_wave.tscn")
const _BOULDER_SCENE := preload("res://characters/bosses/rolling_boulder.tscn")
const _FRAGMENT_SCENE := preload("res://characters/bosses/rock_fragment.tscn")

const _TEX_IDLE_W := preload("res://characters/bosses/terragor/terragor_west.png")
const _TEX_IDLE_E := preload("res://characters/bosses/terragor/terragor_east.png")
const _TEX_IDLE_NEW_E := preload("res://characters/bosses/terragor/terragor_idle_east.png")
const _TEX_DEATH_NEW_E := preload("res://characters/bosses/terragor/terragor_death_east.png")
const _TEX_WALK_W := preload("res://characters/bosses/terragor/terragor_walk_west.png")
const _TEX_WALK_E := preload("res://characters/bosses/terragor/terragor_walk_east.png")
const _TEX_WALK2_W := preload("res://characters/bosses/terragor/terragor_walk2_west.png")
const _TEX_WALK2_E := preload("res://characters/bosses/terragor/terragor_walk2_east.png")
const _TEX_ENTRY  := preload("res://characters/bosses/terragor/terragor_entry.png")
const _TEX_GRABSTONE_W := preload("res://characters/bosses/terragor/terragor_grabstone_west.png")
const _TEX_GRABSTONE_E := preload("res://characters/bosses/terragor/terragor_grabstone_east.png")
const _TEX_STONESHATTER_W := preload("res://characters/bosses/terragor/terragor_stoneshatter_west.png")
const _TEX_STONESHATTER_E := preload("res://characters/bosses/terragor/terragor_stoneshatter_east.png")
const _TEX_THROWLEGAL_W := preload("res://characters/bosses/terragor/terragor_throwlegal_west.png")
const _TEX_THROWLEGAL_E := preload("res://characters/bosses/terragor/terragor_throwlegal_east.png")
const _TEX_SMASH_W := preload("res://characters/bosses/terragor/terragor_smash_west.png")
const _TEX_SMASH_E := preload("res://characters/bosses/terragor/terragor_smash_east.png")
const _TEX_BREATHSTONES_W := preload("res://characters/bosses/terragor/terragor_breathstones_west.png")
const _TEX_BREATHSTONES_E := preload("res://characters/bosses/terragor/terragor_breathstones_east.png")
const _TEX_TAKEHIT_W := preload("res://characters/bosses/terragor/terragor_takehit_west.png")
const _TEX_TAKEHIT_E := preload("res://characters/bosses/terragor/terragor_takehit_east.png")

const _WALK_FRAMES  := 9
const _WALK_FPS     := 8.0
const _ENTRY_FRAMES := 9
const _ENTRY_FPS    := 8.0
const _GRABSTONE_FRAMES := 9
const _GRABSTONE_FPS    := 10.0
const _STONESHATTER_FRAMES := 5
const _STONESHATTER_FPS    := 8.0
const _THROWLEGAL_FRAMES := 9
const _THROWLEGAL_FPS    := 12.0
const _SMASH_FRAMES := 9
const _SMASH_FPS    := 14.0
const _BREATHSTONES_FRAMES := 9
const _BREATHSTONES_FPS    := 10.0
const _TAKEHIT_FRAMES := 5
const _TAKEHIT_FPS    := 14.0
const _IDLE_NEW_FRAMES  := 9
const _IDLE_NEW_FPS     := 10.0
const _DEATH_NEW_FRAMES := 9
const _DEATH_NEW_FPS    := 10.0

# Alcance pra decidir corpo-a-corpo (ThrowSoneLegal/Smash) vs à distância
# (StoneShatter/BreathStones) depois do GrabStone.
const _MELEE_RANGE     := 150.0
const _BOULDER_DAMAGE    := 4
const _SMASH_STUN_DURATION := 2.0
const _BREATH_DAMAGE     := 3
const _BREATH_COUNT      := 5

enum AttackAnim { NONE, GRABSTONE, STONESHATTER, THROWLEGAL, SMASH, BREATHSTONES }

signal ground_smash

var _anim_timer : float = 0.0
var _anim_frame : int   = 0
var _facing     : float = -1.0
var _phase2_attack_count : int = 0
# Ciclo de caminhada alterna entre os dois loops de 9 frames gerados
# (Walk -> Walk2 -> Walk -> Walk2...) pra dar mais variedade ao passo pesado
# do Terragor — troca de textura sempre que um loop completa uma volta.
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
		_sprite.texture = _TEX_ENTRY
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
		AttackAnim.GRABSTONE:
			var tex := _TEX_GRABSTONE_E if _facing > 0.0 else _TEX_GRABSTONE_W
			_apply_anim(tex, _GRABSTONE_FRAMES, _GRABSTONE_FPS, delta)
			return
		AttackAnim.STONESHATTER:
			var tex := _TEX_STONESHATTER_E if _facing > 0.0 else _TEX_STONESHATTER_W
			_apply_anim(tex, _STONESHATTER_FRAMES, _STONESHATTER_FPS, delta)
			return
		AttackAnim.THROWLEGAL:
			var tex := _TEX_THROWLEGAL_E if _facing > 0.0 else _TEX_THROWLEGAL_W
			_apply_anim(tex, _THROWLEGAL_FRAMES, _THROWLEGAL_FPS, delta)
			return
		AttackAnim.SMASH:
			var tex := _TEX_SMASH_E if _facing > 0.0 else _TEX_SMASH_W
			_apply_anim(tex, _SMASH_FRAMES, _SMASH_FPS, delta)
			return
		AttackAnim.BREATHSTONES:
			var tex := _TEX_BREATHSTONES_E if _facing > 0.0 else _TEX_BREATHSTONES_W
			_apply_anim(tex, _BREATHSTONES_FRAMES, _BREATHSTONES_FPS, delta)
			return

	if absf(velocity.x) > 10.0:
		_update_walk_animation(delta)
	else:
		_walk_variant = 0   # próxima vez que andar, começa sempre pelo Walk
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

# Aplica textura/frames/fps e avança o ciclo em loop — usado pelas
# animações de ataque e TakeHit (não-locomoção).
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

# Alterna entre os dois loops de caminhada (Walk -> Walk2 -> Walk -> Walk2...),
# trocando de textura sempre que o loop atual de 9 frames completa uma volta.
func _update_walk_animation(delta: float) -> void:
	var tex_e := _TEX_WALK_E if _walk_variant == 0 else _TEX_WALK2_E
	var tex_w := _TEX_WALK_W if _walk_variant == 0 else _TEX_WALK2_W
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
	if abs(dx) > 80.0:
		velocity.x = sign(dx) * 50.0
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
			await _do_grabstone(dx, true)
		else:
			await _do_smash()
	else:
		if randf() < 0.5:
			await _do_grabstone(dx, false)
		else:
			await _do_breath_stones(dx)
	if phase == 2:
		_phase2_attack_count += 1
	_attack_anim = AttackAnim.NONE
	_is_attacking = false

# GrabStone: preparação compartilhada (pega uma pedra) que ramifica pro golpe
# corpo-a-corpo (ThrowSoneLegal) ou pro arremesso à distância (StoneShatter),
# de acordo com o alcance decidido em _do_attack().
func _do_grabstone(dx: float, melee: bool) -> void:
	_attack_anim = AttackAnim.GRABSTONE
	_anim_frame = 0; _anim_timer = 0.0
	var dir: float = sign(dx)
	if dir != 0.0:
		_facing = dir
	await get_tree().create_timer(_GRABSTONE_FRAMES / _GRABSTONE_FPS).timeout
	if is_dead:
		return
	if melee:
		await _do_throw_legal()
	else:
		await _do_stone_shatter()

# Corpo-a-corpo: empurra a pedra grande (rolling_boulder.tscn) no chão até
# o player — sem "soltar" a pedra num frame específico, igual ao Ice Orb do
# Cryovex. Se bater na parede antes de alcançar o player, só quebra "muda"
# (sem espalhar fragmentos — a quebra-com-fragmentos é exclusiva do
# StoneShatter, ver abaixo).
func _do_throw_legal() -> void:
	_attack_anim = AttackAnim.THROWLEGAL
	_anim_frame = 0; _anim_timer = 0.0
	var total := _THROWLEGAL_FRAMES / _THROWLEGAL_FPS
	await get_tree().create_timer(total * 0.6).timeout
	if is_dead:
		return
	var boulder: Area2D = _BOULDER_SCENE.instantiate()
	boulder.global_position = global_position + Vector2(_facing * 40.0, 0.0)
	boulder.dir = _facing
	boulder.damage = _BOULDER_DAMAGE
	boulder.source_id = "terragor"
	boulder.set("spawn_fragments_on_shatter", false)
	get_parent().add_child(boulder)
	await get_tree().create_timer(total * 0.4).timeout

# À distância: esmaga a pedra grande contra o próprio peito — ela não viaja,
# só quebra ali mesmo e explode fragmentos (rock_fragment.tscn) em todas as
# direções, alcançando o player à distância.
func _do_stone_shatter() -> void:
	_attack_anim = AttackAnim.STONESHATTER
	_anim_frame = 0; _anim_timer = 0.0
	await get_tree().create_timer(_STONESHATTER_FRAMES / _STONESHATTER_FPS).timeout
	if is_dead:
		return
	var boulder: Area2D = _BOULDER_SCENE.instantiate()
	boulder.global_position = global_position + Vector2(_facing * 20.0, -20.0)
	boulder.dir = _facing
	boulder.source_id = "terragor"
	get_parent().add_child(boulder)
	boulder.call("shatter_now")
	await get_tree().create_timer(0.5).timeout

# Pisão no chão — reaproveita a quake_wave já existente (mesma usada na
# fase 2 antiga), agora como um ataque corpo-a-corpo independente do ciclo
# do GrabStone. Emite ground_smash (a stage conecta pra tremer a câmera) e,
# se o player estiver no chão ou na parede no momento do impacto, paralisa
# por 2s (stagger — não escapa de um pisão tão pesado).
func _do_smash() -> void:
	_attack_anim = AttackAnim.SMASH
	_anim_frame = 0; _anim_timer = 0.0
	var total := _SMASH_FRAMES / _SMASH_FPS
	await get_tree().create_timer(total * 0.55).timeout
	if is_dead:
		return
	_do_quake_attack()
	ground_smash.emit()
	if player != null and (player.is_on_floor() or player.is_on_wall()):
		if player.has_method("stun"):
			player.stun(_SMASH_STUN_DURATION)
	await get_tree().create_timer(total * 0.45).timeout

# Rajada à distância: espalha fragmentos de pedra (rock_fragment.tscn) num
# leque à frente do Terragor, gravidade faz eles caírem em arco.
func _do_breath_stones(dx: float) -> void:
	_attack_anim = AttackAnim.BREATHSTONES
	_anim_frame = 0; _anim_timer = 0.0
	var dir: float = sign(dx)
	if dir != 0.0:
		_facing = dir
	var total := _BREATHSTONES_FRAMES / _BREATHSTONES_FPS
	await get_tree().create_timer(total * 0.5).timeout
	if is_dead:
		return
	var spread_angle := deg_to_rad(50.0)
	for i in _BREATH_COUNT:
		var t := (float(i) / float(_BREATH_COUNT - 1)) - 0.5
		var angle := t * spread_angle
		var vel := Vector2(_facing, 0.0).rotated(angle) * 220.0
		var frag: Area2D = _FRAGMENT_SCENE.instantiate()
		frag.global_position = global_position + Vector2(_facing * 30.0, -10.0)
		frag.velocity = vel
		frag.damage = _BREATH_DAMAGE
		frag.source_id = "terragor"
		get_parent().add_child(frag)
	await get_tree().create_timer(total * 0.5).timeout

func _do_quake_attack() -> void:
	for dir in [1.0, -1.0]:
		var wave: QuakeWave = _QUAKE_SCENE.instantiate()
		wave.global_position = global_position + Vector2(0.0, -20.0)
		wave.direction = dir
		get_parent().add_child(wave)

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.2
	_phase2_attack_count = 0
