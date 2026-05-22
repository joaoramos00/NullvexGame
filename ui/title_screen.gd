extends Control

func _ready() -> void:
    $VBox/ContinueButton.disabled = not GameManager.has_save()
    $VBox/NewGameButton.pressed.connect(_on_new_game_pressed)
    $VBox/ContinueButton.pressed.connect(_on_continue_pressed)
    $VBox/QuitButton.pressed.connect(_on_quit_pressed)
    _build_sprite_debug()

func _build_sprite_debug() -> void:
    var walk_z  := load("res://characters/ranged/ZaelAndando.png")  as Texture2D
    var run_z   := load("res://characters/ranged/ZaelCorrendo.png") as Texture2D
    var shoot_z := load("res://characters/ranged/ZaelAtirando.png") as Texture2D
    var walk_a  := load("res://characters/melee/ZaraAndando.png")   as Texture2D
    var run_a   := load("res://characters/melee/ZaraCorrendo.png")  as Texture2D

    # [frame_name, texture, atlas_x]
    var zael_frames: Array = [
        ["idle",     walk_z,  2 * 68],
        ["run[0]",   run_z,   0 * 68],
        ["run[1]",   run_z,   1 * 68],
        ["run[2]",   run_z,   2 * 68],
        ["jump",     walk_z,  2 * 68],
        ["shoot[0]", shoot_z, 0 * 68],
        ["shoot[1]", shoot_z, 1 * 68],
        ["shoot[2]", shoot_z, 2 * 68],
    ]
    var zara_frames: Array = [
        ["idle",     walk_a, 2 * 68],
        ["run[0]",   run_a,  0 * 68],
        ["run[1]",   run_a,  1 * 68],
        ["run[2]",   run_a,  2 * 68],
        ["jump",     walk_a, 2 * 68],
        ["attack",   walk_a, 0 * 68],
    ]

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    root.offset_top = -380
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    var vbox := VBoxContainer.new()
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vbox.add_theme_constant_override("separation", 12)
    root.add_child(vbox)

    _add_char_row(vbox, "ZAEL", zael_frames)
    _add_char_row(vbox, "ZARA", zara_frames)

func _add_char_row(parent: VBoxContainer, char_name: String, frame_data: Array) -> void:
    var lbl := Label.new()
    lbl.text = char_name
    lbl.add_theme_font_size_override("font_size", 22)
    lbl.add_theme_color_override("font_color", Color(1, 1, 0))
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    parent.add_child(lbl)

    var hbox := HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 10)
    hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    parent.add_child(hbox)

    for entry in frame_data:
        var frame_name: String = entry[0]
        var tex: Texture2D     = entry[1]
        var atlas_x: int       = entry[2]

        var col := VBoxContainer.new()
        col.add_theme_constant_override("separation", 4)
        hbox.add_child(col)

        var panel := PanelContainer.new()
        var style := StyleBoxFlat.new()
        style.bg_color = Color(0, 0, 0, 0.6)
        style.border_color = Color(1, 1, 0)
        style.set_border_width_all(6)
        panel.add_theme_stylebox_override("panel", style)
        col.add_child(panel)

        var at := AtlasTexture.new()
        at.atlas = tex
        at.filter_clip = true
        at.region = Rect2(atlas_x, 0, 68, 68)
        var rect := TextureRect.new()
        rect.texture = at
        rect.custom_minimum_size = Vector2(136, 136)
        rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        panel.add_child(rect)

        var name_lbl := Label.new()
        name_lbl.text = frame_name
        name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_lbl.add_theme_font_size_override("font_size", 16)
        name_lbl.add_theme_color_override("font_color", Color(1, 1, 0.5))
        col.add_child(name_lbl)

func _on_new_game_pressed() -> void:
    GameManager.reset()
    get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_continue_pressed() -> void:
    if GameManager.load_game():
        get_tree().change_scene_to_file("res://ui/stage_select.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()
