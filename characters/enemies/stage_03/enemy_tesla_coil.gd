extends EnemyBase
class_name EnemyTeslaCoil

# Bobina de tesla: fica parada e descarrega DOIS arcos horizontais (esquerda e
# direita ao mesmo tempo) quando o player está no alcance.
const _PROJ := preload("res://characters/enemies/stage_03/arc_projectile.tscn")
const FRAMES := 4
const FPS := 8.0
const RANGE := 520.0
const INTERVAL := 2.2
const BOLT_SPEED := 300.0
const BOLT_DAMAGE := 8

var _shoot_timer := 0.8

func _init() -> void:
	max_hp = 16
	contact_damage = 9

func _ready() -> void:
	max_hp = 16
	contact_damage = 9
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	move_and_slide()
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	_shoot_timer -= delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null and _shoot_timer <= 0.0 \
			and global_position.distance_to(p.global_position) <= RANGE:
		_shoot_timer = INTERVAL
		_fire(1.0)
		_fire(-1.0)

func _fire(dir: float) -> void:
	var proj = _PROJ.instantiate()
	proj.setup(Vector2(dir * BOLT_SPEED, 0.0), BOLT_DAMAGE, "tesla_coil")
	get_parent().add_child(proj)
	var ov := HitboxData.proj_offset(_hitbox_id(), dir)
	var off := ov if ov != Vector2.INF else Vector2(dir * 34.0, -18.0)
	proj.global_position = global_position + off

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
