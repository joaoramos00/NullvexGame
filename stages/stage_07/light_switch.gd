# Interruptor de toggle PERMANENTE (sem timer, ao contrário de
# phase_platform.gd) — ao ser tocado pelo player uma vez, aplica
# target_active_value no nó apontado por target_path e nunca mais reage.
# Funciona com dois tipos de alvo:
#   - um nó com método set_active(bool) (ex: light_beam.gd) — chama direto.
#   - um StaticBody2D "portão" sem set_active — alterna a CollisionShape2D
#     filha (disabled) e a meta skip_base_draw diretamente, mesma técnica
#     de stages/stage_01/crumbling_ledge.gd.
extends Area2D
class_name LightSwitch

@export var target_path: NodePath
@export var target_active_value: bool = true

var _triggered: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered or DebugBoot.bot_enabled:
		return
	if not body.is_in_group("player"):
		return
	_triggered = true
	_apply()

func _apply() -> void:
	var target := get_node_or_null(target_path)
	if target == null:
		return
	if target.has_method("set_active"):
		target.call("set_active", target_active_value)
		return
	var cs: CollisionShape2D = null
	for c in target.get_children():
		if c is CollisionShape2D:
			cs = c
			break
	if cs:
		cs.set_deferred("disabled", not target_active_value)
	if target_active_value:
		if target.has_meta("skip_base_draw"):
			target.remove_meta("skip_base_draw")
	else:
		target.set_meta("skip_base_draw", true)
