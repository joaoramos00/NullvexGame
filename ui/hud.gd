extends CanvasLayer

@onready var _hp_bar: Control      = $Control/HPBar
@onready var _lives_label: Label   = $Control/LivesLabel
@onready var _ability_label: Label = $Control/AbilityLabel

const _HP_PER_PIXEL := 4.0   # 1 HP = 4px of bar height
const _BAR_BOTTOM   := 462.0  # bottom edge of bar (fixed, from hud.tscn)

func _ready() -> void:
	_update_lives(GameManager.lives)
	_update_ability(_active_ability())
	GameManager.lives_changed.connect(_update_lives)
	GameManager.character_changed.connect(func(_c): _update_ability(_active_ability()))
	GameManager.max_hp_changed.connect(_update_bar_height)
	_update_bar_height(GameManager.max_hp)

func connect_to_player(player: CharacterBase) -> void:
	player.hp_changed.connect(_update_hp)
	_update_hp(player.current_hp, player.max_hp)

func _update_hp(current: int, maximum: int) -> void:
	_hp_bar.set_hp(current, maximum)

func _update_lives(lives: int) -> void:
	_lives_label.text = "x %d" % lives

func _update_ability(ability: String) -> void:
	_ability_label.text = ability.to_upper()

func _active_ability() -> String:
	if GameManager.active_character == "zael":
		return GameManager.zael_selected_shot
	return GameManager.zara_selected_weapon

func _update_bar_height(max_hp: int) -> void:
	var bar_h := float(max_hp) * _HP_PER_PIXEL
	_hp_bar.offset_top    = _BAR_BOTTOM - bar_h
	_hp_bar.offset_bottom = _BAR_BOTTOM
