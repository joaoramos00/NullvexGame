# effects/shockwave_effect.gd
extends Area2D

@export var damage: int = 3

var _alpha: float = 1.0

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 2
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(0.4).timeout.connect(queue_free)

func _process(delta: float) -> void:
	_alpha = max(0.0, _alpha - delta * 2.5)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-150.0, -24.0, 300.0, 48.0), Color(1.0, 0.6, 0.0, _alpha * 0.4))

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
