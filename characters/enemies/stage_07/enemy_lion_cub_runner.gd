extends EnemyBase
class_name EnemyLionCubRunner

# Cria robótica veloz: patrulha normal; ao ver o player no mesmo nível,
# dispara uma arrancada rápida até bater em parede ou esgotar o tempo.
const FRAMES := 9
const FPS := 11.0
const DETECT_X := 300.0
const DETECT_Y := 60.0
const DASH_SPEED := 230.0
const DASH_TIME := 0.65
const DASH_COOLDOWN := 1.3

var _dash_timer := 0.0
var _cooldown := 0.5

func _init() -> void:
	max_hp = 8
	contact_damage = 6

func _ready() -> void:
	max_hp = 8
	contact_damage = 6
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _dash_timer > 0.0:
		_dash_timer -= delta
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = DASH_SPEED * _direction
		move_and_slide()
		if is_on_wall():
			_dash_timer = 0.0
		if _dash_timer <= 0.0:
			_cooldown = DASH_COOLDOWN
		_advance_sprite_frame_loop(delta, FRAMES, FPS * 1.5)
		_sprite.flip_h = (_direction < 0)
		return
	super._physics_process(delta)
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null:
		var off: Vector2 = p.global_position - global_position
		if absf(off.x) <= DETECT_X and absf(off.y) <= DETECT_Y:
			_direction = signf(off.x)
			_dash_timer = DASH_TIME
