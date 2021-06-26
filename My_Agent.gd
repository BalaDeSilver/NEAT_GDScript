extends NN_Agent
# To utilize this asset, extend both NN_Agent and NN_Population and define your static functions, listed below.

class_name My_Agent # Give it whatever name you want, but don't forget to give it one.

# While thinking, the Neural Network will go through some phases.
func update(): # First, it will call update() regardless of active status.
	pass # You can put whatever needs to be done before adding the inputs here.

func look(): # Then, if active, it calls look().
	pass # It is recommended to set the inputs of the Network in here with vision = MyArray
# Then, it resolves the Network with current inputs.
func move(): # Then, it calls move().
	pass # Here, you can put code to be executed after the Network was resolved, like calculating score.

func dead(): # If (active == false), then this will be executed.
	pass # If you want it to do something if inactive, write it here.

func finally(): # This is called at the end of the think() function.
	pass # Here just in case.

func calculate_fitness(): # You can modify how you want it to calculate the fitness of every agent here.
	fitness = score # If you want to clamp or normalize it, just do it.
	return fitness
