# Espinhos de gelo: INSTANT KILL para o player (padrão do projeto — espinho
# mata, como no stage 01). O caminho de dano fica para corpos genéricos/testes.
extends Area2D

@export var instant_kill: bool = true
@export var damage: int = 12

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if instant_kill and body is CharacterBase:
		(body as CharacterBase).kill()
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
