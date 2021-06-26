extends Node

# The class for each genome in the NN.
# This is the brain of each agent.

class_name NN_Genome

var agent_ref # A reference upwards, to the agent
var genes : Array = [] # Connections
var nodes : Array = [] # Nodes
var inputs : int = 0 # How many input nodes
var outputs : int = 0 # How many output nodes
var layers : int = 2 # How many layers in the network
var next_node : int = 0 # Meta variable
var bias_node : int = 0 # Bias node
var network : Array = [] # A list of the nodes in the order that they need to be considered in the NN

# The top left and bottom right corners of the genome display, inside its parent.
var top_left = Vector2(INF, INF)
var bottom_right = Vector2(-INF, -INF)

# Constructor
func _init(inp : int, out : int, clone : bool, agent, innovation_history) -> void:
	inputs = inp
	outputs = out
	agent_ref = agent
	
	if(!clone):
		var local_next_connection_number = agent_ref.pop_ref.next_connection_number
		
		# Creates input nodes
		for i in range(inputs):
			nodes.append(NN_Node.new(self, i))
			next_node += 1
			nodes[i].layer = 0
			add_child(nodes[i])
		
		# Creates output nodes
		for i in range(outputs):
			nodes.append(NN_Node.new(self, inputs + i))
			next_node += 1
			nodes[inputs + i].layer = 1
			add_child(nodes[inputs + i])
		
		# Creates bias node
		nodes.append(NN_Node.new(self, next_node))
		add_child(nodes[next_node])
		bias_node = next_node
		next_node += 1
		nodes[bias_node].layer = 0
		
		# Connect inputs to outputs
		for i in range(inputs):
			for j in range(outputs):
				genes.append(NN_Connection.new(get_innovation_number(innovation_history, nodes[i], nodes[inputs + j]), self, nodes[i], nodes[inputs + j], agent_ref.pop_ref.rng.randf_range(-1, 1), local_next_connection_number))
				local_next_connection_number += 1
		# Connect bias
		for j in range(outputs):
			genes.append(NN_Connection.new(get_innovation_number(innovation_history, nodes[bias_node], nodes[inputs + j]), self, nodes[bias_node], nodes[inputs + j], agent_ref.pop_ref.rng.randf_range(-1, 1), local_next_connection_number))
			local_next_connection_number += 1
		
		for i in genes:
			add_child(i)
			pass
		
		agent_ref.pop_ref.next_connection_number = local_next_connection_number


# Returns the node with a matching number
# Most of the time, nodes will not be in order
func get_NN_node(num : int) -> NN_Node:
	for i in nodes:
		if(i.number == num):
			return i
	return null

# Returns the connection with a matching number
# Most of the time, nodes will not be in order
func get_NN_conn(num : int) -> NN_Connection:
	for i in genes:
		if(i.number == num):
			return i
	return null

# Adds the connections' references between the nodes, so they can access each other during feed forward
func connect_nodes() -> void:
	for i in nodes:
		i.output_connections.clear()
		i.input_connections.clear()
	
	for i in genes:
		i.from_node.output_connections.append(i)
		i.to_node.input_connections.append(i)

# Processes the node output based on input
func feed_forward(input_values : Array) -> Array:
	for i in range(inputs):
		nodes[i].output_value = input_values[i]
	nodes[bias_node].output_value = 1.0 #Bias output is always 1
	
	for i in network:
		i.Engage()
	
	for i in nodes:
		i.Reset()
	
	var outs = []
	outs.resize(outputs)
	for i in outs:
		i = nodes[inputs + i].output_value
	return outs

# Sets up the NN as a list of nodes in the right order to be engaged
func generate_network() -> void:
	connect_nodes()
	network = []
	# For each layer, add the node in that layer, since layers cannot connect to themselves, there is no need to order the nodes within a layer.
	for i in range(layers): # For each layer
		for j in nodes: # For each node
			if(j.layer == i): # If that node is in that layer
				network.append(j) # Add it to the list.

