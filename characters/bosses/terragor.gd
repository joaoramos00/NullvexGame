extends BossBase

const _TEX_IDLE_W := preload("res://characters/bosses/terragor/terragor_west.png")
const _TEX_IDLE_E := preload("res://characters/bosses/terragor/terragor_east.png")
const _TEX_WALK_W := preload("res://characters/bosses/terragor/terragor_walk_west.png")
const _TEX_WALK_E := preload("res://characters/bosses/terragor/terragor_walk_east.png")
const _TEX_ENTRY  := preload("res://characters/bosses/terragor/terragor_entry.png")

const _WALK_FRAMES  := 9
const _WALK_FPS     := 8.0
const _ENTRY_FRAMES := 7
const _ENTRY_FPS    := 8.0

var _anim_timer : float = 0.0
var _anim_frame : int   = 0
var _facing     : float = -1.0

@onready var _sprite: Sprite2D = $Sprite2D

func _draw() -> void:
	var pct := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	draw_rect(Rect2(-24, -52, 48, 6), Color.BLACK)
	draw_rect(Rect2(-24, -52, 48.0 * pct, 6), Color.GREEN)

func _face_player() -> void:
	pass

func _physics_process(delta: float) -> void:
	super(delta)
	_update_animation(delta)

func _update_animation(delta: float) -> void:
	if state == State.INTRO:
		_sprite.texture = _TEX_ENTRY
		_sprite.hframes = _ENTRY_FRAMES
		_anim_timer += delta
		if _anim_timer >= 1.0 / _ENTRY_FPS:
			_anim_timer -= 1.0 / _ENTRY_FPS
			_anim_frame = mini(_anim_frame + 1, _ENTRY_FRAMES - 1)
		_sprite.frame    = _anim_frame
		_sprite.modulate = Color.WHITE
		return
	if state in [State.DYING, State.DEAD]:
		return
	if   velocity.x >  10.0: _facing =  1.0
	elif velocity.x < -10.0: _facing = -1.0
	var tex   : Texture2D
	var frames: int
	var fps   : float
	if absf(velocity.x) > 10.0:
		tex = _TEX_WALK_E if _facing > 0.0 else _TEX_WALK_W
		frames = _WALK_FRAMES; fps = _WALK_FPS
	else:
		tex = _TEX_IDLE_E if _facing > 0.0 else _TEX_IDLE_W
		frames = 1; fps = 4.0
	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = frames
		_anim_frame = 0; _anim_timer = 0.0
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	elif _invincible:
		var a := 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
		_sprite.modulate = Color(1.0, 1.0, 1.0, a)
	else:
		_sprite.modulate = Color.WHITE
	_anim_timer += delta
	if frames > 1 and _anim_timer >= 1.0 / fps:
		_anim_timer -= 1.0 / fps
		_anim_frame = (_anim_frame + 1) % frames
	_sprite.frame = _anim_frame

func _do_combat(delta: float) -> void:
	if player == null:
		return
	var dx := player.global_position.x - global_position.x
	if abs(dx) > 80.0:
		velocity.x = sign(dx) * 50.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	_clamp_to_arena()

func _do_attack() -> void:
	_is_attacking = true
	velocity.x = 0.0
	await get_tree().create_timer(0.4).timeout
	if is_dead:
		_is_attacking = false
		return
	var count := 4 if phase == 2 else 2
	for i in count:
		var dir := 1.0 if i % 2 == 0 else -1.0
		# Phase 2: odd pair fires slightly upward for arcing rocks
		var vy := -100.0 if phase == 2 and i >= 2 else 0.0
		_spawn_projectile(
			global_position, Vector2(dir * 180.0, vy),
			15, "terragor", Color(0.5, 0.35, 0.1)
		)
	_is_attacking = false

func _enter_phase_2() -> void:
	attack_interval_p2 = 1.2
