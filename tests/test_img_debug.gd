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
    test_hitbox_view_controls_exist()
    test_hitbox_view_hierarchical_selectors()
    test_hitbox_view_frame_selector_updates_sprite_and_glacier_barrier()
    test_hitbox_view_projectile_row_tracks_stage02_release_frames()
    test_hitbox_view_has_floor()
    test_hitbox_view_draws_entities_above_floor_tiles()
    test_hitbox_view_aligns_character_collision_bottom_to_floor()
    test_hitbox_view_freezes_inspected_entities()
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
        assert(entry.has("kind"), "entrada hitbox deve ter kind")
        assert(entry.has("stage"), "entrada hitbox deve ter stage")
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

func test_hitbox_view_controls_exist() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    panel._show_section("HITBOXES")
    assert(panel._hitbox_view != null, "ImgDebug deve guardar referencia da HitboxView")
    for text in ["Todos", "Personagens", "Inimigos", "Bosses", "Projeteis", "Sprite ON", "Labels ON"]:
        assert(_find_button(panel._hitbox_view, text) != null, "HitboxView deve ter botao " + text)
    assert(_find_button(panel._hitbox_view, "<") == null, "HitboxView nao deve usar botao anterior")
    assert(_find_button(panel._hitbox_view, ">") == null, "HitboxView nao deve usar botao proximo")
    _assert_buttons_without_fallback_symbols(panel._hitbox_view)
    panel.queue_free()
    print("PASS: hitbox_view_controls_exist")

func test_hitbox_view_hierarchical_selectors() -> void:
    var view := ImgDebug._HitboxView.new()
    add_child(view)
    assert(view._type_row != null, "HitboxView deve ter linha de tipos")
    assert(view._stage_row != null, "HitboxView deve ter linha de stages")
    assert(view._entity_row != null, "HitboxView deve ter linha de entidades")

    view._set_filter("Inimigos")
    assert(_find_button(view._stage_row, "Stage 00") != null, "Inimigos deve listar Stage 00")
    assert(_find_button(view._stage_row, "Stage 02") != null, "Inimigos deve listar Stage 02")
    view._set_stage("Stage 02")
    assert(_find_button(view._entity_row, "Ice Grunt") != null, "Stage 02 deve listar Ice Grunt")
    assert(_find_button(view._entity_row, "Glacier Shield") != null, "Stage 02 deve listar Glacier Shield")

    view._set_filter("Personagens")
    assert(view._stage_row.get_child_count() == 0, "Personagens nao deve mostrar linha de stage")
    assert(_find_button(view._entity_row, "Zael") != null, "Personagens deve listar Zael")
    assert(_find_button(view._entity_row, "Kawagael") != null, "Personagens deve listar Kawagael")
    view.queue_free()
    print("PASS: hitbox_view_hierarchical_selectors")

func test_hitbox_view_frame_selector_updates_sprite_and_glacier_barrier() -> void:
    var view := ImgDebug._HitboxView.new()
    add_child(view)
    view._set_filter("Inimigos")
    view._set_stage("Stage 02")
    view._select_entity_by_name("Glacier Shield")
    assert(view._frame_row != null, "HitboxView deve ter linha de frame")
    assert(_find_button(view._frame_row, "Frame 2") != null, "Glacier Shield deve expor Frame 2")
    assert(_find_button(view._frame_row, "Frame 3") != null, "Glacier Shield deve expor Frame 3")

    var sprite := view._current_instance.get_node_or_null("Sprite2D") as Sprite2D
    var barrier := view._current_instance.get_node_or_null("ShieldBarrier") as Area2D
    view._select_frame(1)
    assert(sprite != null and sprite.frame == 1, "selecionar frame 2 deve atualizar Sprite2D.frame")
    assert(barrier != null and barrier.position == Vector2(38, -52), "frame 2 deve baixar barreira do escudo em 4px")

    view._select_frame(2)
    assert(sprite != null and sprite.frame == 2, "selecionar frame deve atualizar Sprite2D.frame")
    assert(barrier != null and barrier.position == Vector2(38, -40), "frame do escudo baixo deve mover barreira para baixo")

    view._select_frame(0)
    assert(sprite.frame == 0, "voltar frame deve atualizar Sprite2D.frame")
    assert(barrier.position == Vector2(38, -56), "frame normal deve restaurar barreira")
    view.queue_free()
    print("PASS: hitbox_view_frame_selector_updates_sprite_and_glacier_barrier")

func test_hitbox_view_projectile_row_tracks_stage02_release_frames() -> void:
    var view := ImgDebug._HitboxView.new()
    add_child(view)
    view._set_filter("Inimigos")
    view._set_stage("Stage 02")

    _assert_projectile_preview_state(view, "Ice Archer", 3, false, "ice_arrow", false)
    _assert_projectile_preview_state(view, "Ice Archer", 4, true, "ice_arrow", false)
    _assert_projectile_preview_state(view, "Frost Turret", 2, false, "ice_cannonball", false)
    _assert_projectile_preview_state(view, "Frost Turret", 3, true, "ice_cannonball", false)
    _assert_projectile_preview_state(view, "Cryo Bomber", 3, true, "ice_ball", true)
    _assert_projectile_preview_state(view, "Glacier Shield", 2, true, "eye_beam", false)

    view.queue_free()
    print("PASS: hitbox_view_projectile_row_tracks_stage02_release_frames")

