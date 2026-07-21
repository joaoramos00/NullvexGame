extends Area2D
class_name PlayerStoneShard

# Habilidade "Stone Shard" do Zael, desbloqueada ao derrotar o Terragor —
# reaproveita a arte do fragmento de pedra do StoneShatter do próprio boss
# (fx_rock_fragment_idle/shatter), atirado reto na direção que o Zael está
# de frente. source_id = "terragor" pra bater a checagem de fraqueza em
# boss_base.gd (Voltrix é fraco a essa habilidade). Gira tombando em voo
# (código); ao bater em algo que não seja o alvo, estilhaça no lugar.
const TEX_IDLE := preload("res://characters/bosses/terragor/fx_rock_fragment_idle.png")
const TEX_SHATTER := preload("res://characters/bosses/terragor/fx_rock_fragment_shatter.png")
const _SHATTER_FRAMES := 9
const _SHATTER_FPS := 20.0
const _SPIN_SPEED := 12.0   # rad/s em voo
const _SPEED := 440.0
const _LIFETIME := 2.0

var dir: float = 1.0
var damage: int = 8
var source_id: String = "terragor"
var _lifetime := _LIFETIME
var _hit := false
var _shattering := false
var _shatter_frame := 0
var _shatter_anim_timer := 0.0

var _sprite: Sprite2D

func _ready() -> void:
	collision_layer = 8   # projéteis do player
	collision_mask = 5    # enemy (4) + world (1) — estilhaça na parede também
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	cs.shape = shape
	add_child(cs)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	body_entered.connect(_on_body_entered)
	_sprite.texture = TEX_IDLE
	_sprite.hframes = 1

func _physics_process(delta: float) -> void:
	if _shattering:
		_shatter_anim_timer += delta
		if _shatter_anim_timer >= 1.0 / _SHATTER_FPS:
			_shatter_anim_timer -= 1.0 / _SHATTER_FPS
			_shatter_frame += 1
			if _shatter_frame >= _SHATTER_FRAMES:
				queue_free()
				return
			_sprite.frame = _shatter_frame
		return
	if _hit:
		return
	global_position.x += dir * _SPEED * delta
	_sprite.rotation += _SPIN_SPEED * dir * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
		queue_free()
		return
	# Bateu em terreno (sem take_damage): estilhaça em vez de simplesmente sumir.
	_shattering = true
	_shatter_frame = 0
	_shatter_anim_timer = 0.0
	_sprite.texture = TEX_SHATTER
	_sprite.hframes = _SHATTER_FRAMES
	_sprite.frame = 0
	_sprite.rotation = 0.0
