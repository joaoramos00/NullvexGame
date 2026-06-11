extends Node

func _ready() -> void:
    test_sprite_data()
    test_tile_data()
    test_tile_descs_complete()
    test_tile_displays_populated()
    test_initial_state()
    test_char_change_resets_anim()
    test_frame_cycling()
    test_platform_tab_shows_panel()
    test_hitbox_section_exists()
    test_hitbox_catalog_loads_collision_scenes()
    test_hitbox_view_inspects_representative_entities()
    test_img_debug_buttons_use_web_safe_text()
    test_movement_enemy_catalog_includes_stage02_enemies()
    test_debug_movement_scene_includes_stage02_enemies()
    test_floor_platform_tiles()
    test_floor_platform_hole_tiles()
    print("ALL TESTS PASSED")
    get_tree().quit(0)

func test_sprite_data() -> void:
    # ZAEL: 9 anims, KAWAGAEL: 1, ZARA: 2, MINIBOSS: 5 = 17 total
    assert(ImgDebug._SPRITES.size() == 17, "deve ter 17 sprites")
    assert(ImgDebug._SPRITES[0].char == "ZAEL", "índice 0 deve ser ZAEL")
    assert(ImgDebug._SPRITES[0].anim == "Idle", "índice 0 deve ser Idle")
    assert(ImgDebug._SPRITES[0].frames == 8, "Idle deve ter 8 frames")
    assert(ImgDebug._SPRITES[0].fps == 8.0, "Idle deve ter 8.0 fps")
    var zara_walk := ImgDebug._SPRITES.filter(func(s): return s.char == "ZARA" and s.anim == "Walk")
    assert(zara_walk.size() == 1, "deve existir sprite ZARA Walk")
    print("PASS: sprite_data")

func test_tile_data() -> void:
    # 2 (stage00) + 6 (stage01) + 5*7 (stages 02-08) = 43 tilesets
    assert(ImgDebug._TILESETS.size() == 43, "deve ter 43 tilesets")
    assert(ImgDebug._TILESETS[0].name == "Stage_00T", "índice 0 deve ser Stage_00T")
    assert(ImgDebug._TILESETS[0].cols == 4, "Stage_00T deve ter 4 colunas")
    assert(ImgDebug._TILESETS[0].rows == 4, "Stage_00T deve ter 4 linhas")
    assert(ImgDebug._TILESETS[0].tile_size == 32, "Stage_00T tile_size deve ser 32")
    assert(ImgDebug._TILESETS[1].name == "Stage_00_glass", "índice 1 deve ser Stage_00_glass")
    assert(ImgDebug._TILE_DESCS.has("Stage_00T:0,0"), "deve ter desc Stage_00T:0,0")
    print("PASS: tile_data")

func test_tile_descs_complete() -> void:
    # Stage_00T tem descs explícitas; zone tilesets usam _ZONE_TILE_DESCS como fallback
    for ts in ImgDebug._TILESETS:
        for row in ts.rows:
            for col in ts.cols:
                var full_key  := "%s:%d,%d" % [ts.name, col, row]
                var coord_key := "%d,%d" % [col, row]
                var ok := ImgDebug._TILE_DESCS.has(full_key) or ImgDebug._ZONE_TILE_DESCS.has(coord_key)
                assert(ok, "faltando desc: " + full_key)
    print("PASS: tile_descs_complete")

func test_tile_displays_populated() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    assert(panel._tile_displays.size() == ImgDebug._TILESETS.size(),
        "_tile_displays deve ter uma entrada por tileset")
    for ts in ImgDebug._TILESETS:
        assert(panel._tile_displays.has(ts.name),
            "_tile_displays deve conter " + ts.name)
    panel.queue_free()
    print("PASS: tile_displays_populated")

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

