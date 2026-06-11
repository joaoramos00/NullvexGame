extends EnemyBase
class_name EnemyIceGrunt

const RUN_FRAMES := 6
const RUN_FPS := 10.0

func _init() -> void:
	max_hp = 10
	contact_damage = 8

func _ready() -> void:
	max_hp = 10
	contact_damage = 8
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_advance_sprite_frame_loop(delta, RUN_FRAMES, RUN_FPS)
