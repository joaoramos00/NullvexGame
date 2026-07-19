# stages/stage_01/cracked_wall.gd
# StaticBody2D com CollisionShape2D filho.
# Visual: pilha de blocos de pedra-pomes (fx_pumice_idle.png, 64x64) cobrindo
# a altura do collider — gerado via PixelLab (objeto quebrável, tema "sumir
# com o vento"). Destruída quando um projétil (Area2D, collision_layer=8)
# entra num filho HitDetector enquanto o player tiver "galerix" desbloqueada:
# a colisão desliga na hora e cada bloco toca a animação de quebra
# (fx_pumice_break.png, 13 frames) em sincronia antes da parede sumir.
# @export break_side: "" = qualquer lado; "left"/"right" = só esse detector.
extends StaticBody2D

signal wall_destroyed

@export var break_side: String = ""

const TEX_IDLE := preload("res://stages/stage_01/fx_pumice_idle.png")
const TEX_BREAK := preload("res://stages/stage_01/fx_pumice_break.png")
const _BLOCK_SIZE := 64.0
const _BREAK_FRAMES := 13
const _BREAK_FPS := 16.0

var _segments: Array[Sprite2D] = []
var _breaking := false
var _break_frame := 0
var _break_timer := 0.0

func can_break_from(side: String) -> bool:
	if not GameManager.boss_abilities_unlocked.has("galerix"):
		return false
	return break_side == "" or break_side == side

func _ready() -> void:
	add_to_group("cracked_wall")
	set_meta("skip_base_draw", true)   # desenho próprio (segments), não a rocha da zona
	_build_segments()
	for child in get_children():
		if child is Area2D and child.name.begins_with("HitDetector"):
			var side := "left" if child.name.ends_with("L") else ("right" if child.name.ends_with("R") else "")
			(child as Area2D).area_entered.connect(func(_a): _on_hit_side(side))

func _first_collision_shape() -> CollisionShape2D:
	for c in get_children():
		if c is CollisionShape2D:
			return c
	return null

# Empilha blocos de 64x64 do topo pro fundo até cobrir a altura do collider
# (arredondando pra cima — o último bloco pode ultrapassar um pouco a borda
# de baixo, sem problema visual num shaft/corredor de rocha).
func _build_segments() -> void:
	var shape := _first_collision_shape()
	if shape == null or not (shape.shape is RectangleShape2D):
		return
	var size: Vector2 = (shape.shape as RectangleShape2D).size
	var rows := ceili(size.y / _BLOCK_SIZE)
	var top := -size.y * 0.5 + _BLOCK_SIZE * 0.5
	for i in rows:
		var seg := Sprite2D.new()
		seg.texture = TEX_IDLE
		seg.position = Vector2(0.0, top + i * _BLOCK_SIZE)
		add_child(seg)
		_segments.append(seg)

func _process(delta: float) -> void:
	if not _breaking:
		return
	_break_timer += delta
	if _break_timer >= 1.0 / _BREAK_FPS:
		_break_timer -= 1.0 / _BREAK_FPS
		_break_frame += 1
		if _break_frame >= _BREAK_FRAMES:
			queue_free()
			return
		for seg in _segments:
			seg.frame = _break_frame

func _on_hit_side(side: String) -> void:
	if is_queued_for_deletion() or _breaking:
		return
	if can_break_from(side):
		wall_destroyed.emit()
		_start_break()

func _start_break() -> void:
	_breaking = true
	_break_frame = 0
	_break_timer = 0.0
	var shape := _first_collision_shape()
	if shape != null:
		shape.set_deferred("disabled", true)
	for seg in _segments:
		seg.texture = TEX_BREAK
		seg.hframes = _BREAK_FRAMES
		seg.frame = 0

# Kept for backwards compatibility — called by tests/test_stage01_hazards.gd
# Ignora break_side (usa ""), então só destrói paredes default/qualquer-lado —
# intencional para os callers existentes do teste de hazards.
func try_destroy() -> void:
	if is_queued_for_deletion() or _breaking:
		return
	if can_break_from(""):
		wall_destroyed.emit()
		_start_break()
