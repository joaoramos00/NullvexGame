extends CharacterBody2D
class_name EnemyBase

signal died
signal damaged(amount: int)

const GRAVITY                := 980.0
const PATROL_SPEED           := 80.0
const INVINCIBILITY_DURATION := 0.3
const ANIM_FPS               := 5.0
const WALK_FRAMES            := 6

const _DEATH_EFFECT_SCENE  := preload("res://effects/death_effect.tscn")
const _DROP_PICKUP_SCENE   := preload("res://characters/pickups/drop_pickup.tscn")

const _DROP_ARCH: Dictionary = {
	"grunt":        {"chance": 0.25, "pool": {"hp_small": 45, "en_small": 50, "one_up": 5}},
	"hopper":       {"chance": 0.25, "pool": {"hp_small": 55, "en_small": 40, "one_up": 5}},
	"flyer":        {"chance": 0.20, "pool": {"hp_small": 25, "en_small": 70, "one_up": 5}},
	"orbiter":      {"chance": 0.20, "pool": {"hp_small": 45, "en_small": 50, "one_up": 5}},
	"ranged_light": {"chance": 0.30, "pool": {"hp_small": 25, "en_small": 70, "one_up": 5}},
	"turret":       {"chance": 0.35, "pool": {"hp_small": 20, "en_small": 45, "en_large": 30, "one_up": 5}},
	"heavy":        {"chance": 0.20, "pool": {"hp_small": 20, "hp_large": 35, "en_large": 40, "one_up": 5}},
	"trap":         {"chance": 0.12, "pool": {"hp_small": 20, "en_small": 75, "one_up": 5}},
	"elite":        {"chance": 0.20, "pool": {"hp_large": 45, "en_large": 45, "one_up": 10}},
	"miniboss":     {"chance": 1.00, "pool": {"hp_large": 55, "en_large": 35, "one_up": 10}},
}

const _DROP_TABLE: Dictionary = {
	# Stage 01 — Fogo
	"enemy_magma_grunt":        "grunt",
	"enemy_ash_hopper":         "hopper",
	"enemy_flame_skimmer":      "grunt",
	"enemy_cinder_flyer":       "flyer",
	"enemy_ember_orbiter":      "orbiter",
	"enemy_heat_mortar":        "turret",
	"enemy_magma_turret":       "turret",
	"enemy_lava_serpent":       "elite",
	"enemy_molten_ram":         "heavy",
	# Stage 02 — Gelo
	"enemy_ice_grunt":          "grunt",
	"enemy_ice_flyer":          "flyer",
	"enemy_ice_wisp":           "orbiter",
	"enemy_ice_archer":         "ranged_light",
	"enemy_cryo_bomber":        "ranged_light",
	"enemy_frost_turret":       "turret",
	"enemy_glacier_shield":     "heavy",
	"enemy_ice_miniboss":       "miniboss",
	# Stage 03 — Raio
	"enemy_rail_runner":        "grunt",
	"enemy_volt_guard":         "grunt",
	"enemy_arc_orbiter":        "orbiter",
	"enemy_storm_kite":         "flyer",
	"enemy_thunder_hawklet":    "flyer",
	"enemy_arc_turret":         "turret",
	"enemy_tesla_coil":         "turret",
	"enemy_storm_relay":        "trap",
	"enemy_static_interceptor": "trap",
	# Stage 04 — Gravidade
	"enemy_grav_guard":         "grunt",
	"enemy_mass_brute":         "heavy",
	"enemy_debris_orbiter":     "orbiter",
	"enemy_void_drone":         "flyer",
	"enemy_singularity_turret": "turret",
	"enemy_crush_pylon":        "turret",
	"enemy_orbit_mauler":       "elite",
	"enemy_grav_well":          "trap",
	"enemy_gravity_mine":       "trap",
	# Stage 05 — Vento
	"enemy_gale_runner":        "grunt",
	"enemy_gale_grappler":      "heavy",
	"enemy_feather_swarm":      "orbiter",
	"enemy_sky_harrier":        "flyer",
	"enemy_claw_glider":        "flyer",
	"enemy_airfoil_lancer":     "ranged_light",
	"enemy_gale_turret":        "turret",
	"enemy_updraft_fan":        "trap",
	"enemy_turbine_wisp":       "flyer",
	# Stage 06 — Sombra
	"enemy_shadow_stalker":     "grunt",
	"enemy_eclipse_duelist":    "elite",
	"enemy_night_pouncer":      "hopper",
	"enemy_eclipse_turret":     "turret",
	"enemy_dark_lantern":       "trap",
	"enemy_umbra_bat":          "flyer",
	"enemy_void_orbiter":       "orbiter",
	"enemy_phase_mine":         "trap",
	"enemy_shadow_snare":       "trap",
	# Stage 07 — Luz
	"enemy_lion_cub_runner":    "grunt",
	"enemy_mirror_ram":         "heavy",
	"enemy_solar_guard":        "grunt",
	"enemy_beam_turret":        "turret",
	"enemy_radiant_pylon":      "turret",
	"enemy_glasswing_drone":    "flyer",
	"enemy_mirror_moth":        "flyer",
	"enemy_prism_orbiter":      "orbiter",
	"enemy_sun_grabber":        "elite",
	# Stage 08 — Terra
	"enemy_terra_grunt":        "grunt",
	"enemy_mossback_brute":     "heavy",
	"enemy_drill_mole":         "grunt",
	"enemy_ore_orbiter":        "orbiter",
	"enemy_gem_wasp":           "flyer",
	"enemy_stone_glider":       "flyer",
	"enemy_boulder_turret":     "turret",
	"enemy_fossil_totem":       "trap",
	"enemy_root_snare":         "trap",
	# Genéricos
	"enemy_flyer":              "flyer",
	"enemy_miniboss":           "miniboss",
}

