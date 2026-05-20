extends Node2D

var color: Color = Color.ORANGE_RED
var _time: float = 0.0
const DURATION := 0.35

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= DURATION:
		queue_free()

func _draw() -> void:
	var pct: float = _time / DURATION
	var alpha: float = 1.0 - pct
	var radius: float = 14.0 + pct * 36.0
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, alpha * 0.8))
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1.0, 1.0, 0.9, alpha * 0.6))
