extends Area2D
class_name PlayerSolarCorona

# Habilidade "Solar Corona" do Zael, desbloqueada ao derrotar o Luxar. Mesma
# arte da orb do próprio boss (`luxar_solar_orb*.png`), agora atirada em linha
# reta pelo player. Ciclo de estados idêntico ao LuxarSolarOrb:
#   FLY     -> orb voando em pulso, hits inimigo/parede -> EXPLODE
#   EXPLODE -> burst radial (9f, sem dano extra — já bateu no impacto)
#   FADE    -> dissipa (7f) -> queue_free.

const TEX_FLY     := preload("res://characters/bosses/luxar/luxar_solar_orb.png")
const TEX_EXPLODE := preload("res://characters/bosses/luxar/luxar_solar_orb_explode.png")
const TEX_FADE    := preload("res://characters/bosses/luxar/luxar_solar_orb_fade.png")

const _FLY_FRAMES     := 7
const _EXPLODE_FRAMES := 9
const _FADE_FRAMES    := 7
const _FLY_FPS        := 12.0
const _EXPLODE_FPS    := 18.0
const _FADE_FPS       := 14.0

enum State { FLY, EXPLODE, FADE }

var dir: float = 1.0
var speed: float = 460.0
var damage: int = 3
var source_id: String = "zael_solar_corona"

var _state: State = State.FLY
var _lifetime: float = 3.0
var _anim_frame: int = 0
var _anim_timer: float = 0.0

var _sprite: Sprite2D
var _collision: CollisionShape2D

func _ready() -> void:
	collision_layer = 8  # projéteis do player
	collision_mask = 5   # enemy (4) + world (1)
	_collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	_collision.shape = shape
	add_child(_collision)
	_sprite = Sprite2D.new()
	_sprite.scale = Vector2(0.75, 0.75)
	add_child(_sprite)
	body_entered.connect(_on_body_entered)
	_sprite.texture = TEX_FLY
	_sprite.hframes = _FLY_FRAMES
	_sprite.frame = 0

func _physics_process(delta: float) -> void:
	match _state:
		State.FLY:
			global_position.x += dir * speed * delta
			_advance_anim(delta, _FLY_FRAMES, _FLY_FPS, true)
			_lifetime -= delta
			if _lifetime <= 0.0:
				_enter_explode()
		State.EXPLODE:
			_advance_anim(delta, _EXPLODE_FRAMES, _EXPLODE_FPS, false)
			if _anim_frame >= _EXPLODE_FRAMES - 1:
				_enter_fade()
		State.FADE:
			_advance_anim(delta, _FADE_FRAMES, _FADE_FPS, false)
			if _anim_frame >= _FADE_FRAMES - 1:
				queue_free()

func _advance_anim(delta: float, frames: int, fps: float, loop: bool) -> void:
	_anim_timer += delta
	if _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		if loop:
			_anim_frame = (_anim_frame + 1) % frames
		else:
			_anim_frame = mini(_anim_frame + 1, frames - 1)
		_sprite.frame = _anim_frame

func _on_body_entered(body: Node) -> void:
	if _state != State.FLY:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	_enter_explode()

func _enter_explode() -> void:
	if _state != State.FLY:
		return
	_state = State.EXPLODE
	_anim_frame = 0
	_anim_timer = 0.0
	_sprite.texture = TEX_EXPLODE
	_sprite.hframes = _EXPLODE_FRAMES
	_sprite.frame = 0
	_collision.set_deferred("disabled", true)

func _enter_fade() -> void:
	_state = State.FADE
	_anim_frame = 0
	_anim_timer = 0.0
	_sprite.texture = TEX_FADE
	_sprite.hframes = _FADE_FRAMES
	_sprite.frame = 0
