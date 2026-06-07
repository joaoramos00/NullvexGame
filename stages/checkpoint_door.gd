# stages/checkpoint_door.gd
class_name CheckpointDoor
extends StaticBody2D

signal door_opening
signal door_opened
signal door_closed

@export var open_offset: float = -128.0
@export var tween_duration: float = 0.35
## 0 = abre de qualquer lado (padrão). -1 = só abre quando o corpo está à ESQUERDA
## da porta (entra indo p/ a direita). +1 = só da direita. Corredores left→right usam -1
## p/ a porta não reabrir/ser atravessada pelo lado de saída (bug parede transpassável).
@export var open_from_side: int = 0

@onready var _sprite: ColorRect = $ColorRect
@onready var _collider: CollisionShape2D = $CollisionShape2D
@onready var _trigger: Area2D = $TriggerArea

var _is_open := false
var anim_offset: float = 0.0

func _ready() -> void:
	assert(_sprite != null, "CheckpointDoor: ColorRect child missing")
	assert(_collider != null, "CheckpointDoor: CollisionShape2D child missing")
	assert(_trigger != null, "CheckpointDoor: TriggerArea child missing")
	_trigger.body_entered.connect(_on_body_entered)

func open() -> void:
	if _is_open:
		return
	_is_open = true
	door_opening.emit()
	var tween := create_tween()
	tween.tween_property(self, "anim_offset", open_offset, tween_duration)
	await tween.finished
	_collider.disabled = true
	door_opened.emit()

func close() -> void:
	if not _is_open:
		return
	_collider.disabled = false
	_is_open = false
	var tween := create_tween()
	tween.tween_property(self, "anim_offset", 0.0, tween_duration)
	await tween.finished
	door_closed.emit()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	# Guarda direcional: não abrir quando o player chega pelo lado "errado".
	if open_from_side < 0 and body.global_position.x > global_position.x:
		return
	if open_from_side > 0 and body.global_position.x < global_position.x:
		return
	open()
