# stages/stage_01/rising_lava.gd
# Lava instant-kill com 3 modos:
#   tide    — oscila low_y ↔ high_y (maré da zona 3).
#   chase   — após activate(), sobe contínua (rise_speed) até cap_y; não para.
#   coupled — acompanha a altura máxima do player (player.y+coupled_offset); só sobe.
# Em TODOS os modos: instant-kill no contato e CONGELA em low_y no modo bot.
extends Area2D

@export var mode: String = "tide"        # "tide" | "chase" | "coupled"
@export var low_y:  float = 2720.0        # superfície em repouso / congelada (bot)
@export var high_y: float = 2500.0        # tide: pico
@export var speed:  float = 70.0          # tide: px/s
@export var pause_time: float = 1.2       # tide: pausa nos extremos
@export var rise_speed: float = 80.0      # chase: px/s subindo
@export var cap_y: float = 1500.0         # chase: teto (para de subir)
@export var coupled_offset: float = 220.0 # coupled: distância abaixo do player

var _going_up: bool = true
var _pause: float = 0.0
var _active: bool = false                 # chase: ligada?
var _coupled_target: float = 0.0
var _player: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	position.y = low_y
	if mode == "coupled":
		_coupled_target = low_y

func set_player(p: Node2D) -> void:
	_player = p

func activate() -> void:
	_active = true

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		(body as CharacterBase).kill()

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return                            # bot: lava parada embaixo (valida o caminho)
	if mode == "coupled" and is_instance_valid(_player):
		_set_coupled_target(_player.global_position.y)
	_tick(delta)

# Lógica pura (testável headless), separada do _physics_process.
func _tick(delta: float) -> void:
	match mode:
		"tide":   _tick_tide(delta)
		"chase":  _tick_chase(delta)
		"coupled": _tick_coupled(delta)

func _tick_tide(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		return
	var tgt := high_y if _going_up else low_y
	position.y = move_toward(position.y, tgt, speed * delta)
	if absf(position.y - tgt) < 0.5:
		_going_up = not _going_up
		_pause = pause_time

func _tick_chase(delta: float) -> void:
	if not _active:
		return
	position.y = move_toward(position.y, cap_y, rise_speed * delta)

func _set_coupled_target(player_y: float) -> void:
	_coupled_target = player_y + coupled_offset

func _tick_coupled(_delta: float) -> void:
	# só sobe (y menor = mais alto): nunca aumenta position.y.
	position.y = minf(position.y, _coupled_target)
