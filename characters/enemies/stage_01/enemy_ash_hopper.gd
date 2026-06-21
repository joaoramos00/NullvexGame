extends EnemyBase
class_name EnemyAshHopper

const FRAMES := 6
const FPS := 10.0
const HOP_INTERVAL := 0.9
const HOP_VY := -460.0
const HOP_VX := 150.0

# Hitbox por frame [largura, altura], em game-px. Base original = 32x60.
# Frames 1-2: -50% vertical + 10px/lado horizontal (52x30). Frame 3: 52x60.
# Frame 4: atual (32x60). Frame 5: -50% vertical (32x30). Frame 6: atual (32x60).
const _FRAME_BOX := [
	Vector2(52.0, 30.0),  # frame 1
	Vector2(52.0, 30.0),  # frame 2
	Vector2(52.0, 60.0),  # frame 3
	Vector2(32.0, 60.0),  # frame 4
	Vector2(32.0, 30.0),  # frame 5
	Vector2(32.0, 60.0),  # frame 6
]
const _FOOT_Y := 30.0   # fundo do hitbox (base/2); shapes ancorados aqui p/ os pés não tremerem

var _hop_timer := 0.6
var _body_cs: CollisionShape2D
var _contact_cs: CollisionShape2D
var _last_box_frame := -1

func _init() -> void:
	max_hp = 7
	contact_damage = 7

func _ready() -> void:
	max_hp = 7
	contact_damage = 7
	super._ready()
	_body_cs = get_node_or_null("CollisionShape2D")
	_contact_cs = get_node_or_null("ContactZone/CollisionShape2D")
	apply_frame_hitbox(0)

# Define o tamanho da hitbox (corpo + ContactZone) p/ o frame dado, ancorado pelos
# pés (fundo fixo em _FOOT_Y). Público: o imgdebug chama isto ao scrubbar frames.
func apply_frame_hitbox(frame_idx: int) -> void:
	var i: int = clampi(frame_idx, 0, _FRAME_BOX.size() - 1)
	if i == _last_box_frame:
		return
	_last_box_frame = i
	var box: Vector2 = _FRAME_BOX[i]
	var pos := Vector2(0.0, _FOOT_Y - box.y * 0.5)
	for cs in [_body_cs, _contact_cs]:
		if cs == null:
			continue
		var rect := cs.shape as RectangleShape2D
		if rect == null:
			rect = RectangleShape2D.new()
			cs.shape = rect
		rect.size = box
		cs.position = pos

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_invincibility(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor():
		if not _has_floor_ahead():
			_direction = -_direction
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			_hop_timer = HOP_INTERVAL
			velocity.y = HOP_VY
			velocity.x = HOP_VX * _direction
		else:
			velocity.x = 0.0
	move_and_slide()
	if is_on_wall():
		_direction = -_direction
	_sprite.flip_h = _direction < 0.0
	_sprite.modulate.a = 0.35 if (_invincible and int(Time.get_ticks_msec() / 80) % 2 == 0) else 1.0
	_advance_sprite_frame_loop(delta, FRAMES, FPS)
	apply_frame_hitbox(_anim_frame)

func _tick_invincibility(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
