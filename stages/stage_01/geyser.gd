extends Area2D

# Gêiser-turbina em 4 fases (sprites animados do PixelLab + subida via clip no motor):
#   DORMENTE → turbina girando devagar, sem dano.
#   AVISO    → turbina ACELERA (telegrafa), AINDA sem dano.
#   SUBIDA   → o jato de vapor cresce do zero (topo da turbina) até o topo, dano ligado.
#   ATIVO    → jato de vapor em loop, dano ligado.

@export var active_time:   float = 1.4   # erupção sustentada (vapor)
@export var inactive_time: float = 2.0   # dormente
@export var warn_time:     float = 1.0   # turbina acelerando (aviso)
@export var rise_time:     float = 0.45  # subida do jato (do zero ao topo)
@export var damage:        int   = 20
@export var start_delay:   float = 0.0   # encadeia gêiseres
@export var turbine_offset: Vector2 = Vector2.ZERO  # ajuste fino visual da turbina (por gêiser)

const _SPIN_IDLE := 1.0   # turbina dormente (giro lento)
const _SPIN_FAST := 3.0   # turbina acelerando (aviso) / erupção
const _JET_SCALE := 1.5   # proporção do jato de vapor
const _JET_CONTENT_CX := 28.4   # centro horizontal do CONTEÚDO do vapor no frame (111px); conteúdo fica à esquerda
const _STEAM_DROP := 16.0   # 1/4 de tile (64) — desce a base do vapor p/ a junção dos tiles
const _JET_WIDTH_EXTRA := 1.5   # alarga só a largura do jato (além do _JET_SCALE)
const _STEAM_NUDGE_X := -1.0    # ajuste fino horizontal do vapor

enum State { DORMANT, WARN, RISING, ACTIVE }
var _state: int = State.DORMANT
var _timer: float = 0.0
var _bodies_inside: Array[Node] = []
var _turbine: AnimatedSprite2D = null   # turbina cilíndrica (gira sempre; acelera no aviso)
var _jet: AnimatedSprite2D = null       # jato de vapor em loop (ATIVO)
var _rise: Sprite2D = null              # subida: revela o jato de baixo p/ cima
# geometria do jato (p/ a subida)
var _crater_y: float = 0.0
var _col_top: float = 0.0
var _jet_sx: float = 1.0
var _jet_sy: float = 1.0
var _jet_tw: float = 1.0
var _jet_th: float = 1.0

func _ready() -> void:
	monitoring = false
	_timer = inactive_time + start_delay
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()

