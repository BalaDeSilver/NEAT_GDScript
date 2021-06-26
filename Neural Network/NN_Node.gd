extends Node

# The class for all the nodes in the NN.
# This is where the magic (partially) happens.

class_name NN_Node

var canvas_location := Vector2(0, 0) # The location in the canvas where the node should be. Used in the Node_Display script

var genome_ref # A reference upwards to the genome this node belongs to.
var number := 0
var input_sum := 0.0
var output_value := 0.0
var output_connections := []
var input_connections := []
var layer := 0
const e := 2.7182818284590452353602874713527 #Fun fact: Godot doesn't have a literal for the euler constant

# Constructor
func _init(genome, no : int) -> void:
	genome_ref = genome
	number = no

# As the duplicate() function sucks in Godot, this is really necessary.
func clone():
	var clone = get_script().new(genome_ref, number)
	clone.layer = layer
	return clone

# Resets the input
func Reset():
	input_sum = 0

# The superior sigmoid activation function
func Sigmoid(x : float) -> float:
	var y = 1 / (1 + pow(e, -4.9 * x))
	return y

# The node sens its output to the inputs of the nodes it's connected to
func Engage():
	var output = 0
	if(layer != 0):
		output = Sigmoid(input_sum)
	for x in range(output_connections.size()):
		output_connections[x].to_node.input_sum += output_connections[x].weight * output

func is_connected_to(node):
	if (node.layer == layer):
		return false
	
	if (node.layer < layer):
		for i in node.output_connections:
			if(i.to_node == self):
				return true
	else:
		for i in output_connections:
			if(i.to_node == node):
				return true
	
	return false
