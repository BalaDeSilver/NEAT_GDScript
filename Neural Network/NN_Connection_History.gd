extends Node

# A class to store the history of past connections and define new ones.
# It serves to group similar connections together.

class_name NN_Connection_History

var from_node : int = 0 # Connections that have this input
var to_node : int = 0 # and this output belong to this history
var innovation : int = 0

var innovation_numbers : Array = []

# Constructor
func _init(from : int, to : int, inno : int, innos : Array):
	from_node = from
	to_node = to
	innovation = inno
	innovation_numbers = innos

func matches(genome, from : NN_Node, to : NN_Node):
	if (genome.genes.size() == innovation_numbers.size()):
		if (from.number == from_node and to.number == to_node):
			for i in genome.genes:
				if not (innovation_numbers.has(i.innovation)):
					return false
			return true
	return false
