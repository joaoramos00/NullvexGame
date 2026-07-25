extends Area2D
class_name QuakeWave

# Onda de choque horizontal do Terragor (fase 2): nasce na posição do boss e
# se desloca pro lado indicado (uma instância por direção — a fase 2 spawna
# 2, uma pra cada lado) até percorrer max_distance, então some. Dano por
# contato (uma vez por corpo, via _hit_bodies).
#
# quake_wave.png é uma folha 2x2 (4 frames de 128x128, mesma convenção de
# stone_bolt.tscn) — precisa hframes/vframes, não é uma textura estática.

const TEX := preload("res://characters/enemies/stage_08/quake_wave.png")
const _FRAMES := 4
const _ANIM_FPS := 10.0

@export var direction: float = 1.0
@export var speed: float = 260.0
@export var damage: int = 3
@export var max_distance: float = 900.0

var source_id: String = "terragor"

var _origin_x: float = 0.0
var _hit_bodies: Dictionary = {}
var _anim_timer: float = 0.0
var _frame: int = 0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_origin_x = global_position.x
	body_entered.connect(_on_body_entered)
	if _sprite != null:
		_sprite.texture = TEX
		_sprite.hframes = 2
		_sprite.vframes = 2
		_sprite.frame = 0
		_sprite.flip_h = direction < 0.0

func _physics_process(delta: float) -> void:
	global_position.x += direction * speed * delta
	_anim_timer += delta
	if _anim_timer >= 1.0 / _ANIM_FPS:
		_anim_timer -= 1.0 / _ANIM_FPS
		_frame = (_frame + 1) % _FRAMES
		if _sprite != null:
			_sprite.frame = _frame
	if absf(global_position.x - _origin_x) >= max_distance:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit_bodies.has(body):
		return
	if body.has_method("take_damage"):
		_hit_bodies[body] = true
		body.take_damage(damage, source_id)
