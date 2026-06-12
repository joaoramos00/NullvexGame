# characters/enemies/enemy_miniboss.gd
extends EnemyBase
class_name EnemyMiniBoss

const _SHOCKWAVE_SCENE := preload("res://effects/shockwave_effect.tscn")
const _TEX_WALK  := preload("res://characters/enemies/miniboss/stage_00/miniboss_walk.png")
const _TEX_IDLE  := preload("res://characters/enemies/miniboss/stage_00/miniboss_idle.png")
const _TEX_PUNCH := preload("res://characters/enemies/miniboss/stage_00/miniboss_punch.png")
const _TEX_STOMP   := preload("res://characters/enemies/miniboss/stage_00/miniboss_stomp.png")
const _TEX_CHARGE  := preload("res://characters/enemies/miniboss/stage_00/miniboss_charge.png")

const _WALK_FRAMES   := 6
const _IDLE_FRAMES   := 4
const _PUNCH_FRAMES  := 9
const _STOMP_FRAMES  := 9
const _CHARGE_FRAMES    := 9  # frames no sprite sheet (para hframes)
const _CHARGE_ANIM_END  := 7  # último frame animado (frame 8 não utilizado)
const _WALK_FPS      := 8.0
const _IDLE_FPS      := 6.0
const _PUNCH_FPS     := 12.0
const _STOMP_FPS     := 12.0
const _CHARGE_FPS    := 10.0

enum State { ADVANCE, CHARGE, STOMP, RECOVER, PUNCH, BACKJUMP }

const MINI_PATROL_SPEED := 60.0
const MINI_PATROL_FAR   := 100.0   # velocidade quando player está longe
const PATROL_FAR_DIST   := 350.0   # distância para considerar "longe"
const CHARGE_DIST       := 320.0
const CHARGE_DASH_SPEED := 380.0
const CHARGE_COOLDOWN   := 2.5
const STOMP_IMPULSE     := -420.0
const RECOVER_TIME      := 0.5
const STOMP_COOLDOWN    := 5.0
const FEET_OFFSET_Y     := 100.0
const PUNCH_RANGE       := 160.0
const PUNCH_COOLDOWN    := 2.5
const PUNCH_DAMAGE      := 4
const PUNCH_ACTIVE_FROM := 4
const PUNCH_ACTIVE_TO   := 7
const PHASE2_HP_RATIO   := 0.5
const PHASE2_SPEED_MULT := 1.35
const PHASE2_CD_MULT    := 0.65
const BACKJUMP_DIST     := 130.0   # distância mínima — abaixo disso pula para trás
const BACKJUMP_SPEED    := 200.0   # velocidade horizontal do backjump
const BACKJUMP_IMPULSE  := -360.0  # impulso vertical
const BACKJUMP_COOLDOWN := 3.5     # cooldown entre backjumps

var _state            : State = State.ADVANCE
var _state_timer      : float = 0.0
var _stomp_cd         : float = 0.0
var _charge_cd        : float = 0.0
var _punch_cd         : float = 0.0
var _was_airborne     : bool  = false
var _punch_timer      : float = 0.0
var _stomp_land_timer : float = 0.0
var _punch_hit        : bool  = false
var _stomp_land_active: bool  = false
var _phase2           : bool  = false
var _backjump_cd      : float = 0.0
var _charge_phase     : int   = 0   # 0=windup 1=dash

@onready var _punch_zone: Area2D = $PunchZone

func _ready() -> void:
	max_hp         = 18
	contact_damage = 3
	super._ready()
	_punch_zone.body_entered.connect(_on_punch_zone_hit)
	_punch_zone.monitoring = false

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_stomp_cd    = max(0.0, _stomp_cd    - delta)
	_punch_cd    = max(0.0, _punch_cd    - delta)
	_charge_cd   = max(0.0, _charge_cd   - delta)
	_backjump_cd = max(0.0, _backjump_cd - delta)
	if not _phase2 and float(current_hp) / float(max_hp) <= PHASE2_HP_RATIO:
		_phase2 = true

	match _state:
		State.ADVANCE:  _tick_advance()
		State.CHARGE:   _tick_charge(delta)
		State.STOMP:    pass
		State.RECOVER:  _tick_recover(delta)
		State.PUNCH:    _tick_punch(delta)
		State.BACKJUMP: _tick_backjump()

	move_and_slide()

	if _state == State.CHARGE and _charge_phase == 1 and is_on_wall():
		_on_charge_wall()
	if _was_airborne and is_on_floor():
		if _state == State.STOMP:
			_on_stomp_land()
		elif _state == State.BACKJUMP:
			_on_backjump_land()
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

func _tick_advance() -> void:
	var player := _get_player()
	if player == null:
		velocity.x = 0.0
		return
	var dx  : float = player.global_position.x - global_position.x
	var adx : float = abs(dx)
	# Sempre encarar e avançar para o player
	_direction = sign(dx) if dx != 0.0 else _direction
	var spd := (MINI_PATROL_FAR if adx > PATROL_FAR_DIST else MINI_PATROL_SPEED)
	if _phase2:
		spd *= PHASE2_SPEED_MULT
	velocity.x = spd * _direction

	# Player muito perto e punch em cooldown → abrir espaço pulando para trás
	if adx < BACKJUMP_DIST and _punch_cd > 0.0 and _backjump_cd <= 0.0 and is_on_floor():
		_enter_backjump()
	# Decisão de ataque: PUNCH → CHARGE → STOMP
	elif adx <= PUNCH_RANGE and _punch_cd <= 0.0:
		_enter_punch()
	elif adx <= CHARGE_DIST and _charge_cd <= 0.0:
		_enter_charge()
	elif adx > CHARGE_DIST and _stomp_cd <= 0.0:
		velocity.y = STOMP_IMPULSE * (1.1 if _phase2 else 1.0)
		_state = State.STOMP

func _enter_charge() -> void:
	_charge_cd    = CHARGE_COOLDOWN * (PHASE2_CD_MULT if _phase2 else 1.0)
	_charge_phase = 0
	_anim_frame   = 0
	_anim_timer   = 0.0
	velocity.x    = 0.0
	_state        = State.CHARGE

func _enter_punch() -> void:
	velocity.x   = 0.0
	_punch_hit   = false
	_punch_cd    = PUNCH_COOLDOWN * (PHASE2_CD_MULT if _phase2 else 1.0)
	_state_timer = float(_PUNCH_FRAMES) / _PUNCH_FPS
	_punch_timer = _state_timer
	_state       = State.PUNCH

func _tick_punch(delta: float) -> void:
	velocity.x   = 0.0
	_state_timer -= delta
	_punch_timer  = maxf(0.0, _punch_timer - delta)
	var total_dur := float(_PUNCH_FRAMES) / _PUNCH_FPS
	var elapsed   := total_dur - maxf(0.0, _state_timer)
	var cur_frame := int(elapsed * _PUNCH_FPS)
	var active    := cur_frame >= PUNCH_ACTIVE_FROM and cur_frame <= PUNCH_ACTIVE_TO
	# Posiciona e ativa a zona de impacto
	_punch_zone.position = Vector2(_direction * 100.0, -150.0)
	_punch_zone.monitoring = active and not _punch_hit
	if not active:
		_punch_hit = false
	if _state_timer <= 0.0:
		_punch_zone.monitoring = false
		_state = State.ADVANCE

func _on_punch_zone_hit(body: Node2D) -> void:
	if _punch_hit or not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(PUNCH_DAMAGE)
		_punch_hit = true
		_punch_zone.monitoring = false

