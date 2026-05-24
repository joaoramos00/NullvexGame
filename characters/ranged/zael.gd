extends CharacterBase
class_name Zael

const CHARGE_L2_THRESHOLD := 0.4
const CHARGE_L3_THRESHOLD := 1.2

const BULLET_DAMAGE := [0, 5, 12, 25]
const BULLET_SCALE := [
    Vector2.ZERO,
    Vector2(1.0, 1.0),
    Vector2(1.6, 1.6),
    Vector2(2.5, 2.5),
]

const _BULLET_SCENE := preload("res://characters/ranged/zael_bullet.tscn")

const _FRAME_W := 68
const _FRAME_H := 68
const _ROW_RIGHT := 0

const _SPAWN_OFFSET_Y := -10.0
const _SPAWN_OFFSET_X := [0.0, 60.0, 65.0, 85.0]  # por nível: L1/L2/L3

# Absorção: bolinhas partem do círculo externo e espiralam para o centro
const _CHARGE_SPEED    := 0.6
const _CHARGE_TURNS    := 1.2
const _CHARGE_CENTER_Y := -18.0

const _CHARGE_COUNT_L2     := 6
const _CHARGE_OUTER_L2     := 60.0
const _CHARGE_SIZE_L2      := 5.0
const _CHARGE_BIG_COUNT_L2 := 3
const _CHARGE_BIG_SIZE_L2  := 11.0
const _CHARGE_COLOR_L2     := Color(1.0, 0.88, 0.2, 0.85)

const _CHARGE_COUNT_L3     := 8
const _CHARGE_OUTER_L3     := 72.0
const _CHARGE_SIZE_L3      := 7.0
const _CHARGE_BIG_COUNT_L3 := 4
const _CHARGE_BIG_SIZE_L3  := 14.0
const _CHARGE_COLOR_L3     := Color(1.0, 0.22, 0.18, 0.85)

const _CHARGE_BIG_SPEED := 0.4  # bolinhas grandes mais lentas

const _SQUAT_DURATION     := 0.1
const _DASH_JUMP_BUFFER   := 0.15  # janela após o dash terminar para ainda fazer dash-jump
const _DASH_JUMP_SPEED    := 480.0 # velocidade horizontal do dash-jump (< DASH_SPEED=720)

var _charge_timer: float = 0.0
var _is_charging: bool = false
var _is_shooting: bool = false
var _jump_squat_timer: float = -1.0
var _dash_jump: bool = false
var _dash_jump_dir: float = 0.0
var _was_dashing_timer: float = 0.0
var _landing_timer: float = 0.0
var _was_on_floor: bool = true
var _spiral_phases: Array = []
var _spiral_phases_big: Array = []
var _draw_orbs: Array = []  # [{pos, color, radius}]
var _orb_canvas: Node2D    # filho com z_index alto para desenhar por cima

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    super._ready()
    _setup_sprite_frames()
    _sprite.animation_finished.connect(_on_shoot_finished)
    for i in _CHARGE_COUNT_L3:
        _spiral_phases.append(randf())
    for i in _CHARGE_BIG_COUNT_L3:
        _spiral_phases_big.append(randf())
    _orb_canvas = Node2D.new()
    _orb_canvas.z_index = 10
    add_child(_orb_canvas)
    _orb_canvas.draw.connect(_on_orb_canvas_draw)

func _on_orb_canvas_draw() -> void:
    for d in _draw_orbs:
        _orb_canvas.draw_circle(d.pos, d.radius, d.color)

