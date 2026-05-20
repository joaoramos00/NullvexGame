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

const _FRAME_W := 48
const _FRAME_H := 48
const _ROW_RIGHT := 2  # RPG Maker MZ row 2 = facing right

# bullet spawn offset from character center
const _SPAWN_OFFSET := Vector2(30.0, -10.0)

var _charge_timer: float = 0.0
var _is_charging: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    super._ready()
    _setup_sprite_frames()

func _setup_sprite_frames() -> void:
    var frames := SpriteFrames.new()
    var walk_tex := load("res://characters/ranged/ZaelAndando.png") as Texture2D
    var fight_tex := load("res://characters/ranged/ZaelLutando.png") as Texture2D
    var fw := _FRAME_W
    var fh := _FRAME_H
    var ry := _ROW_RIGHT * fh  # y = 96

    frames.add_animation("idle")
    frames.set_animation_loop("idle", true)
    frames.set_animation_speed("idle", 1.0)
    var idle_at := AtlasTexture.new()
    idle_at.atlas = walk_tex
    idle_at.region = Rect2(fw, ry, fw, fh)
    frames.add_frame("idle", idle_at)

    frames.add_animation("walk")
    frames.set_animation_loop("walk", true)
    frames.set_animation_speed("walk", 8.0)
    for i in 3:
        var at := AtlasTexture.new()
        at.atlas = walk_tex
        at.region = Rect2(i * fw, ry, fw, fh)
        frames.add_frame("walk", at)

    # jump — single static frame (middle of row 2)
    frames.add_animation("jump")
    frames.set_animation_loop("jump", false)
    frames.set_animation_speed("jump", 1.0)
    var jump_at := AtlasTexture.new()
    jump_at.atlas = walk_tex
    jump_at.region = Rect2(fw, ry, fw, fh)
    frames.add_frame("jump", jump_at)

    # shoot — single static frame from ZaelLutando row 2 (first frame)
    frames.add_animation("shoot")
    frames.set_animation_loop("shoot", false)
    frames.set_animation_speed("shoot", 1.0)
    var shoot_at := AtlasTexture.new()
    shoot_at.atlas = fight_tex
    shoot_at.region = Rect2(0, ry, fw, fh)
    frames.add_frame("shoot", shoot_at)

    _sprite.sprite_frames = frames
    _sprite.play("idle")

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if is_dead:
        return
    _handle_shooting(delta)
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

func _update_animation() -> void:
    _sprite.flip_h = not facing_right
    if not is_on_floor():
        _sprite.play("jump")
    elif _sprite.animation == "shoot" and _sprite.is_playing():
        pass
    elif velocity.x != 0.0:
        _sprite.play("walk")
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
    _sprite.play("shoot")
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
