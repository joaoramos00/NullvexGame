# Zona de visão limitada: ao entrar, escurece a tela inteira via
# CanvasModulate e acende uma PointLight2D (textura de gradiente radial)
# grudada no player, revelando só uma área ao redor dele. Ao sair, desfaz.
# Sistema visual novo — deliberadamente simples (sem motor de iluminação
# por tile), só CanvasModulate + 1 luz pontual seguindo o player.
extends Area2D
class_name VisionLimitZone

@export var dark_color: Color = Color(0.03, 0.03, 0.08, 0.92)
@export var light_radius: float = 220.0
@export var light_energy: float = 1.4

var _canvas_mod: CanvasModulate = null
var _point_light: PointLight2D = null
var _player: Node2D = null
var _active := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if DebugBoot.bot_enabled:
		return
	if not body.is_in_group("player"):
		return
	_player = body as Node2D
	_activate()

func _on_body_exited(body: Node) -> void:
	if body == _player:
		_deactivate()
		_player = null

func _activate() -> void:
	if _active:
		return
	if not is_inside_tree() or get_tree().current_scene == null:
		return
	_active = true
	_canvas_mod = CanvasModulate.new()
	_canvas_mod.color = dark_color
	get_tree().current_scene.add_child(_canvas_mod)
	_point_light = PointLight2D.new()
	_point_light.energy = light_energy
	_point_light.texture = _radial_gradient_texture()
	_point_light.texture_scale = light_radius / 256.0
	if _player:
		_player.add_child(_point_light)

func _deactivate() -> void:
	_active = false
	if is_instance_valid(_canvas_mod):
		_canvas_mod.queue_free()
	if is_instance_valid(_point_light):
		_point_light.queue_free()
	_canvas_mod = null
	_point_light = null

func _radial_gradient_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex
