extends Area2D
class_name PlayerThunderBolt

# Habilidade "Thunder Bolt" do Zael, desbloqueada ao derrotar o Voltrix.
# Reusa as sprites do próprio VoltrixThunderOrb (9 frames individuais
# fx_thunder_orb_f00..f08.png — sem spritesheet, mesmo pattern do boss),
# agora atirado em linha reta pelo player.
#
# Comportamento: orb crepita em loop enquanto voa; ao acertar inimigo ou
# parede, dá dano no primeiro impacto e queue_free.

const _FRAMES := 9
const _FPS := 14.0

var _frame_textures: Array[Texture2D] = []

var dir: float = 1.0
var speed: float = 460.0
var damage: int = 3
var source_id: String = "zael_thunder_bolt"
var _lifetime: float = 3.0
var _hit: bool = false
var _anim_frame: int = 0
var _anim_timer: float = 0.0

var _sprite: Sprite2D
var _collision: CollisionShape2D

func _ready() -> void:
	collision_layer = 8  # projéteis do player
	collision_mask = 5   # enemy (4) + world (1)
	_collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	_collision.shape = shape
	add_child(_collision)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	body_entered.connect(_on_body_entered)
	for i in _FRAMES:
		_frame_textures.append(load("res://characters/bosses/voltrix_fx/fx_thunder_orb_f%02d.png" % i))
	_sprite.texture = _frame_textures[0]

func _physics_process(delta: float) -> void:
	if _hit:
		return
	global_position.x += dir * speed * delta
	_anim_timer += delta
	if _anim_timer >= 1.0 / _FPS:
		_anim_timer -= 1.0 / _FPS
		_anim_frame = (_anim_frame + 1) % _FRAMES
		_sprite.texture = _frame_textures[_anim_frame]
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
