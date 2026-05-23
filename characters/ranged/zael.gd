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

const _SPAWN_OFFSET := Vector2(60.0, -10.0)

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

var _charge_timer: float = 0.0
var _is_charging: bool = false
var _is_shooting: bool = false
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
    var jump_tex  := load("res://characters/ranged/ZaelJump.png")     as Texture2D
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
    for i in 9:
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

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if is_dead:
        return
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
    if not is_on_floor():
        if not _is_shooting:
            _sprite.play("jump")
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
    var offset_x := _SPAWN_OFFSET.x if facing_right else -_SPAWN_OFFSET.x
    bullet.global_position = global_position + Vector2(offset_x, _SPAWN_OFFSET.y)

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        _is_charging = false
        _charge_timer = 0.0
