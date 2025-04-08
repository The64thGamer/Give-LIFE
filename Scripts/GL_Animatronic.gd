extends GL_Animatable

var anim_tree: AnimationTree
var blend_tree: AnimationNodeBlendTree

# Assuming this node has a child node with an AnimationPlayer
func _ready():
	# Grab the AnimationPlayer from the first child
	var anim_player := get_child(0).get_node("AnimationPlayer") as AnimationPlayer
	
	# Initialize the AnimationTree and set up the blend tree
	anim_tree = AnimationTree.new()
	anim_tree.anim_player = anim_player.get_path()
	add_child(anim_tree)

	# Create and assign the root node for the blend tree
	anim_tree.tree_root = AnimationNodeAnimation.new()
	anim_tree.active = true
	var animations = anim_player.get_animation_list()
	if animations.size() == 0:
		return

	blend_tree = AnimationNodeBlendTree.new()
	anim_tree.tree_root = blend_tree
	anim_player.speed_scale = 0
	
	# Handle single animation case
	if animations.size() == 1:
		var node_name = "Anim_" + animations[0]
		var anim_node := AnimationNodeAnimation.new()
		anim_node.animation = animations[0]
		blend_tree.add_node(node_name, anim_node, Vector2.ZERO)

		var output := AnimationNodeOutput.new()
		blend_tree.add_node("Output", output, Vector2(200, 0))
		blend_tree.connect_node("Output", 0, node_name)
		return

	# Start with the first animation
	var prev_name = "Anim_" + animations[0]
	var prev_anim_node := AnimationNodeAnimation.new()
	prev_anim_node.animation = animations[0]
	blend_tree.add_node(prev_name, prev_anim_node, Vector2.ZERO)

	# Iteratively add and connect animations through Add2 nodes
	for i in range(1, animations.size()):
		var anim_name = "Anim_" + animations[i]
		var add_name = "Add_" + str(i)

		var new_anim_node := AnimationNodeAnimation.new()
		new_anim_node.animation = animations[i]
		blend_tree.add_node(anim_name, new_anim_node, Vector2(i * 200, 0))

		var add_node := AnimationNodeAdd2.new()
		blend_tree.add_node(add_name, add_node, Vector2(i * 200, 100))
		blend_tree.connect_node(add_name, 0, prev_name)
		blend_tree.connect_node(add_name, 1, anim_name)
		prev_name = add_name

	# Final output node connection
	#var output := AnimationNodeOutput.new()
	#blend_tree.add_node("Output", output, Vector2((animations.size() + 1) * 200, 100))
	blend_tree.connect_node("output", 0, prev_name)
	for i in range(0,animations.size()):
		anim_tree.set("parameters/Add_" + str(i) + "/add_amount", 1.0)


func _sent_signals(anim_name: String, value: float):
	if not anim_tree:
		return

	var anim_path = "parameters/Anim_" + anim_name + "/time"
	var anim_player = get_child(0).get_node("AnimationPlayer") as AnimationPlayer

	if not anim_player.has_animation(anim_name):
		print("Animation not found: ", anim_name)
		print(anim_player.get_animation_list())
		return

	var anim_length = anim_player.get_animation(anim_name).length
	var time_value = clamp(value, 0.0, 1.0) * anim_length

	anim_tree.set(anim_path, time_value)
