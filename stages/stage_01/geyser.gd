extends Area2D

const _LAVA_SHADER := preload("res://stages/stage_01/lava_flow.gdshader")

@export var active_time:   float = 2.5
@export var inactive_time: float = 1.5
@export var damage:        int   = 20
@export var start_delay:   float = 0.0   # atrasa o 1º disparo → encadeia gêiseres em sequência

var _active: bool = false
var _timer:  float = 0.0
var _bodies_inside: Array[Node] = []
var _fire: Sprite2D = null   # coluna de lava (jato) visível só quando ativo

func _ready() -> void:
	monitoring = false
	_timer = inactive_time + start_delay
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_fire_visual()

# Sem isto o gêiser dava dano INVISÍVEL: era só Area2D, sem sprite. Desenha um jato de
# lava (lava_fill + shader de fluxo) do tamanho da área, mostrado só na fase ativa.
func _build_fire_visual() -> void:
	var cs: CollisionShape2D = null
	for c in get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			cs = c
			break
	if cs == null:
		return
	var size: Vector2 = (cs.shape as RectangleShape2D).size
	var tex: Texture2D = load("res://stages/stage_01/lava_fill.png")
	if tex == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = _LAVA_SHADER
	_fire = Sprite2D.new()
	_fire.texture = tex
	_fire.centered = false
	_fire.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_fire.region_enabled = true
	_fire.region_rect = Rect2(0, 0, size.x * 0.5, size.y * 0.5)   # *0.5 → scale 2
	_fire.scale = Vector2(2, 2)
	_fire.position = -size * 0.5                                   # canto sup-esq (node no centro)
	_fire.z_index = 1
	_fire.material = mat
	_fire.visible = false
	add_child(_fire)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_active = !_active
		monitoring = _active
		_timer = active_time if _active else inactive_time
		if _fire:
			_fire.visible = _active   # jato aparece exatamente quando o gêiser dá dano
		if not _active:
			_bodies_inside.clear()

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		_bodies_inside.append(body)

func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)

func _physics_process(_delta: float) -> void:
	if not _active:
		return
	for body in _bodies_inside:
		if is_instance_valid(body):
			(body as CharacterBase).take_damage(damage)