func _tick_charge(delta: float) -> void:
	match _charge_phase:
		0:  # Windup: toca frames 0-7 parado
			velocity.x = 0.0
			_anim_timer += delta
			if _anim_timer >= 1.0 / _CHARGE_FPS:
				_anim_timer -= 1.0 / _CHARGE_FPS
				if _anim_frame < _CHARGE_ANIM_END:
					_anim_frame += 1
				if _anim_frame >= _CHARGE_ANIM_END:
					_charge_phase = 1
		1:  # Dash: congelado no frame 7, avança até a parede
			var spd := CHARGE_DASH_SPEED * (PHASE2_SPEED_MULT if _phase2 else 1.0)
			velocity.x = spd * _direction

func _on_stomp_land() -> void:
	_stomp_cd           = STOMP_COOLDOWN * (PHASE2_CD_MULT if _phase2 else 1.0)
	velocity            = Vector2.ZERO
	_stomp_land_timer   = 3.0 / _STOMP_FPS
	_stomp_land_active  = true
	_punch_timer        = 0.0
	_state_timer        = _stomp_land_timer + RECOVER_TIME
	_state              = State.RECOVER
	var sw := _SHOCKWAVE_SCENE.instantiate() as Node2D
	sw.global_position = Vector2(global_position.x, global_position.y + FEET_OFFSET_Y)
	get_parent().add_child(sw)

func _tick_recover(delta: float) -> void:
	velocity.x        = 0.0
	_state_timer     -= delta
	_punch_timer      = maxf(0.0, _punch_timer - delta)
	_stomp_land_timer = maxf(0.0, _stomp_land_timer - delta)
	if _stomp_land_timer <= 0.0:
		_stomp_land_active = false
	if _state_timer <= 0.0:
		_state = State.ADVANCE

# ─── Backjump ─────────────────────────────────────────────────────────────────

func _enter_backjump() -> void:
	_backjump_cd = BACKJUMP_COOLDOWN * (PHASE2_CD_MULT if _phase2 else 1.0)
	# Salta para trás (direção oposta ao player)
	velocity.x = -_direction * BACKJUMP_SPEED
	velocity.y = BACKJUMP_IMPULSE
	_state = State.BACKJUMP

func _tick_backjump() -> void:
	# Mantém velocidade horizontal enquanto no ar
	pass

func _on_backjump_land() -> void:
	velocity.x = 0.0
	_state = State.ADVANCE

func _on_charge_wall() -> void:
	velocity.x = 0.0
	_state     = State.ADVANCE

# ─── Detecção de borda (exclui o próprio corpo) ───────────────────────────────

func _has_floor_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var start := Vector2(global_position.x + _direction * 50.0, global_position.y - 8.0)
	var end   := Vector2(global_position.x + _direction * 50.0, global_position.y + 120.0)
	var params := PhysicsRayQueryParameters2D.create(start, end)
	params.exclude = [get_rid()]
	return not space.intersect_ray(params).is_empty()

# ─── Debug / ImgDebug ─────────────────────────────────────────────────────────

func debug_set_patrol() -> void:  # mantém nome para o imgdebug
	_state = State.ADVANCE
	set_physics_process(true)

func debug_set_charge() -> void:
	var player := _get_player()
	if player:
		_direction = sign(player.global_position.x - global_position.x)
	_enter_charge()
	set_physics_process(true)

func debug_set_punch() -> void:
	var player := _get_player()
	if player:
		_direction = sign(player.global_position.x - global_position.x)
	_enter_punch()
	set_physics_process(true)

func debug_set_backjump() -> void:
	var player := _get_player()
	if player:
		_direction = sign(player.global_position.x - global_position.x)
	_enter_backjump()
	set_physics_process(true)

func debug_set_stomp() -> void:
	velocity.y = STOMP_IMPULSE
	_state = State.STOMP
	set_physics_process(true)

func debug_set_recover() -> void:
	velocity          = Vector2.ZERO
	_stomp_land_timer = 3.0 / _STOMP_FPS
	_punch_timer      = 0.0
	_state_timer      = _stomp_land_timer + RECOVER_TIME
	_state            = State.RECOVER
	set_physics_process(true)

