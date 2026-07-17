# Plataforma que alterna sólida/vazia num ciclo temporizado — mesma técnica
# de toggle de colisão de stages/stage_01/crumbling_ledge.gd (set_deferred
# "disabled" + skip_base_draw), só que disparada por tempo, não por contato.
# phase_offset dessincroniza múltiplas instâncias entre si (Zona 2).
extends StaticBody2D

@export var solid_time: float = 2.0
@export var phase_time: float = 1.0
@export var phase_offset: float = 0.0
@export var warn_time: float = 0.3   # flicker de aviso antes de fasear

var _cs: CollisionShape2D
var _timer: float = 0.0
var _solid: bool = true

func _ready() -> void:
	_cs = get_node_or_null("CollisionShape2D")
	if _cs == null:
		for c in get_children():
			if c is CollisionShape2D:
				_cs = c
				break
	assert(_cs != null, "PhasePlatform precisa de um CollisionShape2D filho")
	solid_time = maxf(solid_time, 0.05)
	phase_time = maxf(phase_time, 0.05)
	_timer = phase_offset
	if not DebugBoot.bot_enabled:
		_catch_up()

func _catch_up() -> void:
	# Aplica o avanço de phase_offset sem esperar o primeiro frame de física
	# (senão a plataforma pisca visualmente sólida por 1 frame antes de ajustar).
	while _timer >= (solid_time if _solid else phase_time):
		_timer -= (solid_time if _solid else phase_time)
		_solid = not _solid
	_apply_state()

func _physics_process(delta: float) -> void:
	if DebugBoot.bot_enabled:
		return   # bot: plataforma sempre sólida, valida o layout sem depender do timing
	_timer += delta
	var period: float = solid_time if _solid else phase_time
	if _timer >= period:
		_timer -= period
		_solid = not _solid
		_apply_state()
	if _solid and (period - _timer) <= warn_time:
		visible = int(Time.get_ticks_msec() / 80) % 2 == 0
	else:
		visible = _solid

func _apply_state() -> void:
	if _cs:
		_cs.set_deferred("disabled", not _solid)
	visible = _solid
	if _solid:
		if has_meta("skip_base_draw"):
			remove_meta("skip_base_draw")
	else:
		set_meta("skip_base_draw", true)
