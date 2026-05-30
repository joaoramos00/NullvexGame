# Hurtbox da cabeça do MiniBoss — única zona que recebe dano.
extends Area2D

func take_damage(amount: int, source: String = "") -> void:
	var parent := get_parent()
	if parent.has_method("head_take_damage"):
		parent.head_take_damage(amount, source)