const _DROP_POOL_TO_TYPE: Dictionary = {
	"hp_small": DropPickup.Type.HP_SMALL,
	"hp_large": DropPickup.Type.HP_LARGE,
	"en_small": DropPickup.Type.EN_SMALL,
	"en_large": DropPickup.Type.EN_LARGE,
	"one_up":   DropPickup.Type.ONE_UP,
}

@export var max_hp:         int = 8
@export var contact_damage: int = 8

var current_hp:           int   = 8
var is_dead:              bool  = false
var _direction:           float = 1.0
var _invincible:          bool  = false
var _invincibility_timer: float = 0.0
var _anim_timer:          float = 0.0
var _anim_frame:          int   = 0
var _visual_motion_time:  float = 0.0
var _visual_rest_position := Vector2.ZERO
var _visual_rest_rotation := 0.0
var _visual_rest_cached   := false

var show_hitbox: bool = false:
	set(value):
		show_hitbox = value
		queue_redraw()

@onready var _sprite := $Sprite2D

var _hb_per_frame: bool = false
var _hb_last_frame: int = -1

func _ready() -> void:
	current_hp = max_hp
	$ContactZone.body_entered.connect(_on_contact)
	HitboxData.reloaded.connect(_apply_hitbox_data)
	_apply_hitbox_data()

func _hitbox_id() -> String:
	var scr: Script = get_script() as Script
	if scr == null:
		return ""
	return scr.resource_path.get_file().get_basename()

func _apply_hitbox_data() -> void:
	var id := _hitbox_id()
	if not HitboxData.has(id):
		return
	var e := HitboxData.entry(id)
	if e.has("sprite") and is_instance_valid(_sprite):
		var sp = e["sprite"]
		if sp.has("pos"): _sprite.position = Vector2(sp["pos"][0], sp["pos"][1])
		if sp.has("scale"): _sprite.scale = Vector2(sp["scale"][0], sp["scale"][1])
	_hb_per_frame = false
	for s in e.get("shapes", []):
		var fr = s.get("frames", "all")
		if not (fr is String and fr == "all"):
			_hb_per_frame = true
			break
	_apply_hitbox_frame(0)

func _apply_hitbox_frame(frame: int) -> void:
	var id := _hitbox_id()
	var shapes := HitboxData.frame_shapes(id, frame)
	if shapes.is_empty():
		return
	_rebuild_shapes("body", shapes)
	_rebuild_shapes("contact", shapes)
	_hb_last_frame = frame

func _rebuild_shapes(target: String, shapes: Array) -> void:
	var host: Node = self if target == "body" else get_node_or_null("ContactZone")
	if host == null:
		return
	for c in host.get_children():
		if c is CollisionShape2D:
			c.free()
	for s in shapes:
		if String(s.get("target", "")) != target:
			continue
		var cs := CollisionShape2D.new()
		cs.position = Vector2(s["pos"][0], s["pos"][1])
		var _kind := String(s.get("kind", "rect"))
		if _kind == "capsule":
			var cap := CapsuleShape2D.new()
			cap.radius = float(s["size"][0]); cap.height = float(s["size"][1])
			cs.shape = cap
		elif _kind == "circle":
			var circ := CircleShape2D.new()
			circ.radius = float(s["size"][0])
			cs.shape = circ
		else:
			var r := RectangleShape2D.new()
			r.size = Vector2(s["size"][0], s["size"][1])
			cs.shape = r
		host.add_child(cs)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if is_on_floor() and not _has_floor_ahead():
		_direction = -_direction
	velocity.x = PATROL_SPEED * _direction
	move_and_slide()
	if is_on_wall():
		_direction = -_direction
	if _invincible:
		_sprite.modulate.a = 0.35 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0
	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer -= 1.0 / ANIM_FPS
		_anim_frame = (_anim_frame + 1) % WALK_FRAMES
	_sprite.frame  = _anim_frame
	_sprite.flip_h = (_direction < 0)

