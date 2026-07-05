extends EnemyBase
class_name EnemyGravWell

# Poço gravitacional vivo: estacionário; enquanto viver, SUGA o player que
# entrar na aura (apply_stage_wind radial). Matar o poço desliga a sucção.
const FRAMES := 4
const FPS := 6.0
const AURA_RADIUS := 260.0
const PULL := 240.0

var _aura: Area2D = null
var _pulled: Array[Node] = []

func _init() -> void:
	max_hp = 14
	contact_damage = 10

func _ready() -> void:
	max_hp = 14
	contact_damage = 10
	super._ready()
	_aura = Area2D.new()
	_aura.collision_layer = 0
	_aura.collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = AURA_RADIUS
	cs.shape = sh
	_aura.add_child(cs)
	add_child(_aura)
	_aura.body_entered.connect(func(b: Node) -> void:
		if not _pulled.has(b):
			_pulled.append(b))
	_aura.body_exited.connect(func(b: Node) -> void:
		_pulled.erase(b))

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = 0.0
	move_and_slide()
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	if DebugBoot.bot_enabled:
		return
	for b in _pulled:
		if is_instance_valid(b) and b.has_method("apply_stage_wind"):
			var dir: Vector2 = global_position - (b as Node2D).global_position
			if dir.length() > 12.0:
				b.apply_stage_wind(dir.normalized() * PULL * delta)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