func _setup_sprite_frames() -> void:
    var frames := SpriteFrames.new()
    var idle_tex  := load("res://characters/ranged/ZaelIdle.png")     as Texture2D
    var run_tex   := load("res://characters/ranged/ZaelCorrendo.png") as Texture2D
    var jump_tex  := load("res://characters/ranged/ZaelJump_new.png") as Texture2D
    var shoot_tex := load("res://characters/ranged/ZaelAtirando.png") as Texture2D
    var fw := _FRAME_W
    var fh := _FRAME_H

    frames.add_animation("idle")
    frames.set_animation_loop("idle", true)
    frames.set_animation_speed("idle", 8.0)
    for i in 8:
        var at := AtlasTexture.new()
        at.atlas = idle_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("idle", at)

    frames.add_animation("run")
    frames.set_animation_loop("run", true)
    frames.set_animation_speed("run", 10.0)
    for i in 6:
        var at := AtlasTexture.new()
        at.atlas = run_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("run", at)

    frames.add_animation("jump")
    frames.set_animation_loop("jump", false)
    frames.set_animation_speed("jump", 10.0)
    for i in 4:
        var at := AtlasTexture.new()
        at.atlas = jump_tex
        at.filter_clip = true
        at.region = Rect2(i * fw, 0, fw, fh)
        frames.add_frame("jump", at)

    var shoot_ranges := [[4, 4], [4, 5], [4, 6]]
    for lvl in 3:
        var anim := "shoot_%d" % (lvl + 1)
        frames.add_animation(anim)
        frames.set_animation_loop(anim, false)
        frames.set_animation_speed(anim, 10.0)
        for i in range(shoot_ranges[lvl][0], shoot_ranges[lvl][1] + 1):
            var at := AtlasTexture.new()
            at.atlas = shoot_tex
            at.filter_clip = true
            at.region = Rect2(i * fw, 0, fw, fh)
            frames.add_frame(anim, at)

    _sprite.sprite_frames = frames
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sprite.play("idle")

func _handle_jump() -> void:
    if _jump_squat_timer >= 0.0:
        return
    if Input.is_action_just_pressed("jump"):
        if _is_wall_sliding:
            _apply_wall_jump()
            return
        if _is_dashing or (_was_dashing_timer > 0.0 and is_on_floor()):
            # Dash-jump: pulo imediato sem squat, mantém velocidade do dash
            _dash_jump = true
            _dash_jump_dir = _dash_direction
            _is_dashing = false
            _was_dashing_timer = 0.0
            velocity.y = JUMP_VELOCITY
            velocity.x = _DASH_JUMP_SPEED * _dash_jump_dir
            AudioManager.play_sfx(AudioLibrary.sfx_jump)
            return
        if is_on_floor() or _coyote_timer > 0.0:
            _jump_squat_timer = 0.0
            _coyote_timer = 0.0

func _handle_movement() -> void:
    if _dash_jump and not is_on_floor():
        return
    super._handle_movement()

func _physics_process(delta: float) -> void:
    if _jump_squat_timer >= 0.0:
        _jump_squat_timer += delta
        if _jump_squat_timer >= _SQUAT_DURATION:
            velocity.y = JUMP_VELOCITY
            _jump_squat_timer = -1.0
            AudioManager.play_sfx(AudioLibrary.sfx_jump)
    # Rastreia tempo desde o último dash para a janela de buffer
    if _is_dashing:
        _was_dashing_timer = _DASH_JUMP_BUFFER
    elif _was_dashing_timer > 0.0:
        if is_on_floor():
            _was_dashing_timer = max(0.0, _was_dashing_timer - delta)
        else:
            _was_dashing_timer = 0.0
    super._physics_process(delta)
    if is_dead:
        return
    # Mantém velocidade horizontal do dash durante todo o tempo aéreo
    if _dash_jump and not is_on_floor():
        velocity.x = _DASH_JUMP_SPEED * _dash_jump_dir
    var just_landed: bool = is_on_floor() and not _was_on_floor
    _was_on_floor = is_on_floor()
    if just_landed:
        _landing_timer = 0.15
        _dash_jump = false
    elif is_on_floor():
        _dash_jump = false
    if _landing_timer > 0.0:
        _landing_timer = max(0.0, _landing_timer - delta)
    _handle_shooting(delta)
    _update_charge_effect(delta)
    _update_animation()

func _handle_shooting(delta: float) -> void:
    if is_dead:
        return
    if Input.is_action_just_pressed("attack"):
        _is_charging = true
    if _is_charging:
        _charge_timer += delta
    if Input.is_action_just_released("attack") and _is_charging:
        _fire(get_charge_level(_charge_timer))
        _is_charging = false
        _charge_timer = 0.0

