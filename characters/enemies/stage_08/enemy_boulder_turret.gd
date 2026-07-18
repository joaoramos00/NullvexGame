extends EnemyBase
class_name EnemyBoulderTurret

# Canhão de pedra fixo: não vira; atira stone_shot quando o player entra na
# janela do lado configurado (face_dir).
const _PROJ := preload("res://characters/enemies/stage_08/stone_bolt.tscn")
const FRAMES := 4
const FPS := 8.0
const SHOOT_RANGE := 520.0
const AIM_Y := 110.0
const SHOOT_INTERVAL := 1.4
const BOLT_SPEED := 300.0
const BOLT_DAMAGE := 7

@export var face_dir: float = -1.0

var _shoot_timer := 0.4

func _init() -> void:
	max_hp = 12
	contact_damage = 0

func _ready() -> void:
	max_hp = 12
	contact_damage = 0
	super._ready()
	_direction = face_dir
	_sprite.flip_h = _direction < 0.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	move_and_slide()
	_shoot_timer -= delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null and _shoot_timer <= 0.0:
		var off: Vector2 = p.global_position - global_position
		if absf(off.y) <= AIM_Y and absf(off.x) <= SHOOT_RANGE and signf(off.x) == _direction:
			_shoot_timer = SHOOT_INTERVAL
			_fire()
	_sprite.modulate.a = 0.35 if (_invincible and int(Time.get_ticks_msec() / 80) % 2 == 0) else 1.0
	_advance_sprite_frame_loop(delta, FRAMES, FPS)

func _fire() -> void:
	var proj := _PROJ.instantiate() as StoneBolt
	proj.setup(Vector2(_direction * BOLT_SPEED, 0.0), BOLT_DAMAGE, "boulder_turret", 0.0, "stone_shot")
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(_direction * 36.0, -6.0)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