# Checks to see if there are possible spots for a new connection
func fully_connected():
	var max_connections = 0
	var nodes_in_layers = []
	
	for _i in range(layers):
		nodes_in_layers.append(0)
	
	for i in nodes:
		nodes_in_layers[i.layer] += 1
	
	for i in range(layers - 1):
		var nodes_in_front = 0
		for j in range(i + 1, layers):
			nodes_in_front += nodes_in_layers[j]
		
		max_connections += nodes_in_layers[i] * nodes_in_front
	
	if (max_connections == genes.size()):
		return true
	return false

# Checks to see if the random connection is actually any good
func random_connection_nodes_are_shit(rand1 : int, rand2 : int):
	if(nodes[rand1].layer == nodes[rand2].layer or nodes[rand1].is_connected_to(nodes[rand2])):
		return true
	return false

# I still can't remember what an innovation history is, sorry
func get_innovation_number(innovation_history : Array, from : NN_Node, to : NN_Node):
	var isnew = true
	var connection_innovation_number = agent_ref.pop_ref.next_connection_number
	for i in innovation_history:
		if(i.matches(self, from, to)):
			isnew = false
			connection_innovation_number = i.innovation
			break
	
	if(isnew):
		var inno_numbers = []
		for i in genes:
			inno_numbers.append(i.innovation)
		
		innovation_history.append(NN_Connection_History.new(from.number, to.number, connection_innovation_number, inno_numbers))
		agent_ref.pop_ref.next_connection_number += 1
	
	return connection_innovation_number

# Adds a random connection to the network
func add_random_connection(innovation_history : Array):
	if (fully_connected()):
		return
	
	var random_node_01 = agent_ref.pop_ref.rng.randi_range(0, nodes.size() - 1)
	var random_node_02 = agent_ref.pop_ref.rng.randi_range(0, nodes.size() - 1)
	while (random_connection_nodes_are_shit(random_node_01, random_node_02)):
		random_node_01 = agent_ref.pop_ref.rng.randi_range(0, nodes.size() - 1)
		random_node_02 = agent_ref.pop_ref.rng.randi_range(0, nodes.size() - 1)
	
	if (nodes[random_node_01].layer > nodes[random_node_02]):
		var temp = random_node_02
		random_node_02 = random_node_01
		random_node_01 = temp
	
	var connection_innovation_number = get_innovation_number(innovation_history, nodes[random_node_01], nodes[random_node_02])
	
	genes.append(NN_Connection.new(connection_innovation_number, self, nodes[random_node_01], nodes[random_node_02], agent_ref.pop_ref.rng.randf(-1, 1), genes.size()))
	self.add_child(genes.back())
	connect_nodes()

# Adds a random node to the network
func add_random_node(innovation_history : Array):
	if (genes.size() == 0):
		add_random_connection(innovation_history)
		return
	
	var random_connection = agent_ref.pop_ref.rng.randi_range(0, genes.size() - 1)
	while (genes[random_connection].from_node == nodes[bias_node]):
		random_connection = agent_ref.pop_ref.rng.randi_range(0, genes.size() - 1)
	
	genes[random_connection].enabled = false
	
	var new_node_no = next_node
	nodes.append(NN_Node.new(self, new_node_no))
	self.add_child(nodes[new_node_no])
	next_node += 1
	
	var connection_innovation_number = get_innovation_number(innovation_history, genes[random_connection].from_node, get_NN_node(new_node_no))
	genes.append(NN_Connection.new(connection_innovation_number, self, genes[random_connection].from_node, get_NN_node(new_node_no), 1, genes.size()))
	self.add_child(genes.back())
	get_NN_node(new_node_no).layer = genes.back().from_node.layer + 1
	
	connection_innovation_number = get_innovation_number(innovation_history, get_NN_node(new_node_no), genes[random_connection].to_node)
	genes.append(NN_Connection.new(connection_innovation_number, self, get_NN_node(new_node_no), genes[random_connection].to_node, genes[random_connection].weight, genes.size()))
	self.add_child(genes.back())
	
	connection_innovation_number = get_innovation_number(innovation_history, get_NN_node(bias_node), get_NN_node(new_node_no))
	genes.append(NN_Connection.new(connection_innovation_number, self, get_NN_node(bias_node), get_NN_node(new_node_no), 0, genes.size()))
	self.add_child(genes.back())
	
	
	if(get_NN_node(new_node_no).layer == genes[random_connection].to_node.layer or get_NN_node(new_node_no).layer == genes[random_connection].from_node.layer):
		for i in range(nodes.size() - 1):
			if (nodes[i].layer >= get_NN_node(new_node_no).layer):
				nodes[i].layer += 1
		layers += 1
	
	connect_nodes()
	#return get_NN_node(new_node_no)