# Regressão: clicar na aba "Plataformas" deve tornar o painel visível e esconder
# os outros. Bug: show_section (lambda) capturava _plat_panel_ref como null por valor
# antes da atribuição → is_instance_valid() sempre false → aba abria em branco.
func test_platform_tab_shows_panel() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    panel._show_section("TILES")

    assert(panel._plat_panel_ref != null, "_plat_panel_ref deve existir")
    assert(panel._col_panel_ref != null, "_col_panel_ref deve existir")
    assert(panel._plat_panel_ref.get_child_count() > 0,
        "painel Plataformas deve ter controles/tiles")

    var plat_btn := _find_button(panel, "Plataformas")
    assert(plat_btn != null, "botão Plataformas deve existir")
    plat_btn.emit_signal("pressed")
    assert(panel._plat_panel_ref.visible, "aba Plataformas deve ficar visível ao clicar")

    var col_btn := _find_button(panel, "Colisões")
    assert(col_btn != null, "botão Colisões deve existir")
    col_btn.emit_signal("pressed")
    assert(panel._col_panel_ref.visible, "aba Colisões deve ficar visível ao clicar")
    assert(not panel._plat_panel_ref.visible, "Plataformas deve esconder ao trocar de aba")

    panel.queue_free()
    print("PASS: platform_tab_shows_panel")

func test_hitbox_section_exists() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    assert(panel._section_btns.has("HITBOXES"), "ImgDebug deve ter seção HITBOXES")
    panel._show_section("HITBOXES")
    assert(panel._hitboxes_box != null, "HITBOXES deve ter container")
    assert(panel._hitboxes_box.visible, "HITBOXES deve ficar visível ao selecionar")
    panel.queue_free()
    print("PASS: hitbox_section_exists")

func test_hitbox_catalog_loads_collision_scenes() -> void:
    assert(ImgDebug._HITBOX_ENTITIES.size() >= 8, "catálogo de hitboxes deve cobrir várias entidades")
    var groups := {}
    for entry in ImgDebug._HITBOX_ENTITIES:
        assert(entry.has("name"), "entrada hitbox deve ter name")
        assert(entry.has("path"), "entrada hitbox deve ter path")
        assert(entry.has("group"), "entrada hitbox deve ter group")
        groups[entry.group] = true
        var scene := load(entry.path) as PackedScene
        assert(scene != null, "cena hitbox deve carregar: " + entry.path)
        var inst := scene.instantiate()
        assert(_has_collision_shape(inst), "cena hitbox deve ter CollisionShape2D: " + entry.path)
        inst.queue_free()
    for group_name in ["Personagens", "Inimigos", "Bosses", "Projeteis"]:
        assert(groups.has(group_name), "catálogo hitbox deve incluir grupo " + group_name)
    print("PASS: hitbox_catalog_loads_collision_scenes")

func test_hitbox_view_inspects_representative_entities() -> void:
    var view := ImgDebug._HitboxView.new()
    add_child(view)
    for group_name in ["Personagens", "Inimigos", "Bosses", "Projeteis"]:
        var idx := view._find_first_group(group_name)
        assert(idx >= 0, "HitboxView deve encontrar grupo " + group_name)
        view._select_index(idx)
        assert(view._current_instance != null, "HitboxView deve instanciar " + group_name)
        assert(view._shape_infos.size() > 0, "HitboxView deve coletar shapes de " + group_name)
        assert(view._meta_label.text.contains(group_name), "metadata deve indicar grupo " + group_name)
    view.queue_free()
    print("PASS: hitbox_view_inspects_representative_entities")

func test_img_debug_buttons_use_web_safe_text() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    panel._show_section("MOVIMENTOS")
    _assert_buttons_without_fallback_symbols(panel)
    panel.queue_free()

    var scene := load("res://ui/debug_movement.tscn") as PackedScene
    assert(scene != null, "debug_movement.tscn deve carregar")
    var movement_panel = scene.instantiate()
    add_child(movement_panel)
    _assert_buttons_without_fallback_symbols(movement_panel)
    movement_panel.queue_free()
    print("PASS: img_debug_buttons_use_web_safe_text")

