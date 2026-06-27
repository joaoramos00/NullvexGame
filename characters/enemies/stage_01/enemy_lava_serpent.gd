extends EnemyBase
class_name EnemyLavaSerpent

const _PROJ := preload("res://characters/enemies/stage_01/fire_projectile.tscn")
const FRAMES := 16
const FPS := 10.0
const T_SUBMERGED := 1.6
const T_EMERGE := 0.7
const T_EXPOSED := 1.2
const T_SUBMERGE := 0.6
const SPIT_SPEED := 320.0
const SPIT_DAMAGE := 8
const SPIT_FRAME := 9   # cospe o fogo quando a animação chega neste frame

enum S { SUBMERGED, EMERGING, EXPOSED, SUBMERGING }
var _state: S = S.SUBMERGED
var _timer := T_SUBMERGED
var _base_y := 0.0
var _base_captured := false
var _spat := false

func _init() -> void:
	max_hp = 14
	contact_damage = 11

func _ready() -> void:
	max_hp = 14
	contact_damage = 11
	super._ready()
	# _base_y é capturado no 1º frame de física (a posição pode ser setada após add_child).
	# Já entra escondida/invulnerável p/ não piscar 1 frame antes da captura.
	_invincible = true
	_set_visible_contact(false)

func _enter(s: S) -> void:
	_state = s
	match s:
		S.SUBMERGED:
			_timer = T_SUBMERGED
			_invincible = true
			global_position.y = _base_y
			_set_visible_contact(false)
		S.EMERGING:
			_timer = T_EMERGE
			_spat = false
			_set_sprite_frame(0)   # reseta a animação p/ o SPIT_FRAME ser consistente por ciclo
		S.EXPOSED:
			_timer = T_EXPOSED
			_invincible = false
			_set_visible_contact(true)
		S.SUBMERGING:
			_timer = T_SUBMERGE

func _set_visible_contact(on: bool) -> void:
	visible = on
	var cz := get_node_or_null("ContactZone") as Area2D
	if cz != null:
		cz.monitoring = on
		cz.monitorable = on

# Vira a serpente para o player (ela é fixa; só espelha o sprite).
func _face_player() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var d: float = signf(p.global_position.x - global_position.x)
	if d != 0.0:
		_direction = d
		if is_instance_valid(_sprite):
			_sprite.flip_h = _direction < 0.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not _base_captured:
		_base_captured = true
		_base_y = global_position.y
		_enter(S.SUBMERGED)
		return
	_timer -= delta
	match _state:
		S.SUBMERGED:
			if _timer <= 0.0:
				visible = true
				_enter(S.EMERGING)
		S.EMERGING:
			# Emerge no lugar — a animação de 16 frames faz o visual de subir do poço.
			if _timer <= 0.0:
				_enter(S.EXPOSED)
		S.EXPOSED:
			_face_player()
			# Cospe fogo quando a animação atinge o frame de disparo (uma vez por ciclo).
			if not _spat and is_instance_valid(_sprite) and _sprite.frame >= SPIT_FRAME:
				_spat = true
				_fire()
			if _timer <= 0.0:
				_enter(S.SUBMERGING)
		S.SUBMERGING:
			if _timer <= 0.0:
				_enter(S.SUBMERGED)
	if _state in [S.EMERGING, S.EXPOSED, S.SUBMERGING]:
		_advance_sprite_frame_loop(delta, FRAMES, FPS)

func _fire() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var dir := Vector2(_direction, -0.2).normalized()
	if p != null:
		dir = (p.global_position - global_position).normalized()
	var proj = _PROJ.instantiate()
	proj.setup(dir * SPIT_SPEED, SPIT_DAMAGE, "lava_serpent", 0.0, "fire_spit")
	get_parent().add_child(proj)
	var ov := HitboxData.proj_offset(_hitbox_id(), _direction)
	var off := ov if ov != Vector2.INF else Vector2(_direction * 50.0, -20.0)
	proj.global_position = global_position + off

func take_damage(amount: int, source: String = "") -> void:
	if _state == S.SUBMERGED:
		return   # invulnerável submersa
	super.take_damage(amount, source)