func _update_charge_effect(delta: float) -> void:
    _draw_orbs.clear()
    var level := get_charge_level(_charge_timer)
    if not _is_charging or level < 2:
        _orb_canvas.queue_redraw()
        return

    var count   := _CHARGE_COUNT_L2 if level == 2 else _CHARGE_COUNT_L3
    var outer_r := _CHARGE_OUTER_L2 if level == 2 else _CHARGE_OUTER_L3
    var size    := _CHARGE_SIZE_L2  if level == 2 else _CHARGE_SIZE_L3
    var col     := _CHARGE_COLOR_L2 if level == 2 else _CHARGE_COLOR_L3

    for i in count:
        _spiral_phases[i] = fmod(_spiral_phases[i] + _CHARGE_SPEED * delta, 1.0)
        var t: float = _spiral_phases[i]
        var angle := (TAU / count) * i + t * TAU * _CHARGE_TURNS
        var r := lerpf(outer_r, 0.0, t)
        _draw_orbs.append({
            "pos":    Vector2(cos(angle) * r, sin(angle) * r + _CHARGE_CENTER_Y),
            "color":  Color(col.r, col.g, col.b, col.a * (1.0 - t * t)),
            "radius": size,
        })

    var big_count := _CHARGE_BIG_COUNT_L2 if level == 2 else _CHARGE_BIG_COUNT_L3
    var big_size  := _CHARGE_BIG_SIZE_L2  if level == 2 else _CHARGE_BIG_SIZE_L3
    for i in big_count:
        _spiral_phases_big[i] = fmod(_spiral_phases_big[i] + _CHARGE_BIG_SPEED * delta, 1.0)
        var t: float = _spiral_phases_big[i]
        var angle := (TAU / big_count) * i + t * TAU * _CHARGE_TURNS
        var r := lerpf(outer_r * 1.1, 0.0, t)
        _draw_orbs.append({
            "pos":    Vector2(cos(angle) * r, sin(angle) * r + _CHARGE_CENTER_Y),
            "color":  Color(col.r, col.g, col.b, col.a * 0.7 * (1.0 - t * t)),
            "radius": big_size,
        })

    _orb_canvas.queue_redraw()

func _on_shoot_finished() -> void:
    if _sprite.animation.begins_with("shoot_"):
        _is_shooting = false

func _update_animation() -> void:
    if not _is_shooting:
        _sprite.flip_h = not facing_right
    if _jump_squat_timer >= 0.0:
        if not _is_shooting:
            _sprite.stop()
            _sprite.animation = "jump"
            _sprite.frame = 0 if _jump_squat_timer < _SQUAT_DURATION * 0.5 else 1
    elif not is_on_floor():
        if not _is_shooting:
            _sprite.stop()
            _sprite.animation = "jump"
            _sprite.frame = 2
    elif _landing_timer > 0.0:
        if not _is_shooting:
            _sprite.stop()
            _sprite.animation = "jump"
            _sprite.frame = 3
    elif _is_shooting:
        pass
    elif velocity.x != 0.0:
        _sprite.play("run")
    else:
        _sprite.play("idle")

static func get_charge_level(timer: float) -> int:
    if timer >= CHARGE_L3_THRESHOLD:
        return 3
    if timer >= CHARGE_L2_THRESHOLD:
        return 2
    return 1

func _fire(level: int) -> void:
    assert(level >= 1 and level <= 3, "charge level deve ser 1, 2 ou 3")
    AudioManager.play_sfx(AudioLibrary.sfx_shoot)
    _is_shooting = true
    _sprite.play("shoot_%d" % level)
    var bullet: ZaelBullet = _BULLET_SCENE.instantiate()
    bullet.damage = BULLET_DAMAGE[level]
    bullet.direction = 1.0 if facing_right else -1.0
    bullet.scale = BULLET_SCALE[level]
    bullet.source_id = GameManager.zael_selected_shot
    get_parent().add_child(bullet)
    var offset_x: float = _SPAWN_OFFSET_X[level] if facing_right else -_SPAWN_OFFSET_X[level]
    bullet.global_position = global_position + Vector2(offset_x, _SPAWN_OFFSET_Y)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        _is_charging = false
        _charge_timer = 0.0
