extends Button
class_name GL_Node_Point

var mainNode : GL_Node
@export var isOutput:bool

var valueName:String
var dragging:bool

var previewLine:Line2D = null

func _ready():
	set_process(true)

func _process(delta):
	if dragging:
		if previewLine == null:
			previewLine = Line2D.new()
			previewLine.width = 10
			previewLine.default_color = Color.WHITE
			previewLine.add_point(Vector2.ZERO)
			previewLine.add_point(Vector2.ZERO)
		previewLine.points[0] = position
		previewLine.points[1] = get_viewport().get_mouse_position()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if !event.pressed:
			_finish_drag()

func _start_drag():
	if (not isOutput):
		return 
		
	dragging = true

func _finish_drag():
	if not dragging:
		return

	dragging = false