func test_movement_enemy_catalog_includes_stage02_enemies() -> void:
    for enemy_name in ["Ice Grunt", "Ice Flyer", "Ice Archer", "Frost Turret", "Cryo Bomber", "Glacier Shield", "Ice Wisp", "Ice MiniBoss"]:
        assert(ImgDebug._MovView._ENEMY_NAMES.has(enemy_name), "Movimentos deve incluir " + enemy_name)
    for path in ImgDebug._MovView._ENEMY_PATHS:
        if path.contains("stage_02"):
            assert(load(path) != null, "caminho de inimigo stage02 deve carregar: " + path)
    assert(ImgDebug._MovView._ENEMY_NAMES.size() == ImgDebug._MovView._ENEMY_PATHS.size(), "nomes e caminhos de inimigos devem ter o mesmo tamanho")
    assert(ImgDebug._MovView._ENEMY_Y.size() == ImgDebug._MovView._ENEMY_PATHS.size(), "offsets Y devem acompanhar caminhos de inimigos")
    print("PASS: movement_enemy_catalog_includes_stage02_enemies")

func test_debug_movement_scene_includes_stage02_enemies() -> void:
    var scene := load("res://ui/debug_movement.tscn") as PackedScene
    assert(scene != null, "debug_movement.tscn deve carregar")
    var panel = scene.instantiate()
    add_child(panel)
    for enemy_name in ["Ice Grunt", "Ice Flyer", "Ice Archer", "Frost Turret", "Cryo Bomber", "Glacier Shield", "Ice Wisp", "Ice MiniBoss"]:
        assert(panel.get("_ENEMY_NAMES").has(enemy_name), "DebugMovement deve incluir " + enemy_name)
    for path in panel.get("_ENEMY_PATHS"):
        if path.contains("stage_02"):
            assert(load(path) != null, "DebugMovement caminho stage02 deve carregar: " + path)
    assert(panel.get("_ENEMY_NAMES").size() == panel.get("_ENEMY_PATHS").size(), "DebugMovement nomes e caminhos devem ter o mesmo tamanho")
    assert(panel.get("_ENEMY_Y").size() == panel.get("_ENEMY_PATHS").size(), "DebugMovement offsets Y devem acompanhar caminhos")
    panel.queue_free()
    print("PASS: debug_movement_scene_includes_stage02_enemies")

# Modo "Piso+Plat": valida o tile de cada célula-chave do heightfield
# (cols=3 largura da plataforma, rows=2 elevação; lados=3, prof.=2 → grid 9x4).
func test_floor_platform_tiles() -> void:
    var pv = ImgDebug._PlatformView.new()
    pv.mode = "floor_platform"
    pv.cols = 3   # largura da plataforma
    pv.rows = 2   # elevação acima do piso

    var grid: Vector2i = pv._fp_grid()
    assert(grid == Vector2i(9, 4), "grid deve ser 9x4, veio " + str(grid))

    # Topo da plataforma
    assert(pv._fp_tile(3, 0) == Vector2i(1, 3), "canto sup-esq da plataforma")
    assert(pv._fp_tile(4, 0) == Vector2i(3, 0), "topo reto da plataforma (TOP)")
    assert(pv._fp_tile(5, 0) == Vector2i(0, 0), "canto sup-dir da plataforma")
    # Paredes da plataforma (eixos invertidos: esq=(1,0), dir=(3,2))
    assert(pv._fp_tile(3, 1) == Vector2i(1, 0), "parede esquerda visual da plataforma")
    assert(pv._fp_tile(5, 1) == Vector2i(3, 2), "parede direita visual da plataforma")
    # Junções côncavas (degrau encontra o piso)
    assert(pv._fp_tile(3, 2) == Vector2i(1, 1), "junção esquerda côncava")
    assert(pv._fp_tile(5, 2) == Vector2i(2, 0), "junção direita côncava")
    # Piso lateral
    assert(pv._fp_tile(1, 2) == Vector2i(3, 0), "superfície do piso (TOP)")
    assert(pv._fp_tile(0, 2) == Vector2i(1, 3), "canto sup-esq do piso esquerdo")
    # Miolo e base
    assert(pv._fp_tile(4, 2) == Vector2i(2, 1), "miolo preenchido (FILL)")
    assert(pv._fp_tile(4, 3) == Vector2i(1, 2), "base da plataforma (BOTTOM)")

    pv.free()
    print("PASS: floor_platform_tiles")

