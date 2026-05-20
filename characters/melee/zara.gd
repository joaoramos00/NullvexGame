extends CharacterBase
class_name Zara

const COMBO_WINDOW := 0.5
const HITBOX_OFFSET := Vector2(30, -8)
const COMBO_DAMAGE := [0, 8, 12, 20]

const _HITBOX_SCENE := preload("res://characters/melee/zara_hitbox.tscn")

var _combo_step: int = 0
var _combo_timer: float = 0.0
var _is_attacking: bool = false
var _attack_timer: float = 0.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	_handle_combo(delta)

func _draw() -> void:
	draw_rect(Rect2(-10, -28, 20, 48), Color.MAGENTA)

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
	var hitbox: ZaraHitbox = _HITBOX_SCENE.instantiate()
	hitbox.damage = COMBO_DAMAGE[strike_num]
	hitbox.source_id = GameManager.zara_selected_weapon
	var offset_x := HITBOX_OFFSET.x if facing_right else -HITBOX_OFFSET.x
	get_parent().add_child(hitbox)
	hitbox.global_position = global_position + Vector2(offset_x, HITBOX_OFFSET.y)