func _has_floor_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var start := Vector2(global_position.x + _direction * 26.0, global_position.y - 8.0)
	var end   := Vector2(global_position.x + _direction * 26.0, global_position.y + 88.0)
	var params := PhysicsRayQueryParameters2D.create(start, end)
	return not space.intersect_ray(params).is_empty()

func _cache_sprite_rest_transform() -> void:
	if not is_instance_valid(_sprite):
		return
	if _visual_rest_cached:
		return
	_visual_rest_position = _sprite.position
	_visual_rest_rotation = _sprite.rotation
	_visual_rest_cached = true

func _animate_sprite_frames(delta: float, frame_count: int = WALK_FRAMES, fps: float = ANIM_FPS) -> void:
	if not is_instance_valid(_sprite):
		return
	var available_frames: int = max(1, _sprite.hframes * _sprite.vframes)
	var cycle_frames: int = int(min(frame_count, available_frames))
	if cycle_frames <= 1 or fps <= 0.0:
		return
	_anim_timer += delta
	var frame_duration: float = 1.0 / fps
	while _anim_timer >= frame_duration:
		_anim_timer -= frame_duration
		_anim_frame = (_anim_frame + 1) % cycle_frames
	_sprite.frame = _anim_frame

func _advance_sprite_frame_loop(delta: float, frame_count: int, fps: float) -> int:
	_animate_sprite_frames(delta, frame_count, fps)
	var fr: int = _sprite.frame if is_instance_valid(_sprite) else 0
	if _hb_per_frame and fr != _hb_last_frame:
		_apply_hitbox_frame(fr)
	return fr

func _set_sprite_frame(frame_index: int) -> void:
	_anim_frame = max(0, frame_index)
	_anim_timer = 0.0
	if is_instance_valid(_sprite):
		var available_frames: int = max(1, _sprite.hframes * _sprite.vframes)
		_sprite.frame = _anim_frame % available_frames

func _animate_sprite_motion(delta: float, bob_pixels: float, bob_speed: float, tilt_degrees: float = 0.0, sway_pixels: float = 0.0) -> void:
	if not is_instance_valid(_sprite):
		return
	_cache_sprite_rest_transform()
	_visual_motion_time += delta
	var bob: float = sin(_visual_motion_time * bob_speed) * bob_pixels
	var sway: float = sin(_visual_motion_time * bob_speed * 0.7) * sway_pixels
	var tilt: float = sin(_visual_motion_time * bob_speed * 0.8) * deg_to_rad(tilt_degrees)
	_sprite.position = _visual_rest_position + Vector2(sway, bob)
	_sprite.rotation = _visual_rest_rotation + tilt

func _on_contact(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(contact_damage)

func take_damage(amount: int, _source: String = "") -> void:
	if is_dead or _invincible:
		return
	current_hp = max(0, current_hp - amount)
	_invincible = true
	_invincibility_timer = INVINCIBILITY_DURATION
	damaged.emit(amount)
	if current_hp == 0:
		_die()
	else:
		AudioManager.play_sfx(AudioLibrary.sfx_enemy_hit)

func _draw() -> void:
	if not show_hitbox:
		return
	# CapsuleShape2D radius=20, height=40 → bounding rect (-20,-40,40,80)
	var bounds := Rect2(-20.0, -40.0, 40.0, 80.0)
	draw_rect(bounds, Color(1.0, 0.25, 0.25, 0.25))
	draw_rect(bounds, Color(1.0, 0.25, 0.25, 1.0), false, 2.0)

func _try_drop() -> void:
	var arch_name: String = _DROP_TABLE.get(_hitbox_id(), "grunt")
	var arch: Dictionary  = _DROP_ARCH.get(arch_name, _DROP_ARCH["grunt"])
	if randf() > float(arch["chance"]):
		return
	var pool: Dictionary = arch["pool"]
	var total: int = 0
	for w: int in pool.values():
		total += w
	var roll: int = randi() % total
	var acc: int = 0
	var chosen: String = pool.keys()[0]
	for key: String in pool:
		acc += int(pool[key])
		if roll < acc:
			chosen = key
			break
	var drop: DropPickup = _DROP_PICKUP_SCENE.instantiate()
	drop.drop_type = _DROP_POOL_TO_TYPE[chosen]
	drop.global_position = global_position
	get_parent().add_child(drop)

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	AudioManager.play_sfx(AudioLibrary.sfx_enemy_death)
	died.emit()
	var effect: Node2D = _DEATH_EFFECT_SCENE.instantiate()
	effect.global_position = global_position
	get_parent().add_child(effect)
	_try_drop()
	queue_free()
