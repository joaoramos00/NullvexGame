extends CanvasLayer

@onready var _hp_bar: ProgressBar = $Control/HPBar
@onready var _hp_label: Label = $Control/HPLabel
@onready var _lives_label: Label = $Control/LivesLabel
@onready var _ability_label: Label = $Control/AbilityLabel

func _ready() -> void:
    _update_lives(GameManager.lives)
    _update_ability(_active_ability())
    GameManager.lives_changed.connect(_update_lives)
    GameManager.character_changed.connect(func(_c): _update_ability(_active_ability()))

func connect_to_player(player: CharacterBase) -> void:
    player.hp_changed.connect(_update_hp)
    _update_hp(player.current_hp, player.max_hp)

func _update_hp(current: int, maximum: int) -> void:
    _hp_bar.max_value = maximum
    _hp_bar.value = current
    _hp_label.text = "%d / %d" % [current, maximum]

func _update_lives(lives: int) -> void:
    _lives_label.text = "LIVES: %d" % lives

func _update_ability(ability: String) -> void:
    _ability_label.text = ability.to_upper()

func _active_ability() -> String:
    if GameManager.active_character == "zael":
        return GameManager.zael_selected_shot
    return GameManager.zara_selected_weapon
