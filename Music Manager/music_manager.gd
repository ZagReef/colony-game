extends AudioStreamPlayer

var music_list: Dictionary = {
	"lost":load("res://Music Manager/Menu Musics/lost.mp3"),
	"lost_": load("res://Music Manager/Menu Musics/lost_.mp3"),
}

var is_eg_playing: bool = false
var default_music = "lost_"
var default_volume = self.volume_db
var paused_pos = 0.0

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	self.finished.connect(_on_music_finished)
	self.bus = "Music"
	
	self.volume_db = -21.0
	default_volume = self.volume_db
	self.stream = music_list["lost_"]
	self.play()

func set_music(music_name: String):
	is_eg_playing = false
	default_music = music_name
	self.stream = music_list[music_name]
	self.play(paused_pos)


func _on_music_finished():
	if is_eg_playing:
		is_eg_playing = false
		set_music(default_music)
		self.volume_db = default_volume
	else:
		set_music(default_music)
		self.volume_db = default_volume
