extends EnemyBase
class_name EnemyVoltGuard

# Sentinela de patrulha — o "grunt" elétrico (molde do EnemyMagmaGrunt).
const IDLE_FRAMES := 4
const IDLE_FPS := 6.0

func _init() -> void:
	max_hp = 12
	contact_damage = 8

func _ready() -> void:
	max_hp = 12
	contact_damage = 8
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_advance_sprite_frame_loop(delta, IDLE_FRAMES, IDLE_FPS)
