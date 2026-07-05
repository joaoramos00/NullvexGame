# Faixa de "borda áspera": cascalho sobre o gelo que DESATIVA a derrapagem
# enquanto o player estiver dentro — usada na aproximação dos pulos sobre
# abismos mortais da Z4 (gelo + pulo no limite era injusto). Inerte no bot
# (o bot já roda sem gelo; reativar no exit ligaria gelo pra ele).
extends Area2D

func _ready() -> void:
	z_index = 5
	body_entered.connect(func(b: Node) -> void:
		if DebugBoot.bot_enabled:
			return
		if b.has_method("set_stage_ice"):
			b.set_stage_ice(false))
	body_exited.connect(func(b: Node) -> void:
		if DebugBoot.bot_enabled:
			return
		if b.has_method("set_stage_ice"):
			b.set_stage_ice(true))

func _draw() -> void:
	# tracinhos de cascalho no piso (marrom-acinzentado)
	var cs := get_child(0) as CollisionShape2D
	if cs == null or not cs.shape is RectangleShape2D:
		return
	var w: float = (cs.shape as RectangleShape2D).size.x
	var x := -w * 0.5 + 6.0
	while x < w * 0.5 - 6.0:
		draw_line(Vector2(x, 22.0), Vector2(x + 8.0, 22.0), Color(0.55, 0.48, 0.4, 0.9), 3.0)
		draw_line(Vector2(x + 4.0, 16.0), Vector2(x + 9.0, 16.0), Color(0.4, 0.36, 0.3, 0.8), 2.0)
		x += 20.0
