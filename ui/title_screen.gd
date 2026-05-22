extends Control

var _debug_panel: Node = null

func _ready() -> void:
    $VBox/ContinueButton.disabled = not GameManager.has_save()
    $VBox/NewGameButton.pressed.connect(_on_new_game_pressed)
    $VBox/ContinueButton.pressed.connect(_on_continue_pressed)
    $VBox/QuitButton.pressed.connect(_on_quit_pressed)
    $VBox/ImgDebugButton.pressed.connect(_on_img_debug_pressed)

func _on_img_debug_pressed() -> void:
    if is_instance_valid(_debug_panel):
        _debug_panel.queue_free()
        _debug_panel = null
    else:
        call_deferred("_build_sprite_debug")

func _build_sprite_debug() -> void:
    var vp := get_viewport_rect().size

    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.z_index = 100
    add_child(root)
    _debug_panel = root

    var bg := ColorRect.new()
    bg.color = Color(0, 0, 0, 0.82)
    bg.position = Vector2(0, vp.y - 380)
    bg.size = Vector2(vp.x, 380)
    root.add_child(bg)

    var vbox := VBoxContainer.new()
    vbox.position = Vector2(0, vp.y - 377)
    vbox.size = Vector2(vp.x, 374)
    vbox.add_theme_constant_override("separation", 6)
    root.add_child(vbox)

    var shoot_z := load("res://characters/ranged/ZaelAtirando.png") as Texture2D

    var shoot_frames: Array = []
    for i in 9:
        shoot_frames.append(["shot[%d]" % i, shoot_z, i * 68])

    _add_char_row(vbox, "ZAEL SHOT", shoot_frames)

func _add_char_row(parent: VBoxContainer, char_name: String, frame_data: Array) -> void:
    var lbl := Label.new()
    lbl.text = char_name
    lbl.add_theme_font_size_override("font_size", 18)
    lbl.add_theme_color_override("font_color", Color(1, 1, 0))
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    parent.add_child(lbl)

    var hbox := HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 8)
    hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    parent.add_child(hbox)

    for entry in frame_data:
        var frame_name: String = entry[0]
        var tex: Texture2D     = entry[1]
        var atlas_x: int       = entry[2]

        var col := VBoxContainer.new()
        col.add_theme_constant_override("separation", 2)
        hbox.add_child(col)

        var panel := PanelContainer.new()
        var style := StyleBoxFlat.new()
        style.bg_color = Color(0.08, 0.08, 0.08)
        style.border_color = Color(1, 1, 0)
        style.set_border_width_all(5)
        style.content_margin_left   = 3
        style.content_margin_right  = 3
        style.content_margin_top    = 3
        style.content_margin_bottom = 3
        panel.add_theme_stylebox_override("panel", style)
        col.add_child(panel)

        var rect := TextureRect.new()
        rect.custom_minimum_size = Vector2(112, 112)
        rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        if tex != null:
            var at := AtlasTexture.new()
            at.atlas = tex
            at.filter_clip = true
            at.region = Rect2(atlas_x, 0, 68, 68)
            rect.texture = at
        panel.add_child(rect)

        var name_lbl := Label.new()
        name_lbl.text = frame_name
        name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_lbl.add_theme_font_size_override("font_size", 13)
        name_lbl.add_theme_color_override("font_color", Color(1, 1, 0.4))
        col.add_child(name_lbl)

func _on_new_game_pressed() -> void:
    GameManager.reset()
    get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_continue_pressed() -> void:
    if GameManager.load_game():
        get_tree().change_scene_to_file("res://ui/stage_select.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()
