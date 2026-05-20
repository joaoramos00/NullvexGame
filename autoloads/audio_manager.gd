extends Node

const SFX_POOL_SIZE := 8

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _tween: Tween

func _ready() -> void:
    _music_player = AudioStreamPlayer.new()
    _music_player.bus = "Music"
    add_child(_music_player)
    for i in SFX_POOL_SIZE:
        var p := AudioStreamPlayer.new()
        p.bus = "SFX"
        add_child(p)
        _sfx_pool.append(p)

func play_bgm(stream: AudioStream, fade_in: float = 0.5) -> void:
    if stream == null:
        return
    if _music_player.playing:
        await _fade_out_music(fade_in * 0.5)
    _music_player.stream = stream
    _music_player.volume_db = -80.0
    _music_player.play()
    _fade_in_music(fade_in)

func stop_bgm(fade_out: float = 0.5) -> void:
    if not _music_player.playing:
        return
    await _fade_out_music(fade_out)
    _music_player.stop()

func play_sfx(stream: AudioStream) -> void:
    if stream == null:
        return
    for player in _sfx_pool:
        if not player.playing:
            player.stream = stream
            player.play()
            return
    _sfx_pool[0].stream = stream
    _sfx_pool[0].play()

func _fade_in_music(duration: float) -> void:
    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(_music_player, "volume_db", 0.0, duration)

func _fade_out_music(duration: float) -> void:
    if _tween:
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(_music_player, "volume_db", -80.0, duration)
    await _tween.finished
