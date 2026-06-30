extends Area2D
class_name DropPickup

enum Type { HP_SMALL, HP_LARGE, EN_SMALL, EN_LARGE, ONE_UP }

const _HP_SMALL_RESTORE := 4
const _HP_LARGE_RESTORE := 16
const _LIFETIME         := 8.0
const _BLINK_AFTER      := 6.0
const _GRAVITY          := 700.0
const _BOUNCE_VY        := -180.0
const _BOB_SPEED        := 4.0
const _BOB_AMP          := 3.0
const _ANIM_FPS         := 8.0

const _TEX: Dictionary = {
	Type.HP_SMALL: preload("res://characters/pickups/pickup_health_small.png"),
	Type.HP_LARGE: preload("res://characters/pickups/pickup_health_large.png"),
	Type.EN_SMALL: preload("res://characters/pickups/pickup_energy_small.png"),
	Type.EN_LARGE: preload("res://characters/pickups/pickup_energy_large.png"),
	Type.ONE_UP:   preload("res://characters/pickups/pickup_1up.png"),
}

var drop_type: Type = Type.HP_SMALL

var _vy: float         = _BOUNCE_VY
var _land_y: float     = 0.0
var _landed: bool      = false
var _lifetime: float   = _LIFETIME
var _anim_timer: float = 0.0
var _anim_frame: int   = 0
var _bob_time: float   = 0.0
var _sprite: Sprite2D

func _ready() -> void:
	_land_y = position.y
	_sprite = Sprite2D.new()
	_sprite.texture = _TEX.get(int(drop_type))
	_sprite.hframes = 2
	_sprite.vframes = 2
	_sprite.scale = Vector2(0.25, 0.25)
	add_child(_sprite)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not _landed:
		_vy += _GRAVITY * delta
		position.y += _vy * delta
		if _vy > 0.0 and position.y >= _land_y:
			position.y = _land_y
			_landed = true
	else:
		_bob_time += delta
		position.y = _land_y + sin(_bob_time * _BOB_SPEED) * _BOB_AMP

	_anim_timer += delta
	if _anim_timer >= 1.0 / _ANIM_FPS:
		_anim_timer -= 1.0 / _ANIM_FPS
		_anim_frame = (_anim_frame + 1) % 4
		_sprite.frame = _anim_frame

	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()
		return
	if _lifetime < _LIFETIME - _BLINK_AFTER:
		_sprite.visible = int(_lifetime / 0.1) % 2 == 0

func _on_body_entered(body: Node) -> void:
	if not body.has_method("heal"):
		return
	match drop_type:
		Type.HP_SMALL: body.heal(_HP_SMALL_RESTORE)
		Type.HP_LARGE: body.heal(_HP_LARGE_RESTORE)
		Type.ONE_UP:   GameManager.add_life()
		# EN_SMALL / EN_LARGE: reservado para sistema de energia de habilidades
	AudioManager.play_sfx(AudioLibrary.sfx_collectible)
	queue_free()
