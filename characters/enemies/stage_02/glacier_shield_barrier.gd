extends Area2D
class_name GlacierShieldBarrier

func take_damage(amount: int, _source: String = "") -> void:
	var owner := get_parent()
	if owner != null and owner.has_method("take_damage"):
		owner.take_damage(amount, "shield_front")
