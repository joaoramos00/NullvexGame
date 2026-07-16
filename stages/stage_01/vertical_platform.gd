extends AnimatableBody2D

@export var move_distance: float = 256.0
@export var speed: float = 70.0
@export var start_going_up: bool = false
@export var up_only: bool = false   # elevador: parte da base (start) e sobe move_distance, só pra cima
@export var trigger_on_step: bool = false   # fica parada até o player pisar em cima, então sobe uma vez só (implica up_only)
@export var tex: Texture2D = null   # visual do topo em modo tile (fallback) — ignorado se anim_tex for setada
@export var plat_size: Vector2 = Vector2(64.0, 32.0)
@export var anim_tex: Texture2D = null    # sprite sheet animada (N frames de anim_frame_size lado a lado) — tem prioridade sobre tex
@export var anim_frames: int = 9
@export var anim_frame_size: float = 64.0
@export var anim_fps: float = 10.0

const _TS  := 64.0
const _STS := 32.0

var _dir: float = 1.0
var _traveled: float = 0.0
var _triggered: bool = false
var _finished: bool = false

func _ready() -> void:
	sync_to_physics = true
	_dir = -1.0 if (start_going_up or up_only) else 1.0
	_triggered = not trigger_on_step
	if anim_tex != null:
		var sf := SpriteFrames.new()
		sf.add_animation("idle")
		sf.set_animation_loop("idle", true)
		sf.set_animation_speed("idle", anim_fps)
		for i in anim_frames:
			var at := AtlasTexture.new()
			at.atlas = anim_tex
			at.region = Rect2(i * anim_frame_size, 0.0, anim_frame_size, anim_frame_size)
			sf.add_frame("idle", at)
		# UM sprite só, esticado horizontalmente pra cobrir plat_size.x inteiro
		# (a arte gerada é um quadrado anim_frame_size) — sem repetir ladrilho.
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = sf
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(plat_size.x / anim_frame_size, 1.0)
		add_child(sprite)
		sprite.play("idle")
	else:
		queue_redraw()
	if trigger_on_step:
		var trig := Area2D.new()
		trig.collision_layer = 0
		trig.collision_mask = 2   # player layer
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(plat_size.x, 8.0)
		cs.position = Vector2(0.0, -plat_size.y * 0.5 - 4.0)   # linha rente ao topo da plataforma
		cs.shape = shape
		trig.add_child(cs)
		trig.body_entered.connect(_on_trigger_entered)
		add_child(trig)

func _on_trigger_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_triggered = true

func _draw() -> void:
	if tex == null:
		return
	var cols := ceili(plat_size.x / _TS)
	var left := -plat_size.x * 0.5
	for col in cols:
		var dx := left + col * _TS
		var dw := minf(_TS, left + plat_size.x - dx)
		draw_texture_rect_region(tex, Rect2(dx, -plat_size.y * 0.5, dw, plat_size.y),
			Rect2(3.0 * _STS, 0.0, _STS * dw / _TS, _STS))

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return   # debug do bot: plataformas paradas (valida o layout, não o timing)
	if not _triggered or _finished:
		return
	var step := _dir * speed * delta
	_traveled += step
	if up_only:
		# sobe do start (base, 0) até o topo (-move_distance) e PARA — não volta
		# (elevador de segredo: uma viagem só, disparada ao pisar em cima).
		if _traveled <= -move_distance:
			_traveled = -move_distance
			_finished = true
	elif _traveled >= move_distance * 0.5:
		_traveled = move_distance * 0.5
		_dir = -1.0
	elif _traveled <= -move_distance * 0.5:
		_traveled = -move_distance * 0.5
		_dir = 1.0
	# AnimatableBody2D com sync_to_physics carrega o player ao mover via
	# position; move_and_collide é proibido nesse modo (gera erro e não carrega).
	position.y += step
