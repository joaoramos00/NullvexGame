extends Node2D
class_name GravitusSingularityFX

# Efeito visual puro (sem colisão/dano — o dano já é aplicado por proximidade
# em gravitus.gd) do Singularity Punch. mode="shrink" toca durante o preparo,
# mas DE TRÁS PRA FRENTE — a animação original encolhe um vórtice grande até
# um ponto; invertida, ela cresce de um ponto até o vórtice cheio, o que bate
# com "energia se acumulando na garra" em vez de "efeito sumindo". mode=
# "explode" toca normal no momento do impacto (implosão + onda de choque).
# Ambas geradas via PixelLab a partir do mesmo objeto.
const TEX_SHRINK  := preload("res://characters/bosses/gravitus/fx_singularity_shrink.png")
const TEX_EXPLODE := preload("res://characters/bosses/gravitus/fx_singularity_explode.png")
const _FRAMES := 9
const _SHRINK_FPS  := 12.0
const _EXPLODE_FPS := 18.0

@export var mode: String = "explode"   # "shrink" ou "explode"

var _frame := 0
var _timer := 0.0
var _fps: float = _EXPLODE_FPS
var _reverse := false

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var tex: Texture2D = TEX_SHRINK if mode == "shrink" else TEX_EXPLODE
	_fps = _SHRINK_FPS if mode == "shrink" else _EXPLODE_FPS
	_reverse = mode == "shrink"
	_sprite.texture = tex
	_sprite.hframes = _FRAMES
	_sprite.frame = _FRAMES - 1 if _reverse else 0

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 1.0 / _fps:
		_timer -= 1.0 / _fps
		_frame += 1
		if _frame >= _FRAMES:
			queue_free()
			return
		_sprite.frame = _FRAMES - 1 - _frame if _reverse else _frame
