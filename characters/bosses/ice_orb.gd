extends Area2D
class_name IceOrb

# Projétil do 3º ataque do Cryovex: bola espinhosa de gelo formada na boca
# durante a janela de boca aberta do Bite (ver ice_orb_charge.gd) e lançada
# em linha reta mirada no player. Sprite = último frame da animação de
# convergência (PixelLab), usado como projétil estático + giro constante
# (silhueta arredondada, não precisa alinhar rotação com a velocidade como
# o ice_shard em formato de ponta de flecha).
const TEX := preload("res://characters/bosses/cryovex/fx_ice_orb_projectile.png")
const _SPIN_SPEED := 6.0  # rad/s

var projectile_velocity: Vector2 = Vector2(200.0, 0.0)
var damage: int = 14
var source_id: String = "cryovex"
var _lifetime: float = 4.0
var _hit := false

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	AudioManager.play_sfx(AudioLibrary.sfx_boss_shoot)
	_sprite.texture = TEX

func _physics_process(delta: float) -> void:
	if _hit:
		return
	global_position += projectile_velocity * delta
	rotation += _SPIN_SPEED * delta
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
