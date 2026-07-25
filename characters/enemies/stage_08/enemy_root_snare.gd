extends EnemyBase
class_name EnemyRootSnare

# Raiz-armadilha fixa: enquanto viva, PRENDE (root_bind) o player que entrar
# na aura de curto alcance e aplica dano periódico enquanto ele permanecer
# perto. Matar a raiz desliga a armadilha. Sem projétil próprio.
const FRAMES := 9
const FPS := 6.0
const AURA_RADIUS := 90.0
const AURA_DAMAGE := 4
const AURA_TICK := 0.5

var _aura: Area2D = null
var _snared: Array[Node] = []
var _tick_timer := 0.0

func _init() -> void:
	max_hp = 4
	contact_damage = 2

func _ready() -> void:
	max_hp = 4
	contact_damage = 2
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
		if not _snared.has(b):
			_snared.append(b))
	_aura.body_exited.connect(func(b: Node) -> void:
		_snared.erase(b))

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
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = AURA_TICK
		for b in _snared:
			if is_instance_valid(b) and b.has_method("take_damage"):
				b.take_damage(AURA_DAMAGE, "root_snare")

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
