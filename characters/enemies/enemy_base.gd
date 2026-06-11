extends CharacterBody2D
class_name EnemyBase

signal died
signal damaged(amount: int)

const GRAVITY                := 980.0
const PATROL_SPEED           := 80.0
const INVINCIBILITY_DURATION := 0.3
const ANIM_FPS               := 5.0
const WALK_FRAMES            := 6

const _DEATH_EFFECT_SCENE := preload("res://effects/death_effect.tscn")

@export var max_hp:         int = 8
@export var contact_damage: int = 8

var current_hp:           int   = 8
var is_dead:              bool  = false
var _direction:           float = 1.0
var _invincible:          bool  = false
var _invincibility_timer: float = 0.0
var _anim_timer:          float = 0.0
var _anim_frame:          int   = 0
var _visual_motion_time:  float = 0.0
var _visual_rest_position := Vector2.ZERO
var _visual_rest_rotation := 0.0
var _visual_rest_cached   := false

var show_hitbox: bool = false:
	set(value):
		show_hitbox = value
		queue_redraw()

@onready var _sprite := $Sprite2D

func _ready() -> void:
	current_hp = max_hp
	$ContactZone.body_entered.connect(_on_contact)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor() and not _has_floor_ahead():
		_direction = -_direction
	velocity.x = PATROL_SPEED * _direction
	move_and_slide()
	if is_on_wall():
		_direction = -_direction
	if _invincible:
		_sprite.modulate.a = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0
	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer -= 1.0 / ANIM_FPS
		_anim_frame = (_anim_frame + 1) % WALK_FRAMES
	_sprite.frame  = _anim_frame
	_sprite.flip_h = (_direction < 0)

func _has_floor_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var start := Vector2(global_position.x + _direction * 26.0, global_position.y - 8.0)
	var end   := Vector2(global_position.x + _direction * 26.0, global_position.y + 88.0)
	var params := PhysicsRayQueryParameters2D.create(start, end)
	return not space.intersect_ray(params).is_empty()

func _cache_sprite_rest_transform() -> void:
	if not is_instance_valid(_sprite):
		return
	if _visual_rest_cached:
		return
	_visual_rest_position = _sprite.position
	_visual_rest_rotation = _sprite.rotation
	_visual_rest_cached = true

func _animate_sprite_frames(delta: float, frame_count: int = WALK_FRAMES, fps: float = ANIM_FPS) -> void:
	if not is_instance_valid(_sprite):
		return
	var available_frames: int = max(1, _sprite.hframes * _sprite.vframes)
	var cycle_frames: int = int(min(frame_count, available_frames))
	if cycle_frames <= 1 or fps <= 0.0:
		return
	_anim_timer += delta
	var frame_duration: float = 1.0 / fps
	while _anim_timer >= frame_duration:
		_anim_timer -= frame_duration
		_anim_frame = (_anim_frame + 1) % cycle_frames
	_sprite.frame = _anim_frame

func _animate_sprite_motion(delta: float, bob_pixels: float, bob_speed: float, tilt_degrees: float = 0.0, sway_pixels: float = 0.0) -> void:
	if not is_instance_valid(_sprite):
		return
	_cache_sprite_rest_transform()
	_visual_motion_time += delta
	var bob: float = sin(_visual_motion_time * bob_speed) * bob_pixels
	var sway: float = sin(_visual_motion_time * bob_speed * 0.7) * sway_pixels
	var tilt: float = sin(_visual_motion_time * bob_speed * 0.8) * deg_to_rad(tilt_degrees)
	_sprite.position = _visual_rest_position + Vector2(sway, bob)
	_sprite.rotation = _visual_rest_rotation + tilt

func _on_contact(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(contact_damage)

func take_damage(amount: int, _source: String = "") -> void:
	if is_dead or _invincible:
		return
	current_hp = max(0, current_hp - amount)
	_invincible = true
	_invincibility_timer = INVINCIBILITY_DURATION
	damaged.emit(amount)
	if current_hp == 0:
		_die()

func _draw() -> void:
	if not show_hitbox:
		return
	# CapsuleShape2D radius=20, height=40 → bounding rect (-20,-40,40,80)
	var bounds := Rect2(-20.0, -40.0, 40.0, 80.0)
	draw_rect(bounds, Color(1.0, 0.25, 0.25, 0.25))
	draw_rect(bounds, Color(1.0, 0.25, 0.25, 1.0), false, 2.0)

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	AudioManager.play_sfx(AudioLibrary.sfx_enemy_death)
	died.emit()
	var effect: Node2D = _DEATH_EFFECT_SCENE.instantiate()
	effect.global_position = global_position
	get_parent().add_child(effect)
	queue_free()