# Modo "Piso+Buraco": um lado vira abismo (vazio total); o penhasco da plataforma
# sai do marching-squares. mirror_hole alterna o lado. Grid igual ao floor_platform (9x4).
func test_floor_platform_hole_tiles() -> void:
    var pv = ImgDebug._PlatformView.new()
    pv.mode = "floor_platform_hole"
    pv.cols = 3   # largura da plataforma
    pv.rows = 2   # elevação acima do piso

    assert(pv._fp_grid() == Vector2i(9, 4), "grid deve ser 9x4 (igual floor_platform)")

    # Buraco à direita (padrão: mirror_hole = false)
    pv.mirror_hole = false
    assert(pv._fp_hole_dir() == 1, "hole_dir deve ser +1 (buraco à direita)")
    assert(not pv._fp_solid(6, 2), "coluna 6 (lado direito) deve ser vazia")
    assert(not pv._fp_solid(8, 0), "coluna 8 deve ser vazia")
    assert(pv._fp_tile(5, 0) == Vector2i(0, 0), "topo do penhasco direito = (0,0)")
    assert(pv._fp_tile(5, 1) == Vector2i(3, 2), "lateral do penhasco direito = (3,2)")
    assert(pv._fp_solid(0, 2), "piso esquerdo deve continuar sólido")
    assert(pv._fp_tile(1, 2) == Vector2i(3, 0), "superfície do piso esquerdo (TOP)")
    assert(pv._fp_tile(0, 2) == Vector2i(1, 3), "canto sup-esq do piso esquerdo sobrevivente = (1,3)")

    # Buraco à esquerda (mirror_hole = true)
    pv.mirror_hole = true
    assert(pv._fp_hole_dir() == -1, "hole_dir deve ser -1 (buraco à esquerda)")
    assert(not pv._fp_solid(2, 2), "coluna 2 (lado esquerdo) deve ser vazia")
    assert(not pv._fp_solid(0, 0), "coluna 0 deve ser vazia")
    assert(pv._fp_tile(3, 0) == Vector2i(1, 3), "topo do penhasco esquerdo = (1,3)")
    assert(pv._fp_tile(3, 1) == Vector2i(1, 0), "lateral do penhasco esquerdo = (1,0)")
    assert(pv._fp_solid(8, 2), "piso direito deve continuar sólido")
    assert(pv._fp_tile(7, 2) == Vector2i(3, 0), "superfície do piso direito (TOP)")
    assert(pv._fp_tile(8, 2) == Vector2i(0, 0), "canto sup-dir do piso direito sobrevivente = (0,0)")

    # Modo clássico não afetado
    pv.mode = "floor_platform"
    assert(pv._fp_hole_dir() == 0, "floor_platform clássico → hole_dir 0")
    assert(pv._fp_solid(6, 2), "no modo clássico, lado direito volta a ser piso")

    pv.free()
    print("PASS: floor_platform_hole_tiles")

func _find_button(node: Node, text: String) -> Button:
    if node is Button and (node as Button).text == text:
        return node
    for child in node.get_children():
        var found := _find_button(child, text)
        if found != null:
            return found
    return null

func _has_collision_shape(node: Node) -> bool:
    if node is CollisionShape2D:
        return true
    for child in node.get_children():
        if _has_collision_shape(child):
            return true
    return false

func _assert_buttons_without_fallback_symbols(node: Node) -> void:
    var forbidden := ["✕", "↺", "◄", "►", "▶", "⏸", "←", "→", "↻"]
    if node is Button:
        var text := (node as Button).text
        for symbol in forbidden:
            assert(not text.contains(symbol), "botão usa símbolo sem fallback Web: " + text)
    for child in node.get_children():
        _assert_buttons_without_fallback_symbols(child)
