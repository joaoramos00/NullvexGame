extends Area2D
class_name Collectible

enum Type { HEART, SUBTANK, ARMOR_ZAEL, ARMOR_ZARA, SHOT_ZAEL, WEAPON_ZARA }

const COLORS := {
    Type.HEART:       Color.RED,
    Type.SUBTANK:     Color.CYAN,
    Type.ARMOR_ZAEL:  Color.GOLD,
    Type.ARMOR_ZARA:  Color.ORANGE,
    Type.SHOT_ZAEL:   Color.GREEN,
    Type.WEAPON_ZARA: Color.PURPLE,
}

@export var collectible_type: Type = Type.HEART
@export var stage_id: int = 0
@export var subtank_index: int = 0
@export var armor_piece: String = ""
@export var ability_id: String = ""

func _ready() -> void:
    if _already_collected():
        queue_free()
        return
    body_entered.connect(_on_body_entered)
    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2.ZERO, 12.0, COLORS.get(collectible_type, Color.WHITE))

func _on_body_entered(body: Node) -> void:
    if not body is CharacterBase:
        return
    _collect()
    queue_free()

func _collect() -> void:
    match collectible_type:
        Type.HEART:
            GameManager.collect_heart(stage_id)
        Type.SUBTANK:
            GameManager.collect_subtank(subtank_index)
        Type.ARMOR_ZAEL:
            GameManager.set_zael_armor(armor_piece, true)
        Type.ARMOR_ZARA:
            GameManager.set_zara_armor(armor_piece, true)
        Type.SHOT_ZAEL:
            GameManager.unlock_zael_shot(ability_id)
        Type.WEAPON_ZARA:
            GameManager.unlock_zara_weapon(ability_id)

func _already_collected() -> bool:
    match collectible_type:
        Type.HEART:
            return GameManager.collected_hearts.has(stage_id)
        Type.SUBTANK:
            return GameManager.collected_subtanks.has(subtank_index)
        Type.ARMOR_ZAEL:
            return GameManager.zael_armor.get(armor_piece, false)
        Type.ARMOR_ZARA:
            return GameManager.zara_armor.get(armor_piece, false)
        Type.SHOT_ZAEL:
            return GameManager.zael_shot_types.has(ability_id)
        Type.WEAPON_ZARA:
            return GameManager.zara_weapons.has(ability_id)
    return false
