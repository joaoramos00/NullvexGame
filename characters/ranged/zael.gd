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

const _SPAWN_OFFSET := Vector2(60.0, -28.0)

# Espiral: 4 bolinhas sobem em loop, somem perto do topo e reaparecem embaixo
const _SPIRAL_COUNT  := 4
const _SPIRAL_SPEED  := 0.7   # loops por segundo
const _SPIRAL_RADIUS := 16.0  # raio horizontal
const _SPIRAL_BOTTOM := 22.0  # y inicial (abaixo do centro)
const _SPIRAL_TOP    := -46.0 # y final (acima da cabeça)
const _SPIRAL_TURNS  := 1.5   # rotações ao longo da subida
const _SPIRAL_COLOR  := Color(1.0, 0.88, 0.2, 0.55)
const _SPIRAL_RADIUS_PX := 5.0

class _ChargeOrb extends Node2D:
    var orb_color := Color(1.0, 0.88, 0.2, 0.55)
    var orb_radius := 5.0
    func _draw() -> void:
        draw_circle(Vector2.ZERO, orb_radius, orb_color)

var _charge_timer: float = 0.0
var _is_charging: bool = false
var _is_shooting: bool = false
var _spiral_phases: Array = [0.0, 0.25, 0.5, 0.75]
var _charge_orbs: Array = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    super._ready()
    _setup_sprite_frames()
    _sprite.animation_finished.connect(_on_shoot_finished)
    _setup_charge_orbs()

func _setup_charge_orbs() -> void:
    for i in _SPIRAL_COUNT:
        var orb := _ChargeOrb.new()
        orb.orb_color = _SPIRAL_COLOR
        orb.orb_radius = _SPIRAL_RADIUS_PX
        orb.visible = false
        orb.z_index = 2
        add_child(orb)
        _charge_orbs.append(orb)

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
    var show := _is_charging and get_charge_level(_charge_timer) >= 2
    if not show:
        for orb in _charge_orbs:
            (orb as Node2D).visible = false
        return

    for i in _SPIRAL_COUNT:
        _spiral_phases[i] = fmod(_spiral_phases[i] + _SPIRAL_SPEED * delta, 1.0)
        var t: float = _spiral_phases[i]
        var orb := _charge_orbs[i] as Node2D
        # fade out no topo (últimos 15% do ciclo)
        var alpha_mul := clampf(1.0 - (t - 0.85) / 0.15, 0.0, 1.0)
        orb.visible = alpha_mul > 0.0
        if orb.visible:
            var angle := (TAU / _SPIRAL_COUNT) * i + t * TAU * _SPIRAL_TURNS
            var x := sin(angle) * _SPIRAL_RADIUS
            var y := lerpf(_SPIRAL_BOTTOM, _SPIRAL_TOP, t)
            orb.position = Vector2(x, y)
            (orb as _ChargeOrb).orb_color = Color(
                _SPIRAL_COLOR.r, _SPIRAL_COLOR.g, _SPIRAL_COLOR.b,
                _SPIRAL_COLOR.a * alpha_mul
            )
            orb.queue_redraw()

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
