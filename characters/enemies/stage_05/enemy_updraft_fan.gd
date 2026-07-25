extends EnemyBase
class_name EnemyUpdraftFan

# Fã industrial fixo: enquanto vivo, empurra pra CIMA quem entrar na coluna
# vertical acima dele (apply_stage_wind). Matar o fã desliga o empuxo.
const FRAMES := 6
const FPS := 6.0
const COLUMN_WIDTH := 90.0
const COLUMN_HEIGHT := 420.0
const PUSH := 260.0

var _column: Area2D = null
var _pushed: Array[Node] = []

func _init() -> void:
	max_hp = 4
	contact_damage = 1

func _ready() -> void:
	max_hp = 4
	contact_damage = 1
	super._ready()
	_column = Area2D.new()
	_column.collision_layer = 0
	_column.collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(COLUMN_WIDTH, COLUMN_HEIGHT)
	cs.shape = sh
	cs.position = Vector2(0.0, -COLUMN_HEIGHT * 0.5)
	_column.add_child(cs)
	add_child(_column)
	_column.body_entered.connect(func(b: Node) -> void:
		if not _pushed.has(b):
			_pushed.append(b))
	_column.body_exited.connect(func(b: Node) -> void:
		_pushed.erase(b))

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	velocity = Vector2.ZERO
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	if DebugBoot.bot_enabled:
		return
	for b in _pushed:
		if is_instance_valid(b) and b.has_method("apply_stage_wind"):
			b.apply_stage_wind(Vector2(0.0, -PUSH) * delta)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
