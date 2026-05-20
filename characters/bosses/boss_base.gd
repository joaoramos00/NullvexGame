extends CharacterBody2D
class_name BossBase

signal boss_defeated(ability_id: String)
signal damaged(amount: int)
signal died

enum State { IDLE, INTRO, COMBAT, DYING, DEAD }

const GRAVITY := 980.0
const AGGRO_RANGE := 500.0
const INVINCIBILITY_DURATION := 0.5
const WEAKNESS_MULTIPLIER := 2.0

@export var boss_id: String = ""
@export var weakness_id: String = ""
@export var ability_id: String = ""
@export var stage_id: int = -1
@export var max_hp: int = 200
@export var boss_color: Color = Color.DARK_RED
@export var death_duration: float = 1.5
@export var intro_duration: float = 1.0
@export var player: CharacterBase = null

var current_hp: int
var state: State = State.IDLE
var is_dead: bool = false
var _invincible: bool = false
var _invincibility_timer: float = 0.0

func _ready() -> void:
	current_hp = max_hp
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-24, -40, 48, 80), boss_color)
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	draw_rect(Rect2(-24, -52, 48, 6), Color.BLACK)
	draw_rect(Rect2(-24, -52, 48.0 * pct, 6), Color.GREEN)

func _physics_process(delta: float) -> void:
	if state in [State.DYING, State.DEAD]:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	match state:
		State.COMBAT:
			_tick_combat(delta)
		State.IDLE:
			velocity.x = 0.0
			_tick_idle()
		State.INTRO:
			velocity.x = 0.0
	move_and_slide()

func _tick_idle() -> void:
	if player == null:
		return
	if global_position.distance_to(player.global_position) < AGGRO_RANGE:
		_start_intro()

func _start_intro() -> void:
	state = State.INTRO
	velocity = Vector2.ZERO
	_run_intro()

func _run_intro() -> void:
	await get_tree().create_timer(intro_duration).timeout
	if state == State.INTRO:
		state = State.COMBAT

func _tick_combat(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
	_do_combat(delta)

func _do_combat(_delta: float) -> void:
	if player != null:
		velocity.x = sign(player.global_position.x - global_position.x) * 60.0

func take_damage(amount: int, source_id: String = "") -> void:
	if is_dead or _invincible or state in [State.IDLE, State.INTRO, State.DEAD]:
		return
	if source_id != "" and source_id == weakness_id:
		amount = int(amount * WEAKNESS_MULTIPLIER)
	current_hp = max(0, current_hp - amount)
	_invincible = true
	_invincibility_timer = INVINCIBILITY_DURATION
	damaged.emit(amount)
	queue_redraw()
	if current_hp == 0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	state = State.DYING
	velocity = Vector2.ZERO
	died.emit()
	_run_death_sequence()

func _run_death_sequence() -> void:
	await get_tree().create_timer(death_duration).timeout
	if stage_id >= 0:
		GameManager.complete_stage(stage_id)
	if ability_id != "":
		GameManager.unlock_ability(ability_id)
	state = State.DEAD
	boss_defeated.emit(ability_id)
	queue_free()
