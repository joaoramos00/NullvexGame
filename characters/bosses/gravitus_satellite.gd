extends Area2D
class_name GravitusSatellite

# Satélite orbital lançado pelo Gravitus (Orbiting Satellite Strike). Ao
# nascer, voa até um canto superior da arena (lado oposto ao player, pra
# melhor ângulo de tiro), flutua (Floating), dispara 3 lasers teleguiados no
# chão sob o player (GravitusLaser: telegraph pontilhado -> feixe com dano),
# e termina se autodestruindo (Crack: anel quebra -> explode, dano por
# proximidade na posição do satélite) deixando um buraco negro residual
# (fx_satellite_blackhole, só visual) antes de sumir.
#
# Damageable: funciona como um inimigo — tem HP e take_damage(); se abatido
# pelo player a qualquer momento da sequência, interrompe o que estava
# fazendo e explode no ar (Crack + buraco negro), sem aplicar o dano de
# _strike() no player (abater o satélite é a recompensa, não um risco extra).
const TEX_FLOAT     := preload("res://characters/bosses/gravitus/fx_satellite_float.png")
const TEX_FIRELASER := preload("res://characters/bosses/gravitus/fx_satellite_firelaser.png")
const TEX_CRACK      := preload("res://characters/bosses/gravitus/fx_satellite_crack.png")
const _LASER_SCENE := preload("res://characters/bosses/gravitus_laser.tscn")
const _BLACKHOLE_FX_SCENE := preload("res://characters/bosses/gravitus_blackhole_fx.tscn")

const _FLOAT_FRAMES     := 9
const _FLOAT_FPS        := 8.0
const _FIRELASER_FRAMES := 9
const _FIRELASER_FPS    := 14.0
const _CRACK_FRAMES     := 17
const _CRACK_FPS        := 18.0

const _LAUNCH_SPEED  := 320.0
const _CORNER_MARGIN := 90.0
const _LASER_COUNT   := 3
const _LASER_GAP     := 0.35
const _STRIKE_DAMAGE := 1
const _STRIKE_RADIUS := 90.0

const _MAX_HP := 24
const _INVINCIBILITY_DURATION := 0.15

var player: Node2D = null
var arena_left: float = 100.0
var arena_right: float = 1820.0
var arena_top: float = -200.0
var arena_floor: float = 500.0
var source_id: String = "gravitus"

var current_hp: int = _MAX_HP
var _destroyed := false
var _invincible := false
var _invincibility_timer := 0.0

