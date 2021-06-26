extends NN_Population
# To utilize this asset, extend both NN_Agent and NN_Population and define your static functions, listed below.

class_name My_Population # Give it whatever name you want, but don't forget to give it one.

# Whenever you want to generate the network, call generate(n), where n is the number of agents you wish to create.
func _ready():
	generate(4)

# Don't forget to write this function, so the parent class can call your Agent class, instead of the base one.
func create_agent():
	return My_Agent.new().generate(4, 4, false, self)
