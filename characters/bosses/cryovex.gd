extends BossBase

const _TEX_IDLE_W := preload("res://characters/bosses/cryovex/cryovex_west.png")
const _TEX_IDLE_E := preload("res://characters/bosses/cryovex/cryovex_east.png")
const _TEX_WALK_W := preload("res://characters/bosses/cryovex/cryovex_walk_west.png")
const _TEX_WALK_E := preload("res://characters/bosses/cryovex/cryovex_walk_east.png")
const _TEX_ENTRY  := preload("res://characters/bosses/cryovex/cryovex_entry.png")
const _TEX_GATHER_W := preload("res://characters/bosses/cryovex/cryovex_gather_west.png")
const _TEX_GATHER_E := preload("res://characters/bosses/cryovex/cryovex_gather_east.png")
const _TEX_BITE_W := preload("res://characters/bosses/cryovex/cryovex_bite_west.png")
const _TEX_BITE_E := preload("res://characters/bosses/cryovex/cryovex_bite_east.png")
const _TEX_ICEBLAST_W := preload("res://characters/bosses/cryovex/cryovex_iceblast_west.png")
const _TEX_ICEBLAST_E := preload("res://characters/bosses/cryovex/cryovex_iceblast_east.png")
const _TEX_TAKEHIT_W := preload("res://characters/bosses/cryovex/cryovex_takehit_west.png")
const _TEX_TAKEHIT_E := preload("res://characters/bosses/cryovex/cryovex_takehit_east.png")
const _TEX_GROUNDBURST_W := preload("res://characters/bosses/cryovex/cryovex_groundburst_west.png")
const _TEX_GROUNDBURST_E := preload("res://characters/bosses/cryovex/cryovex_groundburst_east.png")
const _ICE_SHARD_SCENE := preload("res://characters/bosses/ice_shard.tscn")
const _FROST_IMPACT_SCENE := preload("res://characters/bosses/frost_impact.tscn")
const _ICE_ORB_CHARGE_SCENE := preload("res://characters/bosses/ice_orb_charge.tscn")
const _ICE_ORB_SCENE := preload("res://characters/bosses/ice_orb.tscn")
const _ICE_TOOTH_SCENE := preload("res://characters/bosses/ice_tooth.tscn")

const _WALK_FRAMES  := 9
const _WALK_FPS     := 8.0
const _DASH_FPS     := 14.0   # mesmos frames do walk, tocado mais rápido durante o dash
const _ENTRY_FRAMES := 7
const _ENTRY_FPS    := 8.0
const _GATHER_FRAMES  := 5
const _GATHER_FPS     := 10.0
const _BITE_FRAMES    := 9
const _BITE_FPS       := 16.0
const _ICEBLAST_FRAMES := 9
const _ICEBLAST_FPS    := 12.0
const _TAKEHIT_FRAMES  := 9
const _TAKEHIT_FPS     := 18.0
const _ICE_ORB_CHARGE_FRAMES := 17
const _ICE_ORB_CHARGE_FPS    := 18.0
const _ICE_ORB_SPEED   := 200.0
const _ICE_ORB_DAMAGE  := 14
const _GROUNDBURST_FRAMES := 9
const _GROUNDBURST_FPS    := 14.0
const _ICE_TOOTH_SPACING   := 48.0
const _ICE_TOOTH_STAGGER   := 0.1
const _ICE_TOOTH_DAMAGE    := 6
const _ICE_TOOTH_MAX_COUNT := 8

# Alcance pra decidir qual ramo o ataque toma depois do GatherEnergy: perto
# vira dash+mordida (melee), longe vira IcyBlast (à distância). Um pouco
# maior que o raio em que _do_combat() já para de se aproximar (120px),
# dando espaço real pro dash fechar a distância.
const _DASH_RANGE  := 260.0
const _DASH_SPEED  := 420.0
const _BITE_RANGE  := 100.0
const _BITE_DAMAGE := 16

enum AttackAnim { NONE, GATHER, DASH, BITE, ICEBLAST, GROUNDBURST }

var _anim_timer : float = 0.0
var _anim_frame : int   = 0
var _facing     : float = -1.0
var _attack_anim: int = AttackAnim.NONE
var _takehit_timer: float = 0.0

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

# Escolhe textura/frames/fps pro estado atual e faz a animação avançar.
# Centraliza a lógica repetida entre idle/walk/gather/dash/bite/iceblast/takehit.
# _anim_frame/_anim_timer são resetados no chamador (início de cada ataque/
# reação a dano) — aqui só troca a textura se o estado mudou por fora
# (ex.: virou de direção no meio da animação) e avança o ciclo em loop,
# mesmo padrão já usado pra idle/walk antes desta task.
func _apply_anim(tex: Texture2D, frames: int, fps: float, delta: float) -> void:
	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = frames
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var a := 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, a)
	else:
		_sprite.modulate = Color.WHITE
	_anim_timer += delta
	if frames > 1 and _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		_anim_frame = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame

