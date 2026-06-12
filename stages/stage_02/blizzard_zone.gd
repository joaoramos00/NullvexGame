extends Area2D

@export var force: Vector2 = Vector2(180.0, 0.0)

var _bodies_inside: Array[Node] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if not _bodies_inside.has(body):
		_bodies_inside.append(body)

func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)

func _physics_process(delta: float) -> void:
	for body in _bodies_inside:
		if is_instance_valid(body) and body.has_method("apply_stage_wind"):
			body.apply_stage_wind(force * delta)
