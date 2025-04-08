extends GL_Animatable

var anim_tree: AnimationTree
var blend_tree: AnimationNodeBlendTree

# Assuming this node has a child node with an AnimationPlayer
func _ready():
	# Grab the AnimationPlayer from the first child
	var anim_player := get_child(0).get_node("AnimationPlayer") as AnimationPlayer
	
	# Initialize the AnimationTree and set up the blend tree
	anim_tree = AnimationTree.new()
	add_child(anim_tree)

	# Create and assign the root node for the blend tree
	anim_tree.tree_root = AnimationNodeBlendTree.new()
	anim_tree.active = true
	
	blend_tree = anim_tree.tree_root as AnimationNodeBlendTree

func _sent_signals(anim_name: String, value: float):
	pass
