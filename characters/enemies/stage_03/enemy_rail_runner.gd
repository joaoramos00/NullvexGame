extends EnemyBase
class_name EnemyRailRunner

# Corredor de trilho: patrulha normal; quando vê o player no mesmo nível,
# dispara uma INVESTIDA rápida até bater em parede ou esgotar o tempo.
const FRAMES := 4
const FPS := 10.0
const DETECT_X := 380.0
const DETECT_Y := 70.0
const CHARGE_SPEED := 340.0
const CHARGE_TIME := 1.1
const CHARGE_COOLDOWN := 1.6

var _charge_timer := 0.0
var _cooldown := 0.6

func _init() -> void:
	max_hp = 3
	contact_damage = 2

func _ready() -> void:
	max_hp = 3
	contact_damage = 2
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _charge_timer > 0.0:
		_charge_timer -= delta
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = CHARGE_SPEED * _direction
		move_and_slide()
		if is_on_wall():
			_charge_timer = 0.0
		if _charge_timer <= 0.0:
			_cooldown = CHARGE_COOLDOWN
		_advance_sprite_frame_loop(delta, FRAMES, FPS * 1.6)
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
			_charge_timer = CHARGE_TIME
