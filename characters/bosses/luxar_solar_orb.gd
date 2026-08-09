extends Area2D
class_name LuxarSolarOrb

# Projétil do attack_beam do Luxar. Ciclo:
#   FLY   -> orb voando, loopa a anim de pulsação (7 frames).
#   EXPLODE -> spawnou ao acertar o player ou expirar o lifetime; toca a
#              anim de burst (9 frames) uma vez, sem se mover.
#   FADE  -> após o explode, dissipa até sumir (7 frames), então queue_free.
# Sprites gerados via PixelLab (mesmo object 23e27056-...) e stitched em
# spritesheets horizontais via tools/stitch_frames.ps1.

const _TEX_FLY := preload("res://characters/bosses/luxar/luxar_solar_orb.png")
const _TEX_EXPLODE := preload("res://characters/bosses/luxar/luxar_solar_orb_explode.png")
const _TEX_FADE := preload("res://characters/bosses/luxar/luxar_solar_orb_fade.png")

const _FLY_FRAMES := 7
const _EXPLODE_FRAMES := 9
const _FADE_FRAMES := 7
const _FLY_FPS := 12.0
const _EXPLODE_FPS := 18.0
const _FADE_FPS := 14.0

enum State { FLY, EXPLODE, FADE }

var projectile_velocity: Vector2 = Vector2(500.0, 0.0)
var damage: int = 6
var source_id: String = "luxar"
var _lifetime: float = 3.0
var _state: State = State.FLY
var _anim_frame: int = 0
var _anim_timer: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)
	_sprite.texture = _TEX_FLY
	_sprite.hframes = _FLY_FRAMES
	_sprite.frame = 0

func _physics_process(delta: float) -> void:
	match _state:
		State.FLY:
			global_position += projectile_velocity * delta
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
	_sprite.texture = _TEX_EXPLODE
	_sprite.hframes = _EXPLODE_FRAMES
	_sprite.frame = 0
	# Desativa colisão pra não bater múltiplas vezes durante a explosão.
	_collision.set_deferred("disabled", true)
	projectile_velocity = Vector2.ZERO

func _enter_fade() -> void:
	_state = State.FADE
	_anim_frame = 0
	_anim_timer = 0.0
	_sprite.texture = _TEX_FADE
	_sprite.hframes = _FADE_FRAMES
	_sprite.frame = 0
