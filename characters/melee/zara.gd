extends CharacterBase
class_name Zara

const COMBO_WINDOW := 0.5
const HITBOX_OFFSET := Vector2(30, -8)
const COMBO_DAMAGE := [0, 8, 12, 20]

const _HITBOX_SCENE := preload("res://characters/melee/zara_hitbox.tscn")

const _FRAME_W := 68
const _FRAME_H := 68
const _ROW_RIGHT := 0

var _combo_step: int = 0
var _combo_timer: float = 0.0
var _is_attacking: bool = false
var _attack_timer: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    super._ready()
    _setup_sprite_frames()

func _setup_sprite_frames() -> void:
    var frames := SpriteFrames.new()
    var tex := load("res://characters/melee/ZaraAndando.png") as Texture2D
    var fw := _FRAME_W
    var fh := _FRAME_H
    var ry := _ROW_RIGHT * fh  # y = 0

    frames.add_animation("idle")
    frames.set_animation_loop("idle", true)
    frames.set_animation_speed("idle", 1.0)
    var idle_at := AtlasTexture.new()
    idle_at.atlas = tex
    idle_at.region = Rect2(2 * fw, ry, fw, fh)
    frames.add_frame("idle", idle_at)

    frames.add_animation("walk")
    frames.set_animation_loop("walk", true)
    frames.set_animation_speed("walk", 8.0)
    for i in 5:
        var at := AtlasTexture.new()
        at.atlas = tex
        at.region = Rect2(i * fw, ry, fw, fh)
        frames.add_frame("walk", at)

    # jump — middle walk frame
    frames.add_animation("jump")
    frames.set_animation_loop("jump", false)
    frames.set_animation_speed("jump", 1.0)
    var jump_at := AtlasTexture.new()
    jump_at.atlas = tex
    jump_at.region = Rect2(2 * fw, ry, fw, fh)
    frames.add_frame("jump", jump_at)

    # attack — first walk frame as placeholder
    frames.add_animation("attack")
    frames.set_animation_loop("attack", false)
    frames.set_animation_speed("attack", 1.0)
    var attack_at := AtlasTexture.new()
    attack_at.atlas = tex
    attack_at.region = Rect2(0, ry, fw, fh)
    frames.add_frame("attack", attack_at)

    _sprite.sprite_frames = frames
    _sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sprite.play("idle")

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if is_dead:
        return
    _handle_combo(delta)
    _update_animation()

func _update_animation() -> void:
    var attacking := _sprite.animation == "attack" and _sprite.is_playing()
    if not attacking:
        _sprite.flip_h = not facing_right
    if not is_on_floor():
        _sprite.play("jump")
    elif attacking:
        pass
    elif velocity.x != 0.0:
        _sprite.play("walk")
    else:
        _sprite.play("idle")

func _handle_combo(delta: float) -> void:
    if is_dead:
        return
    if _is_attacking:
        _attack_timer -= delta
        if _attack_timer <= 0.0:
            _is_attacking = false
    if _combo_step > 0 and not _is_attacking:
        _combo_timer += delta
        if _combo_timer >= COMBO_WINDOW:
            _combo_step = 0
            _combo_timer = 0.0
    if Input.is_action_just_pressed("attack") and not _is_attacking:
        _strike()

static func next_combo_step(step: int) -> int:
    return (step + 1) % 3

func _strike() -> void:
    AudioManager.play_sfx(AudioLibrary.sfx_attack)
    var strike_num := _combo_step + 1
    _combo_step = strike_num % 3
    _combo_timer = 0.0
    _is_attacking = true
    _attack_timer = ZaraHitbox.ATTACK_DURATION
    _sprite.play("attack")
    var hitbox: ZaraHitbox = _HITBOX_SCENE.instantiate()
    hitbox.damage = COMBO_DAMAGE[strike_num]
    hitbox.source_id = GameManager.zara_selected_weapon
    var offset_x := HITBOX_OFFSET.x if facing_right else -HITBOX_OFFSET.x
    get_parent().add_child(hitbox)
    hitbox.global_position = global_position + Vector2(offset_x, HITBOX_OFFSET.y)