# ─── Debug hitbox ─────────────────────────────────────────────────────────────

func _draw() -> void:
	if not show_hitbox:
		return
	# Corpo — vermelho
	draw_rect(Rect2(-28, -188, 56, 136), Color(1.0, 0.25, 0.25, 0.2))
	draw_rect(Rect2(-28, -188, 56, 136), Color(1.0, 0.25, 0.25, 1.0), false, 2.0)
	# Cabeça — verde
	draw_rect(Rect2(-32, -223, 65, 35), Color(0.25, 1.0, 0.25, 0.2))
	draw_rect(Rect2(-32, -223, 65, 35), Color(0.25, 1.0, 0.25, 1.0), false, 2.0)
	# Zona de impacto do Punch — amarelo (brilha quando ativo)
	if _state == State.PUNCH:
		var total_dur := float(_PUNCH_FRAMES) / _PUNCH_FPS
		var elapsed   := total_dur - maxf(0.0, _state_timer)
		var cur_frame := int(elapsed * _PUNCH_FPS)
		var active    := cur_frame >= PUNCH_ACTIVE_FROM and cur_frame <= PUNCH_ACTIVE_TO
		var pz_x      := _direction * 100.0 - 70.0
		var alpha     := 0.7 if active else 0.2
		draw_rect(Rect2(pz_x, -180.0, 140.0, 60.0), Color(1.0, 0.9, 0.0, alpha * 0.4))
		draw_rect(Rect2(pz_x, -180.0, 140.0, 60.0), Color(1.0, 0.9, 0.0, alpha), false, 2.0)
	# Zona de impacto do Stomp — laranja (enquanto stomp_land_active)
	if _stomp_land_active:
		draw_rect(Rect2(-150.0, -24.0, 300.0, 48.0), Color(1.0, 0.5, 0.0, 0.35))
		draw_rect(Rect2(-150.0, -24.0, 300.0, 48.0), Color(1.0, 0.5, 0.0, 0.8), false, 2.0)

# ─── Animação ─────────────────────────────────────────────────────────────────

func _update_animation(delta: float) -> void:
	var tex: Texture2D
	var frames: int
	var fps: float

	if _stomp_land_timer > 0.0:
		# Pouso: frames 6-8 do stomp
		tex    = _TEX_STOMP
		frames = _STOMP_FRAMES
		fps    = _STOMP_FPS
	elif _state == State.PUNCH or _punch_timer > 0.0:
		tex    = _TEX_PUNCH
		frames = _PUNCH_FRAMES
		fps    = _PUNCH_FPS
	elif _state == State.CHARGE:
		tex    = _TEX_CHARGE
		frames = _CHARGE_FRAMES
		fps    = _CHARGE_FPS
	elif _state == State.STOMP:
		tex    = _TEX_STOMP
		frames = _STOMP_FRAMES
		fps    = _STOMP_FPS
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

	# Pouso do stomp: avança frames 6-8 com base no tempo restante
	if _stomp_land_timer > 0.0:
		var land_total := 3.0 / _STOMP_FPS
		var elapsed    := land_total - _stomp_land_timer
		_sprite.frame  = 6 + clampi(int(elapsed * _STOMP_FPS), 0, 2)
		return

	# Charge: frame controlado por _tick_charge
	if _state == State.CHARGE:
		_sprite.frame = _anim_frame
		if _direction > 0.0:
			_sprite.flip_h = true
		elif _direction < 0.0:
			_sprite.flip_h = false
		return

	# No ar durante Stomp ou Backjump: congela no frame 5
	if _state == State.STOMP or _state == State.BACKJUMP:
		_sprite.frame = 5
		if velocity.x > 0.0:
			_sprite.flip_h = true
		elif velocity.x < 0.0:
			_sprite.flip_h = false
		return

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