func _update_animation(delta: float) -> void:
	if state == State.INTRO:
		_sprite.texture = _TEX_ENTRY
		_sprite.hframes = _ENTRY_FRAMES
		_anim_timer += delta
		if _anim_timer >= 1.0 / _ENTRY_FPS:
			_anim_timer -= 1.0 / _ENTRY_FPS
			_anim_frame = mini(_anim_frame + 1, _ENTRY_FRAMES - 1)
		_sprite.frame    = _anim_frame
		_sprite.modulate = Color.WHITE
		return
	if state in [State.DYING, State.DEAD]:
		return
	if   velocity.x >  10.0: _facing =  1.0
	elif velocity.x < -10.0: _facing = -1.0

	# Prioridade: reação a dano > ataque em andamento > locomoção normal.
	if _takehit_timer > 0.0:
		var tex := _TEX_TAKEHIT_E if _facing > 0.0 else _TEX_TAKEHIT_W
		_apply_anim(tex, _TAKEHIT_FRAMES, _TAKEHIT_FPS, delta)
		return

	match _attack_anim:
		AttackAnim.GATHER:
			var tex := _TEX_GATHER_E if _facing > 0.0 else _TEX_GATHER_W
			_apply_anim(tex, _GATHER_FRAMES, _GATHER_FPS, delta)
			return
		AttackAnim.DASH:
			var tex := _TEX_WALK_E if _facing > 0.0 else _TEX_WALK_W
			_apply_anim(tex, _WALK_FRAMES, _DASH_FPS, delta)
			return
		AttackAnim.BITE:
			var tex := _TEX_BITE_E if _facing > 0.0 else _TEX_BITE_W
			_apply_anim(tex, _BITE_FRAMES, _BITE_FPS, delta)
			return
		AttackAnim.ICEBLAST:
			var tex := _TEX_ICEBLAST_E if _facing > 0.0 else _TEX_ICEBLAST_W
			_apply_anim(tex, _ICEBLAST_FRAMES, _ICEBLAST_FPS, delta)
			return
		AttackAnim.GROUNDBURST:
			var tex := _TEX_GROUNDBURST_E if _facing > 0.0 else _TEX_GROUNDBURST_W
			_apply_anim(tex, _GROUNDBURST_FRAMES, _GROUNDBURST_FPS, delta)
			return

	var tex   : Texture2D
	var frames: int
	var fps   : float
	if absf(velocity.x) > 10.0:
		tex = _TEX_WALK_E if _facing > 0.0 else _TEX_WALK_W
		frames = _WALK_FRAMES; fps = _WALK_FPS
	else:
		tex = _TEX_IDLE_E if _facing > 0.0 else _TEX_IDLE_W
		frames = 1; fps = 4.0
	_apply_anim(tex, frames, fps, delta)

func _do_combat(delta: float) -> void:
	if player == null:
		return
	var dx := player.global_position.x - global_position.x
	if abs(dx) > 120.0:
		velocity.x = sign(dx) * 60.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	_clamp_to_arena()

func _do_attack() -> void:
	_is_attacking = true
	velocity.x = 0.0
	_attack_anim = AttackAnim.GATHER
	_anim_frame = 0; _anim_timer = 0.0
	await get_tree().create_timer(_GATHER_FRAMES / _GATHER_FPS).timeout
	if is_dead:
		_attack_anim = AttackAnim.NONE
		_is_attacking = false
		return
	if player == null:
		_attack_anim = AttackAnim.NONE
		_is_attacking = false
		return
	var dx := player.global_position.x - global_position.x
	if abs(dx) <= _DASH_RANGE:
		await _do_dash_bite(dx)
	else:
		var roll := randf()
		if roll < 1.0 / 3.0:
			await _do_iceblast(dx)
		elif roll < 2.0 / 3.0:
			await _do_ice_orb(dx)
		else:
			await _do_ground_burst(dx)
	_attack_anim = AttackAnim.NONE
	_is_attacking = false

func _do_dash_bite(dx: float) -> void:
	_attack_anim = AttackAnim.DASH
	_anim_frame = 0; _anim_timer = 0.0
	var dir: float = sign(dx)
	if dir == 0.0:
		dir = _facing
	var dash_time := 0.35
	var elapsed := 0.0
	while elapsed < dash_time:
		if is_dead:
			return
		velocity.x = dir * _DASH_SPEED
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	velocity.x = 0.0
	_attack_anim = AttackAnim.BITE
	_anim_frame = 0; _anim_timer = 0.0
	var bite_total := _BITE_FRAMES / _BITE_FPS
	await get_tree().create_timer(bite_total * 0.6).timeout
	if is_dead:
		return
	if player != null and global_position.distance_to(player.global_position) < _BITE_RANGE:
		var impact: Node2D = _FROST_IMPACT_SCENE.instantiate()
		impact.global_position = player.global_position
		get_parent().add_child(impact)
		if player.has_method("take_damage"):
			player.take_damage(_BITE_DAMAGE)
	await get_tree().create_timer(bite_total * 0.4).timeout