var _anim_frame := 0
var _anim_timer := 0.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Layer "enemy" (4) — os projéteis/hitboxes do player (zael_bullet,
	# zara_hitbox, etc.) já escutam body_entered/area_entered e chamam
	# take_damage() em quem acertarem; o satélite só precisa estar nessa
	# layer e expor o método, não precisa escutar nada por conta própria.
	collision_layer = 4
	collision_mask = 0
	_sprite.texture = TEX_FLOAT
	_sprite.hframes = _FLOAT_FRAMES
	_run_sequence()

func take_damage(amount: int, _source_id: String = "") -> void:
	if _destroyed or _invincible:
		return
	current_hp = max(0, current_hp - amount)
	_invincible = true
	_invincibility_timer = _INVINCIBILITY_DURATION
	if current_hp <= 0:
		_destroyed = true

func _process(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer = maxf(0.0, _invincibility_timer - delta)
		_invincible = _invincibility_timer > 0.0
	_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0) if _invincible else Color.WHITE
	if _sprite.texture == TEX_FIRELASER or _sprite.texture == TEX_CRACK:
		_anim_timer += delta
		var fps: float = _FIRELASER_FPS if _sprite.texture == TEX_FIRELASER else _CRACK_FPS
		var frames: int = _FIRELASER_FRAMES if _sprite.texture == TEX_FIRELASER else _CRACK_FRAMES
		if _anim_timer >= 1.0 / fps:
			_anim_timer -= 1.0 / fps
			_anim_frame = mini(_anim_frame + 1, frames - 1)
			_sprite.frame = _anim_frame

func _run_sequence() -> void:
	await _launch_to_corner()
	if _destroyed or not is_instance_valid(self):
		await _explode_early()
		return
	for i in _LASER_COUNT:
		await _fire_laser_cycle()
		if _destroyed or not is_instance_valid(self):
			await _explode_early()
			return
		await get_tree().create_timer(_LASER_GAP).timeout
		if _destroyed or not is_instance_valid(self):
			await _explode_early()
			return
	await _strike()

# Voa até o canto superior do lado oposto ao player (melhor ângulo de tiro).
func _launch_to_corner() -> void:
	var center_x := (arena_left + arena_right) * 0.5
	var player_x := player.global_position.x if is_instance_valid(player) else center_x
	var target_x: float = (arena_right - _CORNER_MARGIN) if player_x < center_x else (arena_left + _CORNER_MARGIN)
	var target := Vector2(target_x, arena_top + _CORNER_MARGIN)
	while global_position.distance_to(target) > 6.0 and not _destroyed:
		global_position = global_position.move_toward(target, _LAUNCH_SPEED * get_process_delta_time())
		_play_loop(TEX_FLOAT, _FLOAT_FRAMES, _FLOAT_FPS)
		await get_tree().process_frame
	if not _destroyed:
		global_position = target

func _fire_laser_cycle() -> void:
	_sprite.texture = TEX_FIRELASER
	_sprite.hframes = _FIRELASER_FRAMES
	_anim_frame = 0; _anim_timer = 0.0
	var total := _FIRELASER_FRAMES / _FIRELASER_FPS
	# Dispara no meio da animação (pico do recuo/descarga).
	await get_tree().create_timer(total * 0.5).timeout
	if _destroyed or not is_instance_valid(self):
		return
	_spawn_laser()
	await get_tree().create_timer(total * 0.5).timeout

func _spawn_laser() -> void:
	var laser: GravitusLaser = _LASER_SCENE.instantiate()
	laser.global_position = global_position
	var target_x: float = player.global_position.x if is_instance_valid(player) else global_position.x
	laser.target = Vector2(target_x, arena_floor)
	laser.player = player
	laser.source_id = source_id
	get_parent().add_child(laser)

func _strike() -> void:
	_sprite.texture = TEX_CRACK
	_sprite.hframes = _CRACK_FRAMES
	_anim_frame = 0; _anim_timer = 0.0
	var total := _CRACK_FRAMES / _CRACK_FPS
	await get_tree().create_timer(total * 0.5).timeout
	if not is_instance_valid(self):
		return
	if not _destroyed and is_instance_valid(player) and global_position.distance_to(player.global_position) <= _STRIKE_RADIUS:
		if player.has_method("take_damage"):
			player.take_damage(_STRIKE_DAMAGE, source_id)
	await get_tree().create_timer(total * 0.5).timeout
	_spawn_blackhole()
	queue_free()

# Abatido pelo player antes de terminar a sequência: interrompe o que
# estava fazendo e explode no ar, sem causar dano no player.
func _explode_early() -> void:
	if not is_instance_valid(self):
		return
	set_deferred("monitoring", false)
	_sprite.texture = TEX_CRACK
	_sprite.hframes = _CRACK_FRAMES
	_anim_frame = 0; _anim_timer = 0.0
	var total := _CRACK_FRAMES / _CRACK_FPS
	await get_tree().create_timer(total).timeout
	if not is_instance_valid(self):
		return
	_spawn_blackhole()
	queue_free()

func _spawn_blackhole() -> void:
	var bh: Sprite2D = _BLACKHOLE_FX_SCENE.instantiate()
	bh.global_position = global_position
	get_parent().add_child(bh)

func _play_loop(tex: Texture2D, frames: int, fps: float) -> void:
	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = frames
		_anim_frame = 0; _anim_timer = 0.0
	_anim_timer += get_process_delta_time()
	if _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		_anim_frame = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame
