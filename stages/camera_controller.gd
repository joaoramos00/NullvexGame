# stages/camera_controller.gd
class_name CameraController
extends RefCounted

# ── Constantes ────────────────────────────────────────────────────────────────
const _CAM_RISE      := 128.0   # câmera acima do origin do player → piso 60px da borda inferior
const GROUNDED_SPEED := 8.0     # lerp ao pousar (~0.3s para atingir o alvo)
const SHAFT_SPEED    := 10.0    # lerp em modo shaft (subida e descida)
const FALL_SPEED     := 5.0     # lerp quando leash activo
const LEASH_SLACK    := 64.0    # 1 tile — folga antes de câmera seguir em queda
const LOCK_SPEED     := 0.1     # factor de lerp em modo locked (por frame)

# ── Estado público ────────────────────────────────────────────────────────────
var target_x: float = 0.0
var target_y: float = 0.0
var is_locked: bool = false
var lock_zoom: float = 2.0

# ── Estado interno ────────────────────────────────────────────────────────────
var _player: CharacterBase = null
var _cam_x: float  = 0.0   # posição X actual da câmera (lerp durante lock)
var _cam_y: float  = 0.0   # posição Y actual da câmera
var _floor_y: float = 0.0  # nível de piso actual (actualizado ao pousar)
var _lock_target: Vector2 = Vector2.ZERO
var _shaft: bool = false

# ── API pública ───────────────────────────────────────────────────────────────

func setup(player: CharacterBase, _cam: Camera2D) -> void:
	_player  = player
	_cam_x   = player.global_position.x
	_cam_y   = player.global_position.y - _CAM_RISE
	_floor_y = player.global_position.y
	target_x = _cam_x
	target_y = _cam_y

func update(delta: float) -> void:
	if not is_instance_valid(_player):
		return

	# ── Nível 1: LOCKED (corredor / boss room) ────────────────────────────────
	if is_locked:
		_cam_x = lerpf(_cam_x, _lock_target.x, LOCK_SPEED)
		_cam_y = lerpf(_cam_y, _lock_target.y, LOCK_SPEED)
		target_x = _cam_x
		target_y = _cam_y
		return

	# reset _cam_x para o player quando não está locked
	_cam_x = _player.global_position.x
	target_x = _cam_x

	# ── Nível 1: SHAFT (shaft vertical — câmera segue em ambas as direcções) ──
	if _shaft:
		var ty: float = _player.global_position.y - _CAM_RISE
		_cam_y = lerpf(_cam_y, ty, minf(SHAFT_SPEED * delta, 1.0))
		target_y = _cam_y
		return

	# ── Nível 2: Default MMX ──────────────────────────────────────────────────
	if _player.is_on_floor():
		# Qualquer aterragem actualiza _floor_y (sem threshold)
		_floor_y = _player.global_position.y
		_cam_y = lerpf(_cam_y, _floor_y - _CAM_RISE, minf(GROUNDED_SPEED * delta, 1.0))
	elif _player.velocity.y > 0.0:   # a cair
		var ideal: float = _player.global_position.y - _CAM_RISE
		if ideal > _cam_y + LEASH_SLACK:
			_cam_y = lerpf(_cam_y, ideal, minf(FALL_SPEED * delta, 1.0))
	# a subir (pulo): _cam_y congela

	target_y = _cam_y

func lock_to(target: Vector2, zoom: float) -> void:
	is_locked  = true
	lock_zoom  = zoom
	_lock_target = target

func unlock() -> void:
	is_locked = false
	if is_instance_valid(_player):
		_floor_y = _player.global_position.y   # reset nível de piso ao desbloquear
		_cam_x   = _player.global_position.x

func set_shaft_mode(active: bool) -> void:
	_shaft = active
	if active and is_instance_valid(_player):
		_floor_y = _player.global_position.y   # reset nível de piso ao entrar no shaft