func test_hitbox_view_has_floor() -> void:
    var view := ImgDebug._HitboxView.new()
    add_child(view)
    assert(view._overlay != null, "HitboxView deve ter overlay")
    assert(view._scene_root != null, "HitboxView deve ter root de zoom")
    assert(view._scene_root.scale.is_equal_approx(Vector2(2.0, 2.0)), "HitboxView deve aplicar zoom 2x")
    assert(view._overlay.floor_tex != null, "HitboxView deve carregar textura de piso")
    assert(view._overlay.floor_tex.resource_path == "res://stages/stage_00/Stage_00T.png", "piso da HitboxView deve usar Stage_00T")
    assert(view._overlay.get("floor_body_rows") == 1, "piso da HitboxView deve ser uma plataforma baixa")
    assert(is_equal_approx(view._overlay.ground_y, 300.0), "piso deve alinhar com ground_y 300")
    view.queue_free()
    print("PASS: hitbox_view_has_floor")

func test_hitbox_view_draws_entities_above_floor_tiles() -> void:
    var view := ImgDebug._HitboxView.new()
    add_child(view)
    assert(view._floor_overlay != null, "HitboxView deve ter overlay separado para piso")
    assert(view._shape_overlay != null, "HitboxView deve ter overlay separado para hitboxes")
    assert(view._floor_overlay.z_index < view._world_root.z_index, "piso deve ficar abaixo das entidades no eixo z")
    assert(view._world_root.z_index < view._shape_overlay.z_index, "hitboxes devem continuar acima das entidades")
    view.queue_free()
    print("PASS: hitbox_view_draws_entities_above_floor_tiles")

func test_hitbox_view_aligns_character_collision_bottom_to_floor() -> void:
    var view := ImgDebug._HitboxView.new()
    add_child(view)
    var idx := view._find_first_group("Personagens")
    assert(idx >= 0, "HitboxView deve encontrar personagem")
    view._select_index(idx)
    var bottom := _max_collision_shape_bottom(view._current_instance, float(view._scene_root.scale.x))
    assert(is_equal_approx(bottom, view._overlay.ground_y), "fundo da hitbox do personagem deve alinhar ao piso")
    view.queue_free()
    print("PASS: hitbox_view_aligns_character_collision_bottom_to_floor")

func test_hitbox_view_freezes_inspected_entities() -> void:
    var view := ImgDebug._HitboxView.new()
    add_child(view)
    var idx := view._find_first_group("Personagens")
    assert(idx >= 0, "HitboxView deve encontrar personagem para congelar")
    view._select_index(idx)
    assert(_all_processing_disabled(view._current_instance), "entidade inspecionada nao deve processar fisica ou cair")
    view.queue_free()
    print("PASS: hitbox_view_freezes_inspected_entities")

func test_img_debug_buttons_use_web_safe_text() -> void:
    var panel = load("res://ui/img_debug.tscn").instantiate()
    add_child(panel)
    panel._show_section("MOVIMENTOS")
    _assert_buttons_without_fallback_symbols(panel)
    panel._show_section("HITBOXES")
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

func _max_collision_shape_bottom(node: Node, zoom: float = 1.0) -> float:
    var bottom := -INF
    if node is CollisionShape2D:
        var cs := node as CollisionShape2D
        bottom = maxf(bottom, _collision_shape_bottom(cs, zoom))
    for child in node.get_children():
        bottom = maxf(bottom, _max_collision_shape_bottom(child, zoom))
    return bottom

func _collision_shape_bottom(cs: CollisionShape2D, zoom: float = 1.0) -> float:
    if cs.shape is RectangleShape2D:
        return cs.global_position.y + (cs.shape as RectangleShape2D).size.y * 0.5 * zoom
    if cs.shape is CircleShape2D:
        return cs.global_position.y + (cs.shape as CircleShape2D).radius * zoom
    if cs.shape is CapsuleShape2D:
        return cs.global_position.y + (cs.shape as CapsuleShape2D).height * 0.5 * zoom
    return cs.global_position.y

func _all_processing_disabled(node: Node) -> bool:
    if node == null:
        return true
    if node.process_mode != Node.PROCESS_MODE_DISABLED:
        return false
    if node.is_processing() or node.is_physics_processing():
        return false
    for child in node.get_children():
        if not _all_processing_disabled(child):
            return false
    return true

func _assert_buttons_without_fallback_symbols(node: Node) -> void:
    var forbidden := ["✕", "↺", "◄", "►", "▶", "⏸", "←", "→", "↻"]
    if node is Button:
        var text := (node as Button).text
        for symbol in forbidden:
            assert(not text.contains(symbol), "botão usa símbolo sem fallback Web: " + text)
    for child in node.get_children():
        _assert_buttons_without_fallback_symbols(child)

func _assert_projectile_preview_state(
    view: ImgDebug._HitboxView,
    entity_name: String,
    frame_index: int,
    expected_visible: bool,
    expected_variant: String,
    expected_parabolic: bool
) -> void:
    view._select_entity_by_name(entity_name)
    view._select_frame(frame_index)
    var row := view.get("_projectile_row") as Control
    assert(row != null and row.visible, entity_name + " deve mostrar linha Projetil")
    var info_value = view.get("_current_projectile_info")
    assert(info_value is Dictionary, entity_name + " deve expor metadata de projetil")
    var info := info_value as Dictionary
    assert(String(info.get("variant", "")) == expected_variant, entity_name + " deve usar variant " + expected_variant)
    assert(bool(info.get("visible", false)) == expected_visible, entity_name + " visibilidade do projetil no frame incorreta")
    assert(bool(info.get("parabolic", false)) == expected_parabolic, entity_name + " parabola incorreta")
    if entity_name == "Ice Archer" and expected_visible:
        var offset := info.get("offset", Vector2.ZERO) as Vector2
        assert(offset.is_equal_approx(Vector2(52.0, -82.0)), entity_name + " deve subir 16px")
