extends Area2D
class_name ZaelBullet

const SPEED := 500.0

const _BUSTER_TEX := [
	preload("res://assets/generated/zael_buster/buster_L1.png"),
	preload("res://assets/generated/zael_buster/buster_L2.png"),
	preload("res://assets/generated/zael_buster/buster_L3.png"),
]

var damage: int = 5
var direction: float = 1.0
var source_id: String = "single"
var level: int = 1
var _hit: bool = false
var _deflected: bool = false
var _deflect_velocity: Vector2 = Vector2.ZERO
var _sprite: AnimatedSprite2D

func _ready() -> void:
	add_to_group("player_bullet")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	$Timer.timeout.connect(queue_free)
	_setup_anim()

func _setup_anim() -> void:
	var tex: Texture2D = _BUSTER_TEX[clampi(level, 1, 3) - 1]
	var sf := SpriteFrames.new()
	sf.add_animation("fly")
	sf.set_animation_loop("fly", true)
	sf.set_animation_speed("fly", 12.0)
	for i in 9:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.filter_clip = true
		at.region = Rect2(i * 32, 0, 32, 32)
		sf.add_frame("fly", at)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = sf
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.flip_h = direction < 0.0
	add_child(_sprite)
	_sprite.play("fly")

func _physics_process(delta: float) -> void:
	if _hit:
		return
	if _deflected:
		_deflect_velocity.y += 980.0 * delta
		global_position += _deflect_velocity * delta
		for area in get_overlapping_areas():
			_on_area_entered(area)
			return
		for body in get_overlapping_bodies():
			_on_body_entered(body)
			return
		return
	global_position.x += direction * SPEED * delta
	# Checa áreas primeiro (hurtboxes têm prioridade sobre paredes)
	for area in get_overlapping_areas():
		_on_area_entered(area)
		return
	for body in get_overlapping_bodies():
		_on_body_entered(body)
		return

func deflect_upward() -> void:
	if _deflected:
		return
	_deflected = true
	source_id = "deflected"
	_deflect_velocity = Vector2(direction * SPEED, -SPEED)
	_sprite.flip_h = direction < 0.0

func _on_area_entered(area: Area2D) -> void:
	if _hit:
		return
	if area.has_method("take_damage"):
		_hit = true
		area.take_damage(damage, source_id)
		$Timer.stop()
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	else:
		AudioManager.play_sfx(AudioLibrary.sfx_shot_wall)   # bateu na parede/chão
	$Timer.stop()
	queue_free()
