extends EnemyBase
class_name EnemyDrillMole

# Toupeira perfuradora: bash/investida curta e rápida quando o player está perto.
const FRAMES := 9
const FPS := 9.0
const DETECT_X := 160.0
const DETECT_Y := 50.0
const LUNGE_SPEED := 260.0
const LUNGE_TIME := 0.32
const LUNGE_COOLDOWN := 1.2

var _lunge_timer := 0.0
var _cooldown := 0.4

func _init() -> void:
	max_hp = 10
	contact_damage = 8

func _ready() -> void:
	max_hp = 10
	contact_damage = 8
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _lunge_timer > 0.0:
		_lunge_timer -= delta
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = LUNGE_SPEED * _direction
		move_and_slide()
		if is_on_wall():
			_lunge_timer = 0.0
		if _lunge_timer <= 0.0:
			_cooldown = LUNGE_COOLDOWN
		_advance_sprite_frame_loop(delta, FRAMES, FPS * 1.8)
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
			_lunge_timer = LUNGE_TIME
