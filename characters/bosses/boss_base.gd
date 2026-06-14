extends CharacterBody2D
class_name BossBase

signal boss_defeated(ability_id: String)
signal boss_aggro
signal boss_intro_ended
signal damaged(amount: int)
signal died
signal hp_changed(current: int, maximum: int)

enum State { IDLE, INTRO, COMBAT, DYING, DEAD }

const GRAVITY := 980.0
const AGGRO_RANGE := 500.0
const INVINCIBILITY_DURATION := 0.5
const WEAKNESS_MULTIPLIER := 2.0

const _PROJECTILE_SCENE := preload("res://characters/bosses/boss_projectile.tscn")
const _DEATH_EFFECT_SCENE := preload("res://effects/death_effect.tscn")

const HIT_FLASH_DURATION := 0.12

@export var boss_id: String = ""
@export var weakness_id: String = ""
@export var ability_id: String = ""
@export var stage_id: int = -1
@export var max_hp: int = 200
@export var boss_color: Color = Color.DARK_RED
@export var death_duration: float = 1.5
@export var intro_duration: float = 1.0
@export var player: CharacterBase = null
@export var phase2_threshold: float = 0.5
@export var attack_interval_p1: float = 2.5
@export var attack_interval_p2: float = 1.5
@export var arena_left: float = 100.0
@export var arena_right: float = 1820.0
@export var arena_floor: float = 500.0
# Quando true (padrão), o boss aciona a luta sozinho ao player entrar em AGGRO_RANGE.
# Quando false, a luta só começa via aggro() externo (ex.: gatilho de entrada na sala).
@export var auto_aggro: bool = true

var current_hp: int
var state: State = State.IDLE
var is_dead: bool = false
var phase: int = 1
var gravity_scale: float = 1.0

var _invincible: bool = false
var _invincibility_timer: float = 0.0
var _hit_flash_timer: float = 0.0
var _attack_timer: float = 1.5
var _is_attacking: bool = false

func _ready() -> void:
	current_hp = max_hp
	queue_redraw()

func _draw() -> void:
	var draw_color := Color.WHITE if _hit_flash_timer > 0.0 else boss_color
	draw_rect(Rect2(-24, -40, 48, 80), draw_color)
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	draw_rect(Rect2(-24, -52, 48, 6), Color.BLACK)
	draw_rect(Rect2(-24, -52, 48.0 * pct, 6), Color.GREEN)

func _physics_process(delta: float) -> void:
	if state in [State.DYING, State.DEAD]:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * gravity_scale * delta
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
	if not auto_aggro or player == null:
		return
	if global_position.distance_to(player.global_position) < AGGRO_RANGE:
		_start_intro()

# Inicia a luta por gatilho externo (ex.: player entrou na sala do boss).
# No-op se o boss não estiver mais em IDLE (já em luta/morto).
func aggro() -> void:
	if state == State.IDLE:
		_start_intro()

func _start_intro() -> void:
	state = State.INTRO
	velocity = Vector2.ZERO
	boss_aggro.emit()
	AudioManager.play_sfx(AudioLibrary.sfx_boss_aggro)
	_run_intro()

func _run_intro() -> void:
	await get_tree().create_timer(intro_duration).timeout
	if state == State.INTRO:
		state = State.COMBAT
		boss_intro_ended.emit()

func _tick_combat(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
		if _hit_flash_timer <= 0.0:
			queue_redraw()
	if not _is_attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			var interval := attack_interval_p2 if phase >= 2 else attack_interval_p1
			_attack_timer = interval
			_do_attack()
	_do_combat(delta)

func _do_combat(_delta: float) -> void:
	if player != null:
		velocity.x = sign(player.global_position.x - global_position.x) * 60.0

func _do_attack() -> void:
	pass

func _enter_phase_2() -> void:
	pass

func take_damage(amount: int, source_id: String = "") -> void:
	if is_dead or _invincible or state in [State.IDLE, State.INTRO, State.DEAD]:
		return
	if source_id != "" and source_id == weakness_id:
		amount = int(amount * WEAKNESS_MULTIPLIER)
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	_invincible = true
	_invincibility_timer = INVINCIBILITY_DURATION
	_hit_flash_timer = HIT_FLASH_DURATION
	AudioManager.play_sfx(AudioLibrary.sfx_boss_damage)
	damaged.emit(amount)
	queue_redraw()
	if current_hp > 0 and phase == 1 and float(current_hp) / float(max_hp) <= phase2_threshold:
		phase = 2
		_enter_phase_2()
	if current_hp == 0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	state = State.DYING
	velocity = Vector2.ZERO
	AudioManager.play_sfx(AudioLibrary.sfx_boss_death)
	died.emit()
	var effect: Node2D = _DEATH_EFFECT_SCENE.instantiate()
	effect.global_position = global_position
	effect.color = boss_color
	get_parent().add_child(effect)
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

func _face_player() -> void:
	if player != null:
		scale.x = sign(player.global_position.x - global_position.x)

func _clamp_to_arena() -> void:
	if global_position.x <= arena_left:
		velocity.x = max(0.0, velocity.x)
	elif global_position.x >= arena_right:
		velocity.x = min(0.0, velocity.x)

func _spawn_projectile(pos: Vector2, vel: Vector2, dmg: int, src: String, col: Color = Color.ORANGE_RED) -> void:
	var p: BossProjectile = _PROJECTILE_SCENE.instantiate()
	p.global_position = pos
	p.projectile_velocity = vel
	p.damage = dmg
	p.source_id = src
	p.color = col
	get_parent().add_child(p)
