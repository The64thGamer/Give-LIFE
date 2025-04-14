extends GL_Animatable

var speaker:AudioStreamPlayer

func _ready():
	speaker = get_child(0)
	
func _sent_signals(anim_name: String, value):
	if speaker == null:
		printerr("Can't find Animatable Speaker, needs to be the first child of node")
		return
		
	match(anim_name):
		"Audio":
			var path = (value as GL_AudioType).value
			if path != "":
				var stream
				match(path.get_extension().to_lower()):
					"mp3":
						stream = AudioStreamMP3.load_from_file(path)
					"wav":
						stream = AudioStreamWAV.load_from_file(path)
					"ogg":
						stream = AudioStreamOggVorbis.load_from_file(path)
				if stream and stream is AudioStream:
					speaker.stream = stream
					speaker.play()
				else:
					printerr("Invalid audio stream at path: ", path)
		"Volume":
			speaker.volume_linear = value
		"Current Time":
			if abs(speaker.get_playback_position() - value) < 0.1:
				speaker.seek(value)
	

	
