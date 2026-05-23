extends CharacterBody2D
class_name EnemyBase

signal died
signal damaged(amount: int)

const GRAVITY := 980.0
const PATROL_SPEED := 80.0
const INVINCIBILITY_DURATION := 0.3
const HIT_FLASH_DURATION := 0.1

const _DEATH_EFFECT_SCENE := preload("res://effects/death_effect.tscn")

@export var max_hp: int = 4
@export var contact_damage: int = 8

var current_hp: int = 4
var is_dead: bool = false
var _direction: float = 1.0
var _invincible: bool = false
var _invincibility_timer: float = 0.0
var _hit_flash_timer: float = 0.0

func _ready() -> void:
	current_hp = max_hp
	$ContactZone.body_entered.connect(_on_contact)
	queue_redraw()

func _draw() -> void:
	var c := Color.WHITE if _hit_flash_timer > 0.0 else Color.ORANGE_RED
	draw_rect(Rect2(-20, -40, 40, 80), c)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
		if _hit_flash_timer <= 0.0:
			queue_redraw()
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor() and not _has_floor_ahead():
		_direction = -_direction
	velocity.x = PATROL_SPEED * _direction
	move_and_slide()
	if is_on_wall():
		_direction = -_direction

func _has_floor_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var start := Vector2(global_position.x + _direction * 26.0, global_position.y - 8.0)
	var end   := Vector2(global_position.x + _direction * 26.0, global_position.y + 88.0)
	var params := PhysicsRayQueryParameters2D.create(start, end)
	return not space.intersect_ray(params).is_empty()

func _on_contact(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(contact_damage)

func take_damage(amount: int, _source: String = "") -> void:
	if is_dead or _invincible:
		return
	current_hp = max(0, current_hp - amount)
	_invincible = true
	_invincibility_timer = INVINCIBILITY_DURATION
	_hit_flash_timer = HIT_FLASH_DURATION
	queue_redraw()
	damaged.emit(amount)
	if current_hp == 0:
		_die()

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	AudioManager.play_sfx(AudioLibrary.sfx_enemy_death)
	died.emit()
	var effect: Node2D = _DEATH_EFFECT_SCENE.instantiate()
	effect.global_position = global_position
	get_parent().add_child(effect)
	queue_free()
