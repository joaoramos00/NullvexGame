extends Node
# Adiciona bindings de CONTROLE (gamepad) às ações do jogo em runtime.
# O input map do projeto só define teclado; isto mapeia o controle por cima,
# sem mexer no formato frágil do project.godot. Layout estilo Xbox:
#   A = pular | X = atirar/atacar | B = dash | Y = special
#   LB/RB = trocar habilidade | Start = pause
#   D-pad ←/→ e analógico esquerdo = mover

func _ready() -> void:
	_btn("jump",         JOY_BUTTON_A)
	_btn("attack",       JOY_BUTTON_X)
	_btn("dash",         JOY_BUTTON_B)
	_btn("special",      JOY_BUTTON_Y)
	_btn("ability_prev", JOY_BUTTON_LEFT_SHOULDER)
	_btn("ability_next", JOY_BUTTON_RIGHT_SHOULDER)
	_btn("pause",        JOY_BUTTON_START)
	# Movimento: D-pad + analógico esquerdo (eixo X)
	_btn("move_left",  JOY_BUTTON_DPAD_LEFT)
	_btn("move_right", JOY_BUTTON_DPAD_RIGHT)
	_axis("move_left",  JOY_AXIS_LEFT_X, -1.0)
	_axis("move_right", JOY_AXIS_LEFT_X,  1.0)

func _btn(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)

func _axis(action: String, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)
