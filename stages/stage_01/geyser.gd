extends Area2D

@export var active_time:   float = 2.5
@export var inactive_time: float = 1.5
@export var damage:        int   = 20

var _active: bool = false
var _timer:  float = 0.0
var _bodies_inside: Array[Node] = []

func _ready() -> void:
	monitoring = false
	_timer = inactive_time
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_active = !_active
		monitoring = _active
		_timer = active_time if _active else inactive_time
		if not _active:
			_bodies_inside.clear()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		_bodies_inside.append(body)

func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)

func _physics_process(_delta: float) -> void:
	if not _active:
		return
	for body in _bodies_inside:
		if is_instance_valid(body):
			(body as CharacterBase).take_damage(damage)