func _do_iceblast(dx: float) -> void:
	_attack_anim = AttackAnim.ICEBLAST
	_anim_frame = 0; _anim_timer = 0.0
	var dir: float = sign(dx)
	if dir != 0.0:
		_facing = dir   # vira de frente pro player durante o windup, mesmo a rajada saindo pros dois lados
	var blast_total := _ICEBLAST_FRAMES / _ICEBLAST_FPS
	await get_tree().create_timer(blast_total * 0.7).timeout
	if is_dead:
		return
	# Ice Spike Blast: rajada radial de estilhaços saindo em várias direções
	# ao redor do boss (360°, ângulos igualmente espaçados) — ataque de área
	# à distância, não um tiro único mirado no player.
	var shots := 12 if phase == 2 else 8
	for i in shots:
		var angle: float = (TAU / shots) * i
		var vel := Vector2(220.0, 0.0).rotated(angle)
		var shard: Area2D = _ICE_SHARD_SCENE.instantiate()
		shard.global_position = global_position
		shard.projectile_velocity = vel
		shard.damage = 10
		shard.source_id = "cryovex"
		get_parent().add_child(shard)
	await get_tree().create_timer(blast_total * 0.3).timeout

# 3º ataque à distância: reaproveita a animação Bite (boca aberta) parado no
# lugar — sem dash — enquanto uma esfera espinhosa de gelo se forma na boca
# (ice_orb_charge.tscn) e depois é lançada em linha reta mirada no player
# (ice_orb.tscn).
func _do_ice_orb(dx: float) -> void:
	_attack_anim = AttackAnim.BITE
	_anim_frame = 0; _anim_timer = 0.0
	var dir: float = sign(dx)
	if dir != 0.0:
		_facing = dir
	var mouth_offset := Vector2(_facing * 18.0, -38.0)
	var charge: Node2D = _ICE_ORB_CHARGE_SCENE.instantiate()
	charge.global_position = global_position + mouth_offset
	get_parent().add_child(charge)
	var charge_total := _ICE_ORB_CHARGE_FRAMES / _ICE_ORB_CHARGE_FPS
	await get_tree().create_timer(charge_total).timeout
	if is_dead:
		return
	if player != null:
		var launch_pos := global_position + mouth_offset
		var target_dir := (player.global_position - launch_pos).normalized()
		if target_dir == Vector2.ZERO:
			target_dir = Vector2(_facing, 0.0)
		var orb: Area2D = _ICE_ORB_SCENE.instantiate()
		orb.global_position = launch_pos
		orb.projectile_velocity = target_dir * _ICE_ORB_SPEED
		orb.damage = _ICE_ORB_DAMAGE
		orb.source_id = "cryovex"
		get_parent().add_child(orb)
	await get_tree().create_timer(0.2).timeout

# 4º ataque à distância: o boss se ergue no lugar, como se estivesse saindo
# do chão e rasgando o piso (animação GroundBurst, gerada via
# animate_character no PixelLab), enquanto uma fileira de dentes de gelo
# nasce em sequência (ice_tooth.tscn) marchando em direção ao player, até
# alcançá-lo ou atingir o limite de _ICE_TOOTH_MAX_COUNT.
func _do_ground_burst(dx: float) -> void:
	_attack_anim = AttackAnim.GROUNDBURST
	_anim_frame = 0; _anim_timer = 0.0
	var dir: float = sign(dx)
	if dir != 0.0:
		_facing = dir
	velocity.x = 0.0
	var total := _GROUNDBURST_FRAMES / _GROUNDBURST_FPS
	await get_tree().create_timer(total * 0.5).timeout
	if is_dead:
		return
	var count := _ICE_TOOTH_MAX_COUNT
	if player != null:
		count = clampi(int(abs(dx) / _ICE_TOOTH_SPACING), 2, _ICE_TOOTH_MAX_COUNT)
	for i in count:
		if is_dead:
			return
		var tooth: Area2D = _ICE_TOOTH_SCENE.instantiate()
		tooth.global_position = global_position + Vector2(dir * _ICE_TOOTH_SPACING * (i + 1), 0.0)
		tooth.damage = _ICE_TOOTH_DAMAGE
		tooth.source_id = "cryovex"
		get_parent().add_child(tooth)
		await get_tree().create_timer(_ICE_TOOTH_STAGGER).timeout
	await get_tree().create_timer(total * 0.3).timeout

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.2
