# stages/checkpoint_door.gd
class_name CheckpointDoor
extends StaticBody2D

signal door_opened
signal door_closed

@export var open_offset: float = -128.0
@export var tween_duration: float = 0.35

@onready var _sprite: ColorRect = $ColorRect
@onready var _collider: CollisionShape2D = $CollisionShape2D
@onready var _trigger: Area2D = $TriggerArea

var _is_open := false

func _ready() -> void:
	_trigger.body_entered.connect(_on_body_entered)

func open() -> void:
	if _is_open:
		return
	_is_open = true
	_collider.disabled = true
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", open_offset, tween_duration)
	door_opened.emit()

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", 0.0, tween_duration)
	tween.tween_callback(func() -> void:
		_collider.disabled = false
	)
	door_closed.emit()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		open()
