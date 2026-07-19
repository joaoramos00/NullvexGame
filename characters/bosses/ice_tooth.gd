extends Area2D
class_name IceTooth

# Dente/espinho de gelo do 4º ataque do Cryovex (GroundBurst): nasce do chão
# (toca a animação gerada de trás pra frente — cotoco até o espinho cheio),
# segura no topo, depois desmorona (toca a animação na ordem normal até
# sumir). Dano por contato só na janela "sólido" (topo do ciclo). Vários
# IceTooth são spawnados em sequência pelo boss, marchando em direção ao
# player (ver cryovex.gd::_do_ground_burst). Sprite gerado via PixelLab +
# skill pixellab-effect (objeto 29a2fbc0, animação "grows...shatters").
const TEX := preload("res://characters/bosses/cryovex/fx_ice_tooth.png")
const _RAW_FRAMES := 15
const _FPS := 20.0

var damage: int = 6
var source_id: String = "cryovex"

var _sequence: Array[int] = []
var _step := 0
var _anim_timer := 0.0
var _solid_start := 0
var _solid_end := 0
var _hit_bodies: Dictionary = {}

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_sprite.texture = TEX
	_sprite.hframes = _RAW_FRAMES
	for i in range(_RAW_FRAMES - 1, -1, -1):
		_sequence.append(i)
	for i in range(1, _RAW_FRAMES):
		_sequence.append(i)
	_solid_start = _RAW_FRAMES - 3
	_solid_end = _RAW_FRAMES + 2
	_sprite.frame = _sequence[0]

func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 1.0 / _FPS:
		_anim_timer -= 1.0 / _FPS
		_step += 1
		if _step >= _sequence.size():
			queue_free()
			return
		_sprite.frame = _sequence[_step]

func _on_body_entered(body: Node) -> void:
	if _step < _solid_start or _step > _solid_end:
		return
	if _hit_bodies.has(body):
		return
	if body.has_method("take_damage"):
		_hit_bodies[body] = true
		body.take_damage(damage, source_id)
