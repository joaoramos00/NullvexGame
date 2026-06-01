# stages/stage_01/lava_floor.gd
extends Area2D

@export var damage_per_second: float = 40.0

var _bodies_inside: Array[Node] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		_bodies_inside.append(body)

func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)

func _physics_process(delta: float) -> void:
	for body in _bodies_inside:
		if is_instance_valid(body):
			(body as CharacterBase).take_damage(int(damage_per_second * delta))
