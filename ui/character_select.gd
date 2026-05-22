extends Control

signal character_chosen(character: String)

const _FRAME_W := 68
const _FRAME_H := 68
const _ROW_RIGHT := 0
const _ANIM_SPEED := 8.0

var _standalone: bool = false
var _zael_frames: Array[AtlasTexture] = []
var _zara_frames: Array[AtlasTexture] = []
var _frame_timer: float = 0.0
var _current_frame: int = 0

@onready var _stage_label: Label = $Panel/VBox/StageLabel
@onready var _zael_preview: TextureRect = $Panel/VBox/HBox/ZaelCol/ZaelPreview
@onready var _zara_preview: TextureRect = $Panel/VBox/HBox/ZaraCol/ZaraPreview

func _ready() -> void:
    _standalone = get_parent() == get_tree().root
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    if _standalone:
        _stage_label.text = "New Game"
        visible = true
    else:
        visible = false
    $Panel/VBox/HBox/ZaelCol/ZaelButton.pressed.connect(func(): _choose("zael"))
    $Panel/VBox/HBox/ZaraCol/ZaraButton.pressed.connect(func(): _choose("zara"))
    $Panel/VBox/CancelButton.pressed.connect(_on_cancel)
    _setup_previews()

func _setup_previews() -> void:
    var zael_tex := load("res://characters/ranged/ZaelCorrendo.png") as Texture2D
    var zara_tex := load("res://characters/melee/ZaraCorrendo.png") as Texture2D
    var ry := _ROW_RIGHT * _FRAME_H
    for i in 3:
        var at := AtlasTexture.new()
        at.atlas = zael_tex
        at.filter_clip = true
        at.region = Rect2(i * _FRAME_W, ry, _FRAME_W, _FRAME_H)
        _zael_frames.append(at)
        var at2 := AtlasTexture.new()
        at2.atlas = zara_tex
        at2.filter_clip = true
        at2.region = Rect2(i * _FRAME_W, ry, _FRAME_W, _FRAME_H)
        _zara_frames.append(at2)
    _zael_preview.texture = _zael_frames[0]
    _zara_preview.texture = _zara_frames[0]

func _process(delta: float) -> void:
    if not visible or _zael_frames.is_empty():
        return
    _frame_timer += delta
    if _frame_timer >= 1.0 / _ANIM_SPEED:
        _frame_timer = 0.0
        _current_frame = (_current_frame + 1) % 3
        _zael_preview.texture = _zael_frames[_current_frame]
        _zara_preview.texture = _zara_frames[_current_frame]

func show_for_stage(stage_id: int, boss_name: String) -> void:
    _stage_label.text = "Stage %d — %s" % [stage_id, boss_name]
    visible = true

func _choose(character: String) -> void:
    if _standalone:
        GameManager.set_active_character(character)
        StageManager.load_stage(0)
    else:
        visible = false
        character_chosen.emit(character)

func _on_cancel() -> void:
    if _standalone:
        get_tree().change_scene_to_file("res://ui/title_screen.tscn")
    else:
        visible = false
