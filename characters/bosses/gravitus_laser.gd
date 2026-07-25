extends Node2D
class_name GravitusLaser

# Laser do satélite orbital do Gravitus: telegraph (linha pontilhada, sem
# dano) por _TELEGRAPH_DURATION, depois feixe sólido por _FIRE_DURATION que
# causa dano (checagem de distância ponto-segmento, sem CollisionShape2D —
# mais preciso pra uma linha fina). Ao disparar, spawna o FX de impacto
# (GravitusLaserImpactFX) no ponto final do feixe.
const _IMPACT_FX_SCENE := preload("res://characters/bosses/gravitus_laser_impact_fx.tscn")

const _TELEGRAPH_DURATION := 0.6
const _FIRE_DURATION      := 0.15
const _BEAM_WIDTH         := 6.0
const _HIT_RADIUS         := 14.0

@export var target: Vector2 = Vector2.ZERO   # em coordenadas globais
@export var damage: int = 10
@export var source_id: String = "gravitus"

var player: Node2D = null

var _target_local: Vector2 = Vector2.ZERO
var _firing := false
var _timer := 0.0

func _ready() -> void:
	_target_local = target - global_position

func _process(delta: float) -> void:
	_timer += delta
	if not _firing:
		if _timer >= _TELEGRAPH_DURATION:
			_firing = true
			_timer = 0.0
			AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)
			_check_hit()
			_spawn_impact_fx()
		queue_redraw()
		return
	if _timer >= _FIRE_DURATION:
		queue_free()
		return
	queue_redraw()

func _check_hit() -> void:
	if player == null or not is_instance_valid(player):
		return
	var closest := Geometry2D.get_closest_point_to_segment(player.global_position, global_position, target)
	if player.global_position.distance_to(closest) <= _HIT_RADIUS and player.has_method("take_damage"):
		player.take_damage(damage, source_id)

func _spawn_impact_fx() -> void:
	var fx: Node2D = _IMPACT_FX_SCENE.instantiate()
	fx.global_position = target
	get_parent().add_child(fx)

func _draw() -> void:
	if not _firing:
		draw_dashed_line(Vector2.ZERO, _target_local, Color(0.7, 0.2, 0.9, 0.7), 2.0, 8.0)
	else:
		draw_line(Vector2.ZERO, _target_local, Color(0.85, 0.55, 1.0, 0.95), _BEAM_WIDTH)
		draw_line(Vector2.ZERO, _target_local, Color(1.0, 1.0, 1.0, 0.85), _BEAM_WIDTH * 0.4)
