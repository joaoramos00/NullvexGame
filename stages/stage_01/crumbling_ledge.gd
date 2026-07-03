# Saliência que desmorona ~crumble_delay após o player pousar, e respawna depois.
extends StaticBody2D

@export var crumble_delay: float = 0.5
@export var respawn_delay: float = 1.2

enum State { SOLID, CRUMBLING, GONE }

var _cs: CollisionShape2D
var _state: int = State.SOLID
var _timer: float = 0.0

func _ready() -> void:
	_cs = get_node_or_null("CollisionShape2D")
	if _cs == null:
		for c in get_children():
			if c is CollisionShape2D:
				_cs = c
				break
	assert(_cs != null, "CrumblingLedge precisa de um CollisionShape2D filho")

func touched() -> void:
	if _state == State.SOLID:
		_state = State.CRUMBLING
		_timer = 0.0

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return   # bot: saliência fica sólida (valida o caminho)
	_tick(delta)

func _tick(delta: float) -> void:
	if _state == State.CRUMBLING:
		_timer += delta
		if _timer >= crumble_delay:
			if _cs: _cs.set_deferred("disabled", true)
			# Some do desenho da stage junto com a colisão (o _draw da stage_scene
			# checa skip_base_draw por frame) — senão o tile fica visível sem chão.
			set_meta("skip_base_draw", true)
			_state = State.GONE
			_timer = 0.0
	elif _state == State.GONE:
		_timer += delta
		if _timer >= respawn_delay:
			if _cs: _cs.set_deferred("disabled", false)
			if has_meta("skip_base_draw"):
				remove_meta("skip_base_draw")
			_state = State.SOLID
			_timer = 0.0
