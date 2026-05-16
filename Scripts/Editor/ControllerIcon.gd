extends TextureRect
class_name ControllerIcon

@export var button_name: String = "" 

var _pause_menu: Node = null
var _icon_set: int = 0  

const BASE = "res://UI/Buttons/Xelu_Free_Controller&Key_Prompts/"

const ICON_MAP = {
	"A":               ["Others/Xbox 360/360_A.png",              "Others/PS3/PS3_Cross.png",     "Switch/Switch_A.png",              "Steam Deck/SteamDeck_A.png"],
	"B":               ["Others/Xbox 360/360_B.png",              "Others/PS3/PS3_Circle.png",    "Switch/Switch_B.png",              "Steam Deck/SteamDeck_B.png"],
	"X":               ["Others/Xbox 360/360_X.png",              "Others/PS3/PS3_Square.png",    "Switch/Switch_X.png",              "Steam Deck/SteamDeck_X.png"],
	"Y":               ["Others/Xbox 360/360_Y.png",              "Others/PS3/PS3_Triangle.png",  "Switch/Switch_Y.png",              "Steam Deck/SteamDeck_Y.png"],
	"LB":              ["Others/Xbox 360/360_LB.png",             "Others/PS3/PS3_L1.png",        "Switch/Switch_LB.png",             "Steam Deck/SteamDeck_L1.png"],
	"RB":              ["Others/Xbox 360/360_RB.png",             "Others/PS3/PS3_R1.png",        "Switch/Switch_RB.png",             "Steam Deck/SteamDeck_R1.png"],
	"LT":              ["Others/Xbox 360/360_LT.png",             "Others/PS3/PS3_L2.png",        "Switch/Switch_LT.png",             "Steam Deck/SteamDeck_L2.png"],
	"RT":              ["Others/Xbox 360/360_RT.png",             "Others/PS3/PS3_R2.png",        "Switch/Switch_RT.png",             "Steam Deck/SteamDeck_R2.png"],
	"L3":              ["Others/Xbox 360/360_Left_Stick_Click.png",  "Others/PS3/PS3_Left_Stick_Click.png",  "Switch/Switch_Left_Stick_Click.png",  "Steam Deck/SteamDeck_Left_Stick_Click.png"],
	"R3":              ["Others/Xbox 360/360_Right_Stick_Click.png", "Others/PS3/PS3_Right_Stick_Click.png", "Switch/Switch_Right_Stick_Click.png", "Steam Deck/SteamDeck_Right_Stick_Click.png"],
	"Dpad_Up":         ["Others/Xbox 360/360_Dpad_Up.png",        "Others/PS3/PS3_Dpad_Up.png",   "Switch/Switch_Dpad_Up.png",        "Steam Deck/SteamDeck_Dpad_Up.png"],
	"Dpad_Down":       ["Others/Xbox 360/360_Dpad_Down.png",      "Others/PS3/PS3_Dpad_Down.png", "Switch/Switch_Dpad_Down.png",      "Steam Deck/SteamDeck_Dpad_Down.png"],
	"Dpad_Left":       ["Others/Xbox 360/360_Dpad_Left.png",      "Others/PS3/PS3_Dpad_Left.png", "Switch/Switch_Dpad_Left.png",      "Steam Deck/SteamDeck_Dpad_Left.png"],
	"Dpad_Right":      ["Others/Xbox 360/360_Dpad_Right.png",     "Others/PS3/PS3_Dpad_Right.png","Switch/Switch_Dpad_Right.png",     "Steam Deck/SteamDeck_Dpad_Right.png"],
	"Start":           ["Others/Xbox 360/360_Start.png",          "Others/PS3/PS3_Start.png",     "Switch/Switch_Plus.png",           "Steam Deck/SteamDeck_Menu.png"],
	"Back":            ["Others/Xbox 360/360_Back.png",           "Others/PS3/PS3_Select.png",    "Switch/Switch_Minus.png",          "Steam Deck/SteamDeck_View.png"],
	"LstickL":         ["Others/Xbox 360/360_Left_Stick.png",     "Others/PS3/PS3_Left_Stick.png",  "Switch/Switch_Left_Stick.png",   "Steam Deck/SteamDeck_Left_Stick.png"],
	"LstickR":         ["Others/Xbox 360/360_Left_Stick.png",     "Others/PS3/PS3_Left_Stick.png",  "Switch/Switch_Left_Stick.png",   "Steam Deck/SteamDeck_Left_Stick.png"],
	"LstickUp":        ["Others/Xbox 360/360_Left_Stick.png",     "Others/PS3/PS3_Left_Stick.png",  "Switch/Switch_Left_Stick.png",   "Steam Deck/SteamDeck_Left_Stick.png"],
	"LstickDown":      ["Others/Xbox 360/360_Left_Stick.png",     "Others/PS3/PS3_Left_Stick.png",  "Switch/Switch_Left_Stick.png",   "Steam Deck/SteamDeck_Left_Stick.png"],
	"LstickMagnitude": ["Others/Xbox 360/360_Left_Stick.png",     "Others/PS3/PS3_Left_Stick.png",  "Switch/Switch_Left_Stick.png",   "Steam Deck/SteamDeck_Left_Stick.png"],
	"LstickAngle":     ["Others/Xbox 360/360_Left_Stick.png",     "Others/PS3/PS3_Left_Stick.png",  "Switch/Switch_Left_Stick.png",   "Steam Deck/SteamDeck_Left_Stick.png"],
	"RstickL":         ["Others/Xbox 360/360_Right_Stick.png",    "Others/PS3/PS3_Right_Stick.png", "Switch/Switch_Right_Stick.png",  "Steam Deck/SteamDeck_Right_Stick.png"],
	"RstickR":         ["Others/Xbox 360/360_Right_Stick.png",    "Others/PS3/PS3_Right_Stick.png", "Switch/Switch_Right_Stick.png",  "Steam Deck/SteamDeck_Right_Stick.png"],
	"RstickUp":        ["Others/Xbox 360/360_Right_Stick.png",    "Others/PS3/PS3_Right_Stick.png", "Switch/Switch_Right_Stick.png",  "Steam Deck/SteamDeck_Right_Stick.png"],
	"RstickDown":      ["Others/Xbox 360/360_Right_Stick.png",    "Others/PS3/PS3_Right_Stick.png", "Switch/Switch_Right_Stick.png",  "Steam Deck/SteamDeck_Right_Stick.png"],
	"RstickMagnitude": ["Others/Xbox 360/360_Right_Stick.png",    "Others/PS3/PS3_Right_Stick.png", "Switch/Switch_Right_Stick.png",  "Steam Deck/SteamDeck_Right_Stick.png"],
	"RstickAngle":     ["Others/Xbox 360/360_Right_Stick.png",    "Others/PS3/PS3_Right_Stick.png", "Switch/Switch_Right_Stick.png",  "Steam Deck/SteamDeck_Right_Stick.png"],
}

func _ready() -> void:
	add_to_group("SettingsReceivers")
	_pause_menu = get_tree().get_first_node_in_group("Pause Menu")
	if _pause_menu and _pause_menu.currentSettings.has("controller_icons"):
		_icon_set = _pause_menu.currentSettings.get("controller_icons", 0)
	_update_texture()

func on_settings_applied(settings: Dictionary) -> void:
	if settings.has("controller_icons"):
		_icon_set = settings.get("controller_icons", 0)
		_update_texture()

func _update_texture() -> void:
	if button_name == "" or not ICON_MAP.has(button_name):
		texture = null
		return
	var paths: Array = ICON_MAP[button_name]
	var idx = clamp(_icon_set, 0, paths.size() - 1)
	var full_path = BASE + paths[idx]
	texture = load(full_path)
