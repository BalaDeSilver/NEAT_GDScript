extends Node

# The class for each connection.
# Short and sweet, but vital to the overall functioning of the NN.

class_name NN_Connection

# I won't comment everything, you should get the gist of it.
var genome_ref # The reference upwards in the hierarchy. This allows for the NN to not be in a scene tree, if needed or desired.
var from_node # The connection links this node
var to_node # to this node,
var weight := 0.0 # with this weight.
var number := 0 # The number is the unique ID of a connection
var enabled := true
var innovation := 0 # The innovation is given to a connection to match it with other connections. Similar connections have the same innovation number.

# Constructor
func _init(inno : int, genome, from, to, w : float, n : int):
	genome_ref = genome
	from_node = from
	to_node = to
	weight = w
	number = n
	innovation = inno

# Generates a random, brand new weight.
func mutate_weight():
	var rand2 = genome_ref.agent_ref.pop_ref.rng.randf()
	if(rand2 < 0.1):
		weight = genome_ref.agent_ref.pop_ref.rng.randf_range(-1, 1)
	else:
		weight += genome_ref.agent_ref.pop_ref.rng.randfn() / 50
		weight = clamp(weight, -1, 1)

# As the duplicate() function sucks in Godot, this is really necessary.
func clone(from, to, net):
	var clone = get_script().new(innovation, net, from, to, weight, net.genes.size())
	clone.enabled = enabled
	return clone
