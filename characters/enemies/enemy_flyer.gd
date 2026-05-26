extends EnemyBase

enum State { HOVER, WINDUP, DIVE, RETREAT }

@export var patrol_range:    float = 150.0
@export var detect_radius:   float = 200.0
@export var dive_speed:      float = 280.0
@export var retreat_speed:   float = 150.0
@export var bob_amplitude:   float = 6.0
@export var bob_speed:       float = 2.0
@export var max_dive_time:   float = 1.2
@export var windup_duration: float = 0.6
@export var windup_radius:   float = 20.0

var _state:         State   = State.HOVER
var _start_x:       float   = 0.0
var _spawn_y:       float   = 0.0
var _bob_time:      float   = 0.0
var _dive_timer:    float   = 0.0
var _dive_dir:      Vector2 = Vector2.ZERO
var _windup_timer:  float   = 0.0
var _windup_origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	super._ready()
	_start_x = global_position.x
	_spawn_y  = global_position.y

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false

	match _state:
		State.HOVER:   _tick_hover(delta)
		State.WINDUP:  _tick_windup(delta)
		State.DIVE:    _tick_dive(delta)
		State.RETREAT: _tick_retreat()

	if _state != State.WINDUP:
		move_and_slide()

	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0.0
	if _invincible:
		_sprite.modulate.a = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0

func _tick_hover(delta: float) -> void:
	_bob_time += delta
	if abs(global_position.x - _start_x) >= patrol_range:
		_direction = -_direction
	velocity.x = PATROL_SPEED * _direction
	velocity.y = sin(_bob_time * bob_speed) * bob_amplitude
	if is_on_wall():
		_direction = -_direction

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and global_position.distance_to(player.global_position) <= detect_radius:
		_dive_dir      = (player.global_position - global_position).normalized()
		_windup_origin = global_position
		_windup_timer  = 0.0
		_state         = State.WINDUP

func _tick_windup(delta: float) -> void:
	_windup_timer += delta
	var angle := (_windup_timer / windup_duration) * TAU
	global_position = _windup_origin + Vector2(cos(angle), sin(angle)) * windup_radius
	velocity = Vector2.ZERO
	if _windup_timer >= windup_duration:
		global_position = _windup_origin
		_dive_timer     = max_dive_time
		_state          = State.DIVE

func _tick_dive(delta: float) -> void:
	_dive_timer -= delta
	velocity = _dive_dir * dive_speed
	if _dive_timer <= 0.0:
		_state = State.RETREAT

func _tick_retreat() -> void:
	velocity = Vector2(0.0, -retreat_speed)
	if global_position.y <= _spawn_y:
		global_position.y = _spawn_y
		velocity = Vector2.ZERO
		_state = State.HOVER

func _draw() -> void:
	if not show_hitbox:
		return
	var bounds := Rect2(-10.0, -20.0, 20.0, 40.0)
	draw_rect(bounds, Color(0.2, 0.5, 1.0, 0.25))
	draw_rect(bounds, Color(0.2, 0.5, 1.0, 1.0), false, 2.0)
