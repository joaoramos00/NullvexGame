extends EnemyBase
class_name EnemyStaticInterceptor

# Interceptador estático: patrulha e salta em arco na direção do player em
# intervalos (molde do jumper da skill new-enemy, virado pro alvo).
const FRAMES := 4
const FPS := 7.0
const JUMP_SPEED := 520.0
const JUMP_INTERVAL := 1.8
const DETECT_RANGE := 420.0

var _jump_timer := JUMP_INTERVAL

func _init() -> void:
	max_hp = 9
	contact_damage = 8

func _ready() -> void:
	max_hp = 9
	contact_damage = 8
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	if is_dead:
		return
	_jump_timer -= delta
	if _jump_timer <= 0.0 and is_on_floor():
		_jump_timer = JUMP_INTERVAL
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p != null and global_position.distance_to(p.global_position) <= DETECT_RANGE:
			_direction = signf(p.global_position.x - global_position.x)
		velocity.y = -JUMP_SPEED
