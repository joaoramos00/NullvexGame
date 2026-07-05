extends Area2D
class_name GravProjectile

# Projétil elétrico compartilhado do roster do stage 03 (molde do fire_projectile).
const TEX := {
	"gravity_bolt": preload("res://characters/enemies/stage_04/gravity_bolt.png"),
	"mass_pulse": preload("res://characters/enemies/stage_04/mass_pulse.png"),
	"orbit_shard": preload("res://characters/enemies/stage_04/orbit_shard.png"),
}

var projectile_velocity: Vector2 = Vector2(300.0, 0.0)
var damage: int = 6
var source_id: String = "stage04_grav"
var variant: String = "gravity_bolt"
var _lifetime: float = 4.0
var _hit := false
var _anim_timer := 0.0
var _frame := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_enemy_shoot)

func setup(velocity_value: Vector2, damage_value: int, source_value := "stage04_grav",
		gravity_value := 0.0, variant_value := "gravity_bolt") -> void:
	projectile_velocity = velocity_value
	damage = damage_value
	source_id = source_value
	gravity = gravity_value
	variant = variant_value
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null and TEX.has(variant):
		spr.texture = TEX[variant]
		spr.hframes = 2
		spr.vframes = 2
		spr.frame = 0

func _physics_process(delta: float) -> void:
	if _hit:
		return
	projectile_velocity.y += gravity * delta
	global_position += projectile_velocity * delta
	rotation = projectile_velocity.angle()
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if spr != null:
		_anim_timer += delta
		if _anim_timer >= 1.0 / 12.0:
			_anim_timer -= 1.0 / 12.0
			_frame = (_frame + 1) % 4
			spr.frame = _frame
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(damage, source_id)
	queue_free()
