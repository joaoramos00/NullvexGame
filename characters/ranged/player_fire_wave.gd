extends Area2D
# Onda de fogo da habilidade Fire Walk do Zael.
# Segue o chão, sobe a parede ao colidir, e volta ao chão quando a parede acaba.
# Some após MAX_BURSTS explosões visuais.

const _TEX_GROUND_BURST := preload("res://characters/bosses/ignarath/fx_ground_burst.png")
const _BURST_FRAMES     := 9
const _BURST_FPS        := 14.0
const _BURST_SPACING    := 80.0
const MAX_BURSTS        := 3
const _WAVE_H           := 56.0
const _WAVE_W           := 90.0

var dir: float = 1.0
var speed: float = 300.0
var damage: int = 3
var source_id: String = "ignarath"

var _burst_count: int = 0
var _dist_since_burst: float = 0.0
var _vertical: bool = false
var _ray_floor: RayCast2D = null
var _ray_wall: RayCast2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4  # enemy layer
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(_WAVE_W, _WAVE_H)
	cs.shape = rect
	add_child(cs)
	body_entered.connect(_on_body_entered)

	_ray_floor = RayCast2D.new()
	_ray_floor.collision_mask = 1
	_ray_floor.target_position = Vector2(0.0, _WAVE_H * 0.5 + 64.0)
	add_child(_ray_floor)

	_ray_wall = RayCast2D.new()
	_ray_wall.collision_mask = 1
	_ray_wall.target_position = Vector2(dir * (_WAVE_W * 0.5 + 8.0), 0.0)
	add_child(_ray_wall)

	# Se já há parede à frente, iniciar direto no modo parede
	_ray_wall.force_raycast_update()
	if _ray_wall.is_colliding():
		_switch_to_wall()

	_spawn_burst()  # burst imediato (posição correta para o modo já definido)

func _physics_process(delta: float) -> void:
	var moved: float = speed * delta
	if _vertical:
		global_position.y -= moved
		# Parede acabou → volta ao chão
		if _ray_wall != null and not _ray_wall.is_colliding():
			_switch_to_floor()
	else:
		global_position.x += dir * moved
		if _ray_floor != null and _ray_floor.is_colliding():
			global_position.y = _ray_floor.get_collision_point().y - _WAVE_H * 0.5
		if _ray_wall != null and _ray_wall.is_colliding():
			_switch_to_wall()
	_dist_since_burst += moved
	if _dist_since_burst >= _BURST_SPACING:
		_dist_since_burst -= _BURST_SPACING
		_spawn_burst()

func _switch_to_wall() -> void:
	_vertical = true
	# Mantém _ray_wall para detectar quando a parede acaba
	if _ray_floor != null:
		_ray_floor.queue_free()
		_ray_floor = null

func _switch_to_floor() -> void:
	_vertical = false
	# _ray_wall só perde a parede quando o ponto de checagem (à frente, em X)
	# já está sobre o novo piso; avança X até lá para não flutuar num vão
	# entre a lateral da parede (onde a wave ficou parada subindo) e o piso novo.
	global_position.x += dir * (_WAVE_W * 0.5 + 8.0)
	# Restaura floor following
	_ray_floor = RayCast2D.new()
	_ray_floor.collision_mask = 1
	_ray_floor.target_position = Vector2(0.0, _WAVE_H * 0.5 + 64.0)
	add_child(_ray_floor)
	# _ray_wall já existe e agora detecta a próxima parede no nível do chão acima

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)

func _spawn_burst() -> void:
	_burst_count += 1
	if _burst_count > MAX_BURSTS:
		queue_free()
		return
	var sf := SpriteFrames.new()
	sf.add_animation("burst")
	sf.set_animation_loop("burst", false)
	sf.set_animation_speed("burst", _BURST_FPS)
	for i in _BURST_FRAMES:
		var at := AtlasTexture.new()
		at.atlas = _TEX_GROUND_BURST
		at.region = Rect2(i * 64.0, 0.0, 64.0, 64.0)
		sf.add_frame("burst", at)
	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = sf
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.z_index = 3
	if _vertical:
		sp.global_position = Vector2(
			global_position.x + dir * _WAVE_W * 0.5,
			global_position.y - _WAVE_H * 0.5 + 32.0)
		sp.rotation = -dir * PI * 0.5
	else:
		sp.global_position = Vector2(global_position.x, global_position.y + _WAVE_H * 0.5 - 32.0)
	sp.animation_finished.connect(sp.queue_free)
	get_parent().add_child(sp)
	sp.play("burst")
