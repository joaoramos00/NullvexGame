extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if DebugBoot.bot_enabled:
		return   # bot roda com atrito normal (o modelo de movimento dele não lida com derrapagem)
	if body.has_method("set_stage_ice"):
		body.set_stage_ice(true)

func _on_body_exited(body: Node) -> void:
	if body.has_method("set_stage_ice"):
		body.set_stage_ice(false)
