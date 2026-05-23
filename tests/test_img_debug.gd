extends Node

func _ready() -> void:
    test_sprite_data()
    test_tile_data()
    test_initial_state()
    test_char_change_resets_anim()
    test_frame_cycling()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_sprite_data() -> void:
    assert(ImgDebug._SPRITES.size() == 6, "deve ter 6 sprites")
    assert(ImgDebug._SPRITES[0].char == "ZAEL", "índice 0 deve ser ZAEL")
    assert(ImgDebug._SPRITES[0].anim == "Idle", "índice 0 deve ser Idle")
    assert(ImgDebug._SPRITES[0].frames == 8, "Idle deve ter 8 frames")
    assert(ImgDebug._SPRITES[0].fps == 8.0, "Idle deve ter 8.0 fps")
    assert(ImgDebug._SPRITES[4].char == "ZARA", "índice 4 deve ser ZARA")
    assert(ImgDebug._SPRITES[4].anim == "Walk", "índice 4 deve ser Walk")
    print("PASS: sprite_data")

func test_tile_data() -> void:
    assert(ImgDebug._TILESETS.size() == 2, "deve ter 2 tilesets")
    assert(ImgDebug._TILESETS[0].name == "Stage_00T", "índice 0 deve ser Stage_00T")
    assert(ImgDebug._TILESETS[0].cols == 4, "Stage_00T deve ter 4 colunas")
    assert(ImgDebug._TILESETS[0].rows == 4, "Stage_00T deve ter 4 linhas")
    assert(ImgDebug._TILESETS[0].tile_size == 32, "Stage_00T tile_size deve ser 32")
    assert(ImgDebug._TILESETS[1].name == "Stage_01T", "índice 1 deve ser Stage_01T")
    assert(ImgDebug._TILESETS[1].cols == 4, "Stage_01T deve ter 4 colunas")
    assert(ImgDebug._TILESETS[1].rows == 5, "Stage_01T deve ter 5 linhas")
    assert(ImgDebug._TILESETS[1].tile_size == 32, "Stage_01T tile_size deve ser 32")
    assert(ImgDebug._TILE_DESCS.has("Stage_01T:0,0"), "deve ter desc Stage_01T:0,0")
    assert(ImgDebug._TILE_DESCS.has("Stage_01T:0,4"), "deve ter desc Stage_01T:0,4 (parede esquerda)")
    assert(ImgDebug._TILE_DESCS.has("Stage_01T:1,4"), "deve ter desc Stage_01T:1,4 (parede direita)")
    assert(ImgDebug._TILE_DESCS.has("Stage_00T:0,0"), "deve ter desc Stage_00T:0,0")
    print("PASS: tile_data")

func test_initial_state() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    assert(panel._section == "SPRITES", "seção inicial deve ser SPRITES")
    assert(panel._char == "ZAEL", "personagem inicial deve ser ZAEL")
    assert(panel._anim_idx == 0, "anim_idx inicial deve ser 0")
    assert(panel._frame == 0, "frame inicial deve ser 0")
    assert(not panel._paused, "não deve iniciar pausado")
    panel.queue_free()
    print("PASS: initial_state")

func test_char_change_resets_anim() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    panel._select_anim(2)
    assert(panel._anim_idx == 2, "anim_idx deve ser 2")
    panel._select_char("ZARA")
    assert(panel._anim_idx == 0, "trocar personagem deve resetar anim_idx para 0")
    assert(panel._frame == 0, "trocar personagem deve resetar frame para 0")
    panel.queue_free()
    print("PASS: char_change_resets_anim")

func test_frame_cycling() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    # Zael Idle: 8 frames, 8 fps → frame_dur = 0.125s
    panel._select_char("ZAEL")
    panel._select_anim(0)
    panel._frame = 7
    panel._paused = false
    panel._anim_timer = 0.126  # ligeiramente acima de 1/8
    panel._process(0.0)
    assert(panel._frame == 0, "frame 7 deve ciclar para 0 (8 frames total)")
    panel.queue_free()
    print("PASS: frame_cycling")
