extends GL_Animatable
class_name GL_LightProjector
var video_player: VideoStreamPlayer
var spot_light: SpotLight3D
var oldPath: String
@export var canChangeColor: bool = false
@export var energyMultiplier: float = 300
@export var lerp_speed: float = 5.0
var target_energy: float = 0.0

# Video seek cooldown
const VIDEO_SEEK_COOLDOWN = 0.5
var _pending_path: String = ""
var _pending_time: float = -1.0
var _seek_cooldown: float = 0.0

func _ready():
	super()
	spot_light = self.get_parent() as SpotLight3D
	if not spot_light:
		printerr("Parent must be a SpotLight3D for projector")
		return
	target_energy = spot_light.light_energy
	video_player = get_child(0) as VideoStreamPlayer
	if not video_player:
		printerr("First child must be a VideoStreamPlayer")
	set_process(true)

func _process(delta: float) -> void:
	super(delta)
	spot_light.light_energy = lerp(spot_light.light_energy, target_energy, delta * lerp_speed)
	spot_light.visible = spot_light.light_energy > 0.0
	if video_player.stream:
		spot_light.light_projector = null
		spot_light.light_projector = video_player.get_video_texture()

	if _seek_cooldown > 0.0:
		_seek_cooldown -= delta
		if _seek_cooldown <= 0.0:
			_seek_cooldown = 0.0
			_flush_pending_video()

func _flush_pending_video() -> void:
	if _pending_path != "" and _pending_path != oldPath:
		var stream: VideoStream = null
		var ext = _pending_path.get_extension().to_lower()
		match ext:
			"ogv", "ogg":
				stream = VideoStreamTheora.new()
				stream.file = _pending_path
			_:
				var loaded = ResourceLoader.load(_pending_path, "VideoStream")
				if loaded and loaded is VideoStream:
					stream = loaded
		if stream:
			video_player.stream = stream
			video_player.play()
			oldPath = _pending_path
			if _pending_time >= 0.0:
				video_player.stream_position = _pending_time
		else:
			printerr("GL_Light_Projector: could not create VideoStream for: ", _pending_path)
	elif _pending_time >= 0.0 and video_player.stream:
		var pos = video_player.get_stream_position()
		if abs(_pending_time - pos) > 0.5 and _pending_time > 0.05:
			video_player.stream_position = _pending_time
			if not video_player.is_playing():
				video_player.play()
		elif not video_player.is_playing() and _pending_time > 0.0:
			video_player.play()
			video_player.stream_position = _pending_time
	_pending_path = ""
	_pending_time = -1.0

func _sent_signals(anim_name: String, value):
	anim_name = anim_name.split("|", true, 1)[-1]
	if not video_player:
		printerr("Can't find VideoPlayer, needs to be first child")
		return
	match anim_name:
		"Video":
			if value == null or str(value).contains("null"):
				video_player.stop()
				video_player.stream = null
				spot_light.light_projector = null
				oldPath = ""
				_pending_path = ""
				_pending_time = -1.0
				_seek_cooldown = 0.0
				return
			var path: String = str(value)
			if path == "" or path == oldPath:
				return
			_pending_path = path
			if _seek_cooldown <= 0.0:
				_seek_cooldown = VIDEO_SEEK_COOLDOWN
		"Current Time":
			if video_player.stream and typeof(value) == TYPE_FLOAT:
				_pending_time = value
				if _seek_cooldown <= 0.0:
					_seek_cooldown = VIDEO_SEEK_COOLDOWN
		"intensity":
			if typeof(value) == TYPE_BOOL:
				value = float(value)
			target_energy = max(value, 0.0) * energyMultiplier
		"color":
			if canChangeColor and value is Color:
				spot_light.light_color = value
