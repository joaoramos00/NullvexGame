extends EnemyBase
class_name EnemySingularityTurret

# Torre de arco (molde do EnemyMagmaTurret): não vira; atira arc_bolt quando o
# player entra na janela do lado configurado.
const _PROJ := preload("res://characters/enemies/stage_04/grav_projectile.tscn")
const FRAMES := 4
const FPS := 8.0
const SHOOT_RANGE := 560.0
const AIM_Y := 120.0
const SHOOT_INTERVAL := 1.5
const BOLT_SPEED := 340.0
const BOLT_DAMAGE := 8

@export var face_dir: float = -1.0

var _shoot_timer := 0.4

func _init() -> void:
	max_hp = 18
	contact_damage = 9

func _ready() -> void:
	max_hp = 18
	contact_damage = 9
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
	var proj = _PROJ.instantiate()
	proj.setup(Vector2(_direction * BOLT_SPEED, 0.0), BOLT_DAMAGE, "singularity_turret")
	get_parent().add_child(proj)
	var ov := HitboxData.proj_offset(_hitbox_id(), _direction)
	var off := ov if ov != Vector2.INF else Vector2(_direction * 38.0, -5.0)
	proj.global_position = global_position + off

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