# Mutates the network so it becomes The Hulk®
func mutate(innovation_history : Array):
	if (genes.size() == 0):
		add_random_connection(innovation_history)
	
	var rand = agent_ref.pop_ref.rng.randf()
	if (rand < 0.8):
		for i in genes:
			i.mutate_weight()
	
	rand = agent_ref.pop_ref.rng.randf()
	if (rand < 0.08):
		add_random_connection(innovation_history)
	
	rand = agent_ref.pop_ref.rng.randf()
	if (rand < 0.02):
		add_random_node(innovation_history)

# Returns the index of a gene in the network that matches another gene for another agent
func matching_gene(parent2, innovation_number : int):
	var x = 0
	while x < parent2.genes.size():
		if (parent2.genes[x].innovation == innovation_number):
			return x
		x += 1
	return -1

# As the duplicate() function sucks in Godot, this is really necessary.
func clone():
	var clone = get_script().new(inputs, outputs, true)
	
	for i in nodes:
		clone.nodes.append(i.clone())
		clone.add_child(clone.nodes.back())
	
	for i in genes:
		clone.genes.append(i.clone(clone.get_NN_node(i.from_node.number), clone.get_NN_node(i.to_node.number)))
		clone.add_child(clone.genes.back())
	
	clone.layers = layers
	clone.next_node = next_node
	clone.bias_node = bias_node
	clone.connect_nodes()
	
	return clone

# Sex 3: The Return of the Kink
func crossover(parent2):
	var child = get_script().new(inputs, outputs, true, agent_ref, null)
	child.genes.clear()
	child.nodes.clear()
	child.layers = layers
	child.next_node = next_node
	child.bias_node = bias_node
	
	var child_genes = []
	var is_enabled = []
	
	for i in range(genes.size()):
		var set_enabled = true
		
		var parent2_gene = matching_gene(parent2, genes[i].innovation)
		if (parent2_gene > -1):
			if (!genes[i].enabled or !parent2.genes[parent2_gene].enabled):
				if (agent_ref.pop_ref.rng.randf() < 0.75):
					set_enabled = false
			
			var rand = agent_ref.pop_ref.rng.randf()
			if (rand < 0.5):
				child_genes.append(genes[i])
			else:
				child_genes.append(parent2.genes[i])
		else:
			child_genes.append(genes[i])
			set_enabled = genes[i].enabled
		
		is_enabled.append(set_enabled)
	
	for i in nodes:
		child.nodes.append(i.clone())
		child.get_NN_node(i.number).genome_ref = child
		child.add_child(child.nodes.back())
	
	for i in range(child_genes.size()):
		child.genes.append(child_genes[i].clone(child.get_NN_node(child_genes[i].from_node.number), child.get_NN_node(child_genes[i].to_node.number), child))
		child.genes[i].enabled = is_enabled[i]
		#child.genes[i].genome_ref = child
		child.add_child(child.genes.back())
	
	child.connect_nodes()
	return child