func _build_visual() -> void:
	var cs: CollisionShape2D = null
	for c in get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape is RectangleShape2D:
			cs = c
			break
	if cs == null:
		return
	var size: Vector2 = (cs.shape as RectangleShape2D).size
	var col_bottom: float = size.y * 0.5
	_col_top = -size.y * 0.5
	# (O buraco no piso é desenhado pelo render do chão — meta "floor_holes" na ledge.)
	# Turbina cilíndrica: gira sempre (acelera no aviso). Afunda no buraco do piso.
	_crater_y = col_bottom
	var sf_v := _make_frames("spin", "res://stages/stage_01/geyser_turbine_%d.png", 9, 12.0)
	if sf_v:
		_turbine = AnimatedSprite2D.new()
		_turbine.sprite_frames = sf_v
		_turbine.animation = "spin"
		_turbine.centered = true                 # gira em torno do centro
		# Sprite 128×80; girada -90° → escala NÃO-uniforme p/ caber no poço como um todo:
		#   scale.x controla a ALTURA no mundo (128*sx); scale.y controla a LARGURA (80*sy).
		# Poço: canal transparente ~66px largura × ~62px fundo (pode vazar ~10px p/ cima).
		var sx := 0.66                           # altura ≈ 128*0.66 ≈ 84px
		var sy := 0.95                           # largura ≈ 80*0.95 ≈ 76px (excesso mascarado pela rocha)
		_turbine.scale = Vector2(sx, sy)
		_turbine.rotation_degrees = -90.0        # 90° p/ a esquerda → fan aponta pra cima
		var t0: Texture2D = sf_v.get_frame_texture("spin", 0)
		var rot_h: float = float(t0.get_width()) * sx       # largura original × sx = altura após girar
		# Por cima dos tiles, centrada no poço (+ ajuste fino por gêiser).
		_turbine.position = Vector2(0.0, col_bottom + 46.0) + turbine_offset
		_turbine.z_index = 2                     # à frente do desenho do piso
		_turbine.speed_scale = _SPIN_IDLE
		_turbine.play("spin")        # gira o tempo todo
		add_child(_turbine)
		_crater_y = _turbine.position.y - rot_h * 0.5 + 8.0   # vapor sai do topo (fan) da turbina
	# Jato de vapor (ATIVO): preenche do topo da turbina até o topo da coluna (sem dano invisível).
	var sf_j := _make_frames("steam", "res://stages/stage_01/geyser_steam_%d.png", 9, 12.0)
	if sf_j:
		var jt: Texture2D = sf_j.get_frame_texture("steam", 0)
		_jet_tw = float(jt.get_width())
		_jet_th = float(jt.get_height())
		_jet_sx = (size.x / _jet_tw) * _JET_SCALE * _JET_WIDTH_EXTRA
		_jet_sy = ((_crater_y - _col_top) / _jet_th) * _JET_SCALE
		_jet = AnimatedSprite2D.new()
		_jet.sprite_frames = sf_j
		_jet.animation = "steam"
		_jet.centered = false
		_jet.scale = Vector2(_jet_sx, _jet_sy)
		# X: centro do conteúdo alinhado à turbina (junção dos tiles). Y: base no topo da turbina, descida 1/4 tile.
		_jet.position = Vector2(turbine_offset.x + _STEAM_NUDGE_X - _JET_CONTENT_CX * _jet_sx, _crater_y - _jet_th * _jet_sy + _STEAM_DROP)
		_jet.z_index = 3                         # vapor à frente da turbina (z 2)
		_jet.visible = false
		add_child(_jet)
		# Sprite de subida: mesmo jato, revelado de baixo p/ cima (região cresce da cratera).
		_rise = Sprite2D.new()
		_rise.texture = jt
		_rise.centered = false
		_rise.region_enabled = true
		_rise.scale = Vector2(_jet_sx, _jet_sy)
		_rise.z_index = 3                         # vapor à frente da turbina (z 2)
		_rise.visible = false
		add_child(_rise)

func _make_frames(anim: String, path_fmt: String, count: int, fps: float) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation(anim)
	sf.set_animation_loop(anim, true)
	sf.set_animation_speed(anim, fps)
	var any := false
	for i in count:
		var t: Texture2D = load(path_fmt % i) as Texture2D
		if t:
			sf.add_frame(anim, t)
			any = true
	return sf if any else null

# Revela o jato de baixo (cratera) p/ cima: p=0 → nada; p=1 → jato cheio.
func _set_rise(p: float) -> void:
	p = clampf(p, 0.0, 1.0)
	var rev_h: float = _jet_th * p
	_rise.region_rect = Rect2(0.0, _jet_th - rev_h, _jet_tw, rev_h)
	_rise.position = Vector2(turbine_offset.x + _STEAM_NUDGE_X - _JET_CONTENT_CX * _jet_sx, _crater_y - rev_h * _jet_sy + _STEAM_DROP)

func _process(delta: float) -> void:
	_timer -= delta
	if _state == State.RISING and _rise and rise_time > 0.0:
		_set_rise(1.0 - _timer / rise_time)
	if _timer > 0.0:
		return
	match _state:
		State.DORMANT:
			_state = State.WARN
			_timer = warn_time
			if _turbine:
				_turbine.speed_scale = _SPIN_FAST   # turbina acelera (aviso)
		State.WARN:
			_state = State.RISING
			_timer = rise_time
			monitoring = true                   # dano a partir da subida
			if _rise:
				_rise.visible = true
				_set_rise(0.0)
		State.RISING:
			_state = State.ACTIVE
			_timer = active_time
			if _rise:
				_rise.visible = false
			if _jet:
				_jet.visible = true
				_jet.play("steam")
		State.ACTIVE:
			_state = State.DORMANT
			_timer = inactive_time
			monitoring = false
			_bodies_inside.clear()
			if _turbine:
				_turbine.speed_scale = _SPIN_IDLE   # turbina desacelera (dormente)
			if _jet:
				_jet.stop()
				_jet.visible = false

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase:
		_bodies_inside.append(body)

func _on_body_exited(body: Node) -> void:
	_bodies_inside.erase(body)

func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	for body in _bodies_inside:
		if is_instance_valid(body):
			(body as CharacterBase).take_damage(damage)
