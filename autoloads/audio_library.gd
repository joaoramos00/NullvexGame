extends Node

@export var bgm_intro: AudioStream = null
@export var bgm_stage_01: AudioStream = null
@export var bgm_stage_02: AudioStream = null
@export var bgm_stage_03: AudioStream = null
@export var bgm_stage_04: AudioStream = null
@export var bgm_stage_05: AudioStream = null
@export var bgm_stage_06: AudioStream = null
@export var bgm_stage_07: AudioStream = null
@export var bgm_stage_08: AudioStream = null
@export var bgm_gauntlet: AudioStream = null
@export var bgm_nullvex: AudioStream = null
@export var bgm_nullvex_true: AudioStream = null

var sfx_jump: AudioStream
var sfx_shoot: AudioStream
var sfx_attack: AudioStream
var sfx_player_damage: AudioStream
var sfx_player_death: AudioStream
var sfx_enemy_death: AudioStream
var sfx_boss_damage: AudioStream
var sfx_boss_death: AudioStream
var sfx_collectible: AudioStream

func _ready() -> void:
	sfx_jump          = load("res://assets/audio/sfx/sfx_jump.mp3")
	sfx_shoot         = load("res://assets/audio/sfx/sfx_shoot.mp3")
	sfx_attack        = load("res://assets/audio/sfx/sfx_attack.mp3")
	sfx_player_damage = load("res://assets/audio/sfx/sfx_player_damage.mp3")
	sfx_player_death  = load("res://assets/audio/sfx/sfx_player_death.mp3")
	sfx_enemy_death   = load("res://assets/audio/sfx/sfx_enemy_death.mp3")
	sfx_boss_damage   = load("res://assets/audio/sfx/sfx_boss_damage.mp3")
	sfx_boss_death    = load("res://assets/audio/sfx/sfx_boss_death.mp3")
	sfx_collectible   = load("res://assets/audio/sfx/sfx_collectible.mp3")

func get_stage_bgm(stage_id: int) -> AudioStream:
	match stage_id:
		0: return bgm_intro
		1: return bgm_stage_01
		2: return bgm_stage_02
		3: return bgm_stage_03
		4: return bgm_stage_04
		5: return bgm_stage_05
		6: return bgm_stage_06
		7: return bgm_stage_07
		8: return bgm_stage_08
		9: return bgm_gauntlet
		10: return bgm_nullvex
		11: return bgm_nullvex_true
	return null
