# characters/enemies/enemy_miniboss.gd
extends EnemyBase
class_name EnemyMiniBoss

const _SHOCKWAVE_SCENE := preload("res://effects/shockwave_effect.tscn")
const _TEX_WALK  := preload("res://characters/enemies/miniboss/miniboss_walk.png")
const _TEX_IDLE  := preload("res://characters/enemies/miniboss/miniboss_idle.png")
const _TEX_PUNCH := preload("res://characters/enemies/miniboss/miniboss_punch.png")

const _WALK_FRAMES  := 6
const _IDLE_FRAMES  := 4
const _PUNCH_FRAMES := 9
const _WALK_FPS     := 8.0
const _IDLE_FPS     := 6.0
const _PUNCH_FPS    := 12.0

enum State { PATROL, CHARGE, STOMP, RECOVER }

const MINI_PATROL_SPEED := 50.0
const CHARGE_SPEED      := 220.0
const CHARGE_DURATION   := 0.5
const CHARGE_DIST       := 300.0
const STOMP_IMPULSE     := -400.0
const RECOVER_TIME      := 0.6
const STOMP_COOLDOWN    := 4.0
const FEET_OFFSET_Y     := 100.0

var _state        : State = State.PATROL
var _state_timer  : float = 0.0
var _stomp_cd     : float = 0.0
var _was_airborne : bool  = false
var _punch_timer  : float = 0.0

func _ready() -> void:
	max_hp         = 18
	contact_damage = 3
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_stomp_cd = max(0.0, _stomp_cd - delta)

	match _state:
		State.PATROL:  _tick_patrol()
		State.CHARGE:  _tick_charge(delta)
		State.STOMP:   pass
		State.RECOVER: _tick_recover(delta)

	move_and_slide()

	if _was_airborne and is_on_floor() and _state == State.STOMP:
		_on_stomp_land()
	_was_airborne = not is_on_floor()

	_update_animation(delta)

	if _invincible:
		_sprite.modulate.a = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

# ─── Dano ─────────────────────────────────────────────────────────────────────

# O corpo é uma parede — não recebe dano diretamente.
func take_damage(_amount: int, _source: String = "") -> void:
	pass

# Só a cabeça (Head Area2D) chama este método.
func head_take_damage(amount: int, source: String = "") -> void:
	if is_dead or _invincible:
		return
	current_hp = max(0, current_hp - amount)
	_invincible = true
	_invincibility_timer = INVINCIBILITY_DURATION
	damaged.emit(amount)
	if current_hp == 0:
		_die()

# ─── Estados ──────────────────────────────────────────────────────────────────

func _tick_patrol() -> void:
	if is_on_wall():
		_direction = -_direction
	var player := _get_player()
	if player == null:
		velocity.x = MINI_PATROL_SPEED * _direction
		return
	var dx: float = player.global_position.x - global_position.x
	_direction = sign(dx) if dx != 0.0 else _direction
	if is_on_floor() and not _has_floor_ahead():
		_direction = -_direction
	velocity.x = MINI_PATROL_SPEED * _direction
	if abs(dx) <= CHARGE_DIST:
		_state_timer = CHARGE_DURATION
		_state       = State.CHARGE
	elif _stomp_cd <= 0.0:
		velocity.y = STOMP_IMPULSE
		_state      = State.STOMP

func _tick_charge(delta: float) -> void:
	if is_on_wall():
		_direction = -_direction
	_state_timer -= delta
	velocity.x    = CHARGE_SPEED * _direction
	if _state_timer <= 0.0:
		velocity.x = 0.0
		velocity.y = STOMP_IMPULSE
		_state     = State.STOMP

func _on_stomp_land() -> void:
	_stomp_cd    = STOMP_COOLDOWN
	velocity     = Vector2.ZERO
	_punch_timer = float(_PUNCH_FRAMES) / _PUNCH_FPS
	_state_timer = _punch_timer + RECOVER_TIME
	_state       = State.RECOVER
	var sw := _SHOCKWAVE_SCENE.instantiate() as Node2D
	sw.global_position = Vector2(global_position.x, global_position.y + FEET_OFFSET_Y)
	get_parent().add_child(sw)

func _tick_recover(delta: float) -> void:
	velocity.x   = 0.0
	_state_timer -= delta
	_punch_timer  = maxf(0.0, _punch_timer - delta)
	if _state_timer <= 0.0:
		_state = State.PATROL

# ─── Detecção de borda (exclui o próprio corpo) ───────────────────────────────

func _has_floor_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var start := Vector2(global_position.x + _direction * 50.0, global_position.y - 8.0)
	var end   := Vector2(global_position.x + _direction * 50.0, global_position.y + 120.0)
	var params := PhysicsRayQueryParameters2D.create(start, end)
	params.exclude = [get_rid()]
	return not space.intersect_ray(params).is_empty()

# ─── Debug / ImgDebug ─────────────────────────────────────────────────────────

func debug_set_patrol() -> void:
	_state = State.PATROL
	set_physics_process(true)

func debug_set_charge() -> void:
	var player := _get_player()
	if player:
		_direction = sign(player.global_position.x - global_position.x)
	_state_timer = CHARGE_DURATION
	_state = State.CHARGE
	set_physics_process(true)

func debug_set_stomp() -> void:
	velocity.y = STOMP_IMPULSE
	_state = State.STOMP
	set_physics_process(true)

func debug_set_recover() -> void:
	velocity = Vector2.ZERO
	_punch_timer = float(_PUNCH_FRAMES) / _PUNCH_FPS
	_state_timer = _punch_timer + RECOVER_TIME
	_state = State.RECOVER
	set_physics_process(true)

# ─── Debug hitbox ─────────────────────────────────────────────────────────────

func _draw() -> void:
	if not show_hitbox:
		return
	# Corpo — vermelho (visual, não estende até o chão para mostrar área vulnerável)
	draw_rect(Rect2(-28, -188, 56, 136), Color(1.0, 0.25, 0.25, 0.2))
	draw_rect(Rect2(-28, -188, 56, 136), Color(1.0, 0.25, 0.25, 1.0), false, 2.0)
	# Cabeça (RectangleShape2D size=65×35 em y=-205) — verde
	draw_rect(Rect2(-32, -223, 65, 35), Color(0.25, 1.0, 0.25, 0.2))
	draw_rect(Rect2(-32, -223, 65, 35), Color(0.25, 1.0, 0.25, 1.0), false, 2.0)

# ─── Animação ─────────────────────────────────────────────────────────────────

func _update_animation(delta: float) -> void:
	var tex: Texture2D
	var frames: int
	var fps: float

	if _punch_timer > 0.0:
		tex    = _TEX_PUNCH
		frames = _PUNCH_FRAMES
		fps    = _PUNCH_FPS
	elif _state == State.RECOVER:
		tex    = _TEX_IDLE
		frames = _IDLE_FRAMES
		fps    = _IDLE_FPS
	else:
		tex    = _TEX_WALK
		frames = _WALK_FRAMES
		fps    = _WALK_FPS

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
	# Só atualiza o flip quando em movimento — mantém última direção quando parado
	if velocity.x > 0.0:
		_sprite.flip_h = true   # movendo para direita → vira (sprite orienta para esquerda)
	elif velocity.x < 0.0:
		_sprite.flip_h = false  # movendo para esquerda → face padrão
