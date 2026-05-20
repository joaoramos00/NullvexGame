extends CharacterBody2D
class_name EnemyBase

signal died
signal damaged(amount: int)

const GRAVITY := 980.0
const PATROL_SPEED := 80.0
const INVINCIBILITY_DURATION := 0.3

@export var max_hp: int = 30
var current_hp: int = 30
var is_dead: bool = false
var _direction: float = 1.0
var _invincible: bool = false
var _invincibility_timer: float = 0.0

func _ready() -> void:
    current_hp = max_hp
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(-10, -28, 20, 48), Color.ORANGE_RED)

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    if _invincibility_timer > 0.0:
        _invincibility_timer -= delta
        if _invincibility_timer <= 0.0:
            _invincible = false
    if not is_on_floor():
        velocity.y += GRAVITY * delta
    velocity.x = PATROL_SPEED * _direction
    move_and_slide()
    if is_on_wall():
        _direction = -_direction

func take_damage(amount: int) -> void:
    if is_dead or _invincible:
        return
    current_hp = max(0, current_hp - amount)
    _invincible = true
    _invincibility_timer = INVINCIBILITY_DURATION
    damaged.emit(amount)
    if current_hp == 0:
        _die()

func _die() -> void:
    is_dead = true
    velocity = Vector2.ZERO
    died.emit()
    queue_free()
