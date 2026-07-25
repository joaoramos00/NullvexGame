extends EnemyBase
class_name EnemyCrushPylon

# Pilar de esmagamento: estacionário; arremessa DOIS mass_pulse em arco (um pra
# cada lado) que sobem e caem com gravidade — nega a área em volta dele.
const _PROJ := preload("res://characters/enemies/stage_04/grav_projectile.tscn")
const FRAMES := 4
const FPS := 7.0
const RANGE := 540.0
const INTERVAL := 2.4
const LOB_VX := 130.0
const LOB_VY := -430.0
const LOB_GRAVITY := 620.0
const LOB_DAMAGE := 9

var _shoot_timer := 1.0

func _init() -> void:
	max_hp = 5
	contact_damage = 2

func _ready() -> void:
	max_hp = 5
	contact_damage = 2
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
		_lob(1.0)
		_lob(-1.0)

func _lob(dir: float) -> void:
	var proj = _PROJ.instantiate()
	proj.setup(Vector2(dir * LOB_VX, LOB_VY), LOB_DAMAGE, "crush_pylon", LOB_GRAVITY, "mass_pulse")
	get_parent().add_child(proj)
	var ov := HitboxData.proj_offset(_hitbox_id(), dir)
	var off := ov if ov != Vector2.INF else Vector2(dir * 20.0, -40.0)
	proj.global_position = global_position + off

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
