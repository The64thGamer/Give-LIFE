extends Node

# Set of node names to hide when toggling
var hidden_names = ["Cosmetic Body", "Cosmetic Hand L", "Cosmetic Hand R", "Cosmetic Head", "Cupcake", "Cutter"]

# Internal toggle state
var hide_specific := false

func _input(event):
	if event.is_action_pressed("Test Visibility"): # Make sure 'Test Visibility' is mapped to 'H'
		hide_specific = !hide_specific
		_toggle_visibility_recursive(self)

func _toggle_visibility_recursive(node: Node):
	for child in node.get_children():
		if child is Node3D:
			if hide_specific:
				child.visible = not hidden_names.has(child.name)
			else:
				child.visible = true
		# Recursively process all children
		_toggle_visibility_recursive(child)
