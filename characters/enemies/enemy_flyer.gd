extends EnemyBase

@export var patrol_range: float = 150.0

var _start_x: float = 0.0

func _ready() -> void:
	super._ready()
	_start_x = global_position.x

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
	velocity.x = PATROL_SPEED * _direction
	velocity.y = 0.0
	move_and_slide()
	if abs(global_position.x - _start_x) >= patrol_range:
		_direction = -_direction

func _draw() -> void:
	draw_rect(Rect2(-14, -22, 28, 44), Color(0.2, 0.4, 0.9))
